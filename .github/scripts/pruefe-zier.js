// =============================================================================
// pruefe-zier.js — steht die Zier im Browser, wo sie im PDF steht?
// =============================================================================
// Issue #16: „Footer (page number) location changed between PDF and HTML
// output". Im PDF stand „6/34" ganz da, im Browser „6/3", die letzte Ziffer
// unter dem Rand der Bühne. Die Zier -- Foliennummer, Laufzeile, Fußlinie,
// Leiste -- steht im Browser als eigene Ebene über der Bühne, auf Papier in der
// Seite. Was auf Papier aus der Umgebung kam, fehlte ihr dort, und was eine
// Regel des Decks erreichte, erreichte sie nur auf einer Seite.
//
// Je Fall ein kleines Deck, einmal als PDF-Seite (Typsts PNG-Ausgabe in der
// Auflösung des Fensters) und einmal im Chrome, Fenster gleich Bühne. Die Zier
// trägt über ihre Labels Signalfarben, der Rumpf eine eigene; gemessen wird der
// Tintenrahmen jeder Farbe, auf beiden Seiten in Pixeln derselben Bühne. Mehr
// als TOL Pixel Abstand an einer Kante ist eine Klage. Die Fälle, jeweils mit
// dem, was sie am Stand vor der Behebung gemessen haben, bei 1600 x 900:
//
//   1. Ränder und Abstände in `em`: `margin: (x: 1.5em, y: 1em)` und
//      `foot-gap: 2em` an `themes.lesson`. Im Browser löste die Zier `em`
//      gegen die Schrift des Dokuments auf (11pt), auf Papier gegen die des
//      Themes (20pt) -- die Nummer stand 26 px zu weit rechts, die Laufzeile
//      26 px zu weit links und 11 px zu hoch, die Fußlinie 34 px zu tief.
//   2. `#set place(dx: 10pt, dy: 10pt)` vor `presentation` schob die Zier nur
//      auf Papier, um 19 px nach rechts unten.
//   3. `#set page(flipped: true)` legte die Seite hochkant, 900 x 1600 px, und
//      die Nummer stand neben dem Blatt.
//   4. `#set block(inset: 8pt)`: die Nummer und die Laufzeile standen im
//      Browser 15 px weiter links oben, die Leiste war auf Papier ein
//      eingerückter Block von 8pt Höhe. Und jedes verfolgte Element schrumpfte
//      im Browser in eine eingerückte Marke: zwei Läufe hinter `#pause` auf
//      weniger als die Hälfte und 424 px daneben, ein `anim(place(bottom +
//      right, …))` war nicht mehr zu sehen, ein `anim(align(center, …))` stand
//      48 px daneben, und eine lange Anmerkung endete 62 px früher. Eine
//      Anmerkung mit eigenem Block stand 18 px daneben -- und 239 px, auf gut
//      zwei Drittel gestaucht, solange ihre Zeile im Schlitz ohne die Regel
//      des Decks stand, im Sprite aber mit ihr. Eine Szene und ein Daumenkino
//      stehen auf Papier in einem `block`, der den Einzug annahm, im Browser
//      in einer `box`: 58 und 77 px daneben, für sich allein 15 und 16 px.
//   5. `#set block(fill: …, stroke: …)` legte den Rahmen der Zier als Fläche
//      über die Folie: im Browser war der Rumpf darunter verschwunden. Die
//      zweite Folie trägt eine Linie in `anim`: sie misst keine Fläche, der
//      Browser gibt ihrem Sprite Luft rundum, und ohne `nackt` trug der Kasten
//      darum den Rand des Decks: ein blauer Kasten, den nur der Browser
//      zeichnet, gemessen 615 px daneben, sobald dort das `nackt` fehlt.
//   6. Der Weg, den das Handbuch nennt: `move.with(dx: …, dy: …)` auf
//      `ts-slide-footer` und auf `ts-slide-header-text` vor `presentation`,
//      hier mit einem Rand in `em` wie im nachgebauten Bild des Issues -- die
//      Nummer stand 17 px zu weit rechts, an der Kante der Bühne, die
//      Laufzeile 17 px zu weit links oben. Mit einem Rand in `pt` hielt es
//      schon vorher; die Probe hält das Versprechen des Handbuchs fest. Unter
//      demselben Rand eine lange Anmerkung: ihr Sprite löste `em` gegen 11pt
//      auf, setzte sie breiter als ihren Schlitz, und die Laufzeit stauchte
//      ihn hinein -- ihr Ende stand 29 px zu weit links.
//   7. Die Leiste zog die Laufzeit in festen 2,5 CSS-pt, 3,33 px in jedem
//      Fenster; auf Papier sind es 2,5 Folienpunkte, bei 3200 px Bühnenbreite
//      9,5 px. Gemessen in diesem großen Fenster, wo der Unterschied mehr als
//      Kantenglättung ist: 7 px.
//   8. Der Spiegel zu Fall 4: im Browser stehen Szene und Daumenkino in einer
//      `box`, ein `morph` im Lauf in einer Hülle, die eine `box` ist, und die
//      nahmen eine `set box`-Regel des Decks an; auf Papier gibt es diese
//      Kästen nicht. Unter `#set box(inset: 8pt)` standen alle drei im
//      Browser 16 px weiter rechts unten, und `#set box(fill: …, stroke: …)`
//      zog dort einen Kasten um Szene und Daumenkino, den das PDF nicht hat.
//      Geprüft wird der Einzug; dieselbe Zeile nimmt auch Fläche und Rand.
//   9. `#set rect(outset: 8pt)`: die Marke eines verfolgten Elements ist ein
//      `rect`, und die Laufzeit setzte den Sprite in die um den `outset`
//      größere Marke -- ein Lauf hinter `#pause` stand 15 px weiter links.
//  10. `#set block(inset: 8pt)` *hinter* `#show: presentation`: die Marke maß
//      den Rumpf mit der Regel, der Sprite setzte ihn ohne sie. Der Text eines
//      eigenen Blocks in `anim` und in `stagger` stand 16 px daneben, in
//      `alternatives` 150 px.
//  11. Eine Themengröße in `em`, `themes.default + (size: 2em)` unter
//      `margin: 1em`: die Zier setzte sie auf Papier ein zweites Mal, gegen
//      die schon gesetzte, und die Nummer stand im PDF 42 px weiter links.
//  12. `#set block(width: 80%)`: das `layout` eines verfolgten Elements nahm
//      die 80 % selbst an und ein Block darin 80 % davon. Ein Block hinter
//      `#pause` kam im Browser 236 px schmaler heraus, ein
//      `anim(align(center, …))` stand 148 px daneben, und eine lange
//      Anmerkung war im Browser auf den Schlitz von 80 % gestaucht (5 px).
//  13. Eine Anmerkung unter einer Themengröße in `em`, `themes.default +
//      (size: 1.3em)`: der Schlitz setzt `t.size * 0.62` zweimal, im
//      Anmerkungsblock und in `notiz-zeile`, der Sprite setzte es einmal
//      gegen die Foliengröße. Er kam 1,24-mal so hoch heraus wie sein
//      Schlitz, die Laufzeit verkleinerte ihn hinein und rückte ihn dabei
//      143 px nach rechts; eine längere Anmerkung brach im Sprite um und
//      stand unleserlich klein 512 px neben ihrem Ort.
//
// Jede der Behebungen einzeln zurückgenommen lässt die Probe klagen; die
// Stellen stehen in CHANGELOG.md unter 0.1.3, „Fixed". Was in beiden
// Ausgaben gleich falsch stand, sieht sie nicht, denn sie misst die eine
// gegen die andere: ein Block, den eine Label-Regel des Decks in die Zier
// legt, verlor dort unter `#set block(inset: …)` seinen Einzug, und die
// Kästen von `alternatives` und `build` stauchten einen Block des Decks.
//
//   node .github/scripts/pruefe-zier.js [--browser PFAD] [--laut]
//
// Rückgabewert 0, wenn alles hält, 1 bei einer Klage, 2 ohne Chrome.
// =============================================================================
const fs = require("fs"), os = require("os"), path = require("path");
const { execFileSync } = require("child_process");
const { starte, schlaf } = require("./decklauf/cdp.js");
const { pngLesen } = require("./decklauf/zeigerdeck.js");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };

