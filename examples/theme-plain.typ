// Simpson's paradox. A talk built out of one real data set.
//
//   typst compile --root .. --features html --format html theme-plain.typ theme-plain.html
//   typst compile --root .. theme-plain.typ theme-plain.pdf
//
// The numbers are two of the treatments compared by Charig, Webb, Payne and
// Wickham in the British Medical Journal in 1986, 350 patients each. They are
// reproduced unchanged: the paradox only lands if the arithmetic is checkable
// on the spot, and made-up figures invite the audience to look for the trick
// in the figures rather than in the grouping.
//
//   A  small 81/87 = 93 %   large 192/263 = 73 %   all 273/350 = 78 %
//   B  small 234/270 = 87 % large  55/80  = 69 %   all 289/350 = 83 %
//
// `themes.plain` is used as it comes. The talk is a table talk: the slides
// carry few words and large numbers, and the design has nothing to add.

#import "@preview/typstage:0.1.1": *

// Two hues and a grey, fixed once here and handed to every helper below.
// A colour in this deck always names "one of the two things being compared":
// treatment A against treatment B, the left cluster against the right one. It
// never means "good". Which side is ahead is carried by weight and by a tinted
// cell instead, so that the reversal shows up as the tint jumping columns
// while the columns themselves keep their identity.
#let hue-a = rgb("#12664f")
#let hue-b = rgb("#a3541f")
#let quiet = luma(45%)

// One column spec, shared by every table in the deck. The rows are separate
// blocks rather than rows of a real `table`, for two reasons: a row can then
// be wrapped in `anim` (`#pause` is not seen inside a table cell), and the
// identical spec puts the numbers in the same place on both slides that carry
// them. That is what makes the swap on the turning slide legible.
#let cols = (215pt, 1fr, 1fr)

// A percentage with a thin space before the sign. At 1.7em a full word space
// pulls the sign off its number far enough that the pair stops reading as one
// value, which is the one thing these slides cannot afford.
#let pc(n) = [#n#h(0.16em)%]

// A single rate. `sub` carries the raw counts, so nobody has to take the
// percentage on trust. This talk asks the room to check the arithmetic.
// `best` tints the cell in its own column colour; that tint is the only mark
// of "better" anywhere in the deck, and watching it change columns is the
// whole point of the slide it was built for.
#let rate(value, sub, colour, best: false) = align(center, block(
  width: 168pt,
  radius: 5pt,
  fill: if best { colour.lighten(90%) } else { none },
  inset: (x: 6pt, y: 8pt),
  align(center, {
    set block(spacing: 3pt)
    block(text(size: 1.7em, fill: if best { colour } else { quiet },
               weight: if best { "bold" } else { "regular" }, pc(value)))
    block(text(size: 0.6em, fill: quiet, tracking: 0.4pt, sub))
  }),
))

