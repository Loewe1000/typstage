// A drawing that comes into being while the room watches.
//
//   typst compile zeichnen.typ zeichnen.html --format html --features html
//   typst compile zeichnen.typ zeichnen.pdf
//
// "The Metre That Almost Was": five lengths of string, one stopwatch, and why
// a pendulum that beats seconds is 99.4 cm long -- the length the French very
// nearly called a metre in 1791.
//
// Two ways of drawing, each on what it is made for. The diagrams grow in
// stages (`build`), because a lilaq diagram is 64 stroked paths -- grid,
// ticks, frame, marks -- and a pen would set off along all of them at once.
// The geometry is drawn with a pen (`enter: "draw"`), because it is six long
// strokes over three steps and an eye can follow every one of them. The manual
// counts out which drawing packages hand out outlines that can be traced.
//
// This deck needs two foreign packages, and the build already needed both:
// the manual imports cetz 0.5.2 and lilaq 0.6.0 the same way, and the example
// check compiles those. They resolve from the package cache or are fetched on
// first compile.

#import "@preview/typstage:0.1.0": *
#import "@preview/cetz:0.5.2"
#import "@preview/lilaq:0.6.0" as lq

// Theme and palette separately, which no other example does. The layout is the
// default one; the colours are those of a German maths textbook. A palette is
// only the eight colours, so anything the deck draws itself reaches into `p`
// and not into `t`: the theme keeps its own accent, and a drawing that used it
// would sit in one colour on slides in another.
#let t = themes.default
#let p = palettes.textbook

// Three meaning colours, fixed once and handed in everywhere. They follow the
// convention of the textbook this palette was measured from: vermilion is what
// we measured, blue is what the theory claims, grey is a construction line,
// which is neither.
#let messung = p.strong
#let modell = p.accent
#let hilfs = p.muted

#show: presentation.with(
  theme: t,
  palette: p,
  title: [The Metre That Almost Was],
  subtitle: [Five lengths of string, one stopwatch, and the second that
             nearly defined the metre],
  author: [Physics · Year 11],
  date: [12 October 2026],
  // A plain cross-fade. Four slides carry a drawing that builds itself, and a
  // page that shoves the last one aside would be the largest movement on a
  // slide whose whole point is a much smaller one.
  transition: "fade",
  transition-duration: 420,
  duration: 520,
  // Most bodies here are one figure and two lines. Without this they cling to
  // the top edge with the drawing hanging under the title.
  style: it => { set par(justify: false); v(1fr); it; v(1fr) },
)

// ── The measurements ────────────────────────────────────────────────────────
// Five lengths, each timed over ten swings. Checkable rather than decorative:
// 2π·sqrt(L/9.81) gives 0.897, 1.269, 1.554, 1.794 and 2.006, so what stands
// below is a few milliseconds of scatter and not invented numbers.

#let laenge = (0.20, 0.40, 0.60, 0.80, 1.00)   // m
#let dauer = (0.90, 1.28, 1.55, 1.79, 2.01)    // s
#let wurzel = laenge.map(calc.sqrt)

// The same five for the table. Written out rather than computed: Typst drops a
// trailing zero, and a column of measurements in which 0.20 reads as 0.2 says
// the stopwatch was read to one digit when it was read to two.
#let messwerte = (([0.20], [0.90]), ([0.40], [1.28]), ([0.60], [1.55]),
                  ([0.80], [1.79]), ([1.00], [2.01]))

// The two claims, sampled finely enough that neither shows its corners.
#let fein = range(1, 53).map(i => i * 0.02)              // 0.02 … 1.04
#let gerade = fein.map(l => 2.01 * l)                    // T ~ L
#let bogen = fein.map(l => 2.006 * calc.sqrt(l))         // T = 2π sqrt(L/g)

// Two points are enough for a straight line, and a straight line drawn from
// two points cannot bend where nobody looked.
#let stuetze = (0, 1.06)


= A clock made of string

== What sets the beat?

#speaker-note[
  Take the guesses before showing anything. Somebody always says the mass, and
  that guess has to be in the room before it is knocked down -- otherwise the
  measurement answers a question nobody asked.
]

A pendulum keeps time. Something about it must decide how fast.

