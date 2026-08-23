// Slides, sections and what belongs to a single slide.

#import "internal.typ": (deck-info, html-output, note-state, step-cursor,
                        step-jetzt, transition-state)

/// A regular slide.
///
/// `title: none`, or a bare `==` in heading form, leaves out the title bar;
/// the body then gets the whole area.
#let slide(title: none, note: none, transition: none, ..rest) = {
  // So that all three notations work: `slide[body]` (without a title),
  // `slide([title])[body]` and `slide(none)[body]`. A single piece is the
  // body, two are title and body.
  let teile = rest.pos()
  let kopf = title
  let rumpf = []
  if teile.len() == 1 {
    rumpf = teile.at(0)
  } else if teile.len() >= 2 {
    kopf = teile.at(0)
    rumpf = teile.at(1)
  }
  (kind: "slide", title: kopf, note: note, transition: transition, body: rumpf)
}

/// A section slide.
#let section(title, transition: none) = (
  kind: "section", title: title, note: none, transition: transition, body: none,
)

/// The title slide.
#let title-slide(title: [], subtitle: [], author: [], date: none) = (
  kind: "title", title: title, subtitle: subtitle, author: author,
  date: date, note: none, transition: none, body: none,
)

/// How this slide comes in, otherwise the presentation's setting applies.
///
/// - `"none"`: hard cut.
/// - `"fade"`: cross-fade, nothing moves.
/// - `"slide"`, `"push"`, `"cover"`, `"uncover"`: sliding; `from` says where
///   the new slide comes from: `"right"` (default), `"left"`, `"top"`,
///   `"bottom"`. `push` shoves the old one out, `cover` lies down on top,
///   `uncover` pulls the old one away.
/// - `"zoom"`: `direction: "in"` (default) grows the new one towards you,
///   `"out"` lets it step back from the front.
/// - `"blur"`: blurred across.
/// - `"iris"`, `"wipe"`: an aperture. `direction: "open"` (default) opens the
///   new slide out, `"close"` shuts the old one over it. For the wipe, `from`
///   additionally says which edge it starts at.
/// - `"flip"`, `"cube"`: rotation in space; `axis: "y"` (default) turns about
///   the vertical, `"x"` about the horizontal.
///
/// Backwards each one runs as a true reversal. If a morph meets the slide it
/// cross-fades regardless: the movement is then carried by the morph.
#let transition(kind, ..spec) = transition-state.update((kind: kind) + spec.named())

/// What the deck knows about itself, read from inside a slide.
///
/// ```typ
/// #context {
///   let deck = info()
///   [#deck.section.title #h(1fr) #deck.slide.number/#deck.slide.total]
/// }
/// ```
///
/// It is the same reading the built-in chrome does. Every number the package
/// prints on a slide, the footer, the fraction, the length of the progress bar
/// and the running header, comes out of this function and out of no second
/// count, so a hand-built footer and the built-in one cannot disagree.
///
/// What comes back, as a dictionary:
///
/// - `title`, `subtitle`, `author`, `date`: the deck's own particulars, as
///   `presentation` or a `title-slide` received them.
/// - `slide.number`, `slide.total`: this slide and how many there are.
///   Counted the way the footer counts, so title and section slides are not
///   in it.
/// - `slide.numbered`: whether this slide is one of the counted ones. It is
///   `false` on a title slide and on a section slide, and `number` then holds
///   the last slide counted before it, 0 on a cover that opens the deck. A
///   footer can therefore leave its counter slot clear instead of printing a
///   zero into it.
/// - `step.number`, `step.total`: this deck counts in steps as well as in
///   slides, which no footer can guess at. `number` is the step the calling
///   content itself stands on: 1 in the body of a slide, and inside an
///   `anim`, a `stagger` or an `alternatives` the step of that reveal, its
///   first one where it covers several. On paper a slide is one page in its
///   final state, so `number` is `total` there.
/// - `section.number`, `section.total`, `section.title`: which section the
///   slide belongs to, how many the deck has, and its title. Before the first
///   `=` heading, `number` is `0` and `title` is `none`.
///
/// Only in a context. *Before* any presentation has run there is nothing to
/// read and this stops with a message rather than handing out zeros. *After*
/// one it does not: whoever passes the slides as arguments and writes an
/// `info()` below the call still gets the last slide's numbers. Clearing the
/// deck's own record at the end would close that, and it was measured: a slide
/// carrying one reveal beside a `tiles` went from no layout warning to three
/// "did not converge" ones. A corner nobody stands in is not worth that, and in
/// the show-rule notation nothing comes after the deck anyway.
#let info() = {
  let stand = deck-info.get()
  assert(stand != none, message:
    "typstage: info() reads what the deck knows about itself and therefore "
    + "works only inside a presentation.")
  // A footer stands inside the slide whose step count it wants, and that count
  // is only settled once the slide has been laid out. So the count is fetched
  // from the far end: `slide-body` leaves a mark there carrying the slide's
  // number, and the cursor is read at that mark. The same forward reference as
  // "page 3 of 12", and read straight off the counter rather than passed
  // through a state, which would cost one layout run too many.
  let ende = query(<typstage-slide-end>).find(e => e.value == stand.nr)
  let gesamt = if ende == none { 1 } else {
    calc.max(1, step-cursor.at(ende.location()).first())
  }
  stand.data + (step: (
    // Paged output has no current step. Every page shows the slide in its
    // final state, everything at once, so the step shown is the last one.
    number: if html-output.get() { step-jetzt() } else { gesamt },
    total: gesamt,
  ))
}

/// A note for the presenter view (key `s`).
#let speaker-note(body) = note-state.update(body)
