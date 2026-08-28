// =============================================================================
// sprung.js — was ein Sprung mitten in einem Übergang hinterlässt
// =============================================================================
// Warum eigens: der große Prüflauf misst Decks im *Ruhezustand*, und
// `flug-hoehe.js` misst, was während eines Fluges übereinander liegt. Beide
// sehen nicht, was ein Sprung tut, der mitten in eine laufende Bewegung fällt
// -- und genau dort saß der Fehler, der das hier ausgelöst hat:
//
//   `finishTransitionNow()` -- die eine Stelle, die laufende Folienanimationen
//   abbricht -- hing allein an `fly()`, und `fly` läuft bei einem `instant`
//   nicht. Pos1, Ende, ein Wechsel der Adresse und Vor/Zurück im Browser gingen
//   daran vorbei. Die alte Animation lief mit `fill: "both"` weiter, und sie
//   traf unter Umständen genau die Folie, auf die gesprungen wurde.
//
//   Nachgestellt, 300 ms nach einem Pos1 mitten in einem Übergang: die
//   Zielfolie stand bei `translateX(-13.8px)` und 0,70 Deckkraft, die alte lag
//   mit 0,30 darüber, beide noch in Bewegung. Erst als der Zeitgeber des alten
//   Übergangs ablief, sprang es an seinen Platz. Bei der Vorgabe von 420 ms
//   wäre das eine halbe Sekunde nach jedem Pos1.
//
// Gemessen wird *im* Fenster, also zwischen dem Sprung und dem Ablauf des alten
// Zeitgebers. Eine Messung danach sieht nichts: dann hat der alte Zeitgeber
// selbst aufgeräumt, und das war die erste Fassung dieser Probe, die deshalb
// stumm durchging.
//
//   node .github/scripts/decklauf/sprung.js [--browser PFAD]
//
// Rückgabewert 0, wenn alles hält, sonst 1.
// =============================================================================
const fs = require("fs"), os = require("os"), path = require("path");
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

function deckBauen() {
  const pp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-sp-"));
  const ziel = path.join(pp, "schule", "typstage");
  fs.mkdirSync(ziel, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.0"), "dir");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-sp-h-")), "sprungdeck.html");
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--root", WURZEL, "--package-path", pp,
    path.join(__dirname, "sprungdeck.typ"), aus], { stdio: ["ignore", "ignore", "pipe"] });
  return aus;
}

// Jede Folie mit dem, was man ihr ansieht. `transform` und `opacity` gerechnet,
// nicht als Inline-Stil: eine Web Animation mit `fill: "both"` steht in keinem
// `style`-Attribut, und genau die war das Problem.
const STAND = `(() => {
  const fs = [...document.querySelectorAll('.ts-slide')];
  return JSON.stringify(fs.map((f, i) => ({
    i,
    an: f.dataset.on === "1",
    tf: getComputedStyle(f).transform,
    op: +getComputedStyle(f).opacity,
    anim: f.getAnimations().length
  })));
})()`;

const ruht = f => (f.tf === "none" || f.tf === "matrix(1, 0, 0, 1, 0, 0)");

(async () => {
  const maengel = [];
  const sagt = (wo, was) => { maengel.push(wo); console.error("ABWEICHUNG " + wo + ": " + was); };

  const datei = deckBauen();
  const c = await starte(arg("--browser", browserSuchen()));
  try {
    await c.navigiere("file://" + datei);
    await schlaf(1600);

    // Eine Geste, die springt, mitten in einen Übergang gelegt. Danach wird
    // gemessen, *bevor* der alte Zeitgeber ablaufen kann.
    const probe = async (name, taste) => {
      // Zurück auf Anfang und zur Ruhe kommen lassen.
      await c.taste("Home");
      await schlaf(2400);

      // Übergang starten und mittendrin springen.
      await c.taste("ArrowRight");
      await schlaf(250);
      await c.taste(taste);
      await schlaf(300);

      const r = JSON.parse(await c.ev(STAND));
      const ziel = r.find(f => f.an);
      if (!ziel) { sagt(name, "keine Folie ist an"); return; }
      if (!ruht(ziel))
        sagt(name, "die Zielfolie steht verschoben: " + ziel.tf);
      if (ziel.op < 0.999)
        sagt(name, "die Zielfolie ist durchsichtig: " + ziel.op);
      const fremd = r.filter(f => !f.an && f.op > 0.001);
      if (fremd.length)
        sagt(name, "eine fremde Folie ist noch sichtbar: Folie "
             + fremd.map(f => f.i + " bei " + f.op).join(", "));
      const laeuft = r.filter(f => f.anim > 0);
      if (laeuft.length)
        sagt(name, "es läuft noch etwas: Folie " + laeuft.map(f => f.i).join(", "));
    };

    await probe("Pos1 im Übergang", "Home");
    await probe("Ende im Übergang", "End");
  } catch (e) {
    if (!maengel.length) sagt("lauf", e.message);
  } finally {
    await c.ende();
  }
  console.log("\nSprung: " + (maengel.length ? maengel.length + " Abweichungen" : "ohne Abweichung"));
  process.exit(maengel.length ? 1 : 0);
})();
