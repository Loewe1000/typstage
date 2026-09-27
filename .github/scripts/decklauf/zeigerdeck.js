// =============================================================================
// zeigerdeck.js — die Probedecks des Zeigers, und wie man sie liest
// =============================================================================
// Zwei Proben messen denselben Zeiger: `pruefe-zeiger.js` in Chrome und
// `pruefe-zeiger-ff.js` in Firefox. Die Decks und die Leseausdruecke stehen
// deshalb hier und nicht zweimal nebeneinander -- zwei Kopien eines Probedecks
// waeren zwei Wahrheiten, und die eine faellt irgendwann hinter die andere
// zurueck.
// =============================================================================
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");
const zlib = require("zlib");

const BT = "`".repeat(3);

// Ein Rahmen, der mitschreibt. `__log` sammelt jedes Zeigerereignis, das
// wirklich hineinkommt; der Zähler zeigt, ob ein Klick bis zum Knopf ging.
// Jeder Eintrag traegt Art, gedrueckte Tasten und Ziel (`knopf` oder `feld`):
// `LOG` zaehlt nur, `ARTEN` liest die Eintraege. Ohne Tasten und Ziel war ein
// Zug in den Rahmen nicht von einem Schweben zu trennen, und ob er beim
// Knopf blieb, der den Druck genommen hat, gar nicht zu sehen.
const RAHMEN = BT + `
<div id="feld" style="width:100%;height:100%;background:#cde;font:14px sans-serif;position:relative">
<b id="titel">EMBED</b>
<button id="knopf" style="position:absolute;left:40px;top:60px;width:120px;height:40px">drücken <span id="zaehler">0</span></button>
</div>
<script>
window.__log = [];
["pointerdown","pointermove","pointerup","mousedown","mouseup","click","wheel"]
  .forEach(function (t) {
    document.addEventListener(t, function (e) {
      var z = e.target && e.target.closest && e.target.closest("#knopf");
      window.__log.push(t + ":" + (e.buttons || 0) + "@" + (z ? "knopf" : "feld"));
    }, true);
  });
document.getElementById("knopf").addEventListener("click", function () {
  var z = document.getElementById("zaehler");
  z.textContent = String(+z.textContent + 1);
});
</script>
` + BT + ".text";

const kopf = (raum) => `#import "@preview/typstage:0.2.0": *
#let rahmen = ${RAHMEN}
#show: presentation.with(theme: themes.lesson, title: [Zeiger]${raum})

== Textfolie
Nur Text, kein Rahmen. Hier soll der Punkt zu sehen sein.

== Rahmenfolie
#embed(html: rahmen, width: 80%, height: 300pt)

== Mehrschrittig
- Erstens
#pause
- Zweitens

== Schluss
Diese Folie steht hinter der mehrschrittigen, und nur deshalb misst Punkt 10
seinen zweiten Teil ueberhaupt. Ohne sie lief der Pfeil am Ende des Decks gegen
den Anschlag, weit.folie blieb gleich vorher.folie, der Zweig lief nie, und die
Frage, ob ein Folienwechsel den Punkt nimmt, wurde nie gestellt. Gemessen: mit
dem Aufruf von punktFolie aus der Laufzeit herausgenommen blieb die Probe
gruen -- mit dieser Folie klagt sie.
`;

const MIT_PUNKT = kopf("");
const OHNE_PUNKT = kopf(", room: (pointer: false)");
const GESTELLT = kopf(", room: (pointer: (color: rgb(\"#00c853\"), size: 4%))");