function browserSuchen() {
  const k = ["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
             "/Applications/Chromium.app/Contents/MacOS/Chromium",
             "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable",
             "/usr/bin/chromium", "/usr/bin/chromium-browser", "/snap/bin/chromium"];
  const da = k.find(x => fs.existsSync(x));
  if (!da) { console.error("FEHLER: kein Chrome gefunden, --browser angeben."); process.exit(2); }
  return da;
}

// Pixel, um die eine Kante abweichen darf. Kantenglättung und die Rundung der
// Seitengröße machen gemessen höchstens einen aus (`--laut` zeigt jeden
// Abstand); die kleinste Abweichung, die diese Probe bei 1600 px fangen soll,
// sind 15. Die Leiste im großen Fenster hat ihre eigene Grenze, siehe dort.
const TOL = 3;
const LAUT = process.argv.includes("--laut");
const BREITE = 841.89;

// Die Masken. Eine Farbe gilt, wo ihr Kanal die anderen um mehr als 40
// überragt -- so zählt der geglättete Rand einer Glyphe mit, der helle Grund
// nicht.
const FARBE = {
  magenta: (r, g, b) => Math.min(r, b) - g > 40,
  cyan: (r, g, b) => Math.min(g, b) - r > 40,
  gruen: (r, g, b) => g - Math.max(r, b) > 40,
  rot: (r, g, b) => r - Math.max(g, b) > 40,
  blau: (r, g, b) => b - Math.max(r, g) > 40,
};

