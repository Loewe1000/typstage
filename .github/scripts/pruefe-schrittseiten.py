#!/usr/bin/env python3
"""Deckt `pages: "step"` das PDF Schritt für Schritt auf?

    python3 .github/scripts/pruefe-schrittseiten.py

`pages: "slide"` setzt eine Seite je Folie, jedes Element in seinem
Endzustand. `pages: "step"` setzt eine Seite je Schritt, so wie der Vortrag
sie zeigt. Geprüft wird beides an denselben Decks: die Seitenzahl je Fassung
und dass das Dokument dabei konvergiert.

Gezählt wird über die PNG-Ausgabe (`--format png` schreibt eine Datei je
Seite) statt über ein PDF-Werkzeug, das auf dem Prüfrechner fehlen darf.

Die Kamerafahrt hat eine eigene Zeile: sie zeigt auf Papier nichts, belegt in
der Schrittfassung deshalb keinen Schritt und bekommt keine zweite, identische
Seite. Ohne diese Regel standen sechs Seiten da, drei davon gleich.
"""
import os, re, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

KOPF = '#import "@preview/typstage:0.1.1": *\n#show: presentation.with(title: [P], pages: "{modus}")\n'

# name -> (Rumpf, Seiten bei "slide", Seiten bei "step")
FAELLE = {
    "anim": ("== A\n#anim[eins]\n#anim[zwei]\n", 2, 4),
    "stagger": ("== A\n#stagger([a], [b], [c])\n", 2, 4),
    "alternatives": ("== A\n#alternatives([p], [q], [r])\n", 2, 4),
    "build": ("== A\n#build(from => [#for i in range(3) { if from(i + 1) [S#{i + 1} ] }], steps: 3)\n", 2, 4),
    "scene": ('== A\n#scene("s", t => box(width: 100pt, height: 60pt, '
              'place(top + left, dx: t * 20pt, [o])), stops: (0, 1, 2), tween: 4)\n', 2, 4),
    "zwei Folien": ("== A\n#anim[eins]\n== B\n#stagger([a], [b])\n", 3, 5),
    # `contents()` setzt Marken auf die Abschnittsfolien. Kämen sie je Seite
    # noch einmal, wüchse ihre Zahl mit der Seitenzahl -- und die Seitenzahl
    # hängt an den Schritten. Gemessen, bevor die Marke auf die erste Seite
    # beschränkt wurde: "query for elements labelled `typstage-slide-target`
    # did not stabilize".
    "contents": ("= Ein Abschnitt\n== Aufdecken\n#anim[eins]\n"
                 "#stagger([a], [b])\n#alternatives([p], [q])\n"
                 "== Verzeichnis\n#contents()\n", 4, 9),
    # Die Fahrt belegt in der Schrittfassung keinen Schritt: vier statt sechs.
    "kamera": ("== A\n#anim[eins]\n#pin(<z>, [Ziel])\n#camera(<z>)\n#anim[zwei]\n", 2, 4),
}


def setzen(quelle, ordner, paketpfad):
    datei = os.path.join(ordner, "deck.typ")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(quelle)
    bilder = os.path.join(ordner, "bild")
    for alt in os.listdir(ordner):
        if alt.startswith("bild"):
            os.remove(os.path.join(ordner, alt))
    lauf = subprocess.run(
        ["typst", "compile", "--format", "png", "--ppi", "24",
         "--package-path", paketpfad, "--root", ordner,
         datei, bilder + "{p}.png"],
        capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        return None, fehler[0], 0
    seiten = len([x for x in os.listdir(ordner) if x.startswith("bild")])
    warnungen = len(re.findall(r"did not converge|did not stabilize", lauf.stderr))
    return seiten, None, warnungen


def main():
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.1.1"))
        klagen = []
        for name, (rumpf, soll_folie, soll_schritt) in FAELLE.items():
            for modus, soll in (("slide", soll_folie), ("step", soll_schritt)):
                seiten, fehler, warnungen = setzen(
                    KOPF.format(modus=modus) + rumpf, tmp, paket)
                wo = "%s (pages: %s)" % (name, modus)
                if fehler is not None:
                    klagen.append("%s: übersetzt nicht -- %s" % (wo, fehler))
                    continue
                if seiten != soll:
                    klagen.append("%s: %d Seiten, erwartet %d"
                                  % (wo, seiten, soll))
                if warnungen:
                    klagen.append(
                        "%s: %d Konvergenzmeldung(en). Die Seitenzahl darf "
                        "nicht an etwas hängen, das beim Setzen der Seiten "
                        "erst entsteht -- sonst läuft das Dokument in eine "
                        "Rückkopplung." % (wo, warnungen))
        if klagen:
            print("Schrittseiten: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Schrittseiten: %d Decks in beiden Fassungen" % len(FAELLE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
