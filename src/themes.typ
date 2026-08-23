// The look of a presentation: five themes and the blueprint behind them.
//
// A theme is a *dictionary*. Almost everything in it is a value: a color,
// a font, a measure, or a short word for one of the few construction
// kinds (`header`, `footer`, `progress`). Only two entries are functions:
// the title slide and the section slide. The two are whole pictures, not
// a variation of one another; they could only be described with a dozen
// more switches, and even then they would still all be built the same
// way.
//
//   #show: presentation.with(theme: themes.night)
//   #show: presentation.with(theme: themes.lesson + (accent: blue))
//
// The second line is the whole trick to varying a theme: a theme is a
// dictionary, and `+` overwrites individual entries.

#import "config.typ": margins

/// Font arguments that simply leave out a `none`.
///
/// `text(font: none)` does not exist: anyone who does not want to
/// prescribe a font must not set the argument at all.
#let font-args(f) = if f == none { (:) } else { (font: f) }

/// Pieces stacked one below another, with exactly the given spacing.
///
/// The arguments alternate: content, spacing, content, spacing, content.
/// Necessary because Typst inserts `par.spacing` between two paragraphs
/// and `block.spacing` between two blocks: both add to an explicit
/// `v()`. On a title slide with 24pt base text, that was measured at
/// 29pt extra, which pulled the layout apart. Here only what is written
/// counts.
#let stapel(..teile) = {
  let xs = teile.pos()
  for (i, x) in xs.enumerate() {
    if calc.rem(i, 2) == 0 {
      block(above: if i == 0 { 0pt } else { xs.at(i - 1) }, below: 0pt, x)
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Title and section slides
// ═══════════════════════════════════════════════════════════════════════════
//
// Each of these functions receives `(t, s, geo)`: the theme, the slide
// (with `title`, `subtitle`, `author`, `date`) and the canvas.
// `geo.scale` is the factor by which all measures grow along: every
// number below is meant in points of the default canvas and gets
// multiplied by it.

/// The date, as it appears under a title.
///
/// `date` may be either. A `datetime` is set in the local notation;
/// anyone who wants a different one supplies content directly: `date:
/// [15 September 2026]`. Previously, three title slide functions called
/// `display` without asking. An English deck thereby inevitably got
/// "15.09.2026" under the title, and passing content broke the build,
/// because content does not know `display`. The first attempt only fixed
/// this one line here and overlooked the other two places; that is why
/// the conversion now lives in a single place.
#let datum(d) = if type(d) == datetime {
  d.display("[day].[month].[year]")
} else { d }

/// The line with author and date, as it stands under every title slide.
#let by-line(t, s, k) = text(size: 12pt * k, fill: t.muted, {
  s.author
  if s.date != none [ · #datum(s.date) ]
})

// ── default ────────────────────────────────────────────────────────────────

/// Title on the left at half height, with a short accent stroke below it.
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

/// Dark full-bleed surface, accent stroke above the title.
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

/// Centered and large, with an accent band across the full width.
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

/// Tinted background, wide accent bar along the left edge.
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

/// Everything in the middle, nothing at the edge: in a dark room you only
/// see the bright spots anyway.
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

/// Two accent lines, with the title in the accent color between them.
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

/// Only text, left, far down. No stroke, no surface, no color.
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

/// The title sits where the slide title would otherwise stand, just at
/// half height.
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

/// A title page: two hairlines, the title between them, the subtitle in
/// italics below.
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

/// Full-bleed surface in the primary color, title in paper color on top.
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
//  The blueprint
// ═══════════════════════════════════════════════════════════════════════════

/// Builds a theme. Without an argument it produces the default
/// appearance: `themes.default` is exactly that.
///
/// The entries in groups: colors (`paper ink strong accent muted
/// surface border inverted`), typography (`font title-font size
/// title-size weight tracking`), the ordinary slide (`header title-fill
/// rule-size rule-fill head-gap foot-gap band-height box footer
/// footer-rule progress`) and the two whole pictures (`title-slide`,
/// `section`).
///
/// Font sizes: measured against Beamer and Metropolis, where the body
/// text takes up around 3.0% of the slide width and the title 3.9%. The
/// earlier 19pt/23pt were at 2.3% and 2.7%: noticeably smaller than what
/// you would want to read from the back row.
///
/// Comments must NOT go into the parameter list: tidy splits it at the
/// commas and expects a colon in every piece; the API reference breaks
/// on that.
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
  // A typo in one of these three would otherwise simply do nothing: the
  // footer would stay missing, and nobody would know why.
  assert(header in ("band", "plain", "run"),
         message: "typstage: theme(header: ..) is \"band\", \"plain\" or \"run\"")
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
//  The five
// ═══════════════════════════════════════════════════════════════════════════