const KOPF = `#import "@preview/typstage:0.1.3": *
#show <ts-slide-number>: set text(fill: rgb("#ff00ff"))
#show <ts-slide-header-text>: set text(fill: rgb("#00ffff"))
#show <ts-slide-footer-rule>: set rect(fill: rgb("#00ff00"))
`;
// Grün für den Rumpf: `themes.lesson` setzt seine Titel zinnoberrot, und die
// Leiste des Standardthemas ist orange -- beides fiele unter eine rote Maske.
const GRUEN = (t) => `text(fill: rgb("#00c000"))[${t}]`;

// `bereich` in Bruchteilen der Bühne: x0, y0, x1, y1.
const UNTEN_RECHTS = [0.5, 0.8, 1, 0.985], OBEN = [0, 0, 1, 0.2];
const FUSS = [0, 0.8, 1, 0.97], LEISTE = [0, 0.97, 1, 1], RUMPF = [0, 0.1, 1, 0.97];
const NUMMER = ["Foliennummer", "magenta", UNTEN_RECHTS];

const FAELLE = [
  { name: "Rand und foot-gap in em", folien: [[0, [NUMMER,
      ["Laufzeile", "cyan", OBEN], ["Fußlinie", "gruen", FUSS]]]],
    deck: KOPF + `#show: presentation.with(margin: (x: 1.5em, y: 1em),
  theme: themes.lesson + (footer: "fraction", footer-rule: 0.8pt, foot-gap: 2em))
== Eins
Text.
` },
  { name: "#set place(dx, dy) vor presentation", folien: [[0, [NUMMER]]],
    deck: KOPF + `#set place(dx: 10pt, dy: 10pt)
#show: presentation
== Eins
Text.
` },
  { name: "#set page(flipped: true)", folien: [[0, [NUMMER]]],
    deck: KOPF + `#set page(flipped: true)
#show: presentation
== Eins
Text.
` },
  { name: "#set block(inset: 8pt)", folien: [
      [0, [NUMMER, ["Laufzeile", "cyan", OBEN], ["Leiste", "blau", LEISTE]]],
      [1, [["zwei Läufe hinter #pause", "gruen", RUMPF]]],
      [2, [["anim(place(bottom + right))", "gruen", RUMPF]]],
      [3, [["anim(align(center))", "gruen", RUMPF]]],
      [4, [["Anmerkung", "gruen", RUMPF]]],
      [5, [["Anmerkung mit eigenem Block", "gruen", RUMPF]]],
      [6, [["Szene", "gruen", RUMPF]]],
      [7, [["Daumenkino", "gruen", RUMPF]]]],
    deck: KOPF + `#set block(inset: 8pt)
#show: presentation.with(theme: themes.lesson + (footer: "fraction", progress: "bar"))
== Zier
Text.
== Pause
Text
#pause
#${GRUEN("Wort nach der Pause")}
#pause
#${GRUEN("Zweiter Lauf")}
== Anim
Text
#anim(place(bottom + right, dx: 20pt, dy: 20pt, ${GRUEN("Unten")}))
== Mitte
#anim(align(center, ${GRUEN("Mitte")}))
== Fussnote
Text#footnote[#${GRUEN("Eine lange Anmerkung, die fast die ganze Breite unter der Folie füllt: an ihrem Ende zeigt sich, wie breit ihr Platz im Browser ist.")}]
== Fussnote mit Block
Text#footnote[#${GRUEN("Vorher")} #block(stroke: 1pt + blue)[#${GRUEN("Im eigenen Block")}] #${GRUEN("Nachher")}]
== Szene
Text
#scene(x => place(top + left, dx: x * 100pt, ${GRUEN("Punkt")}), stops: (0, 1, 2), tween: 0, width: 400pt, height: 100pt)
== Daumenkino
Text
#flipbook(t => ${GRUEN("Flip")}, frames: 2, loop: false, width: 200pt, height: 80pt)
` },
  // Die zweite Folie: eine Linie misst keine Fläche und bekommt als Sprite
  // Luft um sich (`pad`, siehe render.typ). Den Rahmen darum zeichnet nur der
  // Browser, und ohne `nackt` trug er den Rand des Decks: ein blauer Kasten
  // um die Linie, den das PDF nicht hat. Der Bereich reicht links über den
  // Rand des Rumpfes, damit beide Seiten dort Tinte haben.
  { name: "#set block(fill, stroke)", folien: [[0, [NUMMER, ["Rumpf", "gruen", RUMPF]]],
      [1, [["Linie", "gruen", RUMPF], ["Rahmen um die Linie", "blau", [0, 0.2, 0.5, 0.4]]]]],
    deck: KOPF + `#set block(fill: rgb("#ffe0e0"), stroke: 2pt + blue)
#show: presentation
== Eins
#${GRUEN("Rumpftext")}
== Linie
Text
#anim(line(length: 300pt, stroke: 3pt + rgb("#00c000")))
` },
  { name: "move wie im Handbuch, Rand in em", folien: [[0, [NUMMER, ["Laufzeile", "cyan", OBEN]]],
      [1, [["Anmerkung", "gruen", RUMPF]]]],
    deck: KOPF + `#show <ts-slide-footer>: move.with(dx: 14pt, dy: 8pt)
#show <ts-slide-header-text>: move.with(dx: -12pt, dy: -6pt)
#show: presentation.with(margin: 1em, theme: themes.lesson + (footer: "fraction"))
== Eins
Text.
== Anmerkung
Text#footnote[#${GRUEN("Eine lange Anmerkung, die fast die ganze Breite unter der Folie füllt, damit man sieht, wie breit ihr Platz im Browser ist und wo sie endet.")}]
` },
  { name: "Leiste in 3200 x 1800", fenster: [3200, 1800], tol: 2,
    folien: [[0, [["Leiste", "rot", LEISTE]]]],
    deck: KOPF + `#show: presentation
== Eins
Text.
== Zwei
Text.
` },
  { name: "#set box(inset: 8pt)", folien: [[0, [["Szene", "gruen", RUMPF]]],
      [1, [["Daumenkino", "gruen", RUMPF]]], [2, [["morph im Lauf", "gruen", RUMPF]]]],
    deck: KOPF + `#set box(inset: 8pt)
#show: presentation
== Szene
Text
#scene(x => place(top + left, dx: x * 100pt, ${GRUEN("Punkt")}), stops: (0, 1, 2), tween: 0, width: 400pt, height: 100pt)
== Daumenkino
Text
#flipbook(t => ${GRUEN("Flip")}, frames: 2, loop: false, width: 200pt, height: 80pt)
== Morph
Vorher #morph("m")[#${GRUEN("Morph")}] nachher
` },
  { name: "#set rect(outset: 8pt)", folien: [[0, [["Lauf hinter #pause", "gruen", RUMPF]]]],
    deck: KOPF + `#set rect(outset: 8pt)
#show: presentation
== Pause
Text
#pause
#${GRUEN("Wort nach der Pause")}
` },
  { name: "#set block(inset: 8pt) hinter presentation", folien: [
      [0, [["Block in anim", "gruen", RUMPF]]],
      [1, [["Block in stagger", "gruen", RUMPF]]],
      [2, [["Block in alternatives", "gruen", RUMPF]]]],
    deck: KOPF + `#show: presentation
#set block(inset: 8pt)
== Anim
Text
#anim(block(stroke: 1pt + blue, ${GRUEN("Block in anim")}))
== Stagger
#stagger([Eins], block(stroke: 1pt + blue, ${GRUEN("Block in stagger")}))
== Alternatives
#alternatives([A], block(stroke: 1pt + blue, ${GRUEN("Block in alternatives")}))
` },
  { name: "Themengröße und Rand in em", folien: [[0, [NUMMER]]],
    deck: KOPF + `#show: presentation.with(margin: 1em, theme: themes.default + (size: 2em))
== Eins
Text.
` },
  { name: "#set block(width: 80%)", folien: [
      [0, [["Block hinter #pause", "blau", RUMPF]]],
      [1, [["anim(align(center))", "gruen", RUMPF]]],
      [2, [["Anmerkung", "gruen", RUMPF]]]],
    deck: KOPF + `#set block(width: 80%)
#show: presentation
== Pause
Text
#pause
#block(stroke: 1.5pt + blue, ${GRUEN("Block hinter der Pause")})
== Mitte
Text
#anim(align(center, ${GRUEN("Mitte")}))
== Fussnote
Text#footnote[#${GRUEN("Eine lange Anmerkung, die fast die ganze Breite unter der Folie füllt, damit man sieht, wie breit ihr Platz im Browser ist und wo sie endet.")}]
` },
  { name: "Anmerkung unter Themengröße in em", folien: [[0, [["Anmerkung", "gruen", RUMPF]]]],
    deck: KOPF + `#show: presentation.with(theme: themes.default + (size: 1.3em))
== Fussnote
Text#footnote[#${GRUEN("Eine lange Anmerkung, die fast die ganze Breite unter der Folie füllt: an ihrem Ende zeigt sich, wie breit ihr Platz im Browser ist.")}]
` },
];

