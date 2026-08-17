// Handbuch und Website in einem Lauf:
//
//   typst compile docs.typ build --format bundle --features bundle,html --root /
//
// Der Inhalt steht in `content.typ` und ist für beide Ausgaben derselbe.

#import "@schule/schuldocs:0.2.0": *

#let pkg = toml("../typst.toml")

#show: docs.with(
  toml: pkg,
  authors: pkg.package.authors,
  abstract: [
    `typstage` setzt Präsentationen mit Typst und bewegt sie im Browser. Jede
    Folie wird als SVG gesetzt — die Anordnung ist deshalb dieselbe wie im PDF —,
    und was sich bewegen soll, wird angemeldet: Einblendungen, Magic Move,
    Folienübergänge, Medien. Aus derselben Quelle entstehen eine animierte
    HTML-Präsentation, ein Foliensatz als PDF und ein Handout zum Mitschreiben.
  ],
  links: (
    (name: "GitHub", url: "https://github.com/Loewe1000/Typst-Schule"),
  ),
  notices: ([Teil des Schule-Typst-Ökosystems],),
)

#include "content.typ"
