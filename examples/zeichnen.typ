// A drawing that comes into being while the room watches.
//
//   typst compile zeichnen.typ zeichnen.html --format html --features html
//   typst compile zeichnen.typ zeichnen.pdf
//
// "The Metre That Almost Was": five lengths of string, one stopwatch, and the
// question why a pendulum that beats seconds is 99.4 cm long -- the length the
// French nearly called a metre in 1791.
//
// Two ways of drawing, each on what it is made for. The two diagrams grow in
// stages (`build`), because a lilaq diagram has 64 stroked paths and all of
// them would set off at once; the geometry is drawn with a pen (`enter:
// "draw"`), because it is four long lines an eye can follow. The manual says
// which drawing packages hand out outlines that can be traced.

#import "@schule/typstage:0.1.0": *
#import "@preview/cetz:0.5.2"
#import "@preview/lilaq:0.6.0" as lq

// Theme and palette separately: the layout is the default one, the colours are
// those of a German maths textbook. A palette is only the eight colours, so
// the deck reaches into `p` and not into the theme for anything it draws
// itself -- the theme still carries its own accent, and a drawing that used it
// would sit next to slides in another colour.
#let t = themes.default
#let p = palettes.textbook

// Three meaning colours, fixed once and handed in everywhere. They follow the
// convention of the textbook this palette was measured from: vermilion is what
// we measured, blue is what the theory claims, grey is a construction line
// that is neither.
#let messung = p.strong
#let modell = p.accent
#let hilfs = p.muted

#show: presentation.with(
  theme: t,
  palette: p,
  title: [The Metre That Almost Was],
  subtitle: [Five lengths of string, one stopwatch, and the second that nearly
             defined the metre],
  author: [Physics · Year 11],
  date: [12 October 2026],
  // A plain cross-fade. Three slides carry a drawing that builds itself, and a
  // page that slides in would be the largest movement on a slide whose whole
  // point is a much smaller one.
  transition: "fade",
  transition-duration: 420,
  duration: 520,
  // Most bodies here are one figure and three lines. Without this they cling
  // to the top edge with the drawing hanging under the title.
  style: it => { set par(justify: false); v(1fr); it; v(1fr) },
)

// ── The measurements ────────────────────────────────────────────────────────
// Five lengths, the period of each timed over ten swings. Real enough to be
// checked: 2π·sqrt(L/9.81) gives 0.897, 1.269, 1.554, 1.794, 2.006, so the
// scatter below is a few milliseconds and not a decoration.

#let laenge = (0.20, 0.40, 0.60, 0.80, 1.00)   // m
#let dauer = (0.90, 1.28, 1.55, 1.79, 2.01)    // s
#let wurzel = laenge.map(calc.sqrt)

// The two claims, sampled finely enough that neither shows its corners.
#let fein = range(1, 53).map(i => i * 0.02)               // 0.02 … 1.04
#let gerade = fein.map(l => 2.01 * l)                     // T ~ L
#let kurve = fein.map(l => 2.006 * calc.sqrt(l))          // T = 2π sqrt(L/g)

// The straight line through the origin in the straightened plot. Two points
// are enough for a straight line, and a straight line drawn from two points
// cannot bend where nobody looked.
#let stuetze = (0, 1.06)


= A clock made of string

== What sets the beat?

#speaker-note[
  Take the guesses before showing anything. Somebody always says the mass, and
  that guess has to be in the room before it is knocked down -- otherwise the
  measurement answers a question nobody asked.
]

A pendulum keeps time. Something about it must decide how fast.

// `easing: "out-quad"` on the list: three candidates that are equally likely
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
  half a swing, no more. Only the third candidate is left, and that one has a
  number to it.
], at: 5, enter: "fade-up")

== Five lengths, one stopwatch

#speaker-note[
  Ten swings and divide, never one. The stopwatch is worth about a tenth of a
  second in a human hand, and a tenth spread over ten swings is a hundredth.
]

