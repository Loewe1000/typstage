// A talk whose order is decided in the room.
//
//   typst compile vortragen.typ vortragen.html --format html --features html
//   typst compile vortragen.typ vortragen.pdf
//
// A lesson on John Snow's map of Soho, 1854. Three slides ask the class a
// question, and whatever gets called out the teacher reveals with its digit --
// that is what `cue` is for. The spine of the hour is that the class reads the
// map itself before anybody says the word water, and a deck that dictates the
// order takes exactly that away.
//
// Everything else is built the ordinary way: `stagger(dim: true)` for a walk
// through an argument, `after: "dimmed"` for a sentence that stays quietly, and
// a speaker note on every slide. This deck is written for somebody who holds
// it.

#import "@schule/typstage:0.1.0": *

// The classroom theme, because there really is a classroom here.
#let t = themes.lesson

// Two meaning colours, fixed once and handed everywhere. Warm is always the
// dying, cool is always the water: the two things whose connection the lesson
// claims. Nothing else gets a colour of its own, or the map would carry a third
// signal that means nothing.
#let dead = t.strong
#let water = t.accent
#let quiet = t.muted

#show: presentation.with(
  theme: t,
  title: [The Pump on Broad Street],
  subtitle: [How a map of one Soho street settled an argument about disease],
  author: [Science · Ms Achebe],
  date: [4 February 2026],
  // A cross-fade, not a push. On the map slide, layers appear at fixed places;
  // a slide that slides itself would make the room work out twice over what has
  // actually moved.
  transition: "fade",
  // The slide body is a box of fixed height. Without this a short slide clings
  // to the top edge while the class is looking at the middle.
  style: it => { v(1fr); it; v(1fr) },
)

// ═══════════════════════════════════════════════════════════════════════════
//  The map
// ═══════════════════════════════════════════════════════════════════════════
//
// Drawn in a box of fixed size, everything through `place`. `place` takes up no
// room, so a layer can appear without shifting what already stands -- and that
// is the condition for the digits being allowed to come in any order at all.
//
// Every layer carries *only its own contribution*: no street grid, no dot
// twice. Otherwise the layer set last would paint over the first, and it would
// do so no matter which order things are revealed in.

// The drawing space is 430 by 300. A factor rather than converted numbers: the
// coordinates below stay readable, and the map can be made larger or smaller in
// one single place.
#let zoom = 1.0
#let px(v) = v * zoom * 1pt
#let map-width = px(430)
#let map-height = px(300)

// A street as a pale band rather than a hairline: a map shows lanes, and the
// dead stand along their frontages.
#let street(x1, y1, x2, y2) = place(top + left, line(
  start: (px(x1), px(y1)), end: (px(x2), px(y2)),
  stroke: (paint: luma(91%), thickness: 7pt * zoom, cap: "round")))

// One piece of map at its place, and as a layer of the group "map".
//
// The `place` stands *outside* and `cue-layer` inside, not the other way round.
// A tracked element gets its position in the browser from the measurement Typst
// makes of it, and a `place` inside it takes up no room -- measured, the whole
// layer then landed in the corner of the box instead of on its street. A point
// may carry as many layers as it likes, so every piece gets its own `place`.
#let on-map(nr, x, y, body, dx: 0pt, dy: 0pt) = place(
  top + left, dx: px(x) + dx, dy: px(y) + dy,
  cue-layer("map", nr, body))

// One death, given by its centre. `place` sets the top left corner, so the
// radius has to come off.
#let dot(nr, x, y, r: 2.7pt, fill: dead) = on-map(
  nr, x, y, dx: -r, dy: -r, circle(radius: r, fill: fill, stroke: none))

// A pump: a light ring with a core. Not a filled circle -- that would look like
// a very large death.
#let pump(nr, x, y, r: 6pt, fill: water) = on-map(
  nr, x, y, dx: -r, dy: -r,
  circle(radius: r, fill: white, stroke: 2.2pt + fill))

#let map-label(nr, x, y, body, fill: quiet, size: 8pt) = on-map(
  nr, x, y, text(size: size, fill: fill, weight: 500, body))

