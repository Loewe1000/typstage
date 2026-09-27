# Contributing

Thanks for looking. This file describes how the repository checks itself, which
is the part that is easy to get wrong and hard to guess.

## Getting a clone to build

Every source in this repository imports `@preview/typstage:0.2.0` — the name
the package carries once published. A clone under the local package path is
found before the published one, so that import reaches your working tree:

```bash
git clone https://github.com/Loewe1000/typstage \
  ~/Library/Application\ Support/typst/packages/preview/typstage/0.2.0
```

On Linux that path is `~/.local/share/typst/packages/preview/…`, on Windows
`%APPDATA%\typst\packages\preview\…`.

The check scripts do not rely on any of this: each builds a throwaway package
root and links the working tree into it, under `schule` *and* under `preview`.
That is deliberate — a run that found the *installed* package instead of the
one it is checking would measure the wrong thing and say nothing about it. Needs Typst 0.15; the HTML target
additionally needs `--features html`.

The manual, the website and the example decks are built in one go. `AGGREGAT`
points at a checkout of Typst-Schule, from which the site takes the companion
package and the index page:

```bash
AGGREGAT=/path/to/Typst-Schule bash .github/scripts/build-site.sh
```

For one deck at a time there is `.vscode/tasks.json`. The build shortcut runs
`typst watch` for the file in front of you, serves it on
`http://127.0.0.1:3000` and reloads the browser on every save — on the step the
deck was standing on, so you keep your place. Compile errors land in the
problem list. The manual describes the same task under *While you write*, for
readers who are not in this repository.

## What runs before a change lands

| Check | What it does |
| --- | --- |
| `pruefe-beispiele.py` | compiles every example in both manuals |
| `pruefe-decks.js` | drives all example decks through a real browser |
| `decklauf/pult.js` | the speaker view in both light and dark |
| `pruefe-pult-teiler.js` | the slide tile can be dragged smaller, and it stays |
| `decklauf/zwei-fenster.js` | talk window and speaker window together |
| `decklauf/flug-hoehe.js` | what lies on top of what during a flight |
| `decklauf/sprung.js` | what a jump into a running transition leaves behind |
| `pruefe-palette.py` | the contrast contract of the speaker palette |
| `pruefe-rundgang.py` | every export is demonstrated in `tour.typ`, and so is every new key that has no export of its own (`room` and its entries, `section-back`, `ends-at`) |
| `pruefe-inhalt.js` | `contents()` jumps to a section and back |
| `pruefe-fussnoten.js` | a footnote's note is revealed with its marker, not before |
| `pruefe-uhr-ziffern.js` | the digits set the class clock, and a `cue()` slide keeps them |
| `pruefe-zeiger.js` | the pointer lights a dot in the hall on any slide, embedded frames stay operable, and a mirroring frame takes the dot out rather than leaving it behind (Chrome) |
| `pruefe-zeiger-ff.js` | the same dot in a real Firefox over WebDriver BiDi: it arrives in the hall at the same fraction of the stage, it goes out, pen and frame stay intact |
| `pruefe-klang.js` | a key plays a sound, in the hall and not at the desk |
| `pruefe-video-frist.js` | a video ends on the minute the lesson begins |
| `pruefe-lesezeichen.py` | the PDF carries an outline, one entry per slide, and none of them empty: a heading that draws but carries no character gets no entry |
| `pruefe-woerter.py` | de, en and fr carry the same runtime words |
| `pruefe-cue-pfeil.js` | a `cue()` group claims the arrow only when due |
| `pruefe-cue-folien.js` | a `cue()` group stays on its slide, a layer on its point |
| `pruefe-konvergenz.py` | the reveal chains converge within five passes |
| `pruefe-schrittseiten.py` | `pages: "step"` unfolds the PDF step by step, and every example deck converges as a handout and step by step |
| `pruefe-papierregel.py` | each PDF page shows what the manual promises: all reveals on a slide page and in the handout, only the last version of what is replaced, and layers on their own step |
| `pruefe-verzeichnis.py` | `contents()` shows its levels and where the talk stands |
| `pruefe-ueberlauf.py` | no example deck runs over its slide |
| `pruefe-vollbild.py` | `bleed` reaches the edges and takes the chrome off, a slide without a title has no running header, what may stand above `bleed` is kept, and every misplaced `bleed` stops with its message |
| `pruefe-vollbild.js` | sprites inside `bleed` sit on the canvas, morphs fly on and off it, the progress bar hides and comes back, the print view carries no chrome there |
| `pruefe-unterbrechen.js` | a reveal, a flight and a slide change, each interrupted 300 ms in: the picture carries on from where it stands, and paging back reverses the running movement instead of restarting it |
| `pruefe-morph-pin.js` | a `pin` holds every glyph of its content, its glyphs travel together, a named piece travels above the glyph limit while the rest changes in place, an unnamed formula above it still moves as a block, `morph: (glyph-limit: …)` arrives, and the default is 120 |
| `pruefe-zier.js` | number, running header, footer line and progress bar stand in the browser where they stand on the PDF page -- with margins and a theme size in `em`, under a deck's `set place`, `set block` and `set page(flipped: true)`, moved with `move` as the manual shows, and at 3200 pixels; revealed pieces, a line without area, a scene, a flip book and footnotes -- one with a block of its own -- too under a deck-wide `set block`, one after the show rule and one that sets a width; a scene, a flip book, a `morph` in a line and a run behind `#pause` under `set box` and `set rect`; and a long footnote under a margin and under a theme size in `em` |
| `pruefe-desmos.js` | the Desmos bridge, by hand (see below) |

