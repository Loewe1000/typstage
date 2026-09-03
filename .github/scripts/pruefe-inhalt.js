// pruefe-inhalt.js — springt ein Inhaltsverzeichnis wirklich?
//
// `contents()` setzt Verweise auf die Abschnittsfolien, und die Laufzeit muss
// sie auf die Folie umbiegen, die sie enthält. Beides ist im Quelltext nicht
// zu sehen: Typst schreibt interne Ziele als erzeugte DOM-Namen, und ob der
// Klick am Ende auf dem richtigen Schritt landet, sagt nur der Browser.
//
//   node .github/scripts/pruefe-inhalt.js [--browser /pfad]
//
// Geprüft wird beides, hin und zurück:
//   1. Ein Klick auf den n-ten Eintrag führt auf die n-te Abschnittsfolie.
//   2. Ein Klick auf "zurück zum Inhalt" führt auf die Folie mit dem
//      Verzeichnis.
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

const DECK = `#import "@preview/typstage:0.1.1": *
#show: presentation.with(theme: themes.night, title: [Inhalt])

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
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.1.1"));
  }
  fs.writeFileSync(path.join(tmp, "deck.typ"), DECK);
  try {
    execFileSync("typst", ["compile", "--format", "html", "--features", "html",
      "--package-path", paket, "--root", tmp,
      path.join(tmp, "deck.typ"), path.join(tmp, "deck.html")],
      { stdio: ["ignore", "ignore", "pipe"] });
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Inhalt: das Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  const klagen = [];
  await b.navigiere("file://" + path.join(tmp, "deck.html"));
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
