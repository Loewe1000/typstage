// A Tour of typstage: the introduction deck.
//
// This is the one deck that is allowed to be about typstage itself, so it takes
// that literally: the slide about `morph` uses a morph to say what a morph is
// for, the slide about `stagger` unfolds, the slide about `bridge-job` drives a
// lamp in a foreign document. The movement is the argument.
//
//   typst compile tour.typ tour.html --format html --features html
//   typst compile tour.typ tour.pdf
//   typst compile tour.typ handout.pdf          (with handout: 3 below)
//
// Deliberately in `themes.plain`: white, black, one grey, no progress bar. The
// layout is meant to keep out of the way. What is on show is the package, not
// a taste in colours.
//
// The slide transitions used below are "zoom", "fade", "push" and "cover". The
// full set is none, fade, slide, push, cover, uncover, zoom, blur, iris, wipe,
// flip and cube; a typo in one of them does not stop the build, it quietly
// becomes a cross-fade.
//
// A body is a box of fixed height, so a short slide would stick to the top with
// white space under it. `#v(1fr)` at both ends centres one; a pure `fr` spacer
// is passed through untouched even where it stands next to tracked elements.

#import "@schule/typstage:0.1.0": *

// Two meaning colours, declared once here and passed in wherever they are
// needed. This deck's theme keeps none of its own. `live` marks the parts of a
// slide that actually move, so even a still screenshot says which half of the
// slide is alive; `done` is its counterpart on the bridged lamp.
#let live = accent
#let done = rgb("#16a34a")

#show: presentation.with(
  theme: themes.plain,
  title: [A Tour of typstage],
  subtitle: [Every function once, and what it is for],
  author: [typstage #runtime-version],
  date: [23 August 2026],
  transition: "slide",
  // Both in milliseconds: the slide change, and the reveal of one element.
  transition-duration: 420,
  duration: 520,
  // The style hook reaches slides *and* the moving parts. A tracked element is
  // typeset a second time, in a frame of its own, and that frame never sees a
  // `#set` rule written in the document, so shared typography has to go here.
  style: it => { set par(justify: false); it },
)

= What this is

== One source, three outputs

#speaker-note[
  Don't go into the mechanics here. This slide says what comes out of the box;
  how it is made is the next one.
]

#v(1fr)

// `align: top` rather than the default `horizon`: two boxes of unequal height
// would otherwise hang from their middles and their title bars would not line
// up, which reads as a mistake.
#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [What goes in])[
    One `.typ` file. Headings cut it into slides: `=` opens a section, `==` a
    slide, `== #h(0pt)` a slide with no title bar.
  ],
  callout(title: [What comes out])[
    An animated talk as a single HTML file, a slide deck as PDF (one page per
    slide, not per step), and with `handout: 3` a handout with room to write.
  ],
)

#anim([No server, no loading: the HTML file carries everything with it.],
      at: 2, enter: "fade-up")

#v(1fr)

== Typst sets, the browser moves

#v(1fr)

#statement(size: 1.3em)[
  Every slide is typeset by Typst and embedded as SVG.
]

// Three steps, each a consequence of the one above it. Shown at once they would
// be three claims competing for the same glance.
#anim([The arrangement is therefore the same as in the PDF, down to the point.
       Motion happens afterwards, and only to what asked for it.],
      at: "2-", enter: "fade-up")

#anim(callout(title: [Which is why the style hook exists])[
  A moving element is typeset a second time, in a frame of its own, and that
  frame does not see the document's `#set` rules. Everything beyond size,
  colour, font, style, alignment and language belongs in `style:`.
], at: "3-", enter: "fade-up")

#v(1fr)

== Two ways to write a deck

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [As headings])[
    #text(size: 0.72em, raw(lang: "typ",
      "#show: presentation.with(…)\n\n= A section\n== A slide\nOne point.\n#pause\nAnd another."))

    The way for talks that are written by hand. This deck uses it.
  ],
  card(title: [As arguments])[
    #text(size: 0.72em, raw(lang: "typ",
      "#presentation(\n  title-slide(title: […]),\n  section([A section]),\n  slide(title: […],\n        note: […])[…],\n)"))

    The way for talks that are computed. Slides out of a loop.
    `theme-night.typ` next door does it that way.
  ],
)

