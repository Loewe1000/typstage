// Gegenprobe zur Klage über ein verfolgtes Element, das keinen Platz findet.
//
// Zwei Ausgänge derselben Sache, und beide führten einmal in den stillen
// Verlust: das Element steht vollständig in der Seite -- mit Pfad, Farbe und
// Strichbreite -- und ist trotzdem nicht zu sehen. Auf Papier steht es.
//
// *Ohne Ausdehnung.* Ein Element ohne Fläche bekommt Luft um seine Marke, und
// die Luft ist eine Schriftgröße breit. Bei `text(size: 0pt)` ist sie das
// nicht mehr, die Marke wird null breit, und das SVG des Sprites bekommt ein
// Ansichtsfenster der Breite null. Ein solches skaliert seinen Inhalt unter
// `xMidYMid meet` mit dem Faktor null.
//
// *Ohne Marke.* Ein geschachteltes Element hat im Hintergrund keine Marke --
// das `hide()` des äußeren verschluckt sie --, sondern erst im Sprite des
// äußeren. `stelle()` legt darum in Runden, und es sind vier. Was tiefer liegt,
// findet nie einen Ort und bleibt bei `opacity: 0` liegen. Sechs ineinander
// heißt: die beiden innersten bleiben liegen.
//
// Zur Übersetzungszeit ist keine der beiden Meldungen zu haben. Ob ein Inhalt
// Fläche hat, ist im Dokument keine Frage, die sich stellen ließe; es ist
// derselbe blinde Fleck, wegen dessen dieses Paket überhaupt mit Rechtecken in
// Signalfarbe arbeitet. Erst im Browser liegt das Rechteck da.
//
// Also läuft dieses Deck im Browser, und der Prüflauf sieht nach, ob die
// Laufzeit genau einmal und genau zweimal klagt. Ohne die Probe könnte die
// Klage aufhören zu klagen, und dann wäre der stille Verlust zurück, den
// niemand bemerkt.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Verloren, aber nicht stillschweigend],
  author: [typstage #runtime-version],
  duration: 200,
)

== Eine Marke ohne Ausdehnung

#text(size: 0pt,
  anim(at: 2, line(angle: 90deg, length: 80pt, stroke: 2pt + blue)))

== Eine Marke, die keiner findet

#anim(at: 2, anim(anim(anim(anim(anim[sechs ineinander])))))
