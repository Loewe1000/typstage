#!/usr/bin/env node
// =============================================================================
// pruefe-decks.js — die Beispieldecks im echten Browser durchfahren
// =============================================================================
// Aufruf aus dem Repo-Wurzelverzeichnis, nachdem `build-site.sh` gelaufen ist:
//
//     node .github/scripts/pruefe-decks.js
//     node .github/scripts/pruefe-decks.js --tempo 8          (Schnellfassung)
//     node .github/scripts/pruefe-decks.js --browser /pfad/zu/firefox
//     node .github/scripts/pruefe-decks.js --neu-soll         (Sollstand neu)
//     node .github/scripts/pruefe-decks.js --bericht b.json   (Bericht als Datei)
//     node .github/scripts/pruefe-decks.js --bilder bilder/   (je Folie ein PNG)
//
// Braucht node 22 (wegen des globalen `WebSocket`) und einen Chrome oder
// Firefox auf der Platte. Ohne `--browser` wird gesucht.
//
// Rückgabewert 0, wenn alles hält, sonst 1. Der Bericht geht als JSON nach
// stdout, die Zeile je Deck nach stderr.
//
// --- Warum ohne npm ----------------------------------------------------------
// Chrome ist über das DevTools-Protokoll erreichbar, Firefox über
// WebDriver-BiDi, beides mit dem, was node selbst mitbringt (`decklauf/cdp.js`
// und `decklauf/bidi.js`, zusammen keine 150 Zeilen). Playwright wäre bequemer,
// aber dann hinge die Frage „ist dieses Paket prüfbar" an einem Download von
// einigen hundert Megabyte. Wer WebKit oder den Zwei-Fenster-Fall dazunehmen
// will, kann Playwright danebenstellen; Voraussetzung ist es nicht.
//
// --- Was er prüft, und was nicht ---------------------------------------------
// Geprüft wird, was im Browser eine Zahl hat: Folien, Schritte, Elemente, je
// Schritt wie viele sichtbar und wie viele gedimmt sind, wie viele Geister
// ein Flug erzeugt, der Wiedereintritt über den Hash, die Sprecheransicht,
// der Grund jeder Folie und die Fehlerliste der Laufzeit. Dazu die Frage, ob
// jedes Deck die Laufzeit trägt, die daneben im Paket liegt.
//
// Nicht geprüft wird, wie eine Folie aussieht. Es werden keine Bilder
// verglichen (`--bilder` schießt welche, vergleicht sie aber nicht), keine
// Schriftgrößen und keine Positionen gemessen. Was `fit`, `info()`, `invert`
// und die Paletten tun, entsteht in Typst und ist im Browser nicht als Zahl
// zu haben; dafür steht `satz`, der Fingerabdruck der HTML-Ausgabe des
// Prüfdecks ohne den Laufzeitblock, und `grund`, die Farbe jeder Folie.
// Tastatur, Maus, Zeigegesten, die Tinte, das Daumenkino selbst und der
// Zwei-Fenster-Fall zwischen zwei echten Fenstern sind hier nicht drin.
//
// --- Wie lange er braucht ----------------------------------------------------
// Auf einem Mac mini gemessen, sieben Decks: voll 254 s, mit `--tempo 20`
// 78 s, in Firefox mit `--tempo 8` 84 s. Alle drei liefern einen
// byteidentischen Bericht. Was übrig bleibt, ist Seitenladen und
// Browserstart, nicht Warten auf Animationen. Deshalb gibt es keine eigene
// Schnellfassung in einem zweiten Arbeitsablauf: sie spräche dieselben Zahlen
// aus und wäre eine zweite Stelle, die grün bleiben muss.
//
// --- Warum nicht in pages.yml ------------------------------------------------
// `pages.yml` baut und deployt. Ein Prüflauf, der einen Deploy aufhält, wird
// beim ersten Fehlalarm umgangen, und danach prüft er nichts mehr. Er gehört
// vor eine Freigabe, also in `decks.yml` an den Pull Request.
//
// --- Der Durchlauf liegt in der Seite ----------------------------------------
// Die eigentliche Fahrt passiert in *einem* `Runtime.evaluate`. Das ist nicht
// Bequemlichkeit: 400 Schritte einzeln über den Socket zu fahren kostet
// dieselbe Messung ein Vielfaches, und jede Wartezeit dazwischen ist eine
// Quelle von Flattern.
//
// --- Woran der alte Sollwert krankte -----------------------------------------
// Die Reihe hieß früher `folien/schritte/flieger`, etwa `tour 24/56/110`. Die
// dritte Zahl war nicht reproduzierbar. `fly()` räumt seine Geister per
// `setTimeout` ab; wer `#ts-fly` irgendwann später abfragt, zählt je nach
// Laune des Rechners die Geister des vorigen Übergangs mit. Belegt durch
// denselben Lauf bei zwölffachem Tempo: `192/656/592/1100/672/288` statt
// `96/328/278/396/224/96`. Zwei Prüfer sind daran gescheitert.
//
// Die Zahl wird deshalb nicht mehr am DOM abgelesen, sondern in der Laufzeit
// gezählt, dort wo die Geister entstehen (`FLUG` in `assets/typstage-0.1.0.js`).
// Ein laufender Zähler kann nicht zum falschen Zeitpunkt gefragt werden.
// =============================================================================
"use strict";
const fs = require("fs"), path = require("path"), os = require("os");
const { execFileSync } = require("child_process");

