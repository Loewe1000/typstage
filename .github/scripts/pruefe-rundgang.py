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
  ZITAT   was dieses Deck nicht aufrufen *kann*, jeder Name mit Grund: vier
          Namen und die elf der Desmos-Seite.

Seit 0.1.2 hängt ein Gutteil dessen, was neu ist, an keinem Namen in
`lib.typ`, sondern an einem Schlüssel: `room` und seine Einträge an
`presentation`, `section-back`, `ends-at` an `video`. Die Ausfuhrliste sieht
keinen davon, und die Probe blieb grün, solange der Rundgang keinen zeigte --
gemessen 71 Ausfuhren, 56 vorgeführt, 15 zitiert, 0 fehlen, vor den Folien
dazu wie danach. Deshalb eine zweite Tabelle:

  SCHLUESSEL  muss als `name:` im Code stehen, und zwar dort, wo er wirkt:
              `room` und `section-back` in der Klammer von `presentation(…)`
              oder `presentation.with(…)`, die Einträge von `room` in dessen
              Klammer dort, `step` in der von `clock`, `ends-at` in einem
              `video(`-Aufruf. `digits: 2` in `calc.round` ist kein Beweis
              für `room.clock.digits`, und die Überschrift
              `== section-back: …` keiner für `section-back`.
  SCHLUESSEL_ZITAT  was der Rundgang nicht setzen kann, mit Grund.

Tasten -- die Ziffern, `a`, `m`, `b` -- prüft keine Tabelle. Ob eine Notiz
„Press `3`" sagt, ist Text, und Text fällt vor der Suche weg; ob die Taste
wirkt, zeigen die Browserproben (`pruefe-uhr-ziffern.js`, `pruefe-klang.js`,
`pruefe-zeiger.js`).

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
DESMOS_GRUND = (
    "Desmos gibt sein Skript nur gegen einen API-Schlüssel heraus. Der Rundgang steht auf der Projektseite; eine Folie damit trüge den Schlüssel öffentlich mit sich und warnte bei jedem Aufruf in der Konsole. Geprüft wird die Desmos-Seite deshalb mit einem eigenen Deck, das niemand veröffentlicht")

ZITAT = {
    "bundle": "eine Datei, die bundle benutzt, übersetzt nur mit "
              "--format bundle; der Rundgang muss als HTML und als PDF "
              "herauskommen. Er zitiert es und sagt auf der Folie, warum",
    "slide": "Überschriftennotation: == ist dieser Aufruf. Das Deck ist so "
             "geschrieben und zeigt die Aufrufform im Listing daneben",
    "section": "Überschriftennotation: = ist dieser Aufruf",
    "title-slide": "die Titelfolie entsteht aus presentation(title: …); die "
                   "Aufrufform steht im Listing daneben",
    "desmos": DESMOS_GRUND,
    "demo-key": DESMOS_GRUND,
    "dsm-animate": DESMOS_GRUND,
    "dsm-expr": DESMOS_GRUND,
    "dsm-hide": DESMOS_GRUND,
    "dsm-remove": DESMOS_GRUND,
    "dsm-set": DESMOS_GRUND,
    "dsm-show": DESMOS_GRUND,
    "dsm-style": DESMOS_GRUND,
    "dsm-tween": DESMOS_GRUND,
    "dsm-view": DESMOS_GRUND,
}

# Schlüssel ohne eigene Ausfuhr. Je Eintrag: wo er stehen muss.
#   ("presentation", None)  in der Klammer von `presentation(` oder `.with(`
#   ("room", None)          in der Klammer von `room:` dort
#   ("room", "clock")       in der Klammer von `clock:` in diesem `room:`
#   ("video", None)         in der Klammer eines `video(`-Aufrufs
SCHLUESSEL = {
    "room": ("presentation", None),
    "section-back": ("presentation", None),
    "clock": ("room", None),
    "sounds": ("room", None),
    "bell": ("room", None),
    "pointer": ("room", None),
    "step": ("room", "clock"),
    "ends-at": ("video", None),
}

SCHLUESSEL_ZITAT = {
    "morph": "`morph: (glyph-limit: …)` zu setzen hieße, dem Rundgang eine "
             "Formel von über 120 Zeichen zu geben, nur damit die Zahl etwas "
             "tut -- die längste hier hat 48. Die Folie „pin: when the wrong "
             "signs fly\" zitiert den Aufruf und sagt, wofür er gut ist",
    "glyph-limit": "steht im selben Listing wie `morph` und aus demselben "
                   "Grund",
    "digits": "`digits: false` nähme dem Rundgang die Zifferntasten, die er "
              "auf seiner Uhrenfolie vorführt; das Listing dort zitiert es",
    "pages": "`pages: \"step\"` gäbe dem PDF des Rundgangs eine Seite je "
             "Schritt, und er muss eine je Folie liefern; die Folie „On "
             "paper\" zitiert es",
}

