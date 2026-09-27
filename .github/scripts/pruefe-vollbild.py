#!/usr/bin/env python3
"""pruefe-vollbild.py -- eine leere Überschrift und `bleed`, auf Papier und im Satz

    python3 .github/scripts/pruefe-vollbild.py [--paketpfad PFAD]

Das Abnahmedeck aus der Rückmeldung „Folien ohne Laufzeile und Vollbildinhalt":
vier Folien, `themes.lesson` mit Bruchzahl und Leiste, damit die Laufzeile, die
Fußzeile und der Fortschritt überhaupt da sind. Das Standardthema zeigte auf
einer titellosen Folie auch vorher keine Laufzeile, und die Probe bestünde dort
aus dem falschen Grund.

Das Bild ist ein SVG aus vier Feldern bekannter Farbe, genau so groß wie die
Leinwand. Damit ist jede Ecke eine bekannte Farbe, und ein Pixel des Chromes
auf dem Bild fällt als fremde Farbe auf. Laufzeile, Haarlinie, Nummer und
Leiste tragen über ihre Labels je eine eigene Farbe (`show <ts-...>`), vor der
Show-Regel des Decks, sonst erreicht die Regel die Chrome-Ebene des HTML nicht.
So wird nach Farbe gesucht, nicht nach Glyphen gezählt.

Ohne PIL: das PNG wird mit zlib gelesen, damit auf dem Prüfrechner nichts
nachinstalliert werden muss. Im Browser misst `pruefe-vollbild.js` dasselbe
Deck: Sprites, Flug, Leiste, Druckansicht.

Rückgabewert 0, wenn alles hält, sonst 1.
"""
import os, re, shutil, struct, subprocess, sys, tempfile, zlib

WURZEL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PPI = 150
S = PPI / 72

# Die Farben der vier Felder, oben links, oben rechts, unten links, unten rechts.
FELD = [(0x1c, 0x3a, 0x5c), (0x2e, 0x7d, 0x32), (0x6a, 0x1b, 0x9a), (0x8d, 0x6e, 0x00)]
MARKE = {"haarlinie": (0x12, 0x34, 0x56), "laufzeile": (0x65, 0x43, 0x21),
         "nummer": (0x0a, 0x0b, 0x0c), "leiste": (0xab, 0xcd, 0xef)}

BILD = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 841.89 473.56">
<rect x="0" y="0" width="420.945" height="236.78" fill="#1c3a5c"/>
<rect x="420.945" y="0" width="420.945" height="236.78" fill="#2e7d32"/>
<rect x="0" y="236.78" width="420.945" height="236.78" fill="#6a1b9a"/>
<rect x="420.945" y="236.78" width="420.945" height="236.78" fill="#8d6e00"/>
</svg>"""

DECK = """#import "@preview/typstage:0.2.0": *
#show <ts-slide-header-rule>: set rect(fill: rgb("#123456"))
#show <ts-slide-header-text>: set text(fill: rgb("#654321"))
#show <ts-slide-number>: set text(fill: rgb("#0a0b0c"))
#show <ts-slide-progress>: set rect(fill: rgb("#abcdef"))
#let bild = image(bytes(read("bild.svg")), format: "svg",
                  width: 100%, height: 100%, fit: "cover")
#show: presentation.with(
  theme: themes.lesson + (footer: "fraction", progress: "bar"){zusatz})

= Abschnitt Eins

== Mit Titel
#place(dx: 60pt, dy: 40pt, morph("k", rect(width: 100pt, height: 60pt, fill: red)))
#place(dx: 300pt, dy: 40pt, morph("m", circle(radius: 20pt, fill: orange)))
Erste Folie.

==
#bleed[
  #bild
  #place(dx: 600pt, dy: 60pt, morph("m", circle(radius: 30pt, fill: orange)))
  #place(top + left, dx: 40pt, dy: 300pt, anim(at: 2, rect(width: 160pt, height: 50pt, fill: white)))
]
#place(dx: 500pt, dy: 250pt, morph("k", rect(width: 200pt, height: 120pt, fill: red)))

==
Nur Text auf einer Folie ohne Titel.

