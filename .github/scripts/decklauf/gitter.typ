// Gegenprobe zu `split-body`: dieselbe Tabelle, vier Verpackungen.
//
// `pruefe-decks.js` übersetzt dieses Deck und zählt je Folie die gestrichenen
// Pfade im Hintergrund-SVG. Alle vier Folien müssen dieselbe Zahl nennen --
// eine Tabelle behält ihre Striche, egal was um sie herum steht.
//
// Warum es das braucht: `split-body` zerlegte den Rumpf einer Folie an seinem
// `children`-Feld, und `table`, `grid`, `list` und `stack` führen so ein Feld
// genauso wie eine Sequenz. Getroffen hat es den Weg durch `styled`, denn
// `text(fill: …, table(…))` reicht die Tabelle selbst als Kind herunter: die
// Zellen wurden zu Geschwistern, wieder zusammengeklebt, und heraus kam ein
// Fließabsatz ohne einen einzigen Strich. Gemessen, vier Fassungen derselben
// Folie: roh 6 Striche, Inhaltsblock 6, box 6 -- text() 0.
//
// Die Probe vergleicht die Folien miteinander und nicht gegen eine feste
// Zahl. Was das Thema selbst an Strichen zieht, steht auf allen vieren gleich
// und fällt so heraus; die Zahl hängt damit an keiner Schrift und an keinem
// Rechner.
//
// Die Kopfzeile steht mit Absicht dabei. `table.header` war der zweite Beleg:
// in der zerlegten Fassung meldete typst „header was ignored during paged
// export", in den drei heilen nicht. Wer den Kopf hier herausnimmt, nimmt
// diesen Zeugen mit.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(theme: themes.lesson)

#let probe = table(
  columns: 2, stroke: 1pt,
  table.header([Spalte], [Wert]),
  [a], [1],
  [b], [2],
)

== Roh
#probe

== In text
#text(fill: red, probe)

== Im Inhaltsblock
#[
  #set text(fill: red)
  #probe
]

== In einer box
#box(text(fill: red, probe))
