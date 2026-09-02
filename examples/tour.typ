// A Tour of typstage: the introduction deck.
//
// This is the one deck that is allowed to be about typstage itself, so it takes
// that literally: the slide about `morph` uses a morph to say what a morph is
// for, the slide about `stagger` unfolds, the slide about `bridge-job` drives a
// lamp in a foreign document. The movement is the argument.
//
//   typst compile tour.typ tour.html --format html --features html
//   typst compile tour.typ tour.pdf
//   typst compile tour.typ handout.pdf          (with handout: 3 below)
//
// `themes.default` with `palettes.textbook`: a theme is a dictionary and a
// palette is colour on its own, so `+` is all it takes to put one on the
// other. Red for the built shapes, a blue accent, cream card surfaces. The
// deck reads its own colours back out of `t` wherever it draws by hand, so a
// change here reaches every drawing on it.
//
// The slide transitions used below are "zoom", "fade", "push" and "cover". The
// full set is none, fade, slide, push, cover, uncover, zoom, blur, iris, wipe,
// flip and cube; a typo in one of them does not stop the build, it quietly
// becomes a cross-fade.
//
// A body is a box of fixed height, so a short slide would stick to the top with
// white space under it. `#v(1fr)` at both ends centres one; a pure `fr` spacer
// is passed through untouched even where it stands next to tracked elements.

#import "@preview/typstage:0.1.1": *

// Two meaning colours, declared once here and passed in wherever they are
// needed. This deck's theme keeps none of its own. `live` marks the parts of a
// slide that actually move, so even a still screenshot says which half of the
// slide is alive; `done` is its counterpart on the bridged lamp.
#let t = themes.default + palettes.textbook
#let live = t.accent
#let done = rgb("#3f7d3a")

#show: presentation.with(
  theme: t,
  title: [A Tour of typstage],
  subtitle: [Every function once, and what it is for],
  author: [typstage #runtime-version],
  date: [23 August 2026],
  transition: "slide",
  // Both in milliseconds: the slide change, and the reveal of one element.
  transition-duration: 420,
  duration: 520,
  // The style hook reaches slides *and* the moving parts. A tracked element is
  // typeset a second time, in a frame of its own, and that frame never sees a
  // `#set` rule written in the document, so shared typography has to go here.
  style: it => { set par(justify: false); it },
)

= What this is

== One source, three outputs

#speaker-note[
  Don't go into the mechanics here. This slide says what comes out of the box;
  how it is made is the next one.
]

#v(1fr)

// `align: top` rather than the default `horizon`: two boxes of unequal height
// would otherwise hang from their middles and their title bars would not line
// up, which reads as a mistake.
#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [What goes in])[
    One `.typ` file. Headings cut it into slides: `=` opens a section, `==` a
    slide, `==` a slide with no title bar.
  ],
  callout(title: [What comes out])[
    An animated talk as a single HTML file, a slide deck as PDF (one page per
    slide, not per step), and with `handout: 3` a handout with room to write.
  ],
)

#anim([No server, no loading: the HTML file carries everything with it.],
      at: 2, enter: "fade-up")

#v(1fr)

== Typst sets, the browser moves

#v(1fr)

#statement(size: 1.3em)[
  Every slide is typeset by Typst and embedded as SVG.
]

// Three steps, each a consequence of the one above it. Shown at once they would
// be three claims competing for the same glance.
#anim([The arrangement is therefore the same as in the PDF, down to the point.
       Motion happens afterwards, and only to what asked for it.],
      at: "2-", enter: "fade-up")

#anim(callout(title: [Which is why the style hook exists])[
  A moving element is typeset a second time, in a frame of its own, and that
  frame does not see the document's `#set` rules. Everything beyond size,
  colour, font, style, alignment and language belongs in `style:`.
], at: "3-", enter: "fade-up")

#v(1fr)

== Two ways to write a deck

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [As headings])[
    #text(size: 0.72em, raw(lang: "typ",
      "#show: presentation.with(title: [My talk])\n\n= A section\n== A slide\nOne point.\n#pause\nAnd another."))

    The way for talks that are written by hand. This deck uses it.
  ],
  card(title: [As arguments])[
    #text(size: 0.72em, raw(lang: "typ",
      "#presentation(\n  title-slide(title: [My talk]),\n  section([A section]),\n  slide(title: [A slide],\n        note: [Say this])[One point.],\n)"))

    The way for computed talks -- slides out of a loop.
    `theme-night.typ` next door does it that way.
  ],
)

#anim([Pick one and stay with it. In the heading form, `speaker-note[…]` does
       what `note:` does in the call.], at: 2, enter: "fade-up")

#v(1fr)

= Revealing

== anim: one piece, one step

// The zoom is the loudest transition in the set, and it is used exactly once:
// here, where the talk stops describing the deck and starts describing the
// steps inside a slide.
#transition("zoom")

#v(1fr)

#stagger(
  card(title: [at: auto])[The next free step. Consecutive reveals number
    themselves, so nothing has to be renumbered when one is inserted.],
  card(title: [at: 3, the same as at: 2-])[A bare number means "from here
    on". Both are one selection, written two ways.],
)

// This line is the demonstration: it stands on step 1, goes away on step 2 and
// comes back on step 3. Spelled out it would need a sentence; shown it needs
// none.
#anim([And `at: "1,3"` means: here, gone, here again.],
      at: "1,3", enter: "fade-left")

#v(1fr)

== stagger: several things, one after another

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  stagger[
    - Written as a list. One step per point.
    - `stagger` sets the bullets itself.
    - Left to the list, they would stand there before their point arrives.
  ],
  stagger(
    card(title: [As blocks])[Instead of a list, any pieces at all.],
    card(title: [stride: 0])[All on the same step, spread only by `stagger:` in
      milliseconds, a wave instead of a sequence.],
  ),
)

#v(1fr)

== build: a drawing that cannot be taken apart

// A CeTZ canvas or a lilaq diagram is one piece. Typst hands out the finished
// setting, and what was a line in it cannot be reached from outside any more,
// so there is no `anim` around a part of a drawing. What there is, is the
// drawing itself, as often as one wants it.
//
// `draw` is called once per step and handed a question. `from(k, value)` gives
// the value back once the k-th piece is due and otherwise the same thing made
// of air: a colour with alpha 0, a stroke with a transparent brush, a text in
// `hide`. The piece is therefore never really missing, every stage measures the
// same to the point, and nothing around it moves while the drawing grows.
#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: horizon,
  build(from => {
    let w = 260pt
    let h = 150pt
    let a = (24pt, h - 24pt)
    let b = (w - 24pt, h - 24pt)
    let c = (w - 24pt, 26pt)
    box(width: w, height: h, {
      place(line(start: a, end: b, stroke: 3pt + t.muted))
      place(line(start: b, end: c, stroke: from(2, 3pt + t.muted)))
      place(line(start: a, end: c, stroke: from(3, 3.5pt + live)))
      place(dx: 74pt, dy: 44pt, from(3, text(size: 0.8em, fill: live)[c]))
    })
  }, steps: 3),
  stagger[
    - `steps` is said, not guessed: what the drawing does with its question is
      nobody's business from outside.
    - Exactly one stage is drawn at a time. Three layers stacked would paint
      the same axes and labels three times over, and the ink adds up.
  ],
)

