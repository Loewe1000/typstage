// Handbuch und Website in einem Lauf:
//
//   typst compile docs.typ build --format bundle --features bundle,html --root /
//
// Der Inhalt steht in `content.typ` und ist für beide Ausgaben derselbe.

#import "@schule/schuldocs:0.3.0": *

#let pkg = toml("../typst.toml")

// Die Sprache ausdrücklich. Typsts Vorgabe ist Englisch, und ohne diese Zeile
// trennte ein deutscher Text nach englischen Regeln, setzte englische
// Anführungszeichen und bekäme die englischen Wörter der Vorlage.
#set text(lang: "de")

#show: docs.with(
  toml: pkg,
  // Eine Seite je Kapitel statt einer Seite von 1,06 MB. Das Inhaltsverzeichnis
  // steht auf jeder davon vollstaendig da und fuehrt ueber die Dateigrenzen
  // hinweg; `alles.html` bleibt als eine Seite daneben liegen, fuer Strg-F und
  // zum Drucken. Das PDF entsteht unveraendert aus dem ungeteilten Koerper.
  //
  // Nur fuer das deutsche Handbuch. Das englische traegt dieselben
  // Kapitelnamen -- zweimal `geogebra.html` waere eine Kollision --, und ein
  // Unterverzeichnis dafuer hat `schuldocs` noch nicht.
  split: true,
  // Drei Ebenen -- aber nur fuer das Kapitel, auf dem man ist: das Verzeichnis
  // klappt auf, statt alles aufzuzaehlen. Dadurch ist wieder Platz fuer die
  // Unterabschnitte, und sie stehen dort, wo sie helfen.
  toc-depth: 3,
  authors: pkg.package.authors,
  abstract: [
    `typstage` setzt Präsentationen mit Typst und bewegt sie im Browser. Jede
    Folie wird als SVG gesetzt — die Anordnung ist deshalb dieselbe wie im PDF —,
    und was sich bewegen soll, wird angemeldet: Einblendungen, Magic Move,
    Folienübergänge, Medien. Aus derselben Quelle entstehen eine animierte
    HTML-Präsentation, ein Foliensatz als PDF und ein Handout zum Mitschreiben.
  ],
  links: (
    (name: "GitHub", url: "https://github.com/Loewe1000/typstage"),
    // Absolut, nicht relativ: derselbe Eintrag steht auch auf der Titelseite
    // des PDFs, und dort führt ein Pfad ins Leere.
    (name: "Beispiele", url: "https://loewe1000.github.io/typstage/beispiele/"),
    (name: "English", url: "https://loewe1000.github.io/typstage/en.html"),
  ),
  notices: ([Teil des Schule-Typst-Ökosystems],),
)

#include "content.typ"
