// pruefe-unterbrechen.js — springt das Bild, wenn jemand mitten hinein blättert?
//
// Eine Aufdeckung dauert eine halbe Sekunde, ein Flug fast eine, ein
// Folienwechsel eine knappe halbe. Wer in dieser Zeit die Taste drückt --
// und das tut jeder, der ein Deck zügig vorführt --, sah bisher, wie das Bild
// an die Ruhelage sprang und von dort neu lief: Die laufende Animation wurde
// abgebrochen, und die neue begann, wo die alte begonnen hatte, nicht wo das
// Auge das Element zuletzt gesehen hatte.
//
//   node .github/scripts/pruefe-unterbrechen.js [--browser /pfad] [--laut]
//
// Gemessen wird Bild für Bild (`requestAnimationFrame`) und immer nur, was zu
// sehen ist: ein Sprung hinter der Blende ist keiner. Verglichen wird der
// größte Unterschied zwischen zwei aufeinanderfolgenden Bildern mit dem, was
// dieselbe Bewegung ungestört kostet -- eine Bewegung, die in 16 ms ein
// Viertel ihres Weges zurücklegt, ist kein Sprung, sondern schnell.
//
// Geprüft wird:
//   1. Umkehren mitten in einer Aufdeckung: Die Deckkraft läuft von dort
//      weiter, wo sie steht. Vorher sprang sie von 0.20 auf 0.99.
//   2. Umkehren mitten in einem Flug: Der Geist fährt seine Bahn zurück.
//      Vorher sprang er 648 px an die Ruhelage der Zielfolie.
//   3. Umkehren mitten im Folienwechsel: Die Folien fahren zurück. Vorher
//      sprang die hereinkommende 25 px.
//   4. Weiterblättern mitten in einer Aufdeckung macht sie nicht kaputt: Das
//      Element steht danach da, wo es hingehört, und die nächste Aufdeckung
//      läuft.
//   6. Und nichts steht doppelt da: Solange Geister fliegen, sind beide
//      Enden des Morphs verborgen -- auch dann, wenn zwei Flüge einander
//      ablösen. Gemessen auf dem Rundgang stand das Ziel 370 ms sichtbar
//      unter seinen eigenen Geistern, weil das Aufräumen des einen Flugs dem
//      anderen den Vorhang wegnahm.
//   7. Und nichts bleibt liegen: Nach schnellem Hin und Her -- zwei
//      Schrittwechsel unter 200 ms -- ist `#ts-fly` in Ruhe leer. Vorher
//      loeschte der naechste Flug den `remove()` der ausblendenden Geister
//      mit seiner pauschalen `clearTimeout`-Runde, und sie blieben bis zum
//      Neuladen liegen, unsichtbar bei `opacity: 0`.
//   8. Der Rueckweg einer Kette ist der Hinweg rueckwaerts: Beim
//      Zurueckblaettern fliegt die Zeile in die zurueck, aus der sie
//      hervorging, statt nach unten auszublenden -- sie ist dabei verborgen,
//      ihre Geister steigen, und die Zeile darueber steht die ganze Zeit da.
//      Und beim schnellen Hin und Her steht nie eine kommende oder gehende
//      Zeile halb durchsichtig neben Geistern: Der Abbruch eines Flugs gab
//      frueher auch die gehende Zeile sofort frei.
//   9. Und beim sehr schnellen Blaettern stapeln sich keine Fassungen: Ein
//      neuer Flug uebernimmt den laufenden dort, wo dessen Geister gerade
//      sind, statt sie einfrieren und ausblenden zu lassen. Gemessen wird,
//      wie viele Geister zugleich sichtbar sind -- bei Tasten im Abstand von
//      45 ms gegen einen einzelnen, ungestoerten Flug. Vorher standen auf dem
//      Rundgang drei bis vier Fassungen uebereinander (93 Geister gegen 26).
//   5. Umkehren mitten in einer Zeichnung (`enter: "draw"`): Die Feder fährt
//      von dort zurück, wo sie steht. Vorher sprang der Strich erst ans Ende
//      -- `clearAnims` nimmt der laufenden Animation den Lauf, und der Pfad
//      steht dann fertig da -- und fuhr von dort heraus: 400 von 508 px in
//      einem Bild.
//
// Jede der drei Behebungen einzeln zurückgenommen lässt die Probe klagen; die
// Stellen stehen im CHANGELOG unter 0.2.0.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const LAUT = process.argv.indexOf("--laut") > 0;

