// pruefe-leinwand.js — wächst die Folie mit ihrem Inhalt, und folgt die Ansicht?
//
// Zwei Rechtecke, wie in `animo`: Der Ausschnitt ist die Folie und schneidet
// ab; die Leinwand ist, worauf der Rumpf steht. Gewöhnlich sind beide gleich
// groß. Läuft der Fluss weiter nach unten oder steht ein `place` neben der
// Folie, wächst die Leinwand -- im Browser schwenkt die Bühne über sie, auf
// Papier kommt sie ganz auf die Seite, eingepasst und mit einer Randnotiz.
//
//   node .github/scripts/pruefe-leinwand.js [--browser /pfad] [--laut]
//
// Geprüft wird:
//   1. Eine gewöhnliche Folie wächst NICHT: Leinwand = Ausschnitt, und die
//      Bühne schwenkt nie. Ohne diese Frage wüchse jedes Deck ein wenig, und
//      keine Folie stünde mehr, wo sie stand. Auf ihr steht ein `place` mit
//      Anker (`bottom + right`), dessen Versatz nach innen zeigt.
//   2. Eine Rechnung, die nach unten weiterläuft: Die Leinwand ist höher als
//      der Ausschnitt, die ersten Schritte stehen ohne Schwenk da, und der
//      letzte ist zu sehen -- die Ansicht ist ihm gefolgt.
//   3. Ein `place` rechts neben der Folie: Die Leinwand ist breiter, und das
//      Stück steht wirklich außerhalb des Ausschnitts.
//   4. Auf Papier trägt die gewachsene Folie ihre Randnotiz (`<ts-canvas-note>`)
//      -- die gewöhnliche nicht. Damit hängt auch der Handzettel daran: er
//      setzt dieselbe Funktion.
//   5. Der Kopf der gewachsenen Folie steht: Er liegt als eigene Schicht über
//      der Leinwand, bleibt beim Schwenk an der Oberkante der Bühne und ist so
//      breit wie sie. Eine gewöhnliche Folie trägt diese Schicht gar nicht.
//   6. Zurückblättern fährt die Ansicht zurück. Die erste Fassung fuhr vom
//      zuletzt erreichten Stand aus weiter und nur so weit wie nötig: vorwärts
//      richtig, rückwärts gar nicht -- wer zurückblätterte, blieb unten
//      stehen. Verglichen wird Schritt für Schritt mit dem Hinweg.
//   7. Und ein Sprung mitten auf die Folie zeigt dasselbe wie das
//      Durchblättern dorthin: Der Ausschnitt hängt am Schritt und nicht am
//      Weg, den der Vortrag genommen hat.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
const LAUT = process.argv.indexOf("--laut") > 0;

const KOPF = `#import "@preview/typstage:0.2.0": *\n`;

const DECKS = {
  schmal: KOPF + `#show: presentation.with(title: [Schmal])

== Eine gewöhnliche Folie
Ein Satz, der in den Ausschnitt passt.
// Mit Anker: Die 20pt zählen von der rechten unteren Ecke des Rumpfes nach
// innen und nicht von der linken oberen nach außen. Ohne diese Rechnung
// bekäme die Folie hier eine Leinwand, die sie nicht braucht.
#place(bottom + right, dx: -20pt, dy: -20pt, rect(width: 60pt, height: 40pt))
`,
  lang: KOPF + `#show: presentation.with(title: [Lang])

== Eine Rechnung, Schritt für Schritt
#stagger(dim: true)[
  $ 3x + 5 = 20 $
][
  $ 3x = 15 $
][
  $ x = 5 $
][
  $ "Probe:" 3 dot 5 + 5 = 20 $
][
  $ 2y - 4 = 10 $
][
  $ 2y = 14 $
][
  $ y = 7 $
][
  $ x + y = 12 $
][
  $ 5 + 7 = 12 $
]
`,
  daneben: KOPF + `#show: presentation.with(title: [Daneben])

== Etwas rechts daneben
Der Text auf der Folie.
#place(dx: 780pt, dy: 20pt, rect(width: 180pt, height: 100pt, fill: orange)[Rechts])
`,
};

function typst(args) {
  return execFileSync("typst", args, { encoding: "utf8" });
}

function bauen(quelle, name, paket, ordner) {
  const typ = path.join(ordner, name + ".typ");
  fs.writeFileSync(typ, quelle);
  typst(["compile", "--format", "html", "--features", "html",
         "--package-path", paket, "--root", ordner,
         typ, path.join(ordner, name + ".html")]);
  return path.join(ordner, name + ".html");
}

