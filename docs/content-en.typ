#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= What this package is

`typstage` turns a single Typst file into an animated presentation for the
browser, and a PDF from the same source. The sentence behind it is this:
*Typst typesets, the browser moves.* Every slide is set by Typst as SVG and
written into the HTML file as such, so the arrangement in the browser is the
one on paper. Motion comes afterwards. Whatever is meant to stir is registered
for it in the source, and a small runtime sets it going in the browser.

The rest follows from that. A slide is a slide and not a stack of intermediate
states. The PDF has one page per slide, not one per step. And whatever belongs
to the motion alone falls away on paper by itself.

== Five words this manual uses

The vocabulary matters more here than in a package that counts pages, because
one of these words does not mean what it usually means.

/ Slide: One picture, typeset once by Typst. It is one page of the PDF and one
  `.ts-slide` in the HTML.
/ Step: One press of the arrow key. A slide can hold several of them. Paging
  forward inside a slide reveals more of it; at its end the next press moves
  to the next slide. The address bar counts steps, the footer counts slides.
/ Element: A piece of a slide that the runtime may touch. It is typeset in
  place, held back with `hide()`, and painted over a marker that says where it
  belongs. `anim`, `stagger`, `alternatives`, `morph`, `embed`, `video` and
  `flipbook` all produce one.
/ Morph: The same named element on two slides. Between them it flies, glyph by
  glyph where it can.
/ Speaker view: The same file opened a second time with `#speaker` on the
  address. It carries the note, the clock and the next step, and it draws on
  the slide the room sees.

== Where it sits among the others

Typst has good presentation packages, and most of them make PDF. `touying` and
`polylux` are mature, have far more themes, and are on Universe. If you want a
normal PDF talk, take one of those.

What this package does that they do not is level four of four: a named piece
stands in one place on slide n and elsewhere on slide n+1 and flies there,
ideally glyph by glyph, so an equation visibly rewrites itself. The other
levels are a page that turns, a viewer that cross-fades between two pages, and
whole slides pushed around by a script.

The other comparison group is `reveal.js`, `Slidev` and `Quarto`. They animate
in the browser and do it well, but the layout is HTML's, not Typst's. Here the
layout is Typst's to the point, and the price is on the next page but one.

#warning[
  The price, so it stands before the first line of code and not after the
  first talk. The slides are SVG outlines. Nothing in the browser is
  selectable or searchable, and a screen reader sees nothing at all. There is
  a chapter on that further down, and for some talks the price is too high.
]

This manual is ordered by intent rather than by function:

+ *Your first presentation* — from the empty file to a running HTML
+ *Revealing a slide step by step* — `pause`, `stagger`, `anim`, `alternatives`
+ *Showing instead of claiming* — an applet, a video, a flip book
+ *GeoGebra* — constructions that follow the steps of the slide
+ *Developing a calculation* — magic move across several slides
+ *Giving the talk* — keys, touch, the overview, the speaker view
+ *Three outputs from one source* — talk, slide deck, handout
+ *Making it your own* — themes, colours, canvas, building blocks
+ *Handing it on* — one file, assets, hosting
+ *What it cannot do* — reach, accessibility, size
+ *When nothing happens* — the traps, in the order they are usually hit
+ *API reference* — every function, from the source

#info[
  The typeset examples in this manual are paper and therefore show the final
  state, everything at once. What happens one after another in the browser is
  said in the text beside them or as a comment in the source.

  Every `typ` listing here is compiled against the real package before the site
  is built, by `python3 .github/scripts/pruefe-beispiele.py`, so that no example
  survives a rename in the package that makes it invalid. What the run does
  *not* do belongs in the same breath: most listings are fragments rather than
  whole files, so it wraps each one in a slide and checks that it compiles
  there, not that the slide then looks right. Lines that deliberately raise an
  error are marked as such and have to keep failing, and they name what they
  have to fail at -- a line that breaks for some other reason is a failed
  check, not a passed one. A line that does compile but does not do what was
  wanted ("has no effect", "too late") it cannot tell from a correct one. It
  compiles for the browser, not for paper, and it never looks at the prose
  beside a listing -- which is where a stale number likes to sit. Listings in
  other languages are left alone and counted, so nobody loses one by writing
  the wrong fence. And an example whose companion package is missing is
  skipped, and the run says which.
]

= Your first presentation

The aim of this chapter: a complete, presentable talk, in ten minutes and
without detours.

== One file is enough

No more than this is needed. An import, a show rule, and headings. The
following file is complete and can be typed out:

// Read from the file rather than copied out: "complete and can be typed out"
// is a promise, and it only holds if these are the very bytes that
// `.github/scripts/pruefe-beispiele.py` compiles.
#show-code(raw(read("../examples/handbuch/first-deck.typ").trim(),
               block: true, lang: "typ"))

A first-level heading is a section slide, a second-level heading is a slide,
and the text below it is its body. That is the whole structure.

== More than two levels

The default cuts the deck at the second level: `=` becomes a section slide,
`==` becomes a slide. `slide-level` moves that cut. A heading *above* it
becomes a section slide, a heading at it or below it becomes a slide.

// check: dokument
#show-code[```typ
#show: presentation.with(title: [Analysis I], slide-level: 3)
= Part I -- Limits
== Sequences
=== What a sequence is
A map from the naturals into the reals.
=== Convergence
For every epsilon there is an N.
== Series
=== Partial sums
The sum of the first n terms.
```]

`= Part I` and `== Sequences` each become a section slide, every `===` becomes
a slide. The transition slides for *both* levels come along by themselves: a
section heading here already is the transition slide, so there is nothing to
switch on and no hook to write.

`slide-level: 1` makes every heading a slide; the deck then has no structure
level at all.

The five bundled themes draw a deeper level more quietly: the title gets
smaller, and above it stands what the section hangs under. A theme with a
`section` function of its own reads `s.depth` and `s.parents` off the record
and may ignore both. Then every level looks alike, and nothing breaks.

What the deck knows about its structure is in `info()`: `section` still means
the level directly above the slide, `levels` has one entry per structure
level, and `outline` is the whole thing. The section "`info()`: what the deck
knows about itself" says what is in them.

=== Text that belongs to no slide

Between a section heading and the next heading there is no room for text. A
section slide is a whole picture the theme draws; it has no body. Such text
used to fall out of the deck without a word: it compiled, the slide count was
right, and the paragraph was simply gone. Now that there is more than one kind
of structure heading there are more chances to run into that, so compiling
stops there with a message instead.

A sentence between `= The proof` and `== The dissection` therefore aborts with
`content between the heading "The proof" and the next one belongs to no
slide`:

// check: dokument bricht=belongs_to_no_slide
#show-code[```typ
#show: presentation.with()
= The proof
This sentence belongs to no slide and stops the compile.
== The dissection
```]

It belongs under the slide heading:

// check: dokument
#show-code[```typ
#show: presentation.with()
= The proof
== The dissection
This sentence belongs to the slide and gets typeset.
```]

Two reservations, so that nothing here promises more than the code holds.
First, text *before* the first heading is refused as well, but only if the deck
has any heading at all: a body without a single heading is not a presentation
in the heading notation, and there it is not one slide that is missing, there
are none. Second, all of this applies to the heading notation only; whoever
passes slides as arguments writes every body out anyway.

== Two compilations

The same file yields two outputs, and which one you get depends on the flags:

#show-code[```sh
typst compile talk.typ talk.html --format html --features html
typst compile talk.typ talk.pdf
```]

#warning[
  Without `--features html` the HTML export is not available at all, and Typst
  says so in a way that is easy to mistake for a mistake of your own. The
  feature is experimental on Typst's side, not on this package's.
]

== Looking at it

The HTML file is one file. Double-click it, and it runs: no server, no network,
nothing loaded afterwards. That is deliberate and it is the reason several
decisions later in this manual look stricter than they need to.

Arrow keys page. `?` shows every key, `o` opens the overview, `f` goes full
screen, and `n` opens the speaker view in a second window.

= Revealing a slide step by step

The aim of this chapter: a slide that unfolds in front of the room instead of
standing there finished.

== Which tool for what

Six building blocks cover very nearly everything. They mix on one slide, and
which one is right depends on how finely the slide needs to be steered.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Tool*], [*For what*]),
  [`#pause`],
  [The slide unfolds from top to bottom without anything having to be wrapped.
   The shortest way and the commonest case.],
  [`stagger[…]`],
  [A list point by point, bullet and text together. Also for several blocks in
   sequence.],
  [`anim(…)`],
  [One particular piece on one particular step, with a motion of its own. The
   tool wherever `#pause` cannot reach: in grid cells, tables, boxes.],
  [`alternatives(…)`],
  [Several versions of the same thing in the same place, each replacing the
   one before.],
  [`build(…)`],
  [A drawing or a diagram that comes into being in stages -- one CeTZ line,
   one lilaq data series, one label after another.],
  [`scene(…)`],
  [A drawing that depends on a value, and the values at which the talk stops.
   For everything that *moves* rather than being added.],
)

Beside them stand `tiles` for a grid that staggers itself, and `morph` for
things that fly between two slides.

== The step cursor

Every slide carries a step cursor. `at` is `auto` by default, and `auto` means
"the next free step". Consecutive reveals therefore number themselves, and as
a rule a slide holds no number at all.

#show-code[```typ
== Three things
#anim[first]            // step 1
#anim[second]           // step 2
#anim(at: 4)[late]      // 4
#anim[after that]       // 5
```]

The spellings of `at`:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Written*], [*Meaning*]),
  [`auto`], [the next free step (the default)],
  [`3`], [from step three on, the same as `"3-"`],
  [`(2, 5)`], [on step two and on step five],
  [`"2-"`], [from step two on],
  [`"1-2"`], [on steps one and two, not after that],
  [`"2,4"`], [on step two and on step four],
  [`"-2"`], [from the start until step two],
  [`"3"`], [exactly on step three],
)

A bare number is an open end: what is there once stays until the end of the
slide. That is the normal case. A closed spelling such as `"1-2"` or `"3"`
lets the element disappear again, and then `exit` applies.

== A slide without a single number

`#pause` needs no counting at all. It cuts the body at the place where it
stands, and everything after it arrives one step later:

#show-code[```typ
== What we know

The two legs carry as much area as the hypotenuse.

#pause

$ a^2 + b^2 = c^2 $

#pause

And that is enough to compute the third side from two of them.
```]

#tip[
  `#pause` splits the body. That is why it works between blocks and not inside
  a grid cell or a table: there is nothing there to cut. `anim` is the tool for
  those places, and it can go anywhere content can go.
]

== A list point by point

`stagger` takes a list and reveals it item by item, bullet and text together:

