// Sizes, colours and the runtime files.
//
// Everything here is data: nothing in this file produces output.

/// Version of the runtime. It goes into the asset file names so a CDN can hold
/// several releases side by side and no browser serves a stale one from cache.
#let runtime-version = "0.1.0"

/// Default slide geometry. 16:9 on an A4-width canvas, so a slide and a
/// handout page carry text at the same physical size. `presentation` takes
/// `width`, `height` and `margin` to override them.
#let slide-width = 841.89pt
#let slide-height = slide-width * 9 / 16
#let slide-margin = 32pt

/// Work out the canvas from what the deck asked for.
///
/// `scale` is the heart of it: everything the theme draws — header height,
/// type sizes, rules — is given in points of the default canvas and multiplied
/// by this. A deck at half the width then looks the same, only smaller,
/// instead of carrying a header built for a canvas twice its size.
///
/// Only the *ratio* really changes the layout, and that is the point: 4:3 is
/// `height: width * 3 / 4`.
#let canvas(width: auto, height: auto, margin: auto) = {
  let w = if width == auto { slide-width } else { width }
  let k = w / slide-width
  (
    width: w,
    height: if height == auto { w * 9 / 16 } else { height },
    margin: if margin == auto { slide-margin * k } else { margin },
    scale: k,
  )
}

/// The default palette. Override it by wrapping the presentation in your own
/// document template — see `style` on `presentation`.
#let dark = rgb("#23303f")
#let accent = rgb("#eb5e28")
#let paper = rgb("#fafafa")
#let muted = luma(45%)

/// The two runtime files, read at compile time so there is a single source of
/// truth: whether they are inlined, linked next to the HTML or fetched from a
/// CDN, it is always this text.
#let runtime-css = read("../assets/typstage-" + runtime-version + ".css")
#let runtime-js = read("../assets/typstage-" + runtime-version + ".js")

/// File name of an asset, carrying the version.
#let asset-name(extension) = "typstage-" + runtime-version + "." + extension

/// The runtime files, ready to be written next to the HTML.
///
/// Typst cannot create files. Whoever uses `assets: "split"` or a CDN writes
/// them out once — the content comes from here so the copies cannot drift.
#let runtime-files = (
  (name: asset-name("css"), content: runtime-css),
  (name: asset-name("js"), content: runtime-js),
)