#v(1fr)

== cue: in whatever order the room calls it out

// `stagger` has an order and holds to it. This group has none. The digits 1 to
// 9 pick the point that was just named, and the speaker view shows which digit
// belongs to which. The group owns as many steps as it has points either way,
// so the progress bar, the handout and the overflow check never learn that the
// order was open.
#speaker-note[
  Ask first, then press the digit. Whatever nobody names still arrives by
  paging on.
]

#v(1fr)

#side-by-side(
  split: (1.15fr, 1fr), align: top,
  cue("reading")[
    - Where the curve crosses zero.
    - Where it turns.
    - Where it is steepest.
  ],
  stagger[
    - Unset, the points keep their reading order, so a late one does not push
      the others down when it arrives.
    - `cue-layer` hangs a sentence, a formula or a drawing on one of the
      points. It shares that point's step, wherever the room puts it.
  ],
)

// The layer belongs to the second point and rides along with it. The group has
// to stand before its layers in the source, because a layer looks up which
// step its point was given.
#cue-layer("reading", 2,
  align(center, text(size: 0.9em, fill: live)[
    The turning point is the one they name first.
  ]))

#v(1fr)

== pause: for slides that simply unfold

// Long enough to fill its own height, so no centring pair here. A single
// `#v(1fr)` would push the whole body to the bottom rather than centre it.
No `anim`, no step numbers: everything after a `#pause` arrives one step later.
This slide holds two of them, and you have just crossed the first.

#pause

#callout(title: [Where it does not reach])[
  `#pause` is read at the top level of a slide body. Inside a grid cell or a
  table the content is a field of an element, not part of the body. There it is
  not seen, and `anim` has to do the work.
]

#pause

That is the whole of it: two markers, three steps, and not a number anywhere.
For anything finer (a piece that comes back later, two that arrive together),
reach for `anim`.

== alternatives: one place, changing content

#v(1fr)

// Three versions in the same box, each replacing the one before. The box is as
// large as the largest of them, so nothing around it jumps, which is the whole
// reason to reach for this instead of three separate `anim`s.
#alternatives(
  card(title: [First version])[One replaces the one before it, in exactly the
    same place. Nothing around it moves, because the space reserved is that of
    the largest version.],
  card(title: [Second version])[For the same statement in several passes, or
    for a drawing that changes step by step while its caption stays put.],
  card(title: [Third version])[`inline: true` turns the whole thing into a
    change in the middle of a running line.],
)

#anim([Three cards, one place. Only the last one reaches the PDF. Printed, all
       three would lie on top of one another.], at: 4, enter: "fade-up")

#v(1fr)

= Moving

== morph: the same thing, in a new place

#speaker-note[
  Actually page forward here. A still frame shows nothing at all of what this
  slide is about.
]

#v(1fr)

#statement(size: 1.4em, color: live)[
  #morph(<identity>, $ e^(i pi) + 1 = 0 $)
]

#anim([The same formula stands on the next slide once more. It does not appear
       there anew. It flies across and grows on the way, and the flight is what
       says "this is that formula, not a second one".],
      at: "2-", enter: "fade-up")

#anim([Source and target have to sit on *adjacent* slides; the flight is made
       out of the change between exactly two. Longer chains are built link by
       link.], at: "3-", enter: "fade-up")

#v(1fr)

==

// A morph and a moving stage would fight each other, so the runtime cross-fades
// wherever a morph meets a slide change, whatever the transition says. The
// "fade" here only makes that explicit for whoever reads the source.
#transition("fade")

#v(1fr)

#align(center, morph(<identity>, text(size: 2.4em, fill: live)[$ e^(i pi) + 1 = 0 $]))

#v(1fr)

#anim(align(center, block(width: 64%,
  text(size: 0.9em, fill: t.muted)[
    Whatever transition a slide asks for, a morph overrides it with a
    cross-fade: otherwise the flight would ride on a moving stage.
  ])), at: "2-", enter: "fade")

#v(0.5fr)

== pin: when the shape is not enough

#transition("push")

#v(1fr)

Glyphs are paired by their outline, and where that is ambiguous, by proximity.
Usually that is right. Where it is not (because the same letter occurs twice
and the wrong two find each other), the piece gets a name instead.

#statement(size: 1.4em)[
  #morph(<sum>, $ #pin("a", $a$) + #pin("b", $b$) = c $)
]

#anim([On the next slide the same equation is solved for #box($c$). Watch the
       two named terms swap sides: pinned, they take the long way round instead
       of the short one.], at: "2-", enter: "fade-up")

#v(1fr)

==

#transition("cover")

#v(1fr)

#align(center, morph(<sum>, text(size: 2em)[$ c = #pin("b", $b$) + #pin("a", $a$) $]))

#v(1fr)

#anim(align(center, block(width: 64%,
  text(size: 0.9em, fill: t.muted)[
    Without the pins both letters would find the nearest matching outline and
    quietly stay where they were.
  ])), at: "2-", enter: "fade")

#v(0.5fr)

== morph: without leaving the slide

// The flight is not tied to a slide boundary. It happens between two steps,
// and two steps of one slide are as much two steps as the change to the next
// one. Two shapes carry that themselves, and both are on this slide at once,
// stepping together.
//
// Left, `stagger(morph: true)`: every piece stays from its own step on, so at
// a step change the piece set last is the source and the new one the target.
// The new line grows out of the line above while the line above stays put.
//
// Right, `alternatives(morph: true)`: the versions all stand in the same
// place, so the flight is no distance at all and what is left of it is the
// glyphs rearranging themselves where they stand.
//
// `start: 1` on the right so the two run side by side on the same three
// steps; left to itself it would take the three steps after them.
#speaker-note[
  Page forward and stay. Left the chain grows downwards, right the same three
  steps happen in one place. Nothing else on the slide moves.
]

// Kein `#v(1fr)`-Paar: fünf Gleichungszeilen füllen den Rumpf, und gepolstert
// lief die Folie unten hinaus.
#v(0.2fr)

// A caption over each half, because the two are told apart by which one they
// are and not by what they say. Set here rather than left to the reader: a
// slide that shows two things at once has to name both.
#let ueber(was, satz) = align(center, {
  text(size: 0.78em, raw(was))
  linebreak()
  text(size: 0.72em, fill: t.muted, satz)
  v(10pt)
})

