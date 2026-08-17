// Appearing, moving and staggering.

#import "internal.typ": html-output, name-of, step-cursor, track

/// Reveal content on particular steps.
///
/// `at` is a step selector. `auto` — the default — takes the next free step,
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
/// The name is a string or a label — `morph(<pythagoras>, …)`.
///
/// `match` is `"auto"`, `"glyph"` (always per glyph) or `"block"` (always as
/// one rectangle).
///
/// Two names may be equal on the *target* slide. The runtime looks the source
/// up by name but iterates over the targets, so two targets sharing a name
/// both start from the same place and the glyph visibly splits in two.
#let morph(name, body, duration: auto, match: "auto", inline: true) = track(
  "morph", body, at: "1-", inline: inline,
  extra: (name: name-of(name), match: match,
          duration: if duration == auto { none } else { duration }),
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
/// They all stand in the same place, in a box as large as the largest of them,
/// so nothing around them jumps as they change. Each takes one step; the last
/// one stays for the rest of the slide.
///
/// On paper only the last one is set — in the same box, so the page keeps the
/// spacing of the slide. Printing all of them would pile them on top of one
/// another.
#let alternatives(
  ..variants,
  start: auto,
  align: top + left,
  enter: "fade",
  duration: auto,
) = {
  let items = variants.pos()
  assert(items.len() > 0,
         message: "typstage: alternatives() wants at least one version")
  layout(available => context {
    let sizes = items.map(v => measure(v, width: available.width))
    let w = calc.max(..sizes.map(s => s.width))
    let h = calc.max(..sizes.map(s => s.height))
    if not html-output.get() {
      return block(width: w, height: h, place(align, items.last()))
    }
    let first = if start == auto { step-cursor.get().first() + 1 } else { start }
    let last = items.len() - 1
    block(width: w, height: h, {
      for (i, v) in items.enumerate() {
        // Exactly this step for all but the last, which stays: `"3"` is that
        // one step, `"3-"` is from there on.
        let at = if i == last { str(first + i) + "-" } else { str(first + i) }
        place(align, anim(v, at: at, enter: enter, duration: duration))
      }
    })
  })
}

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
/// included. Inside a grid cell, a table or a figure it is not seen — there
/// the content is a field of an element, not part of the body — so reach for
/// `anim` in those places.
#let pause = metadata("typstage-pause")

/// Stagger the items of a list across the steps.
///
/// The rows are set here rather than handed to `list()`: only that way does
/// the bullet belong to the tracked element. Left to the list, it would sit in
/// the background — and be there before its item appeared.
///
/// `start` is `auto` by default: the list carries on where the slide left off,
/// so `stagger` after two `anim`s begins at step three.
#let stagger(
  body,
  start: auto,
  stride: 1,
  enter: "fade-up",
  duration: auto,
  stagger: 0,
  spacing: 0.65em,
) = context {
  let start = if start == auto { step-cursor.get().first() + 1 } else { start }
  let parts = if body.has("children") { body.children } else { (body,) }
  let items = parts.filter(c => c.func() in (list.item, enum.item))
  if items.len() == 0 {
    // No list content — then as one piece.
    return anim(body, at: str(start) + "-", enter: enter, duration: duration)
  }
  let numbered = items.at(0).func() == enum.item
  let marks = items.enumerate().map(((i, p)) => {
    if numbered { [#(i + 1).] } else { [•] }
  })
  // One shared column width so the texts line up.
  let column = calc.max(..marks.map(m => measure(m).width.pt())) * 1pt

  for (i, p) in items.enumerate() {
    if i > 0 { v(spacing, weak: true) }
    anim(
      grid(
        columns: (column, 1fr),
        column-gutter: 0.5em,
        align: (right, left),
        marks.at(i), p.body,
      ),
      at: str(start + i * stride) + "-",
      enter: enter, duration: duration, delay: i * stagger,
    )
  }
}

/// Stagger arbitrary blocks that are not a list — same rules as `stagger`,
/// `start` included.
#let steps(..blocks, start: auto, stride: 1, enter: "fade-up",
           stagger: 0) = context {
  let start = if start == auto { step-cursor.get().first() + 1 } else { start }
  for (i, b) in blocks.pos().enumerate() {
    block(anim(b, at: str(start + i * stride) + "-",
               enter: enter, delay: i * stagger))
  }
}
