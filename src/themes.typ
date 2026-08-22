// Das Aussehen einer Präsentation — fünf Themes und der Bauplan dahinter.
//
// Ein Theme ist ein *Wörterbuch*. Fast alles darin ist ein Wert: eine Farbe,
// eine Schrift, ein Maß — oder ein kurzes Wort für eine der wenigen Bauformen
// (`header`, `footer`, `progress`). Nur zwei Einträge sind Funktionen: die
// Titel- und die Abschnittsfolie. Die beiden sind ganze Bilder und keine
// Abwandlung voneinander; sie ließen sich nur mit einem Dutzend weiterer
// Schalter beschreiben, und dann wären sie noch immer alle gleich gebaut.
//
//   #show: presentation.with(theme: themes.night)
//   #show: presentation.with(theme: themes.lesson + (accent: blue))
//
// Die zweite Zeile ist der ganze Trick beim Abwandeln: ein Theme ist ein
// Wörterbuch, und `+` schreibt einzelne Einträge um.

#import "config.typ": margins

/// Schriftargumente, die ein `none` einfach weglassen.
///
/// `text(font: none)` gibt es nicht — wer keine Schrift vorschreiben will,
/// darf das Argument gar nicht erst setzen.
#let font-args(f) = if f == none { (:) } else { (font: f) }

/// Stücke untereinander, mit genau dem angegebenen Abstand.
///
/// Die Argumente wechseln sich ab: Inhalt, Abstand, Inhalt, Abstand, Inhalt.
/// Nötig, weil Typst zwischen zwei Absätzen `par.spacing` und zwischen zwei
/// Blöcken `block.spacing` einschiebt — beides addiert sich zu einem
/// ausdrücklichen `v()`. Auf einer Titelfolie mit 24pt Grundschrift waren das
/// gemessen 29pt zusätzlich, die den Aufbau auseinanderzogen. Hier zählt nur,
/// was dasteht.
#let stapel(..teile) = {
  let xs = teile.pos()
  for (i, x) in xs.enumerate() {
    if calc.rem(i, 2) == 0 {
      block(above: if i == 0 { 0pt } else { xs.at(i - 1) }, below: 0pt, x)
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Titel- und Abschnittsfolien
// ═══════════════════════════════════════════════════════════════════════════
//
// Jede dieser Funktionen bekommt `(t, s, geo)`: das Theme, die Folie (mit
// `title`, `subtitle`, `author`, `date`) und den Canvas. `geo.scale` ist der
// Faktor, mit dem alle Maße mitwachsen — jede Zahl unten ist in Punkten des
// Vorgabe-Canvas gemeint und wird damit multipliziert.

/// Das Datum, wie es unter einem Titel steht.
///
/// `date` darf beides sein. Ein `datetime` wird in der hiesigen Schreibweise
/// gesetzt; wer eine andere will, gibt gleich Inhalt an: `date: [15 September
/// 2026]`. Vorher riefen drei Titelfolien `display` ohne zu fragen. Ein
/// englisches Deck bekam damit zwangsläufig „15.09.2026" unter den Titel, und
/// Inhalt mitzugeben brach den Bau ab, weil Inhalt kein `display` kennt. Der
/// erste Anlauf hat nur diese eine Zeile hier geheilt und die beiden anderen
/// Stellen übersehen; deshalb steht die Umrechnung jetzt an einem Ort.
#let datum(d) = if type(d) == datetime {
  d.display("[day].[month].[year]")
} else { d }

/// Die Zeile mit Autor und Datum, wie sie unter jeder Titelfolie steht.
#let by-line(t, s, k) = text(size: 12pt * k, fill: t.muted, {
  s.author
  if s.date != none [ · #datum(s.date) ]
})

// ── default ────────────────────────────────────────────────────────────────

/// Titel links auf halber Höhe, darunter ein kurzer Akzentstrich.
#let band-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(top + left, dx: m.left, dy: geo.height * 0.32, {
    stapel(
      text(..font-args(t.title-font), size: 34pt * k, weight: "bold",
           fill: t.strong, s.title),
      6pt * k,
      rect(width: 190pt * k, height: 2.5pt * k, fill: t.accent, stroke: none),
      8pt * k,
      text(size: 17pt * k, fill: t.muted, s.subtitle),
    )
  })
  place(bottom + left, dx: m.left, dy: -m.bottom, by-line(t, s, k))
}