#side-by-side(
  split: (1fr, 1.1fr),
  align: top,
  card(title: [What was measured])[
    #v(0.3em)
    #table(
      columns: (auto, auto),
      align: (right, right),
      stroke: (x, y) => if y == 0 { (bottom: 0.6pt + p.ink) }
                        else { (bottom: 0.3pt + p.border) },
      table.header([$L$ in m], [$T$ in s]),
      ..laenge.zip(dauer).map(((l, d)) => ([#l], [#d])).flatten(),
    )
    #v(0.3em)
  ],
  stagger(start: 2)[
    - Five strings, a nut on the end of each, ten swings timed and divided
      by ten.
    - Double the length from $0.20$ to $0.40$, and the period goes from
      $0.90$ to $1.28$ -- not to $1.80$.
    - Double it again to $0.80$, and it goes to $1.79$. Doubling the length
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
// was a data series in it cannot be reached from outside. So the drawing is
// asked for once per stage, and `from` says which piece is due when. The
// measured points carry no number and therefore stand there from the first
// stage on.
//
// Why the pieces that are not due yet are made of air rather than left out:
// lilaq computes its axes over everything it is given. A series that was left
// out would take its share of the scale with it, and the ticks would jump the
// moment the curve arrived.
//
// The `anim` above it is not decoration. Entering a slide shows no entrances
// -- the runtime only restores the state -- so a drawing on step one would
// simply be there. It needs a step in front of it.
#anim[The five points, and the proportionality we half expected.]

#align(center, build(from => lq.diagram(
  width: 15cm, height: 6.4cm,
  xlabel: [length $L$ in m], ylabel: [period $T$ in s],
  xlim: (0, 1.08), ylim: (0, 2.3),
  legend: (position: bottom + right),
  // No number: there from the first stage on.
  lq.scatter(laenge, dauer, color: messung, size: (60,) * 5, label: [measured]),
  // Stage 2: the straight line through the last point. A colour becomes the
  // same colour with alpha 0, and the entry in the legend has to be made of
  // air as well -- otherwise the name stands there while its line is missing.
  lq.plot(fein, gerade, color: from(2, hilfs), mark: none,
          stroke: from(2, (paint: hilfs, thickness: 1.2pt, dash: "dashed")),
          label: from(2, [$T tilde L$])),
  // Stage 3: what the points actually do.
  lq.plot(fein, kurve, color: from(3, modell), mark: none,
          stroke: from(3, 1.6pt + modell),
          label: from(3, [$T tilde sqrt(L)$])),
), steps: 3))

#anim[At $L = 0.20$ the straight line asks for $0.40$ s and the stopwatch
      said $0.90$. The curve is not a bad line, it is a different shape.]

== Take the root and it straightens

#speaker-note[
  This is the move worth teaching, not the answer. If a curve looks like a
  root, plot against the root and see whether it goes straight. A straight
  line is the only shape the eye can judge.
]

#anim[The same five measurements, against $sqrt(L)$ instead of $L$.]

#align(center, build(from => lq.diagram(
  width: 15cm, height: 6.4cm,
  xlabel: [$sqrt(L)$ in $sqrt(upright(m))$], ylabel: [period $T$ in s],
  xlim: (0, 1.08), ylim: (0, 2.3),
  legend: (position: bottom + right),
  lq.scatter(wurzel, dauer, color: messung, size: (60,) * 5, label: [measured]),
  // Stage 2: a straight line through the origin, two points and no more.
  lq.plot(stuetze, stuetze.map(x => 2.010 * x), color: from(2, modell),
          mark: none, stroke: from(2, 1.6pt + modell),
          label: from(2, [$T = k dot sqrt(L)$])),
  // Stage 3: the slope, read off the line the way it is read off in a book.
  lq.plot((0.55, 0.95, 0.95), (1.106, 1.106, 1.910),
          color: from(3, p.ink), mark: none,
          stroke: from(3, (paint: p.ink, thickness: 1pt, dash: "dashed")),
          label: from(3, [$k approx 2.01 thin upright(s) slash sqrt(upright(m))$])),
), steps: 3))

#anim[A straight line through the origin: $T = k sqrt(L)$ with
      $k approx 2.01$. That number is not ours -- it is
      $2 pi slash sqrt(g)$, and it hands back $g approx 9.8 thin
      upright(m) slash upright(s)^2$.]


= Why a root, of all things

== What actually pulls it back

#speaker-note[
  Ask where the string's pull goes before showing the components. Somebody will
  say "into the string", and that is exactly right: the part along the string
  is held, and only what is left over moves anything.
]

