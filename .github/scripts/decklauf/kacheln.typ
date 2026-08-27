// Ob `tiles` seine Kurve und seine Dauer weiterreicht.
//
// Beides nahm es lange gar nicht entgegen. Ein Deck, das ein Raster langsamer
// oder mit Rückschwung wollte, musste das Raster verlassen und die `anim`s von
// Hand in ein `grid` schreiben -- genau die Arbeit, die `tiles` abnehmen soll.
//
// Zwei Folien, weil zwei Dinge schiefgehen können. Mit Angabe muss jede der
// sechs Kacheln beide Werte tragen; ohne Angabe darf keine sie tragen, sonst
// bekäme jedes Deck von gestern zwei neue Attribute je Kachel und sein Satz
// verschöbe sich, ohne dass jemand etwas geändert hätte.
//
// Geprüft wird in `pruefe-decks.js`, `kachelProbe`, an der HTML-Ausgabe und
// ohne Browser: was hier zu sehen ist, entsteht in Typst.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Kacheln mit Kurve],
  author: [typstage #runtime-version],
  duration: 200,
)

== Sechs Kacheln, eine Kurve

#tiles(columns: 3, duration: 1500, easing: "out-back",
  [eins], [zwei], [drei], [vier], [fünf], [sechs])

== Und dieselben ohne Angabe

#tiles(columns: 3, [eins], [zwei], [drei])
