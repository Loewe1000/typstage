#!/usr/bin/env python3
"""Steht auf Papier, was das Handbuch verspricht?

    python3 .github/scripts/pruefe-papierregel.py

Zwei Regeln, und sie gelten nicht für dieselben Elemente (`papier-zeigt` in
src/internal.typ):

- Was *ersetzt* wird -- die Fassungen einer `alternatives` außer der letzten,
  die Stufen eines `build`, die Halte einer `scene` --, steht nur in seiner
  Spanne. Eine Seite je Folie und der Handzettel zeigen die letzte Fassung.
- Alles andere steht auf einer Seite je Folie und im Handzettel immer: `after`
  tut auf Papier nichts. Nur `pages: "step"` blättert wie der Vortrag, und was
  gedimmt ruht, ist dort nicht gegangen.

Gezählt wird nicht, sondern gelesen: der Text jeder Seite über `pdftotext`.
Eine Seitenzahl allein sah den Fehler nicht, den diese Probe festhält -- mit
der Schrittfassung kam die geschlossene Spanne für alle Elemente, und die Seite
je Folie druckte von `stagger(dim: true)[Eins][Zwei][Drei]` nur noch „Drei",
ohne Meldung und mit der richtigen Seitenzahl. Der Handzettel druckte die
Fassungen einer `alternatives` übereinander.

Seit 0.1.2 beginnt eine Kette mit `at: auto` bei Schritt ZWEI, auch am Kopf
einer Folie ("Automatic reveal chains start at step 2", dort als Bruch
angekündigt). Auf Papier heißt das: Vor dem ersten Stück einer solchen Kette
steht eine Schrittseite, auf der von ihr noch nichts steht -- die Folie, wie
sie der Saal beim Betreten sieht. Die Erwartungen unten tragen diese leere
Seite; wer sie nicht will, schreibt `at: 1` bzw. `start: 1`.

Dazu die Schichten: eine `scene-layer` und eine `cue-layer` stehen auf der
Schrittseite ihres Halts bzw. Punktes und nicht früher. Beides stand vorher
falsch, weil das Dokument unter `pages: "step"` nicht konvergierte und Typst
einen Zwischenstand druckte.
"""
import os, re, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

KOPF = ('#import "@preview/typstage:0.1.3": *\n'
        '#show: presentation.with(title: [P], {zusatz})\n')
ZUSATZ = {"slide": "", "step": 'pages: "step",', "handout": "handout: 1,"}