// `WebSocket` gibt es global erst ab node 22. Ohne diese Zeile stürzt der Lauf
// zwanzig Zeilen später mit "WebSocket is not defined" ab, und das liest sich
// wie ein Fehler im Paket.
if (typeof WebSocket === "undefined") {
  console.error("FEHLER: node " + process.versions.node + " kennt kein globales "
    + "WebSocket. Der Lauf braucht node 22 oder neuer.");
  process.exit(2);
}

const WURZEL = path.resolve(__dirname, "..", "..");
const args = process.argv.slice(2);
const hat = n => args.indexOf(n) >= 0;
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };

// Welcher Browser. Ohne `--browser` wird gesucht, statt einen Pfad zu raten:
// auf einem GitHub-Läufer heißt Chrome anders als auf einem Mac, und ein
// falsch geratener Pfad sieht aus wie ein kaputtes Paket.
function browserSuchen() {
  const kandidaten = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable",
    "/usr/bin/chromium", "/usr/bin/chromium-browser",
    "/snap/bin/chromium",
    // Firefox zuletzt: der Lauf spricht mit ihm über WebDriver-BiDi statt
    // über CDP und ist dort etwas langsamer. Aber er gehört gesucht, sonst
    // verweist die Meldung unten auf etwas, wonach nie gesehen wurde.
    "/Applications/Firefox.app/Contents/MacOS/firefox",
    "/usr/bin/firefox", "/snap/bin/firefox"
  ];
  const da = kandidaten.find(k => fs.existsSync(k));
  if (da) return da;
  console.error("FEHLER: kein Chrome gefunden. Mit --browser einen Pfad "
    + "angeben; ein Firefox tut es auch.");
  process.exit(2);
}
const binaer = opt("--browser", null) || browserSuchen();
const istFF = /firefox/i.test(binaer);
const { starte, schlaf } = require(istFF ? "./decklauf/bidi.js" : "./decklauf/cdp.js");

