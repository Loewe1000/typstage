// Greyscale — after the Portfolio deck of the mosaic package.
//
// Source: the "Photojournalist Portfolio" template by SlidesCarnival
// (https://www.slidescarnival.com/), CC BY 4.0, adapted; mosaic brought it to
// Typst first (docs-src/examples/decks/portfolio). The template's photographs
// are not carried over — they are credited only in aggregate there, with no
// per-file provenance. In their place stand nine synthetic greyscale images
// generated for this deck; model, date and prompts are recorded in
// `mosaic-bilder/PROVENANCE.md`.
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
// already stood. And the pictures further down never move at all: they are
// photographs, and the greys the chart is drawn in beside them are `luma()`
// and not roles — a photograph does not turn vermilion because the palette
// did.
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

// ── The plates ─────────────────────────────────────────────────────────────
// The nine pictures that are photographs in the template. True greyscale —
// written out of PIL's mode `L`, so red, green and blue are one number —
// because the claim this deck makes is that a single dictionary colours all
// of it, and a picture carrying colour would be the one piece that does not
// follow. Model, date and prompts stand in `mosaic-bilder/PROVENANCE.md`.
//
// Typst inlines an image as a `data:` URI once per *use*, not once per file:
// a plate on three slides sits in the HTML three times. So each file is 820 px
// on its long edge or the long edge of the largest cell it appears in,
// whichever is smaller — a plate that is only ever a tile in the contact sheet
// is stored at tile size. That, and not the picture count, is what keeps the
// packed deck where it is.
//
// `fit: "cover"` and not `"contain"`: a plate fills its cell, and the box cuts
// away what runs over the edge. Otherwise white strips would stand beside the
// picture, and the cell would no longer be the surface the layout treats it
// as.
#let photos = (
  photographer: "mosaic-bilder/photographer.webp",  // at work, from behind
  street: "mosaic-bilder/street.webp",              // wet street, one figure
  facade: "mosaic-bilder/facade.webp",              // a grid of windows
  pier: "mosaic-bilder/pier.webp",                  // a pier into the mist
  darkroom: "mosaic-bilder/darkroom.webp",          // prints on the line
  hands: "mosaic-bilder/hands.webp",                // hands loading a camera
  alley: "mosaic-bilder/alley.webp",                // a shaft of light
  contact: "mosaic-bilder/contact.webp",            // a sheet and a loupe
  trays: "mosaic-bilder/trays.webp",                // three developing trays
)

