// Greyscale — after the Portfolio deck of the mosaic package.
//
// Source: the "Photojournalist Portfolio" template by SlidesCarnival
// (https://www.slidescarnival.com/), CC BY 4.0, adapted; mosaic brought it to
// Typst first (docs-src/examples/decks/portfolio). The template's photographs
// are not carried over; grey surfaces drawn in plain Typst stand in their
// place — a gradient, a horizon, a silhouette.
//
//   typst compile mosaic-greyscale.typ mosaic-greyscale.html --format html --features html
//   typst compile mosaic-greyscale.typ mosaic-greyscale.pdf
//
// The point of this deck is a single line. mosaic says of its own version:
// "Its monochrome look is one dictionary" — eight entries handed to
// `m.setup(colors: ..)`. typstage has `palette:` for that, and it is very
// nearly the same thing: eight roles, overridable in part, independent of the
// design. The furniture below names roles only (`t.ink`, `t.paper`,
// `t.strong`, `t.accent`): the title slide, the section plate, the black
// panels, the cards. Swap `palette: greyscale` for `palettes.textbook` and
// every one of them takes the new colours, without a second line changing.
//
// How much you then see is a second question, and worth stating plainly
// rather than promising a different deck. Measured on that swap: the section
// plate turns vermilion with a blue rule, because its whole ground is
// `strong`; the rest keeps its look, because textbook's `ink` is very nearly
// black and its `paper` is white, so the panels and cards land where they
// already stood. And the grey surfaces further down never move at all: they
// stand in for photographs and are written in `luma()`, not in roles — a
// photograph does not turn vermilion because the palette did.
//
// That is the honest size of the claim, and it is still mosaic's claim: the
// deck's own colour lives in one dictionary. The pictures live outside it.
//
// What the template cannot do and this deck does: one picture steps out of
// the contact sheet and becomes the print. And the big number counts itself
// up instead of standing there.

#import "@schule/typstage:0.1.0": *

// ── The one line ───────────────────────────────────────────────────────────
// Set beside mosaic's own `greyscale` dictionary:
//
//   mosaic          typstage    value
//   canvas          paper       #f7f7f5
//   text            ink         #111111
//   muted           muted       #6b6b6b
//   line            border      #d9d9d9
//   surface         surface     white
//   accent          accent      —  see below
//   warning, error  (missing)   typstage has no status colours
//   (missing)       strong      the dark ground of the title and section
//                               slides
//   (missing)       inverted    whether the palette is already turned around
//
// The one value that cannot be carried over is the accent. mosaic sets it to
// the ink, and that works there because its default theme draws no accent
// shape on a dark ground. typstage draws one: the rule above the section
// title stands on `strong`, and black on black is not a rule. Measured
// against the two grounds this deck actually has, luma(40%) holds 5.35 to 1
// on the paper #f7f7f5 and 3.29 on the strong #111111 — the window for a grey
// that carries on both is narrow, and this sits in it. Against pure white and
// pure black the same grey measures 5.74 and 3.66; the deck uses neither, so
// the numbers above are the ones that count. Both ends clear the 3.0 that
// WCAG 2 asks of a shape that is not text, which is what the rule is.
#let greyscale = (
  paper: rgb("#f7f7f5"),
  ink: rgb("#111111"),
  strong: rgb("#111111"),
  accent: luma(40%),
  muted: rgb("#6b6b6b"),
  surface: white,
  border: rgb("#d9d9d9"),
)

// ── Grey surfaces ──────────────────────────────────────────────────────────
// In place of the photographs. A gradient gives the depth, two or three dark
// shapes the statement; a surface that stands in for a photograph without
// pretending to be one needs no more.

