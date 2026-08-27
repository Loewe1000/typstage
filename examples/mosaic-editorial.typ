// Clean Minimal — after the Editorial deck of the mosaic package.
//
// Source: the "Cream, Green, and Black Geometric Blocks Clean Minimal
// Presentation" template by SlidesCarnival (https://www.slidescarnival.com/),
// CC BY 4.0, adapted; mosaic brought it to Typst first
// (docs-src/examples/decks/editorial). The template's photographs are not
// carried over — geometric plates drawn in plain Typst stand in their place.
// The template is called "Geometric Blocks"; it can take it.
//
//   typst compile mosaic-editorial.typ mosaic-editorial.html --format html --features html
//   typst compile mosaic-editorial.typ mosaic-editorial.pdf
//
// mosaic builds this deck out of named cells and paints them with `styled(..)`.
// typstage has no cells. In their place stand `margin: 0pt`, a theme that draws
// nothing of its own, and `plate(..)` below — the counterpart of mosaic's
// `surface(..)`. The margin therefore lives in the content, as it does there.
//
// What the template cannot do and this deck does: the first line of the agenda
// flies onto the section slide and becomes its heading. On paper you have to
// tell the room where you are; here they watch it happen.

#import "@schule/typstage:0.1.0": *

// ── Colours ────────────────────────────────────────────────────────────────
// The template's four, taken literally. White on sage measures 1.96 to 1 and
// would be too little for body copy; the template sets it anyway, and for the
// large capitals it stands here too.
#let cream = rgb("#f2eee5")
#let sage = rgb("#aebdb3")
#let ink = rgb("#111111")
#let white = rgb("#f9f8f3")

// ── The plates ─────────────────────────────────────────────────────────────
// Where the template photographs, this deck draws. Six compositions out of
// circle, bar and arch in the deck's warm tones: near enough to the template's
// interior shots to stand in for them, far enough from them to pretend
// nothing.

#let sand = rgb("#d8cbb8")
#let clay = rgb("#b5715a")
#let rose = rgb("#cbb0a2")
#let shell = rgb("#efe9e0")

/// One plate: a ground tone, two or three shapes on it, hard-cropped.
///
/// `n` picks the composition. All six fill the same area, so one plate can
/// replace another without anything beside it moving.
#let plate-art(n) = block(width: 100%, height: 100%, clip: true, {
  let i = calc.rem(n, 6)
  place(top + left, rect(width: 100%, height: 100%,
                         fill: (shell, sand, rose, shell, sand, rose).at(i)))
  if i == 0 {
    // A disc above an edge.
    place(top + right, dx: -18pt, dy: 34pt, circle(radius: 46pt, fill: clay))
    place(bottom + left, rect(width: 100%, height: 26%, fill: sand))
  } else if i == 1 {
    // An archway: a rectangle with its top corners taken off. As a circle on
    // a rectangle it looked like a matchstick.
    place(bottom + center, dy: -14%, rect(
      width: 44%, height: 60%, fill: shell,
      radius: (top-left: 100%, top-right: 100%),
    ))
    place(bottom + left, dy: -8%, line(length: 100%, stroke: 1pt + clay))
  } else if i == 2 {
    // Two overlapping discs.
    place(center + horizon, dx: -22pt, circle(radius: 50pt, fill: shell))
    place(center + horizon, dx: 24pt, dy: 14pt,
          circle(radius: 36pt, stroke: 1.2pt + ink))
  } else if i == 3 {
    // Stacked bands, like a shelf seen from the side.
    for (j, h) in (14%, 9%, 20%).enumerate() {
      place(top + left, dy: 16% + j * 22%,
            rect(width: 100%, height: h, fill: (clay, sand, rose).at(j)))
    }
  } else if i == 4 {
    // A quarter disc in the corner and one tall narrow form.
    place(top + left, dx: -58pt, dy: -58pt, circle(radius: 116pt, fill: rose))
    place(bottom + right, dx: -34pt, rect(width: 16%, height: 52%, fill: ink))
  } else {
    // A vase on a table: wide below, narrow above, a disc behind it that is
    // allowed to be the light.
    place(bottom + center, dy: -18%, rect(
      width: 22%, height: 30%, fill: shell,
      radius: (top-left: 60%, top-right: 60%, bottom: 12pt),
    ))
    place(top + right, dx: -22%, dy: 16%, circle(radius: 30pt, fill: sand))
    place(bottom + left, rect(width: 100%, height: 18%, fill: clay))
  }
})

