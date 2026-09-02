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
// Schriftgrößen und keine Positionen gemessen. Und nicht, was in einer
// Einbettung läuft: die beiden GeoGebra-Decks fahren mit abgeklemmtem
// GeoGebra, siehe `ohneGeoGebra`. Was `fit`, `info()`, `invert`
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
// gezählt, dort wo die Geister entstehen (`FLUG` in `assets/typstage-0.1.1.js`).
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
// Der Paketpfad, unter dem die Prüfdecks `@preview/typstage:0.1.1` finden.
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
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.1"), "dir");
  // Und unter `preview`, wie das Paket nach der Einreichung heisst. Die
  // Pruefdecks nennen es so; ohne diesen zweiten Verweis faenden sie es nicht.
  const ziel2 = path.join(wurzel, "preview", "typstage");
  fs.mkdirSync(ziel2, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel2, "0.1.1"), "dir");
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
  "der sie entstehen (FLUG in assets/typstage-0.1.1.js).",
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
  "halt steht nur beim Prüfdeck und beschreibt den Schrittwechsel einer",
  "Zeichnung aus build(): <Deckkraft der abtretenden Stufe> · <die der",
  "ankommenden> · <danach gezeichnete Stufen>/<Stufen der Folie>. Die",
  "abtretende Stufe wartet, statt zu gehen, deshalb steht dort 1>1 und nicht",
  "1>0. Ginge sie auf dem gewöhnlichen Weg, blendeten zwei fast gleiche Bilder",
  "gegeneinander und die geteilte Tinte sänke auf zwei Drittel -- am",
  "Ruhezustand ist davon nichts zu sehen, an den Zwischenbildern schon.",
  "",
  "haltRueck ist derselbe Wechsel rückwärts: <Deckkraft der abtretenden",
  "Stufe> · <die der ankommenden> · <Deckkraft der ankommenden im Augenblick",
  "des Tastendrucks> · <danach gezeichnete Stufen>/<Stufen>. Rückwärts kommt",
  "die kleinere Stufe herein und liegt vollständig unter der größeren, die",
  "noch abtritt: sie hat nichts zu blenden. Deshalb steht dort „sofort\" und",
  "eine 1 und nicht 0>1 und eine 0. Gemessen, Bild für Bild angehalten und",
  "abgelichtet: mit der Blende sank die geteilte Tinte auf 0,7522, mit",
  "enter: \"draw\" von Hand gestapelt auf 0,4348; ohne sie steht sie in beide",
  "Richtungen bei 1,0000.",
  "",
  "feder und federRueck sind die Zahl der Pfade, die sich auf dem Hin- und auf",
  "dem Rueckweg selbst gezeichnet haben (enter: \"draw\"). Gezaehlt wie flieger:",
  "in der Laufzeit, dort wo sie entstehen (FEDER in assets/typstage-0.1.1.js),",
  "und nicht am DOM. Sie stehen bei allen Decks; nur das Pruefdeck zeichnet,",
  "bei den anderen sind sie 0 -- und das ist selbst eine Aussage, denn ein Deck,",
  "das ploetzlich zeichnet, hat sich veraendert.",
  "",
  "zeichnung steht nur beim Pruefdeck und beschreibt eine Fahrt der Feder:",
  "  <Pfade hin>+<Pfade zurueck> · <Richtung hin>/<Richtung zurueck> ·",
  "  <Deckkraft der Blende darunter> · <offen nach dem Hinweg>/<offen am Ende>",
  "  · Sprung <Federn>/<gezeichnet>/<insgesamt gezogen>.",
  "Keine Laenge und keine Dauer: beide haengen am Fenster und am --tempo. Die",
  "Richtung haengt an keinem von beiden. Hinter dem Sprung steht der Endzustand,",
  "den ein Sprung herstellen muss, ohne die Zeichnung zu spielen: keine Feder,",
  "das Element gezeichnet, und die Gesamtzahl unveraendert.",
  "",
  "kurve steht ebenfalls nur beim Pruefdeck:",
  "  <was easing: ins Markup geschrieben hat> · <Kurve der Blende> ·",
  "  <Kurve der Feder>. Alle drei, weil jede fuer sich auf die Hauskurve",
  "zurueckfallen kann. Leerzeichen und fuehrende Nullen sind herausgerechnet,",
  "sonst schrieben Chrome und Firefox dieselbe Kurve verschieden auf.",
  "",
  "masz steht ebenfalls nur beim Prüfdeck und sagt, wie viele verschiedene",
  "Maße die Stufen einer build-Zeichnung melden. Es muss genau eines sein:",
  "alle Stufen liegen deckungsgleich, weil ein Stück, das noch nicht dran ist,",
  "als Luft dasteht und seinen Platz behält. Wird daraus mehr als eines,",
  "springt die Zeichnung bei jedem Schritt.",
  "",
  "szene steht nur beim Prüfdeck und beschreibt eine scene(): <Halte> ·",
  "<Bilder> · <Ruhebild je Schritt der Folie> · <Bild auf halber Zeit eines",
  "Zuges> · <Bild nach einem Sprung>. Halt k liegt auf Bild k·(tween + 1);",
  "wandert diese Reihe, stimmt die Zuordnung von Schritt zu Halt nicht mehr.",
  "Das Bild auf halber Zeit wird nicht zu einem geratenen Zeitpunkt abgelesen",
  "-- das hinge am Rechner --, sondern die Bewegung wird angehalten und auf",
  "die Hälfte ihrer Zeit gestellt. Es muss 7 von 9 sein und nicht 4 oder 5:",
  "daran hängt, dass der Zug die Kurve des Pakets fährt und keine Gerade.",
  "",
  "kamera steht nur beim Prüfdeck und beschreibt eine camera():",
  "  <Streckung je Schritt der Folie> · <tragen beide Ebenen dasselbe> ·",
  "  <Mitte des Details auf der Bühne> · <Streckung auf halber Zeit> ·",
  "  <nach einem Sprung> · <Vorschau: ganz/nah/einig> ·",
  "  <Schritte der Folie mit der Fahrt allein>.",
  "",
  "Die Mitte muss 0.50/0.50 sein, und sie ist die eigentliche Zusage: das",
  "Detail steht mitten im Bild. Eine Streckung allein sagt darüber nichts --",
  "wer den Ursprung der Streckung von der linken oberen Ecke in die Mitte des",
  "Kastens rückt, streckt genau gleich weit und zeigt die falsche Stelle.",
  "Streckungen und keine Verschiebungen: die Streckung ist das Verhältnis von",
  "Detail zu Folie und in jedem Fenster dieselbe, die Verschiebung stünde auf",
  "vier Nachkommastellen und hinge am Satz. Keine Dauer, die teilte --tempo",
  "durch seine Zahl.",
  "",
  "Die Reihe ist 1/x/x/1: die Folie steht ganz da, dann zwei Schritte lang der",
  "Ausschnitt, dann wieder ganz. Die Streckung auf halber Zeit muss echt",
  "dazwischen liegen; daran hängt, dass die Kamera fährt und nicht springt.",
  "Das Ziel der Fahrt steht mit Absicht in einem verfolgten Element: ein Pin",
  "im Hintergrund verschwindet unter dem hide() seines Wirts und steht allein",
  "im Sprite, und der zählt erst, wenn dieser seinen Platz gefunden hat.",
  "Findet die Kamera nichts, klagt sie in die Konsole -- dann wächst fehler,",
  "und die Reihe geht flach auf 1/1/1/1.",
  "",
  "allein ist 3 und nicht 2. Auf jener Folie steht nichts als ein Pin und eine",
  "Fahrt darauf; dass die Folie einen Schritt mehr braucht -- den, auf dem die",
  "Kamera wieder herausfährt --, muss die Laufzeit aus dem Bereich der Fahrt",
  "selbst dazurechnen. Dieselbe Sorte Lücke wie bei der alleinstehenden Szene.",
  "",
  "kino steht ebenfalls nur beim Prüfdeck. Die Uhr eines Daumenkinos beginnt,",
  "wenn es zu sehen ist, und nicht, wenn seine Folie kommt. Es stehen zwei",
  "Kinos auf der Folie und deshalb zwei Reihen hier: je fünf Zahlen, nämlich",
  "die drei Schritte der Folie und danach zweimal eine weitergestellte",
  "Prüfuhr, ohne dass ein Schritt geschieht.",
  "",
  "Das Kino at 3- ist beim Betreten verborgen und deckt auf Schritt 3 auf; das",
  "Kino at 1- steht von Anfang an da. Beide werden gebraucht. Ein Startpunkt,",
  "der beim Folieneintritt gestempelt wird, fällt nur dem zweiten auf -- das",
  "erste ist beim Betreten verborgen und bekommt seinen Startpunkt beim",
  "Aufdecken ohnehin neu. Ein Startpunkt, der unter der festgenagelten Uhr aus",
  "der Rechnung fällt, macht dagegen bei beiden alle fünf Zahlen gleich, und",
  "das ist der gefährlichere Fall: mit ihm bleibt der Lauf grün, während das",
  "Kino abgelaufen ist, bevor es zu sehen war. Gemessen mit dem alten Stand:",
  "23/23/23/23/23 statt 0/0/0/12/23.",
  "",
  "grund ist die Füllfarbe des ersten Pfades im Hintergrund-SVG jeder Folie,",
  "also die Fläche, auf der sie steht. Daran hängen Palette und invert.",
  "",
  "satz ist der SHA-256 der HTML-Ausgabe des Prüfdecks ohne den Laufzeitblock,",
  "auf 16 Stellen gekürzt, satzBytes ihre Länge. Nur für das Prüfdeck: was",
  "fit, info(), invert und die Paletten tun, entsteht in Typst und hat im",
  "Browser keine Zahl. Nach einem Typst-Wechsel darf er neu gesetzt werden,",
  "aber nur nachdem jemand nachgesehen hat, was sich geändert hat.",
  "",
  "Geteilt wird ein Wert erst, wenn eine Abweichung belegt ist -- nie",
  "vorsorglich. Geteilt sind derzeit theme-night/sprecher,",
  "geogebra-sprecher/sprecher, pruefdeck/satz und pruefdeck/satzBytes. Alle",
  "vier hängen an den Schriften des Rechners und an nichts sonst, und das ist",
  "inzwischen zweimal belegt: beim Zusammenlegungszweig über 9 Decks, beim",
  "Zweig mit den fünfzehn Beispielen über 16. Beim zweiten Mal wichen sogar",
  "nur pruefdeck/satz und satzBytes ab -- die sieben neu dazugekommenen Decks",
  "nannten auf macOS und auf Ubuntu durchweg dieselben Zahlen, sprecher",
  "eingeschlossen.",
  "",
  "Wer ein Deck aendert, dessen Satz sich dabei verschiebt, macht die",
  "linux-Werte ungueltig und muss sie entfernen statt sie stehenzulassen. Der",
  "naechste CI-Lauf meldet die neuen und nennt sie. Genau das ist gerade",
  "geschehen: das Pruefdeck hat eine Folie dazubekommen -- die Szene, die",
  "wachsen darf --, und pruefdeck/satz und pruefdeck/satzBytes stehen deshalb",
  "nur noch fuer darwin da.",
  "",
  "Die Vollbilduhr hat sprecher in allen 16 Decks um genau eins gehoben: sie",
  "legte ein Minutenfeld in den Fuss der Sprecherbox, und ein DOM-Knoten haengt",
  "an keiner Schrift. Die beiden geteilten Werte wurden deshalb mit +1",
  "nachgezogen und nicht entfernt.",
  "",
  "Der Kachelentwurf der Sprecheransicht hat sprecher danach in allen 16 Decks",
  "um genau sieben gehoben, und zwar um dieselben sieben: die Kopfzeile mit",
  "ihren zwei Gruppen ist fort, dafuer stehen fuenf Kacheln da, jede mit einer",
  "Marke, und die Kachelzeile um vier davon. Dass die Zahl auf allen 16 Decks",
  "dieselbe ist, ist selbst die Probe -- ein Deck, bei dem sie abwiche, haette",
  "mehr veraendert als den Aufbau. Die beiden geteilten Werte sind wieder mit",
  "+7 nachgezogen.",
  "",
  "pruefdeck/satz und satzBytes haben sich dabei um 6274 Bytes verschoben, und",
  "die Zahl geht auf: das Stilblatt ist um 6177 Bytes gewachsen -- es steht mit",
  "im Satz, herausgeschnitten wird nur der JS-Block -- und die englischen",
  "Laufzeitwoerter um 97, drei neue Schluessel und zwei laengere Hilfetexte.",
  "Ihre linux-Werte waren schon fort und sind es geblieben.",
  "",
  "Dieser Absatz stand einmal von Hand in soll.json und war nach dem ersten",
  "--neu-soll fort: was hier nicht steht, ueberlebt keine Neuaufnahme."
];

