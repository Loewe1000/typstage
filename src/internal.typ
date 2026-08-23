// The machinery behind a tracked element. Nothing here is public.
//
// Two tricks carry the whole package.
//
// *Geometry.* In HTML export `here().position()` returns `(0, 0)` everywhere,
// so Typst no longer knows where it put anything. Instead every tracked
// element paints a rectangle around itself in a signal colour, `#feHHLL00`,
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

/// Marks that may sit anywhere in a slide body, even deeply nested, because a
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

/// Alpha 0: invisible, but Typst keeps the path in the SVG.
#let marker(n) = rgb(254, calc.div-euclid(n, 256), calc.rem(n, 256), 0%)

/// The colour of a pin marker. Like `marker`, only with 253 in the first
/// channel. That is how the runtime tells a pin apart from an element's
/// marker.
#let pin-marker(n) = rgb(253, calc.div-euclid(n, 256), calc.rem(n, 256), 0%)

/// Turn a name into a number from 0 to 65535 (FNV-1a over the bytes).
///
/// Computed on purpose rather than counted: the same name gives the same
/// number on every slide and in every run, without a list having to be kept
/// anywhere and passed along between slides. Two different names can hit the
/// same number. With a handful of pins per transformation that is unlikely,
/// and the consequence would be a wrongly paired glyph, not an error.
#let pin-index(name) = {
  let h = 2166136261
  for b in array(bytes(name)) {
    h = calc.rem(h.bit-xor(b) * 16777619, 4294967296)
  }
  calc.rem(h, 65536)
}

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

/// Does a selector cover the first step?
///
/// Decides whether a morph is already present when the slide is entered.
/// `"1-"` and `"1,3"` do, `"2-"` and `"3"` do not.
#let ab-schritt-eins(sel) = {
  sel.split(",").any(teil => {
    let t = teil.trim()
    if t.ends-with("-") {
      let a = t.slice(0, -1).trim()
      a == "" or int(a) <= 1
    } else if t.contains("-") {
      let g = t.split("-")
      int(g.first().trim()) <= 1 and int(g.last().trim()) >= 1
    } else { int(t) == 1 }
  })
}

/// All morphs of the document: each entry is slide, name and whether it
/// stands from step one. Checked at the end: a delayed morph must not share
/// its name with one on the slide before it, or the flight there is lost.
#let morph-index = state("typstage-morphs", ())

/// A stroke that no longer folds into the one it is set inside.
///
/// A `stroke` keeps `auto` for whatever it does not name, and `auto` is
/// filled in from the enclosing stroke rather than from the default. That
/// matters here because the box hands its own border to a `set` rule and
/// puts the document's back inside: a deck's `#set block(stroke: red)` names
/// only the paint, so inside the box's `0.7pt + border` it came out 0.7pt red
/// instead of 1pt red. Measured on the card's colored tab, in all five
/// themes.
///
/// Every field has to be pinned, not just the thickness. Pinning only that
/// one left the same fold a row further along: `#set block(stroke: 3pt)`
/// names the thickness and leaves the paint on `auto`, and the inner edges
/// then came out in the box's border grey instead of black. Measured on a
/// deck without a single label, seven spellings affected, among them
/// `stroke: 3pt` and `stroke: (dash: "dashed")`.
#let fester-strich(v) = {
  let einer(x) = if type(x) == stroke {
    stroke(
      paint: if x.paint == auto { black } else { x.paint },
      thickness: if x.thickness == auto { 1pt } else { x.thickness },
      cap: if x.cap == auto { "butt" } else { x.cap },
      join: if x.join == auto { "miter" } else { x.join },
      dash: if x.dash == auto { none } else { x.dash },
      miter-limit: if x.miter-limit == auto { 4.0 } else { x.miter-limit },
    )
  } else { x }
  if type(v) == dictionary {
    v.pairs().map(((k, x)) => (k, einer(x))).to-dict()
  } else { einer(v) }
}

