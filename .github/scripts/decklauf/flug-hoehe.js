// =============================================================================
// flug-hoehe.js — was während eines Fluges übereinander liegt
// =============================================================================
// Warum eigens: der große Prüflauf misst Decks im *Ruhezustand*. Er fährt sie
// durch, wartet nach jedem Schritt, bis nichts mehr läuft, und liest dann ab.
// Was während der Bewegung übereinander liegt, sieht er nie -- und genau dort
// saß der Fehler, der das hier ausgelöst hat:
//
//   Auf `mosaic-greyscale` fliegt eine Kachel auf die nächste Folie und wird
//   dort zur ganzen Fläche. Unten rechts steht eine Bildunterschrift, die im
//   Ruhezustand über dem Bild liegt. Während des Fluges verschwand sie und kam
//   erst wieder, als das Bild stand. Grund: der Geist hängt auf `#ts-fly`
//   (z-index 5), sie hängt in der Folie -- zwei getrennte Stapelkontexte,
//   zwischen die kein z-index passt.
//
// Gemessen wird mit angehaltenen Animationen: jede `animate()`-Anfrage wird
// beim Auslösen sofort pausiert und danach auf feste Bruchteile des Fluges
// gestellt. So hängt keine Messung an einem Zeitgeber, und der Lauf ist auf
// einer langsamen Maschine derselbe wie auf einer schnellen.
//
// Treffertests brauchen dafür `pointer-events`, die die Flugebene sonst nicht
// hat. Das Prüfblatt setzt sie; gemalt wird dadurch nichts anders, die
// Stapelreihenfolge ist dieselbe.
//
//   node .github/scripts/decklauf/flug-hoehe.js [--browser /pfad]
// =============================================================================
const fs = require("fs"), path = require("path"), os = require("os");
const { execFileSync } = require("child_process");
const { starte, schlaf } = require("./cdp.js");

const WURZEL = path.resolve(__dirname, "..", "..", "..");
const arg = (n, v) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : v; };

function browserSuchen() {
  const k = ["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
             "/Applications/Chromium.app/Contents/MacOS/Chromium",
             "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable",
             "/usr/bin/chromium", "/usr/bin/chromium-browser", "/snap/bin/chromium"];
  const da = k.find(x => fs.existsSync(x));
  if (!da) { console.error("FEHLER: kein Chrome gefunden, --browser angeben."); process.exit(2); }
  return da;
}

function deckBauen() {
  const pp = fs.mkdtempSync(path.join(os.tmpdir(), "typstage-fh-"));
  const ziel = path.join(pp, "schule", "typstage");
  fs.mkdirSync(ziel, { recursive: true });
  fs.symlinkSync(WURZEL, path.join(ziel, "0.1.0"), "dir");
  const aus = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "typstage-fh-h-")), "flugdeck.html");
  execFileSync("typst", ["compile", "--format", "html", "--features", "html",
    "--root", WURZEL, "--package-path", pp,
    path.join(__dirname, "flugdeck.typ"), aus], { stdio: ["ignore", "ignore", "pipe"] });
  return aus;
}

// Die drei Sprites der zweiten Folie, in Quellreihenfolge: UNTEN, der `morph`,
// OBEN. Gemerkt wird *vor* dem Tastendruck -- was der Flug hochzieht, hängt
// danach nicht mehr unter seiner Folie und wäre dort nicht mehr zu finden.
const MERKEN = `(() => {
  const st = document.createElement('style');
  st.textContent = '#ts-fly *,.ts-el,.ts-el *{pointer-events:auto!important}';
  document.head.appendChild(st);
  // Die letzte Folie: das Deck stellt eine Titelfolie voran, gezaehlt wird
  // also nicht ab dem, was in der Quelle zuerst steht.
  const alle = document.querySelectorAll('.ts-slide');
  const f = alle[alle.length - 1];
  const ov = f.querySelector('.ts-ov');
  const el = [...ov.querySelectorAll('.ts-el')];
  window.__fh = { ov: ov, unten: el[0], morph: el[1], oben: el[2], fern: el[3],
                  fly: document.getElementById('ts-fly') };
  return JSON.stringify({
    anzahl: el.length,
    zweitesIstMorph: !!(el[1] && el[1].classList.contains('ts-morph')),
    andereKeinMorph: [0, 2, 3].every(i => el[i] && !el[i].classList.contains('ts-morph'))
  });
})()`;