// Der Tintenrahmen einer Farbe in einem Bereich, in Pixeln des Bildes.
function rahmen(bild, farbe, bereich) {
  const f = FARBE[farbe];
  const x0 = Math.round(bereich[0] * bild.breite), y0 = Math.round(bereich[1] * bild.hoehe);
  const x1 = Math.round(bereich[2] * bild.breite), y1 = Math.round(bereich[3] * bild.hoehe);
  let r = null;
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      const p = bild.punkt(x, y);
      if (!p || !f(p[0], p[1], p[2])) continue;
      if (!r) r = [x, y, x + 1, y + 1];
      else { r[0] = Math.min(r[0], x); r[1] = Math.min(r[1], y);
             r[2] = Math.max(r[2], x + 1); r[3] = Math.max(r[3], y + 1); }
    }
  }
  return r;
}

// Ein Ausschnitt eines Bildes als eigenes Bild, mit derselben Schnittstelle:
// die Bühne aus dem Bildschirmfoto.
function ausschnitt(bild, x0, y0, b, h) {
  return { breite: b, hoehe: h, punkt: (x, y) =>
    (x < 0 || y < 0 || x >= b || y >= h) ? null : bild.punkt(x + x0, y + y0) };
}

function paketpfad() {
  const pp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zier-pk-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(pp, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(pp, raum, "typstage", "0.1.3"), "dir");
  }
  return pp;
}

