// The visible chrome of a slide.
//
// Not a Touying theme: header, footer, section slide and title slide are built
// by hand here. The default theme resembles Metropolis but is not the same
// thing.
//
// Hier steht nur noch, *wie* gezeichnet wird — *was* gezeichnet wird, sagt das
// Theme (siehe `themes.typ`). Jede Zahl unten ist entweder ein Maß aus dem
// Theme oder ein Punktwert auf dem Vorgabe-Canvas, mit `k` mitskaliert.

#import "config.typ": *
#import "internal.typ": note-state, plain-text, slide-counter
#import "themes.typ": font-args

/// The body of one slide, background included.
///
/// The same block serves both outputs: in HTML it becomes the background layer
/// under the overlay, on paper it is the page.
///
/// `t` ist das Theme: alle Farben, Schriften und Maße kommen von dort, und die
/// Titel- wie die Abschnittsfolie zeichnet es selbst.
#let slide-body(s, n, total, style, geo, t) = block(
  width: geo.width, height: geo.height,
{
  // Everything below is measured on the default canvas and scaled with it, so
  // a smaller or wider slide keeps its proportions.
  let k = geo.scale
  let m = margins(geo)
  let inner = geo.width - m.left - m.right
  // Schriftgröße: auf einem 841pt breiten Canvas ist Typsts Vorgabe von 11pt
  // Kleingedrucktes; ein Theme setzt hier um die 19pt an.
  //
  // Schrift, Größe und Textfarbe stehen *hier* und nicht im `style`-Haken —
  // der liegt weiter innen, und was dort steht, überstimmt das Theme.
  set text(..font-args(t.font), size: t.size * k, fill: t.ink)
  if s.kind == "title" {
    (t.title-slide)(t, s, geo)
  } else if s.kind == "section" {
    (t.section)(t, s, geo)
  } else {
    // Eine Folie ohne Titel bekommt keinen Balken: `slide(none)[…]` oder ein
    // nacktes `==`. Der Rumpf rückt dann nach oben und bekommt die Höhe, die
    // sonst der Balken belegt hätte — sonst wäre eine titellose Folie kleiner
    // als eine mit Titel.
    // `plain-text` liefert für eine leere Überschrift `none`, nicht "".
    let roh = if s.title == none { none } else { plain-text(s.title) }
    let titel = roh != none and roh.trim() != ""
    let bar = t.band-height * k
    let strich = if t.rule-size > 0pt {
      t.rule-size * k + t.title-size * 0.34 * k
    } else { 0pt }
    // Wie hoch der Kopf baut. Beim Balken steht das im Theme; ohne Balken wird
    // die Höhe der Titelzeile gerechnet statt gemessen — messen hieße, den
    // Titel zweimal zu setzen, und der Abstand darunter fängt die paar Punkte
    // Unterschied ohnehin auf.
    let kopf = if not titel { m.top } else if t.header == "band" { bar } else {
      m.top + t.title-size * 1.35 * k + strich
    }
    let titel-text = text(
      ..font-args(t.title-font), size: t.title-size * k, weight: t.weight,
      fill: t.title-fill, tracking: t.tracking * k, s.title,
    )
    rect(width: 100%, height: 100%, fill: t.paper, stroke: none)
    if titel and t.header == "band" {
      place(top + left, rect(width: 100%, height: bar, fill: t.strong, stroke: none))
      place(top + left, dx: m.left,
        block(width: inner, height: bar, align(left + horizon, titel-text)))
    } else if titel {
      // Dieselbe Falle wie im Merksatz: ohne gesetztes `above`/`below` läge
      // zwischen Titel und Linie zusätzlich der Absatzabstand, und die Linie
      // rutschte an den Inhalt statt an den Titel.
      place(top + left, dx: m.left, dy: m.top, block(width: inner, {
        block(above: 0pt, below: 0pt, titel-text)
        if t.rule-size > 0pt {
          block(above: t.title-size * 0.34 * k, below: 0pt,
            rect(width: 100%, height: t.rule-size * k, fill: t.rule-fill,
                 stroke: none))
        }
      }))
    }
    // Fußzeile: die Zahl, wahlweise mit der Gesamtzahl, und eine Haarlinie
    // darüber.
    if t.footer-rule > 0pt {
      place(bottom + left, dx: m.left, dy: -(t.foot-gap + 6pt) * k,
            rect(width: inner, height: t.footer-rule * k, fill: t.border, stroke: none))
    }
    let zahl = if t.footer == "fraction" { str(n) + " / " + str(total) } else { str(n) }
    if t.footer == "center" {
      place(bottom + center, dy: -13pt * k, text(size: 12pt * k, fill: t.muted, zahl))
    } else if t.footer != "none" {
      place(bottom + right, dx: -m.right, dy: -13pt * k,
            text(size: 12pt * k, fill: t.muted, zahl))
    }
    // Fortschritt: ein wachsender Balken unten oder oben, oder eine Marke, die
    // auf ihrer Schiene wandert — die zeigt auch bei siebzig Folien noch, wo
    // man ist, während der Balken dort nur langsam länger wird.
    if t.progress == "bar" {
      place(bottom + left,
            rect(width: 100% * n / total, height: 2.5pt * k, fill: t.accent, stroke: none))
    } else if t.progress == "top" {
      place(top + left,
            rect(width: 100% * n / total, height: 2.5pt * k, fill: t.accent, stroke: none))
    } else if t.progress == "tick" {
      let breite = 34pt * k
      place(bottom + left,
            rect(width: 100%, height: 3pt * k, fill: t.accent.lighten(78%), stroke: none))
      place(bottom + left, dx: (geo.width - breite) * n / total,
            rect(width: breite, height: 3pt * k, fill: t.accent, stroke: none))
    }
    place(top + left, dx: m.left, dy: kopf + t.head-gap * k,
      block(width: inner,
            height: geo.height - kopf - (t.head-gap + t.foot-gap) * k,
            style(s.body)))
  }
})

