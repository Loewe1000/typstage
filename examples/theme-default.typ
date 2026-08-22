// themes.default — der Vortrag im hellen Saal.
//
// Zeigt: stagger, morph auf eine titellose Folie, Übergänge je Folie,
// Sprechernotizen.
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

#speaker-note[
  Hier nicht die Formel vorwegnehmen — die kommt am Schluss und wirkt nur,
  wenn vorher niemand sie gesehen hat.
]

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

#transition("push")

#tiles(
  card(number: 1, title: [Ton])[unter 0,002 mm — schwebt, sinkt kaum],
  card(number: 2, title: [Sand])[0,063 bis 2 mm — springt über den Grund],
  card(number: 3, title: [Kies])[über 2 mm — rollt, und nur bei Hochwasser],
)

#v(1em)

#anim([Deshalb liegt im Oberlauf Geröll und im Mündungsdelta Ton.],
      at: "4-", enter: "fade-up")

== Was ein Fluss unterwegs sortiert

#transition("uncover")

// `stagger` deckt eine Liste Punkt für Punkt auf — ein Schritt je Punkt,
// ohne dass man sie nummerieren müsste.
#stagger[
  - Im Oberlauf bleibt liegen, was zu schwer ist: Blöcke und Geröll.
  - In der Mittelstrecke wandert der Sand, sprungweise über den Grund.
  - Erst im ruhigen Wasser des Deltas sinkt der Ton.
]

#anim(callout(title: [Deshalb])[
  Ein Flussbett ist eine Sortiermaschine. Wer die Korngröße kennt, weiß
  ungefähr, wie schnell das Wasser dort war.
], at: "4-", enter: "rise")

= Was daraus folgt

== Der Kern

// Quelle des Morphs. Auf der nächsten Folie steht dieselbe Formel groß und
// allein — sie fliegt dorthin, statt neu zu erscheinen. Quelle und Ziel müssen
// dafür auf *benachbarten* Folien stehen: der Flug entsteht beim Übergang
// zwischen genau zwei Folien.
#statement(color: t.accent)[
  #morph(<kraft>, $ "Transportkraft" tilde v^6 $)
]

#anim([Doppelte Geschwindigkeit heißt das *64-fache* an Transportkraft. Ein
       Hochwasser bewegt in Stunden, wofür ein Jahr nicht reicht.],
      at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Woran man es sieht])[
  Findlinge mitten in der Aue, die kein heutiger Sommerpegel je bewegt hätte —
  jeder von ihnen ist die Signatur eines einzigen Hochwassers.
], at: "3-", enter: "rise")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift, der
// Rumpf bekommt dafür die ganze Höhe.
== #h(0pt)

#transition("zoom")

// Dieselbe Farbe wie die Quelle: sonst wechselt die Formel mitten im Flug
// die Farbe, was wie ein Aussetzer aussieht.
#place(center + horizon,
       morph(<kraft>, text(size: 2.4em, fill: t.accent)[$ "Transportkraft" tilde v^6 $]))