// ── Surfaces ───────────────────────────────────────────────────────────────

/// One whole surface in one colour, carrying its own margin.
///
/// The counterpart of mosaic's `surface(fill: .., inset: .., align: ..)`:
/// there the cell carries the margin, here the content does. The same
/// rectangle.
#let plate(body, fill: sage, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

/// Two surfaces side by side, with no gap.
///
/// `grid` rather than `side-by-side`: the template lives on the colours
/// meeting. A gutter, however small, would turn two fields into two boxes.
#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

/// The thin white keyline the template lays over half its slides.
#let framed(body) = block(width: 100%, height: 100%, {
  place(top + left, body)
  place(top + left, dx: 14pt, dy: 14pt,
        rect(width: 100% - 28pt, height: 100% - 28pt, stroke: 0.8pt + white))
})

/// A heading in the template's voice: capitals, bold, no kicker rule.
#let head(body, size: 2.1em, fill: ink) = text(
  size: size, weight: "bold", fill: fill, upper(body),
)

/// A small rubric of the kind that stands over the template's grids.
#let rubric(title, body) = block(width: 100%, {
  block(above: 0pt, below: 0.45em, text(weight: "bold", size: 1.05em, title))
  text(size: 0.86em, body)
})

#let filler = [Elaborate on your topic here. Lorem ipsum dolor sit amet,
consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et
dolore magna aliqua.]

// ── The title slide, as a theme function ───────────────────────────────────
// mosaic puts the title slide in the theme (`layouts.title`), and typstage
// does the same: `title-slide` is an entry in the dictionary and is handed the
// theme, the slide and the geometry. That way `title:` stays with the deck
// instead of emigrating into a hand-built first slide, where neither the
// browser tab nor the speaker view would find it.
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
    // The rule under the title draws itself. It is the slide's only ornament;
    // it may take the blink of an eye.
    anim(at: 2, enter: "draw", duration: 900, easing: "out-quad",
         line(length: 100%, stroke: 1pt + ink))
  }))
}

