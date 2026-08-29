#!/usr/bin/env python3
"""
pruefe-rundgang.py — der Rundgang führt jede Ausfuhr des Pakets wirklich vor

Warum eigens: `tour.typ` trägt im Untertitel „Every function once, and what it
is for", und sein Kopfkommentar sagt, jede Folie führe vor, wovon sie handelt.
Das war ein Versprechen ohne Aufsicht. Gemessen, als es zum ersten Mal geprüft
wurde: von 57 Ausfuhren wurden 34 benutzt. `camera`, die ganze `ggb-*`-Familie,
`cue`, `scene`, `build`, `fit`, die Paletten und alles, was das Deck über sich
selbst weiß, fehlten -- und niemand hätte es gemerkt, denn ein fehlender Aufruf
baut sich fehlerfrei.

Warum nicht einfach nach dem Namen suchen: weil ein Deck über seine eigenen
Funktionen *redet*. „the section of the plane" im Fließtext, `theme(…)` in
Anführungszeichen auf einer Folie, `#ggb-tween` in einer Aufzählung -- das sind
Erwähnungen, keine Vorführungen. Die erste Fassung dieser Probe suchte nur den
Namen und ließ vier von fünf Verstümmelungen durch. Deshalb steht hier zu jedem
Namen, was als Vorführung zählt.

  AUFRUF  der Regelfall: `name(` steht irgendwo im Code der Datei.
  MARKE   `#pause` und `#invert` tragen keine Klammern.
  WERT    Farben, Maße, Wörterbücher. Sie werden in einem Ausdruck gebraucht,
          nicht aufgerufen -- `swatch(dark, …)`, `themes.plain`, `#runtime-version`.
  ZITAT   was dieses Deck nicht aufrufen *kann*. Vier Namen, jeder mit Grund.

Vor der Suche fallen Kommentarzeilen, Zaunblöcke, Codespannen in Backticks und
der Inhalt von Zeichenketten weg. Was dort steht, wird zitiert, nicht benutzt.

Eine neue Ausfuhr, die in keiner Gruppe steht, lässt die Probe durchfallen: wer
etwas ausführt, entscheidet auch, woran man sieht, dass der Rundgang es zeigt.

    python3 .github/scripts/pruefe-rundgang.py [--deck pfad]

Rückgabewert 0, wenn jede Ausfuhr vorgeführt wird, sonst 1.
"""
import os, re, sys

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Marken tragen keine Klammern.
MARKE = ("pause", "invert")

# Werte, die in einem Ausdruck gebraucht statt aufgerufen werden.
WERT = ("slide-width", "slide-height", "slide-margin", "dark", "accent",
        "paper", "muted", "runtime-version", "runtime-files", "themes",
        "palettes")

# Was dieser Rundgang nicht aufrufen kann, und warum nicht.
ZITAT = {
    "bundle": "eine Datei, die bundle benutzt, übersetzt nur mit "
              "--format bundle; der Rundgang muss als HTML und als PDF "
              "herauskommen. Er zitiert es und sagt auf der Folie, warum",
    "slide": "Überschriftennotation: == ist dieser Aufruf. Das Deck ist so "
             "geschrieben und zeigt die Aufrufform im Listing daneben",
    "section": "Überschriftennotation: = ist dieser Aufruf",
    "title-slide": "die Titelfolie entsteht aus presentation(title: …); die "
                   "Aufrufform steht im Listing daneben",
}

def arg(name, vorgabe):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else vorgabe

def ausfuhren(lib):
    """Die Namen aus den `#import`-Zeilen von lib.typ, ohne Kommentare."""
    namen = []
    for block in re.finditer(r"#import\s+\"[^\"]+\":\s*\(([^)]*)\)", lib, re.S):
        for zeile in block.group(1).split("\n"):
            namen += [n for n in re.split(r"[,\s]+", zeile.split("//")[0]) if n]
    for zeile in lib.split("\n"):
        m = re.match(r"#import\s+\"[^\"]+\":\s*([^(\n]+)$", zeile)
        if m:
            namen += [n for n in re.split(r"[,\s]+", m.group(1).split("//")[0]) if n]
    return sorted(set(namen))

