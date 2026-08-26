// Ein Vortrag, dessen Reihenfolge im Raum entschieden wird.
//
//   typst compile vortragen.typ vortragen.html --format html --features html
//   typst compile vortragen.typ vortragen.pdf
//
// Eine Unterrichtsstunde zu John Snows Karte von Soho, 1854. Drei Folien
// fragen die Klasse, und was gerufen wird, deckt die Lehrkraft mit der Ziffer
// auf -- dafür ist `cue` da. Der rote Faden hängt daran, dass die Klasse die
// Karte selbst liest, bevor irgendjemand das Wort Wasser sagt; eine Folge, die
// das Deck vorschreibt, nimmt der Stunde genau das.
//
// Alles Übrige ist gewöhnlich gebaut: `stagger(dim: true)` für einen Gang
// durch eine Begründung, `after: "dimmed"` für einen Satz, der leise
// stehenbleibt, und zu jeder Folie eine Sprechernotiz. Das Deck ist für
// jemanden geschrieben, der es hält.

#import "@schule/typstage:0.1.0": *

// Das Klassenzimmer-Thema, denn hier steht wirklich eins.
#let t = themes.lesson

// Zwei Bedeutungsfarben, einmal festgelegt und überall durchgereicht. Warm ist
// hier immer das Sterben, kühl immer das Wasser -- die beiden Dinge, deren
// Zusammenhang die Stunde behauptet. Nichts sonst bekommt eine Farbe, sonst
// stünde auf der Karte ein drittes Signal, das keine Bedeutung hat.
#let tot = t.strong
#let wasser = t.accent
#let leise = t.muted

#show: presentation.with(
  theme: t,
  title: [The Pump on Broad Street],
  subtitle: [How a map of one Soho street settled an argument about disease],
  author: [Science · Ms Achebe],
  date: [4 February 2026],
  // Überblendung, kein Schub. Auf der Kartenfolie erscheinen Schichten an
  // festen Orten; eine Folie, die selbst verrutscht, ließe den Raum zweimal
  // hintereinander nachsehen, was sich denn nun bewegt hat.
  transition: "fade",
  // Der Folienkörper ist ein Kasten fester Höhe. Ohne das hinge eine kurze
  // Folie am oberen Rand, während die Klasse in die Mitte sieht.
  style: it => { v(1fr); it; v(1fr) },
)

// ═══════════════════════════════════════════════════════════════════════════
//  Die Karte
// ═══════════════════════════════════════════════════════════════════════════
//
// Gezeichnet in einem Kasten fester Größe, alles über `place`. `place` nimmt
// keinen Platz weg, eine Schicht kann also auftauchen, ohne das zu verschieben,
// was schon steht -- und das ist die Bedingung dafür, dass die Ziffern in
// beliebiger Folge gedrückt werden dürfen.
//
// Jede Schicht trägt *nur ihren eigenen Beitrag*: kein Straßennetz, keine
// Punkte doppelt. Sonst übermalte die zuletzt gesetzte Schicht die erste, und
// zwar unabhängig davon, in welcher Reihenfolge aufgedeckt wird.

// Der Zeichenraum ist 430 × 300 groß. Ein Faktor statt umgerechneter Zahlen:
// die Koordinaten unten bleiben ablesbar, und die Karte lässt sich an einer
// einzigen Stelle größer oder kleiner machen.
#let m = 1.0
#let px(v) = v * m * 1pt
#let karte-breite = px(430)
#let karte-hoehe = px(300)

// Eine Straße als blasses Band, nicht als Strich: eine Karte zeigt Gassen, und
// die Toten stehen an ihren Fronten.
#let strasse(x1, y1, x2, y2) = place(top + left, line(
  start: (px(x1), px(y1)), end: (px(x2), px(y2)),
  stroke: (paint: luma(91%), thickness: 7pt * m, cap: "round")))

// Ein Stück Karte an seinem Ort, und zwar als Schicht der Gruppe "karte".
//
// Das `place` steht *außen* und `cue-layer` innen, nicht umgekehrt. Ein
// verfolgtes Element bekommt im Browser seinen Ort aus der Messung, die Typst
// von ihm macht, und ein `place` in seinem Inneren nimmt keinen Platz ein --
// gemessen landete die ganze Schicht dann in der Ecke des Kastens statt auf
// ihrer Straße. Ein Punkt darf so viele Schichten haben, wie er will, also
// bekommt jedes Stück sein eigenes `place`.
#let auf(nr, x, y, body, dx: 0pt, dy: 0pt) = place(
  top + left, dx: px(x) + dx, dy: px(y) + dy,
  cue-layer("karte", nr, body))

