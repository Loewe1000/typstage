# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), the numbering
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Decks that read from the right.** `#set text(lang: "fa")` before the show
  rule, or `#set text(dir: rtl)`, turns the whole slide around. The slide body
  was placed with `place(top + left, …)`, and that alignment beat the `start`
  every paragraph resolves for itself: every line sat on the left while the
  lists and columns around it were already mirrored. The body now hands down
  `start`; the title in its band, the bar beside a `callout`, the footer
  number, the progress bar and the title and section slides mirror along; the
  moving parts carry the direction into their own frames; and a `callout`
  without a title reads its caption in Arabic, Persian or Hebrew. Reported on
  the forum from a Persian deck. Decks that read from the left come out byte
  for byte as before.
- **`build(at: …)`.** A drawing whose stages do not come one click after
  another. `at: (1, 9)` gives two stages, the second from step 9 on, and the
  first holds until then. Until now a stage lay fixed on `start + i`, so a
  picture due on step 9 needed `steps: 9`, and the eight identical stages
  before it were all typeset. Measured on a slide with three diagrams that are
  discussed one after another: ten sprites instead of 22, and the file 2.98 MB
  instead of 3.45 MB. `from` keeps counting stages rather than steps, because
  under `start: auto` a deck cannot know its own step numbers. Reported with a
  worked case; `steps` and `start` are refused beside `at`, rather than
  silently losing to it.

### Fixed

- **A centred `anim` on paper.** `anim(align(center, …))` inside a grid column
  was centred in the browser and flush left in the PDF, from one source. The
  HTML branch widens content that wants to centre itself to the room it has;
  the paper branch handed the body back untouched, and an `align` measured as
  narrow as its own ink had nothing left to centre in. Both branches now ask
  the same question. Reported from a deck whose three columns each carried a
  verdict under a diagram.

## [0.1.0] — unreleased

First release.

### The idea

One Typst file becomes an animated HTML talk and a PDF handout. Typst sets,
the browser moves: magic-move morphing, staggered reveals, slide transitions,
media, and GeoGebra applets that follow the steps of the slide.

### What is in it

- **Two notations for a deck.** Headings, or `slide()` calls as arguments —
  the same deck either way.
- **Revealing.** `#pause`, `anim`, `stagger`, `alternatives`, `build`, `cue`
  and `scene`, all counted in steps rather than pages.
- **Moving.** `morph` carries a shape from where it stood to where it now
  stands — between slides and, since it grew the second half, from step to
  step within one. `pin` pairs what an outline alone would mispair.
- **Layout.** `card`, `callout`, `side-by-side`, `tiles`, `statement`, `fit`.
- **Media.** `video`, `flipbook`, `embed`, and a bridge that posts jobs into an
  embedded document step by step. `typstage-geogebra` builds on it.
- **Five themes and five palettes**, each measured against a contrast contract
  of seven pairs before it ships.
- **A speaker view** in a second window: the current slide as the drawing
  surface, the note beside it, elapsed time, the planned length, a class clock,
  a preview of the next step, and a pen. `speaker-view` says what of it to
  show.
- **A PDF from the same source**: one page per slide, every tracked element in
  its final state, and a handout of up to six slides per page.

### Fixed

- **The handout sheet fits its page.** With the notes below the slide
  (`handout: 1` or `2`), and beside a 4:3 slide at three per page, every sheet
  ran a hair over and left a page behind that carried one ruled line. The
  spacing between the rows now takes the place of Typst's paragraph spacing
  instead of adding to it.
- **Room under a 4:3 slide.** At two per page the slide filled its whole share
  of the height and the notes came out with a negative height. At least four
  ruled lines now stay underneath; the slide gives way, not the room.

### Known limits

- Typst's HTML export is experimental; every HTML run needs `--features html`.
- The manual is fuller in German than in English.
- GeoGebra is not in the box: a typeset applet fetches it at run time and
  stands under GeoGebra's own terms.
