// Layouts für den Folienrumpf.
//
// Bewusst Inhaltsfunktionen, keine neuen Folienarten: der Aufteiler in
// `present.typ` erzeugt aus Überschriften `slide` und `section`, sonst nichts.
// Ein Layout ist damit etwas, das *in* einer Folie steht — es lässt sich
// schachteln, in eine Rasterzelle setzen und mit `anim` einblenden.
//
// Die Farbgebung kommt aus dem Theme, und zwar nur als *Vorgabe*: `color`,
// `fill` und `stroke` stehen auf `auto` und holen sich dort ihren Wert. Wer
// sechs Bedeutungsfarben führt, gibt sie wie bisher an der Stelle mit; das
// Paket schreibt keine vor.
//
// Deshalb steckt der Kasten in einem `context`: er steht im Folienrumpf und
// erfährt erst dort, unter welchem Theme er gesetzt wird.

#import "elements.typ": anim
#import "internal.typ": step-cursor
#import "themes.typ": theme-state

/// Ein benannter Kasten — Beamers `block`.
///
/// `title` steht in einem farbigen Streifen darüber, `number` setzt zusätzlich
/// eine Ziffernscheibe davor. Ohne beides bleibt ein schlichter Kasten.
///
/// `color`, `fill` und `stroke` nehmen auf `auto` die Werte des Themes —
/// dessen tragende Farbe, seinen Kartengrund und seinen Rahmen.
///
/// Kein `clip: true`: Typst leitet die Kennung eines Beschnittpfads aus dem
/// Inhalt ab, und derselbe Kasten zweimal auf einer Folie ergäbe dieselbe
/// Kennung. Die Ecken rundet deshalb der Streifen selbst.
#let card(
  body,
  title: none,
  number: none,
  color: auto,
  fill: auto,
  stroke: auto,
  radius: auto,
  inset: (x: 12pt, y: 10pt),
  width: 100%,
) = context {
  let t = theme-state.get()
  // Zwei Bauarten. `"bar"` ist die bisherige: weiße Fläche, dünner Rahmen,
  // farbiger Streifen mit versalem Etikett darüber. `"label"` kommt aus dem
  // Schulbuch: keine Kante, keine Rundung, eine getönte Fläche, und die
  // Beschriftung steht in der Farbe *im* Kasten statt auf einem Balken.
  let stil = t.at("box", default: "bar")
  let eigene-farbe = color != auto
  let color = if color == auto { t.strong } else { color }
  // Beim Etikettenstil trägt die Tönung dieselbe Bedeutung wie die Schrift
  // darauf: ein blau beschrifteter Kasten steht auf Blau, ein roter auf Rot.
  // Nur wer keine Farbe angibt, bekommt `surface` — im Schulbuch-Theme ist das
  // die ausgemessene Tönung des Merkkastens, und die ist wärmer als eine bloß
  // aufgehellte Überschriftenfarbe.
  let fill = if fill != auto { fill }
              else if stil == "label" and eigene-farbe {
                if t.inverted { color.darken(72%) } else { color.lighten(89%) }
              } else { t.surface }
  let radius = if radius != auto { radius } else if stil == "label" { 0pt } else { 7pt }
  let stroke = if stroke != auto { stroke }
                else if stil == "label" { none } else { 0.7pt + t.border }
  block(
    width: width, radius: radius, fill: fill, stroke: stroke,
  {
    // Zwischen Streifen und Rumpf setzt Typst sonst seinen Blockabstand —
    // gemessen 20pt bei 17pt Schrift, wodurch der Text 30pt unter dem Kopf
    // hing, aber nur 9pt über dem unteren Rand. Beide Blöcke geben ihn ab,
    // der Abstand kommt allein aus `inset`.
    set block(spacing: 0pt)
    if title != none and stil == "bar" {
      block(
        width: 100%, fill: color,
        radius: (top-left: radius, top-right: radius),
        inset: (x: 11pt, y: 6pt),
        text(size: 0.62em, weight: "bold", fill: white, tracking: 0.6pt,
             upper(title)),
      )
    }
    block(width: 100%, inset: inset, {
    // Beim Etikettenstil sitzt die Beschriftung im Kasten und teilt sich den
    // Einzug mit dem Rumpf. Gemischtschriftlich und in der Farbe, nicht versal
    // und weiß: das Etikett ist hier eine Überschrift, kein Reiter.
    if title != none and stil == "label" {
      block(above: 0pt, below: 0.45em,
        text(size: 0.78em, weight: "bold", fill: color, title))
    }
    if number == none { body } else {
      grid(
        columns: (auto, 1fr), column-gutter: 8pt, align: (left + top, left + top),
        box(baseline: 0.24em, circle(
          radius: 0.62em, fill: color, stroke: none,
          align(center + horizon,
                text(size: 0.62em, weight: "bold", fill: white, str(number))),
        )),
        body,
      )
    }
    })
  },
  )
}

