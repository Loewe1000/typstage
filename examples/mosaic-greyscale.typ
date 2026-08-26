// Greyscale — nach dem Portfolio-Deck des Pakets mosaic.
//
// Vorlage: „Photojournalist Portfolio" von SlidesCarnival
// (https://www.slidescarnival.com/), CC BY 4.0, bearbeitet; mosaic hat sie
// zuerst nach Typst geholt (docs-src/examples/decks/portfolio). Die
// Fotografien der Vorlage sind nicht übernommen; an ihrer Stelle stehen
// Grauflächen aus reinem Typst — Verlauf, Horizont, Silhouette.
//
//   typst compile mosaic-greyscale.typ mosaic-greyscale.html --format html --features html
//   typst compile mosaic-greyscale.typ mosaic-greyscale.pdf
//
// Der Punkt dieses Decks ist eine einzige Zeile. mosaic sagt über seine
// Fassung: „Its monochrome look is one dictionary" — acht Einträge an
// `m.setup(colors: ..)`. typstage hat dafür `palette:`, und das ist beinahe
// wörtlich dasselbe: acht Rollen, teilweise überschreibbar, unabhängig vom
// Entwurf. Alles unten, die Titelfolie und die Abschnittstafel eingeschlossen,
// nennt nur Rollen (`t.ink`, `t.paper`, `t.strong`, `t.accent`). Wer
// `palette: greyscale` gegen `palettes.textbook` tauscht, bekommt dasselbe
// Deck in den Farben eines Mathebuchs, ohne eine zweite Zeile zu ändern.
//
// Was die Vorlage nicht kann und dieses Deck tut: aus dem Kontaktbogen tritt
// ein Bild heraus und wird zum Abzug. Und die große Zahl zählt sich hoch,
// statt dazustehen.

#import "@schule/typstage:0.1.0": *

// ── Die eine Zeile ─────────────────────────────────────────────────────────
// Nebeneinandergestellt mit mosaics `greyscale`-Wörterbuch:
//
//   mosaic          typstage    Wert
//   canvas          paper       #f7f7f5
//   text            ink         #111111
//   muted           muted       #6b6b6b
//   line            border      #d9d9d9
//   surface         surface     white
//   accent          accent      —  siehe unten
//   warning, error  (fehlt)     typstage kennt keine Statusfarben
//   (fehlt)         strong      der dunkle Grund von Titel- und
//                               Abschnittsfolie
//   (fehlt)         inverted    ob die Palette schon gewendet ist
//
// Der eine Wert, der nicht übernommen werden kann, ist der Akzent. mosaic
// setzt ihn auf die Tinte, und das geht dort auf, weil sein Standard-Theme
// keine Akzentform auf dunklem Grund zeichnet. typstage zeichnet eine:
// die Zierlinie über dem Abschnittstitel steht auf `strong`, und Schwarz auf
// Schwarz ist keine Linie. luma(40%) misst 5,74 zu 1 auf Weiß und 3,66 auf
// Schwarz — das Fenster für ein Grau, das auf beiden Gründen hält, ist
// schmal, und das ist die Mitte davon.
#let greyscale = (
  paper: rgb("#f7f7f5"),
  ink: rgb("#111111"),
  strong: rgb("#111111"),
  accent: luma(40%),
  muted: rgb("#6b6b6b"),
  surface: white,
  border: rgb("#d9d9d9"),
)

// ── Grauflächen ────────────────────────────────────────────────────────────
// An der Stelle der Aufnahmen. Ein Verlauf gibt die Tiefe, zwei bis drei
// dunkle Formen die Aussage; mehr braucht eine Fläche nicht, die für ein Foto
// einsteht, ohne eines vorzugeben.

