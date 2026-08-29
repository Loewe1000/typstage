// The English manual, website and PDF in one run:
//
//   typst compile manual-en.typ build --format bundle --features bundle,html --root /
//
// A second entry point rather than a switch inside `docs.typ`: `docs()` is a
// show rule and emits exactly two documents, so one file cannot carry both
// languages. The content sits in `content-en.typ`; the German manual is
// `docs.typ` with `content.typ` and stays the one that `index.html` is built
// from.

#import "@schule/schuldocs:0.3.0": *

#let pkg = toml("../typst.toml")

// The template has a few words of its own, and they follow the document's
// language. Without this line an English manual would carry a German table of
// contents and German callout headings.
#set text(lang: "en")

#show: docs.with(
  // Wie beim deutschen Handbuch, aber in einen eigenen Ordner: beide tragen
  // dieselben Kapitelnamen, und `geogebra.html` gaebe es sonst zweimal.
  split: true,
  // Drei Ebenen -- aber nur fuer das Kapitel, auf dem man ist: das Verzeichnis
  // klappt auf, statt alles aufzuzaehlen. Dadurch ist wieder Platz fuer die
  // Unterabschnitte, und sie stehen dort, wo sie helfen.
  toc-depth: 3,
  ordner: "en/",
  // The description on the header comes from `typst.toml` and is German
  // there, because that is what Typst Universe shows. The English manual says
  // the same thing in its own language.
  toml: pkg.package + (
    description: "Animated HTML presentations from a single Typst file, and a "
      + "PDF handout from the same source. Typst typesets, the browser moves: "
      + "magic-move morphing, step-by-step reveals, slide transitions, media "
      + "and a speaker view in the same file.",
  ),
  authors: pkg.package.authors,
  html-name: "en.html",
  pdf-name: "typstage-en.pdf",
  abstract: [
    `typstage` typesets presentations with Typst and moves them in the browser.
    Every slide is set as SVG, so the arrangement is the one the PDF has, and
    whatever is meant to move is registered for it: reveals, magic move, slide
    transitions, media. One source yields an animated HTML talk, a slide deck
    as PDF, and a handout to write on.
  ],
  links: (
    (name: "GitHub", url: "https://github.com/Loewe1000/typstage"),
    (name: "Examples", url: "https://loewe1000.github.io/typstage/beispiele/"),
    // Absolute, not relative: the same entry stands on the title page of the
    // PDF, and there a path leads nowhere.
    (name: "Deutsch", url: "https://loewe1000.github.io/typstage/"),
  ),
  notices: ([Part of the Schule Typst ecosystem],),
)

#include "content-en.typ"
