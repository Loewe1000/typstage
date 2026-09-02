// "Closing the Door": a talk on damping.
//
//   typst compile ziehen.typ ziehen.html --format html --features html
//   typst compile ziehen.typ ziehen.pdf
//
// This deck does not switch its picture, it pulls it. The step response of a
// damped oscillator hangs on a single number, and that is precisely the case
// `scene` exists for: the deck writes the function from the number to the
// picture and says at which values the talk stops.
//
// One drawing function carries almost all of it: the scene on ζ, the scene on
// a pair of spring and oil, and the flipbook, which gets the same curve with a
// runner on it. Only the root locus is its own drawing, and it is the second
// view of the same number.

#import "@preview/cetz:0.5.2"
#import "@preview/typstage:0.1.1": *

#let t = themes.default

#show: presentation.with(
  theme: t,
  title: [Closing the Door],
  subtitle: [One number decides whether it slams, sticks, or settles],
  author: [A talk on damping],
  date: [26 August 2026],
  // A deck whose content is continuously in motion cannot afford a slide
  // change that moves as well: the eye should not have to work out which of
  // "the picture is being pulled" and "the slide turned" it just saw.
  transition: "fade",
  transition-duration: 380,
  duration: 460,
  style: it => { set par(justify: false); it },
)

// ── Colours that mean something ────────────────────────────────────────────
// Fixed once here and handed in everywhere, so that a meaning changes its
// colour in one place rather than seven.

#let pulled = t.accent                    // the curve that is being pulled
#let rest = t.strong.transparentize(35%)  // the position everything runs to
#let guide = t.border.darken(22%)         // axes and construction lines
#let quiet = t.muted                      // labelling

// ── The drawing ────────────────────────────────────────────────────────────
//
// The step response of a spring-mass-damper: where is the door at time `tt` if
// it is let go at zero? Two quantities settle it, the natural frequency `w`
// and the damping ratio `z` -- and the scenes of this deck differ only in
// which of the two they pull.

#let SECONDS = 12.0    // seconds on show
#let SX = 0.50      // one second in canvas units
#let SY = 2.35      // the height at which the door is shut

// The rectangle that holds the canvas open. Without it the canvas would grow
// with its content, and pulling would move the whole picture instead of the
// curve -- the manual has the case under "A drawing that moves". Whatever
// reaches past it is clipped: an overshoot running off the top would open the
// canvas up exactly as a missing frame would.
#let FRAME = ((-0.85, -1.05), (6.85, 4.6))
#let CLIP-TOP = 4.30
#let CLIP-BOTTOM = -0.45

/// Where the door is at time `tt`, as a fraction of the way from open to shut.
///
/// Three cases, and the middle one is not a nicety: at `z = 1` the two roots
/// fall together, and the underdamped formula would divide by zero there. A
/// scene travels continuously through that place, so the neighbourhood of 1
/// needs the separate branch, not merely the point itself.
#let door-at(w, z, tt) = {
  let a = w * tt
  if calc.abs(z - 1.0) < 0.004 {
    1.0 - (1.0 + a) * calc.exp(-a)
  } else if z < 1.0 {
    let d = calc.sqrt(1.0 - z * z)
    1.0 - calc.exp(-z * a) * (calc.cos(d * a * 1rad) + z / d * calc.sin(d * a * 1rad))
  } else {
    let r = calc.sqrt(z * z - 1.0)
    let (s1, s2) = (-z + r, -z - r)
    1.0 - (s2 * calc.exp(s1 * a) - s1 * calc.exp(s2 * a)) / (s2 - s1)
  }
}

/// Two decimal places, always. `calc.round` drops the trailing zero, and a
/// readout that switches between "1" and "0.15" twitches while it is pulled,
/// at precisely the spot the room is looking at.
#let two-places(x) = {
  let n = calc.round(x, digits: 2)
  let whole = calc.floor(calc.abs(n))
  let frac = calc.round((calc.abs(n) - whole) * 100)
  str(whole) + "." + (if frac < 10 { "0" } else { "" }) + str(frac)
}

/// The point of the curve at time `tt`, already clipped.
#let point-at(w, z, tt) = (
  tt * SX,
  calc.max(CLIP-BOTTOM, calc.min(CLIP-TOP, door-at(w, z, tt) * SY)),
)

// 60 sample points. Fewer, and the overshoot at small ζ gets a corner instead
// of a peak; more costs something in every single frame of a scene.
#let SAMPLES = 60