/// Dunkle Vollfläche, Akzentstrich über dem Titel.
#let band-section(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.strong, stroke: none)
  place(horizon + left, dx: m.left, {
    stapel(
      rect(width: 62pt * k, height: 2.5pt * k, fill: t.accent, stroke: none),
      10pt * k,
      text(..font-args(t.title-font), size: 30pt * k, weight: "bold",
           fill: white, s.title),
    )
  })
}

// ── lesson ─────────────────────────────────────────────────────────────────

/// Mittig und groß, mit einem Akzentband über der ganzen Breite.
#let lesson-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(top + left, rect(width: 100%, height: 12pt * k, fill: t.accent, stroke: none))
  place(center + horizon, dy: -10pt * k, block(width: geo.width - 2 * m.left, {
    set align(center)
    stapel(
      text(..font-args(t.title-font), size: 38pt * k, weight: "bold",
           fill: t.strong, s.title),
      14pt * k,
      rect(width: 130pt * k, height: 3pt * k, fill: t.accent, stroke: none),
      14pt * k,
      text(size: 18pt * k, fill: t.muted, s.subtitle),
    )
  }))
  place(bottom + center, dy: -m.bottom, by-line(t, s, k))
}

/// Getönter Grund, breiter Akzentbalken an der linken Kante.
#let lesson-section(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  let balken = 16pt * k
  rect(width: 100%, height: 100%, fill: t.accent.lighten(88%), stroke: none)
  place(top + left, rect(width: balken, height: 100%, fill: t.accent, stroke: none))
  place(horizon + left, dx: m.left + balken,
    block(width: geo.width - 2 * m.left - balken,
      text(..font-args(t.title-font), size: 32pt * k, weight: "bold", fill: t.strong, s.title)))
}

// ── night ──────────────────────────────────────────────────────────────────

/// Alles in der Mitte, nichts am Rand — im dunklen Raum sieht man ohnehin nur
/// die hellen Stellen.
#let night-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(center + horizon, block(width: geo.width * 0.74, {
    set align(center)
    stapel(
      text(..font-args(t.title-font), size: 40pt * k, weight: "bold",
           fill: t.ink, s.title),
      16pt * k,
      rect(width: 90pt * k, height: 2pt * k, fill: t.accent, stroke: none),
      16pt * k,
      text(size: 17pt * k, fill: t.muted, s.subtitle),
    )
  }))
  place(bottom + center, dy: -m.bottom, by-line(t, s, k))
}

/// Zwei Akzentlinien, dazwischen der Titel in Akzentfarbe.
#let night-section(t, s, geo) = {
  let k = geo.scale
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(center + horizon, block(width: geo.width * 0.56, {
    set align(center)
    stapel(
      rect(width: 100%, height: 1pt * k, fill: t.accent, stroke: none),
      18pt * k,
      text(..font-args(t.title-font), size: 30pt * k, weight: "bold",
           fill: t.accent, s.title),
      18pt * k,
      rect(width: 100%, height: 1pt * k, fill: t.accent, stroke: none),
    )
  }))
}

// ── plain ──────────────────────────────────────────────────────────────────

/// Nur Text, links, weit unten. Kein Strich, keine Fläche, keine Farbe.
#let plain-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(top + left, dx: m.left, dy: geo.height * 0.42, block(width: geo.width * 0.7, {
    stapel(
      text(..font-args(t.title-font), size: 30pt * k, fill: t.strong,
           tracking: 0.3pt * k, s.title),
      12pt * k,
      text(size: 15pt * k, fill: t.muted, s.subtitle),
    )
  }))
  place(bottom + left, dx: m.left, dy: -m.bottom,
    text(size: 10pt * k, fill: t.muted, {
      s.author
      if s.date != none [ · #datum(s.date) ]
    }))
}

