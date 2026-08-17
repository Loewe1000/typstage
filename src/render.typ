// Turning tracked elements into HTML.

#import "config.typ": *
#import "theme.typ": with-style

/// One sprite: the element as its own small frame, plus everything the runtime
/// needs to know about it as data attributes.
#let sprite-markup(s, n, template) = {
  let attrs = (class: "ts-el ts-" + s.kind, "data-n": str(n), "data-at": s.at)
  for (k, v) in s.extra {
    if v != none and v != auto {
      attrs.insert("data-" + k,
        if type(v) == bool { if v { "1" } else { "0" } } else { str(v) })
    }
  }
  if s.kind == "video" {
    let a = (src: s.extra.src, preload: "auto", playsinline: "")
    if s.extra.muted { a.insert("muted", "") }
    if s.extra.loop { a.insert("loop", "") }
    if s.extra.controls { a.insert("controls", "") }
    html.elem("div", attrs: attrs, html.elem("video", attrs: a, []))
  } else if s.kind == "embed" {
    let a = (frameborder: "0", sandbox: "allow-scripts allow-same-origin")
    if s.extra.url != none { a.insert("src", s.extra.url) }
    if s.extra.doc != none { a.insert("srcdoc", s.extra.doc) }
    // A bridged frame is marked so the runtime finds it and can post the jobs
    // of the current step into it.
    // Nur die Abwahl muss übertragen werden; zoomen ist die Vorgabe.
    if s.extra.at("zoom", default: true) == false {
      attrs.insert("data-zoom", "0")
    }
    if s.extra.at("bridge", default: none) != none {
      attrs.insert("data-bridge", s.extra.bridge)
      attrs.insert("class", "ts-el ts-embed ts-bridged")
    }
    html.elem("div", attrs: attrs, html.elem("iframe", attrs: a, []))
  } else if s.kind == "flipbook" {
    html.elem("div", attrs: attrs + ("data-frames": str(s.raw-frames.len())),
      s.raw-frames.map(f => html.elem("div", attrs: (class: "ts-frame"),
        html.frame(block(width: s.width, height: s.height,
                         template(with-style(s, f)))))).join())
  } else {
    html.elem("div", attrs: attrs, {
      // The counter is set to this element's own number before the content is
      // laid out a second time. Nested elements then count on exactly as they
      // did in the background — the numbering is a pre-order, its children
      // carry n+1, n+2, … Only that way does the browser find again the marker
      // of an element that vanished into its parent's `hide()`.
      counter("typstage-n").update(n)
      html.frame(block(width: s.width, height: s.height,
                       template(with-style(s, s.body))))
    })
  }
}

/// How CSS and JavaScript get into the page.
///
/// - `"inline"` — both sit in the HTML. One file, nothing beside it, nothing
///   to fetch. This is the default.
/// - `"split"` — the HTML points at `typstage-<version>.css` and `.js` next to
///   it. Write both out from `runtime-files`.
/// - `(cdn: "https://…")` — the same file names under the given address. Then
///   nothing is created beside the HTML.
#let asset-links(assets) = {
  let base = if type(assets) == dictionary and "cdn" in assets {
    assets.cdn.trim("/") + "/"
  } else { "" }
  (
    css: html.elem("link", attrs: (rel: "stylesheet",
                                   href: base + asset-name("css"))),
    js: html.elem("script", attrs: (src: base + asset-name("js")), ""),
  )
}