/// One grey surface. `n` picks the composition; all of them fill the same
/// area.
#let gplate(n) = block(width: 100%, height: 100%, clip: true, {
  let i = calc.rem(n, 5)
  place(top + left, rect(width: 100%, height: 100%,
    fill: gradient.linear(luma(90%), luma(52%), angle: 90deg)))
  if i == 0 {
    // Conifers in fog. Written out by hand rather than computed: a formula
    // puts the trunks at equal spacing, and what stands evenly looks like a
    // bar chart and not like a wood. The small tilt is the whole difference:
    // upright they are bars, a degree off they are trunks.
    for (x, w, h, tone, tilt) in (
      (5%, 3.4%, 74%, 20%, -1.2deg), (13%, 2.2%, 58%, 34%, 0.8deg),
      (22%, 4.0%, 82%, 17%, 1.4deg), (31%, 1.8%, 47%, 44%, -0.6deg),
      (41%, 3.0%, 66%, 26%, 1.0deg), (52%, 2.4%, 88%, 22%, -1.6deg),
      (60%, 1.6%, 41%, 48%, 0.5deg), (71%, 3.6%, 70%, 19%, -0.9deg),
      (83%, 2.0%, 54%, 38%, 1.7deg), (91%, 2.8%, 78%, 29%, -0.7deg),
    ) {
      place(bottom + left, dx: x, dy: -6%, rotate(tilt, origin: bottom + center,
            reflow: false, rect(width: w, height: h, fill: luma(tone))))
    }
    // The fog over them, so that the trunks at the back disappear into it.
    place(bottom + left, rect(width: 100%, height: 46%,
      fill: gradient.linear(luma(70%).transparentize(100%), luma(74%),
                            angle: 90deg)))
  } else if i == 1 {
    // A horizon with a low sun.
    place(top + right, dx: -22%, dy: 18%, circle(radius: 26pt, fill: luma(96%)))
    place(bottom + left, rect(width: 100%, height: 34%, fill: luma(28%)))
  } else if i == 2 {
    // A portrait against the light. Cropped, not centred: a centred
    // silhouette of head and shoulders is a user icon, a cropped one is a
    // portrait. The pale disc behind it is the light.
    place(bottom + left, dx: 6%, dy: -12%,
          ellipse(width: 34%, height: 34%, fill: luma(80%), stroke: none))
    place(bottom + right, dx: 14%, dy: 12%, rect(
      width: 58%, height: 52%, fill: luma(16%),
      radius: (top-left: 52%, top-right: 22%),
    ))
    place(bottom + right, dx: -4%, dy: -38%,
          ellipse(width: 19%, height: 24%, fill: luma(16%), stroke: none))
  } else if i == 3 {
    // Dunes, three ridges one behind the other, each lighter than the last.
    for (dy, w, h, tone) in ((-4%, 150%, 46%, 24%), (-14%, 130%, 40%, 38%),
                             (-26%, 170%, 34%, 52%)) {
      place(bottom + center, dy: dy, ellipse(width: w, height: h,
                                             fill: luma(tone), stroke: none))
    }
  } else {
    // Architecture: a grid of windows.
    place(top + left, rect(width: 100%, height: 100%, fill: luma(64%)))
    for a in range(4) {
      for b in range(5) {
        place(top + left, dx: 8% + b * 18%, dy: 12% + a * 22%,
              rect(width: 11%, height: 13%, fill: luma(24%)))
      }
    }
  }
})

// ── Surfaces ───────────────────────────────────────────────────────────────
#let plate(body, fill: none, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

#let rows-of(fracs, ..cells) = grid(
  columns: (100%,), rows: fracs, row-gutter: 0pt, ..cells,
)

/// The black field this deck makes its statements out of.
///
/// The template has it on nearly every slide: a light ground, a rectangle in
/// ink, text on it in paper. Both colours come from the palette; neither
/// stands here as a value.
#let panel(t, body, inset: 20pt, width: 100%) = block(
  width: width, fill: t.ink, inset: inset, text(fill: t.paper, body),
)

#let lorem = [Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris.]

/// The number with thousands separators, out of one of the scene's
/// intermediate values.
///
/// The scene hands in floating-point numbers, one per tween frame; none of
/// that may be visible on the slide.
#let grouped(x) = {
  let s = str(int(calc.round(x)))
  let groups = ()
  let k = s.len()
  while k > 3 { groups.push(s.slice(k - 3, k)); k -= 3 }
  groups.push(s.slice(0, k))
  groups.rev().join(",")
}

