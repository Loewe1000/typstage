// themes.plain, abgewandelt — ein eigenes Theme, von Grund auf gebaut.
//
// Zeigt: theme(...) von Grund auf, themes.x + (accent: ...) als Kurzform
// (als Code), den style-Haken an presentation, card/callout mit eigenen
// Farben, tiles mit fester Spaltenbreite, die Paket-Werte accent/muted/
// paper/dark/slide-width, alternatives, statement.
//
//   typst compile theme-plain.typ theme-plain.html --format html --features html
//   typst compile theme-plain.typ theme-plain.pdf

#import "@schule/typstage:0.1.0": *

// Ein eigenes Theme — nicht themes.plain, sondern theme() selbst, mit den
// rohen Werten, die das Paket mitbringt. accent, muted, paper und dark sind
// keine Erfindung dieses Decks; es sind dieselben Farben, die themes.default
// benutzt. Was sie hier anders macht, ist die Zusammenstellung.
#let t = theme(
  paper: paper,
  ink: black,
  strong: dark,
  accent: accent,
  muted: muted,
  surface: white,
  border: luma(88%),
  font: ("Iowan Old Style", "Charter", "Libertinus Serif"),
  size: 19pt,
  title-size: 24pt,
  weight: "regular",
  tracking: 0.2pt,
  header: "plain",
  title-fill: dark,
  rule-size: 1pt,
  rule-fill: muted,
  head-gap: 28pt,
  foot-gap: 22pt,
  footer: "fraction",
  progress: "tick",
)

#show: presentation.with(
  theme: t,
  title: [Die Folie ist auch ein Diagramm],
  subtitle: [Was ein Theme von einem guten Diagramm lernt],
  author: [Werkstattbericht],
  date: datetime(year: 2026, month: 3, day: 4),
  transition: "fade",
  // Der Haken liegt in der Folie, nicht im Theme — er überstimmt es und gilt
  // für alles, was zur Folie gehört: Fließtext, Karten, auch das, was
  // gerade fliegt. `s.body` wird damit eingehüllt, und jeder fliegende Teil
  // bekommt beim Aufsetzen dieselbe Hülle.
  style: it => {
    set text(tracking: 0.15pt)
    set par(justify: true, leading: 0.68em)
    it
  },
)

= Der Befund

== Zwei Wege, dieselben Daten

#speaker-note[
  Die beiden Karten nebeneinander stehen lassen und schweigen. Wer selbst
  zählt, glaubt dem Ergebnis mehr als der Legende.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Was gezeigt wird], color: dark, fill: paper, stroke: 1pt + muted)[
    Ein Balken je Quartal, vier Farben, ein Raster, eine Legende, ein Titel,
    eine Quelle.

    Sieben Zeichenebenen für vier Zahlen. Wer die Zahlen sucht, liest die
    Legende.
  ],
  callout(title: [Der Einwand], color: accent)[
    Jede Ebene, die nicht von den Daten kommt, verlangt Aufmerksamkeit und
    gibt nichts zurück.

    Man kann sie weglassen und nachsehen, ob etwas fehlt. Meistens fehlt
    nichts.
  ],
)

#v(0.8em)

#anim([Der Prüfstein ist einfach: streichen, und schauen, ob die Aussage
       leidet. Das gilt für ein Diagramm — und gleich für die Folie, die es
       zeigt.], at: 2, enter: "fade-up")

== Dieselbe Zahl, dreimal gezeigt

#transition("iris")

// `alternatives` setzt die Fassungen übereinander an dieselbe Stelle.
#alternatives(
  card(title: [Als Diagramm])[
    Ein Balken, vier Farben, ein Raster, eine Legende — und die Zahl steht
    nirgends.
  ],
  card(title: [Als Zahl])[
    #align(center, text(size: 1.6em)[*+12 %*])
  ],
  card(title: [Als Satz])[
    Der Umsatz ist im vierten Quartal um zwölf Prozent gestiegen.
  ],
)

#anim([Drei Fassungen derselben Aussage. Die kürzeste ist nicht immer die
       richtige — aber sie ist der Maßstab, an dem man die anderen misst.],
      at: 4, enter: "fade-up")

= Die Fläche, die trägt

== Vier Farben, ein Auftrag

Der Kanon ist #slide-width breit, keine Zufallszahl — und trägt nur vier
Farben, jede mit genau einer Aufgabe.

#transition("wipe")