== Mit Titel
Normaler Inhalt.
"""

# Was abbrechen muss, und woran. Je ein Rumpf hinter `== A`.
FEHLER = {
    "nach Inhalt": ("Text\n#bleed(rect())", "comes after other content"),
    "nach #v": ("#v(1em)\n#bleed(rect())", "comes after other content"),
    "nach #pause": ("#pause\n#bleed(rect())", "stands behind a #pause"),
    "zweimal": ("#bleed(rect())\n#bleed(rect())", "holds 2 bleed() calls"),
    "#pause darin": ("#bleed[A #pause B]", "a #pause inside bleed()"),
    "in bleed": ("#bleed[#bleed(rect())]", "bleed() inside bleed()"),
    "im Block": ("#block(bleed(rect()))", "instead of being taken out of it"),
    "im Raster": ("#grid(columns: 2, bleed(rect()), [B])", "instead of being taken out of it"),
    "in anim": ("#anim(bleed(rect()))", "instead of being taken out of it"),
    "unter show: it => block": ("#show: it => block(it)\n#bleed(rect())", "instead of being taken out of it"),
    "in der Notiz": ("#speaker-note[Hallo #bleed(rect())]", "cannot stand in a speaker note"),
}
FEHLER_DOKUMENT = {
    "im Titel": ("#show: presentation.with()\n== A #bleed(rect())\nText", "cannot stand in a title"),
    "Abschnittsfolie": ("#presentation(section(bleed(rect())), slide[A][B])", "cannot stand in a title"),
    "Titelfolie": ("#show: presentation.with(title: bleed(rect()))\n== A\nText", "cannot stand in a title"),
    # „part of the page outside the deck" und nicht bloß „outside the deck":
    # der Satz zählt am Ende jeden Ort auf, an dem bleed() nicht stehen darf,
    # und trägt dabei auch „not outside the deck". Jede Verschachtelungsmeldung
    # bestünde mit dem kürzeren Stück, auch die falsche.
    "außerhalb des Decks": ("#bleed(rect())\n#show: presentation.with()\n== A\nText",
                            "part of the page outside the deck"),
    # Und dahinter. Der Zustand des Decks behielt hier den Stand der letzten
    # Folie, und die Meldung schickte den Leser auf eine Folie, auf der nichts
    # zu finden war: „on slide 1" statt „outside the deck".
    "hinter dem Deck": ("#presentation(slide([Eins])[Text.])\n#bleed(rect())",
                        "part of the page outside the deck"),
    # Die Art vor dem Namen: eine Abschnittsfolie mit Titel hieß in dieser
    # Meldung „the slide", und wer das las, suchte nach einem `==`.
    "Abschnittsfolie mit Titel": ("#show: presentation.with()\n= Teil #bleed(rect())\n"
                                  "== A\nText", 'the section slide "Teil"'),
}


def arg(name, vorgabe=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else vorgabe


def paketpfad_bauen():
    pfad = tempfile.mkdtemp(prefix="typstage-vollbild-pk-")
    for raum in ("schule", "preview"):
        os.makedirs(os.path.join(pfad, raum, "typstage"))
        os.symlink(WURZEL, os.path.join(pfad, raum, "typstage", "0.2.0"))
    return pfad


def png_lesen(pfad):
    """(breite, hoehe, zeilen) mit zeilen[y][x] = (r, g, b). Nur 8 Bit RGB/RGBA."""
    roh = open(pfad, "rb").read()
    pos, idat, kopf = 8, b"", None
    while pos < len(roh):
        n, art = struct.unpack(">I4s", roh[pos:pos + 8])
        daten = roh[pos + 8:pos + 8 + n]
        if art == b"IHDR":
            kopf = struct.unpack(">IIBBBBB", daten)
        elif art == b"IDAT":
            idat += daten
        pos += 12 + n
    w, h, tiefe, farbe = kopf[0], kopf[1], kopf[2], kopf[3]
    assert tiefe == 8 and farbe in (2, 6), "unerwartetes PNG"
    bpp = 4 if farbe == 6 else 3
    strom = zlib.decompress(idat)
    zeilen, vor, i = [], bytearray(w * bpp), 0
    for _ in range(h):
        f, z = strom[i], bytearray(strom[i + 1:i + 1 + w * bpp])
        i += 1 + w * bpp
        for x in range(len(z)):
            a = z[x - bpp] if x >= bpp else 0
            b = vor[x]
            c = vor[x - bpp] if x >= bpp else 0
            if f == 1: z[x] = (z[x] + a) & 255
            elif f == 2: z[x] = (z[x] + b) & 255
            elif f == 3: z[x] = (z[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                z[x] = (z[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        zeilen.append([tuple(z[x * bpp:x * bpp + 3]) for x in range(w)])
        vor = z
    return w, h, zeilen


def farben(zeilen, x0, y0, x1, y1):
    """Die Farben eines Streifens in pt."""
    menge = set()
    for y in range(int(y0 * S), int(y1 * S)):
        menge.update(zeilen[y][int(x0 * S):int(x1 * S)])
    return menge


def uebersetzen(tmp, pk, quelle, ziel, *extra):
    return subprocess.run(["typst", "compile", "--package-path", pk, "--root", tmp,
                           *extra, quelle, ziel], capture_output=True, text=True)


def meldungen(stderr):
    return [z for z in stderr.splitlines() if z.startswith(("warning:", "error:"))
            and "is under active development" not in z
            and "export is experimental" not in z]


def main():
    eigener = arg("--paketpfad") is None
    pk = arg("--paketpfad") or paketpfad_bauen()
    tmp = tempfile.mkdtemp(prefix="typstage-vollbild-")
    klagen = []
    klage = klagen.append
    try:
        open(os.path.join(tmp, "bild.svg"), "w").write(BILD)
        deck = os.path.join(tmp, "deck.typ")
        open(deck, "w").write(DECK.format(zusatz=""))

        # ── Papier ──────────────────────────────────────────────────────────
        r = uebersetzen(tmp, pk, deck, os.path.join(tmp, "s-{p}.png"), "--ppi", str(PPI))
        if r.returncode != 0 or meldungen(r.stderr):
            print("Vollbild: das Deck übersetzt nicht sauber --", meldungen(r.stderr)[:2])
            return 1
        seiten = sorted(f for f in os.listdir(tmp) if re.match(r"s-\d+\.png$", f))
        if len(seiten) != 5:
            klage(f"Papier: {len(seiten)} Seiten statt 5")
        bild = {i + 1: png_lesen(os.path.join(tmp, f)) for i, f in enumerate(seiten)}

        def hat(seite, name):
            w, h, z = bild[seite]
            ziel = MARKE[name]
            return any(ziel in zeile for zeile in z)

        # Seite 3 ist die Folie mit bleed (Seite 1 ist die Abschnittsfolie).
        w, h, z = bild[3]
        ecken = [z[1][1], z[1][w - 2], z[h - 2][1], z[h - 2][w - 2]]
        if ecken != [FELD[0], FELD[1], FELD[2], FELD[3]]:
            klage(f"Papier, bleed: Eckpixel {ecken} statt der Bildfarben {FELD}")
        # Kopf- und Fußstreifen tragen nur Bild: keine Nummer, keine Haarlinie,
        # keine Leiste. Die unterste Pixelzeile bleibt draußen, sie ist nur
        # teilweise bedeckt (473.56pt sind bei 150 ppi 986.6 px).
        kopf = farben(z, 0, 0, 841, 50)
        fuss = farben(z, 0, 440, 841, (h - 1) / S)
        if kopf - {FELD[0], FELD[1]}:
            klage(f"Papier, bleed: fremde Farben im Kopf {sorted(kopf - {FELD[0], FELD[1]})[:4]}")
        if fuss - {FELD[2], FELD[3]}:
            klage(f"Papier, bleed: fremde Farben im Fuß {sorted(fuss - {FELD[2], FELD[3]})[:4]}")
        for name in MARKE:
            if hat(3, name):
                klage(f"Papier, bleed: {name} steht auf der Folie")
        # Seite 4: titellos. Keine Laufzeile, aber Nummer und Leiste.
        for name, soll in (("haarlinie", False), ("laufzeile", False),
                           ("nummer", True), ("leiste", True)):
            if hat(4, name) != soll:
                klage(f"Papier, ohne Titel: {name} {'fehlt' if soll else 'steht da'}")
        # A2: der Rumpf rückt um die Laufzeile nach oben. Erste Tinte unter dem
        # Kopf; mit reservierter Laufzeile läge sie gemessen 27pt tiefer.
        w, h, z = bild[4]
        papier = z[int(100 * S)][int(420 * S)]
        erste = next((y for y in range(int(20 * S), int(200 * S))
                      if any(p != papier for p in z[y][int(32 * S):int(700 * S)])), None)
        if erste is None or erste / S > 70:
            klage(f"Papier, ohne Titel: erste Tinte bei {erste and round(erste / S, 1)}pt, "
                  "der Rumpf hält die Höhe der Laufzeile frei")
        # Seiten 2 und 5: Titel, alles da.
        for seite in (2, 5):
            for name in MARKE:
                if not hat(seite, name):
                    klage(f"Papier, Seite {seite}: {name} fehlt")

        # ── Ein Titel ohne Text ist ein Titel ───────────────────────────────
        # Leer ist, was nichts zeichnet. Ein Bild im Titel zeichnet: die Folie
        # behält Band, Laufzeile und Kopfhöhe. `== #h(0pt)` zeichnet nichts und
        # steht in `example.typ` für eine Folie ohne Titel.
        titel = os.path.join(tmp, "titel.typ")
        open(titel, "w").write('#import "@preview/typstage:0.2.0": *\n'
                               '#show <ts-slide-header-rule>: set rect(fill: rgb("#123456"))\n'
                               '#show: presentation.with(theme: themes.lesson)\n'
                               '== #box(rect(width: 30pt, height: 12pt, fill: rgb("#00ff02")))\nLogo\n'
                               '== #h(0pt)\nLeer\n')
        r = uebersetzen(tmp, pk, titel, os.path.join(tmp, "t-{p}.png"), "--ppi", str(PPI))
        if r.returncode != 0 or meldungen(r.stderr):
            klage(f"Titel ohne Text: übersetzt nicht sauber {meldungen(r.stderr)[:2]}")
        else:
            t1 = png_lesen(os.path.join(tmp, "t-1.png"))[2]
            t2 = png_lesen(os.path.join(tmp, "t-2.png"))[2]
            if not any((0x00, 0xff, 0x02) in z for z in t1):
                klage("Titel ohne Text: das Bild im Titel fehlt")
            if not any(MARKE["haarlinie"] in z for z in t1):
                klage("Titel ohne Text: die Folie mit Bildtitel hat keine Laufzeile")
            if any(MARKE["haarlinie"] in z for z in t2):
                klage("Titel ohne Text: `== #h(0pt)` trägt eine Laufzeile")

        # ── HTML ────────────────────────────────────────────────────────────
        html = os.path.join(tmp, "deck.html")
        r = uebersetzen(tmp, pk, deck, html, "--features", "html", "--format", "html")
        if r.returncode != 0 or meldungen(r.stderr):
            klage(f"HTML übersetzt nicht sauber: {meldungen(r.stderr)[:2]}")
        else:
            t = open(html, encoding="utf-8").read()
            ebene = t[t.index('<div id="ts-chrome">'):t.index('id="ts-fly"')]
            eintraege = re.split(r'(?=<div class="ts-chrome")', ebene)[1:]
            if len(eintraege) != 5:
                klage(f"HTML: {len(eintraege)} Chrome-Einträge statt 5")
            else:
                if not re.match(r'<div class="ts-chrome" data-anteil="0.5"></div>', eintraege[2]):
                    klage("HTML: der Chrome-Eintrag der bleed-Folie ist nicht leer "
                          "oder hat seinen Anteil verloren")
                if "#123456" in eintraege[3] or "#654321" in eintraege[3]:
                    klage("HTML: der Chrome-Eintrag der titellosen Folie trägt die Laufzeile")
                if "#0a0b0c" not in eintraege[3]:
                    klage("HTML: der Chrome-Eintrag der titellosen Folie hat keine Nummer")
                if "#123456" not in eintraege[4]:
                    klage("HTML: auf Folie 4 fehlt die Laufzeile")
            folien = t.split('<section class="ts-slide"')[1:]
            if len(folien) == 5:
                if 'class="ts-chromep"' in folien[2]:
                    klage("HTML: die bleed-Folie trägt ein Druck-Chrome")
                druck = re.search(r'<div class="ts-chromep">(.*?)</div><div class="ts-ov"',
                                  folien[3], re.S)
                if not druck or "#123456" in druck.group(1) or "#abcdef" not in druck.group(1):
                    klage("HTML: das Druck-Chrome der titellosen Folie stimmt nicht")
            if t.count('data-name="k"') != 2:
                klage(f'HTML: data-name="k" steht {t.count(chr(100) + "ata-name=" + chr(34) + "k" + chr(34))}-mal')

        # ── Schritt für Schritt, Handzettel, Bündel ─────────────────────────
        for name, zusatz, ziel, extra in (
                ("Schrittseiten", ', pages: "step"', "x.pdf", ()),
                ("Handzettel", ", handout: 2", "x.pdf", ()),
                ("Bündel", "", "b", ("--features", "html,bundle", "--format", "bundle"))):
            quelle = DECK.format(zusatz=zusatz)
            if name == "Bündel":
                quelle = quelle.replace("#show: presentation.with(",
                                        '#show: bundle.with(handout: "h.pdf", ')
            p = os.path.join(tmp, "f.typ")
            open(p, "w").write(quelle)
            r = uebersetzen(tmp, pk, p, os.path.join(tmp, ziel), *extra)
            if r.returncode != 0 or meldungen(r.stderr):
                klage(f"{name}: {meldungen(r.stderr)[:2]}")

        # Unter `pages: "step"` steht der Inhalt des bleed auf jeder Seite der
        # Folie noch einmal. Ein Label darin darf dabei nur einmal zählen, sonst
        # bricht der Verweis mit "label `<abb>` occurs multiple times" ab.
        p = os.path.join(tmp, "l.typ")
        open(p, "w").write('#import "@preview/typstage:0.2.0": *\n#show: presentation.with(pages: "step")\n'
                           "== A\n#bleed[\n"
                           "  #place(dx: 40pt, dy: 300pt, [#figure(rect(width: 40pt, height: 20pt), caption: [Bild]) <abb>])\n"
                           "  #place(dx: 300pt, dy: 300pt, anim(at: 2)[Später])\n]\nSiehe @abb.\n")
        r = uebersetzen(tmp, pk, p, os.path.join(tmp, "l.pdf"))
        if r.returncode != 0 or meldungen(r.stderr):
            klage(f"Schrittseiten mit Label im bleed: {meldungen(r.stderr)[:2]}")

        # ── Was abbrechen muss ──────────────────────────────────────────────
        faelle = {k: ('#import "@preview/typstage:0.2.0": *\n#show: presentation.with()\n'
                      "= Teil\n== A\n" + rumpf.replace("rect()", "rect(width: 100%, height: 100%)"), weil)
                  for k, (rumpf, weil) in FEHLER.items()}
        faelle.update({k: ('#import "@preview/typstage:0.2.0": *\n'
                           + q.replace("rect()", "rect(width: 100%, height: 100%)"), weil)
                       for k, (q, weil) in FEHLER_DOKUMENT.items()})
        for k, (quelle, weil) in faelle.items():
            p = os.path.join(tmp, "e.typ")
            open(p, "w").write(quelle)
            for extra in ((), ("--features", "html", "--format", "html")):
                r = uebersetzen(tmp, pk, p, os.path.join(tmp, "e.html" if extra else "e.pdf"), *extra)
                text = " ".join(r.stderr.split())
                if r.returncode == 0 or weil not in text:
                    klage(f"Meldung „{k}“ ({'HTML' if extra else 'PDF'}): erwartet „{weil}“, "
                          f"bekommen: {text[:160] or 'keinen Abbruch'}")

        # ── bleed(none) ─────────────────────────────────────────────────────
        # Ein Deck, das sein Bild bedingt setzt -- `#bleed(if bild != none {
        # image(bild, ..) })` --, schreibt `none`. Das ist die leere Leinwand
        # wie `#bleed[]` und kein Fehler: der Fund reist als Wert der Marke,
        # und ein `none` darin war von „kein bleed gefunden" nicht zu
        # unterscheiden -- die Folie behielt ihren Rumpf samt Marke, und der
        # Wächter meldete eine Verschachtelung, die niemand geschrieben hat.
        bilder = {}
        for wie, ruf in (("none", "#bleed(none)"), ("leer", "#bleed[]")):
            p = os.path.join(tmp, "n-" + wie + ".typ")
            open(p, "w").write('#import "@preview/typstage:0.2.0": *\n'
                               "#show: presentation.with(theme: themes.lesson)\n"
                               "== A\n" + ruf + "\nText\n")
            r = uebersetzen(tmp, pk, p, os.path.join(tmp, "n-" + wie + ".png"), "--ppi", "20")
            if r.returncode != 0 or meldungen(r.stderr):
                klage(f"bleed({wie}): übersetzt nicht sauber "
                      f"{' '.join(r.stderr.split())[:160]}")
            else:
                bilder[wie] = open(os.path.join(tmp, "n-" + wie + ".png"), "rb").read()
        if len(bilder) == 2 and bilder["none"] != bilder["leer"]:
            klage("bleed(none) setzt nicht dasselbe wie bleed[]")

        # ── Was über dem bleed stehen darf ──────────────────────────────────
        # Regeln, `#invert`, `#transition`, `#speaker-note` und `#class-clock`
        # sind keine Inhalte. Sie dürfen davor stehen, und keines darf dabei
        # verlorengehen: die `set`-Regel erreicht den Inhalt des bleed (die
        # untere Ecke trägt ihre Farbe, die obere das Titelband über dem
        # bleed), die Notiz, die Uhr und der Übergang stehen
        # an der Folie, und `#invert` kehrt sie um, vor dem bleed wie darin.
        p = os.path.join(tmp, "d.typ")
        open(p, "w").write('#import "@preview/typstage:0.2.0": *\n#show: presentation.with()\n'
                           "== Davor\n"
                           '#set rect(fill: rgb("#00ff02"))\n#show strong: set text(red)\n'
                           '#transition("fade")\n#speaker-note[Die Notiz]\n#class-clock(5)\n'
                           "#bleed(rect(width: 100%, height: 100%))\n*Text*\n"
                           "== Grund\nText\n"
                           "==\n#invert\n#bleed(place(dx: 10pt, dy: 10pt, rect(width: 5pt, height: 5pt)))\n"
                           "==\n#bleed[#invert #place(dx: 10pt, dy: 10pt, rect(width: 5pt, height: 5pt))]\n")
        r = uebersetzen(tmp, pk, p, os.path.join(tmp, "d-{p}.png"), "--ppi", "20")
        if r.returncode != 0 or meldungen(r.stderr):
            klage(f"Über dem bleed: übersetzt nicht sauber {meldungen(r.stderr)[:2]}")
        else:
            d = [png_lesen(os.path.join(tmp, f"d-{i}.png"))[2] for i in (1, 2, 3, 4)]
            if d[0][-2][1] != (0x00, 0xff, 0x02):
                klage(f"Über dem bleed: die set-Regel erreicht den Inhalt nicht, Ecke {d[0][-2][1]}")
            grund = d[1][60][100]
            for i in (2, 3):
                if d[i][60][100] == grund:
                    klage(f"Über dem bleed: Folie {i + 1} ist nicht umgekehrt ({grund})")
        r = uebersetzen(tmp, pk, p, os.path.join(tmp, "d.html"), "--features", "html", "--format", "html")
        if r.returncode != 0 or meldungen(r.stderr):
            klage(f"Über dem bleed, HTML: {meldungen(r.stderr)[:2]}")
        else:
            erste = open(os.path.join(tmp, "d.html"), encoding="utf-8").read().split('<section class="ts-slide"')[1]
            ov = re.search(r'<div class="ts-ov"[^>]*>', erste)
            # Der Übergang reist als JSON: `{"kind": "fade"}`, gesetzt.
            for attr in (r'data-transition="[^"]*fade', r'data-note="Die Notiz"', r'data-clock="5"'):
                if not ov or not re.search(attr, ov.group(0)):
                    klage(f"Über dem bleed, HTML: {attr} fehlt an der Folie")

        # ── Überlauf ────────────────────────────────────────────────────────
        # Ein bleed läuft nie über, und seine Sprites verschieben den Schritt
        # nicht, den der Melder für den Rumpf nennt.
        p = os.path.join(tmp, "u.typ")
        open(p, "w").write('#import "@preview/typstage:0.2.0": *\n'
                           '#show: presentation.with(overflow: "record")\n'
                           "== Ohne\n#rect(height: 380pt)\n#anim(at: 3, rect(height: 100pt))\n"
                           "== Mit\n#bleed[#place(top + left, anim(at: 2, rect(height: 400pt)))]\n"
                           "#rect(height: 380pt)\n#anim(at: 3, rect(height: 100pt))\n"
                           "== Nur bleed\n#bleed(rect(width: 100%, height: 100%))\nText\n")
        r = subprocess.run(["typst", "eval", "--package-path", pk, "--root", tmp,
                            "--target", "html", "--features", "html",
                            "query(<typstage-overflow>).map(e => (e.value.slide, e.value.step))",
                            "--in", p], capture_output=True, text=True)
        if r.stdout.split() != ["[[1,1],[2,1]]"] and r.stdout.strip() != "[[1, 1], [2, 1]]":
            klage(f"Überlauf: erwartet Folie 1 und 2 ab Schritt 1, bekommen {r.stdout.strip() or r.stderr[:160]}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        if eigener:
            shutil.rmtree(pk, ignore_errors=True)
    for k in klagen:
        print("  " + k)
    print(f"Vollbild: {len(klagen)} Befund(e)" if klagen
          else "Vollbild: Laufzeile, Chrome, Ecken, Meldungen und Überlauf stimmen")
    return 1 if klagen else 0


if __name__ == "__main__":
    sys.exit(main())
