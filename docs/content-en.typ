#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= What this package is

`typstage` turns a single Typst file into an animated presentation for the
browser, and a PDF from the same source. *Typst typesets, the browser moves.*
Every slide is set by Typst as SVG, so the arrangement in the browser is the
one on paper. Whatever is meant to move is marked in the source, and a small
runtime animates it.

A slide therefore stays a slide, not a stack of intermediate states. The PDF
has one page per slide, and whatever belongs to the motion alone falls away on
paper -- or, with `pages: "step"`, one page per step, so the paper turns the
way the talk does.

== Five words this manual uses

/ Slide: One picture, typeset once by Typst. One page of the PDF, one
  `.ts-slide` in the HTML.
/ Step: One press of the arrow key. A slide can hold several; at the last one
  the next press moves on. The address bar counts steps, the footer counts
  slides.
/ Element: A piece of a slide that the runtime may touch. `anim`, `stagger`,
  `alternatives`, `morph`, `scene`, `embed`, `video` and `flipbook` all
  produce one.
/ Morph: The same named element twice -- on two adjacent slides, or on two
  steps of one slide. Between them it flies, glyph by glyph where it can.
/ Speaker view: The same file opened a second time with `#speaker` on the
  address. It carries the note, the clock and the next step, and it draws on
  the slide the room sees.

== Where it sits among the others

`touying` and `polylux` are mature, have far more themes, and make PDF. For a
normal PDF talk, take one of those. `reveal.js`, `Slidev` and `Quarto` animate
in the browser, but their layout is HTML's, not Typst's.

Nearest are the Typst packages that write HTML themselves. `touying-exporter`
renders one SVG per slide and packages the sequence with `impress.js`. `slipst`
follows slipshow and gives up the fixed-size slide altogether: there "slips"
scroll from top to bottom. On the PDF side, `mosaic` is worth a look -- it cuts
its slides from the same headings this package does, `=` for the section and
`==` for the slide -- and so is `slydekit`. Three of the seventeen example
decks are adaptations of mosaic decks, so that part of the comparison is on the
screen rather than in my prose.

What this package does instead: a named piece stands in one place on slide n
and elsewhere on slide n+1, and it flies between the two -- glyph by glyph, so
an equation visibly rewrites itself. Weaker forms cover the rest: a page that
turns, a cross-fade, whole slides pushed around by a script. What carries all
of it is one SVG per #emph[state] rather than per slide, so between two states
there is something left that can fly.

#warning[
  The price, stated before the first line of code: the slides are SVG
  outlines. Nothing in the browser is selectable or searchable, and a screen
  reader sees nothing at all. For some talks that is too high; there is a
  chapter on it further down.
]

This manual is ordered by intent rather than by function:

+ *Your first presentation* — from the empty file to a running HTML
+ *One deck, from start to finish* — one talk, built to the end
+ *Revealing a slide step by step* — `pause`, `stagger`, `anim`, `alternatives`
+ *Showing instead of claiming* — an applet, a video, a flip book
+ *GeoGebra* — constructions that follow the steps of the slide
+ *Desmos* — the same road, a different calculator
+ *Developing a calculation* — magic move across several slides
+ *Giving the talk* — keys, touch, the overview, the speaker view
+ *Three outputs from one source* — talk, slide deck, handout
+ *Making it your own* — themes, colours, canvas, building blocks
+ *Handing it on* — one file, assets, hosting
+ *What it cannot do* — reach, accessibility, size
+ *When nothing happens* — the traps, in the order they are usually hit
+ *API reference* — every function, from the source

#info[
  The typeset examples here are paper and show the final state, everything at
  once. What happens one after another in the browser is said in the text
  beside them.

  Every `typ` listing is compiled against the real package before publishing.
  That catches a listing which no longer compiles -- not one that compiles and
  does the wrong thing.
]

= Your first presentation

A complete, presentable talk in ten minutes.

== One file is enough

An import, a show rule, headings. This file is complete and can be typed out
as it stands:

// Read from the file rather than copied out, so these are the very bytes that
// `.github/scripts/pruefe-beispiele.py` compiles.
#show-code(raw(read("../examples/handbuch/first-deck.typ").trim(),
               block: true, lang: "typ"))

A first-level heading is a section slide, a second-level heading is a slide,
and the text below it is its body. That is the whole structure.

== More than two levels

By default `=` becomes a section slide and `==` a slide. `slide-level` moves
that cut: a heading *above* it becomes a section slide, a heading at it or
below it becomes a slide.

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
a slide. Every section heading is its own transition slide, so there is
nothing to switch on.

`slide-level: 1` makes every heading a slide; the deck then has no structure
level at all.

A heading written as a function call counts by its level like a typed one:
`#heading(level: 3)[…]` as `===`, `#heading[…]` without a level as `=`. A
subheading that stays in the body and begins no slide goes into a block:
`#block(heading(level: 3)[…])`.

The five bundled themes draw a deeper level more quietly: the title gets
smaller, and above it stands what the section hangs under. What the deck knows
about its structure is in `info()` -- see "`info()`: what the deck knows about
itself".

=== Text that belongs to no slide

A section slide is a whole picture the theme draws; it has no body. Text
between a section heading and the next heading therefore belongs to no slide,
and stops the compile instead of silently disappearing.

A sentence between `= The proof` and `== The dissection` aborts with
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

Text *before* the first heading is refused the same way, as long as the deck
has at least one heading. Both rules apply to heading notation only.

== When the slides are computed

Headings created while the document is set become slides too. A loop over a
list gives one slide per entry:

#show-code[```typ
#for element in ("Water", "Air", "Earth") [
  == #element
  Something about #element.
]
```]

Where the slides come entirely from data, hand them over one by one instead.
Each slide is a function call, and a list of slides spreads with `..` like any
other array:

// check: dokument
#show-code[```typ
#presentation(
  title-slide(title: [The Pythagorean Theorem], author: [A. Schulz]),
  section[The proof],
  slide([The dissection], note: [Show the square first.])[
    The text of the slide.
  ],
)
```]

Both spellings give the same output; `presentation` tells them apart from its
arguments. The heading form is the ordinary case.

== Two compilations

The same file gives two outputs. The flags decide which:

#show-code[```sh
typst compile talk.typ talk.html --format html --features html
typst compile talk.typ talk.pdf
```]

#warning[
  Without `--features html`, HTML export is unavailable, and Typst's error
  message reads like a mistake in your file rather than a missing flag. The
  feature is experimental in Typst itself, not in this package.
]

== Looking at it

The HTML is one file. Double-click it and it runs: no server, no network,
nothing loaded afterwards.

Arrow keys page. `?` shows a line with the main keys, `o` opens the overview,
`f` goes full screen, and `n` opens the speaker view in a second window.

== While you write

That is the finished deck. While one is still taking shape, `typst watch` takes
the compiling over: it rebuilds on every save, and for HTML it also brings a
small server and puts one line into the page it serves, with which the browser
reloads itself.

#show-code[```bash
typst watch talk.typ talk.html --format html --features html --port 3000
```]

Open `http://127.0.0.1:3000` once and leave the tab alone. A deck of
twenty-eight slides -- four megabytes of HTML -- is back about seventy
milliseconds after a save, and it is back *on the step it was on*: the step
stands in the address, and the deck reads it as it loads.

#info[
  `--port` may be left out; Typst then takes the first free port between 3000
  and 3005 and prints it. Naming it keeps the address the same every time, and
  a second run on that port says `port 3000 is already in use` instead of
  quietly serving somewhere else.
]

#warning[
  The page the server hands out and the file beside your source are not the
  same. The reload line is ninety-seven bytes that only the server adds; the
  file never carries it, so what you pass on is untouched. `--no-serve` and
  `--no-reload` switch the two off separately.
]

In VS Code this is one keystroke. Put the following in `.vscode/tasks.json`,
and the build shortcut -- `Shift+Cmd+B` on macOS, `Ctrl+Shift+B` elsewhere --
runs the watch for whichever file is in front of you; errors land in the
problem list with a line to click.

#show-code[```json
{
  "version": "2.0.0",
  "tasks": [{
    "label": "Deck live",
    "type": "shell",
    "command": "typst",
    "args": ["watch", "${file}",
             "${fileDirname}/${fileBasenameNoExtension}.html",
             "--format", "html", "--features", "html",
             "--root", "${workspaceFolder}", "--port", "3000"],
    "isBackground": true,
    "group": { "kind": "build", "isDefault": true },
    "problemMatcher": {
      "owner": "typst",
      "pattern": [
        { "regexp": "^(error|warning): (.*)$", "severity": 1, "message": 2 },
        { "regexp": "^\\s*┌─ (.+):(\\d+):(\\d+)\\s*$",
          "file": 1, "line": 2, "column": 3 }
      ],
      "background": {
        "activeOnStart": true,
        "beginsPattern": "compiling \\.\\.\\.",
        "endsPattern": "(compiled |is already in use)"
      }
    }
  }]
}
```]

= One deck, from start to finish

One talk in a single file, from the empty line to the handout. Every step
adds exactly one thing, and together they cover what an ordinary deck needs.

The subject is a school exercise: *How tall is the tower?* A pole 1.20 m high
casts a shadow of 0.90 m; the tower casts a shadow of 21 m. Find its height.

== The empty file

Two lines are a deck: one fetches the package, one says this document is a
presentation.

// check: dokument
#show-code[```typ
#import "@preview/typstage:0.2.0": *
#show: presentation.with(title: [How tall is the tower?])
```]

It is compiled twice, from the same file:

```bash
typst compile tower.typ tower.html --format html --features html
typst compile tower.typ tower.pdf
```

Open the HTML and page with the arrow keys. So far there is only the title
slide -- `title:` alone produces it.

== The first slide

`==` is a slide, the text below it its body; `=` is a section slide.

// check: folgen
#show-code[```typ
= The question

== A pole and a tower

A pole 1.20 m high casts a shadow of 0.90 m.
The tower casts 21 m. How tall is it?
```]

No more structure than this is needed.

== What is to appear one after another

`stagger` splits a bullet list at its items: one step per item.

// check: folgen
#show-code[```typ
== What we see

#stagger[
  - The sun stands equally high for both.
  - So the angle is the same.
  - So the triangles are similar.
]
```]

The slide now has three steps: the first point stands there with the body, and
each of the other two comes one step later.

== A box that has to stick

The sentence that matters does not belong in the list. `callout` sets it
apart, with a bar down its left side.

// check: folgen
#show-code[```typ
== What we see

#stagger[
  - The sun stands equally high for both.
  - So the angle is the same.
  - So the triangles are similar.
]

#callout[
  In similar triangles corresponding sides stand in the same ratio.
]
```]

The caption of the box follows the document language. `title:` changes it,
`title: none` leaves it off.

== The formula that rewrites itself

The same formula stands on two slides, and between them it flies -- glyph by
glyph, as far as they recognise one another. Both slides call it by the same
name; a label is all it takes.

// check: folgen
#show-code[```typ
== The ratio

#align(center, morph(<tower>, $ h / 21 = 1.2 / 0.9 $))

== Solved for h

#align(center, morph(<tower>, $ h = 21 dot 1.2 / 0.9 $))
```]

In the browser `h`, the fraction bar and the numbers travel to their new place
instead of vanishing and coming back. On paper the chain becomes the
calculation, one slide per line.

== A note only you see

`speaker-note` belongs to the slide and appears nowhere on the screen.

// check: folgen
#show-code[```typ
== The result

#statement[$ h = 28 "m" $]

#speaker-note[
  Let them work it out first, then show it. Anyone saying 28 has rounded --
  28.0 is more precise than the measurement allows.
]
```]

It appears in the speaker view -- opened in a second window with `n` -- and in
the handout, beside its slide.

== A note the room can read

`#footnote` works, and it does not look like it does in a book: the note
stands at the foot of *its slide*, under a short rule, and the numbering
starts again on every slide. A footnote on slide seven is number one there.

// check: folgen
#show-code[```typ
== The measurement

The pole is 1.20 m high#footnote[Measured at the base, not at the tip.] and
casts a shadow of 0.90 m.
```]

It reaches all three outputs: the browser, the PDF, and the handout beside its
slide. A footnote standing inside a reveal chain appears with its marker: in
the browser the note is revealed on the same step, so the foot of the slide
gives nothing away that the talk has not shown yet. And it goes with its
marker, out of a chain inside a chain as well: a `stagger` inside a version of
an `alternatives` takes its notes along when the version goes. Its place is
held from the start, so nothing jumps when it arrives.

#info[
  On a page per slide and in the handout the notes of the slide stand -- except
  those whose marker sits in a version, a stage or a stop the paper does not
  show there. Of an `alternatives` only the last version stands, and so only its
  note; the place of the others is kept free, and the numbers are the
  browser's. `pages: "step"` sets the same slide once per step, and there the
  paper shows
  what the browser reveals: a note stands on the pages on which its marker is
  revealed, with the number it has in the browser, and its place is kept free
  on the others.
]

#warning[
  A footnote carries text. Block content with an alignment of its own inside a
  note -- a displayed equation, a `figure`, an `#align(center)` -- reaches both
  outputs, but not the same place: the browser centres it, the paper starts it
  at the beginning of the line.
]

#info[
  Typst's own footnote machinery is switched off for a deck, because it cannot
  work here: it puts its entries at the foot of the *text area*, and a slide is
  a block of exactly page height that leaves nothing there. Left alone, it cost
  a three-slide deck a fourth page, with the note alone on it, before the slide
  that names it; in the browser the note appeared on no slide at all. What you
  write is unchanged -- `#footnote[…]` -- only the setting is the deck's own.
]

#warning[
  Not in a heading. A title is repeated -- as a running head above the slides
  of its section, in the contents, in the speaker view -- and every repetition
  sets the footnote again: the slides after it carried the note of their
  section title instead of their own, and their own numbering shifted from 1 to
  2. A footnote in a title stops the compilation and says so.
]

== A PDF that unfolds

`pages: "step"` sets one page per step instead of one per slide. What is not
there yet is not there yet, and what has gone is gone -- the paper turns the
way the talk does.

// check: dokument
#show-code[```typ
#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  title: [How tall is the tower?],
  pages: "step",
)

== Two ways
#stagger([The shadow], [The angle])
```]

Everything that reveals takes part: `#pause`, `anim`, `stagger`, `tiles`,
`alternatives`, `build`, `cue` and `scene` -- a scene gets one page per stop,
not one per tween frame. A piece that is not due yet keeps its space, so
nothing shifts from one page to the next.

Two things are worth knowing. A `cue` group is called out at the keyboard, so
on paper it can only follow the written order. And a camera move has no page
of its own: on paper there is no camera, so its page would stand there twice.

And two things concern the Typst document underneath. A figure, an equation and
a heading carry their label on the first page of a slide only; the pages after
it set them without. So `@fig` finds its target exactly once, leads to where the
slide opens and gives the same number as every page of it, and `query(<fig>)`
finds one per slide. A `show` rule on such a label therefore does not reach the
later pages; one on the kind, such as `show figure`, reaches all of them. Inside
a `card`, `callout`, `statement`, `fit`, `side-by-side(equal: true)` or `build`,
in a list item -- also as a point of a `cue` group -- and in a `scene-layer`,
`cue-layer` or `stagger-layer`, the label stays on every page, and a reference
to it stops the compilation: a figure that is referred to then goes beside the
card or the list rather than into it.

A deck's own `state`, on the other hand, runs on across the pages of a slide.
Every page carries out its `update` again: `Task #context task.get()` after
`task.update(n => n + 1)` counts 1 and 2 on the two pages of a slide with a
`#pause` instead of 1 twice, and the next slide says 3. The package cannot set
it back, because Typst reveals neither what a state starts from nor what an
`update` does to it. For numbering, a `counter` does the job, and the pages set
that one back; and an `update` with a value rather than a function gives the
same on every page.

Expect two to three pages per slide -- the example decks come out at that.

== The handout

One argument turns the deck into a sheet to write on: three slides per page,
the note beside each one, ruled lines beside any slide that has none.

// check: dokument
#show-code[```typ
#import "@preview/typstage:0.2.0": *
#show: presentation.with(
  title: [How tall is the tower?],
  handout: 3,
)
```]

== The whole source

Nothing in it that was not explained above.

// check: dokument
#show-code[```typ
#import "@preview/typstage:0.2.0": *

#show: presentation.with(
  title: [How tall is the tower?],
  author: [Year 9],
  theme: themes.lesson,
)

= The question

== A pole and a tower

A pole 1.20 m high casts a shadow of 0.90 m.
The tower casts 21 m. How tall is it?

== What we see

#stagger[
  - The sun stands equally high for both.
  - So the angle is the same.
  - So the triangles are similar.
]

#callout[
  In similar triangles corresponding sides stand in the same ratio.
]

= The calculation

== The ratio

#align(center, morph(<tower>, $ h / 21 = 1.2 / 0.9 $))

== Solved for h

#align(center, morph(<tower>, $ h = 21 dot 1.2 / 0.9 $))

== The result

#statement[$ h = 28 "m" $]

#speaker-note[
  Let them work it out first, then show it. Anyone saying 28 has rounded --
  28.0 is more precise than the measurement allows.
]
```]

#tip[
  Two things worth a look next: `side-by-side` -- a drawing on the left, the
  words on the right -- and `theme:`, which changes the whole look without
  moving a line of content.
]

= Revealing a slide step by step

A slide that unfolds in front of the room instead of standing there finished.

== Which tool for what

Six building blocks cover nearly everything, and they mix on one slide.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Tool*], [*For what*]),
  [`#pause`],
  [The slide unfolds from top to bottom, with nothing wrapped around anything.
   The commonest case.],
  [`stagger[…]`],
  [A list point by point, bullet and text together. Also for several blocks in
   sequence.],
  [`anim(…)`],
  [One piece on one step, with a motion of its own. The tool wherever `#pause`
   cannot reach: grid cells, tables, boxes.],
  [`alternatives(…)`],
  [Several versions of the same thing in the same place, each replacing the
   one before.],
  [`build(…)`],
  [A drawing that comes into being in stages -- one CeTZ line, one lilaq data
   series, one label after another.],
  [`scene(…)`],
  [A drawing that depends on a value. For everything that *moves* rather than
   being added.],
)

Beside them stand `tiles` for a grid that staggers itself, and `morph` for
things that fly between two slides.

== The step cursor

Every slide carries a step cursor. `at` defaults to `auto`, the next free step, so
consecutive reveals number themselves and most slides hold no number at all.
Automatic reveals start no earlier than step 2, including the first items of
`stagger`, `cue`, `alternatives`, `tiles`, `build` and `scene`. Step 1 contains
static content. Use an explicit `at: 1` or `start: 1` to show an item on entry.

