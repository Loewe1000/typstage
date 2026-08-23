
(function () {
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

  // ── Die Rolle, einmal und für immer ───────────────────────────────────────
  //
  // Dieselbe Datei trägt zwei Ansichten: den Vortrag und, mit `#speaker` an
  // der Adresse, die Sprecheransicht. Welche gemeint ist, steht im Hash, und
  // genau da liegt die Falle, denn der Hash gehört sonst dem laufenden
  // Schritt: `goto` schreibt ihn fort. Das erste `goto` würde `#speaker`
  // überschreiben, und die Ansicht kippte mitten im Laden zurück. Deshalb wird
  // die Rolle hier einmal gelesen und danach nie wieder aus dem Hash geholt;
  // im Sprecherfenster wird der Hash überdies gar nicht mehr angefasst.
  var ROLLE = (location.hash.slice(1).split(/[&=]/)[0] || "").toLowerCase()
              === "speaker" ? "speaker" : "stage";
  if (ROLLE === "speaker") document.documentElement.dataset.tsRolle = "speaker";

  // ── Doppelte SVG-Kennungen entschärfen ───────────────────────────────────
  //
  // Typst leitet die Kennungen in einem SVG aus dem Inhalt ab. Derselbe
  // beschnittene Kasten zweimal auf einer Folie — einmal im Hintergrund und
  // einmal als Sprite, oder schlicht zweimal — ergibt deshalb dieselbe
  // `<clipPath id>` zweimal. In HTML muss eine Kennung eindeutig sein, also
  // bindet `url(#…)` ans erste Vorkommen: der zweite Kasten wird gegen fremde
  // Maße beschnitten und verschwindet meist ganz. Dasselbe trifft die
  // `<symbol id>` der Glyphen.
  //
  // Umbenannt wird nur, was wirklich doppelt ist, und Verweise werden nur
  // innerhalb desselben SVG umgebogen — dort, wo sie hingehören.
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

  // ── Welches Deck ist das hier ─────────────────────────────────────────────
  //
  // Bei `file://` teilen sich in Chrome *alle* lokalen Dateien denselben
  // Ursprung: `location.origin` ist wörtlich "file://". Alles, was am Ursprung
  // hängt, gehört damit nicht diesem Deck, sondern jeder Datei auf der
  // Platte. Zwei Stellen brauchen deshalb eine Kennung, die das Deck meint
  // und nicht den Ursprung: das Gedächtnis über das Neuladen hinweg, und der
  // Handschlag zwischen den Fenstern.
  //
  // Der Pfad unterscheidet die Dateien, die Zählung dahinter unterscheidet
  // zwei Stände derselben Datei.
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
        w: r.width / bezug.width, h: r.height / bezug.height,
        // Wer der Wirt ist, steht hier schon fest: ein Marker, der in einem
        // Sprite liegt, gehört einem verschachtelten Element. Der Schrittwechsel
        // braucht das, um Einblendwerte vom Elternteil zu erben.
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

  // Was ein verschachteltes Element nicht selbst angibt, erbt es von seinem
  // Wirt — aber nur, wenn beide im selben Schritt erscheinen (gleiches `at`).
  // Grund: Sprites hängen als Geschwister im Overlay, nicht ineinander. Ein
  // `translateY` des Elternteils trägt das Kind also nicht mit; sie laufen nur
  // dann im Gleichschritt, wenn sie dieselbe Bewegung mit denselben Werten
  // ausführen. Wich einer ab — etwa `delay: 120` bei einer gestaffelten Liste
  // gegen 0 beim Morph darin —, kam das Kind vor seinem eigenen Behälter.
  function erbt(el, feld) {
    if (el.dataset[feld] !== undefined) return el.dataset[feld];
    if (!el.dataset.parent) return undefined;
    var folie = el.closest(".ts-slide");
    if (!folie) return undefined;
    var wirt = folie.querySelector('.ts-el[data-n="' + el.dataset.parent + '"]');
    if (!wirt || wirt.dataset.at !== el.dataset.at) return undefined;
    return wirt.dataset[feld];
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
        if (r.wirt) el.dataset.parent = r.wirt; else delete el.dataset.parent;
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

  // Pins liegen als durchsichtige Rechtecke hinter ihrem Inhalt — dieselbe
  // Bauart wie die Elementmarken, nur mit #fd statt #fe. Die Zahl darin ist
  // aus dem Namen gerechnet, gleiche Namen ergeben also dieselbe Zahl.
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

  // Der Kasten einer Glyphe in Bildschirmkoordinaten.
  //
  // Nicht `getBoundingClientRect()`, obwohl das der naheliegende Weg wäre: auf
  // einem `<use>` liefert Firefox dafür nicht den Kasten der Glyphe, sondern
  // den des ganzen SVG. Gemessen an einer Gleichung mit 23 Zeichen gab Chrome
  // 25x23, 16x24, 34x34 und Firefox 476x43 für *jedes* Zeichen. Da der Geist
  // seine Größe aus diesem Kasten bekommt, wurde dort jeder Buchstabe auf die
  // Breite der Formel gezogen. Genau das war als „alle Buchstaben quergezogen"
  // gemeldet worden.
  //
  // `getBBox()` stimmt dagegen in beiden Motoren überein (16x14, 10x15, 21x21),
  // und `getScreenCTM()` rechnet es in Bildschirmmaße um. Alle vier Ecken, weil
  // eine Matrix auch drehen und scheren kann. In Chrome kommt damit auf das
  // Pixel dasselbe heraus wie zuvor.
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
      // Die Glyphe gehört zu dem Pin, in dessen Feld ihre Mitte liegt. Bei
      // geschachtelten Pins gewinnt das kleinste — sonst schluckte ein Pin um
      // den ganzen Term die Namen der Zeichen darin.
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
  // nearest counterpart — otherwise a glyph would be dropped merely because
  // it changed places.
  function pairs(a, b) {
    var frei = b.slice(), zug = [];
    // Erst die Pins: gleiche Namen finden zueinander, bevor die Form befragt
    // wird. Ein Pin ohne Gegenstück fällt danach in den Formabgleich zurück.
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
    // Kein Rückfall auf das nächstgelegene freie Zeichen. Wer keine gleiche
    // Form findet, blendet an seinem Platz aus, und das neue blendet an seinem
    // ein. Ein Doppelpunkt, der sich in einen Buchstaben zieht, ist kein Flug,
    // sondern ein Schmieren — und welches Zeichen räumlich am nächsten liegt,
    // sagt nichts darüber, ob die beiden etwas miteinander zu tun haben.
    //
    // Wer zwei Zeichen aufeinander beziehen will, deren Form sich unterscheidet,
    // gibt ihnen mit `pin` denselben Namen. Das ist ausgesprochen und
    // nachvollziehbar; Nachbarschaft ist es nicht.

    // Ein Pin darf sich zweimal aufs Ziel legen: dann teilt sich das Zeichen
    // sichtbar in zwei. Genau das braucht die Potenzregel — der Exponent tritt
    // vorn als Faktor auf und bleibt zugleich oben stehen. Gesucht wird
    // deshalb auch unter den bereits vergebenen Quellen.
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
    // `rest` are target glyphs without a source — those have to fade in.
    return { zug: zug, rest: frei };
  }

  // Lift a glyph out as its own SVG. Both the clip and the clone matrix must
  // be expressed in the source SVG's user coordinate system; getCTM() maps to
  // the viewport instead and would apply the viewBox factor a second time.
  function inBenutzer(node, svg) {
    return svg.getScreenCTM().inverse().multiply(node.getScreenCTM());
  }

  // Die Strichstärke, sofern der Knoten überhaupt strichelt. Glyphen-Umrisse
  // haben nur eine Füllung und liefern 0 — daran lassen sie sich erkennen.
  function strichBreite(node) {
    var st = node.getAttribute("stroke");
    if (!st || st === "none") return 0;
    return parseFloat(node.getAttribute("stroke-width")
                      || getComputedStyle(node).strokeWidth) || 0;
  }

  function kastenInBenutzer(node, svg, m) {
    var b = node.getBBox(), p = svg.createSVGPoint(), xs = [], ys = [];
    // `getBBox` misst die Geometrie ohne den Strich. Ein waagerechter
    // Wurzelstrich ist damit null hoch, und sein Doppel bliebe unsichtbar.
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

  // Was gezeichnet und nicht gesetzt ist: Wurzelbögen, Bruchstriche,
  // Gleichheitsbalken, Rahmen. `glyphs()` sammelt nur `<use>`, diese Teile also
  // nicht — und weil `[data-hold]` das ganze Element verbirgt, waren sie
  // während des Fluges verschwunden und erschienen erst am Ende schlagartig.
  function striche(el) {
    var out = [];
    el.querySelectorAll("path").forEach(function (n) {
      var sw = strichBreite(n);
      if (sw <= 0) return;              // Glyphen-Umriss, kein gezeichneter Strich
      var r = n.getBoundingClientRect();
      if (r.width <= 0 && r.height <= 0) return;
      // Auch auf dem Schirm um die halbe Strichstärke weiten, sonst wäre der
      // Kasten des Doppels in einer Richtung null.
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
      var d = +dst.dataset.fly || +src.dataset.fly || fallback;
      var qr = src.getBoundingClientRect(), zr = dst.getBoundingClientRect();
      // Von beiden Seiten, wie schon die Flugdauer eine Zeile darüber: Beim
      // Zurückblättern tauschen Quelle und Ziel die Rollen, und wer `match` nur
      // am Ziel liest, findet dort die Vorgabe. In theme-editorial trägt die
      // lange Zeile `match: "glyph"`; rückwärts ist sie die Quelle, und aus dem
      // Flug wurde ein Blockschub.
      //
      // `"auto"` zählt dabei als „nicht gewählt" und nicht als Antwort — der
      // Wert steht als Vorgabe an *jedem* Morph, ein bloßes `||` käme deshalb
      // nie bis zur Quelle durch. Eine ausdrückliche Wahl auf einer der beiden
      // Seiten gilt für den Flug zwischen ihnen, in beide Richtungen.
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
        // Striche gehen denselben Weg wie ein Zeichen ohne Partner: das alte
        // blendet aus, das neue ein. Gepaart wird nicht — ein Wurzelbogen und
        // ein Gleichheitsbalken haben nichts miteinander zu tun.
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
        // Jede Kopie liegt in *ihrem eigenen* Kasten und wird von dort bewegt.
        //
        // Vorher lagen beide im Kasten der Quelle. Für die Quelle stimmt das,
        // für das Ziel nicht. Die Regel `.ts-ghost svg` zwingt das SVG auf
        // volle Breite und Höhe der Kopie, das Ziel wurde also in ein fremdes
        // Seitenverhältnis eingepasst; und weil ein SVG dabei sein eigenes
        // Verhältnis wahrt, blieb Luft an zwei Rändern. Die anisotrope
        // Skalierung danach nahm das nicht zurück. Am Ende des Fluges stand die
        // Zeichnung deshalb in anderen Proportionen da als das echte Element,
        // das eine Zehntelsekunde später an ihre Stelle trat.
        //
        // Gemessen im Editorial-Deck, Bild für Bild: von 760ms bis 840ms
        // bewegte sich nichts mehr, der Flug saß. Bei 920ms sprangen dann 824
        // Pixel um, rückwärts 302. Genau das ist der Ruck, den man sieht.
        //
        // Jetzt liegt das Ziel von Anfang an in seinem eigenen Kasten und
        // startet zusammengestaucht auf dem der Quelle. Es endet bei
        // scale(1,1) und ist damit Pixel für Pixel das, was danach dasteht:
        // beide Richtungen 0 statt 824 und 302.
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
        // Der Ursprung der Geister liegt oben links (siehe CSS), deshalb setzt
        // sich der Weg schlicht aus Verschiebung und Streckung zusammen.
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

  // ── Der Kanal zwischen den Fenstern ───────────────────────────────────────
  //
  // Ein Vortrag und seine Sprecheransicht sind zwei Fenster auf derselben
  // Datei. `window.open` setzt im geöffneten Fenster `window.opener`, und
  // `postMessage` trägt über diesen Griff in beide Richtungen, auch von einer
  // `file://`-Seite aus, wo `localStorage` nicht taugt: Firefox gibt seit 68
  // jeder lokalen Datei einen eigenen Ursprung, und dann sieht keiner den
  // Speicher des anderen.
  //
  // Jede Nachricht trägt `typstage: 1` und dazu ein eigenes Feld `kanal`.
  // Das `typstage` allein reicht nicht: darüber läuft schon die Brücke zu den
  // eingebetteten Dokumenten (`{typstage: 1, ready: 1}` und ihre Aufträge).
  // Die beiden Empfänger sortieren einander deshalb am `kanal` aus: die
  // Brücke steigt bei `d.ready == null` aus, dieser hier bei fehlendem
  // `kanal`.
  //
  // Ohne Partner tut hier alles nichts. Ein Deck, das nie ein zweites Fenster
  // öffnet, verhält sich Zeile für Zeile wie zuvor.
  var PARTNER = null;   // das andere Fenster, sobald es sich gemeldet hat
  var KIND = null;      // der Griff aus window.open, nur zum Wiederfinden
  var HOERER = Object.create(null);
  var stumm = 0;        // >0, solange wir einer Fernbedienung folgen

  // Ein geschlossenes Fenster bleibt als Griff liegen, taugt aber nichts mehr.
  function partner() {
    if (PARTNER) { try { if (PARTNER.closed) PARTNER = null; } catch (x) {} }
    return PARTNER;
  }

  function sende(art, daten) {
    var p = partner();
    if (!p) return false;
    var m = { typstage: 1, kanal: art, deck: DECK };
    if (daten) for (var k in daten) m[k] = daten[k];
    // Bei `file://` ist der Ursprung "null"; ein genauer Zielursprung ließe
    // die Nachricht fallen. Gefiltert wird stattdessen am Inhalt.
    try { p.postMessage(m, "*"); } catch (x) { return false; }
    return true;
  }

  // Für alles, was später dazukommt: eine eigene Nachrichtenart braucht keinen
  // Eingriff in den Empfänger unten, nur ein `horch("meinding", fn)`.
  function horch(art, fn) { (HOERER[art] || (HOERER[art] = [])).push(fn); }

  // ── Ein Strom statt einzelner Nachrichten ─────────────────────────────────
  //
  // Manches kommt nicht alle paar Sekunden, sondern im Takt der Maus: ein
  // Strich, den einer in der Sprecheransicht zieht, ist eine Folge von
  // Punkten. Eine Nachricht je Punkt wäre Verschwendung, denn jede kostet auf der
  // Gegenseite einen eigenen Durchlauf durch den Empfänger, und bei
  // gedrückter Maus sind das Hunderte.
  //
  // `strom` sammelt deshalb und schickt einmal je Bild ein Bündel:
  // `{kanal: art, punkte: [...]}`. Der Empfänger drüben bekommt dieselbe Art
  // wie bei `sende`, nur eben mit `punkte` statt eines einzelnen Werts.
  // Gesammelt wird nur, wenn überhaupt jemand zuhört; und wer in einem
  // verdeckten Fenster sammelt, bekommt kein Bild, deshalb die Schranke, die
  // ein volles Bündel notfalls auch ohne Bild losschickt.
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
  // Ein Bild, das noch aussteht, während die Schranke schon geleert hat,
  // findet dann nichts mehr vor und kehrt gleich um. Abbestellen lohnt nicht.
  function stromAus() {
    stromTakt = 0;
    var s = STROM;
    STROM = null;
    if (!s) return;
    for (var art in s) sende(art, { punkte: s[art] });
  }

  // Ein Schritt, der von drüben kommt, darf nicht zurückgemeldet werden:
  // sonst schickten sich die beiden Fenster dieselbe Zahl ohne Ende hin und
  // her. `stumm` legt `melde` für die Dauer des Sprungs still.
  // Eingefroren heißt: der Vortrag nimmt den fremden Schritt entgegen, zeigt
  // ihn aber nicht. Er merkt sich nur, wo der Vortragende inzwischen steht,
  // und holt es beim Auftauen nach. Ohne Sprecherfenster ist `FROST` null und
  // die Zeile kostet nichts.
  var FROST = 0, FROST_ZIEL = null;
  function fernGoto(n, instant) {
    if (typeof n !== "number" || isNaN(n) || n === current) return;
    if (FROST) { FROST_ZIEL = n; return; }
    stumm++;
    try { goto(n, instant); } finally { stumm--; }
  }

  // Jeder Schrittwechsel geht hinüber: der Vortrag meldet, wo er steht, die
  // Sprecheransicht bittet um den Schritt. Beim Vortrag ist die Bitte ein
  // richtiger Wechsel mit Übergang, die Meldung an die Sprecheransicht dagegen
  // ein Sprung ohne Bewegung, dort wird die Bühne ohnehin zugedeckt.
  function melde(n) {
    if (stumm) return;
    sende(ROLLE === "speaker" ? "gehe" : "schritt", { n: n });
  }

  // ── Wer ist drüben, und ist er noch derselbe ──────────────────────────────
  //
  // Jedes Fenster bekommt beim Laden eine Kennung. Sie steht in der Antwort
  // auf `hallo`, und daran erkennt die Gegenseite, ob dort noch dasselbe
  // Fenster sitzt oder ein neu geladenes. Das ist der ganze Unterschied
  // zwischen "die Meldung wiederholt sich" und "drüben hat jemand neu
  // geladen", und ohne ihn liefen die beiden nach einem Neuladen des
  // Vortragsfensters still auseinander: `window.opener` überlebt drüben das
  // Neuladen, der Griff in der Gegenrichtung nicht.
  var SITZUNG = String(Date.now()) + "." + Math.floor(Math.random() * 1e6);
  var FERN_SITZUNG = null;   // die Kennung, die zuletzt von drüben kam
  var FRISCH = 1;            // dieses Fenster hat sich noch nie abgeglichen
  var LETZTER_SCHLAG = Date.now();   // wann zuletzt überhaupt etwas ankam
  var SICHT_GESENDET = 0;            // wann zuletzt ein eigener Sichtbefehl ging

  // Die Begrüßung, also die Antwort auf `hallo`. Sie wiederholt sich im Takt
  // des Herzschlags, gehandelt wird deshalb nur bei einer neuen Kennung.
  //
  // Wer neu geladen ist, übernimmt den Stand des anderen; wer schon lief,
  // gibt seinen weiter. Damit findet ein neu geladenes Vortragsfenster
  // zurück, ohne dass die Ansicht ihren Platz verliert, und eine neu
  // geöffnete Ansicht zeigt, was im Saal wirklich steht, statt "hell und
  // aufgetaut" zu behaupten, während es dort schwarz ist.
  function begruessung(d) {
    // Zuerst und bei jedem Schlag: was der Vortrag von sich aus entschieden
    // hat, gilt. Er ist das Fenster, das die Sicht wirklich zeigt; hier steht
    // nur die Anzeige darüber. Hebt er Schwarz oder Frost selbst auf, stünde
    // hier sonst weiter "eingefroren", und die Tasten wären verkehrt herum:
    // der erste Druck auf `b` schaltete aus, was gar nicht mehr an war, und
    // fror dabei den Vortrag wieder ein, weil beide Werte zusammen gehen.
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
    // Ein neuer Partner bekommt alles, was hier steht: die Sicht, den Schritt
    // und die Striche.
    //
    // Die Sicht zuerst, und das ist keine Geschmacksfrage. Ein neu geladenes
    // Vortragsfenster ist aufgetaut; käme `gehe` vor `sicht`, führte es den
    // Sprung aus, ehe es wieder einfriert, und das Einfrieren bräche beim
    // Neuladen still. In dieser Reihenfolge landet der Schritt in
    // `FROST_ZIEL`, wo er hingehört.
    sichtSenden();
    sende("gehe", { n: current });
    if (TINTE_AN) sende("tintestand", { liste: tinteAbschrift() });
  }

  addEventListener("message", function (e) {
    var d = e.data;
    if (!d || d.typstage !== 1 || !d.kanal) return;
    // Zwei Fenster gehören nur dann zusammen, wenn sie dasselbe Deck zeigen.
    // Ohne diese Zeile paart sich eine Sprecheransicht anstandslos mit einem
    // fremden Vortrag: navigiert einer im selben Tab zu einem anderen Deck,
    // steuerte die Ansicht danach etwas, das sie gar nicht zeigt. Vor allem
    // anderen geprüft, damit auch der Partnergriff nicht gesetzt wird.
    if (d.deck !== DECK) return;
    // Wer schreibt, ist ab jetzt der Partner. Das trägt über ein Neuladen
    // hinweg: das nachgeladene Fenster meldet sich erneut, und der tote Griff
    // wird dabei schlicht überschrieben.
    if (e.source) PARTNER = e.source;
    LETZTER_SCHLAG = Date.now();
    if (d.kanal === "hallo") {
      sende("schritt", { n: current, folien: SLIDES.length,
                         schritte: STEPS.length, rolle: ROLLE,
                         sitzung: SITZUNG,
                         schwarz: document.documentElement.dataset.tsSchwarz ? 1 : 0,
                         frost: FROST });
      // Den Bestand nur an ein frisch geladenes Gegenüber. Sonst schöben
      // sich die beiden im Takt des Herzschlags dieselben Striche zu.
      if (d.frisch && TINTE_AN) sende("tintestand", { liste: tinteAbschrift() });
    } else if (d.kanal === "schritt") {
      // Mit Kennung ist es eine Begrüßung, ohne ein wirklicher Schrittwechsel.
      // Der Unterschied zählt: der Begrüßung blind zu folgen hieße, jede
      // Sekunde dorthin zu springen, wo der Vortrag steht, und genau das ist
      // beim Einfrieren nicht gewollt.
      if (d.sitzung !== undefined) begruessung(d);
      else fernGoto(d.n, true);
    } else if (d.kanal === "gehe") {
      fernGoto(d.n, false);
    }
    var hs = HOERER[d.kanal];
    if (hs) for (var i = 0; i < hs.length; i++) hs[i](d, e);
  });

  // Das geöffnete Fenster meldet sich beim Öffner, und zwar dauerhaft.
  //
  // Einmal reichte nicht. `window.opener` überlebt ein Neuladen des
  // Vortragsfensters, der Griff dorthin überlebt es nicht: nach einem
  // Neuladen weiß der Vortrag von niemandem mehr, und weil er sich nie von
  // sich aus meldet, blieben die beiden für immer getrennt. Eine Nachricht je
  // Sekunde führt sie wieder zusammen und kostet nichts.
  function anmelden() {
    if (ROLLE !== "speaker") return false;
    var o = null;
    // Erst das Fenster, das diese Ansicht selbst aufgemacht hat: nur das gibt
    // es, wenn der Vortrag zwischendurch geschlossen wurde.
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

  // Die Taste öffnet das zweite Fenster. Ohne Nutzergeste fiele `window.open`
  // dem Popup-Blocker zum Opfer, der Tastendruck ist die Geste. Der Name im
  // zweiten Argument sorgt dafür, dass ein zweiter Druck dasselbe Fenster
  // trifft statt ein drittes zu öffnen.
  function oeffneSprecher() {
    if (ROLLE === "speaker") {
      // Andersherum: aus der Sprecheransicht holt die Taste den Vortrag nach
      // vorn, statt eine Sprecheransicht der Sprecheransicht aufzumachen.
      var o = partner();
      if (o) { try { o.focus(); } catch (x) {} return o; }
      try { if (KIND && !KIND.closed) { KIND.focus(); return KIND; } } catch (y) {}
      // Ist der Vortrag zu, holt dieselbe Taste einen neuen. Sonst blätterte
      // und zeichnete die Ansicht für immer ins Leere, und an den Saal käme
      // niemand mehr heran. Das neue Fenster meldet sich, bekommt über die
      // Begrüßung den laufenden Schritt samt Strichen und steht damit da, wo
      // die Ansicht steht.
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

  // ── Striche auf der Folie ─────────────────────────────────────────────────
  //
  // Gezeichnet wird in der Sprecheransicht, zu sehen ist es im Vortrag: der
  // Vortragende hat Maus und Trackpad vor sich, die Leinwand hat er nicht.
  // Gerechnet wird deshalb in Anteilen der Bühne (0 bis 1) statt in Pixeln.
  // Zwei Fenster sind selten gleich groß; ein Pixelwert säße drüben an einer
  // anderen Stelle, ein Anteil sitzt an derselben.
  //
  // Die Striche kleben an ihrer Folie. `TINTE[folie]` ist die Liste ihrer
  // Striche, und in der Zeichenebene liegen immer nur die der laufenden
  // Folie. Wer vorblättert und zurückkommt, findet sie wieder.
  //
  // Solange niemand gezeichnet hat, ist `TINTE_AN` null und dieser ganze
  // Abschnitt rührt nichts an: ein Deck ohne Sprecherfenster merkt von ihm
  // nichts.
  var TINTE = [], TINTE_AN = 0, TINTE_SVG = null, TINTE_FOLIE = -1;
  var FARBEN = ["#eb5e28", "#ffd166", "#4cc9f0", "#f4f4f5"];
  var STRICH_PT = 3.2;    // Strichstärke in Punkten der Bühne, skaliert mit ihr

  function tinteListe(i) { return TINTE[i] || (TINTE[i] = []); }

  // Ein SVG im Maß der Bühne. Der viewBox ist das Folienformat selbst, dann
  // stimmen Seitenverhältnis und Strichstärke ohne weitere Rechnung, und die
  // Anteile werden schlicht mit Breite und Höhe multipliziert.
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

  // Ein Strich bekommt seine Linie einmal und behält sie. Nachgetragen wird je
  // Bündel genau ein Attribut. Wer drüben je Punkt ein Element anlegte, machte
  // das Bündeln beim Sender wieder zunichte.
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

  // Die Striche der laufenden Folie in die Ebene, alles andere heraus. Steht
  // schon die richtige Folie darin, ist nichts zu tun.
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

  // Ein einzelnes Ereignis in den Bestand: entweder ein Punkt, oder ein
  // Befehl. Beides läuft durch denselben Strom, damit die Reihenfolge hält.
  // Ein `sende` neben dem Strom käme vor dem noch ausstehenden Bündel an, und
  // ein Löschen überholte die Punkte, die es löschen sollte.
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
    // Die laufende Nummer trennt die Striche: eine neue Nummer heißt, dass
    // die Maus zwischendurch los war.
    if (!s || s.n !== ev.n) {
      s = { n: ev.n, farbe: ev.f || FARBEN[0], punkte: [], knoten: null };
      liste.push(s);
    }
    s.punkte.push({ x: ev.x, y: ev.y });
    if (ev.s === tinteFolie() && schmutz.indexOf(s) < 0) schmutz.push(s);
  }

  // Ein ganzes Bündel auf einmal, und erst danach gezeichnet.
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
  // Der Vortrag hört zu. Die Sprecheransicht bekommt nichts davon, sie
  // schickt nur; deshalb gibt es keine Rückkopplung.
  horch("tinte", function (d) { tinteBuendel(d.punkte); });

  // Was schon auf den Folien steht, geht bei der Anmeldung einmal hinüber.
  // Sonst sähe eine neu geladene Sprecheransicht leere Folien, während im
  // Saal die Striche von vorhin stehen, und der Vortragende radierte an
  // etwas herum, das er gar nicht mehr vor sich hat. Die Knoten bleiben
  // dabei zurück: ein DOM-Element lässt sich nicht verschicken.
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
      // Der nächste eigene Strich muss eine Nummer bekommen, die drüben noch
      // nicht vergeben ist, sonst wüchse er an einen fremden an.
      if (q.n >= STRICH_NR) STRICH_NR = q.n + 1;
      TINTE_AN = 1;
    }
    tinteNeu();
  }
  horch("tintestand", function (d) { tinteEinlesen(d.liste); });

  // ── Vortragsfenster: schwarz ──────────────────────────────────────────────
  //
  // pdfpc trennt zwei Dinge, und das ist übernehmenswert: *schwarz* macht den
  // Saal dunkel, *einfrieren* lässt das Bild stehen, während der Vortragende
  // in seiner Ansicht schon weiterblättert. Das Erste hängt an einem Attribut
  // am Wurzelelement und ist reine Darstellung; das Zweite steckt in
  // `fernGoto`, denn dort kommt der fremde Schritt an.
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
    // Nur das wieder anwerfen, was vorher auch lief: ein Video, das der
    // Vortragende von Hand angehalten hatte, bleibt angehalten.
    gehaltene.forEach(function (v) {
      var p = v.play(); if (p && p.catch) p.catch(function () {});
    });
    gehaltene = [];
  }
  function auftauen() {
    FROST = 0;
    // Beim Auftauen holt der Vortrag nach, was er verpasst hat.
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

  // Ein Neuladen des Vortragsfensters ließ den Saal für die Dauer des Ladens
  // hell werden, bis der nächste Herzschlag das Schwarz zurückbrachte: ein
  // sichtbarer Blitz auf eine Folie, die niemand sehen soll. `sessionStorage`
  // gehört genau diesem einen Tab und überlebt genau dessen Neuladen, mehr
  // wird davon nicht verlangt. Der Kanal bleibt `postMessage`; das hier ist
  // nur ein Gedächtnis über das Laden hinweg, und schlägt es fehl, ist alles
  // wie zuvor.
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
    // Der Wächter hebt das gleich wieder auf, wenn niemand mehr da ist: eine
    // Erinnerung ohne Partner ist genau der Fall, für den er gebaut ist.
    wacheAn();
  }

  // Ein Saal, der schwarz bleibt, weil das Fenster mit der Taste zugegangen
  // ist, ist das Schlimmste, was diese Ansicht anrichten kann: im
  // Vortragsfenster gibt es keine Taste dagegen, und es soll auch keine
  // geben, denn ein Deck ohne Sprecheransicht darf keine neue kennen.
  // Bleibt der Herzschlag aus oder ist der Partner fort, hebt der Vortrag
  // Schwarz und Frost von sich aus auf. Der Wächter läuft erst, wenn eines
  // von beidem an ist, und hört wieder auf, sobald beides aus ist.
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
      // Gemessen wird der Partner, nicht die Uhr. `closed` am Fenstergriff
      // ist genau dieses Signal: es ist synchron, es lügt nicht, und es ist
      // eine der wenigen Eigenschaften, die auch über Ursprungsgrenzen hinweg
      // lesbar sind. Es trägt damit dort, wo Firefox jeder lokalen Datei
      // einen eigenen Ursprung gibt.
      if (!partner()) { sichtLoesen(); return; }
      // Stockte dieser Strang selbst, sagt ein altes `LETZTER_SCHLAG` nichts
      // über den Partner aus: dessen Nachrichten liegen dann noch in der
      // Schlange und werden gleich zugestellt. Wer das verwechselt, hebt das
      // Einfrieren auf, weil das eigene Fenster einen Augenblick beschäftigt
      // war. Deshalb setzt ein verspäteter eigener Schlag die Frist zurück.
      if (eigenerVerzug > 2500) { LETZTER_SCHLAG = jetzt; return; }
      // Was bleibt, ist ein grobes Netz für den einen Fall, den `closed`
      // nicht kennt: das Fenster steht offen, trägt aber inzwischen eine
      // andere Seite. Eine Minute, damit kein bloßes Stocken hineinfällt.
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

  // ── Sprecheransicht: die Bausteine ────────────────────────────────────────

  // Die Notiz einer Folie, leer wenn keine da ist. Sie steht als `data-note`
  // an der Overlay-Ebene, weil die im Kontext der Folie gesetzt wurde.
  function notiz(i) {
    var f = SLIDES[i];
    return (f && attr(f, "note")) || "";
  }

  // Was der nächste Tastendruck täte: ein weiterer Schritt auf derselben
  // Folie, eine neue Folie, oder nichts mehr. `STEPS` weiß das, denn dort
  // steht zu jedem Schritt seine Folie.
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

  // Eine Folie als stehendes Bild, und zwar auf einem *bestimmten* Schritt.
  // `miniatur` kann das nicht: dort ist nur der Hintergrund kopiert, und die
  // eingeblendeten Teile liegen als Sprites in der Overlay-Ebene. Für die
  // Vorschau ist das der ganze Unterschied, denn die Frage lautet nicht "wie
  // sieht die nächste Folie aus", sondern "was steht nach dem nächsten
  // Tastendruck da", und das ist oft dieselbe Folie mit einem Teil mehr.
  //
  // `stelle` zuerst, weil die Sprites ihre Plätze aus den Marken im
  // Hintergrund holen. Eine Folie, die noch nie dran war, hat noch keine.
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
      var k = ov.cloneNode(true);
      // Ein geklonter iframe lüde das fremde Dokument ein zweites Mal, ein
      // geklontes Video spielte ein zweites Mal Ton. In ein Standbild gehört
      // beides nicht.
      k.querySelectorAll("iframe,video,audio").forEach(function (x) { x.remove(); });
      k.querySelectorAll(".ts-el").forEach(function (el) {
        el.removeAttribute("data-hold");
        el.style.opacity = activeAt(el.dataset.at, schritt) ? "1" : "0";
      });
      m.appendChild(k);
    }
    return m;
  }

  // ── Sprecheransicht: die Ansicht ──────────────────────────────────────────
  //
  // Gebaut wird sie zur Laufzeit und nicht in die Datei geschrieben: dieselbe
  // Datei trägt beide Ansichten, und das Vortragsfenster soll von dieser hier
  // nichts merken.
  //
  // Die laufende Folie wird nicht nachgebaut. Sie ist die echte Bühne dieses
  // Fensters, die ohnehin mitläuft; sie wird nur an ihren Platz gerückt statt
  // zugedeckt. Das spart nicht nur den Nachbau: sie zeigt damit den laufenden
  // Schritt samt Übergängen, und die Zeichenebene liegt ohne Zutun schon
  // darüber, in genau derselben Geometrie wie drüben.
  var W = CFG.words || {};
  var SPW = W.sp || {};
  function wort(k, r) { return SPW[k] || r; }

  var PLATZ = null;        // der Kasten im Gerüst, auf den die Bühne rückt
  var LEIB = null;         // dessen Raster, dessen Spalten sich nach dem Fenster richten
  var ELN = {};            // die Anzeigen, einmal gesucht
  var gebaut = 0;
  var UHR_START = 0;       // ab wann gezählt wird, 0 = noch nicht angefangen
  var ZIEL_MIN = 0;        // geplante Dauer in Minuten, 0 = kein Plan
  var NOTIZ_PX = 21;
  var SCHWARZ = 0, EIS = 0;
  var VORSCHAU = "";
  // Die laufende Nummer beginnt zufällig. Nach einem Neuladen der
  // Sprecheransicht fingen sonst beide Seiten wieder bei eins an, und der
  // erste neue Strich wüchse an den letzten alten an, statt ein eigener zu
  // sein. Kommt die Abschrift von drüben, wird die Nummer ohnehin
  // hochgesetzt; ohne Partner trägt der Zufall.
  var STRICH_NR = Math.floor(Math.random() * 1e6), MALT = 0, FARBE = 0, LETZT = null;
  // `OFFEN` ist der zurückgehaltene erste Punkt, `GESETZT` merkt, ob vom
  // laufenden Strich schon etwas hinausging, `DRAUSSEN`, ob der Zeiger
  // gerade neben der Folie steht.
  var OFFEN = null, GESETZT = 0, DRAUSSEN = 0;

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
  // Die eine große Zahl einer Gruppe. Sie trägt die Hierarchie, damit nicht
  // sechs gleich laute Spalten nebeneinanderstehen und der Blick sich seinen
  // Anker selbst suchen muss.
  function haupt(wohin, name) {
    var d = bau("div", "ts-sp-haupt", wohin);
    bau("div", "ts-sp-marke", d).textContent = name;
    return bau("div", "ts-sp-gross", d);
  }
  // Ein stiller Wert: Zahl zuerst, Wort klein dahinter. In einer Zeile
  // nebeneinander gelesen wie „12:56 verbleibend".
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

  // Die Uhr läuft ab dem ersten Tastendruck, nicht ab dem Laden: wer die
  // Ansicht früh aufmacht und noch mit dem Saal redet, will keine falsche
  // Zahl vor sich haben.
  function uhrAn() { if (!UHR_START) UHR_START = Date.now(); }

  function lageZeigen() {
    if (!ELN.lage) return;
    while (ELN.lage.firstChild) ELN.lage.removeChild(ELN.lage.firstChild);
    if (GETRENNT) bau("span", "ts-sp-weg", ELN.lage).textContent =
      wort("lost", "no talk window");
    if (SCHWARZ) bau("span", "", ELN.lage).textContent = wort("black", "black");
    if (EIS) bau("span", "ts-sp-eis", ELN.lage).textContent = wort("frozen", "frozen");
  }

  // Antwortet drüben niemand mehr, muss man das sehen. Sonst blättert der
  // Vortragende weiter in eine Leinwand, die ihm längst nicht mehr folgt:
  // das Fenster kann geschlossen sein, ein anderes Deck tragen, oder der
  // Rechner am Beamer kann hängen. Fünf Sekunden, damit ein einzelner
  // ausgefallener Herzschlag nichts meldet.
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
  // Was drüben gilt, gilt auch hier, laufend und nicht nur beim Handschlag.
  // Eine Antwort, die vor dem eigenen Tastendruck losgeschickt wurde, weiß
  // von ihm noch nichts; kurz nach einem eigenen Befehl gilt deshalb der
  // eigene, und der nächste Schlag bestätigt ihn ohnehin.
  function sichtAbgleichen(schwarz, frost) {
    if (ROLLE !== "speaker" || schwarz == null) return;
    if (Date.now() - SICHT_GESENDET < 1500) return;
    var s = schwarz ? 1 : 0, f = frost ? 1 : 0;
    if (s === SCHWARZ && f === EIS) return;
    SCHWARZ = s; EIS = f;
    lageZeigen();
  }
  // Was drüben gilt, gilt hier. Eine neu geöffnete Ansicht behauptete sonst
  // "hell und aufgetaut", während der Saal schwarz ist, und der erste Druck
  // auf `b` machte es schlimmer statt besser.
  function sichtUebernehmen(schwarz, frost) {
    if (ROLLE !== "speaker") return;
    SCHWARZ = schwarz ? 1 : 0;
    EIS = frost ? 1 : 0;
    lageZeigen();
  }

  function tinteSenden(ev) {
    tinteBuendel([ev]);   // erst bei sich selbst, dann hinüber
    strom("tinte", ev);
  }

  function sprecherAufbau() {
    if (ROLLE !== "speaker" || !SPRECHERBOX) return;

    // Der Kopf trägt zwei Gruppen: links die Zeit, rechts der Ort im Vortrag.
    // Vorher standen sechs gleichrangige Spalten nebeneinander, alle links
    // gedrängt, und rechts blieb Platz liegen. Jetzt hat jede Gruppe eine
    // große Zahl, alles Weitere steht klein daneben, und die beiden Gruppen
    // sitzen an den beiden Rändern.
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
    // Ohne diesen Ausgang wäre das Feld eine Falle: `tippt` hält die
    // Pfeiltasten davon ab zu blättern, und ohne Maus käme man nicht mehr
    // heraus. Enter nimmt den Wert, Escape lässt ihn ebenfalls stehen; beide
    // geben die Tastatur zurück. `stopPropagation`, damit Escape nicht
    // nebenbei die Übersicht aufklappt.
    inp.addEventListener("keydown", function (ev) {
      if (ev.key !== "Enter" && ev.key !== "Escape") return;
      inp.blur();
      ev.preventDefault();
      ev.stopPropagation();
    });
    ELN.ziel = inp;
    ELN.rest = neben(zeile, wort("left", "remaining"));
    ELN.takt = neben(zeile, wort("pace", "pace"));
    // Ohne Zieldauer gibt es weder Rest noch Plan. Statt zweimal einen Punkt
    // neben einem lauten Etikett zu zeigen, verschwinden beide Paare, bis
    // eine Dauer dasteht. Das ist die Hälfte dessen, was den Kopf voll
    // aussehen ließ.
    ELN.restPaar = ELN.rest.parentNode;
    ELN.taktPaar = ELN.takt.parentNode;

    var gOrt = bau("div", "ts-sp-gruppe ts-sp-rechts", kopf);
    ELN.fort = haupt(gOrt, wort("slide", "slide"));
    var zeile2 = bau("div", "ts-sp-neben", gOrt);
    ELN.fortSchritt = neben(zeile2, wort("step", "step"));
    // Ein Balken sagt ohne Worte, wo man steht. Er ist das zweite
    // Hierarchiemittel neben der Schriftgröße und braucht keine Beschriftung.
    ELN.balken = bau("i", "", bau("div", "ts-sp-balken", gOrt));

    // Der Leib: links die laufende Folie, rechts Vorschau und Notiz.
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

    // Der Fuß: Farben, Zustand, Tastenhilfe.
    var fuss = bau("div", "ts-sp-fuss", SPRECHERBOX);
    var stift = bau("div", "ts-sp-stift", fuss);
    bau("span", "ts-sp-marke", stift).textContent = wort("pen", "pen");
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

    // Der Ton gehört in den Saal, nicht an den Platz des Vortragenden: die
    // Bühne läuft hier voll mit, samt Video. Zu sehen ist das erwünscht,
    // zweimal zu hören nicht.
    document.querySelectorAll("video,audio").forEach(function (v) { v.muted = true; });

    tasten();
    zeichnen();
    farbeSetzen(0);
    gebaut = 1;
    document.documentElement.dataset.tsFertig = "1";

    // Die Uhr läuft, sobald sich drüben etwas bewegt, und nicht schon, wenn
    // der Vortrag bloß meldet, wo er steht. Diese Meldung ist die Antwort auf
    // die Anmeldung, und die Anmeldung wiederholt sich, bis sie ankommt:
    // gezählt wird deshalb nicht, wie oft eine Meldung kam, sondern ob sie
    // eine andere Zahl trägt als die vorige.
    var fern = null;
    horch("schritt", function (d) {
      if (d.sitzung !== undefined) return;   // eine Begrüßung, kein Schritt
      if (fern !== null && fern !== d.n) uhrAn();
      fern = d.n;
    });

    setInterval(sprecherUhr, 250);
    sprecherStand();
    sprecherUhr();
    fit();
  }

  function farbeSetzen(i) {
    FARBE = i % FARBEN.length;
    if (!ELN.tupf) return;
    for (var k = 0; k < ELN.tupf.length; k++) {
      if (k === FARBE) ELN.tupf[k].dataset.an = "1";
      else delete ELN.tupf[k].dataset.an;
    }
  }

  // Solange niemand die Größe von Hand gewählt hat, richtet sie sich nach dem
  // Fenster: 21px sind auf einem großen Schirm richtig und in einem kleinen
  // Fenster zu groß, dort blieben vier Zeilen. Das Fenster geht überdies klein
  // auf und wird oft erst danach aufgezogen. Ein Druck auf + oder − beendet
  // das Mitwachsen, denn dann gilt, was der Vortragende will.
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
  // Eine Zeile, die am unteren Rand einfach abgeschnitten ist, liest sich,
  // als sei die Notiz zu Ende. Deshalb ein Verlauf und ein Pfeil, sobald noch
  // etwas kommt, und zwei Tasten zum Rollen: die Hände sind beim Vortrag
  // nicht an der Maus.
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

  // ── Die Tasten der Sprecheransicht ────────────────────────────────────────
  //
  // Ein eigener Empfänger, angemeldet erst im Aufbau: im Vortragsfenster gibt
  // es ihn gar nicht. Blättern, Übersicht und Vollbild kommen aus der
  // gemeinsamen Steuerung weiter oben und stehen hier nicht noch einmal.
  function tasten() {
    addEventListener("keydown", function (e) {
      if (tippt(e)) return;
      var k = e.key;
      if (k === "ArrowRight" || k === "ArrowLeft" || k === "PageDown" ||
          k === "PageUp" || k === " " || k === "Home" || k === "End") {
        uhrAn(); return;
      }
      // Hoch und runter sind in der gemeinsamen Steuerung frei und rollen
      // hier die Notiz. Im Vortragsfenster gibt es diesen Empfänger nicht.
      if (k === "ArrowDown") { notizRollen(1); e.preventDefault(); return; }
      if (k === "ArrowUp") { notizRollen(-1); e.preventDefault(); return; }
      if (k === "b") { SCHWARZ = SCHWARZ ? 0 : 1; sichtSenden(); }
      else if (k === "e") { EIS = EIS ? 0 : 1; sichtSenden(); }
      else if (k === "t") { if (ELN.ziel) { ELN.ziel.focus(); ELN.ziel.select(); e.preventDefault(); } }
      else if (k === "r") { UHR_START = 0; sprecherUhr(); }
      else if (k === "c") { farbeSetzen(FARBE + 1); }
      else if (k === "z") { tinteSenden({ b: "weg", s: tinteFolie() }); }
      else if (k === "x") { tinteSenden({ b: "loesch", s: tinteFolie() }); }
      else if (k === "+" || k === "=") { notizGroesse(2); }
      else if (k === "-" || k === "_") { notizGroesse(-2); }
    });
  }

  // ── Zeichnen ──────────────────────────────────────────────────────────────
  //
  // Die Zeiger liegen auf der Bühne selbst, denn die liegt hier obenauf. Ein
  // Klick blättert in dieser Rolle ohnehin nicht (siehe die Steuerung), der
  // Platz ist also frei.
  function zeichnen() {
    function anteil(e) {
      var r = B.getBoundingClientRect();
      if (!r.width || !r.height) return null;
      return { x: (e.clientX - r.left) / r.width,
               y: (e.clientY - r.top) / r.height };
    }
    // Zittern kostet Bandbreite und bringt kein Bild. Ein schneller Strich
    // hat große Abstände und verliert dadurch nichts.
    function weitGenug(p) {
      if (!LETZT) return true;
      var dx = p.x - LETZT.x, dy = p.y - LETZT.y;
      return dx * dx + dy * dy > 0.000004;   // gut 0.2% der Bühnenbreite
    }
    // Nichts außerhalb der Folie in den Bestand. Ein Zeiger, der über den
    // Rand hinauszieht, lieferte sonst Werte wie 1.4 oder -0.2, die keiner je
    // zu sehen bekommt (`#ts-ink` schneidet ab) und die trotzdem in jede
    // Abschrift wandern. Kommt er zurück, fängt ein neuer Strich an, statt
    // quer über die Folie zu springen.
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
      // Der erste Punkt wartet, bis ein zweiter kommt. Ein bloßer Klick legte
      // sonst einen Strich aus einem Punkt an: `getBBox` ist 0 mal 0, zu
      // sehen ist nichts, und das Rückgängig räumte danach diesen Geist weg
      // statt des Strichs, den der Vortragende meinte.
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
      MALT = 1; STRICH_NR++; LETZT = null; DRAUSSEN = 0; OFFEN = null; GESETZT = 0;
      // Ohne Fang endete der Strich, sobald der Zeiger die Bühne verlässt.
      try { B.setPointerCapture(e.pointerId); } catch (x) {}
      punkt(e);
      e.preventDefault();
    });
    B.addEventListener("pointermove", function (e) {
      if (!MALT) return;
      // Der Browser fasst schnelle Bewegungen zu einem Ereignis zusammen und
      // hebt die Zwischenpunkte auf. Wer sie nicht abholt, bekommt bei
      // schnellem Zug eine eckige Linie.
      var liste = e.getCoalescedEvents ? e.getCoalescedEvents() : null;
      if (liste && liste.length) { for (var i = 0; i < liste.length; i++) punkt(liste[i]); }
      else punkt(e);
      e.preventDefault();
    });
    function schluss(e) {
      if (!MALT) return;
      // Ein zurückgehaltener erster Punkt, dem nie ein zweiter folgte, war
      // ein Klick und kein Strich. Er wird fallengelassen.
      MALT = 0; LETZT = null; OFFEN = null; GESETZT = 0;
      try { B.releasePointerCapture(e.pointerId); } catch (x) {}
    }
    B.addEventListener("pointerup", schluss);
    B.addEventListener("pointercancel", schluss);
  }

  // ── Die Uhr, viermal je Sekunde ───────────────────────────────────────────
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
      // Solange die Uhr steht, gibt es keinen Plan, gegen den man liegen
      // könnte. "vor Plan" wäre dann bloß eine Folge davon, dass die
      // erwartete Position bei null Sekunden null ist.
      if (!UHR_START) {
        ELN.takt.textContent = "·";
        ELN.takt.dataset.lage = "";
        return;
      }
      // So rechnet reveal.js: die verstrichene Zeit im Verhältnis zur
      // geplanten Dauer, aufgetragen auf die Gesamtschrittzahl. Der Abstand
      // zwischen erwartetem und wirklichem Schritt, mal der Zeit je Schritt,
      // ist der Vorsprung in Sekunden.
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

  // ── Nach jedem Schritt ────────────────────────────────────────────────────
  function sprecherStand() {
    if (ROLLE !== "speaker" || !SPRECHERBOX || !gebaut) return;
    var st = STEPS[current] || { slide: 0, step: 1 };

    var n = notiz(st.slide);
    ELN.notiz.textContent = n || (W.noNote || "no note");
    if (n) delete ELN.notiz.dataset.leer; else ELN.notiz.dataset.leer = "1";

    ELN.fort.textContent = (st.slide + 1) + " / " + SLIDES.length;
    ELN.fortSchritt.textContent = (current + 1) + " / " + STEPS.length;
    ELN.balken.style.width =
      (STEPS.length < 2 ? 100 : (current * 100 / (STEPS.length - 1))) + "%";

    // Die Vorschau kostet einen Klon der Folie. Sie wird deshalb nur neu
    // gebaut, wenn sie etwas anderes zeigen soll als eben noch.
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
        // Nur die Nummer hinter die Bezeichnung, nicht noch einmal das Wort
        // „Folie": bei einem Folienwechsel stand sonst wörtlich „nächste Folie
        // Folie 2.1" da.
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

    // Die Chrome-Ebene folgt der Folie, wandert aber nicht mit ihr: sie liegt
    // über der Bühne und wird nur ein- und ausgeblendet. Außerhalb der beiden
    // Zweige darüber, denn der eine gilt nur für die allererste Folie und der
    // andere reicht den Wechsel an `transition` weiter.
    CHROME.forEach(function (c, i) {
      if (i === dst.slide) c.dataset.on = "1"; else delete c.dataset.on;
    });

    SLIDES[dst.slide].querySelectorAll(".ts-el").forEach(function (el) {
      var an = activeAt(el.dataset.at, dst.step);
      var d = +erbt(el, "duration") || CFG.duration;
      var delay = back ? 0 : (+erbt(el, "delay") || 0);

      if (instant || changed) {
        clearAnims(el);
        if (an) { el.dataset.on = "1"; el.style.opacity = "1"; }
        else { delete el.dataset.on; el.style.opacity = "0"; }
        return;
      }

      if (an && el.dataset.on !== "1") {
        el.dataset.on = "1";
        fadeIn(el, erbt(el, "enter") || "fade-up", d, delay);
      } else if (!an && el.dataset.on === "1") {
        delete el.dataset.on;
        if (back) fadeOut(el, erbt(el, "enter") || "fade-up", d);
        else fadeOut(el, erbt(el, "exit") || "fade", d * 0.75);
      }
    });

    mediaOn(dst.slide);
    drive(dst.slide, dst.step, back || changed);
    // Der laufende Schritt gehört in den Hash, aber nur im Vortragsfenster.
    // Im Sprecherfenster steht dort `#speaker`, und das muss stehen bleiben:
    // wer neu lädt, will die Sprecheransicht wiederhaben und nicht den Vortrag.
    if (ROLLE !== "speaker" && location.hash !== "#" + (n + 1)) {
      history.replaceState(null, "", "#" + (n + 1));
    }
    melde(n);
    sprecherStand();
    tinteStand();
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
  //
  // Eine Folie als stehendes Bildchen. Herausgelöst, weil die Sprecheransicht
  // dasselbe braucht, dort für die Folie, die als nächste kommt.
  //
  // Fußzeile und Fortschritt liegen nicht mehr in `.ts-bg`, sondern in der
  // Ebene über der Bühne. Fürs Vorschaubild wird deshalb die Druckkopie
  // mitgenommen, die ohnehin in jeder Folie steckt — sonst wären die Bildchen
  // ohne Seitenzahl. Was das Bildchen nicht zeigt, sind die bewegten Teile:
  // es steht immer auf dem ersten Schritt seiner Folie.
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

  // ── Skalieren ─────────────────────────────────────────────────────────────
  // Wie die drei Teile das Fenster aufteilen.
  //
  // Die laufende Folie ist die Zeichenfläche und bekommt den meisten Platz.
  // Sie hält dabei ihr Seitenverhältnis, und das entscheidet die Aufteilung:
  //
  //   hoch:  unter der Folie bleibt ein Streifen frei, dort steht die Notiz
  //          über die ganze Breite. Das ist der Normalfall.
  //   flach: bei einem breiten, niedrigen Fenster ist die Folie schon so hoch
  //          wie der Leib, und neben ihr bliebe eine große leere Fläche. Dann
  //          ziehen Vorschau und Notiz untereinander dorthin.
  //
  // Die Vorschau ist ein Blick und keine zweite Bühne: höchstens ein knappes
  // Halb der laufenden Folie, sonst kehrte sich die Bauordnung um.
  function sprecherSpalten() {
    if (ROLLE !== "speaker" || !LEIB || !PLATZ) return;
    var r = LEIB.getBoundingClientRect();
    if (!r.width || !r.height) return;
    var v = CFG.width / CFG.height;
    var frei = r.width - 14;
    // Ist das Fenster hochkant, reicht die Höhe für eine Bühne über die ganze
    // Breite und darunter bleibt immer noch viel übrig. Dann stünde die Notiz
    // in einer Spalte, die größer wäre als die Bühne selbst, und die
    // Bauordnung stünde auf dem Kopf. Also legt sich die Bühne oben quer, und
    // Vorschau und Notiz teilen sich die Reihe darunter.
    // So breit dürfte die Bühne, wenn die Notiz darunter ein gutes Drittel
    // behält.
    var breit = Math.min(frei * 0.72, r.height * 0.68 * v);
    var flach = (frei - breit) > breit * 0.75;
    if (flach) breit = Math.min(frei * 0.72, r.height * v);
    breit = Math.max(frei * 0.34, breit);
    // Der Mindestwert darf die Bühne nicht höher machen als der Leib ist. Bei
    // einem sehr breiten und sehr flachen Fenster ragte sie sonst unten aus
    // ihrem Platz heraus, und die Ansicht bekam einen Bildlauf.
    breit = Math.min(breit, frei, r.height * v);

    // Und jetzt die Probe aufs Exempel. Durchgesetzt werden soll nicht ein
    // Seitenverhältnis des Fensters, sondern das Ergebnis: die laufende Folie
    // ist die größte Fläche der Ansicht. Also nachrechnen, was die Notiz in
    // dieser Form bekäme, und auf die dritte ausweichen, wenn sie die Bühne
    // überholte und die Höhe für eine Bühne über die ganze Breite reicht.
    //
    // Die alte Bedingung hing am Seitenverhältnis und ließ ein ganzes Band
    // von Fenstergrößen durch, in dem die Notiz das Anderthalbfache der Bühne
    // bekam. Am Ergebnis gemessen kann das nicht mehr passieren.
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
    // Steht die Bühne in einem sehr flachen Fenster schon so hoch wie der
    // Leib, bleibt neben ihr mehr Breite übrig, als eine Notiz braucht. Ohne
    // Schranke wäre die Notiz dort die größte Fläche der Ansicht, und die
    // Bauordnung stünde wieder auf dem Kopf.
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
    // the ratio as a number — it is not 16:9 for every deck.
    document.documentElement.style.setProperty(
      "--ts-ratio", (100 / v) + "%");
    sprecherSpalten();
    // In der Sprecheransicht füllt die Bühne nicht das Fenster, sondern den
    // für sie freigehaltenen Kasten im Gerüst. Sie bleibt dabei die echte
    // Bühne: dieselben Folien, derselbe Schritt, dieselbe Zeichenebene.
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

  // ── Steuerung ─────────────────────────────────────────────────────────────
  var hintTimer;
  function hint(t) {
    HINT.textContent = t;
    HINT.dataset.on = "1";
    clearTimeout(hintTimer);
    hintTimer = setTimeout(function () { delete HINT.dataset.on; }, 2600);
  }
  // Die Sprecheransicht hat ein Eingabefeld für die geplante Dauer. Eine
  // Leertaste darin ist ein Leerzeichen und kein Blättern.
  function tippt(e) {
    var t = e.target;
    if (!t || !t.tagName) return false;
    var n = t.tagName.toLowerCase();
    return n === "input" || n === "textarea" || n === "select" || !!t.isContentEditable;
  }
  addEventListener("keydown", function (e) {
    if (tippt(e)) return;
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
      hint(attr(SLIDES[STEPS[current].slide], "note") || CFG.words.noNote);
    } else if (e.key === "?") {
      hint((ROLLE === "speaker" && CFG.words.helpSpeaker) || CFG.words.help);
    } else if (e.key === "p") { print(); }
    // Das zweite Fenster. Der Tastendruck ist zugleich die Nutzergeste, ohne
    // die der Popup-Blocker `window.open` verschluckt.
    else if (e.key === "n") { oeffneSprecher(); }
  });
  addEventListener("click", function (e) {
    // In der Sprecheransicht deckt `#ts-speaker` die Bühne zu. Ein Klick dort
    // gilt dem, was der nächste Agent hineinbaut, und soll nicht nebenbei
    // weiterblättern.
    if (ROLLE === "speaker") return;
    if (OVERVIEW.dataset.on) return;
    if (e.target.closest && e.target.closest(".ts-embed")) return;
    goto(current + (e.clientX < innerWidth * 0.25 ? -1 : 1));
  });
  addEventListener("hashchange", function () {
    // Im Sprecherfenster ist der Hash die Rolle und keine Schrittzahl. Dort
    // wird er weder geschrieben noch gelesen.
    if (ROLLE === "speaker") return;
    var n = +location.hash.slice(1) - 1;
    if (!isNaN(n) && n !== current) goto(n, true);
  });

  fit();
  // Die Sprecheransicht fängt bei der ersten Folie an und wartet darauf, dass
  // der Vortrag ihr sagt, wo er steht. Der Vortrag selbst nimmt die Zahl aus
  // dem Hash, dieses eine Mal und danach nie wieder.
  goto(ROLLE === "speaker"
       ? 0 : Math.max(0, (+location.hash.slice(1) || 1) - 1), true);
  // Nach dem ersten `goto`, damit `schwarzMedien` die Folie kennt, und noch
  // vor dem ersten Bild: so bleibt der Saal dunkel, statt kurz aufzublitzen.
  sichtErinnern();
  sprecherAufbau();
  anmeldeSchleife();

  window.typstage = {
    goto: goto, steps: STEPS, slides: SLIDES,
    state: function () { return current; },
    geo: vermessen, build: CFG.build,

    // ── Zweites Fenster ─────────────────────────────────────────────────────
    // `rolle` ist "stage" oder "speaker" und steht ab dem Laden fest.
    // `box` ist der leere Behälter der Sprecheransicht, `ink` die Ebene über
    // der Bühne im Vortragsfenster, auf der Fremdes gezeichnet werden darf.
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

    // ── Sprecheransicht ─────────────────────────────────────────────────────
    // Zum Nachmessen und für alles, was von außen daran will.
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
    }
  };
})();
