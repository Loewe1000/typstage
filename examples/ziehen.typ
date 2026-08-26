// "Closing the Door" — ein Vortrag über Dämpfung.
//
//   typst compile ziehen.typ ziehen.html --format html --features html
//   typst compile ziehen.typ ziehen.pdf
//
// Dieses Deck schaltet sein Bild nicht, es zieht es. Die Sprungantwort eines
// gedämpften Schwingers hängt an einer einzigen Zahl, und genau das ist der
// Fall, für den `scene` da ist: das Deck schreibt die Funktion von der Zahl
// auf das Bild und sagt, an welchen Werten der Vortrag hält.
//
// Eine einzige Zeichenfunktion trägt fast alles: die Szene an ζ, die Szene an
// einem Paar aus Feder und Öl, und das Daumenkino, das denselben Kurvenzug
// bekommt und einen Läufer darauf. Nur die Wurzelortskurve ist eine eigene,
// und sie ist die zweite Ansicht derselben Zahl.

#import "@preview/cetz:0.4.2"
#import "@schule/typstage:0.1.0": *

#let t = themes.default

#show: presentation.with(
  theme: t,
  title: [Closing the Door],
  subtitle: [One number decides whether it slams, sticks, or settles],
  author: [A talk on damping],
  date: [26 August 2026],
  // Ein Deck, dessen Inhalt sich stetig bewegt, verträgt keinen Folienwechsel,
  // der selbst schiebt: die Augen sollen den Unterschied zwischen "das Bild
  // wird gezogen" und "die Folie wechselt" nicht erst suchen müssen.
  transition: "fade",
  transition-duration: 380,
  duration: 460,
  style: it => { set par(justify: false); it },
)

// ── Farben mit Bedeutung ────────────────────────────────────────────────────
// Einmal hier festgelegt und überall hineingereicht, damit eine Bedeutung an
// einer Stelle die Farbe wechselt und nicht an sieben.

#let zug = t.accent                       // die Kurve, die gezogen wird
#let ruhe = t.strong.transparentize(35%)  // die Lage, auf die alles zuläuft
#let riss = t.border.darken(22%)          // Achsen und Hilfslinien
#let leise = t.muted                      // Beschriftung

// ── Die Zeichnung ───────────────────────────────────────────────────────────
//
// Die Sprungantwort eines Feder-Masse-Dämpfers: wo steht die Tür zur Zeit `tt`,
// wenn sie bei null losgelassen wird? Zwei Größen bestimmen sie, die
// Eigenfrequenz `w` und der Dämpfungsgrad `z` -- und die Szenen dieses Decks
// unterscheiden sich nur darin, welche davon sie ziehen.

#let ZEIT = 12.0    // gezeigte Sekunden
#let SX = 0.50      // eine Sekunde in Einheiten der Leinwand
#let SY = 2.35      // die Höhe, auf der die Tür zu ist

// Der Kasten, der die Leinwand aufhält. Ohne ihn wüchse sie mit ihrem Inhalt,
// und beim Ziehen wanderte das ganze Bild, statt dass sich die Kurve bewegte;
// das Handbuch beschreibt den Fall unter "Eine Zeichnung, die sich bewegt".
// Was darüber hinausreicht, wird gekappt -- ein Überschwinger, der oben
// hinausliefe, zöge die Leinwand ebenso auf wie ein fehlender Rahmen.
#let RAHMEN = ((-0.85, -1.05), (6.85, 4.6))
#let KAPP-OBEN = 4.30
#let KAPP-UNTEN = -0.45