// `easing: "out-quad"` on the list. Three candidates that are equally likely
// as far as the class knows should arrive at an even pace, without the small
// run-up the house curve gives each of them.
#stagger(easing: "out-quad", start: 2)[
  - the *mass* of the bob -- a heavier weight, a slower swing?
  - the *width* of the swing -- a longer way to travel, a longer time?
  - the *length* of the string -- and if so, in what proportion?
]

#anim(callout(title: [Two of the three are out after one lesson])[
  Hang a rubber and a bolt on strings of the same length: they keep step.
  Start one at $5degree$ and one at $20degree$: over ten swings they drift by
  a fourteenth of a swing. Only the third candidate is left, and that one has a
  number to it.
], at: 5, enter: "fade-up")

== Five lengths, one stopwatch

#speaker-note[
  Ten swings and divide, never one. A stopwatch is worth about a tenth of a
  second in a human hand, and a tenth spread over ten swings is a hundredth.
]

#side-by-side(
  split: (1fr, 1.3fr),
  align: top,
  card(title: [What was measured])[
    #v(0.3em)
    #table(
      columns: (auto, auto),
      align: (right, right),
      inset: (x: 10pt, y: 5pt),
      stroke: (x, y) => if y == 0 { (bottom: 0.6pt + p.ink) }
                        else { (bottom: 0.3pt + p.border) },
      table.header([$L$ in m], [$T$ in s]),
      ..messwerte.flatten(),
    )
    #v(0.3em)
  ],
  stagger(start: 2)[
    - Five strings, a nut on the end of each, ten swings timed and divided
      by ten.
    - Double the length from $0.20$ to $0.40$ and the period goes from
      $0.90$ to $1.28$ -- not to $1.80$.
    - Double it again to $0.80$ and it goes to $1.79$. Doubling the length
      does *not* double the period.
    - Whatever the rule is, it is not proportionality. So plot it.
  ],
)

== The points refuse a straight line

#speaker-note[
  Let the straight line stand for a moment before the curve comes. It is the
  guess the class made two slides ago, and it deserves to be seen failing at
  the short end, where it is worst.
]

// A lilaq diagram is one piece: Typst hands out the finished setting, and what
// was a data series in it cannot be reached from outside any more. So the
// drawing is asked for once per stage, and `from` says which piece is due
// when. The measured points carry no number and therefore stand there from the
// first stage on.
//
// Why a piece that is not due yet is made of air rather than left out: lilaq
// computes its axes over everything it is handed. A series that was missing
// would take its share of the scale with it, and the ticks would jump the
// moment the curve arrived. A colour becomes the same colour with alpha 0, so
// the series is still in the data and still worth nothing to the eye.
//
// The `anim` above the drawing is not decoration. Entering a slide shows no
// entrances -- the runtime only restores the state -- so a drawing on step one
// would simply be there, and would never be seen to grow. It needs a step in
// front of it.
#anim[The five points, and the proportionality we half expected.]

#align(center, build(from => lq.diagram(
  width: 18cm, height: 6.1cm,
  xlabel: [length $L$ in m], ylabel: [period $T$ in s],
  xlim: (0, 1.08), ylim: (0, 2.3),
  legend: (position: bottom + right),
  lq.scatter(laenge, dauer, color: messung, size: (170,) * 5,
             label: [measured]),
  // Stage 2: the guess. Its entry in the legend has to be made of air as well
  // -- a name standing there while its line is still missing is the one thing
  // that is easy to forget.
  lq.plot(fein, gerade, color: from(2, hilfs), mark: none,
          stroke: from(2, (paint: hilfs, thickness: 1.2pt, dash: "dashed")),
          label: from(2, [$T tilde L$])),
  // Stage 3: what the points actually do.
  lq.plot(fein, bogen, color: from(3, modell), mark: none,
          stroke: from(3, 1.6pt + modell),
          // The vinculum of the root rises above the line box lilaq gives the
          // legend row, and without this it underlines the row above it.
          label: from(3, box(inset: (top: 2.5pt))[$T tilde sqrt(L)$])),
), steps: 3))

#anim[At $L = 0.20$ the straight line asks for $0.40$ s and the stopwatch said
      $0.90$. That is not a bad line, it is a different shape.]

== Take the root and it straightens

#speaker-note[
  This is the move worth teaching, not the answer. If a curve looks like a
  root, plot against the root and see whether it goes straight. A straight
  line is the only shape an eye can judge.
]

