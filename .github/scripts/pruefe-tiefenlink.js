// pruefe-tiefenlink.js — zeigt die Adresse auf den Schritt, und hält sie?
//
// Bis 0.1.2 stand im Feld der laufende Schritt über das ganze Deck: `#7`.
// Damit ließ sich zwar jeder Teilschritt ansprechen, aber der Link hielt nur
// bis zur nächsten eingefügten Folie -- alles dahinter rückt weiter. Seit
// 0.2.0 steht dort die Folie und der Schritt darin: `#slide-3` und
// `#slide-3-2`.
//
//   node .github/scripts/pruefe-tiefenlink.js [--browser /pfad] [--laut]
//
// Geprüft wird:
//   1. Blättern schreibt die Adresse mit: `#slide-2`, `#slide-2-2`, …
//   2. Ein Link auf einen Teilschritt trifft ihn, frisch geladen.
//   3. Ein Link auf einen Schritt, den es nicht (mehr) gibt, landet auf dem
//      letzten Schritt seiner Folie statt im Leeren.
//   4. Die alte Form (`#3`) gilt weiter: ein Lesezeichen aus 0.1.2 führt auf
//      denselben Schritt wie damals.
//   5. Eine eingefügte Folie verschiebt nur die Foliennummer und nicht den
//      Schritt: Dasselbe Deck mit einer Folie davor steht am Ende auf
//      demselben Schritt derselben Folie, die nur anders heißt. Mit der alten
//      Form wäre die letzte Adresse von #6 auf #8 gerückt.
//   6. Im Sprecherfenster bleibt `#speaker` stehen.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const LAUT = process.argv.indexOf("--laut") > 0;

const KOPF = `#import "@preview/typstage:0.2.0": *\n`;
const RUMPF = `
== Erste
#anim[Ein Punkt]
#anim[Noch einer]

== Zweite
#anim[Und hier]
`;

const DECKS = {
  deck: KOPF + `#show: presentation.with(title: [Adressen])\n` + RUMPF,
  // Dasselbe Deck mit einer Folie davor: Die Adressen dahinter müssen
  // dieselben bleiben.
  davor: KOPF + `#show: presentation.with(title: [Adressen])

== Eingeschoben
#anim[Ein Punkt]
` + RUMPF,
};

function bauen(quelle, name, paket, ordner) {
  const typ = path.join(ordner, name + ".typ");
  fs.writeFileSync(typ, quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
                         "--package-path", paket, "--root", ordner,
                         typ, path.join(ordner, name + ".html")]);
  return path.join(ordner, name + ".html");
}

const STAND = `JSON.stringify({ hash: location.hash,
                                stand: typstage.pruef.stand() })`;

// Wirklich neu laden. Nur die Adresse zu wechseln ist dieselbe Seite: Der
// Browser springt dann über `hashchange` und lädt nichts. Genau daran hängt
// die Rolle -- `#speaker` wird beim Laden einmal gelesen --, und eine Probe,
// die den Umweg ausläßt, prüft die halbe Sache.
async function frisch(b, schlaf, url) {
  await b.navigiere("about:blank");
  await schlaf(150);
  await b.navigiere(url);
  await schlaf(1500);
}