// ── Welche Decks ────────────────────────────────────────────────────────────
// Die fünfzehn Beispiele plus das Prüfdeck. Letzteres steht nicht unter
// `examples/`, weil es nicht auf die Website gehört; es wird hier übersetzt.
// Es deckt ab, was die anderen nicht anfassen. Nachgezählt in ihren Quellen:
// `after: "dimmed"` 0x, `stagger(dim: true)` 0x, `invert` 0x, `info()` 0x,
// `fit` 0x. Ohne das Prüfdeck kann man diese fünf zerstören, ohne dass hier
// eine Zahl wackelt.
//
// `ziehen` ist das einzige Beispiel mit `scene()`. Es trägt drei Szenen und
// ein Daumenkino und ist deshalb das größte Deck der Reihe: seine Schrittzahl
// hängt an den Halten der Szenen, nicht an Einblendungen, und eine Szene, die
// aufhörte, ihre Halte zu zählen, fiele hier als Erstes auf.
//
// Die beiden GeoGebra-Decks messen den Rahmen, nicht das Applet. Was hier eine
// Zahl hat -- Folien, Schritte, Elemente, gezeichnet und gedimmt, Grund, Hash,
// Sprecheransicht --, entsteht in Typst und in der Laufzeit; was in dem
// Rahmen läuft, holt der Browser von `geogebra.org` und meldet sich in seinem
// eigenen Fenster. Der Lauf ist deshalb nicht vom Netz abhängig: gemessen
// ergeben beide Decks mit und ohne erreichbares GeoGebra dieselben Zahlen.
const BEISPIELE = ["tour", "theme-default", "theme-editorial",
                   "theme-lesson", "theme-night", "theme-plain", "ziehen",
                   "geogebra", "geogebra-sprecher", "anziehen", "zeichnen",
                   "vortragen", "mosaic-editorial", "mosaic-manifesto",
                   "mosaic-greyscale", "unterrichten", "gliedern"];

// Kein Beispiel darf hier fehlen. Diese Liste war einmal von Hand gepflegt,
// und zwei frisch gebaute Decks sind dabei stillschweigend durchgerutscht:
// gefahren wurde, was hier stand, gemeldet wurde nichts, der Lauf war grün.
// Darum wird jetzt gegengelesen, was `build-site.sh` tatsächlich abgelegt hat.
// `index` und `en` sind die beiden Übersichtsseiten, deutsch und englisch.
const NICHT_DECK = ["index", "en"];

// Decks mit einem Applet darin. Sie werden mit abgeklemmtem GeoGebra gefahren,
// siehe `ohneGeoGebra`.
const MIT_APPLET = ["geogebra", "geogebra-sprecher", "tour"];

// Wohin die Applets statt zu `geogebra.org` greifen. Port 9 ist der
// Mülleimer-Port: die Verbindung wird sofort abgelehnt, es wird nichts
// gewartet.
const TOTE_QUELLE = "http://127.0.0.1:9/";
const GGB_QUELLE = "https://www.geogebra.org/apps/";

// Ein Deck mit Applets, aber ohne GeoGebra dahinter.
//
// Zwei Gründe, und der zweite ist der zwingende.
//
// Erstens gehört das Applet nicht zu dem, was hier gemessen wird. Der Lauf
// zählt Folien, Schritte, Elemente, Gezeichnetes, Gedimmtes, Gründe, den
// Wiedereintritt und die Sprecheransicht -- alles Zahlen, die in Typst und in
// der Laufzeit entstehen. Was in dem Rahmen läuft, steht ausdrücklich außen
// vor. Gemessen: dasselbe Deck einmal mit geladenem GeoGebra und einmal mit
// abgeklemmtem liefert eine zeichengleiche Messreihe, bis auf die letzte
// Ziffer jeder Zeile.
//
// Zweitens legt ein geladenes Applet den Lauf lahm. Gemessen in Chrome
// headless: sobald die drei Applets eines Decks leben, kehrt das nächste
// `Page.navigate` nicht mehr zurück -- über eine Minute gewartet, dann
// abgebrochen. Mit abgeklemmter Quelle sind es 0,6 Sekunden. Der Lauf hing
// also nicht an einer Animation, sondern an der Seite, die er verlassen
// wollte.
//
// Ausgetauscht wird allein die Adresse, von der das Applet sein GeoGebra holt.
// Die Laufzeit im Deck bleibt wörtlich stehen, und dass es dieselbe ist wie
// die im Paket, prüft der Lauf weiter unten ohnehin nach.
function ohneGeoGebra(datei) {
  const text = fs.readFileSync(datei, "utf8");
  if (text.indexOf(GGB_QUELLE) < 0) return datei;
  const ordner = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-ggb-"));
  const aus = path.join(ordner, path.basename(datei));
  fs.writeFileSync(aus, text.split(GGB_QUELLE).join(TOTE_QUELLE), "utf8");
  // Und daneben alles, was im Ordner des Originals liegt. Ein Deck lädt seine
  // Medien relativ, und die Kopie liegt woanders: als `tour` ein Applet bekam
  // und damit hier hereinkam, meldete der Lauf sofort
  // `error: file:///…/typstage-ggb-…/demo.mp4`. Das Video lag noch im
  // Beispielordner. Verknüpfungen statt Kopien, weil `mosaic-bilder/` und
  // `medien/` sonst bei jedem Lauf mitwandern würden.
  const quelle = path.dirname(datei);
  for (const name of fs.readdirSync(quelle)) {
    if (name === path.basename(datei)) continue;
    try { fs.symlinkSync(path.join(quelle, name), path.join(ordner, name)); }
    catch (e) { /* schon da oder nicht verknüpfbar -- dann eben nicht */ }
  }
  return aus;
}

// Die Laufzeit, wie sie im Paket liegt. Jedes Deck muss genau diese tragen.
const LAUFZEIT = fs.readFileSync(path.join(WURZEL, "assets", "typstage-0.1.1.js"));

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

// Gegenprobe zum Melder für wandernde Szenen. `wanderung.typ` ist ein Deck,
// dessen Szene mit dem Wert wächst, und es darf deshalb *nicht* übersetzen.
// Dieselbe Vorkehrung wie beim Überlauf: das Prüfdeck nebenan läuft auf der
// Vorgabe `drift: "error"` durch, ohne dass eine Szene dort wanderte, und
// sagt damit nur, dass der Prüfgang läuft -- nicht, dass er trifft.
function wanderungProbe() {
  try {
    decklaufBauen("wanderung");
  } catch (e) {
    if (/frames of different sizes/.test(e.meldung || "")) return null;
    return "wanderung.typ brach ab, aber nicht an der wandernden Szene: "
      + String(e.meldung || "").slice(0, 300);
  }
  return "wanderung.typ ließ sich übersetzen. Der Melder sieht nicht mehr, "
    + "dass die Bilder einer Szene verschieden groß sind.";
}

// Gegenprobe zu `split-body`. `gitter.typ` stellt dieselbe Tabelle viermal
// hin -- roh, in `text()`, im Inhaltsblock, in einer `box` -- und alle vier
// müssen gleich viele gestrichene Pfade tragen.
//
// Warum das im Browser keine Zahl hat und deshalb hier steht: die Striche
// entstehen in Typst und stehen im Hintergrund-SVG der Folie. Die Laufzeit
// sieht sie nie an, kein Element trägt ein `ts-`-Merkmal, und der Sollstand
// des Prüfdecks bewegte sich keinen Zähler, als die Striche verschwanden --
// gemessen. Sichtbar wird der Verlust erst, wenn man die vier Fassungen
// nebeneinanderlegt.
//
// Verglichen wird gegen die rohe Fassung und nicht gegen eine feste Zahl:
// was das Thema selbst zieht, steht auf allen vier Folien gleich und fällt
// heraus. Die Probe hängt so an keiner Schrift und an keinem Rechner.
function gitterProbe() {
  let datei;
  try { datei = decklaufBauen("gitter"); }
  catch (e) {
    return "gitter.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300);
  }
  const html = fs.readFileSync(datei, "utf8");
  // `<defs>` heraus: dort liegen die Glyphenumrisse, und die zählen mit,
  // sobald ein Titel einen Buchstaben mehr hat als der nächste.
  const folien = html.split('<section class="ts-slide"').slice(1)
    .map(s => s.split("</section>")[0].replace(/<defs>[\s\S]*?<\/defs>/g, ""))
    .map(s => (s.match(/<path[^>]*\sstroke=/g) || []).length);
  const NAMEN = ["roh", "text()", "Inhaltsblock", "box"];
  if (folien.length !== NAMEN.length) {
    return "gitter.typ hat " + folien.length + " Folien statt " + NAMEN.length
      + ". Die Probe vergleicht vier Verpackungen derselben Tabelle; fehlt "
      + "eine, vergleicht sie nichts mehr.";
  }
  if (folien[0] === 0) {
    return "schon die rohe Tabelle in gitter.typ trägt keinen gestrichenen "
      + "Pfad. Dann misst die Probe nicht mehr, was sie messen soll -- "
      + "vermutlich hat die Tabelle ihr stroke: verloren.";
  }
  const abweichend = folien.map((n, i) => [NAMEN[i], n])
    .filter(([, n]) => n !== folien[0]);
  if (!abweichend.length) return null;
  return "dieselbe Tabelle trägt je nach Verpackung verschieden viele "
    + "Striche: roh " + folien[0] + ", aber "
    + abweichend.map(([n, z]) => n + " " + z).join(", ")
    + ". Ein Rumpf ist an einem `children`-Feld zerlegt worden, das keiner "
    + "Sequenz gehört: die Zellen stehen dann als Geschwister nebeneinander "
    + "und die Tabelle ist ein Fließabsatz.";
}

// Gegenprobe zur Sprechernotiz. `notiz.typ` trägt eine Notiz aus zwei
// Absätzen, und die muss mit der Leerzeile dazwischen ankommen.
//
// Zwei Hälften, denn eine allein trägt nichts. Die erste ist der Wortlaut in
// `data-note`: die Notiz ist ein Attribut und kann nur eine Zeichenkette
// sein, also steht der Absatz dort als Umbruch oder gar nicht. Die zweite ist
// `white-space: pre-wrap` am Notizfeld -- ohne die faltete der Browser
// denselben Umbruch zu einem Leerzeichen zurück, und der Absatz wäre wieder
// fort, obwohl die Zeichenkette stimmt. Genau deshalb ist es eine Leerzeile
// und kein Leerzeichen geworden: die Blase der `s`-Taste steht auf `normal`
// und faltet ohnehin, das Notizfeld nicht. Eine Zeichenkette, zwei Leser,
// jeder bekommt das Seine.
//
// Der Wortlaut wird verglichen, nicht die Zeilenzahl: wie viele Zeilen daraus
// werden, hängt am Umbruch und damit an der Schrift des Rechners.
function notizProbe() {
  let datei;
  try { datei = decklaufBauen("notiz"); }
  catch (e) {
    return "notiz.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300);
  }
  const html = fs.readFileSync(datei, "utf8");
  const treffer = html.match(/ data-note="([^"]*)"/);
  if (!treffer) {
    return "notiz.typ trägt kein data-note mehr. Die Notiz erreicht die "
      + "Sprecheransicht nur über dieses Attribut; ohne es steht dort "
      + "\"no note\".";
  }
  const SOLL = "Erster Absatz.\n\nZweiter Absatz.";
  if (treffer[1] !== SOLL) {
    return "die zweiabsätzige Notiz kam als " + JSON.stringify(treffer[1])
      + " an, erwartet war " + JSON.stringify(SOLL) + ". Ein Absatz ist auf "
      + "dem Weg ins Attribut verlorengegangen -- kennt `plain-text` den "
      + "`parbreak` nicht, stoßen die Sätze ohne ein Leerzeichen aneinander.";
  }
  const css = fs.readFileSync(path.join(WURZEL, "assets",
                                        "typstage-0.1.1.css"), "utf8");
  if (!/\.ts-sp-notiz\{[^}]*white-space:\s*pre-wrap/.test(css)) {
    return "das Notizfeld der Sprecheransicht steht nicht mehr auf "
      + "white-space: pre-wrap. Der Umbruch im Attribut stimmt dann zwar, "
      + "aber der Browser faltet ihn zu einem Leerzeichen, und der Absatz "
      + "ist trotzdem fort.";
  }
  return null;
}