// Wie groß die Leinwand einer Folie ist, in Vielfachen des Ausschnitts: Das
// SVG im Hintergrund trägt die Maße der Leinwand.
//
// Der Ausschnitt kommt von der Titelfolie: Sie hat keinen Rumpf, der wachsen
// könnte, also ist ihre Leinwand die Folie selbst. Das erspart der Probe eine
// eigene Oberfläche in der Laufzeit für eine Zahl, die ohnehin dasteht.
const MASS = `(function(){
  var st = typstage.pruef.stand();
  var f = document.querySelectorAll('.ts-slide')[st.folie];
  var svg = f.querySelector('.ts-bg svg');
  var vb = (svg.getAttribute('viewBox') || '').split(/\\s+/).map(Number);
  var erste = document.querySelector('.ts-slide .ts-bg svg');
  var ausschnitt = (erste.getAttribute('viewBox') || '').split(/\\s+/).map(Number);
  var buehne = document.getElementById('ts-stage').getBoundingClientRect();
  var ov = f.querySelector('.ts-ov');
  var kp = f.querySelector('.ts-kopf');
  var kr = kp ? kp.getBoundingClientRect() : null;
  return { schritt: st.schritt,
           breit: +(vb[2] / ausschnitt[2]).toFixed(3),
           hoch: +(vb[3] / ausschnitt[3]).toFixed(3),
           fahrt: ov.style.transform || '-',
           buehne: { oben: Math.round(buehne.top), unten: Math.round(buehne.bottom),
                     links: Math.round(buehne.left), rechts: Math.round(buehne.right) },
           kopf: kr ? { oben: Math.round(kr.top), unten: Math.round(kr.bottom),
                        breit: Math.round(kr.width) } : null };
})()`;