/// The block style the surrounding document has set.
///
/// `card`, `callout` and the handout frame hand their own surface to a `set`
/// rule instead of writing it as an argument, because only then can a
/// `show label(..): set block(fill: ..)` in a deck reach it. That rule would
/// otherwise run on into every block of their contents and out over the
/// rounded corners, so it is put back inside, and this is what gets put back.
///
/// Not simply `none` and `0pt`. Everything Typst reports here is *partial*,
/// and a partial value folds into the one it is set inside instead of
/// replacing it. Three shapes of that, all measured on a deck that carries no
/// label at all.
///
/// An unset `stroke` or `radius` comes back as an *empty dictionary*, and
/// setting that again changes nothing: that is how the callout's left bar
/// first ended up beside every line of its own text. It becomes `none` and
/// `0pt` by hand.
///
/// A dictionary names only the sides it was given, so `stroke: (left: green)`
/// would leave the box's own border on the other three. The missing sides and
/// corners are filled in.
///
/// And a stroke keeps `auto` for what it does not name: `stroke: red` inside
/// the card's `0.7pt + border` drew 0.7pt red instead of 1pt red. That is what
/// `fester-strich` is for.
///
/// Must be called inside a context.
#let umgebungs-block() = {
  let leer(v) = type(v) == dictionary and v.len() == 0
  let voll(v, seiten, fehlt) = if type(v) != dictionary { v } else {
    seiten.map(k => (k, v.at(k, default: fehlt))).to-dict()
  }
  (
    fill: block.fill,
    stroke: if leer(block.stroke) { none } else {
      fester-strich(voll(block.stroke, ("top", "right", "bottom", "left"), none))
    },
    radius: if leer(block.radius) { 0pt } else {
      voll(block.radius,
           ("top-left", "top-right", "bottom-left", "bottom-right"), 0pt)
    },
  )
}

/// The height of the row a box is currently standing in, or `none`.
///
/// `side-by-side(equal: true)` measures its columns, fixes the largest
/// height and records it here; `card` and `callout` read it and then fill
/// their cell. There is no way around this detour: a `height: 100%` inside
/// the box resolves against the *region*, not against the grid row, and
/// would therefore be slide-high instead of row-high. Verified: two boxes
/// with `height: 100%` in a grid with `rows: auto` both came out 250 pixels
/// tall on a 278-pixel-tall page. Only an explicitly set row height turns
/// `100%` into the row.
#let zeilen-hoehe = state("typstage-zeile", none)

/// The running step cursor: the highest step handed out on this slide so far.
///
/// A counter, not a state, and that is the whole trick. Reading a state and
/// writing to it in the same place is circular and never settles; a counter is
/// built for exactly this and converges.
#let step-cursor = counter("typstage-step")

/// Which slide we are on. Only used to scope things that a companion package
/// looks up across the whole document. A query sees every slide at once and
/// has to be able to tell them apart.
#let slide-counter = counter("typstage-slide")

/// A name, however it was written.
///
/// Names identify things across slides: a morph that flies, a frame that
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
/// `auto` is *not* resolved here. It needs the cursor and hence a context.
#let selector(at) = {
  if type(at) == int { str(at) + "-" }
  else if type(at) == array {
    at.map(x => if type(x) == int { str(x) } else { x }).join(",")
  } else { at }
}

/// A tracked element: holds its place in the background, paints its marker and
/// registers itself for the overlay.
///
/// In paged output none of this applies. There is no overlay and there are no
/// steps, so the element simply stands where Typst puts it.
/// `width` decides how wide the tracked element becomes.
///
/// - `auto`: as wide as its content. Right for inline things: a morphing
///   glyph should not claim the whole line.
/// - a length: that width. Block elements default to the full available
///   width, because that is what a block *is*: without it an `align(center,
///   …)` inside `anim` has no room to centre in and silently stays left.
/// Does the body carry an `fr` spacer at its top level?
///
/// `fr` means "share of what is left over", and what is left over is
/// distributed by the parent among the siblings. A tracked element, though,
/// is measured on its own, and `measure` does not see the siblings.
/// Therefore an `fr` that applies *to the element itself* cannot be resolved
/// here as a matter of principle; an `fr` further inside (say
/// `grid(rows: (1fr, 1fr))`) is not affected by this, because it distributes
/// the grid among itself.
#let fr-teile(body) = {
  let teile = if body == none { () }
              else if body.has("children") { body.children } else { (body,) }
  teile.filter(c => c.func() in (v, h) and type(c.amount) == fraction)
}