// Und dasselbe Deck noch einmal auf Papier. Der Browser sieht nur den
// HTML-Zweig, und `build` hat einen zweiten: dort wird nur die letzte Stufe
// gesetzt, und der Schrittzähler muss trotzdem so weit laufen wie im Browser.
// Die Zusicherung dazu steht im Prüfdeck selbst; hier wird sie nur gefragt.
// Ohne diesen Aufruf bliebe der ganze Papierzweig ungeprüft -- gemessen, indem
// dort das Weiterzählen wegfiel: der Browserlauf blieb grün.
function papierProbe() {
  const quelle = path.join(__dirname, "decklauf", "pruefdeck.typ");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-pp2-")),
                        "pruefdeck.pdf");
  try {
    execFileSync("typst", ["compile", "--root", WURZEL,
                           "--package-path", paketpfad, quelle, aus],
                 { stdio: ["ignore", "ignore", "pipe"] });
  } catch (e) {
    return "Das Prüfdeck ließ sich nicht auf Papier übersetzen: "
      + String(e.stderr || e.message).slice(0, 400);
  }
  return null;
}

// Ob `tiles` seine Kurve und seine Dauer weiterreicht.
//
// Ohne Browser, denn hier ist nichts zu fahren: die beiden Werte entstehen in
// Typst und stehen als `data-duration` und `data-easing` in der Ausgabe. Was
// die Laufzeit daraus macht, prüft das Prüfdeck an anderer Stelle.
//
// Zwei Fragen. Mit Angabe muss jede der sechs Kacheln beide Werte tragen --
// `tiles` nahm sie lange gar nicht entgegen, und ein Deck, das ein Raster mit
// Rückschwung wollte, musste die `anim`s von Hand in ein `grid` schreiben.
// Ohne Angabe darf keine Kachel sie tragen: `auto` schreibt kein Attribut, und
// jedes Deck von gestern soll Byte für Byte dasselbe bleiben.
function kachelProbe() {
  let datei;
  try { datei = decklaufBauen("kacheln"); }
  catch (e) {
    return "kacheln.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300)
      + " -- nimmt tiles() duration und easing noch entgegen?";
  }
  const html = fs.readFileSync(datei, "utf8");
  // Die Kurve steht aufgelöst da, nicht unter ihrem Namen: `kurve()` schlägt
  // sie beim Übersetzen nach, damit ein Name, den es nicht gibt, dort auffällt
  // und nicht als stille Blende im Vortrag.
  const AUS_BACK = "cubic-bezier(.34,1.56,.64,1)";
  const dauer = (html.match(/data-duration="1500"/g) || []).length;
  const kurve = (html.match(/data-easing="cubic-bezier\(\.34,1\.56,\.64,1\)"/g) || []).length;
  if (dauer !== 6 || kurve !== 6) {
    return dauer + " Kacheln mit der Dauer und " + kurve + " mit der Kurve "
      + AUS_BACK + " statt je sechs. tiles() reicht nicht durch, was ihm "
      + "gegeben wurde, und ein Raster mit Rückschwung muss wieder von Hand "
      + "in ein grid geschrieben werden.";
  }
  // Und die Gegenprobe: die drei ohne Angabe. Insgesamt also nicht mehr als
  // die sechs von oben.
  const alleDauer = (html.match(/data-duration="/g) || []).length;
  const alleKurve = (html.match(/data-easing="/g) || []).length;
  if (alleDauer !== 6 || alleKurve !== 6) {
    return "ohne Angabe trugen Kacheln trotzdem ein Attribut: "
      + alleDauer + " mal data-duration und " + alleKurve + " mal data-easing "
      + "im ganzen Deck statt je sechs. auto schreibt kein Attribut, sonst "
      + "verschiebt sich der Satz jedes Decks von gestern.";
  }
  return null;
}

// Gegenprobe zur Klage über `enter: "draw"` ohne gestrichenen Pfad.
//
// `ohne-strich.typ` übersetzt anstandslos, und das ist der Punkt: diese
// Meldung ist zur Übersetzungszeit nicht zu haben. Typst gibt das SVG erst
// beim Export heraus, und im Dokument gibt es keine Frage, die „hat dieser
// Inhalt eine Kontur" beantwortete. Erst im Browser steht der Pfad da.
//
// Also läuft das Deck im Browser, und hier wird nachgesehen, ob genau eine
// Klage herauskommt. Ohne das könnte die Klage aufhören zu klagen und
// niemandem fiele es auf: das Element blendet dann still auf, und eine stille
// Blende sieht aus wie eine gewollte.
//
// Genau eine, nicht mindestens eine: die Klage geht einmal je Element heraus
// und nicht einmal je Schritt. Wer sechsmal durch das Deck blättert, soll sie
// nicht sechsmal lesen.
async function ohneStrichProbe(b) {
  let datei;
  try { datei = decklaufBauen("ohne-strich"); }
  catch (e) {
    return "ohne-strich.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300);
  }
  await laden(b, "about:blank");
  if (!await laden(b, "file://" + datei)) return "ohne-strich.typ lud nicht";
  const roh = await b.ev(`(async function () {
    var p = typstage.pruef;
    // Durch das ganze Deck: die Klage faellt beim Auftritt, und der faellt
    // nicht beim Betreten der Folie.
    typstage.goto(0, true); await p.ruhig(4000);
    for (var i = 1; i < p.schritte; i++) { typstage.goto(i); await p.ruhig(4000); }
    return JSON.stringify(p.fehler());
  })()`);
  const klagen = JSON.parse(roh).filter(x => x.indexOf('enter: "draw"') >= 0);
  const fremd = JSON.parse(roh).filter(x => x.indexOf('enter: "draw"') < 0);
  if (fremd.length) return "ohne-strich.typ meldete außerdem: " + fremd.join(" | ");
  if (klagen.length === 1) return null;
  if (klagen.length === 0) {
    return "ein Element mit enter: \"draw\" ohne gestrichenen Pfad blendete "
      + "still auf. Die Laufzeit sagt nichts mehr dazu, und eine stille Blende "
      + "sieht aus wie eine gewollte.";
  }
  return klagen.length + " Klagen statt einer. Sie gehört einmal je Element "
    + "heraus, nicht einmal je Schritt.";
}

// Der Weg durch ein ganzes Deck, den beide Proben unten brauchen. Die Klage
// fällt beim Auftritt, und der fällt nicht beim Betreten der Folie.
const DURCH_DAS_DECK = `
  var p = typstage.pruef;
  typstage.goto(0, true); await p.ruhig(4000);
  for (var i = 1; i < p.schritte; i++) { typstage.goto(i); await p.ruhig(4000); }
`;

// Zwei Elemente, die im Fluss nichts messen, und die trotzdem stehen müssen.
//
// `schmal.typ` sagt selbst, worum es geht. Hier steht, woran gemessen wird:
// an der Hülle, denn die Hülle war das Feld, das umfiel. Sie bekam `width: 0%`
// -- aus einer Marke ohne Ausdehnung bei der senkrechten Linie, aus einer
// Marke am falschen Ort bei den drei gesetzten Rechtecken --, und ein
// Ansichtsfenster der Breite null skaliert seinen Inhalt mit dem Faktor null.
// Das Element stand vollständig in der Seite und war nicht da.
//
// Drei Fragen, weil drei Dinge schiefgehen können. Keine Hülle ohne
// Ausdehnung: das ist der Verlust selbst. Die drei gesetzten auf einer Höhe
// und in gleichem Abstand: das ist die Treppe, die sie im Browser hinunter-
// liefen, während sie auf Papier nebeneinander standen. Und die Fehlerliste
// leer: ein Deck, das seine Elemente behält, hat nichts zu klagen.
//
// In Promille des Folienkastens gemessen und nicht in Pixeln. Die Bühne ist
// so groß, wie das Fenster es zulässt, und eine Zahl, die daran hängt, fiele
// bei jeder anderen Fenstergröße um.
async function schmalProbe(b) {
  let datei;
  try { datei = decklaufBauen("schmal"); }
  catch (e) {
    return "schmal.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300);
  }
  await laden(b, "about:blank");
  if (!await laden(b, "file://" + datei)) return "schmal.typ lud nicht";
  const roh = await b.ev(`(async function () {
    ${DURCH_DAS_DECK}
    var r = [];
    document.querySelectorAll(".ts-slide").forEach(function (f, i) {
      var svg = f.querySelector(".ts-bg svg");
      if (!svg) return;
      var bg = svg.getBoundingClientRect();
      f.querySelectorAll(".ts-el").forEach(function (el) {
        var h = el.getBoundingClientRect();
        r.push({ folie: i + 1, n: +el.dataset.n,
                 x: Math.round((h.left - bg.left) / bg.width * 1000),
                 y: Math.round((h.top - bg.top) / bg.height * 1000),
                 w: Math.round(h.width / bg.width * 1000),
                 h: Math.round(h.height / bg.height * 1000) });
      });
    });
    return JSON.stringify({ els: r, fehler: p.fehler() });
  })()`);
  const d = JSON.parse(roh);
  if (d.fehler.length) return "schmal.typ meldete: " + d.fehler.join(" | ");
  if (d.els.length !== 6) {
    return d.els.length + " verfolgte Elemente statt sechs. Das Deck hält zwei "
      + "Linien, ein gesetztes Rechteck ohne Ausrichtung und drei mit.";
  }
  const leer = d.els.filter(e => !e.w || !e.h);
  if (leer.length) {
    return leer.map(e => "Folie " + e.folie + ", Element " + e.n).join(", ")
      + ": Hülle ohne Ausdehnung (" + leer.map(e => e.w + "x" + e.h).join(", ")
      + " Promille). Ein Ansichtsfenster der Breite null skaliert seinen Inhalt "
      + "mit dem Faktor null: das Element steht in der Seite und ist nicht da. "
      + "Im PDF steht es.";
  }
  // Die drei gesetzten. Sie stehen auf derselben Zeile und in gleichem
  // Abstand, so wie sie auf Papier stehen.
  //
  // Über die letzte Folie gesucht und nicht über eine gezählte: die Titelfolie
  // steht vorn, und wer hier eine 2 hinschreibt, hat sie vergessen.
  const letzte = Math.max.apply(null, d.els.map(e => e.folie));
  const gesetzt = d.els.filter(e => e.folie === letzte).sort((a, c) => a.x - c.x);
  if (gesetzt.length !== 3) {
    return gesetzt.length + " gesetzte Rechtecke statt dreier auf Folie "
      + letzte;
  }
  if (gesetzt[0].y !== gesetzt[1].y || gesetzt[1].y !== gesetzt[2].y) {
    return "die drei gesetzten Rechtecke stehen auf den Höhen "
      + gesetzt.map(e => e.y).join(", ") + " Promille statt auf einer. Im "
      + "Browser laufen sie eine Treppe hinunter, auf Papier stehen sie "
      + "nebeneinander: die Hülle nimmt Platz im Fluss, statt keinen zu nehmen.";
  }
  const ab = [gesetzt[1].x - gesetzt[0].x, gesetzt[2].x - gesetzt[1].x];
  if (Math.abs(ab[0] - ab[1]) > 1) {
    return "die drei gesetzten Rechtecke stehen in den Abständen "
      + ab.join(" und ") + " Promille statt in gleichen. Ihr dx ist dreimal "
      + "dasselbe Stück.";
  }
  return null;
}

// Gegenprobe zur Klage über ein verfolgtes Element, das keinen Platz findet.
//
// Dasselbe Muster wie bei `ohne-strich.typ`, und aus demselben Grund:
// `ohne-flaeche.typ` übersetzt anstandslos, denn keine der beiden Meldungen
// ist zur Übersetzungszeit zu haben. Erst im Browser liegt das Rechteck da.
//
// Genau eine und genau zwei, nicht mindestens: die Klage geht einmal je
// Element heraus und nicht einmal je Schritt.
//
// Warum es diese Probe gibt: der stille Verlust ist der eine Ausgang, den es
// nicht geben darf. Ein Deck, das ein Element verliert, muss das sagen. Hört
// die Laufzeit damit auf, sagt es sonst niemand -- am Deck ist nichts zu
// sehen, es fehlt ja gerade das, was zu sehen wäre.
async function ohneFlaecheProbe(b) {
  let datei;
  try { datei = decklaufBauen("ohne-flaeche"); }
  catch (e) {
    return "ohne-flaeche.typ ließ sich nicht übersetzen: "
      + String(e.meldung || "").slice(0, 300);
  }
  await laden(b, "about:blank");
  if (!await laden(b, "file://" + datei)) return "ohne-flaeche.typ lud nicht";
  const roh = await b.ev(`(async function () {
    ${DURCH_DAS_DECK}
    return JSON.stringify(p.fehler());
  })()`);
  const alle = JSON.parse(roh);
  const ohneMass = alle.filter(x => x.indexOf("has a marker with no") >= 0);
  const ohneMarke = alle.filter(x => x.indexOf("finds no marker to sit on") >= 0);
  const fremd = alle.filter(x => ohneMass.indexOf(x) < 0
                                 && ohneMarke.indexOf(x) < 0);
  if (fremd.length) return "ohne-flaeche.typ meldete außerdem: " + fremd.join(" | ");
  if (ohneMass.length !== 1) {
    return ohneMass.length + " Klagen über eine Marke ohne Ausdehnung statt "
      + "einer. Bei null: das Element steht in der Seite, ist nicht zu sehen, "
      + "und die Laufzeit sagt nichts mehr dazu -- der stille Verlust ist "
      + "zurück.";
  }
  if (ohneMarke.length !== 2) {
    return ohneMarke.length + " Klagen über eine fehlende Marke statt zweier. "
      + "Sechs verfolgte Elemente ineinander, vier Runden zum Stellen: die "
      + "beiden innersten finden keinen Ort und bleiben liegen.";
  }
  return null;
}

// Was „Bewegung reduzieren" aus einer Zeichnung macht.
//
// Die Regel des Pakets lautet: Deckkraft bleibt, Weg fällt weg. Das Zeichnen
// *ist* der Weg -- ein Strich, der sich malt, hat keine Deckkraft, die davon
// übrig bliebe --, also hält die Feder still und es bleibt bei der Blende, die
// ohnehin darunter lief.
//
// Der Lauf selbst weist einen Browser mit der Einstellung ab, aus gutem Grund:
// dann flöge kein Morph und vierzehn Zahlen fielen um. Diese eine Frage lässt
// sich aber vortäuschen, und ohne sie bliebe der ganze Zweig ungeprüft --
// gemessen, indem die Abfrage in der Laufzeit wegfiel: keine Zahl des Laufs
// bewegte sich.
//
// Vorgetäuscht am Prototyp und nicht an einer neuen Abfrage: die Laufzeit hat
// ihre MediaQueryList beim Laden gemerkt und fragt sie bei jedem Schritt neu;
// ein Getter am Prototyp erreicht genau diese. Es geschieht auf einer eigenen,
// zuletzt geladenen Seite, damit es nichts anderes mehr trifft.
async function leiserProbe(b, datei) {
  await laden(b, "about:blank");
  if (!await laden(b, "file://" + datei)) return "das Prüfdeck lud nicht";
  const roh = await b.ev(`(async function () {
    Object.defineProperty(MediaQueryList.prototype, "matches", {
      configurable: true,
      get: function () { return this.media.indexOf("reduced-motion") >= 0; }
    });
    if (!matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return JSON.stringify({ fehlt: "die Einstellung liess sich nicht vortaeuschen" });
    }
    var p = typstage.pruef, S = typstage.steps;
    var el = document.querySelector('.ts-el[data-enter="draw"]');
    if (!el) return JSON.stringify({ fehlt: "kein Element mit enter=draw" });
    var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
    var nr = folien.indexOf(el.closest(".ts-slide"));
    var ab = +(el.dataset.at.match(/[0-9]+/) || [1])[0];
    var davor = -1, ziel = -1;
    for (var i = 0; i < S.length; i++) if (S[i].slide === nr) {
      if (S[i].step === ab - 1) davor = i;
      if (S[i].step === ab) ziel = i;
    }
    if (davor < 0 || ziel < 0) return JSON.stringify({ fehlt: "Schritt nicht gefunden" });
    typstage.goto(davor, true); await p.ruhig(4000);
    var vor = p.stand().feder;
    typstage.goto(ziel);
    var eig = el.getAnimations()[0];
    var mitten = {
      federn: el.querySelectorAll("[data-ts-feder]").length,
      eKf: eig ? eig.effect.getKeyframes().map(function (k) {
        return String(k.opacity);
      }) : null
    };
    await p.ruhig(4000);
    return JSON.stringify({ mitten: mitten, gezogen: p.stand().feder - vor,
                            an: el.dataset.on === "1" ? 1 : 0,
                            fehler: p.fehler() });
  })()`);
  const r = JSON.parse(roh);
  if (r.fehlt) return r.fehlt;
  if (r.mitten.federn || r.gezogen) {
    return "unter „Bewegung reduzieren\" fuhr die Feder trotzdem: "
      + r.mitten.federn + " am Pfad, " + r.gezogen + " gezogen. Das Zeichnen "
      + "ist der Weg, und der faellt dort weg.";
  }
  if (!r.mitten.eKf || r.mitten.eKf.join(">") !== "0>1") {
    return "unter „Bewegung reduzieren\" blendete die Zeichnung nicht auf: "
      + JSON.stringify(r.mitten.eKf) + " statt 0>1. Die Deckkraft bleibt, auch "
      + "wenn der Weg wegfaellt.";
  }
  if (!r.an) return "unter „Bewegung reduzieren\" stand die Zeichnung danach nicht da";
  if (r.fehler.length) return "unter „Bewegung reduzieren\": " + r.fehler.join(" | ");
  return null;
}

// Die Vollbilduhr, unter festgenagelter Uhr.
//
// Sie ist der Grund, warum sie aus `beat` gezeichnet wird und nicht aus
// `Date.now()`: nur so gibt derselbe Zeitpunkt in zwei Läufen dieselbe Zahl.
// Die vorhandene Sprecheruhr liest die Wanduhr und ist deshalb nicht prüfbar
// -- sie steht in keinem Sollstand, und das ist keine Nachlässigkeit, sondern
// die Folge der Bauart.
//
// Geprüft wird an drei Zeitpunkten, an der Schwelle bei null, über einen
// Folienwechsel und einen Sprung hinweg, und dazu die drei Kreuzungen, an
// denen die Uhr auf einen anderen Bühnenzustand trifft. Und dass `ruhig()`
// zurückkommt: eine Uhr, die als Web-Animation gebaut wäre, ließe jeden
// Aufruf in die Frist laufen -- gemessen, 4143 ms statt 19 --, und der Lauf
// ruft ihn auf jedem Schritt.
async function uhrProbe(b, datei) {
  await laden(b, "about:blank");
  if (!await laden(b, "file://" + datei)) return "das Prüfdeck lud nicht";
  const roh = await b.ev(`(async function () {
    var p = typstage.pruef;
    if (!typstage.clock) return JSON.stringify({ fehlt: "typstage.clock fehlt" });
    function bei(ms) { p.uhr(ms); return neuesBild(); }
    // Ein Bild abwarten: gezeichnet wird in beat, und beat haengt am
    // Bildtakt des Browsers. Sofort danach zu fragen laese die vorige Zahl
    // lesen -- ein Wettlauf, der auf einem schnellen Rechner heil aussieht.
    function neuesBild() {
      return new Promise(function (f) {
        requestAnimationFrame(function () { requestAnimationFrame(f); });
      });
    }
    var aus = {};
    typstage.goto(0, true);
    p.uhr(0);
    typstage.clock.start(300);
    await neuesBild();
    aus.start = p.clock();
    await bei(60000);  aus.eineMinute = p.clock().text;
    await bei(299000); aus.letzteSekunde = p.clock().text;
    await bei(300000); aus.schwelle = p.clock();
    aus.spalteVorher = document.querySelector("#ts-clock .ts-clock-num").textContent;
    await bei(300001); aus.knappDrueber = p.clock();
    aus.wort = document.querySelector("#ts-clock .ts-clock-word").textContent;
    aus.spalte = document.querySelector("#ts-clock .ts-clock-num").textContent;
    await bei(371000); aus.ueberzeit = p.clock().text;
    // Gedeckelt bei der Dauer, hoechstens einer halben Stunde.
    await bei(300000 + 900000); aus.deckel = p.clock().text;
    // Festgenagelt heisst still: dieselbe Frage, eine Sekunde Wanduhr spaeter.
    var a = p.clock().text;
    await new Promise(function (f) { setTimeout(f, 1100); });
    aus.still = [a, p.clock().text];
    // Ueber einen Folienwechsel und einen Sprung hinweg.
    await bei(120000);
    typstage.goto(1); await p.ruhig(4000);
    aus.nachFolienwechsel = p.clock().text;
    typstage.goto(typstage.steps.length - 1, true); await p.ruhig(4000);
    aus.nachSprung = p.clock().text;
    typstage.goto(0, true); await p.ruhig(4000);
    aus.nachSprungZurueck = p.clock().text;
    // Und ruhig() kommt zurueck, ohne in die Frist zu laufen.
    var t0 = Date.now();
    aus.ruhig = await p.ruhig(4000);
    aus.ruhigMs = Date.now() - t0;
    // Die drei Kreuzungen.
    var k = document.getElementById("ts-clock");
    aus.zUhr = +getComputedStyle(k).zIndex;
    aus.zUebersicht = +getComputedStyle(document.getElementById("ts-overview")).zIndex;
    aus.zHinweis = +getComputedStyle(document.getElementById("ts-hint")).zIndex;
    document.documentElement.dataset.tsSchwarz = "1";
    await neuesBild();
    aus.unterSchwarz = getComputedStyle(k).opacity;
    delete document.documentElement.dataset.tsSchwarz;
    await neuesBild();
    aus.wiederDa = getComputedStyle(k).display;
    // Die dritte Kreuzung, die Druckansicht. Gelesen wird die Regel selbst und
    // nicht das umgeschaltete Medium: das Medium umzustellen kann nur der eine
    // der beiden Browser, die dieser Lauf fahren soll. Im @media-print-Block
    // muss #ts-clock stehen und dort display:none bekommen -- sonst liegt eine
    // schwarze Countdown-Seite im Handout.
    aus.druck = (function () {
      var treffer = 0;
      for (var i = 0; i < document.styleSheets.length; i++) {
        var b;
        try { b = document.styleSheets[i].cssRules; } catch (e) { continue; }
        for (var j = 0; j < b.length; j++) {
          var m = b[j];
          if (!m.media || String(m.media.mediaText).indexOf("print") < 0) continue;
          for (var n = 0; n < m.cssRules.length; n++) {
            var t = m.cssRules[n];
            if (t.selectorText && t.selectorText.indexOf("#ts-clock") >= 0
                && t.style.display === "none") treffer++;
          }
        }
      }
      return treffer;
    })();
    // Und aus.
    typstage.clock.stop();
    await neuesBild();
    aus.ausDanach = p.clock();
    aus.ausSchicht = getComputedStyle(k).display;
    aus.fehler = p.fehler();
    p.uhr();
    return JSON.stringify(aus);
  })()`);
  const r = JSON.parse(roh);
  if (r.fehlt) return r.fehlt;
  const klage = [];
  const gleich = (was, ist, soll) => {
    if (JSON.stringify(ist) !== JSON.stringify(soll)) {
      klage.push(was + ": " + JSON.stringify(ist) + " statt " + JSON.stringify(soll));
    }
  };
  gleich("beim Stellen", [r.start.text, r.start.duration, r.start.over],
         ["05:00", 300, false]);
  gleich("nach einer Minute", r.eineMinute, "04:00");
  gleich("die letzte Sekunde", r.letzteSekunde, "00:01");
  gleich("an der Schwelle", [r.schwelle.text, r.schwelle.over], ["00:00", false]);
  gleich("eine Millisekunde darüber", [r.knappDrueber.text, r.knappDrueber.over],
         ["+00:01", true]);
  // Das Wort war vorher nicht da; sein Erscheinen ist das Ereignis.
  if (!r.wort) klage.push("in der Überzeit steht kein Wort über den Ziffern");
  // Die Vorzeichenspalte: in der Überzeit trägt sie das `+`, davor ein
  // Leerzeichen. Ohne das springen die Ziffern beim Umschlag seitlich weg.
  if (r.spalte.charAt(0) !== "+") {
    klage.push("die Vorzeichenspalte trägt in der Überzeit " + JSON.stringify(r.spalte));
  }
  if (r.spalteVorher.charAt(0) !== " ") {
    klage.push("vor der Überzeit ist die Vorzeichenspalte nicht freigehalten: "
      + JSON.stringify(r.spalteVorher) + ". Ohne das freie Zeichen springen die "
      + "Ziffern beim Umschlag um eine Spalte zur Seite.");
  }
  gleich("in der Überzeit", r.ueberzeit, "+01:11");
  gleich("am Deckel", r.deckel, "+05:00");
  gleich("festgenagelt heißt still", r.still, [r.still[0], r.still[0]]);
  gleich("nach einem Folienwechsel", r.nachFolienwechsel, "03:00");
  gleich("nach einem Sprung nach hinten", r.nachSprung, "03:00");
  gleich("nach einem Sprung nach vorn", r.nachSprungZurueck, "03:00");
  if (r.ruhig !== "ruhig") {
    klage.push("pruef.ruhig() gab " + r.ruhig + " zurück und nicht \"ruhig\" -- "
      + "die Uhr wartet auf etwas, oder sie ist eine Web-Animation geworden");
  }
  if (r.ruhigMs > 1500) {
    klage.push("pruef.ruhig() brauchte " + r.ruhigMs + " ms. Der Lauf ruft ihn "
      + "auf jedem Schritt; eine Uhr, auf die er wartet, ist kein Aufpreis, "
      + "sondern ein Bruch.");
  }
  if (!(r.zUhr < r.zUebersicht && r.zUhr < r.zHinweis)) {
    klage.push("die Uhr liegt auf " + r.zUhr + ", die Übersicht auf "
      + r.zUebersicht + ", der Hinweis auf " + r.zHinweis + ". Sie muss unter "
      + "beiden liegen, sonst ist `o` blind.");
  }
  if (r.unterSchwarz !== "0") {
    klage.push("unter `b schwarz` steht die Uhr auf Deckkraft " + r.unterSchwarz
      + ". Wer schwarz drückt, will nichts sehen. Schwarz gewinnt.");
  }
  if (r.wiederDa !== "flex") {
    klage.push("nach dem Aufheben von schwarz kam die Uhr nicht wieder: " + r.wiederDa);
  }
  if (!r.druck) {
    klage.push("keine Regel blendet `#ts-clock` unter `@media print` aus. Auf "
      + "Papier gibt es keine Pause, die zu Ende geht; ohne diese Zeile liegt "
      + "eine schwarze Countdown-Seite im Handout.");
  }
  if (r.ausDanach !== null) klage.push("`stop()` ließ sie stehen: " + JSON.stringify(r.ausDanach));
  if (r.ausSchicht !== "none") klage.push("die Uhrschicht blieb nach `stop()` auf " + r.ausSchicht);
  if (r.fehler.length) klage.push("Laufzeitfehler: " + r.fehler.join(" | "));
  return klage.length ? klage.join("; ") : null;
}

// ── Der Durchlauf, als ein Stück Seitencode ─────────────────────────────────
const DURCHLAUF = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  if (p.fassung !== 3) return JSON.stringify({ fassungFehler: p.fassung });
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

  // ── Die Hand, die eine cue-Gruppe bedient ────────────────────────────────
  //
  // Eine adaptive Gruppe kommt nicht von selbst herein. Ihre Punkte liegen an
  // den Zifferntasten, und goto() drueckt keine: es geht auf den Schritt, aber
  // der Punkt bleibt beiseitegestellt, weit hinter dem letzten Schritt des
  // Decks. Ein Lauf, der nur blaettert, misst auf einer cue-Folie durchgehend
  // 0/0 und haelt das fuer den Befund. Gemessen an vortragen: 13 seiner 44
  // Schritte lagen so im Dunkeln, und gerade das Neue an dem Deck war damit
  // nicht abgesichert.
  //
  // Genannt wird in geschriebener Reihenfolge, und nur der Punkt, dessen Platz
  // der Schritt ist, auf den es gerade geht. Das ist die eine Reihenfolge, die
  // sich wiederholen laesst -- ein Sprecher darf jede andere waehlen, aber ein
  // Sollwert kann nicht von seiner Laune abhaengen.
  //
  // Nach dem goto, nicht davor: ziffer() sucht den Schritt des Punktes auf der
  // Folie, auf der das Deck *steht*. Vorher gedrueckt suchte sie ihn auf der
  // vorigen und traefe eine fremde.
  function cueBedienen(ziel) {
    var g = p.adaptiv().filter(function (x) {
      return x.folie === ziel.slide && x.folge.length < x.nummern.length;
    })[0];
    if (!g) return false;
    if (parseInt(g.plaetze[g.folge.length], 10) !== ziel.step) return false;
    var offen = g.nummern.filter(function (n) { return g.folge.indexOf(n) < 0; });
    return p.ziffer(offen[0]);
  }

  typstage.goto(0, true); cueBedienen(S[0]); await ruhe(); vor.push(p.stand());
  for (var i = 1; i < p.schritte; i++) {
    var wechsel = S[i].slide !== S[i - 1].slide;
    typstage.goto(i);
    cueBedienen(S[i]);
    // Der alte Weg, nur zum Abgleich mitgezaehlt: sofort und ausschliesslich
    // beim Folienwechsel. Der Zaehler in der Laufzeit ist der massgebliche.
    if (wechsel) flyDom += FLY.querySelectorAll("*").length;
    await ruhe();
    vor.push(p.stand());
  }
  var vorFlieger = p.stand().flieger, vorFeder = p.stand().feder;
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
    feder: vorFeder, federRueck: p.stand().feder - vorFeder,
    // Kein Pfad darf nach der Fahrt noch eine Feder tragen. Am Ende gefragt,
    // wo die Buehne zur Ruhe gekommen ist.
    federOffen: p.stand().federOffen,
    flyDom: flyDom, flyDomRueck: flyDomRueck,
    fristen: fristen, grund: grund,
    vor: vor, zurueck: zurueck, fehler: p.fehler()
  });
})()`;

// ── Wie eine Stufe abtritt ──────────────────────────────────────────────────
//
// Der Durchlauf oben misst die Ruhezustände: auf jedem Schritt ist genau eine
// Stufe von `build` gezeichnet. Was er nicht sieht, ist der Weg dazwischen,
// und genau dort steckt die Absicht: die abtretende Stufe geht nicht, sie
// wartet, bis die neue vollständig dasteht (`exit: "hold"`).
//
// Ginge sie auf dem gewöhnlichen Weg, blendeten zwei fast gleiche Bilder
// gegeneinander, und die Tinte, die beide teilen, sänke währenddessen auf zwei
// Drittel: das ganze Bild blinkt bei jedem Schritt. Am Ruhezustand ist davon
// nichts zu sehen, deshalb wird hier die Animation selbst gefragt und nicht
// eine Deckkraft zu einem geratenen Zeitpunkt -- eine Messung, die an einer
// Uhr hängt, hängt am Rechner.
//
// Tempounabhängig: `--tempo` teilt beide Dauern durch dieselbe Zahl, also
// bleibt ihre Gleichheit stehen. In den Sollstand geht nur, was keine Dauer
// ist.
const HALTPROBE = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  var alle = [].slice.call(document.querySelectorAll('.ts-el[data-exit="hold"]'));
  if (alle.length < 2) return JSON.stringify({ fehlt: alle.length });
  var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
  var folie = alle[0].closest(".ts-slide");
  var nr = folien.indexOf(folie);
  var stufen = alle.filter(function (e) { return e.closest(".ts-slide") === folie; });
  var erste = -1;
  for (var i = 0; i < S.length; i++) if (S[i].slide === nr) { erste = i; break; }
  if (erste < 0) return JSON.stringify({ fehlt: -1 });
  typstage.goto(erste, true); await p.ruhig(4000);
  // Ein Schritt weiter, und sofort gefragt: zwischen goto und dieser Zeile
  // liegt kein await, die Animationen laufen also noch.
  typstage.goto(erste + 1);
  function lesen(el) {
    var a = el.getAnimations()[0];
    if (!a) return null;
    return { dauer: a.effect.getTiming().duration,
             kf: a.effect.getKeyframes().map(function (k) { return String(k.opacity); }) };
  }
  var raus = lesen(stufen[0]), rein = lesen(stufen[1]);
  await p.ruhig(4000);
  var an = stufen.filter(function (e) { return e.dataset.on === "1"; }).length;

  // Und derselbe Wechsel rueckwaerts. Vorwaerts wartet die abtretende Stufe,
  // bis die neue da ist; rueckwaerts kommt die *kleinere* Stufe herein und
  // liegt vollstaendig unter der groesseren, die noch abtritt. Sie hat nichts
  // zu blenden -- sie ist einfach da, und was verschwindet, ist allein die
  // Tinte, die die groessere mehr hat. Blendete sie doch auf, blendeten
  // wieder zwei fast gleiche Bilder gegeneinander: gemessen sank die geteilte
  // Tinte dabei auf 0,7522, und mit enter: "draw" von Hand gestapelt auf
  // 0,4348. Am Ruhezustand ist davon nichts zu sehen.
  //
  // Gefragt wird deshalb dreierlei: ob an der ankommenden Stufe ueberhaupt
  // eine Blende laeuft (es darf keine), was die abtretende tut, und welche
  // Deckkraft die ankommende im Augenblick des Tastendrucks traegt. Die
  // letzte Zahl ist die eigentliche: sie muss 1 sein, und nicht 0.
  typstage.goto(erste + 1, true); await p.ruhig(4000);
  typstage.goto(erste);
  var rRaus = lesen(stufen[1]), rRein = lesen(stufen[0]);
  var rDeck = String(Math.round(parseFloat(getComputedStyle(stufen[0]).opacity) * 100) / 100);
  await p.ruhig(4000);
  var rAn = stufen.filter(function (e) { return e.dataset.on === "1"; }).length;
  // Und das Mass: alle Stufen einer Zeichnung muessen deckungsgleich liegen.
  // Das ist die eigentliche Zusage von build -- ein Stueck, das noch nicht
  // dran ist, steht als Luft da und behaelt seinen Platz. Fiele der Platz weg,
  // laege die Stufe, die es hat, anders als die, die es noch nicht hat, und
  // die Zeichnung spraenge bei jedem Schritt.
  //
  // Abgelesen an dem, was stelle den Sprites in Prozent der Buehne
  // hinschreibt, und nicht an Pixeln: Prozente haengen nicht an der
  // Fenstergroesse. Auf eine Nachkommastelle gerundet, das sind rund 0,1
  // Prozent der Buehne; feiner gefragt zaehlte man das Rauschen der Messung
  // mit. (Ohne Schraegstriche und ohne Akzente: der ganze Block steht in einer
  // Zeichenkette mit Rueckwaertsakzenten, und ein weiterer schloesse sie.)
  var masze = stufen.map(function (e) {
    return ["left", "top", "width", "height"].map(function (k) {
      return (Math.round(parseFloat(e.style[k]) * 10) / 10).toFixed(1);
    }).join(",");
  });
  var einig = masze.filter(function (m, i) { return masze.indexOf(m) === i; });
  return JSON.stringify({ raus: raus, rein: rein, an: an,
                          rueckRaus: rRaus, rueckRein: rRein,
                          rueckDeck: rDeck, rueckAn: rAn,
                          stufen: stufen.length, masze: einig });
})()`;