// Zwei Gruende, ein Deck je Grund. Die zwei Ringe tragen den Kontrast des
// Punktes, und welcher der beiden ihn traegt, haengt am Grund: auf heller
// Folie verschwindet der helle Ring im Papier und der dunkle traegt, auf
// `themes.night` umgekehrt. Mit nur einem Grund bliebe die Haelfte der Zusage
// ungemessen -- und genau diese zwei Zahlen stehen im CHANGELOG, in beiden
// Handbuechern und im Kommentar der Laufzeit.
//
// `themes.default` und nicht das Probedeck-Thema: die helle Folie, die die
// Handbuecher meinen, ist das Vorgabepapier `#fafafa`. Gemessen liest der
// dunkle Ring darauf 10,90 und auf reinem Weiss (`themes.lesson`,
// `themes.plain`) 11,20 -- zwei verschiedene Sachen, zwei Zahlen, und die
// Probe misst die, die in der Doku steht.
const grundDeck = (thema) => `#import "@preview/typstage:0.2.0": *
#show: presentation.with(theme: themes.${thema}, title: [Zeiger auf ${thema}])

== Textfolie
Nur Text, kein Rahmen. Hier soll der Punkt zu sehen sein.
`;
const HELL = grundDeck("default");
const NACHT = grundDeck("night");

// Was auf diesen zwei Gruenden herauskommen muss. Steht hier und nicht in den
// zwei Proben, damit Chrome und Firefox gegen dieselbe Zahl messen -- und
// damit es EINE Stelle gibt, die man mit der Doku vergleicht.
const RINGE = [
  { deck: "hell", thema: "default", grund: "#fafafa", welcher: "dunkel",
    soll: 10.90, wort: "auf heller Folie tr\u00e4gt der dunkle Ring" },
  { deck: "nacht", thema: "night", grund: "#0f1319", welcher: "hell",
    soll: 15.45, wort: "auf `themes.night` tr\u00e4gt der helle Ring" }
];

// Ein Rahmen, der sich als spiegelnd meldet -- das tut das GeoGebra-Applet
// über `assets/geogebra-boot.js` genauso, nur mit viel mehr Beiwerk. Erst
// diese Meldung setzt `data-spiegel="1"` am Wirt, und erst dann gibt das
// Stilblatt ihm im Zeigermodus die Maus.
const SPIEGELRAHMEN = BT + `
<div id="feld" style="width:100%;height:100%;background:#cde;font:14px sans-serif;position:relative">
<b id="titel">SPIEGEL</b>
<button id="knopf" style="position:absolute;left:40px;top:60px;width:120px;height:40px">drücken <span id="zaehler">0</span></button>
</div>
<script>
window.__log = [];
["pointerdown","pointermove","pointerup","mousedown","mouseup","click","wheel"]
  .forEach(function (t) {
    document.addEventListener(t, function (e) { window.__log.push(t); }, true);
  });
document.getElementById("knopf").addEventListener("click", function () {
  var z = document.getElementById("zaehler");
  z.textContent = String(+z.textContent + 1);
});
parent.postMessage({ typstage: 1, ready: 1, spiegel: "s1" }, "*");
</script>
` + BT + ".text";

const SPIEGEL = `#import "@preview/typstage:0.2.0": *
#let rahmen = ${SPIEGELRAHMEN}
#show: presentation.with(theme: themes.lesson, title: [Zeiger und Spiegel])

== Textfolie
Nur Text, kein Rahmen.

== Spiegelfolie
#embed(html: rahmen, bridge: "s1", width: 60%, height: 260pt)
`;

// Was der Punkt gerade ist, in Bruchteilen der Bühne und in Prozent ihrer
// Breite -- nicht in Pixeln: die zwei Fenster sind verschieden groß, und
// genau das ist hier die Frage.
//
// Über `typstage.pruef.zeiger()` und nicht am DOM abgelesen -- `punkt()`
// ist etwas anderes und längst vergeben: seit den cue-Gruppen ist es der
// Pfeil einer adaptiven Gruppe. Die erste Fassung
// dieser Probe griff nach `#ts-punkt`, `.ts-punkt-kern` und `--ts-zeiger` --
// drei Namen, die niemandem versprochen sind: wer einen umbenannt hätte, hätte
// keine Klage bekommen, sondern still gemessene Nullen. Genau dagegen steht
// `pruef.fassung` (hier: 5).
const PUNKT = `JSON.stringify(typstage.pruef.zeiger())`;
const FASSUNG = `typstage.pruef && typstage.pruef.fassung || 0`;
const NOETIG = 5;