#anim([Pick one and stay with it. In the heading form, `speaker-note[…]` does
       what `note:` does in the call.], at: 2, enter: "fade-up")

#v(1fr)

= Revealing

== anim: one piece, one step

// The zoom is the loudest transition in the set, and it is used exactly once:
// here, where the talk stops describing the deck and starts describing the
// steps inside a slide.
#transition("zoom")

#v(1fr)

#stagger(
  card(title: [at: auto])[The next free step. Consecutive reveals number
    themselves, so nothing has to be renumbered when one is inserted.],
  card(title: [at: 3, the same as at: 2-])[A bare number means "from here
    on". Both are one selection, written two ways.],
)

// This line is the demonstration: it stands on step 1, goes away on step 2 and
// comes back on step 3. Spelled out it would need a sentence; shown it needs
// none.
#anim([And `at: "1,3"` means: here, gone, here again.],
      at: "1,3", enter: "fade-left")

#v(1fr)

== stagger: several things, one after another

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  stagger[
    - Written as a list. One step per point.
    - `stagger` sets the bullets itself.
    - Left to the list, they would stand there before their point arrives.
  ],
  stagger(
    card(title: [As blocks])[Instead of a list, any pieces at all.],
    card(title: [stride: 0])[All on the same step, spread only by `stagger:` in
      milliseconds, a wave instead of a sequence.],
  ),
)

#v(1fr)

== pause: for slides that simply unfold

// Long enough to fill its own height, so no centring pair here. A single
// `#v(1fr)` would push the whole body to the bottom rather than centre it.
No `anim`, no step numbers: everything after a `#pause` arrives one step later.
This slide holds two of them, and you have just crossed the first.

#pause

#callout(title: [Where it does not reach])[
  `#pause` is read at the top level of a slide body. Inside a grid cell or a
  table the content is a field of an element, not part of the body. There it is
  not seen, and `anim` has to do the work.
]

#pause

That is the whole of it: two markers, three steps, and not a number anywhere.
For anything finer (a piece that comes back later, two that arrive together),
reach for `anim`.

== alternatives: one place, changing content

#v(1fr)

// Three versions in the same box, each replacing the one before. The box is as
// large as the largest of them, so nothing around it jumps, which is the whole
// reason to reach for this instead of three separate `anim`s.
#alternatives(
  card(title: [First version])[One replaces the one before it, in exactly the
    same place. Nothing around it moves, because the space reserved is that of
    the largest version.],
  card(title: [Second version])[For the same statement in several passes, or
    for a drawing that changes step by step while its caption stays put.],
  card(title: [Third version])[`inline: true` turns the whole thing into a
    change in the middle of a running line.],
)

#anim([Three cards, one place. Only the last one reaches the PDF. Printed, all
       three would lie on top of one another.], at: 4, enter: "fade-up")

#v(1fr)

= Moving

== morph: the same thing, in a new place

#speaker-note[
  Actually page forward here. A still frame shows nothing at all of what this
  slide is about.
]

#v(1fr)

#statement(size: 1.4em, color: live)[
  #morph(<identity>, $ e^(i pi) + 1 = 0 $)
]

#anim([The same formula stands on the next slide once more. It does not appear
       there anew. It flies across and grows on the way, and the flight is what
       says "this is that formula, not a second one".],
      at: "2-", enter: "fade-up")

#anim([Source and target have to sit on *adjacent* slides; the flight is made
       out of the change between exactly two. Longer chains are built link by
       link.], at: "3-", enter: "fade-up")

#v(1fr)

== #h(0pt)

// A morph and a moving stage would fight each other, so the runtime cross-fades
// wherever a morph meets a slide change, whatever the transition says. The
// "fade" here only makes that explicit for whoever reads the source.
#transition("fade")

#v(1fr)

#align(center, morph(<identity>, text(size: 2.4em, fill: live)[$ e^(i pi) + 1 = 0 $]))

#v(1fr)