/// Eine Graufläche. `n` wählt die Komposition; alle füllen dieselbe Fläche.
#let gplate(n) = block(width: 100%, height: 100%, clip: true, {
  let i = calc.rem(n, 5)
  place(top + left, rect(width: 100%, height: 100%,
    fill: gradient.linear(luma(90%), luma(52%), angle: 90deg)))
  if i == 0 {
    // Nadelwald im Nebel. Von Hand aufgeschrieben und nicht gerechnet: eine
    // Formel setzt die Stämme in gleichen Abständen, und was gleichmäßig
    // steht, sieht aus wie ein Balkendiagramm und nicht wie ein Wald.
    // Der kleine Neigungswinkel ist der ganze Unterschied: senkrecht sind es
    // Balken, um ein Grad gekippt sind es Stämme.
    for (x, w, h, tone, tilt) in (
      (5%, 3.4%, 74%, 20%, -1.2deg), (13%, 2.2%, 58%, 34%, 0.8deg),
      (22%, 4.0%, 82%, 17%, 1.4deg), (31%, 1.8%, 47%, 44%, -0.6deg),
      (41%, 3.0%, 66%, 26%, 1.0deg), (52%, 2.4%, 88%, 22%, -1.6deg),
      (60%, 1.6%, 41%, 48%, 0.5deg), (71%, 3.6%, 70%, 19%, -0.9deg),
      (83%, 2.0%, 54%, 38%, 1.7deg), (91%, 2.8%, 78%, 29%, -0.7deg),
    ) {
      place(bottom + left, dx: x, dy: -6%, rotate(tilt, origin: bottom + center,
            reflow: false, rect(width: w, height: h, fill: luma(tone))))
    }
    // Der Nebel darüber, damit die hinteren Stämme darin verschwinden.
    place(bottom + left, rect(width: 100%, height: 46%,
      fill: gradient.linear(luma(70%).transparentize(100%), luma(74%),
                            angle: 90deg)))
  } else if i == 1 {
    // Horizont mit tiefstehender Sonne.
    place(top + right, dx: -22%, dy: 18%, circle(radius: 26pt, fill: luma(96%)))
    place(bottom + left, rect(width: 100%, height: 34%, fill: luma(28%)))
  } else if i == 2 {
    // Porträt gegen das Licht: Schultern, Kopf, und ein heller Saum, damit
    // die Silhouette nicht aussieht wie ein Benutzersymbol.
    // Angeschnitten, nicht zentriert: eine mittige Silhouette aus Kopf und
    // Schultern ist ein Benutzersymbol, eine angeschnittene ist ein Porträt.
    place(bottom + left, dx: 6%, dy: -12%,
          ellipse(width: 34%, height: 34%, fill: luma(80%), stroke: none))
    place(bottom + right, dx: 14%, dy: 12%, rect(
      width: 58%, height: 52%, fill: luma(16%),
      radius: (top-left: 52%, top-right: 22%),
    ))
    place(bottom + right, dx: -4%, dy: -38%,
          ellipse(width: 19%, height: 24%, fill: luma(16%), stroke: none))
  } else if i == 3 {
    // Dünen, drei Kämme hintereinander, jeder heller als der davor.
    for (dy, w, h, tone) in ((-4%, 150%, 46%, 24%), (-14%, 130%, 40%, 38%),
                             (-26%, 170%, 34%, 52%)) {
      place(bottom + center, dy: dy, ellipse(width: w, height: h,
                                             fill: luma(tone), stroke: none))
    }
  } else {
    // Architektur: ein Raster aus Fenstern.
    place(top + left, rect(width: 100%, height: 100%, fill: luma(64%)))
    for a in range(4) {
      for b in range(5) {
        place(top + left, dx: 8% + b * 18%, dy: 12% + a * 22%,
              rect(width: 11%, height: 13%, fill: luma(24%)))
      }
    }
  }
})

// ── Flächen ────────────────────────────────────────────────────────────────
#let plate(body, fill: none, inset: 0pt, align: top + left) = block(
  width: 100%, height: 100%, fill: fill, inset: inset, clip: true,
  std.align(align, body),
)

#let bands(fracs, ..cells) = grid(
  columns: fracs, rows: (100%,), column-gutter: 0pt, ..cells,
)

#let rows-of(fracs, ..cells) = grid(
  columns: (100%,), rows: fracs, row-gutter: 0pt, ..cells,
)

/// Das schwarze Feld, aus dem dieses Deck seine Aussagen macht.
///
/// Die Vorlage hat es auf fast jeder Folie: heller Grund, ein Rechteck in
/// Tinte, Text darin in Papier. Beide Farben kommen aus der Palette, keine
/// steht hier als Wert.
#let panel(t, body, inset: 20pt, width: 100%) = block(
  width: width, fill: t.ink, inset: inset, text(fill: t.paper, body),
)

#let lorem = [Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris.]

/// Die Zahl mit Tausenderpunkten, aus einem Zwischenwert der Szene.
///
/// Die Szene reicht Fließkommazahlen herein, eine je Zwischenbild; auf der
/// Folie darf davon nichts zu sehen sein.
#let grouped(x) = {
  let s = str(int(calc.round(x)))
  let teile = ()
  let k = s.len()
  while k > 3 { teile.push(s.slice(k - 3, k)); k -= 3 }
  teile.push(s.slice(0, k))
  teile.rev().join(",")
}

