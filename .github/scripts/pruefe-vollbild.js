// pruefe-vollbild.js — `bleed` im Browser: Sprites, Flug, Leiste, Druckansicht
//
//   node .github/scripts/pruefe-vollbild.js [--browser /pfad]
//
// Das Abnahmedeck aus `pruefe-vollbild.py`, nur dass die titellose Folie hier
// einen `morph` trägt: die Kette `m` fliegt aus dem Bild weiter. Gemessen
// wird, was keine Datei sagt:
//
// - wo die Sprites im Bild sitzen, in pt der Leinwand, gegen das Rechteck von
//   `.ts-bg svg` (so rechnet auch die Laufzeit). Ein place im bleed zählt von
//   der Ecke der Leinwand, eines im Rumpf vom Rand des Rumpfs;
// - ob `k` und `m` von Folie 1 auf das Bild fliegen und `m` von dort weiter,
//   mit eingefrorenen Animationen und Anfang und Ende jedes Geistes;
// - ob die Leiste auf der bleed-Folie unsichtbar ist und auf der nächsten
//   wieder steht, mit deren Anteil;
// - ob die Druckansicht auf der bleed-Folie kein Chrome und nirgends die
//   Leiste der Bühne zeigt. Die stand vorher auf Blatt eins, mit dem Stand der
//   Folie, auf der der Vortrag gerade war.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const W = 841.89, H = 473.563125, TOL = 0.5;

const DECK = `#import "@preview/typstage:0.1.3": *
#show: presentation.with(theme: themes.lesson + (footer: "fraction", progress: "bar"))

= Abschnitt Eins

== Mit Titel
#place(dx: 60pt, dy: 40pt, morph("k", rect(width: 100pt, height: 60pt, fill: red)))
#place(dx: 300pt, dy: 40pt, morph("m", circle(radius: 20pt, fill: orange)))
Erste Folie.

==
#bleed[
  #image(bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 9'><rect width='16' height='9' fill='#1c3a5c'/></svg>"), format: "svg", width: 100%, height: 100%, fit: "cover")
  #place(dx: 600pt, dy: 60pt, morph("m", circle(radius: 30pt, fill: orange)))
  #place(top + left, dx: 40pt, dy: 300pt, anim(at: 2, rect(width: 160pt, height: 50pt, fill: white)))
]
#place(dx: 500pt, dy: 250pt, morph("k", rect(width: 200pt, height: 120pt, fill: red)))

==
#place(dx: 400pt, dy: 100pt, morph("m", circle(radius: 25pt, fill: orange)))
Text auf einer Folie ohne Titel.

== Mit Titel
Normaler Inhalt.
`;

// Rechtecke der Sprites einer Folie auf ihrem letzten Schritt, in pt.
const SPRITES = (i) => `(function(){
  var alle = typstage.steps.map(function(s, k){ return [s, k]; }).filter(function(p){ return p[0].slide === ${i}; });
  typstage.goto(alle[alle.length - 1][1], true);
  var f = typstage.slides[${i}], bg = f.querySelector('.ts-bg svg').getBoundingClientRect();
  return JSON.stringify([].slice.call(f.querySelectorAll('.ts-el')).map(function(e){
    var q = e.getBoundingClientRect();
    return { name: e.dataset.name || '', at: e.dataset.at,
      r: [(q.left - bg.left) / bg.width * ${W}, (q.top - bg.top) / bg.height * ${H},
          q.width / bg.width * ${W}, q.height / bg.height * ${H}] };
  }));
})()`;

