# typstage

Animated HTML presentations from a single Typst file — and a PDF handout from
the same source.

```bash
typst compile deck.typ deck.html --format html --features html   # animated
typst compile deck.typ deck.pdf                                  # handout
```

Typst's own HTML export leaves the layout to the browser, which loses exactly
what you use Typst for. typstage goes the other way: **Typst sets, the browser
moves.** Every slide is rendered as SVG, so the layout is identical to the PDF;
elements that should move are announced with `anim`, `morph`, `video`, `embed`
or `flipbook`, and the runtime moves them with the Web Animations API.



## Installation

The package lives in the local `@schule` namespace and is not (yet) on Typst
Universe. Clone it under the package path to use it:

```bash
git clone https://github.com/Loewe1000/typstage \
  ~/Library/Application\ Support/typst/packages/schule/typstage/0.1.0
```

On Linux that path is `~/.local/share/typst/packages/schule/…`, on Windows
`%APPDATA%\typst\packages\schule\…`.

The documentation is built with `@schule/schuldocs`; one run produces the
manual, the website and its stylesheet:

```bash
typst compile docs/docs.typ build --format bundle --features bundle,html
```

## Getting started

```typ
#import "@schule/typstage:0.1.0": *

#show: presentation.with(title: [My talk], transition: "slide")

= A section

== Step by step

#stagger[
  - appears first
  - then this
  - and last of all
]

== Magic move

#align(center, morph(<formula>, $a^2 + b^2$))

== #h(0pt)

#place(center + horizon, morph(<formula>, text(size: 2.6em)[$a^2 + b^2 = c^2$]))
```

## Names

Anything that has to be recognised across slides carries a name: a `morph` that
flies, a frame that receives step jobs. Write it as a label or as a string —
`morph(<pythagoras>, …)` and `morph("pythagoras", …)` are the same thing. The
label reads as what it is and Typst colours it accordingly.

## Which step something appears on

`at` is `auto` by default, and `auto` means *the next free step*. Consecutive
reveals therefore number themselves:

```typ
#anim[first]        // step 1
#anim[second]       // step 2
#stagger[           // steps 3, 4, 5 — the list carries on where the slide
  - third           //                 left off
  - fourth
  - fifth
]
```

For a slide that simply unfolds, nothing needs wrapping at all:

```typ
== A slide
First this.
#pause
Then that.
```

`#pause` puts everything after it one step later. It is read at the top level
of the slide body, `#set` and `#show` rules included; inside a grid cell or a
table it is not seen — reach for `anim` there. A pause begins a new block, and
the PDF sets it the same way.

Several versions of one thing, each replacing the one before:

```typ
#alternatives(
  $ (a + b)^2 $,
  $ (a + b)(a + b) $,
  $ a^2 + 2 a b + b^2 $,
)
```

They stand in the same place, in a box as large as the largest of them, so
nothing around them moves. Each takes one step, the last one stays. On paper
only the last is set — in the same box, so the spacing carries over.

Give a number and the counting continues from there — so a single correction
does not force you to renumber everything behind it:

```typ
#anim[first]        // 1
#anim(at: 4)[late]  // 4
#anim[after it]     // 5
```

| written | means |
|---|---|
| `auto` | the next free step (default) |
| `3` | from step three on — the same as `"3-"` |
| `(2, 5)` | on steps two and five |
| `"2-"`, `"1-2"`, `"2,4"`, `"-2"`, `"3"` | as before |

The cursor counts **reveals** — `anim`, `stagger`, `steps`. An applet, a video
or a `morph` neither uses up a step nor pushes anything along: in a two-column
slide the bullets beside an applet belong at step one, not behind the applet's
tweens. The cursor restarts on every slide.

## The canvas

16:9 on an A4-width canvas by default, so a slide and a handout page carry text
at the same physical size. Any other shape is three arguments:

```typ
#show: presentation.with(width: 800pt, height: 600pt)   // 4:3
#show: presentation.with(margin: 48pt)                  // more air
```

Everything the theme draws — the title band, the type sizes, the rules — is
measured on the default canvas and scaled with the width. A deck at half the
width therefore looks the same, only smaller, rather than wearing a header
built for a canvas twice its size. Only the *ratio* really changes the layout.

The browser follows: the stage is fitted to the ratio, and so are the overview
thumbnails and the printed pages.

## What is in the package

| | |
|---|---|
| `presentation` | builds the deck; takes slides as arguments or a show-rule body split at headings |
| `slide`, `section`, `title-slide` | the three kinds of slide |
| `anim`, `morph`, `stagger`, `steps` | appearing, moving, staggering |
| `pause`, `alternatives` | unfolding a slide, and versions replacing each other |
| `video`, `embed`, `flipbook` | media; `embed(bridge: …)` opens a frame to companion packages |
| `transition`, `speaker-note` | per slide |
| `bridge-job` | send a step job to a bridged element |
| `slide-width`, `dark`, `accent`, … | the defaults behind `width:` and the palette |
| `runtime-version`, `runtime-files` | the CSS and JS, for `assets: "split"` and CDNs |

Controls: ← → page, `o` overview, `f` full screen, `s` note, `p` print.

## The PDF

One page per slide, every tracked element in its final state. What belongs only
to the motion — notes, transitions, bridge jobs — are state updates without
output and fall away by themselves.

Where a frame or an applet stands in the browser, an empty box would remain on
paper. `embed` therefore takes `fallback` (arbitrary content, e.g. a CeTZ
drawing) and `link` (clickable in the PDF).

### As a handout

```typ
#show: presentation.with(handout: 3)   // three slides per A4 page
```

`handout` takes `true` (two per page) or a number from 1 to 6, and only affects
the PDF — the HTML ignores it. The slides are not redrawn, only shrunk, so the
handout cannot drift away from what was on the screen.

Beside or below each slide stands its `speaker-note`; where a slide has none,
ruled lines take its place. Which of the two depends on the count: a 16:9 slide
beside a note column is wide and low, so up to two per upright A4 the notes go
underneath and the slide takes the full width. From three on they stand beside
it — the classic sheet with room to write.

## Where CSS and JavaScript come from

```typ
#show: presentation.with(assets: "inline")                          // default
#show: presentation.with(assets: "split")
#show: presentation.with(assets: (cdn: "https://cdn.example.org/ts/"))
```

`"inline"` puts both into the HTML — one file, nothing beside it. `"split"`
links `typstage-0.1.0.css` and `.js` next to the HTML, a CDN the same names
under the given address. The names carry the version so several releases can
live side by side. Typst cannot create files; write them out from
`runtime-files` once.

## Companion packages

`typstage-geogebra` adds GeoGebra applets. It is a package of its own so a deck
without applets carries none of it — everything it needs from the core is
`embed(bridge: …)` and `bridge-job`.
