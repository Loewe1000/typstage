// =============================================================================
// zwei-fenster.js — die Fernsteuerung, mit zwei echten Fenstern
// =============================================================================
// Warum eigens: der große Prüflauf lädt die Sprecheransicht über `#speaker` in
// *einem* Fenster. Damit lässt sich alles prüfen, was ein Fenster für sich
// tut -- aber nichts, was zwischen beiden passiert. Drei Fehler sind genau
// durch diese Lücke gekommen:
//
//   1. Die Zuordnung einer cue-Gruppe reiste nicht mit. Im
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
// Aus demselben Grund steht am Ende die Feder: ein Schritt vom Pult aus ist in
// der Halle ein echter Schritt mit Bewegung und kein Sprung, und eine
// Zeichnung, die sich nur bei dem zeichnet, der selbst am Rechner steht, wäre
// in einem Fenster nicht als Fehler zu sehen.
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
  // Und unter `preview`, wie das Paket nach der Einreichung heisst.
  const ziel2 = path.join(pp, "preview", "typstage");
  fs.mkdirSync(ziel2, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel2, "0.1.0"), "dir");
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

// Auf welchem Bild die Szene der Folie steht -- in dem Fenster, das gefragt
// wird. Eine Szene haengt am Schritt und nicht an der Uhr, also muss sie in
// beiden Fenstern dasselbe Bild zeigen. Ueber `#ts-stage`, wo es die Buehne
// gibt: im Sprecherfenster steht daneben noch die Vorschau, und die traegt
// eine zweite Szene, die absichtlich einen Schritt weiter ist.
// Und dasselbe fuer die Kamera: die Streckung, die die Buehne dieses Fensters
// gerade traegt. Ueber `#ts-stage`, aus demselben Grund wie beim Bild der
// Szene -- die Vorschau daneben traegt absichtlich den Ausschnitt des
// naechsten Schritts, und der ist ein anderer.
const kameraStreckung = `(function () {
  var b = document.querySelector('#ts-stage');
  if (!b) return -2;
  var f = b.querySelector('.ts-slide[data-on] .ts-bg');
  if (!f) return -1;
  var t = getComputedStyle(f).transform;
  if (!t || t === 'none') return 1;
  return +(new DOMMatrix(t).a).toFixed(2);
})()`;