(async () => {
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-tl-"));
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
    console.log("Tiefenlink: ein Probedeck übersetzt nicht\n  " +
                String(e.stderr || e.message).split("\n").slice(0, 4).join("\n  "));
    fs.rmSync(ordner, { recursive: true, force: true });
    process.exit(1);
  }

  const klagen = [];
  const b = await starte(CHROME);
  const hole = async () => JSON.parse(await b.ev(STAND));
  try {
    await b.ruf("Emulation.setDeviceMetricsOverride",
                { width: 1600, height: 900, deviceScaleFactor: 1, mobile: false });

    // ── 1: Blättern schreibt die Adresse mit ───────────────────────────────
    await frisch(b, schlaf, "file://" + weg.deck);
    const bahn = [];
    for (let i = 0; i < 4; i++) {
      await b.taste("ArrowRight");
      await schlaf(450);
      bahn.push(await hole());
    }
    if (LAUT) bahn.forEach(x => console.log("  1. " + x.hash + "  Folie "
      + x.stand.folie + " Schritt " + x.stand.aufFolie));
    const soll = ["#slide-2", "#slide-2-2", "#slide-2-3", "#slide-3"];
    bahn.forEach((x, i) => {
      if (x.hash !== soll[i]) {
        klagen.push("1. nach " + (i + 1) + " Tastendruck/-drücken steht "
                    + x.hash + " im Feld, erwartet " + soll[i]);
      }
    });

    // ── 2 und 3: ein Link trifft seinen Schritt ────────────────────────────
    for (const [adresse, folie, schritt] of [["#slide-2-3", 1, 3],
                                             ["#slide-2-99", 1, 3]]) {
      await frisch(b, schlaf, "file://" + weg.deck + adresse);
      const x = await hole();
      if (LAUT) console.log("  2/3. " + adresse + " → Folie " + x.stand.folie
                            + " Schritt " + x.stand.aufFolie);
      if (x.stand.folie !== folie || x.stand.aufFolie !== schritt) {
        klagen.push((adresse.endsWith("99") ? "3. " : "2. ") + adresse
                    + " führt auf Folie " + x.stand.folie + ", Schritt "
                    + x.stand.aufFolie + " -- erwartet Folie " + folie
                    + ", Schritt " + schritt);
      }
    }

    // ── 4: die alte Form gilt weiter ───────────────────────────────────────
    await frisch(b, schlaf, "file://" + weg.deck + "#4");
    const alt = await hole();
    if (LAUT) console.log("  4. #4 → " + alt.hash);
    if (alt.stand.schritt !== 3) {
      klagen.push("4. die alte Adresse #4 führt auf Schritt "
                  + alt.stand.schritt + " statt auf den vierten (3, von null "
                  + "gezählt) -- Lesezeichen aus 0.1.2 zeigen ins Leere");
    }

    // ── 5: eine Folie davor verschiebt nichts ──────────────────────────────
    await frisch(b, schlaf, "file://" + weg.davor);
    await b.taste("End");
    await schlaf(600);
    const ende1 = await hole();
    await frisch(b, schlaf, "file://" + weg.deck);
    await b.taste("End");
    await schlaf(600);
    const ende2 = await hole();
    if (LAUT) console.log("  5. mit Folie davor " + ende1.hash
                          + ", ohne " + ende2.hash);
    // `End` geht auf den letzten Schritt der letzten Folie, und der ist hier
    // der zweite.
    if (ende1.hash !== "#slide-4-2" || ende2.hash !== "#slide-3-2") {
      klagen.push("5. die letzte Folie heißt mit einer Folie davor "
                  + ende1.hash + " und ohne " + ende2.hash
                  + " -- erwartet #slide-4-2 und #slide-3-2");
    }
    if (ende1.stand.aufFolie !== ende2.stand.aufFolie) {
      klagen.push("5. die letzte Folie steht auf verschiedenen Schritten ("
                  + ende1.stand.aufFolie + " und " + ende2.stand.aufFolie
                  + ") -- die eingeschobene Folie ändert an ihr nichts");
    }

    // ── 6: das Sprecherfenster behält seine Rolle ──────────────────────────
    await frisch(b, schlaf, "file://" + weg.deck + "#speaker");
    await b.taste("ArrowRight");
    await schlaf(600);
    const sp = await hole();
    if (LAUT) console.log("  6. Sprecherfenster: " + sp.hash);
    if (sp.hash !== "#speaker") {
      klagen.push("6. im Sprecherfenster steht " + sp.hash
                  + " im Feld -- wer neu lädt, bekäme den Vortrag statt der "
                  + "Sprecheransicht");
    }

    const fehler = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.fehler())`));
    if (fehler.length) klagen.push("die Laufzeit meldete " + fehler.length + " Fehler");
  } finally {
    await b.ende();
    fs.rmSync(ordner, { recursive: true, force: true });
  }

  if (klagen.length) {
    console.log("Tiefenlink: " + klagen.length + " Beanstandung(en)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Tiefenlink: die Adresse nennt Folie und Schritt, hält beim "
              + "Einschieben und liest die alte Form weiter (2 Decks, 6 Punkte)");
})();
