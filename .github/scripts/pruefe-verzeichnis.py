#!/usr/bin/env python3
"""Zeigt `contents()` die Ebenen und die Stelle, an der der Vortrag steht?

    python3 .github/scripts/pruefe-verzeichnis.py

Zwei Zusagen, beide über `deck-outline()` und `info().levels`:

  `indent`     ein tieferer Eintrag rückt ein
  `when`       jeder Eintrag weiß, ob er vorbei ist, läuft oder noch kommt

Die zweite ist die wichtigere: `highlight` baut darauf auf, und wer die
Hervorhebung anders will, bekommt `when` in seiner eigenen Renderfunktion.
Geprüft wird deshalb der Wert selbst und nicht seine Farbe -- eine Farbe im
PDF nachzumessen sagt wenig, ein falsches `when` alles.

Die Einrückung wird gröber geprüft: dasselbe Deck einmal flach und einmal weit
eingerückt muss verschiedene Seiten ergeben. Das faengt den Fall, dass `indent`
gar nichts tut.
"""
import os, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

KOPF = '''#import "@preview/typstage:0.1.1": *
#show: presentation.with(title: [V], slide-level: 3)
= Teil eins
== Kapitel A
=== Folie
Text.
= Teil zwei
== Kapitel B
=== Verzeichnis
'''
SCHWANZ = '''
= Teil drei
== Kapitel C
=== Folie
Text.
'''


def setzen(rumpf, ordner, paketpfad, endung="pdf"):
    datei = os.path.join(ordner, "deck.typ")
    aus = os.path.join(ordner, "aus." + endung)
    with open(datei, "w", encoding="utf-8") as f:
        f.write(KOPF + rumpf + SCHWANZ)
    lauf = subprocess.run(
        ["typst", "compile", "--package-path", paketpfad, "--root", ordner,
         datei, aus], capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        return None, fehler[0]
    with open(aus, "rb") as f:
        return f.read(), None


def main():
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.1.1"))
        klagen = []

        # 1. `when` je Eintrag. Das Deck prüft sich selbst: eine Renderfunktion,
        #    die abbricht, sobald ein Wert nicht stimmt. So braucht die Probe
        #    keinen Text aus dem PDF zu lesen -- die Folien stehen dort als
        #    Umrisse, und eine Farbe nachzumessen sagte ohnehin wenig.
        SOLL = ('(: "1-1": "past", "2-1": "past", '
                '"1-2": "running", "2-2": "running", '
                '"1-3": "coming", "2-3": "coming")')
        _, fehler = setzen(
            '#let soll = ' + SOLL + '\n'
            '#contents(number: none, title: (e, z) => {\n'
            '  let k = str(e.depth) + "-" + str(e.number)\n'
            '  assert(soll.at(k, default: none) == e.when,\n'
            '    message: "when fuer " + k + ": " + e.when + " statt "\n'
            '      + repr(soll.at(k, default: none)))\n'
            '  e.title\n'
            '})',
            tmp, paket)
        if fehler is not None:
            klagen.append(
                "der Stand stimmt nicht: " + fehler + ". `when` kommt aus dem "
                "Vergleich der Eintragsnummer mit `info().levels`; stimmt er "
                "nicht, zeigt eine Gliederung die falsche Stelle.")

        # 2. Die Einrückung tut überhaupt etwas.
        flach, f1 = setzen("#contents(indent: none)", tmp, paket)
        weit, f2 = setzen("#contents(indent: 60pt)", tmp, paket)
        if f1 is not None or f2 is not None:
            klagen.append("das Einrückungsdeck übersetzt nicht -- "
                          + (f1 or f2))
        elif flach == weit:
            klagen.append(
                "`indent: none` und `indent: 60pt` ergeben dieselbe Seite -- "
                "die Einrückung tut nichts.")

        # 3. Und die Vorgabe rückt ein, ist also nicht heimlich flach.
        vorgabe, f3 = setzen("#contents()", tmp, paket)
        if f3 is None and vorgabe == flach:
            klagen.append(
                "die Vorgabe setzt so flach wie `indent: none`. Ein "
                "Verzeichnis soll seine Ebenen zeigen.")

        if klagen:
            print("Verzeichnis: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Verzeichnis: Ebenen und Stand stimmen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
