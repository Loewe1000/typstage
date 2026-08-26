
(function () {
  // ── Check surface, part one: the error list ────────────────────────────────
  //
  // This stands before everything else on purpose. A collector that is hung on
  // after `load` misses exactly the errors thrown while the deck is being put
  // together, and those are the ones worth catching. `console.error` and
  // `console.warn` are wrapped too, because the runtime reports several real
  // faults that way and none of them throws.
  //
  // The list is bounded. A deck that throws inside an animation frame would
  // otherwise fill the tab with strings nobody reads.
  var FEHLER = [];
  var VERWORFEN = 0;
  function merke(art, was) {
    // Bounded, but it says so. Silently dropping everything after the
    // two-hundredth entry means a run reports the wrong errors: a flood of
    // warnings would push out the one throw that mattered, and the list would
    // look complete.
    if (FEHLER.length < 200) { FEHLER.push(art + ": " + String(was)); return; }
    VERWORFEN += 1;
    FEHLER[199] = "…and " + VERWORFEN + " more, not recorded";
  }
  // The list is reachable from here on, and not only through `typstage.pruef`
  // at the very end. A deck that dies while being built never gets that far,
  // and then this is the only place that still says why.
  window.typstageFehler = FEHLER;
  addEventListener("error", function (e) {
    merke("error", e.message
      || (e.target && (e.target.src || e.target.href || e.target.currentSrc))
      || e);
  }, true);
  addEventListener("unhandledrejection", function (e) {
    merke("promise", e.reason && e.reason.message ? e.reason.message : e.reason);
  });
  ["error", "warn"].forEach(function (k) {
    var echt = console[k];
    console[k] = function () {
      // The real call first, and the note second and guarded. Turning the
      // arguments into text can throw -- a Symbol, an object whose `toString`
      // throws, a Proxy that refuses the read -- and this wrapper sits in the
      // runtime that ships. Measured before this: `console.error(Symbol("x"))`
      // threw where it used to print, and the output never arrived. A checking
      // aid must not be able to take down the talk it is watching.
      echt.apply(console, arguments);
      try { merke(k, [].join.call(arguments, " ")); } catch (x) {
        try { merke(k, "(an argument could not be turned into text)"); }
        catch (y) {}
      }
    };
  });

  var NS = "http://www.w3.org/2000/svg";
  var B = document.getElementById("ts-stage");
  var FLY = document.getElementById("ts-fly");
  var OVERVIEW = document.getElementById("ts-overview");
  var HINT = document.getElementById("ts-hint");
  var SLIDES = [].slice.call(document.querySelectorAll(".ts-slide"));
  var CFG = JSON.parse(document.getElementById("ts-cfg").textContent);
  var EASE = "cubic-bezier(.4,0,.2,1)";
  var SPRECHERBOX = document.getElementById("ts-speaker");
  var INK = document.getElementById("ts-ink");

  // ── Links that point outside ──────────────────────────────────────────────
  //
  // A link on a slide leads away from the deck. Opening it in the same tab
  // would take the talk with it, and there is no way back that a speaker wants
  // to look for in front of a room.
  //
  // The anchors come out of `html.frame` and sit inside the SVG, where they
  // carry `href` as well as `xlink:href`. Both are read, because which of the
  // two Typst writes is not ours to decide.
  document.querySelectorAll("a").forEach(function (a) {
    var href = a.getAttribute("href") || a.getAttribute("xlink:href") || "";
    if (!/^https?:/i.test(href)) return;
    a.setAttribute("target", "_blank");
    a.setAttribute("rel", "noopener");
  });

  // ── The role, once and for good ───────────────────────────────────────────
  //
  // The same file carries two views: the talk and, with `#speaker` in the
  // address, the speaker view. Which one is meant sits in the hash, and that
  // is exactly the trap, because the hash otherwise belongs to the running
  // step: `goto` keeps writing it forward. The first `goto` would overwrite
  // `#speaker`, and the view would flip back mid-load. So the role is read
  // here once and never fetched from the hash again; in the speaker window
  // the hash is not touched at all anymore.
  var ROLLE = (location.hash.slice(1).split(/[&=]/)[0] || "").toLowerCase()
              === "speaker" ? "speaker" : "stage";
  if (ROLLE === "speaker") document.documentElement.dataset.tsRolle = "speaker";

  // ── Defusing duplicate SVG ids ────────────────────────────────────────────
  //
  // Typst derives the ids in an SVG from the content. The same clipped box
  // twice on one slide, once in the background and once as a sprite, or
  // simply twice, therefore produces the same `<clipPath id>` twice. In HTML
  // an id has to be unique, so `url(#...)` binds to the first occurrence: the
  // second box gets clipped against foreign dimensions and mostly disappears
  // entirely. The same hits the glyphs' `<symbol id>`.
  //
  // Only what is really duplicated gets renamed, and references are only
  // rewired within the same SVG, which is where they belong.
  (function () {
    var gesehen = Object.create(null), lauf = 0;
    document.querySelectorAll("svg").forEach(function (svg) {
      var karte = null;
      svg.querySelectorAll("[id]").forEach(function (el) {
        var alt = el.id;
        if (!gesehen[alt]) { gesehen[alt] = 1; return; }
        var neu = alt + "-ts" + (++lauf);
        el.id = neu;
        gesehen[neu] = 1;
        (karte || (karte = Object.create(null)))[alt] = neu;
      });
      if (!karte) return;
      svg.querySelectorAll("*").forEach(function (u) {
        for (var i = 0; i < u.attributes.length; i++) {
          var a = u.attributes[i], v = a.value;
          if (v.indexOf("#") < 0) continue;
          for (var alt in karte) {
            if (v === "#" + alt) { a.value = "#" + karte[alt]; break; }
            if (v === "url(#" + alt + ")") { a.value = "url(#" + karte[alt] + ")"; break; }
          }
        }
      });
    });
  })();

  // Per-slide settings live on the overlay: it sits inside a `context` and
  // therefore sees marks that were only set while laying out the body.
  function attr(f, name) {
    var o = f.querySelector(".ts-ov");
    return o ? o.dataset[name] : null;
  }

  // ── Step list ─────────────────────────────────────────────────────────────
  // A slide's step count comes from the selectors: those of its elements
  // and those of the bridge jobs.
  var STEPS = [];
  SLIDES.forEach(function (f, i) {
    var n = 1;
    function schau(at) {
      String(at || "").replace(/\d+/g, function (z) { n = Math.max(n, +z); });
    }
    f.querySelectorAll(".ts-el").forEach(function (el) { schau(el.dataset.at); });
    var s = f.querySelector("script.ts-bridge");
    if (s) JSON.parse(s.textContent).forEach(function (j) { schau(j.at); });
    f.dataset.steps = n;
    for (var k = 1; k <= n; k++) STEPS.push({ slide: i, step: k });
  });

  // ── Which deck this is ────────────────────────────────────────────────────
  //
  // Under `file://`, Chrome has *all* local files share the same origin:
  // `location.origin` is literally "file://". Anything hung off the origin
  // therefore belongs not to this deck but to every file on the disk. Two
  // places need an id that means the deck and not the origin: the memory
  // across reloads, and the handshake between the windows.
  //
  // The path tells the files apart, the count behind it tells apart two
  // states of the same file.
  var DECK = location.pathname + "|" + SLIDES.length + "." + STEPS.length;

  // ── Selektoren: "2-", "1-2", "2,4", "3" ───────────────────────────────────
  function activeAt(at, s) {
    var parts = String(at || "1-").split(",");
    for (var i = 0; i < parts.length; i++) {
      var t = parts[i].trim();
      if (!t) continue;
      var k = t.indexOf("-");
      if (k < 0) { if (+t === s) return true; continue; }
      var a = t.slice(0, k) === "" ? 1 : +t.slice(0, k);
      var b = t.slice(k + 1) === "" ? Infinity : +t.slice(k + 1);
      if (s >= a && s <= b) return true;
    }
    return false;
  }

  // The last step a selector still covers, or Infinity if it runs to the end
  // of the slide. Only a selector with a last step has an "after" for an
  // element to rest in.
  function endeBei(at) {
    var parts = String(at || "1-").split(","), e = 0;
    for (var i = 0; i < parts.length; i++) {
      var t = parts[i].trim();
      if (!t) continue;
      var k = t.indexOf("-");
      if (k < 0) { e = Math.max(e, +t); continue; }
      if (t.slice(k + 1) === "") return Infinity;
      e = Math.max(e, +t.slice(k + 1));
    }
    return e;
  }

  // ── Geometry ──────────────────────────────────────────────────────────────
  // Marks live in the background SVG. getCTM() maps them into viewBox
  // coordinates; the result is stored as ratios so any window size fits.
  // Collect every mark currently drawn in the slide: background as well as
  // sprites that already found their place.
  function marken(slide, bezug) {
    var karte = {};
    slide.querySelectorAll("path").forEach(function (p) {
      var f = (p.getAttribute("fill") || "").toLowerCase();
      if (f.length !== 9 || f.slice(0, 3) !== "#fe" || f.slice(7) !== "00") return;
      // A mark inside a sprite that has not been placed yet measures
      // nonsense. Only once the parent sits does its content count.
      var wirt = p.closest(".ts-el");
      if (wirt && !wirt.style.width) return;
      var r = p.getBoundingClientRect();
      if (!r.width && !r.height) return;
      karte[parseInt(f.slice(3, 7), 16)] = {
        x: (r.left - bezug.left) / bezug.width,
        y: (r.top - bezug.top) / bezug.height,
        w: r.width / bezug.width, h: r.height / bezug.height,
        // Who the wirt (host) is is already settled here: a marker inside a
        // sprite belongs to a nested element. The step change needs this to
        // inherit fade-in values from the parent.
        wirt: wirt ? wirt.dataset.n : null
      };
    });
    return karte;
  }

  function setzen(el, r) {
    el.style.left = (r.x * 100) + "%";
    el.style.top = (r.y * 100) + "%";
    el.style.width = (r.w * 100) + "%";
    el.style.height = (r.h * 100) + "%";
  }

  // What a nested element does not specify itself, it inherits from its wirt
  // (host), but only if both appear in the same step (same `at`). Reason:
  // sprites hang as siblings in the overlay, not nested inside one another. A
  // `translateY` on the parent therefore does not carry the child along; they
  // only stay in lockstep if they run the same motion with the same values.
  // If one diverged, say `delay: 120` on a staggered list against 0 on the
  // morph inside it, the child arrived before its own container.
  function erbt(el, feld) {
    if (el.dataset[feld] !== undefined) return el.dataset[feld];
    if (!el.dataset.parent) return undefined;
    var folie = el.closest(".ts-slide");
    if (!folie) return undefined;
    var wirt = folie.querySelector('.ts-el[data-n="' + el.dataset.parent + '"]');
    if (!wirt || wirt.dataset.at !== el.dataset.at) return undefined;
    return wirt.dataset[feld];
  }

  // ── Keys out of an embedded frame ─────────────────────────────────────────
  //
  // A frame that has been clicked holds the focus, and from then on every key
  // lands inside it. The window around it hears nothing, so the talk stops
  // paging: reported from a real desk, and in the speaker view it is worse,
  // because `m` is in there too and one cannot even switch back to the pen.
  //
  // Measured on a GeoGebra applet before deciding what to do about it. Focus
  // sits on its `canvas`, it sees all seventeen keys tried, it calls
  // `preventDefault` on none of them, and it changes nothing in the
  // construction. In this configuration, without toolbar and without an
  // algebra input, the applet has no use for the keyboard at all. So the keys
  // belong to the talk, and they are handed back to it.
  //
  // Three conditions, so this stays true for a document that does want keys:
  // it must not have taken the key already (`defaultPrevented`), the key must
  // be one the talk actually uses, and whatever was typed into must not be a
  // text field, or typing an `n` into a form would open a second window.
  var TASTEN_DECK = {
    ArrowRight: 1, ArrowLeft: 1, ArrowUp: 1, ArrowDown: 1,
    PageDown: 1, PageUp: 1, " ": 1, Home: 1, End: 1, Escape: 1,
    o: 1, f: 1, s: 1, p: 1, n: 1, "?": 1,
    b: 1, e: 1, t: 1, r: 1, m: 1, c: 1, z: 1, x: 1,
    "+": 1, "=": 1, "-": 1, "_": 1
  };
  function tastenBruecke(frame) {
    // A foreign origin cannot be reached, and it will not become reachable.
    if (frame.tsTastenFremd) return;
    var d = null;
    try { d = frame.contentDocument; } catch (x) { frame.tsTastenFremd = 1; return; }
    // The document is remembered, not a yes or no. A `srcdoc` frame starts on
    // a throwaway `about:blank` and replaces it a moment later, and whoever
    // ticks himself off after the first attempt has hung his listener on the
    // document that was thrown away. Measured: in the talk window the timing
    // happened to work out, in the speaker view it did not, and there the
    // arrow key stayed dead.
    if (!frame.tsTastenLoad) {
      frame.tsTastenLoad = 1;
      frame.addEventListener("load", function () { tastenBruecke(frame); });
    }
    if (!d || frame.tsTastenDoc === d) return;
    frame.tsTastenDoc = d;
    d.addEventListener("keydown", function (e) {
      if (e.defaultPrevented) return;
      if (!TASTEN_DECK[e.key]) return;
      if (tippt(e)) return;
      // Dispatched at our own document, so both receivers see it exactly as
      // they see a key of their own. No loop: this one is not in the frame.
      document.dispatchEvent(new KeyboardEvent("keydown", {
        key: e.key, code: e.code, bubbles: true, cancelable: true,
        ctrlKey: e.ctrlKey, altKey: e.altKey,
        shiftKey: e.shiftKey, metaKey: e.metaKey
      }));
      e.preventDefault();
    });
  }

  // In rounds: a nested element has no mark in the background, the outer
  // element's hide() swallows it, but it has one in the outer element's
  // sprite. That one has to be placed first.
  function stelle(i) {
    var svg = SLIDES[i].querySelector(".ts-bg svg");
    if (!svg) return;
    var bezug = svg.getBoundingClientRect();
    if (!bezug.width) return;
    var offen = [].slice.call(SLIDES[i].querySelectorAll(".ts-el"));
    for (var runde = 0; runde < 4 && offen.length; runde++) {
      var karte = marken(SLIDES[i], bezug);
      var rest = [];
      var skala = bezug.width / CFG.width;   // screen pixels per point
      offen.forEach(function (el) {
        var r = karte[+el.dataset.n];
        if (!r) { rest.push(el); return; }
        setzen(el, r);
        if (r.wirt) el.dataset.parent = r.wirt; else delete el.dataset.parent;
        // Corner radius in points, scaled along with the stage.
        if (el.dataset.radius && +el.dataset.radius > 0) {
          el.style.borderRadius = (+el.dataset.radius * skala) + "px";
          el.style.overflow = "hidden";
        }
        // An iframe measures in real CSS pixels and knows nothing of the
        // stage: in a large window its content would stay small inside a big
        // box. So it is given the size in slide units and then zoomed, that
        // way it always sees the same area.
        //
        // Scaled with `zoom`, not `transform: scale()`. A transform stretches
        // the finished raster; the frame drew 400 pixels wide and would be
        // blown up to 460, blurry. `zoom` acts before rasterising: the inner
        // window stays 400 points but its pixel density rises with it.
        var frame = el.querySelector("iframe");
        if (frame) {
          tastenBruecke(frame);
          var w = r.w * CFG.width, h = r.h * CFG.height;
          var neu = w + "px|" + h + "px|" + skala;
          if (frame.dataset.mass !== neu) {
            frame.dataset.mass = neu;
            // `zoom: false` means: span the frame in real screen pixels and
            // let the content reflow itself. That is the point of opting
            // out. Otherwise an embedded document would always show the same
            // crop, just rasterised larger.
            var ohneZoom = el.dataset.zoom === "0";
            frame.style.width = (ohneZoom ? w * skala : w) + "px";
            frame.style.height = (ohneZoom ? h * skala : h) + "px";
            frame.style.transform = "";
            frame.style.zoom = ohneZoom ? "" : skala;
            // An embedded app that draws has to be told, because its own
            // window need not have changed at all: where only the zoom moves,
            // the inner viewport keeps its size and no `resize` fires in
            // there. The message says "your box is new", and what to do about
            // it is the embedded document's business, not ours.
            // Both measurements, because they say different things. `w` and
            // `h` are the box in points of the slide and therefore the same
            // number in every window; `px` is the same box in screen points
            // and a different number in every window. Whoever wants to draw
            // sharply needs the second, whoever wants every window to show
            // the same thing needs the first.
            try {
              frame.contentWindow.postMessage({ typstage: 1, mass: 1,
                w: w, h: h, px: skala }, "*");
            } catch (e) {}
            // The older, direct way, for a companion package that predates
            // the message.
            try { frame.contentWindow.ggbApplet.recalculateEnvironments(); }
            catch (e) {}
          }
        }
      });
      if (rest.length === offen.length) break;
      offen = rest;
    }
  }

  function vermessen(i) {
    var svg = SLIDES[i].querySelector(".ts-bg svg");
    return svg ? marken(SLIDES[i], svg.getBoundingClientRect()) : {};
  }

  // ── Less motion ───────────────────────────────────────────────────────────
  //
  // `prefers-reduced-motion: reduce` is set by the person at the machine, in
  // the operating system, and the browser hands it on. It asks for less
  // motion, not for less deck: what this runtime drops is travel, and only
  // travel. Opacity stays everywhere, because a fade says "this is new"
  // without carrying anything across the screen, and that saying is the
  // whole job of an entrance.
  //
  // Read afresh at every use rather than latched at load. Someone who turns
  // the setting on during a talk gets the next step under the new rule, and
  // a flipbook already running stops within a frame; turning it off again
  // lets everything back in the same way. That costs a media-query lookup
  // per step, which is nothing, and saves a listener plus the state behind
  // it.
  var WENIGER = window.matchMedia
    ? window.matchMedia("(prefers-reduced-motion: reduce)") : null;
  function wenigerBewegung() { return !!(WENIGER && WENIGER.matches); }

  // ── Effects ───────────────────────────────────────────────────────────────
  var EFFECT = {
    "fade":       [{ opacity: 0 }, { opacity: 1 }],
    "fade-up":    [{ opacity: 0, transform: "translateY(14px)" },  { opacity: 1, transform: "none" }],
    "fade-down":  [{ opacity: 0, transform: "translateY(-14px)" }, { opacity: 1, transform: "none" }],
    "fade-left":  [{ opacity: 0, transform: "translateX(22px)" },  { opacity: 1, transform: "none" }],
    "fade-right": [{ opacity: 0, transform: "translateX(-22px)" }, { opacity: 1, transform: "none" }],
    "scale":      [{ opacity: 0, transform: "scale(.86)" },        { opacity: 1, transform: "none" }],
    "scale-down": [{ opacity: 0, transform: "scale(1.14)" },       { opacity: 1, transform: "none" }],
    "blur":       [{ opacity: 0, filter: "blur(7px)" },            { opacity: 1, filter: "blur(0px)" }],
    "rise":       [{ opacity: 0, transform: "translateY(26px) scale(.96)" }, { opacity: 1, transform: "none" }],
    "none":       [{ opacity: 1 }, { opacity: 1 }]
  };

  // An animation with `fill: both` pins its end value even long after it is
  // done. Whoever sets the state anew has to clear it first, otherwise it
  // wins against the value that was set.
  function clearAnims(el) {
    el.getAnimations().forEach(function (a) { try { a.cancel(); } catch (e) {} });
  }

  // The effect, with its travel taken out when less motion is asked for.
  // Every entry of the table above names an opacity in both of its two
  // states, so stripping it down to that leaves a plain fade and never an
  // empty pair. What goes with the rest is `blur`'s blur: it does not move,
  // but it is decoration on top of the fade, and the fade already carries
  // everything the effect has to say.
  function effekt(name) {
    var f = EFFECT[name] || EFFECT["fade"];
    if (!wenigerBewegung()) return f;
    return [{ opacity: f[0].opacity }, { opacity: f[1].opacity }];
  }

  function fadeIn(el, name, dur, delay) {
    clearAnims(el);
    // "none" means no effect. Animating from 1 to 1 would not merely be
    // pointless: played backwards it would keep the element visible.
    if (name === "none") { el.style.opacity = "1"; return; }
    var f = effekt(name);
    el.style.opacity = "";
    var a = el.animate([f[0], f[1]],
      { duration: dur, delay: delay, easing: EASE, fill: "both" });
    a.onfinish = function () { el.style.opacity = "1"; a.cancel(); };
  }

  // How far down a dimmed element goes. Not a taste, a measurement. Dimming
  // composites the ink towards the ground, so the ground decides what it
  // costs, and the value is the smallest hundredth at which body text still
  // meets the 4.5 to 1 the package's contrast contract asks of it, on
  // all five bundled palettes, upright and inverted, on the paper and on a
  // card surface. The tightest of the twenty is `parchment` on its own paper:
  // 4.57 at 0.65 and 4.44 at 0.64. The most forgiving is `mono` inverted at
  // 8.60, because opacity costs far less on a dark ground than on a light
  // one. Between full and dimmed there remain 1.94 to 3.23 to 1, so the step
  // is plainly visible everywhere. The arithmetic is `contrast()` in
  // `src/palettes.typ`.
  //
  // It holds for text in the ink colour, which is what a point is set in.
  // Dimming something already quiet, a `muted` footer or an accent-coloured
  // word, drops under the contract; the manual says so.
  var DIM = 0.65;

  function fadeOut(el, name, dur, von) {
    clearAnims(el);
    if (name === "none") { el.style.opacity = "0"; return; }
    var f = effekt(name);
    var ab = f[1];
    // Leaving out of the dimmed state starts where the element stands. Taken
    // from the effect's full end value it would flash back to full strength
    // for one frame before it goes.
    if (von != null && von !== 1) {
      ab = {};
      for (var k in f[1]) ab[k] = f[1][k];
      ab.opacity = von;
    }
    var a = el.animate([ab, f[0]],
      { duration: dur, easing: EASE, fill: "both" });
    a.onfinish = function () { el.style.opacity = "0"; try { a.cancel(); } catch (e) {} };
  }

  // Between two resting opacities, with no effect and no travel. Dimming is
  // not an entrance and not a departure: the point does not move, it only
  // steps back or comes forward again.
  function fadeTo(el, von, bis, dur) {
    clearAnims(el);
    var a = el.animate([{ opacity: von }, { opacity: bis }],
      { duration: dur, easing: EASE, fill: "both" });
    a.onfinish = function () {
      el.style.opacity = String(bis); try { a.cancel(); } catch (e) {}
    };
  }

  // The three states a sprite rests in, on the element as well as in the
  // markup: 0 not drawn, 1 drawn muted, 2 drawn. `data-on` keeps meaning
  // "is on the slide", so whatever asks that question -- a morph looking for
  // its source, the pointer looking for a frame -- finds a dimmed element
  // too, because it is on the slide.
  function ruhe(el, z) {
    if (z === 0) {
      delete el.dataset.on; delete el.dataset.dim; el.style.opacity = "0";
    } else if (z === 1) {
      el.dataset.on = "1"; el.dataset.dim = "1";
      el.style.opacity = String(DIM);
    } else {
      el.dataset.on = "1"; delete el.dataset.dim; el.style.opacity = "1";
    }
  }

  // Which of the three a sprite is in on a given step.
  function eigenerZustand(el, schritt) {
    if (activeAt(el.dataset.at, schritt)) return 2;
    // The cheap question first. Almost every selector runs to the end of the
    // slide, and then there is nothing to look up.
    if (schritt > endeBei(el.dataset.at) && erbt(el, "after") === "dimmed") return 1;
    return 0;
  }

  function wirtVon(el) {
    if (!el.dataset.parent) return null;
    var folie = el.closest(".ts-slide");
    return folie
      ? folie.querySelector('.ts-el[data-n="' + el.dataset.parent + '"]') : null;
  }

  // Nothing is more visible than what it sits inside.
  //
  // A tracked element inside another keeps its own range -- `morph`, `video`,
  // `embed` and `flipbook` all default to `at: "1-"` -- and the sprites are
  // siblings in the DOM, so the host cannot hide it by covering it. Measured
  // on a `morph` inside an `anim(at: "2-")`: on step 1 the formula stood there
  // at full strength while its own bullet was still invisible.
  //
  // The host is known: `stelle` writes `data-parent` whenever a marker was
  // found inside another element's sprite. So the state is simply capped by
  // the host's, up the whole chain. An inner element may still be *less*
  // visible than its host -- that is what its own range is for.
  function zustand(el, schritt, tiefe) {
    var z = eigenerZustand(el, schritt);
    if (z === 0 || (tiefe || 0) > 8) return z;
    var wirt = wirtVon(el);
    if (!wirt) return z;
    return Math.min(z, zustand(wirt, schritt, (tiefe || 0) + 1));
  }

  // ── Magic move ────────────────────────────────────────────────────────────
  // Typst bakes the font size into the outline: the same glyph has different
  // path data at 20pt and at 34pt, and therefore different symbol ids. For
  // pairing, the outline is normalised to its largest coordinate: what
  // remains is the shape, and the size drops out.
  var sigCache = {};
  function signatur(id) {
    if (sigCache[id] != null) return sigCache[id];
    var sym = document.getElementById(id.replace(/^#/, ""));
    var d = "";
    if (sym) sym.querySelectorAll("path").forEach(function (p) {
      d += (p.getAttribute("d") || "") + "|";
    });
    var max = 0;
    (d.match(/-?\d+(\.\d+)?/g) || []).forEach(function (z) {
      max = Math.max(max, Math.abs(+z));
    });
    var sig = max ? d.replace(/-?\d+(\.\d+)?/g, function (z) {
      return Math.round(+z / max * 1000) / 1000;
    }) : d;
    sigCache[id] = sig;
    return sig;
  }

  // Pins sit as transparent rectangles behind their content, the same
  // construction as the element marks, only with #fd instead of #fe. The
  // number inside is computed from the name, so equal names give the same
  // number.
  function pinFelder(el) {
    var felder = [];
    el.querySelectorAll("path").forEach(function (p) {
      var f = (p.getAttribute("fill") || "").toLowerCase();
      if (f.length !== 9 || f.slice(0, 3) !== "#fd" || f.slice(7) !== "00") return;
      var r = p.getBoundingClientRect();
      if (!r.width && !r.height) return;
      felder.push({ id: parseInt(f.slice(3, 7), 16), r: r });
    });
    return felder;
  }

  // A glyph's box in screen coordinates.
  //
  // Not `getBoundingClientRect()`, even though that would be the obvious
  // route: on a `<use>`, Firefox returns for it not the glyph's box but the
  // whole SVG's. Measured on an equation with 23 characters, Chrome gave
  // 25x23, 16x24, 34x34, and Firefox gave 476x43 for *every* character. Since
  // the ghost gets its size from this box, every letter there was stretched
  // to the width of the formula. That is exactly what was reported as "all
  // the letters smeared sideways".
  //
  // `getBBox()`, by contrast, agrees between both engines (16x14, 10x15,
  // 21x21), and `getScreenCTM()` converts it into screen dimensions. All four
  // corners, because a matrix can also rotate and shear. In Chrome this comes
  // out to the same pixel value as before.
  function glyphKasten(u) {
    var b, m;
    try { b = u.getBBox(); m = u.getScreenCTM(); } catch (e) { return null; }
    if (!m || !b || (!b.width && !b.height)) return null;
    var xs = [], ys = [];
    for (var i = 0; i < 4; i++) {
      var x = b.x + (i & 1 ? b.width : 0), y = b.y + (i & 2 ? b.height : 0);
      xs.push(m.a * x + m.c * y + m.e);
      ys.push(m.b * x + m.d * y + m.f);
    }
    var l = Math.min.apply(null, xs), r = Math.max.apply(null, xs);
    var o = Math.min.apply(null, ys), un = Math.max.apply(null, ys);
    return { left: l, top: o, right: r, bottom: un, width: r - l, height: un - o };
  }

  function glyphs(el) {
    var out = [], felder = pinFelder(el);
    el.querySelectorAll("use").forEach(function (u) {
      var r = glyphKasten(u);
      if (!r || r.width <= 0 || r.height <= 0) return;
      var id = u.getAttribute("xlink:href") || u.getAttribute("href") || "";
      // The glyph belongs to the pin in whose field its center lies. With
      // nested pins the smallest one wins, otherwise a pin around the whole
      // term would swallow the names of the characters inside it.
      var mx = r.left + r.width / 2, my = r.top + r.height / 2;
      var pin = null, klein = Infinity;
      for (var i = 0; i < felder.length; i++) {
        var q = felder[i].r;
        if (mx < q.left || mx > q.right || my < q.top || my > q.bottom) continue;
        var a = q.width * q.height;
        if (a < klein) { klein = a; pin = felder[i].id; }
      }
      out.push({ id: id, sig: signatur(id), r: r, node: u, pin: pin });
    });
    return out;
  }

  // First in reading order by shape, then whatever is left goes to its
  // nearest counterpart, otherwise a glyph would be dropped merely because
  // it changed places.
  function pairs(a, b) {
    var frei = b.slice(), zug = [];
    // Pins first: equal names find each other before the shape is
    // consulted. A pin without a counterpart then falls back to the shape
    // match.
    var fest = [];
    a.forEach(function (g) {
      if (g.pin === null || g.pin === undefined) return;
      for (var i = 0; i < frei.length; i++) {
        if (frei[i].pin === g.pin) {
          fest.push([g, frei[i]]);
          frei.splice(i, 1);
          return;
        }
      }
    });
    function gepinnt(g) {
      for (var i = 0; i < fest.length; i++) if (fest[i][0] === g) return fest[i][1];
      return null;
    }
    a.forEach(function (g) {
      var p = gepinnt(g);
      if (p) { zug.push([g, p]); return; }
      var t = -1;
      for (var i = 0; i < frei.length; i++) if (frei[i].sig === g.sig) { t = i; break; }
      if (t < 0) { zug.push([g, null]); return; }
      zug.push([g, frei[t]]);
      frei.splice(t, 1);
    });
    // No fallback to the nearest free character. Whoever finds no matching
    // shape fades out at its own place, and the new one fades in at its own.
    // A colon that stretches into a letter is not a flight but a smear, and
    // which character happens to sit closest spatially says nothing about
    // whether the two have anything to do with each other.
    //
    // Anyone who wants to relate two characters whose shape differs gives
    // them the same name with `pin`. That is explicit and traceable;
    // proximity is not.

    // A pin is allowed to land on the target twice: then the character
    // visibly splits into two. That is exactly what the power rule needs;
    // the exponent appears up front as a factor and at the same time stays
    // up top. So the search also covers sources that have already been
    // assigned.
    for (var i = frei.length - 1; i >= 0; i--) {
      var z = frei[i];
      if (z.pin === null || z.pin === undefined) continue;
      for (var k = 0; k < fest.length; k++) {
        if (fest[k][0].pin === z.pin) {
          zug.push([fest[k][0], z]);
          frei.splice(i, 1);
          break;
        }
      }
    }
    // `rest` are target glyphs without a source, those have to fade in.
    return { zug: zug, rest: frei };
  }

  // Lift a glyph out as its own SVG. Both the clip and the clone matrix must
  // be expressed in the source SVG's user coordinate system; getCTM() maps to
  // the viewport instead and would apply the viewBox factor a second time.
  function inBenutzer(node, svg) {
    return svg.getScreenCTM().inverse().multiply(node.getScreenCTM());
  }

  // The stroke width, provided the node strokes at all. Glyph outlines only
  // have a fill and yield 0, which is how they can be told apart.
  function strichBreite(node) {
    var st = node.getAttribute("stroke");
    if (!st || st === "none") return 0;
    return parseFloat(node.getAttribute("stroke-width")
                      || getComputedStyle(node).strokeWidth) || 0;
  }

  function kastenInBenutzer(node, svg, m) {
    var b = node.getBBox(), p = svg.createSVGPoint(), xs = [], ys = [];
    // `getBBox` measures the geometry without the stroke. A horizontal
    // radical bar is thus zero tall, and its ghost double would stay
    // invisible.
    var sw = strichBreite(node);
    if (sw > 0) {
      b = { x: b.x - sw / 2, y: b.y - sw / 2,
            width: b.width + sw, height: b.height + sw };
    }
    [[b.x, b.y], [b.x + b.width, b.y],
     [b.x, b.y + b.height], [b.x + b.width, b.y + b.height]].forEach(function (c) {
      p.x = c[0]; p.y = c[1];
      var q = p.matrixTransform(m);
      xs.push(q.x); ys.push(q.y);
    });
    var x0 = Math.min.apply(null, xs), x1 = Math.max.apply(null, xs);
    var y0 = Math.min.apply(null, ys), y1 = Math.max.apply(null, ys);
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
  }

  // What is drawn and not set: radical arcs, fraction bars, equals bars,
  // frames. `glyphs()` only collects `<use>`, so not these parts, and
  // because `[data-hold]` hides the whole element, they used to vanish
  // during the flight and appear abruptly only at the end.
  function striche(el) {
    var out = [];
    el.querySelectorAll("path").forEach(function (n) {
      var sw = strichBreite(n);
      if (sw <= 0) return;              // glyph outline, not a drawn stroke
      // Measured the way the glyphs are, not with `getBoundingClientRect`.
      // Firefox counts the stroke into that box, and more generously than by
      // half its width: on the same fraction bar it reports 18.9 by 5.2 where
      // the geometry is 13.7 by 0, and Chrome reports 13.7 by 0 as well.
      // Because half a stroke width is added on each side right afterwards,
      // the ghost came out twice as tall, and `preserveAspectRatio="none"`
      // stretched the line onto it. Reported from the forum as fraction bars
      // that briefly thicken during a flight, though not in Chrome.
      var r = glyphKasten(n);
      if (!r || (r.width <= 0 && r.height <= 0)) return;
      // Widen on screen too by half the stroke width, otherwise the ghost
      // double's box would be zero in one direction.
      var c = n.getScreenCTM();
      var px = sw * (c ? Math.hypot(c.a, c.c) : 1) / 2;
      var py = sw * (c ? Math.hypot(c.b, c.d) : 1) / 2;
      out.push({ node: n, r: { left: r.left - px, top: r.top - py,
                               width: r.width + 2 * px, height: r.height + 2 * py } });
    });
    return out;
  }

  function glyphGeist(g, stage, box) {
    var k = box || g.r;
    var w = g.node.ownerSVGElement;
    var m = inBenutzer(g.node, w);
    var vb = kastenInBenutzer(g.node, w, m);
    var d = document.createElement("div");
    d.className = "ts-ghost";
    var s = document.createElementNS(NS, "svg");
    s.setAttribute("preserveAspectRatio", "none");
    s.setAttribute("viewBox", vb.x + " " + vb.y + " " + vb.w + " " + vb.h);
    var box = document.createElementNS(NS, "g");
    box.setAttribute("transform",
      "matrix(" + m.a + "," + m.b + "," + m.c + "," + m.d + "," + m.e + "," + m.f + ")");
    var klon = g.node.cloneNode(true);
    klon.removeAttribute("transform");
    box.appendChild(klon);
    s.appendChild(box);
    d.appendChild(s);
    d.style.left = (k.left - stage.left) + "px";
    d.style.top = (k.top - stage.top) + "px";
    d.style.width = k.width + "px";
    d.style.height = k.height + "px";
    return d;
  }

  var CHROME = [].slice.call(document.querySelectorAll("#ts-chrome > .ts-chrome"));

  var flyTimers = [];
  // How many ghosts a talk has produced since it was loaded. Counted where
  // they are made, not read off `#ts-fly` afterwards: the layer is emptied
  // again by a timer, so whoever counts it later counts whatever the machine
  // happened to have cleaned up by then. A running total cannot be asked at
  // the wrong moment.
  var FLUG = 0;

  //
  function finishTransitionNow() {
    SLIDES.forEach(function (f) {
      if (f.mo_zeit) { clearTimeout(f.mo_zeit); f.mo_zeit = null; }
      if (f.mo_aus) { try { f.mo_aus.cancel(); } catch (e) {} f.mo_aus = null; }
      f.getAnimations().forEach(function (a) { try { a.cancel(); } catch (e) {} });
      delete f.dataset.off;
      resetStyle(f);
    });
    B.style.perspective = "";
  }

  function fly(fromSlide, toSlide, fallback) {
    // Magic move is travel and nothing but travel: the point of it is that
    // the eye follows a shape from where it stood to where it now stands.
    // Asked for less motion there is nothing left of it worth keeping, so
    // the slide change falls back to the ordinary transition. `false` says
    // "no morph happened", the same answer a slide pair without a matching
    // name gives, and it is the same route a jump already takes.
    if (wenigerBewegung()) return false;
    flyTimers.forEach(function (t) { clearTimeout(t); });
    flyTimers = [];
    finishTransitionNow();
    while (FLY.firstChild) FLY.removeChild(FLY.firstChild);
    document.querySelectorAll(".ts-el[data-hold]").forEach(function (e) {
      delete e.dataset.hold;
    });
    var sources = {};
    SLIDES[fromSlide].querySelectorAll(".ts-morph").forEach(function (e) {
      if (e.dataset.on === "1") sources[e.dataset.name] = e;
    });
    var stage = B.getBoundingClientRect();
    var any = false;

    SLIDES[toSlide].querySelectorAll(".ts-morph").forEach(function (dst) {
      var src = sources[dst.dataset.name];
      if (!src) return;
      any = true;
      var d = +dst.dataset.fly || +src.dataset.fly || fallback;
      var qr = src.getBoundingClientRect(), zr = dst.getBoundingClientRect();
      // From both sides, like the flight duration a line above already:
      // going backward, source and target swap roles, and reading `match`
      // only on the target would then find the default there. In
      // theme-editorial the long line carries `match: "glyph"`; going
      // backward it is the source, and the flight turned into a block push.
      //
      // `"auto"` counts here as "not chosen" and not as an answer. The value
      // sits as the default on *every* morph, so a mere `||` would never get
      // through to the source. An explicit choice on either side applies to
      // the flight between them, in both directions.
      var wie = dst.dataset.match;
      if (!wie || wie === "auto") wie = src.dataset.match || "auto";
      var qg = glyphs(src), zg = glyphs(dst);
      var perGlyph = wie !== "block" && qg.length > 0 && zg.length > 0 &&
        (wie === "glyph" || (qg.length <= 48 && zg.length <= 48));

      src.dataset.hold = "1";
      dst.dataset.hold = "1";
      var ghosts = [];
      var ueber = 0.42;
      var window = { duration: d * ueber, delay: d * (0.5 - ueber / 2),
                      easing: "linear", fill: "both" };

      var attach = function (node) {
        FLY.appendChild(node); ghosts.push(node); FLUG++;
      };

      if (perGlyph) {
        var p = pairs(qg, zg);
        p.zug.forEach(function (paar) {
          var g = paar[0], z = paar[1];
          if (!z) {
            var allein = glyphGeist(g, stage);
            attach(allein);
            allein.animate([{ opacity: 1 }, { opacity: 0 }],
              { duration: d * 0.55, easing: "ease-out", fill: "forwards" });
            return;
          }

          var zx = z.r.left - g.r.left, zy = z.r.top - g.r.top;
          var sx = z.r.width / g.r.width, sy = z.r.height / g.r.height;
          var path = [
            { transform: "translate(0,0) scale(1,1)" },
            { transform: "translate(" + zx + "px," + zy + "px) scale(" + sx + "," + sy + ")" }
          ];
          var timing = { duration: d, easing: EASE, fill: "forwards" };

          //
          var ank = glyphGeist(z, stage, g.r);
          attach(ank);
          ank.animate(path, timing);

          var ghost = glyphGeist(g, stage);
          attach(ghost);
          ghost.animate(path, timing);
          ghost.animate([{ opacity: 1 }, { opacity: 0 }], window);
        });
        p.rest.forEach(function (z) {
          var a = glyphGeist(z, stage);
          a.style.opacity = "0";
          attach(a);
          a.animate([{ opacity: 0 }, { opacity: 1 }],
            { duration: d * 0.5, delay: d * 0.5, easing: "ease-out", fill: "both" });
        });
        // Strokes take the same path as a character without a partner: the
        // old one fades out, the new one fades in. They are not paired, a
        // radical arc and an equals bar have nothing to do with each other.
        striche(src).forEach(function (n) {
          var a = glyphGeist(n, stage);
          attach(a);
          a.animate([{ opacity: 1 }, { opacity: 0 }],
            { duration: d * 0.55, easing: "ease-out", fill: "forwards" });
        });
        striche(dst).forEach(function (n) {
          var a = glyphGeist(n, stage);
          a.style.opacity = "0";
          attach(a);
          a.animate([{ opacity: 0 }, { opacity: 1 }],
            { duration: d * 0.5, delay: d * 0.5, easing: "ease-out", fill: "both" });
        });
      } else {
        var takt2 = { duration: d, easing: EASE, fill: "forwards" };
        // Each copy sits in *its own* box and is moved from there.
        //
        // Previously both sat in the source's box. For the source that is
        // correct, for the target it is not. The rule `.ts-ghost svg` forces
        // the SVG to the full width and height of the copy, so the target
        // was fitted into a foreign aspect ratio; and because an SVG keeps
        // its own ratio while doing so, air remained on two edges. The
        // anisotropic scaling afterward did not undo that. At the end of the
        // flight the drawing therefore stood in different proportions than
        // the real element that took its place a tenth of a second later.
        //
        // Measured in the editorial deck, frame by frame: from 760ms to
        // 840ms nothing moved anymore, the flight had settled. At 920ms then
        // 824 pixels jumped, 302 going backward. That is exactly the jerk
        // you see.
        //
        // Now the target sits in its own box from the start and begins
        // squeezed down onto the source's. It ends at scale(1,1) and is
        // thus pixel for pixel what stands there afterward: both directions
        // 0 instead of 824 and 302.
        var kopie = function (was, kasten) {
          var k = was.cloneNode(true);
          k.className = "ts-ghost";
          k.removeAttribute("data-n");
          k.removeAttribute("data-at");
          k.removeAttribute("data-hold");
          k.style.left = (kasten.left - stage.left) + "px";
          k.style.top = (kasten.top - stage.top) + "px";
          k.style.width = kasten.width + "px";
          k.style.height = kasten.height + "px";
          return k;
        };
        // The ghosts' transform origin sits at top left (see CSS), so the
        // path is simply composed of translation and scaling.
        var hin = function (von, nach) {
          return "translate(" + (nach.left - von.left) + "px," +
                 (nach.top - von.top) + "px) scale(" +
                 (nach.width / von.width) + "," + (nach.height / von.height) + ")";
        };
        var ank2 = kopie(dst, zr);
        ank2.style.opacity = "1";
        attach(ank2);
        ank2.animate([{ transform: hin(zr, qr) },
                      { transform: "translate(0,0) scale(1,1)" }], takt2);

        var ghost = kopie(src, qr);
        ghost.style.opacity = "1";
        attach(ghost);
        ghost.animate([{ transform: "translate(0,0) scale(1,1)" },
                       { transform: hin(qr, zr) }], takt2);
        ghost.animate([{ opacity: 1 }, { opacity: 0 }], window);
      }

      flyTimers.push(setTimeout(function () {
        delete src.dataset.hold;
        delete dst.dataset.hold;
        ghosts.forEach(function (g) { g.remove(); });
      }, d));
    });
    return any;
  }

  // ── Media ─────────────────────────────────────────────────────────────────
  var ticking = [];
  function mediaOn(i) {
    SLIDES[i].querySelectorAll(".ts-video").forEach(function (w) {
      var v = w.querySelector("video");
      if (!v || w.dataset.autoplay === "0") return;
      if (v.paused) { var p = v.play(); if (p && p.catch) p.catch(function () {}); }
    });
    SLIDES[i].querySelectorAll(".ts-flipbook").forEach(function (fb) {
      for (var k = 0; k < ticking.length; k++) if (ticking[k].el === fb) return;
      ticking.push({ el: fb, t0: performance.now(), letztes: -1 });
    });
  }
  function mediaOff(i) {
    SLIDES[i].querySelectorAll("video").forEach(function (v) { v.pause(); });
    ticking = ticking.filter(function (t) { return !SLIDES[i].contains(t.el); });
  }
  // `null` is the wall clock, a number is a pinned time in milliseconds. A
  // flipbook otherwise shows whatever frame the machine happened to reach, and
  // two runs of the same deck never agree on it.
  var PRUEFUHR = null;
  function beat(current) {
    if (PRUEFUHR !== null) current = PRUEFUHR;
    for (var k = 0; k < ticking.length; k++) {
      var t = ticking[k];
      var n = +t.el.dataset.frames, fps = +t.el.dataset.fps || 30;
      if (!n) continue;
      var i;
      if (wenigerBewegung()) {
        // Frozen on one frame. A looping flipbook is the loudest thing this
        // package can put on a slide: it runs from the moment the slide
        // comes up until the moment it goes, and it pulls the eye the whole
        // while, including while someone is talking beside it.
        //
        // Which frame it freezes on is not a matter of taste. A flipbook
        // that does not loop plays once and comes to rest on its last frame,
        // and that resting frame is its finished state; it stays the
        // finished state, only the way there falls away. One that loops or
        // ping-pongs has no rest to come to, and there frame 0 is the right
        // answer twice over: it is the frame Typst put in the box before any
        // clock started, and it is the frame the handout shows on paper.
        //
        // `pingpong` beats `loop` here, exactly as it does below.
        i = (t.el.dataset.pingpong !== "1" && t.el.dataset.loop === "0")
          ? n - 1 : 0;
      } else {
        // With the clock pinned the start time drops out as well. Otherwise the
        // frame would still depend on when the slide was entered.
        i = Math.floor((current - (PRUEFUHR === null ? t.t0 : 0)) / 1000 * fps);
        if (t.el.dataset.pingpong === "1") {
          var p = n > 1 ? 2 * n - 2 : 1;
          var m = i % p;
          i = m < n ? m : p - m;
        } else if (t.el.dataset.loop === "0") { i = Math.min(i, n - 1); }
        else { i = i % n; }
      }
      if (i === t.letztes) continue;
      t.letztes = i;
      var kinder = t.el.children;
      for (var j = 0; j < kinder.length; j++) {
        if (j === i) kinder[j].dataset.on = "1"; else delete kinder[j].dataset.on;
      }
    }
    requestAnimationFrame(beat);
  }
  requestAnimationFrame(beat);

  // ── Bridge ────────────────────────────────────────────────────────────────
  var JOBS = SLIDES.map(function (f) {
    var s = f.querySelector("script.ts-bridge");
    return s ? JSON.parse(s.textContent) : [];
  });
  var bridgeReady = {};

  // Two applets on one slide sharing a name would both receive every job. That
  // happens when the second one is left unnamed and falls back to the default.
  SLIDES.forEach(function (f, i) {
    var seen = {};
    f.querySelectorAll(".ts-bridged").forEach(function (node) {
      var n = node.dataset.bridge;
      if (!n) return;
      if (seen[n]) {
        console.warn("typstage: slide " + (i + 1) + " has two bridged elements"
          + ' named "' + n + '". Both get every job, so give one its own name.');
      }
      seen[n] = 1;
    });
  });

  function drive(i, step, neu) {
    SLIDES[i].querySelectorAll(".ts-bridged").forEach(function (node) {
      var frame = node.querySelector("iframe");
      if (!frame || !frame.contentWindow || frame.dataset.live !== "1") return;
      var name = node.dataset.bridge;
      var jobs = [];
      if (neu) {
        for (var k = 1; k <= step; k++) {
          JOBS[i].forEach(function (j) {
            if (j.t === name && activeAt(j.at, k)) jobs.push(j);
          });
        }
      } else {
        JOBS[i].forEach(function (j) {
          if (j.t === name && activeAt(j.at, step)) jobs.push(j);
        });
      }
      if (!jobs.length && !neu) return;
      var key = i + "|" + step + "|" + (neu ? 1 : 0);
      if (frame.dataset.sync === key) return;
      frame.dataset.sync = key;
      frame.contentWindow.postMessage({ typstage: 1, reset: neu, jobs: jobs }, "*");
    });
  }

  function stopBridges(i) {
    SLIDES[i].querySelectorAll(".ts-bridged iframe").forEach(function (r) {
      r.dataset.sync = "";
      if (r.contentWindow) r.contentWindow.postMessage({ typstage: 1, stop: 1 }, "*");
    });
  }

  addEventListener("message", function (e) {
    var d = e.data;
    if (!d || d.typstage !== 1) return;
    if (d.failed) {
      console.warn("typstage: GeoGebra refused: " + d.failed.join(", "));
      return;
    }
    // An embedded document that can mirror itself reports what became of
    // it after a hand touched it. The speaker view passes that on to the
    // talk, which puts it into its own copy. That is the second way to
    // operate an embed from the view, and the better one wherever it is
    // available: the speaker works on a live applet in front of them
    // instead of aiming at one across the room.
    if (d.spiegel != null && d.stand) {
      if (ROLLE === "speaker") strom("spiegel", { b: d.spiegel, s: d.stand });
      return;
    }
    if (d.ready == null) return;
    var lebt = null;
    document.querySelectorAll(".ts-bridged iframe").forEach(function (r) {
      if (r.contentWindow === e.source) lebt = r;
    });
    if (!lebt) return;
    lebt.dataset.live = "1";
    var wirt = lebt.closest(".ts-el");
    wirt.dataset.bereit = "1";
    // The document says of itself whether it mirrors. Only then does the
    // style sheet hand it the pointer in the speaker view; everything else
    // is served by the route across.
    if (d.spiegel) wirt.dataset.spiegel = "1";
    var st = STEPS[current];
    if (st) drive(st.slide, st.step, true);
  });

  // ── The channel between the windows ───────────────────────────────────────
  //
  // A talk and its speaker view are two windows on the same file.
  // `window.open` sets `window.opener` in the opened window, and
  // `postMessage` carries over this handle in both directions, even from a
  // `file://` page, where `localStorage` is no good: since 68, Firefox gives
  // every local file its own origin, and then neither sees the other's
  // storage.
  //
  // Every message carries `typstage: 1` plus its own `kanal` field. The
  // `typstage` alone is not enough: the bridge to the embedded documents
  // already runs over it (`{typstage: 1, ready: 1}` and their jobs). The two
  // receivers therefore sort each other out by `kanal`: the bridge bails out
  // on `d.ready == null`, this one here on a missing `kanal`.
  //
  // Without a partner, everything here does nothing. A deck that never opens
  // a second window behaves line for line as before.
  var PARTNER = null;   // the other window, once it has checked in
  var KIND = null;      // the handle from window.open, only for finding it again
  var HOERER = Object.create(null);
  var stumm = 0;        // >0 while we are following a remote control

  // A closed window remains lying around as a handle, but it is no longer
  // any good.
  function partner() {
    if (PARTNER) { try { if (PARTNER.closed) PARTNER = null; } catch (x) {} }
    return PARTNER;
  }

  function sende(art, daten) {
    var p = partner();
    if (!p) return false;
    var m = { typstage: 1, kanal: art, deck: DECK };
    if (daten) for (var k in daten) m[k] = daten[k];
    // Under `file://` the origin is "null"; an exact target origin would
    // drop the message. Filtering happens on content instead.
    try { p.postMessage(m, "*"); } catch (x) { return false; }
    return true;
  }

  // For anything added later: a new message kind needs no change to the
  // receiver below, only a `horch("meinding", fn)`.
  function horch(art, fn) { (HOERER[art] || (HOERER[art] = [])).push(fn); }

  // ── A stream instead of individual messages ───────────────────────────────
  //
  // Some things do not arrive every few seconds but at the pace of the
  // mouse: a stroke someone draws in the speaker view is a sequence of
  // points. One message per point would be wasteful, since each one costs
  // the other side its own pass through the receiver, and with the mouse
  // held down that is hundreds.
  //
  // `strom` therefore collects and sends one bundle per frame:
  // `{kanal: art, punkte: [...]}`. The receiver on the other side gets the
  // same kind as with `sende`, just with `punkte` instead of a single value.
  // Collecting only happens when someone is actually listening; and whoever
  // collects in a hidden window gets no frame, hence the cap that sends off
  // a full bundle even without a frame if it has to.
  var STROM = null, stromTakt = 0, STROM_MAX = 128;
  function strom(art, punkt) {
    if (!partner()) return false;
    if (!STROM) STROM = Object.create(null);
    var b = STROM[art] || (STROM[art] = []);
    b.push(punkt);
    if (b.length >= STROM_MAX) { stromAus(); return true; }
    if (!stromTakt) {
      stromTakt = window.requestAnimationFrame
        ? requestAnimationFrame(stromAus) : setTimeout(stromAus, 16);
    }
    return true;
  }
  // A frame still pending while the cap has already emptied finds nothing
  // left and turns right back around. Cancelling it is not worth it.
  function stromAus() {
    stromTakt = 0;
    var s = STROM;
    STROM = null;
    if (!s) return;
    for (var art in s) sende(art, { punkte: s[art] });
  }

  // A step that comes from the other side must not be reported back:
  // otherwise the two windows would send each other the same number back
  // and forth forever. `stumm` silences `melde` for the duration of the
  // jump.
  // Frozen means: the talk accepts the remote step but does not display it.
  // It only remembers where the speaker has moved to in the meantime, and
  // catches up on thawing. Without a speaker window, `FROST` is null and
  // this line costs nothing.
  var FROST = 0, FROST_ZIEL = null;
  function fernGoto(n, instant) {
    if (typeof n !== "number" || isNaN(n) || n === current) return;
    if (FROST) { FROST_ZIEL = n; return; }
    stumm++;
    try { goto(n, instant); } finally { stumm--; }
  }

  // Every step change goes across: the talk reports where it stands, the
  // speaker view requests the step. On the talk side the request is a real
  // change with a transition; the report to the speaker view, by contrast,
  // is a jump without motion, since the stage is covered up there anyway.
  function melde(n) {
    if (stumm) return;
    sende(ROLLE === "speaker" ? "gehe" : "schritt", { n: n });
  }

  // ── Who is on the other side, and are they still the same ────────────────
  //
  // Every window gets an id when it loads. It sits in the reply to `hallo`,
  // and that is how the other side can tell whether the same window is
  // still sitting there or a freshly loaded one. That is the whole
  // difference between "the report is repeating" and "someone over there
  // reloaded", and without it the two would silently drift apart after a
  // reload of the talk window: `window.opener` survives a reload over
  // there, the handle in the opposite direction does not.
  var SITZUNG = String(Date.now()) + "." + Math.floor(Math.random() * 1e6);
  var FERN_SITZUNG = null;   // the id that last came from the other side
  var FRISCH = 1;            // this window has never synced yet
  var LETZTER_SCHLAG = Date.now();   // when anything last arrived at all
  var SICHT_GESENDET = 0;            // when this window last sent its own view command

  // The greeting, i.e. the reply to `hallo`. It repeats at the pace of the
  // heartbeat, so it is only acted on for a new id.
  //
  // Whoever just reloaded adopts the other's state; whoever was already
  // running passes its own on. That way a freshly reloaded talk window
  // finds its way back without the view losing its place, and a freshly
  // opened view shows what actually stands in the hall, instead of
  // claiming "bright and thawed" while it is black there.
  function begruessung(d) {
    // First, and on every beat: whatever the talk itself has decided holds.
    // It is the window that actually shows the view; here there is only the
    // indicator about it. If it lifts black or frost itself, this would
    // otherwise keep saying "frozen", and the keys would be backward: the
    // first press of `b` would switch off something that was not even on
    // anymore, and would freeze the talk again in the process, because both
    // values go together.
    sichtAbgleichen(d.schwarz, d.frost);
    if (d.sitzung === FERN_SITZUNG) return;
    var warFrisch = FRISCH;
    FERN_SITZUNG = d.sitzung;
    FRISCH = 0;
    if (warFrisch) {
      fernGoto(d.n, true);
      sichtUebernehmen(d.schwarz, d.frost);
      return;
    }
    // A new partner gets everything that stands here: the view, the step,
    // and the ink strokes.
    //
    // The view first, and that is not a matter of taste. A freshly loaded
    // talk window is thawed; if `gehe` came before `sicht`, it would carry
    // out the jump before freezing again, and the freeze would silently
    // break on reload. In this order the step lands in `FROST_ZIEL`, where
    // it belongs.
    sichtSenden();
    sende("gehe", { n: current });
    if (TINTE_AN) sende("tintestand", { liste: tinteAbschrift() });
  }

  addEventListener("message", function (e) {
    var d = e.data;
    if (!d || d.typstage !== 1 || !d.kanal) return;
    // Two windows only belong together if they show the same deck. Without
    // this line, a speaker view would happily pair up with a foreign talk:
    // if someone navigates to a different deck in the same tab, the view
    // would then control something it does not even show. Checked before
    // anything else, so that the partner handle is not set either.
    if (d.deck !== DECK) return;
    // Whoever writes is the partner from now on. This carries across a
    // reload: the reloaded window checks in again, and the dead handle
    // simply gets overwritten in the process.
    if (e.source) PARTNER = e.source;
    LETZTER_SCHLAG = Date.now();
    if (d.kanal === "hallo") {
      sende("schritt", { n: current, folien: SLIDES.length,
                         schritte: STEPS.length, rolle: ROLLE,
                         sitzung: SITZUNG,
                         schwarz: document.documentElement.dataset.tsSchwarz ? 1 : 0,
                         frost: FROST });
      // The stock only goes to a freshly loaded counterpart. Otherwise the
      // two would keep pushing the same strokes back and forth at the pace
      // of the heartbeat.
      if (d.frisch && TINTE_AN) sende("tintestand", { liste: tinteAbschrift() });
    } else if (d.kanal === "schritt") {
      // With an id it is a greeting, without one a real step change. The
      // difference matters: blindly following the greeting would mean
      // jumping every second to wherever the talk stands, and that is
      // exactly what is not wanted while frozen.
      if (d.sitzung !== undefined) begruessung(d);
      else fernGoto(d.n, true);
    } else if (d.kanal === "gehe") {
      fernGoto(d.n, false);
    }
    var hs = HOERER[d.kanal];
    if (hs) for (var i = 0; i < hs.length; i++) hs[i](d, e);
  });

  // The opened window checks in with its opener, and does so permanently.
  //
  // Once was not enough. `window.opener` survives a reload of the talk
  // window, the handle to it does not: after a reload, the talk no longer
  // knows of anyone, and because it never checks in on its own, the two
  // would stay separated forever. One message per second brings them back
  // together and costs nothing.
  function anmelden() {
    if (ROLLE !== "speaker") return false;
    var o = null;
    // First the window that opened this view itself: that is the only one
    // that exists once the talk has been closed in the meantime.
    try { if (KIND && !KIND.closed) o = KIND; } catch (x) {}
    if (!o) { try { o = window.opener; } catch (x) {} }
    if (!o) return false;
    try { if (o.closed) return false; } catch (x) {}
    PARTNER = o;
    return sende("hallo", { rolle: ROLLE, frisch: FRISCH ? 1 : 0 });
  }
  function anmeldeSchleife() {
    if (ROLLE !== "speaker") return;
    anmelden();
    setInterval(anmelden, 1000);
  }

  // The key opens the second window. Without a user gesture, `window.open`
  // would fall victim to the popup blocker; the keypress is the gesture.
  // The name in the second argument makes sure a second press hits the same
  // window instead of opening a third.
  function oeffneSprecher() {
    if (ROLLE === "speaker") {
      // The other way round: from the speaker view the key brings the talk
      // forward, instead of opening a speaker view of the speaker view.
      var o = partner();
      if (o) { try { o.focus(); } catch (x) {} return o; }
      try { if (KIND && !KIND.closed) { KIND.focus(); return KIND; } } catch (y) {}
      // If the talk is closed, the same key gets a new one. Otherwise the
      // view would page and draw into the void forever, and no one could
      // reach the hall anymore. The new window checks in, gets the running
      // step along with the strokes via the greeting, and thus stands where
      // the view stands.
      KIND = window.open(location.href.split("#")[0], "typstage-stage",
                        "width=1280,height=800");
      return KIND;
    }
    if (KIND) {
      try { if (!KIND.closed) { KIND.focus(); return KIND; } } catch (x) {}
    }
    var ziel = location.href.split("#")[0] + "#speaker";
    KIND = window.open(ziel, "typstage-speaker",
                       "width=1120,height=760,menubar=no,toolbar=no");
    return KIND;
  }

  // ── Strokes on the slide ───────────────────────────────────────────────────
  //
  // Drawing happens in the speaker view, seeing it happens in the talk: the
  // speaker has mouse and trackpad in front of them, not the canvas. So the
  // computation happens in fractions of the stage (0 to 1) instead of
  // pixels. Two windows are rarely the same size; a pixel value would sit
  // in a different spot over there, a fraction sits in the same one.
  //
  // The strokes stick to their slide. `TINTE[folie]` is the list of its
  // strokes, and the drawing layer always only holds those of the running
  // slide. Whoever pages forward and comes back finds them again.
  //
  // As long as no one has drawn, `TINTE_AN` is null and this whole section
  // does not touch anything: a deck without a speaker window notices
  // nothing of it.
  var TINTE = [], TINTE_AN = 0, TINTE_SVG = null, TINTE_FOLIE = -1;
  var FARBEN = ["#eb5e28", "#ffd166", "#4cc9f0", "#f4f4f5"];
  var STRICH_PT = 3.2;    // stroke width in points of the stage, scaled with it

  function tinteListe(i) { return TINTE[i] || (TINTE[i] = []); }

  // An SVG sized to the stage. The viewBox is the slide format itself, so
  // aspect ratio and stroke width work out without further calculation, and
  // the fractions are simply multiplied by width and height.
  function tinteEbene() {
    if (TINTE_SVG && TINTE_SVG.parentNode === INK) return TINTE_SVG;
    while (INK.firstChild) INK.removeChild(INK.firstChild);
    TINTE_SVG = document.createElementNS(NS, "svg");
    TINTE_SVG.setAttribute("viewBox", "0 0 " + CFG.width + " " + CFG.height);
    INK.appendChild(TINTE_SVG);
    return TINTE_SVG;
  }

  function tintePunkte(s) {
    var out = [];
    for (var i = 0; i < s.punkte.length; i++) {
      out.push((s.punkte[i].x * CFG.width).toFixed(1) + "," +
               (s.punkte[i].y * CFG.height).toFixed(1));
    }
    return out.join(" ");
  }

  // A stroke gets its line element once and keeps it. Exactly one attribute
  // gets updated per bundle. Creating a new element per point on the
  // receiving side would undo the bundling done at the sender.
  function tinteLinie(s, svg) {
    if (s.knoten && s.knoten.parentNode === svg) return s.knoten;
    var n = document.createElementNS(NS, "polyline");
    n.setAttribute("fill", "none");
    n.setAttribute("stroke", s.farbe);
    n.setAttribute("stroke-width", STRICH_PT);
    n.setAttribute("stroke-linecap", "round");
    n.setAttribute("stroke-linejoin", "round");
    svg.appendChild(n);
    s.knoten = n;
    return n;
  }

  // The strokes of the running slide into the layer, everything else out.
  // If the right slide is already sitting there, there is nothing to do.
  function tinteStand() {
    if (!TINTE_AN || !INK || current < 0 || !STEPS[current]) return;
    var si = STEPS[current].slide;
    if (si === TINTE_FOLIE && TINTE_SVG && TINTE_SVG.parentNode === INK) return;
    TINTE_FOLIE = si;
    TINTE_SVG = null;
    var svg = tinteEbene();
    var liste = tinteListe(si);
    for (var i = 0; i < liste.length; i++) {
      liste[i].knoten = null;
      tinteLinie(liste[i], svg).setAttribute("points", tintePunkte(liste[i]));
    }
  }
  function tinteNeu() { TINTE_FOLIE = -1; tinteStand(); }

  function tinteFolie() {
    return (current >= 0 && STEPS[current]) ? STEPS[current].slide : -1;
  }

  // A single event into the stock: either a point, or a command. Both run
  // through the same stream so the order holds. A `sende` alongside the
  // stream would arrive before the still-pending bundle, and a delete would
  // overtake the points it was supposed to delete.
  function tinteNimm(ev, schmutz) {
    if (!ev) return;
    TINTE_AN = 1;
    if (ev.b === "loesch") { TINTE[ev.s] = []; tinteNeu(); return; }
    if (ev.b === "weg") {
      var l = TINTE[ev.s];
      if (l && l.length) l.pop();
      tinteNeu();
      return;
    }
    if (typeof ev.x !== "number" || typeof ev.y !== "number") return;
    var liste = tinteListe(ev.s);
    var s = liste[liste.length - 1];
    // The running number separates the strokes: a new number means the
    // mouse was released in between.
    if (!s || s.n !== ev.n) {
      s = { n: ev.n, farbe: ev.f || FARBEN[0], punkte: [], knoten: null };
      liste.push(s);
    }
    s.punkte.push({ x: ev.x, y: ev.y });
    if (ev.s === tinteFolie() && schmutz.indexOf(s) < 0) schmutz.push(s);
  }

  // A whole bundle at once, and only drawn afterward.
  function tinteBuendel(liste) {
    if (!INK || !liste || !liste.length) return;
    var schmutz = [];
    for (var i = 0; i < liste.length; i++) tinteNimm(liste[i], schmutz);
    tinteStand();
    var svg = tinteEbene();
    for (var k = 0; k < schmutz.length; k++) {
      tinteLinie(schmutz[k], svg).setAttribute("points", tintePunkte(schmutz[k]));
    }
  }
  // The talk listens. The speaker view gets none of it, it only sends;
  // hence there is no feedback loop.
  horch("tinte", function (d) { tinteBuendel(d.punkte); });

  // What already stands on the slides goes across once at check-in.
  // Otherwise a freshly loaded speaker view would see empty slides while
  // the strokes from before still stand in the hall, and the speaker would
  // be erasing at something they no longer have in front of them. The
  // nodes are left behind in the process: a DOM element cannot be sent.
  function tinteAbschrift() {
    var out = [];
    for (var i = 0; i < TINTE.length; i++) {
      if (!TINTE[i]) continue;
      for (var k = 0; k < TINTE[i].length; k++) {
        out.push({ s: i, n: TINTE[i][k].n, f: TINTE[i][k].farbe,
                   p: TINTE[i][k].punkte });
      }
    }
    return out;
  }
  function tinteEinlesen(liste) {
    if (!liste) return;
    TINTE = [];
    for (var i = 0; i < liste.length; i++) {
      var q = liste[i];
      tinteListe(q.s).push({ n: q.n, farbe: q.f, punkte: q.p, knoten: null });
      // The next stroke of our own must get a number not yet assigned on
      // the other side, otherwise it would grow onto a foreign one.
      if (q.n >= STRICH_NR) STRICH_NR = q.n + 1;
      TINTE_AN = 1;
    }
    tinteNeu();
  }
  horch("tintestand", function (d) { tinteEinlesen(d.liste); });

  // ── The pointer through to the embed ──────────────────────────────────────
  //
  // Drawing is one of two things one wants to do on a running slide. The
  // other is to operate what is embedded on it: turn a GeoGebra
  // construction, press a button in an embedded page. Both want the same
  // pointer, so a mode decides which of the two gets it. `m` switches.
  //
  // In pointer mode the position travels the same way the strokes do, in
  // fractions of the stage, and the talk window dispatches the matching
  // event inside its own frame at that spot. The speaker's own copy of the
  // frame gets the same event at the same fraction, so both sides see the
  // same gesture and the speaker is not operating something blind.
  //
  // This only reaches a frame this window may read into, which means an
  // `embed(html:)` and thus a `srcdoc`. A foreign address is another
  // origin, and there `postMessage` is the only way in; the embedded
  // document has to answer it itself. That is what `data-spiegel` is for
  // further down.
  var MODUS = "stift";
  var ZIEL_FERN = null;    // what took the press, so a drag stays with it

  // Which frame lies under a point of the stage. Not `elementFromPoint`:
  // in the speaker view the embeds are switched off for hit testing, and
  // there they would never be found. Rectangles hold in both windows.
  function zeigerRahmen(cx, cy) {
    var st = STEPS[current];
    if (!st || !SLIDES[st.slide]) return null;
    var treffer = null;
    SLIDES[st.slide].querySelectorAll(".ts-el iframe").forEach(function (f) {
      var el = f.closest(".ts-el");
      if (el) {
        var cs = getComputedStyle(el);
        // Something that is not on the slide yet must not catch the
        // pointer either, otherwise a click would land on a frame the hall
        // cannot even see.
        if (cs.visibility === "hidden" || +cs.opacity < 0.05) return;
      }
      var r = f.getBoundingClientRect();
      if (!r.width || !r.height) return;
      if (cx >= r.left && cx <= r.right && cy >= r.top && cy <= r.bottom) treffer = f;
    });
    return treffer;
  }

  // One event into the frame. The constructors are taken from the frame's
  // own window, so an `instanceof` inside it says yes.
  function zeigerSchuss(win, ziel, typ, ix, iy, knopf, dy, klick) {
    var basis = { bubbles: true, cancelable: true, composed: true, view: win,
                  clientX: ix, clientY: iy, screenX: ix, screenY: iy,
                  button: 0, buttons: knopf };
    if (typ === "wheel") {
      if (!win.WheelEvent) return;
      var w = {}; for (var q in basis) w[q] = basis[q];
      w.deltaY = dy; w.deltaMode = 0;
      ziel.dispatchEvent(new win.WheelEvent("wheel", w));
      return;
    }
    // First the pointer event, then the mouse event, exactly as the
    // browser does it. And as the browser does it: whoever cancels the
    // pointer event gets no mouse event afterward. Without this line, a
    // page that listens to both would handle every gesture twice.
    if (win.PointerEvent) {
      var p = {}; for (var k in basis) p[k] = basis[k];
      p.pointerId = 1; p.pointerType = "mouse"; p.isPrimary = true;
      p.width = 1; p.height = 1; p.pressure = knopf ? 0.5 : 0;
      if (!ziel.dispatchEvent(new win.PointerEvent("pointer" + typ, p))) return;
    }
    if (!win.MouseEvent) return;
    ziel.dispatchEvent(new win.MouseEvent("mouse" + typ, basis));
    // A click is only a click if press and release met the same element.
    if (typ === "up" && klick) ziel.dispatchEvent(new win.MouseEvent("click", basis));
  }

  function zeigerZustellen(ev) {
    if (!B || !ev || typeof ev.x !== "number") return;
    var r = B.getBoundingClientRect();
    if (!r.width || !r.height) return;
    var cx = r.left + ev.x * r.width, cy = r.top + ev.y * r.height;
    var f = zeigerRahmen(cx, cy);
    if (!f) { if (ev.t === "up") ZIEL_FERN = null; return; }
    var doc = null, win = null;
    try { doc = f.contentDocument; win = f.contentWindow; } catch (x) {}
    if (!doc || !win) return;
    // The frame is spanned in slide units and zoomed onto the stage. Its
    // rectangle is therefore the size on screen, while inside it counts
    // unzoomed. Dividing by the zoom is the whole conversion.
    var fr = f.getBoundingClientRect();
    var z = parseFloat(f.style.zoom) || 1;
    var ix = (cx - fr.left) / z, iy = (cy - fr.top) / z;
    var unten = null;
    try { unten = doc.elementFromPoint(ix, iy); } catch (y) {}
    // While the button is down, everything goes to whoever took the press,
    // even if the pointer has long since left it. That is what makes
    // dragging a point work at all.
    var ziel = (ev.t !== "down" && ZIEL_FERN && ZIEL_FERN.isConnected)
      ? ZIEL_FERN : unten;
    if (!ziel) return;
    if (ev.t === "down") ZIEL_FERN = ziel;
    zeigerSchuss(win, ziel, ev.t, ix, iy, ev.k || 0, ev.d || 0,
                 ev.t === "up" && unten === ZIEL_FERN);
    if (ev.t === "up") ZIEL_FERN = null;
  }

  function zeigerBuendel(liste) {
    if (!liste) return;
    for (var i = 0; i < liste.length; i++) zeigerZustellen(liste[i]);
  }
  // At ourselves first, then across, and through the stream so that the
  // order of press, drag and release survives the crossing.
  function zeigerSenden(ev) {
    zeigerZustellen(ev);
    strom("zeiger", ev);
  }
  horch("zeiger", function (d) { zeigerBuendel(d.punkte); });

  // The counterpart in the talk window: what came from the view goes into
  // the frame of the same name. Only on the running slide, since only that
  // one is visible, and a state for a slide long since paged past would
  // land in an applet that is reset from the base anyway on the next step.
  horch("spiegel", function (d) {
    if (ROLLE === "speaker" || !d.punkte) return;
    var st = STEPS[current];
    if (!st) return;
    for (var i = 0; i < d.punkte.length; i++) {
      var p = d.punkte[i];
      SLIDES[st.slide].querySelectorAll(".ts-bridged").forEach(function (node) {
        if (node.dataset.bridge !== p.b) return;
        var f = node.querySelector("iframe");
        if (!f || !f.contentWindow || f.dataset.live !== "1") return;
        f.contentWindow.postMessage({ typstage: 1, spiegel: 1, stand: p.s }, "*");
      });
    }
  });

  // ── Talk window: black ────────────────────────────────────────────────────
  //
  // pdfpc separates two things, and that is worth adopting: *black* makes
  // the hall dark, *freeze* leaves the picture standing while the speaker
  // already keeps paging in their own view. The first hangs off an
  // attribute on the root element and is pure presentation; the second
  // sits inside `fernGoto`, because that is where the remote step arrives.
  var gehaltene = [];
  function schwarzMedien(an) {
    var st = STEPS[current];
    if (!st) return;
    if (an) {
      gehaltene = [];
      SLIDES[st.slide].querySelectorAll("video").forEach(function (v) {
        if (!v.paused) { gehaltene.push(v); v.pause(); }
      });
      return;
    }
    // Only restart what was running before: a video the speaker had paused
    // by hand stays paused.
    gehaltene.forEach(function (v) {
      var p = v.play(); if (p && p.catch) p.catch(function () {});
    });
    gehaltene = [];
  }
  function auftauen() {
    FROST = 0;
    // On thawing, the talk catches up on what it missed.
    if (FROST_ZIEL != null) { var z = FROST_ZIEL; FROST_ZIEL = null; fernGoto(z, false); }
  }
  function sichtLoesen() {
    if (document.documentElement.dataset.tsSchwarz) {
      delete document.documentElement.dataset.tsSchwarz;
      schwarzMedien(false);
    }
    if (FROST) auftauen();
    sichtMerken();
  }

  // A reload of the talk window used to let the hall go bright for the
  // duration of loading, until the next heartbeat brought the black back:
  // a visible flash onto a slide no one is supposed to see. `sessionStorage`
  // belongs to exactly this one tab and survives exactly its reload,
  // nothing more is asked of it. The channel remains `postMessage`; this
  // here is only a memory across the load, and if it fails, everything is
  // as before.
  function sichtMerken() {
    try {
      sessionStorage.setItem("ts-sicht:" + DECK,
        (document.documentElement.dataset.tsSchwarz ? "1" : "0") + (FROST ? "1" : "0"));
    } catch (x) {}
  }
  function sichtErinnern() {
    if (ROLLE === "speaker") return;
    var alt = null;
    try { alt = sessionStorage.getItem("ts-sicht:" + DECK); } catch (x) { return; }
    if (!alt || alt === "00") return;
    if (alt.charAt(0) === "1") {
      document.documentElement.dataset.tsSchwarz = "1";
      schwarzMedien(true);
    }
    if (alt.charAt(1) === "1") FROST = 1;
    // The guard lifts that again right away if no one is there anymore: a
    // memory without a partner is exactly the case it was built for.
    wacheAn();
  }

  // A hall that stays black because the window was closed with a keypress
  // is the worst thing this view can cause: in the talk window there is no
  // key against it, and there should not be one either, because a deck
  // without a speaker view must not gain a new dependency on one. If the
  // heartbeat stays absent or the partner is gone, the talk lifts black and
  // frost on its own. The guard only runs once either one is on, and stops
  // again as soon as both are off.
  var WACHE = 0, WACHE_SCHLAG = 0;
  function wacheAn() {
    if (WACHE) return;
    WACHE_SCHLAG = Date.now();
    WACHE = setInterval(function () {
      var jetzt = Date.now();
      var eigenerVerzug = jetzt - WACHE_SCHLAG;
      WACHE_SCHLAG = jetzt;
      if (!FROST && !document.documentElement.dataset.tsSchwarz) {
        clearInterval(WACHE); WACHE = 0; return;
      }
      // What is measured is the partner, not the clock. `closed` on the
      // window handle is exactly that signal: it is synchronous, it does
      // not lie, and it is one of the few properties that can be read even
      // across origin boundaries. That makes it work in the case where
      // Firefox gives every local file its own origin.
      if (!partner()) { sichtLoesen(); return; }
      // If this thread itself stalled, a stale `LETZTER_SCHLAG` says
      // nothing about the partner: its messages are then still sitting in
      // the queue and will be delivered momentarily. Whoever confuses that
      // would lift the freeze because this window itself was busy for a
      // moment. So a delayed beat of our own resets the deadline instead.
      if (eigenerVerzug > 2500) { LETZTER_SCHLAG = jetzt; return; }
      // What remains is a coarse net for the one case `closed` does not
      // know: the window stands open but meanwhile carries a different
      // page. One minute, so a mere stall does not fall into it.
      if (jetzt - LETZTER_SCHLAG > 60000) sichtLoesen();
    }, 1000);
  }

  if (ROLLE !== "speaker") horch("sicht", function (d) {
    if (d.schwarz != null) {
      if (d.schwarz) document.documentElement.dataset.tsSchwarz = "1";
      else delete document.documentElement.dataset.tsSchwarz;
      schwarzMedien(!!d.schwarz);
    }
    if (d.frost != null) {
      if (d.frost) FROST = 1; else if (FROST) auftauen();
    }
    if (FROST || document.documentElement.dataset.tsSchwarz) wacheAn();
    sichtMerken();
  });

  // ── Speaker view: the building blocks ─────────────────────────────────────

  // A slide's note, empty if there is none. It sits as `data-note` on the
  // overlay layer, because that was set in the context of the slide.
  function notiz(i) {
    var f = SLIDES[i];
    return (f && attr(f, "note")) || "";
  }

  // What the next keypress would do: another step on the same slide, a new
  // slide, or nothing more. `STEPS` knows this, because it holds each
  // step's slide.
  function weiter(n) {
    if (n == null) n = current;
    var hier = STEPS[n], nach = STEPS[n + 1];
    if (!nach) {
      return { art: "ende", index: n, slide: hier ? hier.slide : 0,
               step: hier ? hier.step : 1 };
    }
    return { art: (hier && nach.slide === hier.slide) ? "schritt" : "folie",
             index: n + 1, slide: nach.slide, step: nach.step };
  }

  // A slide as a still image, and specifically at a *particular* step.
  // `miniatur` cannot do that: there only the background is copied, and the
  // faded-in parts sit as sprites in the overlay layer. For the preview
  // that is the whole difference, because the question is not "what does
  // the next slide look like" but "what stands there after the next
  // keypress", and that is often the same slide with one more part.
  //
  // `stelle` first, because the sprites get their places from the marks in
  // the background. A slide that has never been on has none yet.
  function schrittBild(si, schritt) {
    var f = SLIDES[si];
    var m = document.createElement("div");
    m.className = "ts-mini";
    if (!f) return m;
    stelle(si);
    var cp = f.querySelector(".ts-chromep");
    m.innerHTML = f.querySelector(".ts-bg").innerHTML + (cp ? cp.innerHTML : "");
    var ov = f.querySelector(".ts-ov");
    if (ov) {
      // Read off the originals, applied to the copies further down. A nested
      // element inherits `data-after` from its host, and that lookup needs the
      // slide around it, which the detached copy no longer has.
      var stufen = [];
      ov.querySelectorAll(".ts-el").forEach(function (el) {
        stufen.push(zustand(el, schritt));
      });
      var k = ov.cloneNode(true);
      // A cloned iframe would load the foreign document a second time, a
      // cloned video would play sound a second time. Neither belongs in a
      // still image.
      k.querySelectorAll("iframe,video,audio").forEach(function (x) { x.remove(); });
      // Und die Ziffern einer adaptiven Gruppe. Sie stehen als Geschwister
      // neben ihren Punkten und werden deshalb mitgeklont -- in der Vorschau
      // schweben sie dann ohne den Text, zu dem sie gehoeren. Waehlen kann man
      // dort ohnehin nicht.
      k.querySelectorAll(".ts-ad-nr").forEach(function (x) { x.remove(); });
      k.querySelectorAll(".ts-el").forEach(function (el, i) {
        el.removeAttribute("data-hold");
        // The preview answers "what stands there after the next keypress",
        // so it has to show the muted state too: otherwise a point that only
        // steps back would look to the speaker as if it had gone.
        var z = stufen[i];
        el.style.opacity = z === 2 ? "1" : (z === 1 ? String(DIM) : "0");
      });
      m.appendChild(k);
    }
    return m;
  }

  // ── Speaker view: the view ────────────────────────────────────────────────
  //
  // It is built at runtime and not written into the file: the same file
  // carries both views, and the talk window is not supposed to notice
  // anything of this one.
  //
  // The running slide is not rebuilt. It is this window's real stage,
  // which runs along anyway; it is only moved to its place instead of
  // being covered up. That does not only save the rebuild: it thereby
  // shows the running step along with transitions, and the drawing layer
  // already sits over it without any extra work, in exactly the same
  // geometry as on the other side.
  var W = CFG.words || {};
  var SPW = W.sp || {};
  function wort(k, r) { return SPW[k] || r; }

  var PLATZ = null;        // the box in the frame the stage moves to
  var LEIB = null;         // its grid, whose columns depend on the window
  var ELN = {};            // the displays, looked up once
  var gebaut = 0;
  var UHR_START = 0;       // since when counting runs, 0 = not started yet
  var ZIEL_MIN = 0;        // planned duration in minutes, 0 = no plan
  var NOTIZ_PX = 21;
  var SCHWARZ = 0, EIS = 0;
  var VORSCHAU = "";
  // The running number starts randomly. After a reload of the speaker
  // view, both sides would otherwise start over at one, and the first new
  // stroke would grow onto the last old one instead of being its own. If
  // the transcript comes from the other side, the number gets bumped up
  // anyway; without a partner, chance carries it.
  var STRICH_NR = Math.floor(Math.random() * 1e6), MALT = 0, FARBE = 0, LETZT = null;
  // `OFFEN` is the held-back first point, `GESETZT` remembers whether
  // anything of the running stroke has already gone out, `DRAUSSEN` whether
  // the pointer currently stands beside the slide.
  var OFFEN = null, GESETZT = 0, DRAUSSEN = 0;
  // `ZEIGT` is the same for pointer mode: the button is down and the
  // gesture belongs to the embed.
  var ZEIGT = 0;

  function bau(tag, klasse, wohin) {
    var e = document.createElement(tag);
    if (klasse) e.className = klasse;
    if (wohin) wohin.appendChild(e);
    return e;
  }
  function feld(wohin, name) {
    var d = bau("div", "ts-sp-feld", wohin);
    bau("div", "ts-sp-marke", d).textContent = name;
    return bau("div", "ts-sp-wert", d);
  }
  // The one large number of a group. It carries the hierarchy, so that six
  // equally loud columns do not stand side by side and the eye has to find
  // its own anchor.
  function haupt(wohin, name) {
    var d = bau("div", "ts-sp-haupt", wohin);
    bau("div", "ts-sp-marke", d).textContent = name;
    return bau("div", "ts-sp-gross", d);
  }
  // A quiet value: number first, word small behind it. Read side by side
  // in one line like "12:56 remaining".
  function neben(wohin, name) {
    var sp = bau("span", "ts-sp-paar", wohin);
    var w = bau("b", "ts-sp-klein", sp);
    bau("i", "ts-sp-wort", sp).textContent = name;
    return w;
  }
  function zwei(z) { return (z < 10 ? "0" : "") + z; }
  function mmss(sek) {
    var v = sek < 0 ? "-" : "";
    sek = Math.abs(Math.round(sek));
    var h = Math.floor(sek / 3600), m = Math.floor(sek / 60) % 60;
    return v + (h ? h + ":" + zwei(m) : String(m)) + ":" + zwei(sek % 60);
  }

  // The clock runs from the first keypress, not from loading: whoever
  // opens the view early and is still talking to the hall does not want a
  // wrong number in front of them.
  function uhrAn() { if (!UHR_START) UHR_START = Date.now(); }

  function lageZeigen() {
    if (!ELN.lage) return;
    while (ELN.lage.firstChild) ELN.lage.removeChild(ELN.lage.firstChild);
    if (GETRENNT) bau("span", "ts-sp-weg", ELN.lage).textContent =
      wort("lost", "no talk window");
    if (SCHWARZ) bau("span", "", ELN.lage).textContent = wort("black", "black");
    if (EIS) bau("span", "ts-sp-eis", ELN.lage).textContent = wort("frozen", "frozen");
  }

  // If no one on the other side answers anymore, that has to be visible.
  // Otherwise the speaker keeps paging into a canvas that has long since
  // stopped following them: the window may be closed, carry a different
  // deck, or the machine at the projector may have hung. Five seconds, so
  // that a single dropped heartbeat reports nothing.
  var GETRENNT = 0;
  function verbindungStand() {
    if (ROLLE !== "speaker") return;
    var weg = (!partner() || Date.now() - LETZTER_SCHLAG > 5000) ? 1 : 0;
    if (weg === GETRENNT) return;
    GETRENNT = weg;
    lageZeigen();
  }
  function sichtSenden() {
    if (ROLLE !== "speaker") return;
    SICHT_GESENDET = Date.now();
    sende("sicht", { schwarz: SCHWARZ, frost: EIS });
    lageZeigen();
  }
  // What holds on the other side also holds here, continuously and not
  // only at the handshake. A reply sent off before our own keypress knows
  // nothing of it yet; shortly after a command of our own, our own value
  // therefore wins, and the next beat confirms it anyway.
  function sichtAbgleichen(schwarz, frost) {
    if (ROLLE !== "speaker" || schwarz == null) return;
    if (Date.now() - SICHT_GESENDET < 1500) return;
    var s = schwarz ? 1 : 0, f = frost ? 1 : 0;
    if (s === SCHWARZ && f === EIS) return;
    SCHWARZ = s; EIS = f;
    lageZeigen();
  }
  // What holds on the other side holds here. A freshly opened view would
  // otherwise claim "bright and thawed" while the hall is black, and the
  // first press of `b` would make it worse instead of better.
  function sichtUebernehmen(schwarz, frost) {
    if (ROLLE !== "speaker") return;
    SCHWARZ = schwarz ? 1 : 0;
    EIS = frost ? 1 : 0;
    lageZeigen();
  }

  function tinteSenden(ev) {
    tinteBuendel([ev]);   // at ourselves first, then across
    strom("tinte", ev);
  }

  function sprecherAufbau() {
    if (ROLLE !== "speaker" || !SPRECHERBOX) return;

    // The head carries two groups: the time on the left, the position in
    // the talk on the right. Previously six equally ranked columns stood
    // side by side, all crowded to the left, with space left unused on the
    // right. Now each group has one large number, everything else stands
    // small beside it, and the two groups sit at the two edges.
    var kopf = bau("div", "ts-sp-kopf", SPRECHERBOX);
    var gZeit = bau("div", "ts-sp-gruppe", kopf);
    ELN.zeit = haupt(gZeit, wort("elapsed", "elapsed"));
    var zeile = bau("div", "ts-sp-neben", gZeit);
    ELN.uhr = neben(zeile, wort("clock", "clock"));
    var zf = bau("span", "ts-sp-paar", zeile);
    var inp = document.createElement("input");
    inp.type = "number"; inp.min = "0"; inp.step = "1";
    inp.className = "ts-sp-ziel"; inp.id = "ts-sp-ziel";
    zf.appendChild(inp);
    bau("i", "ts-sp-wort", zf).textContent = wort("target", "target (min)");
    inp.addEventListener("input", function () {
      ZIEL_MIN = Math.max(0, +inp.value || 0);
      sprecherUhr();
    });
    // Without this way out, the field would be a trap: `tippt` keeps the
    // arrow keys from paging, and without a mouse there would be no way
    // out. Enter takes the value, Escape leaves it standing too; both give
    // the keyboard back. `stopPropagation`, so Escape does not also pop
    // open the overview on the side.
    inp.addEventListener("keydown", function (ev) {
      if (ev.key !== "Enter" && ev.key !== "Escape") return;
      inp.blur();
      ev.preventDefault();
      ev.stopPropagation();
    });
    ELN.ziel = inp;
    ELN.rest = neben(zeile, wort("left", "remaining"));
    ELN.takt = neben(zeile, wort("pace", "pace"));
    // Without a target duration there is neither a remainder nor a plan.
    // Instead of showing a lone dot beside a loud label twice over, both
    // pairs disappear until a duration is set. That is half of what made
    // the head look cluttered.
    ELN.restPaar = ELN.rest.parentNode;
    ELN.taktPaar = ELN.takt.parentNode;

    var gOrt = bau("div", "ts-sp-gruppe ts-sp-rechts", kopf);
    ELN.fort = haupt(gOrt, wort("slide", "slide"));
    var zeile2 = bau("div", "ts-sp-neben", gOrt);
    ELN.fortSchritt = neben(zeile2, wort("step", "step"));
    // A bar says without words where things stand. It is the second means
    // of hierarchy alongside font size and needs no label.
    ELN.balken = bau("i", "", bau("div", "ts-sp-balken", gOrt));

    // The body: the running slide on the left, preview and note on the right.
    LEIB = bau("div", "ts-sp-leib", SPRECHERBOX);
    PLATZ = bau("div", "ts-sp-platz", LEIB);
    var vor = bau("div", "ts-sp-vor", LEIB);
    ELN.vorMarke = bau("div", "ts-sp-marke", vor);
    ELN.vorBild = bau("div", "ts-sp-vorbild", vor);
    var nk = bau("div", "ts-sp-notizkasten", LEIB);
    bau("div", "ts-sp-marke", nk).textContent = wort("note", "note");
    ELN.notizKasten = nk;
    ELN.notiz = bau("div", "ts-sp-notiz", nk);
    notizNachFenster();
    ELN.notiz.addEventListener("scroll", notizStand);

    // The foot: colors, state, key help.
    var fuss = bau("div", "ts-sp-fuss", SPRECHERBOX);
    var stift = bau("div", "ts-sp-stift", fuss);
    // The label is the switch. Whoever reads what is on can also click it
    // and does not have to know the key first.
    var um = bau("button", "ts-sp-modus", stift);
    um.type = "button";
    um.addEventListener("click", modusUm);
    ELN.modus = um;
    ELN.stiftKasten = stift;
    ELN.tupf = [];
    FARBEN.forEach(function (f, i) {
      var t = bau("button", "ts-sp-tupf", stift);
      t.type = "button";
      t.style.background = f;
      t.addEventListener("click", function () { farbeSetzen(i); });
      ELN.tupf.push(t);
    });
    ELN.lage = bau("div", "ts-sp-lage", fuss);
    ELN.hilfe = bau("div", "ts-sp-hilfe", fuss);
    ELN.hilfe.textContent = W.helpSpeakerShort || W.helpSpeaker || W.help || "";

    // The sound belongs in the hall, not at the speaker's seat: the stage
    // runs along here in full, video included. Seeing it is desired,
    // hearing it twice is not.
    document.querySelectorAll("video,audio").forEach(function (v) { v.muted = true; });

    tasten();
    zeichnen();
    farbeSetzen(0);
    modusSetzen("stift");
    gebaut = 1;
    document.documentElement.dataset.tsFertig = "1";

    // The clock runs as soon as something moves on the other side, not
    // already when the talk merely reports where it stands. This report is
    // the reply to the check-in, and the check-in repeats until it
    // arrives: so what is counted is not how often a report came in, but
    // whether it carries a different number than the previous one.
    var fern = null;
    horch("schritt", function (d) {
      if (d.sitzung !== undefined) return;   // a greeting, not a step
      if (fern !== null && fern !== d.n) uhrAn();
      fern = d.n;
    });

    setInterval(sprecherUhr, 250);
    sprecherStand();
    sprecherUhr();
    fit();
  }

  // Pen or pointer. Everything that hangs off it is one attribute on the
  // root element, so the look follows without a second place to keep in
  // step: in pointer mode the colour swatches step back, and an embed that
  // mirrors itself gets the pointer locally (see the style sheet).
  function modusSetzen(m) {
    MODUS = (m === "zeiger") ? "zeiger" : "stift";
    document.documentElement.dataset.tsModus = MODUS;
    // A half-drawn stroke and a held press must not survive the switch.
    MALT = 0; ZEIGT = 0; LETZT = null; OFFEN = null; GESETZT = 0;
    if (ELN.stiftKasten) ELN.stiftKasten.dataset.modus = MODUS;
    if (!ELN.modus) return;
    ELN.modus.textContent = MODUS === "zeiger"
      ? wort("pointer", "pointer") : wort("pen", "pen");
    ELN.modus.dataset.modus = MODUS;
  }
  function modusUm() { modusSetzen(MODUS === "stift" ? "zeiger" : "stift"); }

  function farbeSetzen(i) {
    FARBE = i % FARBEN.length;
    if (!ELN.tupf) return;
    for (var k = 0; k < ELN.tupf.length; k++) {
      if (k === FARBE) ELN.tupf[k].dataset.an = "1";
      else delete ELN.tupf[k].dataset.an;
    }
  }

  // As long as no one has chosen the size by hand, it follows the window:
  // 21px is right on a large screen and too big in a small window, where
  // only four lines would remain. The window also opens small and is often
  // only resized afterward. A press of + or - ends this following, because
  // from then on what the speaker wants applies.
  var NOTIZ_HAND = 0;
  function notizNachFenster() {
    if (NOTIZ_HAND || !ELN.notiz) return;
    var neu = Math.max(15, Math.min(24, Math.round(innerHeight / 34)));
    if (neu === NOTIZ_PX) return;
    NOTIZ_PX = neu;
    ELN.notiz.style.fontSize = NOTIZ_PX + "px";
  }
  function notizGroesse(d) {
    NOTIZ_HAND = 1;
    NOTIZ_PX = Math.max(12, Math.min(64, NOTIZ_PX + d));
    if (ELN.notiz) ELN.notiz.style.fontSize = NOTIZ_PX + "px";
    notizStand();
  }
  // A line that is simply cut off at the bottom edge reads as if the note
  // had ended. Hence a gradient and an arrow as soon as more is coming, and
  // two keys for scrolling: during the talk the hands are not on the mouse.
  function notizStand() {
    if (!ELN.notiz || !ELN.notizKasten) return;
    var n = ELN.notiz;
    if (n.scrollHeight - n.clientHeight - n.scrollTop > 4) {
      ELN.notizKasten.dataset.mehr = "1";
    } else {
      delete ELN.notizKasten.dataset.mehr;
    }
  }
  function notizRollen(richtung) {
    if (!ELN.notiz) return;
    ELN.notiz.scrollTop += richtung * Math.max(40, ELN.notiz.clientHeight * 0.6);
    notizStand();
  }

  // ── The speaker view's keys ───────────────────────────────────────────────
  //
  // A receiver of its own, only registered during setup: in the talk
  // window it does not exist at all. Paging, overview, and fullscreen come
  // from the shared control further up and do not appear here again.
  function tasten() {
    addEventListener("keydown", function (e) {
      if (tippt(e)) return;
      var k = e.key;
      if (k === "ArrowRight" || k === "ArrowLeft" || k === "PageDown" ||
          k === "PageUp" || k === " " || k === "Home" || k === "End") {
        uhrAn(); return;
      }
      // Up and down are free in the shared control and scroll the note
      // here. In the talk window this receiver does not exist.
      if (k === "ArrowDown") { notizRollen(1); e.preventDefault(); return; }
      if (k === "ArrowUp") { notizRollen(-1); e.preventDefault(); return; }
      if (k === "b") { SCHWARZ = SCHWARZ ? 0 : 1; sichtSenden(); }
      else if (k === "e") { EIS = EIS ? 0 : 1; sichtSenden(); }
      else if (k === "t") { if (ELN.ziel) { ELN.ziel.focus(); ELN.ziel.select(); e.preventDefault(); } }
      else if (k === "r") { UHR_START = 0; sprecherUhr(); }
      else if (k === "m") { modusUm(); }
      else if (k === "c") { farbeSetzen(FARBE + 1); }
      else if (k === "z") { tinteSenden({ b: "weg", s: tinteFolie() }); }
      else if (k === "x") { tinteSenden({ b: "loesch", s: tinteFolie() }); }
      else if (k === "+" || k === "=") { notizGroesse(2); }
      else if (k === "-" || k === "_") { notizGroesse(-2); }
    });
  }

  // ── Drawing ────────────────────────────────────────────────────────────────
  //
  // The pointer handlers sit on the stage itself, since it sits on top
  // here. A click does not page in this role anyway (see the control
  // handler), so the place is free.
  function zeichnen() {
    function anteil(e) {
      var r = B.getBoundingClientRect();
      if (!r.width || !r.height) return null;
      return { x: (e.clientX - r.left) / r.width,
               y: (e.clientY - r.top) / r.height };
    }
    // Jitter costs bandwidth and adds no visible picture. A fast stroke has
    // large gaps and loses nothing by it.
    function weitGenug(p) {
      if (!LETZT) return true;
      var dx = p.x - LETZT.x, dy = p.y - LETZT.y;
      return dx * dx + dy * dy > 0.000004;   // a good 0.2% of the stage width
    }
    // Nothing outside the slide into the stock. A pointer dragged past the
    // edge would otherwise yield values like 1.4 or -0.2 that no one ever
    // gets to see (`#ts-ink` clips them off) and that still travel into
    // every transcript. If it comes back, a new stroke begins instead of
    // jumping across the slide.
    function drin(p) { return p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1; }
    function punkt(e) {
      var p = anteil(e);
      if (!p) return;
      if (!drin(p)) { DRAUSSEN = 1; return; }
      if (DRAUSSEN) {
        DRAUSSEN = 0; STRICH_NR++; LETZT = null; OFFEN = null; GESETZT = 0;
      }
      if (!weitGenug(p)) return;
      LETZT = p;
      // The first point waits until a second one arrives. A mere click
      // would otherwise create a stroke out of one point: `getBBox` is 0 by
      // 0, nothing is visible, and undo would then clear away this ghost
      // instead of the stroke the speaker actually meant.
      if (OFFEN) { schicke(OFFEN); OFFEN = null; }
      else if (!GESETZT) { OFFEN = p; return; }
      schicke(p);
    }
    function schicke(p) {
      GESETZT = 1;
      tinteSenden({ n: STRICH_NR, s: tinteFolie(), f: FARBEN[FARBE],
                    x: p.x, y: p.y });
    }
    B.addEventListener("pointerdown", function (e) {
      if (e.button !== 0) return;
      if (MODUS === "zeiger") {
        var p0 = anteil(e);
        if (!p0 || !drin(p0)) return;
        ZEIGT = 1;
        try { B.setPointerCapture(e.pointerId); } catch (x) {}
        zeigerSenden({ t: "down", x: p0.x, y: p0.y, k: 1 });
        e.preventDefault();
        return;
      }
      MALT = 1; STRICH_NR++; LETZT = null; DRAUSSEN = 0; OFFEN = null; GESETZT = 0;
      // Without capture, the stroke would end as soon as the pointer leaves
      // the stage.
      try { B.setPointerCapture(e.pointerId); } catch (x) {}
      punkt(e);
      e.preventDefault();
    });
    B.addEventListener("pointermove", function (e) {
      if (MODUS === "zeiger") {
        // Only while pressed. A hover would put a message on the wire for
        // every mouse movement across the slide, and nothing in the hall
        // would change because of it.
        if (!ZEIGT) return;
        var pm = anteil(e);
        if (!pm) return;
        zeigerSenden({ t: "move", x: pm.x, y: pm.y, k: 1 });
        e.preventDefault();
        return;
      }
      if (!MALT) return;
      // The browser coalesces fast movements into one event and keeps the
      // in-between points aside. Whoever does not pick them up gets an
      // angular line on a fast drag.
      var liste = e.getCoalescedEvents ? e.getCoalescedEvents() : null;
      if (liste && liste.length) { for (var i = 0; i < liste.length; i++) punkt(liste[i]); }
      else punkt(e);
      e.preventDefault();
    });
    function schluss(e) {
      if (MODUS === "zeiger") {
        if (!ZEIGT) return;
        ZEIGT = 0;
        try { B.releasePointerCapture(e.pointerId); } catch (x) {}
        var pe = anteil(e);
        if (pe) zeigerSenden({ t: "up", x: pe.x, y: pe.y, k: 0 });
        return;
      }
      if (!MALT) return;
      // A held-back first point that was never followed by a second was a
      // click and not a stroke. It is dropped.
      MALT = 0; LETZT = null; OFFEN = null; GESETZT = 0;
      try { B.releasePointerCapture(e.pointerId); } catch (x) {}
    }
    B.addEventListener("pointerup", schluss);
    B.addEventListener("pointercancel", schluss);
    // A construction is zoomed with the wheel, and that is worth carrying
    // across too. Not passive, because the page behind it must not scroll
    // along.
    B.addEventListener("wheel", function (e) {
      if (MODUS !== "zeiger") return;
      var p = anteil(e);
      if (!p || !drin(p)) return;
      if (!zeigerRahmen(e.clientX, e.clientY)) return;
      zeigerSenden({ t: "wheel", x: p.x, y: p.y, k: 0, d: e.deltaY });
      e.preventDefault();
    }, { passive: false });
  }

  // ── The clock, four times a second ────────────────────────────────────────
  function sprecherUhr() {
    if (!gebaut) return;
    verbindungStand();
    var zeigen = ZIEL_MIN > 0 && STEPS.length > 0 ? "" : "none";
    if (ELN.restPaar) ELN.restPaar.style.display = zeigen;
    if (ELN.taktPaar) ELN.taktPaar.style.display = zeigen;
    var j = new Date();
    ELN.uhr.textContent = zwei(j.getHours()) + ":" + zwei(j.getMinutes())
                          + ":" + zwei(j.getSeconds());
    var v = UHR_START ? (Date.now() - UHR_START) / 1000 : 0;
    ELN.zeit.textContent = mmss(v);
    ELN.zeit.dataset.laeuft = UHR_START ? "1" : "0";
    if (ZIEL_MIN > 0 && STEPS.length > 0) {
      var plan = ZIEL_MIN * 60;
      var rest = plan - v;
      ELN.rest.textContent = mmss(rest);
      ELN.rest.dataset.lage = rest < 0 ? "zurueck" : "";
      // As long as the clock stands still, there is no plan to be ahead of
      // or behind. "ahead of plan" would then merely be a consequence of
      // the expected position being zero at zero seconds.
      if (!UHR_START) {
        ELN.takt.textContent = "·";
        ELN.takt.dataset.lage = "";
        return;
      }
      // This is how reveal.js computes it: the elapsed time relative to the
      // planned duration, plotted onto the total step count. The distance
      // between the expected and the actual step, times the time per step,
      // is the lead in seconds.
      var proSchritt = plan / STEPS.length;
      var d = ((current + 1) - v / plan * STEPS.length) * proSchritt;
      var gut = Math.abs(d) < proSchritt;
      ELN.takt.textContent = (gut ? "" : mmss(Math.abs(d)) + " ") +
        (gut ? wort("onplan", "on plan")
             : d > 0 ? wort("ahead", "ahead") : wort("behind", "behind"));
      ELN.takt.dataset.lage = gut ? "" : (d > 0 ? "vor" : "zurueck");
    } else {
      ELN.rest.textContent = "·";
      ELN.rest.dataset.lage = "";
      ELN.takt.textContent = "·";
      ELN.takt.dataset.lage = "";
    }
  }

  // ── After every step ──────────────────────────────────────────────────────
  function sprecherStand() {
    if (ROLLE !== "speaker" || !SPRECHERBOX || !gebaut) return;
    var st = STEPS[current] || { slide: 0, step: 1 };

    var n = notiz(st.slide);
    ELN.notiz.textContent = n || (W.noNote || "no note");
    if (n) delete ELN.notiz.dataset.leer; else ELN.notiz.dataset.leer = "1";

    ELN.fort.textContent = (st.slide + 1) + " / " + SLIDES.length;
    ELN.fortSchritt.textContent = (current + 1) + " / " + STEPS.length;
    // The bar's right edge travels across it, so with less motion asked for
    // it jumps to its new place instead of gliding there. Set here rather
    // than as a media query in the stylesheet, so one predicate answers the
    // question for the whole runtime and the two halves cannot drift apart.
    // The empty string takes the inline value away again and hands the bar
    // back to the rule in the stylesheet.
    ELN.balken.style.transition = wenigerBewegung() ? "none" : "";
    ELN.balken.style.width =
      (STEPS.length < 2 ? 100 : (current * 100 / (STEPS.length - 1))) + "%";

    // The preview costs a clone of the slide. So it is only rebuilt when it
    // is supposed to show something different than it just did.
    var w = weiter(current);
    var schluessel = w.art + "|" + w.slide + "|" + w.step;
    if (schluessel !== VORSCHAU) {
      VORSCHAU = schluessel;
      while (ELN.vorBild.firstChild) ELN.vorBild.removeChild(ELN.vorBild.firstChild);
      if (w.art === "ende") {
        ELN.vorMarke.textContent = wort("next", "next");
        var kasten = bau("div", "ts-sp-ende", ELN.vorBild);
        bau("span", "", kasten).textContent = wort("end", "end of talk");
      } else {
        // Only the number goes behind the label, not the word "slide" a
        // second time: on a slide change it would otherwise literally say
        // "next slide slide 2.1".
        ELN.vorMarke.textContent =
          (w.art === "folie" ? wort("nextSlide", "next slide")
                             : wort("nextStep", "next step"))
          + "   " + (w.slide + 1) + "." + w.step;
        ELN.vorBild.appendChild(schrittBild(w.slide, w.step));
      }
    }
    ELN.notiz.scrollTop = 0;
    notizStand();
    sprecherUhr();
  }

  // ── Anzeigen ──────────────────────────────────────────────────────────────
  var current = -1;

  function goto(n, instant) {
    n = Math.max(0, Math.min(STEPS.length - 1, n));
    var prev = current < 0 ? null : STEPS[current];
    var dst = STEPS[n];
    var changed = !prev || prev.slide !== dst.slide;
    var back = current > n;
    current = n;

    if (changed) stelle(dst.slide);

    var hasMorph = false;
    if (changed && prev && !instant) hasMorph = fly(prev.slide, dst.slide, CFG.duration);

    if (changed && prev) {
      mediaOff(prev.slide);
      stopBridges(prev.slide);
      transition(SLIDES[prev.slide], SLIDES[dst.slide], back, instant, hasMorph);
    } else if (!prev) {
      SLIDES.forEach(function (f) { delete f.dataset.on; delete f.dataset.off; });
      SLIDES[dst.slide].dataset.on = "1";
    }

    // The chrome layer follows the slide but does not travel along with
    // it: it sits above the stage and is only faded in and out. Outside
    // the two branches above, because one applies only to the very first
    // slide and the other passes the change on to `transition`.
    CHROME.forEach(function (c, i) {
      if (i === dst.slide) c.dataset.on = "1"; else delete c.dataset.on;
    });

    SLIDES[dst.slide].querySelectorAll(".ts-el").forEach(function (el) {
      var d = +erbt(el, "duration") || CFG.duration;
      var delay = back ? 0 : (+erbt(el, "delay") || 0);
      // Where the element stands now and where it belongs. `data-on` alone no
      // longer answers the first question: drawn muted is a third state, and
      // it has to be told apart from drawn, or paging back would find nothing
      // to bring up again.
      var war = el.dataset.on !== "1" ? 0 : (el.dataset.dim === "1" ? 1 : 2);
      var wird = zustand(el, dst.step);

      // Entering a slide or jumping into it plays no effects, so the whole run
      // is replayed as state. That is what puts a dimmed element back where it
      // belongs after a reload, after paging in from the other side, and in
      // the speaker view.
      if (instant || changed) { clearAnims(el); ruhe(el, wird); return; }
      if (wird === war) return;
      ruhe(el, wird);

      if (war === 0) {
        // Straight to full is the entrance. Straight to muted only happens on
        // a jump that skipped the whole range, and then the point has no
        // arrival to play: it simply is there, quietly.
        if (wird === 2) fadeIn(el, erbt(el, "enter") || "fade-up", d, delay);
        else fadeTo(el, 0, DIM, d);
      } else if (wird === 0) {
        var von = war === 1 ? DIM : 1;
        if (back) fadeOut(el, erbt(el, "enter") || "fade-up", d, von);
        else fadeOut(el, erbt(el, "exit") || "fade", d * 0.75, von);
      } else if (wird === 1) {
        fadeTo(el, 1, DIM, d);
      } else {
        fadeTo(el, DIM, 1, d);
      }
    });

    mediaOn(dst.slide);
    drive(dst.slide, dst.step, back || changed);
    // The running step belongs in the hash, but only in the talk window.
    // In the speaker window `#speaker` sits there, and that has to stay:
    // whoever reloads wants the speaker view back, not the talk.
    if (ROLLE !== "speaker" && location.hash !== "#" + (n + 1)) {
      history.replaceState(null, "", "#" + (n + 1));
    }
    melde(n);
    sprecherStand();
    tinteStand();
    mark();
    // Before the badges are painted: which points count as named can change
    // with the step, and the badges follow from that.
    adRueck();
    // Last, because `ruhe` above has just written an opacity onto every
    // element: a point still waiting to be called out would otherwise be
    // invisible to the speaker as well, and there is nothing to choose from
    // in an empty column.
    adSprecher();
  }

  // ── Slide transitions ─────────────────────────────────────────────────────
  //

  // Where the incoming slide comes from. "right" is the default.
  function shove(from, dist) {
    if (from === "left") return { rein: "translateX(-" + dist + ")",
                                  raus: "translateX(" + dist + ")" };
    if (from === "top") return { rein: "translateY(-" + dist + ")",
                                 raus: "translateY(" + dist + ")" };
    if (from === "bottom") return { rein: "translateY(" + dist + ")",
                                    raus: "translateY(-" + dist + ")" };
    return { rein: "translateX(" + dist + ")", raus: "translateX(-" + dist + ")" };
  }

  // The closed state of a wipe, depending on the edge it starts at.
  function curtain(from) {
    if (from === "right") return "inset(0 0 0 100%)";
    if (from === "top") return "inset(0 0 100% 0)";
    if (from === "bottom") return "inset(100% 0 0 0)";
    return "inset(0 100% 0 0)";
  }

  var OFFEN = "inset(0 0 0 0)";
  var RUND_AUF = "circle(75% at 50% 50%)";
  var RUND_ZU = "circle(0% at 50% 50%)";

  var TRANSITION = {
    "none": null,

    "fade": function () { return {
      rein: [{ opacity: 1 }, { opacity: 1 }],
      raus: [{ opacity: 1 }, { opacity: 0 }], oben: "alt" }; },

    "slide": function (o) {
      var v = shove(o.from, "46px");
      return {
        rein: [{ opacity: 0, transform: v.rein }, { opacity: 1, transform: "none" }],
        raus: [{ opacity: 1, transform: "none" }, { opacity: 0, transform: v.raus }] };
    },

    "push": function (o) {
      var v = shove(o.from, "100%");
      return {
        rein: [{ transform: v.rein }, { transform: "none" }],
        raus: [{ transform: "none" }, { transform: v.raus }] };
    },

    "cover": function (o) {
      var v = shove(o.from, "100%");
      return {
        rein: [{ transform: v.rein }, { transform: "none" }],
        raus: [{ opacity: 1 }, { opacity: 1 }], oben: "neu" };
    },

    "uncover": function (o) {
      var v = shove(o.from, "100%");
      return {
        rein: [{ opacity: 1 }, { opacity: 1 }],
        raus: [{ transform: "none" }, { transform: v.raus }], oben: "alt" };
    },

    "zoom": function (o) {
      var raus = o.direction === "out";
      return {
        rein: [{ opacity: 0, transform: "scale(" + (raus ? 1.18 : 0.82) + ")" },
               { opacity: 1, transform: "none" }],
        raus: [{ opacity: 1, transform: "none" },
               { opacity: 0, transform: "scale(" + (raus ? 0.82 : 1.18) + ")" }] };
    },

    "blur": function () { return {
      rein: [{ opacity: 0, filter: "blur(16px)" }, { opacity: 1, filter: "blur(0px)" }],
      raus: [{ opacity: 1, filter: "blur(0px)" }, { opacity: 0, filter: "blur(16px)" }] }; },

    "iris": function (o) {
      if (o.direction === "close") return {
        rein: [{ opacity: 1 }, { opacity: 1 }],
        raus: [{ clipPath: RUND_AUF }, { clipPath: RUND_ZU }], oben: "alt" };
      return {
        rein: [{ clipPath: RUND_ZU }, { clipPath: RUND_AUF }],
        raus: [{ opacity: 1 }, { opacity: 1 }], oben: "neu" };
    },

    "wipe": function (o) {
      var zu = curtain(o.from);
      if (o.direction === "close") return {
        rein: [{ opacity: 1 }, { opacity: 1 }],
        raus: [{ clipPath: OFFEN }, { clipPath: zu }], oben: "alt" };
      return {
        rein: [{ clipPath: zu }, { clipPath: OFFEN }],
        raus: [{ opacity: 1 }, { opacity: 1 }], oben: "neu" };
    },

    "flip": function (o) {
      var dreh = o.axis === "x" ? "rotateX" : "rotateY";
      return {
        rein: [{ transform: dreh + "(180deg)" }, { transform: dreh + "(0deg)" }],
        raus: [{ transform: dreh + "(0deg)" }, { transform: dreh + "(-180deg)" }],
        d3: true, ruecken: true };
    },

    "cube": function (o, W, H) {
      var quer = o.axis !== "x";
      var dreh = quer ? "rotateY" : "rotateX";
      var K = quer ? W : H;
      var h = "translateZ(" + (-K / 2) + "px) ";
      var v = " translateZ(" + (K / 2) + "px)";
      return {
        rein: [{ transform: h + dreh + "(" + (quer ? 90 : -90) + "deg)" + v },
               { transform: h + dreh + "(0deg)" + v }],
        raus: [{ transform: h + dreh + "(0deg)" + v },
               { transform: h + dreh + "(" + (quer ? -90 : 90) + "deg)" + v }],
        d3: true, ruecken: true };
    }
  };

  function reverse(a) {
    return {
      rein: a.raus.slice().reverse(),
      raus: a.rein.slice().reverse(),
      oben: a.oben === "neu" ? "alt" : (a.oben === "alt" ? "neu" : a.oben),
      d3: a.d3, ruecken: a.ruecken
    };
  }

  function asSpec(x) {
    if (!x) return { kind: "fade" };
    if (typeof x === "string") {
      if (x.charAt(0) === "{") { try { return JSON.parse(x); } catch (e) {} }
      return { kind: x };
    }
    return x;
  }

  function transition(alt, neu, back, instant, hasMorph) {
    neu.dataset.on = "1";
    SLIDES.forEach(function (f) { if (f !== neu) delete f.dataset.on; });

    if (alt.mo_zeit) { clearTimeout(alt.mo_zeit); alt.mo_zeit = null; }
    if (alt.mo_aus) { try { alt.mo_aus.cancel(); } catch (e) {} alt.mo_aus = null; }
    resetStyle(alt); resetStyle(neu);
    delete alt.dataset.off;

    var later = back ? alt : neu;
    var o = asSpec(hasMorph ? "fade"
                               : (attr(later, "transition") || CFG.transition));
    var bau = TRANSITION[o.kind] === undefined ? TRANSITION["fade"] : TRANSITION[o.kind];
    // Asked for less motion, every transition becomes the cross-fade. All the
    // others move the whole slide, and a slide is the largest thing on the
    // screen: `slide` and `push` and `cover` carry it across, `zoom` grows it,
    // `flip` and `cube` turn it, `iris` and `wipe` drag an edge over it. The
    // fade keeps what a transition is actually for, which is to mark the cut
    // between one slide and the next, and it keeps it at the same length.
    // `"none"` stays untouched, because nothing is already what it does.
    if (bau && wenigerBewegung()) bau = TRANSITION["fade"];
    if (instant || !bau) return;

    var d = CFG.transitionDuration;
    var box = B.getBoundingClientRect();
    var kind = bau(o, box.width, box.height);
    if (back) kind = reverse(kind);

    if (kind.d3) {
      B.style.perspective = Math.round(box.width * 1.4) + "px";
      if (kind.ruecken) {
        alt.style.backfaceVisibility = "hidden";
        neu.style.backfaceVisibility = "hidden";
      }
    }
    if (kind.achse) {
      neu.style.transformOrigin = kind.achse.neu;
      alt.style.transformOrigin = kind.achse.alt;
    }
    neu.style.zIndex = kind.oben === "alt" ? "1" : "2";
    alt.style.zIndex = kind.oben === "alt" ? "2" : "1";

    var e = neu.animate(kind.rein, { duration: d, easing: EASE, fill: "both" });
    e.onfinish = function () { try { e.cancel(); } catch (x) {} };

    alt.dataset.off = "1";
    var a = alt.animate(kind.raus, { duration: d, easing: EASE, fill: "both" });
    alt.mo_aus = a;
    var done = function () {
      if (alt.mo_aus !== a) return;
      try { a.cancel(); } catch (x) {}
      try { e.cancel(); } catch (x) {}
      delete alt.dataset.off;
      alt.mo_aus = null;
      alt.mo_zeit = null;
      resetStyle(alt); resetStyle(neu);
      B.style.perspective = "";
    };
    a.onfinish = done;
    alt.mo_zeit = setTimeout(done, d + 80);
  }

  function resetStyle(f) {
    f.style.zIndex = "";
    f.style.transformOrigin = "";
    f.style.backfaceVisibility = "";
  }

  // ── Overview ──────────────────────────────────────────────────────────────
  //
  // A slide as a still thumbnail. Factored out because the speaker view
  // needs the same thing, there for the slide that comes next.
  //
  // Footer and progress no longer sit in `.ts-bg` but in the layer above
  // the stage. For the thumbnail, the print copy that is embedded in every
  // slide anyway is therefore taken along, otherwise the thumbnails would
  // have no page number. What the thumbnail does not show are the animated
  // parts: it always stands at the first step of its slide.
  function miniatur(i) {
    var f = SLIDES[i];
    var m = document.createElement("div");
    m.className = "ts-mini";
    if (!f) return m;
    var cp = f.querySelector(".ts-chromep");
    m.innerHTML = f.querySelector(".ts-bg").innerHTML + (cp ? cp.innerHTML : "");
    return m;
  }

  var minis = [];
  function buildOverview() {
    if (minis.length) return;
    SLIDES.forEach(function (f, i) {
      var m = miniatur(i);
      m.addEventListener("click", function () {
        OVERVIEW.removeAttribute("data-on");
        for (var k = 0; k < STEPS.length; k++) {
          if (STEPS[k].slide === i) { goto(k, true); return; }
        }
      });
      OVERVIEW.appendChild(m);
      minis.push(m);
    });
  }
  function mark() {
    if (!minis.length) return;
    var f = STEPS[current].slide;
    for (var i = 0; i < minis.length; i++) {
      if (i === f) minis[i].dataset.hier = "1"; else delete minis[i].dataset.hier;
    }
  }

  // ── Scaling ────────────────────────────────────────────────────────────────
  // How the three parts divide up the window.
  //
  // The running slide is the canvas and gets the most space. It keeps its
  // aspect ratio while doing so, and that decides the layout:
  //
  //   tall:  a strip stays free below the slide, and the note sits there
  //          across the full width. This is the normal case.
  //   flat:  in a wide, low window the slide is already as tall as the
  //          body, and a large empty area would remain beside it. Then
  //          preview and note pull down there, stacked on top of each other.
  //
  // The preview is a glance and not a second stage: at most a scant half of
  // the running slide, otherwise the layout order would flip.
  function sprecherSpalten() {
    if (ROLLE !== "speaker" || !LEIB || !PLATZ) return;
    var r = LEIB.getBoundingClientRect();
    if (!r.width || !r.height) return;
    var v = CFG.width / CFG.height;
    var frei = r.width - 14;
    // If the window is portrait, the height suffices for a stage across the
    // full width and plenty still remains below it. Then the note would
    // stand in a column bigger than the stage itself, and the layout order
    // would stand on its head. So the stage lays itself crosswise at the
    // top, and preview and note share the row below it.
    // This is how wide the stage would be allowed to be if the note below
    // it keeps a good third.
    var breit = Math.min(frei * 0.72, r.height * 0.68 * v);
    var flach = (frei - breit) > breit * 0.75;
    if (flach) breit = Math.min(frei * 0.72, r.height * v);
    breit = Math.max(frei * 0.34, breit);
    // The minimum value must not make the stage taller than the body is.
    // In a very wide and very flat window it would otherwise stick out
    // below its place, and the view would get a scrollbar.
    breit = Math.min(breit, frei, r.height * v);

    // And now the proof of the pudding. What is to be enforced is not some
    // aspect ratio of the window, but the result: the running slide is the
    // largest area of the view. So work out what the note would get in
    // this layout, and switch to the third one if it overtook the stage
    // and the height suffices for a stage across the full width.
    //
    // The old condition hung on the aspect ratio and let through a whole
    // band of window sizes in which the note got one and a half times the
    // stage. Measured against the result, that can no longer happen.
    var vollHoch = frei / v;
    var vor = Math.min(frei - breit, breit * 0.45);
    var flBuehne = breit * breit / v;
    var flNotiz = flach
      ? (frei - breit) * Math.max(0, r.height - vor / v - 18)
      : r.width * Math.max(0, r.height - breit / v - 12);
    if (flNotiz > flBuehne && vollHoch <= r.height - 80) {
      LEIB.dataset.form = "hochkant";
      var vorBreit = Math.min(frei * 0.42, (r.height - vollHoch - 14) * v * 0.9);
      vorBreit = Math.max(120, vorBreit);
      LEIB.style.gridTemplateColumns = Math.round(vorBreit) + "px minmax(0,1fr)";
      if (ELN.vorBild) ELN.vorBild.style.maxWidth = "";
      notizNachFenster();
      notizStand();
      return;
    }
    LEIB.dataset.form = flach ? "flach" : "hoch";
    LEIB.style.gridTemplateColumns = Math.round(breit) + "px minmax(0,1fr)";
    if (ELN.vorBild) {
      ELN.vorBild.style.maxWidth = Math.max(80, Math.round(breit * 0.45)) + "px";
    }
    // If the stage in a very flat window already stands as tall as the
    // body, more width remains beside it than a note needs. Without a cap,
    // the note there would be the largest area of the view, and the layout
    // order would stand on its head again.
    if (ELN.notiz) {
      ELN.notiz.style.maxWidth = flach
        ? Math.round(breit * 1.15) + "px" : "";
    }
    notizNachFenster();
    notizStand();
  }

  function fit() {
    var v = CFG.width / CFG.height;
    // Thumbnails and printed pages hold their shape with padding, which needs
    // the ratio as a number: it is not 16:9 for every deck.
    document.documentElement.style.setProperty(
      "--ts-ratio", (100 / v) + "%");
    sprecherSpalten();
    // In the speaker view the stage does not fill the window but the box
    // reserved for it in the frame. It remains the real stage while doing
    // so: the same slides, the same step, the same drawing layer.
    var r = (ROLLE === "speaker" && PLATZ) ? PLATZ.getBoundingClientRect() : null;
    if (r && (r.width < 20 || r.height < 20)) r = null;
    var raumB = r ? r.width : innerWidth, raumH = r ? r.height : innerHeight;
    var bw = Math.min(raumB, raumH * v);
    B.style.width = bw + "px";
    B.style.height = (bw / v) + "px";
    if (r) {
      B.style.left = (r.left + (r.width - bw) / 2) + "px";
      B.style.top = (r.top + (r.height - bw / v) / 2) + "px";
    }
    if (current >= 0) stelle(STEPS[current].slide);
  }
  addEventListener("resize", fit);

  // A page that comes back from the background is not the page that went
  // away. iOS restores it from its cache without firing a `resize`, and an
  // embedded frame then stands at a scale that no longer matches the stage.
  // Reported from an iPhone and seen in both directions: once the text in
  // the frame came back too large for the slide, once the drawing in it came
  // back at a quarter of its width.
  //
  // The frame is sized in slide points and then zoomed, and the stored
  // measurement decides whether that is written again. If the browser drops
  // the scale but keeps the attribute, the stored measurement says "already
  // correct" and nothing ever repairs it. So it is thrown away here and
  // everything is placed anew.
  function neuVermessen() {
    document.querySelectorAll(".ts-el iframe").forEach(function (f) {
      delete f.dataset.mass;
    });
    fit();
    // And again afterwards. A measurement taken at the moment of the return
    // is not to be trusted: iOS reports a viewport that is still on its way,
    // and a scale computed from it would be written into the frame and stay
    // there. Reported from the phone after the first attempt at this: the
    // drawing then came back small every time instead of only sometimes.
    if (window.requestAnimationFrame) requestAnimationFrame(function () { fit(); });
    setTimeout(fit, 250);
  }

  // The measurement that really settles it. Whatever the reason the stage
  // ends up with a different box, the elements on it are placed again: a
  // rotated phone, a window dragged to another screen, a restored page whose
  // viewport arrived late. An event says *that* something happened, this says
  // *when it is over*, and only the second one can be trusted.
  //
  // No loop: this only places what sits on the stage and never writes the
  // stage's own size. Where the scale comes out the same, the stored
  // measurement stops it before anything is written at all.
  if (window.ResizeObserver) {
    try {
      new ResizeObserver(function () {
        if (current >= 0 && STEPS[current]) stelle(STEPS[current].slide);
      }).observe(B);
    } catch (x) {}
  }
  addEventListener("pageshow", neuVermessen);
  addEventListener("orientationchange", neuVermessen);
  // On `document`, not on the window: that is where the event is defined,
  // and it saves the question of whether it bubbles.
  document.addEventListener("visibilitychange", function () {
    if (!document.hidden) neuVermessen();
  });

  // ── Controls ───────────────────────────────────────────────────────────────
  var hintTimer;
  function hint(t) {
    HINT.textContent = t;
    HINT.dataset.on = "1";
    clearTimeout(hintTimer);
    hintTimer = setTimeout(function () { delete HINT.dataset.on; }, 2600);
  }
  // The speaker view has an input field for the planned duration. A space
  // key inside it is a space character, not a page turn.
  function tippt(e) {
    var t = e.target;
    if (!t || !t.tagName) return false;
    var n = t.tagName.toLowerCase();
    return n === "input" || n === "textarea" || n === "select" || !!t.isContentEditable;
  }

  // ── Adaptive groups ────────────────────────────────────────────────────────
  //
  // Points a class calls out in whatever order they come. Every member of a
  // group carries `data-ad` (its name) and `data-ad-nr` (which point it
  // belongs to); a point and everything tied to it -- a drawing layer, a
  // sentence beside it -- share one number and therefore one step. Swapping
  // the step moves them together, so no separate link is needed.
  //
  // The group owns as many steps as it has points. Which point gets which of
  // them is decided here, at the keyboard; the count never changes, and with
  // it neither the progress bar, nor `info().step.total`, nor the overflow
  // check, nor the handout.
  var AD = {};

  function adSammeln() {
    AD = {};
    [].forEach.call(document.querySelectorAll(".ts-el[data-ad]"), function (el) {
      var name = el.dataset.ad;
      var g = AD[name] || (AD[name] = { reihen: {}, plaetze: [], folge: [] });
      var nr = +el.dataset.adNr;
      (g.reihen[nr] || (g.reihen[nr] = [])).push(el);
      // The step the point was written for. Remembered once, because
      // `data-at` is what gets rewritten below.
      if (!el.dataset.adPlatz) el.dataset.adPlatz = el.dataset.at;
    });
    Object.keys(AD).forEach(function (name) {
      var g = AD[name];
      g.plaetze = Object.keys(g.reihen)
        .map(function (nr) { return g.reihen[nr][0].dataset.adPlatz; })
        .sort(function (a, b) { return parseInt(a, 10) - parseInt(b, 10); });
      g.aus = (STEPS.length + 2) + "-";
      // Auf welcher Folie die Gruppe steht. Gebraucht, um beim
      // Zurueckblaettern zu wissen, ob man vor ihr, in ihr oder hinter ihr ist.
      var erst = g.reihen[Object.keys(g.reihen)[0]][0];
      g.folie = SLIDES.findIndex(function (sec) { return sec.contains(erst); });
    });
    // Nothing has been called out yet, so every point stands aside. Without
    // this the first point would simply appear on its own step, which is the
    // behaviour an adaptive group exists to replace.
    Object.keys(AD).forEach(function (name) { adStellen(name, false); });
    adSprecher();
  }

  // `malen` is false while the deck is being set up: there is no current step
  // yet, and `goto` would have nothing to go to.
  function adStellen(name, malen) {
    var g = AD[name];
    if (!g) return;
    Object.keys(g.reihen).forEach(function (nr) {
      var p = g.folge.indexOf(+nr);
      var at = p >= 0 ? g.plaetze[p] : g.aus;
      g.reihen[nr].forEach(function (el) { el.dataset.at = at; });
    });
    adSprecher();
    if (malen !== false) goto(current, true);
  }

  // The digits, and only in the speaker view. A point that has not been called
  // out yet is invisible in the hall -- that is the whole idea -- but the
  // speaker has to see what there is to choose from, and which digit picks
  // it. So it stands there pale, with its number in front of it.
  //
  // Written as inline style rather than as a CSS rule, and not out of taste:
  // the stylesheet is embedded in every deck, so a rule would move the
  // typeset fingerprint the deck check keeps per platform -- and the Linux
  // value cannot be re-recorded from here.
  function adSprecher() {
    if (ROLLE !== "speaker") return;
    Object.keys(AD).forEach(function (name) {
      var g = AD[name];
      Object.keys(g.reihen).forEach(function (nr) {
        var offen = g.folge.indexOf(+nr) < 0;
        g.reihen[nr].forEach(function (el, i) {
          if (offen) {
            // Erst die laufende Ueberblendung abbrechen. Ein Punkt, der eben
            // zurueckgenommen wurde, blendet gerade aus, und ihr Abschluss
            // setzt die Deckkraft danach auf 0 -- gemessen stand genau der
            // zuletzt zurueckgenommene Punkt unsichtbar da, waehrend seine
            // Ziffer schon wieder zur Auswahl einlud.
            clearAnims(el);
            el.style.opacity = "0.3";
            el.style.visibility = "visible";
          } else {
            // Nicht auf "" zuruecksetzen: `ruhe` hat die Deckkraft eben als
            // Inline-Stil gesetzt, und ein leerer Wert faellt auf die
            // Stilvorlage zurueck, wo ein Element unsichtbar ist. Gemessen:
            // ein genannter Punkt verschwand, sobald der naechste genannt
            // wurde. Also dieselbe Entscheidung noch einmal treffen.
            var z = zustand(el, STEPS[current] ? STEPS[current].step : 1);
            el.style.opacity = z === 2 ? "1" : (z === 1 ? String(DIM) : "0");
            el.style.visibility = "";
          }
          // One badge per point, on the first member. The layer that travels
          // with it needs no second number.
          // Beside the point, not inside it. A badge inside inherits the
          // element's opacity, and a point waiting to be called stands at 0.3
          // -- measured, the digit was as pale as the text it labels and no
          // help at all. As a sibling it keeps its own strength and takes the
          // point's own left/top, which `setzen` has already written.
          // Nur das erste Mitglied raeumt auf und legt an. Lief das Aufraeumen
          // fuer jedes Mitglied, entfernte die Schicht die Marke, die ihr
          // eigener Punkt gerade angelegt hatte -- gemessen: keine einzige
          // Ziffer im Bild, obwohl jede angelegt worden war.
          if (i > 0) return;
          var eig = el.parentNode
            && el.parentNode.querySelector(':scope > .ts-ad-nr[data-fuer="' + name + "-" + nr + '"]');
          if (eig) eig.remove();
          if (!offen) return;
          var b = document.createElement("span");
          b.className = "ts-ad-nr";
          b.dataset.fuer = name + "-" + nr;
          b.textContent = nr;
          b.style.left = el.style.left;
          b.style.top = el.style.top;
          // An explicit colour, not `currentColor`: beside `color:#fff` in the
          // same declaration that resolves to white, and the badge was white
          // on white -- measured, invisible in the speaker view.
          //
          // Placed inside the element, not to its left: a point sits at the
          // left edge of its column, and anything outside is clipped away.
          var wo = "left:" + (el.style.left || "0") + ";top:" + (el.style.top || "0") + ";";
          b.style.cssText = "position:absolute;" + wo
            + "font:700 0.72em/1.55 system-ui,sans-serif;width:1.55em;"
            + "height:1.55em;border-radius:50%;text-align:center;"
            + "background:#eb5e28;color:#fff;opacity:1;"
            // Auf den Aufzaehlungspunkt, nicht daneben: die Ziffer nimmt den
            // Platz des Punktes ein, den sie ohnehin ersetzt, und die Zeile
            // rueckt nicht.
            + "pointer-events:none;z-index:5;transform:translate(-12%,6%)";
          if (el.parentNode) el.parentNode.appendChild(b);
        });
      });
    });
  }

  // The other window's assignment. Sent whenever a digit is pressed, so both
  // windows agree on which point took which step -- the reveal itself then
  // falls out of the ordinary step machinery.
  horch("adaptiv", function (d) {
    var g = AD[d.gruppe];
    if (!g || !d.folge) return;
    g.folge = d.folge.slice();
    // Neu zeichnen, aber stumm. Ein gewoehnliches `goto` meldet den eigenen
    // Schritt zurueck, und das ist hier der *alte* -- die Zuordnung kommt vor
    // dem Schritt an. Gemessen: die Halle meldete 4 zurueck, `fernGoto` zog
    // das Sprecherfenster von 5 auf 4, und die Fernsteuerung hinkte fortan
    // einen Schritt hinterher, waehrend die Halle richtig stand.
    stumm++;
    adFrisch = d.gruppe;
    try { adStellen(d.gruppe, true); } finally { stumm--; adFrisch = null; }
  });

  // Backwards takes reveals back, and that is not a nicety: every forward key
  // reveals a point, so without this a group is used up after one pass and
  // offers nothing on the way back -- measured, after four steps back and
  // forward the numbers were gone and every point stood.
  //
  // Before the slide means none, on it means as many as the current step
  // carries, past it means all: the deck reads the same going back as it did
  // going forward.
  // Welche Gruppe gerade eine Zuordnung von drüben bekommen hat. Die
  // Zuordnung reist vor dem Schritt, und ohne diese Ausnahme naehme
  // `adRueck` sie sofort wieder zurueck -- gemessen kam in der Halle nichts
  // mehr an, obwohl beide Nachrichten ankamen.
  var adFrisch = null;

  function adRueck() {
    if (!STEPS[current]) return;
    var si = STEPS[current].slide, schritt = STEPS[current].step;
    Object.keys(AD).forEach(function (name) {
      var g = AD[name];
      if (name === adFrisch) return;
      var erlaubt;
      if (g.folie < 0 || si < g.folie) { erlaubt = 0; }
      else if (si > g.folie) { erlaubt = g.folge.length; }
      else {
        erlaubt = g.plaetze.filter(function (pl) {
          return parseInt(pl, 10) <= schritt;
        }).length;
      }
      if (g.folge.length > erlaubt) {
        g.folge.length = erlaubt;
        adStellen(name, false);
      }
    });
  }

  // A forward key on a slide whose group still has unnamed points takes the
  // next one in written order. That makes an adaptive group a superset of a
  // staggered list rather than a mode beside it: press only arrows and you get
  // the order as written, press a digit and you get that point, and the two
  // mix freely. Without it three keypresses in a row did nothing visible --
  // measured -- which reads as broken even though it was correct.
  function adPfeil() {
    var namen = adHier();
    if (!namen.length) return false;
    var g = AD[namen[0]];
    var offen = Object.keys(g.reihen).map(Number)
      .filter(function (n) { return g.folge.indexOf(n) < 0; })
      .sort(function (a, b) { return a - b; });
    if (!offen.length) return false;
    // Nur vorwärts. Wer über den Hash oder `End` hinter die Gruppe gesprungen
    // ist, soll mit dem Pfeil nicht rückwärts in sie hineinfallen.
    var platz = parseInt(g.plaetze[g.folge.length], 10);
    if (!(platz >= STEPS[current].step)) return false;
    return adTaste(offen[0]);
  }

  // Which groups are on the slide the deck is standing on.
  function adHier() {
    var sec = SLIDES[STEPS[current].slide];
    return Object.keys(AD).filter(function (name) {
      return Object.keys(AD[name].reihen).some(function (nr) {
        return AD[name].reihen[nr].some(function (el) { return sec.contains(el); });
      });
    });
  }

  // A digit reveals that point of the group on this slide. Pressed again it
  // does nothing: taking a point back is what paging backwards is for.
  function adTaste(ziffer) {
    var namen = adHier();
    if (!namen.length) return false;
    var g = AD[namen[0]];
    if (!(ziffer in g.reihen)) return false;
    if (g.folge.indexOf(ziffer) >= 0) return false;
    g.folge.push(ziffer);
    adStellen(namen[0], false);
    // Und in das andere Fenster. Ohne das kennt die Halle die Zuordnung nicht:
    // sie geht auf den Schritt, den der Sprecher meldet, hat dort aber jeden
    // Punkt beiseitegestellt und zeigt nichts. Gemessen -- in der Halle blieb
    // jeder Punkt auf dem Ausweichbereich, waehrend im Sprecherfenster alles
    // richtig stand.
    sende("adaptiv", { gruppe: namen[0], folge: g.folge.slice() });
    // And go there. Naming a point and then having to press onwards would be
    // two moves for one thought; the step is the one the point just took, so
    // the count and the progress bar say the same as before.
    //
    // `data-at` counts steps *within the slide*, `goto` takes the index over
    // the whole deck. Confusing the two was measured to jump to slide one on
    // any deck with more than a single slide -- and a one-slide test deck
    // cannot tell the difference, because there the two numbers agree.
    var lokal = parseInt(g.plaetze[g.folge.length - 1], 10);
    var si = STEPS[current].slide;
    for (var k = 0; k < STEPS.length; k++) {
      if (STEPS[k].slide === si && STEPS[k].step === lokal) { goto(k, false); break; }
    }
    return true;
  }

  addEventListener("keydown", function (e) {
    if (tippt(e)) return;
    if (/^[1-9]$/.test(e.key) && adTaste(+e.key)) { e.preventDefault(); return; }
    if (e.key === "ArrowRight" || e.key === "PageDown" || e.key === " ") {
      if (!adPfeil()) goto(current + 1);
      e.preventDefault();
    }
    else if (e.key === "ArrowLeft" || e.key === "PageUp") { goto(current - 1); e.preventDefault(); }
    else if (e.key === "Home") goto(0, true);
    else if (e.key === "End") goto(STEPS.length - 1, true);
    else if (e.key === "o" || e.key === "Escape") {
      buildOverview();
      if (OVERVIEW.dataset.on) OVERVIEW.removeAttribute("data-on");
      else { OVERVIEW.dataset.on = "1"; mark(); }
    } else if (e.key === "f") {
      if (document.fullscreenElement) document.exitFullscreen();
      else document.documentElement.requestFullscreen();
    } else if (e.key === "s") {
      hint(attr(SLIDES[STEPS[current].slide], "note") || CFG.words.noNote);
    } else if (e.key === "?") {
      hint((ROLLE === "speaker" && CFG.words.helpSpeaker) || CFG.words.help);
    } else if (e.key === "p") { print(); }
    // The second window. The keypress is at the same time the user
    // gesture, without which the popup blocker would swallow
    // `window.open`.
    else if (e.key === "n") { oeffneSprecher(); }
  });
  addEventListener("click", function (e) {
    // In the speaker view, `#ts-speaker` covers the stage. A click there
    // applies to whatever gets built into it and should not also page
    // forward on the side.
    if (ROLLE === "speaker") return;
    if (OVERVIEW.dataset.on) return;
    if (e.target.closest && e.target.closest(".ts-embed")) return;
    // A click on a link follows the link. Paging as well would leave the
    // talk on a different slide than the one the speaker pointed at.
    if (e.target.closest && e.target.closest("a")) return;
    goto(current + (e.clientX < innerWidth * 0.25 ? -1 : 1));
  });
  // ── Swiping ───────────────────────────────────────────────────────────────
  //
  // A phone has no arrow keys. Tapping already pages, because a tap raises a
  // click, but a swipe is the gesture people reach for there, and doing
  // nothing at all is the wrong answer.
  //
  // The direction is the natural one: the finger pushes the slide out of the
  // frame towards the left, so the next one comes in behind it. That matches
  // what the slide transition does anyway.
  //
  // In the speaker view the finger draws on the stage, so a swipe there must
  // not page. Outside the stage it may: the note and the preview are a fine
  // place to swipe on a tablet.
  var WISCH = null;

  function wischErlaubt(z) {
    if (OVERVIEW.dataset.on) return false;
    if (!z || !z.closest) return true;
    if (z.closest(".ts-embed")) return false;
    if (ROLLE === "speaker" && z.closest("#ts-stage")) return false;
    // In the speaker view almost everything has a meaning of its own, from
    // the colour swatch to the input field. A tap must not page there, a
    // swipe may; the check further down separates the two.
    return true;
  }

  addEventListener("touchstart", function (e) {
    // Zwei Finger sind ein Zoom und keine Geste von uns.
    if (e.touches.length !== 1 || !wischErlaubt(e.target)) { WISCH = null; return; }
    var t = e.touches[0];
    WISCH = { x: t.clientX, y: t.clientY, zeit: Date.now() };
  }, { passive: true });

  addEventListener("touchmove", function (e) {
    if (WISCH && e.touches.length !== 1) WISCH = null;
  }, { passive: true });

  addEventListener("touchend", function (e) {
    if (!WISCH) return;
    var t = e.changedTouches[0], a = WISCH;
    WISCH = null;
    if (!t) return;
    var dx = t.clientX - a.x, dy = t.clientY - a.y, dauer = Date.now() - a.zeit;
    // The threshold grows with the device: 48 pixels are a swipe on a
    // phone and a twitch on a large tablet.
    var genug = Math.max(48, innerWidth * 0.07);
    var wisch = dauer <= 900 && Math.abs(dx) >= genug
                && Math.abs(dx) >= Math.abs(dy) * 1.3;
    // A tap has to be handled here as well and must not be left to the
    // click.
    //
    // On an iPhone tapping did nothing at all, while the same spot paged in
    // Chrome. The reason is not ours: iOS Safari only builds a click out of
    // a touch if the element it hit strikes it as clickable, that is a link,
    // a button, a form field or something with a click listener of its own.
    // The stage is none of those, and a listener on the window therefore
    // never hears that click. An emulated phone in Chrome does not show
    // this, because Chrome always builds the click.
    var tipp = !wisch && dauer <= 500
               && Math.abs(dx) < 12 && Math.abs(dy) < 12
               && ROLLE !== "speaker";
    if (!wisch && !tipp) return;
    // `preventDefault` holds back the click a browser would otherwise build
    // afterwards out of the same touch. Without it the gesture would still
    // be right, but the click would page a second time right after.
    e.preventDefault();
    if (wisch) { goto(current + (dx < 0 ? 1 : -1)); return; }
    goto(current + (t.clientX < innerWidth * 0.25 ? -1 : 1));
  }, { passive: false });

  addEventListener("touchcancel", function () { WISCH = null; }, { passive: true });

  addEventListener("hashchange", function () {
    // In the speaker window the hash is the role, not a step number. It is
    // neither written nor read there.
    if (ROLLE === "speaker") return;
    var n = +location.hash.slice(1) - 1;
    if (!isNaN(n) && n !== current) goto(n, true);
  });

  fit();
  // Before the first `goto`, because the very first step already has to know
  // whether a point of an adaptive group has been called out yet -- none has,
  // so all of them stand aside until a digit says otherwise.
  adSammeln();
  // The speaker view starts at the first slide and waits for the talk to
  // tell it where it stands. The talk itself takes the number from the
  // hash, this one time and never again after that.
  goto(ROLLE === "speaker"
       ? 0 : Math.max(0, (+location.hash.slice(1) || 1) - 1), true);
  // After the first `goto`, so `schwarzMedien` knows the slide, and still
  // before the first frame: that way the hall stays dark instead of
  // briefly flashing.
  sichtErinnern();
  sprecherAufbau();
  anmeldeSchleife();

  window.typstage = {
    goto: goto, steps: STEPS, slides: SLIDES,
    state: function () { return current; },
    geo: vermessen, build: CFG.build,

    // ── Second window ────────────────────────────────────────────────────
    // `rolle` is "stage" or "speaker" and is fixed from load time on.
    // `box` is the empty container of the speaker view, `ink` the layer
    // above the stage in the talk window where outside content may be drawn.
    rolle: ROLLE,
    box: SPRECHERBOX,
    ink: INK,
    miniatur: miniatur,
    notiz: notiz,
    weiter: weiter,
    oeffneSprecher: oeffneSprecher,
    kanal: {
      sende: sende, strom: strom, horch: horch,
      partner: partner, anmelden: anmelden,
      verbunden: function () { return !!partner(); }
    },

    // ── Speaker view ────────────────────────────────────────────────────────
    // For measuring, and for anything from outside that wants at it.
    sprecher: {
      zeit: function () { return UHR_START ? (Date.now() - UHR_START) / 1000 : 0; },
      ziel: function (m) {
        if (m == null) return ZIEL_MIN;
        ZIEL_MIN = Math.max(0, +m || 0);
        if (ELN.ziel) ELN.ziel.value = ZIEL_MIN ? String(ZIEL_MIN) : "";
        sprecherUhr();
        return ZIEL_MIN;
      },
      striche: function (i) { return TINTE[i == null ? tinteFolie() : i] || []; },
      malen: tinteSenden,
      farbe: function (i) { if (i != null) farbeSetzen(i); return FARBEN[FARBE]; },
      schwarz: function () { return !!SCHWARZ; },
      frost: function () { return !!EIS; },
      eingefroren: function () { return !!FROST; },
      notizPx: function () { return NOTIZ_PX; },
      platz: function () { return PLATZ; },
      bild: schrittBild
    },

    // ── Check surface, part two: the agreed report ──────────────────────────
    //
    // A check run should not have to reach into the runtime. Everything one
    // needs sits here, behind a version number, so a script notices when it
    // meets a deck older than itself instead of quietly measuring nothing.
    //
    // There is no build switch on this. A switch would mean checking a
    // runtime that is not the one shipped, which is the one thing a check may
    // never do. Measured on the six example decks it costs under one percent
    // of the compressed page.
    pruef: {
      fassung: 1,
      bau: CFG.build,
      deck: DECK,
      rolle: ROLLE,
      folien: SLIDES.length,
      schritte: STEPS.length,
      elemente: document.querySelectorAll(".ts-el").length,

      // Where the talk stands. `schritt` counts from zero like `goto`, `hash`
      // is the number in the address, which counts from one.
      stand: function () {
        var st = current >= 0 ? STEPS[current] : null;
        return {
          schritt: current, hash: current + 1,
          folie: st ? st.slide : -1, aufFolie: st ? st.step : -1,
          // Drawn and drawn-muted are counted apart. Whoever only asks "is it
          // there" does not see it when `after: "dimmed"` stops dimming.
          //
          // Twice, over two different areas, because they answer two
          // questions. Over the whole deck the numbers carry the history: a
          // slide left behind keeps its sprites drawn, so the count grows as
          // the talk walks on, and a sprite that changes on a slide nobody is
          // looking at shows up in it. Over the running slide alone they are
          // the state, and only that one can be held against a fresh jump
          // into the same step, which has no history behind it.
          sichtbar: document.querySelectorAll('.ts-el[data-on="1"]').length,
          gedimmt: document.querySelectorAll('.ts-el[data-dim="1"]').length,
          folieSichtbar: st
            ? SLIDES[st.slide].querySelectorAll('.ts-el[data-on="1"]').length : 0,
          folieGedimmt: st
            ? SLIDES[st.slide].querySelectorAll('.ts-el[data-dim="1"]').length : 0,
          flieger: FLUG,
          fehler: FEHLER.length
        };
      },
      fehler: function () { return FEHLER.slice(); },

      // Pin the wall clock, or hand it back with no argument.
      // A number or nothing. Without the check `uhr("abc")` pins the clock to
      // NaN and every flipbook shows nonsense until someone calls `uhr()`.
      uhr: function (ms) {
        if (ms == null) { PRUEFUHR = null; return null; }
        var n = +ms;
        if (!isFinite(n)) { throw new TypeError("typstage: uhr() takes a number of milliseconds, or nothing"); }
        PRUEFUHR = n;
        return PRUEFUHR;
      },

      // Resolves once no animation is running anymore. This is what replaces
      // a fixed wait, which is either too short on a loaded machine or wasted
      // everywhere else, and either way makes a run depend on the day.
      // Resolves with "ruhig", or with "frist" if the deadline ran out while
      // something was still moving, so a run can tell the two apart instead
      // of trusting a settled screen it never saw.
      //
      // It waits for animations and for nothing else. A change that a plain
      // `setTimeout` makes later, such as the fly layer being emptied, is not
      // covered; whoever needs that has to ask at a moment that does not
      // depend on it.
      ruhig: function (frist) {
        var ende = Date.now() + (frist == null ? 4000 : frist);
        return new Promise(function (fertig) {
          (function runde() {
            var alle = document.getAnimations ? document.getAnimations() : [];
            var laeuft = alle.filter(function (a) { return a.playState === "running"; });
            if (!laeuft.length || Date.now() > ende) {
              // Two frames after the last animation, so the styles it left
              // behind have been applied before anyone measures. With a
              // timer beside them, because a hidden tab stops handing out
              // frames altogether -- measured, the promise then never
              // settled and the caller waited for ever. A deadline that only
              // covers the loop and not the way out is no deadline.
              var raus = false;
              var fertigEinmal = function (wie) {
                if (raus) return;
                raus = true;
                fertig(wie);
              };
              setTimeout(function () { fertigEinmal("keine-bilder"); }, 250);
              requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                  fertigEinmal(Date.now() > ende && laeuft.length ? "frist" : "ruhig");
                });
              });
              return;
            }
            Promise.race([
              Promise.all(laeuft.map(function (a) { return a.finished; }))
                .catch(function () {}),
              new Promise(function (r) { setTimeout(r, 120); })
            ]).then(runde);
          })();
        });
      }
    }
  };
})();
