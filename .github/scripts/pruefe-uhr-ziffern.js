// pruefe-uhr-ziffern.js — stellen die Zifferntasten die Klassenuhr?
//
// Eine Frage am Stundenanfang, ein Gespräch zu zweit: die Hand liegt auf der
// Tastatur, und `3` soll drei Minuten bedeuten. Die Ziffern waren aber schon
// vergeben -- auf einer Folie mit `cue()`-Gruppe rufen sie deren Punkte.
//
//   node .github/scripts/pruefe-uhr-ziffern.js [--browser /pfad]
//
// Eigens im Browser: die Uhr zählt in Bühnenzeit, und wie sie liest, entsteht
// erst im DOM. `pruef.uhr(ms)` nagelt die Bühnenzeit fest, sonst dauerte
// dieser Lauf fünf Minuten je Fall.
//
// Geprüft wird:
//   1. Eine Ziffer startet die ANGEHEFTETE Uhr, nicht das Vollbild: die Frage
//      muss stehen bleiben, während die Zeit läuft.
//   2. Blättern beendet sie nicht. Das ist der Unterschied zur Vollbilduhr und
//      der Grund, warum die Ziffern die angeheftete nehmen.
//   3. `0` beendet sie.
//   4. Auf einer Folie mit `cue()`-Gruppe gehören die Ziffern der Gruppe --
//      auch die jenseits ihrer Punktzahl und auch der zweite Druck derselben
//      Ziffer. Beide geben in `adTaste` false, und beide dürfen keine Uhr
//      starten; genau daran wäre ein Durchfall-Entwurf gescheitert.
//   5. `room: (clock: (step: 5))` lässt die Anzeige nur alle fünf Sekunden
//      springen -- und die letzte Stufe zählt trotzdem einzeln herunter.
//   6. Die angeheftete Uhr überlebt `b`, die Vollbilduhr nicht. Wer während
//      einer Gruppenarbeit verdunkelt, nimmt der Klasse die Ablenkung und
//      nicht ihre Zeit.
//   7. `room: (clock: (digits: false))` nimmt den Ziffern die Uhr wieder.
//   8. Eine gehaltene Ziffer stempelt die Uhr nicht je Anschlag neu.
//   9. Mit zwei Fenstern: eine im Saal gestartete Uhr überlebt das Aufgehen
//      der Sprecheransicht -- sie schlägt nicht auf Vollbild um, springt nicht
//      an ihren Anfang und wird nicht gelöscht. Beide Fenster lesen dieselbe
//      halbe Sekunde gleich: bei 329,5 s Rest stand an der Wand 05:29 und am
//      Pult 05:30, und ein glatter Rest hätte das nie gezeigt. Und die `0` im
//      Saal beendet sie weiterhin, obwohl sie von da an das Pult führt.
//  10. Startet der Saal danach eine Vollbilduhr, übernimmt das Pult auch
//      diese Art -- sonst schlüge sie auf die Folie um.
//
// NICHT geprüft: der Schutz einer eigenen Uhr gegen ein `uhr: 0` von einem
// Pult, das sie noch nicht kennt. Seit das Pult seine Übernahme bestätigt,
// erscheint dieses Fenster im Regelfall nicht mehr -- der Schutz greift nur
// noch, wenn die Bestätigung und der erste Herzschlag des Pults sich
// überholen. Gemessen: den Schutz entfernt, die Probe blieb grün. Er bleibt
// trotzdem, denn die Reihenfolge zweier Fenster ist nicht zugesichert.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

const kopf = (raum) => `#import "@preview/typstage:0.1.3": *
#show: presentation.with(theme: themes.lesson, title: [Ziffern]${raum})
`;

const SCHLICHT = kopf("") + `
== Erste Folie
Ein Satz.
== Zweite Folie
Noch einer.
`;

const MIT_CUE = kopf("") + `
== Ohne Gruppe
Ein Satz.
== Mit Gruppe
#cue("wahl")[Erstens][Zweitens]
`;

const GERASTERT = kopf(", room: (clock: (step: 5))") + `
== Erste Folie
Ein Satz.
== Zweite Folie
Noch einer.
`;

const OHNE_ZIFFERN = kopf(", room: (clock: (digits: false))") + `
== Erste Folie
Ein Satz.
== Zweite Folie
Noch einer.
`;

