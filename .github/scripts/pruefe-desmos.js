// pruefe-desmos.js — tut die Desmos-Brücke, was sie zusagt?
//
// Von Hand, nicht in der CI. Die Probe lädt Desmos' Skript von desmos.com und
// braucht dafür einen API-Schlüssel; beides gehört nicht in einen Lauf, der
// bei jedem Push grün sein soll. Der Rundgang zitiert die Desmos-Ausfuhren
// aus demselben Grund, statt eine Folie dafür zu bauen: ein veröffentlichtes
// Deck trüge den Schlüssel mit sich.
//
//   node .github/scripts/pruefe-desmos.js [--key SCHLÜSSEL]
//
// Ohne --key nimmt sie Desmos' Demo-Schlüssel, den deren Doku zum
// Ausprobieren nennt.
//
// Geprüft wird, was man sonst nur glauben müsste:
//   1. der Rahmen meldet sich überhaupt an          (ready)
//   2. das Startbild steht                          (expressions, bounds)
//   3. dsm-tween läuft und kommt an                 (Zwischenwert, Endwert)
//   4. dsm-tween läuft beim Weiterblättern NICHT neu an
//   5. dsm-set legt einen Ausdruck nach
//   6. dsm-hide verbirgt ihn, ohne ihn zu entfernen
//
// Punkt 4 ist der Grund, warum es diese Datei gibt. Ein ganzzahliges `at`
// wird zu "ab diesem Schritt", nicht zu "auf diesem"; die erste Fassung von
// `dsm-tween` ließ den Regler deshalb bei jedem Weiterblättern von 3 auf 0,75
// zurückspringen und erneut wachsen. Am Bildschirm sieht man das sofort, im
// Quelltext nie.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => process.argv.indexOf(n) >= 0
  ? process.argv[process.argv.indexOf(n) + 1] : v;
const KEY = arg("--key", "dcb31709b452b1cf9dc26972add0fda6");
const CHROME = arg("--chrome",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

// Das Deck steht als eigene Datei daneben, damit es nicht nur diese Probe
// gibt: wer der Brücke zusehen will, übersetzt es von Hand und öffnet es.
const DECK = fs.readFileSync(path.join(__dirname, "desmos-probe.typ"), "utf8");

const AUSDRUECKE = `(function(){
  var f=document.querySelector('iframe');
  try{ var c=f.contentWindow.tsDesmos; if(!c) return null;
       return c.getExpressions().map(function(e){
         return { id: e.id, latex: e.latex || "", hidden: !!e.hidden }; });
  }catch(e){ return null; }})()`;

function a_wert(liste) {
  if (!liste) return null;
  for (const e of liste) if (e.id === "a") {
    const m = /=\s*(-?[0-9.]+)\s*$/.exec(e.latex);
    if (m) return parseFloat(m[1]);
  }
  return null;
}

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-desmos-"));
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-desmos-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.1.0"));
  }
  fs.writeFileSync(path.join(tmp, "deck.typ"), DECK);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", tmp, "--input", "desmos-key=" + KEY,
    path.join(tmp, "deck.typ"), path.join(tmp, "deck.html")]);

  const b = await starte(CHROME);
  const klagen = [];
  await b.ruf("Page.addScriptToEvaluateOnNewDocument", { source: `
    window.__post=[];
    addEventListener("message",function(e){
      if(e.data&&e.data.typstage===1&&e.data.ready)__post.push(e.data.ready);
    });` });
  await b.navigiere("file://" + path.join(tmp, "deck.html"));
  await schlaf(9000);

  // 1. Anmeldung
  const bereit = JSON.parse(await b.ev("JSON.stringify(window.__post||[])"));
  if (!bereit.includes("graph")) {
    klagen.push("der Rahmen hat sich nicht angemeldet (ready fehlt). Ohne die "
      + "Anmeldung schickt der Kern nichts, und der Graph steht nur da.");
  }

  // 2. Startbild
  await b.taste("ArrowRight");
  await schlaf(1500);
  let liste = JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")"));
  if (!liste || !liste.some(e => e.id === "kurve")) {
    klagen.push("das Startbild fehlt: der Ausdruck `kurve` steht nicht im Rechner.");
  }

  // 3. + 4. Tween: läuft, kommt an, und läuft danach nicht wieder an
  await b.taste("ArrowRight");
  await schlaf(250);
  const mitten = a_wert(JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")")));
  await schlaf(1600);
  const angekommen = a_wert(JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")")));
  if (mitten === null || angekommen === null) {
    klagen.push("der Regler `a` ist nicht zu lesen.");
  } else {
    if (!(mitten > 0.2 && mitten < 2.9)) {
      klagen.push("die Tween wurde nicht in Bewegung angetroffen: `a` stand "
        + "bei " + mitten + ", erwartet war ein Wert zwischen 0,2 und 2,9.");
    }
    if (Math.abs(angekommen - 3) > 0.01) {
      klagen.push("die Tween kam nicht an: `a` steht bei " + angekommen
        + " statt bei 3.");
    }
  }
  await b.taste("ArrowRight");
  await schlaf(250);
  const danach = a_wert(JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")")));
  if (danach === null || Math.abs(danach - 3) > 0.01) {
    klagen.push("die Tween läuft beim Weiterblättern noch einmal an: `a` steht "
      + "gleich nach dem Schritt bei " + danach + " statt bei 3. Ein "
      + "ganzzahliges `at` wird zu \"ab diesem Schritt\"; die Bewegung gehört "
      + "auf genau einen, und ab dem nächsten gehört der Endwert gesetzt.");
  }

  // 5. dsm-set
  await schlaf(1200);
  liste = JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")"));
  if (!liste || !liste.some(e => e.id === "gerade")) {
    klagen.push("dsm-set hat nichts angelegt: `gerade` fehlt.");
  }

  // 6. dsm-hide
  await b.taste("ArrowRight");
  await schlaf(1500);
  liste = JSON.parse(await b.ev("JSON.stringify(" + AUSDRUECKE + ")"));
  const g = (liste || []).find(e => e.id === "gerade");
  if (!g) {
    klagen.push("dsm-hide hat `gerade` entfernt statt verborgen. Ein "
      + "verborgener Ausdruck bleibt im Rechner und rechnet weiter mit.");
  } else if (!g.hidden) {
    klagen.push("dsm-hide hat `gerade` nicht verborgen.");
  }

  await b.ende();
  fs.rmSync(tmp, { recursive: true, force: true });
  fs.rmSync(paket, { recursive: true, force: true });

  if (klagen.length) {
    console.log("Desmos: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Desmos: Anmeldung, Startbild, Tween, Nachlegen und Verbergen -- alles wie zugesagt");
})().catch(e => { console.error(e); process.exit(1); });