def klammer(code, i):
    """Der Inhalt der Klammer, die bei code[i] == "(" aufgeht."""
    tiefe, j = 0, i
    while j < len(code):
        if code[j] in "([{":
            tiefe += 1
        elif code[j] in ")]}":
            tiefe -= 1
            if tiefe == 0:
                return code[i + 1:j]
        j += 1
    return code[i + 1:]

def unter(code, name, aufruf=False):
    """Alle Klammerinhalte von `name: (…)`, oder mit aufruf von `name(…)`."""
    muster = (r"(?<![\w-])" + re.escape(name) + (r"\s*\(" if aufruf else r"\s*:\s*\("))
    return [klammer(code, m.end() - 1) for m in re.finditer(muster, code)]

def im_aufruf(code):
    """Die Klammerinhalte von `presentation(…)` und `presentation.with(…)`.

    Dort und nicht irgendwo im Code: `nur_code` nimmt Kommentare, Zäune,
    Codespannen und Zeichenketten weg, Überschriften aber nicht, und die
    Folie, die `section-back` vorführt, heißt `== section-back: …`. Gemessen,
    als die Probe noch im ganzen Code suchte: ohne die Zeile im Aufruf blieb
    sie mit „8 gesetzt, 0 fehlen" grün, und ebenso mit dem ganzen `room:`
    als Wert vor dem Aufruf statt in ihm.
    """
    return (unter(code, "presentation.with", aufruf=True)
            + unter(code, "presentation", aufruf=True))

def gesetzt(schluessel, code):
    ort, tiefer = SCHLUESSEL[schluessel]
    if ort == "presentation":
        felder = im_aufruf(code)
    elif ort == "video":
        felder = unter(code, "video", aufruf=True)
    else:
        felder = [r for f in im_aufruf(code) for r in unter(f, "room")]
        if tiefer:
            felder = [x for f in felder for x in unter(f, tiefer)]
    muster = r"(?<![\w-])" + re.escape(schluessel) + r"\s*:"
    return any(re.search(muster, f) for f in felder)

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
    s_fehlt = [k for k in SCHLUESSEL if not gesetzt(k, code)]
    print("          %d Schlüssel, %d gesetzt, %d zitiert, %d fehlen"
          % (len(SCHLUESSEL) + len(SCHLUESSEL_ZITAT), len(SCHLUESSEL) - len(s_fehlt),
             len(SCHLUESSEL_ZITAT), len(s_fehlt)))
    for n in sorted(ZITAT):
        if n in namen:
            print("  zitiert: %-12s %s" % (n, ZITAT[n]))
    if unbekannt:
        print("\n  Als Zitat geführt, aber gar nicht mehr ausgeführt: "
              + ", ".join(sorted(unbekannt)))
        print("  Aus ZITAT nehmen.")
    for k in sorted(SCHLUESSEL_ZITAT):
        print("  zitiert: %-12s %s" % (k + ":", SCHLUESSEL_ZITAT[k]))
    if s_fehlt:
        print("\n  Nicht gesetzt in %s:" % os.path.relpath(deck_pfad, WURZEL))
        for k in s_fehlt:
            ort, tiefer = SCHLUESSEL[k]
            wo = {"presentation": "in presentation(…) oder presentation.with(…)",
                  "video": "in einem video()-Aufruf",
                  "room": "in room: (…) an presentation"}[ort]
            if tiefer:
                wo = "in " + tiefer + ": (…) in room: (…) an presentation"
            print("    %-13s %s" % (k + ":", wo))
    if fehlt:
        print("\n  Nicht vorgeführt in %s:" % os.path.relpath(deck_pfad, WURZEL))
        for n in fehlt:
            print("    " + n)
        print("\n  Der Rundgang verspricht im Untertitel jede Funktion einmal.")
        print("  Eine Folie dafür bauen -- oder, wenn er sie nicht aufrufen")
        print("  kann, mit Grund in ZITAT eintragen.")
    return 1 if (fehlt or unbekannt or s_fehlt) else 0

if __name__ == "__main__":
    sys.exit(main())
