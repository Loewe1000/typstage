// pruefe-klang.js — spielt eine Taste einen Klang, und zwar im Saal?
//
// Das Deck sagt, welche Taste welchen Klang spielt (`room: (sounds: (a:
// "airhorn.mp3"))`); die Laufzeit bringt keinen mit. Gehört wird er im Saal
// und nur dort: am Pult sitzt der Vortragende vor dem Gerät, im Raum steht die
// Anlage, und zweimal zu hören ist der Ton nie.
//
//   node .github/scripts/pruefe-klang.js [--browser /pfad]
//
// Eigens im Browser und eigens mit zwei Fenstern: ob der Ton im richtigen
// Fenster landet, sagt keine Datei. Der Befehl fährt über eine eigene
// Nachrichtenart und nicht über den Zustandskanal -- stünde er dort, gongte es
// bei jedem Wiederanmelden, und genau das kann nur ein Lauf mit zwei Fenstern
// sehen.
//
// Geprüft wird:
//   1. Der Tonknoten steht im Chrom, mit Taste und Datei.
//   2. Die Taste spielt ihn im Bühnenfenster.
//   3. Eine nicht angemeldete Taste tut nichts.
//   4. Am Pult gedrückt spielt er im SAAL und nicht am Pult.
//   5. Ein Wiederanmelden gongt nicht nach: der Befehl reist nicht im
//      Zustandskanal mit.
//   6. Eine fehlende Tondatei meldet sich beim Laden und nicht erst, wenn
//      jemand die Taste drückt.
//   7. Die Taste steht in der Tastenleiste -- sie kommt aus dem Deck, der
//      übersetzte Hilfetext kann sie nicht kennen.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

const DECK = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  theme: themes.lesson, title: [Klang],
  room: (sounds: (a: "ton.wav")),
)

== Erste Folie
Ein Satz.
#speaker-note[Eine Notiz, damit die Ansicht etwas zu zeigen hat.]
== Zweite Folie
Noch einer.
`;

// Eine Folie mit einer eigenen Aufnahme UND einer Klangtaste. `k` soll die
// Aufnahme umschalten und den Klang der Taste hoechstens anhalten -- nie
// wieder anwerfen. Gemeldet am Rundgang (Folie 38): nach `a` startete jedes
// `k`, das abspielte, beide, und jedes weitere wieder beide.
const DECK_BEIDE = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  theme: themes.lesson, title: [Beide],
  room: (sounds: (a: "ton.wav")),
)

== Eine Aufnahme
#audio("aufnahme.wav")
`;

const DECK_FEHLT = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  theme: themes.lesson, title: [Fehlt],
  room: (sounds: (a: "gibt-es-nicht.wav")),
)