#show-code[```typ
#stagger[
  - What the room already knows
  - What it is about to learn
  - What it will be able to do afterwards
]
```]

`stride: 2` puts two items on each step, `stride: 0` puts all of them on the
same one. `start` sets the first step, `enter` the motion, `stagger` the delay
in milliseconds between neighbours, `spacing` the distance between the items,
and `dim` lets each point step back once the next one arrives.

#tip[
  `stagger` also takes several blocks instead of one list. Then each block is
  one step, which is the way to reveal three paragraphs or three pictures in
  turn without writing three `anim` calls.
]

`dim: true` turns the sequence into a walk: the point being discussed stands
there, the ones before it stay legible but muted.

#show-code[```typ
#stagger(dim: true)[
  - What the room already knows
  - What it is about to learn
  - What it will be able to do afterwards
]
```]

For that, each point holds exactly its own step instead of the rest of the
slide and then rests in `after: "dimmed"` (see "The muted resting state"). Two
things follow, and both are meant. The last point dims as well as soon as the
slide has a further step after it, because then the walk has moved on from it
too. And `stride: 0`, which puts every point on one step, makes them all dim
together on the next.

== Revealing in the order it is called out

Some points have no order. What a graph shows, what stands out in an
experiment, which ways there are to work something out -- a class names those
in whatever order they come, and a deck that reveals them in *its* order makes
the teacher either wait or reshuffle.

`cue` turns that round: the digits `1` to `9` reveal whatever was just
named.

// check: folie
#show-code[```typ
#cue("readings", start: 2)[
  - positive and negative values
  - lowest and highest value
  - falling and rising
]
```]

The group takes a name, because something else can point at it. It owns as many
steps as it has points, and the order changes nothing about that -- the
progress bar, `info().step.total`, the overflow check and the handout are all
untouched.

Set, the list keeps its reading order: a point not yet named holds its place, so
nothing jumps when it arrives later.

=== What appears together with a point

A point rarely stands alone. `cue-layer` hangs something on the same step
-- a drawing layer, a picture, a sentence beside it:

// check: folie davor
#show-code[```typ
#cue-layer("readings", 1, [and what goes with it])
```]

Nothing is linked to do that: the point and the layer share a step, and
swapping the step moves both. You can hang as much on a point as you like.

The group has to stand *before* its layers in the source -- a layer looks up
which step its point was given. Standing after them, the package says so rather
than quietly doing nothing.

#tip[
  For a CeTZ drawing that grows with the points, draw the scaffolding once and
  every layer as its own complete drawing, with everything else made invisible
  through `cetz.draw.hide(rest, bounds: true)` but still counting towards the
  bounds. All layers then lie exactly on top of each other and the graph holds
  still, in whatever order it grows -- measured on a pair of axes with three
  label layers, every subset comes to
  347.9 pt #sym.times 329.71 pt.

  A layer carries *only its own contribution*, no grid and no base curve.
  Otherwise the layer set last paints over the first, and that regardless of
  the order things are revealed in.

  Where the drawing is to grow in the order it was written instead, `build`
  is the tool -- see "A drawing that grows". There every stage carries the
  *whole* drawing, and the question of painting over does not arise.
]

#info[
  The forward arrow reveals the next point *not yet named*, in the order it is
  written. Paging alone therefore behaves exactly like a staggered list;
  pressing a digit gives that point; and the two mix freely. Only once the
  group is full does the arrow carry on.

  Going back takes back: one step back frees the point named last, and leaving
  the slide backwards leaves the group untouched for the next visit. Otherwise
  it would be used up after a single pass.

  The digits work only while an adaptive group stands on the slide. In the
  speaker view every point still open stands there pale, with its digit on the
  bullet; in the hall it is invisible. Pressed a second time a digit does
  nothing -- taking a point back is what paging backwards is for.
]

== One piece on a step of its own

`anim` wraps exactly what should appear and says when:

#show-code[```typ
#side-by-side(
  card(title: [Before])[The old way.],
  anim(at: 2, enter: "fade-left", card(title: [After])[The new one.]),
)
```]

=== Entrance and exit

`enter` and `exit` name the motion. Eleven of them exist:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Written*], [*What happens*]),
  [`"fade"`], [opacity alone],
  [`"fade-up"`], [from a little below, the default for an entrance],
  [`"fade-down"`], [from a little above],
  [`"fade-left"`, `"fade-right"`], [from the side],
  [`"scale"`], [grows into place],
  [`"scale-down"`], [shrinks into place],
  [`"blur"`], [out of the blur],
  [`"rise"`], [from below and slightly smaller, the loudest of them],
  [`"draw"`], [it draws itself -- see "A path that draws itself"],
  [`"none"`], [it is simply there],
  [`"hold"`], [not an exit but a wait: the piece stays until the next one is
               there. As an `enter` it is the same as `"none"`],
)

`duration` is in milliseconds and `auto` takes the presentation's. `delay`
holds the start back, which is what makes two elements on the same step arrive
one after the other.

*A name the package does not know is an error at compile time*, exactly as it
is for `easing`. The runtime used to fall back to `"fade"` without a word, and
a typo then looked like a deck that simply moved differently than intended --
which nobody finds in the middle of a talk.

// check: folie bricht=the_package_does_not_know_that_effect
#show-code[```typ
#anim(enter: "fdae-up")[A typo.]   // error at compile time
```]

=== The curve

Everything this package moves runs on the same curve: slow off the mark, brisk
through the middle, soft at the end. `easing` hands that curve to a single
element -- a result may overshoot its mark and swing back, a stack of bullets
may arrive at an even pace.

// check: folie pre=zeichnung
#show-code[```typ
#anim(result, enter: "rise", easing: "out-back")
#stagger(stride: 0, stagger: 60, easing: "out-quad")[
  - first this
  - then that
]
```]

It stands wherever `duration` stands: on `anim`, `stagger`, `alternatives` and
the drawing that grows in stages. And it applies to everything the element does
itself -- the entrance, the departure and the dimming. Not to the slide
transition, which belongs to the slide and not to the element; and not to the
flight of a magic move, which has two ends and whose curve cannot be settled
from one of them.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Name*], [*Curve*]),
  [`"standard"`], [this package's own curve, written out -- the same as saying
                   nothing],
  [`"linear"`], [even, with no run-up and no run-out],
  [`"ease"`, `"ease-in"`, `"ease-out"`, `"ease-in-out"`],
  [the four the Web Animations API knows by itself],
  [`"in-quad"`, `"out-quad"`, `"in-out-quad"`], [gentle],
  [`"in-cubic"`, `"out-cubic"`, `"in-out-cubic"`], [more pronounced],
  [`"in-expo"`, `"out-expo"`, `"in-out-expo"`], [sharp -- nearly everything
   happens at one end],
  [`"in-back"`, `"out-back"`, `"in-out-back"`], [winds up and overshoots],
)

`in` means slow off the mark, `out` means soft at the end. For an entrance
`out` is nearly always the right one: the eye watches the ending, not the
beginning.

*A name that does not exist is an error at compile time* and not a silent
default. A typo would otherwise hand back the house curve, and whoever wrote it
would spend a while wondering why the overshoot does not overshoot. The message
lists what there is to choose from. (For `enter` it is the other way round, and
older; see the box above.)

// check: folie pre=zeichnung bricht=the_package_does_not_know_that_curve
#show-code[```typ
#anim(result, easing: "out-bounce")   // an error at compile time
```]

*The three `back` curves go past their mark*, and that is what they are for. On
a travel that is the swing back; on opacity the browser clips whatever reaches
past 1, so `easing: "out-back"` on a plain `"fade"` is merely a faster
`"fade"`. It pays off together with an effect that travels: `"rise"`,
`"scale"`, `"fade-up"`.

Springs and bounces -- `elastic`, `bounce` -- do not exist here. They are not
cubic Bézier curves, and the Web Animations API knows only those; they could
only be rebuilt as a sequence of frames.

#info[
  Without `easing` not a byte of a deck changes. The name is resolved to a
  finished curve at compile time and written into the markup only where it
  departs from the default -- otherwise every element of every deck would carry
  a new attribute. Measured on this package's eight examples that name no
  curve, HTML as well as PDF: the same bytes as before.
]

=== The muted resting state

An element whose range has an end goes away afterwards: it plays `exit` and
keeps the room it had. That is one resting state after the range. `after:
"dimmed"` gives the second. The point then does not leave. It stays and is
drawn muted, legible but no longer the thing being talked about.

#show-code[```typ
#anim(at: "2-3", after: "dimmed")[A passing remark.]
#anim(at: 4)[And on with the talk.]
```]

Nothing moves and nothing is recoloured: the element settles to 65 percent
opacity and comes back up when you page back. `after` has exactly two values,
`"hidden"`, the default and what it has always done, and `"dimmed"`.

`after` wants a range that ends. `at: auto` and `at: 3` run to the end of the
slide, and what never leaves has no after; the package says so as an error
rather than quietly doing nothing. `at: "3"` is that one step, `at: "2-3"` a
range.

The slide also needs a step after the range, which is what the second line
above is for. If the range ends with the slide there is no step left on which
the element could be seen muted; it would behave exactly like the default, and
nothing would say so. That, too, is an error at compile time.

*On paper `after` does nothing.* A page shows every step at once, and a point
that is only quiet because the talk has moved past it has no past on a handout.
This is the rule that already holds for `"hidden"`: what falls out of its range
in the browser is printed all the same. Printing the HTML page from the browser
keeps to it too.

*Where the 65 percent comes from.* Opacity composites the ink towards the
ground, so the ground decides what dimming costs, and on a dark ground it costs
far less than on a light one. That is a measurement, not an opinion: 0.65 is
the smallest hundredth at which dimmed body text still reaches the 4.5 to 1
that this package's contrast contract (see "The contrast contract") asks of
body text, on all five bundled palettes, upright and inverted, on the paper of
the slide and on the surface of a card. The tightest of those twenty cases is
`parchment` on its own paper: 4.57 to 1 at 0.65 and 4.44 at 0.64. The most
forgiving is `mono` inverted at 8.60. Between full and dimmed there remain 1.94
to 3.23 to 1 depending on the palette and on whether the element stands on the
paper or on a card, so the step is plainly visible
everywhere.

#warning[
  The guarantee is for text in the `ink` colour, which is what a point is set
  in. What is already quiet becomes too quiet when dimmed: a line in `muted`
  measures 2.39 to 4.60 to 1 once dimmed, a word in the accent colour 1.92 to
  3.03. Dim a point, not a label.

  And opacity mixes with whatever lies behind. The promise is measured against
  the palette's `paper` and `surface`; over a `card(fill: ...)` of your own or
  over an image it is not measured and can fall well below. A card in a strong
  fill was already at 2.73 before dimming and goes to 2.07 with it.
]

A tracked element *inside* a dimmed one takes the dimming over only if it has
exactly the same range. That is the same inheritance by which `enter`, `delay`
and `duration` reach inwards: it applies where both run in lockstep, and not
otherwise. So an `anim` with a range of its own inside a dimmed `anim` stays at
full strength, measured on an inner `at: "1-"` inside an outer `at: "1"`.

What an inner element never does, on the other hand, is appear before the
thing it sits in. Its state is capped by its host's, all the way up the chain.
Without that a `morph` inside an `anim(at: "2-")` stood there at full strength
on step 1 while its own sentence was still invisible -- the sprites are
siblings in the markup, so the host cannot cover anything. Being *less* visible
than its host is still allowed; that is what its own range is for.

In practice that puts `morph`, `video`, `embed` and `flipbook` outside the
inheritance altogether: all four default to `at: "1-"`, an open range, and an
open range can never match a closed one. Inside a dimmed element they keep
full strength -- measured, an `embed` stayed at 1.00 while its host went to
0.65 -- and a formula sitting in a dimmed line stands black in a grey
sentence. Give the inner element the same closed range by hand, or do not dim
the line it sits in.

`at:` as a list keeps its usual meaning here. `at: (2, 4)` with
`after: "dimmed"` shows the element on step 2, takes it away again on step 3,
brings it back on 4 and rests it dim from 5. The gap in the middle is the list,
not the dimming.

== Several versions in the same place

`alternatives` puts versions on top of one another. Each step shows exactly
one, the next replaces it:

#show-code[```typ
#alternatives(
  $ (a + b)^2 $,
  $ a^2 + 2 a b + b^2 $,
  $ a^2 + 2 a b + b^2 = c^2 $,
)
```]

The box is as large as the largest version, so nothing around it jumps when
the content grows. `align` decides where the smaller ones sit inside it,
`start` on which step the first one appears, and `inline: true` puts the whole
thing in a line of text instead of in a block of its own.

== A drawing that grows

A CeTZ canvas and a lilaq diagram are *one* piece, not many. Typst hands out
the finished setting, and what was a line and what was a data series in it
cannot be reached from outside any more. So there is no `anim` around a single
line of a drawing.

What there is, is the drawing itself -- as often as you want it. `build` calls
it once per step and lays the versions exactly on top of one another: on stage
#box[$k$] the drawing stands as it looks after #box[$k$] steps. Exactly one of
them is on show.

Which piece joins when is said by the question every stage is handed. It is
called `ab` -- "from" -- because it says what `at:` says elsewhere:

// check: folie pre=cetz
#show-code[```typ
#build(from => cetz.canvas({
  import cetz.draw: *
  line((0,0), (4,0))                          // there from the start
  line((4,0), (4,3), stroke: from(2, black))    // from step 2
  line((4,3), (0,0), stroke: from(3, 1.4pt + red))
  content((2.2, 1.8), from(4, [$c$]))
  if from(4) { circle((4,0), radius: 0.18) }
  else { hide(circle((4,0), radius: 0.18), bounds: true) }
}), steps: 4)
```]

`from(2, black)` gives the colour back once the second piece is due, and
otherwise the same colour with alpha 0. The base line carries no number and
therefore stands there from the start. `steps: 4` says how many stages there
are; that is not guessed, because what the drawing function does with its
question nobody can see from outside. And `from(4)` with a single argument is the
same question as a boolean, for everything that cannot be recoloured -- in CeTZ
that is where `hide(…, bounds: true)` belongs.

=== Why alpha 0 and not leaving it out

Because a piece that is missing takes the room it had along with it. Measured
on a CeTZ drawing of three lines whose third reaches beyond the other two, and
on a lilaq diagram of two data series:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*How it is hidden*], [*What comes of it*]),
  [left out],
  [The room is gone. CeTZ measures 113 #sym.times 85 instead of
   198 #sym.times 170; in lilaq the `viewBox` moves from 186.58 to 189.64,
   because without the second series the axis gets different labels. That is
   exactly the jump nobody wants.],
  [`stroke: none`],
  [The measure holds, but Typst writes the path out without a single stroke
   attribute -- 933 bytes become 831. In lilaq the marks of a series thereby
   lose their geometry as well, 141 paths instead of 149.],
  [alpha 0],
  [The measure holds, the path stays whole, only its colour carries 00:
   `stroke="#00000000"`, 935 bytes against 933. In lilaq all 149 paths remain
   and the `viewBox` holds to the decimal.],
)

`ab` makes air out of a colour, out of a stroke (the brush goes, thickness and
dashing stay, because the measure hangs on those), out of the colours inside a
dictionary, and out of content, which goes into `hide`. Out of a gradient it
makes nothing: a `gradient` has no opacity to turn, and the package says so
instead of trying.

=== A lilaq diagram

A data series turns to air in two places: at its colour and at its label in the
legend. The second is easy to forget -- the entry would otherwise stand in the
legend while its curve is still missing:

// check: folie pre=lilaq
#show-code[```typ
#build(from => lq.diagram(
  width: 7cm, height: 4.5cm,
  legend: (position: top + left),
  lq.plot(x, measured, color: from(1, red), label: from(1, [measured])),
  lq.plot(x, model, color: from(2, blue), label: from(2, [model])),
), steps: 2)
```]

Because the series stays in the data as air, lilaq reckons its axes over both:
the scale is settled from the start, and the first curve does not jump when the
second arrives. Leaving the series out would bring a new tick division with it.

=== The arguments

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Effect*]),
  [`steps`], [number of stages, and hence of steps (default 2)],
  [`start`], [first step; `auto` follows on from the cursor],
  [`enter`], [motion a stage arrives with (default `"fade"`); `"draw"` is an
              error here, see the next section],
  [`duration`], [duration in milliseconds],
  [`easing`], [the curve of the motion, see "The curve"],
)

On paper only the last stage is set, in a block of the same size: a page shows
every step at once, and stacked stages would be overprint. Measured on a deck
with a CeTZ drawing and a lilaq diagram, the pages come out pixel for pixel the
same as those of a deck that simply writes the drawing down. On paper `build`
costs nothing. Under "reduce motion" nothing changes either: the stages fade,
they do not travel, and what the setting would take away is a motion that is
not there.

#info[
  Why only *one* stage is on show: because painted ink adds up. Three stages of
  the same lilaq diagram on top of one another, against that diagram set once
  -- 3.7 percent of the pixels differ by more than 8 of 255, the largest
  deviation 99. Axes, labels and the half-transparent box of the legend get
  painted three times and grow fatter by it. With stages that carry only their
  own piece it is no better: the same measurement gives 3.5 percent and a
  largest deviation of 243, because the axes belong to no piece and would then
  stand on every stage. One stage at a time is the only arrangement that yields
  the picture that would stand there if the drawing were set once.

  The price would be the crossing, since two nearly identical pictures
  relieving each other fade against one another. It is solved in both
  directions, and in both the same way: the stage that is already standing
  does not stir. Forwards the stage stepping down stays until the new one has
  fully arrived, and then goes without motion. Backwards the *smaller* stage
  comes in and lies entirely underneath the larger one that is still leaving:
  it has nothing to fade, it is simply there. What disappears is only the ink
  the larger one has over and above it.

  Measured on three stacked areas -- the motion held still, photographed frame
  by frame and the ink read off the pixels: paging back, the ink two stages
  share sank to *0.7522* and now stands at *1.0000* in both directions.
  Stacked by hand with `enter: "draw"` the dip was deeper, 0.4348, because the
  pen travelled back over ink that was already down; that is gone with it.
]

#warning[
  Every stage really is typeset. Four stages mean four layouts and four SVG
  trees in the file -- for an elaborate drawing both grow as fast as they do
  for a flip book. A drawing in twenty stages is not a good idea.
]

== A path that draws itself

`enter: "draw"` lets a stroke *come into being* instead of fading in: the pen
is set down and traces the path, from its start to its end.

// check: folie pre=zeichnung
#show-code[```typ
#anim(circuit, enter: "draw", duration: 900)
#stagger(enter: "draw", stride: 1, axes, curve, tangent)
```]

The means behind it is old and plain. A stroked path in the SVG carries its
own length; `stroke-dasharray` cuts it into one dash of exactly that length and
a gap just as long, and `stroke-dashoffset` slides the dash in. At full offset
nothing is there, at zero everything is -- and in between a pen traces the path.

`duration` applies as it does everywhere, but a drawing wants more time than a
bullet point. 900 is a workable start; the presentation's default of 520 is
tight for three long lines.

=== What can be traced and what cannot

*Text cannot.* Typst sets glyphs as filled shapes with no outline -- an "a" is
an area and not a line, and an area has no length to travel along. The same
holds for everything filled: an arrow head, a solid dot, the face of a card.

So `draw` is two things at once. *The strokes draw themselves, everything else
fades in* -- exactly as it would without `draw`, and over exactly the same
time. The label of a drawing therefore arrives while the lines are being drawn,
and stands finished together with them.

An element on which *nothing at all* can be traced fades in completely -- but
not in silence. The runtime says so in the browser's console, once per element:

#show-code[```
typstage: enter: "draw" on slide 4 (element 2) finds no stroked path to
trace. What is drawn is an outline, and text has none: Typst sets glyphs
as filled shapes. The element fades in instead. draw is for a drawing,
the fade is for text.
```]

*Why there and not at compile time.* Because Typst only hands out the SVG on
export. In the document there is no question that would answer "does this
content have an outline" -- it is the same blind spot for which this package
paints rectangles in a signal colour and has the browser report back where
things are. Only in the browser is the path there to be counted. The package's
own check run reads this message along, so that it cannot one day stop coming.

=== All at once, and how to get them one after another

Every stroked path of an element sets off *at the same time*, and there is no
knob for that. The order in the SVG is Typst's painting order and not one the
deck chose; declaring it the order of the argument would be the same
presumption this package explicitly refuses in the magic move, where glyphs are
not paired by proximity. And `duration` would stop being a number anyone can
read: seven strokes at 900 ms one after another are 6.3 seconds.

An order is therefore said rather than inherited. Each piece gets its own step:

// check: folie pre=zeichnung
#show-code[```typ
#stagger(enter: "draw", stride: 1, axes, curve, tangent)
```]

=== Where a drawing has to stand

*Not on the first step of its slide.* Entering a slide plays no entrances --
on a slide change the runtime only restores the state, or the transition and a
dozen reveals would run against each other. A drawing on step one would
therefore simply be there. It needs a step in front of it:

// check: folie pre=zeichnung
#show-code[```typ
#anim[First the sentence that announces the drawing.]
#anim(circuit, enter: "draw", duration: 900)
```]

That holds for every effect. With `draw` it merely stands out, because there
the whole point is in the travel.

=== Who delivers outlines

Measured in the emitted SVG, one element with `enter: "draw"` each:

#table(
  columns: (1fr, auto, auto, auto),
  stroke: 0.5pt + luma(180),
  align: (left, right, right, right),
  table.header([*Drawn with*], [*Paths*], [*stroked*], [*Glyphs*]),
  [cetz 0.5.2 -- three lines, a circle, a label], [11], [4], [7],
  [cetz-plot 0.1.4 -- one function with school-book axes], [59], [25], [53],
  [lilaq 0.6.0 -- two data series], [70], [64], [6],
  [fletcher 0.5.8 -- three nodes, two edges], [12], [6], [3],
  [circuiteria 0.2.1 -- two blocks, one wire], [7], [3], [2],
  [Typst's own `table` with `stroke`], [13], [7], [6],
  [`line`, `rect(stroke: …)`, `circle(stroke: …)`], [3], [3], [0],
  [text only], [14], [0], [18],
)

The rule behind it is simple: *whatever gets a `stroke` in Typst becomes a path
with an outline and can be traced; whatever gets a `fill` does not.* A drawing
package therefore delivers exactly as much as it strokes. The 14 paths of the
last row are not ink -- they are the measuring rectangles and clip paths that
the package and Typst put into every output; none of them carries an outline.

Two numbers deserve a second look. With `lilaq`, 64 of the 70 paths are stroked
-- grid, ticks, frame and markers are among them -- and all 64 set off at once.
That does not look like a drawing coming into being but like a diagram wiping
in evenly. With `cetz` there are four, and that is the case `draw` was made
for: a few long lines an eye can follow. For a diagram, the drawing that grows
in stages from the previous section is the better tool.

*Dashed lines stay with the fade.* A dash pattern lives in the very attribute
the pen needs; overwriting it would erase the dashes for the duration of the
drawing, and a dashed guide line would come in solid. So it fades in while its
solid neighbours draw themselves.

=== In both directions, and what holds at the edges

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Where], [What happens]),
  [Paging back],
  [The pen traces its way out. `enter` applies in both directions as it does
   for every effect: what drew itself undraws itself.],
  [Jumping to a step],
  [No drawing. A jump -- through the address, through the overview, on a reload
   -- restores the end state, and that is the finished drawing.],
  [`exit: "draw"`],
  [Allowed and symmetric: an element leaving its range takes its strokes back
   instead of fading away.],
  [Speaker view],
  [The preview of the next step shows the resting state, that is the finished
   drawing. There is no motion there.],
  [Paper],
  [Nothing. `enter` never reaches the PDF, the drawing simply stands there.
   Measured on this package's nine examples: the same bytes as without
   `draw`.],
  [Reduce motion],
  [The pen holds still, the fade remains. See just below.],
)

=== Under "reduce motion"

This package's rule is: *opacity stays, travel goes.* For `draw` that is not an
exception but the rule in its purest form -- the drawing *is* the travel. Take
it out and what remains is exactly the fade that was running underneath it
anyway, and the drawing appears like any other element, over the same duration.

Nothing is lost that carried the argument: a drawing coming into being says the
same as one that is already there, only more slowly. Where that is once not
true -- where the order of the strokes itself explains something -- it belongs
in words as well, and those are read by the people who never see it run.

The message about an element without an outline still comes. It is about the
deck and not about the machine it happens to be running on; whoever has the
setting turned on should get the same answer as everyone else.

=== Together with a drawing that grows in stages

Both at once does not work, and the package says so at compile time instead of
trying:

// check: folie pre=zeichnung bricht=is_at_odds_with_what_this_function_does
#show-code[```typ
#build(painter, enter: "draw")   // an error at compile time
```]

Every stage of a drawing from the previous section is the *whole* drawing. A
stage that drew itself would therefore retrace every stroke on every step,
including the ones that had long been standing. And it would do so on top of
the stage stepping down, which deliberately stays until the new one has fully
arrived -- the pen would travel over ink that is already down, and nothing
would be seen. The opposite of what `draw` promises.

Paging back it is the same futility mirrored. There the arriving stage is
simply set, underneath the one still leaving, and no pen would run at all. The
refusal is therefore not about one direction; it holds for both.

To have a drawing really come into being stroke by stroke, hand the strokes
over as pieces of their own and let each draw itself; to have a diagram grow in
stages, leave it with its fade.
== A drawing that moves

`build` lets a drawing grow: piece by piece something is added. `scene` is the
other half of the same idea. Here nothing is added -- here a *value* changes,
and the picture hangs on it.

The rule in one sentence: *the deck writes a function from a value to a picture
and says at which values the talk stops. Typst renders every stop and the
frames in between. A step pulls the picture from one stop to the next.*

// check: folie pre=szene
#show-example(
  rendered: {
    import "../src/lib.typ": *
    scene(x => box(width: 260pt, height: 64pt, {
      place(bottom + left, line(length: 100%))
      place(bottom + left, dx: 50%, line(angle: -90deg, length: 100%))
      place(horizon + left, dx: 50% + x * 8%,
            circle(radius: 7pt, fill: accent))
    }), stops: (-3, 0, 1.5, 3), tween: 8, width: 260pt, height: 64pt)
  },
  source: ```typ
  #scene(
    x => drawing-at(x),
    stops: (-3, 0, 1.5, 3),   // four stops, three steps
    tween: 8,                 // frames between two stops
  )
  ```,
  width: 13cm,
)

`stops` are the values themselves, not `0.0` to `1.0`. That is exactly the
difference to the flip book: there `t` is a fraction of a running time, here
`x` is the quantity being talked about. Whoever wants the tangent at $-3$, at
the vertex and at $1.5$ writes those three numbers down.

The scene takes `stops.len() - 1` steps. The first stop is there as soon as the
scene appears -- like a `morph` and unlike an `anim` -- and every further one
costs a keypress.

=== What belongs to a stop

A sentence beside it, a formula, a second drawing: `scene-layer` puts itself on
the step of one particular stop. So that it can find the scene again, the scene
gets a name.

// check: folie pre=szene
#show-code[```typ
#scene("derivative", x => tangent-at(f, x), stops: (-3, 0, 1.5, 3))