const KOPF = `#import "@preview/typstage:0.2.0": *\n`;

// Langsam genug, dass ein Tastendruck wirklich mitten hinein fällt: Eine
// halbe Sekunde ist zu kurz, um sicher in ihrer Mitte zu landen.
const DECKS = {
  aufdecken: KOPF + `#show: presentation.with(title: [Aufdecken], duration: 1200)

== Punkte
#anim(enter: "fade-up")[Erster Punkt]
#anim(enter: "fade-up")[Zweiter Punkt]
`,
  flug: KOPF + `#show: presentation.with(title: [Flug], duration: 1200)

== Links
#align(left, morph(<m>, duration: 1200, text(size: 2em)[$ a + b $]))

== Rechts
#v(3fr)
#align(right, morph(<m>, duration: 1200, text(size: 2em)[$ a + b $]))
`,
  // Vier Folien mit demselben Namen. Auf zwei Folien ist jeder Wechsel die
  // Umkehr des laufenden Flugs, und der Abbruchpfad -- der, dessen remove()
  // verlorenging -- wird nie betreten. Erst ein Weiterblaettern mitten im
  // Flug bricht einen Flug ab, statt ihn umzukehren.
  vier: KOPF + `#show: presentation.with(title: [Vier], duration: 1200)

== Eins
#align(left, morph(<v>, duration: 1200, text(size: 1.6em)[$ a + b = c $]))

== Zwei
#align(right, morph(<v>, duration: 1200, text(size: 2.2em)[$ a + b = c $]))

== Drei
#v(2fr)
#align(left, morph(<v>, duration: 1200, text(size: 1.4em)[$ a + b = c $]))

== Vier
#v(2fr)
#align(right, morph(<v>, duration: 1200, text(size: 2.4em)[$ a + b = c $]))
`,
  fassungen: KOPF + `#show: presentation.with(title: [Fassungen], duration: 900)

== An einer Stelle
#alternatives(morph: true, start: 1,
  $ (a + b)^2 $,
  $ (a + b)(a + b) $,
  $ a dot a + a dot b + b dot a + b dot b $,
  $ a^2 + 2 a b + b^2 $)
`,
  kette: KOPF + `#show: presentation.with(title: [Kette], duration: 900)

== Eine Umformung
#stagger(morph: "k", $ x^2 + 6x + 2 = 0 $, $ x^2 + 6x = -2 $,
         $ x^2 + 6x + 9 = 7 $, $ (x + 3)^2 = 7 $)
`,
  zeichnen: KOPF + `#show: presentation.with(title: [Zeichnen], duration: 1600)

== Ein Pfad
#anim(enter: "draw", box(width: 400pt, height: 200pt,
  place(curve(stroke: 3pt + blue,
    curve.move((0pt, 180pt)),
    curve.cubic((120pt, -120pt), (260pt, 300pt), (390pt, 20pt))))))
`,
  wechsel: KOPF + `#show: presentation.with(title: [Wechsel], transition: "slide",
  transition-duration: 900)

== Erste
Ein Satz.

== Zweite
Noch einer.
`,
};

function bauen(quelle, name, paket, ordner) {
  const typ = path.join(ordner, name + ".typ");
  fs.writeFileSync(typ, quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
                         "--package-path", paket, "--root", ordner,
                         typ, path.join(ordner, name + ".html")]);
  return path.join(ordner, name + ".html");
}

// Die Aufzeichnung: je Bild ein Messwert, gesammelt in der Seite selbst.
const ZEICHNE = (ausdruck) => `window.__m = []; (function z(){
  try { window.__m.push(${ausdruck}); } catch (e) { window.__m.push(null); }
  if (window.__m.length < 400) requestAnimationFrame(z);
})();`;

// Der größte Sprung zwischen zwei Bildern, gezählt nur zwischen zwei
// sichtbaren Ständen.
function groesster(werte, sichtbar) {
  let max = 0;
  for (let i = 1; i < werte.length; i++) {
    const a = werte[i - 1], b = werte[i];
    if (a == null || b == null) continue;
    if (sichtbar && (!sichtbar(a) || !sichtbar(b))) continue;
    max = Math.max(max, Math.abs(sichtbar ? b.x - a.x : b - a));
  }
  return max;
}

