// Giving a deck its look: palette, contrast, and the labels.
//
//   typst compile anziehen.typ anziehen.html --format html --features html
//   typst compile anziehen.typ anziehen.pdf
//
// This deck is `themes.default` and nothing else. Everything that makes it
// look unlike `theme-default.typ` next door is five palette entries and seven
// `show` rules on labels -- the two instruments the talk is about. There is no
// theme of its own anywhere in this file, and that is the argument: a look you
// can reach from outside is a look you never have to fork.
//
// Three heading levels (`slide-level: 3`), so the section slides carry the
// path they hang under and the structure is visible rather than described.
// And `overflow: "error"`: a talk about design that shipped a slide running
// off its own canvas would be arguing against itself.

#import "@schule/typstage:0.1.0": *

// ── The palette ────────────────────────────────────────────────────────────
// Five of the eight entries. `surface`, `border` and `inverted` are not named
// and are therefore not touched: `palette:` overwrites partially, and this
// deck keeps the theme's white card surface and its light hairline.
//
// The five were measured, not chosen by eye, and `accent` is the hard one. It
// has to hold on the paper *and* on the ink, because an inverted slide puts
// the ink behind it, and no colour can be far from both at once. The ceiling
// is exactly the square root of the contrast between the two grounds: here
// paper against ink measures 15.16, so nothing reaches past 3.89 on both, and
// only a colour sitting halfway between them gets there. This accent measures
// 4.05 and 3.75; the slide "Two grounds, one accent" prints both numbers
// rather than repeating them from here.
#let p = (
  paper: rgb("#f5f3ee"),
  ink: rgb("#1b1e1c"),
  strong: rgb("#20372c"),
  accent: rgb("#41836a"),
  muted: rgb("#5f6b62"),
)

// What the deck actually runs on: the theme's eight with those five laid over.
// `palette-report` measures a whole palette and the deck hands `presentation`
// only a part, so the merge is written out here -- it is the same one the
// package makes internally, and slide "Six pairs, one contract" measures it.
#let merged = (
  paper: themes.default.paper, ink: themes.default.ink,
  strong: themes.default.strong, accent: themes.default.accent,
  muted: themes.default.muted, surface: themes.default.surface,
  border: themes.default.border, inverted: false,
) + p

// ── Seven rules, and the whole look of this deck ────────────────────────────
// They stand *here*, above `#show: presentation`, because that is the one
// place that reaches everything: the slide ground, the chrome layer with
// title, footer and progress, the title slide and every section slide. The
// `style:` hook below would reach three of these seven and stay silent about
// the other four.
//
// Four of them are type and take `set text(..)`; one is a rectangle and takes
// `set rect(..)`; two are surfaces built from a block and take
// `set block(..)`. Which of the three a label wants is a property of the
// shape, and the manual's inventory names it for each one.
#show label("ts-slide-title"): set text(weight: 500, tracking: 0.02em)
#show label("ts-slide-number"): set text(size: 0.8em, tracking: 0.08em)
#show label("ts-title-slide-byline"): set text(size: 0.9em, tracking: 0.06em)
#show label("ts-statement"): set text(fill: p.strong, weight: 500)
#show label("ts-slide-progress"): set rect(fill: p.strong)
#show label("ts-card"): set block(stroke: 1.2pt + p.strong)
#show label("ts-callout"): set block(radius: 0pt)

#show: presentation.with(
  theme: themes.default,
  palette: p,
  // Three levels: `=` and `==` open a section slide, `===` opens a slide.
  slide-level: 3,
  // Every body is measured against the room the theme gives it, and a slide
  // that overruns stops the build instead of reaching the projector.
  overflow: "error",
  title: [Dressing a Deck],
  subtitle: [Why contrast is arithmetic, and why a theme is not a fork],
  author: [typstage #runtime-version],
  date: [26 August 2026],
  // A cross-fade throughout. The deck argues that a look should stay out of
  // the way of what is on the slide; a sliding or zooming page change would
  // be the first thing to break that promise.
  transition: "fade",
  style: it => { set par(justify: false); it },
)

= Colour

== A palette is not a design

=== A theme says how, a palette says what

#speaker-note[
  Do not name any function yet. The split is the whole talk, and it is easier
  to sell before anyone has an API in front of them.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [The design])[
    Where the title bar ends and the body begins. How far the rule sits under
    the heading. What a section slide *is*.
  ],
  card(title: [The colour])[
    Eight entries: ground, text, the strong tone, the accent, the muted grey,
    the card surface, the hairline, and whether it is dark.
  ],
)

#anim(callout(title: [Which is why there is no second dark theme])[
  The classroom look is still the classroom look in a darkened room. Darkness
  is a palette, not a design.
], at: 2, enter: "fade-up")

#v(1fr)

=== Five entries changed, three left standing

#speaker-note[
  The point to land here is "partial". Nobody hands over eight colours; people
  move one and want the rest to stay where they were.
]