// One composition bar: the light part is the easy cases, the dark part the
// hard ones, and the counts sit inside their own segment so no legend is
// needed. A ratio is a length, and a length is the one thing a reader takes
// in without arithmetic.
#let bar(small, small-share, large, large-share) = block(width: 100%, stack(dir: ltr,
  block(width: small-share, height: 34pt, fill: luma(84%), inset: (x: 10pt),
        align(horizon, text(size: 0.62em, fill: luma(25%), tracking: 0.3pt,
                            [#small small]))),
  block(width: large-share, height: 34pt, fill: luma(30%), inset: (x: 10pt),
        align(horizon, text(size: 0.62em, fill: white, tracking: 0.3pt,
                            [#large large]))),
))

#let head-row = grid(
  columns: cols, column-gutter: 12pt, align: bottom,
  [],
  align(center, text(size: 0.72em, fill: hue-a, tracking: 1.2pt, upper[Treatment A])),
  align(center, text(size: 0.72em, fill: hue-b, tracking: 1.2pt, upper[Treatment B])),
)

#let data-row(label, a, a-sub, b, b-sub, best: none) = grid(
  columns: cols, column-gutter: 12pt, align: horizon,
  text(size: 0.92em, label),
  rate(a, a-sub, hue-a, best: best == "a"),
  rate(b, b-sub, hue-b, best: best == "b"),
)

// The two readings of the study, as two blocks of exactly the same height so
// that `alternatives` can swap them without anything moving. The height is
// set by hand rather than left to the content: the pooled reading has one row
// and the split reading has two, and if the box grew the header line would
// slide upwards and take the eye with it.
#let panel(body, caption) = block(width: 100%, height: 214pt, {
  body
  place(bottom + left, text(size: 0.78em, fill: quiet, caption))
})

// The scatter plot for the flipbook, drawn in plain Typst.
//
// `u` blends between the two readings: 0 is one grey cloud with one falling
// least-squares line, 1 is two coloured clusters with their own rising lines.
// `both` overrides the blend and draws every line at full strength. The
// printed page gets one frame only, and the frame worth printing is the one
// where all three lines are visible at the same time.
//
// The line endpoints are least-squares fits of exactly these twenty points,
// evaluated once at the ends of each x-range:
//   left cluster   slope +0.734    right cluster  slope +0.795
//   all twenty     slope -0.747
#let dots-one = ((0.14, 0.58), (0.19, 0.66), (0.24, 0.62), (0.28, 0.72),
                 (0.32, 0.70), (0.36, 0.78), (0.40, 0.76), (0.22, 0.55),
                 (0.34, 0.83), (0.17, 0.72))
#let dots-two = ((0.56, 0.18), (0.60, 0.26), (0.64, 0.22), (0.68, 0.33),
                 (0.72, 0.30), (0.76, 0.38), (0.80, 0.36), (0.62, 0.15),
                 (0.74, 0.43), (0.58, 0.32))

#let cloud(u, both: false) = {
  let w = 430pt
  let h = 248pt
  let pad = 20pt
  let px(x) = pad + x * (w - 2 * pad)
  let py(y) = h - pad - y * (h - 2 * pad)
  let fade(c, a) = c.transparentize(100% * (1 - a))
  let pooled-alpha = if both { 1.0 } else { 1.0 - u }
  let group-alpha = if both { 1.0 } else { u }
  let dot(x, y, c) = place(top + left, dx: px(x) - 3.4pt, dy: py(y) - 3.4pt,
                           circle(radius: 3.4pt, fill: c, stroke: none))
  let seg(x1, y1, x2, y2, c, a) = place(top + left,
    line(start: (px(x1), py(y1)), end: (px(x2), py(y2)),
         stroke: 2.2pt + fade(c, a)))

  block(width: w, height: h, {
    // The axis box, so the eye has something fixed to judge the slopes
    // against while the lines swing.
    place(top + left, dx: pad, dy: pad,
          rect(width: w - 2 * pad, height: h - 2 * pad,
               fill: none, stroke: 0.6pt + luma(86%)))
    // The dots do not move; they only take on their group's colour. That is
    // the honest way to show it. Anything that shifted a point would make
    // the reversal an artefact of the drawing.
    let tint(c) = color.mix((luma(62%), 100% * (1 - group-alpha)), (c, 100% * group-alpha))
    for p in dots-one { dot(p.at(0), p.at(1), tint(hue-a)) }
    for p in dots-two { dot(p.at(0), p.at(1), tint(hue-b)) }
    seg(0.14, 0.7375, 0.80, 0.2444, quiet.darken(25%), pooled-alpha)
    seg(0.14, 0.5995, 0.40, 0.7903, hue-a, group-alpha)
    seg(0.56, 0.2056, 0.80, 0.3964, hue-b, group-alpha)
  })
}

