#!/usr/bin/env python3
"""Übersetzt ein Deck fünfmal konvergiert -- oder gar nicht?

    python3 .github/scripts/pruefe-konvergenz.py

Typst läuft die Auszeichnung bis zu fünfmal und gibt dann auf. Ein Deck, das
nicht konvergiert, übersetzt trotzdem: es meldet nur eine Warnung und liefert
irgendeinen der Zwischenstände. Im Bau der Beispiele fällt das auf, weil dort
auf Warnungen geachtet wird -- aber nur für Decks, die es gibt.

Diese Probe hält die Aufbauten fest, die es einmal zerrissen hat. Alle haben
dieselbe Gestalt: ein aufdeckender Befehl, dessen Schritt aus dem gelesenen
Schrittzeiger *berechnet* und an `track` hereingereicht wird, dazu ein Körper
mit etwas außerhalb des Flusses (`place` mit Verschiebung) und ein Kasten
fester Größe. Gemessen an einem echten Deck der Klasse 5: fünf Warnungen bei
`cue`, neun bei `stagger`.

Behoben ist es, indem die Kette ihre Schritte von `track` vergeben lässt
(`at: auto`) statt sie selbst zu rechnen. Diese Probe misst das Ergebnis, nicht
den Weg dorthin: sie fragt nur, ob das Deck konvergiert.
"""
import os, re, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

RUMPF = """#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [Konvergenz])

== Folie
#box(width: 600pt, height: 216pt, {{
  anim[Davor]
  for w in (0, 1, 2) {{
    {aufruf}
  }}
}})
"""

STUECK = 'box(width: 80pt, height: 62pt, place(top + left, dx: 35pt, [x]))'

FAELLE = {
    "cue, drei Aufrufe":      'cue("g", %s)' % STUECK,
    "stagger, drei Aufrufe":  'stagger(%s)' % STUECK,
    "anim, drei Aufrufe":     'anim(%s)' % STUECK,
    "cue im place":           'place(top + left, dx: w * 100pt, cue("g", %s))' % STUECK,
    "alternatives":           'alternatives(%s, %s)' % (STUECK, STUECK),
    "tiles":                  'tiles(%s, %s)' % (STUECK, STUECK),
    "build":                  'build(k => %s, steps: 2)' % STUECK,
}

# Noch offen. Beide hängen am selben Mechanismus -- mit ausgeschriebenem
# Schritt sind sie still --, aber der Weg über `at: auto` steht ihnen nicht
# offen: eine `scene` ist *ein* Element über mehrere Schritte, und `camera`
# ruft `track` gar nicht auf, sondern trägt seinen Schritt nur in eine Liste
# ein. Die Probe hält sie fest, ohne den Lauf rot zu färben -- und schlägt an,
# wenn einer von ihnen still wird: dann gehört er nach oben.
OFFEN = {
    "scene":                  'scene("s" + str(w), t => %s, stops: (0, 1), tween: 4)' % STUECK,
}

# `camera` zielt auf ein `pin` und braucht deshalb einen eigenen Rumpf.
KAMERA = """#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [Konvergenz])

== Folie
#box(width: 600pt, height: 216pt, {{
  anim[Davor]
  place(top + left, pin(<ziel>, {stueck}))
  for w in (0, 1, 2) {{ camera(<ziel>) }}
}})
""".format(stueck=STUECK)


def messen(quelle, ordner, paketpfad):
    datei = os.path.join(ordner, "deck.typ")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(quelle)
    lauf = subprocess.run(
        ["typst", "compile", "--format", "html", "--features", "html",
         "--package-path", paketpfad, "--root", ordner,
         datei, os.path.join(ordner, "deck.html")],
        capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        return None, fehler[0]
    n = len(re.findall(r"did not converge|did not stabilize", lauf.stderr))
    return n, None


def main():
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.1.1"))
        klagen = []
        for name, aufruf in FAELLE.items():
            n, fehler = messen(RUMPF.format(aufruf=aufruf), tmp, paket)
            if fehler is not None:
                klagen.append("%s: übersetzt nicht -- %s" % (name, fehler))
            elif n:
                klagen.append(
                    "%s: %d Konvergenzmeldung(en). Der Schritt wird aus dem "
                    "gelesenen Schrittzeiger berechnet und an track "
                    "hereingereicht; mit `at: auto` vergibt track ihn selbst, "
                    "und die Messung bleibt stabil." % (name, n))

        offene = [(name, RUMPF.format(aufruf=a)) for name, a in OFFEN.items()]
        offene.append(("camera", KAMERA))
        for name, quelle in offene:
            n, fehler = messen(quelle, tmp, paket)
            if fehler is not None:
                klagen.append("%s (bekannt offen): übersetzt nicht -- %s"
                              % (name, fehler))
            elif not n:
                klagen.append(
                    "%s steht als bekannt offen in dieser Probe, meldet aber "
                    "nichts mehr. Entweder ist es behoben -- dann gehört es "
                    "nach oben zu den Fällen, die sauber sein müssen -- oder "
                    "der Aufbau trifft es nicht mehr." % name)
            else:
                print("  bekannt offen: %s (%d Meldungen)" % (name, n))
        if klagen:
            print("Konvergenz: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Konvergenz: %d Aufbauten stabil, %d bekannt offen"
          % (len(FAELLE), len(OFFEN) + 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
