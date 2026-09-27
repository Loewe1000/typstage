// pruefe-video-frist.js — endet ein Video in dem Augenblick, in dem die
// Stunde beginnt?
//
// Vor der Stunde läuft ein Musikvideo. Es soll nicht zu einer Uhrzeit
// *anfangen*, sondern zu einer *aufhören*: gerechnet wird, wie weit es schon
// gelaufen sein müsste, und dort setzt die Laufzeit es ein.
//
//   node .github/scripts/pruefe-video-frist.js [--browser /pfad]
//
// Eigens im Browser: die Dauer eines Videos kennt keine Datei, die Typst
// sieht -- sie steht erst mit den Metadaten fest, und vorher verpufft jedes
// `currentTime`. Und eigens mit festgenagelter Wanduhr (`pruef.wanduhr`),
// sonst hinge jede Messung daran, wie spät es beim Lauf gerade ist.
//
// Geprüft wird:
//   1. Die Frist liegt innerhalb des Videos: es steht auf `Dauer − Rest` und
//      läuft. Genau das ist der Fall, um den es geht.
//   2. Die Frist liegt weiter weg, als das Video lang ist: es wartet auf
//      seinem ersten Bild, pausiert. Das ist ein anderer Zustand als eine
//      verpasste Frist und muss von ihr zu unterscheiden sein.
//   3. Weiter als eine Stunde weg: kein Plan, das Video spielt von vorn.
//      Der Deckel erschlägt zwei Fälle -- über Nacht stehengeblieben, und
//      eine Minute zu spät geöffnet, wo „nächstes Eintreten" 23 Stunden hieße.
//   4. `ends-at: auto` nimmt die Zeit aus `room: (bell: …)`.
//   5. Verdunkeln und zurück stellt NEU statt fortzusetzen: vierzig Sekunden
//      Schwarz verschöben das Ende sonst um vierzig Sekunden.
//   6. Ein Video ohne Frist verhält sich wie zuvor -- es spielt von vorn.
//   7. Gestellt wird erst, wenn das Video zu sehen ist: ein `at: "2-"` läuft
//      nicht ab Schritt 1 unsichtbar mit.
//   8. Ein Video, dem die Metadaten frisch weggenommen wurden, steht am Ende
//      trotzdem richtig.
//   9. Über Mitternacht hinweg zählt der Rest vorwärts und nicht rückwärts.
//  10. Ein Plan, der das Video mitten hinein gestellt hat, gilt nach dem
//      Verlassen der Folie nicht weiter: wer um 08:14 wegblättert und um
//      08:16 zurückkommt, sieht es von vorn und nicht dort, wo es stand.
//  11. Ohne Plan gilt dasselbe: wer um 09:00 mitten im Video wegblättert und
//      um 09:01 zurückkommt, sieht es von vorn -- so, wie die Folie und das
//      Handbuch es sagen („at any other time it plays from the start").
//
// NICHT geprüft, und zwar wissentlich -- zwei Stellen, die ein Browserlauf
// nicht erreicht:
//
//   • Der Zweig, der auf `loadedmetadata` wartet. Punkt 8 nimmt die Metadaten
//     weg (neuer Abfragestring, `load()`), aber eine lokale Datei liefert sie
//     im nächsten Bild schon wieder: `readyState` steht dann auf 1, bevor
//     `fristStellen` überhaupt hinsieht. Gemessen -- der Zweig entfernt, die
//     Probe blieb grün. Über `file://` gibt es keine Drosselung, die das
//     ändern könnte. Der Zweig bleibt trotzdem: er kostet nichts, und ohne ihn
//     verpufft jedes `currentTime` auf einem langsam ladenden Video.
//
//   • Die beiden Zeitumstellungstage. Der Zielaugenblick entsteht
// über `setHours` und nicht über Mitternacht plus Sekunden -- der zweite Weg
// wäre an diesen Tagen genau eine Stunde falsch. Ein Lauf kann das nicht
// sehen: die CI steht auf UTC, wo es keine Umstellung gibt, und eine Probe,
// die auf dem Entwicklungsrechner grün und in der CI bedeutungslos ist, sagt
// weniger als dieser Satz.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