// Ein Toter, an seiner Mitte angegeben. `place` setzt die linke obere Ecke,
// der Radius muss also abgezogen werden.
#let punkt(nr, x, y, r: 2.7pt, fill: tot) = auf(
  nr, x, y, dx: -r, dy: -r, circle(radius: r, fill: fill, stroke: none))

// Eine Pumpe: heller Ring mit Kern. Kein gefüllter Kreis -- der sähe aus wie
// ein sehr großer Toter.
#let pumpe(nr, x, y, r: 6pt, fill: wasser) = auf(
  nr, x, y, dx: -r, dy: -r,
  circle(radius: r, fill: white, stroke: 2.2pt + fill))

#let beschriftung(nr, x, y, body, fill: leise, size: 8pt) = auf(
  nr, x, y, text(size: size, fill: fill, weight: 500, body))

// Ein Häuserblock, hell hinterlegt statt gefüllt: unter ihm liegt nichts, was
// verdeckt werden dürfte, aber die Punkte ringsum sollen weiterlaufen.
#let block-haus(nr, x1, y1, x2, y2, body) = auf(nr, x1, y1, rect(
  width: px(x2 - x1), height: px(y2 - y1),
  fill: wasser.lighten(92%), stroke: 1pt + wasser.lighten(45%), radius: 2pt,
  inset: 5pt, text(size: 8pt, fill: wasser.darken(15%), weight: 600, body)))

// Die Toten, Haus für Haus an der Straßenfront. Die Dichte fällt mit der
// Entfernung zur Pumpe -- das ist die ganze Aussage der Karte, und deshalb sind
// es echte Koordinaten und keine gestreute Wolke.
#let tote = (
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

// Snows Linie gleicher Fußwege: von hier an ist eine andere Pumpe näher.
#let grenze = ((140, 80), (258, 70), (332, 112), (340, 192), (298, 236),
               (198, 246), (128, 212), (118, 132))

#let karte = block(width: karte-breite, height: karte-hoehe, {
  // Grundriss. Er steht von Anfang an da: gefragt wird, was auf ihm liegt,
  // nicht wo Soho ist.
  strasse(40, 70, 392, 70)
  strasse(40, 150, 392, 150)
  strasse(58, 240, 392, 240)
  strasse(75, 60, 75, 272)
  strasse(150, 42, 150, 272)
  strasse(300, 42, 300, 272)
  strasse(375, 42, 375, 252)
  place(top + left, dx: px(42), dy: px(128),
        text(size: 8pt, fill: leise, weight: 500, [BROAD STREET]))

  // Schicht 1 bis 5. Sie stehen hier in der geschriebenen Folge, aber welche
  // wann erscheint, entscheidet die Ziffer. Der Quelltext legt allein fest,
  // was über was liegt, und das muss fest sein.
  tote.map(((x, y)) => punkt(1, x, y)).join()

  pumpe(2, 215, 150)
  // Die Beschriftung steht weit unter der Straße statt neben der Pumpe: neben
  // ihr liegen die Toten, und ein Wort über ihnen nähme der Karte ihre Aussage.
  // Der Strich beginnt erst unterhalb der Häuserreihe, sonst liefe er durch
  // einen Punkt.
  // Als Rechteck und nicht als `line`: eine gedrehte Linie ist ein Rahmen ohne
  // Breite, und im Browser bekommt ein verfolgtes Element daraus nichts, was
  // sich zeichnen ließe -- gemessen fehlte der Strich dort, während er auf
  // Papier stand.
  auf(2, 214.5, 168, rect(width: 1pt, height: px(44), fill: wasser,
                          stroke: none))
  beschriftung(2, 174, 214, fill: wasser.darken(10%), size: 8.5pt,
               [Broad Street pump])

  pumpe(3, 75, 70, r: 5pt, fill: leise)
  pumpe(3, 375, 100, r: 5pt, fill: leise)
  pumpe(3, 95, 240, r: 5pt, fill: leise)
  pumpe(3, 352, 240, r: 5pt, fill: leise)

  block-haus(4, 252, 166, 296, 210, [Lion \ Brewery])
  block-haus(4, 165, 90, 215, 138, [Workhouse])

  auf(5, 0, 0, curve(
    stroke: (paint: wasser, thickness: 1.4pt, dash: "dashed"),
    fill: none,
    curve.move((px(grenze.first().at(0)), px(grenze.first().at(1)))),
    ..grenze.slice(1).map(((x, y)) => curve.line((px(x), px(y)))),
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

#statement(color: tot)[
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

// `dim: true` macht aus der Staffelung einen Gang: der Satz, über den gerade
// gesprochen wird, steht da, die vorherigen bleiben lesbar. Für eine
// Begründung, die Schritt für Schritt aufgebaut wird, ist das genau richtig --
// niemand soll den Anfang vergessen haben, wenn der Schluss kommt.
#stagger(dim: true, spacing: 0.9em)[
  - Disease rises off filth as a smell. Call it a *miasma*.
  - It is heaviest in the low ground, where the sewers run and the air stands.
  - The low ground is where the poorest and the most crowded live.
  - And that is exactly where the dying is worst. So: clean the air.
]

// Der letzte Punkt wird mitgedimmt, sobald die Folie nach ihm noch einen
// Schritt hat. Hier ist das gewollt: der Kasten ist der Einwand, und der Gang
// ist über die ganze Begründung hinweg.
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
  is the same map either way. One more thing, if anyone in the room runs their
  machine on "reduce motion": the layers still fade in, and what falls away is
  the travel and not the fading, so nothing here stops being legible.
]

