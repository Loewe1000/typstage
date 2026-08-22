// themes.editorial — mit Charakter.
//
// Zeigt: stagger, #pause, morph auf eine titellose Folie, Übergänge je Folie,
// Sprechernotizen.
//
//   typst compile theme-editorial.typ theme-editorial.html --format html --features html
//   typst compile theme-editorial.typ theme-editorial.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.editorial

#show: presentation.with(
  theme: t,
  title: [Der Rand des Satzspiegels],
  subtitle: [Wie Bücher ihre Ränder bekamen und warum sie sie behielten],
  author: [Vortrag zur Buchgeschichte],
  date: datetime(year: 2026, month: 11, day: 6),
  transition: "fade",
)

= Die Herkunft der Ränder

== Kein Zierrat, sondern Handwerk

#speaker-note[
  Das Pergament-Beispiel ist der Moment, an dem es klickt. Nicht abkürzen.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Der Daumen])[
    Ein Kodex wird gehalten, nicht aufgelegt. Der äußere Rand ist der Platz
    für die Hand — er ist breit, weil ein Daumen breit ist.

    Der innere Rand verschwindet dagegen im Bund und darf schmaler sein.
  ],
  callout(title: [Der Kern])[
    Jedes Maß am Buch kommt von einem Körper oder von einem Werkzeug.

    Die Zeilenlänge folgt dem Auge, die Höhe dem Bogen, der Rand der Hand.
    Nichts davon ist Geschmack.
  ],
)

#v(0.8em)

#anim([Der Beweis liegt in den Handschriften: dort, wo geblättert wurde, ist
       das Pergament abgegriffen — genau im Rand.], at: 2, enter: "fade-up")

== Drei Maße, die überlebt haben

#transition("cover")

#tiles(
  card(number: 1, title: [Der Neunerteiler])[
    Van de Graaf teilt Höhe und Breite in Neuntel — der Bund bekommt eins,
    der Außenrand zwei.
  ],
  card(number: 2, title: [Die Zeilenlänge])[
    Sechzig bis siebzig Zeichen. Darüber verliert das Auge beim Rücksprung
    die Zeile.
  ],
  card(number: 3, title: [Der Kopfsteg])[
    Immer schmaler als der Fußsteg — sonst kippt die Seite nach unten weg.
  ],
)

#v(1em)

#anim(callout(title: [Anmerkung])[
  Die Regel vom Fußsteg stammt aus einer Zeit, in der beschnitten wurde.
  Wer heute randlos druckt, erbt sie trotzdem — das Auge hat sich nicht
  geändert.
], at: "4-", enter: "rise")

== Was der Rand leistet

#transition("uncover")

// `stagger` deckt eine Liste Punkt für Punkt auf — ein Schritt je Punkt.
#stagger[
  - Er gibt dem Daumen einen Platz, an dem er nichts verdeckt.
  - Er hält die Zeile kurz genug, dass das Auge zurückfindet.
  - Er fängt den Beschnitt ab, den keine Bindung genau trifft.
]

// `#pause` ist die kurze Schreibweise: alles danach kommt einen Schritt später.
#pause

#callout(title: [Und deshalb])[
  Drei Aufgaben, von denen zwei niemand bemerkt, solange sie erfüllt sind.
]

= Was bleibt

== Der Satz, auf den es hinausläuft

// Quelle des Morphs — der Satz fliegt auf die nächste Folie und wächst dabei.
// Quelle und Ziel müssen dafür auf *benachbarten* Folien stehen.
#statement(color: t.strong)[
  #morph(<griff>, [Der Rand ist kein leerer Platz. Er ist der Griff.])
]

#anim([Auf der Folie heißt das dasselbe: was nicht bis an die Kante läuft,
       lässt sich lesen — und was bis an die Kante läuft, ist ein Bild.],
      at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Zum Weiterlesen])[
  Jan Tschichold, _Ausgewählte Aufsätze über Fragen der Gestalt des Buches_,
  Basel 1975 — besonders das Kapitel über die Willkür der Seitenproportion.
], at: "3-", enter: "rise")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift.
== #h(0pt)

#transition("flip")

// Dieselbe Farbe wie die Quelle: sonst wechselt die Formel mitten im Flug
// die Farbe, was wie ein Aussetzer aussieht.
#place(center + horizon,
       morph(<griff>, text(size: 1.9em, fill: t.strong)[Der Rand ist kein leerer Platz. \ Er ist der Griff.]))
