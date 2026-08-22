// themes.night — der abgedunkelte Raum.
//
// Zeigt: alternatives, stagger, morph auf eine titellose Folie, Übergänge je Folie,
// Sprechernotizen.
//
//   typst compile theme-night.typ theme-night.html --format html --features html
//   typst compile theme-night.typ theme-night.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.night

#show: presentation.with(
  theme: t,
  title: [Was ein Rechenzentrum nachts tut],
  subtitle: [Lastverteilung, Wartungsfenster und die Kunst des leisen Neustarts],
  author: [SRE Summit · Halle 2],
  date: datetime(year: 2026, month: 9, day: 30),
  transition: "fade",
)

= Die stille Stunde

== Warum um drei Uhr niemand schläft

#speaker-note[
  Nicht in die Details des Lastverteilers gehen — die Frage aus dem Publikum
  kommt ohnehin, und dann hat man die Folie dafür.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Das Zeitfenster])[
    Zwischen 02:00 und 05:00 fällt die Last auf ein Sechstel. Genau dort
    liegen Migrationen, Reindizierungen und alles, was Sperren hält.

    Wer das Fenster verpasst, verschiebt um einen Tag — nicht um eine Stunde.
  ],
  callout(title: [Der Haken])[
    Ein Sechstel der Last ist nicht ein Sechstel der Nutzer, sondern ein
    anderes Sechstel.

    Nachts laufen die Batchjobs der Kunden. Deren Ausfall sieht niemand
    sofort — und alle am nächsten Morgen.
  ],
)

#v(0.8em)

#anim([Deshalb wird nicht nach Uhrzeit geplant, sondern nach gemessener Last
       je Dienst.], at: 2, enter: "fade-up")

== Der Ablauf, viermal in der Nacht

#transition("cube")

#tiles(
  card(number: 1, title: [Abziehen])[
    Ein Knoten wird aus dem Lastverteiler genommen und läuft leer.
  ],
  card(number: 2, title: [Tauschen])[
    Neues Abbild, neuer Prozess. Der alte bleibt bis zum Beweis liegen.
  ],
  card(number: 3, title: [Zurückgeben])[
    Erst nach drei grünen Prüfungen kommt der Knoten zurück ins Feld.
  ],
)

#v(1em)

#anim(callout(title: [Regel])[
  Nie mehr als ein Knoten je Fehlerdomäne gleichzeitig — sonst ist der
  Rollout selbst der Ausfall.
], at: "4-", enter: "rise")

== Dieselbe Regel, drei Adressaten

#transition("blur")

// `alternatives` setzt die Fassungen übereinander an dieselbe Stelle: eine
// löst die vorige ab, und die Folie springt dabei nicht.
#alternatives(
  card(title: [Für die Bereitschaft])[
    Ein Knoten je Fehlerdomäne. Wer den zweiten zieht, weckt jemanden.
  ],
  card(title: [Für die Geschäftsführung])[
    Wir tauschen die Flotte in vier Nächten statt in einer — und haben in
    jeder Nacht einen Weg zurück.
  ],
  card(title: [Fürs Postmortem])[
    Wenn zwei Knoten gleichzeitig fehlten, war es kein Rollout, sondern ein
    Verfahrensfehler.
  ],
)

#anim([Drei Sätze, eine Regel. Welcher gilt, hängt davon ab, wer im Raum
       sitzt.], at: 4, enter: "fade-up")

== Woran man die Nacht kommen sieht

#transition("uncover")

// `stagger` deckt eine Liste Punkt für Punkt auf — ein Schritt je Punkt.
#stagger[
  - Die Warteschlangen wachsen langsamer, als sie abgearbeitet werden.
  - Der Lastverteiler meldet gleich viele Verbindungen je Knoten.
  - Kein Dienst hat mehr als ein Drittel seines Budgets verbraucht.
]

= Was zählt

== Die eine Zahl

// Quelle des Morphs — die Formel fliegt auf die nächste Folie und wächst
// dabei. Quelle und Ziel müssen dafür auf *benachbarten* Folien stehen.
#statement(color: t.accent)[
  #morph(<budget>, $ "Fehlerbudget" = (1 - "SLO") dot "Zeitraum" $)
]

#anim([Bei 99,9 % im Monat sind das 43 Minuten. Sie werden ausgegeben, nicht
       gespart — ein ungenutztes Budget heißt, dass zu wenig ausgeliefert
       wurde.], at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Woran man eine gute Nacht erkennt])[
  Kein Anruf, kein Eintrag im Vorfallbuch — und am Morgen ein Diagramm, dem
  man nicht ansieht, dass die halbe Flotte ausgetauscht wurde.
], at: "3-", enter: "rise")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift.
== #h(0pt)

#transition("zoom")

// Dieselbe Farbe wie die Quelle: sonst wechselt die Formel mitten im Flug
// die Farbe, was wie ein Aussetzer aussieht.
#place(center + horizon,
       morph(<budget>, text(size: 2em, fill: t.accent)[$ "Fehlerbudget" = (1 - "SLO") dot "Zeitraum" $]))