// Wie viel wirklich in den Rahmen ging, und wie oft der Knopf ansprach.
const LOG = `(function(){
  var o = [];
  document.querySelectorAll('.ts-el iframe').forEach(function (f, i) {
    try { o.push(f.contentWindow.__log.length + "/"
                 + f.contentDocument.getElementById('zaehler').textContent); }
    catch (e) { o.push(i + ":fremd"); }
  });
  return o.join(" ") || "(kein Rahmen)";
})()`;
// Die Eintraege selbst, Rahmen fuer Rahmen durch ` | ` getrennt.
const ARTEN = `(function(){
  var o = [];
  document.querySelectorAll('.ts-el iframe').forEach(function (f) {
    try { o.push(f.contentWindow.__log.join(",")); } catch (e) { o.push("fremd"); }
  });
  return o.join(" | ");
})()`;
const LEER = `(function(){
  document.querySelectorAll('.ts-el iframe').forEach(function (f) {
    try { f.contentWindow.__log.length = 0; } catch (e) {}
  });
  return 1;
})()`;
// Die Buehne, und daneben die Breite des Fensters. Die Fensterbreite braucht
// `ringMessen`: ein Bildschirmfoto kann groesser sein als die Seite, und ohne
// den Massstab greift jede Messung im Bild an der falschen Stelle zu.
const BUEHNE = `(function(){
  var b = document.getElementById('ts-stage').getBoundingClientRect();
  return JSON.stringify([b.left, b.top, b.width, b.height, innerWidth]);
})()`;
const STRICHE = `(function(){
  var i = document.getElementById('ts-ink');
  return i ? i.querySelectorAll('polyline').length : -1;
})()`;

