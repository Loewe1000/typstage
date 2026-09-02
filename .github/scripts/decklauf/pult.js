// =============================================================================
// pult.js — was die Sprecheransicht im Browser wirklich tut
// =============================================================================
// Warum eigens: der große Prüflauf zählt Knoten und misst Deckkraft. Vier
// Sorten Fehler kommen dort nicht vor, und alle vier sind in der letzten
// Runde gefunden worden -- von einem Menschen, nicht von einer Prüfung:
//
//   1. Etwas ragt aus dem Fenster. `#ts-speaker` schneidet ab, also gibt es
//      keinen Rollbalken und keinen Fehler -- nur ein halbes Bild. Gemessen
//      lief die Vorschau bei 700x900 um 93 Pixel hinaus.
//   2. Die vier Zahlen standen nicht auf einer Grundlinie: 20 Pixel
//      auseinander in Ruhe, 49 mit gesetzter Zieldauer, und eine davon sprang
//      im selben Augenblick um 46 Pixel.
//   3. Eine Regel greift nicht. `font: 600 11px/1 inherit` ist ungültig --
//      der Browser wirft die ganze Deklaration weg, und der einzige Schalter
//      der Ansicht stand in Arial 13,33 px. Im Stilblatt sieht so etwas aus
//      wie eine Regel, die greift.
//   4. Ein Auswahlzustand ist unsichtbar. Der Ring um den gewählten Stift
//      trug die Satzfarbe, und die vierte Stiftfarbe *ist* die Satzfarbe:
//      Kontrast 1,00. Und der eigene Umriss der Tupfen überschrieb den
//      Fokusring des Browsers -- vier Knöpfe ohne sichtbaren Tastaturfokus.
//
// Alles doppelt, in beiden Erscheinungsbildern: die hellen Bildschirmfotos
// wurden bisher erzeugt und von niemandem gelesen.
//
//   node .github/scripts/decklauf/pult.js [--browser /pfad]
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

function deckBauen() {
  const pp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pult-"));
  const ziel = path.join(pp, "schule", "typstage");
  fs.mkdirSync(ziel, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.1"), "dir");
  // Und unter `preview`, wie das Paket nach der Einreichung heisst.
  const ziel2 = path.join(pp, "preview", "typstage");
  fs.mkdirSync(ziel2, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel2, "0.1.1"), "dir");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pult-h-")), "pruefdeck.html");
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--root", WURZEL, "--package-path", pp,
    path.join(__dirname, "pruefdeck.typ"), aus], { stdio: ["ignore", "ignore", "pipe"] });
  return aus;
}

// ── Alles, was im Fenster gemessen wird, in einem Stück ─────────────────────
const HILFE = `
  window.__pult = {
    zahl: function (s) { return parseFloat(s) || 0; },
    farbe: function (s) {
      var m = /rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?\\)/.exec(s || "");
      if (!m) return null;
      return { r: +m[1], g: +m[2], b: +m[3], a: m[4] === undefined ? 1 : +m[4] };
    },
    leuchte: function (c) {
      var f = function (v) { v /= 255;
        return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
      return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    },
    kontrast: function (a, b) {
      if (!a || !b) return 0;
      var x = window.__pult.leuchte(a), y = window.__pult.leuchte(b);
      return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }
  };`;

const HINAUS = `(() => {
  const raus = [];
  document.querySelectorAll('#ts-speaker, #ts-speaker *').forEach(e => {
    const b = e.getBoundingClientRect();
    if (!b.width || !b.height) return;
    if (b.right > innerWidth + 1 || b.bottom > innerHeight + 1 ||
        b.left < -1 || b.top < -1) {
      raus.push((typeof e.className === 'string' && e.className ? e.className : e.tagName)
        + ' +' + Math.round(Math.max(b.right - innerWidth, b.bottom - innerHeight,
                                     -b.left, -b.top)));
    }
  });
  return JSON.stringify([...new Set(raus)]);
})()`;

