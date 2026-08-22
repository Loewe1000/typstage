// themes.editorial: a talk for people who set type.
//
// "The Shape of a Page": why the four margins of a book are never equal, where
// the ratio 2 : 3 : 4 : 6 comes from, and what is left of it on a screen.
//
//   typst compile theme-editorial.typ theme-editorial.html --format html --features html
//   typst compile theme-editorial.typ theme-editorial.pdf
//
// As a handout instead of a talk: put `handout: 3` on `presentation(..)` for
// one build (three slides to a page, no transitions), then take the line out
// again. The deck itself runs without it.

#import "@schule/typstage:0.1.0": *

// A theme is a dictionary, so a deck may reach into its palette directly.
#let t = themes.editorial

#show: presentation.with(
  theme: t,
  title: [The Shape of a Page],
  subtitle: [Four margins, two diagonals, and what a screen does to them],
  author: [A talk on book design],
  date: [6 November 2026],
  // Nothing hurried anywhere. This theme is paper and hairlines; a slide that
  // shoves the last one aside makes it look like a slide deck again.
  transition: "fade",
  transition-duration: 500,
  duration: 480,
  // 4:3 rather than 16:9. A talk about the proportion of a leaf should not
  // itself be stuck on a cinema screen.
  width: 800pt,
  height: 600pt,
  // The margins are deliberately unequal: the fore-edge twice the fold, the
  // foot twice the head. Not the canon's 2 : 3 : 4 : 6, because those numbers
  // only hold on a 2 : 3 leaf and this stage is 4 : 3. But the two facts
  // underneath them (slide 7) hold anywhere, and this is what they look like
  // when they are applied honestly rather than copied.
  margin: (left: 30pt, right: 60pt, top: 26pt, bottom: 52pt),
)

// ── Colours ────────────────────────────────────────────────────────────────
// Fixed once, here, and handed in everywhere they are used. The theme supplies
// the palette; these names say what a colour *means* in the drawings, so the
// meaning can be changed in one place.

#let edge = t.border.darken(20%)              // the cut edge of a drawn leaf
#let type-fill = t.muted.lighten(86%)         // where the type would stand
#let type-edge = t.muted.lighten(52%)
#let guide = t.accent                         // a construction line
#let hot = t.strong.transparentize(85%)       // the part under discussion
#let warm = t.accent.transparentize(84%)      // a margin being measured

// ── The drawing ────────────────────────────────────────────────────────────
// The talk looks at one object, a spread, six different ways, so there is one
// set of helpers and every figure is built from them. Each helper returns a box
// of exactly the same size, and that is what lets a figure sit inside `anim`,
// `alternatives` or `morph` without moving anything beside it.
//
// Pure Typst: `rect`, `line`, `circle`, `place`. No drawing package involved.

#let leaf-w = 130pt
#let leaf-h = leaf-w * 3 / 2      // the 2 : 3 leaf the canon assumes
#let spread-w = 2 * leaf-w

/// One transparent overlay, the size of the whole spread.
#let layer(body) = box(width: spread-w, height: leaf-h, body)

/// The two leaves, with any number of overlays on top. Later layers lie over
/// earlier ones. That is why the construction lines are always handed in
/// after the text blocks, or the blocks would bury them.
#let stage(..layers) = box(width: spread-w, height: leaf-h, {
  let leaf = rect(width: leaf-w, height: leaf-h, fill: t.surface,
                  stroke: 0.6pt + edge)
  place(top + left, leaf)
  place(top + left, dx: leaf-w, leaf)
  for l in layers.pos() { place(top + left, l) }
})

/// The canon as coordinates, on the recto, measured from the fold.
///
/// `f` is the inner margin as a fraction of the leaf width, and everything
/// follows from it: the block is `1 - 3f` of the leaf, the head is `f` of its
/// height, and the fore-edge and foot come out at twice their opposites. That
/// is the content of slide 7, written as arithmetic.
#let canon(f) = (
  w: leaf-w * (1 - 3 * f), h: leaf-h * (1 - 3 * f),
  x: leaf-w * f, y: leaf-h * f,
)