#scene-layer("derivative", 2)[At the vertex the slope is zero.]
#scene-layer("derivative", 4, enter: "scale")[$f'(x) = 1/2 x$]
```]

This is word for word `cue-layer`, and for the same reason: the coupling
falls out of the shared step. Move a stop and everything hanging on it moves
along, and nowhere does a number stand twice. The scene has to stand *before*
its layers in the source; standing after them, the package says so.

=== Several values at once

A stop may be a tuple, and then the drawing function takes that many arguments:

// check: folie pre=szene
#show-code[```typ
#scene(
  (a, b) => box-of(width: a, height: b),
  stops: ((1, 1), (1, 3), (2, 3)),
  tween: 6,
)
```]

First the height grows, then the width. What does not work: two values moving
*independently*. Everything travels from stop to stop together. In manim, where
this idea comes from, two `ValueTracker`s could go separate ways; here there is
one way, and a tuple puts several values on it.

=== The arguments

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Effect*]),
  [`stops`],
  [The values at which the talk stops. At least two. A number, a length, an
   angle, a ratio -- or a tuple of them.],
  [`tween`],
  [Frames *between* two stops (default 8). With `0` the scene jumps.],
  [`start`], [first step; `auto` takes the running one],
  [`width`, `height`],
  [The box the scene stands in (default `100%` and `190pt`).],
  [`duration`], [how long one pull from stop to stop takes, in milliseconds],
  [`enter`], [motion the scene itself arrives with (default `"fade"`)],
  [`still`], [what stands on paper, if not the last stop],
  [`steady`],
  [What measuring the frames is for: `auto` reports, `false` takes the scene
   out of the check, `true` insists on it. See below.],
)

`duration` is the duration of the *journey*, not of the fade the scene arrives
with -- the same separation `morph` draws with its `duration`. Putting both
under one name pulls the same motion visibly apart.

Unlike `build`, `scene` does not lay its frames on top of one another. The
stages of a `build` drawing lie exactly on top of each other, because a piece
not yet due stands there as air; the frames of a scene are drawings of
different values and may legitimately come out different sizes. So a scene
stands in a box of a fixed size and every frame is clipped to it.

They are measured all the same, and what for is in the box just below.

#warning[
  *The box stands still, the ink inside it does not do so by itself.* A CeTZ
  canvas grows with its content. If the tangent at $x = -3$ reaches further
  left than the one at $x = 3$, the canvas is wider there, and the axis cross
  sits at a different place in the box -- so paging moves the whole picture
  although only one point was meant to move. Measured on a parabola with a
  tangent, four stops and eight frames per stretch: 28 frames, *19 different
  placements* of the ink in the box.

  *Putting it right is beyond the package. Noticing it is not.* Every scene
  measures its frames, and where the sizes differ it says so with numbers,
  rather than leaving the speaker to find out in front of the class:

  #show-code(```
  error: assertion failed: typstage: 1 scene draws frames of different sizes. …
    slide 4, from step 1: 28 frames in 19 different sizes, up to 28.35pt apart across and 53.86pt down
  ```)

  Why putting it right fails, in one sentence: `measure` answers with a size
  and never with *where* the ink lies inside it -- so there is no offset to
  compute and nothing to shift. `build` can do it, because there a piece not
  yet due stands as air and keeps its room; here there is no shared piece
  whose room could be kept, and `scene` knows nothing of the drawing's
  coordinate system. Padding every frame out to the largest size would not
  help either: the box would stand still, the canvas inside it would still lie
  somewhere else each time.

  The way out lies in the drawing: give it a fixed extent and keep what moves
  inside it. In CeTZ that is a `rect` with a transparent stroke -- the same air
  `ab` works with:

  // check: folie pre=cetz
  ```typ
  #scene(x => cetz.canvas({
    import cetz.draw: *
    // Holds the canvas open, wherever the point stands.
    rect((-4.4, -0.8), (4.4, 4.6), stroke: rgb(0, 0, 0, 0))
    line((-4, 0), (4, 0))
    circle((x, 0.25 * x * x), radius: 0.1)
  }), stops: (-3, 0, 3), height: 160pt)
  ```

  That pins the width. Whatever still reaches beyond it -- a tangent running
  off the edge, say -- has to be cut off, or it pulls the canvas open again:
  the same scene with a frame and a cut-off tangent came to 7 placements
  instead of 19, and its width stood still to the point.

  *Where the frames are meant to differ*, say so: `steady: false`. A rectangle
  that grows, a number that counts up -- there the difference is the subject
  itself, and the scene is not measured at all. The other way round,
  `steady: true` insists that it stands still and stops on the spot rather
  than at the end of the deck. What happens with the findings is decided by
  `drift` on the presentation; see "drift".
]

To commit to it, write `steady: true`. The scene then stops on the spot rather
than standing in a list at the end of the deck:

// check: folie pre=cetz bricht=this_scene_draws_its
#show-code[```typ
#scene(x => cetz.canvas({
  import cetz.draw: *
  line((0, 0), (x, 0.25 * x * x))             // pulls the canvas along
}), stops: (-3, 3), steady: true)             // error at compile time
```]

On paper the last stop is set, as with `alternatives` -- a page shows every
step at once, and that is the state in which the scene leaves the slide.
`still` puts something else in its place. The step cursor still runs there, so
`info().step.total` names the same number in both outputs.

Under "reduce motion" the frames in between fall away and the scene jumps from
stop to stop. That is the package's rule everywhere else too: what stays is the
destination, what goes is the travel.

=== What a scene costs

Every frame really is a Typst layout and sits in the file as an SVG tree of its
own. The raw number alone gives a false picture of that, so both stand here.

Measured on a CeTZ drawing that would really carry a slide: axes with ticks, a
parabola from 61 sample points, a tangent, a dashed slope triangle, two labels.
Typst 0.15.1, cetz 0.4.2.

#table(
  columns: (auto, auto, auto, auto),
  align: (left, right, right, right),
  stroke: 0.5pt + luma(180),
  table.header([*Frames*], [*Compile*], [*HTML raw*], [*HTML gzip*]),
  [2], [0.35 s], [238,559 B], [70,275 B],
  [6], [0.26 s], [302,054 B], [71,591 B],
  [12], [0.30 s], [397,320 B], [73,427 B],
  [24], [0.39 s], [587,817 B], [76,949 B],
  [48], [0.58 s], [968,815 B], [84,032 B],
  [96], [0.98 s], [1,730,833 B], [97,175 B],
)

Per additional frame: *15.9 kB raw, 286 B gzipped, 8.1 ms of compilation.* The
time is read off the slope between 12 and 96 frames; the first rows of the
table carry the compiler's start-up and say little on their own.

Over the wire that is about a fiftieth of what the raw number leads one to
fear. The SVG trees of a scene are so alike that gzip takes 98 percent of them
away. A scene of four stops and eight frames per stretch -- 28 frames in all --
costs, against the same drawing written down once: 436 kB raw, *9 kB gzipped*,
0.21 s of compilation. On paper it costs nothing: a single still image stands
there.

#warning[
  The gzipped number is the honest one, but it only holds as long as the web
  server does gzip. Whoever hands the file on by USB stick or as an attachment
  carries the raw one. And the compilation time is always the full one: eight
  frames per stretch are eight layouts, whether they compress away later or
  not.
]

*And what the measuring costs.* It is one more layout per frame, and a frame is
a whole layout, so the bill doubles -- for the frames only, and only in the
browser branch. Measured on the same scene of 28 frames, fifteen runs, fastest
time: *434 ms without, 536 ms with* -- about 100 ms for the scene, 3.6 ms per
frame. `steady: false` gives it back for one scene, `drift: "none"` for all of
them.

Why the check is on where `overflow` is not: only decks that use `scene` pay
for it, while `overflow` measures every body of every deck and costs 1.2 to 1.5
times the whole compilation. And what it finds is invisible while writing --
every frame on its own looks right, and only paging shows the drawing
travelling.

#info[
  Where the idea comes from: `scene` is manim's `ValueTracker` together with
  `always_redraw`, translated into the step model of a talk -- and the
  translation turns it around. There a number changes while the film runs, and
  everything depending on it is redrawn per frame. Here Typst draws at compile
  time, and a number can only change at a step. So the frames are set
  beforehand and the keypress travels over them.

  What is gained: the picture is a Typst drawing, with everything Typst can do,
  equations included, and it stays sharp at any size. What is lost: the frames
  in between are counted and sit in the file, and several values cannot move
  independently.
]

#info[
  *And `.animate`?* In manim, `obj.animate.shift(RIGHT)` turns a method call
  into an animation: you write the change rather than the target state. There
  is deliberately no word of its own for that here, and the reason is not
  convenience but what would be left of it.

  Typst content is immutable. There is no object for a method to move --
  `move(dx: 40pt, card)` is not the same card in another place but a new piece
  of content. A typstage version of `.animate` could therefore only do what a
  browser can do to a *finished* picture: translate, scale, rotate, fade.
  Everything else manim offers under that spelling -- `set_color`,
  `set_value`, `become`, `next_to` -- means setting it again, and setting it
  again is `scene`.

  That leaves the argument that eight frames fewer are eight frames fewer. It
  has been measured, and it does not hold. The same motion -- a card travels
  right and grows while doing so -- costs *2.6 kB compressed* as a `scene`
  with eight tween frames, over a slide that merely puts the same card there.
  Written across two slides with `morph`, that is, the way a deck would take
  for the same gesture today, it costs *12.0 kB*: the second slide carries
  title, furniture and everything else a second time. The way the package
  already has is the cheaper of the two.
]

== Moving in on a detail

Sometimes the next step of a talk is not a new sentence but the same sentence
from close up: the one cell of the table, the one term of the equation, the one
component in the circuit. `camera` moves in on it and back out again.

The camera aims at a `pin`, and at nothing else. That is the word this package
already has for a named piece of a slide, and its rectangle is exactly what the
runtime measures on every step anyway.

// check: folie
#show-code[```typ
#pin(<sensor>, card(title: [Sensor])[Thermocouple, bridge, amplifier.])

#camera(<sensor>)
#anim[And out again, on the step after.]
```]

That this works at all has a reason worth a line. Typst hands out no geometry
at compile time -- `here().position()` gives $(0, 0)$ everywhere in the HTML
output, and that is precisely why this package works with rectangles in signal
colour. In the browser it is the other way round: there those rectangles *have*
to be known, or not a single sprite would find its place. The camera hangs
itself on that. The deck names a name, not a coordinate, and whoever rearranges
the slide has nothing to recompute.

=== How you get out again

Said, not guessed. `at` is a step selector as everywhere else, and the slide is
seen through the camera for exactly as long as it is active:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Written*], [*What happens*]),
  [`at: auto`],
  [The next free step, and the one after takes it back out. The default.],
  [`at: "3"`],
  [In on step three, out on four.],
  [`at: "3-5"`],
  [The crop holds across three steps.],
  [`at: 3`],
  [In on step three and stay; the slide change takes it out.],
)

The way back out is a step and is counted as one. A slide carrying nothing but
a pin and a camera on it has three steps: the whole slide, the crop, the whole
slide. `info().step.total` says the same number, and the handout counts the
same way.

#info[
  `at: auto` is a *closed* range here, while for `anim` it is an open one. The
  difference is deliberate. An entrance has no natural end -- what has appeared
  stays. A camera move has one: you always come back out. And never step one:
  step one is the slide as it is entered, and a move there would mean nobody
  ever saw the slide whole.
]

=== What travels along and what stays put

What travels is the slide -- its background and the layer of revealed parts
above it, both together and with the same transform. The slide's furniture does
*not* travel: footer, page number, progress and running header have always sat
as their own layer above the stage, so that they do not travel out on a slide
change. That is exactly what pays off here. They stand still while the slide
grows underneath them, and stay legible.

The slide's title does travel along. It stands in the body and belongs to it.

Whatever travels out of frame is cut at the edge of the stage and not painted
beside it -- the same edge that clips an overflowing slide. The ink stays put
too, where it was drawn: what someone draws onto the slide does not belong to
the slide.

=== How far it goes

`margin` says how much of the slide stays around the detail, measured on the
*unzoomed* slide. The camera fits the detail plus that margin into the frame;
the tighter of the two directions decides, so the whole of it is seen and not
its middle.

// check: folie
#show-code[```typ
#pin(<term>, $b^2$)
#camera(<term>, margin: 4pt, duration: 900, easing: "out-quad")
#anim[After that.]
```]

There is no upper limit. A pin the size of a comma is shown the size of a wall
-- what Typst set stays sharp while it happens, because it stands there as
vectors. A video, an image or an embedded document in that crop will not.

A detail already as large as the slide gives nothing to travel to; then the
slide stays whole.

=== Two special cases

*Two pins of the same name on one slide.* The camera frames both, that is, the
box around them. It is the same case in which a glyph visibly splits in two
under a `morph`, and here it is the answer to "show me these two".

*Two moves overlapping on one step.* The later one in the source wins. A rule
you can look up beats two cameras quietly fighting each other.

=== On a jump, paging back, and on paper

The crop is a function of the step and nothing else. Everything else follows
from that on its own:

- *Paging back* runs the way in reverse and lands cleanly on the whole slide
  again.
- *A jump* -- through the overview, through `#3` in the address, through a
  click in the speaker view -- sets the crop instead of travelling to it.
  There is no way there that anyone saw.
- *The speaker view* shows the running slide as what it is: that is this
  window's real stage, camera included. And the preview beside it carries the
  crop along, because its question is not "what does the slide look like" but
  "what stands there after the next keypress".
- Under *reduced motion* the camera jumps to the crop instead of travelling to
  it. The package's rule everywhere else too: what stays is the destination,
  what goes is the travel.

#warning[
  *On paper there is no camera.* The handout sets every slide whole, exactly as
  it would without a move -- and that is the only right answer: a page shows
  every step at once, and a crop on it would be a page with half of it
  missing. The browser's print view (key `p`) puts every slide back whole too.

  A duty for the deck follows from that: *the slide has to be complete and
  legible without the move.* Whoever labels the detail only for the crop -- a
  6-point line, since we are going to move in on it anyway -- has a line on
  paper that nobody reads. The camera is an emphasis, not a layout.
]

=== When the name is not there

A camera aiming at a `pin` that does not exist on its slide is an error at
compile time, and not a silent standstill:

// check: folie bricht=finds_no_pin_of_that_name
#show-code[```typ
#pin(<sensor>, card[…])
#camera(<senor>)            // one letter short
```]

The question is put at the end of the document rather than on the spot: a move
may stand before its target -- it often belongs at the head of the slide -- and
what stands on a slide is only settled once the slide is set. A pin on the
slide *before* does not count; that is a different piece of paper.

One thing stays open, and it has to. A pin sitting inside an `anim` that is not
revealed on this step does have a rectangle, but nothing visible in it. The
camera then moves in on an empty place. Nobody can see that at compile time --
which step shows what is decided in the browser -- and it is the one way to
make a camera pointless without the package saying anything.

#info[
  Where the idea comes from: manim's `MovingCameraScene` moves the scene's
  camera, and `camera.frame.animate` takes it to a crop. The difference is what
  is aimed at. There it is a point in a coordinate system the scene spanned
  itself; here it is a piece of set text that only gets its position in the
  browser -- and therefore a name and not a number.
]

== Three stumbling blocks

*Only reveals count.* The cursor counts `anim`, `stagger`, `alternatives` and
`#pause`, that is, everything that makes something appear. An applet, a video
or a `morph` uses up *no* step and pushes nothing along. Such elements are
there from the beginning. In a two-column slide that is decisive, because the
bullets beside an applet should start at one and not behind its motions:

#show-code[```typ
#side-by-side(
  embed(url: "…", width: 100%, height: 220pt),   // no step
  stagger[
    - first bullet                               // step 1
    - second bullet                              // step 2
  ],
)
```]

*A step is not inherited inwards.* Every tracked element carries its own step.
Where one sits inside another, the inner one still follows its own:

#show-code[```typ
#anim(at: 3)[From step three, #morph(<m>, $x^2$) but from step one.]
```]

With `morph` that is right: the *target* of a flight has to be standing when
the slide is entered, or the flight from the previous slide would arrive
nowhere. With an `anim` inside an `anim` it is usually an oversight, and it is
only noticed while paging, when the outer element is still invisible and the
inner one already stands.

*A morph stands from the first step.* That is the default and it is usually
right. It follows that a morph does not belong inside something that only
appears later. Put it in a tile that arrives on step two and it hovers alone on
step one, at the place where its container will only later turn up.

= Showing instead of claiming

The aim of this chapter: a slide that demonstrates something rather than
asserting it. Three ways in, from the most involved to the simplest.

== A document of your own on the slide

`embed` puts arbitrary HTML into a sandboxed frame:

#show-code[```typ
#embed(html: "<div id=lamp></div><script>…</script>",
       width: 100%, height: 190pt)
```]

`url:` takes a foreign address instead. Both spellings put a frame on the
slide; the difference is what may be reached later.

#tip[
  Everything inside in `em`. `embed` puts the deck's basic style in front of
  the document, and inside a zoomed frame one CSS pixel is exactly one point of
  the slide. So the content grows with the slides. Written as `78px` it would
  stay the size it has on a laptop even on a projector, which measured against
  the slide is about a third as wide. A page that reflows on its own wants
  `zoom: false` instead, and then it spans real screen pixels.
]

`style: false` leaves out the basic style where the embedded document brings
its own. `fallback` is what stands on paper in its place, and `link` is the
address printed beneath it, so whoever holds the handout can still get there.

== Sending it something on a step

A frame with a `bridge:` has a name, and `bridge-job` sends it a dictionary
when a step arrives:

#show-code[```typ
#embed(html: "…", bridge: "lamp", width: 100%, height: 190pt)

#bridge-job("lamp", (color: "#16a34a"), at: 2)
#bridge-job("lamp", (color: "#eb5e28"), at: 3)
```]

The package never reads what is in the job. What it means is known only to the
document on the other side. That is exactly how the `ggb-` commands drive their
applets — see the chapter *GeoGebra*.

#warning[
  Three things about the bridge, and each of them has cost somebody an hour.

  The document has to announce itself once with
  `postMessage({typstage: 1, ready: 1})`. Until it does, the runtime treats the
  frame as not yet alive and sends it nothing.

  Paging back replays the whole run with a `reset`, so a job has to be
  repeatable. "Set the colour to green" survives that, "make it greener" does
  not.

  `bridge-targets()` reports the names on the current slide. Two frames sharing
  a name both receive every job, and the runtime says so in the console rather
  than guessing.
]

== Video

// check: folie dateien=still.png
#show-code[```typ
#video("clip.mp4", width: 100%, height: 260pt, poster: image("still.png"))
```]

The file travels beside the HTML, it is not embedded. `autoplay`, `loop`,
`muted` and `controls` are the usual switches; `poster` is what stands there
before it runs and what the PDF shows in its place.

#info[
  The frame crops rather than stretches, which is what the poster does on paper
  as well. Measured on the example clip, a video without that setting came out
  12 % too wide.
]

== A flip book

`flipbook` lets Typst render the motion itself, frame by frame:

#show-code[```typ
#flipbook(
  t => box(width: 100%, height: 100%,
    place(left + horizon, dx: t * 88%, circle(radius: 9pt, fill: accent))),
  frames: 24, fps: 20, width: 100%, height: 46pt,
)
```]

The function receives `t` running from 0 to 1 and is called once per frame, and
it may draw with anything Typst has, CeTZ and Fletcher included. Every frame
sits in the file as SVG and stays sharp at any size. That makes it the tool for
motion that Typst can draw and CSS cannot: a curve being traced, a mechanism
turning, a diagram assembling itself.

`loop`, `pingpong` and `still` decide how it plays and which frame stands on
paper. If the viewer has turned on "reduce motion" in their operating system,
it never starts playing at all; see "Less motion".

The clock starts when the flip book becomes visible, not when its slide comes
up. A `flipbook(at: "3-", loop: false)` lies still on frame 0 for the first two
steps and starts from zero when it is revealed; page back and reveal it again,
and it plays again from the beginning.

#warning[
  Every frame is really typeset. Twenty-four frames are twenty-four layouts and
  twenty-four SVG trees in the file. That is the most expensive element in this
  package, in compile time and in file size alike, and it is worth reaching for
  only where the motion carries the argument.
]

= GeoGebra

The aim of this chapter: a construction that follows the steps of the slide.
GeoGebra builds the construction, the slides supply the dramaturgy. Jobs can
sit on every step. Set values, show or hide objects, change colours, move the
viewport, start a motion.

This was a package of its own once, `typstage-geogebra`, and the plan of that
day has stayed: everything here rests on the same two public parts any foreign
companion package uses — `embed(bridge: …)` registers a frame as a target, and
`bridge-job` sends it something on a step. What is in the jobs is never read.
A deck without an applet pays nothing for this: the boot script and the applet
document come into being only where `geogebra()` is called, and a deck without
that call is the same size, to the byte, as before.

#warning[
  A typeset applet loads from `geogebra.org` at run time and therefore stands
  under GeoGebra's terms — see "Whose applet this is" at the end of this
  chapter.
]

== Quick start

An applet stands on the slide with `geogebra()`, and the commands stand in the
same slide body, because that is where they are collected. They produce no
output themselves.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#presentation(
  slide([Remote controlled], {
    geogebra(app: "classic", perspective: "G", height: 240pt,
             link: "https://www.geogebra.org/calculator")
    ggb-run("a=1", "f(x)=a*x^2")
    ggb-set((a: 3), at: 2)
  }),
)
```]

The parabola is there from the beginning; on step 2 `a` is set to 3 and it
draws itself together.

`at` is a step selector on every command, as it is on `anim`: `2` means "from
step two on", and `"1-2"`, `"2,4"` and `"-2"` mean what they say. The default
is `"1-"`, since most jobs set the construction up as the slide is entered. The
applet frame itself uses no step and pushes nothing along: the bullets beside it
belong on step one, not behind its jobs.

#info[
  The applet lives in the HTML export only. In the PDF, what stands in its
  place is described in the chapter _On paper_.
]

== Which applet is meant

In the quick start no command carries a name. With one applet on the slide
there is nothing to choose between, and the commands find it by themselves,
whether they stand above or below it in the source.

Two applets on one slide need names, and then the commands need `target`. The
name may be a string or a label, and Typst colours it as what it is:

#show-code[```typ
#geogebra(<left>, height: 200pt)
#geogebra(<right>, height: 200pt)
#ggb-run("A=(0,0)", target: <left>)
#ggb-run("B=(1,1)", target: "right")
```]

Where the argument is missing and there is more than one applet, nothing is
guessed. The build stops and names what it found:

#show-code[```
error: panicked with: typstage: 2 applets on this slide
(left, right) — say which one is meant, e.g. target: "left".
```]

The same holds where the slide carries no applet at all. A command dropped in
silence is far harder to notice than a failed build.

== Building the construction

`ggb-run` takes any number of GeoGebra commands and hands them to `evalCommand`
one at a time. The order counts: whatever is needed has to exist first.

// check: folie drin=applet
#show-code[```typ
#ggb-run(at: "1-",
         "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
         "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
```]

#warning[
  GeoGebra's scripting commands, `SetColor`, `SetValue`, `SetVisibleInView` and
  their relatives, are *not* accepted by `evalCommand`; inside `ggb-run` they
  would come to nothing. That is what `ggb-set`, `ggb-style`, `ggb-show` and
  `ggb-hide` are for: they reach for the JavaScript interface, which can do it.
]

What GeoGebra refuses does not vanish quietly: the applet reports the rejected
commands back, and the runtime writes them into the browser's console.

On entering a slide and on paging back, the run is repeated from its beginning,
and the applet returns to its initial state for that. Commands should therefore
be repeatable. For the same reason it is worth fixing the colour on `"1-"`
straight away: on a rebuild GeoGebra would otherwise hand out the next colour
of its palette, and the slide would look different after paging back.

// check: folie drin=applet
#show-code[```typ
#ggb-run("a=1", "f(x)=a*x^2", at: "1-")
#ggb-style("f", at: "1-", color: dark, thickness: 3)
```]

#info[
  A `.ggb` file cannot be embedded: Typst has no base64 encoding, and without
  it the file's content never reaches the HTML. The construction is therefore
  built with `ggb-run`, or it is loaded from GeoGebra through `material`:
  `geogebra(material: "abc123xy")`.
]

== Values, appearance, viewport

`ggb-set` takes a dictionary of object name and value, `ggb-show` and `ggb-hide`
any number of object names. The usual way is to build everything up at the
start and only make it visible when its turn comes:

// check: folie drin=applet
#show-code[```typ
#ggb-hide("P", "s", "t", at: "1-")
#ggb-show("P", "s", at: 2)
#ggb-set((a: 3), at: 2)
#ggb-set((a: -2, b: 0.5), at: 3)
```]

=== Appearance

`ggb-style` takes the object names and, with them, what should change. Every
setting is available on its own; what is not named stays as it is.

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.4pt + luma(75%),
  table.header([*Setting*], [*Effect*]),
  [`color`], [colour, as a Typst colour and not a GeoGebra one],
  [`thickness`], [line weight],
  [`line-style`], [line style as a number (solid, dashed, dotted …)],
  [`filling`], [fill, 0 to 1],
  [`point-size`], [point size],
  [`trace`], [trace on or off],
  [`label`], [label visible or not],
  [`label-mode`], [kind of label as a number (name, value, caption …)],
  [`fixed`], [held against being moved],
  [`caption`], [a caption of your own],
  [`layer`], [layer, that is, what lies in front of what],
  [`position`], [place as `(x, y)`],
)

That `color` takes a Typst colour is the point of it: the construction carries
the colours of the slides instead of GeoGebra's palette.

// check: folie drin=applet
#show-code[```typ
#ggb-style("P", at: 2, color: accent, point-size: 6)
#ggb-style("s", at: 2, color: dark, thickness: 3)
#ggb-style("d", at: 3, color: accent, filling: 0.18, thickness: 4)
```]

#warning[
  `position` counts in the coordinates of the plane for most objects, but in
  pixels of the applet for a slider made with the `Slider` command, because
  such a slider sits at an absolute place on the screen. Measured: written as
  `(-3.9, 2.2)` two sliders both landed in the same corner on top of one
  another.
]

=== Viewport

`ggb-view` sets the visible range as well as the grid and the axes. `x` and `y`
only take effect together, both being pairs of smallest and largest value.

// check: folie drin=applet
#show-code[```typ
#ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
#ggb-view(at: 3, axes: false)
```]

#warning[
  `ggb-view` sets the x range and the y range separately, so a range that does
  not match the shape of the box stretches one axis. A circle becomes an
  ellipse and a right angle stops looking like one. Where the geometry carries
  the argument, give the box a fixed size and match the ranges to it: 424 by
  262 is 1.618 to one, and so is 8.4 by 5.2.
]

The applet takes the size of the box it stands in and keeps it across step
changes and window sizes. How much of the plane is on screen therefore follows
from `width` and `height` on the `geogebra` line: a wide box shows more x
range. Where a particular range matters, say it with `ggb-view` rather than
letting the box width decide it.

== Motion

There are two ways to set something moving, and they do different things.

`ggb-animate` starts GeoGebra's own animation. It runs back and forth without
end until the slide is left, which is right for a point going round a circle or
a slider demonstrating a relationship. `trace` switches on the trace of the
named objects, `speed` sets the pace, `playing: false` stops it.

// check: folie drin=applet
#show-code[```typ
#ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
```]

`ggb-tween` goes once from A to B and stays there. The browser counts the value
up frame by frame; an object that depends on it grows with it, a segment whose
endpoint travels, an arc whose angle follows. That is how a construction draws
itself. `from` gives the starting value where it should not be the one
currently in force, `duration` the time in milliseconds, `easing` the shape of
it (`"ease-in-out"` or `"linear"`).

// check: folie drin=applet
#show-code[```typ
#ggb-run("t_1=0", "s=Segment(A,(4*t_1,0))", at: "1-")
#ggb-tween("t_1", at: 2, to: 1, duration: 700)
```]

#warning[
  `ggb-tween` needs a step number, not a range: `at: 2`, not `at: "2-"`.
  Otherwise the build stops with "`ggb-tween() needs a step number`".

  And a tween on step 1 would never arrive as a motion. On entering a slide the
  runtime replays the run up to the current step at once, and tweens are set to
  their target value rather than played. Step 1 is for building up; drawing
  starts at step 2.
]

From the step after the tween the value sits on its target anyway. Whoever
pages back therefore sees the finished drawing and not the motion a second
time.

== On paper

In the PDF there is no applet. Without further arguments a labelled placeholder
stays in the size of the frame; `link` puts the way to the live applet beneath
it, clickable in the PDF.

#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  },
  source: ```typ
  #geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  ```,
  width: 12cm,
)

Better is a drawing of your own in its place. `fallback` takes any content, an
image, a table, and above all a drawing with CeTZ:

// check: folie pre=cetz
#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    import "../src/lib.typ": dark
    import "@preview/cetz:0.5.2"
    geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
      fallback: cetz.canvas(length: 0.8cm, {
        import cetz.draw: *
        line((-2.6, 0), (2.6, 0), stroke: luma(70%))
        line((0, -0.4), (0, 2.6), stroke: luma(70%))
        line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
             stroke: dark + 1.6pt)
      }))
  },
  source: ```typ
  #geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
    fallback: cetz.canvas(length: 0.8cm, {
      import cetz.draw: *
      line((-2.6, 0), (2.6, 0), stroke: luma(70%))
      line((0, -0.4), (0, 2.6), stroke: luma(70%))
      line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
           stroke: dark + 1.6pt)
    }))
  ```,
  width: 12cm,
)

#tip[
  Paper can show a sequence where a screen can only show one moment. Where the
  applet runs through several states, the better stand-in is often the whole
  run as a small table or a row of pictures, rather than a photograph of one
  step of it.
]

Both settings take effect in the PDF only; in the browser the applet itself
stands there.

== How the applet looks

The default is `seamless: true`: the applet carries no frame of its own, and
its drawing area takes the colour of the slide. It then no longer looks like a
window inside a window but like part of the slide. `background` sets that
colour; `auto` takes the presentation's paper white, which is worth changing on
a tinted slide.