#anim(align(center, block(width: 64%,
  text(size: 0.9em, fill: themes.plain.muted)[
    Whatever transition a slide asks for, a morph overrides it with a
    cross-fade: otherwise the flight would ride on a moving stage.
  ])), at: "2-", enter: "fade")

#v(0.5fr)

== pin: when the shape is not enough

#transition("push")

#v(1fr)

Glyphs are paired by their outline, and where that is ambiguous, by proximity.
Usually that is right. Where it is not (because the same letter occurs twice
and the wrong two find each other), the piece gets a name instead.

#statement(size: 1.4em)[
  #morph(<sum>, $ #pin("a", $a$) + #pin("b", $b$) = c $)
]

#anim([On the next slide the same equation is solved for #box($c$). Watch the
       two named terms swap sides: pinned, they take the long way round instead
       of the short one.], at: "2-", enter: "fade-up")

#v(1fr)

== #h(0pt)

#transition("cover")

#v(1fr)

#align(center, morph(<sum>, text(size: 2em)[$ c = #pin("b", $b$) + #pin("a", $a$) $]))

#v(1fr)

#anim(align(center, block(width: 64%,
  text(size: 0.9em, fill: themes.plain.muted)[
    Without the pins both letters would find the nearest matching outline and
    quietly stay where they were.
  ])), at: "2-", enter: "fade")

#v(0.5fr)

= Blocks and media

== The five layouts

#v(1fr)

// `tiles` numbers its own reveals: one tile per step, without a hand-counted
// `at:` on each. The last two arrive together, as one `side-by-side`, which is
// why they are a separate `anim` and not two more tiles.
#tiles(
  columns: (1fr, 1fr, 1fr),
  card(number: 1, title: [card])[A named box. `number:` puts a numbered disc in
    front of the text.],
  card(number: 2, title: [callout])[The one that has to stick, with the bar down
    its left side.],
  card(number: 3, title: [side-by-side])[Columns; `split:` gives the widths.],
)

#anim(side-by-side(
  split: (1fr, 1fr), gutter: 24pt, align: top,
  card(number: 4, title: [statement])[One large line in the middle of the slide,
    while this very slide is using `tiles` and `side-by-side` at once.],
  card(number: 5, title: [tiles])[A grid that staggers itself: one tile per
    step, with no numbering by hand.],
), at: "4-", enter: "rise", exit: "fade")

#v(1fr)

// The drawing function gets a name of its own so `still:` can call it a second
// time, for the single frame that goes into the PDF.
#let wave(t) = {
  // `t` runs from 0 to 1, and Typst renders every frame separately. Here a
  // curve grows from left to right, so the picture shows that it is being
  // *drawn* rather than merely moved.
  let w = 340pt
  let h = 190pt
  let n = 60
  // `calc.round` returns a float; `range` wants an integer.
  let upto = calc.max(1, int(calc.round(n * t)))
  let points = range(upto + 1).map(i => (
    i / n * w,
    h / 2 - 54pt * calc.sin(i / n * 3 * calc.pi),
  ))
  box(width: w, height: h, clip: true, {
    place(rect(width: w, height: h, fill: luma(94%), stroke: none))
    place(curve(
      stroke: 4pt + live,
      curve.move(points.first()),
      ..points.slice(1).map(p => curve.line(p)),
    ))
    place(dx: points.last().at(0) - 6pt, dy: points.last().at(1) - 6pt,
          circle(radius: 6pt, fill: live, stroke: none))
  })
}

== Video and flipbook

// Vertically centred: both boxes are shorter than the body, and pinned to the
// top they would leave the lower half of the slide empty.
#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  // `poster` is what stands there while nothing is playing, and in the PDF,
  // where nothing can play at all. Without it that box would be empty on paper.
  // The size is exactly the clip's aspect ratio (1280×720): both the browser and
  // the PDF fill the box and crop for it, so any other ratio would cut something
  // off the sides.
  video("demo.mp4", width: 340pt, height: 191pt, muted: true, loop: true,
        controls: false, radius: 6pt, poster: image("demo-poster.png")),
  flipbook(
    wave,
    frames: 30, fps: 24, width: 340pt, height: 190pt, pingpong: true,
    // On paper there is no motion, so one frame has to do. `auto` would take
    // the first: here a dot at the left edge. `still` puts the finished curve
    // there instead.
    still: wave(1.0),
  ),
)

