// Manifesto — after the Manifesto deck of the mosaic package.
//
// Source: the "Minimalist White Slides" template by SlidesCarnival
// (https://www.slidescarnival.com/), CC BY 4.0, adapted; mosaic brought it to
// Typst first (docs-src/examples/decks/manifesto). The template's photographs
// are not carried over; duotone surfaces drawn in plain Typst stand in their
// place — a poster in one colour cannot take a second one, and a photograph
// would bring one along.
//
//   typst compile mosaic-manifesto.typ mosaic-manifesto.html --format html --features html
//   typst compile mosaic-manifesto.typ mosaic-manifesto.pdf
//
// A poster, not a slide deck: one typeface, one colour, a lot of white and
// hairlines. mosaic's theme sets face and colour once for the whole deck
// (`#set text(font: serif, fill: red)`); typstage's theme does the same,
// because `ink` is the deck's text colour and not merely the body's.
//
// What the template cannot do and this deck does: the three questions on the
// vision slide step forward one at a time and step back again instead of
// standing there together. A manifesto asserts in sequence.

#import "@preview/typstage:0.1.0": *

// ── Two colours; the deck has no more ──────────────────────────────────────
#let cream = rgb("#fffcf9")
#let red = rgb("#c83224")

// ── Duotone surfaces ───────────────────────────────────────────────────────
// In place of the photographs: red, cream and the tints between them. Four
// compositions, all in the same area, so one can stand in for another.
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

/// A surface in the red keyline the template draws around its pictures.
#let plated(n) = rect(width: 100%, height: 100%, stroke: 1.5pt + red,
                      inset: 0pt, duotone(n))

// ── The poster's typography ────────────────────────────────────────────────
// Face and colour live in the theme; here only the size varies, and for the
// titles the weight. Exactly the division mosaic's preamble makes.
// Set tight: the template breaks its titles over two and three lines, and at
// the body's leading they would fall apart.
#let title-text(body, size: 2.2em) = {
  set par(leading: 0.34em)
  text(size: size, weight: "bold", body)
}
#let body-text(body, size: 0.92em) = text(size: size, body)

#let copy = [Presentations turn ideas into clear stories for an audience.
They can inform, persuade, teach, or spark discussion.]

// ── Surfaces ───────────────────────────────────────────────────────────────
#let plate(body, fill: cream, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

/// The vertical hairline that separates claim from evidence in the template.
///
/// It draws itself rather than fading in: it is not ornament but the deck's
/// gesture — here stands the sentence, there stands what carries it. A rule
/// that comes into being says that; one that is simply there does not.
#let divider = anim(at: 2, enter: "draw", duration: 700, easing: "out-quad",
                    line(angle: 90deg, length: 100%, stroke: 0.8pt + red))

// ── Title slide and section slide as theme functions ───────────────────────
// mosaic keeps both in the theme (`layouts.title`, `layouts.section`), and so
// does typstage: two entries in the dictionary, handed the theme, the slide
// and the geometry. That way `title:` stays with the deck and `section(..)`
// writes itself in the flow.

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

/// The red plate: full bleed, one word, one full stop.
///
/// The stop after the word is not decoration. In the template every section
/// heading ends with it, and it is the tone of the whole deck: nothing is
/// announced here, things are stated.
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