// The chain, as pairs of left-hand and right-hand side. Written apart for one
// reason: `&` aligns inside *one* equation, and every piece of a stagger is an
// equation of its own. So the alignment comes out of a shared measurement
// instead -- the widest left-hand side, measured once, and every line set to
// exactly that width, flush right. The equals signs then stand in a column and
// every line is still its own piece for the flight to come out of.
// Vier benannte Zeichen statt zweier gleichnamiger. Gleiche Namen auf der
// Zielseite teilen sich *eine* Quelle -- das ist die Spaltung, die beim
// Ausmultiplizieren gewollt ist. Aber `a` und `a` in derselben Fassung sind
// zwei verschiedene Stellen der Rechnung, und ohne eigene Namen flog beim
// Schritt von `(a+b)(a+b)` auf `a(a+b) + b(a+b)` alles aus dem letzten `a`
// heraus, kreuz und quer. Die Ziffern stehen nirgends auf der Folie; sie sind
// nur die Namen.
#let eins = pin("a1", $a$)
#let zwei = pin("b1", $b$)
#let drei = pin("a2", $a$)
#let vier = pin("b2", $b$)

#let kette = (
  ($#pin("x", $x$)^2 + #pin("halb", $6$)#pin("x", $x$) + #pin("c", $2$)$, $0$),
  ($#pin("x", $x$)^2 + #pin("halb", $6$)#pin("x", $x$)$, $-#pin("c", $2$)$),
  ($#pin("x", $x$)^2 + #pin("halb", $6$)#pin("x", $x$) + 9$,
   $-#pin("c", $2$) + 9$),
  ($(#pin("x", $x$) + #pin("halb", $3$))^2$, $7$),
  ($#pin("x", $x$)$, $-#pin("halb", $3$) plus.minus sqrt(7)$),
)

#context {
  let breit = calc.max(..kette.map(z => measure(z.first()).width.pt())) * 1pt
  let zeile-roh(z) = box[
    #box(width: breit, align(right, z.first()))
    #h(0.3em) $=$ #h(0.3em)
    #z.last()
  ]
  // Feste Zeilenhöhe, und der Abstand zwischen den Blöcken ausdrücklich
  // gesetzt: nur so ist der Zeilenabstand eine Zahl, die auch die Anmerkungen
  // daneben benutzen können. (`spacing:` von `stagger` greift nur im
  // Listenzweig; hier stehen die Stücke einzeln, und dann zählt der
  // Blockabstand.)
  let zh = calc.max(..kette.map(z => measure(zeile-roh(z)).height.pt())) * 1pt
  let luft = 13pt
  let zeile(z) = box(height: zh, align(horizon, zeile-roh(z)))
  side-by-side(
    split: (1.3fr, 1fr), align: top,
    {
      ueber("stagger(morph: \"rewrite\")", [every line stays])
      // Etwas kleiner als der Fließtext: die längste Zeile stieß sonst an den
      // Rand der Spalte.
      set text(size: 0.9em)
      // Ein Kasten mit fester Höhe, damit `place` an seiner oberen linken Ecke
      // hängt und nicht am Fluss: die Anmerkungen sollen *neben* den Zeilen
      // stehen, nicht unter ihnen.
      set block(spacing: luft)
      block(width: 100%, height: (zh + luft) * kette.len(), {
        stagger(morph: "rewrite", ..kette.map(zeile))
        // Was zu der jeweiligen Zeile geführt hat, an ihrem Rand.
        // `stagger-layer` schlägt den Schritt nach, statt ihn abzuzählen: die
        // Anmerkung zur Umformung k erscheint mit der Zeile, die aus ihr
        // hervorgeht -- und steht neben der Zeile *darüber*, denn dort wird
        // gerechnet. Daher `dy` eine Zeilenhöhe weniger.
        for (nr, was) in ((2, $| -2$), (3, $| +9$), (4, $"binomial"$),
                          (5, $| sqrt("")$)) {
          // `top + left` ausdrücklich: ohne eine Ausrichtung hängt `place` an
          // der Stelle im Fluss, an der es steht -- also unter der Kette --
          // und nicht an der Ecke des Kastens.
          place(top + left, dx: breit + 112pt,
                dy: (nr - 2) * (zh + luft) + zh / 2 - 8pt,
                stagger-layer("rewrite", nr,
                              text(size: 0.78em, fill: t.muted, was)))
        }
      })
    },
    {
      ueber("alternatives(morph: true)", [one place])
      // Das `align(center, …)` gehört um den ganzen Aufruf: `alternatives`
      // baut einen Kasten so breit wie seine breiteste Fassung, und der stand
      // sonst linksbündig unter einer mittigen Überschrift.
      align(center, alternatives(morph: true, start: 1, align: center + top,
        $ (#eins + #zwei)^2 $,
        $ (#eins + #zwei)(#drei + #vier) $,
        // Kein Zwischenschritt `a(a+b) + b(a+b)`. Dort wird *eine* Klammer zu
        // zweien, und was ein Zeichen mit sich nimmt, hängt daran, welche der
        // beiden Kopien man ansieht -- gemessen sah der Flug zerrissen aus,
        // gleich wie die vier Zeichen benannt waren. Der Schritt hier verteilt
        // jedes mit jedem, und dann hat jedes seinen Weg.
        $ #eins dot #drei + #eins dot #vier
          + #zwei dot #drei + #zwei dot #vier $,
        $ #eins#drei + #eins#vier + #zwei#drei + #zwei#vier $,
        $ #eins^2 + 2#eins#vier + #vier^2 $,
      ))
    },
  )
}

#anim(align(center, text(size: 0.8em, fill: t.muted)[
  Both are `morph` calls of one name with ranges that do not overlap, written
  out for you.
]), at: "6-", enter: "fade")

#v(0.2fr)

== camera: closer, and back out again

// The camera aims at a `pin` and at nothing else -- the same named piece the
// magic move uses, so a slide that already names its parts adds nothing but
// the aim. No coordinates, no counting: a pin's marker is the rectangle the
// runtime measures anyway.
#v(1fr)

#statement(size: 1.3em)[
  $ nabla times bold(E) = - #pin(<detail>, $(partial bold(B)) / (partial t)$) $
]

#anim([One of Maxwell's four. What the law actually claims sits in the term on
       the right, and that term is the smallest thing on the slide.],
      at: "2-", enter: "fade-up")

// `at: "3"` in quotes is one step closed: in on three, out again on four.
// 110pt of margin, not the default 16: the term is about 60pt wide, and with
// a narrow margin the crop came out at six times the size -- a screenful of
// one fraction, with nothing around it to say where on the slide it sat.
// A bare `at: 3` would hold the crop to the end of the slide. Coming back out
// is a keypress like any other, so it is counted like one and shows up in
// `info().step.total`.
#camera(<detail>, at: "3", margin: 110pt)

