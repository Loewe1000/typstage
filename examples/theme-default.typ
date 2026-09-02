// themes.default: a talk in a bright room.
//
// "How GPS Knows Where You Are": ranging, trilateration, and the fourth
// satellite that solves for time instead of place.
//
//   typst compile theme-default.typ theme-default.html --format html --features html
//   typst compile theme-default.typ theme-default.pdf

#import "@preview/typstage:0.1.1": *

// A theme is a dictionary, so its colours are available to our own drawings.
#let t = themes.default

// Three meaning colours, fixed once here and handed to every drawing and card
// that needs them. Nothing below reaches for a colour of its own.
#let ring = rgb("#3a6ea5") // a satellite and the range ring it draws
#let sky = rgb("#eef2f7") // the panel the map view sits on
#let fix = t.accent // a candidate position, and the fix
#let faster = rgb("#6f8f57") // a clock that runs fast (gravity)
#let slower = rgb("#8a5a9e") // a clock that runs slow (speed)

#show: presentation.with(
  theme: t,
  title: [How GPS Knows Where You Are],
  subtitle: [Four satellites, three unknowns, and a clock nobody trusts],
  author: [Institute of Geodesy],
  date: [17 April 2026],
  transition: "slide",
)


// ═══════════════════════════════════════════════════════════════════════════
//  The map view
// ═══════════════════════════════════════════════════════════════════════════
//
// One drawing serves two slides: the construction on "Each range is a ring"
// and the flipbook on "A millisecond is three hundred kilometres". That reuse
// is the point. When the picture comes back with the rings pulled apart, the
// audience already knows what it is looking at and can spend its attention on
// what changed.
//
// Everything is in plain numbers of points and multiplied by `1pt` where it is
// placed. `calc.sqrt` will not take a length, and carrying units through the
// geometry below would mean converting back and forth at every step.

#let map-w = 372.0
#let map-h = 232.0

// Three satellites and the receiver. The receiver's position is chosen first;
// the ranges then follow from it, so the rings meet exactly by construction
// and no radius has to be tuned by hand.
//
// The positions are picked so that each ring stays mostly inside the frame and
// visibly *encircles* its own satellite. A first attempt put the satellites in
// the corners; the ranges were then over 130pt in a 200pt frame, only a shallow
// arc of each ring survived the clipping, and the drawing read as three loose
// curves that happened to cross rather than as three distances.
#let sats = ((108.0, 68.0), (268.0, 70.0), (180.0, 189.0))
#let me = (187.0, 117.0)

#let dist(a, b) = calc.sqrt(
  calc.pow(b.at(0) - a.at(0), 2) + calc.pow(b.at(1) - a.at(1), 2),
)
#let ranges = sats.map(s => dist(s, me))

// Where two rings cross. `side` picks which of the two crossings: +1 is the
// one the receiver is standing on, -1 the other candidate.
//
// Computed rather than written down: the second crossing of rings 1 and 2 is
// what the middle panel of the construction marks, and if a satellite is ever
// moved, a hand-copied coordinate would quietly point at nothing.
#let cross(a, ra, b, rb, side) = {
  let dx = b.at(0) - a.at(0)
  let dy = b.at(1) - a.at(1)
  let d = calc.sqrt(dx * dx + dy * dy)
  let m = (d * d + ra * ra - rb * rb) / (2 * d)
  let h = calc.sqrt(calc.max(ra * ra - m * m, 0.0))
  let (ux, uy) = (dx / d, dy / d)
  (a.at(0) + m * ux - side * h * uy, a.at(1) + m * uy + side * h * ux)
}

#let ghost = cross(sats.at(0), ranges.at(0), sats.at(1), ranges.at(1), -1)

// A dot at `p`, either hollow (a candidate) or filled (the answer). Called
// `mark`, not `dot`: a `#let dot` at the top of a deck shadows Typst's own
// `dot` inside every equation further down, and `c dot.op Delta t` then fails
// with "cannot access fields on user-defined functions".
#let mark(p, solid: false) = place(
  dx: (p.at(0) - 6.5) * 1pt,
  dy: (p.at(1) - 6.5) * 1pt,
  circle(radius: 6.5pt, fill: if solid { fix } else { none }, stroke: 2.2pt + fix),
)

/// The panel itself.
///
/// `rings` is how many satellites are drawn, `bias` is added to every radius.
/// That single number is the whole clock story: at `0.0` the rings meet, and
/// at anything else they do not.
#let map-frame(rings: 3, bias: 0.0, candidates: (), fix-at: none, readout: none) = box(
  width: map-w * 1pt,
  height: map-h * 1pt,
  clip: true,
  {
    place(rect(width: 100%, height: 100%, fill: sky, stroke: none))
    for i in range(rings) {
      let s = sats.at(i)
      let r = ranges.at(i) + bias
      if r > 0 {
        place(
          dx: (s.at(0) - r) * 1pt,
          dy: (s.at(1) - r) * 1pt,
          circle(radius: r * 1pt, fill: none, stroke: 1.6pt + ring),
        )
      }
    }
    for p in candidates { mark(p) }
    if fix-at != none { mark(fix-at, solid: true) }
    // The satellites go on top of their own rings: a ring passing through the
    // marker of another satellite would read as the two touching.
    for i in range(rings) {
      let s = sats.at(i)
      place(
        dx: (s.at(0) - 8) * 1pt,
        dy: (s.at(1) - 8) * 1pt,
        circle(
          radius: 8pt,
          fill: ring,
          stroke: 2.5pt + sky,
          align(center + horizon, text(size: 9pt, weight: "bold", fill: white, str(i + 1))),
        ),
      )
    }
    if readout != none { place(bottom + left, dx: 11pt, dy: -10pt, readout) }
  },
)


