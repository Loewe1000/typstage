// =============================================================================
// bidi.js — ein Firefox über WebDriver-BiDi, ohne npm
// =============================================================================
// Firefox ab 129 spricht auf `--remote-debugging-port` nur noch BiDi und kein
// CDP mehr, deshalb ein zweiter Treiber statt eines gemeinsamen. Die Fläche,
// die `pruefe-decks.js` benutzt, ist bei beiden dieselbe: `ev`, `navigiere`,
// `bild`, `ende`.
// =============================================================================
const { spawn } = require("child_process");
const fs = require("fs"), os = require("os"), path = require("path");
const schlaf = ms => new Promise(r => setTimeout(r, ms));

async function starte(binaer) {
  const profil = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-bidi-"));
  const port = 9800 + Math.floor(Math.random() * 150);
  const kind = spawn(binaer, ["--headless", "--no-remote", "--profile", profil,
    "--remote-debugging-port", String(port), "about:blank"],
    { stdio: "ignore", env: Object.assign({}, process.env, { MOZ_HEADLESS: "1" }) });

  let ws = null;
  for (let i = 0; i < 120 && !ws; i++) {
    await schlaf(250);
    try {
      const s = new WebSocket(`ws://127.0.0.1:${port}/session`);
      await new Promise((r, j) => {
        s.addEventListener("open", r); s.addEventListener("error", j);
      });
      ws = s;
    } catch (e) { /* noch nicht oben */ }
  }
  if (!ws) { kind.kill(); throw new Error("Firefox meldete sich nicht auf " + port); }

  let id = 0; const offen = new Map();
  ws.addEventListener("message", e => {
    const m = JSON.parse(e.data);
    if (m.id != null && offen.has(m.id)) { offen.get(m.id)(m); offen.delete(m.id); }
  });
  const ruf = (method, params = {}) => new Promise(r => {
    const n = ++id; offen.set(n, r);
    ws.send(JSON.stringify({ id: n, method, params }));
  });

  const s = await ruf("session.new", { capabilities: { alwaysMatch: {} } });
  if (s.error) throw new Error("session.new: " + JSON.stringify(s));
  const ctx = (await ruf("browsingContext.getTree", {})).result.contexts[0].context;

  const ev = async (ausdruck) => {
    const m = await ruf("script.evaluate", { expression: ausdruck,
      target: { context: ctx }, awaitPromise: true, resultOwnership: "none" });
    if (m.error) throw new Error("BiDi: " + JSON.stringify(m).slice(0, 400));
    if (m.result.type === "exception")
      throw new Error("JS: " + ((m.result.exceptionDetails
        && m.result.exceptionDetails.text) || JSON.stringify(m.result)));
    const v = m.result.result;
    return v && "value" in v ? v.value : undefined;
  };
  return {
    name: "firefox", ruf, ev, ctx,
    // `wait: "complete"` statt eines festen Schlafs. Der Aufrufer wartet
    // danach trotzdem noch auf `window.typstage.pruef`: fertig geladen heißt
    // nicht, dass die Laufzeit ihr Deck schon aufgebaut hat.
    navigiere: (url) => ruf("browsingContext.navigate",
      { context: ctx, url, wait: "complete" }),
    bild: async () => (await ruf("browsingContext.captureScreenshot",
      { context: ctx })).result.data,
    ende: async () => {
      try { await ruf("browser.close", {}); } catch (e) {}
      try { ws.close(); } catch (e) {}
      await schlaf(300); kind.kill();
      try { fs.rmSync(profil, { recursive: true, force: true }); } catch (e) {}
    }
  };
}
module.exports = { starte, schlaf };