// =============================================================================
// Was im Saalbild wirklich steht
// =============================================================================
// Die Farbe und die Gestalt des Punktes standen bis hierher in keiner Probe.
// `pruef.zeiger().farbe` wurde zwar gelesen und mitgeschrieben, aber gegen
// nichts geprueft: mit der Zeile, die den Deckakzent setzt, herausgenommen
// meldete die Oberflaeche eine LEERE Zeichenkette, das Stilblatt fiel auf sein
// eigenes Orange zurueck -- und beide Proben sagten "in Ordnung". Eine Probe,
// die eine leere Zeichenkette gegen eine leere Zeichenkette haelt, ist keine.
//
// Darum zweierlei: die Oberflaeche gegen die Vorgabe (den Akzent des Decks,
// wie er in `#ts-cfg` steht), und das Bild gegen beides. Gemessen wird aus dem
// Bildschirmfoto des SAALS -- dort steht der Punkt, um den es geht, und dort
// laesst sich nachsehen, ob er die Farbe wirklich traegt und ob er noch die
// Gestalt hat, die das Stilblatt beschreibt: ein Kern ueber den inneren 50 %
// des Radius, darum ein heller Ring (50--64 %) und ein dunkler (64--78 %).
//
// Ein PNG-Leser ohne npm, wie die Treiber daneben: `zlib` bringt Node mit,
// und ein Bildschirmfoto ist ein PNG in 8 Bit je Kanal, Farbart 2 oder 6,
// nicht verschraenkt. Mehr braucht es nicht.
function pngLesen(b64) {
  const roh = Buffer.from(b64, "base64");
  if (roh.readUInt32BE(0) !== 0x89504e47) throw new Error("kein PNG");
  let i = 8, breite = 0, hoehe = 0, art = -1;
  const daten = [];
  while (i + 8 <= roh.length) {
    const n = roh.readUInt32BE(i), typ = roh.toString("ascii", i + 4, i + 8);
    const rumpf = roh.subarray(i + 8, i + 8 + n);
    if (typ === "IHDR") {
      breite = rumpf.readUInt32BE(0); hoehe = rumpf.readUInt32BE(4); art = rumpf[9];
      if (rumpf[8] !== 8 || (art !== 2 && art !== 6) || rumpf[12] !== 0) {
        throw new Error("PNG-Form " + rumpf[8] + "/" + art + "/" + rumpf[12]);
      }
    } else if (typ === "IDAT") daten.push(rumpf);
    else if (typ === "IEND") break;
    i += 12 + n;
  }
  const k = art === 6 ? 4 : 3;
  const strom = zlib.inflateSync(Buffer.concat(daten));
  const zeile = breite * k;
  const bild = Buffer.alloc(hoehe * zeile);
  // Die fuenf PNG-Filter, zurueckgerechnet. Ohne das steht in `bild` Rauschen.
  for (let y = 0; y < hoehe; y++) {
    const f = strom[y * (zeile + 1)];
    const ein = strom.subarray(y * (zeile + 1) + 1, y * (zeile + 1) + 1 + zeile);
    const aus = bild.subarray(y * zeile, (y + 1) * zeile);
    const ob = y ? bild.subarray((y - 1) * zeile, y * zeile) : null;
    for (let x = 0; x < zeile; x++) {
      const a = x >= k ? aus[x - k] : 0, b = ob ? ob[x] : 0;
      const c = (ob && x >= k) ? ob[x - k] : 0;
      let v = ein[x];
      if (f === 1) v += a;
      else if (f === 2) v += b;
      else if (f === 3) v += (a + b) >> 1;
      else if (f === 4) {
        const s = a + b - c;
        const pa = Math.abs(s - a), pb = Math.abs(s - b), pc = Math.abs(s - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
      }
      aus[x] = v & 255;
    }
  }
  return { breite: breite, hoehe: hoehe,
           punkt: function (x, y) {
             if (x < 0 || y < 0 || x >= breite || y >= hoehe) return null;
             const o = (y * breite + x) * k;
             return [bild[o], bild[o + 1], bild[o + 2]];
           } };
}

// WCAG 2.1, dieselbe Rechnung, die schon die Kontraste der Abschnittsseite
// nennen. Eine Zahl je Sache, ein Verfahren.
function leuchte(c) {
  const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92
                                : Math.pow((v + 0.055) / 1.055, 2.4); };
  return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]);
}
function kontrast(a, b) {
  const x = leuchte(a), y = leuchte(b);
  return +(((Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)).toFixed(2));
}

// Die haeufigste Farbe auf einem Kreis um die Mitte. Nicht ein einzelner
// Bildpunkt: an der Kante jeder Zone liegt eine geglaettete Reihe, und ein
// einzelner Griff hinein misst eine Mischfarbe, die es als Zone nicht gibt.
function aufKreis(bild, cx, cy, rad, n) {
  const z = new Map();
  for (let i = 0; i < n; i++) {
    const w = 2 * Math.PI * i / n;
    const p = bild.punkt(Math.round(cx + Math.cos(w) * rad),
                         Math.round(cy + Math.sin(w) * rad));
    if (!p) continue;
    const s = p.join(",");
    z.set(s, (z.get(s) || 0) + 1);
  }
  let beste = null, m = -1;
  for (const [s, c] of z) if (c > m) { m = c; beste = s; }
  return beste ? { farbe: beste.split(",").map(Number), anteil: +(m / n).toFixed(2) }
               : { farbe: [0, 0, 0], anteil: 0 };
}

