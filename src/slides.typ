// Slides, sections and what belongs to a single slide.

#import "internal.typ": note-state, transition-state

/// A regular slide.
#let slide(title, note: none, transition: none, body) = (
  kind: "slide", title: title, note: note, transition: transition, body: body,
)

/// A section slide.
#let section(title, transition: none) = (
  kind: "section", title: title, note: none, transition: transition, body: none,
)

/// The title slide.
#let title-slide(title: [], subtitle: [], author: [], date: none) = (
  kind: "title", title: title, subtitle: subtitle, author: author,
  date: date, note: none, transition: none, body: none,
)

/// How this slide comes in — otherwise the presentation's setting applies.
///
/// - `"none"` — hard cut.
/// - `"fade"` — cross-fade, nothing moves.
/// - `"slide"`, `"push"`, `"cover"`, `"uncover"` — sliding; `from` says where
///   the new slide comes from: `"right"` (default), `"left"`, `"top"`,
///   `"bottom"`. `push` shoves the old one out, `cover` lies down on top,
///   `uncover` pulls the old one away.
/// - `"zoom"` — `direction: "in"` (default) grows the new one towards you,
///   `"out"` lets it step back from the front.
/// - `"blur"` — blurred across.
/// - `"iris"`, `"wipe"` — an aperture. `direction: "open"` (default) opens the
///   new slide out, `"close"` shuts the old one over it. For the wipe, `from`
///   additionally says which edge it starts at.
/// - `"flip"`, `"cube"` — rotation in space; `axis: "y"` (default) turns about
///   the vertical, `"x"` about the horizontal.
///
/// Backwards each one runs as a true reversal. If a morph meets the slide it
/// cross-fades regardless: the movement is then carried by the morph.
#let transition(kind, ..spec) = transition-state.update((kind: kind) + spec.named())

/// A note for the presenter view (key `s`).
#let speaker-note(body) = note-state.update(body)