/// Both text blocks, mirrored about the fold.
#let blocks(f) = layer({
  let b = canon(f)
  let r = rect(width: b.w, height: b.h, fill: type-fill, stroke: 0.55pt + type-edge)
  place(top + left, dx: leaf-w - b.x - b.w, dy: b.y, r)   // verso
  place(top + left, dx: leaf-w + b.x, dy: b.y, r)         // recto
})

/// Two blocks with the same margin on all four sides: the page nobody sets.
#let even-blocks(m) = layer({
  let s = leaf-w * m
  let r = rect(width: leaf-w - 2 * s, height: leaf-h - 2 * s,
               fill: type-fill, stroke: 0.55pt + type-edge)
  place(top + left, dx: s, dy: s, r)
  place(top + left, dx: leaf-w + s, dy: s, r)
})

#let shade-fold(f) = layer(place(top + left, dx: leaf-w - leaf-w * f,
  rect(width: 2 * leaf-w * f, height: leaf-h, fill: hot, stroke: none)))

#let shade-thumb(f) = layer({
  let o = 2 * leaf-w * f
  place(top + left, rect(width: o, height: leaf-h, fill: hot, stroke: none))
  place(top + left, dx: spread-w - o,
        rect(width: o, height: leaf-h, fill: hot, stroke: none))
})

#let shade-field(f) = layer({
  let b = canon(f)
  place(top + left, dx: 2 * leaf-w * f, dy: b.y,
        rect(width: spread-w - 4 * leaf-w * f, height: b.h, fill: hot, stroke: none))
})

/// The leaf's own diagonal: head of the fold to foot of the fore-edge.
#let leaf-diagonal() = layer(place(top + left,
  line(start: (leaf-w, 0pt), end: (spread-w, leaf-h), stroke: 0.9pt + guide)))

/// The spread's diagonal: it begins on this leaf and ends on the one opposite.
#let spread-diagonal() = layer(place(top + left,
  line(start: (spread-w, 0pt), end: (0pt, leaf-h), stroke: 0.9pt + guide)))

/// A point on the first line, carried straight across to the second.
///
/// Both dots sit on their lines by arithmetic, not by eye: the point is at
/// `(f·w, f·h)` on the leaf diagonal, and at that height the spread diagonal
/// stands at `x = 2w(1 - f)`, which is exactly where the block's fore-edge
/// falls. That identity is the whole construction.
#let carry(f) = layer({
  let b = canon(f)
  let dot(x, y) = place(top + left, dx: x - 2.4pt, dy: y - 2.4pt,
                        circle(radius: 2.4pt, fill: guide, stroke: none))
  place(top + left, dx: leaf-w + b.x, dy: b.y,
        line(start: (0pt, 0pt), end: (b.w, 0pt),
             stroke: (paint: guide, thickness: 0.9pt, dash: "dotted")))
  dot(leaf-w + b.x, b.y)
  dot(leaf-w + b.x + b.w, b.y)
})

/// The four margins of the recto, shaded and named by their numbers.
#let canon-labels(f) = layer({
  let b = canon(f)
  let band(x, y, w, h, n) = {
    place(top + left, dx: x, dy: y, rect(width: w, height: h, fill: warm, stroke: none))
    place(top + left, dx: x, dy: y, box(width: w, height: h, align(center + horizon,
      text(size: 10pt, weight: "bold", fill: t.strong, n))))
  }
  band(leaf-w, b.y, b.x, b.h, [2])                                 // fold
  band(leaf-w + b.x, 0pt, b.w, b.y, [3])                           // head
  band(leaf-w + b.x + b.w, b.y, leaf-w - b.x - b.w, b.h, [4])      // fore-edge
  band(leaf-w + b.x, b.y + b.h, b.w, leaf-h - b.y - b.h, [6])      // foot
})

