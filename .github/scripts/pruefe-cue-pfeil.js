// pruefe-cue-pfeil.js — nimmt eine cue-Gruppe den Pfeil erst, wenn sie dran ist?
//
//   node .github/scripts/pruefe-cue-pfeil.js [--browser /pfad]
//
// Eine Gruppe darf den Vorwärtspfeil nur beanspruchen, wenn ihr nächster Punkt
// der unmittelbar nächste Halt ist. Steht sie weiter vorn, muss der Pfeil
// durchfallen und gewöhnlich weiterblättern.
//
// Das ist nur zu sehen, wenn auf der Folie *vor* der Gruppe noch gewöhnliche
// Schritte stehen. Beginnt die Gruppe auf Schritt 1 -- der Fall, den die
// älteren Proben abdeckten --, ist ihr erster Punkt zufällig der nächste Halt,
// und ein zu früher Zugriff ist von richtigem Verhalten nicht zu unterscheiden.
// Genau daran ist der Fehler vorbeigekommen: gemeldet aus einem echten Deck, in
// dem drei Marken erst nach zwei Fragen und einem Zahlenstrahl kamen.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

// Folie 1 bekommt sieben Schritte: 1 leer, 2/3/4 die `anim`, 5/6/7 die Punkte.
// Die Folie danach ist nötig, damit ein Übersprung sichtbar wird, statt am
// Deckende aufzulaufen.
const DECK = `#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [Pfeil])

== Vor der Gruppe
#anim[Frage eins]
#anim[Frage zwei]
#anim[Der Rahmen]
#cue("marken", [A], [B], [C], start: 5)

== Danach
Text.
`;

const lage = `(function(){var s=window.typstage.steps[window.typstage.state()];
  return s.slide+":"+s.step;})()`;
const PFEIL = " -> ";

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pfeil-"));
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pfeil-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.1.1"));
  }
  fs.writeFileSync(path.join(tmp, "deck.typ"), DECK);
  try {
    execFileSync("typst", ["compile", "--format", "html", "--features", "html",
      "--package-path", paket, "--root", tmp,
      path.join(tmp, "deck.typ"), path.join(tmp, "deck.html")],
      { stdio: ["ignore", "ignore", "pipe"] });
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("cue-Pfeil: das Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  await b.navigiere("file://" + path.join(tmp, "deck.html"));
  await schlaf(2500);
  const klagen = [];

  // 1. Vorwärts durch die Folie: kein Halt darf ausfallen.
  const gelaufen = [await b.ev(lage)];
  for (let i = 0; i < 6; i++) {
    await b.taste("ArrowRight");
    await schlaf(700);
    gelaufen.push(await b.ev(lage));
  }
  const soll = ["0:1", "1:1", "1:2", "1:3", "1:4", "1:5", "1:6"];
  if (gelaufen.join(PFEIL) !== soll.join(PFEIL)) {
    klagen.push("sechs Pfeile nach rechts laufen " + gelaufen.join(PFEIL)
      + ", erwartet wäre " + soll.join(PFEIL) + ". Eine Gruppe, die den Pfeil "
      + "vor ihrer Zeit nimmt, springt auf ihren ersten Punkt und verschluckt "
      + "jeden Halt dazwischen.");
  }

  // 2. Von hinten: wer die Gruppe hinter sich hat, darf mit dem Pfeil nicht
  // rückwärts in sie hineinfallen. Diesen Schutz trug schon die alte
  // Bedingung, und er muss bleiben.
  await b.taste("End");
  await schlaf(700);
  await b.taste("ArrowLeft");
  await schlaf(700);
  const hinten = await b.ev(lage);
  await b.taste("ArrowRight");
  await schlaf(700);
  const weiter = await b.ev(lage);
  if (hinten !== "1:7" || weiter !== "2:1") {
    klagen.push("von " + hinten + " führt der Pfeil auf " + weiter
      + ", erwartet wäre 1:7" + PFEIL + "2:1. Wer über `End` hinter die Gruppe "
      + "gesprungen ist, darf nicht in sie zurückfallen.");
  }

  // 3. Ziffer und Pfeil mischen: die gerufene Ziffer nimmt den ersten freien
  // Platz der Gruppe, der Pfeil danach den zweiten.
  await b.taste("Home");
  await schlaf(700);
  for (let i = 0; i < 4; i++) { await b.taste("ArrowRight"); await schlaf(400); }
  const vorZiffer = await b.ev(lage);
  await b.taste("3");
  await schlaf(700);
  const nachZiffer = await b.ev(lage);
  await b.taste("ArrowRight");
  await schlaf(700);
  const nachPfeil = await b.ev(lage);
  if (vorZiffer !== "1:4" || nachZiffer !== "1:5" || nachPfeil !== "1:6") {
    klagen.push("von " + vorZiffer + " führt Ziffer 3 auf " + nachZiffer
      + " und der Pfeil danach auf " + nachPfeil + "; erwartet wäre 1:4"
      + PFEIL + "1:5" + PFEIL + "1:6.");
  }

  await b.ende();
  fs.rmSync(tmp, { recursive: true, force: true });
  fs.rmSync(paket, { recursive: true, force: true });

  if (klagen.length) {
    console.log("cue-Pfeil: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("cue-Pfeil: die Gruppe greift erst, wenn sie dran ist");
})().catch(e => { console.error(e); process.exit(1); });