// Die Gruppe steht links und damit *vor* der Karte. Das ist keine Frage des
// Geschmacks: eine Schicht sieht nach, welchen Schritt ihr Punkt bekommen hat,
// und findet nichts, wenn sie zuerst gesetzt wird. Die Spaltenfolge entscheidet
// das hier.
#side-by-side(
  split: (1fr, 1.5fr),
  align: horizon,
  cue("karte")[
    - The dots pile into a few streets and thin out fast.
    - There is a *water pump* standing in the middle of the pile.
    - Round the other pumps there is almost nothing.
    - Two big buildings inside the pile are empty.
    - Snow drew a line: inside it, this pump is the nearest one.
  ],
  align(center, karte),
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

// Jeder Punkt und jede Frage genau eine Zeile lang, und beide Spalten im
// selben Abstand: dann stehen sie auf gleicher Höhe, ohne verkoppelt zu sein.
#side-by-side(
  split: (1fr, 1.05fr),
  align: horizon,
  cue("grund", spacing: 1.25em)[
    - Bad air off the drains.
    - Something they ate.
    - Poverty. The poorest suffer worst.
    - The water from the pump.
  ],
  // Zu jedem Punkt eine Rückfrage, die mit ihm erscheint. Sie hängt an
  // derselben Nummer und reist deshalb mit, ohne verdrahtet zu werden -- wer
  // die Punkte umsortierte, sortierte die Fragen mit.
  {
    let frage(nr, body) = cue-layer("grund", nr, block(
      width: 100%, inset: (left: 12pt, y: 5pt),
      stroke: (left: 2.5pt + wasser),
      text(style: "italic", body),
    ))
    stack(
      spacing: 11pt,
      frage(1, [Then why does it stop at the parish line?]),
      frage(2, [Then why a street and not a shop's customers?]),
      frage(3, [Then why the workhouse, poorest of all?]),
      frage(4, [Then the pump must explain who *lived*.]),
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

#cue("bruch", spacing: 0.9em)[
  - The Lion Brewery, halfway down Broad Street
  - The workhouse on Poland Street, inside the worst of it
  - A widow in Hampstead, two miles away
]

#v(0.8em)

// Drei Kacheln, jede an ihrem Punkt. Sie halten ihren Platz frei, auch solange
// sie niemand genannt hat -- deshalb springt nichts, egal in welcher
// Reihenfolge aufgedeckt wird.
#let zahl(gross, klein) = block(
  // Feste Höhe, damit die drei Kacheln eine Kante bilden. Ohne sie ist jede so
  // hoch wie ihr Text, und welche zuerst genannt wird, entschiede das Bild.
  width: 100%, height: 116pt, inset: (x: 12pt, y: 10pt), radius: 6pt,
  fill: t.surface, stroke: 1pt + t.border,
  {
    text(size: 1.25em, weight: 700, fill: tot, gross)
    linebreak()
    v(0.15em)
    text(size: 0.78em, fill: leise, klein)
  },
)

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 14pt,
  cue-layer("bruch", 1, zahl[70 men, 0 dead][
    Their own well in the yard, and a daily allowance of beer. Not one of them
    drank from the street.
  ]),
  cue-layer("bruch", 2, zahl[535 inmates, 5 dead][
    Its own well and pump inside the walls. The poorest people on the map,
    and almost untouched.
  ]),
  cue-layer("bruch", 3, zahl[2 miles off, 1 dead][
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

// `after: "dimmed"` braucht einen Bereich, der endet: `at: "1-3"` ist so einer,
// `at: 1` liefe bis ans Folienende und hätte kein Danach. Der Satz tritt zurück,
// statt zu verschwinden -- gedämpft, an derselben Stelle, in derselben Farbe.
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
  #text(fill: wasser, weight: 600)[Water.] It is the only one of the four that
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

#align(center, statement(color: wasser, size: 1.3em)[
  On 8 September the pump handle came off.
])

== What the handle did not do

#speaker-note[
  Expect someone to feel cheated by this slide. Good. The story they have
  heard before is that the handle stopped the outbreak, and the chart says it
  cannot have. Snow said so himself, in print, about his own case.
]

// Die Angriffe je Tag, aus Snows eigener Tabelle. Die Zahlen stehen hier und
// nicht in einer Erzählung, weil die Folie sonst nur behauptete, was sie
// zeigen soll: die Kurve fällt lange vor dem 8. September.
#let tage = (
  ("31", 56), ("1", 143), ("2", 116), ("3", 54), ("4", 46), ("5", 36),
  ("6", 20), ("7", 28), ("8", 12), ("9", 11), ("10", 5),
)
#let saeule = 25pt
#let luecke = 7pt
#let hoch = 118pt