A full deck run takes about 25 minutes, longer than a laptop stays awake. On
macOS the browser harness therefore holds an idle-sleep guard for as long as
the run lives (`caffeinate -i -w`), because a run that loses the CPU halfway
looks exactly like one that has crashed -- measured once as three hours
without a line of output, from a run that was perfectly fine. Closing the lid
still sleeps.

The same harness sweeps stale browser profiles out of the temp directory when
it starts: anything named `typstage-*` and older than six hours. `SIGKILL`
cannot be caught, so a run someone kills hard leaves its profile behind, and
the only place left to collect it is the start of the next run. Measured on
one development machine before this existed: 4306 leftover profiles, 912 MB.

`pruefe-desmos.js` is run by hand too, and for the same kind of reason: it
loads Desmos' script from desmos.com and needs an API key. Neither belongs
in a run that has to be green on every push. It builds its own deck, drives
it in a browser and checks that the frame announces itself, that the opening
picture stands, that a tween runs and arrives, that it does *not* run again
on the next step, and that hiding an expression keeps it in the calculator.

Two images in the README are generated, not drawn: `assets/logo.png`/`.svg`
from `assets/logo.typ`, and `assets/themes.png` from `assets/themes.typ` via
`python3 .github/scripts/bau-themenbild.py`. **Run that one by hand after
touching a theme, and run it on macOS.** It is deliberately not in CI: the
themes name fonts a Mac has -- Iowan Old Style, Optima, Helvetica Neue --
and on the Linux runner Typst would fall back to others, so the image would
show a look nobody ever sees. The picture goes stale silently otherwise: the
version before this one showed `themes.lesson` with a blue heading and an
orange rule, long after that had become red on a blue rule.

Pass `--paketpfad` to `pruefe-beispiele.py`, or it checks the *installed*
package rather than your working tree. `build-site.sh` passes it; a run by hand
often does not.

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

Compiling proves nothing about motion. A second run loads the seventeen example
decks and an eighteenth check deck into a real browser, pages through every step
forward and backward, and holds the numbers against a written record:

```bash
bash .github/scripts/build-site.sh          # the decks it measures
node .github/scripts/pruefe-decks.js
```

No npm and no Playwright. Chrome is reached over the DevTools protocol and
Firefox over WebDriver BiDi, with what node 22 already brings; the two drivers
together are 541 lines, 355 of them once comment and blank lines are taken out.
Whether this package can be checked should not
depend on a several hundred megabyte download. Playwright may be put beside it
for WebKit or for the two window case; it is not a prerequisite.

The Firefox driver carries input, a viewport, touch, window activation and the
second window since the pointer is measured in it as well: the dot hangs on a
real hover and on two windows of different sizes, and `pruefe-decks.js` only
ever needed to load a page and take a picture. The pointer therefore has two
checks rather than one with a switch -- `pruefe-zeiger.js` speaks CDP,
`pruefe-zeiger-ff.js` speaks BiDi, and both take their decks, their reading
expressions and the method that measures the dot in a screenshot from
`decklauf/zeigerdeck.js` so that there are not two versions of one probe deck.

Both now carry the same seventeen numbered points, 1 to 17, and above them the
same point 0, which says only that the probe deck was not what the check
needed. A number means the same thing on both sides, so the two outputs can be
read line against line. The Chrome check has 70 places to complain at and the
Firefox check 72; two points hold a different count, each for a reason named
just below: point 1 and point 14 have one place more in Firefox. It was not
always so: the Firefox check began with 6 of the Chrome check's 13 points and
20 of its 44 places, and freezing, a change of slide, the throttle, the finger,
`room: (pointer: false)` and the order against `#ts-ink` went unmeasured there.
Measured on one of them: a runtime with the `punktWeg()` taken out of a change
of slide left the Firefox check green while the Chrome one complained.