#anim[The same five measurements, against $sqrt(L)$ instead of $L$.]

#align(center, build(from => lq.diagram(
  width: 18cm, height: 6.1cm,
  xlabel: [$sqrt(L)$ in $sqrt(upright(m))$], ylabel: [period $T$ in s],
  xlim: (0, 1.08), ylim: (0, 2.3),
  // Top left, because every line on this diagram runs from the bottom left
  // corner to the top right one and leaves the two other corners empty.
  legend: (position: top + left),
  lq.scatter(wurzel, dauer, color: messung, size: (170,) * 5,
             label: [measured]),
  lq.plot(stuetze, stuetze.map(x => 2.010 * x), color: from(2, modell),
          mark: none, stroke: from(2, 1.6pt + modell),
          // Same as on the slide before: room for the root's overbar.
          label: from(2, box(inset: (top: 2.5pt))[$T = k dot sqrt(L)$])),
  // Stage 3: the slope, read off the line the way it is read off in a book.
  lq.plot((0.55, 0.95, 0.95), (1.106, 1.106, 1.910),
          color: from(3, p.ink), mark: none,
          stroke: from(3, (paint: p.ink, thickness: 1pt, dash: "dashed")),
          label: from(3, [$k approx 2.01$])),
), steps: 3))

#anim[A straight line through the origin, $T = k sqrt(L)$. And $k$ is not ours:
      it is $2 pi slash sqrt(g)$, which hands back
      $g approx 9.8 thin upright(m) slash upright(s)^2$.]


= Why a root, of all things

== What actually pulls it back

#speaker-note[
  Ask where the string's pull goes before the components appear. Somebody will
  say "into the string", and that is exactly right: the part along the string
  is held, and only what is left over moves anything.
]

// The same function once per stage, this time painting with CeTZ instead of
// lilaq. `build` does not care which -- it hands out a question and takes back
// a drawing. The ceiling, the string and the bob carry no number and stand
// there from the start; the three things the class has to watch happen carry
// one each.
//
// An arrowhead is a filled shape, so its fill goes through `from` just as the
// stroke does. A head left in full colour would arrive a stage before its
// shaft, hanging in the air on its own.
#let bob = (1.1832, -2.5378)      // 2.8 m of string, 25° off the vertical
#let quer = (0.5705, -2.8235)     // m g sin θ, drawn to the same scale
#let laengs = (1.7960, -3.8520)   // m g cos θ, the part the string holds
#let unten = (1.1832, -4.1378)    // the tip of m g

#anim[One pendulum, one instant, and the only force that is doing anything.]

#align(center, build(from => cetz.canvas(length: 66pt, {
  import cetz.draw: *
  // No number: the pendulum itself is there from the first stage on.
  line((-1.1, 0), (1.1, 0), stroke: 1pt + p.ink)
  for i in range(0, 8) {
    line((-1.05 + i * 0.3, 0), (-1.25 + i * 0.3, 0.22), stroke: 0.6pt + hilfs)
  }
  line((0, 0), (0, -2.70),
       stroke: (paint: hilfs, thickness: 0.7pt, dash: "dashed"))
  line((0, 0), bob, stroke: 1pt + p.ink)
  circle((0, 0), radius: 0.07, fill: p.ink, stroke: none)
  circle(bob, radius: 0.22, fill: p.ink, stroke: none)

  // Stage 2: the angle. Everything the rest of the talk is about sits in it.
  arc((0, 0), start: -90deg, stop: -65deg, radius: 1.3, anchor: "origin",
      stroke: from(2, 1pt + modell))
  content((0.36, -1.55), from(2, text(fill: modell, size: 0.8em, $theta$)))

  // Stage 3: the weight. It points down and knows nothing about the string.
  line(bob, unten, stroke: from(3, 1.4pt + messung),
       mark: from(3, (end: ">", fill: messung, stroke: messung)))
  content((1.66, -4.28), from(3, text(fill: messung, size: 0.8em, $m g$)))

  // Stage 4: the same weight, split along the string and across it. Only the
  // part across it moves anything; the rest the string simply holds.
  //
  // Asked with one argument instead of two. `from(4, ...)` would have to be
  // written eight times here -- twice per arrow, once per dashed line, once
  // per label -- to say the one thing `from(4)` says once. The single-argument
  // form answers yes or no, and in CeTZ the answer goes to
  // `hide(…, bounds: true)`, which takes a whole group out of the picture and
  // keeps its measure, so all four stages still measure alike. It is also the
  // only form for what cannot be recoloured at all, a gradient for instance.
  let zerlegung = {
    line(bob, quer, stroke: 1.6pt + messung,
         mark: (end: ">", fill: messung, stroke: messung))
    line(bob, laengs, stroke: 0.9pt + hilfs,
         mark: (end: ">", fill: hilfs, stroke: hilfs))
    line(quer, unten,
         stroke: (paint: hilfs, thickness: 0.6pt, dash: "dashed"))
    line(laengs, unten,
         stroke: (paint: hilfs, thickness: 0.6pt, dash: "dashed"))
    content((-0.05, -3.28),
            text(fill: messung, size: 0.8em, $m g sin theta$))
    content((2.74, -3.72), text(fill: hilfs, size: 0.8em, $m g cos theta$))
  }
  if from(4) { zerlegung } else { hide(zerlegung, bounds: true) }
}), steps: 4))