#tiles(
  columns: (100pt, 160pt, 220pt, 160pt),
  gutter: 12pt,
  block(width: 100%, {
    rect(width: 100%, height: 52pt, fill: accent, stroke: 0.7pt + dark)
    v(6pt)
    text(size: 0.75em, weight: "bold")[accent]
    v(2pt)
    text(size: 0.66em, fill: muted)[Der eine Punkt, auf den es ankommt.]
  }),
  block(width: 100%, {
    rect(width: 100%, height: 52pt, fill: muted, stroke: 0.7pt + dark)
    v(6pt)
    text(size: 0.75em, weight: "bold")[muted]
    v(2pt)
    text(size: 0.66em, fill: muted)[Alles, was mitläuft, aber nicht führt.]
  }),
  block(width: 100%, {
    rect(width: 100%, height: 52pt, fill: paper, stroke: 0.7pt + dark)
    v(6pt)
    text(size: 0.75em, weight: "bold")[paper]
    v(2pt)
    text(size: 0.66em, fill: muted)[Der Grund selbst — diese Folie steht
      genau darauf. Nur der Rahmen verrät das Feld.]
  }),
  block(width: 100%, {
    rect(width: 100%, height: 52pt, fill: dark, stroke: none)
    v(6pt)
    text(size: 0.75em, weight: "bold")[dark]
    v(2pt)
    text(size: 0.66em, fill: muted)[Die Schrift, wo sie tragen muss.]
  }),
)

== Zwei Wege, ein Theme zu bauen

#transition("push")

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Von Grund auf])[
    #text(size: 0.72em)[
      ```typ
      #theme(
        accent: accent,
        muted: muted,
        header: "plain",
        progress: "tick",
      )
      ```
    ]
    Jeder Eintrag wird neu benannt. Was fehlt, nimmt die Vorgabe von
    `theme()` selbst — nicht die eines der fünf mitgelieferten Themes.
  ],
  card(title: [Die Abkürzung])[
    #text(size: 0.72em)[
      ```typ
      themes.plain + (accent: blue)
      ```
    ]
    Ein Theme ist ein Wörterbuch. `+` schreibt genau die Einträge um, die
    man nennt — der Rest bleibt, wie `plain` ihn vorgibt.
  ],
)

#anim([Dieses Deck nimmt den langen Weg, weil fast jeder Eintrag anders
       heißen sollte. Für eine einzelne Farbe reicht die Abkürzung.],
      at: 3, enter: "fade-up")

== Was überall gleich bleibt

#transition("uncover")

// Der `style`-Haken sitzt in der Folie, nicht im Theme — und wirkt deshalb
// auch auf das, was gerade fliegt.
#stagger[
  - Die Laufweite: 0,15 Punkt mehr, auf jedem Wort, auch im Sprung.
  - Der Randausgleich: `justify: true`, überall gleich eng gesetzt.
  - Ein Morph, der mitten im Flug die Schriftart wechselte, wäre kein Flug
    mehr — nur zwei verschiedene Wörter, die sich ablösen.
]

#anim(callout(title: [Der Unterschied], color: dark)[
  Das Theme setzt Farbe und Fläche. Der Haken setzt, wie der Satz *läuft* —
  und das gilt für die ruhende Folie genauso wie für das Wort, das gerade
  den Bildschirm quert.
], at: "4-", enter: "rise")

= Das Maß

== Der Anteil, neu gerechnet

// Quelle des Morphs — der Bruch fliegt auf die nächste Folie und wächst
// dabei. Quelle und Ziel müssen dafür auf *benachbarten* Folien stehen.
#statement[
  #morph(<anteil>, $ "Datenanteil" = "Tinte für Daten" / "Tinte insgesamt" $)
]

#anim([Tufte hat den Bruch 1983 aufgeschrieben — für ein Diagramm. Er gilt
       genauso für die Folie darum: Kopfzeile, Fortschrittsmarke, jede
       Kachel zählt mit im Nenner.], at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [In einem Satz], color: dark, fill: paper, stroke: 1pt + muted)[
  Ein Theme ist fertig, wenn keine Fläche mehr übrig ist, die nicht für den
  Gedanken arbeitet.
], at: "3-", enter: "rise")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift.
== #h(0pt)

#transition("zoom")

#place(center + horizon,
       morph(<anteil>, text(size: 2em)[$ "Datenanteil" = "Tinte für Daten" / "Tinte insgesamt" $]))