// ── Title slide and section plate ──────────────────────────────────────────
// Both name roles only. That is why the whole deck follows the palette, and
// why the claim at the top — one dictionary, one deck — holds here for the
// furniture too and not merely for the body copy.

#let cover(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: t.strong, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-title-slide-ground>]
  }
  // The picture under the word, dark enough for paper to stand on it.
  place(top + left, block(width: 100%, height: 100%,
    std.align(center + horizon, block(width: 100%, height: 100%, {
      set block(spacing: 0pt)
      gplate(0)
    }))))
  place(top + left, rect(width: 100%, height: 100%, fill: t.ink.transparentize(58%)))
  place(top + left, dx: 30pt * k, dy: 26pt * k,
        text(size: 74pt * k, weight: "bold", fill: t.paper,
             [#upper(s.title) <ts-title-slide-title>]))
  place(bottom + left, dx: 32pt * k, dy: -30pt * k, block(width: 60%, {
    text(size: 15pt * k, fill: t.paper,
         [#s.subtitle <ts-title-slide-subtitle>])
    v(6pt * k)
    text(size: 11pt * k, fill: t.paper.transparentize(25%),
         [#s.author <ts-title-slide-byline>])
  }))
}

#let plate-section(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: t.strong, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-section-slide-ground>]
  }
  place(horizon + left, dx: 40pt * k, block(width: geo.width - 80pt * k, {
    // The rule in the accent colour, on the dark ground. Exactly the shape
    // for whose sake the accent above may not be the ink.
    {
      set rect(fill: t.accent, stroke: none)
      [#rect(width: 74pt * k, height: 3pt * k) <ts-section-slide-rule>]
    }
    v(12pt * k)
    text(size: 44pt * k, weight: "bold", fill: t.paper,
         [#upper(s.title) <ts-section-slide-title>])
  }))
}

// ── The theme ──────────────────────────────────────────────────────────────
// `themes.default`, varied by two pictures and three measures. Not one colour
// stands in it: the colour comes entirely from `palette:` below. That is the
// division of labour typstage shares with mosaic — a theme says how a slide
// is built, a palette says in what colour.
#let t = themes.default + (
  font: ("Inter", "Helvetica Neue", "Arial", "DejaVu Sans"),
  size: 15pt,
  header: "plain",
  footer: "none",
  head-gap: 0pt,
  foot-gap: 0pt,
  box: "label",
  title-slide: cover,
  section: plate-section,
)

// And the same move once more, for what the slides themselves need: a
// resolved theme, so that `panel(tp, ..)` uses the palette's colours and not
// a second copy running alongside them.
#let tp = t + greyscale

#presentation(
  theme: t,
  // Eight roles, overridden in part. Nothing more about this deck is
  // coloured — or rather: nothing more about it is grey.
  palette: greyscale,
  title: [Greyscale],
  subtitle: [A photojournalist's portfolio],
  author: [after SlidesCarnival, via mosaic],
  date: [27 August 2026],
  margin: 0pt,
  // A deck made of pictures cross-fades. Anything that pushes, wipes or
  // tilts would turn a sequence of images into an operation.
  transition: "fade",
  transition-duration: 440,
  duration: 500,
  style: it => { set par(justify: false, leading: 0.62em); it },

  // ── 02 Contents ──────────────────────────────────────────────────────────
  slide(none)[
    #block(width: 100%, height: 100%, {
      place(top + left, bands((0.16fr, 0.64fr, 0.20fr),
        plate([], fill: white),
        plate(gplate(0)),
        plate([], fill: white),
      ))
      place(top + center, dy: -14pt,
            text(size: 62pt, weight: "bold", fill: tp.ink)[CONTENTS])
      place(bottom + center, dy: 18pt,
            text(size: 62pt, weight: "bold", fill: tp.ink)[CONTENTS])
      place(center + horizon, panel(tp, inset: 22pt, width: 240pt)[
        #stack(dir: ttb, spacing: 15pt,
          text(size: 13pt, weight: "medium")[Introduction],
          text(size: 13pt, weight: "medium")[About us],
          text(size: 13pt, weight: "medium")[Projects],
          text(size: 13pt, weight: "medium")[Exhibitions],
        )
      ])
    })
  ],

  // ── 03 Hello ─────────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.48fr, 0.52fr),
      plate(fill: white, inset: 28pt, align: center + horizon,
        panel(tp, inset: 25pt, std.align(left)[
          #text(size: 30pt, weight: "bold")[HELLO!]
          #v(10pt)
          #text(size: 10pt)[#lorem]
        ])),
      plate(gplate(2)),
    )
  ],

  // ── 04 About us ──────────────────────────────────────────────────────────
  slide(none)[
    #rows-of((1.05fr, 0.95fr),
      block(width: 100%, height: 100%, {
        place(top + left, gplate(4))
        place(left + horizon, dx: 34pt,
              text(size: 34pt, weight: "bold", fill: tp.paper)[ABOUT US])
      }),
      plate(fill: white, inset: 26pt,
        grid(columns: (1fr, 1fr), column-gutter: 30pt,
          text(size: 11.5pt, lorem), text(size: 11.5pt, lorem))),
    )
  ],

  // ── 05 Mission and vision ────────────────────────────────────────────────
  slide(none)[
    #bands((1.3fr, 0.7fr),
      plate(fill: white, inset: 28pt)[
        #set par(leading: 0.3em)
        #text(size: 38pt, weight: "bold")[MISSION\ & VISION]
        #v(26pt)
        #grid(columns: (1fr, 1fr), column-gutter: 14pt,
          panel(tp, inset: 16pt)[
            #text(size: 14pt, weight: "bold")[Mission]
            #v(8pt)
            #text(size: 10pt)[#lorem]
          ],
          panel(tp, inset: 16pt)[
            #text(size: 14pt, weight: "bold")[Vision]
            #v(8pt)
            #text(size: 10pt)[#lorem]
          ],
        )
      ],
      plate(gplate(0)),
    )
  ],

  // ── 06 Section ───────────────────────────────────────────────────────────
  section([Our best shots]),

  // ── 07 The contact sheet ─────────────────────────────────────────────────
  slide(none, note: [Do not say which picture is meant. On the next slide it
                     stands there large, and the way it got there is visible.])[
    #plate(fill: white, inset: 26pt)[
      #grid(columns: (1fr, 1fr), rows: (1fr, 1fr), gutter: 10pt,
        gplate(2),
        // Exactly one tile carries a name. On the next slide the same name
        // stands around the full-bleed version, and in between the picture
        // flies. `match: "block"`: a surface has no glyphs worth pairing, and
        // per-glyph matching would make a swarm of it rather than a
        // movement.
        morph(<print>, gplate(1), match: "block"),
        gplate(4),
        gplate(3),
      )
    ]
  ],

  // ── 08 The print ─────────────────────────────────────────────────────────
  slide(none, note: [This is where the tile lands. The enlarger is the one
                     movement in the deck that makes a claim: this one
                     picture, large.])[
    #block(width: 100%, height: 100%, {
      place(top + left, morph(<print>, block(width: 100%, height: 100%,
                                             gplate(1)), match: "block"))
      place(bottom + right, dx: -34pt, dy: -20pt,
            panel(tp, inset: (x: 26pt, y: 12pt), width: auto,
                  text(size: 15pt, weight: "bold")[
                    A PICTURE IS WORTH A THOUSAND WORDS
                  ]))
    })
  ],

  // ── 09 Numbered work ─────────────────────────────────────────────────────
  slide(none, note: [One keypress, four cards. Like a contact sheet coming up
                     in the developer.])[
    #plate(fill: tp.ink, inset: (x: 96pt, y: 62pt), align: center + horizon)[
      // `at: 2` and not `auto`: on a slide with nothing before it `auto`
      // means step one, and a card that is there on arrival was never
      // revealed.
      #tiles(columns: 2, gutter: 30pt, row-gutter: 26pt,
             at: 2, stride: 0, stagger: 110, enter: "fade-up",
        ..(("01", "02", "03", "04")).map(nr => grid(
          columns: (58pt, 1fr), column-gutter: 15pt, align: top,
          rect(fill: tp.paper, inset: 8pt,
               text(size: 28pt, weight: "bold", fill: tp.ink, nr)),
          text(size: 10.5pt, fill: tp.paper)[
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
            eiusmod tempor incididunt.
          ],
        )),
      )
    ]
  ],

  // ── 10 The big number ────────────────────────────────────────────────────
  slide(none, note: [First a zero stands there. Then ask the room how many
                     they think it is — and only then press.])[
    #block(width: 100%, height: 100%, {
      place(top + left, gplate(3))
      place(top + center, dy: 120pt, block(width: 100%, std.align(center, {
        // `scene` rather than `anim`: the number is not meant to appear, it
        // is meant to run. Two stops, eighteen frames between them, and every
        // one of them set by Typst — which is why the figures stay sharp and
        // in the same face as everything else. The price is in the manual:
        // one frame per tween step, and none of them is measured.
        scene(
          n => std.align(center, text(size: 74pt, weight: "bold",
                                      fill: tp.ink, grouped(n))),
          stops: (0, 123456),
          tween: 18,
          width: 100%,
          height: 96pt,
        )
        v(4pt)
        panel(tp, inset: (x: 12pt, y: 6pt), width: auto,
              text(size: 11pt, weight: "bold")[
                Big numbers catch your audience's attention
              ])
      })))
    })
  ],

  // ── 11 The chart ─────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.85fr, 1.15fr),
      plate(fill: tp.ink, inset: 27pt)[
        #text(size: 30pt, weight: "bold", fill: tp.paper)[CHART]
        #v(10pt)
        #text(size: 10.5pt, fill: tp.paper)[#lorem]
      ],
      plate(fill: white, inset: 20pt)[
        // A field of bars in a handful of greys: the role an embedded image
        // plays in the template, except that this one is typeset and
        // therefore follows any palette.
        #block(width: 100%, height: 100%, {
          let heights = (34%, 58%, 46%, 79%, 63%, 92%)
          place(bottom + left, line(length: 100%, stroke: 0.8pt + tp.border))
          for (j, h) in heights.enumerate() {
            place(bottom + left, dx: 4% + j * 16%, dy: -2pt,
                  rect(width: 11%, height: h,
                       fill: luma(78% - 9 * j * 1%)))
          }
        })
      ],
    )
  ],

  // ── 12 Exhibitions ───────────────────────────────────────────────────────
  slide(none)[
    #rows-of((0.28fr, 1fr),
      plate(fill: tp.ink, inset: (x: 34pt, y: 18pt), align: center + horizon,
            text(size: 30pt, weight: "bold", fill: tp.paper)[EXHIBITIONS]),
      plate(fill: tp.ink, inset: (bottom: 0pt),
        grid(columns: (1fr, 1fr, 1fr), column-gutter: 7pt, rows: (100%,),
          ..(([Project 1], 2), ([Project 2], 4), ([Project 3], 3)).map(p =>
            block(width: 100%, height: 100%, fill: white, {
              block(width: 100%, height: 68%, gplate(p.last()))
              pad(x: 11pt, top: 8pt)[
                #text(size: 12pt, weight: "bold", p.first())
                #linebreak()
                #text(size: 8.5pt)[Lorem ipsum dolor sit amet, consectetur
                                   adipiscing elit.]
              ]
            })),
        ))
    )
  ],

  // ── 13 Closing ───────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.42fr, 0.58fr),
      plate(fill: tp.ink, inset: 32pt, align: left + horizon)[
        #set par(leading: 0.34em)
        #text(size: 58pt, weight: "bold", fill: tp.paper)[THANK\ YOU]
      ],
      plate(fill: tp.ink, inset: (top: 150pt), gplate(2)),
    )
  ],
)
