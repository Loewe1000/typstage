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
//
// Jede der drei Behebungen einzeln zurückgenommen lässt die Probe klagen; die
// Stellen stehen im CHANGELOG unter 0.1.3.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const LAUT = process.argv.indexOf("--laut") > 0;

const KOPF = `#import "@preview/typstage:0.1.3": *\n`;

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
    fs.symlinkSync(WURZEL, path.join(ziel, "0.1.3"));
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
  console.log("Unterbrechen: Aufdeckung, Flug und Folienwechsel lassen sich "
              + "mitten in der Bewegung umkehren (3 Decks, 4 Punkte)");
})();