// ═══════════════════════════════════════════════════════════════════════════

= Distance from a clock

== What a satellite actually sends

#speaker-note[
  The last point is the one people miss: the satellite is not answering a
  question. It is shouting into the dark, and the arithmetic happens entirely
  in the listener's pocket.
]

#stagger(
  [#text(fill: t.strong, weight: "bold")[Where I am.] Its own orbit, good to a
   metre or two, refreshed every couple of hours.],
  [#text(fill: t.strong, weight: "bold")[What time it is.] The instant the
   message left, read off an atomic clock on board.],
  [Subtract the second from your own clock and you have a travel time. Multiply
   by the speed of light and you have a distance: a *range*.],
)

#v(0.9em)

#anim(
  callout(title: [Worth noticing])[
    Nothing in the broadcast is about you. The satellite does not know you are
    listening, and every receiver on the planet reads the same words.
  ],
  enter: "rise",
)

== Each range is a ring

#speaker-note[
  Say out loud that this is a flat slice. Spheres come on the next slide.
  Nobody is confused by the simplification if it is named.
]

#v(1fr)

// Two `alternatives` on the same `start:`. The picture and the sentence about
// it change together, on one step. Written as one alternatives each rather
// than three anims, because the whole claim is that it is *the same picture*
// with one more constraint: same box, same place, nothing around it moving.
#side-by-side(
  split: (auto, 1fr),
  alternatives(
    start: 1,
    align: center + horizon,
    map-frame(rings: 1),
    map-frame(rings: 2, candidates: (me, ghost)),
    // The rejected candidate stays on the panel, still hollow: the sentence
    // says the third ring passes through one of *them*, and it can only say
    // that while both are still visible.
    map-frame(rings: 3, candidates: (ghost,), fix-at: me),
  ),
  text(size: 0.78em, alternatives(
    start: 1,
    align: left + horizon,
    [One range. You are somewhere on this ring, and the ring says nothing about
     where.],
    [A second ring crosses the first in *two* places. Two candidates, no way to
     choose.],
    [A third ring passes through exactly one of them. That point is you.],
  )),
)

#v(0.7em)

#align(center, text(size: 0.62em, fill: t.muted)[
  A flat slice through the problem. Schematic, not to scale.
])

#v(1fr)

== Two answers, one of them absurd

// A quiet slide between the construction and the flipbook. It carries the lift
// from flat to solid, which is a step of *understanding* rather than of
// sequence. An animation here would only invite the audience to watch instead
// of think.

#v(1fr)

Lift that into three dimensions and every ring becomes a sphere.

#v(0.5em)

Two spheres meet in a circle. Three spheres meet that circle in two points.
One of those points sits thousands of kilometres above the ground, travelling
at a speed nothing on Earth travels at. Throw it away.

#v(1em)

#card(title: [So we are finished])[
  Three satellites, three ranges, one position. The receiver needs no
  transmitter, no subscription and no help from the ground.
]

#v(1fr)


= The clock in your pocket

== A millisecond is three hundred kilometres

#speaker-note[
  Let the loop run twice before saying anything. The rings only agree for a
  fraction of a second each time round, and that is the whole slide: agreement
  is a knife-edge in one number nobody has measured.
]

// The bias sweeps through zero and back, twice per loop. Written from a sine
// so that frame 0 and the frame after the last are the same state. `flipbook`
// places its frames at `i / frames` when looping, which lands just short of
// the full turn and closes the loop without a repeated frame.
//
// A still picture cannot make this argument. It can show rings that meet or
// rings that do not; it cannot show that the difference between the two is one
// continuous number passing through zero.
#let clock-frame(frac) = {
  let ms = 0.5 * calc.sin(2 * calc.pi * frac)
  let agree = calc.abs(ms) < 0.03
  // Two decimals by hand: `str(calc.round(0.5, digits: 2))` gives "0.5", and a
  // readout whose width jumps around draws the eye to the wrong thing.
  let n = int(calc.round(calc.abs(ms) * 100))
  let sign = if agree { "" } else if ms > 0 { "+" } else { "\u{2212}" }
  let label = sign + "0." + (if n < 10 { "0" + str(n) } else { str(n) }) + " ms"
  map-frame(
    rings: 3,
    bias: 46.0 * ms,
    fix-at: if agree { me } else { none },
    readout: box(
      fill: white,
      inset: (x: 7pt, y: 4pt),
      radius: 4pt,
      text(size: 0.45em, fill: if agree { fix } else { t.muted },
           "your clock: " + label),
    ),
  )
}