const deckDir = path.resolve(opt("--decks", path.join(WURZEL, "_site", "beispiele")));
const sollDatei = path.resolve(opt("--soll", path.join(__dirname, "decklauf", "soll.json")));
const bildZiel = opt("--bilder", null) && path.resolve(opt("--bilder"));
const tempo = Math.max(1, +(opt("--tempo", "1")) || 1);
const neuSoll = hat("--neu-soll");
// Der Paketpfad, unter dem die Prüfdecks `@schule/typstage:0.1.0` finden.
//
// Ohne Angabe wird er aus dem Arbeitsbaum selbst gebaut, und zwar immer. Das
// ist nicht Bequemlichkeit: verlässt man sich darauf, dass der Import
// irgendwo auflöst, misst der Lauf für die Prüfdecks stillschweigend eine
// *andere* Laufzeit als die, die er prüft -- die installierte statt der
// gebauten. Auf einem CI-Läufer gibt es gar keine, und der Lauf bricht ab,
// bevor ein Browser startet. Ein Verweis auf den Arbeitsbaum trifft in beiden
// Fällen genau das, was hier geprüft werden soll.
const paketpfad = (function () {
  const gesetzt = opt("--paketpfad", null);
  if (gesetzt) return path.resolve(gesetzt);
  const wurzel = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pp-"));
  const ziel = path.join(wurzel, "schule", "typstage");
  fs.mkdirSync(ziel, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.0"), "dir");
  return wurzel;
})();

// Die Wanduhr, auf die jedes Deck festgenagelt wird. Irgendeine Zahl, aber
// dieselbe in jedem Lauf: alles, was am Takt hängt (das Daumenkino), zeigt
// dann in zwei Läufen dasselbe Bild.
const UHR = 1234567;
// Wie lange auf Ruhe gewartet wird, bevor der Lauf sie für nicht eingetreten
// erklärt. Nicht als Wartezeit gedacht, sondern als Notbremse: jedes Mal,
// wo sie greift, steht im Bericht, denn dann ist gemessen worden, während
// noch etwas lief.
const FRIST = 4000;

// Der Text, der in `soll.json` mitgeschrieben wird. Dort könnte sonst niemand
// erklären, warum die Zahlen so heißen, wie sie heißen.
const SOLL_HINWEIS = [
  "Festgeschriebene Werte des Prüflaufs. Geschrieben von",
  ".github/scripts/pruefe-decks.js --neu-soll, und nur mit Absicht.",
  "",
  "flieger und fliegerRueck sind die Zahl der Geister, die die Flüge des",
  "Hin- und des Rückwegs erzeugen, gezählt in der Laufzeit an der Stelle, an",
  "der sie entstehen (FLUG in assets/typstage-0.1.0.js).",
  "",
  "Das ist NICHT die alte dritte Zahl der Reihe folien/schritte/flieger. Die",
  "wurde am DOM abgelesen, an #ts-fly, und fly() räumt seine Geister per",
  "setTimeout ab: wer irgendwann nachzählt, zählt je nach Laune des Rechners",
  "die Geister des vorigen Übergangs mit. Die Reihe hieß darum einmal",
  "tour 24/56/110 und lieferte bei zwölffachem Tempo 192/656/592/1100/672/288",
  "statt 96/328/278/396/224/96. Zwei Prüfer sind daran gescheitert. Ein",
  "laufender Zähler kann nicht zum falschen Zeitpunkt gefragt werden; wer die",
  "alte Zahl zurückschreibt, holt sich das Flattern zurück.",
  "",
  "sichtbar und sichtbarRueck stehen je Schritt als",
  "  <im ganzen Deck sichtbar>/<gedimmt> · <auf der Folie sichtbar>/<gedimmt>.",
  "Sichtbar und gedimmt getrennt, weil sonst niemand merkt, wenn",
  "after: \"dimmed\" aufhört zu dimmen. Zwei Bereiche, weil die Zahlen über das",
  "ganze Deck die Vorgeschichte mittragen (eine verlassene Folie behält ihre",
  "Elemente gezeichnet) und nur die Zahlen über die laufende Folie sich gegen",
  "einen frischen Sprung halten lassen.",
  "",
  "hashStand ist sichtbar/gedimmt auf der Folie nach einem frischen Einstieg",
  "über #8. Er muss dem Wert des Durchblätterns auf demselben Schritt",
  "gleichen, sonst spielt der Einstieg den Lauf falsch nach.",
  "",
  "grund ist die Füllfarbe des ersten Pfades im Hintergrund-SVG jeder Folie,",
  "also die Fläche, auf der sie steht. Daran hängen Palette und invert.",
  "",
  "satz ist der SHA-256 der HTML-Ausgabe des Prüfdecks ohne den Laufzeitblock,",
  "auf 16 Stellen gekürzt, satzBytes ihre Länge. Nur für das Prüfdeck: was",
  "fit, info(), invert und die Paletten tun, entsteht in Typst und hat im",
  "Browser keine Zahl. Nach einem Typst-Wechsel darf er neu gesetzt werden,",
  "aber nur nachdem jemand nachgesehen hat, was sich geändert hat."
];

// ── Welche Decks ────────────────────────────────────────────────────────────
// Die sechs Beispiele plus das Prüfdeck. Letzteres steht nicht unter
// `examples/`, weil es nicht auf die Website gehört; es wird hier übersetzt.
// Es deckt ab, was die sechs nicht anfassen. Nachgezählt in ihren Quellen:
// `after: "dimmed"` 0x, `stagger(dim: true)` 0x, `invert` 0x, `info()` 0x,
// `fit` 0x. Ohne das Prüfdeck kann man diese fünf zerstören, ohne dass hier
// eine Zahl wackelt.
const BEISPIELE = ["tour", "theme-default", "theme-editorial", "theme-lesson",
                   "theme-night", "theme-plain"];

// Die Laufzeit, wie sie im Paket liegt. Jedes Deck muss genau diese tragen.
const LAUFZEIT = fs.readFileSync(path.join(WURZEL, "assets", "typstage-0.1.0.js"));

// Ein Deck aus `decklauf/` übersetzen. Gibt den Pfad zurück, oder wirft mit
// der Meldung von typst.
function decklaufBauen(name) {
  const quelle = path.join(__dirname, "decklauf", name + ".typ");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pd-")),
                        name + ".html");
  const rufe = ["compile", "--format", "html", "--features", "html",
                "--root", WURZEL];
  rufe.push("--package-path", paketpfad);
  rufe.push(quelle, aus);
  try {
    execFileSync("typst", rufe, { stdio: ["ignore", "ignore", "pipe"] });
  } catch (e) {
    const fehler = new Error("typst brach ab");
    fehler.meldung = String(e.stderr || e.message);
    throw fehler;
  }
  return aus;
}

