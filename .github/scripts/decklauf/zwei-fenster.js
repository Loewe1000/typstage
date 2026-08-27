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
      if (nah[0] !== nah[1]) {
        sagt("kamera", "nach einem Schritt steht die Halle auf Streckung "
          + nah[0] + ", das Sprecherfenster auf " + nah[1]);
      }
      if (!(nah[0] > 1)) {
        sagt("kamera", "ein Schritt im Sprecherfenster hat die Kamera in der "
          + "Halle nicht herangefahren: Streckung " + ganz[0] + " -> " + nah[0]);
      }
      console.log("Kamera: Streckung " + ganz[0] + " -> " + nah[0]
        + " in beiden Fenstern");
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
      sicht: getComputedStyle(document.querySelector('#ts-clock')).display })`;
    const lage = `(function(){ var l = document.querySelector('.ts-sp-saal');
      return l ? l.textContent : ""; })()`;

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
      if (!/^ ?[45]:[0-9][0-9]$/.test(uh.zeigt)) {
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
    if (!/^\S+ [45]:[0-9][0-9]$/.test(lz)) {
      sagt("uhr", "die Lagezeile sagt " + JSON.stringify(lz) + ", erwartet etwas wie 'Uhr 4:59'");
    }
    console.log("Uhr: Halle " + JSON.stringify(uh.zeigt) + " · Lagezeile " + JSON.stringify(lz));

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
    if (lz) sagt("uhr", "die Lagezeile traegt die Uhr noch: " + JSON.stringify(lz));
    console.log("Uhr: ein Schritt beendet sie, Folie wieder da");

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