#v(1fr)

#side-by-side(
  split: (auto, 1fr),
  flipbook(clock-frame, frames: 26, fps: 12, width: map-w * 1pt, height: map-h * 1pt,
           still: clock-frame(0.25)),
  text(size: 0.78em)[
    Your phone keeps time with a quartz crystal. It is wrong by something like
    a millisecond.

    #statement(size: 1.1em, color: fix)[$1 "ms" times c approx 300 "km"$]

    The same error goes into all three ranges at once, so all three rings grow
    or shrink together. Then no point lies on all of them.
  ],
)

#v(1fr)

== Three unknowns

#speaker-note[
  This slide is only here so the next one can happen. Read the tuple aloud and
  move on.
]

#v(1fr)

// Source of the morph. The three coordinates are pinned so that each flies to
// its own place on the next slide instead of to whichever letter happens to be
// nearest. The tuple grows a fourth entry, so everything after `x` shifts.
#statement(color: fix)[
  #morph(<unknowns>, $ (#pin(<x>, $x$), #pin(<y>, $y$), #pin(<z>, $z$)) $)
]

#v(0.4em)

// The equation flies too, and it is the more important of the two: the claim
// is that the next slide shows the *same* equation, not a new one.
#align(center, morph(<ranges>, inline: false, $
  sqrt((x - x_i)^2 + (y - y_i)^2 + (z - z_i)^2) = c dot.op Delta t_i
$))

#v(0.6em)

// `at: 2`, not `auto`. A morph does not consume a step. It has to stand from
// the moment the slide is entered, or there would be nothing for the previous
// slide to fly to, so `auto` here would resolve to step 1 and the sentence
// would arrive together with the formula it comments on.
//
// Held to 76% of the width: at full width the sentence broke after "is the"
// and left "truth." alone on a centred second line.
#anim(align(center, block(width: 76%, text(size: 0.8em)[
  Three satellites, #box($i = 1, 2, 3$): three equations, three unknowns, and
  a solution: as long as #box($Delta t_i$) is the truth.
])), at: 2)

#v(1fr)

== Four unknowns

#speaker-note[
  The turn of the talk. Let the flight finish before the sentence: the point is
  that only one thing changed, and it is not the geometry.
]

#v(1fr)

// Target of the morph. `b` has no pin and no counterpart, so it simply appears
// where the others come to rest, which is exactly the reading we want: the
// tuple did not change, it grew.
#statement(color: fix)[
  #morph(<unknowns>, $ (#pin(<x>, $x$), #pin(<y>, $y$), #pin(<z>, $z$), b) $)
]

#v(0.4em)

#align(center, morph(<ranges>, inline: false, $
  sqrt((x - x_i)^2 + (y - y_i)^2 + (z - z_i)^2) = c dot.op (Delta t_i - b)
$))

#v(0.6em)

// A step of its own, after the flight has landed: the whole point is that only
// the unknowns changed, and a sentence appearing mid-flight would compete with
// the one thing worth watching.
#anim(
  callout(title: [The fourth satellite])[
    It does not sharpen your position. It solves for #box($b$), the error in
    your own clock. And a phone that has done this is holding atomic time as a
    by-product.
  ],
  at: 2,
  enter: "rise",
)

#v(1fr)


= The clocks in orbit

== Two effects, opposite signs

#v(1fr)

// A grid rather than two anims: the tiles are a comparison, and a comparison
// wants both halves built the same way. They arrive one after the other so the
// second lands as a contradiction of the first.
#tiles(
  columns: 2,
  card(title: [Gravity], color: faster)[
    Twenty thousand kilometres up the field is weaker, and a clock there ticks
    *faster*, by about #text(fill: faster, weight: "bold")[+45 µs] a day.
  ],
  card(title: [Speed], color: slower)[
    The same satellite circles at #box[3.9 km/s], and a moving clock ticks
    *slower*,
    by about #text(fill: slower, weight: "bold")[−7 µs] a day.
  ],
)

#v(0.8em)

#anim(statement(size: 1.3em, color: fix)[$+45 - 7 = +38 "µs" slash "day"$])

#anim(align(center, text(size: 0.8em)[
  They do not cancel. Gravity wins by a factor of six, and the satellites'
  clocks run away from yours.
]))

#v(1fr)

== The correction is a factory setting

#v(1fr)

#anim(statement(size: 1.35em, color: fix)[
  $38 "µs" times c approx 11 "km"$
])

#anim(align(center, text(size: 0.85em)[
  Every day, if nobody did anything about it.
]))

#v(0.9em)

#anim(callout(title: [And nobody does, in flight])[
  The oscillator on each satellite is built to run at 10.229 999 995 43 MHz, so
  that from the ground it is heard at 10.23 MHz. The relativity correction is
  not code that runs somewhere. It was ground into the crystal before launch.
], enter: "rise")

#v(1fr)
