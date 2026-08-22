// Video, embedded documents and Typst-drawn animation — plus what takes their
// place on paper.

#import "internal.typ": (track, bridge-jobs, html-output, name-of,
                         slide-counter)

/// The box that stands in for a moving element in the PDF.
///
/// `fallback` is arbitrary content — a CeTZ drawing, an image, a table. Left
/// out, a labelled placeholder remains. `link` goes underneath and is
/// clickable in the PDF: whoever holds the handout gets to the live thing.
#let fallback-box(fallback, link-target, width, height, label) = block(
  width: width, height: height, {
    let main = if link-target == none { 100% } else { 88% }
    if fallback != none {
      block(width: 100%, height: main, align(center + horizon, fallback))
    } else {
      block(width: 100%, height: main, fill: luma(95%),
            stroke: 0.5pt + luma(80%), radius: 4pt,
            align(center + horizon, text(size: 0.75em, fill: luma(45%), label)))
    }
    if link-target != none {
      align(center, text(size: 0.62em, fill: luma(45%),
                         link(link-target, link-target)))
    }
  },
)

/// A real HTML5 video over the slide.
#let video(
  src,
  width: 100%,
  height: 200pt,
  poster: none,
  autoplay: true,
  loop: false,
  muted: true,
  controls: false,
  radius: 0pt,
  at: "1-",
  enter: "fade",
) = track(
  "video",
  box(width: width, height: height, clip: true, radius: radius,
      if poster == none { rect(width: 100%, height: 100%, fill: luma(92%)) } else {
        { set image(width: 100%, height: 100%, fit: "cover"); poster }
      }),
  at: at,
  extra: (src: src, autoplay: autoplay, loop: loop, muted: muted,
          controls: controls, radius: radius.pt(), enter: enter),
)

// Was jedem eingebetteten Dokument vorangestellt wird, damit es sich wie ein
// Teil der Folie verhält statt wie eine Webseite in einem Loch.
//
// Zwei Zeilen, ohne die `height: 100%` im Dokument ins Leere greift: ein
// Prozentmaß braucht eine Höhe am Elternteil, und `body` hat von Haus aus
// keine. Der Rahmen ist dann so hoch wie sein Inhalt und klebt oben in der
// Box — der Rest der angegebenen Höhe bleibt leer.
//
// Und die Schriftgröße: in einem gezoomten Rahmen ist ein CSS-Pixel genau ein
// Punkt der Folie, dafür sorgt der Zoom des Runtimes. Also trägt die
// Grundschrift dieselbe Zahl wie die des Vortrags, und alles, was darin in
// `em` bemaßt ist, wächst mit den Folien mit. Ohne Zoom spannt der Rahmen
// echte Bildschirmpixel auf — dann wäre dieselbe Zahl willkürlich, und es
// bleibt bei der des Browsers.
//
// Alles steht *vor* dem Dokument, damit dessen eigenes `<style>` gewinnt.
#let grundstil(doc, zoom, an) = {
  if doc == none or not an { return doc }
  let regeln = (
    "html,body{height:100%;margin:0}",
    "body{background:transparent}",
  )
  if zoom {
    let farbe = if type(text.fill) == color { text.fill.to-hex() } else { "inherit" }
    // `text.font` ist mal eine Zeichenkette, mal eine Liste — beides kommt vor.
    let familien = if type(text.font) == str { (text.font,) } else { text.font }
    let stapel = familien.map(f => "\"" + f + "\"") + ("system-ui", "sans-serif")
    regeln.push("body{font-family:" + stapel.join(",")
                + ";font-size:" + str(calc.round(text.size.pt(), digits: 2)) + "px"
                + ";line-height:1.4;color:" + farbe + "}")
  }
  "<style>" + regeln.join("") + "</style>" + doc
}

/// Arbitrary web content in a sandboxed frame.
///
/// `bridge` names the element so step jobs can be sent to it — that is how a
/// companion package such as `typstage-geogebra` drives its applet without the
/// core knowing anything about it.
///
/// `fallback` and `link` only take effect in paged output; in the browser the
/// embedded document itself stands there.
///
/// `style` gives a document passed as `html` the deck's basic style: it fills
/// the frame, is transparent, and carries the running text size. Switched off,
/// the frame is a blank browser page again.
#let embed(
  url: none,
  html: none,
  width: 100%,
  height: 200pt,
  at: "1-",
  enter: "fade",
  bridge: none,
  zoom: true,
  style: true,
  fallback: none,
  link: none,
  label: [Embedded content],
) = {
  // Announced for the whole document, not just for what comes after it: a
  // companion package resolving `target: auto` has to find an applet that is
  // written *below* its own commands as well.
  let bridge = if bridge == none { none } else { name-of(bridge) }
  if bridge != none {
    context [#metadata((
      slide: slide-counter.get().first(), name: bridge,
    ))<typstage-bridge-target>]
  }
  context if not html-output.get() {
  fallback-box(fallback, if link != none { link } else { url }, width, height, label)
} else {
  track(
    "embed",
    box(width: width, height: height, fill: luma(92%)),
    at: at,
    extra: (url: url, doc: grundstil(html, zoom, style), enter: enter,
            bridge: bridge, zoom: zoom),
  )
}
}

/// Animation drawn by Typst, frame by frame.
///
/// `render` receives `t` running from 0.0 to 1.0. Every frame is rendered by
/// Typst — CeTZ, Fletcher, equations, anything Typst can do. The frames sit in
/// the file as SVG and stay sharp at any size.
#let flipbook(
  render,
  frames: 24,
  fps: 30,
  width: 200pt,
  height: 150pt,
  loop: true,
  pingpong: false,
  at: "1-",
  enter: "fade",
  still: auto,
) = context if not html-output.get() {
  // On paper a single frame has to do. `still` picks which one.
  block(width: width, height: height,
        if still == auto { render(0.0) } else { still })
} else {
  track(
    "flipbook",
    box(width: width, height: height, clip: true, render(0.0)),
    at: at,
    extra: (fps: fps, loop: loop, pingpong: pingpong, enter: enter),
    // Wie `t` über die Bilder verteilt wird, hängt am Abspielmodus:
    //
    // Beim reinen Schleifen ist `t = 1` derselbe Zustand wie `t = 0` — eine
    // Bewegung, die sich schließt, ist nach einer vollen Runde wieder am
    // Anfang. Das letzte Bild wäre also eine Kopie des ersten, und in der
    // Schleife stünde dasselbe Bild zwei Bilder lang. Nachgemessen am
    // wandernden Mäander: Bild 0 und Bild 29 waren pixelgleich, Bild 28 wich um
    // 7% ab. Deshalb `i / frames` — das letzte Bild liegt knapp *vor* dem
    // Rundenschluss.
    //
    // Bei `pingpong` ist `t = 1` dagegen der Wendepunkt und gehört dazu, ebenso
    // beim einmaligen Abspielen, wo es der Endzustand ist.
    raw-frames: range(frames).map(i => box(
      width: width, height: height, clip: true,
      render(if frames <= 1 { 0.0 }
             else if loop and not pingpong { i / frames }
             else { i / (frames - 1) }),
    )),
  )
}