== The three lengths that nearly agree

#speaker-note[
  Drawn at $40degree$ so the three are visibly apart. Say that out loud -- at
  the angle a real pendulum swings, this would be three lines lying on one
  another, which is the whole point and a useless picture.
]

#anim[At $theta = 40degree$, drawn large: a height, an arc and a tangent.]

// `enter: "draw"` sets a pen on a path and runs it from one end to the other.
// It is right here and wrong on the diagrams above: six strokes across three
// steps, whereas a lilaq diagram hands the pen 64 stroked paths -- grid,
// ticks, frame, marks -- which all set off at once and look like a wipe rather
// than like a drawing.
//
// Every stroked path of one element does set off together, and there is
// nothing to turn there. An order is therefore said rather than inherited:
// three layers, three steps, three `anim`s with an `at:` each. Inside a
// `place` the step cursor has no reliable order to run in, so the numbers are
// written out.
//
// The labels are text, and text has no outline to trace: Typst sets glyphs as
// filled shapes. They fade in while the lines draw themselves, which is what
// the manual promises and what it looks like when a hand labels a drawing.
#let r = 3.2
#let winkel = 40deg
#let punkt = (r * calc.cos(winkel), r * calc.sin(winkel))
#let spitze = (r, r * calc.tan(winkel))

// One layer: a canvas of its own, on its own step, on top of the ones before
// it. The frame is drawn and immediately hidden -- without it each canvas
// would measure itself against its own ink, and the three would land in three
// different places.
#let lage(schritt, takt, tinte, dauer: 1000) = place(top + left,
  anim(at: schritt, enter: "draw", duration: dauer, easing: takt,
       cetz.canvas(length: 58pt, {
         import cetz.draw: *
         hide(rect((-0.4, -0.4), (4.5, 3.2)), bounds: true)
         tinte
       })))

#align(center, box(width: 4.9 * 58pt, height: 3.6 * 58pt, {
  // Step 2: the two arms of the angle. Two long straight lines, nothing else.
  lage(2, "standard", dauer: 900, {
    import cetz.draw: *
    line((0, 0), (3.5, 3.5 * calc.tan(winkel)), stroke: 1.1pt + p.ink)
    line((0, 0), (4.1, 0), stroke: 1.1pt + p.ink)
    arc((0, 0), start: 0deg, stop: winkel, radius: 0.62, anchor: "origin",
        stroke: 0.9pt + hilfs)
    content((1.02, 0.33), text(fill: hilfs, size: 0.8em, $theta$))
  })
  // Step 3: the arc. One long curve, and on a unit radius it *is* the angle.
  // A slower, evenly paced curve, because a pen tracing an arc that speeds up
  // and slows down looks like a slip of the hand.
  lage(3, "in-out-cubic", dauer: 1200, {
    import cetz.draw: *
    arc((0, 0), start: 0deg, stop: winkel, radius: r, anchor: "origin",
        stroke: 1.8pt + modell)
    content((2.78, 0.95), text(fill: modell, size: 0.8em, $theta$))
  })
  // Step 4: the two uprights. The short one is the sine, the tall one the
  // tangent, and the arc runs between them. `out-expo` starts fast and eases
  // out: both are drawn almost before the eye has left the arc.
  lage(4, "out-expo", dauer: 1000, {
    import cetz.draw: *
    line(punkt, (punkt.at(0), 0), stroke: 1.6pt + messung)
    line((r, 0), spitze, stroke: 1.6pt + messung)
    content((1.88, 0.92), text(fill: messung, size: 0.8em, $sin theta$))
    content((3.76, 1.30), text(fill: messung, size: 0.8em, $tan theta$))
  })
}))