#show-code[```typ
== Three things
#anim[first]            // step 2
#anim[second]           // step 3
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

A bare number is an open end: what is there once stays to the end of the slide. A
closed spelling such as `"1-2"` or `"3"` lets the element disappear again, and
then `exit` applies. A range is written from its first step to its last: a
backwards one such as `"4-2"` stops the compile, rather than never appearing in
the browser and appearing on paper all the same.

== A slide without a single number

`#pause` needs no counting. It cuts the body where it stands, and everything after
it arrives one step later:

#show-code[```typ
== What we know

The two legs carry as much area as the hypotenuse.

#pause

$ a^2 + b^2 = c^2 $

#pause

And that is enough to compute the third side from two of them.
```]

#tip[
  `#pause` splits the body, so it works between blocks but not inside a grid cell
  or a table -- there is nothing there to cut. `anim` goes anywhere content goes.
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

`stride: 2` leaves a step out between two items, `stride: 0` puts all of them on
one. `start` sets the first step, `enter` the motion, `stagger` the delay in milliseconds
between neighbours, `spacing` the distance between items, `dim` lets each point
step back once the next arrives.

#tip[
  `stagger` also takes several blocks instead of one list. Each block is then one
  step -- three paragraphs or three pictures in turn, without three `anim` calls.
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

Each point then holds its own step and rests in `after: "dimmed"` (see "The muted
resting state"). Two consequences, both intended: the last point dims too once the
slide has a step after it, and `stride: 0` dims them all together.

=== What stands beside a piece

`stagger-layer` hangs something on the step of one particular piece -- the
annotation beside a calculation, say. The stagger needs a name: `name:` says it,
and a `morph:` written as a name says it too.

// check: folie
#show-code[```typ
#stagger(morph: "rewrite",
  $ x^2 + 6x + 2 = 0 $,
  $ x^2 + 6x = -2 $,
  $ (x + 3)^2 = 7 $,
)

#stagger-layer("rewrite", 2)[$| -2$]
```]

The layer stays from its piece to the end of the slide, as `cue-layer` and
`scene-layer` do, and carries no morph name: what flies is the piece, the
annotation merely appears beside it. The stagger has to stand *before* its layers,
because a layer looks up which step its piece was given, and on the same slide: as
with `cue`, a name belongs to one slide, and a layer naming a stagger from the
slide before stops the compile.

#warning[
  `spacing:` applies to the list branch only. Where the pieces stand on their
  own, ordinary block spacing decides.
]

== Revealing in the order it is called out

Some points have no order. What a graph shows, what stands out in an experiment --
a class names those as they come, and a deck that reveals them in *its* order makes
the teacher wait or reshuffle. `cue` turns that round: the digits `1` to `9` reveal
whatever was just named.

// check: folie
#show-code[```typ
#cue("readings", start: 2)[
  - positive and negative values
  - lowest and highest value
  - falling and rising
]
```]

The group takes a name so that `cue-layer` can point at it. It owns as many steps
as it has points, whatever the order, so the progress bar, `info().step.total`, the
overflow check and the handout are untouched. The list keeps its reading order: a
point not yet named holds its place, so nothing jumps when it arrives.

A name belongs to *one* slide. The same name on the next slide is a new group
starting again at `1`, so every exercise slide can say `cue("marks", …)` without
numbering the names apart. Several `cue` calls on the same slide under the same
name do form one group and count on.

=== What appears together with a point

`cue-layer` hangs something on the same step -- a drawing layer, a picture, a
sentence beside it:

// check: folie
#show-code[```typ
#cue("readings", start: 2)[
  - positive and negative values
  - lowest and highest value
  - falling and rising
]
#cue-layer("readings", 1, [and what goes with it])
```]

The point and the layer share a step, so moving the step moves both, and you can
hang as much on a point as you like. The group has to stand *before* its layers;
otherwise the package says so.

#tip[
  For a CeTZ drawing that grows with the points, draw every layer as its own
  complete drawing and hide the rest with `cetz.draw.hide(rest, bounds: true)`, so
  that it still counts towards the bounds. All layers then lie exactly on top of
  each other and the graph holds still, in whatever order it grows. A layer carries
  *only its own contribution*, no grid and no base curve, or the layer set last
  paints over the first. Where the drawing is to grow in written order, use `build`
  instead.
]

#info[
  The forward arrow reveals the next point *not yet named*, so paging alone behaves
  like a staggered list, and arrow and digits mix freely. As long as ordinary steps
  still stand before the group, the arrow pages through those; it reaches into the
  group only once its next point is the next stop. Only when the group is full does
  the arrow carry on. One step back frees the point named last, and
  leaving the slide backwards leaves the group untouched for the next visit. In the
  speaker view every point still open stands there pale, with its digit on the
  bullet; in the hall it is invisible.
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

`enter` and `exit` name the motion. Twelve of them exist:

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

`duration` is in milliseconds and `auto` takes the presentation's. `delay` holds
the start back, which lets two elements on the same step arrive one after the
other.

*A name the package does not know is an error at compile time*, as it is for
`easing`: a typo would otherwise render as `"fade"` in silence.

// check: folie bricht=the_package_does_not_know_that_effect
#show-code[```typ
#anim(enter: "fdae-up")[A typo.]   // error at compile time
```]

=== The curve

Everything this package moves runs on one curve: slow off the mark, brisk through
the middle, soft at the end. `easing` hands a different one to a single element.

// check: folie pre=zeichnung
#show-code[```typ
#anim(result, enter: "rise", easing: "out-back")
#stagger(stride: 0, stagger: 60, easing: "out-quad")[
  - first this
  - then that
]
```]

It stands wherever `duration` stands: on `anim`, `stagger`, `alternatives` and
`build`, and it covers the entrance, the departure and the dimming. Not the slide
transition, and not the flight of a magic move, which has two ends.

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

`in` means slow off the mark, `out` soft at the end; for an entrance `out` is
nearly always right, because the eye watches the ending. *A name that does not
exist is an error at compile time*, and the message lists the choices.

// check: folie pre=zeichnung bricht=the_package_does_not_know_that_curve
#show-code[```typ
#anim(result, easing: "out-bounce")   // an error at compile time
```]

*The three `back` curves go past their mark.* On a travel that is the swing back;
on opacity the browser clips whatever reaches past 1, so `"out-back"` on a plain
`"fade"` is merely a faster `"fade"`. Use it with an effect that travels:
`"rise"`, `"scale"`, `"fade-up"`. Springs and bounces -- `elastic`, `bounce` --
do not exist here: they are not cubic Bézier curves, and the Web Animations API
knows only those.

=== The muted resting state

An element whose range ends plays `exit` and goes. `after: "dimmed"` is the other
resting state: the point stays and is drawn muted -- legible, but no longer the
thing being talked about.

#show-code[```typ
#anim(at: "2-3", after: "dimmed")[A passing remark.]
#anim(at: 4)[And on with the talk.]
```]

Nothing moves and nothing is recoloured: the element settles to 65 percent opacity
and comes back up when you page back. `after` is `"hidden"`, the default, or
`"dimmed"`.

`after` wants a range that ends *and* a step after it, or there is nothing to rest
in and no step to be seen muted on; both are errors at compile time. `at: "3"` is
that one step, `at: "2-3"` a range, and the second line above supplies the step
after it. As a list, `at: (2, 4)` shows the element on 2, hides it on 3, brings it
back on 4 and rests it dim from 5.

*On paper `after` does nothing*: a page shows every step at once, and a point that
is only quiet because the talk moved past it has no past there.

#warning[
  The 65 percent keeps dimmed body text in the `ink` colour above 4.5 to 1 on
  every bundled palette. What is already quiet becomes too quiet: `muted` text or
  a word in the accent colour falls below that. Dim a point, not a label. Over a
  `card(fill: ...)` of your own or over an image nothing is measured at all.
]

A tracked element *inside* a dimmed one inherits the dimming only if it has
exactly the same range -- the same inheritance by which `enter`, `delay` and
`duration` reach inwards. It may be *less* visible than its host, never more.

That leaves `morph`, `video`, `embed` and `flipbook` outside, because all four
default to the open range `at: "1-"`. Inside a dimmed element they keep full
strength, so a formula in a dimmed line stands black in a grey sentence. Give it
the same closed range by hand, or do not dim the line.

== Several versions in the same place

`alternatives` puts versions on top of one another. Each step shows exactly one,
the next replaces it:

#show-code[```typ
#alternatives(
  $ (a + b)^2 $,
  $ a^2 + 2 a b + b^2 $,
  $ a^2 + 2 a b + b^2 = c^2 $,
)
```]

The box is as large as the largest version, so nothing around it jumps. `align`
decides where the smaller ones sit inside it, `start` on which step the first
appears, and `inline: true` puts the whole thing in a line of text. `enter`,
`duration` and `easing` describe the change from one version to the next. A
version that reveals something of its own stays until that is done, and the
next one comes after it. That waiting needs `start: auto`: with `start` written
out, every version but the last holds exactly its own step, and a chain inside
one of them comes after its version has gone and is never seen.

`morph: true` is the other way, and for the example above it is the better
one: the versions fly into one another instead of replacing one another. They
stand in the same place, so the flight has no distance -- what you see is the
glyphs rearranging themselves where they stand, which is what a rewritten
formula does. With `morph` there is no entrance, so `enter:` and `easing:` are
refused; `duration:` becomes the time of the flight. The waiting for a chain
holds on paper only: in the browser the next version comes on the step after
the one before, even when that one reveals something of its own, and what it
reveals is never seen there.

== A drawing that grows

A CeTZ canvas and a lilaq diagram are *one* piece, not many: Typst hands out the
finished setting, and a line or a data series in it cannot be reached from
outside. So there is no `anim` around a single line of a drawing -- there is the
drawing itself, as often as you want it. `build` calls it once per step and lays
the versions exactly on top of one another: on stage #box[$k$] the drawing stands
as it looks after #box[$k$] steps, and exactly one is on show.

Which piece joins when is said by the question every stage is handed. It is called
`ab` -- "from" -- because it says what `at:` says elsewhere:

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

`from(2, black)` gives the colour back once the second piece is due, and otherwise
the same colour with alpha 0. What carries no number stands there from the start.
`steps: 4` says how many stages there are; it is said, not guessed, because nobody
can see from outside what the drawing function does with its question. `from(4)`
with a single argument is the same question as a boolean, for everything that
cannot be recoloured -- in CeTZ that is where `hide(…, bounds: true)` belongs.

Air rather than omission, because a piece left out takes its room with it and the
drawing jumps. `from` makes air out of a colour, out of a stroke (the brush goes,
thickness and dashing stay, because the measure hangs on those), out of the
colours in a dictionary, and out of content, which goes into `hide`. Not out of a
gradient -- there it says so instead.

=== A lilaq diagram

A data series turns to air in two places: at its colour and at its label in the
legend. The second is easy to forget -- the entry would otherwise stand in the
legend while its curve is missing:

// check: folie pre=lilaq
#show-code[```typ
#build(from => lq.diagram(
  width: 7cm, height: 4.5cm,
  legend: (position: top + left),
  lq.plot(x, measured, color: from(1, red), label: from(1, [measured])),
  lq.plot(x, model, color: from(2, blue), label: from(2, [model])),
), steps: 2)
```]

Because the series stays in the data as air, lilaq reckons its axes over both: the
scale is settled from the start, and the first curve does not jump when the second
arrives.

=== Stages that do not come one click after another

`steps: 4` puts the four stages on four consecutive steps. That holds as long
as the drawing grows click by click. As soon as something else happens on the
slide between two stages -- a camera move, a verdict, a second diagram beside
it -- it holds no longer: the drawing has two pictures, but the second is not
due until step 9.

`at:` names, per stage, the step it first stands on:

// check: folie pre=cetz
#show-code[```typ
#build(from => cetz.canvas({
  import cetz.draw: *
  line((0,0), (4,0))
  line((4,0), (4,3), stroke: from(2, black))
}), at: (1, 9))
```]

Two stages, the second from step 9 on; in between the first one stands. The
list's length is the number of stages, so `steps` and `start` have nothing
left to say and are refused rather than quietly ignored.

`from` keeps counting *stages*, not steps. `from(2, …)` means: from the second
picture on. Where that picture stands is said by `at:` alone. It could not be
otherwise -- under `start: auto` nobody knows while writing which step the
drawing will land on.

What this saves is not typing but work. Without `at:` the same picture needs
`steps: 9`, and stages 1 to 8 are pixel for pixel the same drawing and are all
typeset regardless. Measured on a slide carrying three diagrams that are
discussed one after another: ten sprites instead of 22, and the whole file
2.98 MB instead of 3.45 MB.

=== The arguments

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Effect*]),
  [`steps`], [number of stages, and hence of steps (default 2)],
  [`start`], [first step; `auto` follows on from the cursor],
  [`at`], [the step each stage first stands on, say `at: (1, 9)`; every stage
           holds until the next one is due. `steps` and `start` then fall
           away],
  [`enter`], [motion a stage arrives with (default `"fade"`); `"draw"` is an
              error here, see the next section],
  [`duration`], [duration in milliseconds],
  [`easing`], [the curve of the motion, see "The curve"],
)

On paper only the last stage is set, in a block of the same size. Under "reduce
motion" nothing changes: the stages fade, they do not travel.

#warning[
  Every stage really is typeset. Four stages mean four layouts and four SVG trees
  in the file -- for an elaborate drawing both grow as fast as they do for a flip
  book. A drawing in twenty stages is not a good idea.

  Hence `at:` where the stages lie far apart. What counts is the number of
  pictures, not the number of steps between them.
]

== A path that draws itself

`enter: "draw"` lets a stroke *come into being* instead of fading in: the pen is
set down and traces the path from start to end.

// check: folie pre=zeichnung
#show-code[```typ
#anim(circuit, enter: "draw", duration: 900)
#stagger(enter: "draw", stride: 1, axes, curve, tangent)
```]

Behind it lies `stroke-dasharray` on the SVG path: one dash exactly as long as the
path, slid in by `stroke-dashoffset`. `duration` applies as everywhere, but a
drawing wants more time than a bullet point -- 900 is a workable start, and the
presentation's default of 520 is tight for three long lines.

=== What can be traced and what cannot

*Text cannot.* Typst sets glyphs as filled shapes with no outline, and an area has
no length to travel along -- the same for an arrow head, a solid dot, the face of a
card. So `draw` does two things at once: *the strokes draw themselves, everything
else fades in*, over the same time. A label arrives while the lines are being drawn
and stands finished together with them.

An element on which *nothing at all* can be traced fades in completely, and the
runtime says so in the browser's console, once per element:

#show-code[```
typstage: enter: "draw" on slide 4 (element 2) finds no stroked path to
trace. What is drawn is an outline, and text has none: Typst sets glyphs
as filled shapes. The element fades in instead. draw is for a drawing,
the fade is for text.
```]

It cannot be caught earlier: Typst hands out the SVG only on export, so only in
the browser is there a path to count.

=== All at once, and how to get them one after another

Every stroked path of an element sets off *at the same time*, and there is no knob
for that: the order in the SVG is Typst's painting order, not one the deck chose.
Say the order instead, by giving each piece its own step:

// check: folie pre=zeichnung
#show-code[```typ
#stagger(enter: "draw", stride: 1, axes, curve, tangent)
```]

=== Where a drawing has to stand

*Not on the first step of its slide.* Entering a slide plays no entrances -- the
runtime only restores the state, or the transition and a dozen reveals would run
against each other. A drawing on step one would simply be there. Give it a step in
front:

// check: folie pre=zeichnung
#show-code[```typ
#anim[First the sentence that announces the drawing.]
#anim(circuit, enter: "draw", duration: 900)
```]

That holds for every effect; with `draw` it merely stands out, because there the
travel is the whole point.

=== Who delivers outlines

*Whatever gets a `stroke` in Typst becomes a path with an outline and can be
traced; whatever gets a `fill` does not.* A drawing package delivers exactly as
much as it strokes, and a slide of text delivers nothing.

That decides between `draw` and `build`. A plain CeTZ drawing strokes a handful of
paths -- a few long lines an eye can follow, which is what `draw` was made for. A
lilaq diagram strokes nearly everything, grid, ticks and markers included, and all
of it sets off at once: a diagram wiping in, not a drawing coming into being. For
a diagram, use `build`.

*Dashed lines stay with the fade.* The dash pattern lives in the very attribute
the pen needs, so a dashed guide line fades in while its neighbours draw
themselves.

=== In both directions, and what holds at the edges

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Where], [What happens]),
  [Paging back],
  [The pen traces its way out: what drew itself undraws itself.],
  [Jumping to a step],
  [No drawing. A jump -- address, overview, reload -- restores the end state,
   which is the finished drawing.],
  [`exit: "draw"`],
  [Allowed and symmetric: an element leaving its range takes its strokes back
   instead of fading away.],
  [Speaker view],
  [The preview of the next step shows the finished drawing, with no motion.],
  [Paper],
  [Nothing. `enter` never reaches the PDF.],
  [Reduce motion],
  [The pen holds still, the fade remains -- *opacity stays, travel goes*, and for
   `draw` the drawing *is* the travel. What is left is the fade that ran
   underneath it anyway, over the same duration. The console message still comes.],
)

=== Together with a drawing that grows in stages

Both at once does not work, and the package says so at compile time:

// check: folie pre=zeichnung bricht=is_at_odds_with_what_this_function_does
#show-code[```typ
#build(painter, enter: "draw")   // an error at compile time
```]

Every stage of a `build` drawing is the *whole* drawing, so a stage that drew
itself would retrace every stroke over ink already down. For strokes that come
into being one by one, hand them over as pieces of their own; for a diagram that
grows in stages, leave it with its fade.

== A drawing that moves

`build` lets a drawing grow, piece by piece. `scene` is the other half: nothing is
added, a *value* changes, and the picture hangs on it.

*The deck writes a function from a value to a picture and names the values at
which the talk stops. Typst renders every stop and the frames in between, and a
step pulls the picture from one stop to the next.*

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

`stops` are the values themselves, not `0.0` to `1.0`. That is the difference to
the flip book: there `t` is a fraction of a running time, here `x` is the quantity
being talked about. Whoever wants the tangent at $-3$, at the vertex and at $1.5$
writes those three numbers down.

The scene takes `stops.len() - 1` steps. The first stop is there as soon as the
scene appears -- like a `morph`, unlike an `anim` -- and every further stop costs
a keypress.

=== What belongs to a stop

A sentence, a formula, a second drawing: `scene-layer` puts itself on the step of
one particular stop. The scene needs a name to be found by.

// check: folie pre=szene
#show-code[```typ
#scene("derivative", x => tangent-at(f, x), stops: (-3, 0, 1.5, 3))