/// The bundled themes: `themes.default`, `themes.lesson`, `themes.night`,
/// `themes.plain`, `themes.editorial`.
///
/// They are made for different occasions, not the same slide in five
/// colors: the title sits sometimes in a bar, sometimes free, sometimes
/// under a line; the progress indicator grows, travels, or is missing
/// entirely.
#let themes = (
  // The talk in a bright hall. The look typstage has always had, and the
  // default: dark title bar, orange progress.
  default: theme(),

  // The classroom. Larger text, no bar: the title sits on the paper and
  // is underlined by a bold stroke; below, a marker travels along its
  // track, so the class can see how far into the lesson they are.
  // Modeled on German maths textbooks. The colors were not chosen but
  // measured from a sample page of "Fundamente der Mathematik" (Cornelsen,
  // 10th grade): the vermilion of the headings and the note boxes, the
  // cyan blue of the examples and the header line, plus the two tints.
  // What carries meaning there is neither size nor boldness, but *color
  // as meaning*: warm for "this you must know", cool for "this is what it
  // looks like". That is why the heading here is smaller than before and
  // the line beneath it a hairline instead of a bar.
  lesson: theme(
    paper: white,
    ink: rgb("#16181c"),
    // Slightly deeper than the measured #d8391a: on a screen a vermilion
    // glows stronger than on paper.
    strong: rgb("#c1361c"),
    accent: rgb("#2b7fb8"),
    muted: rgb("#767b84"),
    // The tint of the note box. Measured it was #fdf0df; on a slide such
    // a box covers many times the area it has in the book, and the same
    // saturation quickly looks garish there. Hence lighter.
    surface: rgb("#fdf6ee"),
    border: rgb("#f0e2d2"),
    font: ("Source Sans 3", "Source Sans Pro", "Open Sans", "DejaVu Sans"),
    size: 20pt,
    title-size: 24pt,
    // Semibold instead of bold. The heading already stands in its own
    // color and its own size; boldness would be a third signal for the
    // same thing.
    weight: 600,
    title-fill: rgb("#c1361c"),
    // No line under the title. In the book, the colored line belongs to
    // the page's running header, not to the heading; placed underneath it
    // turns two things into one in two colors. The heading carries its
    // hierarchy in its color; it needs nothing more.
    rule-size: 0pt,
    head-gap: 26pt,
    // Header instead of footer: slide number on the left, section on the
    // right, a hairline underneath, exactly like the running header of a
    // textbook page. That drops both at the bottom. The number already
    // stands at the top, and the traveling progress stroke never
    // explained anything the header does not say better: it names the
    // chapter you are in, not merely the fraction.
    header: "run",
    footer: "none",
    progress: "none",
    box: "label",
    title-slide: lesson-title-slide,
    section: lesson-section,
  ),

  // The dimmed room. Deep background, light text, cool accent; the
  // progress sits as a thin line along the top edge, where it does not
  // dazzle.
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

  // As little as possible. White, black, one gray: no color, no surface,
  // no progress. The title is small and leaves the body plenty of room;
  // what you see is the content.
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

  // With character: laid paper, an old-style serif, hairlines. The title
  // sits above a fine line, the page number centered under a second one:
  // a book, not a slide.
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
    // 20pt, not 18pt. Nominally, editorial was tied with plain as the
    // smallest theme, but in reality it was the smallest by far: Iowan
    // sets its x-height at 0.48 of the font size, Inter at 0.55. Measured
    // on a rendered "x", that was 8.64pt against 10.44pt in night and
    // 11.64pt in default, so a quarter smaller than the largest theme,
    // even though the number next to it differed by only six points. At
    // 20pt it is 9.60pt, the same as in lesson (9.72pt). The title grows
    // along with it, otherwise its ratio to the body would fall from 1.33
    // to 1.2.
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


/// The theme currently being set under.
///
/// `card` and `callout` sit *inside* the slide body and know nothing
/// about the presentation on their own. Without this state, every card
/// would have to be handed its colors; this way it fetches them itself.
/// `presentation` writes it once, right at the start, and anyone using a
/// card outside a presentation gets the default.
#let theme-state = state("typstage-theme", themes.default)
