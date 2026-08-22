// themes.night — der abgedunkelte Raum.
//
// Zeigt: die Argument-Form des Decks, aus einer Datenliste berechnete Folien,
// slide(note:, transition:), embed(html:) als Statusampel, eigene duration
// und transition-duration, anim(delay:), statement, callout, card.
//
//   typst compile theme-night.typ theme-night.html --format html --features html
//   typst compile theme-night.typ theme-night.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.night

// Die Daten der Nacht: drei Dienste, die nacheinander durch das Wartungs-
// fenster laufen. Aus dieser Liste entstehen unten per `for` die Folien —
// nicht von Hand geschrieben, sondern berechnet.
#let dienste = (
  (
    name: [Zahlungsdienst],
    fenster: [02:00 – 02:45],
    vorher: "82 %", nachher: "14 %",
    risiko: [Ein sperrender Batch-Lauf beginnt um 02:30 — danach ist die
             Reihenfolge fest.],
  ),
  (
    name: [Suchindex],
    fenster: [02:45 – 03:30],
    vorher: "76 %", nachher: "9 %",
    risiko: [Während der Reindizierung läuft der Dienst nur lesend —
             Schreibversuche warten bis 03:30.],
  ),
  (
    name: [Video-Transkodierung],
    fenster: [03:30 – 04:15],
    vorher: "91 %", nachher: "22 %",
    risiko: [Die Warteschlange läuft über, wenn das Fenster verschoben
             wird — hier gibt es keinen Puffertag.],
  ),
)

// Eine Folie je Dienst, gebaut mit `for` und der Argument-Form (`slide(...)`
// statt `==`). Jede Folie bekommt ihre eigene Sprechernotiz und einen
// eigenen Übergang, weil sie ein eigenständiger Schritt in der Nacht ist.
#let dienst-folien = {
  let out = ()
  for (i, d) in dienste.enumerate() {
    out.push(slide(
      title: [Fenster #(i + 1): #d.name],
      note: [Zahlen sind Beispielwerte für die Anzeige — es geht um die
             Reihenfolge, nicht um die Nachkommastelle.],
      transition: "push",
    )[
      #side-by-side(
        split: (1fr, 1fr),
        card(title: [Zeitfenster])[
          #text(size: 1.3em, weight: "bold", d.fenster)

          #v(0.6em)

          #anim([Last vorher: *#d.vorher* — Last nachher: *#d.nachher*],
                at: 2, enter: "fade-up", delay: 150)
        ],
        callout(title: [Worauf es ankommt])[
          #d.risiko
        ],
      )
    ])
  }
  out
}