#anim([`margin` is how much of the slide stays around the detail, measured on
       the unzoomed slide. On paper there is no camera at all: the page is set
       whole, and the step is still counted, so the handout's footer names the
       same number as the talk.], at: "4-", enter: "fade-up")

#v(1fr)

== scene: a drawing that follows a number

// manim's `ValueTracker`, turned around. There a number moves while the film
// runs and the picture follows it; here Typst draws at compile time, so a
// number can only change at a step. The deck therefore writes a function from
// a value to a picture and says at which values the talk stops. Typst renders
// every stop and the frames between them; a keypress pulls the picture from
// one stop to the next.
//
// `stops` are the values themselves and not 0 to 1 -- that is the whole
// difference to `flipbook`, which knows only how far along it is.
#let tangent(x0) = {
  let w = 300pt
  let h = 176pt
  // The window on the plane: x from -2.2 to 2.2, y from -0.6 to 4.4.
  let px(x) = (x + 2.2) / 4.4 * w
  let py(y) = h - (y + 0.6) / 5.0 * h
  let f(x) = x * x
  let bogen = range(0, 89).map(i => {
    let x = -2.2 + i / 88 * 4.4
    (px(x), py(f(x)))
  })
  // The tangent at x0, from the derivative that this slide is about. Not
  // called `t`: that is the deck's own colour world, a few pages up.
  let tang(x) = f(x0) + 2 * x0 * (x - x0)
  box(width: w, height: h, clip: true, {
    place(rect(width: w, height: h, fill: t.surface, stroke: none))
    place(line(start: (0pt, py(0)), end: (w, py(0)),
               stroke: 1pt + t.border))
    place(curve(stroke: 2.5pt + t.muted, curve.move(bogen.first()),
                ..bogen.slice(1).map(curve.line)))
    place(line(start: (px(-2.2), py(tang(-2.2))), end: (px(2.2), py(tang(2.2))),
               stroke: 3pt + live))
    place(dx: px(x0) - 5pt, dy: py(f(x0)) - 5pt,
          circle(radius: 5pt, fill: live, stroke: none))
  })
}

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  // Three stops are two steps: the first is there as soon as the scene
  // appears, every further one costs a keypress. `tween` is the number of
  // frames *between* two stops, so this scene is 3 stops plus 2 times 8.
  scene("tangent", tangent, stops: (-1.7, 0, 1.7), tween: 8,
        width: 300pt, height: 176pt),
  stagger[
    - A stop may be a tuple, and the drawing then takes that many arguments.
      Unlike in manim, two trackers cannot move independently -- everything
      travels together.
    - `duration` is the time of one pull from stop to stop, not of the
      entrance -- the same separation `morph` draws.
  ],
)

// A layer belongs to one stop and shares its step. The scene has to stand
// before it in the source.
#scene-layer("tangent", 2,
  align(center, text(size: 0.9em, fill: live)[
    At the vertex the slope is zero, and only the line moved.
  ]))

#v(1fr)

= Blocks and media

== The five layouts

#v(1fr)

// `tiles` numbers its own reveals: one tile per step, without a hand-counted
// `at:` on each. The last two arrive together, as one `side-by-side`, which is
// why they are a separate `anim` and not two more tiles.
#tiles(
  columns: (1fr, 1fr, 1fr),
  card(number: 1, title: [card])[A named box. `number:` puts a numbered disc in
    front of the text.],
  card(number: 2, title: [callout])[The one that has to stick, with the bar down
    its left side.],
  card(number: 3, title: [side-by-side])[Columns; `split:` gives the widths.],
)

#anim(side-by-side(
  split: (1fr, 1fr), gutter: 24pt, align: top,
  card(number: 4, title: [statement])[One large line in the middle of the slide,
    while this very slide is using `tiles` and `side-by-side` at once.],
  card(number: 5, title: [tiles])[A grid that staggers itself: one tile per
    step, with no numbering by hand.],
), at: "4-", enter: "rise", exit: "fade")

#v(1fr)

// The drawing function gets a name of its own so `still:` can call it a second
// time, for the single frame that goes into the PDF.
#let wave(anteil) = {
  // `anteil` runs from 0 to 1, and Typst renders every frame separately. Here
  // a curve grows from left to right, so the picture shows that it is being
  // *drawn* rather than merely moved. Not called `t`: that name belongs to the
  // deck's colour world at the top of this file.
  let w = 340pt
  let h = 190pt
  let n = 60
  // `calc.round` returns a float; `range` wants an integer.
  let upto = calc.max(1, int(calc.round(n * anteil)))
  let points = range(upto + 1).map(i => (
    i / n * w,
    h / 2 - 54pt * calc.sin(i / n * 3 * calc.pi),
  ))
  box(width: w, height: h, clip: true, {
    place(rect(width: w, height: h, fill: t.surface, stroke: none))
    place(curve(
      stroke: 4pt + live,
      curve.move(points.first()),
      ..points.slice(1).map(p => curve.line(p)),
    ))
    place(dx: points.last().at(0) - 6pt, dy: points.last().at(1) - 6pt,
          circle(radius: 6pt, fill: live, stroke: none))
  })
}

== fit: for the block whose size the deck does not choose

