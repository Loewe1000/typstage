
(function () {
  var NS = "http://www.w3.org/2000/svg";
  var B = document.getElementById("ts-stage");
  var FLY = document.getElementById("ts-fly");
  var OVERVIEW = document.getElementById("ts-overview");
  var HINT = document.getElementById("ts-hint");
  var SLIDES = [].slice.call(document.querySelectorAll(".ts-slide"));
  var CFG = JSON.parse(document.getElementById("ts-cfg").textContent);
  var EASE = "cubic-bezier(.4,0,.2,1)";

  // Per-slide settings live on the overlay: it sits inside a `context` and
  // therefore sees marks that were only set while laying out the body.
  function attr(f, name) {
    var o = f.querySelector(".ts-ov");
    return o ? o.dataset[name] : null;
  }

  // ── Step list ─────────────────────────────────────────────────────────────
  // A slide's step count comes from the selectors — those of its elements
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

  // ── Geometry ──────────────────────────────────────────────────────────────
  // Marks live in the background SVG. getCTM() maps them into viewBox
  // coordinates; the result is stored as ratios so any window size fits.
  // Collect every mark currently drawn in the slide — background as well as
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
        w: r.width / bezug.width, h: r.height / bezug.height
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

  // In rounds: a nested element has no mark in the background — the outer
  // element's hide() swallows it — but in the outer element's sprite. That
  // one has to be placed first.
  function stelle(i) {
    var svg = SLIDES[i].querySelector(".ts-bg svg");
    if (!svg) return;
    var bezug = svg.getBoundingClientRect();
    if (!bezug.width) return;
    var offen = [].slice.call(SLIDES[i].querySelectorAll(".ts-el"));
    for (var runde = 0; runde < 4 && offen.length; runde++) {
      var karte = marken(SLIDES[i], bezug);
      var rest = [];
      var skala = bezug.width / CFG.width;   // Bildschirmpixel je Punkt
      offen.forEach(function (el) {
        var r = karte[+el.dataset.n];
        if (!r) { rest.push(el); return; }
        setzen(el, r);
        // Corner radius in points, scaled along with the stage.
        if (el.dataset.radius && +el.dataset.radius > 0) {
          el.style.borderRadius = (+el.dataset.radius * skala) + "px";
          el.style.overflow = "hidden";
        }
        // An iframe measures in real CSS pixels and knows nothing of the
        // stage: in a large window its content would stay small inside a big
        // box. So it is given the size in slide units and then zoomed — that
        // way it always sees the same area.
        //
        // Scaled with `zoom`, not `transform: scale()`. A transform stretches
        // the finished raster; the frame drew 400 pixels wide and would be
        // blown up to 460 — blurry. `zoom` acts before rasterising: the inner
        // window stays 400 points but its pixel density rises with it.
        var frame = el.querySelector("iframe");
        if (frame) {
          var w = r.w * CFG.width, h = r.h * CFG.height;
          var neu = w + "px|" + h + "px|" + skala;
          if (frame.dataset.mass !== neu) {
            frame.dataset.mass = neu;
            // `zoom: false` heißt: den Rahmen in echten Bildschirmpixeln
            // aufspannen und den Inhalt selbst umbrechen lassen. Das ist der
            // Sinn der Abwahl — sonst sähe ein eingebettetes Dokument immer
            // denselben Ausschnitt, nur größer gerastert.
            var ohneZoom = el.dataset.zoom === "0";
            frame.style.width = (ohneZoom ? w * skala : w) + "px";
            frame.style.height = (ohneZoom ? h * skala : h) + "px";
            frame.style.transform = "";
            frame.style.zoom = ohneZoom ? "" : skala;
            // Embedded apps read the pixel density while drawing — after a
            // change they have to recompute.
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
  // done. Whoever sets the state anew has to clear it first — otherwise it
  // wins against the value that was set.
  function clearAnims(el) {
    el.getAnimations().forEach(function (a) { try { a.cancel(); } catch (e) {} });
  }

  function fadeIn(el, name, dur, delay) {
    clearAnims(el);
    // "none" means no effect. Animating from 1 to 1 would not merely be
    // pointless — played backwards it would keep the element visible.
    if (name === "none") { el.style.opacity = "1"; return; }
    var f = EFFECT[name] || EFFECT["fade"];
    el.style.opacity = "";
    var a = el.animate([f[0], f[1]],
      { duration: dur, delay: delay, easing: EASE, fill: "both" });
    a.onfinish = function () { el.style.opacity = "1"; a.cancel(); };
  }

  function fadeOut(el, name, dur) {
    clearAnims(el);
    if (name === "none") { el.style.opacity = "0"; return; }
    var f = EFFECT[name] || EFFECT["fade"];
    var a = el.animate([f[1], f[0]],
      { duration: dur, easing: EASE, fill: "both" });
    a.onfinish = function () { el.style.opacity = "0"; try { a.cancel(); } catch (e) {} };
  }

  // ── Magic move ────────────────────────────────────────────────────────────
  // Typst bakes the font size into the outline: the same glyph has different
  // path data at 20pt and at 34pt, and therefore different symbol ids. For
  // pairing, the outline is normalised to its largest coordinate — what
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

  function glyphs(el) {
    var out = [];
    el.querySelectorAll("use").forEach(function (u) {
      var r = u.getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) return;
      var id = u.getAttribute("xlink:href") || u.getAttribute("href") || "";
      out.push({ id: id, sig: signatur(id), r: r, node: u });
    });
    return out;
  }

  // First in reading order by shape, then whatever is left goes to its
  // nearest counterpart — otherwise a glyph would be dropped merely because
  // it changed places.
  function pairs(a, b) {
    var frei = b.slice(), zug = [], offen = [];
    a.forEach(function (g) {
      var t = -1;
      for (var i = 0; i < frei.length; i++) if (frei[i].sig === g.sig) { t = i; break; }
      if (t < 0) { offen.push(g); zug.push([g, null]); return; }
      zug.push([g, frei[t]]);
      frei.splice(t, 1);
    });
    offen.forEach(function (g) {
      if (!frei.length) return;
      var best = 0, weite = Infinity;
      for (var i = 0; i < frei.length; i++) {
        var dx = frei[i].r.left - g.r.left, dy = frei[i].r.top - g.r.top;
        var w = dx * dx + dy * dy;
        if (w < weite) { weite = w; best = i; }
      }
      for (var k = 0; k < zug.length; k++) {
        if (zug[k][0] === g) { zug[k][1] = frei[best]; break; }
      }
      frei.splice(best, 1);
    });
    // `rest` are target glyphs without a source — those have to fade in.
    return { zug: zug, rest: frei };
  }

  // Lift a glyph out as its own SVG. Both the clip and the clone matrix must
  // be expressed in the source SVG's user coordinate system; getCTM() maps to
  // the viewport instead and would apply the viewBox factor a second time.
  function inBenutzer(node, svg) {
    return svg.getScreenCTM().inverse().multiply(node.getScreenCTM());
  }

  function kastenInBenutzer(node, svg, m) {
    var b = node.getBBox(), p = svg.createSVGPoint(), xs = [], ys = [];
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

  var flyTimers = [];

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
      var d = +dst.dataset.duration || +src.dataset.duration || fallback;
      var qr = src.getBoundingClientRect(), zr = dst.getBoundingClientRect();
      var wie = dst.dataset.match || "auto";
      var qg = glyphs(src), zg = glyphs(dst);
      var perGlyph = wie !== "block" && qg.length > 0 && zg.length > 0 &&
        (wie === "glyph" || (qg.length <= 48 && zg.length <= 48));

      src.dataset.hold = "1";
      dst.dataset.hold = "1";
      var ghosts = [];
      var ueber = 0.42;
      var window = { duration: d * ueber, delay: d * (0.5 - ueber / 2),
                      easing: "linear", fill: "both" };

      var attach = function (node) { FLY.appendChild(node); ghosts.push(node); };

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
      } else {
        var bahn2 = [
          { transform: "translate(0,0) scale(1,1)" },
          { transform: "translate(" + (zr.left - qr.left) + "px," +
            (zr.top - qr.top) + "px) scale(" + (zr.width / qr.width) + "," +
            (zr.height / qr.height) + ")" }
        ];
        var takt2 = { duration: d, easing: EASE, fill: "forwards" };
        var copyOf = function (quelle2) {
          var k = quelle2.cloneNode(true);
          k.className = "ts-ghost";
          k.removeAttribute("data-n");
          k.removeAttribute("data-at");
          k.removeAttribute("data-hold");
          k.style.left = (qr.left - stage.left) + "px";
          k.style.top = (qr.top - stage.top) + "px";
          k.style.width = qr.width + "px";
          k.style.height = qr.height + "px";
          return k;
        };
        var ank2 = copyOf(dst);
        ank2.style.opacity = "1";
        attach(ank2);
        ank2.animate(bahn2, takt2);

        var ghost = copyOf(src);
        ghost.style.opacity = "1";
        attach(ghost);
        ghost.animate(bahn2, takt2);
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
  function beat(current) {
    for (var k = 0; k < ticking.length; k++) {
      var t = ticking[k];
      var n = +t.el.dataset.frames, fps = +t.el.dataset.fps || 30;
      if (!n) continue;
      var i = Math.floor((current - t.t0) / 1000 * fps);
      if (t.el.dataset.pingpong === "1") {
        var p = n > 1 ? 2 * n - 2 : 1;
        var m = i % p;
        i = m < n ? m : p - m;
      } else if (t.el.dataset.loop === "0") { i = Math.min(i, n - 1); }
      else { i = i % n; }
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
          + ' named "' + n + '" — both get every job. Give one its own name.');
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
      console.warn("motion: GeoGebra hat abgelehnt: " + d.failed.join(", "));
      return;
    }
    if (d.ready == null) return;
    var lebt = null;
    document.querySelectorAll(".ts-bridged iframe").forEach(function (r) {
      if (r.contentWindow === e.source) lebt = r;
    });
    if (!lebt) return;
    lebt.dataset.live = "1";
    lebt.closest(".ts-el").dataset.bereit = "1";
    var st = STEPS[current];
    if (st) drive(st.slide, st.step, true);
  });

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

    SLIDES[dst.slide].querySelectorAll(".ts-el").forEach(function (el) {
      var an = activeAt(el.dataset.at, dst.step);
      var d = +el.dataset.duration || CFG.duration;
      var delay = back ? 0 : (+el.dataset.delay || 0);

      if (instant || changed) {
        clearAnims(el);
        if (an) { el.dataset.on = "1"; el.style.opacity = "1"; }
        else { delete el.dataset.on; el.style.opacity = "0"; }
        return;
      }

      if (an && el.dataset.on !== "1") {
        el.dataset.on = "1";
        fadeIn(el, el.dataset.enter || "fade-up", d, delay);
      } else if (!an && el.dataset.on === "1") {
        delete el.dataset.on;
        if (back) fadeOut(el, el.dataset.enter || "fade-up", d);
        else fadeOut(el, el.dataset.exit || "fade", d * 0.75);
      }
    });

    mediaOn(dst.slide);
    drive(dst.slide, dst.step, back || changed);
    if (location.hash !== "#" + (n + 1)) history.replaceState(null, "", "#" + (n + 1));
    mark();
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
  var minis = [];
  function buildOverview() {
    if (minis.length) return;
    SLIDES.forEach(function (f, i) {
      var m = document.createElement("div");
      m.className = "ts-mini";
      m.innerHTML = f.querySelector(".ts-bg").innerHTML;
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

  // ── Skalieren ─────────────────────────────────────────────────────────────
  function fit() {
    var v = CFG.width / CFG.height;
    // Thumbnails and printed pages hold their shape with padding, which needs
    // the ratio as a number — it is not 16:9 for every deck.
    document.documentElement.style.setProperty(
      "--ts-ratio", (100 / v) + "%");
    var bw = Math.min(innerWidth, innerHeight * v);
    B.style.width = bw + "px";
    B.style.height = (bw / v) + "px";
    if (current >= 0) stelle(STEPS[current].slide);
  }
  addEventListener("resize", fit);

  // ── Steuerung ─────────────────────────────────────────────────────────────
  var hintTimer;
  function hint(t) {
    HINT.textContent = t;
    HINT.dataset.on = "1";
    clearTimeout(hintTimer);
    hintTimer = setTimeout(function () { delete HINT.dataset.on; }, 2600);
  }
  addEventListener("keydown", function (e) {
    if (e.key === "ArrowRight" || e.key === "PageDown" || e.key === " ") { goto(current + 1); e.preventDefault(); }
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
      hint(attr(SLIDES[STEPS[current].slide], "note") || "keine Notiz");
    } else if (e.key === "?") {
      hint("← → blättern · o Übersicht · f Vollbild · s Notiz · p Druck");
    } else if (e.key === "p") { print(); }
  });
  addEventListener("click", function (e) {
    if (OVERVIEW.dataset.on) return;
    if (e.target.closest && e.target.closest(".ts-embed")) return;
    goto(current + (e.clientX < innerWidth * 0.25 ? -1 : 1));
  });
  addEventListener("hashchange", function () {
    var n = +location.hash.slice(1) - 1;
    if (!isNaN(n) && n !== current) goto(n, true);
  });

  fit();
  goto(Math.max(0, (+location.hash.slice(1) || 1) - 1), true);

  window.typstage = {
    goto: goto, steps: STEPS, slides: SLIDES,
    state: function () { return current; },
    geo: vermessen, build: CFG.build
  };
})();