#scene-layer("derivative", 2)[At the vertex the slope is zero.]
#scene-layer("derivative", 4, enter: "scale")[$f'(x) = 1/2 x$]
```]

This is word for word `cue-layer`: the coupling falls out of the shared step. Move
a stop and everything hanging on it moves along, and nowhere does a number stand
twice. The scene has to stand *before* its layers.

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
*independently*. Everything travels from stop to stop together, and a tuple puts
several values on the one way.

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
with. Unlike `build`, `scene` does not stack its frames: they are drawings of
different values and may legitimately come out different sizes. So a scene stands
in a box of fixed size, every frame is clipped to it -- and every frame is
measured:

#warning[
  *The box stands still, the ink inside it does not do so by itself.* A CeTZ canvas
  grows with its content, so if the tangent at $x = -3$ reaches further left than
  the one at $x = 3$, the axis cross sits elsewhere in the box, and paging moves
  the whole picture although only one point was meant to move. Every scene measures
  its frames and says so where the sizes differ:

  #show-code(```
  error: assertion failed: typstage: 1 scene draws frames of different sizes. …
    slide 4, from step 1: 28 frames in 19 different sizes, up to 28.35pt apart across and 53.86pt down
  ```)

  The way out lies in the drawing: give it a fixed extent and keep what moves
  inside. In CeTZ that is a `rect` with a transparent stroke:

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

  That pins the width. Whatever still reaches beyond it -- a tangent running off
  the edge -- has to be cut off, or it pulls the canvas open again.

  *Where the frames are meant to differ*, say so: `steady: false` takes the scene
  out of the check. `drift` on the presentation decides what happens with the
  findings.
]

`steady: true` is the opposite commitment: the scene has to stand still, and it
stops on the spot rather than in a list at the end of the deck:

// check: folie pre=cetz bricht=this_scene_draws_its
#show-code[```typ
#scene(x => cetz.canvas({
  import cetz.draw: *
  line((0, 0), (x, 0.25 * x * x))             // pulls the canvas along
}), stops: (-3, 3), steady: true)             // error at compile time
```]

On paper the last stop is set, as with `alternatives`; `still` puts something else
in its place. The step cursor runs there too, so `info().step.total` names the same
number in both outputs. Under "reduce motion" the frames in between fall away and
the scene jumps.

=== What a scene costs

Every frame really is a Typst layout and sits in the file as an SVG tree of its
own, so compile time and raw file size grow with `tween`. Over the wire it matters
far less: the trees are so alike that gzip takes some 98 percent away. On paper a
scene costs nothing -- one still image. Measuring the frames costs one more layout
each, in the browser branch only; `steady: false` gives it back for one scene,
`drift: "none"` for all.

#warning[
  The gzipped figure holds only as long as the web server does gzip; whoever hands
  the file on by USB stick or as an attachment carries the raw one. And the compile
  time is always the full one: eight frames per stretch are eight layouts, whether
  they compress away later or not.
]

== Moving in on a detail

Sometimes the next step is not a new sentence but the same one from close up: the
one cell of the table, the one term of the equation. `camera` moves in on it and
back out again. It aims at a `pin` and at nothing else -- the package's word for a
named piece of a slide, whose rectangle the runtime measures anyway.

// check: folie
#show-code[```typ
#pin(<sensor>, card(title: [Sensor])[Thermocouple, bridge, amplifier.])

#camera(<sensor>)
#anim[And out again, on the step after.]
```]

=== How you get out again

Said, not guessed. `at` is a step selector as everywhere else, and the slide is
seen through the camera for as long as it is active:

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

The way back out is a step and is counted as one: a slide carrying nothing but a
pin and a camera has three steps -- the whole slide, the crop, the whole slide.
`info().step.total` and the handout count the same way.

#info[
  `at: auto` is a *closed* range here, while for `anim` it is open: an entrance has
  no natural end, a camera move does. And never step one -- a move there would mean
  nobody ever saw the slide whole.
]

=== What travels along and what stays put

What travels is the slide: background and the layer of revealed parts above it,
with the same transform. The furniture does *not* -- footer, page number, progress
and running header sit as their own layer above the stage, hold still while the
slide grows underneath them, and stay legible. The title travels; it stands in the
body, and so does a footer built by hand into the body. What leaves the frame is
cut at the edge of the stage, and drawn ink stays put.

=== How far it goes

`margin` says how much of the slide stays around the detail, measured on the
*unzoomed* slide (16 pt by default). The camera fits detail plus margin into
the frame, and the tighter direction decides, so the whole of it is seen. The
move takes `duration` milliseconds, 700 by default, and `easing` bends it.

// check: folie
#show-code[```typ
#pin(<term>, $b^2$)
#camera(<term>, margin: 4pt, duration: 900, easing: "out-quad")
#anim[After that.]
```]

There is no upper limit. A pin the size of a comma is shown the size of a wall,
and what Typst set stays sharp, because it stands there as vectors; a video, an
image or an embedded document will not. A detail already as large as the slide
gives nothing to travel to.

=== Two special cases

*Two pins of the same name on one slide.* The camera frames the box around both.

*Two moves overlapping on one step.* The later one in the source wins.

=== On a jump, paging back, and on paper

The crop is a function of the step and nothing else:

- *Paging back* runs the way in reverse and lands on the whole slide again.
- *A jump* -- overview, `#3` in the address, a click in the speaker view -- sets
  the crop instead of travelling to it.
- *The speaker view* shows the running slide with its camera, and the preview
  beside it carries the crop along: its question is "what stands there after the
  next keypress".
- Under *reduced motion* the camera jumps to the crop.

#warning[
  *On paper there is no camera.* The handout sets every slide whole, and so does
  the browser's print view. A duty follows: *the slide has to be complete and
  legible without the move.* Whoever labels the detail only for the crop -- a
  6-point line, since we are going to move in on it anyway -- has a line on paper
  that nobody reads. The camera is an emphasis, not a layout.
]

=== When the name is not there

A camera aiming at a `pin` that does not exist on its slide is an error at
compile time:

// check: folie bricht=finds_no_pin_of_that_name
#show-code[```typ
#pin(<sensor>, card[…])
#camera(<senor>)            // one letter short
```]

The question is asked at the end of the document, not on the spot: a move may
stand before its target, and what stands on a slide is only settled once the slide
is set. A pin on the slide *before* does not count.

One case stays open: a pin inside an `anim` not revealed on this step has a
rectangle but nothing visible in it, and the camera moves in on an empty place.
Which step shows what is decided in the browser.

== Three stumbling blocks

*Only reveals count.* The cursor counts `anim`, `stagger`, `alternatives` and
`#pause` -- everything that makes something appear. An applet, a video or a `morph`
uses up *no* step and is there from the beginning. That matters in a two-column
slide: the bullets beside an applet should start at one, not behind its motions.

#show-code[```typ
#side-by-side(
  embed(url: "…", width: 100%, height: 220pt),   // no step
  stagger[
    - first bullet                               // step 1
    - second bullet                              // step 2
  ],
)
```]

That holds as long as `at` keeps its default. Give a video, an embed, a flip
book or a `morph` an `at` past step one and it *appears*, so it counts like an
`anim`: the slide has at least as many steps as the `at` names, and whatever
follows with `auto` comes after it.

#show-code[```typ
#video("experiment.mp4", at: 2)   // step 2
#anim[What we see]                // step 3
```]

*A step is not inherited inwards.* Every tracked element carries its own step, and
one sitting inside another still follows it:

#show-code[```typ
#anim(at: 3)[From step three, #morph(<m>, $x^2$) but from step one.]
```]

With `morph` that is right: the *target* of a flight has to be standing when the
slide is entered, or the flight from the previous slide arrives nowhere. With an
`anim` inside an `anim` it is usually an oversight, noticed only while paging.

*A morph stands from the first step.* So a morph does not belong inside something
that only appears later. Put it in a tile that arrives on step two and it hovers
alone on step one, where its container will only later turn up.

= Showing instead of claiming

Three ways to make a slide demonstrate something rather than assert it, from
the most involved to the simplest.

== A document of your own on the slide

#info[
  If that document is itself a Typst document, none of this is needed. Give
  its content a name and fetch it:

  // check: aus=zeigt_zwei_Dateien
  #show-code[```typ
  // map.typ -- still compiles on its own, with its own page
  #let map = [ ... ]
  #set page(width: 16cm, height: 8.2cm)
  #map

  // talk.typ
  #import "map.typ": map
  == The map
  #map
  ```]

  The `set page` stays behind, the slide keeps its geometry. What arrives is
  the deck's own content: the same fonts, sharp at any size, part of the PDF,
  and revealable step by step. Under `typst watch` (see *While you write*) a
  save in `map.typ` rebuilds the deck and brings it back on the same step. A
  frame can do none of that.
]

YouTube videos can use `embed(url: "https://www.youtube.com/embed/VIDEO_ID")`
or the `www.youtube-nocookie.com` domain. Presenter play/pause, timeline and
`j`/`k`/`l` control the stage; the preview follows muted. The external YouTube API
loads only when a YouTube embed becomes visible. Internet and a deck served over
HTTP(S) are required; `file://` can cause error 153. If autoplay is blocked,
click Play on the stage once.

`embed` puts arbitrary HTML into a sandboxed frame:

#show-code[```typ
#embed(html: "<div id=lamp></div><script>…</script>",
       width: 100%, height: 190pt)
```]

`url:` takes a foreign address instead.

#tip[
  Size everything inside in `em`. Inside a zoomed frame one CSS pixel is one
  point of the slide, so `em` scales with the slide and `px` does not. A page
  that reflows on its own wants `zoom: false`.
]

`style: false` drops the deck's basic style where the embedded document brings
its own. `fallback` stands on paper in the frame's place, `link` is the
address printed beneath it.

== Sending it something on a step

A frame with a `bridge:` argument gets a name; `bridge-job` sends it a
dictionary when a step arrives:

#show-code[```typ
#embed(html: "…", bridge: "lamp", width: 100%, height: 190pt)

#bridge-job("lamp", (color: "#16a34a"), at: 2)
#bridge-job("lamp", (color: "#eb5e28"), at: 3)
```]

The package never reads a job; the document on the other side interprets it.
That is how the `ggb-` commands drive their applets — see the chapter
*GeoGebra*.

#warning[
  The document has to announce itself once with
  `postMessage({typstage: 1, ready: 1})`. Until it does, it gets nothing.

  Paging back replays the whole run with a `reset`, so a job has to be
  repeatable: "set the colour to green" survives that, "make it greener" does
  not.

  Two frames sharing a name both receive every job, and the runtime says so in
  the console. `bridge-targets()` reports the names on the current slide.
]

== Audio and media clips

`audio` accepts a local file beside the HTML or a direct HTTP(S) audio URL.
It starts manually by default. Audio, video and YouTube accept `start` and
`end` in source seconds; `loop: true` repeats only that segment.

// check: folie
#show-code[```typ
#audio("music.mp3", start: 30, end: 75, loop: true)
```]

// check: folie
#show-code[```typ
#video("film.mp4", start: 30, end: 75, loop: true)
```]

// check: folie
#show-code[```typ
#embed(url: "https://www.youtube.com/embed/M7lc1UVf-VE",
       start: 30, end: 75, loop: true)
```]

The presenter has playback controls and a draggable timeline. `k` plays or
pauses; `j` and `l` seek ten seconds within the segment. `Shift+L` changes the
presenter's light/dark appearance. YouTube requires HTTP(S) and internet access.
Its control bar is hidden by default; `?controls=1` in its URL restores it.
Titles, branding and stream quality remain controlled by YouTube.

A class timer can play an optional signal on the stage when it reaches zero:

#show-code[```typ
#show: presentation.with(room: (
  clock: (step: 5, sound: "gong.mp3"),
))
```]

`sound` accepts a file or direct URL; `none` keeps the timer silent. Browser
audio permissions apply. Use `speaker-view: (shortcuts: false)` to start with
shortcut help hidden; `h` or the `?` button toggles it without reserving space.

== Video

// check: folie dateien=still.png
#show-code[```typ
#video("clip.mp4", width: 100%, height: 260pt, poster: image("still.png"))
```]

The file travels beside the HTML, not inside it. `autoplay`, `loop`, `muted`
and `controls` are the usual switches; `poster` stands there before it runs and
takes its place in the PDF. The frame crops rather than stretches.

=== A video that ends on the bell

A music video runs before the lesson, and it should stop at the moment the
lesson begins. `ends-at` says not when it starts but when it is to be over:

// check: folie
#show-code[```typ
#video("intro.mp4", width: 100%, height: 100%, muted: false, ends-at: "08:15")
```]

On entering the slide the runtime reads the video's own length and starts it far
enough in that its last frame falls on that minute. Unlock the room at 08:11 and
you get the last four minutes; arrive at 08:07 and you get the last eight.

- If the bell is further away than the video is long, it waits on its first
  frame and starts by itself when its moment comes.
- More than an hour away, or an unreadable time: there is no plan and the video
  plays from the start. That covers two cases in one sentence -- the machine
  left on overnight, and the minute after the bell, where "the next 08:15"
  would mean twenty-three hours.
- Blacking out and coming back re-computes instead of resuming. Forty seconds
  of black would otherwise move the end by forty seconds.

The clock is the room's, not the talk's. To move a lesson from the first period
to the third, `room: (bell: …)` is one line rather than one per video:

// check: dokument
#show-code[```typ
#show: presentation.with(room: (bell: "09:50"))
```]

A `video(ends-at: auto)` then takes its time from there.

#warning[
  A video with sound does not start on its own -- browsers allow that only
  muted. One click or keypress in the window releases it, and the next one
  runs.
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

The function receives `t`, running from 0 to 1, and is called once per frame.
It can draw with anything Typst has, CeTZ and Fletcher included, and every
frame sits in the file as SVG. This is the tool for motion Typst can draw and
CSS cannot: a traced curve, a turning mechanism.

`loop`, `pingpong` and `still` decide how it plays and which frame stands on
paper. A viewer who has asked for "reduce motion" never sees it play.

The clock starts when the flip book becomes visible: `flipbook(at: "3-")` lies
on frame 0 until step 3, then plays from zero -- again on every fresh reveal.

#warning[
  Every frame is typeset separately: twenty-four frames are twenty-four
  layouts and twenty-four SVG trees in the file. This is the most expensive
  element in the package. Reach for it only where the motion carries the
  argument.
]

= GeoGebra

GeoGebra builds the construction, the slides supply the dramaturgy. A job can
sit on every step: set values, show or hide objects, change colours, move the
viewport, start a motion.

== Quick start

`geogebra()` puts an applet on the slide. The commands that drive it stand in
the same slide body and produce no output of their own.

#show-code[```typ
#import "@preview/typstage:0.2.0": *

#presentation(
  slide([Remote controlled], {
    geogebra(app: "classic", perspective: "G", height: 240pt,
             link: "https://www.geogebra.org/calculator")
    ggb-run("a=1", "f(x)=a*x^2")
    ggb-set((a: 3), at: 2)
  }),
)
```]

The parabola is there from the start; on step 2 `a` becomes 3.

Every command takes `at`, the step selector known from `anim`; the default is
`"1-"`. The applet frame has no step of its own, so bullet points beside it
still start on step one.

#info[
  The applet lives in the HTML export only; for the PDF see _On paper_.
]

== Which applet is meant

With one applet on the slide the commands find it themselves. Two applets need
names, and the commands then need `target` — a string or a label:

#show-code[```typ
#geogebra(<left>, height: 200pt)
#geogebra(<right>, height: 200pt)
#ggb-run("A=(0,0)", target: <left>)
#ggb-run("B=(1,1)", target: "right")
```]

With no applet, or with more than one and no `target`, nothing is guessed. The
build stops and names what it found:

#show-code[```
error: panicked with: typstage: 2 applets on this slide
(left, right) — say which one is meant, e.g. target: "left".
```]

== Building the construction

`ggb-run` hands GeoGebra commands to `evalCommand`, one at a time. The order
counts: whatever is needed has to exist first.

// check: folie drin=applet
#show-code[```typ
#ggb-run(at: "1-",
         "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
         "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
