// Prüfdeck: das Deck, das der Prüflauf für sich selbst hält.
//
//     typst compile --features html --format html pruefdeck.typ pruefdeck.html
//
// Es steht hier und nicht unter `examples/`, aus einem Grund: `build-site.sh`
// setzt jede Datei in `examples/` auf die Website, und dieses Deck ist kein
// Beispiel, sondern ein Messwerkzeug. Es soll niemanden etwas lehren.
//
// Warum es das gibt: die sechs Beispieldecks benutzen mehrere Funktionen des
// Pakets kein einziges Mal. Nachgezählt in ihren HTML-Ausgaben und Quellen:
// `after: "dimmed"` 0x, `stagger(dim: true)` 0x, `invert` 0x, `info()` 0x,
// `fit` 0x. Ein Prüflauf über die sechs kann darum kaputtgehen lassen, was
// keines von ihnen anfasst — genau das ist vorgeführt worden, indem die
// Dimm-Abfrage absichtlich zerstört wurde und niemand es merkte.
//
// Jede Zeile hier hat deshalb eine Aufgabe, und die steht dabei. Wer etwas
// hinzufügt, schreibt hin, was am Deck kaputtgehen muss, damit der Lauf es
// meldet. Wer etwas wegnimmt, nimmt eine Prüfung weg.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Prüfdeck],
  subtitle: [Was die sechs Beispieldecks nicht anfassen],
  author: [typstage #runtime-version],
  theme: themes.lesson,
  // Eine Palette, die nicht die Vorgabe ist. Bleibt sie unwirksam, fallen die
  // Farbfingerabdrücke im Sollstand auseinander.
  palette: palettes.dark,
  // Der Prüfgang über den Satz, hier scharf gestellt. Er hält fest, dass
  // dieses Deck nirgends überläuft, und dass der Prüfgang selbst auf einem
  // echten Deck durchläuft. Er ist NICHT die Prüfung von `fit`: gemessen,
  // indem `fit` das Kleinrechnen abgewöhnt wurde, blieb der Prüfgang stumm.
  // Er misst den Block, den `fit` aufspannt, und der ist `height: 1fr`, also
  // immer genau so hoch wie der Platz. Was innen übersteht, sieht er nicht.
  // Ob der Überlaufmelder überhaupt meldet, prüft `ueberlauf.typ` daneben.
  overflow: "error",
  transition: "slide",
  transition-duration: 420,
  duration: 520,
)

= Ruhe

== Nachklang
// `anim(after: "dimmed")` mit endendem Bereich, von Hand geschrieben. Der
// Lauf zählt `data-on` und `data-dim` getrennt; dimmt das nicht mehr, wandert
// die Zahl von der zweiten in die erste Spalte. Gemessen, indem die
// Dimm-Abfrage in der Laufzeit stillgelegt wurde: die Reihe dieser Folie ging
// von 2/1·2/1, 3/2·3/2 auf 1/0·1/0, 1/0·1/0.
Ein Satz, der steht.
#anim(at: "2-3", after: "dimmed")[Leise ab Schritt 4.]
#anim(at: "3-4", after: "dimmed")[Leise ab Schritt 5.]
#anim(at: "5-")[Der letzte bleibt hell.]

== Gang
// `stagger(dim: true)`: derselbe Ruhezustand, aber vom Paket selbst erzeugt,
// über `dim-freiwillig`. Der letzte Punkt darf mit der Folie enden; die späte
// Prüfung im Dokument muss ihn in Ruhe lassen. Meldet sie ihn doch, hält der
// Bau an.
#stagger(dim: true)[
  - erster Punkt
  - zweiter Punkt
  - dritter Punkt
]

= Farbe

== Umgedreht
// `invert: true` auf einer gewöhnlichen Folie. Der Lauf nimmt je Folie den
// Farbfingerabdruck des Grundes; greift die Umkehr nicht mehr, gleicht diese
// Folie den anderen.
#invert
#v(1fr)
#align(center, text(size: 3em, weight: "bold")[42])
#v(1fr)

= Zählen