/// Der Ort der Tür zur Zeit `tt`, als Anteil des Wegs von auf bis zu.
///
/// Drei Fälle, und der mittlere ist keine Feinheit: bei `z = 1` fallen die
/// beiden Wurzeln zusammen, und die Formel für den Schwingfall teilte dort
/// durch null. Eine Szene fährt stetig durch diese Stelle hindurch, also
/// braucht die Umgebung von 1 den eigenen Zweig und nicht bloß der Punkt.
#let ort(w, z, tt) = {
  let a = w * tt
  if calc.abs(z - 1.0) < 0.004 {
    1.0 - (1.0 + a) * calc.exp(-a)
  } else if z < 1.0 {
    let d = calc.sqrt(1.0 - z * z)
    1.0 - calc.exp(-z * a) * (calc.cos(d * a * 1rad) + z / d * calc.sin(d * a * 1rad))
  } else {
    let r = calc.sqrt(z * z - 1.0)
    let (s1, s2) = (-z + r, -z - r)
    1.0 - (s2 * calc.exp(s1 * a) - s1 * calc.exp(s2 * a)) / (s2 - s1)
  }
}

/// Zwei Nachkommastellen, immer. `calc.round` wirft die Null am Ende weg, und
/// eine Ablesung, die zwischen "1" und "0.15" die Stellenzahl wechselt, zappelt
/// beim Ziehen genau da, wo man hinsieht.
#let zwei(x) = {
  let n = calc.round(x, digits: 2)
  let ganz = calc.floor(calc.abs(n))
  let rest = calc.round((calc.abs(n) - ganz) * 100)
  str(ganz) + "." + (if rest < 10 { "0" } else { "" }) + str(rest)
}

/// Der Punkt der Kurve zur Zeit `tt`, schon gekappt.
#let punkt(w, z, tt) = (
  tt * SX,
  calc.max(KAPP-UNTEN, calc.min(KAPP-OBEN, ort(w, z, tt) * SY)),
)

// 60 Stützstellen. Weniger, und der Überschwinger bei kleinem ζ bekommt eine
// Ecke statt einer Spitze; mehr kostet in jedem einzelnen Bild einer Szene.
#let STUETZEN = 60