# name -> (Rumpf, {Fassung: [Wörter je Seite]}). Die Titelfolie ist Seite 1 und
# wird nicht mitgelesen. Eine Seite steht als Menge ihrer Großbuchstabenwörter:
# gefordert ist genau diese Menge, kein Wort mehr und keins weniger.
FAELLE = {
    "stagger dim": (
        "== A\n#stagger(dim: true)[EINS][ZWEI][DREI]\n",
        {"slide": ["EINS ZWEI DREI"], "handout": ["EINS ZWEI DREI"],
         "step": ["", "EINS", "EINS ZWEI", "EINS ZWEI DREI"]}),
    "anim after dimmed": (
        '== A\n#anim(at: "1", after: "dimmed")[EINS]\n#anim[ZWEI]\n',
        {"slide": ["EINS ZWEI"], "handout": ["EINS ZWEI"],
         "step": ["EINS", "EINS ZWEI"]}),
    "anim mit geschlossener Spanne": (
        '== A\n#anim(at: "1")[KURZ]\n#anim[LANG]\n',
        {"slide": ["KURZ LANG"], "handout": ["KURZ LANG"],
         "step": ["KURZ", "LANG"]}),
    # Eine Spanne mit Lücke: auf Schritt eins und drei, nicht auf zwei. Die
    # Schrittfassung kannte nur Anfang und Ende und druckte sie auch auf die
    # Seite von Schritt zwei -- im Browser steht dort nichts.
    "Spanne mit Lücke": (
        '== A\n#anim(at: "1,3")[EINSDREI]\n#anim(at: 4)[VIER]\n',
        {"slide": ["EINSDREI VIER"], "handout": ["EINSDREI VIER"],
         "step": ["EINSDREI", "", "EINSDREI", "VIER"]}),
    # Ein Video, eine Einbettung, ein Daumenkino und ein Morph mit einem `at`
    # hinter Schritt eins erscheinen und zählen wie ein `anim`. Vorher zog nur
    # `anim` den Zeiger nach: die Folie hatte auf Papier einen Schritt, die
    # Seite je Folie zeigte weder Video noch Morph, und die Schrittfassung war
    # eine Seite mit dem Platzhalter der Einbettung und dem Daumenkino -- beide
    # gingen auf Papier nicht durch `track` und standen auf jeder Seite.
    "Medien mit spätem at": (
        '== A\n#video("x.mp4", poster: [VIDEO], height: 20pt, at: 2)\n'
        '#embed(html: "<p>e</p>", height: 20pt, fallback: [EMBED], at: "3")\n'
        '#flipbook(t => [FLIP], frames: 2, width: 40pt, height: 20pt, '
        'at: "2,4-")\n'
        '#morph(<m>, at: 4)[MORPH]\n',
        {"slide": ["VIDEO EMBED FLIP MORPH"],
         "handout": ["VIDEO EMBED FLIP MORPH"],
         "step": ["", "VIDEO FLIP", "VIDEO EMBED", "VIDEO FLIP MORPH"]}),
    # Eine Anmerkung steht auf der Schrittseite, auf der ihre Marke steht, und
    # nicht früher. Vorher standen auf der Seite von Schritt eins beide. Die
    # hochgestellte Marke liest `pdftotext` als Teil des Wortes davor.
    #
    # Und wo das Papier eine Fassung nicht zeigt, zeigt es auch ihre Anmerkung
    # nicht: die Seite je Folie und der Handzettel druckten unter „ZWEI" beide.
    # Die verborgene Zeile trägt keine Tinte, `pdftotext` liest sie nicht.
    "Fußnoten in Fassungen": (
        "== A\n#alternatives([EINS#footnote[NOTEINS]], [ZWEI#footnote[NOTZWEI]])\n",
        {"slide": ["ZWEI2 NOTZWEI"], "handout": ["ZWEI2 NOTZWEI"],
         "step": ["", "EINS1 NOTEINS", "ZWEI2 NOTZWEI"]}),
    # Dasselbe für die Stufen eines `build` und die Halte einer `scene`.
    "Fußnoten in Stufen und Halten": (
        "== A\n#build(from => if from(2) [BZWEI#footnote[NBZWEI]] "
        "else [BEINS#footnote[NBEINS]], steps: 2)\n"
        '== B\n#scene("s", x => box(width: 80pt, height: 20pt)'
        "[SH#x#footnote[NSH#x]], stops: (1, 2))\n",
        {"slide": ["BZWEI2 NBZWEI", "SH22 NSH2"],
         "handout": ["BZWEI2 NBZWEI", "SH22 NSH2"],
         "step": ["", "BEINS1 NBEINS", "BZWEI2 NBZWEI", "", "SH11 NSH1",
                  "SH22 NSH2"]}),
    # Eine Kette in einer Fassung: ihre Anmerkung geht mit der Fassung.
    "Fußnote in einer Kette in einer Fassung": (
        '== A\n#alternatives([EINS #anim(at: "1-")[INNEN#footnote[NOTINNEN]]], '
        "[ZWEI#footnote[NOTZWEI]])\n",
        {"slide": ["ZWEI2 NOTZWEI"], "handout": ["ZWEI2 NOTZWEI"],
         "step": ["", "EINS INNEN1 NOTINNEN", "ZWEI2 NOTZWEI"]}),
    "alternatives": (
        "== A\n#alternatives([ALPHA], [BETA], [GAMMA])\n",
        {"slide": ["GAMMA"], "handout": ["GAMMA"],
         "step": ["", "ALPHA", "BETA", "GAMMA"]}),
    # `build` reicht dem Rumpf eine Frage und keine Zahl: `from(i)` ist wahr,
    # sobald Stufe i erreicht ist. Jede Stufe schreibt hier nur ihren eigenen
    # Namen -- zeichnete sie das Ganze bis dorthin, sähen übereinandergelegte
    # Stufen im Text genauso aus wie die letzte allein.
    "build": (
        "== A\n#build(from => [#for i in range(3) { "
        "if from(i + 1) and (i == 2 or not from(i + 2)) [ST#(i + 1)] }], "
        "steps: 3)\n",
        {"slide": ["ST3"], "handout": ["ST3"],
         "step": ["", "ST1", "ST2", "ST3"]}),
    "Szene mit Schichten hinter einer Schrittfolie": (
        '== A\n#anim(at: 2)[VORNE]\n'
        '== B\n#scene("s", x => box(width: 100pt, height: 40pt), '
        'stops: (1, 2, 3))\n'
        '#scene-layer("s", 1)[LA]\n#scene-layer("s", 2)[LB]\n'
        '#scene-layer("s", 3)[LC]\n',
        {"slide": ["VORNE", "LA LB LC"], "handout": ["VORNE", "LA LB LC"],
         "step": ["", "VORNE", "", "LA", "LA LB", "LA LB LC"]}),
    "cue mit fünf Punkten und Schichten": (
        '== A\n#cue("g")[\n- PA\n- PB\n- PC\n- PD\n- PE\n]\n'
        '#cue-layer("g", 1)[QA]\n#cue-layer("g", 5)[QE]\n',
        {"slide": ["PA PB PC PD PE QA QE"], "handout": ["PA PB PC PD PE QA QE"],
         "step": ["", "PA QA", "PA PB QA", "PA PB PC QA", "PA PB PC PD QA",
                  "PA PB PC PD PE QA QE"]}),
}