// Was aus seiner *Kachel* ragt. Das Fenster allein reicht als Grenze
// nicht: eine Kachel schneidet mit `overflow:hidden` ab, und was sie
// abschneidet, steht immer noch innerhalb des Fensters -- gemessen ragten
// die vier Farbfelder 51 px aus einer 102 px schmalen Werkzeugkachel, und
// zwei davon waren gar nicht mehr zu sehen. Genau deshalb ist der Fall
// durch diesen Lauf gerutscht.
const AUS_KACHEL = `(() => {
  const raus = [];
  document.querySelectorAll('#ts-speaker .ts-sp-kachel').forEach(k => {
    const kb = k.getBoundingClientRect();
    if (!kb.width || !kb.height) return;
    const name = (String(k.className).match(/ts-sp-[a-z]+/g) || []).join('.');
    k.querySelectorAll('*').forEach(e => {
      const b = e.getBoundingClientRect();
      if (!b.width || !b.height) return;
      const d = Math.max(b.right - kb.right, kb.left - b.left,
                         b.bottom - kb.bottom, kb.top - b.top);
      if (d > 1) {
        const wer = (String(e.className).match(/ts-sp-[a-z-]+/) || [e.tagName])[0];
        raus.push(name + ' < ' + wer + ' +' + Math.round(d));
      }
    });
  });
  return JSON.stringify([...new Set(raus)]);
})()`;

const GRUNDLINIE = `(() => {
  const sicht = e => e && getComputedStyle(e).display !== 'none';
  const f = [...document.querySelectorAll('.ts-sp-uhren > .ts-sp-kachel')].map(k => {
    const z = [...k.querySelectorAll('.ts-sp-gross,.ts-sp-ziel,.ts-sp-uhrfeld')]
                .filter(sicht)[0];
    return z ? Math.round(z.getBoundingClientRect().bottom * 10) / 10 : null;
  }).filter(x => x !== null);
  return JSON.stringify({ n: f.length, spanne: f.length ? Math.max(...f) - Math.min(...f) : 0, f });
})()`;

// Greift eine Regel wirklich? Verglichen wird gegen das, was danebensteht --
// die Marke einer Kachel ist der Massstab, den das Stilblatt selbst setzt.
const REGELN = `(() => {
  const cs = s => { const e = document.querySelector(s); return e ? getComputedStyle(e) : null; };
  const marke = cs('.ts-sp-marke'), modus = cs('.ts-sp-wz');
  if (!marke || !modus) return JSON.stringify({fehlt: true});
  return JSON.stringify({
    markeFam: marke.fontFamily, modusFam: modus.fontFamily,
    modusGroesse: modus.fontSize, modusGewicht: modus.fontWeight,
    schema: getComputedStyle(document.documentElement).colorScheme
  });
})()`;

const AUSWAHL = `(() => {
  const P = window.__pult;
  const t = [...document.querySelectorAll('.ts-sp-tupf')];
  const grund = P.farbe(getComputedStyle(document.querySelector('.ts-sp-fuss')
    || document.body).backgroundColor)
    || P.farbe(getComputedStyle(document.getElementById('ts-speaker')).backgroundColor);
  return JSON.stringify(t.map((e, i) => {
    const c = getComputedStyle(e);
    const sch = c.boxShadow || '';
    // Die Farben des Schattens in der Reihenfolge, in der sie gemalt werden.
    const farben = (sch.match(/rgba?\\([^)]*\\)|color\\([^)]*\\)/g) || []);
    return {
      an: e.dataset.an === '1',
      tupf: c.backgroundColor,
      ringe: farben.length,
      kanteZuTupf: P.kontrast(P.farbe(farben[0]), P.farbe(c.backgroundColor)),
      kanteZuGrund: P.kontrast(P.farbe(farben[0]), grund),
      tupfZuGrund: P.kontrast(P.farbe(c.backgroundColor), grund),
      spaltZuRing: farben.length >= 3
        ? P.kontrast(P.farbe(farben[1]), P.farbe(farben[2])) : 0
    };
  }));
})()`;

