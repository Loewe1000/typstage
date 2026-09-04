// pruefe-cue-folien.js — wem gehört ein Punkt einer cue-Gruppe?
//
// Zwei Zusicherungen, die beide daran hängen, wie eine Gruppe sich selbst
// zusammenhält: sie bleibt auf ihrer Folie, und eine Schicht sitzt auf dem
// Schritt ihres Punktes.
//
//   node .github/scripts/pruefe-cue-folien.js [--browser /pfad]
//
// Zwei gleichnamige Gruppen auf zwei Folien sind zwei Gruppen. Jede zählt für
// sich von 1, jede hört auf ihre eigenen Ziffern, und keine sieht die Punkte
// der anderen. Der Saal ruft mit den Tasten 1 bis 9; laufen die Nummern über
// die Folien weiter, ruft ab der zweiten Folie niemand mehr die 1 -- und ab
// der fünften Folie übersetzt das Deck gar nicht mehr.
//
// Diese Probe fehlte, als die Trennung einmal vom Folienpräfix im Schlüssel
// abhing und dieser Präfix entfernt wurde. Sie prüft die Zusicherung selbst,
// nicht das Mittel, mit dem sie gerade erfüllt wird.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

// Fünf Folien mit derselben Gruppe: dokumentweit gezählt wären das zehn
// Punkte, und der zehnte bricht die Übersetzung ab.
const DECK = `#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [Folien])

== Eins
#cue("p", [a1], [a2], start: 2)

== Zwei
#cue("p", [b1], [b2], start: 2)

== Drei
#cue("p", [c1], [c2], start: 2)

== Vier
#cue("p", [d1], [d2], start: 2)

== Fünf
#cue("p", [e1], [e2], start: 2)
`;

// Was die Laufzeit über die Gruppen sagt: je Folie eine, jede mit den
// Ziffern 1 und 2.
const gruppen = `JSON.stringify(window.typstage.pruef.adaptiv().map(function(g){
  return { name: g.name, folie: g.folie, nummern: g.nummern };
}))`;

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-folien-"));
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-folien-pkg-"));
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
    console.log("cue-Folien: 1 Beanstandung");
    console.log("  - das Probedeck übersetzt nicht -- " + wort);
    console.log("    Fünf Folien mit gleichnamiger Gruppe sind fünf Gruppen zu "
      + "je zwei Punkten, nicht eine zu zehn.");
    process.exit(1);
  }

  const b = await starte(CHROME);
  await b.navigiere("file://" + path.join(tmp, "deck.html"));
  await schlaf(2500);
  const klagen = [];

  const g = JSON.parse(await b.ev(gruppen));
  // Fünf Gruppen, je eine je Folie, jede mit den Ziffern 1 und 2.
  const ist = g.map(x => x.folie + ":" + x.name + "=" + x.nummern.join(","))
               .sort().join("  ");
  const soll = [1, 2, 3, 4, 5].map(f => f + ":p=1,2").join("  ");
  if (ist !== soll) {
    klagen.push("die Laufzeit sieht " + (ist || "keine Gruppe") + ", erwartet "
      + "wäre " + soll + ". Gleichnamige Gruppen auf verschiedenen Folien "
      + "dürfen nicht zu einer verschmelzen, und jede zählt von 1.");
  }

  // Und die Ziffer greift auch auf der letzten Folie. Ohne Trennung stünde
  // dort die 9 und die 10, und die 1 bewirkte nichts.
  await b.taste("End");
  await schlaf(700);
  const vor = await b.ev("window.typstage.state()");
  await b.taste("1");
  await schlaf(800);
  const nach = await b.ev("window.typstage.state()");
  if (!(nach < vor)) {
    klagen.push("auf der letzten Folie bewirkt die Ziffer 1 nichts (Halt "
      + vor + " bleibt " + nach + "). Jede Gruppe muss auf ihre eigene 1 "
      + "hören.");
  }

  await b.ende();

  // ── Und eine Schicht sitzt auf dem Schritt ihres Punktes ────────────────
  //
  // Auch dann, wenn die Aufrufe nicht lückenlos aufeinanderfolgen. Wird der
  // Schritt aus "Basis plus Nummer" zurückgerechnet, stimmt er nur bei
  // dichten Gruppen -- gemessen landete die Schicht zu Punkt 2 bei
  // `start: 2` und `start: 7` auf Schritt 3 statt auf 7, also eine Ecke des
  // Bildes ohne das Bild.
  const LUECKE = `#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [Lücke])

== Folie
#cue("g", [a], start: 2)
#cue("g", [b], start: 7)
#cue-layer("g", 2, [dazu])
`;
  fs.writeFileSync(path.join(tmp, "luecke.typ"), LUECKE);
  try {
    execFileSync("typst", ["compile", "--format", "html", "--features", "html",
      "--package-path", paket, "--root", tmp,
      path.join(tmp, "luecke.typ"), path.join(tmp, "luecke.html")],
      { stdio: ["ignore", "ignore", "pipe"] });
    const roh = fs.readFileSync(path.join(tmp, "luecke.html"), "utf8");
    const schritte = (roh.match(/<[^>]*data-ad="[^"]*"[^>]*>/g) || [])
      .map(el => {
        const nr = /data-ad-nr="([^"]*)"/.exec(el);
        const at = /data-at="([^"]*)"/.exec(el);
        return (nr ? nr[1] : "?") + "@" + (at ? at[1] : "?");
      });
    const sollL = ["1@2-", "2@7-", "2@7-"];
    if (schritte.join(" ") !== sollL.join(" ")) {
      klagen.push("bei ausgeschriebenen start-Werten stehen Punkte und Schicht "
        + "auf " + schritte.join(" ") + ", erwartet wäre " + sollL.join(" ")
        + ". Eine Schicht muss den gemerkten Schritt ihres Punktes nehmen, "
        + "nicht einen aus der Nummer zurückgerechneten.");
    }
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    klagen.push("das Lückendeck übersetzt nicht -- " + wort);
  }

  fs.rmSync(tmp, { recursive: true, force: true });
  fs.rmSync(paket, { recursive: true, force: true });

  if (klagen.length) {
    console.log("cue-Folien: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("cue-Folien: jede Folie hat ihre eigene Gruppe, und jede Schicht ihren Punkt");
})().catch(e => { console.error(e); process.exit(1); });