// A block of buildings, lightly tinted rather than solid: nothing underneath it
// may be hidden, and the dots around it have to carry on reading as dots.
#let building(nr, x1, y1, x2, y2, body) = on-map(nr, x1, y1, rect(
  width: px(x2 - x1), height: px(y2 - y1),
  fill: water.lighten(92%), stroke: 1pt + water.lighten(45%), radius: 2pt,
  inset: 5pt, text(size: 8pt, fill: water.darken(15%), weight: 600, body)))

// The dead, house by house along the frontage. The density falls with the
// distance to the pump -- that is the whole claim of the map, which is why these
// are real coordinates and not a scattered cloud.
#let deaths = (
  (168, 141), (180, 141), (190, 141), (198, 141), (205, 141), (211, 141),
  (218, 141), (224, 141), (231, 141), (240, 141), (250, 141), (262, 141),
  (278, 141),
  (172, 159), (186, 159), (196, 159), (203, 159), (209, 159), (216, 159),
  (222, 159), (229, 159), (237, 159), (246, 159), (258, 159), (272, 159),
  (159, 100), (159, 116), (159, 128), (159, 138), (159, 168), (159, 182),
  (159, 198), (141, 120), (141, 134), (141, 172), (141, 190),
  (291, 108), (291, 124), (291, 136), (291, 158), (309, 130), (309, 172),
  (200, 61), (230, 61), (265, 61), (190, 249), (225, 249), (255, 249),
  (95, 200), (350, 215),
)

// Snow's line of equal walking distance: beyond it another pump is nearer.
#let boundary = ((140, 80), (258, 70), (332, 112), (340, 192), (298, 236),
               (198, 246), (128, 212), (118, 132))

#let map = block(width: map-width, height: map-height, {
  // The street plan. It stands there from the first step: the question is what
  // lies on it, not where Soho is.
  street(40, 70, 392, 70)
  street(40, 150, 392, 150)
  street(58, 240, 392, 240)
  street(75, 60, 75, 272)
  street(150, 42, 150, 272)
  street(300, 42, 300, 272)
  street(375, 42, 375, 252)
  place(top + left, dx: px(42), dy: px(128),
        text(size: 8pt, fill: quiet, weight: 500, [BROAD STREET]))

  // Layers 1 to 5. They stand here in written order, but which one appears when
  // is decided by the digit. The source settles one thing only -- what lies over
  // what -- and that has to be fixed.
  deaths.map(((x, y)) => dot(1, x, y)).join()

  pump(2, 215, 150)
  // A leader from the pump down to its name. It starts below the row of houses,
  // or it would run through one of the dead.
  //
  // A rect and not a `line`: a rotated line is a frame without width, and a
  // tracked element without width is given no room in the browser -- measured,
  // the leader was missing there while it stood on paper.
  on-map(2, 214.5, 168, rect(width: 1pt, height: px(44), fill: water,
                             stroke: none))
  // The name sits well below the street rather than beside the pump: beside it
  // lie the dead, and a word on top of them would take the map's claim away.
  map-label(2, 174, 214, fill: water.darken(10%), size: 8.5pt,
            [Broad Street pump])

  pump(3, 75, 70, r: 5pt, fill: quiet)
  pump(3, 375, 100, r: 5pt, fill: quiet)
  pump(3, 95, 240, r: 5pt, fill: quiet)
  pump(3, 352, 240, r: 5pt, fill: quiet)

  building(4, 252, 166, 296, 210, [Lion \ Brewery])
  building(4, 165, 90, 215, 138, [Workhouse])

  on-map(5, 0, 0, curve(
    stroke: (paint: water, thickness: 1.4pt, dash: "dashed"),
    fill: none,
    curve.move((px(boundary.first().at(0)), px(boundary.first().at(1)))),
    ..boundary.slice(1).map(((x, y)) => curve.line((px(x), px(y)))),
    curve.close(),
  ))
})


= Ten days in Soho

== Broad Street, September 1854

#speaker-note[
  Say the number and then stop talking. Someone always asks how many people
  lived there: about the same, street for street, as live in one block of flats
  today. That is what makes 500 in ten days the wrong sort of number.
]

#statement(color: dead)[
  More than 500 dead in ten days, all within 250 yards of one corner.
]