/// Die Sprungantwort, gezeichnet. `laeufer` setzt einen Punkt auf die Kurve --
/// das ist die einzige Stelle, an der dieses Deck die Uhr statt der Taste
/// entscheiden lässt.
#let antwort(w, z, merkmal: none, laeufer: none) = cetz.canvas(length: 1.787cm, {
  import cetz.draw: *

  rect(..RAHMEN, stroke: rgb(0, 0, 0, 0))

  line((0, KAPP-UNTEN), (0, KAPP-OBEN), stroke: 0.7pt + riss)
  line((0, 0), (6.45, 0), stroke: 0.7pt + riss)
  line((0, SY), (6.45, SY), stroke: (paint: ruhe, thickness: 0.8pt, dash: "dashed"))
  content((0.12, SY + 0.08), text(size: 8pt, fill: ruhe)[shut], anchor: "south-west")
  content((6.45, -0.12), text(size: 8pt, fill: leise)[12 s], anchor: "north-east")

  line(..range(STUETZEN + 1).map(i => punkt(w, z, ZEIT * i / STUETZEN)),
       stroke: 1.6pt + zug)

  if laeufer != none {
    let p = punkt(w, z, laeufer)
    line((p.at(0), 0), p, stroke: (paint: zug.transparentize(70%), thickness: 0.8pt))
    circle(p, radius: 0.11, fill: zug, stroke: none)
  }

  // Die Skala, auf der ζ steht. Sie ist die eigentliche Auskunft der Szene:
  // was hier wandert, ist der Wert, den die Taste zieht.
  let skala(x) = (0.3 + x / 2.0 * 2.6, -0.68)
  line(skala(0.0), skala(2.0), stroke: 1.0pt + riss)
  for m in (0, 1, 2) {
    line((skala(m).at(0), -0.78), (skala(m).at(0), -0.58), stroke: 1.0pt + riss)
    content((skala(m).at(0), -0.80), text(size: 7pt, fill: leise)[#m],
            anchor: "north")
  }
  content((0.15, -0.68), text(size: 9pt, fill: leise)[$zeta$], anchor: "east")
  circle(skala(calc.min(2.0, z)), radius: 0.13, fill: zug, stroke: none)

  // Die Ablesung. In einem Kasten fester Breite, damit eine Ziffer mehr nichts
  // verschiebt -- innerhalb des Rahmens ist das Kosmetik, am Rand wäre es der
  // Unterschied zwischen stehen und wandern.
  content((6.45, 4.4), box(width: 4.8cm, align(right, text(size: 11pt, fill: leise, {
    if merkmal != none [#merkmal #h(0.8em)]
    text(fill: zug)[$zeta = #zwei(z)$]
  }))), anchor: "north-east")
})

/// Dieselbe Zahl, zweite Ansicht: die beiden Wurzeln von $s^2 + 2 zeta s + 1$.
///
/// Sie sind der Grund, warum bei ζ = 1 etwas passiert und nicht bloß etwas
/// weitergeht -- und deshalb bekommen sie eine eigene Szene statt einer Formel.
// Der Maßstab folgt aus dem weitesten Halt: bei ζ = 2 liegt die ferne Wurzel
// bei −3,73, und sie soll im Bild stehen und nicht am Rand kleben. Daraus fällt
// die Einheit, und aus ihr der Rahmen -- nicht umgekehrt.
#let E = 1.91                                  // eine Einheit der komplexen Ebene
#let RAHMEN2 = ((-7.75, -3.215), (0.9, 3.215))

#let wurzeln(z) = cetz.canvas(length: 1.59cm, {
  import cetz.draw: *

  rect(..RAHMEN2, stroke: rgb(0, 0, 0, 0))

  line((-7.3, 0), (0.7, 0), stroke: 0.7pt + riss)
  line((0, -2.55), (0, 2.55), stroke: 0.7pt + riss)
  content((0.7, -0.1), text(size: 8pt, fill: leise)[Re], anchor: "north-east")
  content((0.12, 2.55), text(size: 8pt, fill: leise)[Im], anchor: "north-west")
  for m in (1, 2, 3) {
    line((-m * E, -0.12), (-m * E, 0.12), stroke: 0.7pt + riss)
    content((-m * E, -0.16), text(size: 7.5pt, fill: leise)[$-#m$], anchor: "north")
  }

  // Der Kreis, auf dem das Paar wandert, solange es eines ist: sein Radius ist
  // die Eigenfrequenz, und der Regler dreht nur den Winkel. Deshalb ist bei
  // ζ = 1 Schluss -- weiter links auf dem Kreis gibt es nichts mehr.
  // Als Streckenzug und nicht als `arc`: welche der beiden Hälften cetz aus
  // einem Winkelpaar macht, muss man nachschlagen -- aus Punkten liest man es.
  line(..range(41).map(i => {
    let a = (90deg + i * 4.5deg)
    (E * calc.cos(a), E * calc.sin(a))
  }), stroke: (paint: ruhe, thickness: 0.8pt, dash: "dashed"))

  let punkte = if z < 1.0 {
    let d = calc.sqrt(1.0 - z * z)
    ((-z * E, d * E), (-z * E, -d * E))
  } else {
    let r = calc.sqrt(z * z - 1.0)
    // Gekappt wie die Kurve nebenan: eine Wurzel, die aus dem Rahmen liefe,
    // zöge die Leinwand auf und brächte damit das ganze Bild ins Wandern.
    ((calc.max(-7.1, (-z + r) * E), 0.0), (calc.max(-7.1, (-z - r) * E), 0.0))
  }
  for pk in punkte {
    line((pk.at(0), 0), pk,
         stroke: (paint: zug.transparentize(70%), thickness: 0.8pt))
    circle(pk, radius: 0.17, fill: zug, stroke: none)
  }

  content((-7.6, 3.15), box(width: 3.0cm,
    text(size: 11pt, fill: zug)[$zeta = #zwei(z)$]), anchor: "north-west")
})

/// Der Mechanismus selbst, einmal und unbewegt: Feder, Öl, Masse.
#let bauteil = cetz.canvas(length: 2.15cm, {
  import cetz.draw: *

  line((0, -0.9), (0, 1.5), stroke: 1.2pt + riss)
  for i in range(6) {
    line((0, -0.85 + i * 0.45), (-0.28, -0.6 + i * 0.45), stroke: 0.7pt + riss)
  }

  // Die Feder: sie schließt die Tür. Ihre Zacken sind der Grund, warum
  // überhaupt etwas schwingen kann.
  let zacken = range(13).map(i => (
    0.35 + i * 0.19,
    1.0 + (if calc.rem(i, 2) == 0 { 0.0 } else if calc.rem(i, 4) == 1 { 0.24 } else { -0.24 }),
  ))
  line((0, 1.0), ..zacken, (3.0, 1.0), stroke: 1.1pt + t.strong)
  content((1.7, 1.62), text(size: 14pt, fill: t.strong)[$k$], anchor: "south")

  // Das Öl: es schließt gar nichts. Es entscheidet nur, wie schnell.
  line((0, -0.3), (1.1, -0.3), stroke: 1.1pt + zug)
  rect((1.1, -0.72), (2.0, 0.12), stroke: 1.1pt + zug)
  line((1.55, -0.3), (3.0, -0.3), stroke: 1.1pt + zug)
  line((1.55, -0.62), (1.55, 0.02), stroke: 2.2pt + zug)
  content((1.55, -0.9), text(size: 14pt, fill: zug)[$c$], anchor: "north")

  rect((3.0, -0.75), (3.9, 1.45), fill: t.surface, stroke: 1.2pt + riss)
  content((3.45, 0.35), text(size: 14pt, fill: leise)[$m$])
})

// Die rechte Spalte einer Szenenfolie steht in einem Kasten fester Höhe: die
// Schichten kommen nacheinander und bleiben stehen, und ohne festes Maß rückte
// die ganze Spalte bei jedem Halt nach.
#let neben(body) = box(width: 100%, height: 290pt, body)

/// Eine Zeile, wie sie zu einem Halt gehört: der Wert vorn, der Satz dahinter.
/// Vier davon müssen nebeneinander in den Kasten passen, denn eine Schicht
/// bleibt bis zum Ende der Folie stehen -- deshalb sind die Sätze kurz.
#let halt(marke, body) = block(spacing: 0.7em, grid(
  columns: (52pt, 1fr),
  column-gutter: 9pt,
  text(fill: zug, weight: "bold", size: 0.78em, marke),
  text(size: 0.78em, body),
))