// Ein Flug mit angehaltenen Animationen: Anfang und Ende jedes Geistes.
const FLUG = (i, taste) => `(function(){
  var s = typstage.steps.map(function(x, k){ return [x, k]; }).filter(function(p){ return p[0].slide === ${i}; });
  typstage.goto((${JSON.stringify(taste)} === 'ArrowRight' ? s[s.length - 1] : s[0])[1], true);
  var orig = Element.prototype.animate, anims = [];
  Element.prototype.animate = function(){ var a = orig.apply(this, arguments); anims.push(a); try { a.pause(); } catch (e) {} return a; };
  var oT = window.setTimeout; window.setTimeout = function(){ return 0; };
  document.dispatchEvent(new KeyboardEvent('keydown', { key: ${JSON.stringify(taste)}, bubbles: true, cancelable: true }));
  var st = document.getElementById('ts-stage').getBoundingClientRect();
  var pt = function(q){ return [(q.left - st.left) / st.width * ${W}, (q.top - st.top) / st.height * ${H}, q.width / st.width * ${W}, q.height / st.height * ${H}]; };
  var zeit = function(f){ anims.forEach(function(a){ var t = a.effect && a.effect.getTiming(); if (t) try { a.currentTime = (t.delay || 0) + (t.duration || 0) * f; } catch (e) {} }); };
  var g = [].slice.call(document.getElementById('ts-fly').children);
  zeit(0); var a0 = g.map(function(x){ return pt(x.getBoundingClientRect()); });
  zeit(1); var a1 = g.map(function(x){ return pt(x.getBoundingClientRect()); });
  Element.prototype.animate = orig; window.setTimeout = oT;
  return JSON.stringify({ von: a0, nach: a1 });
})()`;

const LEISTE = `(function(){ var f = document.getElementById('ts-fortschritt'), s = typstage.steps[typstage.state()];
  return JSON.stringify({ folie: s.slide, deckkraft: +getComputedStyle(f).opacity, transform: f.style.transform }); })()`;