// ── Wie ein Pfad sich selbst zeichnet ───────────────────────────────────────
//
// Der Durchlauf oben zaehlt, *dass* gezeichnet wurde. Was er nicht sieht, ist
// der Weg: faehrt die Feder hinein und rueckwaerts wieder heraus, laeuft sie
// so lange wie die Blende darunter, und traegt sie die Kurve, die das Deck
// genannt hat.
//
// Gefragt wird die Animation selbst und keine Deckkraft zu einem geratenen
// Zeitpunkt -- eine Messung, die an einer Uhr haengt, haengt am Rechner. In
// den Sollstand geht nur, was keine Dauer ist und keine Laenge: beide haengen
// am Fenster und an den Schriften.
const ZEICHENPROBE = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  var el = document.querySelector('.ts-el[data-enter="draw"]');
  if (!el) return JSON.stringify({ fehlt: "kein Element mit enter=draw" });
  var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
  var nr = folien.indexOf(el.closest(".ts-slide"));
  // Der erste Schritt des Bereichs, und der davor. Die Zeichnung darf nicht
  // auf Schritt eins ihrer Folie stehen: einen Folienwechsel spielt goto als
  // Zustand, nicht als Auftritt.
  var ab = +(el.dataset.at.match(/[0-9]+/) || [1])[0];
  if (ab < 2) return JSON.stringify({ fehlt: "die Zeichnung steht auf Schritt 1 ihrer Folie" });
  var davor = -1, ziel = -1;
  for (var i = 0; i < S.length; i++) if (S[i].slide === nr) {
    if (S[i].step === ab - 1) davor = i;
    if (S[i].step === ab) ziel = i;
  }
  if (davor < 0 || ziel < 0) return JSON.stringify({ fehlt: "Schritt nicht gefunden" });
  // Chrome und Firefox schreiben dieselbe Kurve verschieden auf, mit und ohne
  // Leerzeichen und mit und ohne fuehrende Null. Beides weg, dann steht in
  // beiden dasselbe. Die Null nur am Wortanfang, sonst wuerde aus 10.5 eine
  // 1.5 -- in dieser Tabelle kommt das nicht vor, aber der naechste Wert
  // koennte es.
  // Die Rueckwaertsschraegstriche stehen doppelt, und das ist kein Vertipper:
  // der ganze Block ist eine Zeichenkette mit Rueckwaertsakzenten, und darin
  // frisst ein einzelner sich selbst auf -- aus \\s wuerde ein s, und der
  // Ausdruck striche die Buchstaben statt der Leerzeichen. Dieselbe Falle wie
  // beim Mass in der Haltprobe.
  function glatt(k) {
    return k == null ? null
      : String(k).replace(/\\s+/g, "").replace(/\\b0\\./g, ".");
  }
  function lesen() {
    var pf = [].slice.call(el.querySelectorAll("[data-ts-feder]"));
    var a = pf.length ? pf[0].getAnimations()[0] : null;
    var eig = el.getAnimations()[0];
    var kf = a ? a.effect.getKeyframes().map(function (k) {
      return parseFloat(k.strokeDashoffset);
    }) : null;
    return {
      federn: pf.length,
      // Nicht die Laengen, sondern die Richtung: eine Laenge haengt am
      // Fenster, eine Richtung nicht.
      richtung: kf ? (kf[0] > kf[1] ? "hinein" : "heraus") : "nichts",
      fKurve: a ? glatt(a.effect.getTiming().easing) : null,
      fDauer: a ? a.effect.getTiming().duration : null,
      eKurve: eig ? glatt(eig.effect.getTiming().easing) : null,
      eDauer: eig ? eig.effect.getTiming().duration : null,
      eKf: eig ? eig.effect.getKeyframes().map(function (k) {
        return String(k.opacity);
      }) : null
    };
  }
  typstage.goto(davor, true); await p.ruhig(4000);
  var vor = p.stand().feder;
  typstage.goto(ziel);
  var hin = lesen();
  await p.ruhig(4000);
  var offenNachHin = p.stand().federOffen;
  typstage.goto(davor);
  var zurueck = lesen();
  await p.ruhig(4000);
  // Und der Sprung: er stellt den Endzustand her, ohne die Zeichnung zu
  // spielen. Danach darf keine Feder laufen und das Element muss dastehen.
  typstage.goto(ziel, true); await p.ruhig(4000);
  var sprung = { federn: el.querySelectorAll("[data-ts-feder]").length,
                 an: el.dataset.on === "1" ? 1 : 0,
                 gezogen: p.stand().feder - vor };
  return JSON.stringify({ hin: hin, zurueck: zurueck, sprung: sprung,
                          markup: el.dataset.easing || "",
                          offenNachHin: offenNachHin,
                          offen: p.stand().federOffen });
})()`;
// ── Wie eine Szene von Halt zu Halt zieht ───────────────────────────────────
//
// Der Durchlauf oben sieht von einer Szene nichts: sie ist *ein* verfolgtes
// Element, und ob es Bild 0 oder Bild 27 zeigt, steht in keiner der Zahlen,
// die er zählt. Also wird hier eigens gefragt, und zwar viermal.
//
// *Wo sie in Ruhe steht.* Halt k liegt auf Bild k·(tween + 1). Verrechnet sich
// die Zuordnung von Schritt zu Halt, wandert die ganze Reihe.
//
// *Dass ein Schritt zieht und nicht springt.* Nicht zu einem geratenen
// Zeitpunkt gefragt -- eine Messung an der Uhr hängt am Rechner --, sondern an
// der Bewegung selbst: sie wird angehalten und auf die Hälfte ihrer Zeit
// gestellt, und dann muss ein Bild aus der Mitte der Strecke dastehen.
//
// *Dass die Kurve die des Pakets ist.* Auf halber Zeit steht Bild 7 von 9 und
// nicht Bild 4 oder 5. Wer die Kurve gegen eine Gerade tauscht, sieht genau
// das.
//
// *Dass ein Sprung stellt, statt zu ziehen.* Nach `goto(…, true)` darf keine
// Bewegung laufen und das Bild muss am Ziel stehen.
//
// Die Bewegung wird daran erkannt, dass sie am Rumpf des Dokuments hängt: dort
// hängt sonst keine. Warum sie dort hängt und nicht am Sprite, steht in der
// Laufzeit bei `szeneZiehen`. In den Sollstand geht keine Dauer -- die teilte
// `--tempo` durch seine Zahl.
const SZENENPROBE = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  var el = document.querySelector(".ts-scene");
  if (!el) return JSON.stringify({ fehlt: 1 });
  var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
  var nr = folien.indexOf(el.closest(".ts-slide"));
  var erste = -1, wieviele = 0;
  for (var i = 0; i < S.length; i++) if (S[i].slide === nr) {
    if (erste < 0) erste = i;
    wieviele++;
  }
  if (erste < 0) return JSON.stringify({ fehlt: -1 });
  function bild() {
    var f = el.querySelectorAll(".ts-frame");
    for (var j = 0; j < f.length; j++) if (f[j].dataset.on) return j;
    return -1;
  }
  function takte() {
    return document.getAnimations().filter(function (a) {
      return a.effect && a.effect.target === document.body;
    });
  }
  function zweiBilder() {
    return new Promise(function (r) {
      requestAnimationFrame(function () { requestAnimationFrame(r); });
    });
  }

  // Die Ruhezustände, Schritt für Schritt durch die Folie.
  typstage.goto(erste, true); await p.ruhig(4000);
  var ruhe = [];
  for (var k = 0; k < wieviele; k++) {
    typstage.goto(erste + k); await p.ruhig(4000);
    ruhe.push(bild());
  }

  // Und der Zug selbst, angehalten auf halber Zeit.
  typstage.goto(erste, true); await p.ruhig(4000);
  var vorher = bild();
  typstage.goto(erste + 1);
  var t = takte(), mitte = -1;
  if (t.length === 1) {
    t[0].pause();
    t[0].currentTime = t[0].effect.getTiming().duration / 2;
    await zweiBilder();
    mitte = bild();
    t[0].cancel();
  }

  // Ein Sprung stellt: kein Zug, und das Bild am Ziel.
  typstage.goto(erste + wieviele - 1, true);
  await zweiBilder();
  var sprung = bild(), sprungTakte = takte().length;
  await p.ruhig(4000);
  return JSON.stringify({
    stops: +el.dataset.stops, tween: +el.dataset.tween,
    bilder: el.querySelectorAll(".ts-frame").length,
    ruhe: ruhe, vorher: vorher, zuege: t.length, mitte: mitte,
    sprung: sprung, sprungTakte: sprungTakte
  });
})()`;