/// The other object in the talk. Not a leaf: one surface, and no second one.
#let screen() = box(width: 284pt, height: 284pt * 9 / 16, {
  place(top + left, rect(width: 100%, height: 100%, fill: t.surface,
                         stroke: 0.6pt + edge, radius: 3pt))
  place(center + horizon, rect(width: 38%, height: 78%,
                               fill: type-fill, stroke: 0.55pt + type-edge))
})

/// A figure with one line under it. One line, always: `alternatives` sizes its
/// box by the largest version, and a caption that wrapped in only one of them
/// would make the whole column taller for all three.
#let plate(caption, ..layers) = block(width: spread-w, {
  stage(..layers)
  v(7pt)
  align(center, text(size: 0.6em, style: "italic", fill: t.muted, caption))
})

// A slide body is a box of fixed height, so short slides cling to the top.
// These two put every body a little above the optical centre, and the same
// pair stands on every slide so nothing shifts from one to the next.
//
// Note that this rules out `#pause`: a pause splits the body into runs and puts
// each run in a block of its own, and an `fr` spacer inside one of those runs
// resolves against the run instead of the slide. It then eats the whole body.
// Where a slide needs steps, it says so with `anim(at: …)`.
#let air-above = v(0.55fr)
#let air-below = v(1fr)

// ═══════════════════════════════════════════════════════════════════════════

== Nothing is wrong with this page

#speaker-note[
  Say nothing for a moment and let them look at it. Somebody always sees it
  before the sentence arrives.
]

#air-above

#side-by-side(
  split: (1fr, 1.15fr),
  gutter: 22pt,
  align: horizon,
  plate([four margins, all the same], even-blocks(1 / 9)),
  [
    Every margin on this spread is the same width. It is quick to set, and it
    is what an unconfigured word processor hands you.

    // Not `#pause`: a pause is only read at the top level of a slide body, and
    // this paragraph lives inside a grid cell. `anim` is the way in here.
    #anim(at: 2, enter: "fade-up")[
      It is also what no printed book has done in five hundred years. The usual
      explanation is taste, and taste is what we call a reason once we have
      stopped saying it out loud.
    ]
  ],
)

#air-below

= What the margins answer to

== Three reasons, none of them taste

// Figure and sentences run off the same steps on purpose: `alternatives` and
// `stagger` are both started at 1 and advance together, so each reason arrives
// with the part of the spread it is about. Nothing else on the slide moves,
// which is the only way the eye notices what did.
#air-above

#side-by-side(
  split: (1fr, 1.2fr),
  gutter: 22pt,
  align: horizon,
  alternatives(
    start: 1,
    align: center + horizon,
    plate([the fold takes its cut], blocks(1 / 9), shade-fold(1 / 9)),
    plate([the hand has to land], blocks(1 / 9), shade-thumb(1 / 9)),
    plate([two blocks, one field], blocks(1 / 9), shade-field(1 / 9)),
  ),
  stagger(
    start: 1,
    spacing: 0.9em,
    [#text(fill: t.strong)[The fold takes its cut.] The inner margin is shared
     with the leaf behind it, and the binding swallows part of what is left.],
    [#text(fill: t.strong)[The hand has to land somewhere.] It lands on the
     fore-edge. A thumb is a centimetre wide and it cannot read.],
    [#text(fill: t.strong)[The eye takes the spread, not the page.] Two blocks
     read as one field only while the gap between them stays the smaller gap.],
  ),
)

#air-below

== The four have names

#air-above

The printer's names say where a margin is rather than how wide it should be:
the #text(fill: t.strong)[back] at the fold, the #text(fill: t.strong)[head] on
top, the #text(fill: t.strong)[fore-edge] under the thumb, the
#text(fill: t.strong)[tail] beneath. In plainer words:

