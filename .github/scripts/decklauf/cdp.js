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

  let ziel = null;
  for (let i = 0; i < 120 && !ziel; i++) {
    await schlaf(250);
    try {
      const liste = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
      ziel = liste.find(x => x.type === "page" && x.webSocketDebuggerUrl);
    } catch (e) { /* noch nicht oben */ }
  }
  if (!ziel) { kind.kill(); throw new Error("Chrome meldete sich nicht auf " + port); }

  const ws = new WebSocket(ziel.webSocketDebuggerUrl);
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
    ende: async () => {
      try { ws.close(); } catch (e) {}
      await schlaf(200); kind.kill();
      try { fs.rmSync(profil, { recursive: true, force: true }); } catch (e) {}
    }
  };
}
module.exports = { starte, schlaf };