(async () => {
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-unt-"));
  const paket = path.join(ordner, "pk");
  for (const raum of ["preview", "schule"]) {
    const ziel = path.join(paket, raum, "typstage");
    fs.mkdirSync(ziel, { recursive: true });
    fs.symlinkSync(WURZEL, path.join(ziel, "0.2.0"));
  }
  const weg = {};
  try {
    for (const name of Object.keys(DECKS)) weg[name] = bauen(DECKS[name], name, paket, ordner);
  } catch (e) {
    console.log("Unterbrechen: ein Probedeck übersetzt nicht\n  " +
                String(e.stderr || e.message).split("\n").slice(0, 4).join("\n  "));
    fs.rmSync(ordner, { recursive: true, force: true });
    process.exit(1);
  }

  const klagen = [];
  const b = await starte(CHROME);
  try {
    await b.ruf("Emulation.setDeviceMetricsOverride",
                { width: 1600, height: 900, deviceScaleFactor: 1, mobile: false });

    // ── 1: mitten in einer Aufdeckung umkehren ─────────────────────────────
    await b.navigiere("file://" + weg.aufdecken);
    await schlaf(1600);
    await b.taste("ArrowRight");           // auf die Folie
    await schlaf(1400);
    await b.ev(ZEICHNE(`(function(){
      var st = typstage.pruef.stand();
      var el = document.querySelectorAll('.ts-slide')[st.folie].querySelectorAll('.ts-el')[0];
      return el ? +getComputedStyle(el).opacity : null;
    })()`));
    await b.taste("ArrowRight");           // Auftritt beginnt
    await schlaf(300);
    await b.taste("ArrowLeft");            // mitten hinein: umkehren
    await schlaf(1800);
    const deck1 = JSON.parse(await b.ev(`JSON.stringify(window.__m)`));
    const sprung1 = groesster(deck1);
    if (LAUT) console.log("  1. Deckkraft: " + deck1.filter((_, i) => i % 6 === 0).map(v => v == null ? "-" : v.toFixed(2)).join(" "));
    if (sprung1 > 0.2) {
      klagen.push("1. beim Umkehren mitten in der Aufdeckung sprang die "
                  + "Deckkraft um " + sprung1.toFixed(2)
                  + " -- sie soll von dort weiterlaufen, wo sie steht");
    }

    // ── 4: weiterblättern macht die Aufdeckung nicht kaputt ────────────────
    await b.navigiere("file://" + weg.aufdecken);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1400);
    await b.taste("ArrowRight");           // erster Punkt kommt
    await schlaf(300);
    await b.taste("ArrowRight");           // mitten hinein: zweiter Punkt
    await schlaf(2200);
    const stand4 = JSON.parse(await b.ev(`JSON.stringify((function(){
      var st = typstage.pruef.stand();
      var el = document.querySelectorAll('.ts-slide')[st.folie].querySelectorAll('.ts-el');
      return { schritt: st.schritt, deckkraft: [].map.call(el, function(e){ return +getComputedStyle(e).opacity; }) };
    })())`));
    if (stand4.deckkraft.some(o => o < 0.99)) {
      klagen.push("4. nach dem Weiterblättern mitten in der Aufdeckung stehen "
                  + "die Punkte bei " + stand4.deckkraft.map(o => o.toFixed(2)).join(", ")
                  + " statt voll da");
    }

    // ── 2: mitten im Flug umkehren ─────────────────────────────────────────
    await b.navigiere("file://" + weg.flug);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1500);
    await b.ev(ZEICHNE(`(function(){
      var g = document.querySelector('#ts-fly .ts-ghost, #ts-fly svg');
      return g ? Math.round(g.getBoundingClientRect().left) : null;
    })()`));
    await b.taste("ArrowRight");
    await schlaf(400);
    await b.taste("ArrowLeft");
    await schlaf(2000);
    const deck2 = JSON.parse(await b.ev(`JSON.stringify(window.__m)`));
    const sprung2 = groesster(deck2);
    if (LAUT) console.log("  2. Bahn: " + deck2.filter((_, i) => i % 8 === 0).map(v => v == null ? "-" : v).join(" "));
    // Ein Flug legt 1200 px in 1200 ms zurück, das sind 16 px je Bild; beim
    // Umkehren zählt die doppelte Geschwindigkeit. 120 px liegen weit
    // darüber und weit unter den 648, die der Sprung kostete.
    if (sprung2 > 120) {
      klagen.push("2. beim Umkehren mitten im Flug sprang der Geist um "
                  + sprung2 + " px -- er soll seine Bahn zurückfahren");
    }

    // ── 3: mitten im Folienwechsel umkehren ────────────────────────────────
    await b.navigiere("file://" + weg.wechsel);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1400);
    await b.ev(ZEICHNE(`(function(){
      var f = document.querySelectorAll('.ts-slide')[2];
      if (!f) return null;
      var st = getComputedStyle(f), t = st.transform;
      var m = (!t || t === 'none') ? null : t.match(/-?[\\d.]+/g);
      return { x: m ? Math.round(+m[4] || 0) : 0, o: +st.opacity };
    })()`));
    await b.taste("ArrowRight");
    await schlaf(300);
    await b.taste("ArrowLeft");
    await schlaf(2000);
    const deck3 = JSON.parse(await b.ev(`JSON.stringify(window.__m)`));
    const sprung3 = groesster(deck3, (v) => v.o >= 0.05);
    if (LAUT) console.log("  3. Folie: " + deck3.filter((_, i) => i % 6 === 0).map(v => v == null ? "-" : v.x).join(" "));
    if (sprung3 > 10) {
      klagen.push("3. beim Umkehren mitten im Folienwechsel sprang die "
                  + "hereinkommende Folie um " + sprung3
                  + " px -- sie soll zurückfahren");
    }
    // Und sie muss wirklich zurückfahren. Ohne diese zweite Frage bliebe ein
    // harter Schnitt unbemerkt: Wird der Wechsel abgebrochen, stehen beide
    // Folien schlagartig an ihrem Ziel -- unsichtbar, also ohne Sprung im
    // Sinne oben -- und die Rückfahrt findet gar nicht statt. Gemessen wird
    // sie an dem Weg, den die hereinkommende Folie nach der Umkehr noch
    // zurücklegt: Sie kam bis 27 px heran und muss wieder hinaus, an ihren
    // Startplatz bei 46.
    const sichtbar3 = deck3.filter(v => v && v.o >= 0.05).map(v => v.x);
    const kehrt = deck3.findIndex((v, i) => i > 3 && v && deck3[i - 1] && v.x > deck3[i - 1].x);
    const zurueck = kehrt < 0 ? 0 : Math.max.apply(null, deck3.slice(kehrt).map(v => v ? v.x : 0));
    const start = Math.max.apply(null, sichtbar3.length ? sichtbar3 : [0]);
    if (kehrt < 0 || zurueck < start * 0.6) {
      klagen.push("3. nach dem Umkehren fuhr die hereinkommende Folie nicht "
                  + "zurück: sie kam bis " + zurueck + " px von " + start
                  + " px -- der Wechsel wurde abgebrochen statt umgekehrt");
    }

    // ── 5: mitten in einer Zeichnung umkehren ──────────────────────────────
    await b.navigiere("file://" + weg.zeichnen);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1400);
    await b.ev(ZEICHNE(`(function(){
      var n = document.querySelector('[data-ts-feder]');
      return n ? parseFloat(getComputedStyle(n).strokeDashoffset) : null;
    })()`));
    await b.taste("ArrowRight");           // der Strich zeichnet sich
    await schlaf(400);
    await b.taste("ArrowLeft");            // mitten hinein: umkehren
    await schlaf(2200);
    const deck5 = JSON.parse(await b.ev(`JSON.stringify(window.__m)`));
    const sprung5 = groesster(deck5);
    if (LAUT) console.log("  5. Feder: " + deck5.filter((_, i) => i % 5 === 0)
      .map(v => v == null ? "-" : Math.round(v)).join(" "));
    // Der Strich ist rund 508 px lang und fährt ihn in 1600 ms ab, das sind
    // 19 px je Bild bei doppelter Geschwindigkeit der Umkehr. 60 px liegen
    // weit darüber und weit unter den 400, die der Sprung kostete.
    if (sprung5 > 60) {
      klagen.push("5. beim Umkehren mitten in der Zeichnung sprang die Feder "
                  + "um " + Math.round(sprung5) + " px -- sie soll von dort "
                  + "zurückfahren, wo sie steht");
    }

    // ── 6: kein Doppelbild, wenn zwei Flüge einander ablösen ──────────────
    await b.navigiere("file://" + weg.flug);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1500);
    const doppelt = [];
    const schau = `JSON.stringify((function(){
      var g = document.querySelectorAll('#ts-fly .ts-ghost, #ts-fly svg').length;
      var sicht = [].filter.call(document.querySelectorAll('.ts-el[data-name]'),
        function (e) {
          var c = getComputedStyle(e);
          return c.visibility !== 'hidden' && +c.opacity > 0.02;
        }).length;
      return { g: g, sicht: sicht };
    })())`;
    for (const [taste, warten] of [["ArrowRight", 400], ["ArrowLeft", 250],
                                   ["ArrowRight", 250], ["ArrowLeft", 250]]) {
      await b.taste(taste);
      for (let i = 0; i < Math.round(warten / 100); i++) {
        await schlaf(100);
        const x = JSON.parse(await b.ev(schau));
        if (x.g > 0 && x.sicht > 0) doppelt.push(x);
      }
    }
    if (LAUT) console.log("  6. Doppelbilder: " + doppelt.length);
    if (doppelt.length) {
      klagen.push("6. in " + doppelt.length + " von " + 12 + " Messungen stand "
                  + "die Formel sichtbar da, während ihre Geister flogen -- "
                  + "sie war doppelt zu sehen");
    }

    // ── 8: die Kette faehrt zurueck ───────────────────────────────────────
    const ZEILEN = `JSON.stringify((function(){
      var st = typstage.pruef.stand();
      var f = document.querySelectorAll('.ts-slide')[st.folie];
      var el = [].slice.call(f.querySelectorAll('.ts-el[data-name="k"]')).map(function (e) {
        var c = getComputedStyle(e);
        return { an: e.dataset.on === '1', halt: !!e.dataset.hold,
                 sicht: c.visibility !== 'hidden' && +c.opacity > 0.02, o: +c.opacity,
                 y: e.getBoundingClientRect().top };
      });
      var gy = [].slice.call(document.querySelectorAll('#ts-fly .ts-ghost'))
        .map(function (g) { return g.getBoundingClientRect().top; });
      return { s: st.aufFolie, el: el, g: gy.length,
               gy: gy.length ? gy.reduce(function (a, b) { return a + b; }, 0) / gy.length : null };
    })())`;
    await b.navigiere("file://" + weg.kette);
    await schlaf(1600);
    for (let i = 0; i < 4; i++) { await b.taste("ArrowRight"); await schlaf(1300); }
    const ruhe8 = JSON.parse(await b.ev(ZEILEN));
    await b.taste("ArrowLeft");
    const bahn8 = [];
    for (let i = 0; i < 4; i++) { await schlaf(110); bahn8.push(JSON.parse(await b.ev(ZEILEN))); }
    // Welche Zeile geht und in welche sie zurueckfliegt, aus dem Stand und
    // nicht abgezaehlt: Eine Kette beginnt seit 0.1.2 auf Schritt 2, und
    // wie viele Zeilen nach vier Tastendruecken stehen, ist genau die Art
    // Zahl, die sich still verschiebt.
    const an8 = ruhe8.el.map((e, i) => e.an ? i : -1).filter(i => i >= 0);
    const geht = an8[an8.length - 1], bleibt = an8[an8.length - 2];
    if (LAUT) console.log("  8. Geister-y " + bahn8.map(x => x.gy == null ? "-" : Math.round(x.gy)).join(" ")
                          + " · gehende Zeile bei y " + Math.round(ruhe8.el[geht].y)
                          + ", Herkunft bei y " + Math.round(ruhe8.el[bleibt].y));
    if (!bahn8[0].g) {
      klagen.push("8. beim Zurueckblaettern flog nichts -- die Zeile blendete "
                  + "aus, statt in ihre Vorgaengerin zurueckzufliegen");
    } else {
      if (bahn8.some(x => x.el[geht].sicht && x.g)) {
        klagen.push("8. die gehende Zeile stand sichtbar da, waehrend ihre Geister flogen");
      }
      if (bahn8.some(x => !x.el[bleibt].sicht || x.el[bleibt].o < 0.98)) {
        klagen.push("8. die Zeile, in die zurueckgeflogen wird, war unterwegs nicht voll da");
      }
      const ys = bahn8.filter(x => x.gy != null).map(x => x.gy);
      if (ys.length >= 2 && !(ys[ys.length - 1] < ys[0])) {
        klagen.push("8. die Geister stiegen nicht: y " + ys.map(Math.round).join(" -> "));
      }
    }
    // Und schnell hin und her: keine kommende oder gehende Zeile halb
    // durchsichtig neben Geistern. Eine Zeile, die stehen bleibt und nur ihr
    // eigenes Aufblenden noch nicht beendet hat, zaehlt nicht -- aus ihr waechst
    // mit Absicht die naechste heraus.
    let halb = 0;
    for (const k of ["ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowLeft",
                     "ArrowRight", "ArrowRight", "ArrowLeft", "ArrowLeft"]) {
      await b.taste(k);
      for (let i = 0; i < 2; i++) {
        await schlaf(90);
        const x = JSON.parse(await b.ev(ZEILEN));
        x.el.forEach((e, i) => {
          if (x.g && !e.an && e.sicht && e.o < 0.98) {
            halb++;
            if (LAUT) console.log("     nach " + k + " Schritt " + x.s + ": Zeile " + i
                                  + " o=" + e.o.toFixed(2) + " gehalten=" + e.halt + " Geister " + x.g);
          }
        });
      }
    }
    if (LAUT) console.log("  8. halb durchsichtige Zeilen beim Flippen: " + halb);
    if (halb) {
      klagen.push("8. beim schnellen Hin und Her stand " + halb + "-mal eine gehende "
                  + "Zeile halb durchsichtig neben fliegenden Geistern");
    }

    // ── 9: keine Fassungen uebereinander ───────────────────────────────────
    const ZAEHLE = `window.__g = []; window.__gAn = true; (function z(){
      var n = 0;
      document.querySelectorAll('#ts-fly .ts-ghost').forEach(function (x) {
        if (+getComputedStyle(x).opacity > 0.05) n++;
      });
      window.__g.push(n);
      if (window.__gAn) requestAnimationFrame(z);
    })();`;
    const zaehlen = async (warten, tasten) => {
      await b.navigiere("about:blank"); await schlaf(150);
      await b.navigiere("file://" + weg.fassungen);
      await schlaf(1600);
      await b.taste("ArrowRight");
      await schlaf(1200);
      await b.ev(ZAEHLE);
      for (const k of tasten) { await b.taste(k); await schlaf(warten); }
      await schlaf(1500);
      await b.ev("window.__gAn = false");
      return JSON.parse(await b.ev("JSON.stringify(window.__g)")).filter(n => n > 0);
    };
    const hinUndHer = ["ArrowRight", "ArrowRight", "ArrowLeft", "ArrowRight",
                       "ArrowRight", "ArrowLeft", "ArrowLeft", "ArrowRight",
                       "ArrowRight", "ArrowRight", "ArrowLeft", "ArrowLeft"];
    const einzeln = await zaehlen(1300, ["ArrowRight", "ArrowRight", "ArrowRight"]);
    const schnell = await zaehlen(45, hinUndHer);
    const eins = Math.max.apply(null, einzeln.concat([1]));
    const p90 = schnell.slice().sort((x, y) => x - y)[Math.floor(schnell.length * 0.9)] || 0;
    if (LAUT) console.log("  9. ein Flug hoechstens " + eins + " Geister; schnell p90 " + p90
                          + ", max " + Math.max.apply(null, schnell.concat([0])));
    if (p90 > eins * 1.3) {
      klagen.push("9. beim schnellen Blaettern standen meist " + p90 + " Geister zugleich "
                  + "da, ein einzelner Flug hat hoechstens " + eins
                  + " -- Fassungen stapeln sich, statt einander abzuloesen");
    }

    // ── 7: nichts bleibt in der Luft ──────────────────────────────────────
    await b.navigiere("file://" + weg.vier);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1500);
    for (const k of ["ArrowRight", "ArrowRight", "ArrowRight",
                     "ArrowLeft", "ArrowLeft", "ArrowLeft"]) {
      await b.taste(k);
      await schlaf(100);
    }
    await schlaf(2500);
    const liegen = +(await b.ev(`document.getElementById('ts-fly').children.length`));
    if (LAUT) console.log("  7. nach dem Hin und Her liegen " + liegen + " Knoten auf #ts-fly");
    if (liegen > 0) {
      klagen.push("7. nach schnellem Hin und Her liegen in Ruhe noch " + liegen
                  + " Geister auf #ts-fly -- ihr remove() ist verlorengegangen");
    }

    const fehler = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.fehler())`));
    if (fehler.length) klagen.push("die Laufzeit meldete " + fehler.length + " Fehler");
  } finally {
    await b.ende();
    fs.rmSync(ordner, { recursive: true, force: true });
  }

  if (klagen.length) {
    console.log("Unterbrechen: " + klagen.length + " Beanstandung(en)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Unterbrechen: Aufdeckung, Flug, Folienwechsel und Zeichnung "
              + "lassen sich mitten in der Bewegung umkehren, und nichts steht "
              + "dabei doppelt da oder bleibt liegen (7 Decks, 9 Punkte)");
})();
