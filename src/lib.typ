// typstage — animated HTML presentations from a single Typst file, and a PDF
// handout from the same source.
//
// This file is the package's whole public surface. Everything else lives in
// the sibling modules and stays there: Typst has no `private`, and a leading
// underscore is only a convention, so the boundary is drawn here instead — by
// naming exactly what leaves the package.

#import "config.typ": (
  // Geometry and palette, so a deck can build on them.
  slide-width, slide-height, slide-margin,
  dark, accent, paper, muted,
  // Runtime version and the two files, for `assets: "split"` and CDNs.
  runtime-version, runtime-files,
)

#import "slides.typ": slide, section, title-slide, transition, speaker-note
#import "elements.typ": alternatives, anim, morph, pause, stagger, steps
#import "media.typ": video, embed, flipbook, fallback-box
#import "bridge.typ": bridge-job, bridge-targets
#import "present.typ": presentation