#anim(at: 5, align(center, text(fill: hilfs)[
  $sin theta < theta < tan theta$, always. At $10degree$: $0.1736$, $0.1745$,
  $0.1763$. At $5degree$ the sine is within one part in seven hundred of the
  angle -- and it is the sine the force is made of.
]))

== From the triangle to the beat

#speaker-note[
  Do not read the last line as a formula to learn. Read it as: the mass has
  gone and the angle has gone, and what is left is a length and the Earth.
]

The force across the string is $m g sin theta$. For a small angle that is
$m g theta$, and $theta$ is the way out, $s$, divided by the length $L$:

// Two `alternatives` in step, both told to start on the same step: the
// equations in one place and the sentence that reads them in another. That is
// what actually happens between the two lines -- the answer stands where the
// question stood -- and it is also the only way two equations of this size and
// their reasons fit on one slide. `out-cubic` because the swap is the largest
// thing here and may take a moment more than the house curve gives it.
#alternatives(
  start: 2,
  align: center + horizon,
  easing: "out-cubic",
  statement(color: modell)[
    $ m a = - m g s / L $
  ],
  statement(color: messung, size: 2em)[
    $ T = 2 pi sqrt(L / g) $
  ],
)

#alternatives(
  start: 2,
  easing: "out-cubic",
  [The mass stands on both sides and cancels. What is left says the pull back
   is proportional to how far out you are.],
  [And that is the one equation whose answer is a sine wave. No $m$, so the
   bolt and the rubber keep step; no $theta$, so the width of the swing hardly
   matters. Both guesses from the first slide, answered.],
)

== A swing is not a lift

#speaker-note[
  Let all three run twice before saying anything. The question to the room is
  which of them looks like something hanging on a string -- not which is
  quickest, they take exactly the same time.
]

// `easing` on three elements that are otherwise identical and enter on the
// same step, so the only difference an eye can find is the curve. A swing is
// slowest at the two turning points and quickest at the bottom, which is what
// an `in-out` curve does and what a straight one does not.
//
// Only the bob is tracked. The rail stays where it is, so there is something
// standing still to see the movement against.
#let takt(kurve, farbe, erklaerung) = grid(
  columns: (3.6cm, 1fr),
  column-gutter: 18pt,
  align: horizon,
  box(width: 3.6cm, height: 20pt, {
    place(left + horizon, line(length: 100%, stroke: 0.6pt + p.border))
    place(right + horizon, anim(at: 2, enter: "fade-right", duration: 1400,
                                easing: kurve,
                                circle(radius: 7pt, fill: farbe,
                                       stroke: none)))
  }),
  [*#raw(kurve)* -- #erklaerung],
)

#stack(
  spacing: 1.2em,
  takt("linear", hilfs,
       [even from end to end. A lift, or a hand pushing something along.]),
  takt("in-out-quad", modell,
       [slow, quick, slow. This is the one that hangs on a string.]),
  takt("in-out-expo", messung,
       [almost nothing, then everything at once. A door on a spring.]),
)

#anim(at: 3, enter: "fade-up", align(center, text(fill: hilfs)[
  The same distance and the same $1400$ ms for all three. Only the pacing
  differs, and only one of them is a pendulum.
]))


= The metre that almost was

== Ninety-nine point four

#speaker-note[
  Give them the arithmetic to do, not the answer. $T = 2$ seconds, so
  $L = g T^2 slash 4 pi^2$. A calculator and twenty seconds.
]

A clock wants a swing that takes exactly one second -- one tick out, one tick
back, so $T = 2$ s. Turn the formula round:

#pause

#statement[
  $ L = (g T^2) / (4 pi^2) = (9.81 dot 4) / (4 pi^2) $
]