```]

#warning[
  GeoGebra's scripting commands — `SetColor`, `SetValue`, `SetVisibleInView` and
  their relatives — are *not* accepted by `evalCommand` and come to nothing
  inside `ggb-run`. Use `ggb-set`, `ggb-style`, `ggb-show` and `ggb-hide`
  instead. Rejected commands land in the browser's console.
]

Entering a slide and paging back reset the applet and repeat the run, so
commands have to be repeatable. Fix the colour on `"1-"` for the same reason:
on a rebuild GeoGebra would otherwise hand out the next colour of its palette.

// check: folie drin=applet
#show-code[```typ
#ggb-run("a=1", "f(x)=a*x^2", at: "1-")
#ggb-style("f", at: "1-", color: dark, thickness: 3)
```]

#info[
  A `.ggb` file cannot be embedded: Typst has no way to inline binary data into
  the HTML. Build the construction with `ggb-run`, or load it from GeoGebra
  through `material`: `geogebra(material: "abc123xy")`.
]

== Values, appearance, viewport

`ggb-set` takes a dictionary of object name and value, `ggb-show` and `ggb-hide`
any number of object names. Build everything at the start and reveal it when its
turn comes:

// check: folie drin=applet
#show-code[```typ
#ggb-hide("P", "s", "t", at: "1-")
#ggb-show("P", "s", at: 2)
#ggb-set((a: 3), at: 2)
#ggb-set((a: -2, b: 0.5), at: 3)
```]

=== Appearance

`ggb-style` takes the object names and the settings to change. What is not named
stays as it is.

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

`color` takes a Typst colour, so the construction carries the colours of the
slides instead of GeoGebra's palette.

// check: folie drin=applet
#show-code[```typ
#ggb-style("P", at: 2, color: accent, point-size: 6)
#ggb-style("s", at: 2, color: dark, thickness: 3)
#ggb-style("d", at: 3, color: accent, filling: 0.18, thickness: 4)
```]

#warning[
  `position` counts in coordinates of the plane, except for a slider made with
  `Slider`: that one sits at an absolute place on the screen and counts in
  pixels. Two sliders both written as `(-3.9, 2.2)` land in the same corner.
]

=== Viewport

`ggb-view` sets the visible range as well as the grid and the axes. `x` and `y`
take effect only together; each is a pair of smallest and largest value.

// check: folie drin=applet
#show-code[```typ
#ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
#ggb-view(at: 3, axes: false)
```]

#warning[
  `ggb-view` sets x and y separately, so a range that does not match the shape
  of the box stretches one axis and a circle becomes an ellipse. Where the
  geometry carries the argument, give the box a fixed size and match the ranges
  to its proportions.
]

Without `ggb-view` the visible range follows from `width` and `height`.

== Motion

Two ways to set something moving, and they do different things.

`ggb-animate` starts GeoGebra's own animation: back and forth without end until
the slide is left. `trace` switches on the trace of the named objects, `speed`
sets the pace, `playing: false` stops it.

// check: folie drin=applet
#show-code[```typ
#ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
```]

`ggb-tween` moves a value once from A to B and stops. Everything that depends on
it follows along — a segment whose endpoint travels, an arc whose angle grows —
and that is how a construction draws itself. `from` gives the starting value,
`duration` the time in milliseconds, `easing` the shape.

// check: folie drin=applet
#show-code[```typ
#ggb-run("t_1=0", "s=Segment(A,(4*t_1,0))", at: "1-")
#ggb-tween("t_1", at: 2, to: 1, duration: 700)
```]

#warning[
  `ggb-tween` needs a step number, not a range: `at: 2`, not `at: "2-"`.
  Otherwise the build stops with "`ggb-tween() needs a step number`".

  A tween on step 1 never arrives as motion: on entering a slide the runtime
  replays the run up to the current step at once, and tweens jump to their
  target value. Step 1 builds up, drawing starts at step 2.
]

From the next step on the value sits on its target, so paging back shows the
finished drawing instead of the motion again.

== On paper

There is no applet in the PDF. A labelled placeholder keeps the size of the
frame, and `link` puts the way to the live applet beneath it.

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

Better is a drawing of your own. `fallback` takes any content: an image, a
table, above all a drawing with CeTZ.

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
  Where the applet runs through several states, the better stand-in is the whole
  run as a row of pictures, not a photograph of one step.
]

Both take effect in the PDF only.

== How the applet looks

`seamless: true`, the default, takes the frame off the applet and puts its
drawing area in the colour of the slide. It then looks like part of the slide
rather than a window inside a window. `background` sets that colour.

#show-code[```typ
#geogebra(height: 240pt, background: rgb("#f4f1ea"))
#geogebra(height: 240pt, seamless: false)   // with GeoGebra's own frame
```]

`background: auto`, the default, takes the paper of the theme in force, so an
applet on a dark theme comes up dark.

#warning[
  The viewport cannot be dragged by hand, and that is the default: whoever
  reaches beside the point during a talk would otherwise push the whole plane
  away. `pan: true` gives dragging and zooming back; points and sliders can be
  dragged either way.
]

`font-size` counts in points of the slide, like `width` and `height`, so the
applet's font grows with the slide instead of staying physically the same size
on a projector. The default is 17, one above GeoGebra's 16.

#warning[
  GeoGebra snaps the font size to steps, so neighbouring values often come out
  at the same height.
]

#show-code[```typ
#geogebra(height: 240pt, font-size: 22)      // larger axis numbers
#geogebra(height: 240pt, pan: true)          // viewport by hand
```]

`grid` and `axes` follow GeoGebra's own default while they are `auto` and force
one or the other otherwise. `perspective: "G"` shows the graphics view alone,
`app` chooses the GeoGebra app (default `"classic"`), `language` the interface
language, and `animation-button` shows GeoGebra's play button.

=== Size

`width` and `height` count in the measurements of the slide, not in screen
pixels, and `width: 100%` is the usual case. What keeps every window showing the
same crop is the visible range: it is set from the box the first time the applet
appears, and after that `ggb-view` decides.

#tip[
  Two applets side by side sit best in a `grid`, each with `width: 100%` and a
  height of its own.
]

== From the speaker view

The speaker window runs a copy of every applet. `m` switches its pointer from
the pen to the embedded frame; the applet in front of you is then the live one,
and the copy on the canvas follows what you do to it.

Only what a hand has touched travels: a dragged point, a slider, the panned
view. Creating, deleting or renaming sends the whole construction. An animation
running on both sides sends nothing.

#warning[
  A step change resets both copies and replays the jobs of the slide. A change
  made by hand lives as long as the step does. Where a position is meant to
  stay, it belongs in the deck with `ggb-set`.
]

#tip[
  Pin down whatever is not meant to move: `ggb-style("A", "B", fixed: true)`
  nails the points that merely span a construction. Otherwise a hand in the talk
  easily takes the wrong one — with Thales, the diameter instead of the point on
  the half circle, and the whole arc travels with it.
]

`Point(k)` is a point on the path that a hand can take; `Point(k, 0.3)` is
pinned to that parameter and cannot be dragged at all. Where it should start is
said with `position:`. `examples/geogebra-sprecher.typ` is a deck built around
exactly this: Thales with a point that walks along the half circle and leaves
its trace, and a parabola with two sliders.

=== The keyboard

Click the applet and it holds the focus; every key then lands inside it. The
keys the talk uses are handed back out of the frame — see "A frame that has the
focus". Without a toolbar and without an algebra input, no key changes the
construction anyway.

== Whose applet this is

This package does not ship GeoGebra. The browser fetches what runs in the frame
from `codebase`, `https://www.geogebra.org/apps/` by default. Three things
follow:

+ *Without a network the frame stays empty.* Whoever presents offline puts
  GeoGebra's files beside the deck and points `codebase` at them.
+ *The applet stands under GeoGebra's terms*, not under this package's MIT
  licence, which covers the Typst and runtime code here. For commercial use,
  read GeoGebra's.
+ *The viewer's browser talks to `geogebra.org`.* Where that is unwanted — a
  firewall, a data protection requirement — `codebase` sends it elsewhere.

#info[
  On paper none of this is left: the PDF fetches nothing.
]

= Desmos

The same road as GeoGebra, a different calculator. Everything the previous
chapter says about the bridge -- step selectors, choosing a target,
repeatability -- holds here unchanged; this chapter names only what differs.

The difference at the core is the language: GeoGebra takes commands, Desmos
takes *expressions*. Each carries an `id`, and the same `id` again replaces
the expression rather than adding a second one. That is how a curve moves
across the steps.

== The key

`api-key` is required. Desmos serves its script only against a key -- without
one the server answers 403 and the frame would stay empty.

For trying things out there is `demo-key`, which Desmos names for that purpose
in its own documentation. It works, but the script says in the browser console
where you stand:

#show-code[```
This page is using the Desmos API with a trial key suitable for prototyping,
not for commercial use.
```]

#warning[
  Giving a talk on that key means working outside what it is meant for. A key
  of your own comes from #link("https://www.desmos.com/my-api"). And it stands
  in the HTML in plain text -- a deck you hand on or put online hands the key
  on with it.
]

== Quick start

// check: dokument
#show-code[```typ
#import "@preview/typstage:0.2.0": *

#presentation(
  slide([A parabola], {
    desmos(api-key: demo-key, height: 300pt,
           expressions: (a: "a=1", kurve: "y=a x^2"),
           bounds: (-5, 5, -2, 12))
    dsm-set(("gerade": "y=2x"), at: 2)
  }),
)
```]

`expressions` is the opening picture, `bounds` the viewport as
`(left, right, bottom, top)`. On step 2 a line joins it.

An expression with `=` is a slider, one without is a curve; Desmos decides
that, not this package.

== Showing, hiding, removing

// check: folie drin=rechner
#show-code[```typ
#dsm-hide("gerade", at: 3)
#dsm-show("gerade", at: 4)
#dsm-remove("gerade", at: 5)
```]

The difference matters more than it looks: a hidden expression stays in the
calculator and keeps computing, so whatever depends on it still holds. A
removed one is gone, and everything that names it goes with it.

== Appearance and viewport

`dsm-style` takes Desmos' own keys. `color` takes a Typst colour, so the curve
can carry the palette of the slide.

// check: folie drin=rechner
#show-code[```typ
#dsm-style("kurve", color: rgb("#eb5e28"), line-width: 3, at: 2)
#dsm-view(bounds: (-2, 2, -1, 4), at: 3)
```]

`dsm-view` moves the viewport and switches grid, axes and axis numbers. What
`desmos()` is given at build time holds at the start; what `dsm-view` sends
holds from its step on.

== Motion

Two ways, and they do different things.

`dsm-animate` switches on Desmos' own slider animation. It runs at Desmos'
speed and without a destination, back and forth until someone stops it --
right for a picture that should breathe.

`dsm-tween` pulls a slider from one number to another and leaves it there --
right for a step that shows something.

// check: folie drin=rechner
#show-code[```typ
#dsm-tween("a", to: 3.0, at: 2, duration: 900)
#dsm-animate("b", at: 4, min: -3, max: 3, step: 0.1)
```]

#warning[
  On `dsm-tween`, `at` is a *step number* and not a selector, and that is
  deliberate. The motion sits on exactly that step; from the next one the
  command simply sets the end value. Were it "from step 2 on", it would start
  again on every further step of the slide -- measured, the slider jumped back
  from 3 to 0.75 and grew again.
]

== On paper

As with the applet next door: the calculator lives in the HTML only. The PDF
shows what `fallback` says, and without a `fallback` the space stays empty. A
picture of the finished graph is usually the better answer there than an empty
box.

== Whose calculator this is

The frame fetches Desmos from `desmos.com` when the slide is shown. Without a
network it stays empty, the viewer's browser talks to that host, and what runs
inside is under Desmos' terms rather than this package's MIT licence. The PDF
fetches nothing.

A deck that never calls `desmos` carries none of it: boot script and frame
document sit behind the call.

= Developing a calculation

An equation that rewrites itself in front of the room instead of being replaced
by the next one.

== One name, two slides

The same name on two slides, and the thing flies across:

#show-code[```typ
== Step 1
#morph(<term>, $ (a + b)^2 $)

== Step 2
#morph(<term>, $ a^2 + 2 a b + b^2 $)
```]

The name is a string or a label; the runtime pairs the glyphs at both ends and
moves each one to its new place.

== And on one slide

A morph flies between two steps, and two steps of one slide count for as much as
two slides. Use two calls of the same name with ranges that do not overlap:

#show-code[```typ
== Completing the square

#statement[#morph(<sq>, $ x^2 + 6 x $, at: "1")]
#statement[#morph(<sq>, $ (x + 3)^2 - 9 $, at: "2-")]
```]

The second call gives the slide its second step: with an `at` past step one, a
morph counts like an `anim`.

The name also has to be free on the slide before: a morph that starts after step
one may not share its name with one on the previous slide. The package says so
while compiling. A chain counts as one: where one morph of the name stands from
step one, the flight across the edge lands there, and the later ones follow on
their own steps.

#tip[
  Two versions in the same place fly no distance at all, and all you see is the
  glyphs rearranging themselves -- often exactly right. To see movement, put the
  two versions one above the other.
]

== Two shorthands for the common case

`alternatives(morph: true)` lets its versions fly into one another instead of
replacing one another:

#show-code[```typ
#alternatives(morph: true,
  $ (a + b)^2 $,
  $ (a + b)(a + b) $,
  $ a^2 + 2 a b + b^2 $,
)
```]

`stagger(morph: true)` is the chain where every line stays: the new line grows
out of the line above, which stays put. Paging back takes the same way in
reverse: the last line flies back into the one it grew out of instead of fading
out.

#show-code[```typ
#stagger(morph: true, spacing: 14pt,
  $ x^2 + 6 x + 2 = 0 $,
  $ (x + 3)^2 - 7 = 0 $,
  $ x = -3 plus.minus sqrt(7) $,
)
```]

Both take a name of your own instead of `true`. That is needed only where the
flight carries on past the edge of the slide.

#warning[
  A morph has no entrance, so both refuse `enter:` and `easing:` rather than
  quietly dropping them, and `stagger` also refuses `dim:` -- an argument
  `alternatives` does not have. `duration:` is read, and it is the time of the
  flight.
]

== How the pairing works

`match: "auto"` compares the outlines: two glyphs of the same shape find each
other, and where that is not enough, proximity decides. `"glyph"` forces it per
glyph, `"block"` moves the whole thing as one rectangle.

`"auto"` pairs per glyph as long as neither side carries more than 120 glyphs,
and moves the whole thing as one block above that. The limit is a question of
looks and of cost: every glyph costs two ghosts, and a very long formula taken
apart character by character reads as a swarm rather than as a movement.
Measured in Chrome on a 1600-pixel stage: 51 glyphs fly without dropping a
frame, at 121 glyphs one frame goes, at 261 the flight stalls for 117 ms. A
deck of long formulas sets the limit itself:

#show-code[```typ
#show: presentation.with(morph: (glyph-limit: 400))
```]

Whatever carries a name travels regardless. A `pin` says outright that two
pieces belong together, and that holds above the limit too: there the named
pieces fly and everything else changes in place.

A `pin` may hold several glyphs -- `#pin(<s>, $sum_(i=1)^n$)` -- and they
travel together: each glyph of the group finds its counterpart within the group
on the other side, sigma to sigma and limit to limit. As long as the group is
arranged the same way over there they move as one piece; where it is arranged
differently, each glyph goes to its own new place.

#tip[
  `"block"` is the right answer more often than it looks. A picture or a table
  has no glyphs worth pairing, and per-glyph matching there gives a swarm rather
  than a movement.
]

Source order decides what lies #emph[on top], at rest and in flight: what is
written after the `morph` lies above it. A caption need not wait for the picture
to land.

== When the wrong signs fly

Where the pairing goes astray, name the pieces. Matching `pin` names find each
other before the shape is consulted:

#show-code[```typ
#morph(<term>)[$#pin(<factor>)[3] x^#pin(<power>)[4]$]
// and on the next slide
#morph(<term>)[$#pin(<power>)[4] dot #pin(<factor>)[3] x^3$]
```]

A pin without a counterpart on the other slide falls back to shape matching
without complaint.

== Duration and the first link

`duration` is 900 ms rather than the presentation's, since a flight takes longer
than a fade-in; `auto` falls back to the presentation's value.

A morph is present from the first step, at both ends of a chain, since paging
back swaps the roles. Only the *first* link may be delayed, because no flight
arrives there; the package checks that at compile time.

== Where the magic move stops

Two targets on the *same* slide may share a name. Both then start from the same
place, and the glyph visibly splits in two.

#warning[
  A morph is typeset a second time, in a frame of its own, and that frame never
  sees a `#set` rule written in the document. Shared typography belongs in
  `style:` on `presentation`. This is the most common reason for a flying
  equation in the wrong font.
]

== How the slide itself changes

`transition` decides how a slide comes in. The presentation sets the default,
and a single slide may differ:

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

*The transition belongs to the boundary between two slides, not to the direction
of travel.* What counts is the setting of the later slide; backwards it runs
mirrored rather than again.

*Where a morph meets the slide, it cross-fades.* Otherwise the slide would push
away the very object flying across it. A chain of transformations therefore
needs no transition switched off by hand.

== In the middle of a movement

A reveal takes half a second, a flight close to one, a slide change a short
half. Anyone presenting briskly presses the next key while that is still
running, and it must not break anything.

Paging on interrupts without a jump: the new movement starts where the picture
stands, not at the value the old one started from, and it gets the time the
rest of the way is worth -- interrupt at four fifths and you see the last
fifth, not the full duration over again.

Paging back reverses. A running reveal, a running flight and a running slide
change continue backwards instead of starting afresh: the ghost travels back
along its path, the slide slides back where it came from. The time already
spent is the time the way back still needs.

#info[
  Under `prefers-reduced-motion: reduce` there is nothing to interrupt: the
  picture changes without movement there.
]

== When the content runs past the slide

A slide is a viewport. The body is laid out on a canvas, and normally the two
are the same size: what fits on the slide stands on it.

Where the content reaches further, the canvas grows with it -- without a
measure for it written anywhere. Two things make it grow:

/ A flow that runs on: a calculation continuing line by line, a list longer
  than the slide. The canvas grows downwards.
/ A `place` at the top level of the body: a box with `dx: 780pt` stands beside
  the slide. The canvas grows sideways.

In the talk the stage shows the viewport, and the view follows whatever is
being revealed: as long as the new step is in sight the picture stands still;
as soon as it would run out of the bottom, the view pans after it. The slide's
head -- band or title line -- does not travel along. It sits as its own layer
above the canvas so the title stays put while the calculation passes under it.

#show-code[```typ
== A calculation, step by step
#stagger(dim: true)[
  $ 3x + 5 = 20 $
][
  $ 3x = 15 $
][
  $ x = 5 $
][
  // … and so on, past the slide
]
```]

On paper there is nothing to pan. There the whole canvas goes onto the page,
fitted and centred, with a line underneath saying what happens in the talk:
"canvas 1 × 1.29 slides, panned in the talk". The same holds for the handout
and for `pages: "step"` -- a slide larger than its viewport stands complete in
its frame there too.

#info[
  *Only a `place` at the top level counts.* One inside a `box`, a grid cell or
  an `anim` measures its offset against that container, and from the outside
  the two cannot be told apart. To put something beside the slide, write the
  `place` straight into the slide body. Its anchor counts: `place(bottom +
  right, dx: 20pt)` stands 20pt beyond the bottom right corner of the body,
  not 20pt beyond the top left one. A `place` without an anchor stands at its
  spot in the flow, which cannot be known from outside; it counts as
  `top + left`.

  *The overflow check still reports it.* It asks whether the body runs past
  the viewport, and here it does. It is off by default (`overflow: "none"`);
  whoever switches it on wants exactly that answer. Where the panning is
  wanted, leave it off.
]

= Giving the talk

Everything that happens between opening the file and the last slide, including
the second window.

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
  [`?`], [a line with the main keys; the deck's sound keys stand in the
    speaker view's key row],
  [`n`], [open the speaker view, or bring the talk forward],
  [`1` to `9`, `0`], [the class clock for that many minutes, `0` ends it; on
    a slide with a `cue` group the digits call its points],
  [the deck's sound keys], [play their sound in the hall, see "A sound on a
    key"],
)

A click pages forward, a click in the left quarter pages back. The address bar
carries the running step, `#12` being the twelfth, so a reloaded window stands
in the same place and a number typed by hand jumps there.

In the overview a tile is split. The upper two thirds belong to the slide: a
click there goes to its *first* step. The lower third holds one field per step
-- hovering shows that step in the thumbnail, clicking goes straight to it. The
marks stand there always, not only on hover: whoever wants the start of the
slide can see beforehand where not to aim. A slide that reveals nothing has
nothing to choose and gets no fields.

=== A frame that has the focus

Click an embedded frame and it holds the focus: every key then lands inside it
and the talk stops paging. The talk's own keys are therefore handed back out of
the frame, under three conditions -- the embedded document has not already taken
the key, the key is one the talk uses, and the focused element is not a text
field. Otherwise an `n` typed into a form would open a second window.

