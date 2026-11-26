// pruefe-pult-module.js — zeigt das Pult, was die Lehrkraft sehen will, und
// merkt es sich?
//
// Die Sprecheransicht besteht aus Modulen (`slide`, `next`, `notes`,
// `elapsed`, `progress`, `target`, `clock`, `tools`, `media`). Was es davon
// gibt, entscheidet das Deck hart (`speaker-view: (clock: false, ...)`); was
// davon zu sehen ist, entscheidet die Lehrkraft am Pult -- ueber drei
// Voreinstellungen, das Blatt hinter `,` oder `typstage.pult` --, und der
// Browser merkt es sich global in `localStorage` (`typstage:pult:v1`).
//
//   node .github/scripts/pruefe-pult-module.js [--browser /pfad]
//
// Eigens im Browser, aus drei Gruenden. Ob eine Folie den frei gewordenen
// Platz bekommt, entsteht erst im Raster (`sprecherSpalten`), und ob die
// Buehne danach noch in ihre Kachel passt, sagt keine Datei. Was sich der
// Browser merkt, gilt ueber Dateien und Ordner hinweg -- das sieht nur ein
// Lauf, der zwei Decks an zwei Orten im selben Browser oeffnet. Und der
// Stundenzaehler reist ueber den Kanal zwischen zwei Fenstern zurueck; mit
// einem Fenster ist nicht zu sehen, ob er drueben ankommt.
//
// Geprueft wird:
//   1. Ohne Speicher und ohne Typst-Vorgabe startet das Pult als `full`,
//      mit allen Modulen, und nichts steht im Speicher.
//   2. Jede Voreinstellung zeigt genau ihre Module -- nachgesehen am DOM,
//      nicht an `stand()`, denn `stand()` liest dieselbe Auswahl, die es
//      pruefen soll. `lesson` ueber das Blatt (`,`, Leertaste): die Taste
//      blaettert dabei nicht, und Escape schliesst es wieder.
//   3. `minimal`: Kachelzeile und Werkzeugleiste sind fort, ohne Phantom-
//      abstand -- Folie und Notiz reichen bis an den Boden, die Folie ist
//      groesser als bei `full`, und die Buehne passt mit ihrem Seitenmass in
//      ihre Kachel. Dazu die beiden Faelle der zweiten Zeile: nur die Notiz
//      (volle Breite, kein Spaltenteiler) und gar keine (die Folie nimmt
//      die ganze Hoehe, kein Griff).
//   4. `lesson`: die eine Klassenuhr fuellt ihre Zeile, breit und schmal --
//      vorher stand sie in einem Viertel davon. Hochkant (480x800) passt die
//      Buehne bei `minimal`, nur mit der Klassenuhr, ohne Module mit `t`
//      und mit laufender Uhr, und bei `full`.
//   5. Neuladen behaelt die Auswahl, und ein ZWEITES Deck in einem anderen
//      Ordner sieht im selben Browser dieselbe.
//   6. Bei ausgeblendeter Uhr blendet `t` sie ein, solange das Minutenfeld
//      offen ist (der Fokus muss im Feld landen), und Escape blendet sie
//      wieder aus; eine Ziffer startet die Uhr und zeigt sie, `0` beendet
//      sie. Ebenso `d` bei ausgeblendeter Zieldauer: Fokus im Feld, `4 7
//      Enter` setzt sie, und keine Klassenuhr startet. Ausblenden schaltet
//      keine Taste ab. Escape schliesst das Blatt auch mit dem Fokus
//      ausserhalb, ohne die Uebersicht aufzuklappen.
//   7. `#speaker&reset` loescht den Pultstand (nicht die Zieldauer), nimmt
//      `&reset` aus der Adresse und startet mit den Vorgaben.
//   8. Typst als Startwert: `preset: "lesson"` und `modules: (...)`. Was
//      gespeichert ist, gewinnt feldweise -- steht nur `split` im Speicher,
//      kommen die Module weiter aus Typst.
//   9. `tools: false` nimmt nur die Zeichenwerkzeuge: Medienzeile, `?` und
//      hell/dunkel bleiben stehen. Ist auch die Medienzeile ausgeblendet,
//      verschwindet die Leiste ganz. Im Blatt ist `tools` grau.
//  10. Das Pult schliessen und mit `n` neu oeffnen behaelt den Stunden-
//      zaehler (Rueckweg ueber die Buehne), `r` setzt ihn auch dort zurueck
//      -- auch im sessionStorage des Pults, das eine mit `n` geoeffnete
//      Buehne erbt.
//  11. Typst lehnt ein Modul ab, das dasselbe Deck hart abschaltet, und eine
//      einzelne Zeichenkette statt einer Liste.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser", process.env.CHROME || (process.platform === "darwin"
  ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" : "google-chrome"));

