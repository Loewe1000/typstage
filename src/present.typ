// Building the deck: the same source into two targets.

#import "config.typ": *
#import "internal.typ": *
#import "slides.typ": *
#import "theme.typ": handout-body, slide-body, slide-chrome
#import "themes.typ": mit-palette, theme-state, themes
#import "palettes.typ": palette-pruefen
#import "render.typ": *
#import "elements.typ": anim, pause

/// Flatten a body into content pieces and pause markers.
///
/// `#set` in markup wraps everything after it, so a pause following one sits
/// *inside* that wrapper. Without descending into it not a single pause would
/// be found, and it would fail silently, which is the worst way to fail.
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
/// Every run becomes a block. A pause begins a new one, like a blank line.
/// That is not cosmetic: in the browser a tracked element is a block anyway,
/// while on paper it would flow on in the same paragraph. The same source has
/// to set the same way in both, so both are told to.
#let apply-pauses(body) = {
  if body == none { return body }
  let tokens = pause-tokens(body, x => x)
  // Nothing to do, and then the body is handed back untouched rather than
  // reassembled from its pieces.
  if not tokens.contains("pause") { return body }
  let runs = ()
  let current = ()
  for t in tokens {
    if t == "pause" { runs.push(current.join()); current = () }
    else { current.push(t) }
  }
  runs.push(current.join())
  // The first run stands unwrapped, every further run gets a wrapper.
  //
  // The wrapper is needed for the tracked runs: `anim` measures its content,
  // and a paragraph without a width shrinks to its ink. An `align(center, …)`
  // inside it would then have no room to center in and would stay flush
  // left, even though without the pause it sits centered. `width: 100%`
  // gives it the room back.
  //
  // The first run does not need this, since it sits unwrapped in the slide
  // body, which is as wide as the slide anyway. And it must not have it: a
  // `v(1fr)` inside it would then resolve against the *automatic* height of
  // this wrapper instead of against the slide, eat the whole body and push
  // everything after the first pause out of the slide. Silently: measured on
  // a sample with four slides, the PDF was missing every paragraph after the
  // first pause as soon as a `v(1fr)` appeared anywhere.
  //
  // Verified that the wrapper carries no weight here: all six example decks
  // give the same page count and the same text before and after, and a
  // sample with `align(center)` before a pause still centers unchanged.
  let out = runs.first()
  for (i, run) in runs.slice(1).enumerate() {
    out += anim(block(width: 100%, run), at: i + 2)
  }
  out
}