// ═══════════════════════════════════════════════════════════════════════════

= A door is a decision

== Two doors, both wrong

#speaker-note[
  Everybody in the room has met both of these this week. Wait for the nodding
  before you go on; the rest of the talk is easier once they have supplied the
  examples themselves.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  equal: true,
  card(title: [The one that slams])[
    It shuts quickly, arrives faster than it left, and announces itself down
    the whole corridor. Somebody props it open with a chair.
  ],
  card(title: [The one that sticks])[
    It shuts politely and then stops two centimetres short, every time, and the
    latch never catches. Somebody props it open with a chair.
  ],
)

#v(0.6em)

#anim(at: 2, enter: "fade-up", callout(title: [The chair is the tell])[
  Same mechanism, same spring, same door. A door that is wrong in either
  direction stops being a door, and the two failures are one adjustment apart.
])

#v(1fr)

== The same spring, a different valve

#speaker-note[
  If there is a closer on the door of this room, point at it. The screw is
  usually on the end of the barrel and it is usually painted over.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1.15fr),
  gutter: 24pt,
  align: horizon,
  align(center, bauteil),
  [
    A door closer is a spring and a cylinder of oil. The spring is what shuts
    the door. The oil shuts nothing at all — it only resists being moved
    quickly, and there is a screw on it.

    #anim(at: 2, enter: "fade-up")[
      Turning that screw changes nothing about the spring, the door, or the
      room. It changes one number, and that number is the entire difference
      between the two doors on the last slide.
    ]
  ],
)

#v(1fr)

= Turning the knob

== Watch it settle

#speaker-note[
  Do not read the four lines out. Pull the scene one stop at a time and let
  the curve say it; the lines are there so the room can look back.
]

#v(0.5em)