Everything else stays with the frame. `Delete` is the example: it belongs to
whatever is embedded, and the talk never sees it.

== On a phone or a tablet

A tap pages, in the same two halves as a click. A swipe pages in the natural
direction: the finger pushes the slide out to the left, so the next one comes.
Vertical swipes and two fingers are left to the browser: one is scrolling and
the other is zooming.

== The speaker view

`n` opens the same file a second time, with `#speaker` on the address, in a
second window: one for the projector, one for the machine in front of you. The
two talk over `postMessage`, which works between two local files, so no server
is needed.

The view is a lectern made of tiles. The running slide stands on top, across
the whole width; under it the note, and beside the note the next step; under
those a row of four small tiles:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Tile*], [*What stands in it*]),
  [elapsed], [the time since the first keypress, and small below it the time
    of day],
  [slide], [slide #sym.slash slides, below it step #sym.slash steps, and the
    progress bar along its foot],
  [target (min)], [the planned duration -- `d` goes into it --, below it
    remaining and pace, once one is set],
  [class clock], [the clock that stands on the wall in the hall; `t` starts it],
  [next step], [the preview: what the next keypress does],
)

The seam between the slide and the note is a handle: drag it down for more
slide, up for more note. Tab reaches it; the arrow keys then move it by 16
pixels, by 64 with Shift, `Home` and `End` take it to the stops, and a
double-click or `Enter` puts it back. A reload keeps the split. A second divider sets the notes/next-slide width
ratio independently of slide height. `h` or the `?` button toggles the shortcut
bar; `speaker-view: (shortcuts: false)` hides it initially. Presenter media
controls provide playback buttons and timelines for video and audio. A deck without
notes has nothing to divide and gets no handle.

Under the tiles the tool row -- pen, pointer and eraser, the four colours, undo
and clear, light or dark --, and under that the key row with every key of the
view, the deck's sound keys at its end. The state of the hall -- `black`,
`frozen`, `no talk window` -- stands at the top right inside the slide tile.

The keys of the view, which `?` also shows inside it:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Key*], [*What it does*]),
  [`←` `→`], [one step; `Home` `End` to the first or the last],
  [`↑` `↓`], [scroll the note],
  [`o`], [the overview],
  [`b`], [black out the hall],
  [`e`], [freeze the hall on this step],
  [`n`], [bring the talk window forward],
  [`1`…`9`], [that many minutes as a clock on the slide; `0` ends it],
  [`t`], [the class clock, full screen in the hall],
  [`⇧t`], [the same clock, but on the slide instead of over it],
  [`⇧←` `⇧→`], [one minute less or more, while a clock runs],
  [`d`], [the target duration in minutes],
  [`r`], [set the elapsed time back to zero],
  [`m`], [switch between pen and pointer],
  [`c`], [the next drawing colour],
  [`z`], [take back the last stroke],
  [`x`], [clear the strokes on this slide],
  [`⇧L`], [light or dark, for the view alone],
  [`h`], [toggle the shortcut bar],
  [`k`], [pause or resume video and audio],
  [`j` `l`], [seek ten seconds backward or forward],
  [`+` `-`], [the size of the note],
  [`f`], [full screen],
  [`?`], [this table, in the view],
)

=== What the view should show

`speaker-view` cancels what is not wanted, so an unused tile does not take room
the note could use:

// check: dokument
#show-code[```typ
#show: presentation.with(speaker-view: (
  clock: false,                                  // no class clock
  target: false,                                 // no planned length
  pen: (colors: (red, green, rgb("#FF99DD"))),   // your own pen colours
))
```]

What is not named is on: a deck that says nothing gets the whole view.
`tools: false` takes the drawing bar away.

A tile that is switched off takes its keys with it: with `clock: false`, `t`
and `⇧t` do nothing and no longer stand in the key bar.

The colours are Typst colours, not strings, and there may be more or fewer than
four. `c` steps through them in turn.

=== Light or dark

The view follows the system setting of the machine it stands on
(`prefers-color-scheme`), and `l` contradicts it when the room is not what the
operating system thinks. The choice holds for the session and survives a
reload.

It is expressly *not* the deck's palette: the lectern is a tool and should read
the same whatever the room does.

#tip[
  The preview shows the next step, not the next slide: what the next keypress
  does, be it a new slide or one more reveal on the current one. The label above
  it says which.
]

=== Drawing

You draw on the running slide in the speaker view and the strokes appear on the
projected one: the presenter has a trackpad in front of them, and the canvas is
across the room.

Strokes stick to their slide, so paging away and back brings them with you. `x`
clears the current slide, `z` takes back the last stroke, `c` changes colour.

=== A clock the class can see

`t` asks for a number of minutes, and the wall then carries nothing but a clock:
black ground, white digits, `mm:ss`, large enough to read from the back row. It
replaces the slide rather than sitting on it -- the twin of `b`, only with
something on it. It is meant for the break, the group work, the experiment being
set up.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Key*], [*What it does*]),
  [`t`], [ask for minutes; `Enter` starts it, `Esc` leaves it],
  [`t` (while it runs)], [end the clock, the slide is back],
  [`⇧→`, `⇧←`], [one minute more or less, while it runs as well],
  [`→` (or any other paging key)], [ends it and uncovers the slide],
)

In the speaker view it has a tile of its own, `class clock`, beside the tile
`target (min)`. The two do not look alike: the target duration is a field of
whole minutes you set once per talk, the class clock a running `m:ss` with a bar
that empties. While none runs a dash stands there, and while no talk window
answers a longer one.

At zero it does not stop but carries on to `+00:01` in the deck's accent colour,
with the word "over" above it. Nothing blinks and nothing chimes. The overtime
is capped at the duration itself and at thirty minutes. At the lectern the whole
tile turns over at the same moment, in the warning colour, so that the teacher
sees the overtime no later than the class does.

#warning[
  `t` when nothing else is on the wall. No clock while you are talking: a clock
  running beside a sentence pulls the eye for the whole talk. It is therefore
  not laid over the slide but replaces it, and whoever goes on talking presses
  it away.
]

#info[
  Like black and freeze, the clock lifts on its own if the speaker window goes
  away; the talk window has no key against it. Reload the talk window and the
  clock comes back -- further along, not from the start.
]

=== The pointer

`m` switches between the pen and the pointer. What the pointer does is point:
move the mouse across the slide copy in the speaker view and a lit dot appears
at the same spot on the wall. Hovering is enough -- no button, no key. The dot
carries the accent colour at 2.2% of the slide width, and it travels as a
fraction of the stage, so the small window in front of you and the large canvas
behind you agree on where it is.

It goes out when you leave the slide copy, when the window loses focus, when
you reach for the pen, and on a change of slide. It survives a change of step:
whoever points at a term and uncovers the next line means the same term still.
Letting go of the button parks it where it stands -- a dot left standing is an
intention, not an oversight, and one keypress away from gone.

#info[
  What the dot does not do is leave a trail. Whatever should stay on the slide
  belongs to the pen, which is exactly one keypress away.
]

The same mode has a second ability, and it is the older one: a press on an
embedded frame lands in the talk window's copy of that frame instead of on the
slide. Press, drag, release and wheel travel as fractions of the stage, so both
windows hit the same point of the document. Hovering does not reach into a
frame -- pointing at something is not operating it -- and the dot stands on the
frame while you do, which is deliberate: the class should see where the hand is
about to land.

Where the embedded document can mirror itself, as a GeoGebra applet does, the
live one in front of you is operated instead and the projected copy follows.
The dot stays out over such a frame: it takes the pointer for itself, and the
stage never sees the movement.

#warning[
  It reaches listeners, not the browser's own widgets. A checkbox toggles and a
  button fires, because a click carries its activation behaviour along; an
  `input type=range` does not move, because a browser only drags its own slider
  for input it trusts. Whoever builds for this listens rather than relying on a
  native control.
]

=== Blacking out and freezing

`b` blacks the room out, `e` freezes the projected image while you page ahead
in private. Steering works from either window, and either one may be reloaded:
they find each other again, and the strokes come back.

#warning[
  Both lift by themselves shortly after the speaker window is closed. If that
  window stays open but no longer carries a deck, a one-minute deadline applies
  instead -- and a stalling talk window on top of that can put it off
  indefinitely. That is the one known corner in which the room stays dark.
]

The speaker view opens on one keypress, and a *real* keypress is the condition:
`window.open` without a user gesture falls to the popup blocker.

== Less motion

Someone who has turned on "reduce motion" in their operating system gets a
quieter deck. The runtime asks for `prefers-reduced-motion: reduce` afresh on
every step and every frame, so switching it on in the middle of a talk takes
effect at the next keypress. There is nothing to configure.

The setting says "less motion", not "no motion": *opacity stays, travel goes.*
An entrance still says "this is new", but nothing crosses the slide any more.

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

*Video.* A video is content, not decoration. Whoever does not want it to start
by itself writes `autoplay: false`.

*Embedded documents.* The runtime does not reach into a foreign document. The
setting does: `matchMedia("(prefers-reduced-motion: reduce)").matches` is true
inside the frame as well, so anyone animating something there writes their own
`@media` rule.

#info[
  No switch lets a deck overrule the setting. Where a motion really carries the
  argument, it belongs in words as well -- and those are read by the people who
  never see it run.
]

= Three outputs from one source

The talk for the canvas, the deck to read afterwards, and the handout to write
on, without a second version to keep in step.

== The slide deck

The PDF run without further arguments gives one page per slide, in the size of
the canvas. Every element that moves in the browser stands in its final state:
what is revealed is there, and where several versions share one place, the last
one. Notes, transitions and bridge jobs produce no output and fall away by
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
take its place. Up to two slides per page the notes stand *below* and the slide
takes the full width; from three on they stand *beside*. Under a slide at least
four lines remain: a 4:3 slide that would otherwise take the whole height at two
per page is made narrower for them.

== Bookmarks

The PDF carries an outline, like any other Typst document: one entry per
slide, sections above them, the title slide at the top. In a reader that is
the sidebar you jump with instead of paging.

None of it is visible. Each slide places a heading that `hide` strips of ink
and `place` takes out of the flow; it exists only to be bookmarked. The detour
is needed because the headings that cut the deck into slides become
dictionaries on the way and never reach the document, so without the silent
heading there would be nothing for Typst to build an outline from.

A heading a deck writes inside a slide body gets *no* bookmark of its own. It
would otherwise sit beside the slide's own, and under `pages: "step"` once per
step page as well -- the same name several times, on pages that do not show
it. A slide without a title stays out of the outline; an empty entry is worse
than none.

== What the paper leaves out — and what to plan for

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*On the slide*], [*On paper*]),
  [`anim`, `stagger`, `#pause`],
  [everything visible, in the same place and the same room],
  [`alternatives`],
  [the last version only, in the shared box],
  [`morph`],
  [the content of each slide -- the chain becomes the calculation],
  [`embed`, `geogebra`],
  [`fallback`, otherwise a placeholder with `label`; `link` below it],
  [`video`],
  [the `poster`, otherwise a grey panel],
  [`flipbook`],
  [a single picture: `still` or `render(0.0)`],
  [`scene`],
  [a single picture: `still` or the last stop],
  [`speaker-note`],
  [beside its slide in the handout, nothing in the plain slide deck],
  [`transition`, `bridge-job`],
  [nothing -- they belong to the motion alone],
)

#tip[
  Whoever knows a handout will come sets `fallback` and `link` while writing the
  slide. Afterwards every embedded place has to be visited a second time.
]

== All three in one run

Since Typst 0.15 one compilation can write several files. `bundle` writes talk,
deck and handout at once:

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
and `per-sheet` is the number of slides on a handout page. Everything else goes
to `presentation` unchanged.

What the package looks up stays in its own output. The counters start afresh
per output, those of figures and equations and a deck's own included, and a
link such as an entry of `contents()` leads into its own file. Two things Typst
keeps across the whole bundle, though, out of the package's reach. A deck's own
`state` carries on from one output into the next, since there is no value it
could fall back to; a running number therefore belongs in a `counter`. And a
label stands once in every output: a reference such as `@fig` stops the bundle
with "label occurs multiple times in the document", even where the deck
compiles on its own, and an `outline(target: figure)` of the deck's own lists
the figures of every output.

With `pages: "step"` there is one limit more. Where a reveal then sits in a
version of `alternatives` or a stage of `build` and another slide follows --
`#alternatives([A], [#anim[x]])` --, the bundle warns that it does not converge,
and in `talk.html` the `x` never comes. Such a deck builds its HTML on its own,
with `html: none` in the bundle.

#warning[
  The bundle is experimental on Typst's side and needs `--features bundle,html`.
  A file that uses `bundle` compiles *only* with `--format bundle`; a plain
  `typst compile talk.typ talk.pdf` stops with "constructing a document is only
  supported in the bundle target". To keep both routes open, put the body in a
  `#let` and call `presentation` by hand.
]

== Notes

`speaker-note` files a note with the slide. It stands in the body or as the
argument `note` on `slide`:

#show-code[```typ
== The Pythagorean Theorem
#speaker-note[Show the dissection first, then the formula.]
```]

The note appears in the speaker view and on the handout. It produces nothing in
the deck PDF.

A note has to carry text: the speaker view transports it as a string and the
handout prints it where there is text. A note built purely out of layout -- a
`fit`, a bare `rect`, an image -- is refused with a message. What is meant to be
*seen* belongs on the slide.

== Two clocks for the class

`t` starts the *full-screen clock*. It covers the slide edge to edge, with
digits the back row can read: the room is on a break. Paging ends it and
uncovers the slide again.

`⇧T` starts the *pinned clock*. It stands #emph[on] the slide and leaves the
task underneath in place, so paging deliberately does not end it. In the
presenter view it takes the mouse: a drag in the middle moves it, a drag at
the edge makes it larger or smaller, and the cursor says which of the two a
drag would do. Place and size travel along to the talk window as fractions of
the stage, so the clock stands in the same spot of the slide and at the same
size, in a window of a different size.

Both ask for the minutes first and only then run. `⇧←` and `⇧→` give a
minute more or less; the same key again ends the clock.

What a deck knows about the pinned clock it writes with `class-clock`:

#show-example(
  rendered: [],
  source: ```typ
  #slide[
    = Group work
    #class-clock(12)
    Find three examples in pairs.
  ]
  ```,
  width: 12cm,
)

Nothing starts from that: `⇧T` offers the twelve minutes and the speaker
confirms or changes them. The deck knows how long the task was meant to take,
the room decides how long it gets.

=== The digits set the clock

A question at the start of the lesson, a minute of talking in pairs: the hand
is on the keyboard anyway, and a number is shorter than `t`, field, number,
`Enter`. `3` starts three minutes, `7` seven, `0` ends it again.

What starts is the pinned clock. The question stays on the slide while the time
runs, and paging does not end it. And it works without a second window: one
machine at the beamer is enough. The clock used to be reachable only from the
desk, which is not the arrangement anyone teaches in.

On a slide with a `cue()` group the digits belong to the group. That holds for
the whole slide, not for the single keystroke: a digit the group does not have,
and a second press on the same point, start no clock there either. A slide
belongs either to the points or to the clock, and the slide itself says which.

`b` blacks the hall out and leaves the pinned clock standing: blacking out
during group work takes away the distraction, not the time. The full-screen
clock still gives way -- it covers the hall in any case.

=== How calmly the clock reads

A clock that jumps every second pulls the eye off the task each time. `room`
sets the step for the whole deck:

// check: dokument
#show-code[```typ
#show: presentation.with(
  room: (clock: (step: 5)),     // the number moves only every five seconds
)
```]

The last step still counts down singly -- 00:15, 00:10, 00:05, 00:04, 00:03,
00:02, 00:01, 00:00. A clock that shows 00:00 for a full five seconds while time
is left sends the class home early.

The step has to divide 60 evenly: 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30 or 60
seconds; `duration(seconds: 5)` works in place of the number. One that does not
is refused at compile time:

// check: dokument bricht=has_to_divide_60_evenly
#show-code[```typ
#show: presentation.with(room: (clock: (step: 7)))
```]

Otherwise the number is already wrong the moment it starts -- a `class-clock(1)`
would read 00:56 at a step of seven seconds, and that reads like a fault of the
clock rather than one of the setting.

On the deck and not on the slide, deliberately. How coarsely the clock reads is
a property of the eye and not of the task; a running clock that changed its
rhythm on paging would look like a fault. How long a task is meant to take does
genuinely differ per slide -- that is what `class-clock` is for.

`room: (clock: (digits: false))` gives the digits back; whoever drops the clock
entirely writes `speaker-view: (clock: false)` and loses the digits with it.

=== A sound on a key

A signal the class knows: time is up, pack away. `room` binds a key to a sound
file.

// check: dokument
#show-code[```typ
#show: presentation.with(
  room: (sounds: (a: "airhorn.mp3", g: "gong.mp3")),
)
```]

The file travels beside the HTML like any other media file; the package ships
no sound of its own. The example decks `tour` and `unterrichten` carry a horn
computed for them rather than recorded, `examples/medien/airhorn.mp3`, with the
command that builds it in `PROVENANCE.md` beside it. It is heard in the hall
and only there: the speaker sits
at the machine, the speakers are in the room, and the sound is never heard
twice. The key may be pressed in either window.

Free letters are #raw("a g h i j k p q s u v w y") -- the rest belong to the
runtime, and a taken one is refused at compile time with the free ones listed:

// check: dokument bricht=the_runtime_already_has_that_key
#show-code[```typ
#show: presentation.with(room: (sounds: (b: "gong.mp3")))
```]
The chosen keys appear in the speaker view's key bar, since the translated help
text cannot know them.

If the file is missing, the runtime says so at load time rather than when
somebody presses the key: a missing image leaves an empty rectangle, a missing
sound leaves nothing.

=== The dot in the hall

The pointer's dot, from "The pointer" above, is on by default and needs
nothing said about it. `room` has it in case the default does not suit the deck:

// check: dokument
#show-code[```typ
#show: presentation.with(
  room: (pointer: (color: rgb("#00c853"), size: 4%)),
)
```]

`size` is a ratio of the *slide* width and not a length, because the slide copy
in the speaker view and the canvas in the hall are measured in different
numbers of pixels -- 622 against 1600 on this machine -- and the dot is meant
to be the same size on the slide in both. It has to sit between 0.8% and 6%:
below that the two rings are thinner than a pixel on the wall, and they are the
ones carrying the contrast -- at 0.8% of a 1600-pixel stage each of them is
only 0.9 pixels thick. Above it the dot covers a line of text.

// check: dokument bricht=a_ratio_of_the_slide_width
#show-code[```typ
#show: presentation.with(room: (pointer: (size: 12%)))
```]

The colour is free, and freer than it looks: the dot carries a light ring and a
dark one around its core, and whichever ground it lands on, one of the two cuts
it out. Measured, the dark ring reaches 10.90 on a light slide and the light one
15.45 on `themes.night`, whatever the core is. One method for both numbers, so
that two measurements of one thing do not read as a contradiction: the dot
stands at the middle of the stage in a 1600 by 900 hall window at its default
size, the screenshot is read unscaled, the ground is the most frequent colour on
the circle of two and a half radii around the centre, the two rings are the most
frequent colours at 0.57 and 0.71 radii, computed after WCAG 2.1. The light
slide is the default paper, `#fafafa`. A green of one's own reads 2.14 in the
core by the same method and keeps the dark ring's 10.90 all the same. A badly
chosen colour therefore costs visibility, not legibility. Without a colour of
its own the dot takes the deck's accent.

