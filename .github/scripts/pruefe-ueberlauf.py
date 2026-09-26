#!/usr/bin/env python3
"""
pruefe-ueberlauf.py — ragt in einem Beispieldeck etwas aus seiner Folie?

Warum eigens: das Paket bringt einen Überlaufmelder mit, aber er steht per
Vorgabe auf `overflow: "none"`, weil er den Bau um das 1,2- bis 1,5-fache
verteuert. Angeschaltet hat ihn genau ein Deck, `pruefdeck.typ`. Über die
siebzehn Beispieldecks lief er nie -- und der Decklauf prüft nur, *dass* der
Melder noch meldet (`ueberlauf.typ` muss abbrechen), nicht die Decks selbst.

Was dabei durchrutschte, war nicht theoretisch: eine Folie des Rundgangs ragte
33 Bildpunkte unter die Bühne, und der Lauf meldete "ok". Beim ersten Anlauf
dieser Probe kamen sofort drei weitere zum Vorschein, die niemand gesehen
hatte.

Gemessen wird nicht im Browser, sondern beim Übersetzen: der Melder hält die
Höhe des Rumpfes gegen den Raum, den das Thema ihm gibt. Das trifft auch, was
der Browser wegschneidet und man deshalb nie zu sehen bekommt.

    python3 .github/scripts/pruefe-ueberlauf.py [--deck NAME] [--paketpfad PFAD]

Rückgabewert 0, wenn kein Deck übersteht, sonst 1.
"""
import os, re, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def arg(name, vorgabe=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else vorgabe

def paketpfad_bauen():
    """Ein Wegwerf-Paketpfad, der auf *diesen* Stand zeigt.

    Wie im Seitenbau: unter `schule` und unter `preview`, denn die Decks
    schreiben `@preview/typstage` und sollen trotzdem den Arbeitsstand messen
    und nicht ein installiertes Paket.
    """
    pfad = tempfile.mkdtemp(prefix="typstage-ueberlauf-")
    version = "0.1.3"
    with open(os.path.join(WURZEL, "typst.toml"), encoding="utf-8") as f:
        m = re.search(r'^version\s*=\s*"([^"]+)"', f.read(), re.M)
        if m:
            version = m.group(1)
    for raum in ("schule", "preview"):
        ziel = os.path.join(pfad, raum, "typstage")
        os.makedirs(ziel)
        os.symlink(WURZEL, os.path.join(ziel, version))
    return pfad

def messen(deck, paketpfad, aus):
    """Ein Deck mit erzwungenem Melder übersetzen. Gibt die Fundzeilen zurück."""
    r = subprocess.run(
        ["typst", "compile", "--format", "html", "--features", "html",
         "--package-path", paketpfad, "--root", WURZEL,
         "--input", "typstage-overflow=error", deck, aus],
        capture_output=True, text=True, cwd=os.path.dirname(deck))
    if r.returncode == 0:
        return []
    text = r.stderr
    # Die Meldung des Melders nennt je Fund eine Zeile "slide N, from step …".
    funde = re.findall(r"^\s*(slide \d+.*)$", text, re.M)
    if funde:
        return funde
    # Abgebrochen, aber nicht am Überlauf: das ist ein eigener Fehler und
    # gehört ungekürzt gemeldet, sonst sucht man an der falschen Stelle.
    return ["übersetzt nicht: " + " ".join(text.split())[:300]]

# Was übersteht und übersteht soll. Seit 0.1.3 wächst die Leinwand einer Folie
# mit ihrem Inhalt: Was über den Ausschnitt hinausgeht, wird im Vortrag
# geschwenkt und kommt auf Papier eingepasst auf die Seite. Der Melder sagt
# davon nichts anderes als vorher -- er hält die Höhe des Rumpfes gegen den
# Raum der Folie --, und für eine Folie, die das mit Absicht tut, ist seine
# Meldung die richtige Auskunft und kein Fund.
#
# Je Deck die Folien, die es angeht, mit dem Grund. Nur diese eine Folie steht
# hier: Der Rundgang muss die Leinwand vorführen, und eine Folie, die sagt, die
# Ansicht fahre mit, muss mitfahren.
GEWOLLT = {
    "tour": {40: "„When the slide is not enough“ führt die wachsende "
                 "Leinwand vor und läuft dafür über den Ausschnitt hinaus"},
}

def gewollt(name, fund):
    """`True`, wenn dieser Fund für dieses Deck vorgesehen ist."""
    m = re.match(r"slide (\d+)", fund)
    return bool(m) and int(m.group(1)) in GEWOLLT.get(name, {})

def main():
    nur = arg("--deck")
    eigener = arg("--paketpfad") is None
    paketpfad = arg("--paketpfad") or paketpfad_bauen()
    ordner = os.path.join(WURZEL, "examples")
    decks = sorted(d for d in os.listdir(ordner) if d.endswith(".typ"))
    if nur:
        decks = [d for d in decks if d[:-4] == nur]
    aus = tempfile.mkdtemp(prefix="typstage-ueberlauf-aus-")
    schlimm = 0
    try:
        for d in decks:
            name = d[:-4]
            funde = messen(os.path.join(ordner, d), paketpfad,
                           os.path.join(aus, name + ".html"))
            vorgesehen = [f for f in funde if gewollt(name, f)]
            funde = [f for f in funde if not gewollt(name, f)]
            for f in vorgesehen:
                nr = int(re.match(r"slide (\d+)", f).group(1))
                print(f"  {name}: Folie {nr} steht mit Absicht über "
                      f"({GEWOLLT[name][nr]})")
            if funde:
                schlimm += 1
                print(f"  {name}: {len(funde)} Fund(e)")
                for f in funde:
                    print(f"      {f}")
            else:
                print(f"  {name}: passt")
    finally:
        shutil.rmtree(aus, ignore_errors=True)
        if eigener:
            shutil.rmtree(paketpfad, ignore_errors=True)
    print(f"\nÜberlauf: {len(decks)} Decks, {schlimm} mit Fund"
          if schlimm else f"\nÜberlauf: {len(decks)} Decks, keines steht über")
    return 1 if schlimm else 0

if __name__ == "__main__":
    sys.exit(main())
