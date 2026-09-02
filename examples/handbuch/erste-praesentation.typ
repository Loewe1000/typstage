#import "@preview/typstage:0.1.1": *

#show: presentation.with(
  title: [Der Satz des Pythagoras],
  subtitle: [Eine Herleitung in vier Schritten],
  author: [Mathematik · Klasse 9],
  date: datetime.today(),
  transition: "slide",
)

= Worum es geht

== Die Behauptung

#speaker-note[Erst die Zerlegung zeigen, dann die Formel -- nicht umgekehrt.]

#stagger[
  - Ein rechtwinkliges Dreieck hat zwei Katheten und eine Hypotenuse.
  - Über jeder Seite steht ein Quadrat.
  - Die beiden kleinen sind zusammen so groß wie das große.
]

#v(1em)

#anim(callout[Genau das behauptet der Satz.], enter: "scale")

== Und das ist die Formel

#statement[$ a^2 + b^2 = c^2 $]
