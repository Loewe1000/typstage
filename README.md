# typstage

**Animated HTML presentations from a single Typst file, and the slide set and
the handout as PDF from that same file.**

```bash
typst compile deck.typ deck.html --format html --features html   # the animated talk
typst compile deck.typ deck.pdf                                  # slides and handout
```

![A slide of a typstage deck in the browser, halfway through its reveals](assets/slide.png)

**Try it without installing anything:** [fifteen example decks](https://loewe1000.github.io/typstage/beispiele/), running in your browser. They are written as talks somebody might actually give rather than as feature demos: a tour of the package itself, how GPS finds you, why the four margins of a book are unequal, a school lesson on completing the square, a night of rolling deployments, and Simpson's paradox. Four more were built around what the package learned to do last: a pendulum that beats seconds, drawing its own geometry and growing its diagrams a stage at a time; a door that slams, sticks or settles, pulled from one damping value to the next; John Snow's cholera map, where the class calls out what it sees and the lecturer reveals it in the order it is named; and one about dressing a deck, which computes every contrast ratio it quotes. Three are rebuilt from the [mosaic](https://github.com/vincentarelbundock/mosaic) package's own decks, to see what carries across. Two show GeoGebra: one where the slides drive the applet, one where a hand drives it from the speaker window.

## Typst sets, the browser moves

The usual route from Typst to a presentation is a PDF in which every step
occupies a page of its own; nothing ever moves. Typst's own HTML export goes
the other way and leaves the arrangement to the browser, which loses exactly
what Typst is used for.

typstage takes a third route. Every slide is typeset by Typst and written into
the HTML **as SVG**, so what stands in the browser stands there the way Typst
set it, to the point, and it is the same layout the PDF shows. Only then does anything
move: whatever should stir is announced in the source, and a small runtime
moves it with the Web Animations API.

One source, three outputs:

| | |
| --- | --- |
| **Animated talk** | a single self-contained `.html`: reveals, magic move, slide transitions, video, embedded documents. Double-click it; no server, no network, nothing to install alongside |
| **Slide set** | one PDF page per slide rather than one per step, with every tracked element in its final state |
| **Handout** | `handout: 3` puts the same slides on A4, speaker notes or ruled lines beside them |

## A complete deck

This file compiles, as it stands, with both commands above.

```typ
#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [The Pythagorean Theorem],
  author: [A. Schulz],
  transition: "slide",
)

= Proof by rearrangement

== Four triangles in a square

#side-by-side(
  card(title: [The setup])[
    Four copies of the triangle fit into a square of side $a + b$.
  ],
  stagger[
    - The inner square has side $c$
    - Rearranged, the same four copies leave $a^2 + b^2$
  ],
)

#v(1fr)

#callout(title: [Remember])[
  The leftover area cannot change. Only its shape does.
]

== The claim

#align(center, morph(<pythagoras>, $a^2 + b^2$))

== #h(0pt)

#place(center + horizon,
       morph(<pythagoras>, text(size: 2.6em)[$a^2 + b^2 = c^2$]))
```

`=` opens a section slide, `==` a slide, `== #h(0pt)` a slide without a title
band. `stagger` reveals a list point by point, and the same
`morph(<pythagoras>)` on two slides makes the formula fly from the one place to
the other, growing on the way. Nothing carries a step number: `at` is `auto` by
default and means *the next free step*, so consecutive reveals number
themselves. Names are labels or strings: `morph(<pythagoras>, …)` and
`morph("pythagoras", …)` are the same thing.

For a slide that simply unfolds, nothing needs wrapping at all:

```typ
== A slide that unfolds

First this.

#pause

Then that.
```

`slide-level:` moves the cut: with `slide-level: 3` a `=` and a `==` are both
section slides and `===` is the slide, so a semester fits into one file with
its transition slides falling out by themselves. `info().levels` and
`info().outline` hand the structure back for an agenda of your own.

Slides may also be handed over as arguments, `presentation(title-slide(…),
section([…]), slide([Title])[…])`, for decks that are generated rather than
written.

## The building blocks

| | |
| --- | --- |
| `presentation` | builds the deck: slides as arguments, or a show-rule body split at its headings |
| `bundle` | writes talk, slide set and handout in a single compile |
| `slide`, `section`, `title-slide` | the three kinds of slide |
| `anim`, `stagger`, `pause`, `alternatives` | reveal one thing, a series of things, everything after this point, one thing after another in the same place; `anim(after: "dimmed")` lets a point stay muted once its range is over, and `stagger(dim: true)` walks a list that way, the current point lit and the earlier ones quiet |
| `build` | a CeTZ drawing or a lilaq diagram that comes into being step by step: the drawing is written once and set once per stage, and a piece that is not due yet stands there as air — alpha 0, invisible but still holding its room, so the picture never shifts |
| `scene`, `scene-layer` | a drawing as a function of a value, plus the values at which the talk stops: Typst renders every stop and the frames in between, and a keypress pulls the picture from one stop to the next — manim's `ValueTracker` in the step model of a talk. `scene-layer` puts a sentence or a formula on the step of one particular stop |
| `morph`, `pin` | magic move across slides; `pin` names a glyph so the pairing follows the name rather than the shape |
| `camera` | move in on one detail of the slide and back out again, as a step of the talk. It aims at a `pin` and looks its rectangle up while the talk runs, so the deck names a name and never a coordinate. The slide's furniture stays put; on paper there is no camera and the slide is set whole |
| `card`, `callout`, `side-by-side`, `tiles`, `statement` | layouts inside a slide; `tiles` staggers itself, and `side-by-side(equal: true)` makes its columns the same height |
| `fit` | scales one block down to the room it has, for a wide table or a generated chart; no reveal may sit inside it |
| `overflow:` | a checking pass, off by default: `"error"` builds the deck and then names every slide whose body runs over its room, with the step; `"record"` files the same as queryable metadata |
| `drift:` | the second checking pass, and this one is on: every `scene` measures its frames and the ones that come out different sizes are named, because a drawing is as large as what it holds and a wider frame puts it somewhere else in its box. `scene(steady: false)` says the frames of one scene are meant to differ |
| `cue`, `cue-layer` | reveal points in the order a class calls them out; the digits `1` to `9` choose, and anything hung on the same step travels with the point |
| `info` | what the deck knows about itself: title, slide and step number, section, and with `slide-level` the whole outline — for a footer, a running head or an agenda of your own |
| `transition`, `speaker-note` | how this slide comes in, and what only you see |
| `themes`, `theme` | the five built-in looks, and the builder behind them |
| `palettes`, `palette:`, `invert` | colour separately from design: five bundled palettes that compose with every theme, a partial override on `presentation`, and one slide set in the palette turned around |
| `contrast`, `palette-report` | the WCAG contrast of two colours, and the seven pairs the bundled palettes are held to |
| `video`, `embed`, `flipbook` | media, arbitrary web content in a sandboxed frame, and animation drawn frame by frame by Typst |
| `bridge-job`, `bridge-targets` | send step jobs into an embedded document, which is how a companion package drives an applet |
| `geogebra`, `ggb-run`, `ggb-set`, `ggb-show`, `ggb-hide`, `ggb-style`, `ggb-view`, `ggb-animate`, `ggb-tween` | a GeoGebra applet on the slide and the jobs that drive it step by step; the applet itself is fetched from `geogebra.org` at run time |
| `slide-width`, `slide-height`, `slide-margin`, `dark`, `accent`, `paper`, `muted` | the defaults behind `width:`, and the four colour constants of the default look |
| `runtime-version`, `runtime-files` | the CSS and the JS, for `assets: "split"` and for CDNs |

Every one of them is documented in full, with examples, in the manual
(`docs/content.typ`, see below).

Twelve slide transitions (`fade`, `slide`, `push`, `cover`, `uncover`, `zoom`,
`blur`, `iris`, `wipe`, `flip`, `cube`, `none`), set for the deck or for a
single slide, each of them a true reversal when you page backwards. Entrances
(`enter:`) work the same way: paging back takes the entrance away again.

Eleven entrances, one of which is not a fade: `enter: "draw"` traces every
stroked path of an element, so a circuit or a pair of axes comes into being
line by line. Text keeps to the fade -- Typst sets glyphs as filled shapes with
no outline to travel along -- and an element on which nothing can be traced
says so instead of quietly fading. `easing:` names the curve an element moves
on, from the Web Animations API plus a handful of named ones; an unknown name
is an error, not a silent default.

## Themes

```typ
#show: presentation.with(theme: themes.night)
#show: presentation.with(theme: themes.lesson + (accent: blue))
#show: presentation.with(theme: themes.lesson, palette: palettes.dark)
```

![The same slide in the five built-in themes: default, lesson, night, plain, editorial](assets/themes.png)

A theme is a dictionary: colours, fonts, sizes, and one word each for the few
built shapes (`header`, `footer`, `progress`, `box`). That is why `+` is enough
to bend one, and `theme(…)` builds a new one from scratch. `header: "run"`
gives a slide the running head of a textbook page, slide number on the left and
the current section on the right; `box: "label"` builds cards the way a
textbook does, a tinted panel with its label inside rather than a coloured bar
above. Only the title slide
and the section slide are functions in it: they are whole pictures, not
variations of one another.

## Palettes and the contrast contract

Colour is a thing of its own. `palette:` takes a flat dictionary over the eight
colour entries and overwrites *partially*, so `palette: (accent: blue)` moves
the accent alone. Five ship with the package, `light`, `mono`, `textbook`,
`parchment` and `dark`, and each composes with each theme: darkness is a
palette rather than a design, and `themes.lesson` under `palettes.dark` is
still the lesson design, only dark. `themes.night` stays a theme all the same,
because its cyan is tuned to its own ground -- it measures 9.77 to 1 there and
1.59 to 1 on the ground an inverted slide puts behind it.

Reading `themes.X.title-fill` or `.rule-fill` no longer gives a colour: they
are now functions of the palette, or `none` for "the accent". Writing them
(`themes.X + (title-fill: red)`) works as before.

`invert` sets one slide in the palette turned around, for the slide that
carries a single number: the ground becomes the palette's text colour and the
text becomes its ground, `muted`, `border` and `surface` are mixed from those
two, and `strong` and `accent` carry over unchanged. The running head, the
footer and the progress bar follow.

The five bundled palettes, and their inverted forms with them, are held to a
measured contrast contract: real WCAG 2 arithmetic over six pairs, enforced by
an assertion that runs when the package is loaded. **Your own palettes face no
such gate**, and neither do the bundled *themes*: run over those, the contract
finds `muted` at 4.25 in `lesson`, at 3.35 in `plain` and at 3.51 in
`editorial` against the 4.5 body text wants, `accent` at 2.84 in `editorial`
against 3.0, and `accent` on `ink` at 1.59 in `night` and 1.27 in `plain`. Only
`themes.default` passes all six. Those colours were left alone; the manual says
why, and `palette-report(…)` hands the same measurement back for any palette.

## In the browser

The runtime counts in **steps**, not slides: a slide with three reveals has
three steps, and `→` goes to the next one wherever it is.

| key | |
| --- | --- |
| `→` `←`, space, page keys | one step on, one step back |
| `Home`, `End` | first and last step, without motion |
| `o`, `Esc` | overview of all slides |
| `f` | full screen |
| `s` | the speaker note for this slide |
| `p` | print view: one slide per page, everything visible |
| `n` | open the speaker view in a second window |
| `?` | the key map |

Clicking the left quarter of the window goes back, anywhere else forward. On a
phone or tablet the same works with a finger, and so does swiping: right to
left brings the next slide, the other way the previous one. The address bar
carries the current step (`#12`), so a reloaded window stands where it stood.

Where the operating system asks for **reduced motion**, the deck obliges:
opacity stays, travel goes. Entrances and slide transitions become plain
cross-fades of the same length, the magic move does not fly, and a flip book
stands still on one frame. Dimming stays as it is, and a video keeps playing.
The setting is read afresh on every step, so it takes effect at once; there is
nothing to configure and no way for a deck to overrule it. See "Less motion" in
the manual.

## The speaker view

`n` opens the same file a second time, with `#speaker` on the address, in a
second window. Put that one on your laptop and the first one on the projector.
The two talk to each other with `postMessage`, which works between two local
files as well, so this needs no server either.

The speaker view shows the running slide large, the next **step** beside it
(not the next slide: a deck that counts in steps has to answer what the next
keypress does), the note below, and a clock, an elapsed timer and a pace
against a target duration you can type in.

You can draw on the running slide there, and the strokes appear on the
projected one. Strokes stick to their slide, so paging away and back brings
them with you; `x` clears the current slide, `z` takes back the last stroke,
`c` changes colour. `b` blacks the room out, `e` freezes the projected image
while you page ahead in private, and both end by themselves if the speaker
window goes away.

`t` puts a clock on the wall that the class can see: black ground, white
digits, `m:ss`, large enough for the back row, in place of the slide rather
than on top of it. It is for the break and the group work — `⇧→` and `⇧←` add
or take a minute while it runs, `t` again ends it, and so does paging on. Past
zero it counts up in the deck's accent colour with the word "over" above it,
capped at the duration and at thirty minutes. Use it when nothing else is on
the wall; no clock while you are talking.

`m` switches the pointer between pen and embed. In pointer mode the pen rests
and a click on an embedded frame reaches the projected one instead: the same
spot, the same gesture, in whatever size that window happens to have. Where the
embedded document can mirror itself, as a GeoGebra applet does, you operate the
live one in front of you and the projected copy follows.

Steering works from either window, and either one may be reloaded: they find
each other again and the strokes come back.

## On paper

The PDF has one page per slide in the size of the canvas. Everything that moves
in the browser stands there in its final state. What belongs to the motion
alone, the notes, the transitions, the jobs for embedded elements, produces no
output and falls away by itself. Where a frame or an applet stands in the browser, `embed` takes
a `fallback` (any content at all, a CeTZ drawing, an image) and a `link` that is
clickable in the PDF.

One argument turns the slide set into a handout:

```typ
#show: presentation.with(handout: 3)   // three slides per A4 page
```

![A handout page: three slides down the left, notes and ruled lines beside them](assets/handout.png)

`handout` takes `true` (two per page) or a number from 1 to 6, and only affects
the PDF; the HTML ignores it. The slides are not re-set, only shrunk, so the
handout cannot drift away from what stood on the screen. Beside or below each
slide stands its `speaker-note`; where a slide has none, ruled lines take its
place.

### All three in one run

Typst 0.15 can write several files from one compile, which suits a package
where talk, slide set and handout come from the same source and differ only in
their target:

```typ
#bundle(
  theme: themes.lesson,
  title: [Completing the Square],
  handout: "handout.pdf",
)[
  = A section
  == A slide
  Text.
]
```

```bash
typst compile --features bundle,html --format bundle talk.typ out
```

The counters start again for each output, so the slide set numbers its slides
from one rather than carrying on where the HTML left off. Two things to know:
bundle export is experimental in Typst and needs the feature flag, and a file
that calls `bundle` can only be compiled with `--format bundle`. To keep both
routes open, put the body in a `#let` and call `presentation` yourself.

## The canvas

16:9 on an A4-width canvas by default, so a slide and a handout page carry text
at the same physical size. Any other shape is one to three arguments:

```typ
#show: presentation.with(width: 800pt, height: 600pt)   // 4:3
#show: presentation.with(margin: 48pt)                  // more air
```

Everything the theme draws, the title band, the type sizes, the rules, is
measured on the default canvas and scaled with the width, so a narrower deck
looks the same, only smaller. Only the *ratio* really changes the layout, and
the browser follows it, stage, overview thumbnails and printed pages alike.

## CSS and JavaScript

```typ
#show: presentation.with(assets: "inline")                          // default
#show: presentation.with(assets: "split")
#show: presentation.with(assets: (cdn: "https://cdn.example.org/ts/"))
```

`"inline"` puts both files into the HTML, one file that can be mailed, put on
a stick and opened without a network. `"split"` links `typstage-0.1.0.css` and
`.js` next to the HTML, a CDN the same names under the given address; the names
carry the version so several releases can live side by side. Typst creates no
files: write the two out once from `runtime-files`, which the bundle export can
do in the same run.

## Installation

The package lives in the local `@schule` namespace and is **not on Typst
Universe**. Clone it under the package path:

```bash
git clone https://github.com/Loewe1000/typstage \
  ~/Library/Application\ Support/typst/packages/schule/typstage/0.1.0
```

On Linux that path is `~/.local/share/typst/packages/schule/…`, on Windows
`%APPDATA%\typst\packages\schule\…`.

Needs Typst 0.15. The HTML target additionally needs `--features html`; nothing
else, no Node, no bundler.

## What it cannot do

- **Typst's HTML export is experimental.** Every HTML run needs
  `--features html` and prints a warning, and the export may change under you
  from one Typst release to the next. That is Typst's building site, not this
  package's, but you stand on it. The PDF side uses no experimental features.
- **The slides are SVG outlines, not text.** Glyphs go into the file as paths,
  so nothing in the browser is selectable, searchable or reflowable, screen
  readers see nothing, and the file grows with the deck. Measured: the little
  deck above weighs 211 kB, the fifteen example decks between 0.54 and 3.3 MB,
  and the largest of them holds 127 SVG trees with 5581 glyph references across
  23 slides. In exchange no font has to load and the layout cannot drift.
- **`#pause` is read at the top level of a slide body only.** Inside a grid
  cell, a table or a figure it is not seen, so reach for `anim` there.
- **GeoGebra is not in the box.** A typeset applet is an empty frame that
  fetches GeoGebra from `geogebra.org` when the page is shown. Without a
  network it stays empty, the viewer's browser talks to that host, and what
  runs in the frame is under GeoGebra's terms rather than this package's MIT
  licence. `codebase` points the frame somewhere else, at a local copy for
  instance. The PDF fetches nothing.
- **Not on Universe**, so `@preview` will not find it and there is no version
  resolution: you install it by hand, as above.
- **German in places.** The manual is German throughout and the API comments
  are mixed German and English. The two strings the runtime shows for itself,
  the `?` help line and the note of a slide that has none, follow the
  document language and exist in German, English and French; anything else
  falls back to English.
- **Five themes, not a theme ecosystem.** They differ in colour, type and the
  shape of header, footer and progress bar, not in slide layouts. Anything
  further is a dictionary entry, a `style:` wrapper, or plain Typst.
- **The contrast contract binds the bundled palettes only.** A palette written
  in a deck is never checked and never recoloured, and no colour is inferred
  from the lightness of another: a muted sage such as `#aebdb3` reads as
  "light" to a luminance rule, yet white on it measures 1.96 to 1.

## Documentation

The [manual](https://loewe1000.github.io/typstage/) covers steps, magic move,
transitions, media, the bridge and a full API reference. It is published from
this repository, together with the [example decks](https://loewe1000.github.io/typstage/beispiele/).
The German source is `docs/content.typ`, the English one `docs/content-en.typ`.

| | Website | PDF |
| --- | --- | --- |
| English | [en.html](https://loewe1000.github.io/typstage/en.html) | [typstage-en.pdf](https://loewe1000.github.io/typstage/typstage-en.pdf) |
| German | [index](https://loewe1000.github.io/typstage/) | [typstage.pdf](https://loewe1000.github.io/typstage/typstage.pdf) |

One run gives the printed manual, the website and its stylesheet:

```bash
typst compile docs/docs.typ build --format bundle --features bundle,html --root .
```

The site build also writes [llms.txt](https://loewe1000.github.io/typstage/llms.txt),
one line per chapter with its title and first sentence, in both languages. It is
generated from the built pages, so its anchors cannot go stale.

`example.typ` in the repository is a deck that exercises everything: reveals,
magic move, an embedded live canvas, a CeTZ flipbook. It is not shipped with
the package, so build it from a clone.

### The examples in the manual are compiled

Every `typ` listing in both manuals is compiled against the real package before
the site is built, so a renamed function or a changed signature cannot leave a
listing behind:

```bash
python3 .github/scripts/pruefe-beispiele.py
```

Most listings are fragments rather than whole files, so the run wraps each one
in a deck and a slide before compiling it. That is what it checks: that the
code compiles in such a wrapper, not that the slide looks right. Where a
fragment needs more than the wrapper gives it, a `// check:` line above the
listing says so; the header of the script lists the words it takes. Listings
that show what does *not* work are marked, have to keep failing, and say what
they have to fail at -- a listing that breaks for some other reason is a failed
check, not a passed one. The build runs this first and stops on it.

What it does not reach: the prose beside a listing, listings in `bash` or
`json` (it names how many it left alone), the paged output, and anything that
compiles without doing what it claims -- a show rule on a label that no longer
exists still compiles.

### The decks are driven in a browser

Compiling proves nothing about motion. A second run loads the fifteen example
decks and a sixteenth check deck into a real browser, pages through every step
forward and backward, and holds the numbers against a written record:

```bash
bash .github/scripts/build-site.sh          # the decks it measures
node .github/scripts/pruefe-decks.js
```

No npm and no Playwright. Chrome is reached over the DevTools protocol and
Firefox over WebDriver BiDi, with what node 22 already brings; the two drivers
together are under 150 lines. Whether this package can be checked should not
depend on a several hundred megabyte download. Playwright may be put beside it
for WebKit or for the two window case; it is not a prerequisite.

The runtime carries the surface the run reads, `window.typstage.pruef`, and it
is always there rather than behind a build switch: a switch would mean checking
a runtime that is not the one shipped. Measured over the six decks without an
applet it costs between 0.47 and 0.84 percent of the compressed page. Two parts of it are what
make the run repeatable. `ruhig()` resolves when no animation is running
anymore and replaces every fixed wait, and `uhr(ms)` pins the wall clock a
flipbook reads. Five runs at three animation speeds in two browsers produced an
identical record, down to the ghost counts; the report's header carries the
duration, the browser and the speed and differs by design.

A third part makes a `cue` slide visible to the run at all. An adaptive group
is worked by the digit keys, and `goto()` presses none: it moves to a step, but
an unnamed point stays put far behind the last step of the deck, so a run that
only pages sees `0/0` on such a slide and takes that for the finding. Measured
on `vortragen`: 13 of its 44 steps. `ziffer(n)` names a point and `punkt()`
takes the next in written order, exactly as the digit and the arrow do; the run
names them in written order, because a speaker may choose any other and a
written record cannot depend on his mood.

The written record is `.github/scripts/decklauf/soll.json`, rewritten with
`--neu-soll` and only on purpose. Three of its entries depend on the fonts
of the machine rather than on the package: the fingerprint of the check deck's
typeset output, its length, and the node count of the speaker preview. The same
commit measures 546292 bytes on macOS and 500912 on an Ubuntu runner, and
`theme-night` renders its preview with one glyph fewer there. Step counts,
element counts, ghost counts and ground colours are identical to the character
on both.

Those three are split by platform only where a platform has actually been shown
to differ — today that is `theme-night`'s preview and the check deck's
fingerprint. Everywhere else a single number stands and is compared across
platforms, because splitting a value the platforms agree on would check each
side against itself and let a future divergence pass. Where a split value has no
entry for the running platform, the run says so and fails, rather than quietly
checking nothing. It holds per deck the slide and step counts,
how many elements are marked as drawn and as dimmed on every step, the
number of ghosts a magic move produces, re entry through the hash, the speaker
view, the ground colour of every slide and the runtime's own error list.

The sixteenth deck, `.github/scripts/decklauf/pruefdeck.typ`, exists because
the examples leave gaps. `invert`, `info()` and `fit` appear in none of the
fifteen; `after: "dimmed"` in one and `stagger(dim: true)` in two, all of them
added late. Counted in their sources. The dim lookup was once deliberately
broken and nothing in the examples of the day moved. The check deck is not under
`examples/`, so it stays off the website and the published decks keep their
pages unchanged. Beside it, `ueberlauf.typ` and `wanderung.typ` are decks that have to *fail* to
compile, so that the overflow check and the drift check are caught when they
stop finding anything.

What it does not reach: how a slide looks. No images are compared, no sizes and
no positions are measured. And it reads *attributes*, not what the eye sees --
measured, a runtime that sets every element to zero opacity while still marking
it as drawn passes, and so does one where `after: "dimmed"` stops dimming but
keeps its attribute. What `fit`, `info()`, `invert` and the palettes do is
worked out in Typst and has no number in the browser; for those the run keeps a
fingerprint of the check deck's typeset output and the ground colour of every
slide, which catches a change but does not say the result is right. Outside it
altogether: keyboard, mouse, pointer gestures, the ink layer, the flipbook's
own picture, the overview, the blackout, an embedded document, video, and two
real windows talking to each other. Ghosts are counted as they appear and never
as they are cleared away, so a magic move that forgets to tidy up goes
unnoticed.

## GeoGebra

```typ
#geogebra(width: 100%, height: 330pt)

#ggb-run("a=1", "f(x)=a*x^2")
#ggb-style("f", color: accent, thickness: 6)
#ggb-tween("a", at: 2, to: 2.5, duration: 950)
```

GeoGebra builds the construction, the slides supply the dramaturgy: jobs sit on
steps, so a value changes, an object appears or the viewport moves when the
presenter pages. `ggb-run`, `-set`, `-show`, `-hide`, `-style`, `-view`,
`-animate` and `-tween` all take the same step selector as `anim`. Paging back
replays the run from its start, so a job has to be repeatable. With one applet
on the slide no command has to name it. From the speaker view the applet in
front of you is the live one, and the projected copy follows what your hand
does to it.

This was `typstage-geogebra`, a package of its own, and it still goes the way a
foreign package would: `embed(bridge: …)` and `bridge-job`, nothing else. A
deck that never calls `geogebra` therefore carries none of it — measured, such
a deck is the same size to the byte as it was before the two packages became
one.

**Where the applet comes from.** This package does not ship GeoGebra. `geogebra`
puts a frame on the slide, and the browser fetches what runs inside it from
`codebase`, `https://www.geogebra.org/apps/` by default. So: without a network
the frame stays empty; the viewer's browser talks to `geogebra.org`; and the
applet is under **GeoGebra's own licence and terms of use**, not under this
package's MIT licence — for commercial use those are the ones to read. Where
that is unwanted, `codebase` points the frame at a local copy instead. On paper
nothing is fetched at all: `fallback` and `link` stand there instead.

The chapter *GeoGebra* in the manual has the rest, and the
[two example decks](https://loewe1000.github.io/typstage/beispiele/) are on the
site with the others.

## License

MIT, for this package. A GeoGebra applet loaded at run time is GeoGebra's and
carries GeoGebra's terms.
