// Clean Minimal — nach dem Editorial-Deck des Pakets mosaic.
//
// Vorlage: „Cream, Green, and Black Geometric Blocks Clean Minimal
// Presentation" von SlidesCarnival (https://www.slidescarnival.com/), CC BY
// 4.0, bearbeitet; mosaic hat sie zuerst nach Typst geholt
// (docs-src/examples/decks/editorial). Die Fotografien der Vorlage sind hier
// nicht übernommen — an ihrer Stelle stehen geometrische Tafeln aus reinem
// Typst. Die Vorlage heißt „Geometric Blocks"; sie verträgt das.
//
//   typst compile mosaic-editorial.typ mosaic-editorial.html --format html --features html
//   typst compile mosaic-editorial.typ mosaic-editorial.pdf
//
// mosaic baut dieses Deck aus benannten Zellen und malt sie mit `styled(..)`
// an. typstage hat keine Zellen. An ihrer Stelle stehen `margin: 0pt`, ein
// Theme, das von sich aus nichts zeichnet, und `plate(..)` unten — die
// Entsprechung zu mosaics `surface(..)`. Der Rand liegt damit im Inhalt, wie
// dort auch.
//
// Was die Vorlage nicht kann und dieses Deck tut: die erste Zeile der Agenda
// fliegt auf die Abschnittsfolie und wird dort zur Überschrift. Auf Papier
// muss man dem Publikum sagen, wo man ist; hier sieht man es.

#import "@schule/typstage:0.1.0": *

// ── Farben ─────────────────────────────────────────────────────────────────
// Wörtlich die vier der Vorlage. Weiß auf Salbei misst 1,96 zu 1 und wäre für
// Fließtext zu wenig; die Vorlage setzt es trotzdem, und für die großen
// Versalien bleibt es hier stehen.
#let cream = rgb("#f2eee5")
#let sage = rgb("#aebdb3")
#let ink = rgb("#111111")
#let white = rgb("#f9f8f3")

// ── Die Tafeln ─────────────────────────────────────────────────────────────
// Wo die Vorlage fotografiert, wird hier gezeichnet. Sechs Kompositionen aus
// Kreis, Balken und Bogen in den warmen Tönen des Decks: nah genug an den
// Innenraum-Aufnahmen der Vorlage, um an ihrer Stelle zu stehen, und weit
// genug von ihnen weg, um nichts vorzugeben.

#let sand = rgb("#d8cbb8")
#let clay = rgb("#b5715a")
#let rose = rgb("#cbb0a2")
#let shell = rgb("#efe9e0")

/// Eine Tafel: Grundton, darauf zwei bis drei Formen, hart beschnitten.
///
/// `n` wählt die Komposition. Alle sechs füllen dieselbe Fläche, damit eine
/// Tafel eine andere ersetzen kann, ohne dass daneben etwas rückt.
#let plate-art(n) = block(width: 100%, height: 100%, clip: true, {
  let i = calc.rem(n, 6)
  place(top + left, rect(width: 100%, height: 100%,
                         fill: (shell, sand, rose, shell, sand, rose).at(i)))
  if i == 0 {
    // Eine Scheibe über einer Kante.
    place(top + right, dx: -18pt, dy: 34pt, circle(radius: 46pt, fill: clay))
    place(bottom + left, rect(width: 100%, height: 26%, fill: sand))
  } else if i == 1 {
    // Ein Torbogen: ein Rechteck, dem oben die Ecken genommen sind. Als
    // Kreis auf einem Rechteck sah es aus wie ein Streichholz.
    place(bottom + center, dy: -14%, rect(
      width: 44%, height: 60%, fill: shell,
      radius: (top-left: 100%, top-right: 100%),
    ))
    place(bottom + left, dy: -8%, line(length: 100%, stroke: 1pt + clay))
  } else if i == 2 {
    // Zwei Scheiben, die sich überschneiden.
    place(center + horizon, dx: -22pt, circle(radius: 50pt, fill: shell))
    place(center + horizon, dx: 24pt, dy: 14pt,
          circle(radius: 36pt, stroke: 1.2pt + ink))
  } else if i == 3 {
    // Gestapelte Bänder, wie ein Regal von der Seite.
    for (j, h) in (14%, 9%, 20%).enumerate() {
      place(top + left, dy: 16% + j * 22%,
            rect(width: 100%, height: h, fill: (clay, sand, rose).at(j)))
    }
  } else if i == 4 {
    // Viertelscheibe in der Ecke, dazu eine hohe schmale Form.
    place(top + left, dx: -58pt, dy: -58pt, circle(radius: 116pt, fill: rose))
    place(bottom + right, dx: -34pt, rect(width: 16%, height: 52%, fill: ink))
  } else {
    // Eine Vase auf einem Tisch: unten breit, oben schmal, mit einer Scheibe
    // darüber, die das Licht sein darf.
    place(bottom + center, dy: -18%, rect(
      width: 22%, height: 30%, fill: shell,
      radius: (top-left: 60%, top-right: 60%, bottom: 12pt),
    ))
    place(top + right, dx: -22%, dy: 16%, circle(radius: 30pt, fill: sand))
    place(bottom + left, rect(width: 100%, height: 18%, fill: clay))
  }
})