// A wide table, a generated diagram, a list that came out of a data file:
// without `fit` such a block runs over the edge of the slide. In the PDF it is
// still to be seen standing there; in the browser the slide sits in a frame of
// fixed size and whatever reaches past it is simply cut away.
//
// `wrap: false` because this is a table. A paragraph or a list is offered the
// full width first and breaks into it instead of shrinking -- but anything
// that lays itself out in columns would rearrange its own columns, and that
// changes the picture rather than its size.
#let messreihe = {
  // Achtzehn Spalten. Gemessen in dieser Präsentation ist die Tabelle 936,8
  // Punkte breit, die Folie gibt zwischen ihren Rändern 777,9 her -- `fit`
  // staucht sie also auf gut vier Fünftel. Die Zahl der Spalten kommt aus der
  // Messreihe und nicht aus dem Entwurf der Folie, und das ist der Fall, für
  // den es `fit` gibt.
  let werte = (0.42, 1.08, 1.97, 3.12, 4.31, 5.24, 5.83, 6.11, 6.24, 6.29,
               6.31, 6.32, 6.32, 6.33, 6.33, 6.33, 6.33, 6.33)
  table(
    columns: werte.len() + 1,
    stroke: 0.5pt + t.border,
    inset: 7pt,
    align: right,
    table.header([*t* / s], ..range(1, werte.len() + 1).map(i => [#(i * 5)])),
    [*U* / V], ..werte.map(v => [#v]),
  )
}

#v(1fr)

#fit(wrap: false, messreihe)

#v(0.6fr)

#stagger[
  - Measured against the place it stands in and scaled geometrically, so it
    keeps its proportions and what stands around it counts with the new size.
    No factor is given by hand.
  - It only shrinks. `grow: true` also blows up a block that is smaller than
    its place, for the one large number meant to fill the slide.
]

#anim(text(size: 0.85em, fill: t.muted)[
  Eighteen columns at their natural size are wider than this slide. Nothing in
  the source says by how much they had to give.
], at: "3-", enter: "fade")

#v(1fr)

== Video and flipbook

// Vertically centred: both boxes are shorter than the body, and pinned to the
// top they would leave the lower half of the slide empty.
#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  // `poster` is what stands there while nothing is playing, and in the PDF,
  // where nothing can play at all. Without it that box would be empty on paper.
  // The size is exactly the clip's aspect ratio (1280×720): both the browser and
  // the PDF fill the box and crop for it, so any other ratio would cut something
  // off the sides.
  video("demo.mp4", width: 340pt, height: 191pt, muted: true, loop: true,
        controls: false, radius: 6pt, poster: image("demo-poster.png")),
  flipbook(
    wave,
    frames: 30, fps: 24, width: 340pt, height: 190pt, pingpong: true,
    // On paper there is no motion, so one frame has to do. `auto` would take
    // the first: here a dot at the left edge. `still` puts the finished curve
    // there instead.
    still: wave(1.0),
  ),
)

#anim([A video on the left, a flipbook on the right: drawn frame by frame by
       Typst, played back by the browser. Thirty frames are thirty layouts and
       thirty SVG trees in the file: worth it only where a still would not do.],
      at: "2-", enter: "fade-up")

#v(1fr)

== enter: "draw": the same gesture, one layout

// The flipbook next door drew this curve by setting thirty pictures. Here the
// same curve comes out of one. A stroked SVG path carries its own length;
// `stroke-dasharray` cuts it into a dash of exactly that length and a gap just
// as long, and `stroke-dashoffset` slides the dash in. At full offset nothing
// is there, at zero everything is, and in between a pen traces the path.
// Nothing is laid out twice.
//
// Deliberately the same wave as the flipbook: the room has just seen it built
// out of thirty layouts, and that is what makes this an argument rather than
// an example.
//
// Not on step one. Entering a slide restores the state instead of playing the
// entrances -- otherwise the transition and a dozen reveals would run against
// each other -- so a drawing needs a step in front of it.
//
// Two elements rather than one, laid over each other in a box of fixed size:
// every stroked path of *one* element sets off at the same time, and there is
// no knob for that. An order is said instead, one step per piece. That is the
// axis on step two and the curve on step three.
//
// 1400 ms, not the deck's 520: a drawing wants more time than a bullet point,
// and here the travel is the whole point.
#let feld = (340pt, 190pt)

#let grundlinie = {
  let (w, h) = feld
  line(start: (0pt, h / 2), end: (w, h / 2), stroke: 2pt + t.muted)
}

#let welle = {
  let (w, h) = feld
  let punkte = range(0, 121).map(i => (
    i / 120 * w,
    h / 2 - 54pt * calc.sin(i / 120 * 3 * calc.pi),
  ))
  curve(stroke: 4pt + live, curve.move(punkte.first()),
        ..punkte.slice(1).map(curve.line))
}

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: horizon,
  box(width: feld.first(), height: feld.last(), {
    place(anim(grundlinie, at: "2-", enter: "draw", duration: 900))
    place(anim(welle, at: "3-", enter: "draw", duration: 1400))
  }),
  stagger[
    - The same curve as next door, out of one layout instead of thirty.
    - Only strokes are traced. A glyph is a filled shape with no length to
      travel along, so text fades -- over exactly the drawing time.
    - An element with no stroke at all says so in the console, once.
  ],
)

#v(1fr)

== Embedding a foreign document

// `embed` puts arbitrary HTML into a sandboxed frame. `bridge:` gives that frame
// a name, and `bridge-job` sends it a dictionary on a given step. The package
// never reads it. What it means is known only to the document on the other
// side. This is exactly how `geogebra` drives its applets.
//
// A `+` at the start of a line is a list bullet in Typst and would throw the
// expression back into markup; the parentheses hold it in code.
//
// Everything in `em`: `embed` puts the deck's basic style in front of the
// document, and inside a zoomed frame one CSS pixel is exactly one point of the
// slide. So the lamp grows with the slides. Written as `78px` it would stay the
// size it has on a laptop even on a projector: measured against the slide,
// about a third as wide. A page that reflows on its own wants `zoom: false`
// instead, and then it spans real screen pixels.
#let lamp = (
  "<style>body{display:grid;place-items:center}"
  + "#p{width:3.4em;height:3.4em;border-radius:50%;background:"
  + t.muted.to-hex() + ";box-shadow:0 0 0 .3em "
  + t.border.to-hex() + ";transition:background .45s}</style>"
  + "<div><div id=p></div></div><script>"
  // Without this announcement the frame stays mute: the runtime marks a frame
  // live only once the document has said hello, and sends it nothing until then.
  + "parent.postMessage({typstage:1,ready:1},'*');"
  + "addEventListener('message',function(e){var d=e.data;"
  + "if(!d||d.typstage!==1||!d.jobs)return;"
  + "d.jobs.forEach(function(j){if(j.color)"
  + "document.getElementById('p').style.background=j.color;});});</script>"
)

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  embed(html: lamp, width: 100%, height: 190pt, bridge: "lamp",
        // In paged output nothing can run, and `embed` would leave a
        // labelled grey box. `fallback` puts the lamp at rest there, so
        // whoever holds the handout can see what the frame holds.
        fallback: circle(radius: 24pt, fill: t.muted,
                         stroke: 5pt + t.border)),
  stagger[
    - `bridge: "lamp"` names the frame, `bridge-job` sends it a dictionary on
      a step. The lamp changes for that reason and no other.
    - The document announces itself once with
      `postMessage({typstage: 1, ready: 1})`, or it gets nothing.
    - Paging back replays the run with a `reset`, so a job has to be
      repeatable.
  ],
)

// The three jobs sit on the first three steps, next to the first three bullets:
// the lamp is the proof that the sentence beside it is true.
#bridge-job("lamp", (color: t.muted.to-hex()), at: 1)
#bridge-job("lamp", (color: live.to-hex()), at: 2)
#bridge-job("lamp", (color: done.to-hex()), at: 3)

// `bridge-targets()` reports the names on the current slide, which is how a
// companion package can leave the applet unnamed when there is only one.
#context anim(
  text(size: 0.85em, fill: muted)[
    This slide has #bridge-targets().len() named target:
    #raw(bridge-targets().join(", ")).
  ],
  at: "4-", enter: "fade",
)