/// The step response, drawn. `runner` puts a dot on the curve -- the one
/// place in this deck where the clock decides instead of the key.
#let response(w, z, note: none, runner: none) = cetz.canvas(length: 1.787cm, {
  import cetz.draw: *

  rect(..FRAME, stroke: rgb(0, 0, 0, 0))

  line((0, CLIP-BOTTOM), (0, CLIP-TOP), stroke: 0.7pt + guide)
  line((0, 0), (6.45, 0), stroke: 0.7pt + guide)
  line((0, SY), (6.45, SY), stroke: (paint: rest, thickness: 0.8pt, dash: "dashed"))
  content((0.12, SY + 0.08), text(size: 8pt, fill: rest)[shut], anchor: "south-west")
  content((6.45, -0.12), text(size: 8pt, fill: quiet)[12 s], anchor: "north-east")

  line(..range(SAMPLES + 1).map(i => point-at(w, z, SECONDS * i / SAMPLES)),
       stroke: 1.6pt + pulled)

  if runner != none {
    let p = point-at(w, z, runner)
    line((p.at(0), 0), p, stroke: (paint: pulled.transparentize(70%), thickness: 0.8pt))
    circle(p, radius: 0.11, fill: pulled, stroke: none)
  }

  // The scale ζ stands on. It is what the scene is really reporting: the
  // thing travelling here is the value the key pulls.
  let dial(x) = (0.3 + x / 2.0 * 2.6, -0.68)
  line(dial(0.0), dial(2.0), stroke: 1.0pt + guide)
  for m in (0, 1, 2) {
    line((dial(m).at(0), -0.78), (dial(m).at(0), -0.58), stroke: 1.0pt + guide)
    content((dial(m).at(0), -0.80), text(size: 7pt, fill: quiet)[#m],
            anchor: "north")
  }
  content((0.15, -0.68), text(size: 9pt, fill: quiet)[$zeta$], anchor: "east")
  circle(dial(calc.min(2.0, z)), radius: 0.13, fill: pulled, stroke: none)

  // The readout, in a box of fixed width so that one digit more shifts
  // nothing. Inside the frame that is cosmetic; at the edge it would be the
  // difference between standing still and travelling. Wide enough for the
  // longest of them -- the pair of spring and oil needs 4.89 cm, and a box
  // that made it wrap would break the line between "ζ =" and its value.
  content((6.45, 4.4), box(width: 5.2cm, align(right, text(size: 11pt, fill: quiet, {
    if note != none [#note #h(0.8em)]
    text(fill: pulled)[$zeta = #two-places(z)$]
  }))), anchor: "north-east")
})

/// The same number, second view: the two roots of $s^2 + 2 zeta s + 1$.
///
/// They are the reason something *happens* at ζ = 1 rather than merely
/// continuing, which is why they get a scene of their own and not a formula.
// The scale follows from the furthest stop: at ζ = 2 the far root sits at
// −3.73, and it should stand in the picture rather than cling to its edge.
// The unit falls out of that, and the frame out of the unit -- not the other
// way round.
//
// The frame is shifted, not widened: it used to leave that far root 7 % of the
// width from the edge, close enough to the slide margin that the dot read as
// about to fall off. Now it sits at 10 %. The width stays what it was, because
// the drawing already fills its column -- the room comes from the right, where
// nothing stands beyond the imaginary axis but the `Re` label.
#let UNIT = 1.91   // one unit of the complex plane
#let ROOT-FRAME = ((-8.05, -3.215), (0.6, 3.215))

#let root-locus(z) = cetz.canvas(length: 1.59cm, {
  import cetz.draw: *

  rect(..ROOT-FRAME, stroke: rgb(0, 0, 0, 0))

  line((-7.6, 0), (0.45, 0), stroke: 0.7pt + guide)
  line((0, -2.55), (0, 2.55), stroke: 0.7pt + guide)
  content((0.45, -0.1), text(size: 8pt, fill: quiet)[Re], anchor: "north-east")
  content((0.12, 2.55), text(size: 8pt, fill: quiet)[Im], anchor: "north-west")
  for m in (1, 2, 3) {
    line((-m * UNIT, -0.12), (-m * UNIT, 0.12), stroke: 0.7pt + guide)
    content((-m * UNIT, -0.16), text(size: 7.5pt, fill: quiet)[$-#m$], anchor: "north")
  }

  // The circle the pair travels on for as long as it is a pair: its radius is
  // the natural frequency, and the screw only turns the angle. Which is why
  // ζ = 1 is the end of it -- there is nothing further round the circle.
  // Written as a polyline rather than as `arc`: which of the two halves cetz
  // makes of a pair of angles has to be looked up; from points it can be read.
  line(..range(41).map(i => {
    let a = (90deg + i * 4.5deg)
    (UNIT * calc.cos(a), UNIT * calc.sin(a))
  }), stroke: (paint: rest, thickness: 0.8pt, dash: "dashed"))

  let poles = if z < 1.0 {
    let d = calc.sqrt(1.0 - z * z)
    ((-z * UNIT, d * UNIT), (-z * UNIT, -d * UNIT))
  } else {
    let r = calc.sqrt(z * z - 1.0)
    // Clipped like the curve next door: a root running out of the frame would
    // open the canvas up and set the whole picture travelling. The bound sits
    // clear of the furthest stop -- at ζ = 2 the far root wants -7.13, and a
    // bound that caught it would move the one number this scale was built for.
    ((calc.max(-7.4, (-z + r) * UNIT), 0.0), (calc.max(-7.4, (-z - r) * UNIT), 0.0))
  }
  for pk in poles {
    line((pk.at(0), 0), pk,
         stroke: (paint: pulled.transparentize(70%), thickness: 0.8pt))
    circle(pk, radius: 0.17, fill: pulled, stroke: none)
  }

  content((-7.6, 3.15), box(width: 3.0cm,
    text(size: 11pt, fill: pulled)[$zeta = #two-places(z)$]), anchor: "north-west")
})

/// The mechanism itself, once and motionless: spring, oil, mass.
#let mechanism = cetz.canvas(length: 2.15cm, {
  import cetz.draw: *

  line((0, -0.9), (0, 1.5), stroke: 1.2pt + guide)
  for i in range(6) {
    line((0, -0.85 + i * 0.45), (-0.28, -0.6 + i * 0.45), stroke: 0.7pt + guide)
  }

  // The spring: it is what shuts the door, and it is the reason there is
  // anything to oscillate with in the first place.
  let zigzag = range(13).map(i => (
    0.35 + i * 0.19,
    1.0 + (if calc.rem(i, 2) == 0 { 0.0 } else if calc.rem(i, 4) == 1 { 0.24 } else { -0.24 }),
  ))
  line((0, 1.0), ..zigzag, (3.0, 1.0), stroke: 1.1pt + t.strong)
  content((1.7, 1.62), text(size: 14pt, fill: t.strong)[$k$], anchor: "south")

  // The oil: it shuts nothing at all. It only decides how fast.
  line((0, -0.3), (1.1, -0.3), stroke: 1.1pt + pulled)
  rect((1.1, -0.72), (2.0, 0.12), stroke: 1.1pt + pulled)
  line((1.55, -0.3), (3.0, -0.3), stroke: 1.1pt + pulled)
  line((1.55, -0.62), (1.55, 0.02), stroke: 2.2pt + pulled)
  content((1.55, -0.9), text(size: 14pt, fill: pulled)[$c$], anchor: "north")

  rect((3.0, -0.75), (3.9, 1.45), fill: t.surface, stroke: 1.2pt + guide)
  content((3.45, 0.35), text(size: 14pt, fill: quiet)[$m$])
})

// The right-hand column of a scene slide stands in a box of fixed height: the
// layers arrive one after another and then stay, and without a fixed measure
// the whole column would shift at every stop.
#let beside(body) = box(width: 100%, height: 290pt, body)

/// One line as it belongs to a stop: the value in front, the sentence behind.
/// Four of them have to fit in the box together, because a layer stays until
/// the end of the slide -- which is why the sentences are short.
#let stop-line(marke, body) = block(spacing: 0.7em, grid(
  columns: (52pt, 1fr),
  column-gutter: 9pt,
  text(fill: pulled, weight: "bold", size: 0.78em, marke),
  text(size: 0.78em, body),
))

