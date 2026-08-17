// typstage — what the package can do, in one file.
//
//   typst compile example.typ example.html --format html --features html
//   typst compile example.typ example.pdf
//
// The same source gives the animated presentation and a handout. Not shipped
// with the package (see `exclude` in typst.toml).

#import "@schule/typstage:0.1.0": *
#import "@preview/cetz:0.4.2"

#let card(fill: luma(96%), body) = block(
  fill: fill, inset: 12pt, radius: 6pt, width: 100%, body,
)

#show: presentation.with(
  title: [typstage],
  subtitle: [Typst sets, the browser moves — and the same file gives a PDF],
  author: [typstage],
  date: datetime.today(),
  transition: "slide",
  duration: 560,
  // Try `assets: "split"` or `assets: (cdn: "https://…/")` to link the
  // runtime instead of inlining it.
  assets: "inline",
)

== What this file shows

#speaker-note[
  Walk through the four building blocks: reveals, magic move, media, drawn
  animation.
]

#stagger(stagger: 60)[
  - Reveal content *step by step* — with real transitions
  - Let objects *morph* from slide to slide
  - *Embedded* documents right inside the slide
  - Play animations *drawn by Typst*
]

#v(1em)

#anim(
  align(center, card(fill: accent.lighten(85%),
    [And in the end there is *a single `.html`* — and a `.pdf` beside it.])),
  at: "5-", enter: "scale",
)

= Reveals

== Step by step

Every element gets a movement of its own — not just a hard switch. No `at`
anywhere below: each reveal takes the next free step by itself.

#v(0.5em)

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 14pt,
  anim(card[*from the left* \ `enter: "fade-right"`], at: 2, enter: "fade-right"),
  anim(card[*from below* \ `enter: "rise"`], enter: "rise"),
  anim(card[*blurred* \ `enter: "blur"`], enter: "blur"),
)

#v(1em)

#anim([Paging back takes every entrance away again — the same effect in
       reverse.], enter: "fade-up")

== Or simply a pause

For a slide that just unfolds, nothing needs wrapping at all.

#pause

`#pause` puts everything after it one step later.

#pause

A pause begins a new block — and it reads the same on paper.

== One place, several versions

#v(1em)

#align(center, alternatives(
  $ (a + b)^2 $,
  $ (a + b)(a + b) $,
  $ a^2 + 2 a b + b^2 $,
))

#v(1em)

#anim([The box is as large as the largest of them, so nothing around it moves.
       On paper the last one is set.])

= Magic move

== One name, two slides

#speaker-note[The formula is about to travel to the middle and grow.]

#v(2em)

#align(center, morph(<pythagoras>, $a^2 + b^2$))

#v(1em)

#anim(align(center)[
  The same formula sits elsewhere on the next slide — and in another size.
], at: "2-")

== #h(0pt)

#place(center + horizon,
       morph(<pythagoras>, duration: 900, text(size: 2.6em)[$a^2 + b^2 = c^2$]))

#place(bottom + center, dy: -1em,
       anim([A `morph(<pythagoras>)` on both slides is all it takes.],
            at: "2-", enter: "fade-up"))

= Slide transitions

== Every slide may come in differently

#transition("cover", from: "bottom")

#v(1em)

#stagger(stagger: 70)[
  - `transition:` on the presentation applies to everything
  - `#transition("cover", from: "bottom")` in a slide body applies to that one
  - Backwards each transition runs as a true reversal
]

== #h(0pt)

#transition("iris")

#place(center + horizon, text(size: 2em, fill: muted)[`iris`])

= Media

== Arbitrary web content

#speaker-note[
  The embedded document gets a page of its own — the runtime keeps the
  neighbouring steps around, so a `div` would sit in the page three times.
]

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: horizon,
  embed(
    width: 100%, height: 220pt,
    // In the PDF a frame would be an empty box. This is what stands there
    // instead — and a link to the live thing.
    fallback: align(center + horizon, text(fill: muted)[a running canvas]),
    link: "https://developer.mozilla.org/docs/Web/API/Canvas_API",
    html: "<div style=\"height:100%;display:grid;place-items:center;background:#0f1116\">"
      + "<canvas id=\"c\" width=\"320\" height=\"200\"></canvas></div>"
      + "<script>(function(){var c=document.getElementById('c');if(!c)return;"
      + "var x=c.getContext('2d');var s=0;(function d(){s+=0.03;x.clearRect(0,0,320,200);"
      + "x.strokeStyle='#eb5e28';x.lineWidth=2;x.beginPath();"
      + "for(var i=0;i<320;i++){var y=100+60*Math.sin(i/26+s)*Math.cos(i/90-s/2);"
      + "i?x.lineTo(i,y):x.moveTo(i,y);}x.stroke();requestAnimationFrame(d);})();})()</script>",
  ),
  stagger(start: 2)[
    - `embed(html: ..)` inserts your own document
    - `embed(url: ..)` loads a page in an `iframe`
    - `fallback` and `link` take over in the PDF
  ],
)

= Typst animation

== Drawn by Typst, played by the browser

#speaker-note[This is not a video: every frame is rendered by Typst with CeTZ.]

#grid(
  columns: (1fr, 0.85fr),
  gutter: 20pt,
  align: horizon,
  flipbook(
    frames: 40, fps: 20, width: 100%, height: 230pt,
    t => align(center + horizon, cetz.canvas(length: 1.5cm, {
      import cetz.draw: *
      let phase = t * 2 * calc.pi
      set-style(stroke: (thickness: 1pt))
      line((-4.2, 0), (4.2, 0), stroke: luma(70%))
      line((0, -1.8), (0, 1.8), stroke: luma(70%))
      let pts = range(0, 85).map(i => {
        let x = -4 + i * 8 / 84
        (x, 1.4 * calc.sin(x * 1.1 + phase) * calc.cos(x * 0.35 - phase / 2))
      })
      line(..pts, stroke: accent + 1.6pt)
    })),
  ),
  stagger(start: 2)[
    - 40 frames, rendered by Typst
    - CeTZ, Fletcher, equations — anything Typst can do
    - embedded as SVG, so sharp at any size
  ],
)

== In short

#stagger(stagger: 70)[
  - `anim(..)` reveals and hides
  - `morph(name, ..)` carries the same object across slides
  - `video(..)`, `embed(..)` bring media into the slide
  - `flipbook(..)` plays animation drawn by Typst
]

#v(1.5em)

#anim(align(center, text(size: 1.3em)[Enjoy the talk.]),
      at: "5-", enter: "scale")
