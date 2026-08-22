// themes.lesson — der Unterricht.
//
//   typst compile theme-lesson.typ theme-lesson.html --format html --features html
//   typst compile theme-lesson.typ theme-lesson.pdf
//
// Zeigt: stagger, alternatives, #pause, morph über drei Folien, Übergänge je
// Folie, Sprechernotizen.

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

#speaker-note[
  Erst zeichnen lassen, dann rechnen. Wer das 3-4-5-Dreieck selbst gezeichnet
  hat, glaubt der Formel eher.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Die Beobachtung])[
    Setzt man auf jede Seite eines rechtwinkligen Dreiecks ein Quadrat, so
    sind die beiden kleinen zusammen genau so groß wie das große.

    Probiert es an einem 3-4-5-Dreieck: $9 + 16 = 25$.
  ],
  callout(title: [Vorsicht])[
    Der Satz gilt nur, wenn der Winkel wirklich $90 degree$ ist.

    Bei einem stumpfen Dreieck ist das große Quadrat größer, bei einem spitzen
    kleiner. Das ist keine Ungenauigkeit — das ist der Satz.
  ],
)

#anim([Der rechte Winkel liegt immer *gegenüber* der längsten Seite.],
      at: 2, enter: "fade-up")

== Dieselbe Aussage, dreimal gesagt

#transition("zoom")

// `alternatives` setzt die Fassungen übereinander an dieselbe Stelle: eine
// löst die vorige ab, und die Folie springt dabei nicht.
#alternatives(
  card(title: [In Worten])[
    In einem rechtwinkligen Dreieck ist die Summe der Quadrate über den
    Katheten so groß wie das Quadrat über der Hypotenuse.
  ],
  card(title: [In Zeichen])[
    #align(center, text(size: 1.5em, $a^2 + b^2 = c^2$))
  ],
  card(title: [Als Frage])[
    Wenn zwei Seiten bekannt sind — wie lang ist die dritte? Genau dafür ist
    der Satz da.
  ],
)

#anim([Drei Fassungen, ein Satz. Sucht euch die aus, die euch beim Rechnen
       hilft.], at: 4, enter: "fade-up")

= Damit rechnen

== In drei Schritten nachgerechnet

#transition("push")

// Die Morph-Quelle steht *außerhalb* der Kacheln, und zwar mit Absicht: ein
// `morph` verbraucht keinen Schritt und ist von Anfang an da — sonst hätte der
// Flug von der Vorfolie kein Ziel. In einer Kachel, die erst in Schritt zwei
// erscheint, stünde die Formel schon in Schritt eins allein im Leeren.
#statement(color: t.strong, above: 0pt)[
  #morph(<satz>, $a^2 + b^2 = c^2$)
]

#tiles(
  card(number: 1, title: [Benennen])[
    Welche Seite liegt dem rechten Winkel gegenüber? Das ist $c$.
  ],
  card(number: 2, title: [Einsetzen])[
    Die beiden bekannten Seiten einsetzen — die gesuchte bleibt allein.
  ],
  card(number: 3, title: [Wurzel ziehen])[
    Am Ende steht eine Länge, also die positive Wurzel.
  ],
)

#anim(callout(title: [Merke])[
  Wer nach einer *Kathete* sucht, zieht ab statt zu addieren:
  $a^2 = c^2 - b^2$.
], at: "4-", enter: "rise")

== Die Leiter an der Wand

// Dieselbe Formel wie auf der Folie davor: sie fliegt herüber und wächst
// dabei, statt neu zu erscheinen. Quelle und Ziel müssen dafür auf
// *benachbarten* Folien stehen — der Flug entsteht beim Übergang zwischen
// genau zwei Folien, eine Abschnittsfolie dazwischen unterbricht ihn.
#statement(color: t.accent)[
  #morph(<satz>, $c = sqrt(a^2 + b^2)$)
]

// `#pause` ist die kurze Schreibweise: alles danach kommt einen Schritt später.
Eine 5 m lange Leiter steht 3 m von der Wand entfernt.

#pause

Wie hoch reicht sie? — $sqrt(5^2 - 3^2) = 4$, also 4 m.

== Woran man es erkennt

#transition("uncover")

// `stagger` deckt eine Liste Punkt für Punkt auf — ein Schritt je Punkt,
// ohne dass man sie nummerieren müsste.
#stagger[
  - Im Text steht „rechtwinklig", „senkrecht" oder „Lot".
  - Zwei Seiten sind gegeben, die dritte gesucht.
  - Eine Skizze zeigt ein Quadrat oder einen Winkelhaken.
]

#anim(card(title: [Hausaufgabe])[
  Buch S. 118, Nr. 3 und 5. Zeichnet erst eine Skizze und schreibt daran,
  welche Seite $c$ ist — erst dann rechnen.
], at: "4-", enter: "rise")
