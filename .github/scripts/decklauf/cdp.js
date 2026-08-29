// =============================================================================
// cdp.js — ein Chrome über das DevTools-Protokoll, ohne npm
// =============================================================================
// Node ab 21 bringt `fetch` und `WebSocket` global mit, und mehr braucht es
// nicht. Bewusst keine Playwright-Abhängigkeit: ob dieses Paket prüfbar ist,
// soll nicht davon abhängen, dass jemand vorher 200 MB Browser herunterlädt.
// =============================================================================
const { spawn } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");

const schlaf = ms => new Promise(r => setTimeout(r, ms));

// =============================================================================
// Aufräumen, auch wenn der Lauf nicht bis `ende()` kommt
// =============================================================================
// Jeder Browser bekommt ein eigenes Profil im Temp-Verzeichnis, und ein Profil
// wiegt gemessen 68 MB. `ende()` räumt es weg -- aber `ende()` steht am Ende,
// und eine Probe, die vorher wirft, kommt nie dort an. Gemessen auf dem
// Entwicklungsrechner nach einigen Monaten Prüfläufen: 1146 liegengebliebene
// Profile, zusammen 51 GB. Ein Lauf legt rund zwanzig an, und einer davon
// startete gar nicht mehr, weil zu viele verwaiste Chromes den Port hielten.
//
// `exit` feuert auch nach einer geworfenen Ausnahme und nach einer nicht
// behandelten Zusage, und dort geht nur Synchrones -- `rmSync` und `kill` sind
// beides.
const offeneProfile = new Map();
let aufraeumenGesetzt = false;
function aufraeumenAnmelden(profil, kind) {
  offeneProfile.set(profil, kind);
  if (aufraeumenGesetzt) return;
  aufraeumenGesetzt = true;
  process.on("exit", () => {
    for (const [ordner, k] of offeneProfile) {
      try { if (k) k.kill(); } catch (e) {}
      try { fs.rmSync(ordner, { recursive: true, force: true }); } catch (e) {}
    }
  });
  // Ohne das hier beendet ein Abbruch von Hand den Prozess, ohne `exit` zu
  // durchlaufen, und genau der Fall -- ein Lauf, den jemand wegdrückt -- ist
  // der häufigste Grund für ein liegengebliebenes Profil.
  for (const zeichen of ["SIGINT", "SIGTERM", "SIGHUP"]) {
    process.on(zeichen, () => process.exit(1));
  }
}

async function starte(binaer) {
  const profil = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-cdp-"));
  const port = 9200 + Math.floor(Math.random() * 700);
  const kind = spawn(binaer, [
    "--headless=new", "--disable-gpu", "--no-sandbox", "--mute-audio",
    "--force-device-scale-factor=1", "--hide-scrollbars",
    // Ein Deck liegt als Datei da und lädt seine Medien daneben. Ohne das
    // hier zählt jede davon als fremde Herkunft und wird abgelehnt.
    "--allow-file-access-from-files",
    `--user-data-dir=${profil}`, "--window-size=1600,900",
    `--remote-debugging-port=${port}`, "about:blank"
  ], { stdio: "ignore" });
  aufraeumenAnmelden(profil, kind);

  let ziel = null;
  for (let i = 0; i < 120 && !ziel; i++) {
    await schlaf(250);
    try {
      const liste = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
      ziel = liste.find(x => x.type === "page" && x.webSocketDebuggerUrl);
    } catch (e) { /* noch nicht oben */ }
  }
  if (!ziel) { kind.kill(); throw new Error("Chrome meldete sich nicht auf " + port); }

  const verbindung = await verbinde(ziel.webSocketDebuggerUrl, kind, profil);
  // Ein zweites Fenster, das das Deck selbst geöffnet hat (Taste `n`). Es
  // taucht in `/json` als weitere Seite auf; mehr braucht es nicht, um die
  // Fernsteuerung wirklich zu prüfen -- mit nur einem Fenster kann kein Test
  // sehen, ob eine Zuordnung auch drüben ankommt.
  verbindung.zweites = async function (frist) {
    const bekannt = ziel.webSocketDebuggerUrl;
    for (let i = 0; i < (frist || 60); i++) {
      await schlaf(250);
      try {
        const liste = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
        const z = liste.find(x => x.type === "page" && x.webSocketDebuggerUrl
                                  && x.webSocketDebuggerUrl !== bekannt);
        if (z) return await verbinde(z.webSocketDebuggerUrl, null, null);
      } catch (e) { /* noch nicht da */ }
    }
    throw new Error("kein zweites Fenster erschienen");
  };
  return verbindung;
}

async function verbinde(wsUrl, kind, profil) {
  const ws = new WebSocket(wsUrl);
  await new Promise((r, j) => {
    ws.addEventListener("open", r); ws.addEventListener("error", j);
  });
  let id = 0; const offen = new Map();
  ws.addEventListener("message", e => {
    const m = JSON.parse(e.data);
    if (m.id && offen.has(m.id)) { offen.get(m.id)(m); offen.delete(m.id); }
  });
  const ruf = (method, params) => new Promise(r => {
    const n = ++id; offen.set(n, r);
    ws.send(JSON.stringify({ id: n, method, params }));
  });
  const ev = async (ausdruck) => {
    const m = await ruf("Runtime.evaluate",
      { expression: ausdruck, returnByValue: true, awaitPromise: true });
    const f = m.result && m.result.exceptionDetails;
    if (f) throw new Error("JS: " + f.text + " "
      + ((f.exception && f.exception.description) || ""));
    return m.result && m.result.result && m.result.result.value;
  };
  await ruf("Page.enable", {});
  return {
    name: "chrome", ruf, ev,
    navigiere: (url) => ruf("Page.navigate", { url }),
    bild: async () => (await ruf("Page.captureScreenshot", { format: "png" })).result.data,
    // `mod` sind die Modifikatoren, wie das Protokoll sie zaehlt: 8 ist
    // Umschalt. Gebraucht wird das fuer `⇧←`/`⇧→`, die die Vollbilduhr
    // verlaengern -- eine Geste, die sich ohne Umschalt nicht pruefen laesst.
    taste: (k, mod) => ruf("Input.dispatchKeyEvent", {
      type: "keyDown", key: k, modifiers: mod || 0,
      text: k.length === 1 ? k : undefined,
      windowsVirtualKeyCode: k.length === 1 ? k.charCodeAt(0) : undefined
    }).then(() => ruf("Input.dispatchKeyEvent",
      { type: "keyUp", key: k, modifiers: mod || 0 })),
    ende: async () => {
      try { ws.close(); } catch (e) {}
      if (!kind) return;
      await schlaf(200); kind.kill();
      try { fs.rmSync(profil, { recursive: true, force: true }); } catch (e) {}
      offeneProfile.delete(profil);
    }
  };
}
module.exports = { starte, schlaf };