/// Der Titel steht, wo sonst der Folientitel stünde — nur auf halber Höhe.
#let plain-section(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(horizon + left, dx: m.left, block(width: geo.width * 0.7, {
    stapel(
      text(..font-args(t.title-font), size: 26pt * k, fill: t.strong,
           tracking: 0.3pt * k, s.title),
      11pt * k,
      rect(width: 40pt * k, height: 0.8pt * k, fill: t.muted, stroke: none),
    )
  }))
}

// ── editorial ──────────────────────────────────────────────────────────────

/// Ein Titelblatt: zwei Haarlinien, dazwischen der Titel, darunter der
/// Untertitel kursiv.
#let editorial-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(center + horizon, dy: -8pt * k, block(width: geo.width * 0.68, {
    set align(center)
    stapel(
      rect(width: 64pt * k, height: 0.9pt * k, fill: t.accent, stroke: none),
      18pt * k,
      text(..font-args(t.title-font), size: 34pt * k, fill: t.strong,
           tracking: 0.5pt * k, s.title),
      12pt * k,
      text(size: 16pt * k, style: "italic", fill: t.muted, s.subtitle),
      20pt * k,
      rect(width: 64pt * k, height: 0.9pt * k, fill: t.accent, stroke: none),
    )
  }))
  place(bottom + center, dy: -m.bottom,
    text(size: 11pt * k, fill: t.muted, tracking: 1.4pt * k, upper({
      s.author
      if s.date != none [ · #datum(s.date) ]
    })))
}

/// Vollfläche in der tragenden Farbe, Titel in Papierfarbe darauf.
#let editorial-section(t, s, geo) = {
  let k = geo.scale
  rect(width: 100%, height: 100%, fill: t.strong, stroke: none)
  place(center + horizon, block(width: geo.width * 0.7, {
    set align(center)
    stapel(
      rect(width: 44pt * k, height: 0.9pt * k, fill: t.accent, stroke: none),
      20pt * k,
      text(..font-args(t.title-font), size: 30pt * k, fill: t.paper,
           tracking: 0.5pt * k, s.title),
    )
  }))
}


// ═══════════════════════════════════════════════════════════════════════════
//  Der Bauplan
// ═══════════════════════════════════════════════════════════════════════════

/// Baut ein Theme. Ohne Argument ergibt es das voreingestellte
/// Aussehen — `themes.default` ist genau das.
///
/// Die Einträge in Gruppen: Farben (`paper ink strong accent muted
/// surface border inverted`), Typografie (`font title-font size
/// title-size weight tracking`), die gewöhnliche Folie (`header
/// title-fill rule-size rule-fill head-gap foot-gap band-height box
/// footer footer-rule progress`) und die beiden ganzen Bilder
/// (`title-slide`, `section`).
///
/// Schriftgrößen: gemessen an Beamer und Metropolis, wo der Fließtext
/// rund 3,0 % der Folienbreite einnimmt und der Titel 3,9 %. Die
/// früheren 19pt/23pt lagen bei 2,3 % und 2,7 % — spürbar kleiner,
/// als man es aus der letzten Reihe lesen möchte.
///
/// Kommentare dürfen NICHT in die Parameterliste: tidy zerlegt sie an
/// den Kommas und erwartet in jedem Stück einen Doppelpunkt — die
/// API-Referenz bricht daran ab.
#let theme(
  paper: rgb("#fafafa"),
  ink: black,
  strong: rgb("#23303f"),
  accent: rgb("#eb5e28"),
  muted: luma(45%),
  surface: white,
  border: luma(84%),
  inverted: false,
  font: none,
  title-font: none,
  size: 24pt,
  title-size: 31pt,
  weight: "bold",
  tracking: 0pt,
  header: "band",
  title-fill: white,
  rule-size: 0pt,
  rule-fill: none,
  head-gap: 20pt,
  foot-gap: 24pt,
  band-height: 66pt,
  footer: "fraction",
  footer-rule: 0pt,
  progress: "bar",
  box: "bar",
  title-slide: band-title-slide,
  section: band-section,
) = {
  // Ein Tippfehler in einer dieser drei täte sonst schlicht nichts — die
  // Fußzeile bliebe weg, und niemand wüsste, warum.
  assert(header in ("band", "plain"),
         message: "typstage: theme(header: ..) is \"band\" or \"plain\"")
  assert(footer in ("fraction", "number", "center", "none"),
         message: "typstage: theme(footer: ..) is \"fraction\", \"number\", "
           + "\"center\" or \"none\"")
  assert(progress in ("bar", "top", "tick", "none"),
         message: "typstage: theme(progress: ..) is \"bar\", \"top\", \"tick\" "
           + "or \"none\"")
  assert(box in ("bar", "label"),
         message: "typstage: theme(box: ..) is \"bar\" or \"label\"")
  (
  paper: paper, ink: ink, strong: strong, accent: accent, muted: muted,
  surface: surface, border: border, inverted: inverted,
  font: font, title-font: if title-font == none { font } else { title-font },
  size: size, title-size: title-size, weight: weight, tracking: tracking,
  header: header, title-fill: title-fill,
  rule-size: rule-size, rule-fill: if rule-fill == none { accent } else { rule-fill },
  head-gap: head-gap, foot-gap: foot-gap, band-height: band-height,
  footer: footer, footer-rule: footer-rule, progress: progress, box: box,
  title-slide: title-slide, section: section,
  )
}


