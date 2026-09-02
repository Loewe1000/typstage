// Gegenprobe zum Melder für wandernde Szenen: dieses Deck *muss* abbrechen.
//
// `pruefe-decks.js` übersetzt es und meldet einen Fund, wenn es durchgeht.
// Der Grund ist derselbe wie bei `ueberlauf.typ` nebenan: im Prüfdeck steht
// die Vorgabe `drift: "error"`, und dort wandert keine Szene -- es sagt also
// nur, dass der Prüfgang durchläuft, nicht dass er trifft. Ein Melder, der
// nichts mehr meldet, fiele sonst niemandem auf.
//
// Die Szene hier ist mit Absicht eine, deren Bild mit dem Wert wächst. Ohne
// ein Zeichenpaket, damit diese Probe an keinem Download hängt: ein nacktes
// `rect` trägt seine Größe genauso in sich wie eine CeTZ-Leinwand.

#import "@preview/typstage:0.1.1": *

#show: presentation.with(theme: themes.lesson)

== Wandernde Tinte
#scene(x => align(center + horizon, rect(width: x * 1pt, height: 40pt)),
       stops: (40, 160), tween: 6, height: 120pt)