const KOPF = `#import "@preview/typstage:0.3.0": *
`;
const FOLIEN = `
== Erste Folie
Ein Satz.
#speaker-note[
  Eine Notiz über mehrere Zeilen, damit die Kachel etwas zu zeigen hat.
  Noch ein Satz, und noch einer.
]
== Zweite Folie
Noch ein Satz.
#pause
Und mehr.
#speaker-note[Auch hier steht etwas.]
`;
const deck = (sv) => KOPF + `#show: presentation.with(theme: themes.lesson, title: [Module]`
  + (sv ? ", speaker-view: " + sv : "") + ")\n" + FOLIEN;

const DECKS = {
  // Zwei Decks in zwei Ordnern: der Speicher gilt ueber beide.
  "a/deck": deck(""),
  "b/deck": deck(""),
  "lesson/deck": deck(`(preset: "lesson")`),
  "module/deck": deck(`(modules: ("notes", "clock"))`),
  // Medien und keine Zeichenwerkzeuge. Das Video liegt neben dem Deck.
  "medien/deck": KOPF + `#show: presentation.with(theme: themes.lesson, title: [Medien], speaker-view: (tools: false))
== Ohne Medien
Ein Satz.
#speaker-note[Eine Notiz.]
== Mit Medien
#video("demo.mp4", width: 200pt, height: 120pt)
#speaker-note[Medien.]
`
};
const FALSCH = {
  // Die Muster sind die gezielten Meldungen, nicht nur ein Wort daraus:
  // "clock" und "modules" stehen auch in der allgemeinen Meldung fuer einen
  // unbekannten Schluessel, und ein Validator, der `modules` irrtuemlich
  // ganz ablehnte, kaeme sonst durch.
  "hart-aus": [`(clock: false, modules: ("notes", "clock"))`, /modules shows "clock", but clock: false/],
  "zeichenkette": [`(modules: ("notes"))`, /modules is a list of modules, not a single/]
};

const PULT = "typstage:pult:v1";
const MODULE = ["next", "notes", "elapsed", "progress", "target", "clock", "tools", "media"];
const VOR = {
  full: MODULE.slice(),
  lesson: ["next", "notes", "clock", "tools", "media"],
  minimal: ["next", "notes"]
};

// Was am Pult wirklich dasteht, je Modul, dazu die Masse fuer die Rechnung.
// Sichtbar heisst: im Dokument, kein Vorfahr versteckt, und eine Flaeche.
// Das `hidden`-Attribut allein sagt nichts -- `.ts-sp-kachel` setzt selbst
// ein `display`, und genau deshalb braucht es die Regel im Stilblatt.
const MESS = `(function(){
  var L = document.querySelector('.ts-sp-leib');
  if (!L) return JSON.stringify({ fehlt: 1 });
  function sicht(el) {
    if (!el || !document.contains(el)) return false;
    for (var e = el; e && e !== document.documentElement; e = e.parentElement) {
      if (e.hidden) return false;
      var cs = getComputedStyle(e);
      if (cs.display === 'none' || cs.visibility === 'hidden') return false;
    }
    // display:contents (Zeichenwerkzeuge, Medienzeile) hat selbst
    // keine Flaeche; er steht da, wenn eines seiner Kinder dasteht.
    if (getComputedStyle(el).display === 'contents') {
      for (var c = el.firstElementChild; c; c = c.nextElementSibling) if (sicht(c)) return true;
      return false;
    }
    var r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  }
  function rect(el) {
    var r = el.getBoundingClientRect();
    return { l: r.left, t: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height };
  }
  var out = { modul: {} };
  ${JSON.stringify(MODULE)}.forEach(function (m) {
    out.modul[m] = sicht(L.querySelector('[data-modul="' + m + '"]'));
  });
  var lr = rect(L);
  out.leib = lr;
  // Der Boden: wie weit unter der untersten sichtbaren Kachel noch Leib ist.
  var unten = 0;
  for (var c = L.firstElementChild; c; c = c.nextElementSibling) {
    if (c.classList.contains('ts-sp-teiler')) continue;
    if (sicht(c)) unten = Math.max(unten, c.getBoundingClientRect().bottom);
  }
  out.luft = Math.round(lr.b - unten);
  var b = document.querySelector('.ts-sp-buehne');
  out.buehne = b ? Math.round(b.getBoundingClientRect().height) : 0;
  var u = L.querySelector('.ts-sp-uhren');
  out.uhren = sicht(u);
  out.leiste = sicht(L.querySelector('.ts-sp-werkzeugleiste'));
  var uk = L.querySelector('[data-modul="clock"]');
  out.uhrAnteil = (sicht(u) && sicht(uk))
    ? +(uk.getBoundingClientRect().width / u.getBoundingClientRect().width).toFixed(3) : 0;
  out.uhrKacheln = 0;
  if (u) for (var k = u.firstElementChild; k; k = k.nextElementSibling) if (sicht(k)) out.uhrKacheln++;
  var n = L.querySelector('.ts-sp-notizkasten');
  out.notizAnteil = sicht(n) ? +(n.getBoundingClientRect().width / lr.w).toFixed(3) : 0;
  out.teiler = sicht(L.querySelector('.ts-sp-teiler:not(.ts-sp-spaltenteiler)'));
  out.spaltenteiler = sicht(L.querySelector('.ts-sp-spaltenteiler'));
  var pl = document.querySelector('.ts-sp-platz'), st = document.getElementById('ts-stage');
  if (pl && st) {
    var p = pl.getBoundingClientRect(), s = st.getBoundingClientRect();
    out.raus = Math.round(Math.max(0, s.right - p.right, s.bottom - p.bottom,
                                   p.left - s.left, p.top - s.top));
    out.mass = s.height > 0 ? +(s.width / s.height).toFixed(3) : 0;
  }
  return JSON.stringify(out);
})()`;
const STAND = "JSON.stringify(window.typstage.pult.stand())";

