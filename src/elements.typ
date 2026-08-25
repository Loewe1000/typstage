// Appearing, moving and staggering.

#import "internal.typ": (fit-meldung, html-output, im-deck, im-fit, name-of,
                        offenes-ende, pin-index, pin-marker, selector,
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
///
/// `after` says what the element does once its range is behind it, and it has
/// two values.
///
/// - `"hidden"`, the default and what an `anim` has always done: it goes,
///   playing `exit`, and keeps the room it had.
/// - `"dimmed"`: it stays and is drawn muted, so a point remains legible
///   after the talk has moved on. Nothing moves and nothing is recoloured;
///   the element settles to 65 percent opacity, and paging back brings it up
///   again. That number is measured, and the manual says against what.
///
/// On paper `after` does nothing at all. A page shows every step at once, and
/// a point that is only quiet because the talk has moved past it has no
/// "past" on a handout. This is the same rule that already holds for
/// `"hidden"`: what leaves its range in the browser is still printed.
///
/// `after` needs a range that ends. `at: auto` and `at: 3` run to the end of
/// the slide, and an element that never leaves has no after; the package says
/// so instead of doing nothing. `at: "3"` is that one step, `at: "2-3"` a
/// range.
/// What `anim` does once its arguments have been checked.
///
/// Split out for `stagger`, and for one reason: `dim-freiwillig`. An element
/// written by hand with `after: "dimmed"` whose range ends with the slide is a
/// mistake -- it would rest dim on a step that never comes -- and the check at
/// the end of the document says so. A `stagger(dim: true)` produces exactly
/// that shape for its *last* point on purpose: the point being talked about
/// stays bright, and dims only if the deck goes on. So its points say they may
/// end with the slide, and the late check leaves them alone. The flag rides in
/// the sprite record rather than in `extra`, which becomes markup attributes.
#let anim-kern(body, at: auto, enter: "fade-up", exit: "fade",
               after: "hidden", duration: auto, delay: 0,
               dim-freiwillig: false) = track(
  "anim", body, at: at, dim-freiwillig: dim-freiwillig, extra: (
    enter: enter, exit: exit, delay: delay,
    duration: if duration == auto { none } else { duration },
    // Only the departure from the default travels into the markup. `hidden`
    // is what every sprite has always done after its range, and writing it
    // out would put a new attribute on every element of every deck.
    after: if after == "dimmed" { after } else { none },
  ))

#let anim(
  body,
  at: auto,
  enter: "fade-up",
  exit: "fade",
  after: "hidden",
  duration: auto,
  delay: 0,
) = {
  assert(after in ("hidden", "dimmed"), message:
    "typstage: anim(after: ...) is \"hidden\" or \"dimmed\", not \""
    + str(after) + "\".")
  assert(after == "hidden" or (at != auto and not offenes-ende(selector(at))),
         message: "typstage: anim(after: \"dimmed\") wants a range that ends. "
    + "`at: auto` and `at: 3` run to the end of the slide, so there is no "
    + "after for the element to rest in. Write `at: \"3\"` for that one step "
    + "or `at: \"2-3\"` for a range.")
  anim-kern(body, at: at, enter: enter, exit: exit, after: after,
            duration: duration, delay: delay)
}

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
    // On paper `alternatives` never reaches `track`, it only moves the cursor,
    // so the fit check cannot be left to `track` here. Asked as an assertion
    // rather than by placing `fit-verbot`, because the paged branch below
    // leaves through a `return` and a `return` drops whatever was joined
    // before it.
    assert(im-fit.get() == 0, message: fit-meldung("alternatives"))
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
///
/// `dim: true` turns the sequence into a walk: the point being discussed
/// stands there, the ones before it stay legible but muted. Every point then
/// holds exactly its own step instead of the rest of the slide, and rests at
/// `anim`'s `after: "dimmed"` from the next step on. Paging back brings each
/// one up again.
///
/// Two things follow from that and are worth knowing before reaching for it.
/// The last point dims too as soon as the slide has a further step after it,
/// because then the walk has moved on from it as well. And `stride: 0`, which
/// puts every point on one step, makes them all dim together on the next.
#let stagger(
  ..items,
  start: auto,
  stride: 1,
  enter: "fade-up",
  duration: auto,
  stagger: 60,
  spacing: 0.65em,
  dim: false,
) = context {
  // Asked here rather than left to the `anim`s below, so the message names the
  // function the deck actually wrote. An assertion, not a placed `fit-verbot`,
  // because the list branch below leaves through a `return`.
  assert(im-fit.get() == 0, message: fit-meldung("stagger"))
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

  // Where a point rests. Without `dim` it stays for the rest of the slide, so
  // its range stays open; with `dim` it holds its own step and dims after it.
  // Both selectors carry the same highest number, so the slide keeps its step
  // count either way.
  let bereich(n) = if dim { str(n) } else { str(n) + "-" }
  let ruhe = if dim { "dimmed" } else { "hidden" }

  if punkte.len() == 0 {
    // No list: the pieces in order, each as its own block.
    for (i, b) in gegeben.enumerate() {
      block(anim-kern(b, at: bereich(start + i * stride), after: ruhe,
                      dim-freiwillig: dim, enter: enter, duration: duration,
                      delay: i * stagger))
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
    anim-kern(
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
      at: bereich(start + i * stride), after: ruhe, dim-freiwillig: dim,
      enter: enter, duration: duration, delay: i * stagger,
    )
  }
}
