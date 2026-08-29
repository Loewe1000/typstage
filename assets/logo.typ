// Das Zeichen des Pakets, von Typst gesetzt — so wie alles andere auch.
//
//   typst compile assets/logo.typ assets/logo.svg
//   typst compile assets/logo.typ assets/logo.png --ppi 192
//
// Was es zeigt: den Magic Move. Das ist das eine, was typstage kann und ein
// Foliensatz nicht — also steht es im Zeichen. Ein Quadrat ist angekommen,
// zwei blassere Stände liegen hinter ihm.
//
// Nichts hier ist nach Augenmaß gesetzt. Die Grundlinie des Wortes und seine
// Versalhöhe sind ausgerechnet, und die Marke hängt an beiden: die Unterkante
// des angekommenen Quadrats liegt *auf* der Grundlinie, seine Höhe *ist* die
// Versalhöhe. Die Geister bleiben ausdrücklich darüber — was unter die
// Grundlinie rutscht, liest sich als Versehen und nicht als Spur.
// Die Leinwand ist auf die Tinte zugeschnitten, mit 8 Punkt Luft ringsum.
// Gemessen an der Alphamaske der Ausgabe: die Tinte lag bei x 75 bis 639 und
// y 103,5 bis 202,5 auf einer Leinwand von 900 mal 250 -- 336 Punkte davon
// waren rechts nichts und 151 oben und unten. Ein Bild mit solchem Leerraum
// steht nirgends mittig, wo es mittig stehen soll, und schiebt im Kopf des
// Handbuchs die Version weit nach rechts.
#set page(width: 580pt, height: 115pt, margin: 0pt, fill: none)

#let dunkel = rgb("#23303f")
#let akzent = rgb("#eb5e28")

#let grund = 84.5pt
// 0,735 em ist die Versalhöhe von Avenir Next im Fettschnitt, an der
// gesetzten Zeile gemessen.
#let versal = 104pt * 0.735

#let s0 = versal
#place(dx: 41pt, dy: grund - s0,
       rect(width: s0, height: s0, radius: s0 * 0.235, fill: akzent))
#for i in (0, 1) {
  let s = s0 * (0.44 + i * 0.2)
  place(dx: 41pt - (2 - i) * 27pt - (s - s0) / 2,
        dy: grund - s0 + (2 - i) * 16pt,
        rect(width: s, height: s, radius: s * 0.235,
             fill: akzent.transparentize(100% - (17% + i * 19%))))
}

#place(dx: 147pt, dy: grund - versal,
       text(font: "Avenir Next", size: 104pt, weight: "bold", fill: dunkel,
            tracking: -2pt)[typstage])