// Der Kern des Decks. Die Halte sind die Werte selbst -- 0,15 bis 2 --, nicht
// ein Anteil an einer Laufzeit: das ist der Unterschied zum Daumenkino und der
// Grund, warum hier die Taste zieht und nicht die Uhr.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "settle",
    z => antwort(1.0, z),
    stops: (0.15, 0.4, 1.0, 2.0),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  neben[
    #scene-layer("settle", 1)[
      #halt[0.15][Barely any oil. It touches the frame after a second and a
        half, then three times more.]
    ]
    #scene-layer("settle", 2)[
      #halt[0.40][A quarter of the way past, once — and at the latch before
        any calmer setting.]
    ]
    #scene-layer("settle", 3)[
      #halt[1.00][No overshoot at all, and it is the first setting with none.
        Watch where it ends up.]
    ]
    #scene-layer("settle", 4)[
      #halt[2.00][Thick oil. Nothing overshoots, and nothing quite arrives
        either.]
    ]
  ],
)

== The number has a name

#v(1fr)

The screw does not set a time, and it does not set a speed. It sets a ratio,
and the ratio is between the oil, the spring, and what has to be moved.

#statement(size: 2.1em, color: t.accent, above: 0.9em, below: 0.7em)[
  $ zeta = c / (2 sqrt(k m)) $
]

#anim(at: 2, enter: "fade-up")[
  Because it is a ratio it carries no units, and because it carries no units
  the same number describes a door, a car on a bad road, and the arm a camera
  hangs from. Nothing above was about doors.
]

#v(1fr)

== Where the boundary is

#speaker-note[
  This is the only algebra in the talk. It exists to make the next slide
  inevitable rather than pretty.
]

#v(0.8em)

Write the motion down and the whole question collapses into one square root:

#statement(size: 1.5em, color: t.strong, above: 0.5em, below: 0.5em)[
  $ s = omega (-zeta plus.minus sqrt(zeta^2 - 1)) $
]

#text(size: 0.88em, stagger(
  start: 2,
  spacing: 0.6em,
  [#text(fill: t.strong)[Under one.] What is under the root is negative, the
   roots are a complex pair — and a complex pair is a door that comes back.],
  [#text(fill: t.strong)[Exactly one.] The root is zero and the pair is one
   number, twice. Nothing is left to oscillate with.],
  [#text(fill: t.strong)[Above one.] Two real roots, moving apart, and the
   slower of them is now in charge.],
))

#v(0.5em)

== The roots go for a walk

#speaker-note[
  Same screw as two slides ago, second view. Say that out loud — otherwise
  half the room takes this for a new topic.
]

#v(0.5em)

// Dieselbe Größe, ein anderes Bild -- und drei der vier Halte sind wörtlich
// dieselben Zahlen wie eine Folie zuvor. Genau dafür nennt `stops` die Werte
// selbst und nicht 0 bis 1: 0,4 heißt hier, was es dort hieß, und man sieht
// es dem Quelltext an, ohne die Szenen nebeneinanderzulegen.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "roots",
    z => wurzeln(z),
    stops: (0.0, 0.4, 1.0, 2.0),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  neben[
    #scene-layer("roots", 1)[
      #halt[0.00][A pair on the imaginary axis. Nothing decays; the door swings
        for ever.]
    ]
    #scene-layer("roots", 2)[
      #halt[0.40][They slide down a circle of fixed radius. The swing now dies
        out.]
    ]
    #scene-layer("roots", 3)[
      #halt[1.00][They meet on the real axis. That happens exactly once.]
    ]
    #scene-layer("roots", 4)[
      #halt[2.00][They part along it. The one creeping back toward zero sets
        the pace.]
    ]
  ],
)

= What the knob costs

== Critical never quite arrives

#speaker-note[
  The word "critical" does the damage. People hear it as "best", and it only
  ever meant "the boundary". Point back at the ζ = 1 curve if anyone doubts
  that it never touches the line.
]

#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  align: top,
  equal: true,
  card(title: [What $zeta = 1$ buys])[
    The overshoot goes to zero, and it is the first setting at which it does.
    One number, one promise — and the promise is about coming back, not about
    getting there.
  ],
  card(title: [What it does not])[
    At $zeta = 1$ the door never touches the frame; it only approaches it.
    Everything that arrives in finite time overshoots: five per cent at
    $zeta = 0.7$, a quarter at $zeta = 0.4$.
  ],
)

