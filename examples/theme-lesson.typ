// themes.lesson — der Unterricht.
//
//   typst compile theme-lesson.typ theme-lesson.html --format html --features html
//   typst compile theme-lesson.typ theme-lesson.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.lesson

#show: presentation.with(
  theme: t,
  title: [Der Satz des Pythagoras],
  subtitle: [Warum drei Quadrate immer zusammenpassen — Klasse 9],
  author: [Mathematik · Frau Behrens],
  date: datetime(year: 2026, month: 5, day: 4),
  transition: "slide",
)

= Die Entdeckung

== Was am rechtwinkligen Dreieck besonders ist

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Die Beobachtung])[
    Setzt man auf jede Seite eines rechtwinkligen Dreiecks ein Quadrat, so
    sind die beiden kleinen zusammen genau so groß wie das große.

    Probiert es an einem 3-4-5-Dreieck: $9 + 16 = 25$. Es geht auf — und es
    geht bei *jedem* rechtwinkligen Dreieck auf.
  ],
  callout(title: [Vorsicht])[
    Der Satz gilt nur, wenn der Winkel wirklich $90 degree$ ist.

    Bei einem stumpfen Dreieck ist das große Quadrat größer, bei einem spitzen
    kleiner. Das ist keine Ungenauigkeit — das ist der Satz.
  ],
)

#v(0.8em)

#anim([Der rechte Winkel liegt immer *gegenüber* der längsten Seite. Die heißt
       Hypotenuse, die beiden anderen heißen Katheten.],
      at: 2, enter: "fade-up")

== In drei Schritten nachgerechnet

#tiles(
  card(number: 1, title: [Benennen])[
    Welche Seite liegt dem rechten Winkel gegenüber? Das ist $c$.
  ],
  card(number: 2, title: [Einsetzen])[
    $a^2 + b^2 = c^2$ — die gesuchte Größe bleibt allein stehen.
  ],
  card(number: 3, title: [Wurzel ziehen])[
    Am Ende steht eine Länge, also die positive Wurzel.
  ],
)

#v(1em)

#anim(callout(title: [Merke])[
  Wer nach einer *Kathete* sucht, zieht ab statt zu addieren:
  $a^2 = c^2 - b^2$.
], at: "4-", enter: "rise")

= Und wozu

== Die Leiter an der Wand

#statement(color: t.accent)[
  $ c = sqrt(a^2 + b^2) $
]

#anim([Eine 5 m lange Leiter steht 3 m von der Wand entfernt. Wie hoch reicht
       sie? — $sqrt(5^2 - 3^2) = 4$, also 4 m.],
      at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Hausaufgabe])[
  Buch S. 118, Nr. 3 und 5. Zeichnet zu jeder Aufgabe erst eine Skizze und
  schreibt daran, welche Seite $c$ ist — erst dann rechnen.
], at: "3-", enter: "rise")