#show: presentation.with(
  theme: themes.plain,
  title: [Two treatments, one reversal],
  subtitle: [Simpson's paradox, and which of the two numbers to believe],
  author: [Statistics seminar],
  date: [17 September 2026],
  transition: "fade",
  transition-duration: 380,
  duration: 460,
  // Everything the slides share goes through the hook, not through a `#set`
  // rule in the document: the moving parts are typeset a second time in a
  // frame of their own, and that frame never sees a document-level rule. A
  // flying number that suddenly lost its letter spacing would give the trick
  // away.
  style: it => {
    set par(justify: false, leading: 0.72em)
    // A slide body is a box of fixed height, so a short slide would cling to
    // the top edge under its title. Every slide here is short on purpose.
    // The numbers need the air, so all of them are centred at once.
    v(1fr)
    it
    v(1fr)
  },
)

= The question

== Two treatments, 700 patients

#speaker-note[
  Do not give away that anything is wrong yet. This slide is the setup, and
  the setup has to be believed.
]

A hospital compared several ways of removing kidney stones. Take two of them.

#v(0.5em)

#stagger(
  [*Treatment A*: open surgery. 350 patients.],
  [*Treatment B*: a puncture instead of a cut. 350 patients.],
  [*Success* means the stones were gone afterwards. 562 of the 700 succeeded.],
)

#v(1.1em)

#text(size: 0.66em, fill: quiet)[
  Charig, Webb, Payne and Wickham, British Medical Journal 292 (1986), 879–882.
]

== The obvious answer

// The two cells appear one after the other, not together. A number that is
// already on screen beside another number gets compared before it gets read;
// one keypress apart, each is read on its own first.
#head-row
#v(4pt)

#grid(
  columns: cols, column-gutter: 12pt, align: horizon,
  text(size: 0.9em)[All 350 patients],
  anim(rate([78], [273 of 350], hue-a), enter: "fade-up"),
  anim(rate([83], [289 of 350], hue-b, best: true), enter: "fade-up"),
)

#v(1.2em)

#anim(statement(size: 1.25em)[Five points apart, on 700 patients. Take B.],
      enter: "fade-up")

= A second look

== One table, two ways to add it up

#speaker-note[
  This is the slide the talk exists for. Press once, then say nothing at all
  until somebody in the room objects.
]

// The turn. `alternatives` puts both readings in the same box at the same
// place. The first version is the pooled table, standing there the moment the
// slide arrives. The room recognises it from two slides ago. One
// keypress swaps in the split one. Nothing else on the slide moves, no number
// is recomputed, and the tint jumps from the right column to the left. Every
// other animation in this deck was chosen so that this one has the stage.
#alternatives(
  enter: "fade",
  panel(
    {
      head-row
      v(4pt)
      data-row([All 350 patients], [78], [273 of 350], [83], [289 of 350],
               best: "b")
    },
    [Every patient counted once.],
  ),
  panel(
    {
      head-row
      v(4pt)
      data-row([Small stones], [93], [81 of 87], [87], [234 of 270],
               best: "a")
      v(6pt)
      data-row([Large stones], [73], [192 of 263], [69], [55 of 80],
               best: "a")
    },
    [Every patient counted once.],
  ),
)

== Nothing was recomputed

#statement(size: 1.3em)[
  Same 700 patients. Same 562 successes. Different grouping.
]

#v(0.6em)

// `at: 2` rather than `auto`: the first automatic step of a slide is the
// slide's arrival, so `auto` here would put the box on screen together with
// the sentence above it. The sentence needs to be read first.
#anim(at: 2, callout(title: [Both at once], color: quiet)[
  B is better over all patients. A is better among the small stones, and A is
  better among the large stones. There is no third group and no rounding
  trick. Every one of these four statements is true.
], enter: "fade-up")

== Who got which treatment

#speaker-note[
  The bar for A first, on its own. Let them see three quarters dark before
  B's bar shows up underneath.
]

