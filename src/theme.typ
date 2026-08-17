// The visible chrome of a slide.
//
// Not a Touying theme: header, footer, section slide and title slide are built
// by hand here. They resemble Metropolis but are not the same thing.

#import "config.typ": *
#import "internal.typ": note-state, plain-text, slide-counter

/// The body of one slide, background included.
///
/// The same block serves both outputs: in HTML it becomes the background layer
/// under the overlay, on paper it is the page.
#let slide-body(s, n, total, style, geo) = block(
  width: geo.width, height: geo.height,
{
  // Everything below is measured on the default canvas and scaled with it, so
  // a smaller or wider slide keeps its proportions.
  let k = geo.scale
  let pad = geo.margin
  let bar = 54pt * k          // height of the title band
  // Slide type size: on an 841pt wide canvas Typst's default of 11pt is fine
  // print. Metropolis sets around 20pt here.
  set text(size: 19pt * k)
  if s.kind == "title" {
    rect(width: 100%, height: 100%, fill: paper, stroke: none)
    place(top + left, dx: pad, dy: geo.height * 0.32, {
      text(size: 34pt * k, weight: "bold", fill: dark, s.title)
      v(4pt * k)
      rect(width: 190pt * k, height: 2.5pt * k, fill: accent, stroke: none)
      v(6pt * k)
      text(size: 17pt * k, fill: muted, s.subtitle)
    })
    place(bottom + left, dx: pad, dy: -pad,
      text(size: 12pt * k, fill: muted, {
        s.author
        if s.date != none [ · #s.date.display("[day].[month].[year]") ]
      }))
  } else if s.kind == "section" {
    rect(width: 100%, height: 100%, fill: dark, stroke: none)
    place(horizon + left, dx: pad, {
      rect(width: 62pt * k, height: 2.5pt * k, fill: accent, stroke: none)
      v(8pt * k)
      text(size: 30pt * k, weight: "bold", fill: white, s.title)
    })
  } else {
    rect(width: 100%, height: 100%, fill: paper, stroke: none)
    place(top + left, rect(width: 100%, height: bar, fill: dark, stroke: none))
    place(top + left, dx: pad, dy: 14pt * k,
          text(size: 23pt * k, weight: "bold", fill: white, s.title))
    place(bottom + right, dx: -pad, dy: -13pt * k,
          text(size: 12pt * k, fill: muted, str(n) + " / " + str(total)))
    place(bottom + left,
          rect(width: 100% * n / total, height: 2.5pt * k, fill: accent, stroke: none))
    place(top + left, dx: pad, dy: bar + 20pt * k,
      block(width: geo.width - 2 * pad,
            height: geo.height - bar - 44pt * k,
            style(s.body)))
  }
})

/// A hook that wraps a document template around every body and every sprite.
/// Both have to receive the same typography — they are laid out separately.
#let with-style(s, body) = {
  set text(size: s.style.size, fill: s.style.fill, font: s.style.font,
           weight: s.style.weight, style: s.style.style, lang: s.style.lang)
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
#let handout-body(all, total, style, geo, per-page) = {
  set page(paper: "a4", margin: (x: 1.5cm, y: 1.4cm))
  set text(size: 10pt, fill: dark)
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
            slide-body(item.slide, item.number, total, style, geo)))

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