const gleich = (a, b) => a.every((v, k) => Math.abs(v - b[k]) <= TOL);
const hat = (liste, r) => liste.some(x => gleich(x, r));

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-vollbild-"));
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-vollbild-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.1.3"));
  }
  fs.writeFileSync(path.join(tmp, "deck.typ"), DECK);
  try {
    execFileSync("typst", ["compile", "--format", "html", "--features", "html",
      "--package-path", paket, "--root", tmp,
      path.join(tmp, "deck.typ"), path.join(tmp, "deck.html")],
      { stdio: ["ignore", "ignore", "pipe"] });
  } catch (e) {
    const wort = String(e.stderr || "").split("\n").find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Vollbild: das Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }
  const url = "file://" + path.join(tmp, "deck.html");
  const b = await starte(CHROME);
  const klagen = [];
  const frisch = async () => { await b.navigiere("about:blank"); await schlaf(150); await b.navigiere(url); await schlaf(1500); };
  try {
    await b.ruf("Emulation.setDeviceMetricsOverride", { width: 1346, height: 757, deviceScaleFactor: 1, mobile: false });
    await frisch();

    // ── Wo die Sprites sitzen ────────────────────────────────────────────
    const f2 = JSON.parse(await b.ev(SPRITES(2)));
    const soll = [["m", [600, 60, 60, 60], "morph im bleed, place ohne Anker hinter dem Bild"],
                  ["", [40, 300, 160, 50], "anim im bleed"],
                  ["k", [532, 308, 200, 120], "morph im Rumpf, 500/250 vom Rand des Rumpfs"]];
    for (const [name, r, was] of soll) {
      const x = f2.find(e => e.name === name && (name || e.at === "2-"));
      if (!x || !gleich(x.r, r)) {
        klagen.push(was + ": Sprite bei " + (x ? x.r.map(v => v.toFixed(2)).join(", ") : "nicht gefunden")
          + " statt " + r.join(", ") + " (pt der Leinwand)");
      }
    }

    // ── Flüge ────────────────────────────────────────────────────────────
    const fluege = [[1, "ArrowRight", [[600, 60, 60, 60], [532, 308, 200, 120]], "auf das Bild"],
                    [2, "ArrowLeft", [[92, 157.39, 100, 60], [332, 157.39, 40, 40]], "vom Bild zurück"]];
    for (const [von, taste, ziele, was] of fluege) {
      await frisch();
      const f = JSON.parse(await b.ev(FLUG(von, taste)));
      for (const z of ziele) {
        if (!hat(f.nach, z)) klagen.push("Flug " + was + ": kein Geist endet bei " + z.join(", ")
          + " (Enden: " + JSON.stringify(f.nach.map(r => r.map(v => +v.toFixed(1)))) + ")");
      }
    }
    // Und aus dem Bild weiter auf die titellose Folie: dort beginnt der Rumpf
    // m.top + head-gap unter der Oberkante, ohne Laufzeile (58pt bei lesson).
    await frisch();
    const weiter = JSON.parse(await b.ev(FLUG(2, "ArrowRight")));
    if (!hat(weiter.von, [600, 60, 60, 60]) || !hat(weiter.nach, [432, 158, 50, 50])) {
      klagen.push("Flug vom Bild weiter: kein Geist von 600, 60 nach 432, 158 ("
        + JSON.stringify(weiter) + ")");
    }

    // ── Die Leiste ───────────────────────────────────────────────────────
    await frisch();
    await b.ev("typstage.goto(typstage.steps.findIndex(function(s){ return s.slide === 1; }), true)");
    await schlaf(900);
    const stand = [];
    for (let k = 0; k < 3; k++) {
      await b.taste("ArrowRight"); await schlaf(1200);
      stand.push(JSON.parse(await b.ev(LEISTE)));
    }
    const auf2 = stand.filter(s => s.folie === 2), auf3 = stand.find(s => s.folie === 3);
    if (!auf2.length || auf2.some(s => s.deckkraft > 0.01)) {
      klagen.push("Leiste auf der bleed-Folie: " + JSON.stringify(auf2));
    }
    if (!auf3 || auf3.deckkraft < 0.99 || auf3.transform !== "scaleX(0.75)") {
      klagen.push("Leiste auf der Folie danach: " + JSON.stringify(auf3));
    }
    const leer = await b.ev("document.querySelectorAll('#ts-chrome > .ts-chrome')[2].children.length");
    if (leer !== 0) klagen.push("der Chrome-Eintrag der bleed-Folie hat " + leer + " Kind(er)");

    // ── Druckansicht ─────────────────────────────────────────────────────
    await b.ev("typstage.goto(typstage.steps.length - 1, true)"); await schlaf(600);
    await b.ruf("Emulation.setEmulatedMedia", { media: "print" });
    const druck = JSON.parse(await b.ev(`JSON.stringify({
      leiste: getComputedStyle(document.getElementById('ts-fortschritt')).display,
      chromep: [].slice.call(document.querySelectorAll('.ts-slide')).map(function(f){ return !!f.querySelector('.ts-chromep'); }) })`));
    await b.ruf("Emulation.setEmulatedMedia", { media: "" });
    if (druck.leiste !== "none") klagen.push("Druckansicht: die Leiste der Bühne steht mit im Druck");
    if (druck.chromep[2]) klagen.push("Druckansicht: die bleed-Folie trägt ein Druck-Chrome");
    if (!druck.chromep[3]) klagen.push("Druckansicht: die titellose Folie hat kein Druck-Chrome");

    const fehler = await b.ev("typstage.pruef.stand().fehler");
    if (fehler) klagen.push("die Laufzeit meldet " + fehler + " Klage(n): "
      + JSON.stringify(await b.ev("typstage.pruef.fehler()")));
  } finally {
    await b.ende();
    fs.rmSync(tmp, { recursive: true, force: true });
    fs.rmSync(paket, { recursive: true, force: true });
  }
  if (klagen.length) {
    console.log("Vollbild: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Vollbild: Sprites auf der Leinwand, Flug, Leiste und Druck stimmen");
})().catch(e => { console.error(e); process.exit(1); });