#align(center, block(
  width: (saeule + luecke) * tage.len() - luecke,
  height: hoch + 22pt,
  {
    place(top + left, grid(
      columns: (saeule,) * tage.len(),
      column-gutter: luecke,
      row-gutter: 5pt,
      align: bottom,
      ..tage.map(((tag, n)) => rect(
        width: 100%, height: n / 143 * hoch, stroke: none,
        // Ab dem 8. September blass: von da an läuft die Zahl ohne den Griff
        // weiter, und die Farbe soll nicht behaupten, sie täte es deswegen.
        fill: if int(tag) >= 8 and tag != "31" { tot.lighten(65%) } else { tot },
      )),
      ..tage.map(((tag, n)) => align(center, text(size: 0.55em, fill: leise, tag))),
    ))
    // Der Strich am 8. September, auf der Fuge vor der neunten Säule. Der
    // Kasten drumherum ist nötig: eine gedrehte Linie ist ein Rahmen ohne
    // Breite, und ein verfolgtes Element ohne Breite bekommt im Browser keinen
    // Platz zugewiesen -- gemessen fehlte der Strich dort.
    place(top + left, dx: (saeule + luecke) * 8 - luecke / 2 - 1pt, dy: -6pt,
          anim(at: 2, enter: "fade", box(
            width: 2pt, height: hoch + 8pt,
            place(top + left, dx: 1pt, line(
              length: hoch + 8pt, angle: 90deg,
              stroke: (paint: wasser, thickness: 1.4pt, dash: "dashed"))))))
  },
))

#align(center, text(size: 0.72em, fill: leise)[
  new attacks per day, 31 August to 10 September 1854
])

#v(0.4em)

#anim(at: 2, enter: "fade-up")[
  The dashed line is the handle. By then the street had lost three quarters of
  its people to flight, and the attacks had been falling for five days.
]

#anim(at: 3, enter: "fade-up")[
  #text(fill: tot, weight: 600)[So the handle proves nothing.] Snow wrote that
  himself. A cause you cannot separate from a coincidence is not yet a cause.
]

== The proof was in the pipes

#speaker-note[
  This is the payoff, and it is not the famous bit, which is exactly why it is
  worth the time. Same streets, same houses, often the same landlord. The only
  difference between a family that died and a family that did not was which
  company had laid the pipe, and nobody chose that.
]

// Eine Zeile je Gesellschaft, mit einem gemeinsamen Spaltenmaß statt einer
// `table`: eine Tabellenzelle sieht `#pause` nicht, ein `anim` schon.
#let spalten = (420pt, auto, 1fr)
#let zeile(a, b, c, farbe: t.ink) = grid(
  columns: spalten, column-gutter: 14pt,
  align: (left + horizon, right + horizon, left + horizon),
  text(fill: farbe, a),
  text(size: 1.3em, weight: 700, fill: farbe, b),
  text(size: 0.72em, fill: leise, c),
)

#anim(at: 1)[Two companies, one pipe each, down the same streets.]

#v(0.6em)

#anim(at: 2, enter: "fade-right", zeile(
  farbe: tot,
  [*Southwark & Vauxhall* — intake inside London],
  [315], [deaths per 10,000 houses],
))
#v(0.3em)
#anim(at: 3, enter: "fade-right", zeile(
  farbe: wasser,
  [*Lambeth* — intake above the tideway, 1852],
  [37], [deaths per 10,000 houses],
))
#v(0.3em)
#anim(at: 4, enter: "fade-right", zeile(
  farbe: leise,
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

#align(center, text(fill: leise, size: 0.95em)[
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
