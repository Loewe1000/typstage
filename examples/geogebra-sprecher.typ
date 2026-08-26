// GeoGebra from the speaker's side.
//
//   typst compile geogebra-sprecher.typ geogebra-sprecher.html --format html --features html
//   typst compile geogebra-sprecher.typ geogebra-sprecher.pdf
//
// The other example deck shows the slides driving the applet. This one shows
// the hand driving it: press `n` for the speaker window, `m` there for the
// pointer, and the construction in front of you is the live one. What comes of
// it goes to the canvas by itself.
//
// Not shipped with the package (see `exclude` in typst.toml).

#import "@schule/typstage:0.1.0": *

#let live = "https://www.geogebra.org/calculator"

// The theme in a variable, because the applet needs one colour out of it. The
// package's `paper` is the global default and not the theme's, so an applet
// left to `background: auto` would sit as a faintly grey box on this deck's
// white.
#let t = themes.lesson

// The applet gets a fixed width here rather than `100%`, and the viewport it
// is given has the same ratio. `ggb-view` sets the x and the y range
// separately, so a range that does not match the box stretches one axis: a
// circle becomes an ellipse and a right angle stops looking like one. 424 by
// 262 is 1.618 to one, and so is 8.4 by 5.2.
#let kasten = (breite: 424pt, hoehe: 262pt)