// ── Titelfolie und Abschnittstafel ─────────────────────────────────────────
// Beide nennen nur Rollen. Deshalb folgt das ganze Deck der Palette, und
// deshalb steht die Behauptung oben — ein Wörterbuch, ein Deck — hier auch
// für die Zier und nicht bloß für den Fließtext.

#let cover(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: t.strong, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-title-slide-ground>]
  }
  // Die Aufnahme unter dem Wort, dunkel genug, dass Papier darauf steht.
  place(top + left, block(width: 100%, height: 100%,
    std.align(center + horizon, block(width: 100%, height: 100%, {
      set block(spacing: 0pt)
      gplate(0)
    }))))
  place(top + left, rect(width: 100%, height: 100%, fill: t.ink.transparentize(58%)))
  place(top + left, dx: 30pt * k, dy: 26pt * k,
        text(size: 74pt * k, weight: "bold", fill: t.paper,
             [#upper(s.title) <ts-title-slide-title>]))
  place(bottom + left, dx: 32pt * k, dy: -30pt * k, block(width: 60%, {
    text(size: 15pt * k, fill: t.paper,
         [#s.subtitle <ts-title-slide-subtitle>])
    v(6pt * k)
    text(size: 11pt * k, fill: t.paper.transparentize(25%),
         [#s.author <ts-title-slide-byline>])
  }))
}

#let plate-section(t, s, geo) = {
  let k = geo.scale
  {
    set rect(fill: t.strong, stroke: none)
    [#rect(width: 100%, height: 100%) <ts-section-slide-ground>]
  }
  place(horizon + left, dx: 40pt * k, block(width: geo.width - 80pt * k, {
    // Die Zierlinie in der Akzentfarbe, auf dem dunklen Grund. Genau die
    // Form, wegen der der Akzent oben nicht die Tinte sein darf.
    {
      set rect(fill: t.accent, stroke: none)
      [#rect(width: 74pt * k, height: 3pt * k) <ts-section-slide-rule>]
    }
    v(12pt * k)
    text(size: 44pt * k, weight: "bold", fill: t.paper,
         [#upper(s.title) <ts-section-slide-title>])
  }))
}

// ── Das Theme ──────────────────────────────────────────────────────────────
// `themes.default`, um zwei Bilder und drei Maße abgewandelt. Keine Farbe
// steht darin: die kommt vollständig aus `palette:` unten. Das ist die
// Arbeitsteilung, die typstage von mosaic teilt — ein Theme sagt, wie gebaut
// wird, eine Palette sagt, in welcher Farbe.
#let t = themes.default + (
  font: ("Inter", "Helvetica Neue", "Arial", "DejaVu Sans"),
  size: 15pt,
  header: "plain",
  footer: "none",
  head-gap: 0pt,
  foot-gap: 0pt,
  box: "label",
  title-slide: cover,
  section: plate-section,
)

// Und derselbe Griff noch einmal, für das, was die Folien selbst brauchen:
// ein aufgelöstes Theme, damit `panel(.., tp)` die Palettenfarben und nicht
// eine zweite, danebenlaufende Kopie benutzt.
#let tp = t + greyscale

#presentation(
  theme: t,
  // Acht Rollen, teilweise überschrieben. Mehr ist an diesem Deck nicht bunt
  // — beziehungsweise: mehr ist an ihm nicht grau.
  palette: greyscale,
  title: [Greyscale],
  subtitle: [A photojournalist's portfolio],
  author: [after SlidesCarnival, via mosaic],
  date: [27 August 2026],
  margin: 0pt,
  // Ein Foliensatz aus Aufnahmen blendet. Alles, was schiebt, wischt oder
  // kippt, machte aus einer Folge von Bildern eine Bedienung.
  transition: "fade",
  transition-duration: 440,
  duration: 500,
  style: it => { set par(justify: false, leading: 0.62em); it },

  // ── 02 Inhalt ────────────────────────────────────────────────────────────
  slide(none)[
    #block(width: 100%, height: 100%, {
      place(top + left, bands((0.16fr, 0.64fr, 0.20fr),
        plate([], fill: white),
        plate(gplate(0)),
        plate([], fill: white),
      ))
      place(top + center, dy: -14pt,
            text(size: 62pt, weight: "bold", fill: tp.ink)[CONTENTS])
      place(bottom + center, dy: 18pt,
            text(size: 62pt, weight: "bold", fill: tp.ink)[CONTENTS])
      place(center + horizon, panel(tp, inset: 22pt, width: 240pt)[
        #stack(dir: ttb, spacing: 15pt,
          text(size: 13pt, weight: "medium")[Introduction],
          text(size: 13pt, weight: "medium")[About us],
          text(size: 13pt, weight: "medium")[Projects],
          text(size: 13pt, weight: "medium")[Exhibitions],
        )
      ])
    })
  ],

  // ── 03 Hallo ─────────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.48fr, 0.52fr),
      plate(fill: white, inset: 28pt, align: center + horizon,
        panel(tp, inset: 25pt, std.align(left)[
          #text(size: 30pt, weight: "bold")[HELLO!]
          #v(10pt)
          #text(size: 10pt)[#lorem]
        ])),
      plate(gplate(2)),
    )
  ],

  // ── 04 Über uns ──────────────────────────────────────────────────────────
  slide(none)[
    #rows-of((1.05fr, 0.95fr),
      block(width: 100%, height: 100%, {
        place(top + left, gplate(4))
        place(left + horizon, dx: 34pt,
              text(size: 34pt, weight: "bold", fill: tp.paper)[ABOUT US])
      }),
      plate(fill: white, inset: 26pt,
        grid(columns: (1fr, 1fr), column-gutter: 30pt,
          text(size: 11.5pt, lorem), text(size: 11.5pt, lorem))),
    )
  ],

  // ── 05 Auftrag und Absicht ───────────────────────────────────────────────
  slide(none)[
    #bands((1.3fr, 0.7fr),
      plate(fill: white, inset: 28pt)[
        #set par(leading: 0.3em)
        #text(size: 38pt, weight: "bold")[MISSION\ & VISION]
        #v(26pt)
        #grid(columns: (1fr, 1fr), column-gutter: 14pt,
          panel(tp, inset: 16pt)[
            #text(size: 14pt, weight: "bold")[Mission]
            #v(8pt)
            #text(size: 10pt)[#lorem]
          ],
          panel(tp, inset: 16pt)[
            #text(size: 14pt, weight: "bold")[Vision]
            #v(8pt)
            #text(size: 10pt)[#lorem]
          ],
        )
      ],
      plate(gplate(0)),
    )
  ],

  // ── 06 Abschnitt ─────────────────────────────────────────────────────────
  section([Our best shots]),

  // ── 07 Der Kontaktbogen ──────────────────────────────────────────────────
  slide(none, note: [Nicht sagen, welches Bild gemeint ist. Auf der nächsten
                     Folie steht es groß da, und der Weg dorthin ist zu
                     sehen.])[
    #plate(fill: white, inset: 26pt)[
      #grid(columns: (1fr, 1fr), rows: (1fr, 1fr), gutter: 10pt,
        gplate(2),
        // Genau eine Kachel trägt einen Namen. Auf der nächsten Folie steht
        // derselbe Name um die ganzflächige Fassung, und dazwischen fliegt
        // das Bild. `match: "block"`: eine Fläche hat keine Glyphen, die man
        // paaren könnte, und eine Paarung je Glyphe machte daraus einen
        // Schwarm statt einer Bewegung.
        morph(<print>, gplate(1), match: "block"),
        gplate(4),
        gplate(3),
      )
    ]
  ],

  // ── 08 Der Abzug ─────────────────────────────────────────────────────────
  slide(none, note: [Hier landet die Kachel. Der Vergrößerer ist die einzige
                     Bewegung des Decks, die etwas behauptet: dieses eine
                     Bild, groß.])[
    #block(width: 100%, height: 100%, {
      place(top + left, morph(<print>, block(width: 100%, height: 100%,
                                             gplate(1)), match: "block"))
      place(bottom + right, dx: -34pt, dy: -20pt,
            panel(tp, inset: (x: 26pt, y: 12pt), width: auto,
                  text(size: 15pt, weight: "bold")[
                    A PICTURE IS WORTH A THOUSAND WORDS
                  ]))
    })
  ],

  // ── 09 Nummerierte Arbeiten ──────────────────────────────────────────────
  slide(none, note: [Ein Tastendruck, vier Karten. Wie ein Kontaktbogen, der
                     sich entwickelt.])[
    #plate(fill: tp.ink, inset: (x: 96pt, y: 62pt), align: center + horizon)[
      #tiles(columns: 2, gutter: 30pt, row-gutter: 26pt,
             stride: 0, stagger: 110, enter: "fade-up",
        ..(("01", "02", "03", "04")).map(nr => grid(
          columns: (58pt, 1fr), column-gutter: 15pt, align: top,
          rect(fill: tp.paper, inset: 8pt,
               text(size: 28pt, weight: "bold", fill: tp.ink, nr)),
          text(size: 10.5pt, fill: tp.paper)[
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
            eiusmod tempor incididunt.
          ],
        )),
      )
    ]
  ],

  // ── 10 Die große Zahl ────────────────────────────────────────────────────
  slide(none, note: [Erst steht da eine Null. Dann fragen, wie viele es wohl
                     sind — und dann erst drücken.])[
    #block(width: 100%, height: 100%, {
      place(top + left, gplate(3))
      place(top + center, dy: 120pt, block(width: 100%, std.align(center, {
        // `scene` statt `anim`: die Zahl soll nicht erscheinen, sie soll
        // laufen. Zwei Halte, dazwischen achtzehn Zwischenbilder, und jedes
        // wird von Typst gesetzt — die Ziffern bleiben deshalb scharf und in
        // derselben Schrift wie alles andere. Der Preis steht im Handbuch:
        // ein Bild je Zwischenschritt, und nichts davon wird gemessen.
        scene(
          n => std.align(center, text(size: 74pt, weight: "bold",
                                      fill: tp.ink, grouped(n))),
          stops: (0, 123456),
          tween: 18,
          width: 100%,
          height: 96pt,
        )
        v(4pt)
        panel(tp, inset: (x: 12pt, y: 6pt), width: auto,
              text(size: 11pt, weight: "bold")[
                Big numbers catch your audience's attention
              ])
      })))
    })
  ],

  // ── 11 Das Diagramm ──────────────────────────────────────────────────────
  slide(none)[
    #bands((0.85fr, 1.15fr),
      plate(fill: tp.ink, inset: 27pt)[
        #text(size: 30pt, weight: "bold", fill: tp.paper)[CHART]
        #v(10pt)
        #text(size: 10.5pt, fill: tp.paper)[#lorem]
      ],
      plate(fill: white, inset: 20pt)[
        // Ein Balkenfeld in fünf Grautönen: dieselbe Rolle, die in der
        // Vorlage ein eingebettetes Bild spielt, nur dass es hier gesetzt
        // wird und daher jede Palette mitmacht.
        #block(width: 100%, height: 100%, {
          let werte = (34%, 58%, 46%, 79%, 63%, 92%)
          place(bottom + left, line(length: 100%, stroke: 0.8pt + tp.border))
          for (j, h) in werte.enumerate() {
            place(bottom + left, dx: 4% + j * 16%, dy: -2pt,
                  rect(width: 11%, height: h,
                       fill: luma(78% - 9 * j * 1%)))
          }
        })
      ],
    )
  ],

  // ── 12 Ausstellungen ─────────────────────────────────────────────────────
  slide(none)[
    #rows-of((0.28fr, 1fr),
      plate(fill: tp.ink, inset: (x: 34pt, y: 18pt), align: center + horizon,
            text(size: 30pt, weight: "bold", fill: tp.paper)[EXHIBITIONS]),
      plate(fill: tp.ink, inset: (bottom: 0pt),
        grid(columns: (1fr, 1fr, 1fr), column-gutter: 7pt, rows: (100%,),
          ..(([Project 1], 2), ([Project 2], 4), ([Project 3], 3)).map(p =>
            block(width: 100%, height: 100%, fill: white, {
              block(width: 100%, height: 68%, gplate(p.last()))
              pad(x: 11pt, top: 8pt)[
                #text(size: 12pt, weight: "bold", p.first())
                #linebreak()
                #text(size: 8.5pt)[Lorem ipsum dolor sit amet, consectetur
                                   adipiscing elit.]
              ]
            })),
        ))
    )
  ],

  // ── 13 Schluss ───────────────────────────────────────────────────────────
  slide(none)[
    #bands((0.42fr, 0.58fr),
      plate(fill: tp.ink, inset: 32pt, align: left + horizon)[
        #set par(leading: 0.34em)
        #text(size: 58pt, weight: "bold", fill: tp.paper)[THANK\ YOU]
      ],
      plate(fill: tp.ink, inset: (top: 150pt), gplate(2)),
    )
  ],
)
