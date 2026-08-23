// Appearing, moving and staggering.

#import "internal.typ": (html-output, im-deck, name-of, pin-index, pin-marker,
                        step-cursor, track)

/// Reveal content on particular steps.
///
/// `at` is a step selector. `auto`, the default, takes the next free step,
/// so consecutive `anim`s reveal one after another without any numbering.
/// Otherwise: `2` (from step two on), `"1-2"`, `(2, 4)`, `"3"`. An explicit
/// number also moves the cursor along, so a following `auto` carries on after
/// it instead of starting over.
///
/// `enter` applies in both directions: paging back plays the same effect in
/// reverse, taking the entrance back. `exit` only concerns a real departure,
/// when an element falls out of its range while moving forward.
#let anim(
  body,
  at: auto,
  enter: "fade-up",
  exit: "fade",
  duration: auto,
  delay: 0,
) = track("anim", body, at: at, extra: (
  enter: enter, exit: exit, delay: delay,
  duration: if duration == auto { none } else { duration },
))

/// Magic move: the same `name` on two slides, and the thing flies across.
///
/// The name is a string or a label: `morph(<pythagoras>, …)`.
///
/// `duration` is 900 ms, not the duration of the presentation: a flight
/// across the slide takes more time than a simple fade-in, and in real decks
/// the default was overridden in 161 of 165 cases. `auto` falls back to the
/// presentation's duration.
///
/// `match` is `"auto"`, `"glyph"` (always per glyph) or `"block"` (always as
/// one rectangle).
///
/// Two names may be equal on the *target* slide. The runtime looks the source
/// up by name but iterates over the targets, so two targets sharing a name
/// both start from the same place and the glyph visibly splits in two.
/// `at` is almost always right as it is. A morph is present from the first
/// step on: a flight target must already be there when the slide is entered.
/// Because paging back swaps the roles, that holds for both ends.
///
/// Delaying is only worthwhile for the *first* link in a chain, for example
/// when the formula should appear together with its tile. It is allowed
/// exactly when the preceding slide carries no morph of the same name; the
/// package checks this at compile time and speaks up when it does not hold.
#let morph(name, body, at: "1-", duration: 900, match: "auto", inline: true) = track(
  "morph", body, at: at, inline: inline,
  // `fly`, not `duration`: this is the duration of the *flight*, and the
  // runtime used to read the same attribute for the fade-in too. A morph
  // with `at:` therefore faded in over 900ms while the card next to it
  // finished after 520ms: the same motion, visibly pulled apart.
  extra: (name: name-of(name), match: match,
          fly: if duration == auto { none } else { duration }),
)

/// Several versions of the same thing, each replacing the one before.
///
/// ```typ
/// #alternatives(
///   $ (a + b)^2 $,
///   $ (a + b)(a + b) $,
///   $ a^2 + 2 a b + b^2 $,
/// )
/// ```
///
/// `inline: true` keeps the whole thing in the running line, for versions of a
/// single word or formula.
///
/// They all stand in the same place, in a box as large as the largest of them,
/// so nothing around them jumps as they change. Each takes one step; the last
/// one stays for the rest of the slide.
///
/// On paper only the last one is set, in the same box, so the page keeps the
/// spacing of the slide. Printing all of them would pile them on top of one
/// another.
#let alternatives(
  ..variants,
  start: auto,
  align: top + left,
  enter: "fade",
  duration: auto,
  inline: false,
) = {
  let items = variants.pos()
  assert(items.len() > 0,
         message: "typstage: alternatives() wants at least one version")
  // Steps are one-based. A 0 would never hit: the first version would never
  // appear, and the last would be there from the start. This does not show
  // up as an error: the slide simply has one step fewer, and nothing says
  // why.
  assert(start == auto or (type(start) == int and start >= 1),
         message: "typstage: alternatives(start: …) counts from 1, not 0")
  // As with `morph`: `layout()` works block-wise and would break the line
  // the versions are sitting in. The wrapper must therefore lie around the
  // whole thing, not inside it.
  let shell-outer = if inline { box } else { it => it }
  shell-outer(layout(available => context {
    // Measure twice, the larger one wins: the same trap as in `track`.
    // `height: 100%` in one version would otherwise collapse to zero, and
    // measuring only against the available height would clip any overflow.
    let natural = items.map(v => measure(v, width: available.width))
    let bounded = items.map(v => measure(v, width: available.width,
                                         height: available.height))
    let w = calc.max(..natural.map(s => s.width), ..bounded.map(s => s.width))
    let h = calc.max(..natural.map(s => s.height), ..bounded.map(s => s.height))
    let first = if start == auto { step-cursor.get().first() + 1 } else { start }
    if not html-output.get() {
      // Only the last version is set on paper, but the cursor moves as if all
      // of them stood there. Every version is one step, and
      // `info().step.total` has to report the same count in both outputs.
      return {
        if im-deck() {
          step-cursor.update(c => calc.max(c, first + items.len() - 1))
        }
        block(width: w, height: h, place(align, items.last()))
      }
    }
    let last = items.len() - 1
    block(width: w, height: h, {
      for (i, v) in items.enumerate() {
        // Exactly this step for all but the last, which stays: `"3"` is that
        // one step, `"3-"` is from there on.
        let at = if i == last { str(first + i) + "-" } else { str(first + i) }
        place(align, anim(v, at: at, enter: enter, duration: duration))
      }
    })
  }))
}

