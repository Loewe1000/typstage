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

Und die Zähler: jede Schrittseite einer Folie trägt dieselben Nummern wie die
Seite je Folie -- Abbildungen zweier Arten, eine Gleichung, eine nummerierte
Überschrift, ein eigener Zähler mit Ebenen. Abgelesen wird mit `typst eval`
an Marken, die das Prüfdeck neben jede Nummer legt, nicht am Bild. Vor der
Behebung trug die `figure` in der ersten Fassung einer `alternatives` hier auf
ihren beiden Schrittseiten die 3 und die 4, auf der Seite je Folie die 2, und
bei sieben der neun Marken wich mindestens eine Schrittseite ab.

Und dieselben Zähler in `bundle(pages: "step")`: dort zählt das HTML-Dokument
davor dieselben Gleichungen, und seine Zahl setzt sich erst über mehrere
Läufe. Eine Rückstellung, die den Stand an der ersten Seite liest und
hinschreibt, reichte diese Verschiebung von Folie zu Folie einen Lauf später
weiter: gemessen an zwei Folien mit je einer nummerierten Gleichung vor und
hinter einem `#pause` drei Konvergenzmeldungen, im einzelnen Deck keine.
Geprüft wird hier nur, dass das Bündel ohne Meldung durchläuft -- die Nummern
im PDF abzulesen bräuchte ein PDF-Werkzeug.

