// themes.lesson: the classroom.
//
//   typst compile theme-lesson.typ theme-lesson.html --format html --features html
//   typst compile theme-lesson.typ theme-lesson.pdf
//
// A lesson on completing the square. The spine of the talk is one morph chain:
// four neighbouring slides carry the same expression, and the glyphs walk to
// their new places instead of a new line appearing. That is the honest picture
// of what algebra does: nothing is added and nothing is removed, the same
// thing is written differently.

#import "@schule/typstage:0.1.0": *

// A theme is a dictionary. Its colours are available to the deck as well.
#let t = themes.lesson

// Two meaning colours, fixed once and passed everywhere, and they follow the
// convention of a maths textbook rather than being picked for looks: cool for
// what is already there, warm for what you have to supply. `given` is what the
// expression x^2 + 6x hands you. `missing` is the corner you add yourself, and
// warm is the loud one, so the eye goes to the new part first and not to the
// part it has read three slides running.
#let given = t.accent
#let missing = t.strong

#show: presentation.with(
  theme: t,
  title: [Completing the Square],
  subtitle: [Why the quadratic formula is not a rule to memorise (Year 10)],
  author: [Mathematics · Ms Reid],
  date: [15 September 2026],
  // Every page change is a plain cross-fade. The deck already has one kind of
  // motion: glyphs flying from one slide to the next. A sliding or zooming
  // page would compete with it at exactly the moment the class is meant to
  // follow a single digit across the screen.
  transition: "fade",
  // The slide body is a box of fixed height, and half the slides here are one
  // equation and two lines of text. Without this they would all cling to the
  // top edge with the calculation sitting under the title instead of in front
  // of the class. The hook belongs here and not in the body: it is put back
  // around every flying piece as well, so a morph is measured in the same
  // place it will land.
  style: it => { v(1fr); it; v(1fr) },
)

= When factoring runs out

== Two quadratics that look alike

#speaker-note[
  Let them try the second one for a minute before moving on. The point lands
  much harder once they have looked for the pair themselves and failed.
]

// `align: top` instead of the default `horizon`: the two cards are of
// different height, and centred against each other their title strips would
// sit at two levels, which reads as if one of them mattered more.
#side-by-side(
  split: (1fr, 1fr),
  align: top,
  card(title: [Solve $x^2 + 5x + 6 = 0$])[
    Two numbers with sum $5$ and product $6$: that is $2$ and $3$.

    // A card sets `block(spacing: 0pt)` for its title strip, and the rule
    // reaches the body too. A display equation would sit on the line above
    // it. The spacing is therefore given by hand here and below.
    #v(0.4em)
    #align(center, $(x + 2)(x + 3) = 0$)
    #v(0.4em)

    So $x = -2$ or $x = -3$.
  ],
  card(title: [Solve $x^2 + 6x + 2 = 0$])[
    Two numbers with sum $6$ and product $2$, so let us look for them.

    #v(0.5em)

    // `alternatives` puts the attempts in the same place, one replacing the
    // one before: the class watches a single search fail three times instead
    // of reading three finished lines. `start: 2` keeps the card's own text
    // on step 1, so the hunt begins only once the task has been read.
    #alternatives(
      start: 2,
      align: center + horizon,
      $1 dot 2 = 2$ + [, but ] + $1 + 2 = 3$,
      $(-1) dot (-2) = 2$ + [, but ] + $-1 - 2 = -3$,
      $0.5 dot 4 = 2$ + [, but ] + $0.5 + 4 = 4.5$,
    )
  ],
)

#anim(callout(title: [The search cannot succeed])[
  The pair we are hunting for is $-3 plus.minus sqrt(7)$, the very answer we
  wanted the factors to hand us. So stop hunting. Rewrite the expression
  instead, until $x$ occurs only *once*.
], at: 5, enter: "fade-up")

== The name is literal

// No maths in a speaker note: the note travels to the browser as a plain
// attribute, and an equation in it is dropped without a word.
#speaker-note[
  Ask before step three: "how big is the piece that is missing?" Someone will
  say 9 before you write it, and then half of 6, squared, is their idea and
  not yours.
]

