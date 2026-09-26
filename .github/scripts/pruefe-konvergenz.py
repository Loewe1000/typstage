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

RUMPF = """#import "@preview/typstage:0.1.3": *
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
    # Jedes `stride` außer 1 las den Zeiger; gemessen acht Meldungen, bei
    # `stride: 2` wie bei `stride: 0`.
    "tiles mit stride":       'tiles(stride: 2, %s, %s)' % (STUECK, STUECK),
    "build":                  'build(k => %s, steps: 2)' % STUECK,
    "scene":                  'scene("s" + str(w), t => %s, stops: (0, 1), tween: 4)' % STUECK,
    # Im Browser reicht `alternatives(morph: …)` jeder Fassung ihr `at` aus dem
    # gelesenen Zeiger herein. Seit `track` einen Morph hinter Schritt eins
    # nachzieht, darf daran kein Update hängen: die Kette rückt den Zeiger
    # selbst vor, ohne Gelesenes. Die drei Aufrufe liegen damit auf 3/4, 5/6
    # und 7/8 statt alle drei auf 3/4.
    "alternatives mit morph": 'alternatives(morph: true, %s, %s)' % (STUECK, STUECK),
    # Dasselbe in einer Kachel, und erst dort riss es: mit dem Nachziehen am
    # gelesenen `at` gemessen dreizehn Meldungen, ohne keine.
    "alternatives mit morph in einer Kachel":
        'tiles([K], alternatives(morph: true, [R], [T]))',
}

# Eine `cue`-Gruppe in einem Wirt, und dahinter eine weitere Folie. Der Wirt
# setzt seinen Rumpf in der Überlagerung ein zweites Mal, hinter der Folie, wo
# die Gruppe schon alle Punkte hat. Gemessen, bevor `ad-nr` in `track` gelesen
# wurde: bei beiden Wirten zwei Meldungen "a measured element did not
# stabilize" und "document did not converge", gezeigt auf den Listenpunkt.
# Nur mit einer Liste, und nur mit der Folie danach. Und fünf Punkte in einem
# `anim` brachen ab: die Kopie legte ihre Punkte als 6 bis 10 noch einmal ab,
# und die Prüfung am Deckende meldete "would get a point 10". Ebenso ein
# einziger Punkt mit `nr: 1` in einem `anim`, auch ohne Folie danach: die
# Kopie legte die 1 ein zweites Mal ab, "gives a digit to two points".
WIRT = """#import "@preview/typstage:0.1.3": *
#show: presentation.with(title: [Konvergenz])

== Folie
#{aufruf}

== Danach
Text
"""

WIRTE = {
    "cue in anim, Folie danach":         'anim(cue("g")[\n- a\n- b\n])',
    "cue in einer Fassung, Folie danach": 'alternatives([a], cue("g")[\n- a\n- b\n])',
    "fünf cue-Punkte in anim":           'anim(cue("g", [a], [b], [c], [d], [e]))',
    "cue mit nr: in anim":               'anim(cue("g", nr: 1)[\n- a\n])',
}

# Ein Morph ohne eigenen Namen in einem Wirt, und dieselbe Folie noch einmal
# dahinter. Der Wirt setzt seinen Rumpf für den Sprite ein zweites Mal, und
# solange die Nummer hinter dem Namen ein `state` war, zählte die Kopie mit:
# diese Probe zählte elf Meldungen bei der Kachel und neun beim `anim`, und
# die zweite Folie legte R und T im Browser beide auf Schritt 6. Mit einem
# eigenen Namen war es still, und mit einer bloßen Textfolie dahinter auch.
FOLGE = """#import "@preview/typstage:0.1.3": *
#show: presentation.with(title: [Konvergenz])

== Folie
#{aufruf}

== Noch einmal
#{aufruf}
"""

FOLGEN = {
    "stagger mit morph in einer Kachel, zwei Folien":
        'tiles([K], stagger(morph: true)[R][T])',
    "alternatives mit morph in anim, zwei Folien":
        'anim(alternatives(morph: true, [R], [T]))',
}

# Nichts mehr offen. Bleibt als Fach stehen, damit ein neuer Fund hier landen
# kann, statt den Lauf rot zu färben, bevor jemand ihn ansehen konnte.
OFFEN = {}

# `camera` zielt auf ein `pin` und braucht deshalb einen eigenen Rumpf.
KAMERA = """#import "@preview/typstage:0.1.3": *
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
            os.symlink(WURZEL, os.path.join(ziel, "0.1.3"))
        klagen = []
        pflicht = [(name, RUMPF.format(aufruf=a)) for name, a in FAELLE.items()]
        pflicht += [(name, WIRT.format(aufruf=a)) for name, a in WIRTE.items()]
        pflicht += [(name, FOLGE.format(aufruf=a)) for name, a in FOLGEN.items()]
        pflicht.append(("camera", KAMERA))
        for name, quelle in pflicht:
            n, fehler = messen(quelle, tmp, paket)
            if fehler is not None:
                klagen.append("%s: übersetzt nicht -- %s" % (name, fehler))
            elif n and name in WIRTE:
                klagen.append(
                    "%s: %d Konvergenzmeldung(en). Ein Wert, den `cue` liest, "
                    "reist als fertige Zahl in den `context` von track; der "
                    "Sprite des Wirts liest ihn anders, und die Messung des "
                    "Wirts findet ihr Element nicht wieder." % (name, n))
            elif n and name in FOLGEN:
                klagen.append(
                    "%s: %d Konvergenzmeldung(en). Die Nummer hinter einem "
                    "Morph ohne Namen zählt die Kopie des Wirts im Sprite mit; "
                    "als `counter` setzt `sprite-klammer` sie zurück." % (name, n))
            elif n:
                klagen.append(
                    "%s: %d Konvergenzmeldung(en). Der Schritt wird aus dem "
                    "gelesenen Schrittzeiger berechnet und an track "
                    "hereingereicht; mit `at: auto` vergibt track ihn selbst, "
                    "und die Messung bleibt stabil." % (name, n))

        for name, quelle in [
                (name, RUMPF.format(aufruf=a)) for name, a in OFFEN.items()]:
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
    if OFFEN:
        print("Konvergenz: %d Aufbauten stabil, %d bekannt offen"
              % (len(FAELLE) + len(WIRTE) + len(FOLGEN) + 1, len(OFFEN)))
    else:
        print("Konvergenz: %d Aufbauten, alle stabil"
              % (len(FAELLE) + len(WIRTE) + len(FOLGEN) + 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