/// A named piece inside a morph.
///
/// Shape matching pairs glyphs by their outline and, where that is not
/// enough, by proximity. Most of the time that is right. Where it is not,
/// because the 3 in `3x^4` is meant to become the 3 in `4 dot 3x^3` and
/// another 3 sits in between, the piece gets a name, and the pairing follows
/// that instead.
///
/// ```typ
/// #morph(<term>)[$#pin(<faktor>)[3] x^#pin(<hoch>)[4]$]
/// … and on the next slide …
/// #morph(<term>)[$#pin(<hoch>)[4] dot #pin(<faktor>)[3] x^3$]
/// ```
///
/// Matching names find each other before the shape is consulted; everything
/// else works as before. A pin with no counterpart on the other slide falls
/// back to shape matching without complaint.
///
/// The name is a string or a label.
#let pin(name, body) = box(fill: pin-marker(pin-index(name-of(name))), body)

/// Everything after this appears a step later.
///
/// The short form for slides that simply unfold: no `anim` around anything,
/// no step numbers.
///
/// ```typ
/// == A slide
/// First this.
/// #pause
/// Then that.
/// ```
///
/// It is read at the top level of the slide body, `#set` and `#show` rules
/// included. Inside a grid cell, a table or a figure it is not seen: there
/// the content is a field of an element, not part of the body. Reach for
/// `anim` in those places instead.
#let pause = metadata("typstage-pause")

/// Reveal one after another: a list or several blocks.
///
/// Two notations, the same function:
///
/// ```typ
/// #stagger[
///   - this first
///   - then this
/// ]
/// #stagger(card[left], card[right])
/// ```
///
/// For a list, the bullet marks are set here rather than left to `list`:
/// only this way does the mark belong to the tracked element. If it stayed
/// with the list, it would sit in the background and be there before its
/// point appears.
///
/// `start` is `auto`: the sequence continues where the slide left off.
/// `stride: 0` makes everything appear on the same step and staggers only
/// through `stagger`, in milliseconds.
#let stagger(
  ..items,
  start: auto,
  stride: 1,
  enter: "fade-up",
  duration: auto,
  stagger: 60,
  spacing: 0.65em,
) = context {
  let start = if start == auto { step-cursor.get().first() + 1 } else { start }
  let gegeben = items.pos()
  assert(gegeben.len() > 0, message: "typstage: stagger() wants something to stagger")

  // A single piece can be a list: then its items are staggered. Anything
  // else is the pieces themselves.
  let punkte = if gegeben.len() == 1 {
    let body = gegeben.first()
    let parts = if body.has("children") { body.children } else { (body,) }
    parts.filter(c => c.func() in (list.item, enum.item))
  } else { () }

  if punkte.len() == 0 {
    // No list: the pieces in order, each as its own block.
    for (i, b) in gegeben.enumerate() {
      block(anim(b, at: str(start + i * stride) + "-",
                 enter: enter, duration: duration, delay: i * stagger))
    }
    return
  }

  let numbered = punkte.at(0).func() == enum.item
  let marks = punkte.enumerate().map(((i, p)) => {
    if numbered { [#(i + 1).] } else { [•] }
  })
  // One shared column width so the texts line up.
  let column = calc.max(..marks.map(m => measure(m).width.pt())) * 1pt

  for (i, p) in punkte.enumerate() {
    if i > 0 { v(spacing, weak: true) }
    anim(
      grid(
        columns: (column, 1fr),
        column-gutter: 0.5em,
        // Vertical alignment stated explicitly: an `auto` alignment would
        // inherit that of the surrounding grid, and `side-by-side` prescribes
        // `horizon`. The mark would then sit next to the middle of a
        // two-line item instead of next to its first line.
        align: (right + top, left + top),
        marks.at(i), p.body,
      ),
      at: str(start + i * stride) + "-",
      enter: enter, duration: duration, delay: i * stagger,
    )
  }
}