// The picture is one block of a known size with every part placed inside it.
// `place` takes up no room, so a layer can appear without shifting the layers
// already drawn. These four layers are exactly the four things the class
// has to watch happen. Explicit `at:` on each: inside a `place` the automatic
// step cursor has no reliable order to run in.
#let x-side = 140pt
#let half-side = 58pt
#let head = 22pt // room for the edge labels above the square

#let tile(w, h, body, fill: none, stroke: none) = rect(
  width: w, height: h, fill: fill, stroke: stroke, inset: 0pt,
  align(center + horizon, text(size: 0.85em, body)),
)

#let edge-label(w, body) = box(
  width: w, align(center, text(size: 0.7em, fill: given, body)),
)

#let picture = block(
  width: x-side + half-side,
  height: head + x-side + half-side + 30pt,
  {
    // Step 1: x^2 as an actual square.
    place(top + left, dy: 0pt,
          anim(edge-label(x-side, $x$), at: 1, enter: "fade"))
    place(top + left, dy: head,
          anim(tile(x-side, x-side, $x^2$,
                    fill: given.lighten(78%), stroke: 0.8pt + given), at: 1))

    // Step 2: 6x along the sides. It has to go on as two strips, and the
    // width of one strip is the 3 that the whole method turns on.
    place(top + left, dx: x-side, dy: 0pt,
          anim(edge-label(half-side, $3$), at: 2, enter: "fade"))
    place(top + left, dx: x-side, dy: head,
          anim(tile(half-side, x-side, $3x$,
                    fill: given.lighten(90%), stroke: 0.8pt + given), at: 2))
    place(top + left, dy: head + x-side,
          anim(tile(x-side, half-side, $3x$,
                    fill: given.lighten(90%), stroke: 0.8pt + given), at: 2))

    // Step 3: the corner is not there. A dashed outline is the argument of
    // the whole lesson in one shape, so it gets a step to itself.
    place(top + left, dx: x-side, dy: head + x-side,
          anim(tile(half-side, half-side, text(fill: missing)[?],
                    stroke: (paint: missing, thickness: 1pt, dash: "dashed")),
               at: "3", enter: "fade"))

    // Step 4: filled in. Same place as the question mark, so on screen it is
    // replaced rather than joined; on paper the filled tile covers it.
    place(top + left, dx: x-side, dy: head + x-side,
          anim(tile(half-side, half-side, text(fill: white, weight: "bold")[9],
                    fill: missing, stroke: 1pt + missing),
               at: "4-", enter: "scale"))
    place(bottom + center,
          anim(text(size: 0.9em, fill: missing, weight: "bold", $(x + 3)^2$),
               at: "4-", enter: "fade-up"))
  },
)

#side-by-side(
  split: (1fr, 1.1fr),
  align(center, picture),
  stagger(
    start: 1,
    [Draw $x^2$ as a real square. Both sides are $x$.],
    [$6x$ has to lie along those sides. One strip of $6$ would cover one side
     only, so it goes on as *two strips of $3$*. There is the halving.],
    [A corner is missing: $3$ by $3$, area $9 = (6 slash 2)^2$.],
    [Filled in, the figure is $(x + 3)^2$, but that is $9$ more than we were
     given.],
  ),
)

== Step 1 of 4: the constant is in the way

// The chain begins. From here to step 4 the same expression stands on every
// slide under the name <term>, and the pins carry the digits that have
// somewhere to go: <b> is the 6 that becomes the 3, <out> is the 9 that is
// taken back out and ends up as the number under the root. No space between
// the pin and the x: a box next to a symbol in maths keeps the source space,
// and "6 x" would set itself apart from every other line of the chain.
#statement(color: given)[
  #morph(<term>, $ x^2 + #pin(<b>, $6$)x + #pin(<c>, $2$) = 0 $)
]

#anim([$x^2 + 6x$ is the unfinished square from the picture. The $+ 2$ is no
       part of it. Leave it standing and work on the two terms in front.],
      at: 2, enter: "fade-up")

== Step 2 of 4: put the corner in, take it straight back out

// Both nines and the signs in front of them are orange: they are the only
// thing on the slide that was not there a moment ago, and the colour says so
// before anyone reads the line.
#statement(color: given)[
  #morph(<term>, $ x^2 + #pin(<b>, $6$)x
                   #text(fill: missing, $+ #pin(<in>, $9$) - #pin(<out>, $9$)$)
                   + #pin(<c>, $2$) = 0 $)
]

