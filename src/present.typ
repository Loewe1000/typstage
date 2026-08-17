// Building the deck — the same source into two targets.

#import "config.typ": *
#import "internal.typ": *
#import "slides.typ": *
#import "theme.typ": handout-body, slide-body
#import "render.typ": *
#import "elements.typ": anim, pause

/// Flatten a body into content pieces and pause markers.
///
/// `#set` in markup wraps everything after it, so a pause following one sits
/// *inside* that wrapper. Without descending into it not a single pause would
/// be found — and it would fail silently, which is the worst way to fail.
///
/// The style is carried along and put back around each piece: as a style rule
/// that changes nothing about the layout, unlike wrapping in `anim`, which
/// would tear a list apart.
#let pause-tokens(body, restyle) = {
  let parts = if body.has("children") { body.children } else { (body,) }
  let out = ()
  for c in parts {
    let kind = repr(c.func())
    if c.func() == metadata and c.value == "typstage-pause" {
      out.push("pause")
    } else if kind == "styled" and c.has("child") {
      let maker = c.func()
      let inner = c.styles
      out += pause-tokens(c.child, x => restyle(maker(x, inner)))
    } else if kind == "sequence" and c.has("children") {
      out += pause-tokens(c, restyle)
    } else {
      out.push(restyle(c))
    }
  }
  out
}

/// Turn the pauses in a slide body into steps.
///
/// The first run stands from the start and stays untracked; every further run
/// becomes an `anim` on its own step. Written out as a number, not `auto`, so
/// a `stagger` further down carries on after the last pause.
///
/// Every run becomes a block — a pause begins a new one, like a blank line.
/// That is not cosmetic: in the browser a tracked element is a block anyway,
/// while on paper it would flow on in the same paragraph. The same source has
/// to set the same way in both, so both are told to.
#let apply-pauses(body) = {
  if body == none { return body }
  let tokens = pause-tokens(body, x => x)
  // Nothing to do — and then the body is handed back untouched rather than
  // reassembled from its pieces.
  if not tokens.contains("pause") { return body }
  let runs = ()
  let current = ()
  for t in tokens {
    if t == "pause" { runs.push(current.join()); current = () }
    else { current.push(t) }
  }
  runs.push(current.join())
  let out = block(runs.first())
  for (i, run) in runs.slice(1).enumerate() {
    out += anim(block(run), at: i + 2)
  }
  out
}

/// Split a document body at its headings into slides.
///
/// Two things make this harder than walking `body.children`.
///
/// *Rules wrap the rest of the document.* A `#set` or `#show` written after
/// the presentation's own show rule puts everything following it into a
/// `styled` element — the headings then sit one level deeper and the slides
/// vanish without a word. So `styled` is unpacked here and put back around
/// each *run* of content between two headings. Around each run, not around
/// each node: consecutive list items have to stay siblings inside the same
/// `styled`, or a three-point list falls apart into three one-point lists.
///
/// *Generated headings sit in a sequence.* Headings produced by a `#for` end
/// up in a nested `sequence`, which is unpacked the same way.
///
/// The one thing that cannot be carried across: a heading *inside* a `styled`
/// loses those styles, because it leaves the run. A `#set heading` after the
/// show rule therefore does not reach slide titles.
#let split-body(body, wrap) = {
  let parts = if body.has("children") { body.children } else { (body,) }
  let out = ()
  let run = ()
  for c in parts {
    let f = repr(c.func())
    let boundary = c.func() == heading or (f == "styled" and c.has("child")) or (
      f == "sequence" and c.has("children"))
    // A run of ordinary content ends at every boundary and is wrapped as one
    // piece. Typst closures cannot write to variables outside themselves, so
    // this is spelled out rather than put in a `flush()`.
    if boundary and run.len() > 0 {
      out.push((kind: "content", body: wrap(run.join())))
      run = ()
    }
    if c.func() == heading {
      out.push((kind: "heading", depth: c.depth, body: c.body))
    } else if f == "styled" and c.has("child") {
      let maker = c.func()
      let inner = c.styles
      out += split-body(c.child, x => wrap(maker(x, inner)))
    } else if f == "sequence" and c.has("children") {
      out += split-body(c, wrap)
    } else {
      run.push(c)
    }
  }
  if run.len() > 0 { out.push((kind: "content", body: wrap(run.join()))) }
  out
}

#let slides-from-body(body, title, subtitle, author, date) = {
  let out = ()
  if title != none {
    out.push(title-slide(title: title, subtitle: subtitle,
                         author: author, date: date))
  }
  let open = none
  for tok in split-body(body, x => x) {
    if tok.kind == "heading" {
      if open != none { out.push(open); open = none }
      if tok.depth == 1 { out.push(section(tok.body)) } else {
        open = (kind: "slide", title: tok.body, note: none,
                transition: none, body: [])
      }
    } else if open != none {
      open.body = open.body + tok.body
    }
    // Anything before the first heading belongs to no slide.
  }
  if open != none { out.push(open) }
  out
}

