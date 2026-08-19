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

// ═══════════════════════════════════════════════════════════════════════════
//  Titel- und Abschnittsfolien
// ═══════════════════════════════════════════════════════════════════════════
//
// Jede dieser Funktionen bekommt `(t, s, geo)`: das Theme, die Folie (mit
// `title`, `subtitle`, `author`, `date`) und den Canvas. `geo.scale` ist der
// Faktor, mit dem alle Maße mitwachsen — jede Zahl unten ist in Punkten des
// Vorgabe-Canvas gemeint und wird damit multipliziert.

/// Die Zeile mit Autor und Datum, wie sie unter jeder Titelfolie steht.
#let by-line(t, s, k) = text(size: 12pt * k, fill: t.muted, {
  s.author
  if s.date != none [ · #s.date.display("[day].[month].[year]") ]
})

// ── default ────────────────────────────────────────────────────────────────

/// Titel links auf halber Höhe, darunter ein kurzer Akzentstrich.
#let band-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(top + left, dx: m.left, dy: geo.height * 0.32, {
    text(..font-args(t.title-font), size: 34pt * k, weight: "bold", fill: t.strong, s.title)
    v(4pt * k)
    rect(width: 190pt * k, height: 2.5pt * k, fill: t.accent, stroke: none)
    v(6pt * k)
    text(size: 17pt * k, fill: t.muted, s.subtitle)
  })
  place(bottom + left, dx: m.left, dy: -m.bottom, by-line(t, s, k))
}

/// Dunkle Vollfläche, Akzentstrich über dem Titel.
#let band-section(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.strong, stroke: none)
  place(horizon + left, dx: m.left, {
    rect(width: 62pt * k, height: 2.5pt * k, fill: t.accent, stroke: none)
    v(8pt * k)
    text(..font-args(t.title-font), size: 30pt * k, weight: "bold", fill: white, s.title)
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
    text(..font-args(t.title-font), size: 38pt * k, weight: "bold", fill: t.strong, s.title)
    v(12pt * k)
    rect(width: 130pt * k, height: 3pt * k, fill: t.accent, stroke: none)
    v(12pt * k)
    text(size: 18pt * k, fill: t.muted, s.subtitle)
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
    text(..font-args(t.title-font), size: 40pt * k, weight: "bold", fill: t.ink, s.title)
    v(14pt * k)
    rect(width: 90pt * k, height: 2pt * k, fill: t.accent, stroke: none)
    v(14pt * k)
    text(size: 17pt * k, fill: t.muted, s.subtitle)
  }))
  place(bottom + center, dy: -m.bottom, by-line(t, s, k))
}

/// Zwei Akzentlinien, dazwischen der Titel in Akzentfarbe.
#let night-section(t, s, geo) = {
  let k = geo.scale
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(center + horizon, block(width: geo.width * 0.56, {
    set align(center)
    rect(width: 100%, height: 1pt * k, fill: t.accent, stroke: none)
    v(16pt * k)
    text(..font-args(t.title-font), size: 30pt * k, weight: "bold", fill: t.accent, s.title)
    v(16pt * k)
    rect(width: 100%, height: 1pt * k, fill: t.accent, stroke: none)
  }))
}

// ── plain ──────────────────────────────────────────────────────────────────

/// Nur Text, links, weit unten. Kein Strich, keine Fläche, keine Farbe.
#let plain-title-slide(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(top + left, dx: m.left, dy: geo.height * 0.42, block(width: geo.width * 0.7, {
    text(..font-args(t.title-font), size: 30pt * k, fill: t.strong, tracking: 0.3pt * k, s.title)
    v(10pt * k)
    text(size: 15pt * k, fill: t.muted, s.subtitle)
  }))
  place(bottom + left, dx: m.left, dy: -m.bottom,
    text(size: 10pt * k, fill: t.muted, {
      s.author
      if s.date != none [ · #s.date.display("[day].[month].[year]") ]
    }))
}

/// Der Titel steht, wo sonst der Folientitel stünde — nur auf halber Höhe.
#let plain-section(t, s, geo) = {
  let k = geo.scale
  let m = margins(geo)
  rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
  place(horizon + left, dx: m.left, block(width: geo.width * 0.7, {
    text(..font-args(t.title-font), size: 26pt * k, fill: t.strong, tracking: 0.3pt * k, s.title)
    v(9pt * k)
    rect(width: 40pt * k, height: 0.8pt * k, fill: t.muted, stroke: none)
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
    rect(width: 64pt * k, height: 0.9pt * k, fill: t.accent, stroke: none)
    v(16pt * k)
    text(..font-args(t.title-font), size: 34pt * k, fill: t.strong, tracking: 0.5pt * k, s.title)
    v(10pt * k)
    text(size: 16pt * k, style: "italic", fill: t.muted, s.subtitle)
    v(18pt * k)
    rect(width: 64pt * k, height: 0.9pt * k, fill: t.accent, stroke: none)
  }))
  place(bottom + center, dy: -m.bottom,
    text(size: 11pt * k, fill: t.muted, tracking: 1.4pt * k, upper({
      s.author
      if s.date != none [ · #s.date.display("[day].[month].[year]") ]
    })))
}

