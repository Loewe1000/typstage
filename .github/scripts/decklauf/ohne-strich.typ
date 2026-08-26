// Gegenprobe zur Klage über `enter: "draw"` ohne gestrichenen Pfad.
//
// Dieses Deck übersetzt anstandslos -- die Meldung ist zur Übersetzungszeit
// gar nicht zu haben. Typst gibt das SVG erst beim Export heraus, und im
// Dokument gibt es keine Frage, die „hat dieser Inhalt eine Kontur"
// beantwortete; es ist derselbe blinde Fleck, wegen dessen das Paket
// überhaupt mit Signalfarb-Rechtecken arbeitet. Erst im Browser steht der
// Pfad da und lässt sich zählen.
//
// Also läuft dieses Deck im Browser, und der Prüflauf sieht nach, ob die
// Laufzeit genau einmal klagt. Ohne diese Probe könnte die Klage aufhören zu
// klagen und niemand merkte es: das Element blendet dann still auf, und eine
// stille Blende sieht aus wie eine gewollte.
//
// Der Satz steht auf dem *zweiten* Schritt. Wer eine Folie betritt, sieht
// keine Auftritte, und ohne Auftritt wird nicht geklagt.
//
// Und genau ein Element mit `draw`: die Klage geht einmal je Element heraus,
// also ist ein zweites eine zweite Zeile im Bericht.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Zeichnen ohne Kontur],
  author: [typstage #runtime-version],
  duration: 200,
)

== Ein Satz, der sich nicht zeichnen lässt
#anim[Erst ein Satz.]
#anim(enter: "draw")[Glyphen sind gefüllte Umrisse und haben keine Kontur.]
#anim[Und danach.]
