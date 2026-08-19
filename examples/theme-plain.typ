// themes.plain — so wenig wie möglich.
//
//   typst compile theme-plain.typ theme-plain.html --format html --features html
//   typst compile theme-plain.typ theme-plain.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.plain

#show: presentation.with(
  theme: t,
  title: [Weniger Fläche, mehr Zahl],
  subtitle: [Über Diagramme, die nichts erklären wollen],
  author: [Werkstattbericht],
  date: datetime(year: 2026, month: 1, day: 22),
  transition: "fade",
)

= Der Befund

== Zwei Wege, dieselben Daten

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Was gezeigt wird])[
    Ein Balken je Quartal, vier Farben, ein Raster, eine Legende, ein Titel,
    eine Quelle.

    Sieben Zeichenebenen für vier Zahlen. Wer die Zahlen sucht, liest die
    Legende.
  ],
  callout(title: [Der Einwand])[
    Jede Ebene, die nicht von den Daten kommt, verlangt Aufmerksamkeit und
    gibt nichts zurück.

    Man kann sie weglassen und nachsehen, ob etwas fehlt. Meistens fehlt
    nichts.
  ],
)

#v(0.8em)

#anim([Der Prüfstein ist einfach: streichen, und schauen, ob die Aussage
       leidet.], at: 2, enter: "fade-up")

== Drei Streichungen

#tiles(
  card(number: 1, title: [Das Raster])[
    Es hilft beim Ablesen genau dann, wenn keine Zahlen dastehen. Also
    Zahlen hinschreiben.
  ],
  card(number: 2, title: [Die Legende])[
    Zwei Reihen kann man beschriften, wo sie liegen. Der Blick springt nicht
    mehr.
  ],
  card(number: 3, title: [Die Farbe])[
    Sie darf bleiben, wenn sie eine Bedeutung trägt. Sonst ist sie Dekor.
  ],
)

#v(1em)

#anim(callout(title: [Nicht streichen])[
  Die Achsenbeschriftung, die Einheit und den Nullpunkt. Wer daran spart,
  spart am Verständnis, nicht am Beiwerk.
], at: "4-", enter: "rise")

= Das Maß

== Woran man es misst

#statement[
  $ "Datenanteil" = "Tinte für Daten" / "Tinte insgesamt" $
]

#anim([Tufte hat den Bruch 1983 aufgeschrieben. Er ist kein Ziel, sondern eine
       Frage: Wofür ist der Rest da?], at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [In einem Satz])[
  Ein Diagramm ist fertig, wenn nichts mehr weggenommen werden kann, ohne dass
  eine Zahl verschwindet.
], at: "3-", enter: "rise")