// ═══════════════════════════════════════════════════════════════════════════
//  Die fünf
// ═══════════════════════════════════════════════════════════════════════════

/// Die mitgelieferten Themes — `themes.default`, `themes.lesson`,
/// `themes.night`, `themes.plain`, `themes.editorial`.
///
/// Sie sind für verschiedene Anlässe gemacht und nicht dieselbe Folie in fünf
/// Farben: der Titel steht mal in einem Balken, mal frei, mal unter einer
/// Linie; der Fortschritt wächst, wandert oder fehlt ganz.
#let themes = (
  // Der Vortrag im hellen Saal. Das Aussehen, das typstage von jeher hat, und
  // die Vorgabe: dunkler Titelbalken, orangefarbener Fortschritt.
  default: theme(),

  // Der Unterricht. Größere Schrift, kein Balken — der Titel steht auf dem
  // Papier und wird von einem kräftigen Strich unterlegt; unten wandert eine
  // Marke auf ihrer Schiene, damit die Klasse sieht, wie weit die Stunde ist.
  // Nach dem Vorbild deutscher Mathe-Schulbücher. Die Farben sind nicht
  // gewählt, sondern aus einer Musterseite von „Fundamente der Mathematik"
  // (Cornelsen, 10. Schuljahr) ausgemessen: das Zinnoberrot der Überschriften
  // und der Merkkästen, das Cyanblau der Beispiele und der Kopflinie, dazu die
  // beiden Tönungen. Was dort trägt, ist nicht Größe und nicht Fettung,
  // sondern *Farbe als Bedeutung*: warm für „das musst du wissen", kühl für
  // „so sieht es aus". Deshalb ist die Überschrift hier kleiner als zuvor und
  // die Linie darunter eine Haarlinie statt eines Balkens.
  lesson: theme(
    paper: white,
    ink: rgb("#16181c"),
    strong: rgb("#d8391a"),
    accent: rgb("#1292db"),
    muted: rgb("#6b7280"),
    // Die Fläche des Merkkastens, gemessen #fdf0df.
    surface: rgb("#fdf0df"),
    border: rgb("#f2ddc6"),
    font: ("Source Sans 3", "Source Sans Pro", "Open Sans", "DejaVu Sans"),
    size: 20pt,
    title-size: 24pt,
    header: "plain",
    title-fill: rgb("#d8391a"),
    // Eine Haarlinie in Cyan, wie die Kopflinie im Buch. Vorher lagen hier
    // 3pt in Orange, also ein zweites lautes Signal neben einem Titel, der
    // ohnehin schon fett, dunkel und groß war.
    rule-size: 0.9pt,
    head-gap: 24pt,
    footer: "fraction",
    progress: "tick",
    box: "label",
    title-slide: lesson-title-slide,
    section: lesson-section,
  ),

  // Der abgedunkelte Raum. Tiefer Grund, heller Satz, kühler Akzent; der
  // Fortschritt liegt als dünne Linie an der Oberkante, wo er nicht blendet.
  night: theme(
    paper: rgb("#0f1319"),
    ink: rgb("#e6ebf2"),
    strong: rgb("#2c3644"),
    accent: rgb("#5ec8f2"),
    muted: rgb("#8f9bab"),
    surface: rgb("#1a212b"),
    border: rgb("#2e3947"),
    inverted: true,
    font: ("Inter", "Helvetica Neue", "DejaVu Sans"),
    size: 19pt,
    title-size: 24pt,
    header: "plain",
    title-fill: rgb("#5ec8f2"),
    head-gap: 16pt,
    footer: "number",
    progress: "top",
    title-slide: night-title-slide,
    section: night-section,
  ),

  // So wenig wie möglich. Weiß, schwarz, ein Grau — keine Farbe, keine
  // Fläche, kein Fortschritt. Der Titel ist klein und lässt dem Rumpf viel
  // Luft; was zu sehen ist, ist der Inhalt.
  plain: theme(
    paper: white,
    ink: black,
    strong: luma(12%),
    accent: luma(12%),
    muted: luma(55%),
    surface: white,
    border: luma(86%),
    font: ("Helvetica Neue", "Arial", "DejaVu Sans"),
    size: 18pt,
    title-size: 17pt,
    weight: "medium",
    tracking: 0.8pt,
    header: "plain",
    title-fill: luma(30%),
    head-gap: 34pt,
    foot-gap: 20pt,
    footer: "number",
    progress: "none",
    title-slide: plain-title-slide,
    section: plain-section,
  ),

  // Mit Charakter: Werkdruckpapier, Antiqua, Haarlinien. Der Titel steht über
  // einer feinen Linie, die Seitenzahl mittig unter einer zweiten — ein Buch,
  // keine Folie.
  editorial: theme(
    paper: rgb("#f7f2e6"),
    ink: rgb("#2a2622"),
    strong: rgb("#7b2d26"),
    accent: rgb("#b4894a"),
    muted: rgb("#8a7f70"),
    surface: rgb("#fffdf7"),
    border: rgb("#ded2ba"),
    font: ("Iowan Old Style", "Charter", "Libertinus Serif"),
    title-font: ("Optima", "Palatino", "Libertinus Serif"),
    // 20pt, nicht 18pt. Nominell war editorial mit plain das kleinste Theme,
    // in Wirklichkeit das kleinste überhaupt: Iowan setzt seine x-Höhe auf 0,48
    // der Schriftgröße, Inter auf 0,55. Gemessen an einem gerenderten „x" waren
    // das 8,64pt gegen 10,44pt in night und 11,64pt in default, also ein
    // Viertel kleiner als das größte Theme, obwohl die Zahl daneben nur um
    // sechs Punkte abwich. Bei 20pt sind es 9,60pt und damit dasselbe wie in
    // lesson (9,72pt). Der Titel wächst mit, sonst fiele sein Abstand zum
    // Rumpf von 1,33 auf 1,2.
    size: 20pt,
    title-size: 26pt,
    weight: "regular",
    tracking: 0.5pt,
    header: "plain",
    title-fill: rgb("#7b2d26"),
    rule-size: 0.9pt,
    rule-fill: rgb("#ded2ba"),
    head-gap: 22pt,
    foot-gap: 30pt,
    footer: "center",
    footer-rule: 0.7pt,
    progress: "none",
    title-slide: editorial-title-slide,
    section: editorial-section,
  ),
)


/// Das Theme, unter dem gerade gesetzt wird.
///
/// `card` und `callout` stehen *im* Folienrumpf und wissen von sich aus nichts
/// von der Präsentation. Ohne diesen Zustand müsste jede Karte ihre Farben
/// mitbekommen; so holt sie sie sich. `presentation` schreibt ihn einmal, ganz
/// am Anfang — und wer eine Karte außerhalb einer Präsentation benutzt, bekommt
/// die Vorgabe.
#let theme-state = state("typstage-theme", themes.default)
