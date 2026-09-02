// Das Themenbild der README, von Typst gesetzt — so wie das Zeichen daneben.
//
//   python3 .github/scripts/bau-themenbild.py
//
// Zwei Durchgänge, und deshalb zwei Modi in einer Datei. Erst wird dieselbe
// Folie fünfmal gesetzt, einmal je Theme; dann werden die fünf Bilder auf ein
// Blatt gelegt. Das Skript daneben tut nichts weiter, als beides in der
// richtigen Reihenfolge aufzurufen.
//
//   typst compile --input modus=folie --input thema=lesson assets/themes.typ …
//   typst compile --input modus=blatt assets/themes.typ assets/themes.png
//
// Warum das Theme von außen kommt und nicht fünfmal im Quelltext steht: sonst
// vergleicht das Bild nicht die Themes, sondern meine Tippfehler. Ein Rumpf,
// fünf Durchgänge, kein Unterschied außer dem einen, um den es geht.
//
// Warum die Beschriftungen im zweiten Durchgang und nicht in einem Bildwerk-
// zeug entstehen: es ist ein Bild über Typografie. Es in einer Schrift zu
// beschriften, die das Paket nirgends benutzt, wäre ein seltsamer Anfang.
//
// Das Bild veraltet, sobald sich ein Theme ändert, und es hat genau das
// getan: die alte Fassung zeigte `themes.lesson` mit blauer Überschrift und
// oranger Linie, Monate nachdem daraus rot auf blauer Linie geworden war. Wer
// ein Theme anfasst, lässt danach das Skript laufen.
#import "@preview/typstage:0.1.1": *

#let modus = sys.inputs.at("modus", default: "folie")

// =============================================================================
// Durchgang 1 — eine Folie, ein Theme
// =============================================================================
#let namen = ("default", "lesson", "night", "plain", "editorial")

#if modus == "folie" {
  let name = sys.inputs.at("thema", default: "default")
  assert(name in namen, message: "themes.typ: --input thema= ist eines von "
    + namen.map(repr).join(", ") + ", nicht " + repr(name))
  let t = (
    default: themes.default, lesson: themes.lesson, night: themes.night,
    plain: themes.plain, editorial: themes.editorial,
  ).at(name)

  show: presentation.with(theme: t, title: [Four triangles in a square])

  [
    == Four triangles in a square

    #side-by-side(
      split: (1fr, 1fr), align: top,
      card(title: [The setup])[
        Four copies of the triangle fit into a square of side $a + b$.
      ],
      [
        - The inner square has side $c$
        - Rearranged, the same four copies leave $a^2 + b^2$
      ],
    )

    #v(1fr)

    #callout(title: [Remember])[
      The leftover area cannot change --- only its shape does.
    ]
  ]
}

// =============================================================================
// Durchgang 2 — die fünf Bilder auf ein Blatt
// =============================================================================
// Zwei Spalten, drei Zeilen. Die sechste Zelle bleibt frei und trägt den Satz,
// der das Bild erklärt — so braucht die README keine Bildunterschrift dafür.
#if modus == "blatt" {
  let breit = 470pt
  let luft = 18pt

  set page(width: breit * 2 + luft * 3, height: auto, margin: luft,
           fill: rgb("#ffffff"))
  set text(font: ("Helvetica Neue", "Helvetica", "Arial"), size: 10pt,
           fill: rgb("#5a5f66"))

  let zelle(name) = {
    block(
      stroke: 0.5pt + rgb("#d6d8dc"),
      image("themes-" + name + ".png", width: breit),
    )
    v(5pt)
    text(font: ("SF Mono", "Menlo", "DejaVu Sans Mono"), size: 9.5pt,
         "themes." + name)
  }

  grid(
    columns: (breit, breit), rows: auto, column-gutter: luft, row-gutter: luft,
    ..namen.map(zelle),
    // Die freie Zelle. Vertikal auf die Mitte der Nachbarfolie gebracht, damit
    // der Satz nicht oben klebt.
    block(width: breit, inset: (top: breit * 9 / 16 * 0.34))[
      #set text(size: 13pt, fill: rgb("#23303f"))
      The same slide, five built-in themes.
      #v(6pt)
      A theme is a plain dictionary, so
      #v(4pt)
      #text(font: ("SF Mono", "Menlo", "DejaVu Sans Mono"), size: 12pt,
            fill: rgb("#c0491f"))[themes.lesson + (accent: blue)]
      #v(4pt)
      is already a valid one.
    ],
  )
}
