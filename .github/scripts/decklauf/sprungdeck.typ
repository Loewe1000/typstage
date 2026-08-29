// Ein Deck für sprung.js. Drei Folien, ein Übergang, der sich Zeit lässt.
//
// `transition-duration: 2000` ist nicht Geschmack, sondern Messtechnik: das
// Fenster zwischen dem Sprung und dem Ablauf des alten Zeitgebers muss breit
// genug sein, dass eine Messung sicher hineinfällt, auch auf einer langsamen
// Maschine. Bei der Vorgabe von 420 ms wäre die Probe ein Wettlauf.
//
// `slide` und nicht `fade`: der Fehler zeigte sich am `transform`, und eine
// Blende hat keins.

#import "@preview/typstage:0.1.0": *

#show: presentation.with(
  title: [Sprungdeck],
  transition: "slide",
  transition-duration: 2000,
)

= Teil

== Eins

Erste Folie.

== Zwei

Zweite Folie.

== Drei

Dritte Folie.