// ── Flächen ────────────────────────────────────────────────────────────────

/// Eine ganze Fläche in einer Farbe, mit ihrem eigenen Rand.
///
/// Das Gegenstück zu mosaics `surface(fill: .., inset: .., align: ..)`: dort
/// trägt die Zelle den Rand, hier der Inhalt. Dasselbe Rechteck.
#let plate(body, fill: sage, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

/// Zwei Flächen nebeneinander, ohne Fuge.
///
/// `grid` und nicht `side-by-side`: die Vorlage lebt davon, dass die Farben
/// aneinanderstoßen. Eine Fuge, und sei sie klein, machte aus zwei Feldern
/// zwei Kästen.
#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

/// Die dünne weiße Linie, die auf der Vorlage über der halben Folie liegt.
#let framed(body) = block(width: 100%, height: 100%, {
  place(top + left, body)
  place(top + left, dx: 14pt, dy: 14pt,
        rect(width: 100% - 28pt, height: 100% - 28pt, stroke: 0.8pt + white))
})

/// Eine Überschrift im Ton der Vorlage: Versalien, fett, ohne Zierlinie.
#let head(body, size: 2.1em, fill: ink) = text(
  size: size, weight: "bold", fill: fill, upper(body),
)

/// Eine kleine Rubrik, wie sie über den Rastern der Vorlage steht.
#let rubric(title, body) = block(width: 100%, {
  block(above: 0pt, below: 0.45em, text(weight: "bold", size: 1.05em, title))
  text(size: 0.86em, body)
})

#let filler = [Elaborate on your topic here. Lorem ipsum dolor sit amet,
consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et
dolore magna aliqua.]