def nur_code(deck):
    """Alles weg, was Text ist: Zäune, Zeichenketten, Backticks, Kommentare.

    Ein Durchgang mit einem Zustand, kein Stapel von Ersetzungen. Die erste
    Fassung strich nacheinander -- erst Zeichenketten, dann Kommentare --, und
    daran zerbrach sie an einem einzigen Anführungszeichen in einem Kommentar:
    `// … bricht mit „… is not valid in code" ab.` Das eine Zeichen paarte sich
    mit dem nächsten weit unten, und alles dazwischen galt als Zeichenkette.
    Gemessen: 19 von 58 Ausfuhren galten plötzlich als nicht vorgeführt, obwohl
    sich an der Datei nichts geändert hatte, was sie betraf.
    """
    aus, i, n = [], 0, len(deck)
    while i < n:
        c = deck[i]
        if c == '"':                      # Zeichenkette
            i += 1
            while i < n and deck[i] != '"':
                i += 2 if deck[i] == "\\" else 1
            i += 1
            aus.append('""')
        elif deck.startswith("//", i):    # Zeilenkommentar
            while i < n and deck[i] != "\n":
                i += 1
            aus.append(" ")
        elif deck.startswith("/*", i):    # Blockkommentar
            i = deck.find("*/", i)
            i = n if i < 0 else i + 2
            aus.append(" ")
        elif c == "`":                    # Zaun oder Codespanne
            zaun = 1
            while deck.startswith("`" * (zaun + 1), i):
                zaun += 1
            marke = "`" * zaun
            j = deck.find(marke, i + zaun)
            i = n if j < 0 else j + zaun
            aus.append(" ")
        else:
            aus.append(c)
            i += 1
    return "".join(aus)

def vorgefuehrt(name, code):
    e = re.escape(name)
    if name in MARKE:
        return re.search(r"#" + e + r"(?![\w-])", code) is not None
    if name in WERT:
        # In einem Ausdruck gebraucht -- aber nicht als benannter Parameter,
        # denn `theme: themes.plain` sagt nichts über `theme`.
        return (re.search(r"#" + e + r"(?![\w-])", code)
                or re.search(r"(?<![\w-])" + e + r"\s*\.", code)
                or re.search(r"[(,]\s*" + e + r"(?![\w-]|\s*:)", code)) is not None
    # Der Regelfall: ein Aufruf. Klammer oder Inhaltsblock -- `#speaker-note[…]`
    # ist einer wie `#anim(…)`. `presentation.with(…)` zählt auch als einer.
    return (re.search(r"(?<![\w-])" + e + r"\s*[(\[]", code)
            or re.search(r"(?<![\w-])" + e + r"\.with\s*\(", code)) is not None

def main():
    lib = open(os.path.join(WURZEL, "src", "lib.typ")).read()
    deck_pfad = arg("--deck", os.path.join(WURZEL, "examples", "tour.typ"))
    code = nur_code(open(deck_pfad).read())

    namen = ausfuhren(lib)
    if not namen:
        print("Rundgang: keine Ausfuhr in src/lib.typ gefunden -- hat sich die "
              "Schreibweise der #import-Zeilen geändert?")
        return 1

    unbekannt = [n for n in ZITAT if n not in namen]
    fehlt = [n for n in namen if n not in ZITAT and not vorgefuehrt(n, code)]

    print("Rundgang: %d Ausfuhren, %d vorgeführt, %d zitiert, %d fehlen"
          % (len(namen), len(namen) - len(ZITAT) - len(fehlt), len(ZITAT), len(fehlt)))
    for n in sorted(ZITAT):
        if n in namen:
            print("  zitiert: %-12s %s" % (n, ZITAT[n]))
    if unbekannt:
        print("\n  Als Zitat geführt, aber gar nicht mehr ausgeführt: "
              + ", ".join(sorted(unbekannt)))
        print("  Aus ZITAT nehmen.")
    if fehlt:
        print("\n  Nicht vorgeführt in %s:" % os.path.relpath(deck_pfad, WURZEL))
        for n in fehlt:
            print("    " + n)
        print("\n  Der Rundgang verspricht im Untertitel jede Funktion einmal.")
        print("  Eine Folie dafür bauen -- oder, wenn er sie nicht aufrufen")
        print("  kann, mit Grund in ZITAT eintragen.")
    return 1 if (fehlt or unbekannt) else 0

if __name__ == "__main__":
    sys.exit(main())