#anim([A video on the left, a flipbook on the right: drawn frame by frame by
       Typst, played back by the browser. Thirty frames are thirty layouts and
       thirty SVG trees in the file: worth it only where a still would not do.],
      at: "2-", enter: "fade-up")

#v(1fr)

== Embedding a foreign document

// `embed` puts arbitrary HTML into a sandboxed frame. `bridge:` gives that frame
// a name, and `bridge-job` sends it a dictionary on a given step. The package
// never reads it. What it means is known only to the document on the other
// side. This is exactly how `typstage-geogebra` drives its applets.
//
// A `+` at the start of a line is a list bullet in Typst and would throw the
// expression back into markup; the parentheses hold it in code.
//
// Everything in `em`: `embed` puts the deck's basic style in front of the
// document, and inside a zoomed frame one CSS pixel is exactly one point of the
// slide. So the lamp grows with the slides. Written as `78px` it would stay the
// size it has on a laptop even on a projector: measured against the slide,
// about a third as wide. A page that reflows on its own wants `zoom: false`
// instead, and then it spans real screen pixels.
#let lamp = (
  "<style>body{display:grid;place-items:center}"
  + "#p{width:3.4em;height:3.4em;border-radius:50%;background:"
  + themes.plain.muted.to-hex() + ";box-shadow:0 0 0 .3em "
  + themes.plain.border.to-hex() + ";transition:background .45s}</style>"
  + "<div><div id=p></div></div><script>"
  // Without this announcement the frame stays mute: the runtime marks a frame
  // live only once the document has said hello, and sends it nothing until then.
  + "parent.postMessage({typstage:1,ready:1},'*');"
  + "addEventListener('message',function(e){var d=e.data;"
  + "if(!d||d.typstage!==1||!d.jobs)return;"
  + "d.jobs.forEach(function(j){if(j.color)"
  + "document.getElementById('p').style.background=j.color;});});</script>"
)

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  embed(html: lamp, width: 100%, height: 190pt, bridge: "lamp",
        // In paged output nothing can run, and `embed` would leave a
        // labelled grey box. `fallback` puts the lamp at rest there, so
        // whoever holds the handout can see what the frame holds.
        fallback: circle(radius: 24pt, fill: themes.plain.muted,
                         stroke: 5pt + themes.plain.border)),
  stagger[
    - `bridge: "lamp"` names the frame; `bridge-job` sends it a dictionary on
      a step. The lamp changes for that reason and no other.
    - The document has to announce itself once with
      `postMessage({typstage: 1, ready: 1})`, or it silently gets nothing.
    - Paging back replays the whole run with a `reset`, so a job has to be
      repeatable: "set the colour to green", never "make it greener".
  ],
)

// The three jobs sit on the first three steps, next to the first three bullets:
// the lamp is the proof that the sentence beside it is true.
#bridge-job("lamp", (color: themes.plain.muted.to-hex()), at: 1)
#bridge-job("lamp", (color: live.to-hex()), at: 2)
#bridge-job("lamp", (color: done.to-hex()), at: 3)

// `bridge-targets()` reports the names on the current slide, which is how a
// companion package can leave the applet unnamed when there is only one.
#context anim(
  text(size: 0.85em, fill: muted)[
    This slide has #bridge-targets().len() named target:
    #raw(bridge-targets().join(", ")).
  ],
  at: "4-", enter: "fade",
)

#v(1fr)

== The pointer reaches in