// The same function once per stage, this time painting with CeTZ rather than
// lilaq -- `build` does not care which. The frame, the string and the bob
// carry no number and stand there from the start; the three things the class
// has to watch happen carry one each.
//
// Arrowheads are filled shapes, so their fill goes through `from` as well as
// the stroke does. A head left in full colour would arrive before its shaft.
#let bob = (1.352, -2.900)        // 3.2 m at 25 degrees from the vertical
#let quer = (2.184, -2.512)       // the tangential component, drawn to scale

#anim[One pendulum, one instant, and the only force that is doing anything.]

#align(center, build(from => cetz.canvas(length: 30pt, {
  import cetz.draw: *
  // The ceiling, the pivot, the string and the bob: no number, always there.
  line((-1.1, 0), (1.1, 0), stroke: 1pt + p.ink)
  for i in range(0, 8) {
    line((-1.05 + i * 0.3, 0), (-1.25 + i * 0.3, -0.22), stroke: 0.6pt + hilfs)
  }
  line((0, 0), (0, -3.6), stroke: (paint: hilfs, thickness: 0.7pt, dash: "dashed"))
  line((0, 0), bob, stroke: 1pt + p.ink)
  circle((0, 0), radius: 0.07, fill: p.ink, stroke: none)
  circle(bob, radius: 0.24, fill: p.ink, stroke: none)

  // Stage 2: the angle. Everything the rest of the talk is about is in it.
  arc((0, -1.5), start: -90deg, stop: -65deg, radius: 1.5,
      anchor: "origin", stroke: from(2, 1pt + modell))
  content((0.42, -1.75), from(2, text(fill: modell, size: 0.9em, $theta$)))

  // Stage 3: the weight. It points down and knows nothing about the string.
  line(bob, (rel: (0, -1.35)), stroke: from(3, 1.4pt + messung),
       mark: from(3, (end: ">", fill: messung, stroke: messung)))
  content((rel: (0.52, -0.1), to: (bob.at(0), bob.at(1) - 1.35)),
          from(3, text(fill: messung, size: 0.9em, $m g$)))

  // Stage 4: the part of it that is across the string. The rest is held by
  // the string and moves nothing at all.
  line(bob, quer, stroke: from(4, 1.4pt + messung),
       mark: from(4, (end: ">", fill: messung, stroke: messung)))
  line((bob.at(0), bob.at(1) - 1.35), quer,
       stroke: from(4, (paint: hilfs, thickness: 0.7pt, dash: "dashed")))
  content((2.62, -2.28),
          from(4, text(fill: messung, size: 0.9em, $m g sin theta$)))
}), steps: 4))

== The three lengths that nearly agree

#speaker-note[
  Drawn at $40degree$ so the three are visibly apart. Say that out loud -- at
  the angle a real pendulum swings, the drawing would be three lines on top of
  one another, which is the whole point and a useless picture.
]

#anim[At $theta = 40degree$, drawn large: an arc, a height and a tangent.]

// `enter: "draw"` sets a pen on the path and runs it from one end to the
// other. It is the right tool here and the wrong one on the diagrams above:
// this is four long lines an eye can follow, a lilaq diagram is 64 stroked
// paths -- grid, ticks, frame, marks -- that would all set off at once.
//
// Every stroked path of one element sets off together, and there is nothing to
// turn there. An order is therefore said rather than inherited: three layers,
// three steps, three `anim`s. They lie on top of each other in a `place`, and
// each canvas carries the same invisible frame, so all three measure alike and
// none of them shifts the others.
//
// The labels are text, and text has no outline to trace: Typst sets glyphs as
// filled shapes. They fade in while the lines draw themselves, which is what
// the manual promises and what it looks like when a hand labels a drawing.
#let r = 3.2
#let winkel = 40deg
#let punkt = (r * calc.cos(winkel), r * calc.sin(winkel))
#let spitze = (r, r * calc.tan(winkel))