// Sechzig Sekunden Testbild. Lang genug, dass „Frist im Video" und „Frist
// dahinter" weit auseinanderliegen, klein genug für einen Prüflauf.
const SEKUNDEN = 60;

const DECK = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  theme: themes.lesson, title: [Frist],
  room: (bell: "08:15"),
)

== Feste Zeit
#video("probe.mp4", width: 100%, height: 200pt, ends-at: "08:15")

== Aus der Glocke
#video("probe.mp4", width: 100%, height: 200pt, ends-at: auto)

== Ohne Frist
#video("probe.mp4", width: 100%, height: 200pt)

== Erst später
Ein Satz.
#pause
#video("probe.mp4", width: 100%, height: 200pt, ends-at: "08:15", at: "2-")
`;

// 8:15 an einem Tag ohne Zeitumstellung, als Zeitstempel der Ortszeit.
function um(stunde, minute, sekunde) {
  const d = new Date(2026, 5, 15, stunde, minute, sekunde || 0, 0);
  return d.getTime();
}

function bauen(paket, ordner) {
  execFileSync("ffmpeg", ["-y", "-f", "lavfi", "-i",
    `testsrc=size=320x180:rate=15:duration=${SEKUNDEN}`,
    "-pix_fmt", "yuv420p", path.join(ordner, "probe.mp4")],
    { stdio: ["ignore", "ignore", "pipe"] });
  fs.writeFileSync(path.join(ordner, "frist.typ"), DECK);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", ordner,
    path.join(ordner, "frist.typ"), path.join(ordner, "frist.html")],
    { stdio: ["ignore", "ignore", "pipe"] });
  return path.join(ordner, "frist.html");
}

(async () => {
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-frist-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.2.0"));
  }
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-frist-"));
  let deck;
  try {
    deck = bauen(paket, ordner);
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || String(e.message).slice(0, 120);
    console.log("Video-Frist: das Probedeck entsteht nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  const klagen = [];
  const bild = `new Promise(function(f){
    requestAnimationFrame(function(){ requestAnimationFrame(f); });
  })`;
  // Auf die Folie, die Wanduhr stellen, ein paar Bilder warten -- das Stellen
  // wartet auf `loadedmetadata`, und das kommt nicht im selben Bild.
  const stellen = async (schritt, ms) => {
    // Erst weg, dann hin. Ein `goto` auf die Folie, auf der man ohnehin
    // steht, löst kein `mediaOff`/`mediaOn` aus -- es rechnete dann nichts
    // neu, und die Probe maß den Stand der vorigen Frage. Genau daran hat sie
    // sich schon einmal selbst belogen.
    await b.ev(`typstage.goto(0, true)`);
    await b.ev(bild);
    await schlaf(150);
    await b.ev(`typstage.pruef.wanduhr(${ms})`);
    await b.ev(`typstage.goto(${schritt}, true)`);
    await b.ev(bild);
    await schlaf(700);
    return JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.video())`));
  };
  const nah = (a, b2, eps) => a != null && Math.abs(a - b2) <= (eps || 1.2);

  await b.navigiere("file://" + deck);
  await schlaf(2500);
  // Welcher Schritt gehört zu welcher Folie? Die Titelfolie zählt mit.
  const folien = JSON.parse(await b.ev(`JSON.stringify(
    typstage.steps.map(function(s){ return s.slide; }))`));
  const ersterSchritt = (f) => folien.indexOf(f);

  // ── 1: die Frist liegt im Video ─────────────────────────────────────────
  // 08:14:50 -- zehn Sekunden vor der Glocke, das Video ist sechzig lang.
  let v = await stellen(ersterSchritt(1), um(8, 14, 50));
  if (!v.length) klagen.push("1. kein Fristvideo aufgenommen");
  else {
    if (v[0].lage !== "laeuft") klagen.push("1. Lage " + JSON.stringify(v[0].lage) + " statt \"laeuft\"");
    if (!nah(v[0].stand, SEKUNDEN - 10)) {
      klagen.push("1. das Video stand bei " + v[0].stand + " statt bei rund "
                  + (SEKUNDEN - 10) + " (Dauer " + v[0].dauer + ", Rest " + v[0].rest + ")");
    }
  }

  // ── 2: die Frist liegt hinter dem Video ─────────────────────────────────
  v = await stellen(ersterSchritt(1), um(8, 10, 0));   // fünf Minuten vorher
  if (v.length) {
    if (v[0].lage !== "wartet") klagen.push("2. Lage " + JSON.stringify(v[0].lage) + " statt \"wartet\"");
    if (!nah(v[0].stand, 0, 0.5)) klagen.push("2. das wartende Video stand bei " + v[0].stand + " statt bei 0");
  }

  // ── 3: weiter als eine Stunde weg ───────────────────────────────────────
  v = await stellen(ersterSchritt(1), um(5, 0, 0));
  if (v.length) {
    if (v[0].lage !== "ohne-frist") klagen.push("3. Lage " + JSON.stringify(v[0].lage) + " statt \"ohne-frist\"");
    if (!nah(v[0].stand, 0, 2)) klagen.push("3. ohne Plan stand das Video bei " + v[0].stand + " statt am Anfang");
    // Und es LÄUFT. Ohne diese Zeile misst die Probe nur `lage`, und `lage`
    // rechnet den Deckel ein zweites Mal -- die Regel prüfte sich dann selbst
    // statt das Verhalten. Ohne Deckel wartete das Video hier stumm.
    if (v[0].pausiert) {
      klagen.push("3. ohne Plan stand das Video still, statt von vorn zu"
                  + " spielen -- eine Frist jenseits des Deckels ist kein Plan");
    }
  }

  // ── 4: auto nimmt die Glocke ────────────────────────────────────────────
  v = await stellen(ersterSchritt(2), um(8, 14, 30));
  if (!v.length) klagen.push("4. `ends-at: auto` wurde nicht aufgenommen");
  else {
    if (v[0].endsAt !== "auto") klagen.push("4. das Attribut lautet " + JSON.stringify(v[0].endsAt));
    if (!nah(v[0].stand, SEKUNDEN - 30)) {
      klagen.push("4. `auto` ergab Stand " + v[0].stand + " statt rund "
                  + (SEKUNDEN - 30) + " -- die Glocke wurde nicht gelesen");
    }
  }

  // ── 5: verdunkeln und zurück stellt neu ─────────────────────────────────
  //
  // Mit zwei Fenstern, weil `b` am Pult liegt und `schwarzMedien` nur über den
  // `sicht`-Kanal erreichbar ist. Von Hand gesetzte Attribute führen an dem
  // Weg vorbei, um den es geht: die Probe maß dann den Attributwechsel und
  // nicht das Wiederanlaufen.
  v = await stellen(ersterSchritt(1), um(8, 14, 50));
  const vorSchwarz = v.length ? v[0].stand : null;
  await b.taste("n");
  let pult = null;
  try { pult = await b.zweites(40); } catch (e) {
    klagen.push("5. das Sprecherfenster kam nicht (" + e.message + ")");
  }
  if (pult) {
    await schlaf(2500);
    await pult.taste("b");                       // Saal schwarz
    await schlaf(800);
    const schwarz = JSON.parse(await b.ev(`JSON.stringify((function(){
      var v = document.querySelector("#ts-stage video");
      return { schwarz: !!document.documentElement.dataset.tsSchwarz,
               pausiert: v ? v.paused : null };
    })())`));
    if (!schwarz.schwarz) klagen.push("5. `b` am Pult verdunkelte den Saal nicht");
    if (schwarz.pausiert === false) klagen.push("5. das Video lief im schwarzen Saal weiter");
    // Zwanzig Sekunden Schwarz. Danach steht die Glocke dreißig Sekunden
    // entfernt, das Video muss also bei Dauer minus dreißig wieder einsetzen
    // und nicht dort, wo es angehalten wurde.
    await b.ev(`typstage.pruef.wanduhr(${um(8, 14, 30)})`);
    await pult.taste("b");                       // Saal wieder hell
    await schlaf(900);
    v = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.video())`));
    if (v.length && !nah(v[0].stand, SEKUNDEN - 30, 2)) {
      klagen.push("5. nach dem Verdunkeln stand das Video bei " + v[0].stand
                  + " statt bei rund " + (SEKUNDEN - 30)
                  + " (vorher " + vorSchwarz + ") -- es wurde fortgesetzt statt neu gestellt");
    }
    await pult.ende();
  }

  // ── 6: ein Video ohne Frist ─────────────────────────────────────────────
  await b.ev(`typstage.goto(${ersterSchritt(3)}, true)`);
  await b.ev(bild);
  await schlaf(700);
  const ohne = JSON.parse(await b.ev(`JSON.stringify((function(){
    var v = typstage.slides[3].querySelector("video");
    return { stand: v ? v.currentTime : null, pausiert: v ? v.paused : null,
             fristen: typstage.pruef.video().length };
  })())`));
  if (ohne.fristen !== 0) klagen.push("6. ein Video ohne Frist wurde als Fristvideo geführt");
  if (ohne.pausiert) klagen.push("6. ein Video ohne Frist lief nicht an");

  // ── 7: erst wenn es zu sehen ist ────────────────────────────────────────
  await b.ev(`typstage.pruef.wanduhr(${um(8, 14, 50)})`);
  await b.ev(`typstage.goto(${ersterSchritt(4)}, true)`);
  await b.ev(bild);
  await schlaf(700);
  v = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.video())`));
  if (!v.length) klagen.push("7. das späte Video wurde gar nicht aufgenommen");
  else if (v[0].gestellt) {
    klagen.push("7. ein `at: \"2-\"`-Video wurde schon auf Schritt 1 gestellt"
                + " -- es liefe unsichtbar mit, und die Rechnung wäre falsch,"
                + " bevor jemand sie sieht");
  }
  await b.ev(`typstage.goto(${ersterSchritt(4) + 1}, true)`);
  await b.ev(bild);
  await schlaf(700);
  v = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.video())`));
  if (v.length && !v[0].gestellt) {
    klagen.push("7. nach dem Aufdecken wurde das späte Video nicht gestellt");
  }

  // ── 8: die Dauer steht erst mit den Metadaten fest ──────────────────────
  //
  // Ein `currentTime` vor `loadedmetadata` verpufft: `duration` ist dann NaN.
  // `load()` wirft die Metadaten weg und stellt genau den Augenblick her, in
  // dem ein frisch geöffnetes Deck steht.
  await b.ev(`typstage.goto(0, true)`);
  await b.ev(bild);
  await schlaf(200);
  await b.ev(`typstage.pruef.wanduhr(${um(8, 14, 50)})`);
  await b.ev(`(function(){
    var v = typstage.slides[1].querySelector("video");
    // Ein neuer Abfragestring statt eines bloßen \`load()\`: den holt der
    // Browser aus seinem Zwischenspeicher zurück, und \`readyState\` steht im
    // nächsten Bild schon wieder auf 1 -- die Probe maß dann nichts.
    v.src = v.getAttribute("src").split("?")[0] + "?frisch=" + Date.now();
    v.load();
    typstage.goto(${ersterSchritt(1)}, true);
    return 1;
  })()`);
  await b.ev(bild);
  await schlaf(1500);
  v = JSON.parse(await b.ev(`JSON.stringify(typstage.pruef.video())`));
  if (v.length && !nah(v[0].stand, SEKUNDEN - 10, 2)) {
    klagen.push("8. ohne geladene Metadaten verpuffte das Stellen: Stand "
                + v[0].stand + " statt rund " + (SEKUNDEN - 10)
                + " -- vor `loadedmetadata` ist `duration` NaN");
  }

  // ── 9: über Mitternacht hinweg ──────────────────────────────────────────
  //
  // Zehn vor Mitternacht, Glocke um 00:05: der Rest sind fünfzehn Minuten und
  // nicht minus dreiundzwanzigeinhalb Stunden. Ein Rest ohne Überlauf wäre
  // negativ, und das Video stünde von vorn da, als gäbe es keinen Plan.
  const restUm = async (jetztMs, glocke) => JSON.parse(await b.ev(
    `JSON.stringify((function(){
       typstage.pruef.wanduhr(${jetztMs});
       var f = typstage.pruef.video();
       return f.length ? f[0].rest : null;
     })())`));
  await b.ev(`typstage.goto(${ersterSchritt(1)}, true)`);
  await b.ev(bild);
  await schlaf(300);
  const ueberMitternacht = await restUm(um(23, 50, 0));
  if (ueberMitternacht == null) {
    klagen.push("9. kein Fristvideo, um den Überlauf zu messen");
  } else if (!nah(ueberMitternacht, 8 * 3600 + 25 * 60, 2)) {
    // 23:50 bis 08:15 am nächsten Morgen sind 8 h 25 min.
    klagen.push("9. von 23:50 bis zur Glocke um 08:15 kamen "
                + Math.round(ueberMitternacht) + " s heraus statt "
                + (8 * 3600 + 25 * 60) + " -- der Überlauf über Mitternacht fehlt");
  }

  // ── 10: Plan, weg, zurück ohne Plan ─────────────────────────────────────
  //
  // Um 08:14:50 stellt der Plan das Video auf Dauer minus zehn und lässt es
  // laufen. Dann weg von der Folie -- `mediaOff` hält es an und spult nicht
  // zurück -- und um 08:16 wieder hin: dreiundzwanzig Stunden bis zur
  // nächsten Glocke sind kein Plan, das Video muss von vorn spielen. Punkt 3
  // sah das nicht: vor ihm stellt Punkt 2 das Video auf sein erstes Bild,
  // und ein Video, das dort steht, spielt ohnehin von vorn.
  v = await stellen(ersterSchritt(1), um(8, 14, 50));
  const mitten = v.length ? v[0].stand : null;
  if (!v.length || v[0].lage !== "laeuft" || !nah(mitten, SEKUNDEN - 10)) {
    klagen.push("10. der Plan stellte das Video nicht mitten hinein (Stand "
                + mitten + ") -- der Rest dieses Punkts misst dann nichts");
  } else {
    v = await stellen(ersterSchritt(1), um(8, 16, 0));
    if (v.length) {
      if (v[0].lage !== "ohne-frist") klagen.push("10. Lage " + JSON.stringify(v[0].lage) + " statt \"ohne-frist\"");
      if (!nah(v[0].stand, 0, 2)) {
        klagen.push("10. um 08:14:50 bei " + mitten.toFixed(1) + " gestellt, weggeblättert,"
                    + " um 08:16 zurück: Stand " + v[0].stand.toFixed(1) + " statt am Anfang"
                    + " -- der verworfene Plan lief weiter");
      }
      if (v[0].pausiert) klagen.push("10. zurück ohne Plan stand das Video still, statt von vorn zu spielen");
    }
  }

  // ── 11: ohne Plan, weg, zurück ohne Plan ────────────────────────────────
  //
  // Um 09:00 kein Plan: das Video spielt von vorn. Anderthalb Sekunden
  // später weg und um 09:01 wieder hin. Gemessen nach dem Warten in
  // `stellen`: die Laufzeit, die fortsetzte, stand bei 3,7 Sekunden, die
  // behobene steht bei 0,7.
  v = await stellen(ersterSchritt(1), um(9, 0, 0));
  await schlaf(1500);
  v = await stellen(ersterSchritt(1), um(9, 1, 0));
  if (v.length) {
    if (v[0].lage !== "ohne-frist") klagen.push("11. Lage " + JSON.stringify(v[0].lage) + " statt \"ohne-frist\"");
    if (!nah(v[0].stand, 0, 1.5)) {
      klagen.push("11. um 09:00 ohne Plan gespielt, weggeblättert, um 09:01 zurück: Stand "
                  + v[0].stand.toFixed(1) + " statt am Anfang -- ohne Plan setzte es fort");
    }
    if (v[0].pausiert) klagen.push("11. zurück ohne Plan stand das Video still, statt von vorn zu spielen");
  }

  await b.ende();
  if (klagen.length) {
    console.log("Video-Frist: " + klagen.length + " Punkt(e)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Video-Frist: in Ordnung");
})();
