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
//
// `start` steht hier mit Absicht NICHT da: die Gruppe ist das erste verfolgte
// Element ihrer Folie, `auto` muss also dieselbe 1 ergeben, die vorher
// ausgeschrieben stand. Rechnet `adaptiv` den Zaehlerstand ohne `+ 1`, faengt
// sie bei null an und die ganze Reihe rutscht -- die einzige Stelle im Lauf,
// die den auto-Zweig ueberhaupt betritt.
#adaptiv("zweite")[
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
// Ein `anim` und kein `#pause`, obwohl beides ginge: `#pause` faengt seinen
// Abschnitt in einem Block ein, und der Lauf soll hier das nackte verfolgte
// Element sehen. Dass eine Pause hinter der Zeichnung inzwischen richtig
// zaehlt, haelt die Folie mit dem verschachtelten `morph` fest.
//
// Zweitens: was noch nicht dran ist, steht als Luft da und nicht als Tinte.
// Ob eine Farbe Alpha 0 traegt, hat im Browser keine Zahl -- gezeichnet wird
// sie wie jede andere --, das haelt `satz` fest. Gemessen, indem
// `durchsichtig` seinen Wert unveraendert zurueckgab: `satz` fiel um.
//
// Wohl aber eine Zahl hat, ob die Luft ihren *Platz* behaelt, und das ist die
// eigentliche Zusage. Deshalb steht die Zeichnung hier nicht in einem Kasten
// fester Groesse, sondern in einem `stack`, dessen Breite an ihren Stuecken
// haengt, und das letzte Stueck ist Inhalt und keine Farbe: `hide` haelt
// seinen Platz, `none` nicht. Alle vier Stufen muessen dasselbe Mass melden --
// siehe `masz` in der Haltprobe. Gemessen, indem `durchsichtig` fuer Inhalt
// `none` zurueckgab: aus einem Mass wurden zwei.
//
// Drittens: der Schrittzaehler laeuft in beiden Ausgaben gleich. Das sagt die
// Zusicherung unter der Zeichnung, und `pruefe-decks.js` uebersetzt das Deck
// eigens ein zweites Mal auf Papier, weil sie sonst nur im Browser gefragt
// wuerde -- und der Papierzweig von `aufbau` ist ein anderer.
//
// Wie die abtretende Stufe geht, statt *dass* sie geht, misst der Lauf eigens:
// siehe `haltProbe` in `pruefe-decks.js`.
#aufbau(ab => stack(dir: ltr, spacing: 8pt,
  // Der Grund: steht auf jeder Stufe, weil er keine Nummer traegt.
  rect(width: 44pt, height: 44pt, stroke: 0.6pt),
  rect(width: 44pt, height: 44pt, fill: ab(2, red), stroke: ab(2, 0.6pt + black)),
  rect(width: 44pt, height: 44pt, fill: ab(3, green), stroke: ab(3, 0.6pt + black)),
  // Ein Stueck aus Inhalt statt aus Farbe. Daran haengt die Breite des Stapels
  // und damit das Mass aller vier Stufen.
  ab(4, box(width: 80pt, height: 44pt, align(center + horizon)[Beschriftung])),
), schritte: 4)

#anim[Ein Schritt nach der Zeichnung.]

#context assert(info().step.total == 5, message:
  "Prüfdeck: die Folie mit aufbau() zählt " + str(info().step.total)
  + " Schritte statt 5. Der Schrittzeiger zählt aufbau() falsch -- und diese "
  + "Zahl muss in beiden Ausgaben dieselbe sein, sonst zeigt das Handout eine "
  + "andere Fußzeile als der Vortrag.")

== Ein Pfad, der sich selbst zeichnet
// `enter: "draw"` und `easing:`. Beide stehen auf demselben Element und
// werden trotzdem getrennt gemessen -- `zeichnung` und `kurve` --, damit eine
// Abweichung sagt, welche der beiden Fähigkeiten umgefallen ist.
//
// Wieder aus schlichten Formen und nicht aus CeTZ: geprüft wird das Paket und
// nicht ein fremdes Zeichenpaket. Welche Zeichenpakete Konturen liefern, die
// sich abfahren lassen, hält das Handbuch fest.
//
// Vier Dinge hängen daran.
//
// Erstens: die Zeichnung steht auf dem *zweiten* Schritt ihrer Folie und
// nicht auf dem ersten, und das ist keine Zierde. Wer eine Folie betritt,
// sieht keine Auftritte -- `goto` stellt beim Folienwechsel nur den Zustand
// her. Eine Zeichnung auf Schritt eins zeichnete sich also nie, und der Lauf
// hätte nichts zu messen. Der Satz davor kostet den Schritt, den es dafür
// braucht.
//
// Zweitens: drei Striche und ein Rechteck ohne Kontur. Die drei werden
// abgefahren, das vierte blendet -- es hat keine Kontur, an der entlang etwas
// zu fahren wäre, genau wie Text. Gemessen, indem die Strichbreite als
// Bedingung wegfiel: aus 3 Pfaden wurden 4.
//
// Drittens: rückwärts fährt die Feder wieder heraus, und danach trägt kein
// Pfad mehr eine Feder. Bliebe eine stehen, stünde ein Strich für den Rest
// des Vortrags auf halber Strecke -- zu sehen erst bei dem einen Sprung, der
// genau dorthin geht.
//
// Viertens: `easing:` schreibt die fertige Kurve ins Markup, und die Laufzeit
// legt sie sowohl der Blende als auch der Feder unter. Fällt eine der beiden
// auf die Hauskurve zurück, fällt `kurve` um.
#anim[Erst ein Satz -- eine Zeichnung auf Schritt eins zeichnete sich nie.]
#anim(enter: "draw", duration: 640, easing: "out-back",
  box(width: 220pt, height: 100pt, {
    place(top + left, line(end: (100%, 0%), stroke: 1.2pt))
    place(top + left, line(end: (0%, 100%), stroke: 1.2pt))
    place(top + left, dy: 24pt, rect(width: 70pt, height: 50pt, stroke: 1pt))
    // Ohne Kontur: blendet, wie Text es tut, und wird nicht mitgezählt.
    place(top + left, dx: 150pt, dy: 30pt,
          rect(width: 40pt, height: 40pt, fill: accent, stroke: none))
  }))
#anim[Ein Schritt nach der Zeichnung, damit sie auch abtreten kann.]