// One layer: a CeTZ canvas of its own, on its own step, on top of the ones
// before it. The frame is drawn and immediately hidden -- without it the three
// canvases would each measure themselves against their own ink and land in
// three different places.
#let lage(schritt, takt, tinte, dauer: 1000) = place(top + left,
  anim(at: schritt, enter: "draw", duration: dauer, easing: takt,
       cetz.canvas(length: 30pt, {
         import cetz.draw: *
         hide(rect((-0.35, -0.35), (4.6, 3.1)), bounds: true)
         tinte
       })))

#align(center, box(width: 4.95 * 30pt, height: 3.45 * 30pt, {
  // Step 2: the two radii. Two long straight lines and nothing else.
  lage(2, "standard", dauer: 900, {
    import cetz.draw: *
    line((0, 0), (spitze.at(0) + 0.35, spitze.at(1) + 0.3),
         stroke: 1.1pt + p.ink)
    line((0, 0), (4.2, 0), stroke: 1.1pt + p.ink)
    arc((0, 0), start: 0deg, stop: 52deg, radius: 0.6, anchor: "origin",
        stroke: 0.9pt + hilfs)
    content((0.95, 0.36), text(fill: hilfs, size: 0.85em, $theta$))
  })
  // Step 3: the arc itself. One long curve, and it is the angle in radians.
  lage(3, "in-out-cubic", dauer: 1100, {
    import cetz.draw: *
    arc((0, 0), start: 0deg, stop: winkel, radius: r, anchor: "origin",
        stroke: 1.8pt + modell)
    content((3.1, 1.62), text(fill: modell, size: 0.85em, $theta$))
  })
  // Step 4: the two verticals. The shorter one is the sine, the longer one
  // the tangent, and the arc runs between them.
  lage(4, "out-expo", dauer: 1100, {
    import cetz.draw: *
    line(punkt, (punkt.at(0), 0), stroke: 1.6pt + messung)
    line((r, 0), spitze, stroke: 1.6pt + messung)
    line(punkt, (r, 0), stroke: (paint: hilfs, thickness: 0.7pt,
                                 dash: "dashed"))
    content((2.15, 1.35), text(fill: messung, size: 0.85em, $sin theta$))
    content((3.95, 1.5), text(fill: messung, size: 0.85em, $tan theta$))
  })
}))

#anim(at: 5, align(center, text(fill: hilfs)[
  $sin theta < theta < tan theta$ #h(1.4em) at $10degree$: $0.1736$,
  $0.1745$, $0.1763$ #h(1.4em) at $5degree$: apart by one part in eight hundred
]))

== From the triangle to the beat

#speaker-note[
  Do not read the last line as a formula to learn. Read it as: the mass has
  gone, the angle has gone, and what is left is the length and the Earth.
]

The force across the string is $m g sin theta$. For a small angle that is
$m g theta$, and $theta$ is the displacement $s$ divided by the length $L$:

#pause

#statement(color: modell)[
  $ m a = -m g s / L $
]

#pause

The mass stands on both sides and cancels. What is left says that the pull
back is proportional to how far out you are -- and that is the one equation
whose answer is a sine wave:

#pause

#statement(color: messung, size: 2em)[
  $ T = 2 pi sqrt(L / g) $
]

#anim(at: 5, enter: "fade-up")[
  No $m$, so the bolt and the rubber keep step. No $theta$, so the width of the
  swing hardly matters. Both guesses from the first slide, answered by an
  approximation three slides long.
]

== A swing is not a lift

#speaker-note[
  Let all three run twice before saying anything. The question to the room is
  which of them looks like something hanging on a string -- not which is
  fastest, they take exactly the same time.
]

// `easing` on three elements that are otherwise identical, entering on the
// same step, so the only difference the eye can find is the curve. A swing
// is slowest at the two turning points and quickest at the bottom, which is
// what an `in-out` curve does and what a straight one does not.
#let bahn(farbe) = box(width: 100%, {
  place(left + horizon, line(length: 100%, stroke: 0.6pt + p.border))
  place(left + horizon, circle(radius: 7pt, fill: farbe, stroke: none))
})

#let takt(name, kurve-name, farbe, erklaerung) = grid(
  columns: (5.2cm, 1fr),
  column-gutter: 14pt,
  align: horizon,
  anim(at: 2, enter: "fade-right", duration: 1400, easing: kurve-name,
       bahn(farbe)),
  [*#raw(kurve-name)* -- #erklaerung],
)