== Selbstauskunft
// `info()`: eine selbstgebaute Fußzeile aus den Zahlen, die das Deck über
// sich weiß. Lesen kann der Lauf sie nicht: Typst setzt Text als Verweise auf
// Glyphen, im DOM steht keine Ziffer. Was ihn trägt, ist `satz`. Gemessen,
// indem `info().step.total` um eins verstellt wurde: `satz` fiel um und
// `satzBytes` ging von 546292 auf 544704.
#context {
  let deck = info()
  align(center, box(inset: 6pt)[
    #deck.section.title · Folie #deck.slide.number von #deck.slide.total ·
    Schritt #deck.step.number von #deck.step.total
  ])
}
#pause
Ein zweiter Schritt, damit `step.total` größer als eins ist.
#pause
Ein dritter.

= Maß

== Fit
// `fit` schrumpft, was sonst überliefe. Sichtbar ist das allein am Satz, im
// Browser gibt es keine Zahl dafür: `fit` rechnet in Typst, nicht zur
// Laufzeit. Der Lauf hält es über `satz` fest, den Fingerabdruck der
// HTML-Ausgabe ohne Laufzeitblock. Die Tabelle ist mit Absicht deutlich zu
// groß; gemessen, indem `fit` das Kleinrechnen abgewöhnt wurde, wuchs die
// Ausgabe ohne Laufzeitblock von 546292 auf 551857 Bytes, und `satz` fiel um.
// Mit einer knapp zu großen Tabelle tat er das nicht, weil `fit` sie dann in
// der Toleranz stehen ließ. Wer sie kleiner macht, nimmt die Prüfung weg.
#fit(wrap: false, table(
  columns: 10,
  ..for i in range(0, 200) { ([Zelle #i],) },
))

= Flug

== Vorher
// `morph` mit einem Label statt einer Zeichenkette. Der Lauf zählt die
// Geister, die ein Flug erzeugt. Gemessen, indem der Namensabgleich in der
// Laufzeit ins Leere gelenkt wurde: `flieger` fiel von 2 auf 0, und in den
// sechs Beispielen von 24, 82, 67, 99, 56 und 24 ebenfalls auf 0.
#v(1fr)
#align(center, morph(<zahl>, text(size: 2em)[#sym.pi]))
#v(1fr)

== Nachher
#v(1fr)
#align(right, morph(<zahl>, text(size: 4em)[#sym.pi]))
#v(1fr)

#speaker-note[Eine Notiz, damit die Sprecheransicht etwas zu zeigen hat.]

= Adaptiv

== Freie Reihenfolge
// Eine adaptive Gruppe. Sie deckt nichts von selbst auf: alle Punkte stehen
// beiseite, bis eine Ziffer sie ruft. Fuer den Prueflauf heisst das, dass
// `sichtbar` auf diesen Schritten null gedimmte und null gezeichnete Elemente
// meldet -- faellt der Wächter aus, der sie beiseitestellt, kaemen sie von
// selbst und die Reihe wuerde umfallen.
#adaptiv("probe", start: 2)[
  - erster Punkt
  - zweiter Punkt
  - dritter Punkt
]
#adaptiv-schicht("probe", 1, [Beiwerk zum ersten])
#adaptiv-schicht("probe", 2, [Beiwerk zum zweiten])
#adaptiv-schicht("probe", 3, [Beiwerk zum dritten])

== Zweite adaptive Gruppe
// Eine zweite Gruppe auf einer eigenen Folie. Sie belegt, dass Gruppen
// einander nicht ins Gehege kommen -- und vor allem, dass eine Ziffer den
// folienlokalen Schritt und nicht den Deckschritt meint: mit der Verwechslung
// sprang eine Ziffer hier auf die erste Folie des Decks.
#adaptiv("zweite", start: 1)[
  - anderer erster Punkt
  - anderer zweiter Punkt
]

