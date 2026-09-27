#!/usr/bin/env python3
"""Zeigt `contents()` die Ebenen und die Stelle, an der der Vortrag steht?

    python3 .github/scripts/pruefe-verzeichnis.py

Zwei Zusagen, beide über `deck-outline()` und `info().levels`:

  `indent`     ein tieferer Eintrag rückt ein
  `when`       jeder Eintrag weiß, ob er vorbei ist, läuft oder noch kommt

Und eine dritte über `section-back`, den Rückverweis am Fuß der
Abschnittsfolie: `none` nimmt ihn, ein eigenes Wort lässt sein Ziel, wo es war.

Die zweite ist die wichtigere: `highlight` baut darauf auf, und wer die
Hervorhebung anders will, bekommt `when` in seiner eigenen Renderfunktion.
Geprüft wird deshalb der Wert selbst und nicht seine Farbe -- eine Farbe im
PDF nachzumessen sagt wenig, ein falsches `when` alles.

Die Einrückung wird gröber geprüft: dasselbe Deck einmal flach und einmal weit
eingerückt muss verschiedene Seiten ergeben. Das faengt den Fall, dass `indent`
gar nichts tut.
"""
import json, os, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

KOPF = '''#import "@preview/typstage:0.2.0": *
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


def setzen(rumpf, ordner, paketpfad, endung="pdf", kopf=None):
    datei = os.path.join(ordner, "deck.typ")
    aus = os.path.join(ordner, "aus." + endung)
    with open(datei, "w", encoding="utf-8") as f:
        f.write((kopf or KOPF) + rumpf + SCHWANZ)
    lauf = subprocess.run(
        ["typst", "compile", "--package-path", paketpfad, "--root", ordner,
         datei, aus], capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        return None, fehler[0]
    with open(aus, "rb") as f:
        return f.read(), None


def verweise(pdf):
    """Jeder Verweis im PDF als (Seite, Ziel, Breite des Rechtecks).

    `qpdf --json` legt die Seiten als Liste vor; die Verweise hängen als
    `/Annots` an ihnen. Gelesen wird das PDF und nicht der Quelltext: ob ein
    `link()` am Ende eine Annotation wird und wohin sie zeigt, sagt nur die
    Datei. Dieselbe Technik wie in `pruefe-lesezeichen.py`.
    """
    r = subprocess.run(["qpdf", "--json=latest", pdf], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    j = json.loads(r.stdout)
    seite = {p["object"]: i + 1 for i, p in enumerate(j["pages"])}
    roh = j["qpdf"][1]

    def deref(v):
        while isinstance(v, str) and v.endswith(" R"):
            v = roh.get("obj:" + v, {}).get("value")
        return v

    def ziel(z):
        z = deref(z)
        if isinstance(z, dict):
            z = deref(z.get("/D"))
        if isinstance(z, list) and z:
            return "S%d" % seite.get(z[0], 0)
        # Im Bündel steht dort ein benannter Zielpunkt statt einer Seite.
        return str(z).lstrip("u:")

    raus = []
    for ref, nr in seite.items():
        for a in (deref(ref) or {}).get("/Annots", []):
            an = deref(a) or {}
            if an.get("/Subtype") != "/Link":
                continue
            r = [float(x) for x in an.get("/Rect", [0, 0, 0, 0])]
            # Die Breite und nicht die Kante: ein Wort ist auf der Folie ein
            # Umriss, messbar ist nur, wie breit es trägt.
            breit = round(abs(r[2] - r[0]), 1)
            akt = deref(an.get("/A")) or {}
            if akt.get("/S") == "/URI":
                raus.append((nr, "URI " + str(akt.get("/URI")).lstrip("u:"), breit))
            else:
                raus.append((nr, ziel(an.get("/Dest", akt.get("/D"))), breit))
    return sorted(raus)


def main():
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.2.0"))
        klagen = []

        # 1. `when` je Eintrag. Das Deck prüft sich selbst: eine Renderfunktion,
        #    die abbricht, sobald ein Wert nicht stimmt. So braucht die Probe
        #    keinen Text aus dem PDF zu lesen -- die Folien stehen dort als
        #    Umrisse, und eine Farbe nachzumessen sagte ohnehin wenig.
        def probe(soll):
            return (
                '#let soll = ' + soll + '\n'
                '#contents(number: none, title: (e, z) => {\n'
                '  let k = str(e.depth) + "-" + str(e.number)\n'
                '  assert(soll.at(k, default: none) == e.when,\n'
                '    message: "when fuer " + k + ": " + e.when + " statt "\n'
                '      + repr(soll.at(k, default: none)))\n'
                '  e.title\n'
                '})')
        SOLL = ('(: "1-1": "past", "2-1": "past", '
                '"1-2": "running", "2-2": "running", '
                '"1-3": "coming", "2-3": "coming")')
        _, fehler = setzen(probe(SOLL), tmp, paket)
        if fehler is not None:
            klagen.append(
                "der Stand stimmt nicht: " + fehler + ". `when` kommt aus dem "
                "Vergleich der Eintragsnummer mit `info().levels`; stimmt er "
                "nicht, zeigt eine Gliederung die falsche Stelle.")

        # 1b. Ein neuer Teil, der noch kein Kapitel geöffnet hat. Die Nummer
        #     der Kapitelebene bleibt dort auf "Kapitel B" stehen, weil sie nie
        #     zurückgeht; nur `index` ist 0. Ein Vergleich über die Nummer
        #     allein nannte "Kapitel B" laufend, obwohl sein Teil vorbei ist.
        SOLL_TEIL = ('(: "1-1": "past", "1-2": "past", "1-3": "running", '
                     '"1-4": "coming", "2-1": "past", "2-2": "past", '
                     '"2-3": "coming")')
        _, fehler = setzen(
            'Text.\n= Teil ohne Kapitel\n=== Mitte\n' + probe(SOLL_TEIL),
            tmp, paket)
        if fehler is not None:
            klagen.append(
                "der Stand unter einem Teil ohne Kapitel stimmt nicht: " + fehler
                + ". Das Kapitel des vorigen Teils ist dort vorbei, auch wenn "
                "die Kapitelebene seine Nummer behält.")

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

        # 4. `section-back`: der Rückverweis am Fuß der Abschnittsfolie.
        #    Dieselbe Technik wie 2. -- dasselbe Deck mehrmals, und die
        #    Unterschiede müssen die zugesagten sein. Das Deck hat sechs
        #    Abschnittsfolien (bei `slide-level: 3` sind `=` und `==` beide
        #    eine) und ein Verzeichnis auf Seite 7. Gemessen: 12 Verweise mit
        #    `auto`, 6 mit `none`, und alle sechs Rückverweise zeigen auf
        #    Seite 7.
        #
        #    Gezählt wird im PDF und nicht im Quelltext: `section-back` gibt
        #    nur den Körper, das `link` macht das Thema, und ob am Ende eine
        #    Annotation dasteht, sagt allein die Datei.
        if shutil.which("qpdf") is None:
            klagen.append("qpdf fehlt -- der Rückverweis bleibt ungeprüft.")
        else:
            aus = os.path.join(tmp, "aus.pdf")
            KOPF_RV = KOPF.replace("slide-level: 3)", "slide-level: 3, %s)")

            def rueck(wert):
                _, f = setzen("#contents()", tmp, paket,
                              kopf=KOPF_RV % ("section-back: " + wert)
                              if wert else KOPF)
                return (None, f) if f else (verweise(aus), None)

            mit, f4 = rueck(None)
            ohne, f5 = rueck("none")
            wort, f6 = rueck("[Zur Agenda]")
            ziele = lambda vs: [(v[0], v[1]) for v in vs]
            if f4 or f5 or f6:
                klagen.append("das Rückverweisdeck übersetzt nicht -- "
                              + (f4 or f5 or f6))
            else:
                zurueck = [v for v in mit if v[1] == "S7" and v[0] != 7]
                if len(zurueck) != 6:
                    klagen.append(
                        "von den sechs Abschnittsfolien tragen %d einen "
                        "Rückverweis auf das Verzeichnis (Seite 7), nicht 6."
                        % len(zurueck))
                if len(mit) - len(ohne) != 6:
                    klagen.append(
                        "`section-back: none` nimmt %d statt 6 Verweise "
                        "(%d gegen %d). Es soll genau die Rückverweise "
                        "nehmen und die Einträge des Verzeichnisses lassen."
                        % (len(mit) - len(ohne), len(mit), len(ohne)))
                if any(v[1] == "S7" and v[0] != 7 for v in ohne):
                    klagen.append(
                        "`section-back: none` lässt einen Rückverweis stehen.")
                if ziele(wort) != ziele(mit):
                    klagen.append(
                        "ein eigenes Wort verschiebt die Verweise: %r gegen "
                        "%r. `section-back` setzt den Körper, nicht das Ziel."
                        % (ziele(wort), ziele(mit)))
                elif [v[2] for v in wort] == [v[2] for v in mit]:
                    klagen.append(
                        "`section-back: [Zur Agenda]` ergibt genau so breite "
                        "Verweisrechtecke wie `auto` -- das eigene Wort steht "
                        "nicht auf der Folie.")

        if klagen:
            print("Verzeichnis: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Verzeichnis: Ebenen und Stand stimmen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