// Einfrieren und an feste Punkte des Fluges stellen. Gibt für jeden Punkt
// zurück, wer an der Mitte von OBEN und von UNTEN ganz oben liegt.
const FRIEREN = `(() => {
  const h = window.__fh;
  const orig = Element.prototype.animate; const anims = [];
  Element.prototype.animate = function (...a) {
    const an = orig.apply(this, a); anims.push(an); try { an.pause(); } catch (e) {}
    return an;
  };
  // Auch die Aufräum-Zeitgeber: sonst ist der Geist fort, ehe gemessen wird.
  const oT = window.setTimeout; window.setTimeout = function () { return 0; };
  document.dispatchEvent(new KeyboardEvent('keydown',
    { key: 'ArrowRight', bubbles: true, cancelable: true }));
  window.__fhAus = () => { Element.prototype.animate = orig; window.setTimeout = oT; };
  const wer = (el) => {
    const r = el.getBoundingClientRect();
    const t = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
    if (!t) return 'nichts';
    if (t === el || el.contains(t)) return 'selbst';
    if (t.closest('#ts-fly')) return 'geist';
    return 'anderes';
  };
  // Steht in diesem Augenblick ueberhaupt ein Geist ueber der Mitte des
  // Elements? Der Geist waechst von der Kachel zur ganzen Flaeche; ehe er
  // unten links angekommen ist, sagt ein Treffertest dort nichts ueber die
  // Hoehe aus.
  const gedeckt = (el) => {
    const r = el.getBoundingClientRect();
    const x = r.x + r.width / 2, y = r.y + r.height / 2;
    return [...h.fly.querySelectorAll('.ts-ghost')].some(g => {
      const q = g.getBoundingClientRect();
      return x >= q.left && x <= q.right && y >= q.top && y <= q.bottom;
    });
  };
  const bahn = (f) => {
    anims.forEach(an => { const t = an.effect && an.effect.getTiming(); if (!t) return;
      try { an.currentTime = (t.delay || 0) + (t.duration || 0) * f; } catch (e) {} });
    return { f: f, oben: wer(h.oben), unten: wer(h.unten),
             obenGedeckt: gedeckt(h.oben), untenGedeckt: gedeckt(h.unten),
             fernGedeckt: gedeckt(h.fern), fernOben: h.fern.parentElement === h.fly };
  };
  return JSON.stringify([0.25, 0.5, 0.75, 1].map(bahn));
})()`;

// Wo die drei nach dem Flug hängen, und in welcher Reihenfolge.
const RUHE = `(() => {
  const h = window.__fh;
  const el = [...h.ov.querySelectorAll('.ts-el')];
  return JSON.stringify({
    obenInFolie: h.oben.parentElement === h.ov,
    untenInFolie: h.unten.parentElement === h.ov,
    reihenfolge: [h.unten, h.morph, h.oben, h.fern].map(x => el.indexOf(x)).join('/'),
    geisterUebrig: h.fly.children.length
  });
})()`;

// Das Verhältnis von OBEN zur Bühne. Ändert sich das Fenster während des
// Fluges, muss der Hochgezogene mitwandern -- er gehört weiter zu seiner Folie,
// auch wenn er gerade nicht unter ihr hängt.
const VERHAELTNIS = `(() => {
  const h = window.__fh;
  const b = document.getElementById('ts-stage').getBoundingClientRect();
  const r = h.oben.getBoundingClientRect();
  return JSON.stringify({ x: (r.x - b.x) / b.width, y: (r.y - b.y) / b.height,
                          w: r.width / b.width,
                          buehne: Math.round(b.width) + "x" + Math.round(b.height) });
})()`;