== Verfolgtes im Verfolgten
// Ein `morph` in einem `anim`, das erst spaeter kommt. Die Sprites sind im
// DOM Geschwister, der Wirt kann das Innere also nicht verdecken -- und ein
// `morph` traegt `at: "1-"` als Vorgabe. Ohne die Deckelung stand die Formel
// auf Schritt 1 in voller Staerke da, waehrend ihr eigener Satz noch
// unsichtbar war. Der Lauf sieht das an `sichtbar`: auf dem ersten Schritt
// dieser Folie darf nichts gezeichnet sein.
Sichtbar ab Schritt 1.
#anim(at: "2-")[Erst auf Schritt 2, mit #morph(<verschachtelt>)[$x^2$] darin.]
#pause
Dritter Schritt.

== Danach
#align(center, morph(<verschachtelt>, text(size: 2em)[$x^2$]))

= Zeichnen

== Eine Zeichnung in Stufen
// `aufbau`: eine Zeichnung, die in vier Stufen entsteht. Sie steht hier aus
// schlichten Rechtecken und nicht aus CeTZ oder lilaq -- geprueft wird das
// Paket und nicht ein fremdes Zeichenpaket, und ein Prueflauf, der dafuer
// etwas aus dem Netz holen muesste, prueft an dem Tag nichts, an dem das Netz
// fehlt. Wie `aufbau` sich zu CeTZ und lilaq verhaelt, halten die Beispiele
// der Handbuecher fest; hier steht, was die Laufzeit damit macht.
//
// Drei Dinge haengen daran.
//
// Erstens: auf jedem Schritt dieser Folie ist genau *eine* Stufe gezeichnet,
// nie zwei und nie null, und die letzte bleibt bis zum Ende der Folie stehen.
// Dafuer steht der `anim` unter der Zeichnung: ohne einen Schritt *nach* der
// letzten Stufe faellt eine Stufe, deren Bereich zu frueh schliesst, gar nicht
// auf -- ihr letzter Schritt ist dann zugleich der letzte der Folie. Gemessen,
// indem die letzte Stufe einen geschlossenen statt eines offenen Bereichs
// bekam: ohne den `anim` bewegte sich in `sichtbar` keine Zahl, mit ihm ging
// der letzte Schritt dieser Folie von 2/0 auf 1/0.
//
// Ein `anim` und kein `#pause`: `#pause` nummeriert seine Schritte fuer sich
// (`at: i + 2` in `apply-pauses`) und stuende hier auf Schritt 2, mitten in
// der Zeichnung, statt hinter ihr.
//
// Zweitens: was noch nicht dran ist, steht als Luft da und nicht als Tinte.
// Im Browser gibt es dafuer keine Zahl -- Alpha 0 ist gezeichnet wie jede
// andere Farbe --, aber `satz` haelt es fest. Gemessen, indem `durchsichtig`
// seinen Wert unveraendert zurueckgab: `satz` fiel um.
//
// Drittens: der Schrittzaehler laeuft in beiden Ausgaben gleich. Das sagt die
// Zusicherung unter der Zeichnung, und `pruefe-decks.js` uebersetzt das Deck
// eigens ein zweites Mal auf Papier, weil sie sonst nur im Browser gefragt
// wuerde -- und der Papierzweig von `aufbau` ist ein anderer.
//
// Wie die abtretende Stufe geht, statt *dass* sie geht, misst der Lauf eigens:
// siehe `haltProbe` in `pruefe-decks.js`.
#aufbau(ab => box(width: 300pt, height: 90pt, {
  place(bottom + left, line(length: 100%))
  place(bottom + left, dx: 10%, rect(width: 16%, height: 30pt, fill: ab(2, red)))
  place(bottom + left, dx: 40%, rect(width: 16%, height: 60pt, fill: ab(3, green)))
  place(bottom + left, dx: 70%, rect(width: 16%, height: 88pt, fill: ab(4, blue)))
}), schritte: 4)

#anim[Ein Schritt nach der Zeichnung.]

#context assert(info().step.total == 5, message:
  "Prüfdeck: die Folie mit aufbau() zählt " + str(info().step.total)
  + " Schritte statt 5. Der Schrittzeiger zählt aufbau() falsch -- und diese "
  + "Zahl muss in beiden Ausgaben dieselbe sein, sonst zeigt das Handout eine "
  + "andere Fußzeile als der Vortrag.")
