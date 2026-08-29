// GeoGebra — the bridge at work, in one file.
//
//   typst compile geogebra.typ geogebra.html --format html --features html
//   typst compile geogebra.typ geogebra.pdf
//
// The construction is built by GeoGebra, the dramaturgy comes from the slides.
// The `ggb-*` calls sit in the body of the slide they belong to — that is
// where they are collected. They are not visible themselves.
//
// Not shipped with the package (see `exclude` in typst.toml).

#import "@preview/typstage:0.1.0": *
#import "@preview/cetz:0.5.2"

#let live = "https://www.geogebra.org/calculator"

#presentation(
  title: [GeoGebra in typstage],
  subtitle: [Remote-controlled applets — and what stands in the PDF],
  author: [typstage],
  transition: "fade",

  slide([Remote controlled], {
    grid(
      columns: (1.4fr, 1fr),
      gutter: 16pt,
      align: horizon,
      geogebra(app: "classic", perspective: "G",
               width: 100%, height: 240pt,
               // On paper there is no applet: a drawing of our own goes here,
               // and a link to the live one.
               fallback: cetz.canvas(length: 1cm, {
                 import cetz.draw: *
                 line((-2.4, 0), (2.4, 0), stroke: luma(70%))
                 line((0, -0.6), (0, 2.6), stroke: luma(70%))
                 line(..range(0, 49).map(i => {
                   let x = -2.2 + i * 4.4 / 48
                   (x, 0.5 * x * x)
                 }), stroke: dark + 1.6pt)
               }),
               link: live),
      stagger[
        - Jobs go out when the step is entered
        - `a` travels from 1 through 3 to −2
        - last of all the parabola takes the slide's colour
      ],
    )

    ggb-run("a=1", "f(x)=a*x^2", at: "1-")
    // Fix the colour right away: on rebuild GeoGebra would otherwise hand out
    // the next palette colour, and paging back would look different.
    ggb-style("f", at: "1-", color: dark, thickness: 3)
    ggb-set((a: 3), at: 2)
    ggb-set((a: -2), at: 3)
    ggb-style("f", at: 4, color: accent, thickness: 4)
    ggb-set((a: 1), at: 4)
  }),

  slide([Viewport and animation], {
    grid(
      columns: (1.4fr, 1fr),
      gutter: 16pt,
      align: horizon,
      geogebra(app: "classic", perspective: "G",
               grid: false, axes: false, width: 100%, height: 240pt,
               // The last step of the run, drawn by hand: the circle the point
               // has traced, and the radius where the trace was stopped. An
               // empty grey box would say nothing to a reader on paper.
               fallback: cetz.canvas(length: 1cm, {
                 import cetz.draw: *
                 line((-2.9, 0), (2.9, 0), stroke: luma(70%))
                 line((0, -2.9), (0, 2.9), stroke: luma(70%))
                 line(..range(0, 65).map(i => {
                   let a = i * 2 * calc.pi / 64
                   (2 * calc.cos(a), 2 * calc.sin(a))
                 }), stroke: luma(55%) + 1pt)
                 let a = 1.047
                 let px = 2 * calc.cos(a)
                 let py = 2 * calc.sin(a)
                 line((0, 0), (px, py), stroke: dark + 3pt)
                 circle((px, py), radius: 0.11, fill: accent, stroke: none)
               }),
               link: live),
      stagger[
        - 1 — the construction
        - 2 — viewport and colours
        - 3 — animation with a trace
      ],
    )

    ggb-run(at: "1-",
            "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
            "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
    ggb-hide("P", "s", "t", at: "1-")
    ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
    ggb-show("P", "s", at: 2)
    ggb-style("P", at: 2, color: accent, point-size: 6)
    ggb-style("s", at: 2, color: dark, thickness: 3)
    ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
  }),

  slide([Drawing instead of jumping], {
    grid(
      columns: (1.4fr, 1fr),
      gutter: 16pt,
      align: horizon,
      geogebra(app: "classic", perspective: "G",
               grid: false, axes: false, width: 100%, height: 240pt,
               // What the three steps have drawn once they are done: the
               // segment, the arc it swung, and the triangle that closes on
               // them. The arc as a polyline, because which of the two halves
               // `arc` makes of a pair of angles has to be looked up.
               fallback: cetz.canvas(length: 1cm, {
                 import cetz.draw: *
                 line(..range(0, 25).map(i => {
                   let a = i * 1.047 / 24
                   (2.6 * calc.cos(a), 2.6 * calc.sin(a))
                 }), stroke: (paint: luma(55%), thickness: 1.5pt,
                              dash: "dashed"))
                 line((0, 0), (4, 0), (1.5, 2.6), close: true,
                      fill: accent.transparentize(82%), stroke: accent + 2pt)
                 line((0, 0), (4, 0), stroke: dark + 3pt)
               }),
               link: live),
      stagger[
        - the segment grows
        - the arc swings across
        - the triangle closes
      ],
    )

    // GeoGebra's own animation runs back and forth for ever. Drawing needs the
    // opposite — once from 0 to 1 and then stop — so `ggb-tween` counts the
    // value up frame by frame and the construction grows with it.
    ggb-run(at: "1-",
            "t_1=0", "t_2=0",
            "A=(0,0)", "B=(4,0)", "C=(1.5,2.6)",
            "s=Segment(A,(4*t_1,0))",
            "b=CircularArc(A,A+(2.6,0),Rotate(A+(2.6,0),0.0001+1.047*t_2,A))",
            "d=Polygon(A,B,C)")
    ggb-hide("b", "d", "C", at: "1-")
    ggb-view(at: "1-", x: (-1, 5.5), y: (-0.8, 3.2))
    ggb-style("s", at: "1-", color: dark, thickness: 5)
    ggb-style("b", at: "1-", color: luma(55%), thickness: 3, line-style: 2)
    ggb-style("d", at: "1-", color: accent, filling: 0.18, thickness: 4)

    ggb-tween("t_1", at: 1, to: 1, duration: 700)
    ggb-tween("t_2", at: 2, to: 1, duration: 800)
    ggb-show("b", at: 2)
    ggb-show("d", "C", at: 3)
  }),
)