/// One plate, filling its cell. Named and not numbered: which picture goes
/// into which cell is a decision about its shape — the pier is upright, the
/// facade lies down — and a number hides that.
#let photo(name) = block(width: 100%, height: 100%, clip: true,
  image(photos.at(name), width: 100%, height: 100%, fit: "cover"))
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
      photo("photographer")
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
        plate(photo("street")),
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
      plate(photo("hands")),
    )
  ],

  // ── 04 About us ──────────────────────────────────────────────────────────
  slide(none)[
    #rows-of((1.05fr, 0.95fr),
      block(width: 100%, height: 100%, {
        place(top + left, photo("trays"))
        place(left + horizon, dx: 34pt,
              text(size: 34pt, weight: "bold", fill: tp.paper)[ABOUT US])
      }),
      plate(fill: white, inset: 26pt,
        grid(columns: (1fr, 1fr), column-gutter: 30pt,
          text(size: 11.5pt, lorem), text(size: 11.5pt, lorem))),
    )
  ],

  // ── 05 The pier ──────────────────────────────────────────────────────────
  // After the template's fifth slide: two pictures and a column of text, in
  // three bands of 0.72 / 0.72 / 1.05. The first picture keeps a white border
  // — that is the cell's own inset, not a stroke — and the second bleeds to
  // the edges of its cell, which is the whole contrast the slide is built on.
  slide(none)[
    #bands((0.72fr, 0.72fr, 1.05fr),
      plate(fill: white, inset: 25pt, photo("pier")),
      plate(photo("darkroom")),
      plate(fill: white, inset: 30pt, align: center + horizon)[
        #set align(center)
        #text(size: 12.5pt)[
          Two of us, one darkroom, and a standing rule: we photograph what is
          there. Nothing is arranged, nothing re-enacted, nothing composited.

          The work on the following pages was made on assignment over eleven
          years, in eight countries, mostly on days when nothing in particular
          happened.
        ]
      ],
    )
  ],

  // ── 06 Mission and vision ────────────────────────────────────────────────
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
      plate(photo("hands")),
    )
  ],

  // ── 07 Section ───────────────────────────────────────────────────────────
  // An addition. The template has no section plate at all — it goes straight
  // from the mission to the best shots — and this one is here because
  // typstage draws one and the deck should show it. It takes its title from
  // the slide that follows, so the addition announces the template's own
  // slide rather than a section the template does not have.
  section([Our best shots]),

  // ── 08 Our best shots ────────────────────────────────────────────────────
  // After the template's eighth slide: an opening column, one tall picture,
  // and a list on ink. The picture's band is the narrow one at 0.62, which is
  // what makes it read as a plate between two columns of text rather than as
  // an illustration beside them.
  //
  // No `morph` on this slide, so the trap two slides down does not spring
  // here: nothing is tracked, the runtime lifts no sprite over the slide, and
  // ordinary slide content stays where it is drawn.
  slide(none)[
    #bands((0.95fr, 0.62fr, 0.9fr),
      plate(fill: white, inset: 28pt)[
        #set par(leading: 0.3em)
        #text(size: 36pt, weight: "bold")[OUR BEST\ SHOTS]
        #v(18pt)
        #set par(leading: 0.62em)
        #text(size: 11pt)[
          Four sequences, picked because they survived the edit twice: once on
          the light table, and once a year later, when the reason for taking
          them had gone.
        ]
      ],
      plate(photo("alley")),
      plate(fill: tp.ink, inset: 22pt, align: center + horizon)[
        #set align(center)
        #set text(fill: tp.paper)
        #for (title, sub) in (
          ([Low Water], [Three summers on a river that kept getting shorter.]),
          ([Night Shift], [A cannery, from the last bus in to the first bus out.]),
          ([Fifty Metres], [One street corner, photographed for a year.]),
          ([Closing Time], [The final week of a market that stood for 90 years.]),
        ) [
          #text(size: 12pt, weight: "bold", title)
          // The rule names a role. The template writes #555555 here; on this
          // deck the same job belongs to `muted`, and then the list follows
          // the palette like the rest of the furniture.
          #line(length: 100%, stroke: 0.5pt + tp.muted)
          #text(size: 9pt, sub)
          // Wider than the gap above the rule, so each block reads as title,
          // rule, line — and not as a line that belongs to the title below.
          #v(13pt)
        ]
      ],
    )
  ],

  // ── 09 The contact sheet ─────────────────────────────────────────────────
  slide(none, note: [Do not say which picture is meant. On the next slide it
                     stands there large, and the way it got there is visible.])[
    #plate(fill: white, inset: 26pt)[
      #grid(columns: (1fr, 1fr), rows: (1fr, 1fr), gutter: 10pt,
        photo("darkroom"),
        // Exactly one tile carries a name. On the next slide the same name
        // stands around the full-bleed version, and in between the picture
        // flies. `match: "block"`: a surface has no glyphs worth pairing, and
        // per-glyph matching would make a swarm of it rather than a
        // movement.
        morph(<print>, photo("street"), match: "block"),
        photo("facade"),
        photo("contact"),
      )
    ]
  ],

  // ── 10 The print ─────────────────────────────────────────────────────────
  slide(none, note: [This is where the tile lands. The enlarger is the one
                     movement in the deck that makes a claim: this one
                     picture, large.])[
    #block(width: 100%, height: 100%, {
      place(top + left, morph(<print>, block(width: 100%, height: 100%,
                                             photo("street")), match: "block"))
      // A tracked element and not ordinary content: the plate above it sits
      // in a `morph`, and for that the runtime lifts a sprite over the slide.
      // Anything belonging to the slide itself would lie under that sprite —
      // visible on paper, covered in the browser. Two sprites, on the other
      // hand, stand in source order, and this one comes second.
      place(bottom + right, dx: -34pt, dy: -20pt,
            anim(at: "1-",
                 panel(tp, inset: (x: 26pt, y: 12pt), width: auto,
                       text(size: 15pt, weight: "bold")[
                         A PICTURE IS WORTH A THOUSAND WORDS
                       ])))
    })
  ],

  // ── 11 Numbered work ─────────────────────────────────────────────────────
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

  // ── 12 The big number ────────────────────────────────────────────────────
  slide(none, note: [First a zero stands there. Then ask the room how many
                     they think it is — and only then press.])[
    #block(width: 100%, height: 100%, {
      place(top + left, photo("photographer"))
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
          // The frames really do differ in width -- "0" is narrower than
          // "123,456" -- and that is the point of a number that counts up.
          // It does not wander for it: `align(center)` inside a full-width
          // block holds the middle still while the figures grow out from it.
          steady: false,
        )
        v(4pt)
        panel(tp, inset: (x: 12pt, y: 6pt), width: auto,
              text(size: 11pt, weight: "bold")[
                Big numbers catch your audience's attention
              ])
      })))
    })
  ],

  // ── 13 The chart ─────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.85fr, 1.15fr),
      plate(fill: tp.ink, inset: 27pt)[
        #text(size: 30pt, weight: "bold", fill: tp.paper)[CHART]
        #v(10pt)
        #text(size: 10.5pt, fill: tp.paper)[#lorem]
      ],
      plate(fill: white, inset: 20pt)[
        // A field of bars in a handful of greys: the role an embedded image
        // plays in the template, except that this one is typeset rather than
        // imported. Its greys are `luma()` and stay grey when the palette
        // changes, like the surfaces above and for the same reason — only the
        // baseline is a role. A chart that had to carry meaning would name
        // roles here instead; this one carries a shape.
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

  // ── 14 Exhibitions ───────────────────────────────────────────────────────
  slide(none)[
    #rows-of((0.28fr, 1fr),
      plate(fill: tp.ink, inset: (x: 34pt, y: 18pt), align: center + horizon,
            text(size: 30pt, weight: "bold", fill: tp.paper)[EXHIBITIONS]),
      plate(fill: tp.ink, inset: (bottom: 0pt),
        grid(columns: (1fr, 1fr, 1fr), column-gutter: 7pt, rows: (100%,),
          ..(([Project 1], "pier"), ([Project 2], "alley"),
             ([Project 3], "darkroom")).map(p =>
            block(width: 100%, height: 100%, fill: white, {
              block(width: 100%, height: 68%, photo(p.last()))
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

  // ── 15 Closing ───────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.42fr, 0.58fr),
      plate(fill: tp.ink, inset: 32pt, align: left + horizon)[
        #set par(leading: 0.34em)
        #text(size: 58pt, weight: "bold", fill: tp.paper)[THANK\ YOU]
      ],
      plate(fill: tp.ink, inset: (top: 150pt), photo("facade")),
    )
  ],
)