// ── Wie eine Kamera auf ein Detail faehrt ───────────────────────────────────
//
// Der Durchlauf oben sieht von einer Kamerafahrt nichts. Sie deckt kein
// Element auf, sie zaehlt keinen Geist und sie zieht kein Bild weiter -- sie
// verschiebt zwei Ebenen der Folie, und das steht in keiner der Zahlen, die er
// zaehlt. Also wird hier eigens gefragt, und zwar sechsmal.
//
// *Worauf sie steht.* Die Fahrt gilt genau, solange ihr Bereich gilt. Auf
// Schritt 1 steht die Folie ganz da, auf 2 und 3 der Ausschnitt, auf 4 wieder
// die ganze Folie. Verrechnet sich die Zuordnung, wandert die ganze Reihe.
//
// *Dass beide Ebenen dasselbe tragen.* Der Hintergrund und die Sprite-Ebene
// sind zwei Kaesten und muessen deckungsgleich bleiben. Laufen sie
// auseinander, steht der Text neben dem Bild, zu dem er gehoert -- und am
// Ruhezustand einer einzelnen Ebene waere davon nichts zu sehen.
//
// *Dass ein Schritt faehrt und nicht springt.* Nicht zu einem geratenen
// Zeitpunkt gefragt -- das hinge am Rechner --, sondern an der Bewegung
// selbst: sie wird angehalten und auf die Haelfte ihrer Zeit gestellt, und
// dann muss eine Streckung zwischen Anfang und Ziel dastehen.
//
// *Dass ein Sprung stellt.* Nach `goto(…, true)` darf keine Fahrt laufen und
// der Ausschnitt muss am Ziel stehen.
//
// *Dass die Vorschau den Ausschnitt traegt.* Sie klont die Sprite-Ebene
// mitsamt Stilattribut, den Hintergrund aber ueber `innerHTML`. Ungefragt
// stuenden die beiden Haelften des Standbilds gegeneinander verschoben.
//
// *Dass die alleinstehende Fahrt ihren Rueckweg bekommt.* Die Folie daneben
// traegt nichts als einen Pin und eine Kamera; sie muss drei Schritte haben.
//
// In den Sollstand gehen Streckungen und keine Verschiebungen: die Streckung
// haengt am Verhaeltnis von Detail zu Folie und ist in jedem Fenster dieselbe,
// die Verschiebung stuende auf vier Nachkommastellen und wuerde vom Satz
// abhaengen. Und keine Dauer -- die teilte `--tempo` durch seine Zahl.
const KAMERAPROBE = `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
  // Die Folie mit der Fahrt ueber 2-3, und die, auf der nichts als eine Fahrt
  // steht. Beide werden ueber ihre Kameraskripte gefunden und nicht ueber eine
  // Nummer: wer eine Folie davor einfuegt, soll den Sollstand verschieben und
  // nicht die Probe ins Leere laufen lassen.
  var mit = [];
  folien.forEach(function (f, i) {
    var s = f.querySelector("script.ts-camera");
    if (s) mit.push({ nr: i, liste: JSON.parse(s.textContent) });
  });
  if (mit.length !== 2) return JSON.stringify({ fehlt: mit.length });
  function ersteVon(nr) { for (var i = 0; i < S.length; i++) if (S[i].slide === nr) return i; return -1; }
  function wieviele(nr) { var n = 0; for (var i = 0; i < S.length; i++) if (S[i].slide === nr) n++; return n; }
  // Die Streckung einer Ebene, auf drei Stellen. "none" wird zur 1.
  function streckung(el) {
    var t = el ? getComputedStyle(el).transform : "none";
    if (!t || t === "none") return 1;
    return +(new DOMMatrix(t).a).toFixed(3);
  }
  function stand(nr) {
    var f = folien[nr];
    return { bg: streckung(f.querySelector(".ts-bg")),
             ov: streckung(f.querySelector(".ts-ov")) };
  }
  // Wo die Mitte des Details auf der Buehne liegt, im Verhaeltnis zu ihr.
  // Herangefahren muss sie in der Mitte sein, also 0.50/0.50 -- und das ist
  // die eigentliche Zusage der Kamera. Eine Streckung allein sagt darueber
  // nichts: wer den Ursprung der Streckung von der linken oberen Ecke in die
  // Mitte des Kastens rueckt, streckt genau gleich weit und zeigt trotzdem die
  // falsche Stelle. Ein Verhaeltnis und keine Pixel, damit die Zahl nicht am
  // Satz und nicht am Fenster haengt.
  function mitteVon(nr, pin) {
    var f = folien[nr];
    var svg = f.querySelector(".ts-bg svg");
    if (!svg) return "-";
    var b = svg.getBoundingClientRect();
    var l = null, o = null, r = null, u = null;
    f.querySelectorAll("path").forEach(function (p) {
      var fl = (p.getAttribute("fill") || "").toLowerCase();
      if (fl.length !== 9 || fl.slice(0, 3) !== "#fd" || fl.slice(7) !== "00") return;
      if (parseInt(fl.slice(3, 7), 16) !== pin) return;
      var wirt = p.closest(".ts-el");
      if (wirt && !wirt.style.width) return;
      var k = p.getBoundingClientRect();
      if (!k.width && !k.height) return;
      l = l === null ? k.left : Math.min(l, k.left);
      o = o === null ? k.top : Math.min(o, k.top);
      r = r === null ? k.right : Math.max(r, k.right);
      u = u === null ? k.bottom : Math.max(u, k.bottom);
    });
    if (l === null) return "-";
    // An der Buehne gemessen und nicht am Folien-SVG: das SVG faehrt mit, in
    // ihm laege die Mitte immer dort, wo sie ohne Fahrt liegt.
    var st = document.getElementById("ts-stage").getBoundingClientRect();
    return ((l + r) / 2 - st.left) / st.width * 1 + "|"
         + ((o + u) / 2 - st.top) / st.height;
  }
  function mitteKurz(nr, pin) {
    var m = mitteVon(nr, pin);
    if (m === "-") return "-";
    return m.split("|").map(function (z) { return (+z).toFixed(2); }).join("/");
  }
  function fahrten() {
    return document.getAnimations().filter(function (a) {
      var t = a.effect && a.effect.target;
      return t && t.classList && (t.classList.contains("ts-bg")
                                  || t.classList.contains("ts-ov"));
    });
  }
  function zweiBilder() {
    return new Promise(function (r) {
      requestAnimationFrame(function () { requestAnimationFrame(r); });
    });
  }

  var nr = mit[0].nr, erste = ersteVon(nr), wv = wieviele(nr);
  // Die Ruhezustaende, Schritt fuer Schritt durch die Folie. Beide Ebenen,
  // damit ein Auseinanderlaufen auffaellt.
  typstage.goto(erste, true); await p.ruhig(4000);
  var ruhe = [], einig = 1;
  for (var k = 0; k < wv; k++) {
    typstage.goto(erste + k); await p.ruhig(4000);
    var st = stand(nr);
    if (st.bg !== st.ov) einig = 0;
    ruhe.push(st.bg);
  }
  // Und die Mitte des Details, herangefahren.
  typstage.goto(erste + 1); await p.ruhig(4000);
  var mitte = mitteKurz(nr, mit[0].liste[0].pin);

  // Und die Fahrt selbst, angehalten auf halber Zeit.
  typstage.goto(erste, true); await p.ruhig(4000);
  var vorher = stand(nr).bg;
  typstage.goto(erste + 1);
  var a = fahrten(), halb = -1;
  if (a.length === 2) {
    a.forEach(function (x) {
      x.pause();
      x.currentTime = x.effect.getTiming().duration / 2;
    });
    await zweiBilder();
    halb = stand(nr).bg;
    a.forEach(function (x) { x.cancel(); });
  }

  // Ein Sprung stellt: keine Fahrt, und der Ausschnitt am Ziel.
  typstage.goto(erste, true); await p.ruhig(4000);
  typstage.goto(erste + 1, true);
  await zweiBilder();
  var sprung = stand(nr).bg, sprungFahrten = fahrten().length;
  await p.ruhig(4000);

  // Die Vorschau: Grund und Sprite-Ebene tragen denselben Ausschnitt.
  var v1 = typstage.sprecher.bild(nr, 1), v2 = typstage.sprecher.bild(nr, 2);
  var vg = v2.querySelector("svg"), ve = v2.querySelector(".ts-ov");
  var vorschau = (v1.querySelector("svg").style.transform ? "?" : "ganz") + "/"
    + (vg && vg.style.transform ? "nah" : "ganz") + "/"
    + (ve && ve.style.transform === (vg ? vg.style.transform : "") ? "einig" : "?");

  return JSON.stringify({
    ruhe: ruhe, einig: einig, mitte: mitte, vorher: vorher,
    fahrten: a.length, halb: halb,
    sprung: sprung, sprungFahrten: sprungFahrten, vorschau: vorschau,
    allein: wieviele(mit[1].nr)
  });
})()`;