#show-code[```typ
#geogebra(height: 240pt, background: rgb("#f4f1ea"))
#geogebra(height: 240pt, seamless: false)   // with GeoGebra's own frame
```]

#tip[
  `background: auto` takes the package's paper white and not the theme's. On a
  theme whose paper is pure white, an applet left to `auto` therefore sits as a
  faintly grey box. `background: themes.lesson.paper` is the way to say it.
]

#warning[
  The viewport cannot be dragged by hand, and that is the default. Whoever
  reaches beside the point during a talk would otherwise push the whole plane
  away and the construction would be gone. Reported from use, not invented.
  `pan: true` gives dragging and zooming back where they belong to the matter;
  points and sliders can be dragged either way.
]

`font-size` is the applet's type, counted in points of the slide, the way
`width` and `height` are. It therefore grows with the slide instead of staying
at its physical size on a projector.

The default is 20 rather than GeoGebra's 16. Measured on rendered pictures, the
axis numbers are then 0.71 as tall as the slide's body text; at 16 they are
0.62. The first reads as a subordinate label, the second as an afterthought.

#warning[
  GeoGebra snaps the size to steps. Measured, it jumps between 20 and 21: the
  axis numbers go from 0.71 to 1.12 of the body text and are then as large as
  it is. Setting a value in between therefore need not give you a step in
  between.
]

#show-code[```typ
#geogebra(height: 240pt, font-size: 22)      // larger axis numbers
#geogebra(height: 240pt, pan: true)          // viewport by hand
```]

`grid` and `axes` leave GeoGebra's own default alone as long as they are
`auto`, and force one or the other otherwise. `perspective: "G"` shows the
graphics view alone, `app` chooses the GeoGebra app (the default is
`"classic"`), `language` the language of the interface, and `animation-button`
shows GeoGebra's play button.

#info[
  The applet is loaded from `codebase`, from `geogebra.org` as it ships.
  Without a network the frame stays empty; whoever presents offline puts
  GeoGebra's files beside the deck and points `codebase` at them.
]

=== Size

`width` and `height` give the size in the measurements of the slide, not in
screen pixels.

For most embeds the runtime spans the frame in points of the slide and then
enlarges it with `zoom`. An applet is exempt and gets real screen pixels
instead. The reason is measured: Safari counts that zoom twice for GeoGebra, a
canvas buffer of 1400 points at a width of 253, which is zoom times zoom times
pixel density. The applet drew too small, and correcting its size instead
moved the place where it could be hit: it then drew correctly but believed
itself 704 points wide while being shown 424 wide, and a point could only be
grabbed by clicking far to the right of it.

That every window still shows the same crop therefore does not hang on the
pixel count but on the range. The applet sets that from the box in slide
points the first time, at GeoGebra's 50 points per unit; after that `ggb-view`
decides, and a change of size leaves the range where it is.

The applet takes its pixel size from the frame, not from a number written at
compile time. `width: 100%` cannot be a number before the slide has been laid
out, and an applet that guessed one drew a third of the box it sat in.

#tip[
  Two applets side by side sit best in a `grid`, each with `width: 100%` and a
  height of its own.
]

== From the speaker view

The speaker window of `typstage` runs a copy of every applet of its own. `m`
switches its pointer from the pen to the embedded frame, and from then on the
applet in front of you is the live one: drag a point, push a slider, pan the
view, and the copy on the canvas follows.

What crosses is what a hand can move: a point as its coordinates, a slider as
its value. Whatever follows from those is left alone, because the other copy
works it out for itself. Creating, deleting or renaming sends the whole
construction instead, and panning and zooming travel too.

#tip[
  Measured: a point on a half circle reported four states per frame while being
  dragged, the point, both segments and the angle. The three dependent ones are
  not merely redundant. Their XML redefines them on the other side, and that
  wipes away the trace the dragged point had just left behind.
]

Only what a hand has touched is reported. An animation that runs on both sides
anyway therefore sends nothing.

#warning[
  A step change resets both copies from the base as before and replays the jobs
  of the slide. A change made by hand lives as long as the step does. Where a
  position is meant to stay, it belongs in the deck with `ggb-set`.
]

=== The keyboard

Click the applet and it holds the focus, and from then on every key lands
inside it. What the core does about that stands under "A frame that has the
focus" — in short: the keys the talk uses are handed back out of the frame,
everything else stays with the applet. Measured, this applet has no use for the
keyboard anyway: without a toolbar and without an algebra input, no key changes
anything in the construction.

#info[
  Should that ever change, with a toolbar shown for instance, a change made
  with the keyboard travels along: the window in which mirroring is awake opens
  on a key as it does on a press.
]

#tip[
  Whatever is not meant to move belongs pinned down. `ggb-style("A", "B",
  fixed: true)` nails the points that merely span a construction. Otherwise a
  hand in the talk easily takes the wrong one: with Thales, the diameter
  instead of the point on the half circle, and the whole arc travels with it.
  Measured on the example deck: with `fixed`, neither a pull at A nor one at
  the arc moves anything, and C goes on running along its path.
]

When building for this, one distinction pays. `Point(k)` is a point on the path
that a hand can take; `Point(k, 0.3)` is pinned to that parameter and cannot be
dragged at all, and `isMoveable` answers false for it. Where it should start is
said with `position:`.

`examples/geogebra-sprecher.typ` is a deck built around exactly this: Thales with a point
that walks along the half circle and leaves its trace, and a parabola with two
sliders.

== Whose applet this is

This package does not ship GeoGebra. It puts a frame on the slide, and what
runs inside it the browser fetches when it shows the page, from `codebase`,
`https://www.geogebra.org/apps/` by default.

Three things follow, and they are worth knowing before the talk:

+ *Without a network the frame stays empty.* Whoever presents offline puts
  GeoGebra's files beside the deck and points `codebase` at them.
+ *The applet stands under GeoGebra's terms*, not under this package's MIT
  licence. That one covers the Typst and runtime code here; GeoGebra carries
  its own licence and terms of use, and for commercial use they are the ones
  to read.
+ *The viewer's browser talks to `geogebra.org`.* Where that is unwanted — a
  class without a network, a talk behind a firewall, a data protection
  requirement — `codebase` is the place to send it elsewhere.

#info[
  On paper none of this is left: the PDF fetches nothing and shows what "On
  paper" describes.
]

= Developing a calculation

The aim of this chapter: an equation that rewrites itself in front of the room
instead of being replaced by the next one.

== One name, two slides

The same name on two slides, and the thing flies across:

#show-code[```typ
== Step 1
#morph(<term>, $ (a + b)^2 $)

== Step 2
#morph(<term>, $ a^2 + 2 a b + b^2 $)
```]

The name is a string or a label. Nothing else is needed: the runtime finds both
ends, pairs the glyphs, and moves each one from where it was to where it now
belongs.

== How the pairing works

`match: "auto"` compares the outlines. Two glyphs of the same shape find each
other, and where that is not enough, proximity decides. `"glyph"` forces it
per glyph, `"block"` moves the whole thing as one rectangle.

#tip[
  `"block"` is the right answer more often than it looks. A whole picture or a
  table has no glyphs worth pairing, and per-glyph matching there produces a
  swarm rather than a movement.
]

== When the wrong signs fly

Where the pairing goes astray, name the pieces. `pin` marks a piece inside a
morph, and matching names find each other before the shape is consulted:

#show-code[```typ
#morph(<term>)[$#pin(<factor>)[3] x^#pin(<power>)[4]$]
// and on the next slide
#morph(<term>)[$#pin(<power>)[4] dot #pin(<factor>)[3] x^3$]
```]

A pin without a counterpart on the other slide falls back to shape matching
without complaint, so pinning one troublesome pair costs nothing elsewhere.

== Duration and the first link

`duration` is 900 ms rather than the presentation's, because a flight across
the slide takes longer than a fade-in. `auto` falls back to the presentation's
value.

A morph is present from the first step, and that holds at both ends of a chain,
because paging back swaps the roles. The one exception is the *first* link:
there no flight arrives, so it may be delayed. The package checks at compile
time that the preceding slide really carries no morph of that name, and says so
when it does.

== Where the magic move stops

Two names may be equal on the *target* slide. The runtime looks the source up
by name but iterates over the targets, so two targets sharing a name both start
from the same place and the glyph visibly splits in two. That is occasionally
what you want and more often a surprise.

#warning[
  A morph carries its own typesetting. A tracked element is typeset a second
  time, in a frame of its own, and that frame never sees a `#set` rule written
  in the document. Shared typography belongs in `style:` on `presentation`,
  which reaches both. This is the single most common reason for a flying
  equation that suddenly has the wrong font.
]

== How the slide itself changes

`transition` decides how a slide comes in. The presentation sets the default
for all of them, and a single slide may differ:

#show-code[```typ
#show: presentation.with(transition: "slide", transition-duration: 420)

== This one differently
#transition("cover", from: "bottom")

// or, in the argument form:
#slide([This one differently], transition: (kind: "cover", from: "bottom"))[…]
```]

#table(
  columns: (auto, auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Kind], [Takes], [What happens]),
  [`"none"`], [--], [A hard cut.],
  [`"fade"`], [--], [A cross-fade, nothing moves.],
  [`"slide"`], [`from`],
  [The new slide moves in a short way and fades up while doing it, the old one
   gives way in the other direction.],
  [`"push"`], [`from`], [The new one pushes the old one over the edge.],
  [`"cover"`], [`from`], [The new one lays itself over the old one, which stays.],
  [`"uncover"`], [`from`], [The old one moves away and frees the new one.],
  [`"zoom"`], [`direction`],
  [`"in"` grows the new one forward, `"out"` steps the old one back.],
  [`"blur"`], [--], [Out of focus and back.],
  [`"iris"`], [`direction`],
  [A round aperture: `"open"` opens the new slide, `"close"` closes over the old.],
  [`"wipe"`], [`direction`, `from`],
  [The same as a straight edge; `from` names the edge it starts at.],
  [`"flip"`], [`axis`], [Turning over in space, like a leaf.],
  [`"cube"`], [`axis`],
  [Like `flip`, but as two faces of a cube that keeps turning.],
)

`from` is `"right"` (the default), `"left"`, `"top"` or `"bottom"`. `direction`
is `"in"`/`"out"` for `"zoom"` and `"open"`/`"close"` for `"iris"` and
`"wipe"`, the first value being the default in each case. `axis` is `"y"` (the
default, turning about the vertical) or `"x"`.

Three things about transitions are less obvious than they look.

*The transition belongs to the boundary between two slides, not to the
direction of travel.* What counts is always the setting of the later of the
two, the one that comes in when paging forward.

*Backwards it runs as a real reversal.* Not the same transition again, but
mirrored: what was pushed out comes back from the same side, what closed over
opens again.

*Where a morph meets the slide, it cross-fades.* As soon as something flies
between two slides, the configured transition gives way to a plain cross-fade.
Otherwise the slide would push away the very object flying across it. For a
chain of transformations that means the transition does not have to be switched
off by hand.

= Giving the talk

The aim of this chapter: everything that happens between opening the file and
the last slide, including the second window.

== The keys

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Key*], [*What it does*]),
  [`→` `space` `PageDown`], [one step forward],
  [`←` `PageUp`], [one step back],
  [`Home` `End`], [to the first or the last step],
  [`o` `Esc`], [the overview, and a click there goes to that slide],
  [`f`], [full screen],
  [`s`], [the note of the current slide, in the bar],
  [`?`], [every key],
  [`p`], [print],
  [`n`], [open the speaker view, or bring the talk forward],
)

A click pages forward, a click in the left quarter pages back. The address bar
carries the running step, `#12` being the twelfth, so a reloaded window stands
in the same place and a number typed by hand jumps there.

=== A frame that has the focus

Click an embedded frame and it holds the focus. From then on every key lands
inside it, the window around it hears nothing, and the talk stops paging.

The keys the talk uses are therefore handed back to it out of any frame this
window may read into. Three conditions keep that honest: the embedded document
must not have taken the key already, the key must be one the talk actually
uses, and what was typed into must not be a text field, or an `n` typed into a
form would open a second window.

#tip[
  Measured on a GeoGebra applet before deciding this. Focus sits on its
  canvas, it sees all seventeen keys that were tried, it calls
  `preventDefault` on none of them, and it changes nothing in the
  construction: without a toolbar and without an algebra input it has no use
  for the keyboard at all. A document that does want a key takes it in the
  ordinary way, by preventing the default, and then it keeps it.
]

Everything outside that set stays with the frame. `Delete` is the example: it
belongs to whatever is embedded, and the talk never sees it.

== On a phone or a tablet

A tap pages, in the same two halves as a click. A swipe pages in the natural
direction: the finger pushes the slide out to the left, so the next one comes.

#info[
  The tap deliberately does *not* hang off the click. iOS Safari only builds a
  click out of a touch when the element it hits strikes it as clickable, which
  is to say a link, a button or something with a click listener of its own. A
  slide is none of those, and on an iPhone tapping therefore did nothing at
  all, while the same spot paged in Chrome. An emulated phone does not show
  this, because Chrome always builds the click.
]

Vertical swipes and two fingers are left to the browser: one is scrolling and
the other is zooming.

== The speaker view

`n` opens the same file a second time, with `#speaker` on the address, in a
second window. One goes on the projector, the other on the machine in front of
you. The two talk over `postMessage`, and that carries between two local files
as well, so this needs a server as little as everything else here.

Visible are the running slide, large, beside it the next *step*, below it the
note, together with the time of day, the elapsed time and, once a target
duration is typed in, whether you are ahead of or behind plan.

#tip[
  The preview shows the next step, not the next slide. A deck that counts in
  steps has to answer the question "what does the next keypress do", and that
  can be a new slide or one more reveal on the current one. The label above it
  says which.
]

=== Drawing

You draw on the running slide there, and the strokes appear on the projected
one. That direction is deliberate: the presenter has a trackpad in front of
them and the canvas is across the room.

Strokes stick to their slide, so paging away and back brings them with you.
`x` clears the current slide, `z` takes back the last stroke, `c` changes
colour.

=== The pointer

`m` switches the pointer between the pen and the embedded frame. In pointer
mode the pen rests, and a press on an embedded frame lands in the talk window
instead: the same spot, the same gesture, at whatever size that window happens
to have. Press, drag and release travel as fractions of the stage, so a small
laptop window and a large canvas hit the same point of the document.

Where the embedded document can mirror itself, as a GeoGebra applet does, the
live one in front of you is operated instead and the projected copy follows.

#warning[
  It reaches listeners, not the browser's own widgets. Measured in one frame: a
  checkbox toggles and a button fires, because a click carries its activation
  behaviour along; an `input type=range` does not move, because a browser only
  drags its own slider for input it trusts. Whoever builds for this listens
  rather than relying on a native control.
]

=== Blacking out and freezing

`b` blacks the room out, `e` freezes the projected image while you page ahead
in private. Both end by themselves if the speaker window goes away.

#warning[
  Measured: black and freeze lift on their own a good eight tenths of a second
  after the speaker window is closed. If that window stays open but no longer
  carries a deck, a one-minute deadline applies instead. Whoever additionally
  has a stalling talk window in that situation can put it off indefinitely.
  That is the one known corner in which the room stays dark.
]

Steering works from either window, and either one may be reloaded: they find
each other again, and the strokes come back.

Measured in Chrome, Firefox 154 and Safari 26: the six example decks run
through in all three with the same numbers, and the speaker view opens in all
three on one keypress. A *real* keypress is the condition, since `window.open`
without a user gesture would fall to the popup blocker everywhere.

== Less motion

Someone who has turned on "reduce motion" in their operating system gets a
quieter deck. The browser passes the setting on as
`prefers-reduced-motion: reduce`, and the runtime asks for it afresh on every
step and on every frame: turning it on in the middle of a talk takes effect on
the next key press, and a running flip book stops within a frame. There is
nothing to configure for it, neither in the deck nor at build time.

The setting says "less motion", not "no motion", and that is how it is
implemented here: *opacity stays, travel goes.* An entrance still says "this is
new", which is what an entrance is for, but nothing crosses the slide any more.

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([What], [What becomes of it]),
  [Entrances],
  [Every effect keeps its opacity and loses its travel: `fade-up`, `fade-down`,
   `fade-left`, `fade-right`, `scale`, `scale-down`, `rise` and `blur` become a
   plain cross-fade. `fade` and `none` are left as they are. `duration` and
   `delay` do not change.],
  [`enter: "draw"`],
  [The pen holds still, the fade remains. The drawing *is* the travel, and what
   is left when it is taken out is exactly the cross-fade that ran underneath
   it anyway.],
  [Slide transitions],
  [Every kind but `none` becomes the cross-fade, over the same
   `transition-duration`. `none` stays the hard cut.],
  [Magic move],
  [Does not happen. Nothing flies, and the slide changes the way it would
   change without a morph.],
  [Flip book],
  [Stands still on one frame. Without `loop` and without `pingpong` that is the
   last one, where it would have come to rest anyway; only the way there falls
   away. With `loop` or `pingpong` it is frame zero. `still` does not apply:
   the frame for paper is typeset content and is not in the HTML at all, which
   carries only the frames themselves.],
  [`scene`],
  [Jumps from stop to stop. The frames in between still sit in the file, but
   none of them is shown. What falls away is exactly the travel; the stops
   themselves are not travel, they are the content.],
  [`after: "dimmed"`],
  [Stays. A point stepping back changes its opacity and does not move.],
  [The progress bar in the speaker view],
  [Jumps to its new width instead of gliding there.],
)

Two things are deliberately left alone.

*Video.* A video is content, not decoration, and switching it off would take
something away rather than calm it down. Whoever does not want it to start by
itself writes `autoplay: false`; whoever gives controls leaves the decision to
the viewer.

*Embedded documents.* What sits inside an `embed` or is driven over the bridge
is a foreign document with a style of its own, and the runtime does not reach
into it. The setting does reach it, though: inside the frame,
`matchMedia("(prefers-reduced-motion: reduce)").matches` is true as well.
Anyone animating something in an embedded document therefore writes their own
`@media` rule there. The signal board in the `theme-night` example does not,
and its blinking carries on under the setting.

#info[
  There is no switch with which a deck can overrule the setting. Such a switch
  would be half a line of work, but it would answer the wrong question: the
  package cannot know whether a motion is essential, and whoever believes
  theirs is would turn it on everywhere. Where a motion really does carry the
  argument -- the flip book in `theme-default`, which walks a quantity
  continuously through zero -- it belongs in words as well, and those are read
  by the people who never see it run.
]

= Three outputs from one source

The aim of this chapter: the talk for the canvas, the deck to read afterwards,
and the handout to write on, without a second version to keep in step.

== The slide deck

The PDF run without further arguments gives one page per slide, in the size of
the canvas. Every element that moves in the browser stands there in its final
state: what is revealed is there, and of several versions in one place the last
one stands. What belongs to the motion alone, the notes, the transitions, the
jobs for embedded elements, are state changes without output and fall away by
themselves.

== The handout

One argument turns the deck into a handout on A4:

#show-code[```typ
#show: presentation.with(handout: 3)   // three slides per page
```]

`handout` takes `true` (two per page) or a number from 1 to 6 and applies only
to the PDF. The slides are not typeset again, only made smaller, so a handout
cannot differ from what stood on the canvas.

Beside or below each slide stands its note; where a slide has none, ruled lines
take its place. Which of the two depends on the count. A 16:9 slide beside a
column of notes is wide and low, and at up to two slides per page most of the
portrait page would stay empty. Up to two the notes therefore stand *below* and
the slide takes the full width; from three on they stand *beside*.

== All three in one run

Since Typst 0.15 one compilation can write several files. That suits this
package, because talk, deck and handout differ only in their target and in one
argument. `bundle` writes all three at once:

// check: dokument ziel=bundle
#show-code[```typ
#bundle(
  theme: themes.lesson,
  title: [Completing the Square],
  handout: "handout.pdf",
)[
  = A section
  == A slide
  Text.
]
```]

#show-code[```sh
typst compile --features bundle,html --format bundle talk.typ out
```]

`html`, `slides` and `handout` are file names, `none` leaves that output out,
and `per-sheet` is the number of slides on a handout page. Everything else
goes to `presentation` unchanged.

The counters start afresh per output, measured on the deck: it numbers 1, 2, 3
and does not carry on where the HTML version stopped, although Typst runs
introspection across the whole bundle.

#warning[
  Two things to note. The bundle is explicitly experimental on Typst's side and
  is not available without `--features bundle,html`. And a file that uses
  `bundle` can *only* be compiled with `--format bundle`; a plain
  `typst compile talk.typ talk.pdf` stops with "constructing a document is only
  supported in the bundle target". Whoever wants to keep both routes open puts
  the body in a `#let` and calls `presentation` by hand.
]

== Notes

`speaker-note` files a note with the slide. It stands in the body or as the
argument `note` on `slide`:

#show-code[```typ
== The Pythagorean Theorem
#speaker-note[Show the dissection first, then the formula.]
```]

The note appears in the speaker view, on `s` in the bar, and on the handout. It
produces nothing in the deck PDF.

A note has to carry text. The speaker view transports it as a string and the
handout prints it where there is text, so a note built purely out of layout --
a `fit`, a bare `rect`, an image -- would arrive nowhere. That is refused with
a message rather than dropped in silence. What is meant to be *seen* belongs on
the slide.

= Making it your own

The aim of this chapter: a deck that looks like yours and not like the package.

== Choosing a theme

Five ship with the package. They are made for different occasions rather than
being the same slide in five colours: the title sits sometimes in a bar,
sometimes free, sometimes under a line; the progress indicator grows, travels,
or is missing entirely.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*Made for*]),
  [`themes.default`], [A conference talk. Title in a coloured band, bar of progress.],
  [`themes.lesson`], [A lesson. Built from a measured textbook page: white paper,
   a running head, tinted panels with the caption inside, no progress bar.],
  [`themes.night`], [A darkened room. Dark ground, one signal colour.],
  [`themes.plain`], [Getting out of the way. White, black, one grey, nothing else.],
  [`themes.editorial`], [Reading rather than presenting. A serif face, generous
   measure, a quiet rule.],
)

== Changing one

A theme is a plain dictionary, so `+` is all it takes:

#show-code[```typ
#show: presentation.with(theme: themes.lesson + (accent: blue))
```]

`theme(...)` builds one from scratch. Its colours are `paper`, `ink`, `strong`,
`accent`, `muted`, `surface` and `border`; `header` is `"band"`, `"plain"` or
`"run"`, `footer` is `"fraction"`, `"number"`, `"center"` or `"none"`,
`progress` is `"bar"`, `"top"`, `"tick"` or `"none"`, and `box` is `"bar"` or
`"label"`. `title-slide` and `section` are functions, because those two are
whole pictures rather than variations on one another.

#tip[
  A typo in one of those four words does not quietly do nothing. The package
  checks them and says which values it accepts.
]

== Colour, separately: palettes

A theme says how a slide is *built*; a *palette* says what colour it is. The
two vary separately, which is why they are separate arguments: the classroom
design is still the classroom design in a darkened room. A palette overwrites
*partially*, only the entries written down:

#show-code[```typ
#show: presentation.with(theme: themes.lesson, palette: (accent: blue))
#show: presentation.with(theme: themes.lesson, palette: palettes.dark)
```]

A palette carries eight entries, and they are exactly a theme's colour
entries: `paper` the ground of the slide, `ink` the body text, `strong` the
carrying dark colour, `accent` the signal colour, `muted` the secondary
matter, `surface` the ground of a card, `border` its edge, and `inverted`,
whether light text stands on a dark ground. An entry that does not exist is
refused: `palette: (acent: blue)` stops with a message rather than quietly
doing nothing.

Five ship with the package, and each composes with each of the five themes:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Palette*], [*Where it comes from*]),
  [`palettes.light`], [Exactly the colours of `themes.default`, so this one
    changes nothing about the default.],
  [`palettes.mono`], [The greys of `themes.plain`, two of them moved so it
    passes the contract below.],
  [`palettes.textbook`], [The textbook colours measured for `themes.lesson`,
    one grey moved.],
  [`palettes.parchment`], [The laid paper of `themes.editorial`, two tones
    moved.],
  [`palettes.dark`], [The dark ground of `themes.night`, with a deeper
    accent.],
)

Which is the whole reason no further theme is needed for the dark room:
*darkness is a palette rather than a design.* `themes.lesson` under
`palettes.dark` is still the lesson design, only dark.

`themes.night` stays a theme all the same, and the reason is measured. Its
cyan `#5ec8f2` carries the title on night's own ground at 9.77 to 1, and on
the ground an inverted slide lays behind it at 1.59. A colour that holds on
both would have to sit between roughly 0.13 and 0.23 relative luminance; the
cyan sits at 0.52. So `palettes.dark` takes a deeper blue that holds on both,
and `themes.night` keeps the cyan it was designed around.

#warning[
  Two colours of a theme are not palette entries: `title-fill` and
  `rule-fill`. Whether they follow is up to the theme. All five bundled ones
  let them follow -- either as a function of the palette,
  `title-fill: p => p.strong`, or as `none`, which means the accent and
  follows with it. Both changed type for that: reading `themes.X.title-fill`
  used to give a colour and now gives a function, and `rule-fill` gives `none`
  where it gave the accent. Writing them, `themes.X + (title-fill: red)`, is
  unchanged. A theme of your own that names a fixed colour there keeps it
  under every palette. That is deliberate: a colour someone named out loud is
  not swapped behind their back.
]

And `themes.night` stays a theme all the same. Its cyan `#5ec8f2` measures
9.77 to 1 on the dark ground, which is why it glows there, but only 1.59 to 1
on its own text colour, and that is exactly what an inverted slide puts behind
it. `palettes.dark` therefore takes a deeper tone. The theme keeps its own; it
is a design decision, and a measured one rather than an oversight.

== Inverting one slide

For the slide that carries a single number there is `invert`. The ground
becomes the palette's text colour and the text becomes its ground; `muted`,
`border` and `surface` are mixed from those two, and `strong` and `accent`
carry over unchanged. The chrome follows: running head, footer, slide number
and progress bar are set in the same colours as the slide beneath them, and so
are `card` and `callout`.

In the heading notation it is a marker in the slide body, like `#pause`:

#show-code[```typ
== Reached by 2026
#invert
#statement[74 %]
```]

In the argument notation it is an argument of `slide`:

// check: argument
#show-code[```typ
#slide([Reached by 2026], invert: true)[#statement[74 %]]
```]

#warning[
  Only a regular slide inverts. A title slide and a section slide are whole
  pictures the theme draws itself, and three of the five bundled themes build
  them from colours an inversion does not reach; neither takes the argument.

  The `#invert` marker is found wherever the body can be walked: at the top
  level, inside a `block` or an `align`, in a table cell, in a grid, however
  deeply nested, in the slide's own heading, and behind `#set` and `#show`
  rules. It is *not* found where the content is handed to a closure the walk
  cannot enter -- inside `context`, `fit`, `anim`, `card` or `alternatives` --
  and there the slide is simply left as it is, without a word. Measured, those
  five are the whole of it. Where you need one of them, write the slide as
  `slide(invert: true)`, which never depends on the walk.
]

== The contrast contract

The bundled palettes are measured before they ship. The arithmetic is real
WCAG 2 contrast: each channel linearised, from those the relative luminance
$0.2126 R + 0.7152 G + 0.0722 B$, and from two luminances the ratio
$(L_"light" + 0.05) \/ (L_"dark" + 0.05)$. Six pairs are checked:

#table(
  columns: (auto, auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Pair*], [*At least*], [*What for*]),
  [`ink` on `paper`], [4.5], [body text on the slide],
  [`ink` on `surface`], [4.5], [body text in a card],
  [`muted` on `paper`], [4.5], [footer, subtitle, running head],
  [`accent` on `paper`], [3.0], [rules, progress bar, marker],
  [`accent` on `ink`], [3.0], [the same on an inverted slide],
  [`border` on `paper`], [1.2], [hairlines],
)

Every one of the five palettes is checked, and its inverted form with it, by an
assertion in `src/palettes.typ` that runs when the package is loaded. A colour
moved there that breaks the contract stops the build and names the number it
missed.

#warning[
  *The contract holds only the bundled palettes.* A palette of your own faces
  no such gate: it is neither warned about nor recoloured. `palette-report(…)`
  hands back the same measurement as a list for anyone who wants to see it:

  #show-code[```typ
  #for f in palette-report((paper: white, ink: black, surface: white,
                            muted: luma(55%), accent: blue, border: luma(86%))) [
    #f.pair: #calc.round(f.ratio, digits: 2) (wants #f.min) #f.ok \
  ]
  ```]

  `contrast(a, b)` is the arithmetic itself and takes any two colours.
]

*And the five themes do not all pass it.* The contract was run over them before
the palettes existed, and the result stands here rather than being quietly
coloured away:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*What falls short*]),
  [`themes.default`], [nothing, all six pairs hold],
  [`themes.lesson`], [`muted` on `paper` measures 4.25 against 4.5],
  [`themes.night`], [`accent` on `ink` measures 1.59 against 3.0],
  [`themes.plain`], [`muted` on `paper` measures 3.35 against 4.5;
    `accent` on `ink` measures 1.27 against 3.0],
  [`themes.editorial`], [`muted` on `paper` measures 3.51 against 4.5;
    `accent` on `paper` measures 2.84 against 3.0],
)

None of those colours was changed. They sit in designs that were measured in
their own right, those of `themes.lesson` off a sample page of a German maths
textbook, and moving them would have changed every deck already written. What
`muted` carries is the secondary matter: slide number, subtitle, running head.
Anyone who wants the numbers met lays the matching palette over the theme:

#show-code[```typ
#show: presentation.with(theme: themes.editorial, palette: palettes.parchment)
```]

#warning[
  *The text colour is never inferred from the fill.* A muted sage such as
  `#aebdb3` reads as "light" to a luminance rule, yet white on it measures
  1.96 to 1, far under the 4.5 that body text wants. That is why the package
  measures with `contrast` and recolours nothing on its own.

  The one exception lives in the theme rather than in the palette, and it is a
  measurement too. Where a theme sets `strong` as *text*, the heading in
  `themes.lesson`, the section title in `themes.plain`, it picks between
  `strong` and `ink` by measured contrast against the ground, because one
  colour cannot be a dark band and text on a dark ground at the same time.
  Where the colour named first suffices, and it does for all five themes in
  their own colours, that is the one that stays.
]

== The canvas

`width`, `height` and `margin` on `presentation` set the canvas. The default is
16:9 on an A4 width; 4:3 is `width: 800pt, height: 600pt`. Everything the theme
draws scales along.

== Typography

`style` is a show rule applied to the slides *and* to the moving parts:

#show-code[```typ
#show: presentation.with(
  style: it => { set text(font: "Libertinus Serif"); set par(justify: false); it },
)
```]

#warning[
  This hook is not decoration. A tracked element is typeset a second time in a
  frame of its own, and that frame never sees a `#set` rule written in the
  document, so shared typography has to go here. A `#set text` after the show
  rule reaches the slides but not the flying pieces, and the difference only
  shows up mid-flight.

  For the shapes typstage draws itself there is a second route: label rules
  before `#show: presentation`. They reach more than `style` does, because
  they also reach the header, the footer and the title slide. See /Labels:
  reaching every shape the package builds/ below.
]

== Building blocks for the body

/ `card`: A named box. `number:` puts a numbered disc in front of the text.
/ `callout`: The one that has to stick, with the bar down its left side. Its
  caption follows the document language and can be replaced with `title:`.
/ `side-by-side`: Columns; `split:` gives the widths, `equal: true` makes both
  the height of the taller.
/ `tiles`: A grid that numbers its own reveals, one tile per step, without a
  hand-counted `at:` on each. `duration:` and `easing:` are those of `anim` and
  apply to every tile alike: a grid moves as one thing.
/ `statement`: One large sentence, centred, for the slide that carries a single
  claim.
/ `fit`: Scales one block down to the room it has, for content whose size the
  deck does not set itself.

=== fit: working content into the room it has

For the one piece whose size is not written in the deck: the wide table out of
the analysis, the generated chart, the list that came from a data file. With
nothing in between, such a block runs over the edge of the slide. In the PDF it
is still to be seen standing there; in the browser the slide sits in a frame of
fixed size and whatever reaches past it is cut away.

// check: folgen pre=tabelle
#show-code(```typ
== Regression results
#fit(wrap: false, my-table)
```)

`wrap: false` because the block is a table. Everything that lays itself out in
columns wants to be measured as it stands; the reason follows two paragraphs
down, and it is the one setting worth knowing before the first use.

`fit` measures the block against the place it stands in and scales it
geometrically, so the proportions are kept and no factor is given by hand.
Measured on a table of 9 columns and 22 data rows: the body of a slide in the
`plain` theme is 777.89 pt wide and 364.61 pt tall, the table measures
572.09 pt #sym.times 571.60 pt and is therefore 207 pt too tall. `fit` works
out 63.8 % and sets it 364.6 pt tall. The same in the HTML and in the PDF,
because the arithmetic happens at compile time.

*Width first, then smaller.* The block is offered the full width before it is
measured. A paragraph or a list then wraps into the space instead of shrinking,
and only what is still too tall afterwards is scaled. Measured on `lorem(60)`:
set free, the paragraph is a single line of 3490 pt; offered the width of the
body it becomes 777.89 pt #sym.times 111.06 pt and so already fits. The factor
comes to 100 %, `fit` leaves the block alone, and the slide with the fit and
the slide without it are pixel for pixel the same across the paragraph.
Without the offer of the width, the same paragraph would come to 22.3 % and
stand as a thread across the slide.

A table, a chart or a drawing rearranges itself instead when it is offered a
narrower width, and that changes the picture rather than its size.
`wrap: false` measures such a block exactly as it stands:

// check: folie pre=tabelle
#show-code(```typ
#fit(wrap: false, my-table)
```)

Measured on a table of 24 columns that is 1316 pt wide when set free: with the
default `wrap: true`, Typst squeezes the columns into the 777.89 pt of the
body, the digits overlap, and the factor comes out at 100 %, so nothing is
scaled. With `wrap: false`, `fit` works out 59.1 % and the columns keep their
proportions.

*It only shrinks.* `grow: true` also blows up what is smaller than its place,
for the one large number meant to fill the slide. `shrink: false` takes the
shrinking away and leaves only the growing.

#show-code(```typ
#fit(grow: true)[42%]
```)

`width` and `height` take `auto`, a length or a ratio. On `height: auto` the
block takes what is left over below the rest of the slide's content, so a fit
under two bullet points reckons with the bullet points. That has a flip side
wherever something encloses the fit: inside a `card` the box becomes
slide-tall, is cut off at the bottom, and whatever follows the card falls off
the slide -- measured in both outputs. The `1fr` is doing that, not the
scaling: a `card` around a bare `block(height: 1fr)` behaves the same. Give
`height:` explicitly inside a card, and the fit reckons with that instead.

#warning[
  *No reveal inside a `fit`.* Two things do not survive being measured. A
  `pause` is found by walking the slide body, and a fitted block is a closure
  that walk cannot enter: measured on a slide carrying two pauses, the step
  count fell from three to one, and nothing said so. And a measured block has
  no height to reckon against -- the width is the one a wrapping fit hands in,
  but the height comes back unbounded, and that is the axis on which a tracked
  element resolves its size and reserves the room for its marker. Measured: an
  `anim` inside a fit was not scaled at all and ran off the bottom of the
  slide.

  `fit` therefore stops with a message that names the thing, for `pause`,
  `anim`, `stagger`, `alternatives`, `morph`, `tiles`, `video`, `embed`,
  `flipbook`, `build` and `scene` -- in both outputs, and also when the fit
  sits inside another fit.
  The way round it is to put the fit *inside* the reveal rather than around it:

  // check: folie pre=tabelle fehlt=2 weil=cannot_stand_inside_fit
  ```typ
  #anim(fit(wrap: false, my-table))   // yes
  #fit(anim(my-table))                // no
  ```
]

`speaker-note` and `bridge-job` are allowed inside a fit. They settle no
geometry, and a `measure` commits no state, so both were measured to arrive
exactly once. The other direction is the one that does not work: a note made
only of a `fit` carries no text and therefore reaches neither the presenter
view nor the handout. `speaker-note` refuses that with a message.

The arithmetic is taken from mosaic, which took it from Touying 0.7.4; Touying
credits the work on it to Andreas Kröpelin (Polylux PR #91) and to ntjess.

=== overflow: the checking pass before the talk

`fit` answers the one block whose size you already suspect. `overflow` answers
the question you cannot ask slide by slide: does anything in this deck run over
the room it has? It measures every slide body against the room the theme gives
it and names the ones that do not fit.

#show-code(```typ
#show: presentation.with(overflow: "error")
```)

It is off by default and meant to be switched on for a run, not left on while
writing.

A deck needs this more than a document does. A page one leafs through shows an
overrun: the line simply stands past the margin and the eye catches it. A
typstage slide goes into an SVG frame of fixed size and is scaled in the
browser, so what sticks out is cut away or drawn beside the slide -- and a talk
one clicks through shows that at the projector.

/ `"none"`: nothing is measured. The default.
/ `"error"`: the whole deck is built, and it then stops with *every* place at
  once rather than with the first. One run, the whole list.
/ `"record"`: it carries on and files a queryable record per finding instead,
  for a tool or a build script. Typst gives a package no warning channel, so
  `"record"` prints nothing by itself.

The message names the slide, the step and the amount (shortened here, the
prose around the list is left out):

#show-code(```
error: assertion failed: typstage: 2 slides run over the room the body has. …
  slide 2, from step 1 at the earliest: 311.14pt too tall, 675.76pt of content in 364.61pt of room
  slide 3, from step 2 at the earliest: 296.49pt too tall, 661.1pt of content in 364.61pt of room