// First link of the chain. Every word that has to survive the flight is
// pinned, because a word and a numeral share no glyph and the shape match
// alone would drop all four. What is *not* pinned (the separators here, the
// two captions two slides on) has no counterpart and fades in place, which is
// what should happen to a character that means something new.
#statement(size: 2.1em, color: t.accent, above: 1.1em, below: 0.7em)[
  #morph(<canon>, match: "glyph")[
    #pin(<m-back>)[inner] · #pin(<m-head>)[head] ·
    #pin(<m-fore>)[outer] · #pin(<m-tail>)[foot]
  ]
]

#anim(at: 2, enter: "fade-up")[
  Written in that order they are not a list but a sequence: each one is wider
  than the one before it, and always by the same amounts.
]

#air-below

== The four have numbers

#air-above

Give the fold one ninth of the leaf's width and the fore-edge two ninths; give
the head one ninth of its height and the tail two ninths. Now there is nothing
left to choose.

// Middle link: the same four pins, so each name lands on its own numeral and
// not on whichever numeral happens to lie nearest.
#statement(size: 2.1em, color: t.accent, above: 1.1em, below: 0.7em)[
  #morph(<canon>, match: "glyph")[
    #pin(<m-back>)[2] : #pin(<m-head>)[3] :
    #pin(<m-fore>)[4] : #pin(<m-tail>)[6]
  ]
]

#anim(at: 2, enter: "fade-up")[
  On a leaf of two to three, the proportion the canon assumes, those four
  fractions come out as four small whole numbers. Change the leaf and the
  numbers change with it, which is the first sign that they are not the rule.
]

#air-below

== Two facts, not four

#air-above

Read the same four across the leaf instead of along the list.

// Last link, and the reason for having a chain at all: the four numerals
// regroup. A still picture of the two rows would say the same words, but only
// the flight shows that these are the *same* four numbers, read a second way.
#statement(size: 1.9em, color: t.accent, above: 1.1em, below: 0.9em)[
  #morph(<canon>, match: "glyph", grid(
    columns: (auto, auto),
    column-gutter: 20pt,
    row-gutter: 12pt,
    align: (right + horizon, left + horizon),
    [#pin(<m-back>)[2] : #pin(<m-fore>)[4]],
    text(size: 0.42em, fill: t.muted)[across the leaf],
    [#pin(<m-head>)[3] : #pin(<m-tail>)[6]],
    text(size: 0.42em, fill: t.muted)[down the leaf],
  ))
]

#anim(at: 2, enter: "fade-up")[
  The fore-edge is twice the fold; the tail is twice the head. That is the
  whole rule, and it is two facts long. What is left over (2 against 3, 4
  against 6) is not a fifth decision but the leaf's own proportion, turning up
  in its margins because the margins were measured off the leaf.
]

#air-below

== Two lines and no numbers

#speaker-note[
  Draw along with them if there is a board. The point of the slide is that the
  hand never leaves the paper to fetch a number.
]

// A construction is a sequence, so it is built as one: each layer is its own
// `anim` and the earlier ones stay put underneath. A `flipbook` was the
// obvious alternative and is wrong here. It runs on a clock, and this figure
// has to wait for whoever is talking.
#air-above

#side-by-side(
  split: (1fr, 1.15fr),
  gutter: 22pt,
  align: horizon,
  stage(
    // Blocks first so that they lie *under* the two lines: the whole claim is
    // that the lines found the block, and a filled rectangle over them would
    // hide the evidence.
    anim(blocks(1 / 9), at: 4, enter: "fade"),
    anim(leaf-diagonal(), at: 2, enter: "fade"),
    anim(spread-diagonal(), at: 3, enter: "fade"),
    anim(carry(1 / 9), at: 4, enter: "fade"),
    anim(canon-labels(1 / 9), at: 5, enter: "fade"),
  ),
  stagger(
    start: 2,
    spacing: 0.85em,
    [The leaf's own diagonal, from the head of the fold to the foot of the
     fore-edge.],
    [The spread's diagonal, which begins on this leaf and ends on the one
     opposite.],
    [Any point on the first line, carried straight across to the second. The
     rectangle that closes between them is a text block.],
    [Its margins measure 2 : 3 : 4 : 6. Nothing was counted, and no number was
     written down.],
  ),
)

