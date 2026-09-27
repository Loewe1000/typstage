// pruefe-morph-pin.js — reist, was einen Namen trägt?
//
// Ein `pin` ist die ausdrückliche Ansage, dass zwei Stücke zweier Folien
// dasselbe sind. Zwei Meldungen aus der Sammlung zeigten, dass die Laufzeit
// diese Ansage auf zwei Weisen verlor (Issues #17 und #18):
//
//   1. Über einer Grenze von damals 48 Zeichen legte `match: "auto"` die
//      Formel als Block um, und damit sprang ein benanntes Stück ohne Flug an
//      seinen neuen Platz. Gemeldet an einer Formel mit 50 und 49 Zeichen --
//      eine Zutat weniger, und derselbe Flug war richtig.
//   2. Ein `pin` um mehrere Zeichen zerfiel unterwegs. `pin` markiert seinen
//      Inhalt mit einem unsichtbaren Rechteck, und dieses Rechteck ist bei
//      Mathematik kleiner als das Gezeichnete: bei `$sum_(i=1)^n$` 21.9
//      Punkte hoch gegen über 49 Punkte Tinte. Von fünf Zeichen lagen zwei
//      darin, die anderen drei suchten sich ihren Partner über die Form.
//
//   node .github/scripts/pruefe-morph-pin.js [--browser /pfad] [--laut]
//
// Geprüft wird, je an einem eigenen kleinen Deck und im Browser, weil keine
// dieser Fragen an einer Datei zu beantworten ist:
//   1. Ein `pin` um `sum_(i=1)^n` fasst alle fünf Zeichen -- die Zugehörigkeit
//      kommt aus dem Baum und nicht aus der Geometrie.
//   2. Die Gruppe reist als ein Stück: alle ihre Geister fliegen denselben Weg.
//   3. Eine Formel über der Grenze fliegt nicht mehr Zeichen für Zeichen, aber
//      die benannten Stücke reisen (`nurPins`), der Rest wechselt an Ort und
//      Stelle.
//   4. Ohne Namen bleibt es über der Grenze beim Block.
//   5. `presentation(morph: (glyph-limit: …))` verschiebt die Grenze.
//   6. Die Vorgabe steht bei 120: 119 Zeichen fliegen einzeln, 121 nicht.
//
// Jede dieser sechs Behebungen einzeln zurückgenommen lässt die Probe klagen;
// die Mutationen stehen im CHANGELOG unter 0.1.3.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const LAUT = process.argv.indexOf("--laut") > 0;

const KOPF = `#import "@preview/typstage:0.1.3": *\n`;

// Eine Formel aus genau `n` Zeichen: `n` einzelne Buchstaben. Gezählt wird,
// was die Laufzeit zählt -- ein `<use>` je Zeichen --, und ein Buchstabe ist
// genau eines. Ein `+` dazwischen wäre ein weiteres und die Länge nicht mehr
// im Kopf auszurechnen.
const ABC = "abcdefghijklmnopqrstuvwxyz";
function kette(n, umgedreht) {
  const g = [];
  for (let i = 0; i < n; i++) g.push(ABC[i % 26]);
  if (umgedreht) g.reverse();
  return g.join(" ");
}

