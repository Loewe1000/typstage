# typstage

**Animated HTML presentations from a single Typst file — and the slide set and
the handout as PDF from that same file.**

```bash
typst compile deck.typ deck.html --format html --features html   # the animated talk
typst compile deck.typ deck.pdf                                  # slides and handout
```

![A slide of a typstage deck in the browser, halfway through its reveals](assets/slide.png)

**Try it without installing anything:** [five example decks](https://loewe1000.github.io/typstage/beispiele/) — the same short talk in each built-in theme, running in your browser.

## Typst sets, the browser moves

The usual route from Typst to a presentation is a PDF in which every step
occupies a page of its own; nothing ever moves. Typst's own HTML export goes
the other way and leaves the arrangement to the browser — which loses exactly
what Typst is used for.

typstage takes a third route. Every slide is typeset by Typst and written into
the HTML **as SVG**, so what stands in the browser stands there the way Typst
set it, to the point — the same layout the PDF shows. Only then does anything
move: whatever should stir is announced in the source, and a small runtime
moves it with the Web Animations API.

One source, three outputs:

| | |
| --- | --- |
| **Animated talk** | a single self-contained `.html` — reveals, magic move, slide transitions, video, embedded documents. Double-click it; no server, no network, nothing to install alongside |
| **Slide set** | one PDF page per slide — not one per step — with every tracked element in its final state |
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
  The leftover area cannot change — only its shape does.
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
themselves. Names are labels or strings — `morph(<pythagoras>, …)` and
`morph("pythagoras", …)` are the same thing.

For a slide that simply unfolds, nothing needs wrapping at all:

```typ
== A slide that unfolds

First this.

#pause

Then that.
```

Slides may also be handed over as arguments — `presentation(title-slide(…),
section([…]), slide([Title])[…])` — for decks that are generated rather than
written.

## The building blocks

| | |
| --- | --- |
| `presentation` | builds the deck: slides as arguments, or a show-rule body split at its headings |
| `slide`, `section`, `title-slide` | the three kinds of slide |
| `anim`, `stagger`, `pause`, `alternatives` | reveal one thing, a series of things, everything after this point, one thing after another in the same place |
| `morph`, `pin` | magic move across slides; `pin` names a glyph so the pairing follows the name rather than the shape |
| `card`, `callout`, `side-by-side`, `tiles`, `statement` | layouts inside a slide; `tiles` staggers itself |
| `transition`, `speaker-note` | how this slide comes in, and what only you see |
| `themes`, `theme` | the five built-in looks, and the builder behind them |
| `video`, `embed`, `flipbook` | media, arbitrary web content in a sandboxed frame, and animation drawn frame by frame by Typst |
| `bridge-job`, `bridge-targets` | send step jobs into an embedded document — how companion packages drive an applet |
| `slide-width`, `slide-height`, `slide-margin`, `dark`, `accent`, `paper`, `muted` | the defaults behind `width:` and the palette |
| `runtime-version`, `runtime-files` | the CSS and the JS, for `assets: "split"` and for CDNs |

Every one of them is documented in full, with examples, in the manual
(`docs/content.typ`, see below).

Twelve slide transitions — `fade`, `slide`, `push`, `cover`, `uncover`, `zoom`,
`blur`, `iris`, `wipe`, `flip`, `cube`, `none` — set for the deck or for a
single slide, each of them a true reversal when you page backwards. Entrances
(`enter:`) work the same way: paging back takes the entrance away again.

## Themes

```typ
#show: presentation.with(theme: themes.night)
#show: presentation.with(theme: themes.lesson + (accent: blue))
```

![The same slide in the five built-in themes: default, lesson, night, plain, editorial](assets/themes.png)

A theme is a dictionary — colours, fonts, sizes, and one word each for the few
built shapes (`header`, `footer`, `progress`). That is why `+` is enough to
bend one, and `theme(…)` builds a new one from scratch. Only the title slide
and the section slide are functions in it: they are whole pictures, not
variations of one another.

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
| `p` | print view — one slide per page, everything visible |
| `?` | the key map |

Clicking the left quarter of the window goes back, anywhere else forward. The
address bar carries the current step (`#12`), so a reloaded window stands where
it stood.

## On paper

The PDF has one page per slide in the size of the canvas. Everything that moves
in the browser stands there in its final state; what belongs to the motion alone
— notes, transitions, jobs for embedded elements — produces no output and falls
away by itself. Where a frame or an applet stands in the browser, `embed` takes
a `fallback` (any content — a CeTZ drawing, an image) and a `link` that is
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

## The canvas

16:9 on an A4-width canvas by default, so a slide and a handout page carry text
at the same physical size. Any other shape is one to three arguments:

```typ
#show: presentation.with(width: 800pt, height: 600pt)   // 4:3
#show: presentation.with(margin: 48pt)                  // more air
```

Everything the theme draws — the title band, the type sizes, the rules — is
measured on the default canvas and scaled with the width, so a narrower deck
looks the same, only smaller. Only the *ratio* really changes the layout — and
the browser follows it, stage, overview thumbnails and printed pages alike.

## CSS and JavaScript

```typ
#show: presentation.with(assets: "inline")                          // default
#show: presentation.with(assets: "split")
#show: presentation.with(assets: (cdn: "https://cdn.example.org/ts/"))
```

`"inline"` puts both files into the HTML — one file that can be mailed, put on
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
  readers see nothing, and the file grows with the deck — the little deck above
  weighs 200 kB, the one in the screenshot 400 kB, `example.typ` with all its
  media over a megabyte. In exchange no font has to load and the layout cannot
  drift.
- **`#pause` is read at the top level of a slide body only.** Inside a grid
  cell, a table or a figure it is not seen — reach for `anim` there. It also
  does not combine well with centred content: a paused slide sets its runs in
  blocks that shrink to their content, and an `align(center, …)` inside then
  has nothing to centre in.
- **Not on Universe**, so `@preview` will not find it and there is no version
  resolution: you install it by hand, as above.
- **German in places.** The manual is German throughout, the API comments are
  mixed German and English, and two strings the runtime itself shows are German
  — the `?` help line and the message for a slide without a note. `callout`
  likewise carries the German default title `Merke` until you pass a `title:`
  of your own.
- **Five themes, not a theme ecosystem.** They differ in colour, type and the
  shape of header, footer and progress bar — not in slide layouts. Anything
  further is a dictionary entry, a `style:` wrapper, or plain Typst.

## Documentation

The [manual](https://loewe1000.github.io/typstage/) — steps, magic move,
transitions, media, the bridge, a full API reference — is published from this
repository, together with the [example decks](https://loewe1000.github.io/typstage/beispiele/).
It is also available as a [PDF](https://loewe1000.github.io/typstage/typstage.pdf).
Both are German; the source is `docs/content.typ`.

One run gives the printed manual, the website and its stylesheet:

```bash
typst compile docs/docs.typ build --format bundle --features bundle,html --root .
```

`example.typ` in the repository is a deck that exercises everything: reveals,
magic move, an embedded live canvas, a CeTZ flipbook. It is not shipped with
the package — build it from a clone.

## Companion packages

`typstage-geogebra` adds GeoGebra applets. It is a package of its own so that a
deck without applets carries none of it; everything it needs from the core is
`embed(bridge: …)` and `bridge-job`.

## License

MIT.
