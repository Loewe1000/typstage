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

Four building blocks cover very nearly everything. They mix on one slide, and
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

== One piece on a step of its own

`anim` wraps exactly what should appear and says when:

#show-code[```typ
#side-by-side(
  card(title: [Before])[The old way.],
  anim(at: 2, enter: "fade-left", card(title: [After])[The new one.]),
)
```]

=== Entrance and exit

`enter` and `exit` name the motion. Ten of them exist:

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
  [`"none"`], [it is simply there],
)

`duration` is in milliseconds and `auto` takes the presentation's. `delay`
holds the start back, which is what makes two elements on the same step arrive
one after the other.

#warning[
  An unknown name does not stop the build. It quietly becomes a cross-fade, so
  a typo in `enter: "fdae-up"` is only noticed by the motion being duller than
  it was meant to be.
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
document on the other side. That is exactly how `typstage-geogebra` drives its
applets.

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
paper.

#warning[
  Every frame is really typeset. Twenty-four frames are twenty-four layouts and
  twenty-four SVG trees in the file. That is the most expensive element in this
  package, in compile time and in file size alike, and it is worth reaching for
  only where the motion carries the argument.
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

Where the embedded document can mirror itself, as a GeoGebra applet does
through `typstage-geogebra`, the live one in front of you is operated instead
and the projected copy follows.

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
  hand-counted `at:` on each.
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
  `anim`, `stagger`, `alternatives`, `morph`, `tiles`, `video`, `embed` and
  `flipbook` -- in both outputs, and also when the fit sits inside another fit.
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

  For the 15 type labels the two spellings are equivalent: what sits inside
  the matched element there is the text, and a rule reaches that from within
  as well.
]

=== Where the rule has to stand

*Before* `#show: presentation`. That one place reaches everything: the slide
background, the chrome layer with header, footer and progress, the title slide
and every moving piece.

The `style` hook does *not* reach the same. It is wrapped around the slide
*body*, and header, footer, progress and the title and section slides are
built beside it, not inside it. Measured, all 37 rules one at a time: from inside
`style` exactly the 13 that stand in the slide body take effect -- the
building blocks `ts-card…`, `ts-callout…`, `ts-statement`, and the three
stand-in surfaces `ts-media-…`. The other 24 stay silent there, without a
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

#show-module(read("../src/elements.typ"), name: "typstage")

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

== Measurements, colours, runtime files

// Only what `lib.typ` hands out as well.
#show-module(read("../src/config.typ"), name: "typstage",
             only: ("slide-width", "slide-height", "slide-margin",
                    "dark", "accent", "paper", "muted",
                    "runtime-version", "runtime-files"))
