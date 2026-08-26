// =============================================================================
// zwei-fenster.js — die Fernsteuerung, mit zwei echten Fenstern
// =============================================================================
// Warum eigens: der große Prüflauf lädt die Sprecheransicht über `#speaker` in
// *einem* Fenster. Damit lässt sich alles prüfen, was ein Fenster für sich
// tut -- aber nichts, was zwischen beiden passiert. Drei Fehler sind genau
// durch diese Lücke gekommen:
//
//   1. Die Zuordnung einer adaptiven Gruppe reiste nicht mit. Im
//      Sprecherfenster stand alles richtig, in der Halle erschien nichts.
//   2. `adSprecher` setzte die Deckkraft eines genannten Punktes auf "",
//      und ein leerer Wert fällt auf die Stilvorlage zurück, wo ein Element
//      unsichtbar ist. Ein Punkt verschwand, sobald der nächste kam.
//   3. Der Empfänger der Zuordnung meldete den *alten* Schritt zurück, und
//      `fernGoto` zog das Sprecherfenster wieder dorthin. Die Fernsteuerung
//      hinkte fortan einen Schritt hinterher.
//
// Keiner davon ist in einem Fenster sichtbar, und keiner in einem Deck mit
// einer einzigen Folie: dort fallen folienlokaler Schritt und Deckschritt
// zusammen. Der Prüfling ist deshalb das mehrfoliige Prüfdeck.
//
//   node .github/scripts/decklauf/zwei-fenster.js [--browser /pfad]
// =============================================================================
const fs = require("fs"), path = require("path"), os = require("os");
const { execFileSync } = require("child_process");
const { starte, schlaf } = require("./cdp.js");

const WURZEL = path.resolve(__dirname, "..", "..", "..");
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

// Das Prüfdeck, gebaut wie im großen Lauf: gegen den Arbeitsbaum, nicht gegen
// ein installiertes Paket.
function deckBauen() {
  const pp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zf-"));
  const ziel = path.join(pp, "schule", "typstage");
  fs.mkdirSync(ziel, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.0"), "dir");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zf-h-")), "pruefdeck.html");
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--root", WURZEL, "--package-path", pp,
    path.join(__dirname, "pruefdeck.typ"), aus], { stdio: ["ignore", "ignore", "pipe"] });
  return aus;
}

const stand = `(function () {
  var s = window.typstage.pruef.stand();
  var b = document.querySelector('#ts-stage') || document;
  var e = [].slice.call(b.querySelectorAll('.ts-el[data-ad]'));
  return JSON.stringify({ schritt: s.schritt, folie: s.folie, auf: s.aufFolie,
    punkte: e.map(function (x) { return x.dataset.ad + x.dataset.adNr + ':'
      + (+getComputedStyle(x).opacity).toFixed(1); }).join(' '),
    fehler: window.typstage.pruef.fehler() });
})()`;

