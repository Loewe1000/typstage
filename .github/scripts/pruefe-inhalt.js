// pruefe-inhalt.js — springt ein Inhaltsverzeichnis wirklich?
//
// `contents()` setzt Verweise auf die Abschnittsfolien, und die Laufzeit muss
// sie auf die Folie umbiegen, die sie enthält. Beides ist im Quelltext nicht
// zu sehen: Typst schreibt interne Ziele als erzeugte DOM-Namen, und ob der
// Klick am Ende auf dem richtigen Schritt landet, sagt nur der Browser.
//
//   node .github/scripts/pruefe-inhalt.js [--browser /pfad]
//
// Geprüft wird beides, hin und zurück, und dazu der anpassbare Rückverweis:
//   1. Ein Klick auf den n-ten Eintrag führt auf die n-te Abschnittsfolie.
//   2. Ein Klick auf "zurück zum Inhalt" führt auf die Folie mit dem
//      Verzeichnis.
//   3. Dasselbe Deck mit `section-back:` trägt weiterhin einen Verweis auf
//      `#typstage-contents`, der Klick landet auf demselben Schritt, und das
//      Rechteck des `<a>` ist ein anderes -- das eigene Wort steht wirklich da.
//
// Zu 3.: gemessen wird die Breite und kein fester Pixelwert. Ein Wort ist in
// der HTML ein Pfad, seine Farbe oder sein Text lassen sich dort nicht lesen;
// wie breit der Verweis trägt, schon. An diesem Deck headless gemessen:
// "Back to contents" 140.2, "Agenda 2" 77.1, beide Klicks von Schritt 2 auf
// Schritt 1. Verglichen werden die beiden Breiten gegeneinander und nicht mit
// einer festen Zahl -- die hinge an Schriftschnitt und Fensterbreite.
//
// Der zweite Punkt ist der, an dem eine Prüfung von Hand scheitert: steht man
// schon auf der Inhaltsfolie, bewegt sich nichts, und der Verweis sieht kaputt
// aus, obwohl er stimmt. Genau darauf bin ich beim ersten Versuch
// hereingefallen.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