#v(1fr)

== GeoGebra: the same bridge, with a vocabulary

// The lamp on the last slide was a document of our own with three lines of
// JavaScript in it. An applet is the same arrangement with the words already
// written down: `geogebra` opens the frame, and the nine `ggb-*` calls are
// jobs over that same bridge. A deck that never calls `geogebra` carries none
// of this.
//
// The calls sit in the body of the slide they belong to -- that is where they
// are collected -- and they print nothing themselves.
//
// The fallback is drawn by hand rather than by CeTZ, so this deck keeps to the
// one package it is about. The last step animates without end, so there is no
// final state to draw; what stands on paper is the construction standing still
// at sixty degrees -- the circle, the point, the radius to it, and the sine
// hanging from it.
#let einheitskreis = {
  let r = 74pt
  let w = 2 * r + 30pt
  // Nicht `t`: so heisst weiter oben die Farbwelt des Decks.
  let winkel = 1.0472       // 60 degrees, where the drawing stands still
  let px = r * calc.cos(winkel)
  let py = r * calc.sin(winkel)
  box(width: w, height: w, {
    place(dx: w / 2 - r, dy: w / 2 - r,
          circle(radius: r, stroke: 1.6pt + t.muted, fill: none))
    place(line(start: (15pt, w / 2), end: (w - 15pt, w / 2),
               stroke: 1pt + t.border))
    place(line(start: (w / 2, 15pt), end: (w / 2, w - 15pt),
               stroke: 1pt + t.border))
    place(line(start: (w / 2 + px, w / 2), end: (w / 2 + px, w / 2 - py),
               stroke: 3pt + live))
    place(line(start: (w / 2, w / 2), end: (w / 2 + px, w / 2 - py),
               stroke: 3pt + t.muted))
    place(dx: w / 2 + px - 4.5pt, dy: w / 2 - py - 4.5pt,
          circle(radius: 4.5pt, fill: live, stroke: none))
  })
}

#v(1fr)

#side-by-side(
  split: (1fr, 1.05fr), align: horizon,
  // Feste Breite statt `100%`, und der Ausschnitt hat dasselbe Verhältnis.
  // `ggb-view` setzt x und y getrennt, also streckt ein Bereich, der nicht zum
  // Kasten passt, eine Achse: gemessen wurde der Einheitskreis hier zur Ellipse,
  // ehe die beiden Verhältnisse zusammenfielen. 360 zu 250 ist 1,44, und 3,6 zu
  // 2,5 ist es auch.
  geogebra("circle", perspective: "G", width: 360pt, height: 250pt,
           grid: false, fallback: align(center, einheitskreis),
           link: "https://www.geogebra.org/calculator"),
  stagger[
    - `ggb-run` builds the construction, `ggb-view` sets the section of the
      plane, `ggb-style` nails colour and weight.
    - `ggb-tween` sends a value on a journey. `ggb-set` puts it where you
      want it with no journey at all.
    - `ggb-hide` and `ggb-show` keep the radius and the sine back;
      `ggb-animate` is GeoGebra's own, and it has no end.
  ],
)

// The construction, and the two legs kept back until step three.
#ggb-run("k=Circle((0,0),1)", "t=Slider(0,6.2832,0.02)",
         "P=(cos(t),sin(t))", "s=Segment((cos(t),0),P)", "c=Segment((0,0),P)",
         target: "circle", at: "1-")
// Der Schieber selbst gehört nicht ins Bild, nur sein Wert.
#ggb-hide("t", target: "circle", at: "1-")
#ggb-set((t: 0), target: "circle", at: "1-")
#ggb-view(target: "circle", x: (-1.8, 1.8), y: (-1.25, 1.25),
          grid: false, at: "1-")
#ggb-style("k", target: "circle", at: "1-", color: t.muted,
           thickness: 2, label: false)
#ggb-style("P", target: "circle", at: "1-", color: live, point-size: 5)
#ggb-style("s", "c", target: "circle", at: "1-", thickness: 4, label: false)
#ggb-hide("s", "c", target: "circle", at: "1-")

// Step two: the point travels a third of the way round, and the value it hangs
// on is counted up frame by frame in the browser.
#ggb-tween("t", target: "circle", to: 2.0944, at: 2, duration: 1100)

// Step three: the radius and the sine, now that there is something to say
// about them.
#ggb-show("s", "c", target: "circle", at: 3)
#ggb-style("s", target: "circle", at: 3, color: live)

// Step four: the same kind of value, set instead of travelled. That is the
// whole difference between `ggb-tween` and `ggb-set`.
#ggb-set((t: 0.5236), target: "circle", at: 4)

// Step five: GeoGebra's own, which has no end of its own.
//
// `t` is a slider and not a plain `t=0`, and that is the whole reason this
// step does anything. Measured on the built deck: with a free number,
// `isAnimationRunning()` stayed `false` through every sample and `t` sat at
// its last value. GeoGebra animates what has bounds to run between.
#ggb-animate("t", target: "circle", at: 5, speed: 0.4, trace: ("P",))

#v(1fr)

== The pointer reaches in

