// Die acht Unterrichts-Themes an einem Deck.
//
//   typst compile --input theme=labor --input class=MA-07 schul-themes.typ labor.pdf
//   typst compile --input theme=labor schul-themes.typ labor.html --format html --features html
//
// Ohne Eingabe gilt `klar` und die Klasse MA-07. Dieselben Namen wie beim
// Arbeitsblatt: klar, atlas, skizze, labor, kontur, leiste, riso, bauhaus.

#import "@preview/typstage:0.3.0": *

#let name = sys.inputs.at("theme", default: "klar")
#let klasse = sys.inputs.at("class", default: "MA-07")

#show: presentation.with(
  theme: name,
  class: klasse,
  title: [Wohin mit Omas Geld?],
  subtitle: [Prozente und Zinsen],
  author: [Herr Schulz],
  date: datetime(year: 2026, month: 11, day: 23),
  // Formeln nach ihren Umrissen messen, damit ein Flug genau dort landet,
  // wo die Formel steht.
  style: it => {
    show math.equation: set text(top-edge: "bounds", bottom-edge: "bounds")
    it
  },
)

= Der Grundwert

== Oma schenkt uns 2400 €

- Sie legt das Geld auf ein Sparkonto.
- Die Bank zahlt *3 %* Zinsen im Jahr.
- Wie viel Geld ist nach einem Jahr dazugekommen?

#pause

#callout(title: [Merke])[
  Der Prozentwert ist ein Teil des Grundwerts:
  $W = G dot p/100$
]

== Drei Größen, eine Gleichung

#side-by-side(
  card(title: [Grundwert $G$])[Das Ganze, hier 2400~€.],
  card(title: [Prozentsatz $p %$])[Der Anteil, hier 3 %.],
  card(title: [Prozentwert $W$])[Der Teil, den wir suchen.],
)

#anim(align(center, text(1.3em)[$W = 2400 thin "€" dot 3/100 = 72 thin "€"$]), enter: "fade-up")

= Zinsen über Jahre

== Ein Jahr

#align(center, morph(<zins>, text(1.4em)[$ K_1 = #pin("k", $2400 thin "€"$) dot #pin("q", $1","03$) $]))

#v(1em)
Nach einem Jahr stehen 2472 € auf dem Konto.

== Zwei Jahre

#align(center, morph(<zins>, text(1.4em)[$ K_2 = #pin("k", $2400 thin "€"$) dot #pin("q", $1","03$)^2 $]))

#v(1em)
Die Zinsen werden selbst verzinst: 2546,16 €.

== Was wir mitnehmen

#stagger(
  [Prozentwert: Grundwert mal Prozentsatz.],
  [Zinsen sind ein Prozentwert.],
  [Über mehrere Jahre wächst das Geld mit dem Faktor $q$.],
)