#air-below

== It never picks one block

// The same spread three times over, in the same place, with only the block
// changing. Set them side by side instead and the room compares three
// pictures; stacked, there is one picture with one thing moving in it. And
// the thing that does not move is the claim.
#air-above

#side-by-side(
  split: (1fr, 1.2fr),
  gutter: 22pt,
  align: horizon,
  {
    alternatives(
      start: 1,
      align: center + horizon,
      plate([a point high on the diagonal],
            blocks(1 / 14), leaf-diagonal(), carry(1 / 14)),
      plate([the customary ninth],
            blocks(1 / 9), leaf-diagonal(), carry(1 / 9)),
      plate([a point further down],
            blocks(1 / 6), leaf-diagonal(), carry(1 / 6)),
    )
    v(10pt)
    // Fixed under the changing figure, and in a box as wide as the figure so
    // it sits under its middle rather than under the column's.
    block(width: spread-w, align(center,
      text(size: 0.8em, fill: t.accent)[2 : 3 : 4 : 6, in all three]))
  },
  [
    Slide the point along the diagonal and the block changes size. It does not
    change shape. It stays similar to the leaf, and the four margins keep
    their ratio exactly.

    #anim(at: 4, enter: "fade-up")[
      So the construction hands you no measurement. It hands you a family, and
      one member of that family became customary: the one whose block is as
      tall as the leaf is wide.
    ]
  ],
)

#air-below

= The screen

== Three reasons, and the screen has none of them

#speaker-note[
  This is the turn. Take it slowly. Nobody argues with the three reasons, and
  nobody has checked lately whether they still apply.
]

#air-above

#side-by-side(
  split: (1fr, 1.25fr),
  gutter: 22pt,
  align: horizon,
  // Source of the second morph. A drawing has no glyphs to pair, so `"block"`
  // is stated at both ends rather than left to `"auto"`: the runtime reads the
  // target's setting first, and paging backwards swaps which end that is.
  morph(<sheet>, match: "block", stage(blocks(1 / 9))),
  stagger(
    start: 1,
    spacing: 0.9em,
    [There is no facing page. A screen shows one surface, and the next one
     replaces it rather than lying beside it.],
    [There is no fold. Nothing disappears into a binding, so nothing has to be
     paid back to it.],
    [The hand is not on the page. It is on a trackpad, an edge, a scroll wheel.
     And wherever it is, it covers nothing.],
  ),
)

#air-below

== What is left when the reasons go

#air-above

#side-by-side(
  split: (1fr, 1.25fr),
  gutter: 22pt,
  align: horizon,
  // Target of the morph: the spread folds down into the one surface that is
  // left. The flight carries the argument: this object was not replaced, it
  // lost a half.
  morph(<sheet>, match: "block", screen()),
  [
    Two things survive, and neither of them is the canon.

    #stagger(
      start: 2,
      spacing: 0.8em,
      [#text(fill: t.strong)[The measure.] A line the eye can come back from is
       still about sixty characters wide. A window that keeps growing has to be
       told where to stop.],
      [#text(fill: t.strong)[The foot.] Type set hard against the bottom edge
       reads as though it were falling out. That was never a fact about paper.],
    )
  ],
)

#v(0.8em)

#anim(at: 4, enter: "fade")[
  #callout(title: [The question underneath], width: 78%)[
    The ninths were an answer. Copy them onto a screen and you have copied the
    answer without the question.
  ]
]

#air-below
