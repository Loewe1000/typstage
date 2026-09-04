# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), the numbering
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] — unreleased

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

### Changed

- **`cue()`: one group, many calls -- and a group belongs to one slide.** A group
  is held together by its name, not by a single call: every `cue("name")[…]`
  contributes points and sets them where it stands, so placing a point freely is
  no longer a special case but simply what happens. Numbers count on across the
  calls of one slide; `start:` and `spacing:` apply per call, and between two
  calls the layout decides. The same name on the next slide is a new group that
  starts again at `1`, so every exercise slide can say `cue("marks", …)` without
  numbering the names apart. `cue-layer` now points at a declared point rather
  than at a number within a span. A tenth point on one slide is refused: the room
  calls with the keys 1 to 9, and a digit with nothing behind it silently becomes
  an ordinary page turn.
- **The runtime files are now `typstage-0.1.1.css` and `typstage-0.1.1.js`.**
  The name carries the version so a CDN can hold several releases side by side
  and no browser serves a stale one from its cache. A deck with
  `assets: "split"` or a CDN writes them out from `runtime-files` and never
  types the name itself; one that inlines them, the default, notices nothing.

### Fixed

- **`stagger` and `cue` let `track` hand out their steps.** A chain that read
  the step cursor and passed a *computed* `at` into a tracked element cost the
  document its convergence, as soon as the revealed body carried something out
  of the flow -- a `place` with an offset -- inside a box of fixed size.
  Measured on a class-5 number-line deck: five warnings for `cue`, nine for
  three `stagger` calls, and Typst giving up after five layout passes. `anim`
  never had it, because at `at: auto` it advances the cursor with a plain
  update and reads the value inside `track`'s own context: the number comes
  into being where it is used rather than being handed in from outside. Both
  now take that same path where they can, and the step floor travels with it
  (2 for an `anim`, which comes *after* the slide appears; 1 for a chain whose
  first piece is already there). `stride`, `dim`, `morph`, a named group and an
  explicit `start:` keep the old path, which they need for the absolute first
  step. Every example deck comes out with the same steps as before, down to
  the check deck's byte count.
- **A `cue()` group no longer swallows the steps before it.** The forward arrow
  reveals the next point not yet named, and the group claimed the key as soon
  as its next point lay anywhere ahead -- not only when that point was the next
  stop. On a slide with ordinary steps before the group, one arrow therefore
  jumped straight to the group's first point and skipped every stop between.
  The arrow now falls through and pages normally until the group is due. Every
  probe so far began its group on step 1, where the first point *is* the next
  stop and a premature claim cannot be told from correct behaviour; reported
  from a lesson deck whose three marks came after two questions and a number
  line. Jumping behind the group by hash or `End` still does not fall back
  into it.
- **A centred `anim` on paper.** `anim(align(center, …))` inside a grid column
  was centred in the browser and flush left in the PDF, from one source. The
  HTML branch widens content that wants to centre itself to the room it has;
  the paper branch handed the body back untouched, and an `align` measured as
  narrow as its own ink had nothing left to centre in. Both branches now ask
  the same question. Reported from a deck whose three columns each carried a
  verdict under a diagram.
- **The handout sheet fits its page.** With the notes below the slide
  (`handout: 1` or `2`), and beside a 4:3 slide at three per page, every sheet
  ran a hair over and left a page behind that carried one ruled line. The
  spacing between the rows now takes the place of Typst's paragraph spacing
  instead of adding to it.
- **Room under a 4:3 slide.** At two per page the slide filled its whole share
  of the height and the notes came out with a negative height. At least four
  ruled lines now stay underneath; the slide gives way, not the room.

## [0.1.0] — 2026-08-31

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

### Known limits

- Typst's HTML export is experimental; every HTML run needs `--features html`.
- The manual is fuller in German than in English.
- GeoGebra is not in the box: a typeset applet fetches it at run time and
  stands under GeoGebra's own terms.