// `out-back` overshoots its target and swings back into it. On a plain fade
// the browser clips whatever runs past 1 and nothing of the overshoot shows;
// on `rise`, which travels, it is the point. A result may arrive with a
// bounce once, on the slide where the talk turns.
#anim(at: 3, enter: "rise", easing: "out-back", duration: 700,
      statement(color: messung, size: 2.2em)[
  $ L = 0.994 thin upright(m) $
])

#anim(at: 4, enter: "fade-up", align(center)[
  Six millimetres short of a metre. Nobody arranged that -- and in 1790 it was
  very nearly the point.
])

== Two proposals, 1791

#speaker-note[
  The commission was Borda, Lagrange, Laplace, Monge and Condorcet. Worth
  naming: this was not a committee dodging a decision, it was five people who
  knew exactly what they were giving up.
]

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  card(title: [Talleyrand, March 1790], color: hilfs)[
    The metre is the length of a pendulum that beats seconds, taken at
    $45degree$ latitude.

    #v(0.4em)
    Anyone with a string and a clock can rebuild it. No expedition, no
    survey.
  ],
  card(title: [The Académie, 19 March 1791])[
    The metre is one ten-millionth of the quarter meridian, pole to equator
    through Paris.

    #v(0.4em)
    Seven years of surveying from Dunkirk to Barcelona, for a number nobody
    could check at home.
  ],
)

#pause

#callout(title: [Why the harder one won])[
  A pendulum borrows the second, which nobody had defined either. And it
  borrows $g$.
]

== The reason it lost

#speaker-note[
  This is the slide the whole talk was built to reach. Five millimetres is not
  a rounding error in a definition; it is the definition failing to be one.
]

#anim[The same seconds pendulum in three places, drawn from $0.988$ m to the
      metre -- the whole rail is twelve millimetres wide.]

// The last drawing and the smallest, and a `build` again rather than a pen:
// three filled bars have no outline to trace, and a chart that grows a bar at
// a time is exactly what stages are for. The rail and the hairline at its
// right end carry no number, so they stand there from the start and every bar
// is seen falling short of the metre.
//
// The scale is cut off at 0.988 and says so in the line above. Drawn from
// zero, the three bars would be the same bar: the difference the whole talk
// is about is five parts in a thousand.
#let von = 0.988
#let voll = 9.5cm
#let balken(from, nummer, ort, wert, zahl, farbe) = grid(
  columns: (2.6cm, voll, 3.6cm),
  column-gutter: 12pt,
  align: horizon,
  align(right, from(nummer, text(fill: hilfs, size: 0.9em, ort))),
  box(width: voll, height: 16pt, {
    place(left + horizon, line(length: 100%, stroke: 0.5pt + p.border))
    place(left + horizon,
          rect(width: voll * (wert - von) / (1 - von), height: 16pt,
               fill: from(nummer, farbe), stroke: none))
    place(left + horizon, dx: voll,
          line(angle: 90deg, length: 16pt, stroke: 1.2pt + p.ink))
  }),
  // Written out and not computed from the number beside it: Typst drops a
  // trailing zero, and 0.99390 would read as 0.9939 in a column whose whole
  // point is the fifth decimal place.
  from(nummer, text(fill: farbe, weight: "bold", size: 0.9em, zahl)),
)

#align(center, build(from => stack(spacing: 1em,
  balken(from, 1, [equator], 0.99095, [0.99095 m], modell),
  balken(from, 2, [Paris], 0.99390, [0.99390 m], messung),
  balken(from, 3, [the pole], 0.99621, [0.99621 m], modell),
), steps: 3))

#anim[Five millimetres from the equator to the pole. A definition that changes
      when you carry it north is not a definition.]

== What the pendulum kept

#speaker-note[
  End here. The last line is the one to leave in the room, and it is not a
  formula.
]

#stagger(easing: "out-quad", start: 2)[
  - The metre went to the meridian, and from there in 1983 to the speed of
    light. No string anywhere in the chain.
  - But turn $T = 2 pi sqrt(L slash g)$ round again and it gives $g$, and for
    two hundred years that was how anyone measured the shape of the Earth.
  - And what the pendulum was best at, it kept: no $m$, no $theta$. A clock
    that does not care what it is made of, or how hard you push it.
]

#anim(at: 5, enter: "scale", easing: "out-expo",
      statement(color: modell)[
  It did not become the metre. It became the clock that measured everything
  else.
])