#v(1fr)

#side-by-side(
  split: (1.15fr, 1fr), align: top,
  text(size: 0.72em, raw(lang: "typ",
    "#show: presentation.with(
  theme: themes.default,
  palette: (
    paper:  rgb(\"#f5f3ee\"),
    ink:    rgb(\"#1b1e1c\"),
    strong: rgb(\"#20372c\"),
    accent: rgb(\"#41836a\"),
    muted:  rgb(\"#5f6b62\"),
  ),
)")),
  [
    That is this deck, and the whole of its colour. `surface` and `border` are
    not named and keep the theme's own white and light grey. The green edge on
    a card is a label's doing, not a palette's.

    #v(0.4em)

    A key that is not one of the eight is refused by name. Silently doing
    nothing is the one thing a colour setting must never do.
  ],
)

#v(1fr)

== Contrast is arithmetic

=== What the eye reports and what the number says

#speaker-note[
  Read the swatch out loud before showing the number: "would you call that
  light?" Everyone says yes. Then the 1.96.
]

#v(1fr)

// The sage from the package's own comments, and the reason the contract
// exists. `contrast` is called here rather than the number written down: a
// figure on a slide about measurement should be measured on the slide.
#let sage = rgb("#aebdb3")

#side-by-side(
  split: (1fr, 1.25fr), align: horizon,
  block(width: 100%, fill: sage, inset: 14pt,
        align(center, text(fill: white, size: 1.1em)[White on sage]),
  ),
  [
    A luminance rule calls this light -- Typst's own `color.luma` reports
    72.6 percent for it. So white on it must be fine.

    #v(0.5em)

    #statement(size: 1.5em)[
      #calc.round(contrast(white, sage), digits: 2) : 1
    ]

    #v(0.2em)

    Body text wants 4.5.
  ],
)

#anim([The two questions are not the same one. "Does this look light" is
       answered by lightness; "can this be read on it" is answered by a ratio
       of two luminances, and only that second question is the one a slide
       asks.], at: 2, enter: "fade-up")

#v(1fr)

=== Six pairs, one contract

#speaker-note[
  This table is computed while the deck is built. If someone in the room
  suggests another green, the honest answer is: change the line and look.
]

#v(0.6em)

// Measured, not typed. Every number below comes out of `palette-report` at
// build time, so the table cannot drift away from the palette above it.
//
// The size comes from a `set` rule in a content block, not from
// `text(size: .., table(..))`: a table handed to `text` as an argument
// arrives in a slide body with its rows collapsed into one paragraph.
#[
#set text(size: 0.78em)
#table(
  columns: (auto, auto, auto, 1fr),
  stroke: none,
  align: (left, right, right, left),
  inset: (x: 6pt, y: 4pt),
  // A plain row, not `table.header`: the table never breaks across a page
  // here, and the header would only make the paged export complain.
  text(fill: p.muted)[Pair], text(fill: p.muted)[Measured],
  text(fill: p.muted)[Wants], text(fill: p.muted)[What for],
  ..palette-report(merged).map(f => (
    raw(f.pair),
    text(fill: if f.ok { p.accent } else { rgb("#b3261e") }, weight: "bold",
         str(calc.round(f.ratio, digits: 2))),
    str(f.min),
    text(fill: p.muted, f.role),
  )).flatten()
)
]

#anim(callout(title: [A report, not a gate])[
  It measures and changes nothing. Only the five bundled palettes are held to
  these six pairs, by an assertion in the package. Four of the five bundled
  *themes* do not pass them, and that is deliberate.
], at: 2, enter: "fade-up")

=== Two grounds, one accent

#speaker-note[
  The cyan is the finding the whole contract was built to catch. Say the two
  numbers slowly: 9.77 and 1.59, same colour, one slide apart.
]

#v(1fr)

#let swatch(name, colour, ground, glyph) = card(title: name)[
  #block(width: 100%, fill: ground, stroke: 0.5pt + merged.border, inset: 10pt,
         align(center, text(fill: colour, weight: "bold", size: 1.1em)[#glyph]))
  #v(0.4em)
  #align(center, text(size: 1.1em, weight: "bold",
    str(calc.round(contrast(colour, ground), digits: 2)) + " : 1"))
]

#side-by-side(
  split: (1fr, 1fr), align: top,
  swatch([This accent on the paper], p.accent, p.paper, [Aa]),
  swatch([The same on the ink], p.accent, p.ink, [Aa]),
)

#anim([An inverted slide turns ground and text around, so the accent has to
       survive both. Anything that manages it sits in the middle.],
      at: 2, enter: "fade-up")

#anim(callout(title: [The colour that only ever had one ground])[
  `themes.night`'s cyan measures
  #calc.round(contrast(rgb("#5ec8f2"), rgb("#0f1319")), digits: 2) on its dark
  paper and #calc.round(contrast(rgb("#5ec8f2"), rgb("#e6ebf2")), digits: 2) on
  its own ink. Nothing about the colour says so. The arithmetic does.
], at: 3, enter: "fade-up")