Two parts came later still, each because a runtime with one line taken out
left both checks green. Point 17 closes the desk while its dot stands: the
hall has to notice by itself, through its watch, and any one of the three
lines that carry this -- starting the watch on a pointer message, keeping it
running while a dot stands, and `punktWeg()` in `sichtLoesen` -- was missed.
And point 3 gained a second half: whoever switches from the pen to the pointer
with `m` in the middle of a stroke and drags out of the stage still holds the
pointer capture, `pointerleave` does not come until the button is released,
and only the check on the position takes the dot; without it the dot stood on
the last place inside the stage.

Three more parts came from a runtime changed in one place that left both
checks green. Point 5 now compares the z-index of the dot layer with that of
`#ts-ink` instead of only their order in the tree: with the dot layer on
z-index 5, a stroke drawn through the dot covered its centre in the hall
picture (235,94,40, the pen, where 43,127,184, the dot, belongs). Point 6 now
drags and scrolls into the frame as well as clicking it, because dragging
and the wheel went through the pointer mode before the dot existed, and
taking either one out, or the rule that a drag stays with what took the
press, went unnoticed. Point 11 now asks where the dot stands after the
burst, not only how many messages it made: a throttle that kept the first
point of a frame instead of the last made exactly one message with one
point, and the dot stood at 0.215 while the hand was at 0.8. And point 17
reloads the desk before it closes it: the hand is gone just the same, but the
watch sees a live partner, and the dot still stood in the hall after 70
seconds, in Chrome and in Firefox. The runtime now takes it when a freshly
loaded desk says hello.

Only one thing is not the same, and it is not a gap in BiDi:

* Point 14, the loss of focus, measures *more* in Firefox.
  `browsingContext.activate` on the hall really does take the focus from the
  desk -- measured, `document.hasFocus()` there goes from `true` to `false`.
  Headless Chrome cannot do it: `Page.bringToFront`,
  `Emulation.setFocusEmulationEnabled: false` and a third target with
  `Target.activateTarget` all three leave the desk focused, measured one after
  the other, so the Chrome check dispatches the `blur` event itself and says so
  above the point.

Point 11, the throttle, is the same on both sides now, both halves and both
judged: forty moves dispatched by the *page* must come out as one message with
one point, and over forty separately awaited driver calls no message may carry
more than one. Until now the Firefox check had only the first half, while this
file said it counted the second and did not judge it; it counted nothing.

Two smaller ones are the browser and not the dot: the desk stage is 3.5 pixels
narrower at the same window, and BiDi rounds a hover to whole pixels, which is
why the Firefox check allows 0.002 of the stage where Chrome allows 0.001. That
same stage width is point 1's extra place in Firefox: it refuses to pass if the
two stages come out nearly the same size, because a dot that travels as a
fraction of the stage is then not being measured at all.

What differs in a full deck run in Firefox, measured rather than assumed. It
takes 714.3 seconds against Chrome's 716.1, and over all eighteen decks and
every field it records the two browsers differ in exactly one: `pruefdeck`'s
`kamera` reads 7.892 where `soll.json` writes 7.893, and `ohne-flaeche` raises
no complaint where Chrome raises one. Both are the engine and not this
package: the same two, word for word, come out of a Firefox run over the state
before the pointer existed. The desk stage is 3.5 pixels narrower there at the
same 1120x760 window -- 618.7 against Chrome's 622.2 -- and BiDi rounds a
hover to whole pixels, so the dot lands on 0.2996/0.7011 where Chrome lands on
0.3/0.7; the fraction of the stage it takes up is 2.2 percent in both. A
Firefox run over two states of this package differs in `pruefdeck.satz` and
`satzBytes` and in nothing else.

The runtime carries the surface the run reads, `window.typstage.pruef`, and it
is always there rather than behind a build switch: a switch would mean checking
a runtime that is not the one shipped. What it costs, measured by building
every example twice -- once as shipped and once with the whole `pruef` object
cut down to `{}` -- and comparing the pages packed with gzip: the shipped page
is larger than the same page without it, on the fifteen example decks without
an applet by between 0.4 percent (`tour`) and 1.4 percent (`theme-plain`), and
across all seventeen by up to 2.4 percent (`geogebra`, the smallest page of the
set) -- rounded to one place, the same three numbers at gzip level 6 and at
level 9. Above one percent are eleven of the seventeen at level 9 and ten at
level 6: `anziehen` sits just above the line at one level and just below it at
the other. The same numbers stand in the runtime's own comment over `pruef`. Two parts of it are what
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
commit measures a different length on macOS than on an Ubuntu runner, and
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