#pause

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  card(title: [What the parish did])[
    Cleared the drains. Burned the bedding. Whitewashed the walls. Told
    everyone who could leave to leave, and three quarters of the street did.
  ],
  card(title: [What nobody could say])[
    Why it stopped where it stopped. Two streets over, in houses just as poor
    and just as crowded, almost nobody died.
  ],
)

== What everybody already knew

#speaker-note[
  Read these out as if you believed them, because the people who held them
  were not fools. The class will want to laugh at bad air; do not let them
  until the last line is up.
]

// `dim: true` turns the stagger into a walk: the sentence being spoken about
// stands there, the ones before it stay legible. For an argument built up step
// by step that is exactly right -- nobody should have forgotten the beginning by
// the time the conclusion arrives.
#stagger(dim: true, spacing: 0.9em)[
  - Disease rises off filth as a smell. Call it a *miasma*.
  - It is heaviest in the low ground, where the sewers run and the air stands.
  - The low ground is where the poorest and the most crowded live.
  - And that is exactly where the dying is worst. So: clean the air.
]

// The last point dims along with the rest as soon as the slide has a further
// step after it. That is wanted here: the box is the objection, and by then the
// walk has moved past the whole argument.
#anim(callout(title: [Every line of that is checkable])[
  It fits the map of London, it fits who dies, and it fits what the street
  smells like. A theory that fits everything you can see is not a stupid
  theory. It is a hard one to argue with.
], at: 5, enter: "fade-up")

== What do you see?

#speaker-note[
  Ask the question, then be quiet for a count of ten. Whatever gets called out,
  press its digit -- 1 to 5, in whatever order they come; the right arrow takes
  the next one nobody has named yet, so you can always move on. Do not correct
  the order: if the brewery comes first, the brewery comes first, and the map
  is the same map either way. One more thing, if anyone in the room has "reduce
  motion" switched on: opacity stays and travel goes, so the points stop rising
  and simply fade in, while the map layers were plain fades to begin with.
  Nothing on this slide is carried by the movement.
]

// The group stands on the left and therefore *before* the map. That is not a
// matter of taste: a layer looks up which step its point was given, and finds
// nothing if it is set first. Here the column order settles it.
#side-by-side(
  split: (1fr, 1.5fr),
  align: horizon,
  cue("map")[
    - The dots pile into a few streets and thin out fast.
    - There is a *water pump* standing in the middle of the pile.
    - Round the other pumps there is almost nothing.
    - Two big buildings inside the pile are empty.
    - Snow drew a line: inside it, this pump is the nearest one.
  ],
  align(center, map),
)


= Four ways to explain a map

== Say one. Any one.

#speaker-note[
  This is the slide where you take suggestions and take them seriously. Press
  the digit for whatever they name; the question that goes with it comes up on
  its own, and that question is for them, not for you to answer. If nobody
  says water, do not lead them to it -- number 4 is still there when the other
  three have run out.
]

// Every point and every question exactly one line long, and both columns on the
// same rhythm: then they stand level without being linked to one another.
#side-by-side(
  split: (1fr, 1.05fr),
  align: horizon,
  cue("why", spacing: 1.25em)[
    - Bad air off the drains.
    - Something they ate.
    - Poverty. The poorest suffer worst.
    - The water from the pump.
  ],
  // One question per point, appearing with it. It hangs on the same number and
  // therefore travels with it, without having to be linked -- reorder the points
  // and the questions reorder too.
  {
    let question(nr, body) = cue-layer("why", nr, block(
      width: 100%, inset: (left: 12pt, y: 5pt),
      stroke: (left: 2.5pt + water),
      text(style: "italic", body),
    ))
    stack(
      spacing: 11pt,
      question(1, [Then why does it stop at the parish line?]),
      question(2, [Then why a street and not a shop's customers?]),
      question(3, [Then why the workhouse, poorest of all?]),
      question(4, [Then the pump must explain who *lived*.]),
    )
  },
)

== The three that do not fit

#speaker-note[
  Three places break the pattern. Let them pick which one to open, and open it:
  the order genuinely does not matter, because each one is a whole argument by
  itself. Hold the brewery until last if you can -- free beer is the line they
  will repeat at home, and it is also the cleanest experiment on the slide.
]