#v(1fr)

= Shape

== The labels

=== Every shape the package draws carries one

#speaker-note[
  Point at the screen while saying this. The progress bar under them is one of
  the seven, and it is green because of a line, not because of a theme.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1.1fr), align: top,
  text(size: 0.64em, raw(lang: "typ",
    "#show label(\"ts-slide-title\"):
  set text(weight: 500)
#show label(\"ts-slide-progress\"):
  set rect(fill: rgb(\"#20372c\"))
#show label(\"ts-callout\"):
  set block(radius: 0pt)")),
  [
    Three of the seven rules this deck wears: the title above you, the bar at
    the bottom edge, the square corners of the note below.

    #v(0.3em)

    The names run `ts-`, then the *place*, then the *part* -- `slide`,
    `title-slide`, `card`, `callout`, `statement`.
  ],
)

#anim(callout(title: [No theme was harmed])[
  Not a key of `themes.default` was changed to get here.
], at: 2, enter: "fade-up")

#v(1fr)

=== Inside the text, never around it

#speaker-note[
  This is the slide to slow down on. Both halves below are the *same* colour
  and the *same* show rule; only the bracket moved. Let them find the
  difference before you say it.
]

// The two spellings, built exactly as the package builds them, so what
// happens below is the real behaviour and not an illustration of it. The
// label of the left one sits on the content *inside* the call; the label of
// the right one sits on a group *around* the finished call.
#let type-inside = text(fill: p.muted, [#[Reachable] <inside-type>])
#let type-outside = [#text(fill: p.muted)[Not reachable] <outside-type>]

#let area-inside = {
  set rect(fill: merged.border)
  [#rect(width: 100%, height: 12pt) <inside-area>]
}
#let area-outside = [#rect(width: 100%, height: 12pt, fill: merged.border) <outside-area>]

// The four rules stand inside a content block, so they hold for this slide
// and no further. Every one of them asks for the same green.
#[
#show label("inside-type"): set text(fill: p.accent, weight: "bold")
#show label("outside-type"): set text(fill: p.accent, weight: "bold")
#show label("inside-area"): set rect(fill: p.accent)
#show label("outside-area"): set rect(fill: p.accent)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [Label inside the call])[
    #text(size: 0.56em, raw(lang: "typ", "text(fill: grey, [#[..] <l>])"))
    #v(0.2em)
    #align(center, type-inside)
    #v(0.35em)
    #text(size: 0.56em, raw(lang: "typ", "set rect(fill: grey)\n[#rect(..) <l>]"))
    #v(0.2em)
    #area-inside
  ],
  card(title: [Label around the call])[
    #text(size: 0.56em, raw(lang: "typ", "[#text(fill: grey)[..] <l>]"))
    #v(0.2em)
    #align(center, type-outside)
    #v(0.35em)
    #text(size: 0.56em, raw(lang: "typ", "\n[#rect(.., fill: grey) <l>]"))
    #v(0.2em)
    #area-outside
  ],
)
]

#anim(callout(title: [An explicit argument beats a rule])[
  A `show` rule can only put a `set` rule *around* what it matched, and where
  the colour arrived as a constructor argument further in, the rule never gets
  past it.
], at: 2, enter: "fade-up")

=== Where the rule has to stand

#speaker-note[
  The number worth quoting is the 13: those are the labels that stand in a
  body, and from inside the style hook they are the only ones that bite.
  Every other one fails silently. Silence is the expensive part.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [Above the show rule])[
    Everything: the slide ground, the chrome with title, footer and progress,
    the title slide, every section slide, and every moving piece.
  ],
  card(title: [Inside #raw(lang: "typ", "style:")], color: p.muted)[
    The slide *body* only. Measured one rule at a time: exactly the 13 that
    stand in a body take effect -- card, callout, statement, and the stand-in
    for a video. Every other label stays silent, without a warning.
  ],
)

#anim([`style:` is still the right place for typography that concerns the
       whole body. For labels there is one place, and it is the line above
       `#show: presentation`.], at: 2, enter: "fade-up")

#v(1fr)

== Before you show it

=== The room a slide has

#speaker-note[
  Close on the three lines. If they remember only the middle one, the talk
  did its job.
]

#v(1fr)

#statement[
  A page one leafs through shows an overrun. A talk one clicks through shows
  it at the projector.
]

#anim([`overflow: "error"` measures every body against the room the theme
       gives it and stops with *every* offending slide at once. This deck is
       built with it.], at: 2, enter: "fade-up")

#anim(callout(title: [Three things])[
  Colour is a palette and arrangement is a theme; keep them apart. Contrast is
  a ratio, so measure it instead of arguing about it. And every shape on a
  slide already has a name -- reach for it before you reach for a fork.
], at: 3, enter: "fade-up")

#v(1fr)
