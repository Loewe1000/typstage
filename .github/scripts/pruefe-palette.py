#!/usr/bin/env python3
"""
pruefe-palette.py — das Kontrastgatter der Sprecheransicht

Warum eigens: `contrast()` im Paket bewacht die *Folienpaletten*. Die zwanzig
Farben der Sprecheransicht leben im Stilblatt und standen unter keiner
Aufsicht -- `satz` im Decklauf merkt jede Änderung am Stilblatt, sagt aber
nicht, *was* sich geändert hat. Wer eine Textfarbe absenkte, kam an allem
vorbei außer an einem Menschen. Genau so entstanden die 4,38 und die 3,41,
die in der letzten Runde gefunden wurden.

Geprüft wird dreierlei:

  1. Beide Bilder tragen dieselben Namen, keiner ist leer, und keiner steht
     nur in einem der beiden Blöcke.
  2. Jedes Paar aus Satz und Fläche erreicht seine Schwelle -- 4,5 für Text,
     3,0 für Flächen, die man unterscheiden muss, 1,2 für die stille
     Trennung von Kachel und Grund.
  3. Jede Farbe ist deckend. `contrast()` rechnet ohne Alpha und nennte für
     ein `#ffffff70` die Zahl von vollem Weiß -- eine Zahl, die nie auf dem
     Schirm stand.

Wer ein Paar hinzufügt, schreibt hin, was es bedeutet. Wer eins wegnimmt,
nimmt eine Prüfung weg.

    python3 .github/scripts/pruefe-palette.py [--css pfad]
"""
import io, os, re, sys

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def arg(name, vorgabe):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else vorgabe

def kanal(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def leuchte(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) for i in (0, 2, 4))
    return 0.2126 * kanal(r) + 0.7152 * kanal(g) + 0.0722 * kanal(b)