#cue("odd", spacing: 0.9em)[
  - The Lion Brewery, halfway down Broad Street
  - The workhouse on Poland Street, inside the worst of it
  - A widow in Hampstead, two miles away
]

#v(0.8em)

// Three tiles, each on its point. They hold their place open even while nobody
// has called them out, so nothing jumps whichever order the reveals come in.
#let tile(head, note) = block(
  // A fixed height, so the three tiles line up along one edge. Without it each
  // is as tall as its own text, and which one gets called first would decide
  // what the slide looks like.
  width: 100%, height: 116pt, inset: (x: 12pt, y: 10pt), radius: 6pt,
  fill: t.surface, stroke: 1pt + t.border,
  {
    text(size: 1.25em, weight: 700, fill: dead, head)
    linebreak()
    v(0.15em)
    text(size: 0.78em, fill: quiet, note)
  },
)

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 14pt,
  cue-layer("odd", 1, tile[70 men, 0 dead][
    Their own well in the yard, and a daily allowance of beer. Not one of them
    drank from the street.
  ]),
  cue-layer("odd", 2, tile[535 inmates, 5 dead][
    Its own well and pump inside the walls. The poorest people on the map,
    and almost untouched.
  ]),
  cue-layer("odd", 3, tile[2 miles off, 1 dead][
    A cart brought her a bottle of Broad Street water every week. She liked
    the taste of it.
  ]),
)

== What is left standing

#speaker-note[
  Three sentences step back here rather than disappear. That is deliberate:
  the class has to see all four claims at once at the end, with three of them
  quiet, or the last line looks like an assertion instead of a remainder.
]

// `after: "dimmed"` wants a range that ends: `at: "1-3"` is one, `at: 1` would
// run to the end of the slide and have no after to rest in. The sentence steps
// back instead of leaving -- muted, in the same place, in the same colour.
#anim(at: "1-3", after: "dimmed")[
  *Bad air.* Then the brewery, the workhouse and the widow are three
  coincidences in a row.
]
#v(0.5em)
#anim(at: "2-3", after: "dimmed")[
  *Food.* Then it would follow a shop's customers, and it follows a street.
]
#v(0.5em)
#anim(at: "3", after: "dimmed")[
  *Poverty.* Then the workhouse should have been the worst place in London.
]
#v(0.5em)
#anim(at: "4-", enter: "fade-up")[
  #text(fill: water, weight: 600)[Water.] It is the only one of the four that
  has an answer for all three.
]


= The handle

== 7 September: Snow at the parish board

#speaker-note[
  He had no germ, no microscope picture, nothing to hold up. What he had was
  this map and the three places that broke it. They gave him the handle
  anyway, and that is worth a sentence: they were not convinced, they were
  out of better ideas.
]

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  card(title: [What he brought])[
    A map with a dot for every death. A list of who drank where. The brewery,
    the workhouse and the widow, written out.
  ],
  card(title: [What he did not bring])[
    Any account of what was in the water. Cholera would not be seen down a
    lens for another thirty years.
  ],
)

#pause

#align(center, statement(color: water, size: 1.3em)[
  On 8 September the pump handle came off.
])

== What the handle did not do

#speaker-note[
  Expect someone to feel cheated by this slide. Good. The story they have
  heard before is that the handle stopped the outbreak, and the chart says it
  cannot have. Snow said so himself, in print, about his own case.
]

// Attacks per day, from Snow's own table. The numbers stand here and not in a
// sentence, because otherwise the slide would merely assert what it is meant to
// show: the curve falls long before 8 September.
#let days = (
  ("31", 56), ("1", 143), ("2", 116), ("3", 54), ("4", 46), ("5", 36),
  ("6", 20), ("7", 28), ("8", 12), ("9", 11), ("10", 5),
)
#let bar-width = 25pt
#let gap = 7pt
#let tall = 118pt