function bauen(quelle, datei, paket, wurzel) {
  fs.mkdirSync(path.dirname(datei), { recursive: true });
  fs.writeFileSync(datei + ".typ", quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", wurzel, datei + ".typ", datei + ".html"],
    { stdio: ["ignore", "ignore", "pipe"] });
  return datei + ".html";
}

(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-module-"));
  const paket = path.join(tmp, "pkg");
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.3.0"));
  }
  const decks = path.join(tmp, "decks");
  fs.mkdirSync(path.join(decks, "medien"), { recursive: true });
  fs.copyFileSync(path.join(WURZEL, "examples", "demo.mp4"), path.join(decks, "medien", "demo.mp4"));
  const url = {};
  try {
    for (const [name, quelle] of Object.entries(DECKS)) {
      url[name.split("/")[0]] = "file://" + bauen(quelle, path.join(decks, name), paket, decks);
    }
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Pult-Module: ein Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const klagen = [];
  const klage = (s) => klagen.push(s);

  // 11. Typst lehnt ab, was nicht gehen kann. Ohne Browser, deshalb zuerst.
  for (const [name, [sv, muster]] of Object.entries(FALSCH)) {
    let meldung = null;
    try {
      bauen(deck(sv), path.join(tmp, "falsch", name), paket, tmp);
    } catch (e) {
      meldung = String(e.stderr || "");
    }
    if (meldung === null) {
      klage("`speaker-view: " + sv + "` übersetzt ohne Fehler. Ein Modul, das "
        + "dasselbe Deck abschaltet, oder eine Zeichenkette statt einer Liste "
        + "ist ein Versehen, und es soll beim Bauen auffallen, nicht am Pult.");
    } else if (!muster.test(meldung)) {
      klage("`speaker-view: " + sv + "` scheitert, aber die Meldung nennt "
        + muster + " nicht: " + meldung.split("\n").find(z => z.startsWith("error:")));
    }
  }

  const b = await starte(CHROME);
  const masse = (w, h) => b.ruf("Emulation.setDeviceMetricsOverride",
    { width: w, height: h, deviceScaleFactor: 1, mobile: false });
  const mess = async () => JSON.parse(await b.ev(MESS));
  const stand = async () => JSON.parse(await b.ev(STAND));
  const oeffne = async (u, warte) => {
    await b.navigiere("about:blank"); await schlaf(200);
    await b.navigiere(u); await schlaf(warte || 2200);
  };
  // Die Module am DOM gegen eine Erwartung. `media` bleibt aussen vor: die
  // Zeile steht nur auf Folien mit Medien, und diese Folien haben keine.
  const moduleSind = (m, soll, wo) => {
    const falsch = MODULE.filter(x => x !== "media")
      .filter(x => m.modul[x] !== soll.includes(x));
    if (falsch.length) {
      klage(wo + ": falsch dargestellt sind " + falsch.map(x =>
        x + (m.modul[x] ? " (steht da, soll fort sein)" : " (fehlt)")).join(", ") + ".");
    }
  };
  const passt = (m, wo, mass) => {
    if (m.raus > 2) {
      klage(wo + ": die Bühne ragt " + m.raus + " Pixel aus ihrer Kachel. "
        + "Nach jedem Umschalten muss `fit()` neu vermessen.");
    }
    if (mass && Math.abs(m.mass - mass) > 0.02) {
      klage(wo + ": das Seitenmaß der Bühne ist " + m.mass + " statt " + mass + ".");
    }
  };

  try {
    await masse(1400, 900);

    // ── 1 Vorgabe ─────────────────────────────────────────────────────────
    await oeffne(url.a + "#speaker");
    await b.ev("localStorage.clear(); sessionStorage.clear()");
    await b.ruf("Page.reload", {}); await schlaf(2200);
    let s = await stand();
    if (!s || s.preset !== "full" || s.stored) {
      klage("ohne Speicher startet das Pult nicht als `full`: " + JSON.stringify(s));
    }
    const voll = await mess();
    moduleSind(voll, VOR.full, "full");
    passt(voll, "full");
    const SEITE = voll.mass;
    if (!voll.uhren || !voll.leiste) {
      klage("bei `full` fehlt " + (!voll.uhren ? "die Kachelzeile" : "die Werkzeugleiste") + ".");
    }

    // ── 2 Voreinstellungen ───────────────────────────────────────────────
    // `lesson` wie ein Mensch: `,`, Fokus auf den Knopf, Leertaste.
    const schritt0 = await b.ev("typstage.state()");
    await b.taste(","); await schlaf(300);
    const blatt = JSON.parse(await b.ev(`JSON.stringify((function(){
      var bl = document.querySelector('.ts-sp-blatt');
      return { da: !!bl, auf: !!bl && !bl.hidden,
               fokus: !!bl && bl.contains(document.activeElement) };
    })())`));
    if (!blatt.auf || !blatt.fokus) {
      klage("`,` öffnet das Blatt nicht" + (blatt.auf ? " mit dem Fokus darin" : "")
        + ". Ohne Fokus im Blatt gehen Tab und Leertaste an die Folie.");
    } else {
      await b.ev("document.querySelector('.ts-sp-blatt-knopf[data-preset=lesson]').focus()");
      await b.taste(" "); await schlaf(400);
      s = await stand();
      if (s.preset !== "lesson") klage("Leertaste auf „Unterricht“ im Blatt wählt " + s.preset + ".");
      if (await b.ev("typstage.state()") !== schritt0) {
        klage("die Leertaste im Blatt blättert zusätzlich das Deck weiter.");
      }
      await b.taste("Escape"); await schlaf(300);
      if (!(await b.ev("document.querySelector('.ts-sp-blatt').hidden"))) {
        klage("Escape schließt das Blatt nicht.");
      }
    }
    for (const p of ["lesson", "minimal", "full"]) {
      if (p !== "lesson") { await b.ev(`typstage.pult.voreinstellung('${p}')`); await schlaf(400); }
      const m = await mess();
      moduleSind(m, VOR[p], p);
      passt(m, p, SEITE);
      s = await stand();
      if (s.preset !== p) klage("nach `" + p + "` meldet stand() " + s.preset + ".");
    }

    // ── 3 minimal: die Folie bekommt den Platz ──────────────────────────
    await b.ev("typstage.pult.voreinstellung('minimal')"); await schlaf(400);
    let m = await mess();
    if (m.uhren) klage("bei `minimal` steht die Kachelzeile noch da, ohne eine sichtbare Kachel.");
    if (m.leiste) klage("bei `minimal` steht die Werkzeugleiste noch da, ohne Werkzeuge und ohne Medien.");
    if (m.luft > 4) {
      klage("bei `minimal` bleiben unter der Notiz " + m.luft + " Pixel leer. Eine "
        + "ausgeblendete Zeile darf keinen Abstand und keine Höhe behalten.");
    }
    if (m.buehne <= voll.buehne + 20) {
      klage("bei `minimal` ist die Folie nicht größer als bei `full` (" + voll.buehne
        + " -> " + m.buehne + "). Was Kachelzeile und Werkzeuge freigeben, soll sie bekommen.");
    }
    passt(m, "minimal", SEITE);
    // Nur die Notiz: volle Breite, kein Spaltenteiler.
    await b.ev("typstage.pult.modul('next', false)"); await schlaf(400);
    m = await mess();
    if (m.notizAnteil < 0.97) {
      klage("ohne Vorschau nimmt die Notiz nur " + m.notizAnteil + " der Breite.");
    }
    if (m.spaltenteiler) klage("ohne Vorschau steht der Spaltenteiler noch da -- er teilt nichts mehr.");
    if (!m.teiler) klage("mit Notiz unter der Folie fehlt der Griff dazwischen.");
    s = await stand();
    if (s.preset !== "custom") klage("eine Auswahl abseits der drei heißt " + s.preset + " statt custom.");
    // Gar keine zweite Zeile: die Folie nimmt die ganze Hoehe.
    await b.ev("typstage.pult.modul('notes', false)"); await schlaf(400);
    m = await mess();
    if (m.teiler) klage("ohne Notiz und Vorschau steht der Griff unter der Folie noch da.");
    if (Math.abs(m.buehne - m.leib.h) > 4) {
      klage("ohne Notiz und Vorschau ist die Folienkachel " + m.buehne + " Pixel hoch, "
        + "der Leib " + Math.round(m.leib.h) + ". Sie soll den ganzen Platz bekommen.");
    }
    passt(m, "nur die Folie", SEITE);

    // ── 4 lesson: eine Uhr fuellt ihre Zeile, breit und schmal ──────────
    await b.ev("typstage.pult.voreinstellung('lesson')"); await schlaf(400);
    for (const [w, h] of [[1400, 900], [700, 900]]) {
      await masse(w, h); await schlaf(600);
      m = await mess();
      if (m.uhrKacheln !== 1 || m.uhrAnteil < 0.97) {
        klage("`lesson` bei " + w + "x" + h + ": " + m.uhrKacheln + " Kachel(n) in der "
          + "Zahlenzeile, die Klassenuhr nimmt " + m.uhrAnteil + " der Zeile. Allein soll sie sie füllen.");
      }
      passt(m, "lesson bei " + w + "x" + h, SEITE);
    }
    // Und hochkant mit `minimal`: auch dort passt die Buehne.
    await masse(480, 800); await schlaf(400);
    await b.ev("typstage.pult.voreinstellung('minimal')"); await schlaf(500);
    passt(await mess(), "minimal hochkant", SEITE);
    // Hochkant mit Kachelzeile, aber ohne Notiz und Vorschau. Ein voriger
    // Lauf hatte der Kachelzeile Zeile 2 gegeben, und die ist in der
    // Vorlage hochkant die `1fr`-Zeile -- gemessen wurde die gestreckte
    // Hoehe, die Folie schrumpfte auf 52 px und die Buehne ragte heraus.
    // Ebenso ohne jedes Modul, wenn `t` die Uhr voruebergehend einblendet.
    const hochkantFolie = async (wo) => {
      const mm = await mess();
      passt(mm, wo, SEITE);
      if (mm.buehne < mm.leib.h * 0.5) {
        klage(wo + ": die Folienkachel ist " + mm.buehne + " Pixel hoch bei einem "
          + Math.round(mm.leib.h) + " Pixel hohen Leib. Ohne Notiz und Vorschau gehört ihr der Platz.");
      }
    };
    for (const id of MODULE) await b.ev(`typstage.pult.modul('${id}', ${id === "clock"})`);
    await schlaf(500);
    await hochkantFolie("hochkant nur mit der Klassenuhr");
    await b.ev("typstage.pult.modul('clock', false)"); await schlaf(400);
    await b.ev("document.activeElement && document.activeElement.blur()");
    await b.taste("t"); await schlaf(500);
    await hochkantFolie("hochkant ohne Module, Uhr nach t");
    await b.taste("Escape"); await schlaf(300);
    await b.taste("3"); await schlaf(500);
    await hochkantFolie("hochkant ohne Module, laufende Uhr");
    await b.taste("0"); await schlaf(500);
    await b.ev("typstage.pult.voreinstellung('full')"); await schlaf(400);
    passt(await mess(), "full hochkant", SEITE);
    await b.ev("typstage.pult.voreinstellung('lesson')"); await schlaf(300);
    await masse(1400, 900); await schlaf(500);

    // ── 5 Neuladen, und ein zweites Deck ─────────────────────────────────
    await b.ruf("Page.reload", {}); await schlaf(2200);
    s = await stand();
    if (s.preset !== "lesson" || !s.stored) {
      klage("nach dem Neuladen steht das Pult auf " + s.preset + " (gespeichert: "
        + s.stored + ") statt auf lesson.");
    }
    moduleSind(await mess(), VOR.lesson, "lesson nach dem Neuladen");
    await oeffne(url.b + "#speaker");
    s = await stand();
    if (s.preset !== "lesson") {
      klage("ein zweites Deck in einem anderen Ordner steht auf " + s.preset
        + " statt auf lesson. Die Auswahl gilt für den Browser, nicht für eine Datei.");
    }
    moduleSind(await mess(), VOR.lesson, "lesson im zweiten Deck");

    // ── 6 Die versteckte Uhr kommt, wenn sie gebraucht wird ─────────────
    await b.ev("typstage.pult.voreinstellung('minimal')"); await schlaf(400);
    await b.ev("document.activeElement && document.activeElement.blur()");
    await b.taste("t"); await schlaf(400);
    m = await mess();
    const feld = await b.ev("!!document.activeElement && document.activeElement.classList.contains('ts-sp-uhrfeld')");
    if (!m.modul.clock) klage("`t` bei ausgeblendeter Uhr öffnet das Minutenfeld, ohne die Kachel zu zeigen.");
    if (!feld) klage("nach `t` bei ausgeblendeter Uhr liegt der Fokus nicht im Minutenfeld -- die Ziffern laufen ins Leere.");
    passt(m, "Uhr nach t", SEITE);
    await b.taste("Escape"); await schlaf(400);
    m = await mess();
    if (m.modul.clock) klage("nach Escape im Minutenfeld bleibt die ausgeblendete Uhr stehen.");
    s = await stand();
    if (s.preset !== "minimal") klage("das vorübergehende Einblenden der Uhr hat die Auswahl verändert: " + s.preset);
    await b.taste("3"); await schlaf(500);
    if (!(await mess()).modul.clock) {
      klage("eine Ziffer startet die Klassenuhr, aber die ausgeblendete Kachel bleibt fort -- die Restzeit ist am Pult nicht abzulesen.");
    }
    await b.taste("0"); await schlaf(500);
    m = await mess();
    if (m.modul.clock) klage("nach `0` bleibt die ausgeblendete Uhr stehen.");
    passt(m, "nach 0", SEITE);
    // Dasselbe fuer `d`: die Zieldauer ist bei `minimal` ausgeblendet, und
    // ein verstecktes Feld nimmt keinen Fokus. Die Ziffern liefen sonst an
    // die Klassenuhr und starteten im Saal eine Pause.
    await b.ev("document.activeElement && document.activeElement.blur()");
    await b.taste("d"); await schlaf(400);
    const zielFeld = await b.ev("document.activeElement === document.getElementById('ts-sp-ziel')");
    if (!zielFeld) klage("`d` bei ausgeblendeter Zieldauer setzt den Fokus nicht ins Feld.");
    if (!(await mess()).modul.target) klage("`d` bei ausgeblendeter Zieldauer zeigt die Kachel nicht.");
    await b.taste("4"); await b.taste("7"); await b.taste("Enter"); await schlaf(500);
    const ziel = await b.ev("typstage.sprecher.ziel()");
    m = await mess();
    if (ziel !== 47) klage("`d 4 7 Enter` bei ausgeblendeter Zieldauer setzt sie auf " + ziel + " statt 47.");
    if (m.modul.clock) klage("`d` und Ziffern bei ausgeblendeter Zieldauer haben eine Klassenuhr gestartet.");
    if (m.modul.target) klage("nach Enter bleibt die ausgeblendete Zieldauer stehen.");
    passt(m, "nach d", SEITE);
    await b.ev("typstage.sprecher.ziel(0)");

    // Escape schliesst das Blatt auch, wenn der Fokus nicht mehr darin liegt
    // (es ist nicht modal); die Uebersicht geht dabei nicht auf.
    await b.taste(","); await schlaf(300);
    await b.ev("document.activeElement && document.activeElement.blur()");
    await b.taste("Escape"); await schlaf(300);
    const esc = JSON.parse(await b.ev(`JSON.stringify({
      blatt: !document.querySelector('.ts-sp-blatt').hidden,
      uebersicht: !!document.querySelector('#ts-overview[data-on]') })`));
    if (esc.blatt) klage("Escape mit dem Fokus außerhalb des Blatts lässt es offen.");
    if (esc.uebersicht) {
      klage("Escape mit offenem Blatt klappt die Folienübersicht auf.");
      await b.taste("Escape"); await schlaf(300);
    }

    // ── 7 #speaker&reset ─────────────────────────────────────────────────
    await oeffne(url.a + "#speaker");
    await b.ev("typstage.sprecher.ziel(45)");
    await schlaf(200);
    await oeffne(url.a + "#speaker&reset");
    s = await stand();
    const hash = await b.ev("location.hash");
    const roh = await b.ev(`localStorage.getItem('${PULT}')`);
    if (s.preset !== "full" || s.stored) {
      klage("`#speaker&reset` startet als " + s.preset + " (gespeichert: " + s.stored + ") statt full.");
    }
    if (hash !== "#speaker") klage("`&reset` bleibt in der Adresse stehen (" + hash + "); jedes Neuladen setzte dann wieder zurück.");
    if (roh !== null) klage("nach `#speaker&reset` steht noch ein Pultstand im Speicher: " + roh);
    if (await b.ev("typstage.sprecher.ziel()") !== 45) {
      klage("`#speaker&reset` hat die Zieldauer des Decks gelöscht. Sie gehört zum Deck, nicht zur Ansicht.");
    }
    moduleSind(await mess(), VOR.full, "nach #speaker&reset");

    // ── 8 Typst als Startwert ────────────────────────────────────────────
    await b.ev("localStorage.clear()");
    await oeffne(url.lesson + "#speaker");
    s = await stand();
    if (s.preset !== "lesson" || s.stored) {
      klage("`speaker-view: (preset: \"lesson\")` startet als " + s.preset + " (gespeichert: " + s.stored + ").");
    }
    moduleSind(await mess(), VOR.lesson, "Typst preset lesson");
    await oeffne(url.module + "#speaker");
    s = await stand();
    const vis = (s.visible || []).slice().sort().join(",");
    if (s.preset !== "custom" || vis !== "clock,notes,slide") {
      klage("`speaker-view: (modules: (\"notes\", \"clock\"))` startet als " + s.preset
        + " mit " + vis + " statt custom mit slide, notes, clock.");
    }
    moduleSind(await mess(), ["notes", "clock"], "Typst modules");
    // Nur `split` im Speicher: die Module kommen weiter aus Typst.
    await b.ev(`localStorage.setItem('${PULT}', JSON.stringify({v: 1, split: {slide: 0.5, notes: 0.6}}))`);
    await oeffne(url.lesson + "#speaker");
    s = await stand();
    if (s.preset !== "lesson" || !s.stored) {
      klage("steht nur die Aufteilung im Speicher, verliert das Deck seine Typst-Vorgabe: "
        + s.preset + " (gespeichert: " + s.stored + "). Gespeichertes gewinnt feldweise.");
    }
    // Eine gespeicherte Auswahl schlaegt Typst.
    await b.ev("typstage.pult.voreinstellung('minimal')"); await schlaf(300);
    await b.ruf("Page.reload", {}); await schlaf(2200);
    s = await stand();
    if (s.preset !== "minimal") {
      klage("eine gespeicherte Auswahl verliert gegen `preset: \"lesson\"` aus Typst: " + s.preset + ".");
    }
    // Kaputtes JSON: Typst-Vorgabe, kein Absturz.
    await b.ev(`localStorage.setItem('${PULT}', '{kaputt')`);
    await b.ruf("Page.reload", {}); await schlaf(2200);
    s = await stand();
    if (!s || s.preset !== "lesson") {
      klage("mit kaputtem JSON im Speicher startet das Pult nicht mit der Typst-Vorgabe: " + JSON.stringify(s));
    }

    // ── 9 tools:false nimmt nur die Zeichenwerkzeuge ─────────────────────
    await b.ev("localStorage.clear()");
    await oeffne(url.medien + "#speaker");
    m = await mess();
    const kopf = JSON.parse(await b.ev(`JSON.stringify((function(){
      var ks = [].slice.call(document.querySelectorAll('.ts-sp-kopfknopf'));
      var da = function (k) { if (!k) return false; var r = k.getBoundingClientRect();
        return r.width > 0 && r.height > 0 && getComputedStyle(k).visibility !== 'hidden'; };
      return { zeichen: !!document.querySelector('.ts-sp-zeichenwz'),
               hilfe: da(ks.filter(function (k) { return k.textContent.trim() === '?'; })[0]),
               licht: da(document.querySelector('.ts-sp-licht')) };
    })())`));
    if (kopf.zeichen) klage("`tools: false` lässt die Zeichenwerkzeuge im Dokument stehen.");
    if (!kopf.hilfe) klage("bei `tools: false` fehlt der Knopf `?` -- ohne ihn findet niemand die Tastenleiste.");
    if (!kopf.licht) klage("bei `tools: false` fehlt der Knopf für hell/dunkel.");
    if (m.leiste) klage("bei `tools: false` steht auf einer Folie ohne Medien eine leere Werkzeugleiste.");
    s = await stand();
    if (s.available.includes("tools")) klage("bei `tools: false` meldet stand() die Werkzeuge als verfügbar.");
    await b.ev("typstage.pult.blatt(true)"); await schlaf(200);
    if (!(await b.ev("document.getElementById('ts-sp-modul-tools').disabled"))) {
      klage("im Blatt lässt sich `tools` anhaken, obwohl das Deck sie abgeschaltet hat.");
    }
    await b.ev("typstage.pult.blatt(false)");
    await b.ev("document.activeElement && document.activeElement.blur()");
    await b.taste("End"); await schlaf(900);
    m = await mess();
    if (!m.modul.media) klage("bei `tools: false` fehlt auf der Medienfolie die Medienzeile.");
    if (!m.leiste) klage("bei `tools: false` fehlt auf der Medienfolie die Werkzeugleiste, die die Medienzeile trägt.");
    passt(m, "Medienfolie", SEITE);
    await b.ev("typstage.pult.modul('media', false)"); await schlaf(400);
    m = await mess();
    if (m.modul.media) klage("ausgeblendet steht die Medienzeile weiter da.");
    if (m.leiste) klage("ohne Werkzeuge und ohne Medienzeile steht die Werkzeugleiste noch da.");
    passt(m, "Medienfolie ohne Medienzeile", SEITE);
    await b.ev("typstage.pult.modul('media', true)"); await schlaf(400);
    if (!(await mess()).modul.media) klage("wieder eingeblendet kommt die Medienzeile nicht zurück.");

    // ── 10 Der Stundenzaehler uebersteht das Schliessen ──────────────────
    await oeffne(url.a, 1500);
    if (await b.ev("typstage.pult.stand()") !== null) {
      klage("im Vortragsfenster antwortet typstage.pult.stand() nicht mit null.");
    }
    let kommt = b.zweites();
    await b.taste("n");
    let p = await kommt; await schlaf(1800);
    await p.taste("ArrowRight"); await schlaf(1200);
    const z1 = await p.ev("typstage.sprecher.zeit()");
    if (!(z1 > 0)) klage("im Pult läuft nach dem ersten Schritt keine Stunde.");
    await schlaf(1200);
    await p.ev("window.close()"); await schlaf(800);
    kommt = b.zweites();
    await b.taste("n");
    p = await kommt; await schlaf(2500);
    const z2 = await p.ev("typstage.sprecher.zeit()");
    if (!(z2 > z1 + 1)) {
      klage("das mit `n` neu geöffnete Pult hat den Stundenzähler verloren (" + z1.toFixed(1)
        + " s -> " + Number(z2).toFixed(1) + " s). Die Bühne soll ihn zurückgeben.");
    }
    await p.taste("r"); await schlaf(1500);
    // Eine Buehne, die das Pult selbst mit `n` oeffnet, erbt eine Kopie
    // *seines* sessionStorage und liest daraus `ts-stunde:`. Steht dort
    // noch der Wert, den das Pult beim eigenen Oeffnen geerbt hat, holt sie
    // die zurueckgesetzte Stunde zurueck.
    // Nur der Schluessel dieses Decks: das Fenster war vorher Pult anderer
    // Decks, und deren Stunden stehen zu Recht unter ihren Pfaden.
    const geerbt = await p.ev(`JSON.stringify(Object.keys(sessionStorage)
      .filter(function (k) { return k.indexOf('ts-stunde:' + location.pathname + '|') === 0; })
      .map(function (k) { return sessionStorage.getItem(k); }))`);
    if (geerbt !== '["0"]') {
      klage("nach `r` steht im sessionStorage des Pults unter `ts-stunde:` " + geerbt
        + " statt [\"0\"]. Eine Bühne, die das Pult mit `n` öffnet, holte die alte Stunde zurück.");
    }
    await p.ev("window.close()"); await schlaf(800);
    kommt = b.zweites();
    await b.taste("n");
    p = await kommt; await schlaf(2500);
    const z3 = await p.ev("typstage.sprecher.zeit()");
    if (z3 !== 0) {
      klage("nach `r` bringt das neu geöffnete Pult die alte Stunde zurück (" + Number(z3).toFixed(1)
        + " s). Das Zurücksetzen muss auch bei der Bühne ankommen.");
    }
  } finally {
    await b.ende();
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  if (klagen.length) {
    console.log("Pult-Module: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Pult-Module: das Pult zeigt, was gewählt ist, und merkt es sich");
})().catch(e => { console.error(e); process.exit(1); });