Shorten the slide, split it, or put the block that does not fit into fit(). …
```)

*Why the step says "at the earliest".* A slide is exactly as tall on step one
as on step five: every tracked element holds its full room with `hide()` from
the start, so whether the body fits is a question about the slide, not about
the step. What changes with the step is only what is *drawn*. An `anim` hanging
over the bottom edge is invisible until its step, and only then is there
something to see.

The step is worked out from the reveals: everything that only arrives after
step k is invisible there, and if the overrun is larger than all of it put
together, something is hanging over the edge on step k already. That is a lower
bound and not an exact answer, because the sum counts the reveals and nothing
else -- the gaps between them, block spacing, a `v()`, count in the body's
height and in no reveal. Measured: a 350pt box, a `v(100pt)` and an
`anim(at: 4)` below it are reported from step 1, while the overrun only reaches
the screen on step 4. Where the thing that overruns is itself a reveal and
nothing empty stands above it, the step is exact: `anim(at: 3)` is reported
from step 3. *The slide is named correctly either way*, and that is the part to
act on. On paper no step is named at all, because every step stands on the page
at once; in the records that shows as `step: 0`.

The records are read with `typst eval`, and for that the deck has to be on
`overflow: "record"` -- on `"error"` this command stops with the error instead:

#show-code(```sh
typst eval --target html --features html --in deck.typ \
  'query(<typstage-overflow>).map(e => e.value)'
```)

which gives one entry per finding:

#show-code(```json
[{"slide":2,"step":1,"height":675.76,"room":364.61,"over":311.14},
 {"slide":3,"step":2,"height":661.1,"room":364.61,"over":296.49}]
```)

#info[
  *What the check does not see.* Only the height is measured. `measure` caps
  the width it reports at the width it is given, so a body that is too wide
  cannot be told from one that fills its column; `fit` is the answer to that
  case, and the two belong together -- the check finds the slide, `fit` fixes
  the block.

  Four things are missed rather than reported. A `height: 100%` inside the body
  measures 0 and a `1fr` collapses. Anything drawing outside its own layout box
  -- `scale`, `move`, `place` with an offset -- is invisible to a measurement
  altogether. And title and section slides are never measured: the theme draws
  them with `place` and they have no body block to overrun.

  One thing is reported where nothing shows: trailing spacing, a `v()` at the
  end of a body, takes room in the measurement and draws nothing.
]

Measured over the six example decks: in HTML the pass costs noticeably more
time, between 1.2 and 1.5 times depending on the deck and on how the process
start is accounted for; on paper it costs a little, a few milliseconds per
deck. Run over all six decks it reports nothing -- none of them overruns.

=== drift: the check for scenes that travel

`overflow` asks whether a slide fits its room. `drift` asks something else that
one likewise cannot check slide by slide: does a scene stand still while the
talk pages through it?

A drawing is as large as what it holds, a CeTZ canvas above all. Change the
content across the stops of a `scene` and every frame comes out a different
size, so the drawing sits somewhere else inside its box each time -- paging
moves the whole picture although only one point was meant to move. Every scene
therefore measures its frames, and `drift` says what happens with the findings.

/ `"error"`: the whole deck is built, and it then stops with *every* scene at
  once. The default.
/ `"record"`: it carries on and files a queryable record per finding.
/ `"none"`: nothing is measured at all.

#show-code(```typ
#show: presentation.with(drift: "record")
```)

The message names the slide, the step and the numbers (shortened here):

#show-code(```
error: assertion failed: typstage: 1 scene draws frames of different sizes. …
  slide 4, from step 1: 28 frames in 19 different sizes, up to 28.35pt apart across and 53.86pt down
```)

The records are read as with the overflow check, and for that the deck has to
be on `drift: "record"`:

#show-code(```sh
typst eval --target html --features html --in deck.typ \
  'query(<typstage-drift>).map(e => e.value)'
```)

#show-code(```json
[{"slide":4,"step":1,"frames":28,"sizes":19,"width":28.35,"height":53.86}]
```)

*Why this check is on where `overflow` is not.* Only decks that use `scene` pay
for it: measured on a scene of 28 CeTZ frames, 434 ms without and 536 ms with,
so about 100 ms for that one scene. `overflow` measures every body of every
deck. And what this one finds is invisible while writing -- every frame on its
own looks right, and only paging shows the drawing travelling. Only the browser
branch measures; on paper a single still image stands there, and a still image
does not travel.

#info[
  *What the check cannot do, and why.* It sees the case, it does not fix it.
  `measure` answers with a size and never with *where* the ink lies inside it
  -- so there is no offset to compute and nothing to shift.

  *What it misses.* The drawing itself is measured, without a width to reckon
  against. Anything setting itself to `100%` then measures the same for every
  frame and drops out of the check -- rightly so, since such a picture already
  has its fixed frame.

  *What it reports where nothing travels.* A drawing that only grows to the
  right and downwards does not move its ink, yet still measures differently.
  That is exactly what `steady: false` on the scene is for.
]

== Labels: reaching every shape the package builds

Every shape typstage draws on a slide itself -- the ground, the header band,
the slide title, the footer, the progress indicator, the card, the callout,
the statement, the title and section slides, the box that stands in for a
video -- carries a fixed Typst label. That makes it addressable from outside:
an ordinary `show` rule is enough, no theme key, no fork.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#show label("ts-slide-header-band"): set rect(fill: rgb("#4c1d95"))
#show label("ts-slide-title"): set text(fill: rgb("#fde047"), style: "italic")
#show label("ts-card"): set block(fill: rgb("#eef2ff"))
#show label("ts-statement"): set text(fill: rgb("#be123c"), weight: "bold")

#show: presentation.with(theme: themes.default)
```]

Two kinds of rule cover all of it, split by what they touch: the *surfaces* --
grounds, bands, hairlines, bars, boxes -- take `set rect(..)`,
`set block(..)`, `set circle(..)` or `set line(..)`; the *type* takes
`set text(..)` with size, weight, colour, font and tracking. Both act at
compile time, so the result is the same in the HTML and in the PDF -- with one
exception: what is only drawn in the PDF, because the browser puts the real
`<video>` or `<iframe>` in its place, is only seen there. That concerns the
six labels under /Media and handout/.

#warning[
  *For the surfaces* the short form works and the long one does not:

  ```typ
  #show label("ts-slide-progress"): set rect(fill: green)          // yes
  #show label("ts-slide-progress"): it => { set rect(fill: green); it }   // no
  ```

  The short form puts the style rule *around* the element it matched, the long
  one puts it *inside* -- and inside the rectangle there is no second rectangle
  left for it to reach. Anyone who knows the two spellings as equivalent from
  other packages runs aground here.

  For the 16 type labels the two spellings are equivalent: what sits inside
  the matched element there is the text, and a rule reaches that from within
  as well.
]

=== Where the rule has to stand

*Before* `#show: presentation`. That one place reaches everything: the slide
background, the chrome layer with header, footer and progress, the title slide
and every moving piece.

The `style` hook does *not* reach the same. It is wrapped around the slide
*body*, and header, footer, progress and the title and section slides are
built beside it, not inside it. Measured, all 38 rules one at a time: from inside
`style` exactly the 13 that stand in the slide body take effect -- the
building blocks `ts-card…`, `ts-callout…`, `ts-statement`, and the three
stand-in surfaces `ts-media-…`. The other 25 stay silent there, without a
warning. `style` remains the right place for typography that concerns the
whole body; for labels, the place before `#show: presentation` is the one.

#warning[
  A `show` rule written *after* `#show: presentation` does not reach a tracked
  element (`anim`, `morph`). The reason is the one given under Typography: in
  the browser every moving piece is typeset a second time in a frame of its
  own, and that frame never sees a `#show` rule from the document body.

  ```typ
  #show: presentation.with(theme: themes.default)
  #show label("ts-statement"): set text(fill: green)   // too late
  == A slide
  #statement[still]
  #anim(statement[moving])
  ```

  In this file `still` comes out green and `moving` black: four coloured areas
  in the background, none in the overlay. With the same rule one line further
  up it is four and six, and both look alike. The PDF does not show the
  difference, because nothing is typeset twice there.

  This holds for every `#show` rule, not only for label rules; it is not a
  quirk of the labels.
]

=== What a label rule changes and what it does not

Reachable is whatever the package does *not* write as an explicit argument.
For type that is everything; for the surfaces it is `fill` and `stroke`
everywhere and `radius` wherever the shape has a rounding, because those are
exactly what typstage gives its shapes through a `set` rule.

`width` stands there as an argument everywhere and is therefore nowhere
reachable. `height` has three exceptions worth naming: `ts-card`,
`ts-card-bar` and `ts-callout` get their height as `auto`, and `auto` is not a
value that could beat a rule. Not in a row of equal height either: measured on
the painted surface itself, `height:` reaches them there as well.

#show-code[```typ
#show label("ts-card"): set block(height: 150pt)   // works
#show label("ts-card"): set block(width: 30%)      // does not
```]

The first line blows the card up to 150 pt and pushes the callout under it off
the slide. On the chrome surfaces, the grounds and the handout frame neither
one does anything; what a `width` rule seems to change there are the blocks
*inside* the content, see the next box.

The slide's *arrangement* is not reachable either. How tall the header builds,
how far the rule sits under the title, where the bar goes -- that is produced
in `place` and `layout` while the layout composes itself, and no `show` rule
reaches inside it. The theme keys are there for that (`head-gap`,
`band-height`, `rule-size` and the rest); they stay exactly as they were.

#warning[
  A rule on `block` or `rect` reaches *inwards*: it holds for the labelled
  surface and for every block inside it. For `fill`, `stroke` and `radius`
  that is caught -- the card puts back inside whatever the document had set,
  or its own colour would run out over the rounded corners. For the spacings
  it is not caught, and then a label rule moves the slide:

  ```typ
  #show label("ts-card"): set block(below: 60pt)
  == A slide
  #card(title: [Card])[Body]
  #callout(title: [Note])[Remember this]
  ```

  Measured with `pdftotext -bbox` on exactly this slide: the callout moves
  down by 31.2 pt, and everything below it with it. The number is `60pt` minus
  the block spacing of 1.2 em, at 24 pt text 28.8 pt, *per edge*. Setting
  `above` and `below` at once, with something above the card, gives both edges
  and so twice the shift.

  That is not a promise but a side effect of Typst's style rules. Labels are
  meant for type and surface; for spacings, use the building blocks' own
  arguments or the theme keys.
]

=== The complete inventory

What stands here exists; what exists stands here. The names follow one scheme:
`ts-`, then the *place*, then the *part* -- the part always comes after the
place, never before. Places are `slide` (the ordinary slide), `title-slide`,
`section-slide`, `card`, `callout`, `statement`, `media` and `handout`.

Two pairs differ only in word order, and reaching for the wrong one is silent
-- it simply does nothing. So here they are side by side:

#table(
  columns: (auto, 1fr),
  stroke: none,
  table.header([*Name*], [*Place and part*]),
  [`ts-slide-title`], [Place `slide`, part `title`: the title of an ordinary
    slide],
  [`ts-title-slide-title`], [Place `title-slide`, part `title`: the title of
    the title slide],
  [`ts-slide-title-rule`], [Place `slide`: the rule under the slide title],
  [`ts-title-slide-rule`], [Place `title-slide`: the accent stroke on the
    title slide],
)

The mnemonic: `slide` in *front* means the ordinary slide; `slide` behind
`title` or `section` means that kind of slide.

A label the current theme does not draw -- a header band under
`header: "run"`, say -- is not on that slide, and a rule on it then does
nothing.

*The ordinary slide*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*What it is*], [*Rule*]),
  [`ts-slide-ground`], [The slide's ground], [`rect`],
  [`ts-slide-header-band`], [The header band, only under `header: "band"`],
    [`rect`],
  [`ts-slide-header-text`], [The running header of number and section, only
    under `header: "run"`], [`text`],
  [`ts-slide-header-rule`], [The hairline under it, only under
    `header: "run"`], [`rect`],
  [`ts-slide-title`], [The slide title, under all three header styles],
    [`text`],
  [`ts-slide-title-rule`], [The rule under the title, only when
    `rule-size > 0pt`], [`rect`],
  [`ts-slide-footer`], [The footer line], [`text`],
  [`ts-slide-number`], [The slide number in it], [`text`],
  [`ts-slide-footer-rule`], [The hairline above it, only when
    `footer-rule > 0pt`], [`rect`],
  [`ts-slide-progress`], [The progress bar, or under `progress: "tick"` the
    marker that travels], [`rect`],
  [`ts-slide-progress-track`], [The track it travels along, only under
    `progress: "tick"`], [`rect`],
)

*The title slide*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*What it is*], [*Rule*]),
  [`ts-title-slide-ground`], [Its ground], [`rect`],
  [`ts-title-slide-band`], [The band along the top edge, only in
    `themes.lesson`], [`rect`],
  [`ts-title-slide-title`], [Its title], [`text`],
  [`ts-title-slide-subtitle`], [Its subtitle], [`text`],
  [`ts-title-slide-rule`], [The accent stroke; `themes.editorial` has two,
    `themes.plain` none], [`rect`],
  [`ts-title-slide-byline`], [The line of author and date], [`text`],
)

*The section slide*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*What it is*], [*Rule*]),
  [`ts-section-slide-ground`], [Its ground], [`rect`],
  [`ts-section-slide-bar`], [The bar along the left edge, only in
    `themes.lesson`], [`rect`],
  [`ts-section-slide-title`], [Its title], [`text`],
  [`ts-section-slide-rule`], [The accent stroke; `themes.night` has two,
    `themes.lesson` none], [`rect`],
  [`ts-section-slide-parent`], [The line above it naming the sections this one
    hangs under. Only from the second structure level on, so never at
    `slide-level: 2`], [`text`],
)

A section slide has no subtitle in typstage, so the list names none.

*The building blocks in the body*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*What it is*], [*Rule*]),
  [`ts-card`], [The card: surface, border, rounding and all of its contents],
    [`block`],
  [`ts-card-bar`], [The coloured tab above it, only under `box: "bar"`],
    [`block`],
  [`ts-card-title`], [Its caption], [`text`],
  [`ts-card-disc`], [The disc of the number, only with `number:`], [`circle`],
  [`ts-card-number`], [The numeral in it], [`text`],
  [`ts-card-body`], [Its body], [`text`],
  [`ts-callout`], [The callout: surface, bar, rounding. The bar on the left is
    not a label of its own, it is this one's left `stroke` --
    `set block(stroke: (left: 4pt + red))` recolours it], [`block`],
  [`ts-callout-title`], [Its caption], [`text`],
  [`ts-callout-body`], [Its body], [`text`],
  [`ts-statement`], [The large statement. `size` acts as a factor on it,
    because `statement` measures in `em`], [`text`],
)

*Media and handout*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*What it is*], [*Rule*]),
  [`ts-media-fallback`], [The box that stands in for a moving element in the
    PDF. A container only, with no colour and no border of its own, so a
    `radius` rule on it is not visible while a `fill` rule is], [`block`],
  [`ts-media-fallback-empty`], [The grey box inside it when no `fallback:` was
    given. That one does have a surface], [`block`],
  [`ts-media-poster`], [The grey area of a `video` without a `poster:`],
    [`rect`],
  [`ts-handout-frame`], [The framed box of one slide on the handout page],
    [`block`],
  [`ts-handout-lines`], [The writing lines beside or below it], [`line`],
  [`ts-handout-note`], [The speaker note, where there is one], [`text`],
)

#info[
  Three things that belong with this.

  *A theme with its own title slide draws none of these labels.*
  `title-slide` and `section` in a theme are functions and paint their picture
  themselves; whoever brings their own loses the six respectively four labels
  of that slide kind, and nothing warns about it. The five bundled ones draw
  what their picture needs and no more: band and bar exist only in
  `themes.lesson`, `themes.plain` has no accent stroke on its title slide,
  `themes.lesson` none on its section slide. Which theme draws what stands in
  the /What it is/ column.

  *The invisible markers carry none.* Every moving element paints a
  transparent rectangle around itself so the browser can find it again, and
  `pin` does the same for a single glyph. That is machinery, not a shape;
  both stay nameless.

  *Typst labels and the runtime's CSS classes are two separate namespaces.*
  `.ts-slide` in the stylesheet is a slide's `<section>` in the browser,
  `ts-slide-title` is a Typst label -- one hyphen apart and unrelated. Typst's
  HTML export does put a `data-typst-label` attribute on some shapes, on the
  building blocks of the body for instance, and on the type shapes it does
  not. That is Typst's own by-product, not a promise of this package: do not
  build CSS on it.
]


== `info()`: what the deck knows about itself

Labels say how a shape the package builds looks. They do not say what stands
in it. The slide number, the fraction, the chapter in the running header --
those numbers were the package's own, and anyone who wanted a footer of their
own had to count along. `info()` hands them out:

#show-code[```typ
#context {
  let deck = info()
  [#deck.section.title #h(1fr) #deck.slide.number / #deck.slide.total]
}
```]

It is the same reading the built-in footer does. Every number the package
prints on a slide -- the slide number, the fraction, the length of the progress
bar, the running header -- comes out of this dictionary and out of no second
count. A hand-built footer and the built-in one cannot print different numbers.

What comes back:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Field*], [*What is in it*]),
  [`title`, `subtitle`], [The deck's title and subtitle, as `presentation` or a
    `title-slide` received them],
  [`author`, `date`], [From the same place. `date` is whatever was passed, a
    `datetime` or content],
  [`slide.number`], [This slide. Counted the way the footer counts, so title
    and section slides are not in it],
  [`slide.total`], [How many slides are counted],
  [`slide.numbered`], [Whether this slide is one of them. `false` on a title
    and on a section slide],
  [`step.number`], [The step the calling content itself stands on],
  [`step.total`], [How many steps this slide has],
  [`section.number`], [Which section is running, `0` before the first],
  [`section.total`], [How many sections the deck has],
  [`section.title`], [Its title, or `none` before the first],
  [`levels`], [One entry per structure level, outermost first. Empty at
    `slide-level: 1`],
  [`outline`], [The whole structure, one entry per section slide in the order
    they come],
)

`section` always means the level directly above the slide. At the default
`slide-level: 2` that is the only level there is, and then `section` is
`levels.last()` without its `depth`.

A deck with more than one level -- see "More than two levels" -- finds them in
`levels` and in `outline`:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Field of an entry*], [*What is in it*]),
  [`levels.at(i).depth`], [The heading level, `1` for `=`, `2` for `==`],
  [`levels.at(i).title`], [The title, or `none` while no section of that level
    is running],
  [`levels.at(i).number`], [Which section of that level it is in the *whole*
    deck. It never goes back, so it also reads as progress],
  [`levels.at(i).total`], [How many sections that level has in the whole deck],
  [`levels.at(i).index`], [Which one it is *under the same parent*, what Beamer
    prints as `1.2`],
  [`levels.at(i).count`], [How many siblings it has there. `index` and `count`
    are `0` while no section of that level is running],
  [`outline.at(j).depth`], [The same for an entry of the outline],
  [`outline.at(j).title`], [Its title],
  [`outline.at(j).number`], [The same count as `levels.at(..).number`.
    Comparing the two says whether the entry is past, running or still to
    come],
  [`outline.at(j).here`], [Whether the slide being shown is that very entry.
    Only a section slide can be, and only a theme's own `section` function can
    read it there: a section slide has no body for a deck to write into],
)

A progressive agenda therefore needs no second count:

// check: folie
#show-code[```typ
#context {
  let d = info()
  stack(spacing: 0.6em, ..d.outline.map(e => {
    let running = d.levels.at(e.depth - 1).number
    text(
      weight: if e.number == running { "bold" } else { "regular" },
      fill: if e.number <= running { black } else { luma(60%) },
      [#h((e.depth - 1) * 1.4em)#e.title],
    )
  }))
}
```]

One number stands deliberately apart: the speaker view and the overview count
*every* slide, title and section slides included, while `info().slide.total`
counts the way the footer counts and leaves them out. On a sample with one
title slide, two section slides and three ordinary ones, that is 6 against 3.

=== Two counts, not one

A deck that counts pages would get by with one number. This one counts slides
*and* steps, and the two are different things: a slide is one picture, a step
is one press of the arrow key. So they stand apart, and they are called what
they are called throughout this manual.

`step.number` is the step the calling content itself stands on: `1` in the body
of a slide, and inside an `anim`, a `stagger` or an `alternatives` the step of
that reveal -- and where a reveal covers several steps, the first of them. That is the difference that matters -- a display naming the
current step has to sit inside the reveals, because the browser typesets
nothing anew:

#show-code[```typ
#let where = context {
  let d = info()
  [Step #d.step.number of #d.step.total]
}