`pointer: false` takes the dot away entirely:

// check: dokument
#show-code[```typ
#show: presentation.with(room: (pointer: false))
```]

Embedded frames stay operable: they are the pointer mode's other half and do
not hang off the dot. What comes back with `false` is the old note -- on a
slide with nothing embedded, the speaker view now says there is nothing to
point at, because now that is true again.

= Making it your own

The aim: a deck that looks like yours and not like the package.

== Choosing a theme

Five ship with the package, made for different occasions rather than one slide
in five colours. The title sits in a bar, free, or under a line; the progress
indicator grows, or is missing.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*Made for*]),
  [`themes.default`], [A conference talk. Title in a coloured band, bar of
   progress.],
  [`themes.lesson`], [A lesson. White paper, a running head, tinted panels with
   the caption inside, no progress bar.],
  [`themes.night`], [A darkened room. Dark ground, one signal colour.],
  [`themes.plain`], [Getting out of the way. White, black, one grey.],
  [`themes.editorial`], [Reading rather than presenting. A serif face, a quiet
   rule.],
)

== Changing one

A theme is a plain dictionary, so `+` is all it takes:

#show-code[```typ
#show: presentation.with(theme: themes.lesson + (accent: blue))
```]

`theme(...)` builds one from scratch. Its eight colour entries are the same
eight a palette carries, listed in the next section. Four keys take one word
each:

/ `header`: `"band"`, `"plain"` or `"run"`
/ `footer`: `"fraction"`, `"number"`, `"center"` or `"none"`
/ `progress`: `"bar"`, `"top"`, `"tick"` or `"none"`
/ `box`: `"bar"` or `"label"`

A typo in one of those four is an error, not a silent default: the message
names the values it accepts. `title-slide` and `section` are functions instead
-- those two are whole pictures, not variations on one theme. The typographic
keys and the measures are in the API reference.

== Colour, separately: palettes

A theme says how a slide is *built*; a *palette* says what colour it is. The
two vary separately, which is why they are separate arguments. A palette
overwrites *partially*, only the entries written down:

#show-code[```typ
#show: presentation.with(theme: themes.lesson, palette: (accent: blue))
#show: presentation.with(theme: themes.lesson, palette: palettes.dark)
```]

The eight entries are exactly a theme's colour entries: `paper` the ground of
the slide, `ink` the body text, `strong` the carrying dark colour, `accent` the
signal colour, `muted` the secondary matter, `surface` the ground of a card,
`border` its edge, and `inverted`, whether light text stands on a dark ground.
An entry that does not exist is refused: `palette: (acent: blue)` stops with a
message.

Five ship with the package, and each composes with each of the five themes:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Palette*], [*Where it comes from*]),
  [`palettes.light`], [The colours of `themes.default`, so this one changes
    nothing.],
  [`palettes.mono`], [The greys of `themes.plain`, two moved so it passes the
    contract below.],
  [`palettes.textbook`], [The colours of `themes.lesson`, one grey moved.],
  [`palettes.parchment`], [The laid paper of `themes.editorial`, two tones
    moved.],
  [`palettes.dark`], [The dark ground of `themes.night`, with a deeper
    accent.],
)

That is why the dark room needs no theme of its own: *darkness is a palette
rather than a design.* `themes.lesson` under `palettes.dark` is still the
lesson design, only dark.

`themes.night` stays a theme all the same. Its cyan glows on night's own ground
but all but vanishes on the ground an inverted slide lays behind it, so
`palettes.dark` takes a deeper blue that holds on both while the theme keeps
the cyan it was designed around.

#warning[
  Two colours of a theme are not palette entries: `title-fill` and
  `rule-fill`. Whether they follow is up to the theme. All five bundled ones
  let them follow -- either as a function of the palette,
  `title-fill: p => p.strong`, or as `none`, which means the accent. A theme of
  your own that names a fixed colour there keeps it under every palette: a
  colour someone named out loud is not swapped behind their back.
]

== The colours of a theme

The five bundled themes fill those eight roles differently:

#show-example(
  rendered: {
    import "../src/lib.typ": themes
    let feld(c) = block(width: 1.5cm, height: 0.8cm, fill: c,
                        stroke: 0.4pt + luma(70%), radius: 2pt)
    table(
      columns: (auto, auto, auto, auto, auto),
      stroke: none,
      align: (left + horizon, center, center, center, center),
      inset: 5pt,
      table.header([], raw("paper"), raw("strong"), raw("accent"), raw("muted")),
      ..("default", "lesson", "night", "plain", "editorial").map(n => {
        let t = themes.at(n)
        (raw(n), feld(t.paper), feld(t.strong), feld(t.accent), feld(t.muted))
      }).flatten(),
    )
  },
  source: ```typ
  #import "@preview/typstage:0.2.0": themes
  #themes.night.accent      // the theme's signal colour, as a colour
  ```,
  width: 12cm,
)

`card` and `callout` take their colours from the running theme, so a change of
theme recolours them. Where one card is to look different, it takes `color:`
and `fill:`.

#tip[
  A colour that carries meaning — blue for the function, orange for its slope —
  is best fixed once at the top of the file and handed on where it belongs:
  `card(color: …)`, `callout(color: …)`, `ggb-style(color: …)`.
]

Independently of the theme the package hands out four colour constants —
`dark`, `accent`, `paper` and `muted` — the default look. They are handy where
a slide needs a shade and the theme is not being changed; whoever swaps the
theme is better served by its entries.

== Inverting one slide

For the slide that carries a single number there is `invert`. The ground
becomes the palette's text colour and the text becomes its ground; `muted`,
`border` and `surface` are mixed from those two, `strong` and `accent` carry
over unchanged. Running head, footer, slide number, progress bar, `card` and
`callout` follow.

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
  Only a regular slide inverts. Title and section slides are whole pictures the
  theme draws itself, and neither takes the argument.

  The `#invert` marker is found wherever the body can be walked: nested in a
  block, an align, a table cell or a grid, in the slide's own heading, and
  behind `#set` and `#show` rules. It is *not* found where the content is
  handed to a closure. Measured, that is nine: `context`, `fit`, `anim`,
  `card`, `callout`, `tiles`, `cue`, `stagger` and `alternatives`. There the
  slide is left as it is, without a word. Where you need one of those, write
  `slide(invert: true)`, which never depends on the walk.
]

== The contrast contract

The bundled palettes are measured before they ship, against the WCAG 2
contrast ratio. Seven pairs are checked:

#table(
  columns: (auto, auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Pair*], [*At least*], [*What for*]),
  [`ink` on `paper`], [4.5], [body text on the slide],
  [`ink` on `surface`], [4.5], [body text in a card],
  [`muted` on `paper`], [4.5], [footer, subtitle, running head],
  [`accent` on `paper`], [3.0], [rules, progress bar, marker],
  [`accent` on `ink`], [3.0], [the same on an inverted slide],
  [`accent` on black], [3.0], [the overtime of the full-screen clock],
  [`border` on `paper`], [1.2], [hairlines],
)

The second to last has no palette role as its ground: the full-screen clock is
black from edge to edge whatever the deck's palette says, and its overtime
digits are set in the accent.

All five bundled palettes are checked automatically, upright and inverted. A
colour moved there that breaks the contract stops the build and names the
number it missed.

#warning[
  *The contract holds only the bundled palettes.* A palette of your own faces
  no gate: it is neither warned about nor recoloured. `palette-report(…)` hands
  the same measurement back as a list:

  #show-code[```typ
  #for f in palette-report((paper: white, ink: black, surface: white,
                            muted: luma(55%), accent: blue, border: luma(86%))) [
    #f.pair: #calc.round(f.ratio, digits: 2) (wants #f.min) #f.ok \
  ]
  ```]

  `contrast(a, b)` is the arithmetic itself and takes any two colours.
]

*And the five themes do not all pass it.* They were measured before the
palettes existed, and the result stands here rather than being quietly coloured
away:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*What falls short*]),
  [`themes.default`], [nothing, all seven pairs hold],
  [`themes.lesson`], [`muted` on `paper`],
  [`themes.night`], [`accent` on `ink`],
  [`themes.plain`], [`muted` on `paper`, and `accent` on `ink`],
  [`themes.editorial`], [`muted` on `paper`, and `accent` on `paper`],
)

None of those colours was changed: moving them would have changed every deck
already written, and what `muted` carries is secondary matter -- slide number,
subtitle, running head. Anyone who wants the numbers met lays the matching
palette over the theme:

#show-code[```typ
#show: presentation.with(theme: themes.editorial, palette: palettes.parchment)
```]

#warning[
  *The text colour is never inferred from the fill.* A muted sage such as
  `#aebdb3` reads as "light" to a luminance rule, yet white on it measures 1.96
  to 1, far under the 4.5 that body text wants. So the package measures with
  `contrast` and recolours nothing on its own.

  The one exception lives in the theme, not the palette. Where a theme uses
  `strong` as *text* -- the heading in `themes.lesson`, the section title in
  `themes.plain` -- it picks between `strong` and `ink` by contrast against the
  ground, because one colour cannot serve as both a dark band and text on a
  dark ground.
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
  A tracked element is typeset a second time in a frame of its own, and that
  frame never sees a `#set` rule from the document. Shared typography therefore
  has to go here: a `#set text` after the show rule reaches the slides but not
  the flying pieces, and the difference only shows up mid-flight. One exception
  typstage carries across itself, the numbering of `figure`, `math.equation`
  and `heading`: a `#set math.equation(numbering: "(1)")` in the document
  numbers an equation in a flying piece as it does on paper. A `#show` rule
  that numbers or counts does not reach it, though, and then the numbers on
  the slides after it go wrong in the browser as well: with
  `#show math.equation.where(block: true): set math.equation(numbering: "(1)")`
  in the document, an equation two slides after an `anim` and an
  `alternatives` read (2) in the browser and (5) on paper. Inside `style` it
  reads (5).

  For the shapes typstage draws itself there is a second route, label rules
  before `#show: presentation`. They reach more, including the header, the
  footer and the title slide. See /Labels: reaching every shape the package
  builds/ below.
]

== Right to left

A deck in Arabic, Hebrew, Persian or Urdu needs one line, and it is Typst's
own:

#show-code[```typ
#set text(lang: "fa")
#show: presentation.with(title: [چهار مثلث در یک مربع])
```]

`lang` is enough for a language Typst reads from the right; `#set text(dir:
rtl)` says it outright for any other. Typst turns the paragraphs, lists and
columns around by itself. typstage turns around what it draws by hand: the
title in its band, the bar beside a `callout`, the number in the footer, the
progress bar, the title and section slides. `alternatives`, `build` and
`tiles` anchor at `start`, which is the right edge in such a deck, and a
`callout` without `title:` reads its caption in Arabic, Persian or Hebrew.

The rule goes *before* the show rule. After it, it still reaches every slide
body and every moving part, but not the title slide, the section slides and
the footer: those are drawn outside the body and would keep reading from the
left.

Not mirrored: the transitions. A `"slide"` still comes in from the right;
`from: "left"` turns it around where that reads better.

== Building blocks for the body

Six functions for the body of a slide: `card`, `callout`, `side-by-side`,
`tiles`, `statement` and `fit`. The coloured ones take the running theme's
colours unless told otherwise.

=== card: the named box

#show-example(
  rendered: {
    import "../src/lib.typ": card
    card(title: [Power function])[$f(x) = x^n$ with $n in NN$.]
  },
  source: ```typ
  #card(title: [Power function])[$f(x) = x^n$ with $n in NN$.]
  ```,
  width: 11cm,
)

`number:` puts a numbered disc in front, for the running order where the number
belongs to the matter -- `card(number: 2, title: [Second step])[…]`. `color:`
tints the bar, `fill:` the panel.

=== callout: the one that has to stick

#show-example(
  rendered: {
    import "../src/lib.typ": callout
    callout[The exponent decides the symmetry.]
  },
  source: ```typ
  #callout[The exponent decides the symmetry.]
  ```,
  width: 11cm,
)

`title:` changes the caption (it follows the document language by default),
`color:` its colour, and `title: none` leaves it off.

=== side-by-side: two columns

The usual case for a slide with something to look at: the drawing or the applet
on the left, the words on the right.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    side-by-side(
      card(title: [Even exponent])[Symmetric about the $y$ axis.],
      stagger[
        - $f(-x) = f(x)$
        - Range $W = [0; oo[$
      ],
    )
  },
  source: ```typ
  #side-by-side(
    card(title: [Even exponent])[Symmetric about the $y$ axis.],
    stagger[
      - $f(-x) = f(x)$
      - Range $W = [0; oo[$
    ],
  )
  ```,
  width: 13cm,
)

`split:` takes the column widths; the default gives the first column a little
more, because that is usually where the picture goes. More than two columns are
allowed — they then share the width equally, unless `split:` names as many
values.

`equal: true` makes every column the height of the tallest; without it each box
stands as tall as its own text, and two cards side by side look differently
weighted. The row is measured once and its height handed on as a length, which
is why `equal` reaches `card` and `callout` rather than arbitrary content. To
reveal one of them, put the `anim` inside the box, `card[#anim[…]]`, not the box
into an `anim`: in the browser a revealed box stands only as tall as its own
text.

=== tiles: the grid that numbers its own reveals

Each tile appears one step after the one before, without an `anim` per tile and
a number counted up.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    tiles(
      card(title: [one])[Observe],
      card(title: [two])[Conjecture],
      card(title: [three])[Justify],
    )
  },
  source: ```typ
  #tiles(
    card(title: [one])[Observe],
    card(title: [two])[Conjecture],
    card(title: [three])[Justify],
  )
  ```,
  width: 13cm,
)

`columns:` sets how many there are (up to three by default). `stride: 0` puts
them all on the same step and staggers only through `stagger`, in
milliseconds — a wave runs through the grid then, instead of a sequence of
keypresses. A tile that reveals something of its own moves the tiles after it
back, as the pieces of a `stagger` do:

#show-code(```typ
#tiles(stride: 0, stagger: 90, [A], [B], [C], [D])
```)

`duration:` and `easing:` are those of `anim` and apply to every tile alike: a
grid moves as one thing. Given neither, the presentation's duration and the
house curve apply.

=== statement: the large claim

#show-example(
  rendered: {
    import "../src/lib.typ": statement
    statement[$ a^2 + b^2 = c^2 $]
  },
  source: ```typ
  #statement[$ a^2 + b^2 = c^2 $]
  ```,
  width: 11cm,
)

`statement` asks for the full width explicitly and centres within it. A bare
`align(center, …)` inside a tracked element cannot: the element is only as wide
as its content.

=== fit: working content into the room it has

For the one piece whose size is not written in the deck: the wide table out of
the analysis, the generated chart, the list from a data file. Left alone, such
a block runs over the edge of the slide -- visibly in the PDF, cut away in the
browser, where the slide sits in a frame of fixed size.

// check: folgen pre=tabelle
#show-code(```typ
== Regression results
#fit(wrap: false, my-table)
```)

`fit` measures the block against the place it stands in and scales it
geometrically, so the proportions are kept and no factor is given by hand. The
result is the same in the HTML and in the PDF.

*Width first, then smaller.* The block is offered the full width before it is
measured. A paragraph or a list then wraps into the space instead of shrinking,
and only what is still too tall afterwards is scaled. A block that already fits
is left untouched.

*`wrap: false` for anything that lays itself out in columns.* A table, a chart
or a drawing does not wrap when it is offered a narrower width, it rearranges
itself -- under the default `wrap: true` the columns are squeezed, the digits
overlap, and nothing is scaled at all. `wrap: false` measures such a block
exactly as it stands. It is the one setting worth knowing before the first use.

*It only shrinks.* `grow: true` also blows up what is smaller than its place,
for the one large number meant to fill the slide. `shrink: false` takes the
shrinking away and leaves only the growing.

#show-code(```typ
#fit(grow: true)[42%]
```)

`width` and `height` take `auto`, a length or a ratio. On `height: auto` the
block takes what is left over below the rest of the slide, so a fit under two
bullet points reckons with them. That backfires inside a `card`: the box
becomes slide-tall, is cut off at the bottom, and whatever follows falls off
the slide. Give `height:` explicitly inside a card.

#warning[
  *No reveal inside a `fit`.* Two things do not survive being measured. A
  `pause` is found by walking the slide body, and a fitted block is a closure
  that walk cannot enter, so its steps fall away silently. And a measured block
  gets no bounded height to reckon against, so a tracked element inside one
  cannot reserve the room for its marker.

  `fit` therefore stops with a message that names the thing, for `pause`,
  `anim`, `stagger`, `alternatives`, `morph`, `tiles`, `video`, `embed`,
  `flipbook`, `build`, `scene`, `camera` and `cue` -- in both outputs, and
  also when the fit
  sits inside another fit. Put the fit *inside* the reveal rather than around
  it:

  // check: folie pre=tabelle fehlt=2 weil=cannot_stand_inside_fit
  ```typ
  #anim(fit(wrap: false, my-table))   // yes
  #fit(anim(my-table))                // no
  ```
]

`speaker-note` and `bridge-job` are allowed inside a `fit`. The other direction
is not: a note made only of a `fit` carries no text, and `speaker-note` refuses
it with a message.

The arithmetic is taken from mosaic, which took it from Touying 0.7.4; Touying
credits the work on it to Andreas Kröpelin (Polylux PR #91) and to ntjess.

=== overflow: the checking pass before the talk

`fit` answers the one block whose size you already suspect. `overflow` answers
the question you cannot ask slide by slide: does anything in this deck run over
the room it has? It measures every slide body and names the ones that do not
fit.

#show-code(```typ
#show: presentation.with(overflow: "error")
```)

It is off by default and meant to be switched on for a run, not left on while
writing. A build script can raise it from the command line instead of editing
the deck, which is how the seventeen example decks of this package are measured
on every push:

#show-code(```sh
typst compile --features html --format html \
  --input typstage-overflow=error deck.typ deck.html
