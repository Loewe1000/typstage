// themes.default — der Vortrag im hellen Saal.
//
//   typst compile theme-default.typ theme-default.html --format html --features html
//   typst compile theme-default.typ theme-default.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.default

#show: presentation.with(
  theme: t,
  title: [Wie ein Fluss sein Bett gräbt],
  subtitle: [Erosion, Transport, Ablagerung — und warum Mäander wandern],
  author: [Institut für Geomorphologie],
  date: datetime(year: 2026, month: 3, day: 12),
  transition: "slide",
)

= Was Wasser mit Gestein macht

== Drei Vorgänge, ein Fluss

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Der Kreislauf])[
    Ein Fluss nimmt Material auf, trägt es fort und legt es wieder ab. Alle
    drei Vorgänge laufen zu jeder Zeit — nur an verschiedenen Stellen.

    Im Oberlauf überwiegt das Aufnehmen, im Unterlauf das Ablegen.
  ],
  callout(title: [Merke])[
    Entscheidend ist die *Fließgeschwindigkeit*: Sie bestimmt, ob ein Korn
    liegen bleibt oder mitgeht.

    Sie hängt am Gefälle, an der Wassermenge und an der Rauheit des Bettes.
  ],
)

#anim([Am Prallhang wird abgetragen, am Gleithang abgelagert. Genau deshalb
       wandert ein Mäander flussabwärts.], at: 2, enter: "fade-up")

== Die Korngrößen

#tiles(
  card(number: 1, title: [Ton])[unter 0,002 mm — schwebt, sinkt kaum],
  card(number: 2, title: [Sand])[0,063 bis 2 mm — springt über den Grund],
  card(number: 3, title: [Kies])[über 2 mm — rollt, und nur bei Hochwasser],
)

#v(1em)

#anim([Deshalb liegt im Oberlauf Geröll und im Mündungsdelta Ton.],
      at: "4-", enter: "fade-up")

= Was daraus folgt

== Der Kern

#statement(color: t.accent)[
  $ "Transportkraft" tilde v^6 $
]

#anim([Doppelte Geschwindigkeit heißt das *64-fache* an Transportkraft. Ein
       Hochwasser bewegt in Stunden, wofür ein Jahr nicht reicht.],
      at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Woran man es sieht])[
  Findlinge mitten in der Aue, die kein heutiger Sommerpegel je bewegt hätte —
  jeder von ihnen ist die Signatur eines einzigen Hochwassers.
], at: "3-", enter: "rise")