// Gegenprobe zum Überlaufmelder. `ueberlauf.typ` ist ein Deck, das übersteht
// und deshalb *nicht* übersetzen darf. Ohne diese Probe sagt das Prüfdeck mit
// seinem `overflow: "error"` nur, dass der Prüfgang durchläuft, und ein
// Melder, der nichts mehr meldet, fiele niemandem auf.
function ueberlaufProbe() {
  try {
    decklaufBauen("ueberlauf");
  } catch (e) {
    if (/runs over the room/.test(e.meldung || "")) return null;
    return "ueberlauf.typ brach ab, aber nicht am Überlauf: "
      + String(e.meldung || "").slice(0, 300);
  }
  return "ueberlauf.typ ließ sich übersetzen. Der Überlaufmelder meldet nicht "
    + "mehr, was übersteht.";
}

// ── Der Durchlauf, als ein Stück Seitencode ─────────────────────────────────
const DURCHLAUF = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  if (p.fassung !== 1) return JSON.stringify({ fassungFehler: p.fassung });
  p.uhr(${UHR});
  var vor = [], zurueck = [], fristen = 0, flyDom = 0, flyDomRueck = 0;
  var FLY = document.getElementById("ts-fly");
  // Jeder Ausgang außer "ruhig" zählt. "frist" heißt, eine Animation lief noch;
  // "keine-bilder" heißt, der Browser hat keine Bilder mehr ausgeteilt -- ein
  // verborgenes Fenster. Nur auf "frist" zu sehen hieße, dass ein solcher Lauf
  // still misst, was gerade dasteht, statt zu sagen, dass er nichts abwarten
  // konnte.
  async function ruhe() {
    const wie = await p.ruhig(${FRIST});
    if (wie !== "ruhig") fristen++;
  }

  typstage.goto(0, true); await ruhe(); vor.push(p.stand());
  for (var i = 1; i < p.schritte; i++) {
    var wechsel = S[i].slide !== S[i - 1].slide;
    typstage.goto(i);
    // Der alte Weg, nur zum Abgleich mitgezaehlt: sofort und ausschliesslich
    // beim Folienwechsel. Der Zaehler in der Laufzeit ist der massgebliche.
    if (wechsel) flyDom += FLY.querySelectorAll("*").length;
    await ruhe();
    vor.push(p.stand());
  }
  var vorFlieger = p.stand().flieger;
  for (var j = p.schritte - 2; j >= 0; j--) {
    var w2 = S[j].slide !== S[j + 1].slide;
    typstage.goto(j);
    if (w2) flyDomRueck += FLY.querySelectorAll("*").length;
    await ruhe();
    zurueck.push(p.stand());
  }

  // Der Grund jeder Folie: der erste gefuellte Pfad im Hintergrund-SVG ist die
  // Flaeche, auf der die Folie steht. Daran haengt, ob eine Palette greift und
  // ob invert eine Folie noch umdreht.
  var grund = [].map.call(document.querySelectorAll(".ts-slide"), function (f) {
    var p1 = f.querySelector(".ts-bg svg path");
    return p1 ? (p1.getAttribute("fill") || "") : "";
  });

  return JSON.stringify({
    folien: p.folien, schritte: p.schritte, elemente: p.elemente,
    flieger: vorFlieger, fliegerRueck: p.stand().flieger - vorFlieger,
    flyDom: flyDom, flyDomRueck: flyDomRueck,
    fristen: fristen, grund: grund,
    vor: vor, zurueck: zurueck, fehler: p.fehler()
  });
})()`;

// Animationen im Zeitraffer, ohne den Browser danach zu fragen. `playbackRate`
// gibt es nur über CDP, also nur in Chrome; `Element.prototype.animate` gibt es
// überall. Der Eingriff steht hier im Prüflauf und nicht in der Laufzeit: eine
// Laufzeit, die ein Tempo kennt, wäre eine andere als die ausgelieferte.
const ZEITRAFFER = (n) => `(function () {
  var echt = Element.prototype.animate;
  Element.prototype.animate = function (kf, o) {
    if (typeof o === "number") o = o / ${n};
    else if (o && typeof o === "object") {
      o = Object.assign({}, o);
      if (o.duration != null) o.duration = o.duration / ${n};
      if (o.delay != null) o.delay = o.delay / ${n};
    }
    return echt.call(this, kf, o);
  };
})()`;

async function laden(b, url) {
  try { await b.navigiere(url); } catch (e) { /* about:blank meldet nichts */ }
  if (url === "about:blank") return true;
  for (let i = 0; i < 400; i++) {
    await schlaf(40);
    try {
      if (await b.ev("!!(window.typstage && window.typstage.pruef)")) {
        if (tempo > 1) await b.ev(ZEITRAFFER(tempo));
        return true;
      }
    } catch (e) { /* lädt noch */ }
  }
  return false;
}

// Der Vergleich mit dem Sollstand. Feld für Feld, damit im Bericht steht,
// *was* abweicht, und nicht nur, dass etwas abweicht.
function vergleiche(soll, ist, name, maengel, plattform, proPlattform) {
  // Über beide Schlüsselmengen, nicht nur über die des Sollstands: ein Feld,
  // das neu dazukommt, soll auffallen und nicht stillschweigend durchgehen.
  const schluessel = [...new Set(Object.keys(soll).concat(Object.keys(ist)))];
  schluessel.forEach(k => {
    if (proPlattform.indexOf(k) >= 0) {
      // Eine schlichte Zahl heißt: die Plattformen sind sich einig, und dann
      // wird auch plattformübergreifend verglichen. Erst wenn eine wirklich
      // abweicht, wird daraus ein Wörterbuch je Plattform. Alles vorsorglich
      // zu teilen wäre bequem und falsch: die Decks, die heute übereinstimmen,
      // würden dann getrennt gegen sich selbst geprüft, und ein künftiges
      // Auseinanderlaufen fiele niemandem mehr auf.
      const s = soll[k], i = ist[k];
      const istGeteilt = s !== null && typeof s === "object";
      if (!istGeteilt) {
        const a = JSON.stringify(s);
        const b = JSON.stringify(i !== null && typeof i === "object" ? i[plattform] : i);
        if (a !== b) maengel.push(name + "." + k + ": soll " + kurz(a) + ", ist " + kurz(b));
        return;
      }
      if (!(plattform in s)) {
        maengel.push(name + "." + k + ": für " + plattform
          + " ist kein Sollwert aufgenommen, gemessen " + kurz(JSON.stringify(i[plattform]))
          + " (nicht verglichen)");
        return;
      }
      const a = JSON.stringify(s[plattform]), b = JSON.stringify(i[plattform]);
      if (a !== b) {
        maengel.push(name + "." + k + " (" + plattform + "): soll " + kurz(a)
                     + ", ist " + kurz(b));
      }
      return;
    }
    const a = JSON.stringify(soll[k]), b = JSON.stringify(ist[k]);
    if (a !== b) maengel.push(name + "." + k + ": soll " + kurz(a) + ", ist " + kurz(b));
  });
}
const kurz = s => (s == null ? "nichts" : (s.length > 220 ? s.slice(0, 217) + "..." : s));

(async () => {
  const t0 = Date.now();
  const decks = BEISPIELE.map(n => ({ name: n, datei: path.join(deckDir, n + ".html") }));
  decks.forEach(d => {
    if (!fs.existsSync(d.datei))
      { console.error("FEHLER: " + d.datei + " fehlt. Erst build-site.sh laufen lassen."); }
  });
  if (decks.some(d => !fs.existsSync(d.datei))) process.exit(2);
  const ueberlauf = ueberlaufProbe();
  if (ueberlauf) console.error("ABWEICHUNG ueberlauf: " + ueberlauf);
  let pd;
  try { pd = decklaufBauen("pruefdeck"); }
  catch (e) {
    console.error("FEHLER: Prüfdeck ließ sich nicht übersetzen\n" + (e.meldung || ""));
    process.exit(2);
  }
  decks.push({ name: "pruefdeck", datei: pd, satz: true });

  const b = await starte(binaer);
  const bericht = []; let schlecht = 0;
  if (bildZiel) fs.mkdirSync(bildZiel, { recursive: true });

  for (const d of decks) {
    const z = { deck: d.name, maengel: [] };
    // Jedes Deck bekommt eine frische Seite. Ein Sprung, der nur den Hash
    // ändert, lädt *nicht* neu, und dann ist die Rolle noch die vorige.
    await laden(b, "about:blank");
    if (!await laden(b, "file://" + d.datei)) {
      // `window.typstageFehler` steht schon, bevor das Deck aufgebaut ist.
      // Wenn der Aufbau abstürzt, ist das die einzige Stelle, die noch sagt,
      // woran. Ohne sie stünde hier nur „fehlt" und niemand wüsste warum.
      let warum = [];
      try { warum = JSON.parse(await b.ev(
        "JSON.stringify(window.typstageFehler || [])")) || []; } catch (e) {}
      z.maengel.push("keine Messfläche: window.typstage.pruef fehlt"
        + (warum.length ? " (" + warum.join(" | ") + ")" : ""));
      bericht.push(z); schlecht++; continue;
    }
    const r = JSON.parse(await b.ev(DURCHLAUF));
    if (r.fassungFehler) {
      z.maengel.push("Messfläche in Fassung " + r.fassungFehler + ", erwartet 1");
      bericht.push(z); schlecht++; continue;
    }

    Object.assign(z, {
      folien: r.folien, schritte: r.schritte, elemente: r.elemente,
      flieger: r.flieger, fliegerRueck: r.fliegerRueck,
      grund: r.grund, fehler: r.fehler,
      // Je Schritt sichtbar/gedimmt im ganzen Deck · sichtbar/gedimmt auf der
      // laufenden Folie. Getrennt gezählt, weil sonst niemand merkt, wenn
      // `after: "dimmed"` aufgehört hat zu dimmen; über zwei Bereiche, weil
      // das ganze Deck die Vorgeschichte mitträgt und die Folie allein den
      // Zustand.
      sichtbar: r.vor.map(s => s.sichtbar + "/" + s.gedimmt
        + "·" + s.folieSichtbar + "/" + s.folieGedimmt),
      sichtbarRueck: r.zurueck.map(s => s.sichtbar + "/" + s.gedimmt
        + "·" + s.folieSichtbar + "/" + s.folieGedimmt)
    });
    // Nicht Teil des Sollstands, nur zum Vergleich: der alte, am DOM
    // abgelesene Weg. Weicht er vom Zähler ab, ist das erwartet und harmlos;
    // er zählt Knoten samt Nachkommen, der Zähler zählt Geister.
    z.flyDom = r.flyDom; z.flyDomRueck = r.flyDomRueck;

    if (r.fristen) z.maengel.push(r.fristen + "x lief die Frist ab, statt dass "
      + "die Bühne zur Ruhe kam. Gemessen wurde in laufender Bewegung.");
    r.vor.forEach((s, i) => { if (s.schritt !== i)
      z.maengel.push("vorwärts: Schritt " + i + " meldete " + s.schritt); });
    r.zurueck.forEach((s, k) => { const soll = r.schritte - 2 - k;
      if (s.schritt !== soll)
        z.maengel.push("rückwärts: Schritt " + soll + " meldete " + s.schritt); });
    if (r.fehler.length)
      z.maengel.push(r.fehler.length + " Fehler/Warnungen: " + r.fehler.join(" | "));

    // Wiedereintritt über den Hash. Frische Seite, sonst ist es nur ein Sprung.
    const ziel = Math.min(8, r.schritte);
    await laden(b, "about:blank");
    await laden(b, "file://" + d.datei + "#" + ziel);
    await b.ev("typstage.pruef.uhr(" + UHR + "); typstage.pruef.ruhig(" + FRIST + ")");
    const h = JSON.parse(await b.ev("JSON.stringify(typstage.pruef.stand())"));
    if (h.hash !== ziel) z.maengel.push("#" + ziel + " landete auf " + h.hash);
    z.hash = h.hash;
    // Nicht nur, ob der Sprung auf dem richtigen Schritt landet, sondern auch,
    // ob die Folie dort so dasteht wie beim Durchblättern. Der Einstieg spielt
    // den Lauf als Zustand nach; tut er das falsch, stimmt die Schrittzahl
    // trotzdem, und ohne diese Zeile fiele es nicht auf.
    // Über die laufende Folie, nicht über das ganze Deck: der Sprung hat
    // keine Vorgeschichte hinter sich, das Durchblättern schon.
    z.hashStand = h.folieSichtbar + "/" + h.folieGedimmt;
    const durch = r.vor[ziel - 1];
    if (durch && z.hashStand !== durch.folieSichtbar + "/" + durch.folieGedimmt)
      z.maengel.push("#" + ziel + " zeigt " + z.hashStand
        + ", beim Durchblättern steht dort "
        + durch.folieSichtbar + "/" + durch.folieGedimmt);

    // Sprecheransicht.
    await laden(b, "about:blank");
    await laden(b, "file://" + d.datei + "#speaker");
    await b.ev("typstage.pruef.ruhig(" + FRIST + ")");
    const sp = JSON.parse(await b.ev(`JSON.stringify({
      rolle: typstage.pruef.rolle,
      kinder: typstage.box ? typstage.box.querySelectorAll("*").length : -1,
      fehler: typstage.pruef.fehler() })`));
    if (sp.rolle !== "speaker") z.maengel.push("Rolle unter #speaker ist " + sp.rolle);
    if (sp.kinder <= 0) z.maengel.push("Sprecherbox leer");
    if (sp.fehler.length) z.maengel.push("Sprecher: " + sp.fehler.join(" | "));
    z.sprecher = sp.kinder;

    // Steckt in diesem Deck die Laufzeit, die daneben im Paket liegt?
    //
    // Ein Deck trägt seine Laufzeit wörtlich in sich (`assets: "inline"`, die
    // Vorgabe). Wer den Lauf über ein altes `_site/` schickt, prüft deshalb
    // eine Laufzeit von gestern und merkt es nicht: gemessen an einer
    // absichtlich zerstörten Morph-Zuordnung fiel nur das Prüfdeck um, weil
    // allein das bei jedem Lauf neu gesetzt wird. Also wird hier nachgesehen.
    const roh = fs.readFileSync(d.datei);
    const stelle = roh.indexOf(LAUFZEIT);
    if (stelle < 0) z.maengel.push("Dieses Deck trägt eine andere Laufzeit als "
      + "assets/typstage-0.1.0.js. Erst neu bauen, dann prüfen.");
    // Und der Satz selbst, als Fingerabdruck der HTML-Ausgabe ohne den
    // Laufzeitblock. Nur für das Prüfdeck: das ist die einzige Stelle, an der
    // eine Änderung an `fit`, `info()`, `invert` oder einer Palette sicher
    // auffällt, denn keine davon ist im Browser als Zahl zu haben. Die sechs
    // Beispiele bleiben davon frei, dort wäre es eine Fehlalarmquelle bei
    // jedem Typst-Wechsel; das Prüfdeck schreibt niemand nebenbei um.
    if (d.satz && stelle >= 0) {
      const ohne = Buffer.concat([roh.subarray(0, stelle),
                                  roh.subarray(stelle + LAUFZEIT.length)]);
      z.satz = require("crypto").createHash("sha256")
        .update(ohne).digest("hex").slice(0, 16);
      z.satzBytes = ohne.length;
    }

    if (bildZiel) {
      await laden(b, "about:blank");
      await laden(b, "file://" + d.datei);
      await b.ev("typstage.pruef.uhr(" + UHR + ")");
      for (let f = 0; f < r.folien; f++) {
        await b.ev("(function(){var S=typstage.steps,z=0;"
          + "for(var i=0;i<S.length;i++) if(S[i].slide===" + f + ") z=i;"
          + "typstage.goto(z,true);})(); typstage.pruef.ruhig(" + FRIST + ")");
        fs.writeFileSync(path.join(bildZiel,
          d.name + "-" + String(f + 1).padStart(2, "0") + ".png"),
          Buffer.from(await b.bild(), "base64"));
      }
    }

    bericht.push(z);
    process.stderr.write(d.name + ": " + z.folien + "/" + z.schritte + "/" + z.flieger
      + " · " + z.elemente + " Elemente · "
      + (z.maengel.length ? "MÄNGEL " + z.maengel.join("; ") : "ok") + "\n");
  }
  await b.ende();

  // ── Gegen den Sollstand ───────────────────────────────────────────────────
  // Nicht „stürzt nicht ab", sondern „verhält sich wie gestern".
  const felder = ["folien", "schritte", "elemente", "flieger", "fliegerRueck",
                  "hash", "hashStand", "sprecher", "grund", "sichtbar",
                  "sichtbarRueck", "fehler", "satz", "satzBytes"];
  // `satz` und `satzBytes` hängen an den Schriften des Rechners, nicht am
  // Paket: derselbe Stand ergibt auf macOS 546292 Bytes und auf einem
  // Ubuntu-Läufer 500912, während alle übrigen Felder -- Schritte, Elemente,
  // Flieger, Gründe -- auf beiden aufs Zeichen gleich sind. Sie werden deshalb
  // je Plattform abgelegt. Fehlt die eigene, wird das gesagt und nicht
  // verglichen; stillschweigend übergehen hieße, eine Prüfung zu verlieren,
  // ohne dass es jemand merkt.
  const PLATTFORM = process.platform;
  // Alles, was an den Schriften des Rechners hängt, steht je Plattform.
  // `sprecher` zählt die Knoten der Sprechervorschau, und die ist gesetzter
  // Text: theme-night hat auf ubuntu-latest einen Knoten weniger als hier,
  // weil dort eine Glyphe fehlt. Dieselbe Ursache wie bei `satz`, also
  // dieselbe Regel -- sonst wäre es eine Zahl, die je nach Rechner umfällt.
  const proPlattform = ["satz", "satzBytes", "sprecher"];
  const jetzt = {};
  bericht.forEach(z => {
    const e = {};
    felder.forEach(k => {
      if (z[k] === undefined) return;
      if (proPlattform.indexOf(k) >= 0) { e[k] = { [PLATTFORM]: z[k] }; }
      else { e[k] = z[k]; }
    });
    jetzt[z.deck] = e;
  });

  // Ein fehlender Sollstand ist ein Fehler, kein Anlass, einen neuen zu
  // schreiben. Sonst bekommt, wer `soll.json` löscht, keinen Fund, sondern
  // eine neue Wahrheit -- und der Lauf ist ab da grün gegen sich selbst.
  if (!neuSoll && !fs.existsSync(sollDatei)) {
    console.error("FEHLER: " + sollDatei + " fehlt. Mit --neu-soll einen "
      + "neuen Sollstand aufnehmen, wenn das beabsichtigt ist.");
    process.exit(2);
  }
  if (neuSoll) {
    // Die Werte anderer Plattformen bleiben stehen. Wer auf macOS neu
    // aufnimmt, darf den Linux-Wert nicht mitnehmen -- sonst prüft die CI
    // beim nächsten Lauf gegen nichts.
    let alt = {};
    try { alt = JSON.parse(fs.readFileSync(sollDatei, "utf8")).decks || {}; }
    catch (e) {}
    Object.keys(jetzt).forEach(n => {
      proPlattform.forEach(k => {
        if (jetzt[n][k] === undefined) return;
        const vorher = alt[n] && alt[n][k];
        const meiner = jetzt[n][k][PLATTFORM];
        if (vorher !== null && typeof vorher === "object") {
          // Schon geteilt: die Werte der anderen Plattformen bleiben stehen,
          // sonst nähme ein Lauf hier der CI ihren Sollwert weg.
          jetzt[n][k] = Object.assign({}, vorher, jetzt[n][k]);
        } else {
          // Noch nicht geteilt: schlicht schreiben. Geteilt wird erst, wenn
          // eine Plattform nachweislich abweicht -- von Hand, mit der Zahl
          // aus dem Lauf, der die Abweichung gezeigt hat.
          jetzt[n][k] = meiner;
        }
      });
    });
    fs.writeFileSync(sollDatei, JSON.stringify({
      fassung: 2,
      hinweis: SOLL_HINWEIS,
      decks: jetzt
    }, null, 1) + "\n");
    process.stderr.write("Sollstand geschrieben: " + sollDatei + "\n");
  } else {
    const soll = JSON.parse(fs.readFileSync(sollDatei, "utf8"));
    Object.keys(soll.decks).forEach(n => {
      const z = bericht.find(x => x.deck === n);
      if (!z) { process.stderr.write("ABWEICHUNG " + n + " fehlt im Lauf\n"); schlecht++; return; }
      vergleiche(soll.decks[n], jetzt[n], n, z.maengel, PLATTFORM, proPlattform);
    });
    Object.keys(jetzt).forEach(n => {
      if (!soll.decks[n]) process.stderr.write("neu, kein Sollstand: " + n + "\n");
    });
  }
  bericht.forEach(z => { if (z.maengel.length) schlecht++; });
  if (ueberlauf) schlecht++;
  bericht.forEach(z => z.maengel.forEach(m =>
    process.stderr.write("ABWEICHUNG " + z.deck + ": " + m + "\n")));

  const ganz = JSON.stringify({
    dauer_s: +((Date.now() - t0) / 1000).toFixed(1),
    browser: b.name, tempo, schlecht, decks: bericht
  }, null, 1);
  const berichtDatei = opt("--bericht", null);
  if (berichtDatei) fs.writeFileSync(berichtDatei, ganz + "\n");
  console.log(ganz);
  process.exit(schlecht ? 1 : 0);
})().catch(e => { console.error("FEHLER:", e.stack); process.exit(2); });
