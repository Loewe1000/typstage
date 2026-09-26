#!/usr/bin/env python3
"""pruefe-lesezeichen.py — trägt das PDF ein Lesezeichenverzeichnis?

Ein Foliensatz ohne Lesezeichen ist im Reader ein Stapel ohne Griff: der
Seitenbalken bleibt leer, und wer zu „Abschnitt 3“ will, blättert. Ein
gewöhnliches Typst-Dokument bekommt das umsonst, weil seine Überschriften im
Dokument stehen. Hier stehen sie nicht mehr: sie schneiden das Deck in Folien
und werden dabei zu Wörterbüchern. Also legt das Paket je Folie eine
unsichtbare Überschrift, die nichts setzt und nur ein Lesezeichen trägt.

    python3 .github/scripts/pruefe-lesezeichen.py

Gelesen wird das PDF selbst, über `qpdf --json`. Kein Browser: Lesezeichen
sind eine Eigenschaft der Datei und keine der Anzeige.

Geprüft wird:
  1. Es gibt überhaupt ein Verzeichnis, und es hat einen Eintrag je Folie
     und je Abschnitt -- gemessen gegen die Seitenzahl.
  2. Jeder Eintrag zeigt auf SEINE Seite, in der Reihenfolge des Decks.
  3. Die Verschachtelung stimmt: Abschnitte oben, ihre Folien darunter.
  4. Beide Notationen -- Überschriften und slide()/section()-Aufrufe --
     ergeben dasselbe.
  5. Eine Überschrift, die ein Deck in einen Folienrumpf schreibt, erzeugt
     KEIN eigenes Lesezeichen. Sonst stünde derselbe Name mehrfach im
     Verzeichnis und zeigte unter `pages: "step"` auf Seiten, auf denen er
     gar nicht steht -- genau das war der Anlass der Meldung.
  6. `pages: "step"` gibt ein Lesezeichen je FOLIE und nicht je Schritt.
  7. Eine Folie ohne Titel bekommt keinen leeren Eintrag. Ebenso eine, deren
     Überschrift zwar zeichnet, aber kein Zeichen trägt: ein Bild, ein leeres
     `box`, ein `context`. Ein Titel mit Text -- auch `$a^2$`, aus dem Typst
     „a2" macht -- bekommt seinen Eintrag.
  8. Der Handzettel trägt seine Lesezeichen ebenfalls.
  9. Und dasselbe für das SPRUNGZIEL, auf das `contents()` verweist: eines je
     Folie, in BEIDEN Seitenfassungen. Es hing an derselben Frage wie das
     Lesezeichen -- „ist das die erste Seite der Folie?" --, nur unter einer
     zweiten, falschen Regel: ohne `pages: "step"` trägt die einzige Seite
     einer Folie deren LETZTE Schrittzahl, und jede Folie mit einem Aufdecker
     verlor damit ihr Ziel. Beide lesen jetzt dieselbe Funktion.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
VERSION = "0.1.3"


def paketwurzel(tmp):
    """Ein Wegwerf-Paketpfad, der auf den Arbeitsbaum zeigt -- nicht auf das
    veröffentlichte Paket aus dem Zwischenspeicher."""
    paket = os.path.join(tmp, "paket")
    for raum in ("schule", "preview"):
        ziel = os.path.join(paket, raum, "typstage")
        os.makedirs(ziel, exist_ok=True)
        os.symlink(WURZEL, os.path.join(ziel, VERSION))
    return paket


def bauen(quelle, name, tmp, paket):
    typ = os.path.join(tmp, name + ".typ")
    pdf = os.path.join(tmp, name + ".pdf")
    Path(typ).write_text(quelle, encoding="utf-8")
    r = subprocess.run(["typst", "compile", "--package-path", paket,
                        "--root", tmp, typ, pdf],
                       capture_output=True, text=True)
    if r.returncode:
        zeile = next((z for z in r.stderr.split("\n") if z.startswith("error:")),
                     r.stderr[:120])
        return None, zeile
    return pdf, None


def verzeichnis(pdf):
    """(Titel, Seitenzahl, Tiefe) je Lesezeichen, in Dokumentreihenfolge.

    `qpdf --json` legt den Baum fertig vor: `outlines` mit `title`,
    `destpageposfrom1` und `kids`. Ihn aus den Objekten selbst
    zusammenzusuchen war der erste Versuch und ging schief -- die Schluessel
    dort tragen ein `obj:` davor, das die Verweise in `/First` und `/Next`
    nicht haben.
    """
    r = subprocess.run(["qpdf", "--json=latest", pdf], capture_output=True, text=True)
    if r.returncode:
        return None
    d = json.loads(r.stdout)
    aus = []

    def gehe(knoten, tiefe):
        for k in knoten:
            aus.append((k.get("title", ""), k.get("destpageposfrom1"), tiefe))
            gehe(k.get("kids", ()), tiefe + 1)

    gehe(d.get("outlines", ()), 1)
    return aus


KOPF = ('#import "@preview/typstage:' + VERSION + '": *\n'
        '#show: presentation.with(theme: themes.default, title: [Titel]{mehr})\n\n')

DECKS = {
    "ueberschriften": KOPF.format(mehr="") + (
        "= Alpha\n== A1\nEins.\n== A2\nZwei.\n"
        "= Beta\n== B1\nDrei.\n"),
    "argumente": (
        '#import "@preview/typstage:' + VERSION + '": *\n'
        "#presentation(\n"
        "  theme: themes.default, title: [Titel],\n"
        "  section[Alpha],\n"
        "  slide([A1], [Eins.]),\n"
        "  slide([A2], [Zwei.]),\n"
        "  section[Beta],\n"
        "  slide([B1], [Drei.]),\n"
        ")\n"),
    "eigene_ueberschrift": KOPF.format(mehr="") + (
        "= Alpha\n== A1\nEin Satz.\n#box[= Fremde Ueberschrift]\nNoch einer.\n"),
    "schritte": KOPF.format(mehr=', pages: "step"') + (
        "= Alpha\n== A1\nEins.\n#pause\nZwei.\n#pause\nDrei.\n== A2\nVier.\n"),
    "ohne_titel": (
        '#import "@preview/typstage:' + VERSION + '": *\n'
        "#presentation(\n"
        "  theme: themes.default, title: [Titel],\n"
        "  slide([Ein Satz ohne Titel.]),\n"
        "  slide([Mit Titel], [Zwei.]),\n"
        ")\n"),
    # Vier Überschriften, die zeichnen: drei ohne ein Zeichen (Kasten, Bild,
    # `context`), eine mit (die Formel). Seit eine leere Überschrift auch die
    # Laufzeile nimmt, entscheidet über Band und Laufzeile, ob der Titel
    # *zeichnet* -- über das Lesezeichen aber muss weiter entscheiden, ob er
    # ein Zeichen trägt. Sonst stehen hier drei leere Zeilen im Verzeichnis.
    "zeichnender_titel": KOPF.format(mehr="") + (
        "= Alpha\n"
        "== #box(width: 20pt, height: 10pt)\nEins.\n"
        "== #image(\"punkt.svg\", width: 20pt)\nZwei.\n"
        "== #context [X]\nDrei.\n"
        "== $a^2$\nVier.\n"
        "== Mit Wort\nFünf.\n"),
    "handzettel": KOPF.format(mehr=", handout: true") + (
        "= Alpha\n== A1\nEins.\n== A2\nZwei.\n"),
    # Vier Folien, davon eine mit Aufdecker -- die verlor ihr Sprungziel.
    "ziele": KOPF.format(mehr="") + (
        "== Ohne Aufdecken\nEins.\n"
        "== Mit Aufdecken\nEins.\n#pause\nZwei.\n"
        "== Wieder ohne\nDrei.\n"),
    "ziele_schritte": KOPF.format(mehr=', pages: "step"') + (
        "== Ohne Aufdecken\nEins.\n"
        "== Mit Aufdecken\nEins.\n#pause\nZwei.\n"
        "== Wieder ohne\nDrei.\n"),
}


def main():
    if not shutil.which("qpdf"):
        print("Lesezeichen: qpdf fehlt -- ohne das lässt sich ein Verzeichnis"
              " nicht lesen")
        return 1
    tmp = tempfile.mkdtemp(prefix="typstage-lz-")
    paket = paketwurzel(tmp)
    Path(os.path.join(tmp, "punkt.svg")).write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
        '<circle cx="5" cy="5" r="4" fill="#c00"/></svg>', encoding="utf-8")
    klagen = []
    gebaut = {}
    for name, quelle in DECKS.items():
        pdf, fehler = bauen(quelle, name, tmp, paket)
        if pdf is None:
            klagen.append(f"{name}: übersetzt nicht -- {fehler}")
        else:
            gebaut[name] = pdf

    def eintraege(name):
        return verzeichnis(gebaut[name]) if name in gebaut else []

    # ── 1 bis 3: Überschriftennotation ──────────────────────────────────────
    v = eintraege("ueberschriften")
    if not v:
        klagen.append("1. die Überschriftennotation ergab gar kein Verzeichnis")
    else:
        namen = [t for t, _, _ in v]
        soll = ["Titel", "Alpha", "A1", "A2", "Beta", "B1"]
        if namen != soll:
            klagen.append(f"1. Verzeichnis {namen} statt {soll}")
        seiten = [s for _, s, _ in v]
        if seiten != sorted(seiten) or len(set(seiten)) != len(seiten):
            klagen.append(f"2. die Ziele laufen nicht aufsteigend und einzeln: {seiten}")
        tiefen = {t: d for t, _, d in v}
        if tiefen.get("Alpha") != tiefen.get("Beta"):
            klagen.append("3. die beiden Abschnitte liegen auf verschiedenen Ebenen")
        if tiefen.get("A1", 0) <= tiefen.get("Alpha", 9):
            klagen.append(f"3. die Folie A1 liegt nicht unter ihrem Abschnitt "
                          f"({tiefen.get('A1')} gegen {tiefen.get('Alpha')})")

    # ── 4: beide Notationen ─────────────────────────────────────────────────
    a = [t for t, _, _ in eintraege("ueberschriften")]
    b = [t for t, _, _ in eintraege("argumente")]
    if a and b and a != b:
        klagen.append(f"4. Überschriften ergaben {a}, Aufrufe {b}")

    # ── 5: eine Überschrift aus dem Rumpf ───────────────────────────────────
    v = eintraege("eigene_ueberschrift")
    if any("Fremde" in t for t, _, _ in v):
        klagen.append("5. eine Überschrift im Folienrumpf kam als eigenes "
                      "Lesezeichen mit: " + str([t for t, _, _ in v]))

    # ── 6: eine Marke je Folie, nicht je Schritt ────────────────────────────
    v = eintraege("schritte")
    namen = [t for t, _, _ in v]
    if namen.count("A1") != 1:
        klagen.append(f"6. die dreischrittige Folie A1 steht {namen.count('A1')}x "
                      f"im Verzeichnis: {namen}")

    # ── 7: eine Folie ohne Titel ────────────────────────────────────────────
    v = eintraege("ohne_titel")
    if any(t.strip() == "" for t, _, _ in v):
        klagen.append("7. eine Folie ohne Titel bekam einen leeren Eintrag")

    # ── 7b: eine Überschrift, die zeichnet, aber kein Zeichen trägt ─────────
    v = eintraege("zeichnender_titel")
    namen = [t for t, _, _ in v]
    leere = [t for t in namen if t.strip() == ""]
    if leere:
        klagen.append(f"7. {len(leere)} leere(r) Eintrag im Verzeichnis: {namen} "
                      f"-- ein Bild, ein leeres box oder ein context im Titel "
                      f"gehört in kein Lesezeichen")
    if v and len(namen) != 4:
        klagen.append(f"7. {namen} statt vier Einträgen (Titel, Alpha, die "
                      f"Formel, „Mit Wort“): entweder ist ein zeichnender "
                      f"Titel ohne Zeichen mitgekommen, oder der Formeltitel, "
                      f"aus dem Typst Text holt, ist verlorengegangen")

    # ── 8: der Handzettel ───────────────────────────────────────────────────
    if "handzettel" in gebaut and not eintraege("handzettel"):
        klagen.append("8. der Handzettel trägt kein Verzeichnis")

    # ── 9: ein Sprungziel je Folie, in beiden Fassungen ─────────────────────
    for name, wie in (("ziele", 'pages: "slide"'), ("ziele_schritte", 'pages: "step"')):
        typ = os.path.join(tmp, name + ".typ")
        r = subprocess.run(["typst", "query", "--package-path", paket, "--root", tmp,
                            "--field", "value", typ, "<typstage-slide-target>"],
                           capture_output=True, text=True)
        if r.returncode:
            klagen.append(f"9. {wie}: die Abfrage der Sprungziele scheiterte")
            continue
        n = len(json.loads(r.stdout))
        # Titelfolie und drei Folien.
        if n != 4:
            klagen.append(f"9. {wie}: {n} Sprungziele statt 4 -- eine Folie mit "
                          f"Aufdecker bekam keines, und contents() verweist dorthin")

    shutil.rmtree(tmp, ignore_errors=True)
    if klagen:
        print(f"Lesezeichen: {len(klagen)} Punkt(e)\n")
        for k in klagen:
            print("  • " + k)
        return 1
    print("Lesezeichen: Verzeichnis, Ziele und Ebenen stimmen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