/// Build the deck.
///
/// Two notations, the same output. Either the slides as arguments:
///
/// ```typ
/// #presentation(title-slide(title: [Title]), section[Part], slide([First])[…])
/// ```
///
/// … or as a show rule — then the headings separate the slides:
///
/// ```typ
/// #show: presentation.with(title: [Title], transition: "slide")
/// = A section
/// == A slide
/// Content …
/// ```
///
/// Two targets, one source:
///
/// ```bash
/// typst compile deck.typ deck.html --format html --features html
/// typst compile deck.typ deck.pdf
/// ```
///
/// The PDF is a handout: one page per slide, every tracked element in its
/// final state. What belongs only to the motion — notes, slide transitions,
/// bridge jobs — are state updates without output and fall away by themselves.
#let presentation(
  ..slides,
  title: none,
  subtitle: [],
  author: [],
  date: none,
  assets: "inline",
  transition: "slide",
  transition-duration: 420,
  duration: 520,
  style: it => it,
  width: auto,
  height: auto,
  margin: auto,
  handout: false,
) = {
  // 16:9 on an A4-width canvas unless told otherwise. 4:3 is
  // `width: 800pt, height: 600pt`; everything the theme draws scales along.
  let geo = canvas(width: width, height: height, margin: margin)
  let given = slides.pos()
  // A single piece of content means: this is the body of a show rule — that
  // gets split at its headings.
  let all = if given.len() == 1 and type(given.at(0)) == content {
    slides-from-body(given.at(0), title, subtitle, author, date)
  } else {
    // The title belongs to the deck, not to one of the two notations. Whoever
    // hands slides as arguments used to lose it without a word.
    let rest = given.flatten()
    if title != none and rest.all(s => s.kind != "title") {
      let head = title-slide(title: title, subtitle: subtitle,
                             author: author, date: date)
      (head,) + rest
    } else { rest }
  }
  let all = all.map(s => if s.body == none { s } else {
    s + (body: apply-pauses(s.body))
  })
  let total = all.filter(s => s.kind == "slide").len()

  // The branch has to enclose the *whole* build, not just the output: in
  // paged mode the module `html` does not even exist, so an `html.elem` in the
  // dead branch would already be an error.
  context if target() != "html" and handout != false {
    let per = if handout == true { 2 } else { handout }
    assert(type(per) == int and per >= 1 and per <= 6,
           message: "typstage: handout takes true or 1 to 6 slides per page")
    handout-body(all, total, style, geo, per)
  } else if target() != "html" {
    set page(width: geo.width, height: geo.height, margin: 0pt)
    let n = 0
    let pages = ()
    for s in all {
      if s.kind == "slide" { n += 1 }
      pages.push(slide-counter.step() + slide-body(s, n, total, style, geo))
    }
    pages.join(pagebreak(weak: true))
  } else {
    html-output.update(true)
    let n = 0
    let parts = ()
    for s in all {
      if s.kind == "slide" { n += 1 }
      let here = n
      parts.push({
        slide-counter.step()
        element-counter.update(0)
        step-cursor.update(0)
        sprites.update(())
        bridge-jobs.update(())
        note-state.update(s.note)
        transition-state.update(s.at("transition", default: none))
        // Order is everything here: the frame has to come BEFORE the `context`
        // that reads the sprite list — otherwise nothing that only registers
        // while the frame is laid out would be entered any more.
        html.elem("section", attrs: (class: "ts-slide"), {
          html.elem("div", attrs: (class: "ts-bg"),
                    html.frame(slide-body(s, here, total, style, geo)))
          context {
            let tr = transition-state.get()
            let note = plain-text(note-state.get()).trim()
            html.elem("div", attrs: (class: "ts-ov")
              + (if tr != none {
                   ("data-transition": if type(tr) == str { tr } else { json.encode(tr) })
                 } else { (:) })
              + (if note != "" { ("data-note": note) } else { (:) }),
              sprites.get().enumerate()
                .map(((i, sp)) => sprite-markup(sp, i + 1, style)).join())
            html.elem("script", attrs: (class: "ts-bridge", type: "application/json"),
                      json.encode(bridge-jobs.get()))
          }
        })
      })
    }

    let links = asset-links(assets)
    if assets == "inline" { html.elem("style", runtime-css) } else { links.css }
    html.elem("div", attrs: (id: "ts-stage"), {
      parts.join()
      html.elem("div", attrs: (id: "ts-fly"), [])
    })
    html.elem("div", attrs: (id: "ts-overview"), [])
    html.elem("div", attrs: (id: "ts-hint"), [])
    html.elem("script", attrs: (id: "ts-cfg", type: "application/json"),
      "{\"duration\":" + str(duration)
        + ",\"transition\":" + (if type(transition) == str {
            json.encode((kind: transition))
          } else { json.encode(transition) })
        + ",\"transitionDuration\":" + str(transition-duration)
        + ",\"width\":" + str(geo.width.pt())
        + ",\"height\":" + str(geo.height.pt()) + "}")
    if assets == "inline" { html.elem("script", runtime-js) } else { links.js }
  }
}