// ── The theme ──────────────────────────────────────────────────────────────
// `ink` is red, not black. Every word of the deck is therefore red without a
// colour being repeated anywhere — the same effect mosaic gets from a single
// `#set text(fill: red)`.
//
// What is missing here and stands in the template: the progress ring in the
// corner. typstage knows a bar, a top edge and a travelling marker, but no
// ring.
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
  // Keine Zahl mehr. Es stand "Nineteen white pages and one red" ueber einem
  // Deck aus dreizehn Blaettern, von denen drei von Rand zu Rand rot sind --
  // die erste Zeile, die ein Besucher liest, und in beiden Zahlen falsch.
  subtitle: [White plates, and red where it interrupts],
  author: [after SlidesCarnival],
  date: [27 August 2026],
  margin: 0pt,
  // White pages cross-fade like turned leaves. The red plates below do
  // something else on purpose: they are laid down.
  transition: "fade",
  transition-duration: 460,
  duration: 520,
  style: it => { set par(justify: false, leading: 0.66em); it },

  // ── 02 The first sentence ────────────────────────────────────────────────
  slide(none, note: [One sentence and nothing else. Anyone who pulls in a
                     second line here has not understood the deck.])[
    #plate(align: center + horizon)[
      #block(width: 70%, std.align(center,
        title-text([Write a short introduction here.], size: 1.9em)))
    ]
  ],

  // ── 03 Contents ──────────────────────────────────────────────────────────
  slide(none)[
    #plate(inset: (left: 48pt), align: left + horizon)[
      #set enum(numbering: "1.", indent: 0pt, body-indent: 12pt, spacing: 0.9em)
      #text(size: 1.8em, weight: "bold")[
        + Introduction
        + About us
        + Our projects
      ]
    ]
  ],

  // ── 04 Section ───────────────────────────────────────────────────────────
  // "cover" from below: the red plate is laid over the white page, and lifted
  // off again on the way back. In a deck of white pages that otherwise only
  // cross-fade, this is the one handling one actually sees as handling.
  section([Introduction], transition: (kind: "cover", from: "bottom")),

  // ── 05 Welcome ───────────────────────────────────────────────────────────
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

  // ── 06 Three questions ───────────────────────────────────────────────────
  slide(none, note: [Three keypresses. The previous question stays, dimmed, so
                     that the sequence remains visible — it is a sequence and
                     not a list.])[
    #bands((0.95fr, 4pt, 1fr),
      plate(inset: 48pt, align: left + horizon)[
        #set par(leading: 0.28em)
        #title-text([Our company was\ created with the\ vision to be the best\
                     in the industry.], size: 1.85em)
      ],
      // The dividing rule, drawing itself.
      plate(align: center + horizon, divider),
      plate(inset: (left: 28pt, right: 45pt), align: left + horizon)[
        // `dim: true`: each question holds exactly its own step and then
        // stays on, dimmed. That is not the same as a list filling up — here
        // exactly *one* question is the one at issue, and the others are the
        // way there.
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

  // ── 07 Section ───────────────────────────────────────────────────────────
  section([About us], transition: (kind: "cover", from: "bottom")),

  // ── 08 Mission and vision ────────────────────────────────────────────────
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

  // ── 09 Section ───────────────────────────────────────────────────────────
  section([Our projects], transition: (kind: "cover", from: "bottom")),

  // ── 10 Numbers ───────────────────────────────────────────────────────────
  slide(none, note: [One number per keypress. A poster puts its numbers down;
                     it does not hand them round as a table.])[
    #bands((1.05fr, 4pt, 0.91fr),
      plate(inset: 48pt, align: left + horizon)[
        #title-text([Market research], size: 2.05em)
        #v(12pt)
        #body-text(copy)
      ],
      plate(align: center + horizon, divider),
      plate(inset: 44pt, align: left + horizon)[
        // "rise" with "out-back": the number comes from below, overshoots
        // its place by a hair and settles. The loudest effect in the package,
        // and right here — those three numbers are the loudest thing this
        // slide has to say.
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

  // ── 11 The curve ─────────────────────────────────────────────────────────
  slide(none, note: [First the field, then the curve, then the mark. Three
                     stages, and the third one is the claim.])[
    #plate(inset: (top: 42pt, left: 48pt, right: 48pt, bottom: 34pt))[
      #title-text([Market research], size: 2.05em)
      #v(4pt)
      #body-text(copy)
      #v(18pt)
      // `build` rather than `anim`: a drawing is one piece, not many. The
      // function is called once per stage and asked what is already due;
      // whatever is not yet due is set out of air and still takes up its
      // room. That is why nothing shifts when the curve arrives.
      #build(from => block(width: 100%, height: 210pt, {
        let w = 100%
        // Axes: there from the start.
        place(bottom + left, line(length: w, stroke: 0.8pt + red))
        place(bottom + left,
              line(angle: -90deg, length: 100%, stroke: 0.8pt + red))
        // The curve from stage two. On stage one `from(2, red)` hands back
        // the same colour with no opacity, not `none`: the curve is set and
        // measured, it just cannot be seen.
        place(bottom + left, curve(
          stroke: 2pt + from(2, red),
          curve.move((4%, -12%)),
          curve.line((22%, -26%)),
          curve.line((40%, -20%)),
          curve.line((58%, -46%)),
          curve.line((76%, -58%)),
          curve.line((94%, -84%)),
        ))
        // And the mark from stage three.
        place(bottom + left, dx: 74%, dy: -84%,
              from(3, block(inset: 6pt, fill: cream,
                            title-text([+88%], size: 1.15em))))
      }), steps: 3)
    ]
  ],

  // ── 12 Quote ─────────────────────────────────────────────────────────────
  slide(none, note: [Nothing moves. A quotation that comes in is a quotation
                     one watches arrive instead of reading.])[
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

  // ── 13 Contact ───────────────────────────────────────────────────────────
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