#anim([Adding $9$ and subtracting $9$ in the same line changes nothing at all.
       That is what buys us the square: we may put in whatever we like, as long
       as we take it away again.], at: 2, enter: "fade-up")

== Step 3 of 4: now it reads as a square

#statement(color: given)[
  #morph(<term>, $ (x + #pin(<b>, $3$))^2 - #pin(<out>, $7$) = 0 $)
]

// Two claims, one per step, because they are two readings of the same flight:
// what went into the bracket, and what was left over outside it.
#stagger(
  start: 2,
  [$x^2 + 6x + 9$ is $(x + 3)^2$. Watch the $6$ walk into the bracket and
   arrive as a $3$.],
  [Outside the bracket, $-9 + 2$ collects into $-7$.],
)

== Step 4 of 4: $x$ occurs once, so undo it

#statement(color: given)[
  #morph(<term>, $ (x + #pin(<b>, $3$))^2 = #pin(<out>, $7$) $)
]

Every step so far was a rewrite. Only now do we *solve*, and we can, because
there is one $x$ to get at instead of two.

#pause

$ x + 3 = plus.minus sqrt(7) quad => quad x = -3 plus.minus sqrt(7) $

#pause

#align(center, text(fill: t.muted)[
  $x approx 0.65$ and $x approx -6.65$: two roots, and no factor pair in sight.
])

== The one sign that goes missing

#speaker-note[
  This is the mistake to expect in the test, so it gets a slide of its own and
  nothing moving on it. Read the wrong line out and let someone find the fault.
]

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  card(title: [What gets written], color: missing)[
    #v(0.2em)
    #align(center, $x^2 + 6x + 2 = (x + 3)^2 + 2$)
    #v(0.5em)

    The corner went in and never came out again.
  ],
  card(title: [What is true])[
    #v(0.2em)
    #align(center, $x^2 + 6x + 2 = (x + 3)^2 - 7$)
    #v(0.5em)

    The $9$ went in, so the $9$ has to come off.
  ],
)

#pause

#callout(title: [Check it in five seconds])[
  Put $x = 0$ into both sides. The left gives $2$; the wrong right-hand side
  gives $11$, the correct one gives $2$. Any number would do. $0$ is simply
  the fastest.
]

= Where the formula comes from

== The same moves, with letters

#speaker-note[
  Do not read the last line out as a formula. Read it as: the same thing we
  just did with the 6, only the 6 is called b now.
]

$ a x^2 + b x + c = 0 quad => quad x^2 + b/a x + c/a = 0 $

#pause

Half of $b slash a$ is $b slash 2a$, so the corner is $(b slash 2a)^2$. Put it
in, take it back out, and collect what is left over:

#pause

// The source of the second chain, and the only morph in the deck that waits:
// the slide before carries no <general>, so nothing is in flight towards this
// line and it may appear together with the reasoning that leads to it.
// `<bb>` and `<aa>` are the two pieces whose journey is the point of the
// lesson: the minus-b and the 2a of the formula are not decoration, they are
// what halving b leaves behind.
#statement(color: given)[
  #morph(<general>, at: "3-", $ (x + #pin(<bb>, $b$)/#pin(<aa>, $2a$))^2
                                = (b^2 - 4 a c)/(4 a^2) $)
]

== You have seen this before

#speaker-note[
  Page back and forth once here. The b and the 2a fly out of the bracket into
  their places in the formula, and that flight is the only thing worth saying
  on this slide.
]

#statement(color: missing, size: 2em)[
  #morph(<general>, $ x = (-#pin(<bb>, $b$) plus.minus sqrt(b^2 - 4 a c))/#pin(<aa>, $2a$) $)
]

#anim([Take the root of both sides and move the $b slash 2a$ across. Nothing
       happened on this slide that did not happen on the slide with the $6$
       and the $2$.], at: 2, enter: "fade-up")

#anim(callout(title: [Homework])[
  Complete the square on $x^2 - 10x + 18$ and on $2x^2 + 8x + 3$. Write the
  corner you put in and the number you took back out on two separate lines.
  That is where the marks are.
], at: 3, enter: "fade-up")