#stagger(
  spacing: 2.2em,
  {
    text(size: 0.78em, fill: hue-a, tracking: 1.2pt, upper[Treatment A])
    v(5pt)
    bar([87], 24.9%, [263], 75.1%)
  },
  {
    text(size: 0.78em, fill: hue-b, tracking: 1.2pt, upper[Treatment B])
    v(5pt)
    bar([270], 77.1%, [80], 22.9%)
  },
)

#v(0.6em)

#anim(statement(size: 1.15em)[
  The surgeons sent the hard cases to A.
], enter: "fade-up")

== Where the 78 % comes from

// Source of the morph. Target is the next slide. A morph only reaches its
// neighbour, so these two slides have to stay adjacent.
#align(center, morph(<rate>, text(size: 2.4em,
  $#pin(<num>, [273]) / #pin(<den>, [350])$)))

#v(1.4em)

#anim(at: 2, statement(size: 1.15em)[
  One numerator, one denominator, no groups anywhere in it.
], enter: "fade-up")

== The pool is an average with lopsided weights

// Target of the morph. Both halves of the fraction carry the *same* pin name
// twice: the runtime looks the source up by name and then iterates over the
// targets, so 273 visibly tears into 81 and 192 while 350 tears into 87 and
// 263. That split is the argument. Pooling is not a mistake in the
// arithmetic, it is a choice about how to group the very same counts.
#align(center, morph(<rate>, text(size: 2.4em,
  $(#pin(<num>, [81]) + #pin(<num>, [192])) / (#pin(<den>, [87]) + #pin(<den>, [263]))$)))

#v(1.1em)

#anim(at: 2, statement(size: 1.1em)[
  $78 thin % = 87/350 dot 93 thin % + 263/350 dot 73 thin %$
], enter: "fade-up")

#anim(at: 3, align(center, text(size: 0.95em)[
  A's own rate of 73 % gets three quarters of the weight, because three
  quarters of A's patients were the hard cases.
]), enter: "fade-up")

== The same shape without a table

#side-by-side(
  split: (1.35fr, 1fr),
  align: horizon,
  // Twenty points, two clusters, three least-squares lines, all of them
  // computed once and written into the code below as endpoints. A still
  // picture can show the falling line or the two rising ones; it cannot show
  // the one turning into the other, and the turning is the whole content.
  // `pingpong` keeps it turning both ways, which is also what a viewer needs
  // in order to believe that no point moved.
  flipbook(
    frames: 26, fps: 26, pingpong: true, width: 430pt, height: 248pt,
    still: cloud(1.0, both: true),
    t => cloud(calc.clamp((t - 0.18) / 0.5, 0.0, 1.0)),
  ),
  {
    stagger(
      [Within the left cluster the line rises.],
      [Within the right cluster it rises too.],
      [Over all twenty points it falls.],
    )
    v(0.7em)
    anim(text(size: 0.9em, fill: quiet)[
      No point is added, removed or moved. Only the question of what counts as
      one group changes.
    ], enter: "fade")
  },
)

== Which number is right?

// Both cards the same height. Without `equal` each one stands as tall as its
// own text, and two boxes of the same weight look like two of different
// weight.
#side-by-side(
  split: (1fr, 1fr),
  equal: true,
  align: top,
  card(title: [If you run the hospital], color: quiet)[
    "What share of our patients recovered last year?" That is the pooled
    number. 83 % against 78 % is the honest record of what happened,
    assignment habits included.
  ],
  card(title: [If you are the patient], color: quiet)[
    "My stone is large. What should I be given?" The split number: 73 %
    against 69 %. The pooled figure is about other people's stones.
  ],
)

#v(0.7em)

#anim(at: 2, callout(title: [The rule], color: quiet)[
  Split by something that influenced *which treatment was given*, and the
  split numbers are the ones to act on. Split by something the treatment
  itself caused, and splitting destroys the answer.
], enter: "fade-up")

==

#statement(size: 1.5em)[
  Which number is right is not a question about the data.\
  It is a question about how the data came about.
]