/// Ein hervorgehobener Merksatz — Beamers `alertblock`.
///
/// Der Balken links macht ihn auf jeder Folie sofort als „das bleibt hängen"
/// erkennbar, ohne dass er wie ein zweiter Kasten aussieht.
#let callout(
  body,
  title: [Note],
  color: auto,
  radius: 7pt,
  inset: (x: 14pt, y: 11pt),
  width: 100%,
) = context {
  let t = theme-state.get()
  let color = if color == auto { t.accent } else { color }
  // Auf dunklem Grund ist ein aufgehellter Akzent ein Scheinwerfer. Dort wird
  // die Farbe abgedunkelt statt aufgehellt, und die Beschriftung aufgehellt.
  let grund = if t.inverted { color.darken(68%) } else { color.lighten(90%) }
  let beschriftung = if t.inverted { color.lighten(15%) } else { color.darken(12%) }
  block(
    width: width, radius: radius, fill: grund,
    stroke: (left: 3.5pt + color), inset: inset,
    {
      // Nicht Text, `v()` und Rumpf hintereinander: zwischen zwei Absätzen
      // schiebt Typst zusätzlich `par.spacing` — bei 24pt Schrift 29pt, die
      // sich zum ausdrücklichen Abstand addieren. Gemessen 34pt statt der
      // gewollten 6. Als Blöcke mit gesetztem `above`/`below` zählt nur, was
      // hier steht.
      if title != none {
        block(above: 0pt, below: 0pt,
          text(size: 0.62em, weight: "bold", fill: beschriftung,
               tracking: 0.6pt, upper(title)))
      }
      // Relativ zur Schrift, damit der Abstand bei jeder Themengröße stimmt:
      // fest gesetzte Punkte sähen bei 15pt zu luftig und bei 31pt gedrängt aus.
      // Mehr Luft als im Kasten: dort trennt der farbige Streifen Etikett und
      // Text, hier stehen beide auf demselben Grund und brauchen den Abstand.
      block(above: if title == none { 0pt } else { 0.6em }, below: 0pt, body)
    },
  )
}

/// Zwei oder mehr Spalten nebeneinander.
///
/// Der Name kommt aus Touying und Polylux, die ihn unabhängig voneinander
/// gleich gewählt haben.
///
/// `split` nimmt die Spaltenbreiten; die Vorgabe gibt der ersten Spalte etwas
/// mehr, weil dort meist die Anschauung steht und rechts der Text.
#let side-by-side(
  ..parts,
  split: (1.25fr, 1fr),
  gutter: 18pt,
  align: horizon,
) = {
  let spalten = parts.pos()
  assert(spalten.len() >= 2,
         message: "typstage: side-by-side() wants at least two columns")
  // `..parts` schluckt sonst jede benannte Angabe wortlos — ein Tippfehler in
  // `split:` bliebe unbemerkt, und die Folie sähe still anders aus.
  assert(parts.named().len() == 0,
         message: "typstage: side-by-side() does not know "
                + parts.named().keys().join(", ")
                + " — it takes split, gutter and align.")
  let breiten = if spalten.len() == split.len() { split }
                else { (1fr,) * spalten.len() }
  grid(columns: breiten, column-gutter: gutter, align: align, ..spalten)
}

/// Ein Kachelraster, das sich von selbst staffelt.
///
/// Jede Kachel erscheint einen Schritt nach der vorigen — das ist der Grund,
/// warum es diese Funktion gibt: von Hand heißt das ein `anim` je Kachel mit
/// hochgezählter Nummer oder Verzögerung.
///
/// `at` verhält sich wie bei `anim`: `auto` nimmt den nächsten freien Schritt.
/// `stride: 0` lässt alle im selben Schritt erscheinen und staffelt nur über
/// `stagger` in Millisekunden — dann läuft eine Welle durch das Raster.
#let tiles(
  ..items,
  columns: auto,
  gutter: 14pt,
  row-gutter: auto,
  at: auto,
  stride: 1,
  stagger: 0,
  enter: "fade-up",
  align: top + left,
) = context {
  let kacheln = items.pos()
  assert(kacheln.len() > 0, message: "typstage: tiles() wants at least one tile")
  assert(at == auto or type(at) == int,
         message: "typstage: tiles() takes a step number or auto")
  // Einmal aufgelöst und dann hochgezählt — nicht je Kachel `auto`, sonst
  // ließe sich `stride: 0` (alle im selben Schritt) gar nicht ausdrücken.
  let start = if at == auto { step-cursor.get().first() + 1 } else { at }
  let spalten = if columns == auto { calc.min(kacheln.len(), 3) } else { columns }
  grid(
    columns: if type(spalten) == int { (1fr,) * spalten } else { spalten },
    column-gutter: gutter,
    row-gutter: if row-gutter == auto { gutter } else { row-gutter },
    align: align,
    ..kacheln.enumerate().map(((i, k)) => anim(
      k,
      at: start + i * stride,
      enter: enter,
      delay: i * stagger,
    )),
  )
}

/// Eine große Aussage in der Mitte — die Formel, auf die es ankommt.
///
/// Verlangt ausdrücklich die volle Breite: ein verfolgtes Element wird so
/// breit wie sein Inhalt, ein blankes `align(center, …)` darin hätte keinen
/// Raum zum Zentrieren und säße unverändert links.
#let statement(
  body,
  size: 1.6em,
  color: none,
  above: 0.6em,
  below: 0.6em,
) = block(width: 100%, {
  v(above)
  // `fill: auto` gibt es bei `text` nicht — ohne Farbe wird sie schlicht nicht
  // gesetzt, damit die der Umgebung gilt.
  let gesetzt = text(size: size, body)
  align(center, if color == none { gesetzt } else { text(fill: color, gesetzt) })
  v(below)
})