const FOKUS = `(() => {
  const wen = ['.ts-sp-tupf', '.ts-sp-wz', '.ts-sp-tat', '.ts-sp-ziel', '.ts-sp-uhrfeld'];
  const aus = {};
  wen.forEach(s => {
    const e = document.querySelector(s);
    if (!e || getComputedStyle(e).display === 'none') { aus[s] = null; return; }
    e.focus();
    const c = getComputedStyle(e);
    aus[s] = { breite: parseFloat(c.outlineWidth) || 0, art: c.outlineStyle,
               farbe: c.outlineColor };
    e.blur();
  });
  return JSON.stringify(aus);
})()`;

(async () => {
  const datei = deckBauen();
  const c = await starte(arg("--browser", browserSuchen()));
  let maengel = [];
  const sagt = (b, s) => { console.error("ABWEICHUNG " + b + ": " + s); maengel.push(s); };
  const GROESSEN = [[1600, 900], [1920, 1080], [1280, 800], [1100, 700],
                    [900, 600], [1440, 500], [800, 1000], [700, 900], [640, 480]];

  try {
    for (const licht of ["dark", "light"]) {
      await c.ruf("Emulation.setEmulatedMedia",
        { features: [{ name: "prefers-color-scheme", value: licht }] });
      const bild = licht === "dark" ? "dunkel" : "hell";
      // Dunkel ist die Vorgabe, ohne das System zu fragen -- ein Pult steht
      // im abgedunkelten Raum. Das helle Bild kommt deshalb nicht mehr von
      // `prefers-color-scheme`, sondern von `l`, und dieser Lauf muss es
      // genauso holen wie ein Mensch. Vorher prueften beide Durchgaenge
      // dasselbe dunkle Bild, und die Haelfte des Laufs war blind.
      // Gestellt, nicht umgeschaltet: `ts-licht` haelt die Sitzung und
      // ueberlebt ein Neuladen. Ein blindes `l` je Seite kippte deshalb ab
      // der zweiten Groesse wieder ins Dunkle zurueck, und der helle
      // Durchgang mass abwechselnd beides.
      const hellStellen = async () => {
        for (let i = 0; i < 3; i++) {
          const ist = await c.ev("document.documentElement.dataset.tsLicht");
          if (ist === (licht === "light" ? "hell" : "dunkel")) return;
          await c.taste("l");
          await schlaf(400);
        }
      };

      // ── 1 Nichts ragt hinaus, in neun Groessen ────────────────────────────
      for (const [w, h] of GROESSEN) {
        await c.ruf("Emulation.setDeviceMetricsOverride",
          { width: w, height: h, deviceScaleFactor: 1, mobile: false });
        await c.navigiere("file://" + datei + "#speaker");
        await schlaf(1100);
        await hellStellen();
        const raus = JSON.parse(await c.ev(HINAUS));
        if (raus.length) {
          sagt("hinaus", bild + " bei " + w + "x" + h + " steht etwas ausserhalb des "
            + "Fensters: " + raus.join(", ") + ". `#ts-speaker` schneidet ab, es "
            + "gibt also weder Rollbalken noch Fehler -- nur ein halbes Bild.");
        }
        const ausK = JSON.parse(await c.ev(AUS_KACHEL));
        if (ausK.length) {
          sagt("kachel", bild + " bei " + w + "x" + h + " ragt etwas aus seiner "
            + "Kachel: " + ausK.join(", ") + ". Die Kachel schneidet es ab; im "
            + "Fenster steht es damit immer noch, zu sehen ist es nicht mehr.");
        }
      }

      // ── 2 Eine Grundlinie, in Ruhe und mit Zieldauer ─────────────────────
      await c.ruf("Emulation.setDeviceMetricsOverride",
        { width: 1600, height: 900, deviceScaleFactor: 1, mobile: false });
      await c.navigiere("file://" + datei + "#speaker");
      await schlaf(1400);
      await hellStellen();
      await c.ev(HILFE);
      for (const [was, vorher] of [["in Ruhe", null], ["mit Zieldauer", "d"]]) {
        if (vorher) {
          await c.taste(vorher); await schlaf(250);
          await c.ev("var z=document.querySelector('.ts-sp-ziel'); z.value='45';"
            + "z.dispatchEvent(new Event('input',{bubbles:true}));"
            + "z.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));");
          await schlaf(600);
        }
        const g = JSON.parse(await c.ev(GRUNDLINIE));
        if (g.n !== 4) {
          sagt("grundlinie", bild + ": " + g.n + " Zahlkacheln statt vier gefunden. "
            + "Ohne die vier prueft dieser Lauf nichts.");
        } else if (g.spanne > 1) {
          sagt("grundlinie", bild + " " + was + ": die vier Zahlen stehen "
            + g.spanne.toFixed(1) + " px auseinander (" + g.f.join(" ") + "). "
            + "Eine Zeile, deren Argument vier gleiche Kacheln sind, haelt eine "
            + "gemeinsame Grundlinie.");
        }
      }

      // ── 3 Greifen die Regeln, die im Stilblatt stehen ────────────────────
      const r = JSON.parse(await c.ev(REGELN));
      if (r.fehlt) sagt("regel", bild + ": Marke oder Schalter fehlen.");
      else {
        if (r.markeFam !== r.modusFam) {
          sagt("regel", bild + ": der Schalter steht in " + r.modusFam
            + ", die Marke daneben in " + r.markeFam + ". Eine Regel, die der "
            + "Browser stillschweigend wegwirft, sieht im Stilblatt aus wie eine, "
            + "die greift.");
        }
        if (r.modusGroesse !== "11px" || r.modusGewicht !== "600") {
          sagt("regel", bild + ": der Schalter misst " + r.modusGroesse + "/"
            + r.modusGewicht + " statt 11px/600.");
        }
        const willSchema = licht === "dark" ? "dark" : "light";
        if (r.schema !== willSchema) {
          sagt("regel", bild + ": `color-scheme` steht auf " + r.schema + " statt "
            + willSchema + ". Ohne sie malt der Browser sein Drehrad in seiner "
            + "eigenen Farbe auf die Kachel.");
        }
      }

      // ── 4 Auswahl und Fokus ─────────────────────────────────────────────
      for (let i = 0; i < 5; i++) {
        const t = JSON.parse(await c.ev(AUSWAHL));
        const gewaehlt = t.filter(x => x.an);
        if (gewaehlt.length !== 1) {
          sagt("auswahl", bild + ": " + gewaehlt.length + " Stifte gelten als gewaehlt.");
          break;
        }
        const g = gewaehlt[0];
        if (g.ringe < 3 || g.spaltZuRing < 3) {
          sagt("auswahl", bild + ": der gewaehlte Stift (" + g.tupf + ") traegt "
            + "keinen erkennbaren Ring -- Spalt gegen Ring " + g.spaltZuRing.toFixed(2)
            + ", verlangt sind 3,0. Die Auswahl haengt sonst daran, dass die "
            + "Ringfarbe zufaellig nicht die Stiftfarbe ist.");
        }
        // Und jeder Tupfen muss ueberhaupt als Scheibe zu sehen sein.
        t.forEach((x, k) => {
          if (Math.max(x.tupfZuGrund, x.kanteZuTupf) < 3) {
            sagt("auswahl", bild + ": Stift " + (k + 1) + " (" + x.tupf + ") steht mit "
              + x.tupfZuGrund.toFixed(2) + " auf dem Grund und traegt eine Kante von "
              + x.kanteZuTupf.toFixed(2) + ". Keins von beidem reicht.");
          }
        });
        if (i < 4) { await c.taste("c"); await schlaf(200); }
      }
      const f = JSON.parse(await c.ev(FOKUS));
      for (const s of Object.keys(f)) {
        if (!f[s]) continue;
        if (f[s].art === "none" || f[s].breite < 2) {
          sagt("fokus", bild + ": " + s + " zeigt beim Tastaturfokus " + f[s].breite
            + "px " + f[s].art + ". WCAG 2.2 will mindestens zwei Pixel, und am Pult "
            + "will man wissen, ob die Tastatur schon im Feld ist.");
        }
      }
    }
  } catch (e) {
    sagt("lauf", e.message);
  } finally {
    await c.ende();
  }
  console.log("\nPult: " + (maengel.length ? maengel.length + " Abweichungen" : "ohne Abweichung"));
  process.exit(maengel.length ? 1 : 0);
})();