/// A hook that wraps a document template around every body and every sprite.
/// Both have to receive the same typography — they are laid out separately.
#let with-style(s, body) = {
  set text(size: s.style.size, fill: s.style.fill, font: s.style.font,
           weight: s.style.weight, style: s.style.style, lang: s.style.lang,
           tracking: s.style.at("tracking", default: 0pt),
           spacing: s.style.at("spacing", default: 100% + 0pt))
  set par(leading: s.style.at("leading", default: 0.65em),
          spacing: s.style.at("par-spacing", default: 1.2em),
          justify: s.style.at("justify", default: false),
          first-line-indent: s.style.at("first-line-indent", default: 0pt),
          hanging-indent: s.style.at("hanging-indent", default: 0pt))
  body
}

/// Slides shrunk onto paper, with room beside or below each one.
///
/// The `slide-body` above is reused unchanged and merely scaled — a handout
/// that redrew the slides could drift away from them.
///
/// Where a slide has a speaker note it stands in that room; where it has none,
/// ruled lines take its place. Both are the same thing really: the space is
/// for whatever is not on the slide itself.
#let handout-body(all, total, style, geo, t, per-page) = {
  set page(paper: "a4", margin: (x: 1.5cm, y: 1.4cm))
  set text(size: 10pt, fill: t.strong)
  let gap = 14pt
  let column-gap = 10pt
  // A 16:9 slide beside a note column is wide and low. Up to two per upright
  // A4 that wastes most of the page, so there the notes go underneath and the
  // slide takes the full width. From three on, beside is the better use.
  let beside = per-page >= 3

  let lines(height) = {
    let count = calc.max(2, int(height.pt() / 17))
    stack(dir: ttb, spacing: 17pt,
          ..range(count).map(_ => line(length: 100%, stroke: 0.4pt + luma(84%))))
  }
  let room-for-notes(height) = context {
    let note = note-state.get()
    if note != none and plain-text(note).trim() != "" {
      text(size: 9pt, fill: luma(35%), note)
    } else { lines(height) }
  }

  // Numbered first, so the count keeps running across the page breaks.
  let numbered = ()
  let n = 0
  for s in all {
    if s.kind == "slide" { n += 1 }
    numbered.push((slide: s, number: n))
  }

  let sheets = ()
  let batch = ()
  for item in numbered {
    batch.push(item)
    if batch.len() == per-page { sheets.push(batch); batch = () }
  }
  if batch.len() > 0 { sheets.push(batch) }

  // One `layout` per sheet, not per row: asked again further down the page it
  // would report the *remaining* height, and every slide would come out a
  // different size.
  sheets.map(sheet => layout(room => {
    let share = (room.height - (per-page - 1) * gap) / per-page
    let note-column = calc.max(4.2cm, room.width * 0.26)
    let w = if beside {
      calc.min(room.width - note-column - column-gap,
               share * (geo.width / geo.height))
    } else {
      calc.min(room.width, share * (geo.width / geo.height))
    }
    let h = w * (geo.height / geo.width)
    let framed(item) = block(
      width: w, height: h, clip: true, radius: 2pt,
      stroke: 0.5pt + luma(72%),
      scale(w / geo.width * 100%, origin: top + left,
            slide-body(item.slide, item.number, total, style, geo, t)))

    let rows = sheet.map(item => {
      // Counted here too, not only in the other two branches: a companion
      // package resolves its targets per slide, and without this every applet
      // in the deck would look as if it stood on the same one.
      slide-counter.step()
      // The slide's own `speaker-note` may overwrite this while it is laid
      // out — which is why the note is only read afterwards.
      note-state.update(item.slide.note)
      if beside {
        grid(columns: (w, 1fr), column-gutter: column-gap, align: top,
             framed(item), room-for-notes(h))
      } else {
        framed(item)
        v(8pt)
        // Fixed height, so every row is exactly its share of the page and the
        // rows below do not creep upwards when a note runs short.
        block(width: w, height: share - h - 8pt, room-for-notes(share - h - 8pt))
      }
    })
    rows.join(v(gap))
  })).join(pagebreak(weak: true))
}