// This frame is *not* bridged. No `bridge:`, no jobs, nothing sent from the
// slide at all. What it answers to is a hand, and in the speaker view that
// hand is not in this window: `m` there swaps the pen for the pointer, the
// press and the drag travel as fractions of the stage, and the talk window
// turns them back into pixels of its own before dispatching the event inside
// the frame. Two windows of very different sizes therefore land on the same
// spot in the document.
//
// The wave is the control, and that is not decoration. A dispatched event
// reaches every listener, but it does not drive the browser's own widgets: a
// real `<input type=range>` was measured here and did not move, because a
// browser only drags its own slider for input it trusts. A checkbox and a
// button did answer, since a click carries its activation behaviour along.
// So anything that listens for itself works, and the way to build for this is
// to listen rather than to rely on a native control.
//
// Drawn as SVG rather than a canvas: a canvas allocates its pixels once, and
// inside a zoomed frame it would be enlarged afterwards. An outline has none
// to lose. `non-scaling-stroke` holds the line width where the viewBox is
// stretched to the shape of the box.
#let wave = (
  "<style>"
  + "body{display:flex;flex-direction:column;gap:.4em;overflow:hidden}"
  // The wave takes what is left over after the readout, so the frame is filled
  // whatever height the slide gives it.
  + "svg{flex:1;min-height:0;width:100%;display:block;cursor:grab;touch-action:none}"
  + "svg:active{cursor:grabbing}"
  + "#r{font-size:.72em;display:flex;gap:1.4em}"
  + "#r b{font-variant-numeric:tabular-nums;font-weight:600}"
  + "</style>"
  + "<svg id=\"s\" viewBox=\"0 0 400 130\" preserveAspectRatio=\"none\">"
  + "<line x1=\"0\" y1=\"65\" x2=\"400\" y2=\"65\" vector-effect=\"non-scaling-stroke\""
  + " stroke=\"" + themes.plain.border.to-hex() + "\" stroke-width=\"1\"/>"
  + "<polyline id=\"w\" fill=\"none\" vector-effect=\"non-scaling-stroke\""
  + " stroke=\"" + live.to-hex() + "\" stroke-width=\"2.4\" stroke-linejoin=\"round\"/>"
  // A transparent sheet over the whole box, so a press anywhere counts and not
  // only one that happens to hit the line.
  + "<rect x=\"0\" y=\"0\" width=\"400\" height=\"130\" fill=\"transparent\"/>"
  + "</svg>"
  + "<div id=\"r\"><span>frequency <b id=\"fv\">2.0</b></span>"
  + "<span>amplitude <b id=\"av\">0.60</b></span>"
  + "<span style=\"opacity:.55\">drag anywhere on the wave</span></div>"
  + "<script>"
  + "var S=document.getElementById('s'),W=document.getElementById('w');"
  + "var n=2,m=0.6,zieht=0;"
  + "function draw(){var p=[],i,x;"
  + "for(i=0;i<=240;i++){x=i*400/240;"
  + "p.push(x.toFixed(1)+','+(65-Math.sin(i/240*n*2*Math.PI)*m*58).toFixed(1));}"
  + "W.setAttribute('points',p.join(' '));"
  + "document.getElementById('fv').textContent=n.toFixed(1);"
  + "document.getElementById('av').textContent=m.toFixed(2);}"
  // Absolute position, not a delta: across the box sets the frequency,
  // distance from the middle line the amplitude. One gesture says both, and a
  // press that arrives without a preceding move still means something.
  + "function stelle(e){var b=S.getBoundingClientRect();if(!b.width)return;"
  + "var x=(e.clientX-b.left)/b.width,y=(e.clientY-b.top)/b.height;"
  + "n=Math.max(1,Math.min(6,1+x*5));"
  + "m=Math.max(0.05,Math.min(1,Math.abs(0.5-y)*2));draw();}"
  + "S.addEventListener('pointerdown',function(e){zieht=1;stelle(e);"
  + "e.preventDefault();});"
  // Move and release on the document: a pointer dragged past the edge of the
  // sheet would otherwise leave the wave standing halfway.
  + "document.addEventListener('pointermove',function(e){if(zieht)stelle(e);});"
  + "document.addEventListener('pointerup',function(){zieht=0;});"
  + "draw();"
  + "</script>"
)

#speaker-note[
  This is the slide to try it on. Press `m`, then drag across the wave. What
  moves is the one in the hall; the frame in front of you is the same document
  and follows the same gesture, so you can see what they see.
]

#v(1fr)

