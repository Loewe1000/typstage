// The machinery behind a tracked element. Nothing here is public.
//
// Two tricks carry the whole package.
//
// *Geometry.* In HTML export `here().position()` returns `(0, 0)` everywhere,
// so Typst no longer knows where it put anything. Instead every tracked
// element paints a rectangle around itself in a signal colour — `#feHHLL00`,
// fully transparent, but recoverable in the emitted SVG as
// `<path fill="#feHHLL00">` and measurable with `getBoundingClientRect()`.
// `HHLL` is the element's running number. The browser reads back what Typst
// can no longer tell it.
//
// *Two layers.* A slide's background is an `html.frame` of the whole slide in
// which every tracked element merely holds its place with `hide()`. Each one
// additionally goes into an overlay as its own small `html.frame` and is put
// over its marker rectangle by the browser.

#import "config.typ": *

/// A counter, not a state: `state.get()` and `state.update()` at the same
/// place would be circular and never converge. A counter is made for this.
#let element-counter = counter("typstage-n")

/// Marks that may sit anywhere in a slide body — even deeply nested, because a
/// state update inside an `html.frame` is readable afterwards.
#let sprites = state("typstage-sprites", ())
#let note-state = state("typstage-note", none)
#let transition-state = state("typstage-transition", none)

/// Which output is being built.
///
/// Not `target()`: inside an `html.frame` Typst lays out for *pages*, so
/// `target()` reports "paged" there even though the file being written is
/// HTML. The presentation therefore tells its elements which output they are
/// part of, and they read it from here.
#let html-output = state("typstage-html", false)

/// Jobs for bridged elements, collected per slide. Companion packages push
/// into this; the core only hands the result to the runtime.
#let bridge-jobs = state("typstage-bridge", ())

/// Alpha 0 — invisible, but Typst keeps the path in the SVG.
#let marker(n) = rgb(254, calc.div-euclid(n, 256), calc.rem(n, 256), 0%)

/// Plain text out of content, for speaker notes.
#let plain-text(c) = {
  if type(c) == str { c } else if type(c) != content { "" } else if c.func() == text {
    c.text
  } else if c.func() == raw { c.text } else if c.has("children") {
    c.children.map(plain-text).join("")
  } else if c.has("body") { plain-text(c.body) } else if repr(c.func()) == "space" {
    " "
  } else { "" }
}

/// Largest step number occurring in a selector.
#let max-step(at) = {
  let numbers = at.matches(regex("\d+")).map(m => int(m.text))
  if numbers.len() == 0 { 1 } else { calc.max(..numbers) }
}

/// The running step cursor: the highest step handed out on this slide so far.
///
/// A counter, not a state — and that is the whole trick. Reading a state and
/// writing to it in the same place is circular and never settles; a counter is
/// built for exactly this and converges.
#let step-cursor = counter("typstage-step")

/// Which slide we are on. Only used to scope things that a companion package
/// looks up across the whole document — a query sees every slide at once and
/// has to be able to tell them apart.
#let slide-counter = counter("typstage-slide")

/// A name, however it was written.
///
/// Names identify things across slides — a morph that flies, a frame that
/// receives jobs. `<pythagoras>` reads better than `"pythagoras"` and Typst
/// colours it as what it is, so both are allowed everywhere a name is taken.
#let name-of(value) = {
  if type(value) == label { str(value) }
  else if type(value) == str { value }
  else {
    panic("typstage: a name is a string or a label, not " + str(type(value)))
  }
}

/// Bring a step selector into the one form the runtime understands.
///
/// - `2` → `"2-"`, from step two on. By far the common case: of 242 selectors
///   in the real decks, 239 were open ranges.
/// - `(1, 3)` → `"1,3"`
/// - `"2-"`, `"1-2"`, `"2,4"`, `"-2"`, `"3"` stay as they are.
///
/// `auto` is *not* resolved here — it needs the cursor and hence a context.
#let selector(at) = {
  if type(at) == int { str(at) + "-" }
  else if type(at) == array {
    at.map(x => if type(x) == int { str(x) } else { x }).join(",")
  } else { at }
}

/// A tracked element: holds its place in the background, paints its marker and
/// registers itself for the overlay.
///
/// In paged output none of this applies — there is no overlay and there are no
/// steps, so the element simply stands where Typst puts it.
/// `width` decides how wide the tracked element becomes.
///
/// - `auto` — as wide as its content. Right for inline things: a morphing
///   glyph should not claim the whole line.
/// - a length — that width. Block elements default to the full available
///   width, because that is what a block *is*: without it an `align(center,
///   …)` inside `anim` has no room to centre in and silently stays left.
#let track(kind, body, at: "1-", extra: (:), raw-frames: none, inline: false,
           width: auto) = {
  // The `box` has to sit around the *whole* construction, not inside it:
  // `layout()` is block-level, so an inline element that only chooses a `box`
  // further in would still break the line it sits in.
  let shell-outer = if inline { box } else { it => it }
  shell-outer(context {
  if not html-output.get() { return body }
  element-counter.step()
  // `auto` takes the next step. An explicit selector pulls the cursor up to its
  // own highest step, so whatever follows carries on after it instead of
  // starting over.
  //
  // Only reveals count. An applet, a video or a morph does not consume a step
  // — they are there from the start —, and above all they must not push the
  // bullets beside them along: in a two-column slide the text next to an
  // applet belongs at step one, not behind the applet's tweens.
  if at == auto { step-cursor.step() }
  context {
    let n = element-counter.get().first()
    let selected = if at == auto {
      str(step-cursor.get().first()) + "-"
    } else { selector(at) }
    // Placed, not assigned: a counter only moves when its update stands in the
    // document. Tucked into a `let` it would join into the value instead and
    // turn the selector into content.
    if at != auto and kind == "anim" {
      step-cursor.update(c => calc.max(c, max-step(selected)))
    }
    layout(available => context {
      // Measured under the same width the element has in the background. That
      // measurement travels outward so the sprite gets exactly the same
      // layout — otherwise a `width: 100%` inside the free frame would come to
      // nothing and boxes would lose their area.
      let room = if width == auto {
        if inline { available.width } else { available.width }
      } else { width }
      let m = measure(body, width: room)
      // What holds here has to be set again in the sprite: its own frame does
      // not know the slide's `set` rules.
      let style = (
        size: text.size, fill: text.fill, font: text.font,
        weight: text.weight, style: text.style, lang: text.lang,
      )
      // Inline elements stay as narrow as their content; block elements take
      // the room they were given.
      let w = if inline or width != auto { m.width } else { available.width }
      sprites.update(a => a + ((kind: kind, at: selected, extra: extra, body: body,
                                raw-frames: raw-frames, width: w,
                                height: m.height, style: style),))
      // A `box` is inline and puts its baseline on the bottom edge — with a
      // two-line list item the bullet would drop a line. Block content gets a
      // `block`.
      let shell = if inline { box } else { block }
      shell(width: w, height: m.height, {
        place(top + left, rect(width: w, height: m.height,
                               fill: marker(n), stroke: none))
        // `hide` lays out but does not draw: the space is right, the content
        // is only visible in the overlay.
        place(top + left, hide(body))
      })
    })
  }
  })
}
