#!/usr/bin/env python3
"""
bau-themenbild.py — erzeugt `assets/themes.png` aus `assets/themes.typ`.

Zwei Durchgänge: erst dieselbe Folie fünfmal, einmal je Theme, dann die fünf
Bilder auf ein Blatt. Beides setzt Typst; hier steht nur die Reihenfolge.

    python3 .github/scripts/bau-themenbild.py [--ppi 144] [--behalten]

**Von Hand, nicht in der CI.** Die Themes nennen Schriften, die es auf einem
Mac gibt -- Iowan Old Style, Optima, Helvetica Neue. Auf dem Linux-Läufer der
CI fiele Typst auf andere zurück, und das Bild zeigte dann ein Aussehen, das
niemand je zu sehen bekommt. Eine Probe, die das erzwingen wollte, würde bei
jedem Lauf ein anderes Bild melden.

Wer ein Theme anfasst, lässt das hier danach laufen. Das Bild veraltet sonst
still: die Fassung vor dieser zeigte `themes.lesson` mit blauer Überschrift
und oranger Linie, lange nachdem daraus rot auf blauer Linie geworden war.
"""
import os, re, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NAMEN = ("default", "lesson", "night", "plain", "editorial")

def arg(name, vorgabe=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else vorgabe

def paketpfad_bauen():
    """Ein Wegwerf-Paketpfad auf *diesen* Stand.

    Sonst setzte das Bild ein installiertes typstage und nicht das hier
    daneben -- und genau die Änderung, derentwegen jemand das Skript aufruft,
    wäre nicht darauf zu sehen.
    """
    pfad = tempfile.mkdtemp(prefix="typstage-themenbild-")
    version = "0.1.0"
    with open(os.path.join(WURZEL, "typst.toml"), encoding="utf-8") as f:
        m = re.search(r'^version\s*=\s*"([^"]+)"', f.read(), re.M)
        if m:
            version = m.group(1)
    for raum in ("schule", "preview"):
        ziel = os.path.join(pfad, raum, "typstage")
        os.makedirs(ziel)
        os.symlink(WURZEL, os.path.join(ziel, version))
    return pfad

def typst(paketpfad, eingaben, aus):
    quelle = os.path.join(WURZEL, "assets", "themes.typ")
    befehl = ["typst", "compile", "--package-path", paketpfad,
              "--root", WURZEL, "--format", "png", "--ppi", arg("--ppi", "144")]
    for k, v in eingaben.items():
        befehl += ["--input", "%s=%s" % (k, v)]
    befehl += [quelle, aus]
    r = subprocess.run(befehl, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr.strip()[:1200])
        raise SystemExit("bau-themenbild: Typst brach ab")

def main():
    paketpfad = paketpfad_bauen()
    assets = os.path.join(WURZEL, "assets")
    zwischen = []
    try:
        # Durchgang 1. Die Folie ist Seite 2 -- Seite 1 ist die Titelfolie, die
        # `presentation` immer setzt. `{p}` schreibt Typst je Seite eine Datei.
        for name in NAMEN:
            muster = os.path.join(assets, "themes-%s-{p}.png" % name)
            typst(paketpfad, {"modus": "folie", "thema": name}, muster)
            for seite in (1, 2):
                d = os.path.join(assets, "themes-%s-%d.png" % (name, seite))
                if seite == 2:
                    os.replace(d, os.path.join(assets, "themes-%s.png" % name))
                elif os.path.exists(d):
                    os.remove(d)
            zwischen.append(os.path.join(assets, "themes-%s.png" % name))
            print("  gesetzt: themes.%s" % name)

        # Durchgang 2. Das Blatt ist eine Seite, also ohne `{p}`.
        ziel = os.path.join(assets, "themes.png")
        typst(paketpfad, {"modus": "blatt"}, ziel)
        groesse = os.path.getsize(ziel)
        print("\nassets/themes.png: %.2f MB" % (groesse / 1048576))
    finally:
        shutil.rmtree(paketpfad, ignore_errors=True)
        if "--behalten" not in sys.argv:
            for d in zwischen:
                if os.path.exists(d):
                    os.remove(d)
    return 0

if __name__ == "__main__":
    sys.exit(main())