// ═══════════════════════════════════════════════════════════════════════════

= A door is a decision

== Two doors, both wrong

#speaker-note[
  Everybody in the room has met both of these this week. Wait for the nodding
  before you go on; the rest of the talk is easier once they have supplied the
  examples themselves.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  equal: true,
  card(title: [The one that slams])[
    It shuts quickly, arrives faster than it left, and announces itself down
    the whole corridor. Somebody props it open with a chair.
  ],
  card(title: [The one that sticks])[
    It shuts politely and then stops two centimetres short, every time, and the
    latch never catches. Somebody props it open with a chair.
  ],
)

#v(0.6em)

#anim(at: 2, enter: "fade-up", callout(title: [The chair is the tell])[
  Same mechanism, same spring, same door. A door that is wrong in either
  direction stops being a door, and the two failures are one adjustment apart.
])

#v(1fr)

== The same spring, a different valve

#speaker-note[
  If there is a closer on the door of this room, point at it. The screw is
  usually on the end of the barrel and it is usually painted over.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1.15fr),
  gutter: 24pt,
  align: horizon,
  align(center, mechanism),
  [
    A door closer is a spring and a cylinder of oil. The spring is what shuts
    the door. The oil shuts nothing at all — it only resists being moved
    quickly, and there is a screw on it.

    #anim(at: 2, enter: "fade-up")[
      Turning that screw changes nothing about the spring, the door, or the
      room. It changes one number, and that number is the entire difference
      between the two doors on the last slide.
    ]
  ],
)