(async () => {
  const datei = deckBauen();
  const c = await starte(arg("--browser", browserSuchen()));
  let maengel = [];
  const sagt = (b, s) => { console.error("ABWEICHUNG " + b + ": " + s); maengel.push(s); };
  const laden = async () => {
    await c.navigiere("file://" + datei);
    await schlaf(1500);
    // Auf den Schritt vor der letzten Folie: erst der naechste Tastendruck
    // loest den Flug aus. Das Deck stellt eine Titelfolie voran, ein festes
    // "#1" traefe also den Wechsel davor.
    await c.ev("typstage.goto(typstage.steps.length - 2, true)");
    await schlaf(600);
  };

  try {
    // ── 1 Die Stellung selbst ────────────────────────────────────────────────
    await laden();
    const bau = JSON.parse(await c.ev(MERKEN));
    if (bau.anzahl !== 4 || !bau.zweitesIstMorph || !bau.andereKeinMorph) {
      sagt("deck", "flugdeck.typ trägt nicht mehr die Stellung, die hier geprüft "
        + "wird: erwartet UNTEN, morph, OBEN, FERN, gefunden " + JSON.stringify(bau)
        + ". Ohne sie prüft dieser Lauf nichts.");
      throw new Error("Prüfling passt nicht");
    }

    // ── 2 Wer liegt während des Fluges oben ──────────────────────────────────
    const punkte = JSON.parse(await c.ev(FRIEREN));
    for (const p of punkte) {
      if (!p.obenGedeckt && p.f >= 0.75) {
        sagt("deck", "bei " + Math.round(p.f * 100) + "% des Fluges deckt kein Geist "
          + "die Mitte von OBEN. Dann prüft dieser Lauf die Höhe nicht mehr -- "
          + "flugdeck.typ muss die beiden so stellen, dass die Bahn sie trifft.");
      }
      if (p.fernOben) {
        sagt("bahn", "bei " + Math.round(p.f * 100) + "% des Fluges hängt FERN in "
          + "der Flugebene. Es liegt außerhalb der Bahn, der Flug hat es nie "
          + "verdeckt -- hochgezogen erscheint es vor seiner eigenen Folie.");
      }
      if (p.fernGedeckt) {
        sagt("deck", "FERN liegt in der Bahn des Fluges. Dann prüft dieser Lauf "
          + "nicht mehr, dass nur Verdecktes hochgezogen wird -- flugdeck.typ muss "
          + "es außerhalb stellen.");
      }
      if (p.oben !== "selbst") {
        sagt("hoehe", "bei " + Math.round(p.f * 100) + "% des Fluges liegt über OBEN "
          + "nicht OBEN, sondern " + p.oben + ". Ein Element, das im Ruhezustand "
          + "über dem Ziel steht, verschwindet also, solange geflogen wird.");
      }
      if (p.untenGedeckt && p.unten !== "geist") {
        sagt("hoehe", "bei " + Math.round(p.f * 100) + "% des Fluges steht ein Geist "
          + "über UNTEN, oben liegt aber " + p.unten + ". UNTEN steht vor dem `morph` "
          + "und gehört darunter -- der Flug zieht zu viel hoch.");
      }
    }

    // ── 3 Wandert der Hochgezogene beim Vergrößern mit ───────────────────────
    const vorher = JSON.parse(await c.ev(VERHAELTNIS));
    await c.ruf("Emulation.setDeviceMetricsOverride",
      { width: 1100, height: 700, deviceScaleFactor: 1, mobile: false });
    await schlaf(400);
    const nachher = JSON.parse(await c.ev(VERHAELTNIS));
    console.log("    Bühne " + vorher.buehne + " → " + nachher.buehne
      + ", OBEN w " + vorher.w.toFixed(4) + " → " + nachher.w.toFixed(4));
    await c.ruf("Emulation.clearDeviceMetricsOverride", {});
    for (const k of ["x", "y", "w"]) {
      if (Math.abs(vorher[k] - nachher[k]) > 0.01) {
        sagt("groesse", "das Fenster wurde mitten im Flug kleiner, und OBEN "
          + "wanderte nicht mit: " + k + " " + vorher[k].toFixed(3) + " → "
          + nachher[k].toFixed(3) + ". Ort und Maß eines Hochgezogenen stehen in "
          + "Prozent auf derselben Fläche wie vorher -- stimmt das nicht mehr, "
          + "trägt die Flugebene nicht dieselbe Geometrie wie die Folie, und der "
          + "ganze Umzug ist unsicher.");
      }
    }
    await c.ev("window.__fhAus()");

    // ── 4 Kommen beide zurück ────────────────────────────────────────────────
    const zurueck = async (titel, schritte) => {
      await laden();
      await c.ev(MERKEN);
      for (const [t, w] of schritte) { await c.taste(t); await schlaf(w); }
      await schlaf(1400);
      const r = JSON.parse(await c.ev(RUHE));
      if (!r.obenInFolie || !r.untenInFolie) {
        sagt("rueckkehr", titel + ": ein Sprite hängt nach dem Flug nicht wieder "
          + "unter seiner Folie (OBEN " + r.obenInFolie + ", UNTEN " + r.untenInFolie
          + "). Es liegt dann über allem, was noch kommt.");
      }
      if (r.reihenfolge !== "0/1/2/3") {
        sagt("rueckkehr", titel + ": die Quellreihenfolge kam als " + r.reihenfolge
          + " zurück statt als 0/1/2/3.");
      }
      if (r.geisterUebrig !== 0) {
        sagt("rueckkehr", titel + ": " + r.geisterUebrig + " Knoten blieben in der "
          + "Flugebene liegen.");
      }
    };
    await zurueck("Flug ausgelaufen", [["ArrowRight", 1500]]);
    await zurueck("mitten im Flug weiter", [["ArrowRight", 200], ["ArrowRight", 900]]);
    await zurueck("mitten im Flug zurück", [["ArrowRight", 200], ["ArrowLeft", 900]]);
  } catch (e) {
    if (!maengel.length) sagt("lauf", e.message);
  } finally {
    await c.ende();
  }
  console.log("\nFlughöhe: " + (maengel.length ? maengel.length + " Abweichungen" : "ohne Abweichung"));
  process.exit(maengel.length ? 1 : 0);
})();