// ── Die Titelfolie als Theme-Funktion ──────────────────────────────────────
// mosaic legt die Titelfolie ins Theme (`layouts.title`), und typstage tut
// dasselbe: `title-slide` ist ein Eintrag im Wörterbuch und bekommt Theme,
// Folie und Geometrie gereicht. So bleibt `title:` am Deck stehen, statt in
// eine handgebaute erste Folie auszuwandern, wo weder Browsertitel noch
// Sprecheransicht sie fänden.
#let cover(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: cream, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-title-slide-ground>]
  }
  place(top + right, block(width: 38%, height: 100%, inset: (
    top: 28pt * k, right: 28pt * k, bottom: 28pt * k,
  ), plate-art(1)))
  place(horizon + left, dx: 42pt * k, block(width: 62% - 84pt * k, {
    std.align(center, {
      text(size: 46pt * k, weight: "bold", fill: ink,
           [#upper(s.title) <ts-title-slide-title>])
      v(10pt * k)
      text(size: 15pt * k, fill: ink.lighten(35%),
           [#s.subtitle <ts-title-slide-subtitle>])
    })
    v(26pt * k)
    // Die Linie unter dem Titel zeichnet sich selbst. Sie ist das einzige
    // Ornament der Folie; sie darf einen Wimpernschlag brauchen.
    anim(at: 2, enter: "draw", duration: 900, easing: "out-quad",
         line(length: 100%, stroke: 1pt + ink))
  }))
}

// ── Das Theme, das sich heraushält ─────────────────────────────────────────
// Kein Kopfband, keine Fußzeile, kein Balken: mosaic setzt für dieses Deck
// `foreground: none` und nimmt dem Theme damit die Seitenzahl. Hier tun
// dieselbe Arbeit drei Wörter und zwei Nullen — `head-gap` und `foot-gap` auf
// 0pt, damit der Körper wirklich bis an den Schnitt reicht.
#let t = theme(
  paper: cream,
  ink: ink,
  strong: sage,
  // Keine Signalfarbe: dieses Deck kennt Creme, Salbei und Tinte, sonst
  // nichts. Der „Akzent" ist deshalb die Tinte selbst.
  accent: ink,
  muted: ink.lighten(42%),
  surface: cream,
  border: ink,
  font: ("Inter", "Helvetica Neue", "Arial", "DejaVu Sans"),
  size: 15pt,
  header: "plain",
  footer: "none",
  progress: "none",
  box: "label",
  head-gap: 0pt,
  foot-gap: 0pt,
  title-slide: cover,
)

#presentation(
  theme: t,
  title: [Clean Minimal],
  subtitle: [A template from mosaic, taught to move],
  author: [after SlidesCarnival],
  date: [27 August 2026],
  // Randlos. Alles, was hier wie ein Rand aussieht, ist Inhalt — genau wie bei
  // mosaic, wo die Zelle `inset: 0pt` bekommt und `surface()` den Rand trägt.
  margin: 0pt,
  // „cover": die neue Folie legt sich über die alte, die stehenbleibt. Ein
  // Deck aus rechteckigen Farbfeldern schiebt keine Folien, es legt Karten
  // aufeinander.
  transition: "cover",
  transition-duration: 520,
  duration: 560,
  // Der Stil-Haken erreicht auch die Flieger des Morphs. Was hier nicht steht,
  // sieht ein getracktes Element nie.
  style: it => { set par(justify: false, leading: 0.62em); it },

  // ── 02 Agenda ────────────────────────────────────────────────────────────
  slide(none, note: [Die drei Punkte stehen auf einmal da. Wer eine
                     Inhaltsübersicht tröpfeln lässt, lässt das Publikum auf
                     etwas warten, was es mit einem Blick braucht.])[
    #bands((0.55fr, 0.45fr),
      plate(fill: cream, inset: 42pt)[
        #head([Agenda])
        #v(18pt)
        #stack(dir: ttb, spacing: 0pt,
          ..(([1], [Introduction]), ([2], [About us]), ([3], [Our projects]))
            .enumerate()
            .map(((i, row)) => block(
              width: 100%, stroke: (bottom: 0.8pt + ink),
              inset: (x: 4pt, y: 15pt),
              grid(columns: (46pt, 1fr),
                align: (left + horizon, left + horizon),
                // Nur die erste Zeile fliegt weiter. Zahl und Wort tragen je
                // einen Namen, damit auf der nächsten Folie jedes an seinen
                // Platz findet, statt nach Gestalt gepaart zu werden.
                if i == 0 {
                  morph(<agenda-no>,
                        text(size: 2em, weight: "bold", fill: ink, row.first()))
                } else {
                  text(size: 2em, weight: "bold", row.first())
                },
                if i == 0 {
                  morph(<agenda-word>, text(size: 1em, weight: "bold",
                                            fill: ink, upper(row.last())))
                } else {
                  text(weight: "bold", upper(row.last()))
                },
              ),
            )),
        )
      ],
      plate(fill: cream, plate-art(4)),
    )
  ],

  // ── 03 Abschnitt: Introduction ───────────────────────────────────────────
  slide(none, note: [Hier landet die erste Agendazeile. Nicht erklären, dass
                     sie geflogen ist — man sieht es.])[
    #framed(bands((0.56fr, 0.44fr),
      plate(fill: sage, inset: 70pt)[
        #v(1fr)
        // Dieselben zwei Namen wie auf der Agenda, in anderer Größe und an
        // anderem Ort. Mehr braucht ein Magic Move nicht. Wo ein Morph über
        // die Folienkante geht, tritt „cover" zurück und die beiden Folien
        // blenden ineinander — sonst führe der Flieger mit der alten Folie
        // aus dem Bild.
        #morph(<agenda-no>, text(size: 1.1em, weight: "bold", fill: white)[1])
        #v(6pt)
        #morph(<agenda-word>,
               text(size: 2.6em, weight: "bold", fill: white)[INTRODUCTION])
        #v(14pt)
        #text(size: 0.92em, fill: white)[Elaborate on your topic here.]
        #v(1fr)
      ],
      plate(fill: sage, plate-art(0)),
    ))
  ],

  // ── 04 Welcome ───────────────────────────────────────────────────────────
  slide(none)[
    #framed(bands((1fr, 1fr),
      plate(fill: sage, inset: 45pt)[
        #v(1fr)
        #block(width: 62%, height: 150pt, plate-art(5))
        #v(22pt)
        #text(size: 0.92em, fill: white)[
          I'm Rain, and I'll be sharing with you my beautiful ideas. Follow me
          at \@reallygreatsite to learn more.
        ]
        #v(1fr)
      ],
      plate(fill: sage, inset: 28pt)[
        #head([Welcome to\ presentation], size: 2.1em, fill: white)
        #v(25pt)
        #block(width: 100%, height: 56%, plate-art(2))
      ],
    ))
  ],

  // ── 05 Topic ─────────────────────────────────────────────────────────────
  slide(none)[
    #framed(bands((0.54fr, 0.46fr),
      plate(fill: sage, inset: 42pt)[
        #head([Topic], fill: white)
        #v(28pt)
        #text(size: 0.92em, fill: white, filler)
      ],
      plate(fill: sage, plate-art(3)),
    ))
  ],

  // ── 06 Vier Themen ───────────────────────────────────────────────────────
  slide(none, note: [Ein Tastendruck, vier Felder. Die Welle läuft in
                     Leserichtung, sonst wäre sie nur Zappeln.])[
    #framed(plate(fill: sage, inset: 34pt,
      grid(columns: (0.34fr, 1fr), column-gutter: 16pt, rows: (100%,),
        plate-art(1),
        // `stride: 0`: alle vier auf einem Schritt, versetzt nur in
        // Millisekunden. Vier Tastendrücke für vier gleichrangige Felder
        // machten aus einer Übersicht eine Aufzählung.
        tiles(columns: 2, gutter: 22pt, row-gutter: 18pt,
              stride: 0, stagger: 90, enter: "fade-up",
          ..range(1, 5).map(n => text(fill: white, rubric(
            [Topic #n],
            [Elaborate on your topic here. Lorem ipsum dolor sit amet,
             consectetur adipiscing elit, sed do eiusmod tempor.],
          ))),
        ),
      ),
    ))
  ],

  // ── 07 About us ──────────────────────────────────────────────────────────
  slide(none, note: [Der Kreis zeichnet sich. Das ist neben der Titellinie die
                     einzige Kontur im Deck, die entsteht statt einzublenden —
                     deshalb fällt sie auf.])[
    #bands((0.62fr, 0.38fr),
      plate(fill: cream, inset: 25pt, align: center + horizon)[
        // `enter: "draw"` braucht eine gezeichnete Kontur, und dieser Kreis
        // ist nichts anderes als eine. Der Text steht darin, ohne zu warten:
        // er ist die Aussage, der Kreis ist der Rahmen um sie.
        #block(width: 330pt, height: 330pt, {
          place(center + horizon, anim(
            at: 2, enter: "draw", duration: 1100, easing: "out-quad",
            circle(radius: 160pt, stroke: 1pt + ink),
          ))
          place(center + horizon, block(width: 230pt, std.align(center)[
            #head([About~us], size: 1.9em)
            #v(6pt)
            #text(size: 0.9em)[Elaborate on your topic here.]
          ]))
        })
      ],
      plate(fill: cream, plate-art(2)),
    )
  ],

  // ── 08 Topic 2 ───────────────────────────────────────────────────────────
  slide(none)[
    #bands((1fr, 1fr),
      plate(fill: cream, plate-art(0)),
      plate(fill: cream, inset: 30pt, align: horizon)[
        #head([Topic 2])
        #v(14pt)
        #text(size: 0.92em, filler)
      ],
    )
  ],

  // ── 09 Das Team ──────────────────────────────────────────────────────────
  slide(none)[
    #plate(fill: cream, inset: 20pt)[
      #v(1fr)
      #std.align(center, head([The team], size: 1.9em))
      #v(16pt)
      #tiles(columns: 4, gutter: 14pt, stride: 0, stagger: 70, enter: "fade-up",
        ..(([Jane Doe], [Director]), ([Jane Doe], [Marketing]),
           ([John Doe], [Sales]), ([Jane Doe], [PR]))
          .enumerate()
          .map(((i, p)) => rect(
            height: 230pt, stroke: 0.7pt + luma(50%), inset: 0pt,
            block(width: 100%, height: 100%, {
              block(width: 100%, height: 130pt, plate-art(i + 2))
              pad(x: 10pt, top: 9pt, std.align(center)[
                #text(weight: "bold", size: 0.95em, p.first())
                #linebreak()
                #text(size: 0.72em)[#p.last()]
              ])
            }),
          )),
      )
      #v(1fr)
    ]
  ],

  // ── 10 Ein Bild sagt mehr ────────────────────────────────────────────────
  slide(none, note: [Kurz stehen lassen. Der Streifen ist der Witz der Folie,
                     und er braucht eine Sekunde.])[
    #block(width: 100%, height: 100%, {
      place(top + left, plate-art(3))
      place(top + left, dx: 42%, block(width: 30pt, height: 100%, fill: cream,
        std.align(center + horizon, rotate(90deg, reflow: false, box(
          width: 500pt,
          std.align(center, text(fill: ink, size: 0.95em)[
            A picture is worth a thousand words
          ]),
        ))),
      ))
    })
  ],

  // ── 11 Marktforschung ────────────────────────────────────────────────────
  slide(none, note: [Die Scheiben wachsen auf ihre Größe. Wer 28, 60 und 100
                     nur hinstellt, verlangt einen Vergleich; wer sie wachsen
                     lässt, führt ihn vor.])[
    #framed(bands((0.78fr, 0.22fr),
      plate(fill: sage, inset: 22pt, align: center)[
        #v(14pt)
        #head([Market research], size: 1.9em, fill: white)
        #v(4pt)
        #text(size: 0.85em, fill: white)[Elaborate on the featured statistics.]
        #v(22pt)
        // Alle drei auf Schritt 2, versetzt über `delay`, und jede wächst aus
        // ihrer eigenen Mitte: der Größenunterschied entsteht vor dem Auge,
        // statt fertig dazustehen. Das ist die Zahl selbst, in Bewegung
        // übersetzt. Nicht `tiles`, weil dort weder `easing` noch `duration`
        // durchgereicht wird und der Überschwung von „out-back" die halbe
        // Wirkung ist.
        #grid(columns: (1fr, 1fr, 1fr), column-gutter: 30pt, align: bottom,
          ..((28, [28%]), (60, [60%]), (100, [100%])).enumerate().map(((i, s)) => {
            let r = 60pt * s.first() / 100
            anim(
              at: 2, enter: "scale", easing: "out-back", duration: 700,
              delay: i * 130,
              std.align(center, {
                box(height: 128pt, std.align(center + bottom, circle(
                  radius: r, fill: white,
                  // Nicht `r * 0.52` allein: bei 28 Prozent wäre die Zahl
                  // neun Punkt groß und die Scheibe leer. Der Kreis trägt
                  // den Vergleich, die Zahl muss nur lesbar bleiben.
                  std.align(center + horizon,
                            text(size: calc.max(r * 0.52, 13pt),
                                 weight: "bold", fill: ink, s.last())),
                )))
                v(10pt)
                text(size: 0.7em, fill: white)[Elaborate here.]
              }),
            )
          }),
        )
      ],
      plate(fill: sage, plate-art(5)),
    ))
  ],

  // ── 12 Kontakt ───────────────────────────────────────────────────────────
  slide(none)[
    #framed(bands((0.46fr, 0.54fr),
      plate(fill: sage, plate-art(4)),
      plate(fill: sage, inset: 44pt, align: horizon)[
        #head([Contact us], fill: white)
        #v(12pt)
        #text(size: 0.92em, fill: white)[
          123 Anywhere St., Any City, ST 12345 \
          123-456-7890 \
          hello\@reallygreatsite.com \
          reallygreatsite.com \
          \@reallygreatsite
        ]
      ],
    ))
  ],
)
