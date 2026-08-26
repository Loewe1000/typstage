// Manifesto — nach dem Manifesto-Deck des Pakets mosaic.
//
// Vorlage: „Minimalist White Slides" von SlidesCarnival
// (https://www.slidescarnival.com/), CC BY 4.0, bearbeitet; mosaic hat sie
// zuerst nach Typst geholt (docs-src/examples/decks/manifesto). Die
// Fotografien der Vorlage sind nicht übernommen; an ihrer Stelle stehen
// Duotonflächen aus reinem Typst — ein Plakat in einer Farbe verträgt keine
// zweite, und ein Foto brächte sie mit.
//
//   typst compile mosaic-manifesto.typ mosaic-manifesto.html --format html --features html
//   typst compile mosaic-manifesto.typ mosaic-manifesto.pdf
//
// Ein Plakat, kein Foliensatz: eine Schrift, eine Farbe, viel Weiß und
// Haarlinien. mosaics Theme setzt Schrift und Farbe einmal für das ganze Deck
// (`#set text(font: serif, fill: red)`); typstages Theme kann dasselbe, denn
// `ink` ist die Textfarbe des Decks und nicht bloß die des Fließtexts.
//
// Was die Vorlage nicht kann und dieses Deck tut: die drei Fragen der
// Vision-Folie treten einzeln vor und treten zurück, statt gemeinsam
// dazustehen. Ein Manifest behauptet nacheinander.

#import "@schule/typstage:0.1.0": *

// ── Zwei Farben, mehr hat das Deck nicht ───────────────────────────────────
#let cream = rgb("#fffcf9")
#let red = rgb("#c83224")

// ── Duotonflächen ──────────────────────────────────────────────────────────
// An der Stelle der Fotografien: Rot, Creme und die Zwischentöne dazwischen.
// Vier Kompositionen, alle in derselben Fläche, damit eine die andere
// vertreten kann.
#let tint = red.lighten(62%)
#let deep = red.darken(18%)

#let duotone(n) = block(width: 100%, height: 100%, clip: true, {
  let i = calc.rem(n, 4)
  place(top + left, rect(width: 100%, height: 100%,
                         fill: (tint, red, tint, deep).at(i)))
  if i == 0 {
    place(bottom + left, rect(width: 100%, height: 42%, fill: red))
    place(top + right, dx: -14%, dy: 16%, circle(radius: 34pt, fill: cream))
  } else if i == 1 {
    place(center + horizon, dy: 10pt, circle(radius: 54pt, fill: cream))
    place(bottom + left, rect(width: 100%, height: 14%, fill: deep))
  } else if i == 2 {
    for j in range(4) {
      place(top + left, dy: 12% + j * 20%,
            rect(width: 100%, height: 7%, fill: red))
    }
  } else {
    place(top + left, dx: -40pt, dy: -40pt, circle(radius: 90pt, fill: red))
    place(bottom + right, dx: -12%, dy: -14%, circle(radius: 26pt, fill: tint))
  }
})

/// Eine Fläche im roten Rahmen, wie ihn die Vorlage um ihre Bilder zieht.
#let plated(n) = rect(width: 100%, height: 100%, stroke: 1.5pt + red,
                      inset: 0pt, duotone(n))

// ── Typografie des Plakats ─────────────────────────────────────────────────
// Schrift und Farbe stehen im Theme; hier variiert nur die Größe, und bei den
// Titeln das Gewicht. Genau die Aufteilung, die mosaics Preamble trifft.
// Eng gesetzt: die Vorlage bricht ihre Titel über zwei und drei Zeilen, und
// bei der Zeilenweite des Fließtexts fielen sie auseinander.
#let title-text(body, size: 2.2em) = {
  set par(leading: 0.34em)
  text(size: size, weight: "bold", body)
}
#let body-text(body, size: 0.92em) = text(size: size, body)

#let copy = [Presentations turn ideas into clear stories for an audience.
They can inform, persuade, teach, or spark discussion.]

// ── Flächen ────────────────────────────────────────────────────────────────
#let plate(body, fill: cream, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