const DECKS = {
  // Die Meldung aus #18, auf das Nötige gekürzt: dieselbe Summe, einmal
  // vorn und einmal als Nenner.
  gruppe: KOPF + `#show: presentation.with(title: [Gruppe])

== Vorn
#morph(<m>)[$ x = #pin(<s>, $sum_(i=1)^n$) a_i $]

== Als Nenner
#morph(<m>)[$ x = a_i / #pin(<s>, $sum_(i=1)^n$) $]
`,
  // Über der Grenze, mit Namen und ohne.
  lang: KOPF + `#show: presentation.with(title: [Lang])

== Mit Namen
#morph(<m>)[$ #pin(<s>, $sum_(i=1)^n$) + ${kette(130)} $]

== Mit Namen (Fortsetzung)
#morph(<m>)[$ ${kette(130, true)} + #pin(<s>, $sum_(i=1)^n$) $]

== Ohne Namen
#morph(<o>)[$ sum_(i=1)^n + ${kette(130)} $]

== Ohne Namen (Fortsetzung)
#morph(<o>)[$ ${kette(130, true)} + sum_(i=1)^n $]
`,
  // Dasselbe Deck mit eigener Grenze.
  weit: KOPF + `#show: presentation.with(title: [Weit], morph: (glyph-limit: 400))

== Mit Namen
#morph(<m>)[$ #pin(<s>, $sum_(i=1)^n$) + ${kette(130)} $]

== Mit Namen (Fortsetzung)
#morph(<m>)[$ ${kette(130, true)} + #pin(<s>, $sum_(i=1)^n$) $]
`,
  // Die Vorgabe selbst: knapp darunter und knapp darüber, ohne Namen.
  rand: KOPF + `#show: presentation.with(title: [Rand])

== Knapp darunter
#morph(<u>)[$ ${kette(119)} $]

== Knapp darunter (Fortsetzung)
#morph(<u>)[$ ${kette(119, true)} $]

== Knapp darüber
#morph(<o>)[$ ${kette(121)} $]

== Knapp darüber (Fortsetzung)
#morph(<o>)[$ ${kette(121, true)} $]
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

// Was nach einem Schritt zu sehen ist: der Bericht der Laufzeit über den
// letzten Flug, und die Wege der Geister je Name.
const LAGE = `JSON.stringify((function () {
  var f = typstage.pruef.flug();
  var wege = {};
  document.querySelectorAll("#ts-fly [data-pin]").forEach(function (g) {
    var a = g.getAnimations ? g.getAnimations() : [];
    for (var i = 0; i < a.length; i++) {
      var k = a[i].effect && a[i].effect.getKeyframes ? a[i].effect.getKeyframes() : [];
      var t = k.length ? k[k.length - 1].transform : null;
      if (!t || t.indexOf("translate") < 0) continue;
      // Je Name ZWEI Listen: die abtretenden Kopien und die ankommenden.
      // Sie gehen entgegengesetzte Wege (die eine hinaus, die andere von
      // klein herauf, damit sie in ihrer Endgroesse gerastert wird), und
      // zusammengeworfen saehe das aus wie eine zerfallende Gruppe.
      var k2 = g.dataset.pin + (g.dataset.ziel ? "/ziel" : "");
      (wege[k2] = wege[k2] || []).push(t);
      break;
    }
  });
  return { flug: f, wege: wege, fehler: typstage.pruef.fehler() };
})())`;

(async () => {
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-mp-"));
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
    console.log("Morph-Pin: ein Probedeck übersetzt nicht\n  " +
                String(e.stderr || e.message).split("\n").slice(0, 4).join("\n  "));
    fs.rmSync(ordner, { recursive: true, force: true });
    process.exit(1);
  }

  const klagen = [];
  const b = await starte(CHROME);
  try {
    await b.ruf("Emulation.setDeviceMetricsOverride",
                { width: 1600, height: 900, deviceScaleFactor: 1, mobile: false });

    // Vorwärts, bis geflogen wird, und mitten im Flug nachsehen: die Wege
    // stehen nur, solange die Geister fliegen. Ein Flug dauert 900 ms, 150 ms
    // nach dem Druck steht alles. Geblättert wird mehrmals, weil zwischen
    // Titelfolie und dem ersten Paar Schritte ohne Flug liegen.
    async function schritt(datei, max) {
      if (datei) { await b.navigiere("file://" + datei); await schlaf(1600); }
      let leer = { flug: [], wege: {}, fehler: [] };
      for (let i = 0; i < (max || 4); i++) {
        await b.taste("ArrowRight");
        await schlaf(150);
        const s = JSON.parse(await b.ev(LAGE));
        await schlaf(1100);
        if (s.flug && s.flug.length) return s;
        leer = s;
      }
      return leer;
    }

    // ── 1 und 2: die Gruppe ────────────────────────────────────────────────
    let s = await schritt(weg.gruppe);
    let f = (s.flug || [])[0];
    if (!f) {
      klagen.push("1. auf der zweiten Folie flog nichts -- kein Bericht der Laufzeit");
    } else {
      const gr = (f.gruppen || [])[0];
      if (!gr || gr.glyphen !== 5) {
        klagen.push("1. der `pin` um $sum_(i=1)^n$ fasst " +
                    (gr ? gr.glyphen : 0) + " statt 5 Zeichen -- die drei "
                    + "Grenzen stehen außerhalb seines Rechtecks und gelten "
                    + "als ungepinnt (Issue #18)");
      }
      const beide = [s.wege[String(gr && gr.pin)] || [],
                     s.wege[String(gr && gr.pin) + "/ziel"] || []];
      const wege = beide[0];
      // Verglichen wird mit einem Pixel Toleranz und nicht auf das Zeichen
      // genau: eine Gruppe, die beim Reisen ein wenig kleiner wird, verschiebt
      // jedes ihrer Zeichen um seinen Anteil an dieser Stauchung. Das sind
      // Bruchteile eines Pixels. Ein Zerfallen sind Dutzende.
      beide.forEach((liste, richtung) => {
        const wohin = richtung ? "ankommend" : "abtretend";
        const zahlen = liste.map(t => (t.match(/-?[\d.]+/g) || []).map(Number));
        const spanne = (i) => zahlen.length
          ? Math.max(...zahlen.map(z => z[i] || 0)) - Math.min(...zahlen.map(z => z[i] || 0))
          : 0;
        if (liste.length < 5) {
          klagen.push("2. nur " + liste.length + " " + wohin + "e Geister "
                      + "trugen den Namen der Gruppe, erwartet sind 5");
        } else if (spanne(0) > 1 || spanne(1) > 1) {
          klagen.push("2. die Gruppe zerfällt unterwegs (" + wohin + "): die "
                      + "Wege ihrer Zeichen gehen um " + spanne(0).toFixed(1)
                      + " px waagrecht und " + spanne(1).toFixed(1)
                      + " px senkrecht auseinander ("
                      + liste.slice(0, 3).join(" | ") + ")");
        }
      });
    }

    // ── 3 und 4: über der Grenze ──────────────────────────────────────────
    s = await schritt(weg.lang);
    f = (s.flug || [])[0];
    if (!f) {
      klagen.push("3. die lange Formel mit Namen flog gar nicht");
    } else {
      if (!(f.glyphen[0] > f.grenze)) {
        klagen.push("3. das Probedeck liegt mit " + f.glyphen.join("/") +
                    " Zeichen nicht über der Grenze " + f.grenze);
      }
      if (!f.jeGlyphe || !f.nurPins) {
        klagen.push("3. über der Grenze reiste das benannte Stück nicht: " +
                    "jeGlyphe=" + f.jeGlyphe + ", nurPins=" + f.nurPins +
                    " (Issue #17)");
      }
      const gr = (f.gruppen || [])[0];
      if (!gr || gr.glyphen !== 5 || f.gepaart !== 5) {
        klagen.push("3. über der Grenze wurden " + f.gepaart + " Zeichen "
                    + "gepaart, erwartet sind die 5 der Gruppe");
      }
    }
    s = await schritt(null, 4);
    f = (s.flug || [])[0];
    if (!f) {
      klagen.push("4. die lange Formel ohne Namen flog gar nicht");
    } else if (f.jeGlyphe) {
      klagen.push("4. ohne Namen flog die lange Formel Zeichen für Zeichen " +
                  "(" + f.glyphen.join("/") + " über Grenze " + f.grenze +
                  ") -- über der Grenze gehört sie als Block umgelegt");
    }

    // ── 5: die Grenze ist einstellbar ─────────────────────────────────────
    s = await schritt(weg.weit);
    f = (s.flug || [])[0];
    if (!f || f.grenze !== 400) {
      klagen.push("5. `morph: (glyph-limit: 400)` kam nicht an (Grenze " +
                  (f ? f.grenze : "keine") + ")");
    } else if (f.nurPins || f.gepaart < f.glyphen[0] - 2) {
      klagen.push("5. mit der eigenen Grenze flog die Formel nicht ganz: " +
                  f.gepaart + " von " + f.glyphen[0] + " Zeichen gepaart");
    }

    // ── 6: die Vorgabe steht bei 120 ──────────────────────────────────────
    s = await schritt(weg.rand);
    f = (s.flug || [])[0];
    if (!f || f.grenze !== 120) {
      klagen.push("6. die Vorgabe der Grenze ist " + (f ? f.grenze : "keine") +
                  " statt 120");
    } else if (f.glyphen[0] > 120 || !f.jeGlyphe) {
      klagen.push("6. knapp unter der Grenze (" + f.glyphen.join("/") +
                  ") flog die Formel nicht Zeichen für Zeichen");
    }
    s = await schritt(null, 4);
    f = (s.flug || [])[0];
    if (!f) {
      klagen.push("6. das Paar knapp über der Grenze flog gar nicht");
    } else if (f.glyphen[0] <= 120) {
      klagen.push("6. das Paar knapp über der Grenze hat nur " +
                  f.glyphen.join("/") + " Zeichen -- das Probedeck trägt nicht");
    } else if (f.jeGlyphe) {
      klagen.push("6. knapp über der Grenze (" + f.glyphen.join("/") +
                  ") flog die Formel ohne Namen Zeichen für Zeichen");
    }

    if (LAUT) {
      for (const name of Object.keys(DECKS)) console.log("  " + name + ": " + weg[name]);
    }
    const fehler = (s.fehler || []).length;
    if (fehler) klagen.push("die Laufzeit meldete " + fehler + " Fehler");
  } finally {
    await b.ende();
    fs.rmSync(ordner, { recursive: true, force: true });
  }

  if (klagen.length) {
    console.log("Morph-Pin: " + klagen.length + " Beanstandung(en)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Morph-Pin: ein Name reist, als Gruppe und über der Grenze " +
              "(4 Decks, 6 Punkte)");
})();