#side-by-side(
  split: (1.05fr, 1fr),
  embed(html: wave, width: 100%, height: 205pt,
        // On paper nothing is dragged, so the fallback is the wave at the
        // setting it starts on.
        fallback: {
          let w = 190pt
          let h = 66pt
          let punkte = range(0, 145).map(i => {
            let x = i / 144.0
            (x * w, h / 2 - calc.sin(x * 2 * 2 * calc.pi) * h * 0.44)
          })
          curve(stroke: 2pt + live, curve.move(punkte.first()),
                ..punkte.slice(1).map(curve.line))
        }),
  stagger[
    - No `bridge:` on this one and no jobs. The slide sends it nothing. The
      only thing it answers to is a hand.
    - In the speaker view `m` swaps the pen for the pointer. Press, drag and
      release travel as fractions of the stage, so a small laptop window and a
      large canvas hit the same point of the document.
    - It reaches listeners, not the browser's own widgets: a click lands, a
      native slider does not move. Build the control yourself and it works.
    - Where the embedded document can mirror itself, as a GeoGebra applet does
      through `typstage-geogebra`, the copy in front of the speaker is operated
      instead and reports what came of it.
  ],
)

#v(1fr)

= Look and output

== Themes are dictionaries

#v(1fr)

#side-by-side(
  split: (1.2fr, 1fr), align: top,
  card(title: [Three ways])[
    `themes.night` takes one of the five that ship with the package.

    `themes.lesson + (accent: blue)` changes one. A theme is a dictionary, so
    `+` is all it takes.

    `theme(paper: …, ink: …, accent: …)` builds one from scratch.
  ],
  callout(title: [What is inside])[
    Colours, fonts, sizes, and one word each for the built shapes: `header`,
    `footer`, `progress`. Only the title and section slides are functions: they
    are whole pictures, not variations on one another.
  ],
)

#v(1fr)

// One swatch: the colour itself next to its name. Written once here so the four
// exported colours are shown by the same shape instead of four hand-built boxes.
#let swatch(c, name) = box(baseline: 0.15em, {
  box(height: 0.72em, width: 0.72em, radius: 2pt, fill: c,
      stroke: 0.5pt + luma(70%))
  h(0.35em)
  raw(name)
})

== What else the package hands out

#v(1fr)

// Each bullet prints its own value instead of describing it: the numbers and
// file names below are read out of the package while it compiles, so this slide
// cannot go stale when the package moves on.
#stagger[
  - `slide-width`, `slide-height` and `slide-margin`: the stage everything is
    measured on. Here #calc.round(slide-width.pt(), digits: 1)pt ×
    #calc.round(slide-height.pt(), digits: 1)pt with a
    #int(slide-margin.pt())pt margin.
  - #swatch(dark, "dark") #swatch(accent, "accent") #swatch(paper, "paper")
    #swatch(muted, "muted"): the default palette, for decks that would rather
    build on it than replace it.
  - `runtime-version` and `runtime-files`: the runtime's CSS and JavaScript,
    for `assets: "split"`, where they sit beside the HTML file rather than
    inside it: #runtime-files.map(f => raw(f.name)).join([, ]).
]

#v(1fr)

== Where to start

#v(1fr)

#side-by-side(
  split: (1fr, 1fr), align: top,
  card(title: [The whole file])[
    #text(size: 0.68em, raw(lang: "typ",
      "#import \"@schule/typstage:0.1.0\": *\n#show: presentation.with(\n  theme: themes.default,\n  title: [My talk],\n  handout: 3,\n)\n\n= First section\n== First slide\nOne point."))
  ],
  card(title: [The three commands])[
    #text(size: 0.68em, raw(lang: "sh",
      "typst compile talk.typ talk.html \\\n  --format html --features html\n\ntypst compile talk.typ slides.pdf\n\n# handout: 3 is set in the file\ntypst compile talk.typ handout.pdf"))
  ],
)

#anim(callout(title: [In the browser])[
  #text(size: 0.85em)[
    `→` `←` one step · `o` overview · `f` full screen · `s` speaker note ·
    `p` print view · `?` key help · `Home` `End` first and last slide
  ]
], at: 2, enter: "rise")

#v(1fr)