// This frame is *not* bridged. No `bridge:`, no jobs, nothing sent from the
// slide at all. What it answers to is a hand, and in the speaker view that
// hand is not in this window: `m` there swaps the pen for the pointer, the
// press and the drag travel as fractions of the stage, and the talk window
// turns them back into pixels of its own before dispatching the event inside
// the frame. Two windows of very different sizes therefore land on the same
// spot in the document.
//
// The wave is the control, and that is not decoration. A dispatched event
// reaches every listener, but it does not drive the browser's own widgets: a
// real `<input type=range>` was measured here and did not move, because a
// browser only drags its own slider for input it trusts. A checkbox and a
// button did answer, since a click carries its activation behaviour along.
// So anything that listens for itself works, and the way to build for this is
// to listen rather than to rely on a native control.
//
// Drawn as SVG rather than a canvas: a canvas allocates its pixels once, and
// inside a zoomed frame it would be enlarged afterwards. An outline has none
// to lose. `non-scaling-stroke` holds the line width where the viewBox is
// stretched to the shape of the box.
#let wave = (
  "<style>"
  + "body{display:flex;flex-direction:column;gap:.4em;overflow:hidden}"
  // The wave takes what is left over after the readout, so the frame is filled
  // whatever height the slide gives it.
  + "svg{flex:1;min-height:0;width:100%;display:block;cursor:grab;touch-action:none}"
  + "svg:active{cursor:grabbing}"
  + "#r{font-size:.62em;display:flex;flex-wrap:wrap;gap:.35em 1.2em}"
  + "#r b{font-variant-numeric:tabular-nums;font-weight:600}"
  + "</style>"
  + "<svg id=\"s\" viewBox=\"0 0 400 130\" preserveAspectRatio=\"none\">"
  + "<line x1=\"0\" y1=\"65\" x2=\"400\" y2=\"65\" vector-effect=\"non-scaling-stroke\""
  + " stroke=\"" + t.border.to-hex() + "\" stroke-width=\"1\"/>"
  + "<polyline id=\"w\" fill=\"none\" vector-effect=\"non-scaling-stroke\""
  + " stroke=\"" + live.to-hex() + "\" stroke-width=\"2.4\" stroke-linejoin=\"round\"/>"
  // A transparent sheet over the whole box, so a press anywhere counts and not
  // only one that happens to hit the line.
  + "<rect x=\"0\" y=\"0\" width=\"400\" height=\"130\" fill=\"transparent\"/>"
  + "</svg>"
  + "<div id=\"r\"><span>frequency <b id=\"fv\">2.0</b></span>"
  + "<span>amplitude <b id=\"av\">0.60</b></span>"
  + "<span style=\"opacity:.55\">drag me</span></div>"
  + "<script>"
  + "var S=document.getElementById('s'),W=document.getElementById('w');"
  + "var n=2,m=0.6,zieht=0;"
  + "function draw(){var p=[],i,x;"
  + "for(i=0;i<=240;i++){x=i*400/240;"
  + "p.push(x.toFixed(1)+','+(65-Math.sin(i/240*n*2*Math.PI)*m*58).toFixed(1));}"
  + "W.setAttribute('points',p.join(' '));"
  + "document.getElementById('fv').textContent=n.toFixed(1);"
  + "document.getElementById('av').textContent=m.toFixed(2);}"
  // Absolute position, not a delta: across the box sets the frequency,
  // distance from the middle line the amplitude. One gesture says both, and a
  // press that arrives without a preceding move still means something.
  + "function stelle(e){var b=S.getBoundingClientRect();if(!b.width)return;"
  + "var x=(e.clientX-b.left)/b.width,y=(e.clientY-b.top)/b.height;"
  + "n=Math.max(1,Math.min(6,1+x*5));"
  + "m=Math.max(0.05,Math.min(1,Math.abs(0.5-y)*2));draw();}"
  + "S.addEventListener('pointerdown',function(e){zieht=1;stelle(e);"
  + "e.preventDefault();});"
  // Move and release on the document: a pointer dragged past the edge of the
  // sheet would otherwise leave the wave standing halfway.
  + "document.addEventListener('pointermove',function(e){if(zieht)stelle(e);});"
  + "document.addEventListener('pointerup',function(){zieht=0;});"
  + "draw();"
  + "</script>"
)

#speaker-note[
  This is the slide to try it on. Press `m`, then drag across the wave. What
  moves is the one in the hall; the frame in front of you is the same document
  and follows the same gesture, so you can see what they see.
]

#v(1fr)

#side-by-side(
  split: (1.05fr, 1fr),
  embed(html: wave, width: 100%, height: 205pt,
        // On paper nothing is dragged, so the fallback is the wave at the
        // setting it starts on.
        fallback: {
          let w = 190pt
          let h = 66pt
          let punkte = range(0, 145).map(i => {
            let x = i / 144.0
            (x * w, h / 2 - calc.sin(x * 2 * 2 * calc.pi) * h * 0.44)
          })
          curve(stroke: 2pt + live, curve.move(punkte.first()),
                ..punkte.slice(1).map(curve.line))
        }),
  stagger[
    - No `bridge:` here and no jobs. This frame answers to a hand alone.
    - In the speaker view `m` swaps the pen for the pointer. The gesture
      travels as fractions of the stage, so both windows hit the same point.
    - It reaches listeners, not native widgets. Build the control yourself.
  ],
)

#v(1fr)

= Look and output

== Themes are dictionaries

#v(1fr)

#side-by-side(
  split: (1.2fr, 1fr), align: top,
  card(title: [Three ways])[
    `themes.night` takes one of the five that ship with the package.

    `themes.lesson + (accent: blue)` changes one. A theme is a dictionary, so
    `+` is all it takes.

    `theme(paper: …, ink: …, accent: …)` builds one from scratch.
  ],
  callout(title: [What is inside])[
    Colours, fonts, sizes, and one word each for the built shapes: `header`,
    `footer`, `progress`. Only the title and section slides are functions: they
    are whole pictures, not variations on one another.
  ],
)

#v(1fr)

// One swatch: the colour itself next to its name. Written once here so the four
// exported colours are shown by the same shape instead of four hand-built boxes.
#let swatch(c, name) = box(baseline: 0.15em, {
  box(height: 0.72em, width: 0.72em, radius: 2pt, fill: c,
      stroke: 0.5pt + luma(70%))
  h(0.35em)
  raw(name)
})


// The third way, taken rather than described. A theme is a dictionary, so one
// built here can be read straight back out again.
#let eigen = theme(paper: rgb("#fffdf6"), ink: rgb("#22252b"),
                   accent: rgb("#0f766e"), muted: rgb("#5b6472"))

#anim(text(size: 0.85em)[
  Built on this slide with `theme(…)`: #swatch(eigen.paper, "paper")
  #swatch(eigen.ink, "ink") #swatch(eigen.accent, "accent")
  #swatch(eigen.muted, "muted") — #eigen.keys().len() keys, and
  this deck's own theme has #t.keys().len().
], at: 2, enter: "fade-up")

== Palettes, and the contract they are held to

// A palette is colour on its own, apart from fonts and sizes. Five ship with
// the package, and those five are held to a contrast contract by an assertion
// in `palettes.typ`: a palette that misses it does not compile. `contrast` is
// the instrument -- the WCAG ratio of two colours, 1 to 21 -- and
// `palette-report` is the reading it takes, one row per pair.
//
// The numbers are measured while this deck compiles, so the slide cannot go
// stale when a colour moves.
#v(1fr)