// Was die Uhr gerade ist und zeigt.
const stand = `(function(){
  var k = document.getElementById('ts-clock');
  var z = k && k.querySelector('.ts-clock-num');
  return JSON.stringify({
    an: !!document.documentElement.dataset.tsClock,
    art: (k && k.dataset.art) || '',
    text: (z && z.textContent || '').trim(),
    deckung: k ? getComputedStyle(k).opacity : '',
    schritt: typstage.state()
  });
})()`;

// Ein Bild abwarten: gezeichnet wird in `beat`, und `beat` hängt am Bildtakt.
const bild = `new Promise(function(f){
  requestAnimationFrame(function(){ requestAnimationFrame(f); });
})`;

function bauen(quelle, name, paket) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-ziffern-"));
  fs.writeFileSync(path.join(tmp, name + ".typ"), quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", tmp,
    path.join(tmp, name + ".typ"), path.join(tmp, name + ".html")],
    { stdio: ["ignore", "ignore", "pipe"] });
  return path.join(tmp, name + ".html");
}

(async () => {
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-ziffern-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.1.3"));
  }
  let schlicht, mitCue, gerastert, ohneZiffern;
  try {
    schlicht = bauen(SCHLICHT, "schlicht", paket);
    mitCue = bauen(MIT_CUE, "cue", paket);
    gerastert = bauen(GERASTERT, "raster", paket);
    ohneZiffern = bauen(OHNE_ZIFFERN, "ohne", paket);
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Uhr-Ziffern: ein Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  const klagen = [];
  const lies = async () => JSON.parse(await b.ev(stand));
  const uhrAuf = async (ms) => { await b.ev(`typstage.pruef.uhr(${ms})`); await b.ev(bild); };

  // ── 1 bis 3: eine Ziffer, ein Blättern, eine Null ────────────────────────
  await b.navigiere("file://" + schlicht);
  await schlaf(2000);
  await b.ev("typstage.goto(0, true); typstage.pruef.uhr(0)");
  await b.ev(bild);
  await b.taste("3");
  await b.ev(bild);
  let s = await lies();
  if (!s.an) klagen.push("1. `3` startete keine Uhr");
  else if (s.art !== "fest") {
    klagen.push("1. `3` startete das Vollbild statt der angehefteten Uhr"
                + " (data-art=" + JSON.stringify(s.art) + ")");
  }
  if (s.text !== "03:00") klagen.push("1. `3` ergab " + JSON.stringify(s.text) + " statt 03:00");

  await uhrAuf(61000);
  s = await lies();
  if (s.text !== "01:59") klagen.push("1. nach 61 s stand " + JSON.stringify(s.text) + " statt 01:59");

  const vorher = s.schritt;
  await b.taste("ArrowRight");
  await b.ev(bild);
  s = await lies();
  if (s.schritt === vorher) klagen.push("2. der Pfeil blätterte gar nicht");
  if (!s.an) klagen.push("2. Blättern beendete die angeheftete Uhr");

  await b.taste("0");
  await b.ev(bild);
  s = await lies();
  if (s.an) klagen.push("3. `0` beendete die Uhr nicht");

  // ── 8: eine klemmende Ziffer stempelt nicht neu ──────────────────────────
  await b.ev("typstage.pruef.uhr(0)"); await b.ev(bild);
  await b.taste("2");
  // Ein Bild dazwischen: `uhrTakt` stempelt `t0` erst beim ersten Bild nach
  // dem Start. Wer die Prüfuhr vorher weiterstellt, stempelt auf die neue
  // Zeit -- die Uhr stünde dann bei voller Dauer, und die Probe hielte das
  // für einen Neustart.
  await b.ev(bild);
  await uhrAuf(30000);
  // Eine Wiederholung, wie die Tastatur sie schickt: derselbe Anschlag mit
  // `autoRepeat`. Sie darf die Uhr nicht auf 02:00 zurückwerfen.
  await b.ruf("Input.dispatchKeyEvent", { type: "keyDown", key: "2", text: "2",
    windowsVirtualKeyCode: 50, autoRepeat: true });
  await b.ruf("Input.dispatchKeyEvent", { type: "keyUp", key: "2" });
  await b.ev(bild);
  s = await lies();
  if (s.text !== "01:30") {
    klagen.push("8. eine gehaltene `2` warf die Uhr auf " + JSON.stringify(s.text)
                + " statt sie bei 01:30 zu lassen");
  }
  await b.taste("0"); await b.ev(bild);

  // ── 6: verdunkeln ────────────────────────────────────────────────────────
  await b.ev("typstage.pruef.uhr(0)"); await b.ev(bild);
  await b.taste("5"); await b.ev(bild);
  await b.ev(`document.documentElement.dataset.tsSchwarz = "1"`);
  await b.ev(bild);
  s = await lies();
  if (s.deckung === "0") klagen.push("6. die angeheftete Uhr verschwand bei schwarz");
  await b.ev(`delete document.documentElement.dataset.tsSchwarz`);
  await b.ev(bild);
  // Und die Vollbilduhr verschwindet weiterhin.
  await b.taste("0"); await b.ev(bild);
  await b.ev("typstage.clock.start(300)"); await b.ev(bild);
  await b.ev(`document.documentElement.dataset.tsSchwarz = "1"`);
  await b.ev(bild);
  s = await lies();
  if (s.deckung !== "0") {
    klagen.push("6. die Vollbilduhr blieb bei schwarz stehen (opacity "
                + s.deckung + ") -- sie deckt den Saal zu und muss weichen");
  }
  await b.ev(`delete document.documentElement.dataset.tsSchwarz; typstage.clock.stop()`);

  // ── 4: die cue-Folie besitzt ihre Ziffern ───────────────────────────────
  await b.navigiere("file://" + mitCue);
  await schlaf(2000);
  await b.ev("typstage.pruef.uhr(0)"); await b.ev(bild);
  // Auf die Folie mit der Gruppe. Gesucht wird sie und nicht gezählt: eine
  // Titelfolie steht davor, und ein fest verdrahteter Index misst am Ende die
  // falsche Folie -- genau daran hat diese Probe sich schon einmal selbst
  // belogen.
  const aufCue = JSON.parse(await b.ev(`(function(){
    function mitGruppe(i) {
      return typstage.slides[i].querySelectorAll('[data-ad],[data-ad-nr]').length;
    }
    var mit = -1, ohne = -1;
    for (var i = 0; i < typstage.slides.length; i++) {
      if (mitGruppe(i)) { if (mit < 0) mit = i; } else if (ohne < 0) ohne = i;
    }
    function schrittAuf(f) {
      for (var k = 0; k < typstage.steps.length; k++) {
        if (typstage.steps[k].slide === f) return k;
      }
      return -1;
    }
    return JSON.stringify({ mit: mit, ohne: ohne,
                            schrittMit: schrittAuf(mit), schrittOhne: schrittAuf(ohne) });
  })()`));
  if (aufCue.mit < 0) {
    klagen.push("4. im Probedeck war keine cue-Gruppe zu finden -- die Probe"
                + " misst dann nichts");
  }
  await b.ev("typstage.goto(" + aufCue.schrittMit + ", true)"); await b.ev(bild);
  // Eine Ziffer jenseits der Punktzahl: `9` gibt es in der Gruppe nicht.
  await b.taste("9"); await b.ev(bild);
  s = await lies();
  if (s.an) {
    klagen.push("4. `9` startete auf einer cue-Folie eine Uhr -- jenseits der"
                + " Punktzahl gibt `adTaste` false, und ein Durchfall nach"
                + " false wäre genau hier falsch");
  }
  // Derselbe Punkt zweimal. Der zweite Druck ist ausdrücklich folgenlos.
  await b.taste("1"); await b.ev(bild);
  await b.taste("1"); await b.ev(bild);
  s = await lies();
  if (s.an) klagen.push("4. der zweite Druck auf `1` startete auf einer cue-Folie eine Uhr");
  // Auf der Folie ohne Gruppe geht die Ziffer wieder an die Uhr.
  await b.ev("typstage.goto(" + aufCue.schrittOhne + ", true); typstage.pruef.uhr(0)");
  await b.ev(bild);
  await b.taste("4"); await b.ev(bild);
  s = await lies();
  if (!s.an || s.text !== "04:00") {
    klagen.push("4. auf der Folie OHNE Gruppe stellte `4` keine Uhr ("
                + JSON.stringify(s.text) + ")");
  }
  await b.taste("0"); await b.ev(bild);

  // ── 5: das Raster ───────────────────────────────────────────────────────
  await b.navigiere("file://" + gerastert);
  await schlaf(2000);
  await b.ev("typstage.goto(0, true); typstage.pruef.uhr(0)"); await b.ev(bild);
  await b.taste("5"); await b.ev(bild);
  const rasterfaelle = [
    [0,      "05:00", "Startwert"],
    [1,      "05:00", "der erste Tick darf keine Stufe verbrauchen"],
    [1000,   "05:00", "nach einer Sekunde bleibt der Startwert"],
    [4999,   "05:00", "unmittelbar vor der ersten Grenze"],
    [5000,   "04:55", "erst nach vollen fünf Sekunden"],
    [5001,   "04:55", "unmittelbar nach der Grenze"],
    [9999,   "04:55", "unmittelbar vor der zweiten Grenze"],
    [10000,  "04:50", "nach zehn Sekunden"],
    [285000, "00:15", "kurz vor Schluss, noch gerastert"],
    [292000, "00:10", "acht Sekunden Rest gehören zur Zehneranzeige"],
    [294999, "00:10", "kurz vor dem letzten Intervall"],
    [295000, "00:05", "Beginn des letzten Intervalls"],
    [295999, "00:05", "erst nach einer ganzen Sekunde herunterzählen"],
    [296000, "00:04", "letzte Sekunden einzeln"],
    [296500, "00:04", "keine vorzeitige Sekundenanzeige"],
    [297000, "00:03", "und weiter einzeln"],
    [298000, "00:02", "jede Sekunde einzeln"],
    [299999, "00:01", "bis zum tatsächlichen Ablauf bleibt Restzeit"],
    [300000, "00:00", "null"],
    [300001, "+00:00", "Überzeit startet ohne vorgezogene Stufe"],
    [304999, "+00:00", "noch keine fünf Sekunden Überzeit"],
    [305000, "+00:05", "fünf volle Sekunden Überzeit"],
  ];
  for (const [ms, soll, warum] of rasterfaelle) {
    await uhrAuf(ms);
    s = await lies();
    if (s.text !== soll) {
      klagen.push("5. bei " + ms + " ms stand " + JSON.stringify(s.text)
                  + " statt " + JSON.stringify(soll) + " (" + warum + ")");
    }
  }

  // ── 7: abbestellte Ziffern ──────────────────────────────────────────────
  await b.navigiere("file://" + ohneZiffern);
  await schlaf(2000);
  await b.ev("typstage.goto(0, true); typstage.pruef.uhr(0)"); await b.ev(bild);
  await b.taste("3"); await b.ev(bild);
  s = await lies();
  if (s.an) klagen.push("7. `room: (clock: (digits: false))` ließ die Ziffer trotzdem eine Uhr stellen");

  // ── 9: die Sprecheransicht geht mitten in der Aufgabe auf ───────────────
  //
  // Der heikelste Fall des ganzen Merkmals. Die Buehne führt die Uhr selbst;
  // dann kommt ein Pult dazu, das nichts von ihr weiß, und schickt im
  // Sekundentakt seinen eigenen Stand. Ohne `uhrArt` in der Begrüßung schlüge
  // die angeheftete Uhr auf Vollbild um -- schwarz von Rand zu Rand, mitten in
  // der Gruppenarbeit -- und der nächste Pfeil am Pult löschte sie.
  await b.navigiere("file://" + schlicht);
  await schlaf(2000);
  await b.ev("typstage.goto(0, true); typstage.pruef.uhr(0)");
  await b.ev(bild);
  await b.taste("6");
  await b.ev(bild);
  await uhrAuf(30000);
  const vorPult = await lies();
  if (vorPult.text !== "05:30") {
    klagen.push("9. vor dem Pult stand " + JSON.stringify(vorPult.text) + " statt 05:30");
  }
  await b.taste("n");
  let pult = null;
  try { pult = await b.zweites(40); } catch (e) {
    klagen.push("9. das Sprecherfenster kam nicht (" + e.message + ")");
  }
  if (pult) {
    // Mehrere Herzschläge abwarten: der Abgleich greift erst nach anderthalb
    // Sekunden, und genau danach ginge die Uhr verloren.
    await schlaf(4000);
    s = await lies();
    if (!s.an) klagen.push("9. die Uhr war weg, nachdem die Sprecheransicht aufging");
    if (s.art !== "fest") {
      klagen.push("9. die Uhr schlug auf " + JSON.stringify(s.art)
                  + " um, als die Sprecheransicht aufging");
    }
    if (s.text !== "05:30") {
      klagen.push("9. die Uhr sprang auf " + JSON.stringify(s.text)
                  + " statt bei 05:30 zu bleiben -- sie wurde neu gestempelt");
    }
    // Und das Pult zeichnet dieselbe Uhr, in derselben Art.
    const pultArt = async () => JSON.parse(await pult.ev(`JSON.stringify((function(){
      var c = document.getElementById("ts-clock");
      return { an: !!document.documentElement.dataset.tsClock,
               art: (c && c.dataset.art) || "",
               ziffern: c ? c.querySelector(".ts-clock-num").textContent.trim() : "" };
    })())`));
    let pa = await pultArt();
    if (pa.art !== "fest") {
      klagen.push("9. das Pult zeichnete die übernommene Uhr nicht auf der"
                  + " Folie (art " + JSON.stringify(pa.art) + ")");
    }
    if (pa.ziffern !== "05:30") {
      klagen.push("9. das Pult zeigte " + JSON.stringify(pa.ziffern)
                  + " statt 05:30 -- die beiden Fenster lasen dieselbe Uhr"
                  + " verschieden");
    }

    // Und beide Fenster lesen dieselbe halbe Sekunde gleich. Bei einem Rest
    // von 329,5 s rundete die Bühne ab und das Pult rundete -- 05:29 an der
    // Wand, 05:30 am Pult, auf derselben Folie. Eine ganze Sekunde ging so
    // auseinander, und unter einem groben Schritt wäre daraus eine ganze
    // Stufe geworden. Ein glatter Rest zeigt das nicht: dort sind Abrunden
    // und Runden dasselbe.
    await uhrAuf(30500);
    await schlaf(2500);
    const saalHalb = (await lies()).text;
    const pultHalb = (await pultArt()).ziffern;
    if (saalHalb !== pultHalb) {
      klagen.push("9. bei 329,5 s Rest las der Saal " + JSON.stringify(saalHalb)
                  + " und das Pult " + JSON.stringify(pultHalb)
                  + " -- dieselbe Uhr auf derselben Folie, zwei Zahlen");
    }
    if (saalHalb !== "05:29") {
      klagen.push("9. bei 329,5 s Rest stand " + JSON.stringify(saalHalb)
                  + " statt 05:29 -- eine Uhr rundet ab, sie rundet nicht");
    }

    // Und die `0` im Saal beendet sie weiterhin, obwohl das Pult sie führt.
    await b.taste("0");
    await schlaf(1200);
    s = await lies();
    if (s.an) {
      klagen.push("9. `0` im Saal beendete die Uhr nicht mehr, sobald das Pult"
                  + " sie übernommen hatte");
    }
    // ── 10: eine Vollbilduhr nach einer angehefteten ──────────────────────
    //
    // Das Pult hat gerade „fest" übernommen. Startet der Saal danach eine
    // VOLLBILDuhr -- über die öffentliche Fläche, wie es ein Deck mit eigenem
    // Knopfwerk täte --, muss das Pult auch diese Art nachziehen. Gemessen
    // wird das AM PULT: es zeichnet die angeheftete Uhr selbst nach, und ohne
    // das Nachziehen zeigte es weiter eine Uhr auf der Folie, während im Saal
    // das Vollbild steht -- zwei Fenster, zwei Antworten auf dieselbe Frage.
    await b.ev("typstage.pruef.uhr(0)");
    await b.ev("typstage.clock.start(300)");
    await b.ev(bild);
    await schlaf(2500);
    s = await lies();
    if (!s.an) klagen.push("10. die Vollbilduhr kam gar nicht");
    if (s.art === "fest") {
      klagen.push("10. die Vollbilduhr stand im Saal auf der Folie statt über ihr");
    }
    pa = await pultArt();
    if (pa.art === "fest") {
      klagen.push("10. das Pult zeigte weiter eine Uhr auf der Folie, während"
                  + " im Saal das Vollbild stand -- es zog die Art nicht nach");
    }
    await pult.ende();
  }

  await b.ende();
  if (klagen.length) {
    console.log("Uhr-Ziffern: " + klagen.length + " Punkt(e)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Uhr-Ziffern: in Ordnung");
})();