(async () => {
  const datei = deckBauen();
  const halle = await starte(arg("--browser", null) || browserSuchen());
  let maengel = [];
  const sagt = (b, s) => { console.error("ABWEICHUNG " + b + ": " + s); maengel.push(s); };
  try {
    await halle.navigiere("file://" + datei);
    await schlaf(1200);
    // Das Sprecherfenster so öffnen, wie es im Betrieb geöffnet wird.
    const kommt = halle.zweites();
    await halle.taste("n");
    const sprecher = await kommt;
    await schlaf(1500);

    // Bis zur ersten adaptiven Gruppe blättern. Sie steht nicht auf der
    // ersten Folie -- gerade das ist der Punkt.
    const zurGruppe = `(function () {
      var st = window.typstage.steps;
      for (var k = 0; k < st.length; k++) {
        var sec = window.typstage.slides[st[k].slide];
        if (sec && sec.querySelector('.ts-el[data-ad]') && st[k].step === 1) {
          window.typstage.goto(k, true); return k;
        }
      }
      return -1;
    })()`;
    const k = await sprecher.ev(zurGruppe);
    if (k < 0) { sagt("aufbau", "keine adaptive Gruppe im Prüfdeck gefunden"); }
    await schlaf(900);

    const beide = async () => ({
      h: JSON.parse(await halle.ev(stand)),
      s: JSON.parse(await sprecher.ev(stand))
    });

    let vorher = await beide();
    if (vorher.h.punkte.split(" ").some(x => !x.endsWith(":0.0"))) {
      sagt("start", "in der Halle steht ein Punkt, bevor eine Ziffer gedrückt wurde: " + vorher.h.punkte);
    }

    // Der Kern: eine Ziffer im Sprecherfenster.
    // Mit einer Luecke: erst die 3, dann muss der Pfeil die 1 nehmen. Waehlte
    // man 2 und 1, waere "der naechste offene" und "der naechste der Zaehlung"
    // dieselbe Antwort, und eine Verwechslung der beiden bliebe unsichtbar --
    // gemessen, genau so ist sie beim ersten Anlauf durchgerutscht.
    const folge = ["3"];
    let erwartet = [];
    for (const z of folge) {
      await sprecher.taste(z);
      await schlaf(900);
      const a = await beide();
      erwartet.push(z);
      // (1) Beide Fenster stehen auf demselben Schritt.
      if (a.h.schritt !== a.s.schritt) {
        sagt("ziffer " + z, "Halle steht auf Schritt " + a.h.schritt
          + ", Sprecher auf " + a.s.schritt);
      }
      // (2) In der Halle ist genau das Genannte zu sehen.
      for (const nr of erwartet) {
        if (!a.h.punkte.includes("probe" + nr + ":1.0")) {
          sagt("ziffer " + z, "Punkt " + nr + " fehlt in der Halle: " + a.h.punkte);
        }
      }
      // (3) Nichts Ungenanntes ist zu sehen.
      for (const nr of ["1", "2", "3"]) {
        if (!erwartet.includes(nr) && a.h.punkte.includes("probe" + nr + ":1.0")) {
          sagt("ziffer " + z, "Punkt " + nr + " steht in der Halle, ohne genannt zu sein");
        }
      }
      // (4) Und im Sprecherfenster steht das Genannte ebenfalls voll da.
      // Ohne diese Prüfung bleibt der zweite der drei Fehler unsichtbar: er
      // sitzt allein in der Sprecheransicht, wo ein genannter Punkt auf die
      // Stilvorlage zurückfiel und verschwand, sobald der nächste kam.
      for (const nr of erwartet) {
        if (!a.s.punkte.includes("probe" + nr + ":1.0")) {
          sagt("ziffer " + z, "Punkt " + nr + " fehlt im Sprecherfenster: " + a.s.punkte);
        }
      }
      // Ein noch nicht genannter Punkt steht dort blass zur Auswahl.
      for (const nr of ["1", "2", "3"]) {
        if (!erwartet.includes(nr) && !a.s.punkte.includes("probe" + nr + ":0.3")) {
          sagt("ziffer " + z, "Punkt " + nr + " steht im Sprecherfenster nicht blass zur Auswahl: " + a.s.punkte);
        }
      }
      if (a.h.fehler.length || a.s.fehler.length) {
        sagt("ziffer " + z, "Laufzeitfehler: " + JSON.stringify([a.h.fehler, a.s.fehler]));
      }
      console.log("Ziffer " + z + ": Halle S" + a.h.auf + " [" + a.h.punkte
        + "] · Sprecher S" + a.s.auf);
    }
    // Und der Pfeil nimmt den naechsten *ungenannten*, nicht den naechsten der
    // Zaehlung. Nach den Ziffern 2 und 1 ist das die 3 -- eine Prueffolge, die
    // eine Verwechslung von "offen" mit "der naechste" sofort zeigt.
    await sprecher.taste("ArrowRight");
    await schlaf(900);
    const nach = await beide();
    if (!nach.h.punkte.includes("probe1:1.0")) {
      sagt("pfeil", "der Pfeil nahm nicht den naechsten offenen Punkt (1): " + nach.h.punkte);
    }
    if (nach.h.punkte.includes("probe2:1.0")) {
      sagt("pfeil", "der Pfeil nahm den naechsten der Zaehlung (2) statt den naechsten offenen (1)");
    }
    if (nach.h.schritt !== nach.s.schritt) {
      sagt("pfeil", "Halle steht auf Schritt " + nach.h.schritt + ", Sprecher auf " + nach.s.schritt);
    }
    // Und das frueher Genannte steht in beiden Fenstern noch. Das ist die
    // Pruefung, an der der zweite der drei Fehler haengt: ein genannter Punkt
    // verschwand, sobald der naechste kam, und zwar nur in der
    // Sprecheransicht. Ohne einen zweiten Aufdeckvorgang mit Blick zurueck
    // bleibt er unsichtbar.
    for (const nr of ["1", "3"]) {
      if (!nach.h.punkte.includes("probe" + nr + ":1.0")) {
        sagt("pfeil", "Punkt " + nr + " ging in der Halle wieder verloren: " + nach.h.punkte);
      }
      if (!nach.s.punkte.includes("probe" + nr + ":1.0")) {
        sagt("pfeil", "Punkt " + nr + " ging im Sprecherfenster wieder verloren: " + nach.s.punkte);
      }
    }
    console.log("Pfeil: Halle S" + nach.h.auf + " [" + nach.h.punkte + "] · Sprecher S" + nach.s.auf);

    await sprecher.ende();
  } catch (e) {
    sagt("lauf", e.message);
  } finally {
    await halle.ende();
  }
  console.log("\nZwei Fenster: " + (maengel.length ? maengel.length + " Abweichungen" : "ohne Abweichung"));
  process.exit(maengel.length ? 1 : 0);
})();