The eighteenth deck, `.github/scripts/decklauf/pruefdeck.typ`, exists because
the examples left gaps: when it was written, `invert`, `info()`, `fit`,
`after: "dimmed"` and `stagger(dim: true)` appeared in none of them, and the dim
lookup was once deliberately broken without anything in the examples of the
day moving. Counted in their sources today: `after: "dimmed"` in one of the
seventeen, `stagger(dim: true)` in five, `invert` and `fit` in one, `info()` in
two. What `fit`, `info()` and `invert` do has no number in the browser, and
the run takes its fingerprint of the typeset output from the check deck alone. The check deck is not under
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

## Before a release

The checks above run against the working tree, where every example is compiled
with a package path pointing back at it. That is not what a user gets. Twice
now, a bug reached the point of being submitted to Universe and was caught only
by the step below.

Assemble the bundle as it will be published — the repository minus what
`exclude` in `typst.toml` names, but *keeping* the README's images, because the
Universe page renders them — and compile a deck against that copy alone:

```bash
mkdir -p /tmp/pkg/preview
cp -R <the assembled 0.2.0 directory> /tmp/pkg/preview/typstage
typst compile --package-path /tmp/pkg --root . probe.typ probe.pdf
```

The probe deck should reach for options that no example deck combines, since
that is where the gap is. Both bugs found this way were of that kind: a
`contents()` together with `pages: "step"`, and a `contents()` standing behind
a slide with reveals. Neither combination exists in `examples/`, so the whole
chain stayed green while the published package would have failed to compile.

Compile it in both outputs and check for `error:` as well as `did not
converge`. A convergence warning is not an error and Typst still writes a file,
so a run that only checks the exit status will miss it.

### YouTube regression

`node .github/scripts/pruefe-youtube.js` compiles a small deck and tests the
real runtime with two Chrome windows and a deterministic IFrame API substitute.
It covers lazy loading, host recognition, presenter controls, muted previews,
mouse/touch dragging (including cancellation and delayed seek feedback),
actual iframe dimensions at DPR 1/2, control visibility, seeking,
slide/reveal/black transitions and provider/network failures without
requiring YouTube access. Set `CHROME` to override the browser executable.

`node .github/scripts/pruefe-youtube.js --live` additionally provides an opt-in
smoke test against the external YouTube API over a local HTTP server. It requires
internet access and an embeddable test video; provider/network restrictions can
make this check fail independently of the offline regression.

### GeoGebra rendering regression

`node .github/scripts/pruefe-geogebra-schaerfe.js` is an opt-in live check using
Chrome and the external GeoGebra applet. It verifies the canvas backing resolution
at small/large window sizes and DPR 1/2, unchanged construction XML and view bounds,
and a real presenter pointer drag synchronized to the stage. Typst and Node 21+
are required; set `CHROME` to override the browser executable. Internet/provider
failures can fail this check independently of the local implementation.

### Audio and timer regression

`node .github/scripts/pruefe-audio-timer.js` uses real Chrome audio with a local
HTTP server. It checks local and absolute URL sources, reveal playback, pause,
PDF compilation and the optional timer signal at zero, including cancellation,
restart and silent presenter playback. It requires no external audio service.

### Media clip regression

`node .github/scripts/pruefe-medien-ausschnitt.js` checks start/end/loop on real
HTML media and a deterministic YouTube API fixture, including clip boundaries,
replay, presenter seeking, source-duration clamping and Typst validation/PDF.
It serves local fixtures with byte ranges and requires no external provider.

### Vortragen card regression

`node .github/scripts/pruefe-vortragen-karten.js` compiles both `vortragen` decks
with the default theme font and DejaVu Sans, in HTML and PDF. It checks the
painted SVG bounds against each card and the stage at two viewport sizes, as
well as equal heights and stable positions across cue orders. This catches
text escaping fixed-height boxes even when the slide overflow check passes.
The fallback-font run requires DejaVu Sans to be installed.

### GeoGebra caption regression

`node .github/scripts/pruefe-geogebra-schritte.js` compiles `geogebra-sprecher`
in HTML and PDF and checks captions against the commands actually sent through
the bridge at every step, forwards, backwards and on direct entry. Only the
external applet is replaced by a message receiver; no GeoGebra network access
is required. The test covers the semicircle, sides, angle, trace and roots.