Und dasselbe Prüfdeck im Browser: ein Sprite setzt den Rumpf seines Elements
ein zweites Mal, und jeder Zähler darin schaltete dabei noch einmal weiter.
Vor der Behebung wichen sieben der zehn Marken ab: die Tabelle hinter dem
`#pause` stand im Sprite bei 2, die Abbildung der `alternatives` bei 3 und die
Abbildung auf der Folie danach bei 4, auf der Seite je Folie bei 1, 2 und 3.
Die Gleichung in der `alternatives` prüft, dass die Nummerierung aus dem Rumpf
des Decks den Sprite erreicht: ohne sie zählte die Klammer um den Sprite dort
eine Gleichung zurück, die er nicht gesetzt hatte, gemessen 1 statt 2. Die
Überschriften vergleicht die Probe im Browser nur mit ihrem eigenen
Hintergrund: auf Papier zählt das Lesezeichen jeder Folie mit, eine
Überschrift, die es im HTML nicht gibt -- gemessen 2.0.1 auf Papier gegen 0.0.1
im Browser, vor der Behebung wie danach.
"""
import json, os, re, shutil, subprocess, sys, tempfile

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

KOPF = '#import "@preview/typstage:0.1.3": *\n#show: presentation.with(title: [P], pages: "{modus}")\n'

# name -> (Rumpf, Seiten bei "slide", Seiten bei "step")
FAELLE = {
    "anim": ("== A\n#anim[eins]\n#anim[zwei]\n", 2, 4),
    "stagger": ("== A\n#stagger([a], [b], [c])\n", 2, 5),
    # `stride`, `name` und `morph` lasen den Schrittzeiger und rechneten jedem
    # Stück sein `at` aus. Gemessen, bevor sie `track` die Schritte vergeben
    # ließen: `stride: 2` sieben Meldungen und zehn Seiten statt fünf, `name:`
    # sieben Meldungen und sechs Seiten statt drei. Und `morph` reservierte
    # seine Schritte gar nicht: das `anim` danach fiel auf den Schritt des
    # zweiten Stücks, und die Schrittfassung hatte drei Seiten statt fünf.
    "stagger stride 2": ("== A\n#stagger(stride: 2, [a], [b], [c])\n", 2, 7),
    "stagger name mit Schicht": ('== A\n#anim[x]\n#stagger(name: "g", [a], [b])\n'
                                 '#stagger-layer("g", 2)[s]\n', 2, 5),
    "stagger morph, danach anim": ("== A\n#stagger(morph: true, [a], [b], [c])\n"
                                   "#anim[d]\n", 2, 6),
    # Dasselbe in `tiles`: jedes `stride` außer 1 las den Zeiger. Gemessen,
    # bevor `track` die Schritte vergab: `stride: 2` acht Meldungen und zehn
    # Seiten statt fünf, `stride: 0` mit einem `anim` dahinter neun Meldungen
    # und vier Seiten statt zwei.
    "tiles stride 2": ("== A\n#tiles(stride: 2, [a], [b], [c])\n", 2, 7),
    "tiles stride 0, danach anim": ("== A\n#tiles(stride: 0, [a], [b])\n"
                                    "#anim[d]\n", 2, 4),
    "alternatives": ("== A\n#alternatives([p], [q], [r])\n", 2, 5),
    "build": ("== A\n#build(from => [#for i in range(3) { if from(i + 1) [S#{i + 1} ] }], steps: 3)\n", 2, 5),
    "scene": ('== A\n#scene("s", t => box(width: 100pt, height: 60pt, '
              'place(top + left, dx: t * 20pt, [o])), stops: (0, 1, 2), tween: 4)\n', 2, 5),
    "zwei Folien": ("== A\n#anim[eins]\n== B\n#stagger([a], [b])\n", 3, 6),
    # `contents()` setzt Marken auf die Abschnittsfolien. Kämen sie je Seite
    # noch einmal, wüchse ihre Zahl mit der Seitenzahl -- und die Seitenzahl
    # hängt an den Schritten. Gemessen, bevor die Marke auf die erste Seite
    # beschränkt wurde: "query for elements labelled `typstage-slide-target`
    # did not stabilize".
    # Ein Verzeichnis *hinter* einer Folie mit Aufdeckschritten: dort fand
    # `contents()` sein Sprungziel nicht mehr, weil die Marke ihre
    # Foliennummer aus einem `place` heraus las und das bei mehreren Seiten je
    # Folie danebengeht -- gemessen fehlten Nummern und andere kamen dreifach.
    "contents nach Aufdecken": ("= Eins\n== A\n=== Aufdecken\n#anim[eins]\n"
                 "#stagger([a], [b])\n= Zwei\n== B\n=== Agenda\n#contents()\n", 7, 10),
    "contents": ("= Ein Abschnitt\n== Aufdecken\n#anim[eins]\n"
                 "#stagger([a], [b])\n#alternatives([p], [q])\n"
                 "== Verzeichnis\n#contents()\n", 4, 9),
    # Die Fahrt belegt in der Schrittfassung keinen Schritt: vier statt sechs.
    "kamera": ("== A\n#anim[eins]\n#pin(<z>, [Ziel])\n#camera(<z>)\n#anim[zwei]\n", 2, 4),
    # Eine Schicht hinter einer Folie mit Schritten. Ihr Schritt kommt aus
    # einer Lesung; stand er als fertige Zeichenkette im Aufruf, bekam der
    # `context` in `track` in jedem Lauf, in dem die Lesung noch wechselte,
    # eine neue Identität, und das Dokument konvergierte nicht.
    "Szene mit Schicht hinter Schritten": (
        '== A\n#anim(at: 2)[x]\n== B\n#scene("s", x => box(width: 100pt, '
        'height: 40pt), stops: (1, 2, 3, 4))\n#scene-layer("s", 2)[s]\n', 3, 8),
    "zwei Schrittfolien vor einer Szene": (
        '== A\n#anim(at: 2)[x]\n== B\n#anim(at: 2)[y]\n== C\n#scene("s", '
        'x => box(width: 100pt, height: 40pt), stops: (1, 2, 3, 4))\n'
        '#scene-layer("s", 1)[s]\n', 4, 10),
    # Eine Szene mit Schicht in einer Fassung von `alternatives`. Die Fassung
    # wird gemessen, und eine Messung zieht einen Lauf später nach; das war
    # für die Schicht einer zu viel. Gemessen, bevor `scene-layer` seine
    # Prüfungen neben die Schicht stellte und seinen Schritt am Ort der Szene
    # las: beide Decks zwei Meldungen "a measured element did not stabilize"
    # und "document did not converge". Die Prüfungen neben der Schicht allein
    # beheben das erste Deck, der Ort der Szene allein das zweite.
    "Szene mit Schicht in einer Fassung, Folie danach": (
        '== A\n#alternatives([p], [#scene("s", x => box(width: 100pt, '
        'height: 40pt), stops: (1, 2, 3))\n#scene-layer("s", 2)[s]], [r])\n'
        '== B\nx\n', 3, 8),
    "drei Folien mit Szene und Schicht in einer Fassung": (''.join(
        '== %s\n#alternatives([p], [#scene("s", x => box(width: 100pt, '
        'height: 40pt), stops: (1, 2, 3))\n#scene-layer("s", 2)[s]], [r])\n'
        % n for n in "ABC"), 4, 19),
    # Fünf Punkte und nicht vier: eine Seite, die in einem Layoutlauf neu
    # hinzukam, las den Stand der Gruppe mit allen Punkten schon darin, und
    # erst ab dem fünften lag die Ziffer über 9. Die Prüfung darauf stand in
    # `cue` selbst, schlug an, und die Seite fiel aus.
    "cue mit fünf Punkten": ('== A\n#cue("g")[\n- a\n- b\n- c\n- d\n- e\n]\n', 2, 7),
    # Ein Verweis auf ein Label einer Folie mit Schritten. Jede Schrittseite
    # setzte das Label noch einmal, und Typst brach ab: "label `<abb>` occurs
    # multiple times in the document". Einmal im Rumpf selbst, einmal in einem
    # aufdeckenden Element, und der Verweis steht auf der Folie und danach.
    "Verweis auf ein Label": (
        '#set math.equation(numbering: "(1)")\n'
        '== A\n#figure(rect(width: 1cm, height: 3mm), caption: [a]) <abb>\n'
        '#pause\nSiehe @abb.\n'
        '== B\n#anim[$ x = 1 $ <gl>]\nSiehe @gl und @abb.\n', 3, 5),
    # Und ein Label in einer Schicht, ohne Verweis. Die Schichten nehmen ihr
    # Label nicht ab: ihr Schritt steht auf einer neuen Schrittseite einen
    # Lauf später fest, und als sie es abnahmen, meldete dieses Deck
    # "did not converge" (die Abfrage `equation.after(…).before(…)` der
    # Zählerklammer), ohne das Abnehmen keine Meldung.
    "Label in einer Schicht": (
        '== A\n#anim(at: 2)[x]\n== B\n#scene("s", x => box(width: 100pt, '
        'height: 20pt), stops: (1, 2, 3))\n#scene-layer("s", 2)[$ s = 1 $ <g>]\n'
        '== C\n#anim[y]\n', 4, 9),
}

# Und die siebzehn Beispieldecks, als Handzettel und unter `pages: "step"`.
# Nicht die Seitenzahl -- die hängt am Inhalt --, sondern dass sie übersetzen
# und konvergieren. Gemessen, bevor diese Probe kam: unter `pages: "step"`
# brachen drei Decks ab, und fünf weitere meldeten, dass das Dokument nicht
# konvergiert -- geprüft hatte das niemand. Ein Deck, das seinen Aufruf
# nicht in der erwarteten Form schreibt, ist eine Beanstandung und kein
# stiller Ausfall.
# Der Aufruf, hinter den die Fassung geschrieben wird. Das Argument darf in
# derselben Zeile weitergehen: die beiden Handzettel-Beispiele schreiben
# `#show: presentation.with(handout: 2,` und waren der Probe sonst nicht
# zugänglich ("kein eindeutiger Aufruf").
KOPF_ZEILE = re.compile(r'^(#show: presentation\.with\(|#presentation\()', re.M)
FASSUNGEN = {"step": 'pages: "step",', "handout": "handout: 2,"}


def kopf_klammer(quelle):
    """Was in der Klammer von `presentation(…)` steht.

    Gebraucht, um eine Fassung nicht zweimal zu setzen: ein Deck, das
    `handout: 2` schon im Aufruf trägt, bekommt es nicht noch einmal.
    """
    m = KOPF_ZEILE.search(quelle)
    if m is None:
        return ""
    i, tiefe = m.end() - 1, 0
    while i < len(quelle):
        if quelle[i] in "([{":
            tiefe += 1
        elif quelle[i] in ")]}":
            tiefe -= 1
            if tiefe == 0:
                return quelle[m.end():i]
        i += 1
    return quelle[m.end():]


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


def beispiele(paketpfad):
    klagen = []
    ordner = os.path.join(WURZEL, "examples")
    decks = sorted(f for f in os.listdir(ordner) if f.endswith(".typ"))
    with tempfile.TemporaryDirectory() as schatten:
        # Ein Schattenbaum: alles verlinkt, nur die Decks liegen als Abschrift
        # mit der eingesetzten Zeile daneben. So finden sie ihre Bilder, und im
        # Repo entsteht keine Datei.
        for e in os.listdir(WURZEL):
            if e != "examples":
                os.symlink(os.path.join(WURZEL, e), os.path.join(schatten, e))
        os.makedirs(os.path.join(schatten, "examples"))
        for f in os.listdir(ordner):
            if not f.endswith(".typ"):
                os.symlink(os.path.join(ordner, f),
                           os.path.join(schatten, "examples", f))
        for deck in decks:
            quelle = open(os.path.join(ordner, deck), encoding="utf-8").read()
            if len(KOPF_ZEILE.findall(quelle)) != 1:
                klagen.append("%s: kein eindeutiger Aufruf von presentation in "
                              "eigener Zeile, die Fassungen sind nicht zu "
                              "setzen" % deck)
                continue
            for fassung, zeile in FASSUNGEN.items():
                datei = os.path.join(schatten, "examples",
                                     deck[:-4] + "--" + fassung + ".typ")
                # Was das Deck selbst schon setzt, wird nicht noch einmal
                # gesetzt: die beiden Handzettel-Beispiele tragen `handout: 2`
                # im Aufruf, und ein zweites Mal hieße "duplicate argument".
                # Sie laufen dann in ihrer eigenen Fassung durch die Probe,
                # und das ist genau die Fassung, um die es bei ihnen geht.
                schluessel = zeile.split(":")[0].strip()
                quelle_f = quelle if schluessel + ":" in kopf_klammer(quelle) \
                    else KOPF_ZEILE.sub(lambda m: m.group(1) + "\n  " + zeile,
                                        quelle, count=1)
                with open(datei, "w", encoding="utf-8") as f:
                    f.write(quelle_f)
                lauf = subprocess.run(
                    ["typst", "compile", "--package-path", paketpfad,
                     "--root", schatten, datei, os.path.join(schatten, "x.pdf")],
                    capture_output=True, text=True)
                fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
                n = len(re.findall(r"did not converge|did not stabilize", lauf.stderr))
                if fehler:
                    klagen.append("%s (%s): übersetzt nicht -- %s"
                                  % (deck, fassung, fehler[0]))
                elif n:
                    klagen.append("%s (%s): %d Konvergenzmeldung(en)"
                                  % (deck, fassung, n))
    return klagen, len(decks)


# Ein Deck, das hinter jede Nummer eine Marke mit dem Zählerstand legt. Die
# Marke liest nur und fließt in nichts zurück, was gesetzt wird.
ZAEHLDECK = (
    '#import "@preview/typstage:0.1.3": *\n'
    '#set heading(numbering: "1.1")\n'
    '#show: presentation.with(title: [P], pages: "{modus}")\n'
    '#set math.equation(numbering: "(1)")\n'
    '#let eigen = counter("eigen")\n'
    '#let nummer(name, c) = context [#metadata((name: name, n: c.get())) <nummer>]\n'
    '= Teil\n'
    '== Pause\n'
    '#figure(rect(width: 1cm, height: 3mm), caption: [a]) '
    '#nummer("a", counter(figure.where(kind: image)))\n'
    '#pause\n'
    '#figure(table[x], caption: [b]) #nummer("b", counter(figure.where(kind: table)))\n'
    '$ x = 1 $ #nummer("gl", counter(math.equation))\n'
    '#block(heading(level: 3)[Unter]) #nummer("h", counter(heading))\n'
    '== Fassungen\n'
    '#alternatives(\n'
    '  [#figure(rect(width: 1cm, height: 3mm), caption: [c]) '
    '#nummer("c", counter(figure.where(kind: image))) '
    '$ y = 1 $ #nummer("gl2", counter(math.equation))],\n'
    '  [#eigen.step(level: 2) #nummer("e", eigen)],\n'
    ')\n'
    '== Danach\n'
    '#figure(rect(width: 1cm, height: 3mm), caption: [d]) '
    '#nummer("d", counter(figure.where(kind: image)))\n'
    '#eigen.step() #nummer("f", eigen)\n'
    '#block(heading(level: 3)[Unter]) #nummer("i", counter(heading))\n'
)


def nummern(modus, ordner, paketpfad, html=False):
    datei = os.path.join(ordner, "zaehler.typ")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(ZAEHLDECK.replace("{modus}", modus))
    ziel = ["--features", "html", "--target", "html"] if html else []
    lauf = subprocess.run(
        ["typst", "eval", *ziel, "--package-path", paketpfad, "--root", ordner,
         "query(<nummer>).map(m => m.value)", "--in", datei],
        capture_output=True, text=True)
    if lauf.returncode != 0:
        return None, lauf.stderr.strip().split("\n")[0]
    if re.search(r"did not converge|did not stabilize", lauf.stderr):
        return None, "Konvergenzmeldung"
    return json.loads(lauf.stdout), None


def zaehler_pruefen(tmp, paket, klagen):
    folie, fehler = nummern("slide", tmp, paket)
    if fehler is not None:
        klagen.append("Zähler (pages: slide): " + fehler)
        return
    schritt, fehler = nummern("step", tmp, paket)
    if fehler is not None:
        klagen.append("Zähler (pages: step): " + fehler)
        return
    soll = {m["name"]: m["n"] for m in folie}
    for m in schritt:
        if m["n"] != soll.get(m["name"]):
            klagen.append(
                "Zähler: %s steht auf einer Schrittseite bei %s, auf der Seite "
                "je Folie bei %s. Jede Schrittseite muss die Zähler dort "
                "beginnen, wo die erste Seite ihrer Folie sie beginnt."
                % (m["name"], m["n"], soll.get(m["name"])))
    # Im Browser trägt jede Marke in einem verfolgten Element zwei Stände: den
    # des Hintergrunds und den ihres Sprites.
    browser, fehler = nummern("slide", tmp, paket, html=True)
    if fehler is not None:
        klagen.append("Zähler (HTML): " + fehler)
        return
    hintergrund = {}
    for m in browser:
        if m["name"] in ("h", "i"):
            gegen, wo = hintergrund.setdefault(m["name"], m["n"]), "im Hintergrund"
        else:
            gegen, wo = soll.get(m["name"]), "auf der Seite je Folie"
        if m["n"] != gegen:
            klagen.append(
                "Zähler: %s steht im Browser bei %s, %s bei %s. Ein Sprite muss "
                "die Zähler dort beginnen, wo sein Rumpf im Hintergrund beginnt, "
                "und darf den Folien danach nichts zulegen."
                % (m["name"], m["n"], wo, gegen))


# Zählt der Browser dieselben Schritte wie das Papier? Die Laufzeit nimmt je
# Folie die größte Zahl in den `data-at` ihrer Elemente (`STEPS` in der
# Laufzeit), das Papier den Zeiger am Folienende. Vergibt ein Element seine
# Schritte im Browser anders als auf Papier, laufen die beiden auseinander,
# und keine Fassung sieht für sich falsch aus.
#
# name -> (Rumpf, Schritte je Folie; die Titelfolie hat einen)
BROWSER = {
    # Die Fassungen reservierten ihre Schritte im Browser nicht: das `anim`
    # danach bekam Schritt 2, mitten in der Umformung, und die Folie hatte drei
    # Schritte gegen vier Seiten auf Papier. Mit `start: 2` fünf gegen zwei.
    "alternatives morph, danach anim": (
        "== A\n#alternatives(morph: true, [p], [q], [r])\n#anim[d]\n", [1, 5]),
    "alternatives morph mit start, danach anim": (
        "== A\n#alternatives(morph: true, start: 2, [p], [q], [r])\n#anim[d]\n",
        [1, 5]),
}


def browser_pruefen(tmp, paket, klagen):
    for name, (rumpf, soll) in BROWSER.items():
        datei = os.path.join(tmp, "browser.typ")
        with open(datei, "w", encoding="utf-8") as f:
            f.write(KOPF.format(modus="slide") + rumpf)
        ziel = os.path.join(tmp, "browser.html")
        lauf = subprocess.run(
            ["typst", "compile", "--features", "html", "--format", "html",
             "--package-path", paket, "--root", tmp, datei, ziel],
            capture_output=True, text=True)
        fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
        if fehler:
            klagen.append("%s (Browser): übersetzt nicht -- %s" % (name, fehler[0]))
            continue
        html = open(ziel, encoding="utf-8").read()
        ist = []
        for folie in html.split('<section class="ts-slide"')[1:]:
            zahlen = [int(z) for at in re.findall(
                r'<div class="ts-el [^"]*"[^>]*data-at="([^"]*)"', folie)
                for z in re.findall(r"\d+", at)]
            ist.append(max([1] + zahlen))
        if ist != soll:
            klagen.append("%s (Browser): Schritte je Folie %s, erwartet %s -- "
                          "so viele Seiten setzt `pages: \"step\"`"
                          % (name, ist, soll))


# Zwei Folien genügen: auf der zweiten kommt die Verschiebung aus der ersten
# schon einen Lauf zu spät an.
BUENDEL = (
    '#import "@preview/typstage:0.1.3": *\n'
    '#bundle(title: [P], pages: "step")[\n'
    '#set math.equation(numbering: "(1)")\n'
    '== Eins\n$ a = 1 $\n#pause\n$ b = 2 $\n'
    '== Zwei\n$ c = 1 $\n#pause\n$ d = 2 $\n'
    ']\n'
)


def buendel_pruefen(tmp, paket, klagen):
    datei = os.path.join(tmp, "buendel.typ")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(BUENDEL)
    ziel = os.path.join(tmp, "buendel-aus")
    shutil.rmtree(ziel, ignore_errors=True)
    lauf = subprocess.run(
        ["typst", "compile", "--features", "bundle,html", "--format", "bundle",
         "--package-path", paket, "--root", tmp, datei, ziel],
        capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        klagen.append("Zähler im Bündel: übersetzt nicht -- " + fehler[0])
        return
    if re.search(r"did not converge|did not stabilize", lauf.stderr):
        klagen.append(
            "Zähler im Bündel (bundle, pages: step): Konvergenzmeldung. Die "
            "Schrittseiten dürfen die Zähler nur um den Abstand ihrer ersten "
            "Seite zurückstellen und keinen gelesenen Stand hinschreiben -- "
            "sonst reicht jede Folie die Zahl des HTML-Dokuments einen Lauf "
            "später an die nächste weiter.")


# Eine Umformung als erstes auf ihrer Folie, im gewöhnlichen Bündel. Seit die
# Fassungen von `alternatives(morph: true)` ihre Schritte von `track` bekommen,
# liest jede den Zeiger, und die Liste der Morphs für die Prüfung am Deckende
# kippte einen Lauf zu spät: gemessen zwei Meldungen "value of
# `state("typstage-morphs")` did not converge" für jede der beiden Folien
# allein, bei `stagger(morph: true)` schon vorher. Das HTML allein und die PDF
# allein blieben still.
MORPH_BUENDEL = (
    '#import "@preview/typstage:0.1.3": *\n'
    '#bundle(title: [P])[\n'
    '== Eins\n#alternatives(morph: true, $a + b$, $b + a$, $c$)\n'
    '== Zwei\n#stagger(morph: true, $a + b$, $b + a$, $c$)\n'
    ']\n'
)


def morph_buendel_pruefen(tmp, paket, klagen):
    datei = os.path.join(tmp, "morph-buendel.typ")
    with open(datei, "w", encoding="utf-8") as f:
        f.write(MORPH_BUENDEL)
    ziel = os.path.join(tmp, "morph-buendel-aus")
    shutil.rmtree(ziel, ignore_errors=True)
    lauf = subprocess.run(
        ["typst", "compile", "--features", "bundle,html", "--format", "bundle",
         "--package-path", paket, "--root", tmp, datei, ziel],
        capture_output=True, text=True)
    fehler = [z for z in lauf.stderr.split("\n") if z.startswith("error:")]
    if fehler:
        klagen.append("Morphs im Bündel: übersetzt nicht -- " + fehler[0])
        return
    if re.search(r"did not converge|did not stabilize", lauf.stderr):
        klagen.append(
            "Morphs im Bündel: Konvergenzmeldung. Was die Prüfung am Deckende "
            "über die Morphs einer Folie festhält, darf nicht am gelesenen "
            "Schritt jedes einzelnen hängen.")


def main():
    with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as paket:
        for raum in ("schule", "preview"):
            ziel = os.path.join(paket, raum, "typstage")
            os.makedirs(ziel, exist_ok=True)
            os.symlink(WURZEL, os.path.join(ziel, "0.1.3"))
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
        zaehler_pruefen(tmp, paket, klagen)
        buendel_pruefen(tmp, paket, klagen)
        morph_buendel_pruefen(tmp, paket, klagen)
        browser_pruefen(tmp, paket, klagen)
        mehr, n_decks = beispiele(paket)
        klagen += mehr
        if klagen:
            print("Schrittseiten: %d Beanstandung(en)" % len(klagen))
            for k in klagen:
                print("  - " + k)
            return 1
    print("Schrittseiten: %d Decks in beiden Fassungen, Zähler stimmen, dazu %d "
          "Beispiele als Handzettel und Schritt für Schritt" % (len(FAELLE), n_decks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
