// Zwei Elemente, die im Fluss nichts messen, und die trotzdem stehen müssen.
//
// Beide sind einmal still verschwunden, und beide auf demselben Weg: die Marke
// bekam keine Ausdehnung oder keinen Ort, die Hülle im Browser bekam daraus
// `width: 0%`, und ein Ansichtsfenster der Breite null skaliert seinen Inhalt
// unter `xMidYMid meet` mit dem Faktor null. Im PDF stand das Element, im
// Browser fehlte es, und `typstage.pruef.fehler()` blieb leer.
//
// *Die senkrechte Linie.* Sie misst nicht null breit, sondern 4,898587e-15 pt:
// der Kosinus von 90° ist in Gleitkomma nicht sauber null. Ein Vergleich auf
// `== 0pt` sagte deshalb nein, das Element bekam keine Luft um seine Marke,
// und die Marke wurde null breit. Die waagerechte Linie daneben steht hier als
// Gegenprobe: sie misst exakt 0pt hoch, bekam ihre Luft immer und war nie
// betroffen. Genau dieses Nebeneinander zeigte den Fehler an.
//
// *Die drei gesetzten Rechtecke.* `place` steht außerhalb des Flusses, ist
// gemessen 0x0, und `dx`/`dy` stehen in keinem Maß, das `measure` hergäbe. Das
// verfolgte Element bekam darum eine Marke am Ort des Flusses statt am Ort des
// Inhalts -- und je eine eigene Zeile dazu. Auf Papier standen die drei
// nebeneinander, im Browser liefen sie eine Treppe hinunter.
//
// Geprüft wird in `pruefe-decks.js`, `schmalProbe`: keine Hülle ohne
// Ausdehnung, die drei gesetzten auf einer Höhe und in gleichem Abstand, und
// die Fehlerliste der Laufzeit leer.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Was im Fluss nichts misst],
  author: [typstage #runtime-version],
  duration: 200,
)

== Eine Linie quer und eine hochkant

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  anim(at: 2, line(length: 80pt, stroke: 2pt + blue)),
  anim(at: 2, line(angle: 90deg, length: 80pt, stroke: 2pt + blue)),
)

== Ein gesetztes ohne Ausrichtung

// Eine nicht genannte Ausrichtung ist nicht dasselbe wie `auto`: dieses `place`
// übersetzt anstandslos, dasselbe mit einem hingeschriebenen `auto` bricht ab,
// denn `auto` gibt es nur für ein Gleitobjekt. Beim Hinausheben ist das der
// Unterschied zwischen einem Deck und einer Fehlermeldung, und schon einmal war
// es letzteres.

#block(width: 100%, height: 100pt,
  anim(at: 2, place(dx: 60pt, dy: 30pt,
                    rect(width: 20pt, height: 20pt, fill: orange))))

== Drei gesetzte Rechtecke

#block(width: 100%, height: 200pt, {
  anim(at: 2, place(top + left, dx: 20pt, dy: 40pt,
                    rect(width: 20pt, height: 20pt, fill: red)))
  anim(at: 2, place(top + left, dx: 100pt, dy: 40pt,
                    rect(width: 20pt, height: 20pt, fill: green)))
  anim(at: 2, place(top + left, dx: 180pt, dy: 40pt,
                    rect(width: 20pt, height: 20pt, fill: blue)))
})