#stack(
  spacing: 1.1em,
  takt([even], "linear", hilfs,
       [even from end to end. A lift, or a hand pushing something along.]),
  takt([swing], "in-out-quad", modell,
       [slow, quick, slow. This is the one that hangs on a string.]),
  takt([slam], "in-out-expo", messung,
       [almost nothing, then everything. A door on a spring.]),
)

#anim(at: 3, enter: "fade-up", align(center, text(fill: hilfs)[
  All three take $1400$ ms and all three cross the same distance. Only the
  pacing differs, and only one of them is a pendulum.
]))


= The metre that almost was

== Ninety-nine point four

#speaker-note[
  Give them the arithmetic to do, not the answer. $T = 2$ seconds, so
  $L = g T^2 slash 4 pi^2$. A calculator and twenty seconds.
]

A clock wants a pendulum whose swing takes exactly one second -- one tick
one way, one tick back, so $T = 2$ s. Turn the formula round:

#pause

#statement[
  $ L = (g T^2) / (4 pi^2) = (9.81 dot 4) / (4 pi^2) $
]

// `out-back` overshoots its target and swings back into it. On a plain fade
// the browser would clip whatever runs past 1 and nothing would show; on
// `rise`, which travels, the overshoot is the point. A result is allowed to
// arrive with a bounce, once, on the slide where the whole talk turns.
#anim(at: 3, enter: "rise", easing: "out-back", duration: 700,
      statement(color: messung, size: 2.2em)[
  $ L = 0.994 thin upright(m) $
])

#anim(at: 4, enter: "fade-up", align(center)[
  Six millimetres short of a metre. Nobody arranged that -- and in 1790 that
  was very nearly the point.
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
    Define the metre as the length of a pendulum that beats seconds, measured
    at $45degree$ latitude.

    #v(0.4em)
    Anyone with a string and a clear night can rebuild it. No expedition, no
    survey, no war in the way.
  ],
  card(title: [The Académie, 19 March 1791])[
    Define the metre as one ten-millionth of the quarter meridian, from the
    pole to the equator through Paris.

    #v(0.4em)
    Seven years of surveying between Dunkirk and Barcelona, through a
    revolution, for a number nobody could check at home.
  ],
)

#pause

#callout(title: [Why the harder one won])[
  A pendulum borrows the second, and the second is an astronomical accident
  nobody had defined either. Worse, it borrows $g$ -- and $g$ is not the same
  everywhere.
]

== The reason it lost

#speaker-note[
  This is the slide the whole talk was built to reach. Five millimetres is not
  a rounding error in a definition; it is the definition failing to be one.
]

#anim[The same seconds pendulum, measured in three places.]

// The last drawing, and the smallest: three bars whose lengths are the numbers
// under discussion, drawn to scale against the metre. A `build` again and not
// a pen -- three filled bars have no outline to trace, and a bar chart that
// grows is exactly what stages are for.
#let voll = 11cm
#let balken(from, nummer, ort, wert, farbe) = grid(
  columns: (3.2cm, voll, 2.4cm),
  column-gutter: 12pt,
  align: horizon,
  align(right, from(nummer, text(fill: hilfs, size: 0.9em, ort))),
  box(width: voll, height: 15pt, {
    // The full width is one metre, so the black hairline at the right edge is
    // the metre and every bar falls short of it.
    place(left + horizon,
          rect(width: voll * wert, height: 15pt,
               fill: from(nummer, farbe), stroke: none))
    place(left + horizon, dx: voll, line(angle: 90deg, length: 15pt,
                                         stroke: 1pt + p.ink))
  }),
  from(nummer, text(fill: farbe, weight: "bold", str(wert) + [ m])),
)

#align(center, build(from => stack(spacing: 0.9em,
  balken(from, 2, [equator], 0.99095, modell),
  balken(from, 3, [Paris], 0.99390, messung),
  balken(from, 4, [north pole], 0.99621, modell),
), steps: 4))

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
  - And the thing the pendulum was best at, it kept: no $m$, no $theta$. A
    clock that does not care what it is made of, or how hard you push it.
]

#anim(at: 5, enter: "scale", easing: "out-expo",
      statement(color: modell)[
  It did not become the metre. It became the clock that measured everything
  else.
])