def kontrast(a, b):
    la, lb = leuchte(a), leuchte(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

# (Satz, Fläche, Schwelle, was es ist)
PAARE = [
    ("--sp-satz",        "--sp-kachel",        4.5, "Satz auf Kachel"),
    ("--sp-satz",        "--sp-grund",         4.5, "Satz auf Grund"),
    ("--sp-leise",       "--sp-kachel",        4.5, "leiser Wert auf Kachel"),
    ("--sp-leise",       "--sp-grund",         4.5, "leiser Wert auf Grund"),
    ("--sp-marke",       "--sp-kachel",        4.5, "Marke auf Kachel"),
    ("--sp-marke",       "--sp-grund",         4.5, "Marke auf Grund, und der Fokusring"),
    ("--sp-uhr",         "--sp-kachel",        4.5, "laufende Klassenuhr"),
    ("--sp-vor",         "--sp-kachel",        4.5, "vor Plan"),
    ("--sp-alarm",       "--sp-kachel",        4.5, "Warnfarbe auf Kachel"),
    ("--sp-alarm",       "--sp-alarm-flaeche", 4.5, "Überzeit auf ihrer Fläche"),
    ("--sp-pille-satz",  "--sp-pille",         4.5, "Satz auf der Signalpille"),
    ("--sp-ruhig-satz",  "--sp-ruhig",         4.5, "Satz auf der ruhigen Pille"),
    ("--sp-zeiger-satz", "--sp-zeiger",        4.5, "Satz auf dem Zeigerschalter"),
    ("--sp-grund",       "--sp-satz",          4.5, "die umgedrehte Pille: schwarz"),
    ("--sp-uhr",         "--sp-spur",          3.0, "Uhrbalken in seiner Spur"),
    ("--sp-leise",       "--sp-spur",          3.0, "Fortschrittsbalken in seiner Spur"),
    ("--sp-pille",       "--sp-kachel",        3.0, "Signalpille auf Kachel"),
    ("--sp-zeiger",      "--sp-grund",         3.0, "Zeigerschalter auf Grund"),
    ("--sp-folienrand",  "--sp-kachel",        3.0, "die Kante der Folie"),
    ("--sp-kachel",      "--sp-grund",         1.2, "Kachel gegen Grund"),
    ("--sp-rand",        "--sp-grund",         1.2, "Rand auf Grund"),
    ("--sp-spur",        "--sp-kachel",        1.2, "Spur auf Kachel"),
    ("--sp-alarm-flaeche", "--sp-kachel",      1.2, "Überzeitfläche auf Kachel"),
    ("--sp-ruhig",       "--sp-kachel",        1.2, "ruhige Pille auf Kachel"),
]

def lies(pfad):
    s = io.open(pfad, encoding="utf-8").read()
    aus = {}
    for bild in ("dunkel", "hell"):
        marke = 'html[data-ts-licht="%s"]{' % bild
        if marke not in s:
            return None, 'im Stilblatt fehlt der Block %s' % marke
        i = s.index(marke)
        j = s.index("\n}", i)
        aus[bild] = dict(re.findall(r'(--sp-[a-z-]+)\s*:\s*([^;]+);', s[i:j]))
    return (aus, s), None

def main():
    css = arg("--css", os.path.join(WURZEL, "assets", "typstage-0.1.0.css"))
    daten, fehler = lies(css)
    if fehler:
        print("FEHLER: " + fehler, file=sys.stderr)
        return 2
    p, ganz = daten
    maengel = []
    def sagt(s): 
        print("ABWEICHUNG: " + s, file=sys.stderr)
        maengel.append(s)

    # 1 ── beide Bilder, dieselben Namen
    nd, nh = set(p["dunkel"]), set(p["hell"])
    for name in sorted(nd - nh):
        sagt("%s steht nur im dunklen Block" % name)
    for name in sorted(nh - nd):
        sagt("%s steht nur im hellen Block" % name)
    for bild in ("dunkel", "hell"):
        for name, wert in sorted(p[bild].items()):
            if not wert.strip():
                sagt("%s ist im %s Bild leer" % (name, bild))

    # 2 ── jede Farbe deckend, und jede benutzt
    farbe = re.compile(r"^#[0-9a-fA-F]{6}$")
    for bild in ("dunkel", "hell"):
        for name, wert in sorted(p[bild].items()):
            w = wert.strip()
            # `--sp-kachel-null` *muss* durchsichtig sein: es ist der eine
            # Halt eines Verlaufs, mit dem die uebervolle Notiz ausblendet,
            # und ein Verlauf, der von der Kachelfarbe zur Kachelfarbe geht,
            # blendet nichts aus. Es steht in keinem Paar.
            if name in ("--sp-schatten", "--sp-kachel-null") or not w.startswith("#"):
                continue
            if not farbe.match(w):
                sagt("%s trägt im %s Bild %s -- eine Farbe mit Alpha. "
                     "Der Kontrast, den man dafür ausrechnet, stand nie auf "
                     "dem Schirm." % (name, bild, w))
    for name in sorted(nd):
        if len(re.findall(r"var\(%s\b" % re.escape(name), ganz)) == 0:
            sagt("%s wird nirgends benutzt" % name)

    # 3 ── die Paare
    breit = max(len(t[3]) for t in PAARE)
    print("%-*s %8s %8s   will" % (breit, "Paar", "dunkel", "hell"))
    for a, b, schwelle, was in PAARE:
        zeile = []
        for bild in ("dunkel", "hell"):
            va, vb = p[bild].get(a, ""), p[bild].get(b, "")
            if not farbe.match(va.strip()) or not farbe.match(vb.strip()):
                zeile.append(None); continue
            zeile.append(kontrast(va.strip(), vb.strip()))
        if None in zeile:
            sagt("%s: eine der beiden Farben ist keine" % was); continue
        print("%-*s %8.2f %8.2f   %.1f%s" % (breit, was, zeile[0], zeile[1], schwelle,
              "" if min(zeile) >= schwelle else "   <<<"))
        for bild, k in zip(("dunkel", "hell"), zeile):
            if k < schwelle:
                sagt("%s misst im %s Bild %.2f, verlangt sind %.1f"
                     % (was, bild, k, schwelle))

    print("\nPalette: " + ("%d Abweichungen" % len(maengel) if maengel
                           else "%d Paare, keines unter der Schwelle" % (len(PAARE) * 2)))
    return 1 if maengel else 0

if __name__ == "__main__":
    sys.exit(main())