```)

The input raises, it never lowers: of the two settings the stricter one wins,
`"none"` < `"record"` < `"error"`, so no run can quietly switch a check off in
passing.

A deck needs this more than a document does: an overrun on a page stands past
the margin where the eye catches it, while a slide goes into a frame of fixed
size and what sticks out is cut away.

/ `"none"`: nothing is measured. The default.
/ `"error"`: the whole deck is built, and it then stops with *every* place at
  once rather than with the first. One run, the whole list.
/ `"record"`: it carries on and files a queryable record per finding instead,
  for a tool or a build script. Typst gives a package no warning channel, so
  `"record"` prints nothing by itself.

The message names the slide, the step and the amount (shortened here):

#show-code(```
error: assertion failed: typstage: 2 slides run over the room the body has. …
  slide 2, from step 1 at the earliest: 311.14pt too tall, 675.76pt of content in 364.61pt of room
  slide 3, from step 2 at the earliest: 296.49pt too tall, 661.1pt of content in 364.61pt of room
Shorten the slide, split it, or put the block that does not fit into fit(). …
```)

*Why the step says "at the earliest".* A slide is the same height on every step
-- only what is *drawn* changes, not the room reserved for it. The step is
therefore a lower bound, exact only where the thing that overruns is itself a
reveal. *The slide is named correctly either way*, and that is the part to act
on. On paper no step is named, because every step stands on the page at once;
in the records that shows as `step: 0`.

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
  *What the check does not see.* Only the height is measured, so a body that is
  too wide goes unnoticed; `fit` is the answer to that case. A `height: 100%`
  in the body measures 0 and a `1fr` collapses. Anything drawing outside its
  own layout box -- `scale`, `move`, `place` with an offset -- is invisible to
  a measurement. Title and section slides are never measured: they have no body
  block to overrun.

  And one thing is reported where nothing shows: trailing spacing, a `v()` at
  the end of a body, takes room in the measurement and draws nothing.
]

In HTML the pass costs up to half again as long per deck; on paper it costs
next to nothing.

With `pages: "step"` the PDF is not measured: every step page sets the same body
as the one page per slide, and measuring it there cost convergence for decks
that look something up in their body. The same goes for a handout that is
given `pages: "step"`, which is what `bundle()` does. The HTML still measures,
and names the step as well.

=== drift: the check for scenes that travel

`overflow` asks whether a slide fits its room. `drift` asks the other question
one cannot check slide by slide: does a scene stand still while the talk pages
through it?

A drawing is as large as what it holds, a CeTZ canvas above all. Change the
content across the stops of a `scene` and every frame comes out a different
size, so the drawing sits somewhere else in its box each time: paging moves the
whole picture although only one point was meant to move. Every scene measures
its frames, and `drift` says what happens with the findings.

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

The records are read exactly as the overflow ones, with
`query(<typstage-drift>)`, and for that the deck has to be on
`drift: "record"`.

*Why this check is on where `overflow` is not.* Only decks that use `scene` pay
for it, while `overflow` measures every body of every deck. And what this one
finds is invisible while writing: every frame on its own looks right, and only
paging shows the drawing travelling. Only the browser branch measures; on paper
a single still image stands there, and a still image does not travel.

#info[
  It flags the scene; it does not fix it. A drawing that sets itself to `100%`
  measures the same on every frame and drops out of the check, rightly so: it
  already has a fixed frame. And a drawing that only grows to the right and
  downwards is reported although its ink does not move -- `steady: false` on
  that scene takes it out of the check.
]

=== Slides without a title

A bare `==` leaves the title band off; the body moves up to the top margin and
gets the height the band would have taken. A running header such as the one of
`themes.lesson` -- slide number, section, hairline -- goes with it, and its
height is not held back either. Footer and progress stand as on every slide.
This is the slide for the one large formula,
and the target of a morph that is to fly into the middle:

#show-code(```typ
==
#place(center + horizon, morph(<derivative>, text(size: 2.4em)[
  $f'(x) = lim_(h -> 0) (f(x+h) - f(x)) / h$
]))
```)

In the argument form all three spellings are allowed: `slide[body]` without a
title, `slide(none)[body]` explicitly without, `slide([Title])[body]` with.
A slide is without a title when its heading draws nothing: `==`, `slide(none)`,
also `== #h(0pt)`. A heading that carries only a formula or a picture is a
title and gets its band and its running header.

=== bleed: to the edge of the canvas

`bleed` lays its body over the whole canvas: its origin is the slide's top left
corner, its room the slide's full width and height, whatever the margins, the
title and the running header take. It lies right above the slide's ground and
below everything else; the title and the body are drawn on top.

// check: folgen dateien=harbour.png
#show-code[```typ
==
#bleed[
  #image("harbour.png", width: 100%, height: 100%, fit: "cover")
  #place(dx: 480pt, dy: 300pt, morph(<sign>, card[How far is it?]))
]
```]

A `place` inside `bleed` counts from the corner of the canvas, without an
anchor too and behind a picture of full height too. It is the corner where the
text begins: in a deck that reads from the right it is the top right one, and a
positive `dx` leads from there off the slide to the right. That is how Typst's
`place` counts everywhere, in the slide body as well and without this package.
To count from the left, spell the anchor out -- `#place(top + left, dx: 40pt,
dy: 300pt, …)` lands at exactly (40, 300) in a Persian deck too --, and a
paragraph inside a block placed that way then aligns to the left until an
`align(start)` around the content puts it back.

`anim`, `cue` and `morph` inside work as anywhere else: the sign flies in from
the slide before and on to the next one. The `style` hook wraps the body of
`bleed` as it wraps the slide body; a `style` that indents the body with `pad`
indents the picture as well. And on a slide with `bleed` the hook runs twice,
because picture and body are laid out separately: a hook that counts something
on the side, or writes a state, does so twice there.

A slide with `bleed` draws no chrome: no running header, no slide number, no
footer line, no progress bar -- on paper, in the browser and in its print view.
It still counts, and on the next slide the bar is back with that slide's
reading. The handout is a PDF as well: there the bleeding slide is the one
slide without its number. To be able to name it in a conversation, put the
number into the `bleed` yourself -- there it lies on the canvas and comes
along. The overflow check measures the body alone; what stands in `bleed`
never overruns.

#warning[
  `bleed` stands at the top of a regular slide's body, before other content and
  before the first `#pause`, once per slide. `#set` and `#show` rules,
  `#invert`, `#transition`, `#speaker-note` and `#class-clock` may come first.
  It is laid out before the body; written further down, the steps, the footnote
  numbers and the stacking would follow another order than the source. So the
  build stops instead of reordering without a word:

  // check: folgen bricht=comes_after_other_content
  #show-code[```typ
  ==
  How far is it?
  #bleed(rect(width: 100%, height: 100%, fill: blue))
  ```]

  The same for `bleed` in a title, in a note, outside the deck, and inside a
  block, a grid, a list, `align`, `context`, `anim`, `fit`, `card` or
  `alternatives` -- also below a rule `#show: it => block(it)`, which lays the
  rest of the slide into a block. What is to appear later stands inside `bleed`
  in an `anim`.
]

#info[
  *What lies on top in the browser.* Tracked elements -- `anim`, `cue`, `morph`
  -- are drawn by the browser on a layer of their own above the slide. So a
  picture in `bleed` is best left untracked; wrapped in an `anim` itself, it
  would lie over the body's text in the browser and under it on paper.

  *What a picture costs.* In the HTML every slide carries its picture embedded
  on its own. Two slides with the same photograph carry it twice; a photograph
  for a projector rarely needs more than 1920 pixels across.
]

== Labels: reaching every shape the package builds

Every shape typstage draws itself carries a fixed Typst label: the ground, the
header band, the slide title, the footer, the progress indicator, the card, the
callout, the statement, the title and section slides, the box that stands in
for a video. An ordinary `show` rule reaches it -- no theme key, no fork.

#show-code[```typ
#import "@preview/typstage:0.2.0": *

#show label("ts-slide-header-band"): set rect(fill: rgb("#4c1d95"))
#show label("ts-slide-title"): set text(fill: rgb("#fde047"), style: "italic")
#show label("ts-card"): set block(fill: rgb("#eef2ff"))
#show label("ts-statement"): set text(fill: rgb("#be123c"), weight: "bold")

#show: presentation.with(theme: themes.default)
```]

Two kinds of rule cover all of it. The *surfaces* -- grounds, bands, hairlines,
bars, boxes -- take `set rect(..)`, `set block(..)`, `set circle(..)` or
`set line(..)`. The *type* takes `set text(..)`. Both apply identically in HTML
and PDF, with two exceptions: the six labels under /Media and handout/ are drawn
only in the PDF, because the browser puts the real `<video>` or `<iframe>` in
their place; and `ts-slide-progress` under `progress: "bar"` and `"top"`. In
the browser the runtime draws that bar itself, so that it can grow on a slide
change, in the theme's colour and height: no rule on the label or on `rect`
reaches it there. Under `progress: "tick"` such a rule reaches both outputs.

#warning[
  *For the surfaces* the short form works and the long one does not:

  ```typ
  #show label("ts-slide-progress"): set rect(fill: green)          // yes
  #show label("ts-slide-progress"): it => { set rect(fill: green); it }   // no
  ```

  The short form puts the style rule *around* the element it matched, the long
  one puts it *inside* -- and inside the rectangle there is no second rectangle
  for it to reach.

  For the 19 type labels the two spellings are equivalent: what sits inside the
  matched element there is the text, and a rule reaches that from within.
]

=== Where the rule has to stand

*Before* `#show: presentation`. That one place reaches everything: the slide
background, the chrome layer with header, footer and progress, the title slide
and every moving piece.

The `style` hook does *not*. It is wrapped around the slide *body*, and header,
footer, progress and the two whole-picture slides are built beside it. Measured,
all 42 rules one by one: from `style` exactly the 13 that stand in the body take
effect -- `ts-card…`, `ts-callout…`, `ts-statement` and the three `ts-media-…`
surfaces. The other 29 stay silent, without a warning.

#warning[
  A `show` rule written *after* `#show: presentation` does not reach a tracked
  element (`anim`, `morph`), for the reason given under Typography: in the
  browser every moving piece is typeset a second time in a frame of its own,
  and that frame never sees a `#show` rule from the document body.

  ```typ
  #show: presentation.with(theme: themes.default)
  #show label("ts-statement"): set text(fill: green)   // too late
  == A slide
  #statement[still]
  #anim(statement[moving])
  ```

  Here `still` comes out green and `moving` black. With the same rule one line
  further up, both look alike. The PDF does not show the difference, because
  nothing is typeset twice there.

  This holds for every `#show` rule, not only for label rules.
]

=== What a label rule changes and what it does not

Reachable is whatever the package does *not* set explicitly: for type
everything, for surfaces `fill`, `stroke` and `radius`.

`width` stands as an argument everywhere and is therefore nowhere reachable.
`height` has three exceptions: `ts-card`, `ts-card-bar` and `ts-callout` get
their height as `auto`, and `auto` cannot beat a rule.

#show-code[```typ
#show label("ts-card"): set block(height: 150pt)   // works
#show label("ts-card"): set block(width: 30%)      // does not
```]

The first line blows the card up to 150 pt and pushes the callout under it off
the slide. On the chrome surfaces and the handout frame neither line does
anything; what a `width` rule seems to change there are the blocks *inside* the
content, see the next box.

The slide's *arrangement* is not reachable either. How tall the header builds,
how far the rule sits under the title, where the bar goes -- no `show` rule
reaches into that. The theme keys are there for it: `head-gap`, `band-height`,
`rule-size` and the rest. What a rule can do is move a finished piece as a
whole: `move` on `ts-slide-footer` shifts the number, see "Moving the built-in
number".

#warning[
  A rule on `block` or `rect` reaches *inwards*: it holds for the labelled
  surface and for every block inside it. For `fill`, `stroke` and `radius` that
  is caught -- the card puts the document's own setting back inside. For the
  spacings it is not, and then a label rule moves the slide:

  ```typ
  #show label("ts-card"): set block(below: 60pt)
  == A slide
  #card(title: [Card])[Body]
  #callout(title: [Note])[Remember this]
  ```

  The callout then moves down, and everything below it with it -- by the
  spacing given minus the block spacing already there, *per edge*. Setting
  `above` and `below` at once gives twice the shift.

  That is not a promise but a side effect of Typst's style rules. Labels are
  meant for type and surface; for spacings, use the building blocks' own
  arguments or the theme keys.
]

=== The complete inventory

What stands here exists; what exists stands here. The names follow one scheme:
`ts-`, then the *place*, then the *part*. Places are `slide` (the ordinary
slide), `title-slide`, `section-slide`, `card`, `callout`, `statement`, `media`
and `handout`.

The mnemonic: `slide` in *front* means the ordinary slide; `slide` behind
`title` or `section` means that kind of slide. So `ts-slide-title` is the title
of an ordinary slide and `ts-title-slide-title` the title of the title slide.
Reaching for the wrong one of such a pair does nothing at all, silently.

A label the current theme does not draw -- a header band under `header: "run"`,
say -- is not on that slide, and a rule on it does nothing.

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
  [`ts-slide-notes`], [The slide's footnotes, only where it has any],
    [`text`],
  [`ts-slide-notes-rule`], [The short rule above them], [`rect`],
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
  [`ts-section-slide-back`], [The link back to the contents, at the end of the
    line, bottom -- on the right in a deck that reads from the left, on the
    left in one that reads from the right. Its word comes from `section-back`
    on `presentation` and by default follows `text.lang`. It appears only when
    the deck has a `contents()` and that contents does not stand on the section
    slide itself -- and it is the one label here that the theme still draws
    when the theme brings its own `section` function], [`text`],
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
    PDF. A container only, so a `radius` rule on it is not visible while a
    `fill` rule is], [`block`],
  [`ts-media-fallback-empty`], [The grey box inside it when no `fallback:` was
    given. That one has a surface], [`block`],
  [`ts-media-poster`], [The grey area of a `video` without a `poster:`],
    [`rect`],
  [`ts-handout-frame`], [The framed box of one slide on the handout page],
    [`block`],
  [`ts-handout-lines`], [The writing lines beside or below it], [`line`],
  [`ts-handout-note`], [The speaker note, where there is one], [`text`],
  [`ts-canvas-note`], [The margin note under a slide whose canvas is larger
    than the slide itself -- on paper only], [`text`],
)

#info[
  *A theme with its own title slide draws none of these labels.* `title-slide`
  and `section` in a theme are functions and paint their picture themselves, so
  whoever brings their own loses the labels of that slide kind, and nothing
  warns about it. Which of the bundled themes draws what stands in the
  /What it is/ column.

  *The invisible markers carry none.* Every moving element paints an invisible
  marker rectangle around itself, and `pin` does the same for a single glyph --
  machinery, not a shape, so neither carries a label.

  *Typst labels and the runtime's CSS classes are two separate namespaces.*
  `.ts-slide` in the stylesheet is a slide's `<section>` in the browser,
  `ts-slide-title` is a Typst label -- one hyphen apart and unrelated. Typst's
  HTML export does put a `data-typst-label` attribute on some shapes and not on
  others. That is Typst's own by-product, not a promise of this package: do not
  build CSS on it.
]


== `info()`: what the deck knows about itself

Labels say how a shape looks, not what stands in it: the slide number, the
fraction, the chapter in the running header. `info()` hands those out:

#show-code[```typ
#context {
  let deck = info()
  [#deck.section.title #h(1fr) #deck.slide.number / #deck.slide.total]
}
```]

Every number the package prints on a slide comes out of this dictionary, so a
hand-built footer and the built-in one cannot disagree. What comes back:

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
`slide-level: 2` that is the only level there is, and `section` is then
`levels.last()` without its `depth`. A deck with more than one level -- see
"More than two levels" -- finds them in `levels` and in `outline`:

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
    come. An equal number is running only while that level's `index` is not
    `0`: after a new part, the last chapter of the part before keeps its
    number in `levels` and is past],
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
    let level = d.levels.at(e.depth - 1)
    let running = e.number == level.number and level.index > 0
    text(
      weight: if running { "bold" } else { "regular" },
      fill: if e.number <= level.number { black } else { luma(60%) },
      [#h((e.depth - 1) * 1.4em)#e.title],
    )
  }))
}
```]

One number stands apart: the speaker view and the overview count *every*
slide, title and section slides included, while `info().slide.total` counts the
way the footer counts and leaves those out.

=== Two counts, not one

A slide is one picture, a step is one press of the arrow key. The deck counts
both, and this manual keeps the two words apart.

`step.number` is the step the calling content itself stands on: `1` in the body
of a slide, and inside an `anim`, a `stagger` or an `alternatives` the step of
that reveal -- the first of them where the reveal covers several. So a display
naming the current step has to sit inside the reveals; the browser typesets
nothing anew:

#show-code[```typ
#let where = context {
  let d = info()
  [Step #d.step.number of #d.step.total]
}

== Four versions
#alternatives(where, where, where, where)
```]

Paging through, that prints "Step 1 of 4" up to "Step 4 of 4".

On paper there is no current step: the page shows the slide in its final state,
everything at once, and `step.number` equals `step.total`.

#info[
  `step.total` counts what the runtime in the browser counts -- for every
  building block that consumes a step, and the PDF names the same number.
]

=== Moving the built-in number

The theme places the footer, and no rule reaches that place. What stands there
can still be moved as a whole, with a rule on `ts-slide-footer` that wraps it
in `move`. `move` shifts the drawing and leaves everything around it where it
was, so the number moves by the same amount on paper and in the browser:

#show-code[```typ
#show <ts-slide-footer>: move.with(dx: 14pt, dy: 8pt)
#show: presentation
```]

Positive values go right and down. Like every label rule it stands *before*
`#show: presentation`. The running header of `header: "run"`, where
`themes.lesson` carries its number, moves the same way with a rule on
`ts-slide-header-text` -- the whole line, section title included, while the
hairline under it stays where it is. `presentation(margin: …)` moves the number
as well, and the body with it: the number keeps the side margin's distance from
the edge. A margin in `em` counts against the theme's type size, in the PDF and
in the browser alike.