(async () => {
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-lw-"));
  const paket = path.join(ordner, "pk");
  for (const raum of ["preview", "schule"]) {
    const ziel = path.join(paket, raum, "typstage");
    fs.mkdirSync(ziel, { recursive: true });
    fs.symlinkSync(WURZEL, path.join(ziel, "0.2.0"));
  }
  const weg = {};
  const klagen = [];
  try {
    for (const name of Object.keys(DECKS)) weg[name] = bauen(DECKS[name], name, paket, ordner);
  } catch (e) {
    console.log("Leinwand: ein Probedeck übersetzt nicht\n  " +
                String(e.stderr || e.message).split("\n").slice(0, 4).join("\n  "));
    fs.rmSync(ordner, { recursive: true, force: true });
    process.exit(1);
  }

  // ── 4: Papier ────────────────────────────────────────────────────────────
  // Vor dem Browser, weil es ohne ihn auskommt: Die Randnotiz trägt eine
  // Marke, und `typst query` sagt, auf welcher Folie sie steht.
  for (const name of ["schmal", "lang", "daneben"]) {
    const treffer = JSON.parse(typst(["query", "--package-path", paket,
      "--root", ordner, path.join(ordner, name + ".typ"), "<ts-canvas-note>"]));
    const soll = name === "schmal" ? 0 : 1;
    if (treffer.length !== soll) {
      klagen.push("4. auf Papier trägt »" + name + "« " + treffer.length
                  + " Randnotiz(en), erwartet " + soll
                  + (soll ? " -- die gewachsene Folie muss sagen, dass sie geschwenkt wird"
                          : " -- eine Folie im Ausschnitt bekommt keine"));
    } else if (LAUT && soll) {
      console.log("  4. " + name + ": " + JSON.stringify(treffer[0]));
    }
  }

  const b = await starte(CHROME);
  try {
    await b.ruf("Emulation.setDeviceMetricsOverride",
                { width: 1600, height: 900, deviceScaleFactor: 1, mobile: false });

    // ── 1: eine gewöhnliche Folie wächst nicht ─────────────────────────────
    await b.navigiere("file://" + weg.schmal);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1200);
    const m1 = JSON.parse(await b.ev(`JSON.stringify(${MASS})`));
    if (LAUT) console.log("  1. " + JSON.stringify(m1));
    if (m1.breit !== 1 || m1.hoch !== 1) {
      klagen.push("1. die gewöhnliche Folie hat eine Leinwand von " + m1.breit
                  + " × " + m1.hoch + " Ausschnitten -- sie soll 1 × 1 sein");
    }
    if (m1.fahrt !== "-") {
      klagen.push("1. die gewöhnliche Folie steht geschwenkt da (" + m1.fahrt
                  + ") -- ohne Leinwand gibt es nichts zu schwenken");
    }
    if (m1.kopf) {
      klagen.push("5. die gewöhnliche Folie trägt eine Kopfschicht -- "
                  + "angeheftet wird nur, wo auch geschwenkt wird");
    }

    // ── 2: der Fluss läuft nach unten weiter ───────────────────────────────
    await b.navigiere("file://" + weg.lang);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1200);
    const bahn = [];
    for (let i = 0; i < 9; i++) {
      await b.taste("ArrowRight");
      await schlaf(700);
      bahn.push(JSON.parse(await b.ev(`JSON.stringify((function(){
        var m = ${MASS};
        var st = typstage.pruef.stand();
        var f = document.querySelectorAll('.ts-slide')[st.folie];
        var an = [].slice.call(f.querySelectorAll('.ts-el[data-on="1"]'));
        var letzte = an[an.length - 1];
        var r = letzte ? letzte.getBoundingClientRect() : null;
        m.sichtbar = r ? (r.top >= m.buehne.oben - 2 && r.bottom <= m.buehne.unten + 2) : null;
        m.unten = r ? Math.round(r.bottom) : null;
        return m;
      })())`)));
    }
    if (LAUT) bahn.forEach(m => console.log("  2. " + JSON.stringify(m)));
    const letzte = bahn[bahn.length - 1];
    if (letzte.hoch <= 1.05) {
      klagen.push("2. die Rechnung läuft über den Ausschnitt hinaus, aber die "
                  + "Leinwand ist nur " + letzte.hoch + " Ausschnitte hoch");
    }
    if (bahn[0].fahrt !== "-") {
      klagen.push("2. schon der erste Schritt steht geschwenkt da ("
                  + bahn[0].fahrt + ") -- geschwenkt wird erst, wenn es nötig ist");
    }
    if (letzte.fahrt === "-") {
      klagen.push("2. beim letzten Schritt ist die Ansicht nicht gefolgt: "
                  + "die Bühne steht noch am Anfang der Leinwand");
    }
    if (!letzte.kopf) {
      klagen.push("5. die gewachsene Folie trägt keine Kopfschicht -- der "
                  + "Titel führe mit der Leinwand aus dem Bild");
    } else if (letzte.kopf.oben !== letzte.buehne.oben
               || letzte.kopf.breit !== letzte.buehne.rechts - letzte.buehne.links) {
      klagen.push("5. der Kopf steht beim letzten Schritt bei "
                  + letzte.kopf.oben + " px und ist " + letzte.kopf.breit
                  + " px breit -- er soll an der Oberkante der Bühne stehen "
                  + "bleiben und so breit sein wie sie");
    }
    // ── 6: und wieder zurück ──────────────────────────────────────────────
    const rueck = [];
    for (let i = bahn.length - 2; i >= 0; i--) {
      await b.taste("ArrowLeft");
      await schlaf(700);
      rueck[i] = JSON.parse(await b.ev(`JSON.stringify(${MASS})`));
    }
    if (LAUT) rueck.forEach(m => m && console.log("  6. " + JSON.stringify(m)));
    const anders = bahn.map((m, i) => (rueck[i] && rueck[i].fahrt !== m.fahrt)
      ? ("Schritt " + m.schritt + ": hin " + m.fahrt + ", zurück " + rueck[i].fahrt)
      : null).filter(Boolean);
    if (anders.length) {
      klagen.push("6. auf dem Rückweg steht die Ansicht anders als auf dem "
                  + "Hinweg -- " + anders[0]
                  + (anders.length > 1 ? " (und " + (anders.length - 1) + " weitere)" : ""));
    }

    // ── 7: hergesprungen statt hingeblättert ──────────────────────────────
    const letzterSchritt = bahn[bahn.length - 1].schritt;
    await b.navigiere("about:blank");
    await schlaf(150);
    await b.navigiere("file://" + weg.lang + "#slide-2-" + letzterSchritt);
    await schlaf(1600);
    const sprung = JSON.parse(await b.ev(`JSON.stringify(${MASS})`));
    if (LAUT) console.log("  7. " + JSON.stringify(sprung));
    if (sprung.schritt !== letzterSchritt || sprung.fahrt !== letzte.fahrt) {
      klagen.push("7. der Sprung auf #slide-2-" + letzterSchritt + " steht auf "
                  + "Schritt " + sprung.schritt + " bei " + sprung.fahrt
                  + ", durchgeblättert steht dort Schritt " + letzterSchritt
                  + " bei " + letzte.fahrt);
    }

    const blind = bahn.filter(m => m.sichtbar === false);
    if (blind.length) {
      klagen.push("2. bei " + blind.length + " von " + bahn.length
                  + " Schritten stand der aufgedeckte Schritt außerhalb der "
                  + "Bühne (zuerst bei Schritt " + blind[0].schritt + ")");
    }

    // ── 3: ein `place` neben der Folie ─────────────────────────────────────
    await b.navigiere("file://" + weg.daneben);
    await schlaf(1600);
    await b.taste("ArrowRight");
    await schlaf(1200);
    const m3 = JSON.parse(await b.ev(`JSON.stringify(${MASS})`));
    if (LAUT) console.log("  3. " + JSON.stringify(m3));
    if (m3.breit <= 1.05) {
      klagen.push("3. das `place` steht rechts neben der Folie, aber die "
                  + "Leinwand ist nur " + m3.breit + " Ausschnitte breit");
    }
    if (m3.hoch !== 1) {
      klagen.push("3. die Leinwand ist auch nach unten gewachsen ("
                  + m3.hoch + ") -- das `place` steht nur rechts");
    }

    const fehler = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.fehler())`));
    if (fehler.length) klagen.push("die Laufzeit meldete " + fehler.length + " Fehler");
  } finally {
    await b.ende();
    fs.rmSync(ordner, { recursive: true, force: true });
  }

  if (klagen.length) {
    console.log("Leinwand: " + klagen.length + " Beanstandung(en)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Leinwand: die Folie wächst mit ihrem Inhalt, die Ansicht folgt, "
              + "der Kopf bleibt stehen, sie fährt zurück, und auf Papier kommt "
              + "sie ganz (3 Decks, 7 Punkte)");
})();