function uebersetzen(pp, tmp, quelle, ziel, ...extra) {
  try {
    execFileSync("typst", ["compile", "--package-path", pp, "--root", tmp, ...extra,
      quelle, ziel], { stdio: ["ignore", "ignore", "pipe"] });
    return null;
  } catch (e) {
    return String(e.stderr || "").split("\n").find(z => z.startsWith("error:")) || "unbekannter Fehler";
  }
}

(async () => {
  const chrome = arg("--browser", null) || browserSuchen();
  const pp = paketpfad();
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zier-"));
  // Wie die Bauordner in `pruefe-decks.js`: `exit` läuft auch nach Strg-C,
  // denn die Signalhaken aus `cdp.js` enden in `process.exit` -- das `finally`
  // unten erreicht ein Abbruch nicht. Gemessen ohne das: nach SIGINT lagen
  // `typstage-zier-*` und `typstage-zier-pk-*` noch da. `rmSync` folgt dem
  // Verweis im Paketpfad nicht, der Arbeitsbaum bleibt stehen.
  process.on("exit", () => {
    for (const d of [tmp, pp]) {
      try { fs.rmSync(d, { recursive: true, force: true }); } catch (e) { /* dann eben nicht */ }
    }
  });
  const klagen = [];
  const b = await starte(chrome);
  try {
    for (const [i, fall] of FAELLE.entries()) {
      const [fb, fh] = fall.fenster || [1600, 900];
      const tol = fall.tol || TOL;
      const quelle = path.join(tmp, "f" + i + ".typ");
      fs.writeFileSync(quelle, fall.deck);
      // Papier: jede Folie eine Seite, in der Auflösung des Fensters.
      const ppi = String(fb / BREITE * 72);
      let fehler = uebersetzen(pp, tmp, quelle, path.join(tmp, "f" + i + "-{0p}.png"), "--ppi", ppi);
      fehler = fehler || uebersetzen(pp, tmp, quelle, path.join(tmp, "f" + i + ".html"),
                                     "--features", "html", "--format", "html");
      if (fehler) { klagen.push(fall.name + ": übersetzt nicht -- " + fehler); continue; }
      const seiten = fs.readdirSync(tmp).filter(f => f.startsWith("f" + i + "-") && f.endsWith(".png")).sort();

      await b.ruf("Emulation.setDeviceMetricsOverride",
                  { width: fb, height: fh, deviceScaleFactor: 1, mobile: false });
      await b.navigiere("about:blank"); await schlaf(150);
      await b.navigiere("file://" + path.join(tmp, "f" + i + ".html"));
      await schlaf(1200);
      for (const [folie, marken] of fall.folien) {
        // Der letzte Schritt der Folie: dort steht, was die Seite zeigt.
        await b.ev(`(function(){ var s = typstage.steps.map(function(x, k){ return [x, k]; })
          .filter(function(p){ return p[0].slide === ${folie}; });
          typstage.goto(s[s.length - 1][1], true); })()`);
        await schlaf(1500);
        const st = JSON.parse(await b.ev(`JSON.stringify((function(){
          var q = document.getElementById('ts-stage').getBoundingClientRect();
          return [q.left, q.top, q.width, q.height]; })())`));
        const foto = pngLesen(await b.bild());
        const buehne = ausschnitt(foto, Math.round(st[0]), Math.round(st[1]),
                                  Math.round(st[2]), Math.round(st[3]));
        const seite = pngLesen(fs.readFileSync(path.join(tmp, seiten[folie])).toString("base64"));
        if (seite.breite !== buehne.breite || seite.hoehe !== buehne.hoehe) {
          klagen.push(fall.name + ", Folie " + (folie + 1) + ": die Seite misst "
            + seite.breite + " x " + seite.hoehe + " px, die Bühne " + buehne.breite + " x "
            + buehne.hoehe + " -- eine der beiden hat nicht die Form der Folie");
          continue;
        }
        for (const [was, farbe, bereich] of marken) {
          const p = rahmen(seite, farbe, bereich), h = rahmen(buehne, farbe, bereich);
          const bruch = r => r ? [r[0] / buehne.breite, r[1] / buehne.hoehe,
                                  r[2] / buehne.breite, r[3] / buehne.hoehe]
                                   .map(v => v.toFixed(4)).join(", ") : "keine Tinte";
          const weit = (p && h) ? Math.max(...p.map((v, k) => Math.abs(v - h[k]))) : Infinity;
          if (LAUT) console.log("  " + fall.name + ", Folie " + (folie + 1) + ", " + was
            + ": PDF [" + bruch(p) + "], HTML [" + bruch(h) + "], " + weit + " px");
          if (weit > tol) {
            klagen.push(fall.name + ", Folie " + (folie + 1) + ": " + was + " im PDF ["
              + bruch(p) + "], im HTML [" + bruch(h) + "]"
              + (weit < Infinity ? " -- " + weit + " px daneben" : ""));
          }
        }
      }
      const laufzeit = await b.ev("typstage.pruef.stand().fehler");
      if (laufzeit) klagen.push(fall.name + ": die Laufzeit meldet " + laufzeit + " Klage(n)");
    }
  } finally {
    await b.ende();
    fs.rmSync(tmp, { recursive: true, force: true });
    fs.rmSync(pp, { recursive: true, force: true });
  }
  if (klagen.length) {
    console.log("Zier: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Zier: Nummer, Laufzeile, Fußlinie, Leiste und Rumpf stehen im Browser wie im PDF ("
    + FAELLE.length + " Decks)");
})().catch(e => { console.error(e); process.exit(1); });