// Wie weit der Kern in jede Richtung reicht. Ein Kreis misst in alle
// Richtungen gleich weit; ein Quadrat reicht in die Ecken um Wurzel zwei
// weiter, und genau daran laesst sich die Gestalt messen statt sie zu glauben.
function kernWeite(bild, cx, cy, r, kern) {
  const achsen = [], schraeg = [];
  for (let i = 0; i < 16; i++) {
    const w = 2 * Math.PI * i / 16;
    let letzt = 0;
    for (let s = 0; s <= r * 1.6; s += 0.25) {
      const p = bild.punkt(Math.round(cx + Math.cos(w) * s),
                           Math.round(cy + Math.sin(w) * s));
      if (p && Math.abs(p[0] - kern[0]) + Math.abs(p[1] - kern[1])
             + Math.abs(p[2] - kern[2]) <= 12) letzt = s;
    }
    (i % 4 === 0 ? achsen : schraeg).push(letzt);
  }
  const mittel = (a) => a.reduce((x, y) => x + y, 0) / a.length;
  return { achsen: +mittel(achsen).toFixed(2), schraeg: +mittel(schraeg).toFixed(2),
           weiteste: +Math.max.apply(null, achsen.concat(schraeg)).toFixed(2) };
}

// Das ganze Verfahren an einem Ort, damit CHANGELOG, Handbuch und Kommentar
// dieselbe Zahl nennen koennen und sie derselbe Lauf ausrechnet:
//
//   Saalfenster, Punkt steht, Bildschirmfoto unskaliert. Die Mitte kommt aus
//   `pruef.zeiger()` (Bruchteil der Buehne), der Radius aus `px / 2`. Grund =
//   haeufigste Farbe auf dem Kreis mit 2,5 Radien (32 Richtungen), Kern auf
//   0,25, heller Ring auf 0,57 und dunkler Ring auf 0,71 Radien (je 16).
//   Kontrast nach WCAG 2.1 zwischen Ring und Grund.
function ringMessen(b64, buehne, z) {
  const bild = pngLesen(b64);
  // Das Bildschirmfoto kann groesser sein als die Seite (Geraeteverhaeltnis).
  const skala = bild.breite / buehne[4];
  const cx = (buehne[0] + buehne[2] * z.x) * skala;
  const cy = (buehne[1] + buehne[3] * z.y) * skala;
  const r = z.px / 2 * skala;
  const grund = aufKreis(bild, cx, cy, r * 2.5, 32);
  const kern = aufKreis(bild, cx, cy, r * 0.25, 16);
  const hell = aufKreis(bild, cx, cy, r * 0.57, 16);
  const dunkel = aufKreis(bild, cx, cy, r * 0.71, 16);
  const w = kernWeite(bild, cx, cy, r, kern.farbe);
  return { bild: bild.breite + "x" + bild.hoehe, skala: +skala.toFixed(2),
           r: +r.toFixed(2), grund: grund, kern: kern, hell: hell, dunkel: dunkel,
           kHell: kontrast(hell.farbe, grund.farbe),
           kDunkel: kontrast(dunkel.farbe, grund.farbe),
           kKern: kontrast(kern.farbe, grund.farbe), weite: w };
}