== Erste Folie
Ein Satz.
`;

// Eine gültige, hörbare halbe Sekunde: 8000 Hz, 8 Bit, ein Sägezahn. Klein
// genug, um im Quelltext zu stehen, und echt genug, dass der Browser sie
// abspielt statt sie als beschädigt abzulehnen.
function tonDatei(wohin) {
  const rate = 8000, n = rate / 2;
  const kopf = Buffer.alloc(44);
  kopf.write("RIFF", 0); kopf.writeUInt32LE(36 + n, 4); kopf.write("WAVE", 8);
  kopf.write("fmt ", 12); kopf.writeUInt32LE(16, 16); kopf.writeUInt16LE(1, 20);
  kopf.writeUInt16LE(1, 22); kopf.writeUInt32LE(rate, 24);
  kopf.writeUInt32LE(rate, 28); kopf.writeUInt16LE(1, 32);
  kopf.writeUInt16LE(8, 34); kopf.write("data", 36); kopf.writeUInt32LE(n, 40);
  const daten = Buffer.alloc(n);
  for (let i = 0; i < n; i++) daten[i] = (i * 13) % 256;
  fs.writeFileSync(wohin, Buffer.concat([kopf, daten]));
}

function bauen(quelle, name, paket, ordner) {
  fs.writeFileSync(path.join(ordner, name + ".typ"), quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", ordner,
    path.join(ordner, name + ".typ"), path.join(ordner, name + ".html")],
    { stdio: ["ignore", "ignore", "pipe"] });
  return path.join(ordner, name + ".html");
}

const lage = `JSON.stringify((function(){
  var a = document.querySelector("audio.ts-sound");
  var k = typstage.pruef.klang();
  return { da: !!a, taste: a && a.dataset.key, quelle: a && a.getAttribute("src"),
           tasten: k.tasten, zuletzt: k.zuletzt, mal: k.mal,
           laeuft: a ? (!a.paused || a.currentTime > 0) : false,
           fehler: typstage.pruef.fehler().filter(function(z){
             return z.indexOf("Ton") === 0; }) };
})())`;

(async () => {
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-klang-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(raum === "schule" ? path.join(paket, "schule") : path.join(paket, "preview"), "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.2.0"));
  }
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-klang-"));
  tonDatei(path.join(ordner, "ton.wav"));
  tonDatei(path.join(ordner, "aufnahme.wav"));
  let deck, fehlt, beide;
  try {
    deck = bauen(DECK, "klang", paket, ordner);
    fehlt = bauen(DECK_FEHLT, "fehlt", paket, ordner);
    beide = bauen(DECK_BEIDE, "beide", paket, ordner);
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Klang: ein Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  const klagen = [];
  await b.navigiere("file://" + deck);
  await schlaf(2000);

  // ── 1: der Knoten ───────────────────────────────────────────────────────
  let s = JSON.parse(await b.ev(lage));
  if (!s.da) klagen.push("1. kein <audio class=\"ts-sound\"> im Dokument");
  if (s.taste !== "a") klagen.push("1. der Knoten trägt data-key=" + JSON.stringify(s.taste) + " statt \"a\"");
  if (s.quelle !== "ton.wav") klagen.push("1. der Knoten trägt src=" + JSON.stringify(s.quelle));
  if (String(s.tasten) !== "a") klagen.push("1. die Laufzeit kennt die Tasten " + JSON.stringify(s.tasten));

  // ── 2: die Taste spielt ─────────────────────────────────────────────────
  await b.taste("a");
  await schlaf(400);
  s = JSON.parse(await b.ev(lage));
  if (s.mal !== 1) klagen.push("2. `a` spielte nicht (mal=" + s.mal + ")");
  if (s.zuletzt !== "a") klagen.push("2. zuletzt gespielt war " + JSON.stringify(s.zuletzt));
  if (!s.laeuft) klagen.push("2. der Knoten stand nach dem Druck still");

  // ── 3: eine fremde Taste ────────────────────────────────────────────────
  await b.taste("g");
  await schlaf(200);
  s = JSON.parse(await b.ev(lage));
  if (s.mal !== 1) klagen.push("3. eine nicht angemeldete Taste spielte etwas");

  // ── 4 und 5: zwei Fenster ───────────────────────────────────────────────
  await b.taste("n");
  let pult = null;
  try { pult = await b.zweites(40); } catch (e) {
    klagen.push("4. das Sprecherfenster kam nicht (" + e.message + ")");
  }
  if (pult) {
    await schlaf(2500);
    const vorher = JSON.parse(await b.ev(lage)).mal;
    await pult.taste("a");
    await schlaf(600);
    const saal = JSON.parse(await b.ev(lage));
    const amPult = JSON.parse(await pult.ev(`JSON.stringify(typstage.pruef.klang())`));
    if (saal.mal !== vorher + 1) {
      klagen.push("4. am Pult gedrückt kam der Ton im Saal nicht an (mal "
                  + vorher + " → " + saal.mal + ")");
    }
    if (amPult.mal !== 0) {
      klagen.push("4. das Pult spielte selbst mit (mal=" + amPult.mal
                  + ") -- gehört wird er dort, wo die Klasse sitzt");
    }
    // Und er gongt nicht nach. Der Herzschlag fährt jede Sekunde; drei
    // Sekunden sind drei Anmeldungen.
    const stand = JSON.parse(await b.ev(lage)).mal;
    await schlaf(3000);
    const danach = JSON.parse(await b.ev(lage)).mal;
    if (danach !== stand) {
      klagen.push("5. der Ton kam von allein wieder (mal " + stand + " → "
                  + danach + ") -- der Befehl reist im Zustandskanal mit");
    }
    // ── 7: die Taste steht in der Leiste ──────────────────────────────────
    const leiste = await pult.ev(`(function(){
      var k = document.querySelectorAll(".ts-sp-hilfe kbd, .ts-sp-kappe");
      return Array.prototype.map.call(k, function(e){ return e.textContent; }).join(" ");
    })()`);
    if (String(leiste).split(/\s+/).indexOf("a") < 0) {
      klagen.push("7. die Klangtaste steht nicht in der Tastenleiste: " + leiste);
    }
    await pult.ende();
  }

  // ── 8: `k` wirft den Klang einer Taste nicht wieder an ─────────────────
  // Gezaehlt wird jedes `play` der beiden Knoten, nicht nur der Stand: ein
  // Klang von einer halben Sekunde ist womoeglich schon wieder still, wenn
  // die Probe hinsieht, und haette doch gerade doppelt geklungen.
  await b.navigiere("file://" + beide);
  await schlaf(2000);
  await b.taste("ArrowRight");
  await schlaf(800);
  await b.ev(`(function(){
    window.__spiel = { taste: 0, folie: 0 };
    document.querySelectorAll("audio").forEach(function (a) {
      a.addEventListener("play", function () {
        window.__spiel[a.classList.contains("ts-sound") ? "taste" : "folie"]++;
      });
    });
  })()`);
  await b.taste("a");
  await schlaf(150);
  const folge = [];
  for (const warten of [300, 300, 300, 900, 300]) {
    await b.taste("k");
    await schlaf(warten);
    folge.push(JSON.parse(await b.ev(`JSON.stringify((function(){
      var t = document.querySelector("audio.ts-sound"),
          f = document.querySelector(".ts-el audio, audio:not(.ts-sound)");
      return { taste: !t.paused, folie: !f.paused, spiel: window.__spiel };
    })())`)));
  }
  const zuletzt = folge[folge.length - 1].spiel;
  if (zuletzt.taste !== 1) {
    klagen.push("8. `k` warf den Klang der Taste wieder an: " + zuletzt.taste
                + " Mal gespielt statt einmal (durch `a`)");
  }
  if (!folge[0].folie || folge[0].taste) {
    klagen.push("8. das erste `k` nach `a` startete die Aufnahme nicht oder "
                + "liess die Taste weiterklingen: " + JSON.stringify(folge[0]));
  }
  if (zuletzt.folie < 3) {
    klagen.push("8. die Aufnahme wurde nur " + zuletzt.folie + " Mal gestartet, "
                + "erwartet 3 -- `k` schaltet sie nicht mehr um");
  }

  // ── 6: eine fehlende Datei ──────────────────────────────────────────────
  await b.navigiere("file://" + fehlt);
  await schlaf(2500);
  s = JSON.parse(await b.ev(lage));
  if (!s.fehler.length) {
    klagen.push("6. eine fehlende Tondatei meldete sich beim Laden nicht -- "
                + "bei einem Bild sieht man ein Standbild, bei einem Ton nichts");
  }

  await b.ende();
  if (klagen.length) {
    console.log("Klang: " + klagen.length + " Punkt(e)\n");
    klagen.forEach(k => console.log("  • " + k));
    process.exit(1);
  }
  console.log("Klang: in Ordnung");
})();