// ── The theme that keeps out of the way ────────────────────────────────────
// No header band, no footer, no progress bar: for this deck mosaic sets
// `foreground: none` and takes the folio away from the theme. Here three words
// and two zeros do the same work — `head-gap` and `foot-gap` at 0pt, so that
// the body really reaches the trim.
#let t = theme(
  paper: cream,
  ink: ink,
  strong: sage,
  // No signal colour: this deck knows cream, sage and ink and nothing else.
  // The "accent" is therefore the ink itself.
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
  // No margin. Everything here that looks like a margin is content — exactly
  // as in mosaic, where the cell gets `inset: 0pt` and `surface()` carries it.
  margin: 0pt,
  // "cover": the new slide lays itself over the old one, which stays. A deck
  // made of rectangular colour fields does not push slides, it lays down
  // cards.
  transition: "cover",
  transition-duration: 520,
  duration: 560,
  // The style hook reaches the morph's flyers too. Whatever is not written
  // here, a tracked element never sees.
  style: it => { set par(justify: false, leading: 0.62em); it },

  // ── 02 Agenda ────────────────────────────────────────────────────────────
  slide(none, note: [The three points stand there at once. Trickling out a
                     table of contents makes the room wait for something it
                     needs at a glance.])[
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
                // Only the first line travels on. Number and word each carry
                // a name, so that on the next slide each finds its own place
                // instead of being paired by shape.
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

  // ── 03 Section: Introduction ─────────────────────────────────────────────
  slide(none, note: [This is where the first agenda line lands. Do not explain
                     that it flew — they saw it.])[
    #framed(bands((0.56fr, 0.44fr),
      plate(fill: sage, inset: 70pt)[
        #v(1fr)
        // The same two names as on the agenda, at another size and in another
        // place. A magic move needs no more than that. Where a morph crosses
        // the slide boundary, "cover" steps aside and the two slides
        // cross-fade instead — otherwise the flyer would ride out of frame
        // with the old slide.
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

  // ── 06 Four topics ───────────────────────────────────────────────────────
  slide(none, note: [One keypress, four fields. The wave runs in reading
                     order; any other way it is only fidgeting.])[
    #framed(plate(fill: sage, inset: 34pt,
      grid(columns: (0.34fr, 1fr), column-gutter: 16pt, rows: (100%,),
        plate-art(1),
        // `stride: 0`: all four on one step, offset only in milliseconds.
        // Four keypresses for four fields of equal rank would turn an
        // overview into a list. `at: 2` and not `auto`, because `auto` on a
        // slide with nothing before it means step one, and a field that is
        // there on arrival was never revealed.
        tiles(columns: 2, gutter: 22pt, row-gutter: 18pt,
              at: 2, stride: 0, stagger: 90, enter: "fade-up",
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
  slide(none, note: [The circle draws itself. Beside the rule on the cover it
                     is the only outline in the deck that comes into being
                     rather than fading in, which is why it is noticed.])[
    #bands((0.62fr, 0.38fr),
      plate(fill: cream, inset: 25pt, align: center + horizon)[
        // `enter: "draw"` wants a stroked path, and this circle is nothing
        // else. The text stands inside without waiting: it is the statement,
        // the circle is the frame around it.
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

  // ── 09 The team ──────────────────────────────────────────────────────────
  // Deliberately still. Four portraits arriving in a wave would explain
  // nothing about four colleagues, and a movement that explains nothing is
  // noise. The deck spends its motion on the agenda, the two outlines and the
  // three discs, and on nothing else.
  slide(none)[
    #plate(fill: cream, inset: 20pt)[
      #v(1fr)
      #std.align(center, head([The team], size: 1.9em))
      #v(16pt)
      #grid(columns: (1fr, 1fr, 1fr, 1fr), column-gutter: 14pt,
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

  // ── 10 A picture is worth a thousand words ───────────────────────────────
  slide(none, note: [Let it stand for a moment. The strip is the joke of the
                     slide and it needs a second.])[
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

  // ── 11 Market research ───────────────────────────────────────────────────
  slide(none, note: [The discs grow to their size. Putting 28, 60 and 100 down
                     asks for a comparison; letting them grow performs it.])[
    #framed(bands((0.78fr, 0.22fr),
      plate(fill: sage, inset: 22pt, align: center)[
        #v(14pt)
        #head([Market research], size: 1.9em, fill: white)
        #v(4pt)
        #text(size: 0.85em, fill: white)[Elaborate on the featured statistics.]
        #v(22pt)
        // All three on step 2, offset through `delay`, each growing out of
        // its own centre: the difference in size comes into being before the
        // eye instead of standing there finished. That is the number itself,
        // translated into motion. Not `tiles`, because it passes on neither
        // `easing` nor `duration`, and the overshoot of "out-back" is half
        // the effect.
        #grid(columns: (1fr, 1fr, 1fr), column-gutter: 30pt, align: bottom,
          ..((28, [28%]), (60, [60%]), (100, [100%])).enumerate().map(((i, s)) => {
            let r = 60pt * s.first() / 100
            anim(
              at: 2, enter: "scale", easing: "out-back", duration: 700,
              delay: i * 130,
              std.align(center, {
                box(height: 128pt, std.align(center + bottom, circle(
                  radius: r, fill: white,
                  // Not `r * 0.52` alone: at 28 percent the number would be
                  // nine point and the disc would look empty. The circle
                  // carries the comparison, the number only has to stay
                  // legible.
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

  // ── 12 Contact ───────────────────────────────────────────────────────────
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