#v(1fr)

= Turning the knob

== Watch it settle

#speaker-note[
  Do not read the four lines out. Pull the scene one stop at a time and let
  the curve say it; the lines are there so the room can look back.
]

#v(0.5em)

// The heart of the deck. The stops are the values themselves -- 0.15 to 2 --
// and not a fraction of a running time: that is the whole difference from a
// flipbook, and the reason the key pulls here rather than the clock.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "settle",
    z => response(1.0, z),
    stops: (0.15, 0.4, 1.0, 2.0),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  beside[
    #scene-layer("settle", 1)[
      #stop-line[0.15][Barely any oil. It touches the frame after a second and a
        half, then three times more.]
    ]
    #scene-layer("settle", 2)[
      #stop-line[0.40][A quarter of the way past, once — and at the latch before
        any calmer setting.]
    ]
    #scene-layer("settle", 3)[
      #stop-line[1.00][No overshoot at all, and it is the first setting with none.
        Watch where it ends up.]
    ]
    #scene-layer("settle", 4)[
      #stop-line[2.00][Thick oil. Nothing overshoots, and nothing quite arrives
        either.]
    ]
  ],
)

== The number has a name

#v(1fr)

The screw does not set a time, and it does not set a speed. It sets a ratio,
and the ratio is between the oil, the spring, and what has to be moved.

#statement(size: 2.1em, color: t.accent, above: 0.9em, below: 0.7em)[
  $ zeta = c / (2 sqrt(k m)) $
]

#anim(at: 2, enter: "fade-up")[
  Because it is a ratio it carries no units, and because it carries no units
  the same number describes a door, a car on a bad road, and the arm a camera
  hangs from. Nothing above was about doors.
]

#v(1fr)

== Where the boundary is

#speaker-note[
  This is the only algebra in the talk. It exists to make the next slide
  inevitable rather than pretty.
]

#v(0.8em)

Write the motion down and the whole question collapses into one square root:

#statement(size: 1.5em, color: t.strong, above: 0.5em, below: 0.5em)[
  $ s = omega (-zeta plus.minus sqrt(zeta^2 - 1)) $
]

#text(size: 0.88em, stagger(
  start: 2,
  spacing: 0.6em,
  [#text(fill: t.strong)[Under one.] What is under the root is negative, the
   roots are a complex pair — and a complex pair is a door that comes back.],
  [#text(fill: t.strong)[Exactly one.] The root is zero and the pair is one
   number, twice. Nothing is left to oscillate with.],
  [#text(fill: t.strong)[Above one.] Two real roots, moving apart, and the
   slower of them is now in charge.],
))

#v(0.5em)

== The roots go for a walk

#speaker-note[
  Same screw as two slides ago, second view. Say that out loud — otherwise
  half the room takes this for a new topic.
]

#v(0.5em)

// The same quantity, a different picture -- and three of the four stops are
// literally the numbers from two slides ago. That is what `stops` naming the
// values rather than 0 to 1 buys: 0.4 means here what it meant there, and the
// source says so without the two scenes having to be laid side by side.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "roots",
    z => root-locus(z),
    stops: (0.0, 0.4, 1.0, 2.0),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  beside[
    #scene-layer("roots", 1)[
      #stop-line[0.00][A pair on the imaginary axis. Nothing decays; the door swings
        for ever.]
    ]
    #scene-layer("roots", 2)[
      #stop-line[0.40][They slide down a circle of fixed radius. The swing now dies
        out.]
    ]
    #scene-layer("roots", 3)[
      #stop-line[1.00][They meet on the real axis. That happens exactly once.]
    ]
    #scene-layer("roots", 4)[
      #stop-line[2.00][They part along it. The one creeping back toward zero sets
        the pace.]
    ]
  ],
)

