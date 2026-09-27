// pruefe-pult-teiler.js — lässt sich die Folie am Pult kleiner ziehen?
//
// Die Sprecheransicht teilt ihre Höhe zwischen der laufenden Folie und der
// Notiz. Wer viel notiert, will die Folie kleiner und die Notiz größer -- und
// zwar im Vortrag, nicht im Stilblatt. Dafür liegt ein Griff zwischen beiden
// Kacheln.
//
//   node .github/scripts/pruefe-pult-teiler.js [--browser /pfad]
//
// Eigens im Browser: die Aufteilung entsteht erst im Gitter, und ob die Bühne
// nach dem Ziehen noch in ihre Kachel passt, sagt keine Datei. Genau daran ist
// die Ansicht schon einmal gescheitert (siehe `pult.js`, Punkt 1: 93 Pixel aus
// dem Fenster heraus, ohne Rollbalken und ohne Fehler).
//
// Geprüft wird:
//   1. Der Griff ist da, ist ein `separator` und lässt sich mit der Tastatur
//      erreichen. Ein Griff, den nur die Maus findet, ist keiner.
//   2. Ziehen verschiebt die Grenze um das, was gezogen wurde, und zwar in
//      die Richtung, in die gezogen wird: nach oben wird die Folie kleiner und
//      die Notiz um dasselbe größer, nach unten wieder größer. Der Griff liegt
//      auf der Unterkante der Folienkachel, und eine Kante folgt dem Finger.
//      Beide Richtungen stehen hier, weil genau das schon einmal verkehrt
//      herum gebaut war -- nach unten ziehen machte die Folie kleiner.
//   3. Die Bühne passt danach noch in ihre Kachel und behält ihr Seitenmaß.
//      Ohne das wäre die Folie zwar kleiner, aber falsch.
//   4. Die Aufteilung übersteht ein Neuladen. Ein Vortrag wird neu geladen,
//      und niemand zieht dann noch einmal.
//   5. Ein Deck ohne Notizen bekommt keinen Griff: dort gibt es nichts zu
//      teilen, und die Ansicht blendet die Notizkachel ohnehin aus.
const { starte, schlaf } = require("./decklauf/cdp.js");
const { execFileSync } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const WURZEL = path.resolve(__dirname, "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };
const CHROME = arg("--browser",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");

const MIT_NOTIZ = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(theme: themes.lesson, title: [Teiler])

== Erste Folie
Ein Satz.
#speaker-note[
  Eine lange Notiz, damit die Kachel etwas zu zeigen hat. Sie geht über
  mehrere Zeilen, weil genau das der Anlass für den Griff ist: wer viel
  notiert, will die Folie kleiner sehen und die Notiz größer.
]
== Zweite Folie
Noch ein Satz.
#speaker-note[Auch hier steht etwas.]
`;

const OHNE_NOTIZ = `#import "@preview/typstage:0.2.0": *
#show: presentation.with(theme: themes.lesson, title: [Ohne])

== Erste Folie
Ein Satz.
== Zweite Folie
Noch einer.
`;

// Die Höhen der beiden Kacheln und ob die Bühne in ihren Platz passt.
const mass = `(function(){
  var b = document.querySelector('.ts-sp-buehne');
  var n = document.querySelector('.ts-sp-notizkasten');
  var pl = document.querySelector('.ts-sp-platz');
  var st = document.getElementById('ts-stage');
  if (!b || !n) return JSON.stringify({ fehlt: 1 });
  var br = b.getBoundingClientRect(), nr = n.getBoundingClientRect();
  var out = { buehne: Math.round(br.height), notiz: Math.round(nr.height) };
  // Wie weit die Notizkachel in die Kacheln darunter hineinragt. Ihr Boden
  // wird an zwei Stellen gehalten -- in der Rechnung und als min-height im
  // Stilblatt --, und solange eine von beiden greift, ist ihre Hoehe
  // unauffaellig. Was dann noch schiefgehen kann, ist keine Hoehe, sondern
  // eine Ueberlappung.
  var u = document.querySelector('.ts-sp-uhren');
  out.ueber = u ? Math.round(Math.max(0, nr.bottom - u.getBoundingClientRect().top)) : 0;
  if (pl && st) {
    var p = pl.getBoundingClientRect(), s = st.getBoundingClientRect();
    out.raus = Math.round(Math.max(0, s.right - p.right, s.bottom - p.bottom,
                                   p.left - s.left, p.top - s.top));
    out.mass = s.height > 0 ? +(s.width / s.height).toFixed(3) : 0;
  }
  return JSON.stringify(out);
})()`;

const griff = `(function(){
  var g = document.querySelector('.ts-sp-teiler');
  if (!g) return JSON.stringify({ da: false });
  var r = g.getBoundingClientRect();
  return JSON.stringify({ da: true, rolle: g.getAttribute('role'),
    tab: g.getAttribute('tabindex'),
    x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) });
})()`;

function bauen(quelle, name, paket) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-teiler-"));
  fs.writeFileSync(path.join(tmp, name + ".typ"), quelle);
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--package-path", paket, "--root", tmp,
    path.join(tmp, name + ".typ"), path.join(tmp, name + ".html")],
    { stdio: ["ignore", "ignore", "pipe"] });
  return path.join(tmp, name + ".html");
}

(async () => {
  const paket = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-teiler-pkg-"));
  for (const raum of ["schule", "preview"]) {
    fs.mkdirSync(path.join(paket, raum, "typstage"), { recursive: true });
    fs.symlinkSync(WURZEL, path.join(paket, raum, "typstage", "0.2.0"));
  }
  let mit, ohne;
  try {
    mit = bauen(MIT_NOTIZ, "mit", paket);
    ohne = bauen(OHNE_NOTIZ, "ohne", paket);
  } catch (e) {
    const wort = String((e.stderr || "")).split("\n")
      .find(z => z.startsWith("error:")) || "unbekannter Fehler";
    console.log("Pult-Teiler: das Probedeck übersetzt nicht -- " + wort);
    process.exit(1);
  }

  const b = await starte(CHROME);
  const klagen = [];
  await b.ruf("Emulation.setDeviceMetricsOverride",
    { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });
  await b.navigiere("file://" + mit + "#speaker");
  await schlaf(2500);

  // 1. Der Griff
  const g = JSON.parse(await b.ev(griff));
  if (!g.da) {
    klagen.push("zwischen Folie und Notiz liegt kein Griff (.ts-sp-teiler). "
      + "Ohne ihn steht die Aufteilung fest, und wer viel notiert, liest in "
      + "einem Streifen.");
  } else {
    if (g.rolle !== "separator") {
      klagen.push("der Griff meldet sich als '" + g.rolle + "' statt als "
        + "'separator'. Wer die Ansicht nicht sieht, erfährt sonst nicht, "
        + "dass sich hier etwas teilen lässt.");
    }
    if (g.tab === null || +g.tab < 0) {
      klagen.push("der Griff ist mit der Tastatur nicht erreichbar (tabindex "
        + g.tab + "). Ein Griff, den nur die Maus findet, ist keiner -- und "
        + "-1 nimmt ihn aus der Tabreihenfolge heraus, ist also so gut wie "
        + "keiner.");
    }
  }

  if (g.da) {
    const vor = JSON.parse(await b.ev(mass));
    const ZIEH = 150;
    // Ein Zug, in Bildpunkten, von der Mitte des Griffs aus.
    const ziehen = async (dy) => {
      const g2 = JSON.parse(await b.ev(griff));
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mousePressed", x: g2.x, y: g2.y, button: "left", clickCount: 1, buttons: 1 });
      for (let i = 1; i <= 5; i++) {
        await b.ruf("Input.dispatchMouseEvent",
          { type: "mouseMoved", x: g2.x, y: g2.y + (dy * i) / 5, button: "left", buttons: 1 });
        await schlaf(40);
      }
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mouseReleased", x: g2.x, y: g2.y + dy, button: "left", buttons: 0 });
      await schlaf(700);
      return JSON.parse(await b.ev(mass));
    };

    // 2a. Nach oben: die Folie wird kleiner, die Notiz größer.
    const nach = await ziehen(-ZIEH);
    const dB = vor.buehne - nach.buehne, dN = nach.notiz - vor.notiz;
    if (Math.abs(dB - ZIEH) > 24) {
      klagen.push("nach " + ZIEH + " Pixeln Ziehen nach oben ist die "
        + "Folienkachel um " + dB + " Pixel kleiner geworden. Der Griff soll "
        + "die Grenze um das verschieben, was gezogen wurde -- und in die "
        + "Richtung, in die gezogen wird.");
    }
    if (Math.abs(dN - dB) > 24) {
      klagen.push("die Folie gab " + dB + " Pixel ab, die Notiz bekam " + dN
        + ". Was die eine verliert, soll die andere gewinnen.");
    }
    // 3. Die Bühne muss noch passen
    if (nach.raus > 2) {
      klagen.push("die Bühne ragt nach dem Ziehen um " + nach.raus
        + " Pixel aus ihrer Kachel. Sie wird von `fit()` auf den Platz "
        + "gerechnet -- der muss nach dem Ziehen neu vermessen werden.");
    }
    if (vor.mass && Math.abs(nach.mass - vor.mass) > 0.02) {
      klagen.push("das Seitenmaß der Bühne springt von " + vor.mass + " auf "
        + nach.mass + ". Kleiner ja, verzerrt nein.");
    }

    // 4. Neuladen
    await b.ruf("Page.reload", {});
    await schlaf(2500);
    const danach = JSON.parse(await b.ev(mass));
    if (Math.abs(danach.buehne - nach.buehne) > 24) {
      klagen.push("nach dem Neuladen steht die Folienkachel wieder bei "
        + danach.buehne + " statt bei " + nach.buehne
        + ". Ein Vortrag wird neu geladen; niemand zieht dann noch einmal.");
    }

    // 2b. Und wieder nach unten: die Folie wird größer.
    const zurueck = await ziehen(ZIEH);
    if (zurueck.buehne <= danach.buehne + 24) {
      klagen.push("nach unten gezogen wächst die Folienkachel nicht: "
        + danach.buehne + " -> " + zurueck.buehne + ". Der Griff liegt auf "
        + "ihrer Unterkante, und eine Kante folgt dem Finger.");
    }
    if (zurueck.raus > 2) {
      klagen.push("die Bühne ragt nach dem Zurückziehen um " + zurueck.raus
        + " Pixel aus ihrer Kachel.");
    }
  }

  // 6. Tastatur, Doppelklick und die beiden Anschläge
  if (g.da) {
    await b.navigiere("file://" + mit + "#speaker");
    await schlaf(2200);
    await b.ev("sessionStorage.clear()");
    await b.ruf("Page.reload", {}); await schlaf(2300);
    const vorgabe = JSON.parse(await b.ev(mass));
    const schritt0 = await b.ev("window.typstage.state()");

    const taste = async (k, n) => {
      await b.ev("document.querySelector('.ts-sp-teiler').focus()");
      for (let i = 0; i < n; i++) {
        await b.ruf("Input.dispatchKeyEvent",
          { type: "rawKeyDown", key: k, code: k, windowsVirtualKeyCode: k === "ArrowDown" ? 40 : 38 });
        await b.ruf("Input.dispatchKeyEvent", { type: "keyUp", key: k, code: k });
        await schlaf(50);
      }
      await schlaf(500);
      return JSON.parse(await b.ev(mass));
    };

    const runter = await taste("ArrowDown", 4);
    if (runter.buehne <= vorgabe.buehne) {
      klagen.push("Pfeil-ab macht die Folie nicht größer (" + vorgabe.buehne
        + " -> " + runter.buehne + "). Die Tastatur soll dieselbe Richtung "
        + "gehen wie der Zeiger.");
    }
    const hoch = await taste("ArrowUp", 8);
    if (hoch.buehne >= runter.buehne) {
      klagen.push("Pfeil-auf macht die Folie nicht kleiner (" + runter.buehne
        + " -> " + hoch.buehne + ").");
    }
    const schritt1 = await b.ev("window.typstage.state()");
    if (schritt1 !== schritt0) {
      klagen.push("die Pfeiltasten am Griff blättern zusätzlich das Deck "
        + "weiter (Schritt " + schritt0 + " -> " + schritt1 + "). Wer die "
        + "Aufteilung stellt, will nicht gleichzeitig den Vortrag verlieren.");
    }

    // Doppelklick zurück auf die Vorgabe
    const g3 = JSON.parse(await b.ev(griff));
    for (let i = 1; i <= 2; i++) {
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mousePressed", x: g3.x, y: g3.y, button: "left", clickCount: i, buttons: 1 });
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mouseReleased", x: g3.x, y: g3.y, button: "left", clickCount: i, buttons: 0 });
    }
    await schlaf(700);
    const zurueckgesetzt = JSON.parse(await b.ev(mass));
    if (Math.abs(zurueckgesetzt.buehne - vorgabe.buehne) > 8) {
      klagen.push("der Doppelklick setzt nicht auf die Vorgabe zurück ("
        + zurueckgesetzt.buehne + " statt " + vorgabe.buehne + "). Er steht "
        + "in drei Sprachen im Hinweis am Griff; dann muss er auch gehen.");
    }

    // Die beiden Anschläge: weit über beide hinaus, keine Kachel darf fallen
    const g4 = JSON.parse(await b.ev(griff));
    const weit = async (dy) => {
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mousePressed", x: g4.x, y: g4.y, button: "left", clickCount: 1, buttons: 1 });
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mouseMoved", x: g4.x, y: g4.y + dy, button: "left", buttons: 1 });
      await b.ruf("Input.dispatchMouseEvent",
        { type: "mouseReleased", x: g4.x, y: g4.y + dy, button: "left", buttons: 0 });
      await schlaf(700);
      return JSON.parse(await b.ev(mass));
    };
    const ganzRunter = await weit(2000);
    if (ganzRunter.ueber > 1) {
      klagen.push("am unteren Anschlag ragt die Notizkachel " + ganzRunter.ueber
        + " Pixel in die Zahlen darunter.");
    }
    if (ganzRunter.notiz < 40) {
      klagen.push("ganz nach unten gezogen bleibt der Notiz nur "
        + ganzRunter.notiz + " Pixel. Eine Kachel, die zusammenfällt, ist "
        + "keine Aufteilung mehr.");
    }
    if (ganzRunter.raus > 2) {
      klagen.push("am unteren Anschlag ragt die Bühne um " + ganzRunter.raus
        + " Pixel aus ihrer Kachel.");
    }
    const ganzHoch = await weit(-2000);
    if (ganzHoch.buehne < 60) {
      klagen.push("ganz nach oben gezogen bleibt der Folie nur "
        + ganzHoch.buehne + " Pixel.");
    }
    if (ganzHoch.raus > 2) {
      klagen.push("am oberen Anschlag ragt die Bühne um " + ganzHoch.raus
        + " Pixel aus ihrer Kachel.");
    }
    if (ganzHoch.ueber > 1) {
      klagen.push("am oberen Anschlag ragt die Notizkachel " + ganzHoch.ueber
        + " Pixel in die Zahlen darunter.");
    }
  }

  // 5. Ein Deck ohne Notizen bekommt keinen Griff
  await b.navigiere("file://" + ohne + "#speaker");
  await schlaf(2200);
  const g2 = JSON.parse(await b.ev(griff));
  if (g2.da) {
    klagen.push("ein Deck ohne Notizen zeigt trotzdem einen Griff. Dort gibt "
      + "es nichts zu teilen -- die Notizkachel ist ausgeblendet.");
  }

  await b.ende();
  fs.rmSync(paket, { recursive: true, force: true });

  if (klagen.length) {
    console.log("Pult-Teiler: " + klagen.length + " Beanstandung(en)");
    for (const k of klagen) console.log("  - " + k);
    process.exit(1);
  }
  console.log("Pult-Teiler: die Folie lässt sich kleiner ziehen, und es bleibt so");
})().catch(e => { console.error(e); process.exit(1); });