WORT = re.compile(r"\b[A-Z][A-Z0-9]+\b")


def seiten(quelle, ordner, paketpfad):
    datei = os.path.join(ordner, "deck.typ")
    pdf = os.path.join(ordner, "deck.pdf")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(quelle)
    lauf = subprocess.run(
        ["typst", "compile", "--package-path", paketpfad, "--root", ordner,
         datei, pdf], capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        return None, fehler[0], 0
    warnungen = len(re.findall(r"did not converge|did not stabilize", lauf.stderr))
    text = subprocess.run(["pdftotext", "-layout", pdf, "-"],
                          capture_output=True, text=True).stdout
    # Die letzte Seite endet mit einem Seitenvorschub, danach steht nichts.
    teile = text.split("\f")[:-1]
    return [set(WORT.findall(t)) - {"P"} for t in teile], None, warnungen


def main():
    if shutil.which("pdftotext") is None:
        print("Papierregel: pdftotext fehlt (poppler-utils)")
        return 1
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.1.3"))
        klagen = []
        for name, (rumpf, soll) in FAELLE.items():
            for modus, erwartet in soll.items():
                wo = "%s (%s)" % (name, modus)
                ist, fehler, warnungen = seiten(
                    KOPF.format(zusatz=ZUSATZ[modus]) + rumpf, tmp, paket)
                if fehler is not None:
                    klagen.append("%s: übersetzt nicht -- %s" % (wo, fehler))
                    continue
                if warnungen:
                    klagen.append("%s: %d Konvergenzmeldung(en); gedruckt ist "
                                  "dann ein Zwischenstand" % (wo, warnungen))
                # Im Handzettel stehen mehrere Folien auf einer Seite. Mit
                # `handout: 1` ist es eine je Seite, und die Titelfolie bleibt
                # die erste -- dieselbe Zählung wie sonst.
                ist = ist[1:]
                erwartet = [set(s.split()) for s in erwartet]
                if ist != erwartet:
                    klagen.append("%s: Seiten %s, erwartet %s" % (
                        wo, [" ".join(sorted(s)) for s in ist],
                        [" ".join(sorted(s)) for s in erwartet]))
        if klagen:
            print("Papierregel: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Papierregel: %d Aufbauten in drei Fassungen" % len(FAELLE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