= What the knob costs

== Critical never quite arrives

#speaker-note[
  The word "critical" does the damage. People hear it as "best", and it only
  ever meant "the boundary". Point back at the ζ = 1 curve if anyone doubts
  that it never touches the line.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  equal: true,
  card(title: [What $zeta = 1$ buys])[
    The overshoot goes to zero, and it is the first setting at which it does.
    One number, one promise — and the promise is about coming back, not about
    getting there.
  ],
  card(title: [What it does not])[
    At $zeta = 1$ the door never touches the frame; it only approaches it.
    Everything that arrives in finite time overshoots: five per cent at
    $zeta = 0.7$, a quarter at $zeta = 0.4$.
  ],
)

#v(0.6em)

#anim(at: 2, enter: "fade-up", callout(title: [Which is why doors are set under one])[
  A door has to latch, so it has to arrive, so it has to overshoot. How much
  depends on who is asleep on the other side of the wall.
])

#v(1fr)

== Two knobs, one number

#speaker-note[
  The middle stop is the one that surprises people: nobody touched the oil,
  and the damping changed anyway.
]

#v(0.5em)

// A stop may be a tuple, and here it is one: spring and oil travel together.
// That is the honest shape of the claim -- ζ is not a third adjustment beside
// the two, it is the thing both of them move.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "both",
    (k, c) => response(calc.sqrt(k), c / (2 * calc.sqrt(k)),
                      note: text(fill: t.strong)[
                        $k = #two-places(k)$ #h(0.7em) $c = #two-places(c)$
                      ]),
    stops: ((1.0, 1.0), (4.0, 1.0), (4.0, 2.0)),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  beside[
    #scene-layer("both", 1)[
      #stop-line[$1 · 1$][As sold. That works out at $zeta = 0.5$, and it is a
        reasonable door.]
    ]
    #scene-layer("both", 2)[
      #stop-line[$4 · 1$][Four times the spring. Twice as quick — and half the
        damping, on the same oil.]
    ]
    #scene-layer("both", 3)[
      #stop-line[$4 · 2$][Twice the oil puts $zeta$ back at $0.5$, on a door that
        shuts in half the time.]
    ]
    #v(0.5em)
    #scene-layer("both", 3, enter: "fade-up")[
      #text(size: 0.75em, fill: quiet)[Two adjustments, and only one of them
        shows up in the answer.]
    ]
  ],
)

= Away from the drawing

== The door itself

#speaker-note[
  Step three starts it. Say the last sentence while it runs — it loops, so
  there is no hurry.
]

#v(0.5em)

#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  // The flipbook, for contrast, and with a late `at:`: the clock starts when
  // it is visible, not when its slide arrives. On the first two steps it lies
  // still on frame 0 and begins at zero the moment it is uncovered.
  flipbook(
    u => response(1.0, 0.4, runner: u * SECONDS),
    frames: 24,
    fps: 20,
    at: "3-",
    width: 390pt,
    height: 290pt,
  ),
  beside(text(size: 0.88em, stagger(
    start: 1,
    spacing: 0.8em,
    [Every picture so far has been a claim about time in which time was an
     axis, and the axis held still while you read it.],
    [That is what a scene is: the value is yours, and the drawing waits for
     the key.],
    [This one does not wait. Twenty-four frames, on the browser's own clock,
     from the moment it is uncovered.],
  ))),
)

== What to set it to

#v(1fr)

#side-by-side(
  split: (1fr, 1.1fr),
  gutter: 24pt,
  align: horizon,
  callout(title: [The whole talk])[
    Too far below one and it argues. At one and above it dawdles, and never
    quite shuts. The screw is worth a quarter turn and ninety seconds of your
    afternoon.
  ],
  [
    #text(size: 0.92em, stagger(
      start: 2,
      spacing: 0.7em,
      [The same number is on the spec sheet of every car suspension, where the
       answer is nearer $0.3$ — a car that never overshoots feels dead.],
      [It is in the arm of every camera crane, where the answer is nearer $1$,
       because a picture that comes back is a picture nobody can use.],
      [And it is in the fade that just carried this slide in. Somebody chose
       it, and the choice was this one.],
    ))
  ],
)

#v(1fr)