#warning[
  *Not with the page.* The browser has no page. `page.width`, `page.height`
  and `page.margin` report the document's page there (Typst's A4 sheet unless
  the deck sets one) instead of the slide, and `here().position()` reports
  (0, 0) -- a `move` or a `place` computed from them lands somewhere else in
  the HTML than in the PDF.
  `counter(page)` counts pages, of which the HTML has none, so it stays at 1;
  the slide number is `info().slide.number`. And `#set page(footer: …)`,
  `numbering:` or `foreground:` draw into the page margin or over the page: a
  slide has no margin, and Typst's HTML export drops page rules altogether, so
  a number drawn that way shows in the PDF at most and never in the HTML.
]

=== Where a hand-built footer goes

typstage draws no footer on a title or a section slide, and nothing belongs in
the counter slot there. `slide.numbered` says when that is the case:

#show-code[```typ
#let footline = context {
  let d = info()
  let number = if d.slide.numbered [#d.slide.number / #d.slide.total] else []
  place(bottom + right, text(size: 12pt, fill: muted, number))
}
```]

On an ordinary slide it goes into the body:

// check: folgen davor
#show-code[```typ
== A slide
#footline
The text of the slide.
```]

At the top of the body, that is: before the first `#pause`, and not inside
`anim`, `stagger`, `alternatives` or any other building block that reveals.
Behind a `#pause` the footer belongs to its run and stands level with the run's
last line instead of at the foot of the slide, in both outputs -- as long as it
is a `place`. Pushed down with `#v(1fr)` instead, it reaches the foot of the
slide in the PDF and falls below the stage in the browser. Inside a reveal the
browser sets the piece in a frame of its own that begins where the piece
begins, and a `place(bottom + …)` in there lands lower in the HTML than in the
PDF, down to below the stage. At the top it aligns against the body, and does
so in both.

On the title and the section slides it has to go into the theme: both are
functions, and a function wrapped around another adds to it instead of
replacing it.

#show-code[```typ
#let base = themes.default
#let with-foot(f) = (t, s, geo) => { f(t, s, geo); footline }

#show: presentation.with(
  theme: base + (title-slide: with-foot(base.title-slide),
                 section: with-foot(base.section)),
)
```]

#warning[
  *Not through `style:`.* `style: it => { footline; it }` looks like the
  shortcut that puts the footer on every slide at once. But `style` is also the
  template each moving element is typeset with a second time, so whatever
  *draws* in there is drawn again inside every sprite: a deck with three
  reveals per slide showed the footer four times over. In the body it is drawn
  once.

  `style:` is for typography -- typeface, size, colour, leading -- and for that
  it is exactly right: background and sprite need the same.
]

#info[
  A footer placed in the body sits at the bottom of the *body*, not at the
  bottom of the slide; the theme's `foot-gap` lies in between. A `dy:` on the
  `place` moves it where it belongs.

  Being part of the body, it is part of the slide: a `camera` takes it along
  and it can leave the frame, while the built-in number stays put (see "What
  travels along and what stays put").
]

#warning[
  `info()` reads the state of the slide being typeset and therefore needs a
  `context` around it. *Before* the presentation there is nothing to read, and
  it stops with a message rather than handing out zeros. *After* it there is:
  whoever passes the slides as arguments and writes an `info()` below the call
  still gets the last slide's numbers. In the show-rule notation nothing comes
  after the deck anyway.
]


=== `deck-outline()`: how the deck is cut

`info()` says *where* you stand, not how the whole thing is divided. A
navigation bar needs exactly that: which slides belong to which section.
`deck-outline()` hands it over, one entry per section, in the order they
come:

// check: folie
#show-code[```typ
#context for a in deck-outline() [
  - #a.number. #a.title -- slides #a.first to #a.last (#a.count)
]
```]

Each entry carries `depth`, `number`, `title`, `target`, `first`, `last`
and `count`. `target` is the slide of the section itself -- what you need
to link to it, as `contents()` does.
`first`, `last` and `count` are *transitive*: a depth-1 section counts the
slides of its sub-sections too, so a bar does not show a zero for every
top-level heading. A section with nothing under it has `none` for `first` and
`last`, and `0` for `count`.

Only headings standing *between* slides count. A heading *inside* a slide,
`slide(none)[= Every map lies]`, is a slide title and opens no section; a deck
written exclusively that way gets an empty list back. So put the `=` between
the slides, not into them; `examples/gliedern.typ` shows how.

#info[
  It reads only what every slide already carries -- no `query`, no second walk
  over the document, the same answer in both outputs.
]

#warning[
  A foreign package looking for the structure through `query(heading)` finds
  nothing: the heading notation splits the body at its headings and copies
  `depth` and `body` out, dropping the element itself. That holds in *both*
  outputs. `deck-outline()` is the answer to it.

  Two more traps wait one step further in, and both were found the hard way by
  a companion package. Every slide is set inside an `html.frame`, and in there
  a `location` collapses to page 1 at (0, 0) -- so anything that groups by page
  sees one group for the whole deck, in the PDF as well. And `target()` reports
  `"paged"` inside that frame even while an HTML file is being written, so it
  cannot be used to tell the two apart either. `info()` and `deck-outline()`
  avoid both: they carry the structure themselves instead of reading it back
  out of the document. `info().levels` in particular answers "which section is
  this slide in" without a single query.
]

=== `contents()`: a linked agenda

`contents()` turns the deck outline into links that work in both HTML and PDF.
Put it on a regular slide, since a section slide has no body:

// check: folie
#show-code[```typ
== Contents
#contents(layout: "1x2-fill")
```]

It lists the sections: the headings above `slide-level` between the slides, or
the `section` calls where the slides are handed over as arguments. A deck
without any -- in heading notation at the default `slide-level: 2`, one without
an `=` -- gets an empty list, and no message says so.

`layout: "1x1"` is the default single-column list. `layout: "1x2"` creates
balanced columns, while `layout: "1x2-fill"` fills the first column by
available height before flowing into the second. For a long agenda, use the
inclusive, one-based `from:` and `to:` range on multiple slides:

// check: folie
#show-code[```typ
== Contents 1
#contents(layout: "1x2-fill", from: 1, to: 8)

== Contents 2
#contents(layout: "1x2-fill", from: 9, to: 16)
```]

A deck with more than one structure level indents the deeper ones. `indent:`
takes a length of your own, or `none` to set every level flush:

// check: folie
#show-code[```typ
== Contents
#contents(indent: none)
```]

`highlight: true` says where the talk stands: the running part and chapter keep
the full ink, everything before and after steps back. That is the agenda between
two parts, the one that shows the audience how far along they are.

// check: folie
#show-code[```typ
== Where we are
#contents(highlight: true)
```]

`number:` replaces the complete number cell and receives one outline entry.
`title:` replaces the complete linked title cell and receives the entry and
its destination. Both renderers can therefore control their own typography.
Every entry carries `when`, which is `"past"`, `"running"` or `"coming"` --
so a highlight of your own needs no arithmetic of its own:

// check: folie
#show-code[```typ
== Contents
#contents(title: (entry, to) => link(to, text(
  fill: if entry.when == "running" { blue } else { gray },
  entry.title,
)))
```]
Use `number: none` to remove the number cell and let the title use the full
item width.
Section slide titles carry no number of their own.
`section-numbering:` on `presentation` puts one in front -- a numbering
pattern such as `"1."`, or a function that receives the section number.

*The link back, at the foot of a section slide*

Every section slide carries a link back to the contents. `section-back:` on
`presentation` says what it reads:

#show-code[```typ
#show: presentation.with(section-back: [Back to the agenda])
```]

Four values. `auto` is the default and takes the word from the deck's language.
`none` leaves the link out on every section slide. Content or a string words it
differently. And a function receives *one* dictionary and returns content -- or
`none`, and then that one slide goes without:

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 0pt, y: 4pt),
  column-gutter: 1em,
  table.header([*Field*], [*What it holds*]),
  [`back.location`], [the `location` of the contents slide, ready for `link()`],
  [`back.word`], [the default word in the deck's language],
  [`back.contents.number`], [the printed slide number of the contents],
  [`back.section.number`], [the number of the section this link stands on],
  [`back.section.title`], [its title, with the `section-numbering` prefix],
  [`back.section.depth`], [its structure level],
  [`back.section.parents`], [the titles above it, outermost first],
)

#show-code[```typ
#show: presentation.with(
  section-back: back => [#back.word (slide #back.contents.number)],
)
```]

The place stays with the theme, the body comes from the deck. Because the body
sits *inside* the theme's `text`, a `text` of your own within it wins -- which
is how the link gets another colour or size, on a ground where the accent reads
too quietly:

#show-code[```typ
#show: presentation.with(
  theme: themes.editorial,
  section-back: back => text(fill: white)[#back.word],
)
```]

Three things this will not do, and one you may do by accident. A `link()` of
your own in the body beats the outer one -- the link then leads there and *no
longer* to the contents; that is the way to another destination, and the trap.
`info()` inside the function names the slide *before* the section slide, the
same way it does in a `show` rule; for the number of the contents take
`back.contents.number`, which is there for exactly that. With no `contents()`
in the deck nothing appears at all, and the function is not even called. And the
parameter gives no other *place*: for that there is `section-back: none` and a
`section` function of your own in the theme.

A `show` rule on `ts-section-slide-back` has the last word over the parameter.

= Handing it on

Getting the talk to where it will be given.

== One file

`assets: "inline"` is the default and writes the runtime into the HTML. The
result is one file that runs from a memory stick, from a download folder, from
an email attachment. No server, no network, nothing loaded afterwards. The
runtime adds about 330 KB to every deck.

== Beside the file

`assets: "split"` refers to two files next to the HTML instead, and
`runtime-files` gives you their names and contents so you can write them out:

#show-code[```typ
#for f in runtime-files {
  // f.name and f.content
}
```]

That is worth it where many decks are published together: the browser caches
the runtime once, and every deck after the first pays nothing for it. On short
decks that is about half of what visitors load.

`assets: (cdn: "https://…")` points at a directory on a server or a CDN. It
takes a dictionary, not a bare string: a string falls through unread, and the
page then links names that are not there.

== The address of a step

The address bar says where the talk stands -- not only which slide, but which
step on it:

#show-code[```typ
// talk.html#slide-3      slide 3, its first step
// talk.html#slide-3-2    slide 3, second step
// talk.html#speaker      the speaker view
```]

The link can be copied and passed on; whoever opens it stands exactly there.
The numbers are the slide numbers, counted from one, and a step that does not
(or no longer) exist leads to the last one of its slide rather than nowhere.

#info[
  *Until 0.1.2 the running step over the whole deck stood there* (`#7`). Such a
  link held only until the next slide was inserted: everything behind it moved
  on. It is still read, so old bookmarks keep working, but no longer written.
]

== Hosting

The HTML file is static. Anything that serves files serves it: GitHub Pages, a
university web space, an S3 bucket.

Media travels beside the file. `video("clip.mp4")` refers to a file that has to
lie next to the HTML; without it an uploaded deck shows an empty frame where it
worked locally.

A deck opened from `file://` behaves like one from a server, speaker view
included.

= What it cannot do

The limits, in one place, so they are not discovered in front of an audience.

== Accessibility

The hardest limit, and it follows from the design decision on the first page.
The slides are SVG outlines: the letters in them are drawn as paths, not as
text. Nothing is selectable, nothing is searchable, and a screen reader finds
nothing to read -- no text alternative, no reading order.

What does work: the document carries a `lang` attribute from `text.lang`,
navigation is fully operable from the keyboard, and colour and contrast are
the theme's and therefore yours to set. A viewer whose system asks for less
motion gets less: `prefers-reduced-motion` is read at run time. For the same
everywhere, set `transition: "none"` and `enter: "none"`.

#warning[
  If someone in the room reads with a screen reader, hand out the PDF as well
  and say what is on each slide. The PDF from the same source carries real
  text.
]

== A tracked element with no area

A tracked element takes its place in the browser from a rectangle Typst paints
around it. Content with no area leaves that rectangle with none either, and a
viewport of zero scales everything inside it to nothing: the element is in the
page and cannot be seen. On paper it stands.

The two usual cases -- a vertical rule and a `place` -- are handled by the
package itself.

// check: folie
#show-code(```typ
#anim(at: 2, place(top + left, dx: 20pt, dy: 50pt,
                   rect(width: 20pt, height: 20pt)))
```)

The rest is reported, not lost: a marker with no width, one with no height,
and one nested deeper than four tracked elements each print once to the
browser's console.

#show-code[```
typstage: the tracked element 3 on slide 4 has a marker with no width.
Its sprite is given a viewport of that extent, and a viewport of zero
scales everything inside it to nothing: the element is in the page, with
its path and its colour, and cannot be seen. On paper it stands. Put it
in a box with a size, or give the element a width.
```]

The check can only run in the browser. Whether content has an area is not a
question the document can answer; only there is the rectangle measurable.

== Reach

Tested in Chrome, Firefox and Safari on macOS, and on an iPhone. Not tested:
older browsers, Windows, Android. The runtime uses the Web Animations API,
`ResizeObserver`, `PointerEvent` and CSS `zoom`, so a browser from before about
2023 is likely to fall short somewhere.

== Size and speed

A slide is typeset once per state, and every tracked element once more, in a
frame of its own. Compile time therefore grows with steps, not with slides,
and `flipbook` grows with frames.

The example decks compile in seconds, and as HTML they weigh between 0.70 and
6.22 MB, the tour with its 48 slides the most. A hundred slides with a flip
book on each is a different matter -- measure it rather than guess.

= When nothing happens

The traps, in roughly the order they are usually hit.

/ No HTML export: `--features html` is missing. The export is experimental in
  Typst, not in this package.
/ The deck is empty but for the title: the two notations have been mixed.
  Either write `= …` and `== …`, or hand `slide(...)` calls to `presentation`.
  A `slide(...)` inside the body of a show rule makes no slide and no error
  either.
/ The first paragraph is missing: content before the first heading belongs to
  no slide. Text there stops the compile — see "Text that belongs to no
  slide". An image there goes without a word.
/ The slide titles ignore a `#set heading`: the `#set` comes after the show
  rule, so the titles are already outside its reach. `style:` reaches them.
/ `#pause` does nothing: it sits in a grid cell or a table, and there is no
  body there to split. `anim` goes anywhere content goes.
/ A transition or an entrance is refused by name: the package does not know it.
  The message names every effect there is.
/ The bullets beside an applet start at step three: `embed` uses no step, but
  something before it did. Count the reveals, not the elements.
/ The build warns "document did not converge": look for a `context` that
  stands around a reveal and hands it what it read, as in
  `#context anim[#bridge-targets().len()]`. The reveal then holds an answer
  that may still change from one layout run to the next, instead of a question
  that never does. Put the `context` inside: `#anim(context
  bridge-targets().len())`. In the tour deck that took two warnings to none.
/ A flying equation has the wrong font: a tracked element is typeset in a frame
  of its own, which `#set` does not reach. `style:` on `presentation` does.
/ An embedded frame stays empty and gets no jobs: the document has not
  announced itself with `postMessage({typstage: 1, ready: 1})`.
/ An applet frame stays empty: the applet comes from `geogebra.org`. Without a
  network, point `codebase` at a local copy.
/ A `ggb-run` command has no effect: it is one of GeoGebra's scripting
  commands, which `evalCommand` does not accept. Use `ggb-set`, `ggb-style`,
  `ggb-show` or `ggb-hide` instead.
/ The build stops naming two applets: two frames on one slide and no `target`.
  Nothing is guessed.
/ The applet's colours change after paging back: GeoGebra takes the next
  colour of its palette on a rebuild. Fix the colour on `"1-"`.
/ A circle in the applet is an ellipse: the x range and the y range of
  `ggb-view` do not match the shape of the box.
/ A tween does not play: it sits on step 1, where tweens are set to their
  target instead of played, or it was given a range instead of a step number.
/ Two sliders lie on top of one another: for a slider made with `Slider`,
  `position` counts in pixels, not in coordinates.
/ A point cannot be dragged in the speaker view: it was made with
  `Point(k, 0.3)` and is pinned to that parameter.
/ An embedded frame is right on the laptop and tiny on the projector: its
  content is sized in `px` instead of `em`. Inside a zoomed frame one CSS pixel
  is one point of the slide.
/ "constructing a document is only supported in the bundle target": the file
  uses `bundle` and therefore needs `--format bundle`.
/ The speaker view does not open: `window.open` needs a real keypress; a
  script cannot stand in for it.

= API reference

Generated from the comments in the source files: presentation and slides
first, then the building blocks, then media and the bridge, and last the
measurements and colours.

== The presentation

// `split-body`, `pause-tokens` and `apply-pauses` take the body apart and are
// not part of the public surface, and neither is `ueberschrift-tiefe`, the
// helper `split-body` reads a heading's level with, nor
// `zaehler-je-dokument`, the one `bundle` sets counters back with.
#show-module(read("../src/present.typ"), name: "typstage",
             exclude: ("split-body", "pause-tokens", "apply-pauses",
                       "slides-from-body", "stiller-lauf",
                       "ueberschrift-tiefe", "zaehler-je-dokument"))

== Slides

#show-module(read("../src/slides.typ"), name: "typstage")

== Revealing, moving, staggering

// `anim-kern` is the checked inside of `anim`, used by `stagger`; `lib.typ`
// does not hand it out. The same holds for the helpers of `scene`.
#show-module(read("../src/elements.typ"), name: "typstage",
             exclude: ("anim-kern", "szene-drift", "szene-messbar",
                       "szene-zwischen"))

== Layouts

#show-module(read("../src/layout.typ"), name: "typstage")

== Themes

// Only the blueprint and the five ready-made ones.
#show-module(read("../src/themes.typ"), name: "typstage",
             only: ("theme", "themes"))

== Palettes

// Only what `lib.typ` hands out.
#show-module(read("../src/palettes.typ"), name: "typstage",
             only: ("palettes", "contrast", "palette-report"))

== Media and embeds

// `fallback-box` is internal; `embed` and `geogebra` use it for paged output.
#show-module(read("../src/media.typ"), name: "typstage",
             exclude: ("fallback-box",))

== The bridge

#show-module(read("../src/bridge.typ"), name: "typstage")

== GeoGebra

// `resolve-target` and `no-stray-target` are internals, as is `applet.typ`.
#show-module(read("../src/geogebra.typ"), name: "typstage",
             exclude: ("resolve-target", "no-stray-target"))

// The same bridge, a different calculator. `boot` and `resolve-target` are
// internals.
#show-module(read("../src/desmos.typ"), name: "typstage",
             exclude: ("resolve-target", "boot"))

== Measurements, colours, runtime files

// Only what `lib.typ` hands out as well.
#show-module(read("../src/config.typ"), name: "typstage",
             only: ("slide-width", "slide-height", "slide-margin",
                    "dark", "accent", "paper", "muted",
                    "runtime-version", "runtime-files"))