#v(0.6em)

#anim(at: 2, enter: "fade-up", callout(title: [Which is why doors are set under one])[
  A door has to latch, so it has to arrive, so it has to overshoot. How much
  depends on who is asleep on the other side of the wall.
])

#v(1fr)

== Two knobs, one number

#speaker-note[
  The middle stop is the one that surprises people: nobody touched the oil,
  and the damping changed anyway.
]

#v(0.5em)

// Ein Halt darf ein Tupel sein, und hier ist er einer: Feder und Öl reisen
// gemeinsam. Das ist die ehrliche Form der Aussage -- ζ ist keine dritte
// Einstellung neben den beiden, sondern das, was beide bewegen.
#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  scene(
    "both",
    (k, c) => antwort(calc.sqrt(k), c / (2 * calc.sqrt(k)),
                      merkmal: text(fill: t.strong)[
                        $k = #zwei(k)$ #h(0.7em) $c = #zwei(c)$
                      ]),
    stops: ((1.0, 1.0), (4.0, 1.0), (4.0, 2.0)),
    tween: 6,
    width: 390pt,
    height: 290pt,
  ),
  neben[
    #scene-layer("both", 1)[
      #halt[$1 · 1$][As sold. That works out at $zeta = 0.5$, and it is a
        reasonable door.]
    ]
    #scene-layer("both", 2)[
      #halt[$4 · 1$][Four times the spring. Twice as quick — and half the
        damping, on the same oil.]
    ]
    #scene-layer("both", 3)[
      #halt[$4 · 2$][Twice the oil puts $zeta$ back at $0.5$, on a door that
        shuts in half the time.]
    ]
    #v(0.5em)
    #scene-layer("both", 3, enter: "fade-up")[
      #text(size: 0.75em, fill: leise)[Two adjustments, and only one of them
        shows up in the answer.]
    ]
  ],
)

= Away from the drawing

== The door itself

#speaker-note[
  Step three starts it. Say the last sentence while it runs — it loops, so
  there is no hurry.
]

#v(0.5em)

#side-by-side(
  split: (392pt, 1fr),
  gutter: 22pt,
  align: top,
  // Das Daumenkino zur Abgrenzung, und mit spätem `at:`: die Uhr beginnt, wenn
  // es zu sehen ist, nicht wenn die Folie kommt. Auf den ersten beiden
  // Schritten liegt es auf Bild 0 still und fängt beim Aufdecken bei null an.
  flipbook(
    u => antwort(1.0, 0.4, laeufer: u * ZEIT),
    frames: 24,
    fps: 20,
    at: "3-",
    width: 390pt,
    height: 290pt,
  ),
  neben(text(size: 0.88em, stagger(
    start: 1,
    spacing: 0.8em,
    [Every picture so far has been a claim about time in which time was an
     axis, and the axis held still while you read it.],
    [That is what a scene is: the value is yours, and the drawing waits for
     the key.],
    [This one does not wait. Twenty-four frames, on the browser's own clock,
     from the moment it is uncovered.],
  ))),
)

== What to set it to

#v(1fr)

#side-by-side(
  split: (1fr, 1.1fr),
  gutter: 24pt,
  align: horizon,
  callout(title: [The whole talk])[
    Too far below one and it argues. At one and above it dawdles, and never
    quite shuts. The screw is worth a quarter turn and ninety seconds of your
    afternoon.
  ],
  [
    #text(size: 0.92em, stagger(
      start: 2,
      spacing: 0.7em,
      [The same number is on the spec sheet of every car suspension, where the
       answer is nearer $0.3$ — a car that never overshoots feels dead.],
      [It is in the arm of every camera crane, where the answer is nearer $1$,
       because a picture that comes back is a picture nobody can use.],
      [And it is in the fade that just carried this slide in. Somebody chose
       it, and the choice was this one.],
    ))
  ],
)

#v(1fr)