const RUMPF = `

== Inhalt
#contents()

= Erster Teil
== Eine Folie
Text.
= Zweiter Teil
== Noch eine
Text.
= Dritter Teil
== Und noch eine
Text.
`;
const KOPF = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(theme: themes.night, title: [Inhalt]`;
const DECK = KOPF + ")" + RUMPF;
// Die Funktionsform, weil sie am meisten zusagt: sie bekommt `location` und
// `contents.number` und baut ihr eigenes `link` daraus. Führt das noch auf das
// Verzeichnis, führen die einfacheren Formen erst recht.
const DECK_EIGEN = KOPF
  + ",\n  section-back: b => link(b.location)[Agenda #b.contents.number])"
  + RUMPF;

const schritt = "window.typstage.state()";
const klick = h => `(function(){
  var a=[].slice.call(document.querySelectorAll('a'))
    .filter(function(x){return (x.getAttribute('href')||'')===${JSON.stringify(h)};});
  if(!a.length) return false;
  a[0].dispatchEvent(new MouseEvent('click',{bubbles:true,cancelable:true}));
  return true;})()`;

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-inhalt-"));
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-inhalt-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.2.0"));
  }
  const uebersetze = (name, quelle) => {
    fs.writeFileSync(path.join(tmp, name + ".typ"), quelle);
    try {
      execFileSync("typst", ["compile", "--format", "html", "--features", "html",
        "--package-path", paket, "--root", tmp,
        path.join(tmp, name + ".typ"), path.join(tmp, name + ".html")],
        { stdio: ["ignore", "ignore", "pipe"] });
    } catch (e) {
      const wort = String((e.stderr || "")).split("\n")
        .find(z => z.startsWith("error:")) || "unbekannter Fehler";
      console.log("Inhalt: das Probedeck " + name + " übersetzt nicht -- " + wort);
      process.exit(1);
    }
    return "file://" + path.join(tmp, name + ".html");
  };
  const wegVorgabe = uebersetze("deck", DECK);
  const wegEigen = uebersetze("deck-eigen", DECK_EIGEN);

  const b = await starte(CHROME);
  const klagen = [];
  await b.navigiere(wegVorgabe);
  await schlaf(2500);
  await b.taste("ArrowRight");
  await schlaf(900);
  const aufInhalt = await b.ev(schritt);

  // 1. Hin: der dritte Eintrag
  if (!await b.ev(klick("#typstage-slide-target-3"))) {
    klagen.push("kein Verweis auf die dritte Abschnittsfolie. `contents()` "
      + "setzt sie als <typstage-slide-target>; fehlt der Verweis, ist das "
      + "Verzeichnis eine Liste ohne Ziel.");
  } else {
    await schlaf(1200);
    const dort = await b.ev(schritt);
    const soll = await b.ev(`(function(){
      var ziel=document.getElementById('typstage-slide-target-3');
      var folie=ziel&&ziel.closest('.ts-slide');
      if(!folie) return -1;
      var nr=window.typstage.slides.indexOf(folie);
      var s=window.typstage.steps;
      for(var k=0;k<s.length;k++) if(s[k].slide===nr&&s[k].step===1) return k;
      return -1;})()`);
    if (dort !== soll) {
      klagen.push("der Klick auf den dritten Eintrag landet auf Schritt "
        + dort + " statt auf " + soll + ". Die Laufzeit biegt interne Ziele "
        + "auf die Folie um, die sie enthält -- greift das nicht, bleibt der "
        + "Vortrag stehen, wo er war.");
    }
  }

  // 2. Zurück
  if (!await b.ev(klick("#typstage-contents"))) {
    klagen.push("kein Rückverweis auf das Verzeichnis.");
  } else {
    await schlaf(1200);
    const zurueck = await b.ev(schritt);
    if (zurueck !== aufInhalt) {
      klagen.push("der Rückverweis landet auf Schritt " + zurueck
        + " statt auf " + aufInhalt + ".");
    }
  }

  // 3. Derselbe Rückverweis, vom Deck selbst gesetzt.
  //
  // Die Breite des `<a>` steht in beiden Decks für das Wort darin: das eine
  // trägt "Back to contents", das andere "Agenda 2". Sind sie gleich breit,
  // hat `section-back` nichts bewirkt -- und das wäre die stille Art zu
  // versagen, denn der Verweis funktionierte dann ja weiter.
  const massEigen = async weg => {
    await b.navigiere(weg);
    await schlaf(2500);
    await b.taste("ArrowRight");
    await schlaf(900);
    const aufVerzeichnis = await b.ev(schritt);
    await b.taste("ArrowRight");
    await schlaf(900);
    const breite = await b.ev(`(function(){
      var f=window.typstage.slides[window.typstage.steps[window.typstage.state()].slide];
      var a=f.querySelector('a[href="#typstage-contents"]');
      if(!a) return -1;
      var r=a.getBoundingClientRect();
      return Math.round(r.width*10)/10;})()`);
    let gelandet = -1;
    if (breite >= 0 && await b.ev(klick("#typstage-contents"))) {
      await schlaf(1200);
      gelandet = await b.ev(schritt);
    }
    return { aufVerzeichnis, breite, gelandet };
  };
  const vorgabe = await massEigen(wegVorgabe);
  const eigen = await massEigen(wegEigen);
  if (eigen.breite < 0) {
    klagen.push("mit `section-back: b => link(b.location)[…]` trägt die "
      + "Abschnittsfolie keinen Verweis auf #typstage-contents mehr. Das "
      + "Paket behält das äußere `link`, der Wert gibt nur den Körper.");
  } else {
    if (eigen.gelandet !== eigen.aufVerzeichnis) {
      klagen.push("der eigene Rückverweis landet auf Schritt "
        + eigen.gelandet + " statt auf " + eigen.aufVerzeichnis + ".");
    }
    if (vorgabe.breite >= 0 && Math.abs(eigen.breite - vorgabe.breite) < 0.5) {
      klagen.push("der eigene Rückverweis ist so breit wie der vorgegebene ("
        + eigen.breite + " gegen " + vorgabe.breite + " Punkte) -- "
        + "`section-back` setzt das Wort nicht.");
    }
  }

  await b.ende();
  fs.rmSync(tmp, { recursive: true, force: true });
  fs.rmSync(paket, { recursive: true, force: true });

  if (klagen.length) {
    console.log("Inhalt: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Inhalt: der Sprung geht hin und zurück");
})().catch(e => { console.error(e); process.exit(1); });