#presentation(
  title-slide(
    title: [Was ein Rechenzentrum nachts tut],
    subtitle: [Lastverteilung, Wartungsfenster und das Fehlerbudget, das
               alles trägt],
    author: [SRE Summit · Halle 2],
    date: datetime(year: 2026, month: 9, day: 30),
  ),

  section([Die stille Stunde]),

  slide(
    title: [Warum um drei Uhr niemand schläft],
    note: [Nicht in die Details des Lastverteilers gehen — die Frage aus dem
           Publikum kommt ohnehin, und dann hat man die Folie dafür.],
    transition: "cube",
  )[
    #side-by-side(
      split: (1fr, 1fr),
      card(title: [Das Zeitfenster])[
        Zwischen 02:00 und 05:00 fällt die Last auf ein Sechstel. Genau dort
        liegen Migrationen, Reindizierungen und alles, was Sperren hält.

        Wer das Fenster verpasst, verschiebt um einen Tag — nicht um eine
        Stunde.
      ],
      callout(title: [Der Haken])[
        Ein Sechstel der Last ist nicht ein Sechstel der Nutzer, sondern ein
        anderes Sechstel.

        Nachts laufen die Batchjobs der Kunden. Deren Ausfall sieht niemand
        sofort — und alle am nächsten Morgen.
      ],
    )

    #v(0.8em)

    #anim([Deshalb wird nicht nach Uhrzeit geplant, sondern nach gemessener
           Last je Dienst — drei Fenster, gleich heute Nacht.],
          at: 2, enter: "fade-up")
  ],

  slide(
    title: [Der Ablauf, viermal in der Nacht],
    transition: "uncover",
  )[
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
  ],

  ..dienst-folien,

  slide(
    title: [Die Ampel für den Saal],
    note: [Das ist die Ansicht, die auf dem zweiten Monitor der Bereitschaft
           steht. Kurz stehen lassen — die Leute lesen sie tatsächlich.],
    transition: "fade",
  )[
    Drei Zahlen, ein Blick: läuft der Lastverteiler im Sollbereich, ist ein
    Wartungsfenster offen, wie viel Fehlerbudget ist heute schon weg.

    #v(0.6em)

    #embed(
      width: 100%, height: 260pt,
      fallback: align(center + horizon,
        text(fill: t.muted)[Statusampel — im Browser interaktiv]),
      label: [Statusampel des Nachtbetriebs],
      html: "<div style=\"height:100%;box-sizing:border-box;padding:14px 18px;"
        + "background:#0f1319;color:#e6ebf2;font-family:-apple-system,"
        + "'Helvetica Neue',Arial,sans-serif;display:flex;flex-direction:column;"
        + "gap:10px;justify-content:center\">"
        + "<style>"
        + "@keyframes pulse{0%{opacity:1}50%{opacity:.45}100%{opacity:1}}"
        + ".dot{width:13px;height:13px;border-radius:50%;flex:none}"
        + ".row{display:flex;align-items:center;gap:12px;font-size:15px}"
        + ".lbl{flex:1}.val{color:#8f9bab;font-variant-numeric:tabular-nums}"
        + "</style>"
        + "<div class=\"row\"><div class=\"dot\" style=\"background:#3ddc84\"></div>"
        + "<div class=\"lbl\">Lastverteiler</div>"
        + "<div class=\"val\">im Sollbereich</div></div>"
        + "<div class=\"row\"><div class=\"dot\" style=\"background:#eab308;"
        + "animation:pulse 1.6s ease-in-out infinite\"></div>"
        + "<div class=\"lbl\">Wartungsfenster</div>"
        + "<div class=\"val\" id=\"wf\">Suchindex — bis 03:30</div></div>"
        + "<div class=\"row\"><div class=\"dot\" style=\"background:#3ddc84\"></div>"
        + "<div class=\"lbl\">Fehlerbudget (Monat)</div>"
        + "<div class=\"val\" id=\"fb\">38 % verbraucht</div></div>"
        + "<div style=\"margin-top:6px;font-size:11px;color:#5b6675\">"
        + "Stand: <span id=\"clk\">02:47</span> Uhr, simuliert</div>"
        + "<script>(function(){"
        + "var m=167;var c=document.getElementById('clk');"
        + "setInterval(function(){m+=1;var hh=Math.floor(m/60)%24;"
        + "var mm=m%60;function p(n){return (n<10?'0':'')+n}"
        + "c.textContent=p(hh)+':'+p(mm);},1000);"
        + "})()</script>"
        + "</div>",
    )
  ],

  section([Was zählt]),

  slide(title: [Die eine Zahl])[
    // Quelle des Morphs — die Formel fliegt auf die nächste Folie und wächst
    // dabei. Quelle und Ziel müssen dafür auf *benachbarten* Folien stehen.
    #statement(color: t.accent)[
      #morph(<budget>, $ "Fehlerbudget" = (1 - "SLO") dot "Zeitraum" $)
    ]

    #anim([Bei 99,9 % im Monat sind das 43 Minuten. Sie werden ausgegeben,
           nicht gespart — ein ungenutztes Budget heißt, dass zu wenig
           ausgeliefert wurde.], at: "2-", enter: "fade-up")

    #v(0.6em)

    #anim(card(title: [Woran man eine gute Nacht erkennt])[
      Kein Anruf, kein Eintrag im Vorfallbuch — und am Morgen ein Diagramm,
      dem man nicht ansieht, dass die halbe Flotte ausgetauscht wurde.
    ], at: "3-", enter: "rise")
  ],

  // Eine Folie ohne Titelbalken: `title: none` gibt ihr keine Überschrift.
  slide(title: none, transition: "zoom")[
    // Dieselbe Farbe wie die Quelle: sonst wechselt die Formel mitten im
    // Flug die Farbe, was wie ein Aussetzer aussieht.
    #place(center + horizon,
           morph(<budget>, text(size: 2em, fill: t.accent)[
             $ "Fehlerbudget" = (1 - "SLO") dot "Zeitraum" $
           ]))
  ],

  duration: 640,
  transition-duration: 500,
  transition: "fade",
  theme: t,
)