#align(center, block(
  width: (bar-width + gap) * days.len() - gap,
  height: tall + 22pt,
  {
    place(top + left, grid(
      columns: (bar-width,) * days.len(),
      column-gutter: gap,
      row-gutter: 5pt,
      align: bottom,
      ..days.map(((tag, n)) => rect(
        width: 100%, height: n / 143 * tall, stroke: none,
        // Pale from 8 September on: from there the number runs on without the
        // handle, and the colour must not claim it runs on because of it.
        fill: if int(tag) >= 8 and tag != "31" { dead.lighten(65%) } else { dead },
      )),
      ..days.map(((tag, n)) => align(center, text(size: 0.55em, fill: quiet, tag))),
    ))
    // The line at 8 September, on the gap before the ninth bar. The box around
    // it is needed: a rotated line is a frame without width, and a tracked
    // element without width is given no room in the browser -- measured, the
    // line was missing there.
    place(top + left, dx: (bar-width + gap) * 8 - gap / 2 - 1pt, dy: -6pt,
          anim(at: 2, enter: "fade", box(
            width: 2pt, height: tall + 8pt,
            place(top + left, dx: 1pt, line(
              length: tall + 8pt, angle: 90deg,
              stroke: (paint: water, thickness: 1.4pt, dash: "dashed"))))))
  },
))

#align(center, text(size: 0.72em, fill: quiet)[
  new attacks per day, 31 August to 10 September 1854
])

#v(0.4em)

#anim(at: 2, enter: "fade-up")[
  The dashed line is the handle. By then the street had lost three quarters of
  its people to flight, and the attacks had been falling for five days.
]

#anim(at: 3, enter: "fade-up")[
  #text(fill: dead, weight: 600)[So the handle proves nothing.] Snow wrote that
  himself. A cause you cannot separate from a coincidence is not yet a cause.
]

== The proof was in the pipes

#speaker-note[
  This is the payoff, and it is not the famous bit, which is exactly why it is
  worth the time. Same streets, same houses, often the same landlord. The only
  difference between a family that died and a family that did not was which
  company had laid the pipe, and nobody chose that.
]

// One row per company, on a shared column spec rather than in a `table`: a
// table cell does not see `#pause`, an `anim` does.
#let cols = (420pt, auto, 1fr)
#let row(a, b, c, colour: t.ink) = grid(
  columns: cols, column-gutter: 14pt,
  align: (left + horizon, right + horizon, left + horizon),
  text(fill: colour, a),
  text(size: 1.3em, weight: 700, fill: colour, b),
  text(size: 0.72em, fill: quiet, c),
)

#anim(at: 1)[Two companies, one pipe each, down the same streets.]

#v(0.6em)

#anim(at: 2, enter: "fade-right", row(
  colour: dead,
  [*Southwark & Vauxhall* — intake inside London],
  [315], [deaths per 10,000 houses],
))
#v(0.3em)
#anim(at: 3, enter: "fade-right", row(
  colour: water,
  [*Lambeth* — intake above the tideway, 1852],
  [37], [deaths per 10,000 houses],
))
#v(0.3em)
#anim(at: 4, enter: "fade-right", row(
  colour: quiet,
  [The rest of London],
  [59], [deaths per 10,000 houses],
))

#v(0.6em)

#anim(at: 5, callout(title: [Nobody chose their pipe])[
  Same trade, same landlord, next door to each other. Everything is shared
  except the water, so everything except the water cancels.
], enter: "fade-up")

== What a map cannot do on its own

#speaker-note[
  Land this and stop. The map is the famous object, but on its own it is a
  picture of where, and where is not why. What made it an argument was three
  places that ought to have died and did not.
]

#stagger(start: 1, spacing: 0.9em)[
  - A pattern tells you where to look. It does not tell you what you are
    looking at.
  - What turns a pattern into a cause is the case that should break it and
    does not.
  - Snow had three of those, and then a whole city's worth.
]

#pause

#v(0.9em)

#align(center, text(fill: quiet, size: 0.95em)[
  Cholera itself was not seen until 1884, thirty years after the handle came
  off.
])

== Before Thursday

#speaker-note[
  The second one is the real task. Anyone can find a cluster; the question is
  what would have to be true for it to be a coincidence, and how you would
  find out.
]

#stagger(start: 1, spacing: 0.9em)[
  - Write out the brewery in your own words. What is being held constant, and
    what is being varied?
  - Find a cluster in the news this week — anything: illness, accidents, exam
    results. Name one thing you could check that would break it.
  - One paragraph, either question. Bring it on paper.
]