// `#rrggbb` oder `rgb(r, g, b)` als drei Zahlen. Die Oberflaeche gibt die
// Farbe so heraus, wie sie im Stilblatt steht, und das Bild gibt Zahlen.
function farbeZahlen(s) {
  if (!s) return null;
  const h = String(s).trim().match(/^#([0-9a-f]{6})$/i);
  if (h) return [0, 2, 4].map(i => parseInt(h[1].substr(i, 2), 16));
  const r = String(s).match(/(\d+)\D+(\d+)\D+(\d+)/);
  return r ? [+r[1], +r[2], +r[3]] : null;
}
function nahe(a, b, d) {
  if (!a || !b) return false;
  return Math.abs(a[0] - b[0]) <= d && Math.abs(a[1] - b[1]) <= d
      && Math.abs(a[2] - b[2]) <= d;
}

// Der Akzent des Decks, wie die Laufzeit ihn selbst liest: aus `#ts-cfg`.
// Damit steht die Vorgabe nicht als Zahl in der Probe -- ein Probedeck mit
// einem anderen Thema wuerde sie sonst zum Luegner machen.
const AKZENT = `(JSON.parse(document.getElementById("ts-cfg").textContent).accent || "")`;

// =============================================================================
// Aufraeumen, auch wenn der Lauf nicht bis zum Ende kommt
// =============================================================================
// Aus demselben gemessenen Grund wie in `cdp.js` und `bidi.js`, und nach
// demselben Muster. Gemessen auf diesem Rechner: ein Lauf dieser Proben baut
// sechs Probedecks und einen Paketpfad, und die sieben Ordner blieben ohne
// diese Haken liegen -- nach einem Abbruch UND nach einem sauberen Lauf,
// zusammen 3080 KiB je Lauf. Mit ihnen sind es in beiden Faellen null.
// Der Treiber darunter raeumt seit `bidi.js` sein Profil weg; dann darf das
// Deck daneben nicht liegen bleiben.
const offeneOrdner = new Set();
let haken = false;
function aufraeumenAnmelden(ordner) {
  offeneOrdner.add(ordner);
  if (haken) return;
  haken = true;
  // `exit` feuert auch nach einer geworfenen Ausnahme; dort geht nur
  // Synchrones, und `rmSync` ist synchron.
  process.on("exit", () => {
    for (const o of offeneOrdner) {
      try { fs.rmSync(o, { recursive: true, force: true }); } catch (e) {}
    }
  });
  for (const zeichen of ["SIGINT", "SIGTERM", "SIGHUP"]) {
    process.on(zeichen, () => process.exit(1));
  }
}

// SIGKILL kommt an beidem vorbei. Der einzige Ort, an dem sich das noch
// einsammeln laesst, ist der Start des naechsten Laufs -- sechs Stunden
// Abstand, wie in den zwei Treibern.
const ALTER_STUNDEN = 6;
let gefegt = false;
function alteResteFegen() {
  if (gefegt) return;
  gefegt = true;
  let weg = 0, namen;
  try { namen = fs.readdirSync(os.tmpdir()); } catch (e) { return; }
  const grenze = Date.now() - ALTER_STUNDEN * 3600 * 1000;
  for (const name of namen) {
    if (!name.startsWith("typstage-zeiger-")) continue;
    const ordner = path.join(os.tmpdir(), name);
    try {
      const st = fs.lstatSync(ordner);
      if (!st.isDirectory() || st.mtimeMs > grenze) continue;
      fs.rmSync(ordner, { recursive: true, force: true });
      weg++;
    } catch (e) { /* schon weg, oder nicht unser Recht */ }
  }
  if (weg) console.error("(" + weg + " liegengebliebene Probedecks aufgeräumt)");
}

function bauen(quelle, name, paket) {
  alteResteFegen();
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zeiger-"));
  aufraeumenAnmelden(tmp);
  fs.writeFileSync(path.join(tmp, name + ".typ"), quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", tmp,
    path.join(tmp, name + ".typ"), path.join(tmp, name + ".html")],
    { stdio: ["ignore", "ignore", "pipe"] });
  return path.join(tmp, name + ".html");
}

// Ein Paketpfad, der auf den Arbeitsbaum zeigt, damit ein Probedeck dieselbe
// Quelle uebersetzt, gegen die die Probe laeuft.
function paketpfad(wurzel) {
  alteResteFegen();
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-zeiger-pkg-"));
  aufraeumenAnmelden(paket);
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(wurzel, path.join(paket, raum, "typstage", "0.2.0"));
  }
  return paket;
}

module.exports = { MIT_PUNKT, OHNE_PUNKT, GESTELLT, SPIEGEL, HELL, NACHT, RINGE,
                   PUNKT, FASSUNG, NOETIG, LOG, ARTEN, LEER, STRICHE, AKZENT,
                   BUEHNE,
                   bauen, paketpfad,
                   pngLesen, kontrast, ringMessen, farbeZahlen, nahe };