const szeneBild = `(function () {
  var b = document.querySelector('#ts-stage') || document;
  var el = b.querySelector('.ts-scene');
  if (!el) return -2;
  var f = el.querySelectorAll('.ts-frame');
  for (var j = 0; j < f.length; j++) if (f[j].dataset.on) return j;
  return -1;
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

    // Bis zur ersten cue-Gruppe blättern. Sie steht nicht auf der
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
    if (k < 0) { sagt("cue", "keine cue-Gruppe im Prüfdeck gefunden"); }
    await schlaf(900);

    const beide = async () => ({
      h: JSON.parse(await halle.ev(stand)),
      s: JSON.parse(await sprecher.ev(stand))
    });

    // Die Ziffern gehoeren auf die Buehne, nicht in die Vorschau: dort stehen
    // sie neben Punkten, die noch niemand genannt hat, und waehlen kann man in
    // einem Standbild ohnehin nicht. Sie sind Geschwister ihrer Punkte und
    // werden deshalb mitgeklont, wenn man sie nicht abraeumt.
    const ziffern = JSON.parse(await sprecher.ev(`JSON.stringify({
      buehne: (document.querySelector('#ts-stage') || document).querySelectorAll('.ts-ad-nr').length,
      vorschau: document.querySelector('.ts-mini')
        ? document.querySelector('.ts-mini').querySelectorAll('.ts-ad-nr').length : -1
    })`));
    if (ziffern.buehne < 1) sagt("ziffern", "auf der Buehne steht keine Ziffer zur Auswahl");
    if (ziffern.vorschau > 0) {
      sagt("ziffern", "in der Vorschau stehen " + ziffern.vorschau + " Ziffern, dort gehoert keine hin");
    }
    console.log("Ziffern: Buehne " + ziffern.buehne + " · Vorschau " + ziffern.vorschau);

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

    // Rueckwaerts nimmt zurueck, und zwar in beiden Fenstern. Ohne das ist eine
    // Gruppe nach einem Durchgang aufgebraucht: jeder Pfeil vorwaerts deckt
    // auf, und wer zurueckblaettert, findet keine Ziffern mehr zur Auswahl.
    await sprecher.taste("ArrowLeft");
    await schlaf(1100);
    const zurueck = await beide();
    if (zurueck.h.punkte.includes("probe1:1.0")) {
      sagt("zurueck", "der zuletzt genannte Punkt steht in der Halle noch: " + zurueck.h.punkte);
    }
    if (!zurueck.s.punkte.includes("probe1:0.3")) {
      sagt("zurueck", "der zurueckgenommene Punkt steht im Sprecherfenster nicht wieder "
        + "blass zur Auswahl: " + zurueck.s.punkte);
    }
    if (zurueck.h.schritt !== zurueck.s.schritt) {
      sagt("zurueck", "Halle steht auf Schritt " + zurueck.h.schritt
        + ", Sprecher auf " + zurueck.s.schritt);
    }
    console.log("Zurueck: Halle S" + zurueck.h.auf + " [" + zurueck.h.punkte
      + "] · Sprecher [" + zurueck.s.punkte + "]");

    // ── Und die Feder, ferngesteuert ─────────────────────────────────────
    //
    // Ein Schritt aus dem Sprecherfenster ist in der Halle ein *echter*
    // Schritt mit Bewegung, kein Sprung: `melde` schickt nur die Zahl, und
    // drüben nimmt `fernGoto` sie ohne `instant`. Eine Zeichnung, die vom
    // Pult aus aufgedeckt wird, muss sich also zeichnen -- sonst zeichnete
    // sie sich nur bei dem, der selbst am Rechner steht, und in der Halle
    // stünde sie einfach da.
    //
    // In einem Fenster ist das nicht zu sehen: dort ist der Weg vom
    // Tastendruck zum `goto` ein anderer. Gezählt wird der laufende Zähler
    // der Laufzeit und keine Deckkraft zu einem geratenen Zeitpunkt -- eine
    // Messung, die an einer Uhr hängt, hängt am Rechner.
    const zurZeichnung = `(function () {
      var st = window.typstage.steps;
      var el = document.querySelector('.ts-el[data-enter="draw"]');
      if (!el) return -1;
      var f = [].indexOf.call(document.querySelectorAll('.ts-slide'),
                              el.closest('.ts-slide'));
      var ab = +(el.dataset.at.match(/[0-9]+/) || [1])[0];
      for (var k = 0; k < st.length; k++) {
        if (st[k].slide === f && st[k].step === ab - 1) {
          window.typstage.goto(k, true); return k;
        }
      }
      return -1;
    })()`;
    // ── Und die Szene, in beiden Fenstern ───────────────────────────────────
    //
    // Sie haengt am Schritt und nicht an der Uhr; ein Schritt drueben muss
    // also hier dasselbe Bild ergeben. Ein Daumenkino koennte das nicht: es
    // haengt an zwei Uhren, die nie genau gleich gehen.
    const zurSzene = `(function () {
      var st = window.typstage.steps;
      for (var k = 0; k < st.length; k++) {
        var sec = window.typstage.slides[st[k].slide];
        if (sec && sec.querySelector('.ts-scene') && st[k].step === 1) {
          window.typstage.goto(k, true); return k;
        }
      }
      return -1;
    })()`;
    const z0 = await sprecher.ev(zurZeichnung);
    if (z0 < 0) {
      sagt("feder", "keine Zeichnung mit enter=\"draw\" im Prüfdeck gefunden");
    } else {
      await schlaf(1200);
      const vorFeder = JSON.parse(await halle.ev(
        "JSON.stringify(window.typstage.pruef.stand().feder)"));
      await sprecher.taste("ArrowRight");
      await schlaf(1400);
      const nachFeder = JSON.parse(await halle.ev(
        "JSON.stringify(window.typstage.pruef.stand().feder)"));
      if (nachFeder <= vorFeder) {
        sagt("feder", "in der Halle zeichnete sich nichts, als das Pult "
          + "weiterschaltete (" + vorFeder + " -> " + nachFeder + "). Ein "
          + "ferngesteuerter Schritt ist ein echter Schritt und kein Sprung.");
      }
      // Und die Vorschau bleibt ein Standbild: dort läuft keine Feder, und
      // eine halb gezeichnete Linie hat in einem Standbild nichts zu suchen.
      const vor = JSON.parse(await sprecher.ev(`JSON.stringify({
        mini: document.querySelector('.ts-mini')
          ? document.querySelector('.ts-mini').querySelectorAll('[data-ts-feder]').length : -1,
        offen: window.typstage.pruef.stand().federOffen })`));
      if (vor.mini > 0) {
        sagt("feder", "in der Vorschau des Sprecherfensters stehen " + vor.mini
          + " halb gezeichnete Pfade; ein Standbild zeigt den Ruhezustand.");
      }
      if (vor.offen > 0) {
        sagt("feder", vor.offen + " Pfad(e) tragen im Sprecherfenster nach der "
          + "Fahrt noch eine Feder.");
      }
      console.log("Feder: Halle " + vorFeder + " -> " + nachFeder
        + " · Vorschau " + vor.mini + " · offen " + vor.offen);
    }
    const sz = await sprecher.ev(zurSzene);
    if (sz < 0) {
      sagt("szene", "keine Szene im Prüfdeck gefunden");
    } else {
      await schlaf(1100);
      const erst = [await halle.ev(szeneBild), await sprecher.ev(szeneBild)];
      if (erst[0] !== erst[1]) {
        sagt("szene", "beim Betreten steht die Halle auf Bild " + erst[0]
          + ", das Sprecherfenster auf " + erst[1]);
      }
      await sprecher.taste("ArrowRight");
      await schlaf(1400);
      const nun = [await halle.ev(szeneBild), await sprecher.ev(szeneBild)];
      if (nun[0] !== nun[1]) {
        sagt("szene", "nach einem Schritt steht die Halle auf Bild " + nun[0]
          + ", das Sprecherfenster auf " + nun[1]);
      }
      if (!(nun[0] > erst[0])) {
        sagt("szene", "ein Schritt im Sprecherfenster hat die Szene in der "
          + "Halle nicht weitergezogen: Bild " + erst[0] + " -> " + nun[0]);
      }
      console.log("Szene: Bild " + erst[0] + " -> " + nun[0] + " in beiden Fenstern");
    }

    // ── Und die Kamera, in beiden Fenstern ─────────────────────────────────
    //
    // Aus demselben Grund wie die Szene: sie haengt am Schritt und an nichts
    // sonst, also muss ein Schritt vom Pult aus in der Halle denselben
    // Ausschnitt ergeben. Und sie ist der einzige Fall, in dem ein Schritt die
    // *ganze Folie* bewegt und nicht ein Element darauf -- in einem Fenster
    // allein waere nicht zu sehen, wenn dieser Teil des Zustands beim
    // Weiterreichen verlorenginge, denn er reist nicht mit: jedes Fenster
    // rechnet ihn sich aus der Zahl aus, die es bekommt.
    const zurKamera = `(function () {
      var st = window.typstage.steps;
      for (var k = 0; k < st.length; k++) {
        var sec = window.typstage.slides[st[k].slide];
        if (sec && sec.querySelector('script.ts-camera') && st[k].step === 1) {
          window.typstage.goto(k, true); return k;
        }
      }
      return -1;
    })()`;
    const km = await sprecher.ev(zurKamera);
    if (km < 0) {
      sagt("kamera", "keine Folie mit einer Kamerafahrt im Prüfdeck gefunden");
    } else {
      await schlaf(1100);
      const ganz = [await halle.ev(kameraStreckung), await sprecher.ev(kameraStreckung)];
      if (ganz[0] !== 1 || ganz[1] !== 1) {
        sagt("kamera", "beim Betreten steht die Folie nicht ganz da: Halle "
          + ganz[0] + ", Sprecherfenster " + ganz[1]);
      }
      await sprecher.taste("ArrowRight");
      await schlaf(1600);
      const nah = [await halle.ev(kameraStreckung), await sprecher.ev(kameraStreckung)];
      // Verglichen mit einer Toleranz und nicht auf die Stelle genau. Die
      // Streckung rechnet sich aus dem Rechteck einer Marke, und das misst
      // jedes Fenster in seiner eigenen Buehnengroesse -- die zwei Ergebnisse
      // sind derselbe Faktor, nur verschieden gerundet. Auf dem Ubuntu-Laeufer
      // fielen sie auf 7,89 und 7,90 und damit auf zwei Seiten derselben
      // Rundungsgrenze; hier fielen sie zusammen. Ein Hundertstel ist keine
      // Abweichung, die jemand sieht.
      //
      // Was die Pruefung weiterhin faengt, ist alles, wofuer sie da ist: eine
      // Kamera, die drueben gar nicht faehrt (1 gegen 7,9), und eine, die
      // woandershin faehrt. Ein Prozent laesst dafuer keinen Raum.
      const spanne = Math.abs(nah[0] - nah[1]) / Math.max(nah[0], nah[1], 1);
      if (spanne > 0.01) {
        sagt("kamera", "nach einem Schritt steht die Halle auf Streckung "
          + nah[0] + ", das Sprecherfenster auf " + nah[1]
          + " -- das sind " + Math.round(spanne * 1000) / 10 + " % Unterschied.");
      }
      if (!(nah[0] > 1)) {
        sagt("kamera", "ein Schritt im Sprecherfenster hat die Kamera in der "
          + "Halle nicht herangefahren: Streckung " + ganz[0] + " -> " + nah[0]);
      }
      console.log("Kamera: Streckung " + ganz[0] + " -> " + nah[0]
        + " in beiden Fenstern");
    }

    // ── Hell und dunkel ───────────────────────────────────────────────────
    //
    // Die Ansicht gibt es in zwei Erscheinungsbildern, und die Zusage lautet:
    // beide sind vollstaendig. Eine Farbe, die nur in einem der beiden Bloecke
    // steht, faellt im anderen auf den ererbten Wert zurueck -- meist auf
    // Schwarz auf Schwarz --, und das sieht niemand, der nur in seinem eigenen
    // Erscheinungsbild arbeitet. Also wird es hier gezaehlt: dieselben Namen,
    // keiner leer, und die beiden Bloecke duerfen nicht dieselben Werte
    // tragen.
    const zeichenSatz = `(function(){
      var hell = {}, dunkel = {};
      [].forEach.call(document.styleSheets, function (b) {
        var rs; try { rs = b.cssRules; } catch (e) { return; }
        [].forEach.call(rs, function (r) {
          if (!r.selectorText) return;
          var z = /data-ts-licht="hell"/.test(r.selectorText) ? hell
                : /data-ts-licht="dunkel"/.test(r.selectorText) ? dunkel : null;
          if (!z) return;
          for (var i = 0; i < r.style.length; i++) {
            var n = r.style[i];
            if (n.indexOf("--sp-") === 0) z[n] = r.style.getPropertyValue(n).trim();
          }
        });
      });
      return JSON.stringify({ hell: hell, dunkel: dunkel });
    })()`;
    const pal = JSON.parse(await sprecher.ev(zeichenSatz));
    const nH = Object.keys(pal.hell), nD = Object.keys(pal.dunkel);
    if (!nH.length || !nD.length) {
      sagt("licht", "eines der beiden Erscheinungsbilder nennt gar keine Farbe: "
        + nH.length + " hell, " + nD.length + " dunkel");
    }
    const nurEins = nH.filter(n => nD.indexOf(n) < 0)
      .concat(nD.filter(n => nH.indexOf(n) < 0));
    if (nurEins.length) {
      sagt("licht", "diese Farben stehen nur in einem der beiden Bloecke: "
        + nurEins.join(", "));
    }
    const leer = nH.filter(n => !pal.hell[n]).concat(nD.filter(n => !pal.dunkel[n]));
    if (leer.length) sagt("licht", "diese Farben sind leer: " + leer.join(", "));
    const gleich = nH.filter(n => pal.hell[n] === pal.dunkel[n]);
    if (gleich.length > nH.length / 2) {
      sagt("licht", "hell und dunkel tragen dieselben Werte, " + gleich.length
        + " von " + nH.length + " -- ein Block ist eine Kopie des anderen");
    }

    // Und die Wahl selbst. Dunkel ist die Vorgabe, und zwar *ohne* das System
    // zu fragen: ein Pult steht im abgedunkelten Raum, und ein helles Fenster
    // neben einer dunklen Wand blendet. Hier stand die umgekehrte Erwartung --
    // die Systemeinstellung entscheide --, und sie ist mit dieser Entscheidung
    // falsch geworden; der Lauf meldete seither zwei Abweichungen fuer etwas,
    // das so gewollt ist. Geprueft wird jetzt beides: dass das System nicht
    // durchgreift, und dass `l` sehr wohl etwas aendert. Gemessen wird nicht
    // das Attribut allein, sondern die Farbe, die dabei herauskommt.
    const grundVon = `(function(){ return document.documentElement.dataset.tsLicht
      + " " + getComputedStyle(document.getElementById("ts-speaker")).backgroundColor; })()`;
    await sprecher.ruf("Emulation.setEmulatedMedia",
      { features: [{ name: "prefers-color-scheme", value: "light" }] });
    await schlaf(400);
    const l1 = await sprecher.ev(grundVon);
    await sprecher.ruf("Emulation.setEmulatedMedia",
      { features: [{ name: "prefers-color-scheme", value: "dark" }] });
    await schlaf(400);
    const l2 = await sprecher.ev(grundVon);
    if (!/^dunkel /.test(l1) || !/^dunkel /.test(l2)) {
      sagt("licht", "dunkel ist nicht die Vorgabe: bei heller Systemeinstellung "
        + JSON.stringify(l1) + ", bei dunkler " + JSON.stringify(l2));
    }
    await sprecher.taste("l"); await schlaf(400);
    const l3 = await sprecher.ev(grundVon);
    if (!/^hell /.test(l3)) {
      sagt("licht", "`l` hat dem dunklen Bild nicht widersprochen: "
        + JSON.stringify(l3));
    }
    // Zwei Bilder muessen auch zwei Bilder sein, sonst hiesse `l` nichts.
    if (l3.split(" ")[1] === l2.split(" ")[1]) {
      sagt("licht", "beide Erscheinungsbilder stehen auf demselben Grund: "
        + l3.split(" ")[1]);
    }
    // Und der Widerspruch haelt, wenn das System danach noch einmal wechselt.
    await sprecher.ruf("Emulation.setEmulatedMedia",
      { features: [{ name: "prefers-color-scheme", value: "light" }] });
    await schlaf(300);
    await sprecher.ruf("Emulation.setEmulatedMedia",
      { features: [{ name: "prefers-color-scheme", value: "dark" }] });
    await schlaf(300);
    const l4 = await sprecher.ev(grundVon);
    if (l4 !== l3) {
      sagt("licht", "die Systemeinstellung hat die Wahl von `l` ueberfahren: "
        + JSON.stringify(l3) + " -> " + JSON.stringify(l4));
    }
    await sprecher.taste("l"); await schlaf(300);
    await sprecher.ruf("Emulation.setEmulatedMedia", { features: [] });
    await schlaf(300);
    console.log("Licht: " + nH.length + " Farben in beiden · " + l1 + " · " + l2
      + " · nach `l` " + l3);

    // ── Die Kachel der laufenden Folie ist die Zeichenflaeche ─────────────
    //
    // Sie sieht nach Verschwendung aus -- die Wand zeigt dasselbe --, und sie
    // ist keine: auf ihr wird gezeichnet, und die Striche gehen in die Halle.
    // Der Kachelentwurf hat sie in einen Kasten gesetzt, und ein Kasten, der
    // ueber ihr laege statt um sie herum, faenge den Zeiger ab. Das faellt an
    // keiner Knotenzahl auf und an keinem Fingerabdruck -- also hier.
    //
    // Gezogen wird mit dem echten Zeiger und nicht mit einer Nachricht: die
    // Frage ist ja gerade, ob der Zeiger ankommt.
    const tMasse = JSON.parse(await sprecher.ev(`(function(){
      var f = document.getElementById('ts-stage').getBoundingClientRect();
      var k = document.querySelector('.ts-sp-buehne').getBoundingClientRect();
      var v = document.querySelector('.ts-sp-vorbild').getBoundingClientRect();
      return JSON.stringify({ f: {x:f.x,y:f.y,width:f.width,height:f.height},
                              k: {x:k.x,y:k.y,width:k.width,height:k.height},
                              v: {width:v.width,height:v.height} });})()`));
    const tBuehne = tMasse.f, tKachel = tMasse.k;
    // Die Vorschau richtet sich nach der Hoehe ihrer Kachel, und ihre Breite
    // rechnet die Laufzeit dazu. Bleibt die Rechnung aus, faellt das Bild auf
    // Breite null zusammen: die Kachel steht dann da und ist leer. Keine
    // Knotenzahl merkt das -- die Knoten sind ja alle noch da -- und der
    // Fingerabdruck des Satzes auch nicht, denn er kennt das Stilblatt und
    // nicht die Laufzeit.
    if (tMasse.v.width < 60 || tMasse.v.height < 30) {
      sagt("vorschau", "die Vorschau misst " + Math.round(tMasse.v.width) + "x"
        + Math.round(tMasse.v.height) + " -- sie hat ihre Breite nicht bekommen");
    }
    const tinteZaehlen = "document.querySelectorAll('#ts-ink *').length";
    const tVor = [+await halle.ev(tinteZaehlen), +await sprecher.ev(tinteZaehlen)];
    // Die Buehne liegt *in* ihrer Kachel. Sie ist nicht deren Kind -- sie
    // schwebt darueber, weil `display:none` den Morphs ihre Masse naehme --,
    // und `fit` setzt sie auf den Platz, den die Kachel freihaelt. Verliert
    // der Platz seine Hoehe, faellt `fit` auf das ganze Fenster zurueck: die
    // Buehne deckt dann die Kacheln zu, und gezeichnet wird trotzdem noch.
    // Der Zug allein faende das also nicht.
    const raus = Math.max(tKachel.x - tBuehne.x, tKachel.y - tBuehne.y,
      (tBuehne.x + tBuehne.width) - (tKachel.x + tKachel.width),
      (tBuehne.y + tBuehne.height) - (tKachel.y + tKachel.height));
    if (raus > 2) {
      sagt("zeichnen", "die Buehne steht " + Math.round(raus)
        + " px ausserhalb ihrer Kachel: Buehne "
        + Math.round(tBuehne.width) + "x" + Math.round(tBuehne.height)
        + " bei " + Math.round(tBuehne.x) + "," + Math.round(tBuehne.y)
        + ", Kachel " + Math.round(tKachel.width) + "x" + Math.round(tKachel.height)
        + " bei " + Math.round(tKachel.x) + "," + Math.round(tKachel.y));
    }
    if (tBuehne.width < 40 || tBuehne.height < 40) {
      sagt("zeichnen", "die Buehne im Sprecherfenster misst "
        + Math.round(tBuehne.width) + "x" + Math.round(tBuehne.height)
        + " -- sie hat ihren Platz in der Kachel nicht gefunden");
    } else {
      const bei = (fx, fy) => ({ x: Math.round(tBuehne.x + tBuehne.width * fx),
                                 y: Math.round(tBuehne.y + tBuehne.height * fy) });
      const zug = [[0.25, 0.35], [0.38, 0.5], [0.5, 0.36], [0.62, 0.52], [0.74, 0.4]];
      let q = bei(zug[0][0], zug[0][1]);
      await sprecher.ruf("Input.dispatchMouseEvent", { type: "mousePressed",
        x: q.x, y: q.y, button: "left", clickCount: 1, buttons: 1 });
      for (const [fx, fy] of zug.slice(1)) {
        q = bei(fx, fy);
        await sprecher.ruf("Input.dispatchMouseEvent", { type: "mouseMoved",
          x: q.x, y: q.y, button: "left", buttons: 1 });
        await schlaf(90);
      }
      await sprecher.ruf("Input.dispatchMouseEvent", { type: "mouseReleased",
        x: q.x, y: q.y, button: "left", clickCount: 1, buttons: 0 });
      await schlaf(900);
      const tNach = [+await halle.ev(tinteZaehlen), +await sprecher.ev(tinteZaehlen)];
      if (tNach[1] <= tVor[1]) {
        sagt("zeichnen", "ein Zug ueber die Folienkachel hat im Sprecherfenster"
          + " keinen Strich gemacht: " + tVor[1] + " -> " + tNach[1]);
      }
      if (tNach[0] <= tVor[0]) {
        sagt("zeichnen", "der Strich kam in der Halle nicht an: "
          + tVor[0] + " -> " + tNach[0]);
      }
      console.log("Zeichnen: Sprecher " + tVor[1] + " -> " + tNach[1]
        + " · Halle " + tVor[0] + " -> " + tNach[0]
        + " · Buehne " + Math.round(tBuehne.width) + "x" + Math.round(tBuehne.height)
        + " · Vorschau " + Math.round(tMasse.v.width) + "x"
        + Math.round(tMasse.v.height));
      // Und `x` raeumt sie wieder ab, damit die naechste Probe eine leere
      // Folie vorfindet.
      await sprecher.taste("x"); await schlaf(500);
    }

    // ── Und die Vollbilduhr, ferngesteuert ────────────────────────────────
    //
    // Sie ist der einzige Zustand, den das Pult setzt und den die Halle
    // *fuehrt*: schwarz und Frost sind Schalter, die Uhr zaehlt. Deshalb ist
    // sie in einem Fenster nicht zu pruefen -- dort gibt es weder die Taste
    // noch den Kanal, und die Nummer des Laufs, an der alles haengt, wird nie
    // ueber die Leitung getragen.
    //
    // Steht am Ende, weil die letzte Probe das Sprecherfenster schliesst.
    const uhrHalle = `JSON.stringify({
      pruef: window.typstage.pruef.clock(),
      an: !!document.documentElement.dataset.tsClock,
      zeigt: document.querySelector('#ts-clock .ts-clock-num').textContent,
      sicht: getComputedStyle(document.querySelector('#ts-clock')).display,
      art: (document.getElementById('ts-clock').dataset.art || ''),
      deckt: (() => { const k = document.getElementById('ts-clock').getBoundingClientRect();
        const b = document.getElementById('ts-stage').getBoundingClientRect();
        return b.width ? Math.round(k.width * k.height / (b.width * b.height) * 1000) / 10 : 0;
      })() })`;
    // Die Uhr der Klasse steht in ihrer eigenen Kachel und nicht mehr als
    // vierte Pille in der Zustandszeile. Gelesen wird beides: der Zustand,
    // den die Kachel von sich behauptet, und die Zahl, die darin steht --
    // eine Kachel, die `laeuft` sagt und einen Strich zeigt, waere so
    // falsch wie umgekehrt.
    const lage = `(function(){ var k = document.querySelector('.ts-sp-uhrkachel');
      if (!k) return "";
      var z = k.querySelector('.ts-sp-gross');
      return (k.dataset.uhr || "?") + " " + (z ? z.textContent : ""); })()`;

    await sprecher.taste("t");
    await schlaf(300);
    const feldAuf = await sprecher.ev(
      "document.activeElement && document.activeElement.className");
    if (feldAuf !== "ts-sp-uhrfeld") {
      sagt("uhr", "`t` hat das Minutenfeld nicht geholt, der Blick liegt auf "
        + JSON.stringify(feldAuf));
    }
    // Die Uhr darf im Sprecherfenster nicht auch angehen: dort stuende sie
    // hinter der Sprecherbox und waere ein zweiter Ort, der stimmen muss.
    await sprecher.ev("document.activeElement.value='5'");
    await sprecher.taste("Enter");
    await schlaf(700);
    let uh = JSON.parse(await halle.ev(uhrHalle));
    if (!uh.an || !uh.pruef) {
      sagt("uhr", "nach `t` 5 Enter laeuft in der Halle keine Uhr: " + JSON.stringify(uh));
    } else {
      if (uh.pruef.duration !== 300) {
        sagt("uhr", "die Halle bekam " + uh.pruef.duration + " s statt 300");
      }
      if (uh.sicht !== "flex") sagt("uhr", "die Uhrschicht steht auf " + uh.sicht);
      if (!/^ ?0[45]:[0-9][0-9] ?$/.test(uh.zeigt)) {
        sagt("uhr", "die Halle zeigt " + JSON.stringify(uh.zeigt) + ", erwartet 5:00 oder knapp darunter");
      }
    }
    const sp0 = JSON.parse(await sprecher.ev(
      `JSON.stringify({ uhr: window.typstage.pruef.clock(),
                        an: !!document.documentElement.dataset.tsClock })`));
    if (sp0.uhr || sp0.an) {
      sagt("uhr", "im Sprecherfenster laeuft die Uhr ebenfalls: " + JSON.stringify(sp0));
    }
    let lz = await sprecher.ev(lage);
    // Das U+2007 vor der Zahl ist kein Schmutz, sondern die Spalte, in der
    // spaeter das Plus der Ueberzeit steht. Ohne sie sprangen die Ziffern
    // beim Umschlag um 19 Pixel nach rechts -- gemessen 64,02 gegen 83,03.
    // Deshalb wird sie hier verlangt und nicht bloss geduldet.
    if (!/^laeuft \u2007[45]:[0-9][0-9]$/.test(lz)) {
      sagt("uhr", "die Uhrkachel sagt " + JSON.stringify(lz)
        + ", erwartet 'laeuft \u2007" + "4:59' -- mit der Ziffernspalte davor");
    }
    console.log("Uhr: Halle " + JSON.stringify(uh.zeigt) + " · Kachel " + JSON.stringify(lz));

    // `⇧→` verlaengert, ohne die Uhr neu zu stempeln.
    //
    // Gemessen wird das VERSTRICHENE und nicht der Rest. Am Rest ist der
    // Unterschied nicht zu sehen, solange die Uhr erst eine halbe Sekunde
    // laeuft: dann sind "60 s dazu" und "von vorn mit 360" fast dieselbe Zahl,
    // und eine Mutation, die jede Nachricht neu stempeln laesst, kam so
    // ungesehen durch -- gemessen. Drei Sekunden Vorlauf, und das Verstrichene
    // trennt die beiden Faelle sauber: es waechst nur um die Wartezeit, oder
    // es faellt auf null.
    await schlaf(3000);
    uh = JSON.parse(await halle.ev(uhrHalle));
    const vorMehr = uh.pruef.duration - uh.pruef.remaining;
    await sprecher.taste("ArrowRight", 8);
    await schlaf(600);
    uh = JSON.parse(await halle.ev(uhrHalle));
    if (uh.pruef.duration !== 360) {
      sagt("uhr", "`⇧→` machte aus 300 s nicht 360, sondern " + uh.pruef.duration);
    }
    const nachMehr = uh.pruef.duration - uh.pruef.remaining;
    if (!(nachMehr >= vorMehr && nachMehr - vorMehr < 2)) {
      sagt("uhr", "`⇧→` hat die Uhr neu gestempelt: verstrichen waren "
        + vorMehr.toFixed(1) + " s, danach " + nachMehr.toFixed(1)
        + " s. Es soll die Dauer wachsen und nicht der Stempel fallen.");
    }
    // Und es hat nicht geblaettert.
    const wo = JSON.parse(await halle.ev(stand));
    await sprecher.taste("ArrowLeft", 8);
    await schlaf(600);
    uh = JSON.parse(await halle.ev(uhrHalle));
    if (uh.pruef.duration !== 300) {
      sagt("uhr", "`⇧←` machte aus 360 s nicht wieder 300, sondern " + uh.pruef.duration);
    }
    const wo2 = JSON.parse(await halle.ev(stand));
    if (wo2.schritt !== wo.schritt) {
      sagt("uhr", "`⇧←` hat nebenbei geblaettert: Schritt " + wo.schritt
        + " -> " + wo2.schritt);
    }
    console.log("Uhr: ⇧→ 300 -> 360 -> 300, Schritt " + wo2.schritt + " unbewegt");

    // Blaettern beendet sie und deckt die Folie auf.
    await sprecher.taste("ArrowRight");
    await schlaf(700);
    uh = JSON.parse(await halle.ev(uhrHalle));
    if (uh.an || uh.pruef) {
      sagt("uhr", "ein Schritt weiter hat die Uhr nicht beendet: " + JSON.stringify(uh));
    }
    const wo3 = JSON.parse(await halle.ev(stand));
    if (wo3.schritt !== wo2.schritt + 1) {
      sagt("uhr", "der Schritt, der die Uhr beendete, hat nicht geblaettert: "
        + wo2.schritt + " -> " + wo3.schritt);
    }
    lz = await sprecher.ev(lage);
    if (!/^aus /.test(lz)) {
      sagt("uhr", "die Uhrkachel traegt die Uhr noch: " + JSON.stringify(lz));
    }
    console.log("Uhr: ein Schritt beendet sie, Folie wieder da");

    // ── Die Ueberzeit am Pult ─────────────────────────────────────────────
    //
    // Der teuerste Fehler, den diese Ansicht hatte: die Wand schlug auf die
    // Signalfarbe um, und am Pult blieb die Uhr gruen. Die Klasse sah die
    // Ueberzeit, bevor die Lehrkraft sie sah. Gemessen wird deshalb beides
    // zugleich, in beiden Fenstern, und nicht nur die Wand -- die allein
    // war schon immer richtig.
    //
    // Die Uhr der Halle wird dafuer festgenagelt und weitergestellt: eine
    // Minute abzuwarten waere eine Minute Prueflauf fuer eine Zahl.
    await sprecher.taste("t"); await schlaf(250);
    await sprecher.ev("document.activeElement.value='1'");
    await sprecher.taste("Enter"); await schlaf(700);
    const jetzt = await halle.ev("Date.now()");
    await halle.ev("typstage.pruef.uhr(" + jetzt + ")"); await schlaf(300);
    await halle.ev("typstage.pruef.uhr(" + (jetzt + 71000) + ")");
    await schlaf(1800);
    const uz = await sprecher.ev(lage);
    if (!/^ueber \+0:1[0-9]$/.test(uz)) {
      sagt("ueberzeit", "die Uhrkachel sagt in der Ueberzeit " + JSON.stringify(uz)
        + ", erwartet 'ueber +0:11'");
    }
    // Und die Kachel sieht anders aus, nicht nur ihre Ziffern: eine Flaeche
    // sieht man aus dem Augenwinkel, eine Ziffer nicht.
    const uf = JSON.parse(await sprecher.ev(`(function(){
      var k = document.querySelector('.ts-sp-uhrkachel');
      var g = getComputedStyle(k), z = getComputedStyle(k.querySelector('.ts-sp-gross'));
      var w = getComputedStyle(document.querySelector('.ts-sp-notizkasten'));
      return JSON.stringify({ grund: g.backgroundColor, ziffer: z.color,
                              ruhig: w.backgroundColor,
                              marke: k.querySelector('.ts-sp-marke').textContent });})()`));
    if (uf.grund === uf.ruhig) {
      sagt("ueberzeit", "die Kachel traegt in der Ueberzeit denselben Grund wie"
        + " jede andere: " + uf.grund);
    }
    if (uf.grund === uf.ziffer) {
      sagt("ueberzeit", "Grund und Ziffer der Uhrkachel sind dieselbe Farbe");
    }
    // Und das Wort wechselt. Drei Zeichen, die unabhaengig voneinander sagen,
    // dass die Zeit um ist: das Wort, das Vorzeichen, die Flaeche.
    if (!/(ber|over|pass)/i.test(uf.marke)) {
      sagt("ueberzeit", "die Marke der Kachel sagt in der Ueberzeit noch "
        + JSON.stringify(uf.marke));
    }
    console.log("Ueberzeit: Kachel " + JSON.stringify(uz) + " · Grund "
      + uf.grund + " statt " + uf.ruhig + " · Marke " + JSON.stringify(uf.marke));
    await halle.ev("typstage.pruef.uhr()"); await schlaf(300);
    await sprecher.taste("t"); await schlaf(600);

    // Und `t` beendet sie ebenfalls.
    await sprecher.taste("t"); await schlaf(250);
    await sprecher.ev("document.activeElement.value='2'");
    await sprecher.taste("Enter"); await schlaf(600);
    if (!JSON.parse(await halle.ev(uhrHalle)).an) {
      sagt("uhr", "die Uhr liess sich kein zweites Mal stellen");
    }
    await sprecher.taste("t"); await schlaf(600);
    if (JSON.parse(await halle.ev(uhrHalle)).an) {
      sagt("uhr", "ein zweites `t` hat die Uhr nicht beendet");
    }
    console.log("Uhr: `t` stellt sie und `t` beendet sie");

    // ── Und ueber ein Neuladen hinweg ─────────────────────────────────────
    //
    // Buehnenzeit ueberlebt kein Neuladen: `performance.now()` faengt in der
    // neuen Seite wieder bei null an. Gemerkt wird deshalb eine Wanduhr-Frist,
    // und beim Wiederherstellen wird daraus eine Restdauer. Die Probe misst
    // genau die Naht: die Uhr muss wiederkommen, und sie muss *weiter* sein,
    // nicht wieder am Anfang stehen.
    await sprecher.taste("t"); await schlaf(250);
    await sprecher.ev("document.activeElement.value='7'");
    await sprecher.taste("Enter"); await schlaf(500);
    const vorLaden = JSON.parse(await halle.ev(uhrHalle)).pruef;
    await schlaf(2200);
    await halle.ev("location.reload()");
    await schlaf(2600);
    const nachLaden = JSON.parse(await halle.ev(uhrHalle));
    if (!nachLaden.an || !nachLaden.pruef) {
      sagt("neuladen", "die Uhr kam nach dem Neuladen nicht wieder: "
        + JSON.stringify(nachLaden));
    } else {
      if (nachLaden.pruef.duration !== 420) {
        sagt("neuladen", "die Dauer kam als " + nachLaden.pruef.duration
          + " s wieder statt als 420");
      }
      const weg = vorLaden.remaining - nachLaden.pruef.remaining;
      // Ein Neuladen kostet ein paar Sekunden, und die laufen mit: die Klasse
      // draussen wartet ja auch. Wieder am Anfang zu stehen waere der Fehler.
      if (!(weg > 1.5 && weg < 20)) {
        sagt("neuladen", "die Uhr sprang beim Neuladen um " + weg.toFixed(1)
          + " s; erwartet war die Zeit, die das Laden gekostet hat");
      }
      console.log("Neuladen: " + vorLaden.remaining.toFixed(1) + " s -> "
        + nachLaden.pruef.remaining.toFixed(1) + " s, Dauer "
        + nachLaden.pruef.duration + " s");
    }

    // ── Der Wach-Vertrag ──────────────────────────────────────────────────
    //
    // Im Buehnenfenster gibt es keine Taste gegen die Uhr, und es soll dort
    // keine geben. Faellt das Pult weg, muss die Halle sie von selbst
    // aufheben -- sonst waere sie ein neuer Weg, einen Saal zugedeckt
    // zurueckzulassen. Zuletzt, weil danach kein Sprecherfenster mehr da ist.
    // Aus der Probe davor laeuft noch eine; der erste `t` beendet sie, der
    // zweite holt das Feld. Genau die Reihenfolge, die auch am Pult gilt.
    await sprecher.taste("t"); await schlaf(400);
    await sprecher.taste("t"); await schlaf(250);
    await sprecher.ev("document.activeElement.value='9'");
    await sprecher.taste("Enter"); await schlaf(600);
    if (!JSON.parse(await halle.ev(uhrHalle)).an) {
      sagt("wache", "die Uhr liess sich fuer die Wachprobe nicht stellen");
    }
    // ── Die angeheftete Uhr ueberlebt das Blaettern ────────────────────────
    // Der Unterschied zwischen den beiden Uhren ist keine Groesse, sondern
    // eine Regel: die Vollbilduhr endet beim Blaettern, die angeheftete
    // nicht. Genau das war der teuerste offene Punkt der Bedienungspruefung,
    // und genau das kann eine Pruefung in *einem* Fenster nicht sehen.
    // Erst abraeumen: aus dem Abschnitt davor laeuft noch eine Uhr, und ein
    // ⇧T auf eine laufende Uhr beendet sie, statt eine neue zu stellen --
    // gemessen kam danach gar keine angeheftete Uhr zustande, und die
    // Pruefung meldete das Richtige aus dem falschen Grund.
    for (let i = 0; i < 3; i++) {
      if (!JSON.parse(await halle.ev(uhrHalle)).an) break;
      await sprecher.taste("T", 8); await schlaf(500);
    }
    await sprecher.taste("T", 8); await schlaf(300);
    await sprecher.ev("document.activeElement.value='4'");
    await sprecher.taste("Enter"); await schlaf(900);
    const fest0 = JSON.parse(await halle.ev(uhrHalle));
    if (!fest0.an || fest0.art !== "fest") {
      sagt("angeheftet", "nach ⇧T steht in der Halle "
        + JSON.stringify(fest0) + ", erwartet eine angeheftete Uhr.");
    }
    const deckte = fest0.deckt;
    await sprecher.taste("ArrowRight"); await schlaf(800);
    const fest1 = JSON.parse(await halle.ev(uhrHalle));
    if (!fest1.an) {
      sagt("angeheftet", "ein Blaettern hat die angeheftete Uhr beendet. Sie "
        + "gehoert der Klasse, die gerade arbeitet, und nicht der Folie, die "
        + "am Pult gerade gesucht wird.");
    }
    if (deckte > 25) {
      sagt("angeheftet", "die angeheftete Uhr deckt " + deckte + " % der "
        + "Buehne zu. Sie soll auf der Folie stehen und die Aufgabe darunter "
        + "lesbar lassen.");
    }
    await sprecher.taste("T", 8); await schlaf(700);
    if (JSON.parse(await halle.ev(uhrHalle)).an) {
      sagt("angeheftet", "ein zweites ⇧T hat die Uhr nicht beendet.");
    }

    await sprecher.ev("window.close()");
    let hoch = -1;
    for (let i = 0; i < 40; i++) {
      await schlaf(250);
      if (!JSON.parse(await halle.ev(uhrHalle)).an) { hoch = i * 250; break; }
    }
    if (hoch < 0) {
      sagt("wache", "das Sprecherfenster ist zu, und die Halle steht nach "
        + "10 s immer noch unter der Uhr. Ein Saal, den niemand mehr "
        + "aufdecken kann.");
    } else {
      console.log("Wache: Uhr nach " + hoch + " ms von selbst aufgehoben");
    }

    await sprecher.ende();
  } catch (e) {
    sagt("lauf", e.message);
  } finally {
    await halle.ende();
  }
  console.log("\nZwei Fenster: " + (maengel.length ? maengel.length + " Abweichungen" : "ohne Abweichung"));
  process.exit(maengel.length ? 1 : 0);
})();