// ── Wann die Uhr eines Daumenkinos zu laufen beginnt ────────────────────────
//
// Beim Aufdecken, nicht beim Folieneintritt. Das war einmal falsch, und der
// Fall hat zwei Hälften, die zusammengehören.
//
// Die eine: `mediaOn` stempelte den Startpunkt beim Folieneintritt, für jedes
// Daumenkino der Folie und ohne nach Sichtbarkeit zu fragen. Ein
// `flipbook(at: "3-", loop: false)` stand im Augenblick des Aufdeckens deshalb
// schon auf dem letzten Bild.
//
// Die andere: der Prüfstand konnte das nicht sehen. Unter der festgenagelten
// Uhr kürzte sich der Startpunkt aus der Rechnung heraus -- genau die Größe,
// um die es ging, fiel beim Messen weg. Ein Prüflauf hätte also grün bleiben
// können, während das Kino abgelaufen war, bevor es zu sehen war.
//
// Darum wird hier beides an einem Stück gefragt: Bild 0, solange es verborgen
// ist, Bild 0 im Augenblick des Aufdeckens -- und danach eine Uhr, die
// weitergestellt wird und das Kino laufen lässt.
//
// Und darum stehen auf der Folie *zwei* Kinos, eines von Anfang an sichtbar
// und eines erst auf Schritt 3. Sie fangen verschiedene Fehler. Ein
// Startpunkt, der unter der festgenagelten Uhr aus der Rechnung fällt, macht
// bei beiden alle fünf Zahlen gleich. Ein Startpunkt, der beim Folieneintritt
// gestempelt wird, fällt dagegen nur dem ersten auf: das zweite ist beim
// Betreten verborgen und bekommt seinen Startpunkt beim Aufdecken ohnehin neu.
// Nachgemessen an genau dieser Mutation: 23/23/23/23/23 für das frühe Kino,
// 0/0/0/12/23 für das späte -- mit nur einem späten Kino wäre sie durchgegangen.
const KINOPROBE = (uhr) => `(async function () {
  var p = typstage.pruef, S = typstage.steps;
  var erstes = document.querySelector(".ts-flipbook");
  if (!erstes) return JSON.stringify({ fehlt: 1 });
  var folien = [].slice.call(document.querySelectorAll(".ts-slide"));
  var folie = erstes.closest(".ts-slide");
  var nr = folien.indexOf(folie);
  // Beide Kinos der Folie, in der Reihenfolge des Quelltexts: das spät
  // aufgedeckte und das von Anfang an sichtbare. Sie prüfen zwei verschiedene
  // Hälften desselben Falls, siehe den Kommentar im Prüfdeck.
  var kinos = [].slice.call(folie.querySelectorAll(".ts-flipbook"));
  var erste = -1, wieviele = 0;
  for (var i = 0; i < S.length; i++) if (S[i].slide === nr) {
    if (erste < 0) erste = i;
    wieviele++;
  }
  if (erste < 0) return JSON.stringify({ fehlt: -1 });
  function bilder() {
    return kinos.map(function (fb) {
      var k = fb.querySelectorAll(".ts-frame");
      for (var j = 0; j < k.length; j++) if (k[j].dataset.on) return j;
      return -1;
    });
  }
  function zweiBilder() {
    return new Promise(function (r) {
      requestAnimationFrame(function () { requestAnimationFrame(r); });
    });
  }
  // Frisch betreten, damit der Startpunkt nichts von vorher weiß.
  typstage.goto(0, true); await p.ruhig(4000);
  p.uhr(${uhr});
  typstage.goto(erste, true); await p.ruhig(4000); await zweiBilder();
  var reihen = [bilder()];
  for (var k = 1; k < wieviele; k++) {
    typstage.goto(erste + k); await p.ruhig(4000); await zweiBilder();
    reihen.push(bilder());
  }
  // Und jetzt die Uhr weiter, ohne einen Schritt. Nur die Zeit bewegt sich.
  p.uhr(${uhr} + 500); await zweiBilder(); reihen.push(bilder());
  p.uhr(${uhr} + 1000); await zweiBilder(); reihen.push(bilder());
  p.uhr(${uhr});
  return JSON.stringify({
    reihen: reihen, anzahl: kinos.length,
    an: kinos.map(function (fb) { return fb.dataset.at || "1-"; })
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
  const gebaut = fs.readdirSync(deckDir).filter(f => f.endsWith(".html"))
    .map(f => f.slice(0, -5)).filter(n => NICHT_DECK.indexOf(n) < 0);
  const vergessen = gebaut.filter(n => BEISPIELE.indexOf(n) < 0);
  if (vergessen.length) {
    console.error("FEHLER: gebaut, aber ungeprueft: " + vergessen.join(", ")
      + "\n  In BEISPIELE eintragen (pruefe-decks.js) und Sollstand aufnehmen.");
    process.exit(2);
  }
  decks.forEach(d => {
    if (MIT_APPLET.indexOf(d.name) >= 0) d.datei = ohneGeoGebra(d.datei);
  });
  const ueberlauf = ueberlaufProbe();
  if (ueberlauf) console.error("ABWEICHUNG ueberlauf: " + ueberlauf);
  const wanderung = wanderungProbe();
  if (wanderung) console.error("ABWEICHUNG wanderung: " + wanderung);
  const gitter = gitterProbe();
  if (gitter) console.error("ABWEICHUNG gitter: " + gitter);
  const notiz = notizProbe();
  if (notiz) console.error("ABWEICHUNG notiz: " + notiz);
  const papier = papierProbe();
  if (papier) console.error("ABWEICHUNG papier: " + papier);
  const kachel = kachelProbe();
  if (kachel) console.error("ABWEICHUNG kacheln: " + kachel);
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

  // Die Sollwerte sind ohne „Bewegung reduzieren" aufgenommen, und die
  // Laufzeit hält sich daran: unter der Einstellung fliegt kein Morph, also
  // steht `flieger` bei allen sieben Decks auf 0. Der Lauf schlägt dann fehl,
  // aber mit vierzehn Zeilen „soll 82, ist 0", aus denen niemand die Ursache
  // liest. Gemessen mit --force-prefers-reduced-motion: genau diese vierzehn.
  // Darum einmal gefragt und beim Namen genannt. Nur `flieger` weicht ab;
  // sichtbar, gedimmt, grund, hash, sprecher und satz halten, weil die
  // Einstellung den Weg wegnimmt und nicht das Ziel.
  await laden(b, "about:blank");
  const leiser = await b.ev(
    "matchMedia('(prefers-reduced-motion: reduce)').matches");
  if (leiser) {
    console.error("FEHLER: Dieser Browser meldet prefers-reduced-motion: "
      + "reduce. Dann fliegt kein Magic Move und flieger steht überall auf 0. "
      + "Der Lauf will einen Browser ohne die Einstellung.");
    await b.ende();
    process.exit(2);
  }

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
      z.maengel.push("Messfläche in Fassung " + r.fassungFehler + ", erwartet 3");
      bericht.push(z); schlecht++; continue;
    }

    Object.assign(z, {
      folien: r.folien, schritte: r.schritte, elemente: r.elemente,
      flieger: r.flieger, fliegerRueck: r.fliegerRueck,
      // Wie viele Pfade sich hin und zurueck selbst gezeichnet haben. Wie
      // `flieger` in der Laufzeit gezaehlt, dort wo sie entstehen.
      feder: r.feder, federRueck: r.federRueck,
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
    if (r.federOffen)
      z.maengel.push(r.federOffen + " Pfad(e) tragen nach der Fahrt noch eine "
        + "Feder. Ein Strich steht dann fuer den Rest des Vortrags auf halber "
        + "Strecke, und zu sehen ist das erst bei dem einen Sprung, der genau "
        + "dorthin geht.");

    // Wie eine Stufe von `build` abtritt. Nur im Prüfdeck: nur dort steht eine.
    if (d.satz) {
      const h = JSON.parse(await b.ev(HALTPROBE));
      if (h.fehlt !== undefined) {
        z.maengel.push("keine zwei build-Stufen im Prüfdeck gefunden ("
          + h.fehlt + "). Entweder ist die Folie weg oder data-exit=\"hold\" "
          + "steht nicht mehr an ihren Stufen.");
      } else if (!h.raus || !h.rein) {
        z.maengel.push("beim Schrittwechsel lief an einer build-Stufe keine "
          + "Animation: abtretend " + JSON.stringify(h.raus)
          + ", ankommend " + JSON.stringify(h.rein));
      } else {
        // Der Sollwert trägt keine Dauer, die hinge am --tempo. Er trägt, was
        // gemeint ist: die abtretende Stufe bleibt voll stehen, die neue
        // blendet auf, und danach ist genau eine gezeichnet.
        z.halt = h.raus.kf.join(">") + "·" + h.rein.kf.join(">")
               + "·" + h.an + "/" + h.stufen;
        z.masz = h.stufen + " Stufen · " + h.masze.length
               + (h.masze.length === 1 ? " Maß" : " Maße");
        if (h.masze.length !== 1) {
          z.maengel.push("die Stufen einer build-Zeichnung liegen nicht "
            + "deckungsgleich: " + h.masze.join(" | ") + ". Ein Stück, das "
            + "noch nicht dran ist, hat seinen Platz nicht behalten -- die "
            + "Zeichnung springt dann bei jedem Schritt.");
        }
        if (Math.round(h.raus.dauer) !== Math.round(h.rein.dauer)) {
          z.maengel.push("die abtretende build-Stufe wartet "
            + Math.round(h.raus.dauer) + "ms, die ankommende braucht "
            + Math.round(h.rein.dauer) + "ms. Sie muss so lange warten, wie "
            + "die neue braucht, sonst sinkt das Bild zum Schluss doch noch ab.");
        }
        // Und derselbe Wechsel rückwärts.
        z.haltRueck = (h.rueckRaus ? h.rueckRaus.kf.join(">") : "nichts")
                    + "·" + (h.rueckRein ? h.rueckRein.kf.join(">") : "sofort")
                    + "·" + h.rueckDeck + "·" + h.rueckAn + "/" + h.stufen;
        if (h.rueckRein) {
          z.maengel.push("beim Zurückblättern blendet die ankommende "
            + "build-Stufe auf (" + h.rueckRein.kf.join(">") + "). Sie liegt "
            + "vollständig unter der Stufe, die noch abtritt, und muss "
            + "einfach dastehen: blendet sie, blenden zwei fast gleiche "
            + "Bilder gegeneinander und die geteilte Tinte sinkt auf drei "
            + "Viertel.");
        }
        if (h.rueckDeck !== "1") {
          z.maengel.push("beim Zurückblättern steht die ankommende "
            + "build-Stufe im Augenblick des Tastendrucks bei Deckkraft "
            + h.rueckDeck + " statt bei 1. Genau in dieser Lücke sinkt die "
            + "geteilte Tinte ein.");
        }
        if (!h.rueckRaus) {
          z.maengel.push("beim Zurückblättern lief an der abtretenden "
            + "build-Stufe keine Blende. Sie trägt die Tinte, die die "
            + "kleinere Stufe nicht hat, und die muss weichen können.");
        }
      }
    }

    // Wie ein Pfad sich selbst zeichnet. Nur im Prüfdeck: nur dort steht einer.
    if (d.satz) {
      const zg = JSON.parse(await b.ev(ZEICHENPROBE));
      if (zg.fehlt) {
        z.maengel.push("die Zeichenprobe fand nichts zu messen: " + zg.fehlt);
      } else if (!zg.hin.federn || !zg.zurueck.federn) {
        z.maengel.push("beim Auftritt oder beim Rückweg fuhr keine Feder: hin "
          + JSON.stringify(zg.hin) + ", zurück " + JSON.stringify(zg.zurueck));
      } else {
        // Der Sollwert trägt keine Dauer und keine Länge; beide hängen am
        // Fenster und am --tempo. Er trägt, was gemeint ist: so viele Pfade
        // fahren hinein, ebenso viele wieder heraus, danach ist keiner offen,
        // und ein Sprung stellt den Endzustand her, ohne zu zeichnen.
        z.zeichnung = zg.hin.federn + "+" + zg.zurueck.federn + " Pfade · "
          + zg.hin.richtung + "/" + zg.zurueck.richtung + " · "
          + zg.hin.eKf.join(">") + " · "
          + zg.offenNachHin + "/" + zg.offen + " offen · Sprung "
          + zg.sprung.federn + "/" + zg.sprung.an + "/" + zg.sprung.gezogen;
        // Und die Kurve: was Typst ins Markup geschrieben hat, was die Blende
        // trägt, was die Feder trägt. Alle drei, weil jede für sich auf die
        // Hauskurve zurückfallen kann.
        z.kurve = zg.markup + " · " + zg.hin.eKurve + " · " + zg.hin.fKurve;
        if (Math.round(zg.hin.fDauer) !== Math.round(zg.hin.eDauer)) {
          z.maengel.push("die Feder läuft " + Math.round(zg.hin.fDauer)
            + "ms, die Blende darunter " + Math.round(zg.hin.eDauer)
            + "ms. Beide gehören gleich lang, sonst steht der Strich fertig "
            + "da, während das Bild noch aufblendet, oder umgekehrt.");
        }
      }
    }
    // Wie eine Szene zieht, und wann die Uhr eines Daumenkinos anfängt. Beide
    // nur im Prüfdeck: nur dort stehen eine Szene und ein spät aufgedecktes
    // Daumenkino.
    if (d.satz) {
      const sz = JSON.parse(await b.ev(SZENENPROBE));
      if (sz.fehlt !== undefined) {
        z.maengel.push("keine Szene im Prüfdeck gefunden (" + sz.fehlt
          + "). Entweder ist die Folie weg oder .ts-scene heißt anders.");
      } else {
        z.szene = sz.stops + " Halte · " + sz.bilder + " Bilder · "
                + sz.ruhe.join("/") + " · Mitte " + sz.mitte + " · Sprung "
                + sz.sprung;
        if (sz.zuege !== 1) {
          z.maengel.push("beim Schritt von Halt 1 auf Halt 2 lief " + sz.zuege
            + "x ein Zug am Rumpf des Dokuments, erwartet genau einer. Ohne "
            + "Zug springt die Szene, statt zu ziehen -- und der Prüflauf "
            + "könnte das an den Ruhezuständen allein nicht sehen.");
        }
        if (sz.sprungTakte !== 0) {
          z.maengel.push("ein Sprung mit goto(…, true) hat einen Zug "
            + "angeworfen. Ein Sprung stellt die Szene, er zieht sie nicht: "
            + "dort gibt es keinen Weg, den jemand gesehen hätte.");
        }
        if (sz.mitte <= sz.vorher || sz.mitte >= sz.ruhe[1]) {
          z.maengel.push("auf halber Zeit steht Bild " + sz.mitte
            + ", also nicht zwischen " + sz.vorher + " und " + sz.ruhe[1]
            + ". Der Zug zeigt keine Zwischenbilder.");
        }
      }
      const km = JSON.parse(await b.ev(KAMERAPROBE));
      if (km.fehlt !== undefined) {
        z.maengel.push("das Prüfdeck hat " + km.fehlt + " Folien mit einer "
          + "Kamerafahrt statt zwei. Es braucht eine mit einem gesagten "
          + "Bereich und eine, auf der nichts als eine Fahrt steht -- die "
          + "beiden prüfen verschiedene Hälften des Falls.");
      } else {
        z.kamera = km.ruhe.join("/") + " · " + (km.einig ? "einig" : "ENTZWEIT")
                 + " · Mitte " + km.mitte + " · halb " + km.halb
                 + " · Sprung " + km.sprung
                 + " · " + km.vorschau + " · allein " + km.allein;
        if (km.fahrten !== 2) {
          z.maengel.push("beim Schritt in den Ausschnitt liefen " + km.fahrten
            + " Fahrten, erwartet genau zwei -- eine je Ebene. Fährt nur eine, "
            + "steht die Sprite-Ebene neben dem Hintergrund; fährt keine, "
            + "springt die Kamera, statt zu fahren.");
        }
        if (!km.einig) {
          z.maengel.push("Hintergrund und Sprite-Ebene tragen verschiedene "
            + "Verschiebungen. Sie sind derselbe Kasten und müssen "
            + "deckungsgleich bleiben, sonst steht der Text neben dem Bild, "
            + "zu dem er gehört.");
        }
        if (km.sprungFahrten !== 0) {
          z.maengel.push("ein Sprung mit goto(…, true) hat eine Fahrt "
            + "angeworfen. Ein Sprung stellt die Kamera, er fährt sie nicht: "
            + "dort gibt es keinen Weg, den jemand gesehen hätte.");
        }
        if (!(km.halb > km.vorher && km.halb < km.ruhe[1])) {
          z.maengel.push("auf halber Zeit steht die Streckung bei " + km.halb
            + ", also nicht zwischen " + km.vorher + " und " + km.ruhe[1]
            + ". Die Kamera zeigt keinen Weg, sie springt.");
        }
        if (km.mitte !== "0.50/0.50") {
          z.maengel.push("herangefahren liegt die Mitte des Details bei "
            + km.mitte + " statt bei 0.50/0.50 der Bühne. Die Kamera streckt "
            + "dann zwar richtig weit, zeigt aber die falsche Stelle -- genau "
            + "das passiert, wenn der Ursprung der Streckung nicht in der "
            + "linken oberen Ecke liegt.");
        }
        if (km.allein !== 3) {
          z.maengel.push("die Folie, auf der nichts als eine Fahrt steht, hat "
            + km.allein + " Schritte statt drei. Der Rückweg ist ein Schritt, "
            + "und die Laufzeit muss ihn aus dem Bereich der Fahrt selbst "
            + "dazurechnen: die Kamera führe sonst hinein und nie heraus.");
        }
      }
      const ki = JSON.parse(await b.ev(KINOPROBE(UHR)));
      if (ki.fehlt !== undefined) {
        z.maengel.push("kein Daumenkino im Prüfdeck gefunden (" + ki.fehlt
          + "). Ohne eines bleibt ungeprüft, wann seine Uhr anfängt.");
      } else if (ki.anzahl !== 2) {
        z.maengel.push("auf der Folie des Daumenkinos stehen " + ki.anzahl
          + " statt zwei. Es braucht ein spät aufgedecktes und ein von Anfang "
          + "an sichtbares -- die beiden prüfen verschiedene Hälften des Falls.");
      } else {
        // Je Kino eine Reihe: Schritt 1, 2, 3, dann die Uhr um 500 und um
        // 1000 ms weiter, ohne dass ein Schritt geschieht.
        z.kino = ki.an.map((an, k) =>
          "at " + an + " " + ki.reihen.map(r => r[k]).join("/")).join(" · ");
        ki.an.forEach((an, k) => {
          const reihe = ki.reihen.map(r => r[k]);
          if (reihe.every(x => x === reihe[0])) {
            z.maengel.push("das Daumenkino at " + an + " zeigt auf allen fünf "
              + "Messungen Bild " + reihe[0] + ". Dann geht der Startpunkt "
              + "nicht in die Rechnung ein, und der Prüflauf kann nicht sehen, "
              + "wann die Uhr anfängt -- genau der blinde Fleck, an dem der "
              + "Fehler so lange vorbeikam.");
          }
        });
      }
    }

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
      + "assets/typstage-0.1.1.js. Erst neu bauen, dann prüfen.");
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
  const ohneStrich = await ohneStrichProbe(b);
  if (ohneStrich) console.error("ABWEICHUNG ohne-strich: " + ohneStrich);
  const schmal = await schmalProbe(b);
  if (schmal) console.error("ABWEICHUNG schmal: " + schmal);
  const ohneFlaeche = await ohneFlaecheProbe(b);
  if (ohneFlaeche) console.error("ABWEICHUNG ohne-flaeche: " + ohneFlaeche);
  const uhr2 = await uhrProbe(b, pd);
  if (uhr2) console.error("ABWEICHUNG uhr: " + uhr2);
  // Zuletzt, weil sie die Seite verbiegt, auf der sie läuft.
  const leiser2 = await leiserProbe(b, pd);
  if (leiser2) console.error("ABWEICHUNG leiser: " + leiser2);
  await b.ende();

  // ── Gegen den Sollstand ───────────────────────────────────────────────────
  // Nicht „stürzt nicht ab", sondern „verhält sich wie gestern".
  const felder = ["folien", "schritte", "elemente", "flieger", "fliegerRueck",
                  "feder", "federRueck", "hash", "hashStand", "sprecher",
                  "grund", "sichtbar", "sichtbarRueck", "fehler", "halt",
                  "haltRueck", "masz", "zeichnung", "kurve", "satz",
                  "satzBytes", "szene", "kino", "kamera"];
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
    // Ein Deck ohne Sollstand wurde zwar gefahren, aber gegen nichts geprüft.
    // Das war einmal nur eine Zeile auf stderr, und der Lauf ging mit 0 durch;
    // wer sie überlas, hielt ein ungeprüftes Deck für geprüft.
    Object.keys(jetzt).forEach(n => {
      if (!soll.decks[n]) {
        process.stderr.write("ABWEICHUNG " + n + ": kein Sollstand."
          + " Mit --neu-soll aufnehmen (und nur die neuen Einträge übernehmen,"
          + " sonst fallen die plattformgeteilten Werte weg).\n");
        schlecht++;
      }
    });
  }
  bericht.forEach(z => { if (z.maengel.length) schlecht++; });
  if (ueberlauf) schlecht++;
  if (wanderung) schlecht++;
  if (gitter) schlecht++;
  if (notiz) schlecht++;
  if (papier) schlecht++;
  if (kachel) schlecht++;
  if (ohneStrich) schlecht++;
  if (schmal) schlecht++;
  if (ohneFlaeche) schlecht++;
  if (uhr2) schlecht++;
  if (leiser2) schlecht++;
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