== Four versions
#alternatives(where, where, where, where)
```]

Paging through, that prints "Step 1 of 4" up to "Step 4 of 4" -- measured on a
sample with nine steps, at every one of them.

On paper there is no current step: the page shows the slide in its final state,
everything at once. There `step.number` equals `step.total`.

#info[
  `step.total` counts what the runtime in the browser counts. Cross-checked on
  a deck holding one of every building block that consumes a step -- `pause`,
  `stagger`, `anim` with and without a number, `alternatives`, `tiles`,
  `morph`, `video`, `flipbook`: on all nine slides with a body `info()` names
  the same number the runtime in the browser counts, and the PDF names it too.
]

=== Where a hand-built footer goes

typstage draws no footer on a title or a section slide. Anyone building their
own faces the question of what belongs in the counter slot there -- and the
answer is nothing. `slide.numbered` says when that is the case:

#show-code[```typ
#let footline = context {
  let d = info()
  let number = if d.slide.numbered [#d.slide.number / #d.slide.total] else []
  place(bottom + right, text(size: 12pt, fill: muted, number))
}
```]

On an ordinary slide it goes into the body, that is, into the slide itself:

// check: folgen davor
#show-code[```typ
== A slide
#footline
The text of the slide.
```]

On the title and the section slides it has to go into the theme: those two
pictures are functions, and a function wrapped around another adds to it rather
than replacing it.

#show-code[```typ
#let base = themes.default
#let with-foot(f) = (t, s, geo) => { f(t, s, geo); footline }

#show: presentation.with(
  theme: base + (title-slide: with-foot(base.title-slide),
                 section: with-foot(base.section)),
)
```]

#warning[
  *Not through `style:`.* The hook looks like the convenient shortcut:
  `style: it => { footline; it }` would put the footer on every slide without
  writing it out once per slide. But it is also the template each moving
  element is typeset with a second time -- and whatever *draws* in there is
  drawn again inside every sprite.

  Measured on a deck with three reveals per slide: in the browser the footer
  stood on the slide four times instead of once, and inside a flip book of six
  frames another six times. Counted in the body, same deck, same sprites: once.
  On paper it does not show, there are no sprites there.

  `style:` is for typography -- typeface, size, colour, leading -- and for that
  it is exactly right: background and sprite need the same.
]

#info[
  A footer placed in the body sits at the bottom of the *body*, not at the
  bottom of the slide; the theme's `foot-gap` lies in between. A `dy:` on the
  `place` moves it where it belongs.
]

#warning[
  `info()` reads the state of the slide being typeset and therefore needs a
  `context` around it. *Before* the presentation there is nothing to read;
  there it stops with a message rather than handing out zeros.

  *After* it, no: whoever passes the slides as arguments and writes an `info()`
  below the call still gets the last slide's numbers. Clearing the deck's own
  record at the end would close that, but measured it costs layout headroom: a
  slide with one reveal beside a `tiles` went from no warning to three
  "did not converge" ones. A corner nobody stands in is not worth that, and in
  the show-rule notation nothing comes after the deck anyway.
]


= Handing it on

The aim of this chapter: getting the talk to where it will be given.

== One file

`assets: "inline"` is the default and writes the runtime into the HTML. The
result is one file that runs from a memory stick, from a download folder, from
an email attachment. No server, no network, nothing loaded afterwards.

The six example decks measure between 1.2 and 2.1 MB that way, and the runtime
is about 100 KB of that. What makes up the rest are the slides themselves: the
tour holds 136 SVGs and 6111 glyph references.

== Beside the file

`assets: "split"` refers to two files next to the HTML instead, and
`runtime-files` gives you their names and contents so you can write them out:

#show-code[```typ
#for f in runtime-files {
  // f.name and f.content
}
```]

That is worth it where many decks are published together, because the browser
then caches the runtime once for all of them. `assets: "https://…"` points at a
directory on a server or a CDN.

== Hosting

The HTML file is static. Anything that serves files serves it: GitHub Pages, a
university web space, an S3 bucket. Two things to watch.

Media travels beside the file. `video("clip.mp4")` refers to a file that has to
lie next to the HTML, and a deck that works locally will show an empty frame
once uploaded without it.

A deck opened from `file://` behaves like one from a server, including the
speaker view, because everything here goes over `postMessage`. That is the one
place where this package is easier than the browser-native tools, which need a
server for exactly that reason.

= What it cannot do

The aim of this chapter: the limits, in one place, so they are not discovered
in front of an audience.

== Accessibility

This is the hardest limit, and it follows directly from the design decision on
the first page.

The slides are SVG outlines. Text in them is drawn as paths and glyph
references, not as text. Nothing in the browser is selectable, nothing is
searchable, and a screen reader finds nothing to read. There is no text
alternative behind them and no reading order.

What does work: the document carries a `lang` attribute from `text.lang`, so
the page announces its language. Navigation is fully operable from the
keyboard, and the full key list is one press of `?` away. Colour and contrast
are the theme's and therefore yours to set, and `themes.plain` is the darkest
of the five on white.

What does not work yet: `prefers-reduced-motion` is not honoured. A viewer who
has asked their system for less motion still gets every fade, flight and slide
transition. If that matters for your audience, `transition: "none"` and
`enter: "none"` are the manual way to the same place.

#warning[
  If the room includes someone who reads with a screen reader, the honest
  answer is to hand out the PDF as well and to say what is on each slide. The
  PDF from the same source carries real text.
]

== A tracked element with no area

A tracked element gets its place in the browser from a rectangle Typst paints
around it in a signal colour. Where the content has no area, that rectangle
would have none either, and a sprite given a viewport of zero scales everything
inside it to nothing: the element stands in the page, with its path and its
colour, and cannot be seen. On paper it stands.

Two shapes reach that point and both are handled. A vertical rule measures no
width; like every arealess element it is given a font height of air on each
side, and the air is placed, so the flow is unchanged. A `place` measures
nothing in either direction and is not in the flow at all; it moves outward on
its own and the tracked element moves inside it, so the marker stands where the
content stands and the flow keeps its zero.

// check: folie
#show-code(```typ
#anim(at: 2, place(top + left, dx: 20pt, dy: 50pt,
                   rect(width: 20pt, height: 20pt)))
```)

What is left over is said rather than lost. A marker with no width or no
height, and a marker nested deeper than four tracked elements, which is as far
as the placing goes: each goes to the browser's console once per element.

#show-code[```
typstage: the tracked element 3 on slide 4 has a marker with no width.
Its sprite is given a viewport of that extent, and a viewport of zero
scales everything inside it to nothing: the element is in the page, with
its path and its colour, and cannot be seen. On paper it stands. Put it
in a box with a size, or give the element a width.
```]

The question cannot be asked at compile time, for the same reason as with
`draw`: whether content has an area is not a question the document can answer.
Only in the browser is the rectangle there to be measured. The package's own
check run reads these messages along.

== Reach

Measured in Chrome, Firefox 154 and Safari 26 on macOS, and on an iPhone. The
six example decks run through in all three engines with identical numbers and
no console errors.

Not measured: older browsers, Windows, Android. The runtime uses the Web
Animations API, `ResizeObserver`, `PointerEvent` and CSS `zoom`, so a browser
from before about 2023 is likely to fall short somewhere.

== Size and speed

A slide is typeset as often as it has states, and every tracked element is
typeset once more in a frame of its own. Compile time therefore grows with
steps, not with slides, and `flipbook` grows with frames.

The largest of the six example decks compiles in a few seconds and weighs
2.1 MB. A deck of a hundred slides with a flip book on each would be a
different matter, and the honest advice is to measure rather than to guess.

= When nothing happens

The traps, in roughly the order they are usually hit.

/ No HTML export: `--features html` is missing. The export is experimental on
  Typst's side, not on this package's.
/ The deck is empty but for the title: the two notations have been mixed. In
  the heading form you write `= …` and `== …`; in the argument form you call
  `slide(...)` and hand the slides to `presentation`. A `slide(...)` call
  inside the body of a show rule produces no slide and no error either.
  Measured on a probe: one slide instead of three, and nothing said.
/ The first paragraph is missing: content before the first heading belongs to
  no slide. Where it carries text, compiling stops there and says so — see
  "Text that belongs to no slide". Where it carries none (an image, say), it
  still goes without a word.
/ The slide titles ignore a `#set heading`: it stands after the show rule and
  they have left the region it encloses. `style:` reaches them.
/ `#pause` does nothing: it is inside a grid cell or a table. `#pause` splits
  the body, and there is nothing there to split. `anim` goes anywhere content
  goes.
/ A transition or an entrance is duller than it was meant to be: an unknown
  name quietly becomes a cross-fade. Check the spelling against the tables
  above, since a typo does not stop the build.
/ The bullets beside an applet start at step three: an `embed` uses no step,
  but something before it did. Count the reveals, not the elements.
/ A flying equation has the wrong font: typography set with `#set` does not
  reach a tracked element, which is typeset in a frame of its own. `style:` on
  `presentation` reaches both.
/ An embedded frame stays empty and gets no jobs: the document has not
  announced itself with `postMessage({typstage: 1, ready: 1})`.
/ An applet frame stays empty: the applet is loaded from `geogebra.org`, so
  without a network there is nothing to load. Point `codebase` at a local copy.
/ A `ggb-run` command has no effect: it is one of GeoGebra's scripting
  commands, which `evalCommand` does not accept. `ggb-set`, `ggb-style`,
  `ggb-show` and `ggb-hide` reach the interface that can do it.
/ The build stops naming two applets: two frames on one slide and no `target`.
  Nothing is guessed here on purpose.
/ The applet's colours change after paging back: GeoGebra hands out the next
  colour of its palette on a rebuild. Fix the colour on `"1-"`.
/ A circle in the applet is an ellipse: the x range and the y range of
  `ggb-view` do not match the shape of the box.
/ A tween does not play: it sits on step 1, where the runtime sets tweens to
  their target instead of playing them, or it was given a range instead of a
  step number.
/ Two sliders lie on top of one another: `position` counts in pixels for a
  slider made with `Slider`, not in coordinates.
/ A point cannot be dragged in the speaker view: it was made with
  `Point(k, 0.3)` and is pinned to that parameter.
/ An embedded frame is tiny on the projector and right on the laptop: its
  content is sized in pixels instead of `em`. Inside a zoomed frame one CSS
  pixel is one point of the slide.
/ "constructing a document is only supported in the bundle target": the file
  uses `bundle` and therefore needs `--format bundle`.
/ The speaker view does not open: `window.open` needs a real keypress, and a
  script cannot stand in for the gesture.

= API reference

Generated from the comments in the source files. The order follows the build of
the package: first the presentation and its slides, then the building blocks,
then media and the bridge, and last the measurements and colours.

== The presentation

// `split-body`, `pause-tokens` and `apply-pauses` take the body apart and are
// not part of the public surface.
#show-module(read("../src/present.typ"), name: "typstage",
             exclude: ("split-body", "pause-tokens", "apply-pauses",
                       "slides-from-body", "stiller-lauf"))

== Slides

#show-module(read("../src/slides.typ"), name: "typstage")

== Revealing, moving, staggering

// `anim-kern` is the checked inside of `anim`. `stagger` uses it from
// within, and `lib.typ` does not hand it out. The same
// holds for the two helpers of `scene`.
#show-module(read("../src/elements.typ"), name: "typstage",
             exclude: ("anim-kern", "szene-messbar", "szene-zwischen"))

== Layouts

#show-module(read("../src/layout.typ"), name: "typstage")

== Themes

// Only the blueprint and the five ready-made ones; the individual title and
// section pictures are building blocks of those and do not stand alone.
#show-module(read("../src/themes.typ"), name: "typstage",
             only: ("theme", "themes"))

== Palettes

// Only what `lib.typ` hands out. `kanal`, `leuchtdichte`, `lesbar` and the
// check itself are internals.
#show-module(read("../src/palettes.typ"), name: "typstage",
             only: ("palettes", "contrast", "palette-report"))

== Media and embeds

// `fallback-box` is no longer public; `embed` and `geogebra` use it from the
// inside where the paged output holds no applet.
#show-module(read("../src/media.typ"), name: "typstage",
             exclude: ("fallback-box",))

== The bridge

#show-module(read("../src/bridge.typ"), name: "typstage")

== GeoGebra

// `resolve-target` and `no-stray-target` belong to the internals, and the
// applet document in `applet.typ` all the more so.
#show-module(read("../src/geogebra.typ"), name: "typstage",
             exclude: ("resolve-target", "no-stray-target"))

== Measurements, colours, runtime files

// Only what `lib.typ` hands out as well.
#show-module(read("../src/config.typ"), name: "typstage",
             only: ("slide-width", "slide-height", "slide-margin",
                    "dark", "accent", "paper", "muted",
                    "runtime-version", "runtime-files"))