/// Die senkrechte Haarlinie, die auf der Vorlage Behauptung und Beleg trennt.
///
/// Sie zeichnet sich, statt einzublenden: sie ist keine Zier, sondern die
/// Geste des Decks — hier steht der Satz, dort steht, was ihn trägt. Eine
/// Linie, die entsteht, sagt das; eine, die da ist, sagt es nicht.
#let divider = anim(at: 2, enter: "draw", duration: 700, easing: "out-quad",
                    line(angle: 90deg, length: 100%, stroke: 0.8pt + red))

// ── Titelfolie und Abschnittsfolie als Theme-Funktionen ────────────────────
// mosaic hält beide im Theme (`layouts.title`, `layouts.section`), typstage
// auch: zwei Einträge im Wörterbuch, denen Theme, Folie und Geometrie gereicht
// werden. Damit bleibt `title:` am Deck stehen und `section(..)` schreibt sich
// im Fließtext.

#let cover(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: cream, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-title-slide-ground>]
  }
  place(horizon + left, dx: 45pt * k, block(width: geo.width - 90pt * k, {
    set par(leading: 0.34em)
    text(size: 52pt * k, weight: "bold", fill: red,
         [#s.title <ts-title-slide-title>])
    v(10pt * k)
    text(size: 16pt * k, fill: red,
         [#s.subtitle <ts-title-slide-subtitle>])
  }))
  place(bottom + left, dx: 45pt * k, dy: -45pt * k, {
    set rect(fill: red, stroke: none)
    [#rect(width: geo.width - 90pt * k, height: 1pt * k) <ts-title-slide-rule>]
  })
  place(bottom + right, dx: -45pt * k, dy: -55pt * k,
        text(size: 12pt * k, fill: red, [#s.author <ts-title-slide-byline>]))
}

/// Die rote Tafel: ganzflächig, ein Wort, ein Punkt.
///
/// Der Punkt hinter dem Wort ist nicht Zierde. Auf der Vorlage endet jede
/// Abschnittsüberschrift mit ihm, und er ist der Ton des ganzen Decks: hier
/// wird nicht angekündigt, hier wird festgestellt.
#let plate-section(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: red, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-section-slide-ground>]
  }
  place(horizon + left, dx: 48pt * k, block(width: geo.width - 96pt * k,
    text(size: 52pt * k, weight: "bold", fill: cream,
         [#s.title. <ts-section-slide-title>])))
}

// ── Das Theme ──────────────────────────────────────────────────────────────
// `ink` ist rot, nicht schwarz. Damit ist jedes Wort des Decks rot, ohne dass
// irgendwo eine Farbe wiederholt wird — dieselbe Wirkung, die mosaic mit einem
// einzigen `#set text(fill: red)` erreicht.
//
// Was hier fehlt und in der Vorlage steht: der Fortschrittsring in der Ecke.
// typstage kennt Balken, Randstreifen und Wandermarke, aber keinen Ring.
#let t = theme(
  paper: cream,
  ink: red,
  strong: red,
  accent: red,
  muted: red.lighten(28%),
  surface: cream,
  border: red,
  font: ("Iowan Old Style", "Charter", "Libertinus Serif"),
  size: 16pt,
  header: "plain",
  footer: "none",
  progress: "none",
  box: "label",
  head-gap: 0pt,
  foot-gap: 0pt,
  title-slide: cover,
  section: plate-section,
)

#presentation(
  theme: t,
  title: [Manifesto\ Presentation.],
  subtitle: [Nineteen white pages and one red],
  author: [after SlidesCarnival],
  date: [27 August 2026],
  margin: 0pt,
  // Weiße Seiten blenden ineinander wie umgeschlagene Blätter. Die roten
  // Tafeln unten tun ausdrücklich etwas anderes: sie werden gelegt.
  transition: "fade",
  transition-duration: 460,
  duration: 520,
  style: it => { set par(justify: false, leading: 0.66em); it },

  // ── 02 Der erste Satz ────────────────────────────────────────────────────
  slide(none, note: [Ein Satz, sonst nichts. Wer hier eine zweite Zeile
                     einzieht, hat das Deck nicht verstanden.])[
    #plate(align: center + horizon)[
      #block(width: 70%, std.align(center,
        title-text([Write a short introduction here.], size: 1.9em)))
    ]
  ],

  // ── 03 Inhalt ────────────────────────────────────────────────────────────
  slide(none)[
    #plate(inset: (left: 48pt), align: left + horizon)[
      #set enum(numbering: "1.", indent: 0pt, body-indent: 12pt, spacing: 0.9em)
      #text(size: 1.8em, weight: "bold")[
        + Introduction
        + About us
        + Our projects
        + Chapter title
        + Chapter title
      ]
    ]
  ],

  // ── 04 Abschnitt ─────────────────────────────────────────────────────────
  // „cover" von unten: die rote Tafel wird über die weiße Seite gelegt, und
  // rückwärts wieder abgehoben. Auf einer weißen Seite, die sonst nur
  // überblendet, ist das der einzige Griff im Deck, den man als Griff sieht.
  section([Introduction], transition: (kind: "cover", from: "bottom")),

  // ── 05 Willkommen ────────────────────────────────────────────────────────
  slide(none)[
    #bands((1fr, 0.72fr),
      plate(inset: (left: 48pt, right: 24pt), align: left + horizon)[
        #title-text([Welcome to\ presentation], size: 2.05em)
        #v(12pt)
        #body-text([I'm Rain, and I'll be sharing with you my beautiful ideas.
                    Follow me at \@reallygreatsite to learn more. #copy])
      ],
      plate(inset: (top: 44pt, right: 48pt, bottom: 38pt), plated(1)),
    )
  ],

  // ── 06 Drei Fragen ───────────────────────────────────────────────────────
  slide(none, note: [Drei Tastendrücke. Die vorige Frage bleibt gedimmt
                     stehen, damit die Reihe sichtbar bleibt — sie ist eine
                     Reihe und keine Liste.])[
    #bands((0.95fr, 4pt, 1fr),
      plate(inset: 48pt, align: left + horizon)[
        #set par(leading: 0.28em)
        #title-text([Our company was\ created with the\ vision to be the best\
                     in the industry.], size: 1.85em)
      ],
      // Die Trennlinie, die sich zieht.
      plate(align: center + horizon, divider),
      plate(inset: (left: 28pt, right: 45pt), align: left + horizon)[
        // `dim: true`: jede Frage hält genau ihren Schritt und bleibt danach
        // gedimmt stehen. Das ist nicht dasselbe wie eine Aufzählung, die
        // sich füllt — hier ist immer *eine* Frage die, um die es gerade
        // geht, und die anderen sind der Weg dorthin.
        #stagger(dim: true, enter: "fade-up", spacing: 1.4em,
          ..(
            ([Who we are?], [Introduce the people behind the work.]),
            ([What we do?], [Describe the value your company creates.]),
            ([Why we do it?], [Explain the purpose that guides the team.]),
          ).map(q => block(width: 100%, {
            block(above: 0pt, below: 0.35em, title-text(q.first(), size: 1.1em))
            body-text(q.last(), size: 0.82em)
          })),
        )
      ],
    )
  ],

  // ── 07 Abschnitt ─────────────────────────────────────────────────────────
  section([About us], transition: (kind: "cover", from: "bottom")),

  // ── 08 Auftrag und Absicht ───────────────────────────────────────────────
  slide(none)[
    #bands((1fr, 1fr),
      plate(inset: 45pt, align: left + horizon)[
        #std.align(center, title-text([Mission], size: 2.05em))
        #v(16pt)
        #body-text(copy)
      ],
      plate(fill: red, inset: 45pt, align: left + horizon)[
        #std.align(center, text(size: 2.05em, weight: "bold", fill: cream)[Vision])
        #v(16pt)
        #text(size: 0.92em, fill: cream, copy)
      ],
    )
  ],

  // ── 09 Abschnitt ─────────────────────────────────────────────────────────
  section([Our projects], transition: (kind: "cover", from: "bottom")),

  // ── 10 Zahlen ────────────────────────────────────────────────────────────
  slide(none, note: [Eine Zahl je Tastendruck. Ein Plakat legt seine Zahlen
                     hin, es reicht sie nicht als Tabelle herum.])[
    #bands((1.05fr, 4pt, 0.91fr),
      plate(inset: 48pt, align: left + horizon)[
        #title-text([Market research], size: 2.05em)
        #v(12pt)
        #body-text(copy)
      ],
      plate(align: center + horizon, divider),
      plate(inset: 44pt, align: left + horizon)[
        // „rise" mit „out-back": die Zahl kommt von unten, schießt einen Hauch
        // über ihren Platz hinaus und setzt sich. Der lauteste Effekt des
        // Pakets, und hier ist er richtig — die drei Zahlen sind das
        // Lauteste, was diese Folie zu sagen hat.
        #stagger(enter: "rise", easing: "out-back", duration: 620,
                 spacing: 1.6em, start: 2,
          ..(([+88%], [Elaborate on the statistic here.]),
             ([+400k], [Elaborate on the statistic here.]),
             ([−12%], [Elaborate on the statistic here.]))
            .map(pair => block(width: 100%, {
              block(above: 0pt, below: 0.3em,
                    title-text(pair.first(), size: 1.75em))
              body-text(pair.last(), size: 0.82em)
            })),
        )
      ],
    )
  ],

  // ── 11 Die Kurve ─────────────────────────────────────────────────────────
  slide(none, note: [Erst das Feld, dann die Kurve, dann die Marke. Drei
                     Stufen, und die dritte ist die Behauptung.])[
    #plate(inset: (top: 42pt, left: 48pt, right: 48pt, bottom: 34pt))[
      #title-text([Market research], size: 2.05em)
      #v(4pt)
      #body-text(copy)
      #v(18pt)
      // `build` statt `anim`: eine Zeichnung ist ein Stück, nicht viele. Die
      // Funktion wird je Stufe einmal gerufen und bekommt gefragt, was schon
      // fällig ist; was noch nicht fällig ist, wird aus Luft gesetzt und
      // nimmt trotzdem seinen Platz ein. Deshalb wackelt nichts, wenn die
      // Kurve dazukommt.
      #build(from => block(width: 100%, height: 210pt, {
        let w = 100%
        // Achsen: von Anfang an da.
        place(bottom + left, line(length: w, stroke: 0.8pt + red))
        place(bottom + left,
              line(angle: -90deg, length: 100%, stroke: 0.8pt + red))
        // Die Kurve ab Stufe zwei. `from(2, red)` gibt auf Stufe eins
        // dieselbe Farbe ohne Deckkraft zurück, nicht `none`: die Kurve wird
        // also gesetzt und gemessen, sie ist nur nicht zu sehen.
        place(bottom + left, curve(
          stroke: 2pt + from(2, red),
          curve.move((4%, -12%)),
          curve.line((22%, -26%)),
          curve.line((40%, -20%)),
          curve.line((58%, -46%)),
          curve.line((76%, -58%)),
          curve.line((94%, -84%)),
        ))
        // Und die Marke ab Stufe drei.
        place(bottom + left, dx: 74%, dy: -84%,
              from(3, block(inset: 6pt, fill: cream,
                            title-text([+88%], size: 1.15em))))
      }), steps: 3)
    ]
  ],

  // ── 12 Zitat ─────────────────────────────────────────────────────────────
  slide(none, note: [Nichts bewegt sich. Ein Zitat, das hereinkommt, ist ein
                     Zitat, dem man beim Kommen zusieht statt es zu lesen.])[
    #plate(align: center + horizon)[
      #std.align(center)[
        #title-text([“], size: 2.8em)
        #v(-14pt)
        #title-text([Write an original statement or\ inspiring quote.],
                    size: 1.9em)
        #v(12pt)
        #body-text([Include a credit, citation, or supporting message],
                   size: 0.85em)
      ]
    ]
  ],

  // ── 13 Kontakt ───────────────────────────────────────────────────────────
  slide(none)[
    #plate(inset: 48pt, align: left + horizon)[
      #title-text([Contact us], size: 2.05em)
      #v(16pt)
      #body-text([
        123 Anywhere St., Any City, ST 12345 \
        123-456-7890 \
        hello\@reallygreatsite.com \
        reallygreatsite.com \
        \@reallygreatsite
      ])
    ]
  ],
)
