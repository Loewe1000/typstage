# Contributing

Thanks for looking. This file describes how the repository checks itself, which
is the part that is easy to get wrong and hard to guess.

## Getting a clone to build

Every source in this repository imports `@preview/typstage:0.1.1` — the name
the package carries once published. A clone under the local package path is
found before the published one, so that import reaches your working tree:

```bash
git clone https://github.com/Loewe1000/typstage \
  ~/Library/Application\ Support/typst/packages/preview/typstage/0.1.1
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

## What runs before a change lands

| Check | What it does |
| --- | --- |
| `pruefe-beispiele.py` | compiles every example in both manuals |
| `pruefe-decks.js` | drives all example decks through a real browser |
| `decklauf/pult.js` | the speaker view in both light and dark |
| `decklauf/zwei-fenster.js` | talk window and speaker window together |
| `decklauf/flug-hoehe.js` | what lies on top of what during a flight |
| `decklauf/sprung.js` | what a jump into a running transition leaves behind |
| `pruefe-palette.py` | the contrast contract of the speaker palette |
| `pruefe-rundgang.py` | every export is demonstrated in `tour.typ` |
| `pruefe-inhalt.js` | `contents()` jumps to a section and back |
| `pruefe-ueberlauf.py` | no example deck runs over its slide |
| `pruefe-desmos.js` | the Desmos bridge, by hand (see below) |

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
together are 175 lines. Whether this package can be checked should not
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
the examples leave gaps. `invert`, `info()` and `fit` appear in none of the
seventeen; `after: "dimmed"` in one and `stagger(dim: true)` in two, all of them
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