/// Vollfläche in der tragenden Farbe, Titel in Papierfarbe darauf.
#let editorial-section(t, s, geo) = {
  let k = geo.scale
  rect(width: 100%, height: 100%, fill: t.strong, stroke: none)
  place(center + horizon, block(width: geo.width * 0.7, {
    set align(center)
    rect(width: 44pt * k, height: 0.9pt * k, fill: t.accent, stroke: none)
    v(18pt * k)
    text(..font-args(t.title-font), size: 30pt * k, fill: t.paper, tracking: 0.5pt * k, s.title)
  }))
}


// ═══════════════════════════════════════════════════════════════════════════
//  Der Bauplan
// ═══════════════════════════════════════════════════════════════════════════

/// Ein Theme bauen.
///
/// Ohne ein einziges Argument kommt genau das Aussehen heraus, das `typstage`
/// von jeher hat — `themes.default` ist nichts anderes als `theme()`. Wer nur
/// eine Kleinigkeit ändern will, nimmt lieber ein fertiges Theme und schreibt
/// den Eintrag um: `themes.night + (accent: blue)`. Das ändert genau diesen
/// einen Eintrag: was beim Bauen daraus abgeleitet wurde — `rule-fill` etwa
/// nimmt ein `none` als „wie `accent`" — steht danach noch so da, wie es
/// gebaut wurde.
///
/// - Farben —
///   `paper` Grund der Folie, `ink` der Fließtext, `strong` die tragende
///   dunkle Farbe (Titelbalken, Kartenkopf, Abschnittsfläche), `accent` die
///   Signalfarbe (Striche, Fortschritt, Merkkasten), `muted` das
///   Nebensächliche (Fußzeile, Untertitel), `surface` der Grund einer Karte,
///   `border` ihr Rahmen. `inverted` sagt, ob hell auf dunkel gesetzt wird —
///   `callout` tönt seinen Grund danach.
/// - Typografie —
///   `font` und `title-font` (`none` heißt: Typsts Vorgabe), `size` der
///   Fließtext und `title-size` der Folientitel, beides in Punkten des
///   Vorgabe-Canvas, dazu `weight` und `tracking` für die Titel.
/// - Die gewöhnliche Folie —
///   `header` ist `"band"` (farbiger Balken über die ganze Breite) oder
///   `"plain"` (der Titel steht einfach da). `rule-size` legt eine Linie unter
///   den Titel, `0pt` lässt sie weg. `head-gap` und `foot-gap` sind die Luft
///   über und unter dem Rumpf, `band-height` die Höhe des Balkens.
///   `footer` ist `"fraction"` (3 / 12), `"number"` (3), `"center"` (mittig)
///   oder `"none"`; `footer-rule` legt eine Haarlinie darüber.
///   `progress` ist `"bar"` (wachsender Balken unten), `"top"` (dasselbe oben),
///   `"tick"` (eine wandernde Marke auf einer Schiene) oder `"none"`.
/// - Ganze Bilder —
///   `title-slide` und `section` sind Funktionen `(t, s, geo) => content`.
#let theme(
  // Farben
  paper: rgb("#fafafa"),
  ink: black,
  strong: rgb("#23303f"),
  accent: rgb("#eb5e28"),
  muted: luma(45%),
  surface: white,
  border: luma(84%),
  inverted: false,
  // Typografie
  font: none,
  title-font: none,
  size: 19pt,
  title-size: 23pt,
  weight: "bold",
  tracking: 0pt,
  // Die gewöhnliche Folie
  header: "band",
  title-fill: white,
  rule-size: 0pt,
  rule-fill: none,
  head-gap: 20pt,
  foot-gap: 24pt,
  band-height: 54pt,
  footer: "fraction",
  footer-rule: 0pt,
  progress: "bar",
  // Ganze Bilder
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
  (
  paper: paper, ink: ink, strong: strong, accent: accent, muted: muted,
  surface: surface, border: border, inverted: inverted,
  font: font, title-font: if title-font == none { font } else { title-font },
  size: size, title-size: title-size, weight: weight, tracking: tracking,
  header: header, title-fill: title-fill,
  rule-size: rule-size, rule-fill: if rule-fill == none { accent } else { rule-fill },
  head-gap: head-gap, foot-gap: foot-gap, band-height: band-height,
  footer: footer, footer-rule: footer-rule, progress: progress,
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
  lesson: theme(
    paper: rgb("#fbfaf6"),
    ink: rgb("#1c2126"),
    strong: rgb("#2b4c7e"),
    accent: rgb("#e0762a"),
    muted: rgb("#6b7280"),
    surface: white,
    border: rgb("#e2ddd2"),
    font: ("Source Sans 3", "Source Sans Pro", "Open Sans", "DejaVu Sans"),
    size: 20pt,
    title-size: 26pt,
    header: "plain",
    title-fill: rgb("#2b4c7e"),
    rule-size: 3pt,
    head-gap: 24pt,
    footer: "fraction",
    progress: "tick",
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
    size: 18pt,
    title-size: 24pt,
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