/// Split a document body at its headings into slides.
///
/// Two things make this harder than walking `body.children`.
///
/// *Rules wrap the rest of the document.* A `#set` or `#show` written after
/// the presentation's own show rule puts everything following it into a
/// `styled` element. The headings then sit one level deeper and the slides
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
/// … or as a show rule, and then the headings separate the slides:
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
/// `theme:` determines the whole look: colors, typeface, title bar,
/// footer, progress, title and section slide. Bundled are `themes.default`
/// (the default), `themes.lesson`, `themes.night`, `themes.plain` and
/// `themes.editorial`; each of them can be varied with
/// `themes.night + (accent: blue)`. The `style` hook stays untouched by this
/// and sits further *inside*: whatever is set there overrides the theme.
///
/// `palette:` changes the colors and leaves the design alone. It is a
/// dictionary over the eight color entries and it overwrites *partially*, so
/// `palette: (accent: blue)` moves the accent and nothing else. Five are
/// bundled, `palettes.light`, `palettes.mono`, `palettes.textbook`,
/// `palettes.parchment` and `palettes.dark`, and each of them composes with
/// each theme:
///
/// ```typ
/// #show: presentation.with(theme: themes.lesson, palette: palettes.dark)
/// ```
///
/// Two colors of a theme are not palette entries: `title-fill` and
/// `rule-fill`. All five bundled themes let them follow, either as a function
/// of the palette or as `none`, which means the accent and follows with it. A
/// theme of your own that names a fixed color there keeps it under every
/// palette, which is deliberate.
///
/// Both changed type with this: reading `themes.X.title-fill` used to give a
/// color and now gives a function, and `rule-fill` gives `none` where it gave
/// the accent. Writing them, `themes.X + (title-fill: red)`, is unchanged.
///
/// The PDF is a handout: one page per slide, every tracked element in its
/// final state. What belongs only to the motion, the notes, the slide transitions,
/// the bridge jobs, are state updates without output and fall away by themselves.
///
/// `overflow` is a checking pass over the deck, off by default. It measures
/// every slide body against the room the theme gives it and names the ones
/// that do not fit, with the earliest step on which the overrun can be on the
/// screen. Title and section slides are not measured: the theme draws them
/// with `place` and they have no body block.
///
/// - `"none"`: nothing is measured. The default.
/// - `"error"`: the whole deck is built, and it then stops with *every* place
///   at once rather than the first.
/// - `"record"`: it carries on and files a record per finding instead, for a
///   tool to read. The deck has to be on `"record"` for this; on `"error"`
///   the command below stops with the error too:
///
/// ```sh
/// typst eval --target html --features html --in deck.typ \
///   'query(<typstage-overflow>).map(e => e.value)'
/// ```
///
/// It is not meant to stay on while writing. Measured over the six example
/// decks: in HTML it costs noticeably more time, between 1.2 and 1.5 times
/// depending on the deck and on how the process start is accounted for. On
/// paper it costs a few milliseconds per deck, small but repeatable: there the
/// check runs without the step arithmetic.
///
/// Why a deck of slides needs this more than a document does: a slide goes
/// into an SVG frame of fixed size and is scaled in the browser, so what
/// sticks out is cut away or drawn beside the slide. A page one leafs through
/// shows an overrun; a talk one clicks through shows it at the projector.
#let presentation(
  ..slides,
  title: none,
  subtitle: [],
  author: [],
  date: none,
  assets: "inline",
  theme: themes.default,
  palette: (:),
  transition: "slide",
  transition-duration: 420,
  duration: 520,
  style: it => it,
  width: auto,
  height: auto,
  margin: auto,
  handout: false,
  overflow: "none",
) = {
  assert(overflow in ("none", "error", "record"), message:
    "typstage: overflow is \"none\" (the default), \"error\" or \"record\", "
    + "not " + repr(overflow))
  // 16:9 on an A4-width canvas unless told otherwise. 4:3 is
  // `width: 800pt, height: 600pt`; everything the theme draws scales along.
  let geo = canvas(width: width, height: height, margin: margin)
  let given = slides.pos()
  // A single piece of content means: this is the body of a show rule, and that
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
    // The marker is looked for in the body as it was written, before the
    // pauses cut it into runs: after that, a marker standing behind a pause
    // sits inside an `anim` wrapper and the walk would miss it. The title is
    // searched too, because in heading notation `== A slide #invert` is the
    // place the marker naturally lands, and it went unseen there.
    s + (invert: s.at("invert", default: false)
                 or hat-invert(s.body) or hat-invert(s.title),
         body: apply-pauses(s.body))
  })
  let total = all.filter(s => s.kind == "slide").len()

  // The theme with the palette laid over it, once for the deck and once
  // turned around. Both are worked out here rather than per slide: they are
  // the same two dictionaries on every slide, and the inverted one is only
  // ever reached for by a slide that asked for it.
  //
  // Both are built from the theme as it came in, not the inverted one from
  // the merged one. `mit-palette` resolves `title-fill` and `rule-fill` into
  // colors, so a theme that has already been through it no longer carries the
  // functions the inversion has to ask again.
  let palette = palette-pruefen(palette)
  let thema-hell = mit-palette(theme, palette)
  let thema-dunkel = mit-palette(theme, palette, invert: true)
  let thema(s) = if s.at("invert", default: false) { thema-dunkel } else { thema-hell }
  // Whether any slide inverts at all. A deck without one writes the theme
  // into its state exactly once, as before; only a deck that inverts pays for
  // an update per slide, and there it is needed, since a `card` reads its
  // tints out of that state and has to see the slide it stands on.
  let wechselt = all.any(s => s.at("invert", default: false))

  // Everything the deck knows about itself, one entry per slide, counted here
  // and nowhere else. All three outputs read from this list, and so does a
  // deck's own `info()`; that there is exactly one list is the whole reason a
  // hand-built footer cannot disagree with the built-in one.
  //
  // `nr` counts every slide, title and section slides included, and stays out
  // of the public dictionary: it is only the key under which a slide files its
  // step count. `slide.number` deliberately counts differently.
  let daten = {
    let kopf = all.find(s => s.kind == "title")
    if kopf != none {
      (title: kopf.title, subtitle: kopf.subtitle,
       author: kopf.author, date: kopf.date)
    } else {
      (title: title, subtitle: subtitle, author: author, date: date)
    }
  }
  let sect-total = all.filter(s => s.kind == "section").len()
  let facts = ()
  let gezaehlt = 0
  let kapitel = 0
  let kapitel-titel = none
  for (i, s) in all.enumerate() {
    if s.kind == "slide" { gezaehlt += 1 }
    if s.kind == "section" { kapitel += 1; kapitel-titel = s.title }
    facts.push((
      nr: i + 1,
      data: daten + (
        slide: (number: gezaehlt, total: total, numbered: s.kind == "slide"),
        section: (number: kapitel, total: sect-total, title: kapitel-titel),
      ),
    ))
  }

  // The branch has to enclose the *whole* build, not just the output: in
  // paged mode the module `html` does not even exist, so an `html.elem` in the
  // dead branch would already be an error.
  context if target() != "html" and handout != false {
    let per = if handout == true { 2 } else { handout }
    assert(type(per) == int and per >= 1 and per <= 6,
           message: "typstage: handout takes true or 1 to 6 slides per page")
    theme-state.update(thema-hell)
    html-output.update(false)
    handout-body(all, facts, style, geo, thema-hell, per,
                 thema: if wechselt { thema } else { none }, overflow: overflow)
    ueberlauf-bericht(overflow)
  } else if target() != "html" {
    set page(width: geo.width, height: geo.height, margin: 0pt)
    theme-state.update(thema-hell)
    // Said out loud, not left to the default. `bundle()` writes several
    // documents from one compilation, and a state carries on from one into the
    // next: without this the slide deck and the handout of a bundle were still
    // being built as if they were the browser's, and every tracked element
    // stayed in `hide()` and was missing from the PDF. Measured on a bundle
    // with an `anim` and an `alternatives`, and the same for the handout above.
    html-output.update(false)
    let pages = ()
    for (i, s) in all.enumerate() {
      pages.push(slide-counter.step()
                 + deck-info.update(facts.at(i))
                 // Nothing is revealed on paper, but the cursor counts here
                 // too, so that `info().step.total` reports the same number in
                 // both outputs. It has to start over on every slide.
                 + step-cursor.update(0)
                 // Nothing on a page sits inside a reveal, so the step being
                 // laid out is the first one. Said out loud for the sake of
                 // `bundle()`, where the browser document ran first and left
                 // its last value standing.
                 + step-here.update(())
                 + sprite-number.update(none)
                 + (if wechselt { theme-state.update(thema(s)) } else { none })
                 + slide-body(s, style, geo, thema(s), overflow: overflow))
    }
    pages.join(pagebreak(weak: true))
    ueberlauf-bericht(overflow)
  } else {
    html-output.update(true)
    theme-state.update(thema-hell)
    morph-index.update(())
    let parts = ()
    let chrome-teile = ()
    for (i, s) in all.enumerate() {
      let hier = facts.at(i)
      let here = hier.data.slide.number
      // Footer and progress come as their own layer above the stage, not
      // into the slide. Otherwise they would leave along with it on
      // transition, while the next one's comes in: two bars would be seen
      // crossing instead of one growing. Title and section slides carry
      // none; their entry stays empty so the count matches the slides.
      //
      // This layer is written out at the *end* of the document, long after
      // the slides. What the chrome reads therefore has to be put back in
      // front of each of its frames, or all of them would draw the numbers of
      // the last slide.
      chrome-teile.push(html.elem("div", attrs: (class: "ts-chrome"),
        if s.kind == "slide" {
          // The step is said out loud as well, even though the chrome prints
          // no step: chrome stands inside no reveal, so its step is the first
          // one. Without it the reading would hang off whatever the last
          // sprite of the last slide left standing, and that lengthens the
          // chain of things Typst has to settle for no gain. Measured on a
          // `bundle()`, where the chain then ran past five attempts and Typst
          // said "document did not converge".
          deck-info.update(hier)
          step-here.update(())
          sprite-number.update(none)
          html.frame(slide-chrome(geo, thema(s)))
        } else { [] }))
      parts.push({
        slide-counter.step()
        deck-info.update(hier)
        element-counter.update(0)
        step-cursor.update(0)
        step-here.update(())
        sprite-number.update(none)
        sprites.update(())
        bridge-jobs.update(())
        note-state.update(s.note)
        transition-state.update(s.at("transition", default: none))
        // Only a deck that inverts somewhere writes this per slide. A `card`
        // and a `callout` read their tints out of this state and would
        // otherwise light the slide they stand on as if it were not inverted.
        if wechselt { theme-state.update(thema(s)) }
        // Order is everything here: the frame has to come BEFORE the `context`
        // that reads the sprite list. Otherwise nothing that only registers
        // while the frame is laid out would be entered any more.
        html.elem("section", attrs: (class: "ts-slide"), {
          html.elem("div", attrs: (class: "ts-bg"),
                    html.frame(slide-body(s, style, geo, thema(s), chrome: false,
                                          overflow: overflow)))
          // Second chrome, only for the print view (key `p`). There each
          // slide stands on its own page, there is no transition. And the
          // layer above the stage cannot travel along there, because the
          // slides stand one below another. On screen this one stays
          // hidden.
          if s.kind == "slide" {
            html.elem("div", attrs: (class: "ts-chromep"), {
              step-here.update(())
              sprite-number.update(none)
              html.frame(slide-chrome(geo, thema(s)))
            })
          }
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
            // For the check at the end of the document, note which morphs
            // sit on this slide and whether they stand from step one.
            // Evaluate first, then record: inside the update function
            // `sprites.get()` would be outside any context and Typst aborts.
            let meine-morphs = sprites.get()
              .filter(sp => sp.kind == "morph")
              .map(sp => (slide: here, name: sp.extra.name,
                          ab-eins: ab-schritt-eins(sp.at)))
            morph-index.update(a => a + meine-morphs)
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
      html.elem("div", attrs: (id: "ts-chrome"), chrome-teile.join())
      html.elem("div", attrs: (id: "ts-fly"), [])
      // The ink layer, empty. Like the chrome layer it sits above the stage
      // and does not travel along on a slide change: what gets drawn on the
      // slide does not belong to the slide. It is filled at runtime, from
      // the speaker view.
      html.elem("div", attrs: (id: "ts-ink"), [])
    })
    // A delayed morph is not yet present on the first step of its slide.
    // That is harmless as long as the slide before it does not carry a morph
    // of the same name. Otherwise the flight between the two is lost, and
    // silently: there is no error message, the formula simply appears
    // instead of flying. Hence an announcement here at compile time.
    context {
      let alle-morphs = morph-index.get()
      for m in alle-morphs.filter(m => not m.ab-eins) {
        let vorher = alle-morphs.filter(v => v.slide == m.slide - 1 and v.name == m.name)
        assert(vorher.len() == 0, message:
          "typstage: morph(" + m.name + ") on slide " + str(m.slide)
          + " starts after step one, but the slide before carries a morph of "
          + "the same name. The flight between them would be lost without a "
          + "word. Either drop the `at:` here, or rename one of the two.")
      }
    }

    // Read back at the end of the deck, not at the first finding: whoever runs
    // the check before a talk wants the whole list in one go.
    ueberlauf-bericht(overflow)

    html.elem("div", attrs: (id: "ts-overview"), [])
    html.elem("div", attrs: (id: "ts-hint"), [])
    // The container of the speaker view, empty. The same file carries both
    // views; which one applies is decided by `#speaker` in the address, and
    // the runtime covers the stage with it.
    html.elem("div", attrs: (id: "ts-speaker"), [])
    let worte = runtime-words(text.lang)
    html.elem("script", attrs: (id: "ts-cfg", type: "application/json"),
      "{\"duration\":" + str(duration)
        + ",\"transition\":" + (if type(transition) == str {
            json.encode((kind: transition))
          } else { json.encode(transition) })
        + ",\"transitionDuration\":" + str(transition-duration)
        + ",\"width\":" + str(geo.width.pt())
        + ",\"height\":" + str(geo.height.pt())
        // The runtime displays two sentences itself. Which language is
        // decided by the slide's `text.lang`, not the runtime, which does
        // not know the document. English is the fallback.
        + ",\"words\":" + json.encode((
            noNote: worte.no-note,
            help: worte.help,
            helpSpeaker: worte.help-speaker,
            helpSpeakerShort: worte.help-speaker-short,
            sp: worte.sp,
          )) + "}")
    if assets == "inline" { html.elem("script", runtime-js) } else { links.js }
  }
}

/// All outputs in one run.
///
/// Since 0.15 Typst can write several files from one compilation. That fits
/// this package, since everything sits in one source anyway: the talk, the
/// slide deck and the handout differ only in target and in one setting.
/// Instead of compiling three times, once:
///
/// ```sh
/// typst compile --features bundle,html --format bundle talk.typ output
/// ```
///
/// ```typ
/// #bundle(
///   theme: themes.lesson,
///   title: [Completing the Square],
///   handout: "handout.pdf",
/// )[
///   = A section
///   == A slide
///   Text.
/// ]
/// ```
///
/// `html`, `slides` and `handout` are file names; `none` leaves out that
/// output. `per-sheet` is the number of slides per handout page. Everything
/// else goes to `presentation` unchanged.
///
/// Two things worth knowing. The bundle is explicitly experimental in Typst.
/// And a file that uses `bundle` can *only* be compiled with `--format
/// bundle`: `typst compile talk.typ talk.pdf` aborts with "constructing a
/// document is only supported in the bundle target". Anyone who wants both
/// writes the body into a `#let` and calls `presentation` by hand.
///
/// Verified: the counters start over for each output. The slide deck numbers
/// its slides 1, 2, 3 and does not continue counting where the HTML version
/// left off, even though Typst runs introspection across the whole bundle.
#let bundle(
  body,
  html: "talk.html",
  slides: "slides.pdf",
  handout: none,
  per-sheet: 3,
  ..args,
) = {
  assert(html != none or slides != none or handout != none,
         message: "typstage: bundle() wants at least one output")
  if html != none {
    document(html, { show: presentation.with(..args); body })
  }
  if slides != none {
    document(slides, { show: presentation.with(..args); body })
  }
  if handout != none {
    document(handout, { show: presentation.with(handout: per-sheet, ..args); body })
  }
}