/// Does the body consist *only* of such spacers (and empty space)?
#let nur-fr(body) = {
  let teile = if body == none { () }
              else if body.has("children") { body.children } else { (body,) }
  let leer = [ ].func()
  teile.len() > 0 and teile.all(c =>
    (c.func() in (v, h) and type(c.amount) == fraction)
    or c.func() in (leer, parbreak))
}

/// Does the body want to fill the offered width?
///
/// The difference cannot be measured: `measure(align(center, rect(80pt)),
/// width: 400pt)` returns 80pt, not 400. A block equation does the same.
/// Both need the full space regardless, or the `align` has no room to
/// center in and the equation has no middle.
///
/// So this does not measure, it looks. A few levels deep, since
/// `text(…)[$ x $]` wraps the equation in a `styled` with `child`, and a
/// paragraph in a `sequence` with `children`: the top level rarely holds
/// what matters.
///
/// Two things depend on this: whether a tracked element in an `auto` grid
/// column pulls the whole width to itself (and thereby pushes the `1fr`
/// neighbour column to zero), and whether frame and region must be the same
/// width so the body does not land next to its marker.
#let will-fuellen(body, tiefe: 4) = {
  if body == none or tiefe <= 0 { return false }
  let f = body.func()
  if f == align { return true }
  if f == math.equation and body.at("block", default: false) { return true }
  if body.has("child") { return will-fuellen(body.child, tiefe: tiefe - 1) }
  if body.has("children") {
    return body.children.any(c => will-fuellen(c, tiefe: tiefe - 1))
  }
  false
}