#side-by-side(
  split: (1.15fr, 1fr), align: top,
  stagger[
    - Five of them: `light`, `mono`, `textbook`, `parchment`, `dark`.
      A theme carries one and adds the rest.
    - `contrast(black, white)` is #calc.round(contrast(black, white)) --
      the largest there is. WCAG names 4.5 for body text and 3.0 for lines
      and bars.
    - It is a report, not a gate: only the five bundled palettes face the
      assertion. A palette written in a deck faces nothing.
  ],
  {
    let bericht = palette-report(palettes.dark)
    table(
      columns: (auto, auto, auto),
      stroke: none,
      inset: (x: 0pt, y: 4pt),
      column-gutter: 14pt,
      align: (left, right, left),
      table.header(
        text(size: 0.72em, fill: t.muted)[`palettes.dark`],
        text(size: 0.72em, fill: t.muted)[measured],
        text(size: 0.72em, fill: t.muted)[wants],
      ),
      ..bericht.map(f => (
        text(size: 0.78em, raw(f.pair)),
        text(size: 0.78em)[#calc.round(f.ratio, digits: 2)],
        text(size: 0.78em, fill: if f.ok { done } else { live })[#f.min],
      )).flatten(),
    )
  },
)

#v(1fr)

== What else the package hands out

#v(1fr)

// Each bullet prints its own value instead of describing it: the numbers and
// file names below are read out of the package while it compiles, so this slide
// cannot go stale when the package moves on.
#stagger[
  - `slide-width`, `slide-height` and `slide-margin`: the stage everything is
    measured on. Here #calc.round(slide-width.pt(), digits: 1)pt ×
    #calc.round(slide-height.pt(), digits: 1)pt with a
    #int(slide-margin.pt())pt margin.
  - #swatch(dark, "dark") #swatch(accent, "accent") #swatch(paper, "paper")
    #swatch(muted, "muted"): the default palette, for decks that would rather
    build on it than replace it.
  - `runtime-version` and `runtime-files`: the runtime's CSS and JavaScript,
    for `assets: "split"`, where they sit beside the HTML file rather than
    inside it: #runtime-files.map(f => raw(f.name)).join([, ]).
]

#v(1fr)

== What the deck knows about itself

// `info()` is the same reading the built-in chrome takes. Every number the
// package prints on a slide -- the footer, the fraction, the length of the
// progress bar -- comes out of this one function and out of no second count,
// so a hand-built footer and the built-in one cannot disagree. That is the way
// to build your own chrome without forking the theme.
//
// `class-clock` is the third thing a slide records about itself, and the only
// one that is not a number to print: how long the work on this slide is meant
// to take. It starts nothing. `Shift+T` in the speaker view offers the number,
// the speaker confirms or changes it, and only then does the clock run.
#class-clock(2)

#speaker-note[
  Press `Shift+T` here. The two minutes are the deck's suggestion, not a
  countdown that started behind your back.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1.05fr), align: top,
  context {
    let deck = info()
    card(title: [What info() answers here])[
      #set text(size: 0.85em)
      Slide #deck.slide.number of #deck.slide.total, step #deck.step.number of
      #deck.step.total, in section #deck.section.number of
      #deck.section.total, #emph(deck.section.title).
    ]
  },
  context {
    card(title: [What deck-outline() answers])[
      #set text(size: 0.78em)
      #for a in deck-outline() [
        #a.number.~#a.title #h(1fr) #a.count slides \
      ]
    ]
  },
)

#anim(text(size: 0.85em, fill: t.muted)[
  Both are read off the state every slide already carries: no `query`, no
  second walk over the document, and the same answer in the HTML and in the
  PDF.
], at: "2-", enter: "fade")

#v(1fr)

== bundle: three outputs, one run

// The one function of the package this deck cannot show at work, and it gets a
// slide of its own for saying so. Appended to the closing slide it ran 33
// points off the bottom of the stage -- measured, not guessed.
#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [The call])[
    #text(size: 0.66em, raw(lang: "typ",
      "#bundle(\n  theme: themes.lesson,\n  title: [Completing the Square],\n  html: \"talk.html\",\n  slides: \"slides.pdf\",\n  handout: \"handout.pdf\",\n)[\n  = A section\n  == A slide\n]"))
  ],
  card(title: [The one command])[
    #text(size: 0.66em, raw(lang: "sh",
      "typst compile \\\n  --features bundle,html \\\n  --format bundle \\\n  talk.typ out"))

    Since 0.15 Typst writes several files from one run, and everything
    here sits in one source anyway.
  ],
)

#anim(callout(title: [Why this slide only quotes it])[
  #text(size: 0.82em)[
    A file that calls `bundle` compiles *only* with `--format bundle`. This
    deck has to come out as HTML *and* as PDF, so it cannot call what it is
    about. Whoever wants both puts the body into a `#let`.
  ]
], at: 2, enter: "fade-up")

#v(1fr)

==

// `#invert` is the heading notation's way of saying `slide(invert: true)`: a
// marker, like `#pause`, because a heading carries no arguments. It is only
// looked for and never split on, so it is found however deeply it is nested --
// but not where the content is handed to a closure, which is `context`, `fit`,
// `anim`, `card` and `alternatives`. Measured, those five are the whole of it.
//
// It prints nothing and may stand anywhere in the body. It inverts the whole
// slide either way, not the part after it.
#invert
#transition("fade")

#v(1fr)

#statement(size: 1.45em)[
  One file, and every function of the package has now stood on a slide of it.
]

#v(1fr)

== Where to start

// Das Zeichen klein, als Quelle für den Flug auf die letzte Folie. Es steht
// als SVG im Paket und ist von Typst gesetzt wie alles andere auch; die
// Schrift ist beim Ausgeben in Pfade umgesetzt, es hängt also an keiner
// installierten Schrift.
#v(0.45fr)

#align(center, morph(<zeichen>, match: "block",
                     image("../assets/logo.svg", width: 128pt)))

#v(0.35fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [The whole file])[
    #text(size: 0.68em, raw(lang: "typ",
      "#import \"@preview/typstage:0.1.1\": *\n#show: presentation.with(\n  theme: themes.default,\n  title: [My talk],\n  handout: 3,\n)\n\n= First section\n== First slide\nOne point."))
  ],
  card(title: [The three commands])[
    #text(size: 0.68em, raw(lang: "sh",
      "typst compile talk.typ talk.html \\\n  --format html --features html\n\ntypst compile talk.typ slides.pdf\n\n# handout: 3 is set in the file\ntypst compile talk.typ handout.pdf"))
  ],
)

// The keys the runtime actually listens for, read out of its own key handler
// rather than out of memory. `s` for the speaker note and `p` for a print view
// stood here for a while and neither exists: there is no branch for either,
// in the talk window or in the speaker view.
#anim(callout(title: [In the browser])[
  #text(size: 0.85em)[
    `→` `←` one step · `Home` `End` first and last slide · `o` overview ·
    `f` full screen · `n` speaker view · `1`--`9` a point of an adaptive
    group · `?` key help
  ]
], at: 2, enter: "rise")

#v(1fr)

==

// Der letzte Beweis in eigener Sache: dasselbe Zeichen, eine Folie weiter,
// groß. `match: "block"` -- ein Bild hat keine Glyphen, die man paaren
// könnte, und paarweise gematcht würde ein Schwarm daraus statt einer
// Bewegung.
#transition("fade")

#v(1fr)

#align(center, morph(<zeichen>, match: "block",
                     image("../assets/logo.svg", width: 520pt)))

#v(1fr)
