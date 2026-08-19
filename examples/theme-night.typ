// themes.night — der abgedunkelte Raum.
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

= Was zählt

== Die eine Zahl

#statement(color: t.accent)[
  $ "Fehlerbudget" = (1 - "SLO") dot "Zeitraum" $
]

#anim([Bei 99,9 % im Monat sind das 43 Minuten. Sie werden ausgegeben, nicht
       gespart — ein ungenutztes Budget heißt, dass zu wenig ausgeliefert
       wurde.], at: "2-", enter: "fade-up")

#v(0.6em)

#anim(card(title: [Woran man eine gute Nacht erkennt])[
  Kein Anruf, kein Eintrag im Vorfallbuch — und am Morgen ein Diagramm, dem
  man nicht ansieht, dass die halbe Flotte ausgetauscht wurde.
], at: "3-", enter: "rise")