#presentation(
  theme: t,
  title: [Dragging in front of the class],
  subtitle: [A GeoGebra construction, operated from the speaker window],
  author: [typstage],
  transition: "fade",

  slide([Where the hand is], {
    v(1fr)
    side-by-side(
      split: (1fr, 1fr),
      callout(title: [Two keys])[
        `n` opens the speaker window. Put that one in front of you and the
        first one on the projector.

        `m` there swaps the pen for the pointer. From then on the applet on
        your screen is the one you are working in.
      ],
      stagger[
        - The speaker window runs its own copy of every applet. It is not a
          picture of the other one, it is a second live construction.
        - Drag a point, push a slider, pan the view: the copy on the canvas
          follows, because the one in front of you says what became of it.
        - Only what a hand touched travels. An animation running on both sides
          sends nothing, since both sides already run it.
      ],
    )
    v(1fr)
  }, note: [
    Open the second window before you start talking, not while they watch.
    The applet needs a moment to load in both, and the room does not need to
    see that.
  ]),

  slide([The angle that will not move], {
    v(1fr)
    grid(
      columns: (kasten.breite, 1fr),
      gutter: 20pt,
      align: horizon,
      geogebra("thales", width: kasten.breite, height: kasten.hoehe,
               grid: false, background: t.paper, link: live,
               // On paper there is no dragging, so the fallback is the picture
               // at one position of C, drawn by Typst itself.
               fallback: {
                 let r = 74pt
                 let bogen = range(0, 61).map(i => {
                   let w = i / 60.0 * calc.pi
                   (r * calc.cos(w), -r * calc.sin(w))
                 })
                 let c = (r * calc.cos(1.05), -r * calc.sin(1.05))
                 box(width: 2 * r, height: r + 6pt, {
                   place(dx: r, dy: r, curve(
                     stroke: 1.4pt + luma(55%),
                     curve.move(bogen.first()),
                     ..bogen.slice(1).map(curve.line),
                   ))
                   place(dx: r, dy: r, curve(
                     stroke: 2.4pt + accent,
                     curve.move((-r, 0pt)), curve.line(c), curve.line((r, 0pt)),
                   ))
                 })
               }),
      stagger[
        - The half circle over #math.italic[AB]
        - #math.italic[C] on it, and the two sides
        - the angle at #math.italic[C], with its value
        - a trace, so #math.italic[C] leaves its path behind
      ],
    )

    // The construction. `Point(k)` is a point on a path: it can be dragged,
    // but only along the half circle, which is exactly the freedom the
    // statement is about.
    ggb-run(at: "1-", "A=(-3,0)", "B=(3,0)", "k=Semicircle(A,B)")
    // The grid is switched off twice on purpose: once for the applet as it is
    // built, and once here, because the perspective brings its own settings
    // along and would put it back.
    ggb-view(at: "1-", x: (-4.2, 4.2), y: (-1.0, 4.2), grid: false)
    ggb-style("k", at: "1-", color: luma(45%), thickness: 3)
    // Festgehalten, und das ist keine Kosmetik. A und B spannen den Durchmesser
    // auf; wer sie mitzieht, verschiebt den ganzen Halbkreis, und das ist genau
    // das, was hier nicht gezeigt werden soll. Frei bleibt allein C, und damit
    // greift eine Hand auf dieser Folie immer das Richtige.
    ggb-style("A", "B", at: "1-", color: luma(35%), point-size: 4, fixed: true)

    // `Point(k)` and not `Point(k, 0.3)`. The second form pins the point to
    // that parameter and makes it dependent: it draws in the same place and
    // `isMoveable` then answers false, so no hand can take it. Where it
    // starts is said afterwards with `position:`, which for a point on a path
    // means the nearest place on the path.
    ggb-run(at: 2, "C=Point(k)", "u=Segment(A,C)", "v=Segment(C,B)")
    ggb-style("C", at: 2, color: accent, point-size: 7,
              position: (1.72, 2.46))
    ggb-style("u", "v", at: 2, color: accent, thickness: 4)

    ggb-run(at: 3, "w=Angle(A,C,B)")
    // Label mode 2 is the value alone: the room is meant to read 90°, not "w".
    ggb-style("w", at: 3, color: dark, filling: 0.25, label: true,
              label-mode: 2)

    ggb-style("C", at: 4, trace: true)
    v(1fr)
  }, note: [
    Step 4 is the one to hold. Press `m`, take C and walk it slowly from one
    end to the other. The number stays at 90 the whole way, and the trace
    draws the half circle back as you go. Say the sentence while you are
    moving, not after.

    If someone asks what happens below the line: let go, page back one step
    and build the other half with them.
  ]),

  slide([A family you can push], {
    v(1fr)
    grid(
      columns: (kasten.breite, 1fr),
      gutter: 20pt,
      align: horizon,
      geogebra("family", width: kasten.breite, height: kasten.hoehe,
               grid: false, background: t.paper, link: live,
               fallback: {
                 let w = 150pt
                 let h = 96pt
                 let punkte = range(0, 81).map(i => {
                   let x = -1.0 + i / 40.0
                   (w / 2 + x * w / 2.4, h * 0.62 - (x * x - 1) * h * 0.3)
                 })
                 box(width: w, height: h, {
                   place(line(start: (0pt, h * 0.62), end: (w, h * 0.62),
                              stroke: 1pt + luma(60%)))
                   place(curve(stroke: 2.4pt + accent,
                               curve.move(punkte.first()),
                               ..punkte.slice(1).map(curve.line)))
                 })
               }),
      stagger[
        - Two sliders, one parabola
        - $a$ turns it over and stretches it
        - $b$ lifts the whole thing
        - the roots follow, and that is the point
      ],
    )

    // The fifth argument of `Slider` is its width in pixels. Left out, the
    // bar reaches across a third of the plane and lies over the curve.
    ggb-run(at: "1-", "a=Slider(-2,2,0.1,1,130)", "b=Slider(-3,3,0.1,1,130)",
            "f(x)=a*x^2+b")
    ggb-view(at: "1-", x: (-4.2, 4.2), y: (-2.6, 2.6), grid: false)
    ggb-set((a: 1, b: -1), at: "1-")
    // A slider made by the `Slider` command sits at an absolute position on
    // the screen, so `position:` counts in pixels of the applet and not in
    // coordinates of the plane. Measured: written as (-3.9, 2.2) both landed
    // in the same corner on top of one another.
    ggb-style("a", at: "1-", position: (16, 206), label: true, label-mode: 1,
              color: dark)
    ggb-style("b", at: "1-", position: (16, 236), label: true, label-mode: 1,
              color: dark)
    ggb-style("f", at: "1-", color: accent, thickness: 4)

    // `Root` gives every root there is, and an empty list where there is
    // none. That is the whole lesson of the fourth bullet: push `b` up and
    // the two points meet, touch and are gone.
    ggb-run(at: 4, "N=Root(f)")
    ggb-style("N", at: 4, color: dark, point-size: 6)
    v(1fr)
  }, note: [
    Push `a` down through zero first and let them watch it turn over. Then `b`,
    and stop at the moment the curve lifts off the axis: that is where the
    roots go away, and it is easier to see than to say.

    The sliders are numbers, so what crosses to the canvas is one value each.
  ]),

  slide([What travels, and what does not], {
    v(1fr)
    side-by-side(
      split: (1fr, 1fr),
      card(title: [It travels])[
        A dragged point as its coordinates, a slider as its value. What a hand
        cannot move is left where it is: the other copy works it out from the
        same point.

        A new, deleted or renamed object sends the whole construction instead,
        and panning and zooming travel too, so the room sees the window you
        see.
      ],
      callout(title: [It does not last])[
        A step change resets both copies from the base and replays the jobs of
        the slide, exactly as it did before. So a change made by hand lives as
        long as the step does.

        That is worth knowing rather than working around: page on and the
        construction is back where the deck put it.
      ],
    )
    v(1fr)
  }, note: [
    If you want a position to survive, put it in the deck with `ggb-set` and
    drag from there. The hand is for showing, the file is for keeping.
  ]),
)