#let track(kind, body, at: "1-", extra: (:), raw-frames: none, inline: false,
           width: auto) = {
  // The `box` has to sit around the *whole* construction, not inside it:
  // `layout()` is block-level, so an inline element that only chooses a `box`
  // further in would still break the line it sits in.
  let shell-outer = if inline { box } else { it => it }
  shell-outer(context {
  // A pure `fr` spacer is passed through instead of tracked. Measured it
  // would come out as the full remaining height and push the siblings out
  // of the slide (verified: 86% instead of 76%). Passed through, the parent
  // distributes it correctly, and there is nothing to animate in empty
  // space anyway, so nothing is lost. The step is not consumed either: it
  // would otherwise stay empty.
  if nur-fr(body) { return body }
  // Mixed content cannot be saved: the spacer belongs to the parent, the
  // rest to the element. Better a clear error than a slide where something
  // silently shifts out of place.
  assert(fr-teile(body).len() == 0, message:
    "typstage: an fr spacer inside a tracked element cannot be resolved. "
    + "fr is shared out by the parent among its siblings, and a tracked "
    + "element is measured on its own. Put the fr outside the anim/stagger, "
    + "or give the element a container with a known size.")
  if not html-output.get() { return body }
  element-counter.step()
  // `auto` takes the next step. An explicit selector pulls the cursor up to its
  // own highest step, so whatever follows carries on after it instead of
  // starting over.
  //
  // Only reveals count. An applet, a video or a morph does not consume a step
  // (they are there from the start), and above all they must not push the
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
      // layout. Otherwise a `width: 100%` inside the free frame would come to
      // nothing and boxes would lose their area.
      let room = if width == auto { available.width } else { width }
      // Measured twice, and the larger one counts. Both measurements are
      // needed, but for different reasons:
      //
      // *With* a height reference is the only thing that resolves
      // `height: 100%` and `1fr` inside the body at all. Without it there is
      // nothing for a percentage to count against, and the element collapses
      // to 0pt. Measured: in 12 of 34 tracked elements of a test deck.
      //
      // *Without* a height reference determines the **position**, not the
      // size. Overflow is drawn outside the SVG box anyway, so the
      // dimensions stay the same; but with the capped height, something
      // like `side-by-side` (defaulting to `horizon`) aligns the element on
      // the wrong middle. Measured: up to 84 percentage points of offset,
      // `lorem(200)` slid entirely off the slide.
      //
      // If the height is unbounded, the second measurement returns 0 and
      // the maximum falls back to the first.
      let natural = measure(body, width: room)
      let bounded = measure(body, width: room, height: available.height)
      let m = (
        width: calc.max(natural.width, bounded.width),
        height: calc.max(natural.height, bounded.height),
      )
      // What holds here has to be set again in the sprite: its own frame does
      // not know the slide's `set` rules.
      // The sprite is set in its own frame and does not know the slide's
      // `set` rules. What determines the line break and the height
      // therefore has to travel along, or it will not fill its measured
      // frame: with `#set par(leading: 2em)` the background measured 63pt,
      // the sprite came out at 37pt with default leading and stuck to the
      // top.
      let style = (
        size: text.size, fill: text.fill, font: text.font,
        weight: text.weight, style: text.style, lang: text.lang,
        tracking: text.tracking, spacing: text.spacing,
        leading: par.leading, par-spacing: par.spacing,
        justify: par.justify, first-line-indent: par.first-line-indent,
        hanging-indent: par.hanging-indent,
      )
      // Only what *wants* to fill gets the full space. Everything else
      // stays as wide as its content, or a tracked element in an `auto`
      // grid column pulls the whole width to itself and pushes the `1fr`
      // neighbour column to zero.
      let fuellt = will-fuellen(body)
      let w = if inline or width != auto { m.width }
              else if fuellt { room }
              else { m.width }
      // An element without an area (a line measures 0pt tall, its stroke
      // sits outside the box) gets a marker without an area, and the
      // runtime skips that (`if (!r.width && !r.height) return;`). The
      // sprite would never be positioned and would stay invisible. Marker
      // and sprite therefore get breathing room on every side. It sits in
      // `place`, so it changes nothing about the flow: the line stays as
      // tall as it would without `anim`.
      //
      // The measure is estimated, not measured: the stroke width of a line
      // cannot be measured in Typst. A font's height covers any common
      // stroke width; anything thicker is a drawing and normally brings its
      // own box along.
      let luft = if m.height == 0pt or m.width == 0pt { text.size } else { 0pt }
      // The *original* region travels along. Without it, the body sits in
      // the sprite inside a wrapper of the measured size, and a relative
      // measure resolves there a second time: `p%` becomes `p²%`. Only
      // `100%` is a fixed point, which is why this went unnoticed for a
      // long time; `height: 50%` came out as 25%, `morph` with
      // `width: 60%` as 36%.
      // The height is always the real region, so `height: 50%` resolves
      // against the correct reference. For the width it depends on whether
      // the body centers itself:
      //
      // - If it does, frame and region must be the same width. Otherwise it
      //   centers itself in the wider region and is drawn next to its
      //   marker: measured at 293pt off, exactly half the difference.
      // - If it does not, it stands to the left and so sits inside the
      //   frame; then the region may have the full width, and `width: 50%`
      //   resolves correctly instead of coming out as 25%.
      let region = (
        width: if fuellt { w } else { room },
        height: if available.height == float("inf") { auto } else { available.height },
      )
      sprites.update(a => a + ((kind: kind, at: selected, extra: extra, body: body,
                                raw-frames: raw-frames, width: w,
                                height: m.height, region: region, pad: luft,
                                style: style),))
      // A `box` is inline and puts its baseline on the bottom edge, and with a
      // two-line list item the bullet would drop a line. Block content gets a
      // `block`.
      let shell = if inline { box } else { block }
      shell(width: w, height: m.height, {
        place(top + left, dx: -luft, dy: -luft,
              rect(width: w + 2 * luft, height: m.height + 2 * luft,
                   fill: marker(n), stroke: none))
        // `hide` lays out but does not draw: the space is right, the content
        // is only visible in the overlay.
        // Same region as during measuring: otherwise a relative measure
        // here resolves against the wrapper instead of the real container,
        // and the marker reserves a different height than the sprite fills
        // later.
        place(top + left, hide(block(
          width: region.width,
          height: if available.height == float("inf") { auto } else { available.height },
          body)))
      })
    })
  }
  })
}
