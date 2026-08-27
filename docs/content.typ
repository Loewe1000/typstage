#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= Über dieses Paket

Das `typstage`-Paket erzeugt aus einer einzigen Typst-Datei eine animierte
Präsentation für den Browser -- und aus derselben Quelle eine PDF. Der Satz
dahinter lautet: *Typst setzt, der Browser bewegt.* Jede Folie wird von Typst
als SVG gesetzt und als solches in die HTML-Datei geschrieben; die Anordnung im
Browser ist deshalb dieselbe wie auf dem Papier. Bewegt wird erst danach: Was
sich rühren soll, wird im Quelltext angemeldet, und eine kleine
Laufzeitumgebung setzt es im Browser in Bewegung.

Daraus folgt der Rest. Eine Folie ist eine Folie und kein Stapel von
Zwischenständen; die PDF hat eine Seite je Folie, nicht eine je Schritt; und
was allein zur Bewegung gehört, fällt auf dem Papier von selbst weg.

Dieses Handbuch ist nach Vorhaben geordnet, nicht nach Funktionen:

+ *Die erste Präsentation* -- von der leeren Datei zur laufenden HTML
+ *Eine Folie Schritt für Schritt aufdecken* -- `pause`, `stagger`, `anim` und
  der Schrittzeiger
+ *Etwas vorführen statt behaupten* -- Applet, Video, Daumenkino
+ *GeoGebra* -- Konstruktionen, die den Schritten der Folie folgen
+ *Eine Rechnung entwickeln* -- Magic Move über mehrere Folien
+ *Aus einer Quelle drei Ausgaben* -- Präsentation, Foliensatz, Handout
+ *Das eigene Aussehen* -- Themes, Farben, Leinwand, Bausteine
+ *API-Referenz* -- vollständige Funktionsdokumentation

#info[
  Die gesetzten Beispiele dieses Handbuchs sind Papier und zeigen deshalb den
  Endzustand -- alles auf einmal. Was im Browser nacheinander geschieht, steht
  im Text daneben oder als Kommentar in der Quelle.

  Jeder `typ`-Block hier wird vor dem Bau der Website gegen das echte Paket
  übersetzt -- `python3 .github/scripts/pruefe-beispiele.py` --, damit kein
  Beispiel eine Umbenennung im Paket überlebt, die es ungültig macht. Was der
  Lauf dabei *nicht* leistet, gehört dazugesagt: Die meisten Blöcke sind
  Bruchstücke und keine ganzen Dateien, er setzt sie also in eine Folie und
  prüft, dass sie darin übersetzen -- nicht, dass die Folie danach richtig
  aussieht. Zeilen, die absichtlich einen Fehler auslösen, sind als solche
  geführt, müssen fehlschlagen und nennen, woran -- eine Zeile, die aus einem
  anderen Grund bricht, ist ein durchgefallener Test und kein bestandener. Eine
  Zeile dagegen, die zwar übersetzt, aber nicht das Gewünschte tut ("wirkt
  nicht", "zu spät"), kann er von einer richtigen nicht unterscheiden. Er
  übersetzt für den Browser, nicht für Papier, und er sieht nie auf die Prosa
  neben einem Listing -- dort sitzt eine veraltete Zahl am liebsten. Blöcke in
  anderen Sprachen bleiben ungeprüft und werden gezählt, damit niemand einen
  davon durch einen verschriebenen Zaun verliert. Und ein Beispiel, für das ein
  Begleitpaket fehlt, wird übersprungen; der Lauf sagt, welches.
]

= Die erste Präsentation

Ziel dieses Kapitels: eine vollständige, vorführbare Präsentation, in zehn
Minuten und ohne Umwege.

== Eine Datei genügt

Mehr als dies braucht es nicht -- den Import, eine Show-Regel und
Überschriften. Die folgende Datei ist vollständig und lässt sich abtippen:

// Aus der Datei gelesen, nicht abgeschrieben: "vollständig und lässt sich
// abtippen" ist eine Zusage, und die hält nur, wenn hier dieselben Zeichen
// stehen, die `.github/scripts/pruefe-beispiele.py` auch übersetzt.
#show-code(raw(read("../examples/handbuch/erste-praesentation.typ").trim(),
               block: true, lang: "typ"))

Daraus entstehen vier Folien: die Titelfolie aus `title`, eine Abschnittsfolie
aus `=`, und je eine gewöhnliche Folie aus den beiden `==`. Der Text bis zur
nächsten Überschrift ist der Rumpf einer Folie.

So sieht der Rumpf der Folie "Die Behauptung" aus, wenn alle Schritte
abgelaufen sind:

#show-example(
  rendered: {
    import "../src/lib.typ": *
    stagger[
      - Ein rechtwinkliges Dreieck hat zwei Katheten und eine Hypotenuse.
      - Über jeder Seite steht ein Quadrat.
      - Die beiden kleinen sind zusammen so groß wie das große.
    ]
    v(1em)
    anim(callout[Genau das behauptet der Satz.], enter: "scale")
  },
  source: ```typ
  #stagger[
    - Ein rechtwinkliges Dreieck hat zwei Katheten und eine Hypotenuse.
    - Über jeder Seite steht ein Quadrat.
    - Die beiden kleinen sind zusammen so groß wie das große.
  ]

  #v(1em)

  #anim(callout[Genau das behauptet der Satz.], enter: "scale")
  ```,
  width: 13cm,
)

Im Browser erscheinen die drei Punkte nacheinander, der Merksatz auf dem
vierten Tastendruck.

== Zweimal übersetzen

Dieselbe Datei ergibt zwei Ausgaben; dazwischen liegt keine Nachbearbeitung.

#show-code[```bash
typst compile vortrag.typ vortrag.html --format html --features html
typst compile vortrag.typ vortrag.pdf
```]

Die erste Zeile ergibt die animierte Präsentation als eine einzige Datei, die
sich mit einem Doppelklick öffnen lässt -- ohne Server und ohne Netz. Die
zweite ergibt den Foliensatz zum Ausdrucken.

#info[
  Der HTML-Export ist in Typst 0.15 als Vorschau gekennzeichnet und verlangt
  deshalb `--features html`. Die Warnung, die Typst dabei ausgibt, betrifft den
  Export im Allgemeinen, nicht dieses Paket.
]

== Vorführen

Die Laufzeitumgebung zählt in *Schritten*, nicht in Folien: Eine Folie mit drei
Einblendungen hat drei Schritte, und `→` geht zum nächsten -- gleich ob der auf
derselben oder auf der nächsten Folie liegt.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Taste*], [*Wirkung*]),
  [`→`, `Bild ab`, Leertaste], [einen Schritt weiter],
  [`←`, `Bild auf`], [einen Schritt zurück],
  [`Pos 1`], [zum ersten Schritt, ohne Bewegung],
  [`Ende`], [zum letzten Schritt, ohne Bewegung],
  [`o`, `Esc`], [Übersicht aller Folien ein- und ausschalten],
  [`f`], [Vollbild],
  [`s`], [Notiz zur laufenden Folie kurz einblenden],
  [`p`], [Druckansicht: eine Folie je Seite, alles sichtbar],
  [`n`], [die Sprecheransicht in einem zweiten Fenster öffnen],
  [`?`], [die Tastenbelegung einblenden],
)

Ein Klick in das linke Viertel des Fensters blättert zurück, jeder andere
vorwärts; innerhalb eines eingebetteten Elements bleibt der Klick bei diesem.

Auf einem Telefon oder Tablet gilt dasselbe mit dem Finger, und dazu der Wisch:
von rechts nach links kommt die nächste Folie, andersherum die vorige. Die
Richtung ist die natürliche, der Finger schiebt die Folie aus dem Bild.

#warning[
  Das Tippen hängt dabei ausdrücklich *nicht* am Klick. iOS Safari baut aus
  einer Berührung nur dann einen Klick, wenn ihm das getroffene Element
  anklickbar vorkommt, also ein Verweis, ein Knopf oder etwas mit eigenem
  Klickzuhörer. Eine Folie ist keins davon, und auf einem iPhone geschah
  deshalb beim Tippen gar nichts, während dieselbe Stelle in Chrome blätterte.
  Ein nachgestelltes Telefon zeigt das nicht, weil Chrome den Klick immer baut.
]

== Die Sprecheransicht

`n` öffnet dieselbe Datei ein zweites Mal, mit `#speaker` an der Adresse, in
einem zweiten Fenster. Das eine kommt auf den Beamer, das andere auf den
Rechner vor dem Vortragenden. Beide reden über `postMessage` miteinander, und
das trägt auch zwischen zwei lokalen Dateien; es braucht also so wenig einen
Server wie alles andere hier.

Die Ansicht ist ein Pult aus Kacheln. Oben die beiden großen: links die
laufende Folie, rechts die Notiz -- die beiden Dinge, auf die man wirklich
sieht. Darunter eine Zeile aus vier kleinen und einer breiten:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Kachel*], [*was darin steht*]),
  [verstrichen], [die Zeit seit dem ersten Tastendruck, darunter klein die
    Uhrzeit an der Wand],
  [Folie], [Folie #sym.slash Folien, darunter Schritt #sym.slash Schritte, am
    Fuß der Fortschrittsbalken],
  [Ziel (min)], [die geplante Dauer -- `d` geht hinein --, darunter Rest und
    Plan, sobald eine gesetzt ist],
  [Klassenuhr], [die Uhr, die im Saal an der Wand steht; `t` startet sie],
  [nächster Schritt], [die Vorschau: was der nächste Tastendruck tut],
)

Darunter die Werkzeugzeile: Stift oder Zeiger, die vier Farben, die
Tastenbelegung. Der Zustand des Saals -- `schwarz`, `eingefroren`, `kein
Vortragsfenster` -- steht oben rechts *in* der Folienkachel, also über dem
Bild, über das er etwas aussagt.

=== Hell oder dunkel

Die Ansicht folgt der Systemeinstellung des Rechners, an dem sie steht
(`prefers-color-scheme`), und `l` widerspricht ihr, wenn der Raum anders ist,
als das Betriebssystem denkt. Die Wahl hält die Sitzung und übersteht ein
Neuladen.

Ausdrücklich *nicht* an der Palette des Decks: die sagt, wie die Wand aussieht.
Dasselbe Nachtdeck läuft morgens um acht im hellen Raum und abends im
abgedunkelten, und davor sitzt beide Male dieselbe Lehrkraft. Das Pult ist
Werkzeug, kein Vortrag; wechselte es mit dem Deck die Farbe, müsste man es in
jeder Stunde neu lesen lernen.

#tip[
  Die Vorschau zeigt den nächsten Schritt, nicht die nächste Folie. Ein Deck,
  das in Schritten zählt, muss die Frage beantworten "was tut der nächste
  Tastendruck", und das kann eine neue Folie sein oder eine weitere Enthüllung
  auf derselben. Die Marke darüber sagt, welches von beidem.
]

Auf der laufenden Folie lässt sich dort zeichnen, und die Striche erscheinen
auf der Leinwand. Sie bleiben an ihrer Folie kleben: wer vorblättert und
zurückkommt, findet sie wieder. `x` löscht die der laufenden Folie, `z` nimmt
den letzten Strich zurück, `c` wechselt die Farbe. `b` schaltet den Saal
schwarz, `e` friert das Bild auf der Leinwand ein, während man bei sich schon
weiterblättert.

=== Eine Uhr, die die Klasse sieht

`t` fragt nach einer Zahl in Minuten, und danach steht auf der Leinwand nichts
als eine Uhr: schwarze Fläche, weiße Ziffern, `m:ss`, so groß, dass sie aus der
letzten Reihe zu lesen ist. Sie ersetzt die Folie, sie liegt nicht darüber --
der Zwilling von `b`, nur mit etwas darauf.

Gedacht ist sie für die Pause, die Gruppenarbeit, den Versuchsaufbau: für die
Minuten, in denen die Klasse etwas tut und nicht zuhört.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Taste*], [*Wirkung*]),
  [`t`], [nach Minuten fragen; `Eingabe` startet, `Esc` lässt es],
  [`t` (während sie läuft)], [Uhr beenden, Folie wieder da],
  [`⇧→`, `⇧←`], [eine Minute mehr oder weniger, auch während sie läuft],
  [`→` (oder jede andere Blättertaste)], [beendet sie und deckt die Folie auf],
)

In der Sprecheransicht hat sie eine eigene Kachel, `Klassenuhr`, neben der
Kachel `Ziel (min)`. Die Sorge, zwei große Zahlen nebeneinander würden
verwechselt, ist berechtigt -- sie ist hier durch Bauart aufgelöst und nicht
durch Verstecken: die Zieldauer ist ein Feld mit ganzen Minuten, das man einmal
je Vortrag setzt, die Klassenuhr eine laufende `m:ss` mit einem Balken, der
leerläuft. Sie sehen verschieden aus, sie ticken verschieden, sie heißen
verschieden.

Läuft keine, steht dort ein Strich. Antwortet kein Vortragsfenster, steht dort
ein langer Strich: geführt wird die Uhr drüben, diese Ansicht liest sie nur ab,
und ohne Gegenüber stünde hinter jeder Zahl nichts.

Bei null hört sie nicht auf, sie geht auf `+0:01` weiter, und die Ziffern
nehmen die Signalfarbe des Decks an. Über den Ziffern steht dann ein Wort, das
vorher nicht da war: „Überzeit". Sein Erscheinen ist das Ereignis; es blinkt
nichts und es klingelt nichts.

Am Pult schlägt im selben Augenblick die ganze Kachel um: Fläche, Rand und
Ziffern in der Warnfarbe, und aus `Klassenuhr` wird `Überzeit`. Eine Fläche
sieht man aus dem Augenwinkel, eine Ziffer nicht -- und die Lehrkraft soll die
Überzeit nicht später bemerken als die Klasse, die sie an der Wand stehen
sieht. Die Überzeit ist gedeckelt, bei der Dauer selbst
und höchstens bei dreißig Minuten. `+2:47:13` sagt niemandem etwas.

#warning[
  `t`, wenn sonst nichts an der Wand steht. Keine Uhr, solange Sie reden.

  Eine Uhr, die neben einem Satz läuft, zieht den Blick, und zwar den ganzen
  Vortrag lang -- dieselbe Rechnung wie beim schleifenden Daumenkino, nur ohne
  Ende. Sie ist deshalb ausdrücklich kein Aufsatz auf die Folie, sondern deren
  Ersatz: solange sie steht, ist nichts anderes zu sehen, und wer weiterredet,
  drückt sie weg.
]

#info[
  „Bewegung reduzieren" ändert an ihr nichts, und das ist Absicht: die Ziffern
  springen ohnehin nur sekündlich, es gibt keinen Weg, der wegfallen könnte.

  Über die Uhr im Saal wacht dieselbe Vorkehrung wie über Schwarz und
  Einfrieren: fällt das Sprecherfenster weg, hebt der Vortrag sie von selbst
  auf. Im Vortragsfenster gibt es keine Taste gegen sie, und es soll dort keine
  geben.

  Wird das Vortragsfenster neu geladen, kommt sie wieder -- und zwar weiter,
  nicht von vorn. Die Sekunden, die das Laden gekostet hat, laufen mit; die
  Klasse draußen wartet ja auch.
]

`m` schaltet den Zeiger zwischen Stift und Einbettung um. Im Zeigermodus ruht
der Stift, und ein Klick auf einen eingebetteten Rahmen landet stattdessen im
Vortragsfenster: dieselbe Stelle, dieselbe Geste, in der Größe, die das andere
Fenster gerade hat. Wo das eingebettete Dokument sich selbst spiegeln kann, wie
ein GeoGebra-Applet es tut, bedient man das lebende vor sich und die Kopie auf
der Leinwand zieht nach.

=== Ein Rahmen, der den Fokus hat

Wer eine Einbettung anklickt, gibt ihr den Fokus. Von da an landet jede Taste
darin, das Fenster ringsum hört nichts, und der Vortrag blättert nicht mehr.

Die Tasten des Vortrags werden ihm deshalb aus jedem Rahmen zurückgereicht, in
den dieses Fenster hineinlesen darf. Drei Bedingungen halten das ehrlich: das
eingebettete Dokument darf die Taste nicht schon genommen haben, die Taste muss
eine sein, die der Vortrag benutzt, und das Getippte darf kein Textfeld sein,
sonst öffnete ein `n` in einem Formular ein zweites Fenster.

#tip[
  Nachgemessen an einem GeoGebra-Applet, bevor darüber entschieden wurde: der
  Fokus sitzt auf seiner Zeichenfläche, es sieht alle siebzehn geprüften
  Tasten, ruft bei keiner `preventDefault` und ändert nichts an der
  Konstruktion. Ohne Werkzeugleiste und ohne Eingabezeile hat es für die
  Tastatur keine Verwendung. Ein Dokument, das eine Taste haben will, nimmt sie
  auf dem üblichen Weg, und dann behält es sie auch.
]

Alles außerhalb dieser Menge bleibt beim Rahmen. `Entf` ist das Beispiel: die
Taste gehört dem Eingebetteten, und der Vortrag sieht sie nie.

Gesteuert wird aus beiden Fenstern, und jedes von beiden darf neu geladen
werden: sie finden sich wieder, und die Striche kommen mit.

#warning[
  Drei Grenzen, die man kennen sollte.

  Die Striche werden *nicht* mitgedruckt. Die Druckansicht ist der saubere
  Foliensatz, nicht das Tafelbild.

  Schwarz und Einfrieren enden von selbst, sobald das Sprecherfenster
  geschlossen wird, gemessen in gut acht Zehntelsekunden. Steht das Fenster
  dagegen offen und trägt nur kein Deck mehr, greift erst eine Frist von einer
  Minute. Wer in dieser Lage zusätzlich ein stockendes Vortragsfenster hat,
  kann sie unbegrenzt hinauszögern; das ist die eine bekannte Ecke, in der der
  Saal schwarz bleibt.

  Gemessen ist das in Chrome, Firefox 154 und Safari 26: die sechs
  Beispiel-Decks laufen in allen dreien mit denselben Zahlen durch, und das
  Sprecherfenster öffnet sich in allen dreien auf einen Tastendruck. Ein
  *echter* Tastendruck ist dabei die Bedingung: `window.open` ohne
  Nutzergeste fiele überall dem Popup-Blocker zum Opfer.
]
In der Übersicht führt ein Klick auf ein Vorschaubild zu dieser Folie.

Die Adresszeile trägt den laufenden Schritt mit, `#12` etwa den zwölften. Ein
neu geladenes Fenster steht damit wieder an derselben Stelle, und eine von Hand
geänderte Nummer springt dorthin -- praktisch, um im Vortrag eine bestimmte
Stelle sofort zu erreichen.

#warning[
  Inhalt, der vor der ersten Überschrift steht, gehört zu keiner Folie. Trägt
  er Text, bricht das Übersetzen dort ab und sagt es -- siehe „Text, der zu
  keiner Folie gehört". Trägt er keinen (ein Bild etwa), verschwindet er
  weiterhin wortlos. Ebenso erreicht ein `#set heading`, das nach der
  Show-Regel steht, die Folientitel nicht mehr -- sie verlassen den Bereich,
  den die Regel umschließt. Für die Typografie der Folien gibt es `style` --
  siehe das Kapitel "Das eigene Aussehen".
]

== Mehr als zwei Ebenen

Die Vorgabe schneidet das Deck an der zweiten Ebene: `=` wird eine
Abschnittsfolie, `==` eine Folie. `slide-level` verschiebt diesen Schnitt.
Eine Überschrift *über* der Ebene wird zur Abschnittsfolie, eine Überschrift
auf ihr oder darunter wird zur Folie.

// check: dokument
#show-code[```typ
#show: presentation.with(title: [Analysis I], slide-level: 3)
= Teil I -- Grenzwerte
== Folgen
=== Was eine Folge ist
Eine Abbildung von den natürlichen in die reellen Zahlen.
=== Konvergenz
Für jedes Epsilon gibt es ein N.
== Reihen
=== Partialsummen
Die Summe der ersten n Glieder.
```]

Aus `= Teil I` und `== Folgen` werden Abschnittsfolien, aus jedem `===` eine
Folie. Die Übergangsfolien für *beide* Ebenen fallen dabei von selbst an: eine
Abschnittsüberschrift ist hier schon die Trennfolie, es gibt also nichts
anzuschalten und keinen Haken zu schreiben.

`slide-level: 1` macht jede Überschrift zu einer Folie; das Deck hat dann
überhaupt keine Struktur-Ebene mehr.

Die fünf mitgelieferten Themes zeichnen eine tiefere Ebene ruhiger: der Titel
wird kleiner, und darüber steht, worunter der Abschnitt hängt. Ein Theme mit
eigener `section`-Funktion liest `s.depth` und `s.parents` vom Datensatz und
darf beide übergehen -- dann sehen alle Ebenen gleich aus, und nichts bricht.

Was das Deck über seine Gliederung weiß, steht in `info()`: `section` meint
weiterhin die Ebene direkt über der Folie, `levels` hat einen Eintrag je
Struktur-Ebene, und `outline` ist die ganze Gliederung. Der Abschnitt
"`info()`: was das Deck über sich selbst weiß" sagt, was darin steht.

=== Text, der zu keiner Folie gehört

Zwischen einer Abschnittsüberschrift und der nächsten Überschrift ist kein
Platz für Text. Eine Abschnittsfolie ist ein ganzes Bild, das das Theme
zeichnet; sie hat keinen Rumpf. Früher fiel solcher Text ohne ein Wort aus dem
Deck: es übersetzte, die Folienzahl stimmte, der Absatz war schlicht weg. Seit
es mehr als eine Art von Struktur-Überschrift gibt, gibt es dafür auch mehr
Gelegenheiten, und deshalb bricht das Übersetzen dort jetzt mit einer Meldung
ab.

Ein Satz zwischen `= Der Beweis` und `== Die Zerlegung` bricht also mit
`content between the heading "Der Beweis" and the next one belongs to no
slide` ab:

// check: dokument bricht=belongs_to_no_slide
#show-code[```typ
#show: presentation.with()
= Der Beweis
Dieser Satz gehört zu keiner Folie und hält das Übersetzen an.
== Die Zerlegung
```]

Er gehört unter die Folienüberschrift:

// check: dokument
#show-code[```typ
#show: presentation.with()
= Der Beweis
== Die Zerlegung
Dieser Satz gehört zur Folie und wird gesetzt.
```]

Zwei Vorbehalte, damit hier nicht mehr versprochen wird, als der Code hält.
Erstens wird auch der Text *vor* der ersten Überschrift abgewiesen, aber nur
dann, wenn das Deck überhaupt eine Überschrift hat: ein Rumpf ohne eine
einzige Überschrift ist keine Präsentation in der Überschriften-Schreibweise,
und dort fehlt nicht eine Folie, sondern es gibt keine. Zweitens greift das
Ganze nur in der Überschriften-Schreibweise; wer Folien als Argumente übergibt,
schreibt jeden Rumpf ohnehin selbst hin.

== Wenn die Folien berechnet werden

Auch Überschriften, die erst beim Setzen entstehen, werden zu Folien. Eine
Schleife über eine Liste ergibt so eine Folie je Eintrag:

#show-code[```typ
#for stoff in ("Wasser", "Luft", "Erde") [
  == #stoff
  Etwas über #stoff.
]
```]

Wo die Folien vollständig aus Daten entstehen, lassen sie sich auch einzeln
übergeben. Dann ist jede Folie ein Funktionsaufruf, und eine Liste von Folien
lässt sich mit `..` weiterreichen wie jedes andere Array:

// check: dokument
#show-code[```typ
#presentation(
  title-slide(title: [Der Satz des Pythagoras], author: [A. Schulz]),
  section[Der Beweis],
  slide([Die Zerlegung], note: [Zuerst das Quadrat zeigen.])[
    Der Text der Folie.
  ],
)
```]

Beide Schreibweisen führen zu derselben Ausgabe; `presentation` erkennt an dem,
was es bekommt, welche gemeint ist. Die Form mit Überschriften liest sich wie
ein Dokument und ist der Normalfall.

= Eine Folie Schritt für Schritt aufdecken

Ziel dieses Kapitels: eine Folie, die sich vor der Klasse entfaltet, statt
fertig dazustehen. Eine Folie ist dafür kein Bild, sondern ein Ablauf aus
*Schritten*: ein Tastendruck zeigt den nächsten Stichpunkt, der übernächste die
Formel darunter, und erst wenn auf der Folie nichts mehr aussteht, blättert der
Druck weiter.

== Welches Mittel wofür

Sechs Bausteine decken so gut wie alles ab. Sie lassen sich auf einer Folie
mischen; welcher der richtige ist, hängt daran, wie fein die Folie gesteuert
werden soll.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Mittel*], [*Wofür*]),
  [`#pause`],
  [Die Folie entfaltet sich von oben nach unten, ohne dass etwas umhüllt werden
   müsste. Der kürzeste Weg und der häufigste Fall.],
  [`stagger[…]`],
  [Eine Liste Punkt für Punkt -- Aufzählungszeichen und Text gemeinsam. Auch
   für mehrere Blöcke nacheinander.],
  [`anim(…)`],
  [Ein bestimmtes Stück auf einem bestimmten Schritt, mit eigener Bewegung. Das
   Mittel überall dort, wo `#pause` nicht hinreicht: in Rasterzellen,
   Tabellen, Kästen.],
  [`alternatives(…)`],
  [Mehrere Fassungen derselben Sache an derselben Stelle, jede die vorige
   ersetzend.],
  [`build(…)`],
  [Eine Zeichnung oder ein Diagramm, das in Stufen entsteht -- eine CeTZ-Linie,
   eine lilaq-Datenreihe, eine Beschriftung nach der anderen.],
  [`scene(…)`],
  [Eine Zeichnung, die von einem Wert abhängt, und die Werte, an denen der
   Vortrag hält. Für alles, was sich *bewegt*, statt dazuzukommen.],
)

Dazu kommt `tiles` für ein Kachelraster, das sich von selbst staffelt (Kapitel
"Das eigene Aussehen"), und `morph` für Objekte, die zwischen zwei Folien
fliegen (Kapitel "Eine Rechnung entwickeln").

== Der Schrittzeiger

Jede Folie führt einen Schrittzeiger mit. `at` ist vorgabemäßig `auto`, und
`auto` heißt "der nächste freie Schritt". Aufeinanderfolgende Einblendungen
nummerieren sich damit von selbst; in der Regel steht in einer Folie überhaupt
keine Zahl.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    anim[Der Zeiger fängt bei eins an.]
    v(0.5em)
    stagger[
      - Die Liste zählt weiter,
      - wo die Folie stand,
      - Punkt für Punkt.
    ]
  },
  source: ```typ
  #anim[Der Zeiger fängt bei eins an.]   // Schritt 1
  #stagger[
    - Die Liste zählt weiter,            // Schritt 2
    - wo die Folie stand,                // Schritt 3
    - Punkt für Punkt.                   // Schritt 4
  ]
  ```,
  width: 12cm,
)

Der Zeiger beginnt auf jeder Folie neu; Schrittnummern sind folienlokal. Eine
ausgeschriebene Zahl setzt den Zeiger neu, und von dort zählt es weiter -- eine
einzelne Korrektur zwingt also nicht dazu, alles dahinter umzunummerieren:

#show-code[```typ
#anim[zuerst]           // 1
#anim(at: 4)[spät]      // 4
#anim[danach]           // 5
```]

Die Schreibweisen von `at`:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Geschrieben*], [*Bedeutung*]),
  [`auto`], [der nächste freie Schritt (Vorgabe)],
  [`3`], [ab Schritt drei -- dasselbe wie `"3-"`],
  [`(2, 5)`], [auf Schritt zwei und auf Schritt fünf],
  [`"2-"`], [ab Schritt zwei],
  [`"1-2"`], [auf Schritt eins und zwei, danach nicht mehr],
  [`"2,4"`], [auf Schritt zwei und auf Schritt vier],
  [`"-2"`], [von Anfang an bis Schritt zwei],
  [`"3"`], [genau auf Schritt drei],
)

Eine bloße Zahl ist ein offenes Ende: Was einmal da ist, bleibt bis zum Ende
der Folie stehen. Das ist der Regelfall. Eine geschlossene Angabe wie `"1-2"`
oder `"3"` lässt das Element wieder verschwinden -- dann greift `exit`.

== Eine Folie ohne eine einzige Zahl

Für eine Folie, die sich einfach nur entfaltet, muss nichts umhüllt werden.
`#pause` schiebt alles Folgende einen Schritt weiter:

#show-code[```typ
== Wie eine Ableitung entsteht

Zwei Punkte auf dem Graphen, dazwischen eine Sekante.

#pause

Rückt der zweite Punkt an den ersten heran, wird aus der Sekante
eine Tangente.

#pause

Ihre Steigung ist die Ableitung an dieser Stelle.
```]

Die Läufe zwischen den Pausen werden vom Folienanfang an durchnummeriert: Der
erste steht von Beginn an, der zweite erscheint auf Schritt zwei, der dritte
auf Schritt drei. Danach zählt der Zeiger regulär weiter -- ein `stagger` unter
zwei Pausen beginnt bei vier.

Eine Pause beginnt einen neuen Block, und die PDF setzt ihn genauso; beide
Ziele werden zum selben Umbruch angehalten.

#warning[
  `#pause` wird auf der obersten Ebene des Folienrumpfs gelesen, `#set`- und
  `#show`-Regeln eingeschlossen: Eine Pause hinter `#set text(size: 20pt)`
  wirkt. In einer Rasterzelle, einer Tabelle oder einer Abbildung wird sie
  *nicht* gesehen -- dort ist der Inhalt ein Feld eines Elements und nicht mehr
  Teil des Rumpfs. An diesen Stellen ist `anim` das Mittel der Wahl.
]

#show-code[```typ
#set text(size: 20pt)
Erster Lauf.
#pause                       // gesehen
Zweiter Lauf.

#grid(columns: (1fr, 1fr),
  [links #pause danach],     // ungesehen
  [rechts],
)
```]

== Eine Liste Punkt für Punkt

`stagger` staffelt die Punkte einer Liste über die Schritte. `start` ist `auto`
und schließt an den Zeiger an, sodass eine Liste dort weiterzählt, wo die Folie
gerade steht.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    stagger[
      - Aufzählungszeichen und Text gehören zusammen
      - und erscheinen deshalb gemeinsam
      - Punkt für Punkt, einer je Schritt
    ]
  },
  source: ```typ
  #stagger[
    - Aufzählungszeichen und Text gehören zusammen
    - und erscheinen deshalb gemeinsam
    - Punkt für Punkt, einer je Schritt
  ]
  ```,
  width: 12cm,
)

Nummerierte Listen funktionieren genauso, mit den Zahlen an der Stelle der
Punkte. Ohne Liste im Rumpf wird dieser als ein Stück eingeblendet; mehrere
Argumente staffeln beliebige Blöcke nach denselben Regeln:

#show-example(
  rendered: {
    import "../src/lib.typ": *
    stagger(
      card(title: [Behauptung])[Die Innenwinkelsumme beträgt $180°$.],
      card(title: [Begründung])[Parallele durch einen Eckpunkt, Wechselwinkel.],
      card(title: [Beispiel])[$70° + 60° + 50° = 180°$],
    )
  },
  source: ```typ
  #stagger(
    card(title: [Behauptung])[Die Innenwinkelsumme beträgt $180°$.],
    card(title: [Begründung])[Parallele durch einen Eckpunkt, Wechselwinkel.],
    card(title: [Beispiel])[$70° + 60° + 50° = 180°$],
  )
  ```,
  width: 12cm,
)

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`start`], [erster Schritt; `auto` schließt an den Zeiger an],
  [`stride`], [Abstand der Schritte; `2` lässt je einen Schritt aus, `0` setzt
               alle Punkte auf denselben],
  [`stagger`], [zusätzliche Verzögerung je Position, in Millisekunden
                (Vorgabe 60)],
  [`enter`], [Bewegung der Punkte, wie bei `anim`],
  [`spacing`], [Abstand zwischen den Zeilen (Vorgabe 0.65 em)],
  [`dim`], [`true` lässt jeden Punkt gedämpft stehenbleiben, sobald der
            nächste kommt (Vorgabe `false`)],
)

`dim: true` macht aus der Staffelung einen Gang: Der Punkt, über den gerade
gesprochen wird, steht da, die vorherigen bleiben lesbar, aber gedämpft.

#show-code[```typ
#stagger(dim: true)[
  - Was der Raum schon weiß
  - Was er gleich lernt
  - Was er danach kann
]
```]

Dafür hält jeder Punkt genau seinen eigenen Schritt statt den Rest der Folie
und ruht danach in `after: "dimmed"` (siehe "Der gedimmte Ruhezustand"). Zwei
Dinge folgen daraus, und beide sind gewollt: Der letzte Punkt wird ebenfalls
gedimmt, sobald die Folie nach ihm noch einen Schritt hat -- dann ist der Gang
auch über ihn hinweg. Und `stride: 0`, das alle Punkte auf einen Schritt legt,
lässt sie gemeinsam auf dem nächsten dimmen.

`stride: 0` und `stagger` gehören zusammen: Alle Punkte erscheinen dann auf
einem einzigen Schritt, aber kurz nacheinander eingeschwenkt -- eine Welle
statt einer Folge.

#show-code[```typ
#stagger(stride: 0, stagger: 60)[
  - alle drei auf Schritt eins
  - der zweite 60 ms später
  - der dritte 120 ms später
]
```]

== Aufdecken in der Reihenfolge, in der es genannt wird

Manche Stichpunkte haben keine Ordnung. Was ein Graph zeigt, was an einem
Versuch auffällt, welche Rechenwege es gibt -- die Klasse nennt das in
beliebiger Folge, und ein Deck, das sie in seiner Folge aufdeckt, zwingt die
Lehrkraft, entweder zu warten oder umzusortieren.

`cue` dreht das um: die Ziffern `1` bis `9` decken auf, was gerade genannt
wurde.

// check: folie
#show-code[```typ
#cue("ablesen", start: 2)[
  - positive und negative Werte
  - tiefster und höchster Wert
  - Abnahme und Zunahme
]
```]

Die Gruppe braucht einen Namen, weil sich etwas anderes auf sie beziehen kann.
Sie verbraucht so viele Schritte, wie sie Punkte hat, und die Reihenfolge ändert
daran nichts -- Fortschritt, `info().step.total`, die Überlaufprüfung und das
Handout bleiben also unberührt.

Beim Setzen behält die Liste ihre Leserichtung: ein noch ungenannter Punkt hält
seinen Platz frei, damit nichts springt, wenn er später dazukommt.

=== Was mit dem Punkt zugleich erscheint

Ein Stichpunkt steht selten allein. `cue-layer` hängt etwas an denselben
Schritt -- eine Zeichenschicht, ein Bild, einen Satz daneben:

// check: folie davor
#show-code[```typ
#cue-layer("ablesen", 1, [dazu das Passende])
```]

Verknüpft wird dabei nichts: Punkt und Schicht teilen sich einen Schritt, und
wer den Schritt vertauscht, bewegt beide. Man kann an einen Punkt hängen, so
viel man will.

Die Gruppe muss im Quelltext *vor* ihren Schichten stehen -- eine Schicht liest
nach, welchen Schritt ihr Punkt bekommen hat. Steht sie davor, sagt das Paket
es, statt still nichts zu tun.

#tip[
  Für eine CeTZ-Zeichnung, die mit den Punkten wächst, zeichnet man das
  Gerüst einmal und jede Schicht als eigene, vollständige Zeichnung, in der
  alles andere über `cetz.draw.hide(rest, bounds: true)` unsichtbar, aber für
  den Ausschnitt maßgebend bleibt. Dann liegen alle Schichten deckungsgleich
  übereinander und der Graph steht still, egal in welcher Reihenfolge er
  wächst -- gemessen an einem Achsenkreuz mit drei Beschriftungsschichten:
  jede Teilmenge misst 347,9 pt #sym.times 329,71 pt.

  Eine Schicht trägt dabei *nur ihren eigenen Beitrag*, kein Gitter und keine
  Grundkurve. Sonst übermalt die zuletzt gesetzte Schicht die erste, und zwar
  unabhängig davon, in welcher Reihenfolge aufgedeckt wird.

  Soll die Zeichnung dagegen in der geschriebenen Reihenfolge wachsen, nimmt
  man `build` -- siehe "Eine Zeichnung, die wächst". Dort trägt jede Stufe die
  *ganze* Zeichnung, und die Frage nach dem Übermalen stellt sich nicht.
]

#info[
  Der Pfeil nach rechts deckt den nächsten *noch ungenannten* Punkt auf, in
  der geschriebenen Reihenfolge. Wer nur blättert, bekommt damit genau das
  Verhalten einer gestaffelten Liste; wer eine Ziffer drückt, bekommt diesen
  Punkt; beides mischt sich frei. Erst wenn die Gruppe voll ist, führt der
  Pfeil weiter.

  Rückwärts nimmt zurück: ein Schritt zurück gibt den zuletzt genannten Punkt
  wieder frei, und wer die Folie nach hinten verlässt, findet die Gruppe beim
  Wiederkommen unberührt vor. Sonst wäre sie nach einem Durchgang aufgebraucht.

  Die Ziffern wirken nur, solange eine adaptive Gruppe auf der Folie steht.
  In der Sprecheransicht steht jeder noch offene Punkt blass da, mit seiner
  Ziffer auf dem Aufzählungspunkt; im Saal ist er unsichtbar. Ein zweites Mal
  gedrückt tut eine Ziffer nichts -- einen Punkt zurückzunehmen ist das, wofür
  das Zurückblättern da ist.
]

== Ein einzelnes Stück auf einem eigenen Schritt

`anim` blendet beliebigen Inhalt auf bestimmten Schritten ein. Das ist das
Mittel dort, wo `#pause` nicht hinsieht -- in Rasterzellen, in Tabellen, in
Kästen -- und überall dort, wo ein Stück eine eigene Bewegung bekommen soll.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 10pt,
      anim(card[*von links* \ `enter: "fade-right"`], enter: "fade-right"),
      anim(card[*von unten* \ `enter: "rise"`], enter: "rise"),
      anim(card[*unscharf* \ `enter: "blur"`], enter: "blur"),
    )
  },
  source: ```typ
  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 10pt,
    anim(card[*von links* \ `enter: "fade-right"`], enter: "fade-right"),
    anim(card[*von unten* \ `enter: "rise"`], enter: "rise"),
    anim(card[*unscharf* \ `enter: "blur"`], enter: "blur"),
  )
  ```,
  width: 14cm,
)

Im Browser stehen die drei Karten nacheinander auf den Schritten eins, zwei und
drei, jede mit ihrer eigenen Bewegung. Auf Papier stehen sie nebeneinander --
der Platz, den sie einnehmen, ist in beiden Zielen derselbe.

=== Auftritt und Abgang

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Wert*], [*Bewegung*]),
  [`"fade"`], [nur Deckkraft; Vorgabe für `exit`],
  [`"fade-up"`], [aufblendend nach oben; Vorgabe für `enter`],
  [`"fade-down"`], [aufblendend nach unten],
  [`"fade-left"`], [aufblendend nach links, kommt also von rechts],
  [`"fade-right"`], [aufblendend nach rechts, kommt also von links],
  [`"scale"`], [wächst heran],
  [`"scale-down"`], [schrumpft zusammen],
  [`"blur"`], [schärft sich ein],
  [`"rise"`], [steigt von unten auf und wächst dabei ein wenig],
  [`"draw"`], [zeichnet sich selbst -- siehe "Ein Pfad, der sich selbst
               zeichnet"],
  [`"none"`], [ohne Bewegung -- der Inhalt ist schlicht da],
  [`"hold"`], [kein Abgang, sondern ein Warten: das Stück bleibt stehen, bis
               das nächste da ist. Als `enter` dasselbe wie `"none"`],
)

Die Himmelsrichtung im Namen ist die Bewegungsrichtung, nicht die Herkunft:
`"fade-right"` läuft nach rechts und kommt daher von links.

*Ein Name, den es nicht gibt, ist ein Fehler beim Übersetzen*, genau wie bei
`easing`. Die Laufzeit fiel früher wortlos auf `"fade"` zurück; ein Vertipper
sah danach aus wie ein Deck, das sich eben anders bewegt als gedacht -- und das
findet niemand mitten im Vortrag.

// check: folie bricht=the_package_does_not_know_that_effect
#show-code[```typ
#anim(enter: "fade-upp")[Vertippt.]   // Fehler beim Übersetzen
```]

`enter` wirkt in beide Richtungen. Beim Zurückblättern läuft derselbe Effekt
rückwärts und nimmt den Auftritt zurück -- ein Element, das von unten
hereinkam, sinkt wieder nach unten weg. `exit` betrifft nur den echten Abgang:
wenn ein Element beim Vorwärtsblättern aus seinem Bereich fällt, weil sein
Selektor ein Ende hat.

#show-code[```typ
#anim(at: "1-2", exit: "fade-down")[Nur für zwei Schritte da.]
#anim(duration: 900, delay: 200)[Langsam und ein wenig später.]
```]

`duration` ist `auto` und übernimmt damit die Vorgabe der Präsentation
(`duration:` auf `presentation`, 520). `delay` ist 0. Beide sind Zahlen in
Millisekunden und gelten für den Auftritt; beim Zurückblättern entfällt die
Verzögerung, damit der Rückweg nicht zäh wird.

=== Die Kurve

Alles, was dieses Paket bewegt, läuft auf derselben Kurve: langsam los, zügig
durch, weich aus. `easing` gibt sie einem einzelnen Element aus der Hand -- ein
Ergebnis darf über sein Ziel hinausschießen und zurückschwingen, ein Stapel
Stichpunkte darf gleichmäßig ankommen.

// check: folie pre=zeichnung
#show-code[```typ
#anim(ergebnis, enter: "rise", easing: "out-back")
#stagger(stride: 0, stagger: 60, easing: "out-quad")[
  - erst dies
  - dann das
]
```]

Sie steht überall dort, wo auch `duration` steht: bei `anim`, `stagger`,
`alternatives` und der Zeichnung in Stufen. Und sie gilt für alles, was das
Element selbst tut -- den Auftritt, den Abgang und das Dimmen. Nicht für den
Folienwechsel, der gehört der Folie und nicht dem Element; und nicht für den
Flug eines Magic Move, der zwei Enden hat und dessen Kurve nicht auf einer
Seite entschieden werden kann.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Name*], [*Kurve*]),
  [`"standard"`], [die Kurve dieses Pakets, ausgeschrieben -- dasselbe wie
                   keine Angabe],
  [`"linear"`], [gleichmäßig, ohne Anlauf und ohne Ausklang],
  [`"ease"`, `"ease-in"`, `"ease-out"`, `"ease-in-out"`],
  [die vier, die die Web Animations API von sich aus kennt],
  [`"in-quad"`, `"out-quad"`, `"in-out-quad"`], [sachte],
  [`"in-cubic"`, `"out-cubic"`, `"in-out-cubic"`], [deutlicher],
  [`"in-expo"`, `"out-expo"`, `"in-out-expo"`], [scharf -- fast alles geschieht
   an einem Ende],
  [`"in-back"`, `"out-back"`, `"in-out-back"`], [holt aus und schwingt über],
)

`in` heißt langsam los, `out` heißt weich aus. Für einen Auftritt ist fast
immer `out` das Richtige: das Auge sieht dem Ende zu und nicht dem Anfang.

*Ein Name, den es nicht gibt, ist ein Fehler beim Übersetzen* und keine stille
Vorgabe. Wer sich vertippt, bekäme sonst die Hauskurve zurück und suchte lange,
warum sein Rückschwung nicht schwingt. Die Meldung zählt auf, was zur Wahl
steht.

// check: folie pre=zeichnung bricht=the_package_does_not_know_that_curve
#show-code[```typ
#anim(ergebnis, easing: "out-bounce")   // Fehler beim Übersetzen
```]

*Die drei `back`-Kurven gehen über ihr Ziel hinaus*, und das ist ihr Zweck. Auf
einem Weg ist das der Rückschwung; auf der Deckkraft schneidet der Browser ab,
was über 1 hinausreicht, ein `easing: "out-back"` auf einem schlichten `"fade"`
ist deshalb nur ein schnelleres `"fade"`. Es lohnt sich zusammen mit einem
Effekt, der wandert: `"rise"`, `"scale"`, `"fade-up"`.

Federn und Sprünge -- `elastic`, `bounce` -- gibt es nicht. Sie sind keine
kubischen Bézierkurven, und die Web Animations API kennt nur solche; sie ließen
sich nur als Bildfolge nachbauen.

#info[
  Ohne `easing` ändert sich an einem Deck kein Byte. Der Name wird beim
  Übersetzen zu einer fertigen Kurve aufgelöst und nur dann ins Markup
  geschrieben, wenn er von der Vorgabe abweicht -- sonst trüge jedes Element
  jedes Decks ein neues Attribut. Nachgemessen an den acht Beispielen dieses
  Pakets, die keine Kurve nennen, HTML wie PDF: dieselben Bytes wie vorher.
]

=== Der gedimmte Ruhezustand

Ein Element, dessen Bereich ein Ende hat, verschwindet danach: Es blendet mit
`exit` aus und behält den Platz, den es hatte. Das ist der eine Ruhezustand
nach dem Bereich. `after: "dimmed"` gibt den zweiten. Dann geht der Punkt nicht
weg, sondern bleibt stehen und wird gedämpft gezeichnet -- lesbar, aber nicht
mehr das, worüber gerade gesprochen wird.

#show-code[```typ
#anim(at: "2-3", after: "dimmed")[Eine Randbemerkung.]
#anim(at: 4)[Und weiter im Text.]
```]

Nichts bewegt sich dabei, und umgefärbt wird auch nichts: Das Element sinkt auf
65 Prozent Deckkraft und kommt beim Zurückblättern wieder herauf. `after` hat
genau zwei Werte, `"hidden"` -- die Vorgabe und das bisherige Verhalten -- und
`"dimmed"`.

`after` braucht einen Bereich, der endet. `at: auto` und `at: 3` laufen bis zum
Ende der Folie, und was nie geht, hat kein Danach; das Paket sagt das als
Fehler, statt stillschweigend nichts zu tun. `at: "3"` ist genau dieser eine
Schritt, `at: "2-3"` ein Bereich.

Und die Folie braucht nach dem Bereich noch einen Schritt -- deshalb steht oben
die zweite Zeile. Endet der Bereich mit der Folie, gibt es keinen Schritt, auf
dem das Element gedämpft zu sehen wäre; es verhielte sich genau wie die Vorgabe,
ohne dass irgendetwas das sagt. Auch das ist ein Fehler beim Übersetzen.

*Auf dem Papier ändert `after` nichts.* Eine Seite zeigt alle Schritte auf
einmal, und ein Punkt, der nur deshalb leise ist, weil der Vortrag an ihm vorbei
ist, hat auf einem Handout kein Vorbei. Das ist dieselbe Regel, die für
`"hidden"` längst gilt: Was im Browser aus seinem Bereich fällt, steht auf dem
Papier trotzdem. Der Ausdruck der HTML-Seite aus dem Browser hält es genauso.

*Woher die 65 Prozent kommen.* Deckkraft mischt die Schrift zum Untergrund hin,
also entscheidet der Untergrund, was das Dimmen kostet -- und auf dunklem Grund
kostet es deutlich weniger als auf hellem. Das ist eine Messung, keine Meinung:
0.65 ist der kleinste Hundertstelwert, bei dem gedimmter Fließtext noch die 4,5
zu 1 erreicht, die der Kontrastvertrag dieses Pakets (siehe "Der
Kontrastvertrag") für Fließtext verlangt -- auf allen fünf mitgelieferten
Paletten, aufrecht wie umgedreht, auf dem Papier der Folie wie auf der Fläche
einer Karte. Der engste dieser zwanzig Fälle ist `parchment` auf seinem eigenen
Papier: 4,57 zu 1 bei 0.65 und 4,44 bei 0.64. Der großzügigste ist `mono`
umgedreht mit 8,60. Zwischen voll und gedimmt bleiben je nach Palette
1,94 bis 3,23 zu 1 -- je nach Palette und danach, ob das Element auf dem
Papier oder auf einer Karte steht; der Unterschied ist also überall deutlich
zu sehen.

#warning[
  Die Zusage gilt für Text in der Schriftfarbe `ink`, und das ist, worin ein
  Stichpunkt gesetzt ist. Was schon leise ist, wird durch Dimmen zu leise: eine
  Zeile in `muted` misst gedimmt 2,39 bis 4,60 zu 1, ein Wort in der
  Akzentfarbe 1,92 bis 3,03. Gedimmt gehört ein Stichpunkt, keine Beschriftung.

  Und Deckkraft mischt zu dem, was dahinterliegt. Die Zusage ist gegen `paper`
  und `surface` der Palette gemessen; über einer eigenen `card(fill: ...)` oder
  über einem Bild ist sie es nicht und kann deutlich darunter fallen. Eine
  Karte in kräftiger Füllung lag schon vor dem Dimmen bei 2,73 und geht mit
  ihm auf 2,07.
]

Ein verfolgtes Element *innerhalb* eines gedimmten übernimmt das Dimmen nur,
wenn es genau denselben Bereich hat. Das ist dieselbe Vererbung, nach der auch
`enter`, `delay` und `duration` von außen nach innen gelten: Sie greift, wenn
beide im Gleichschritt laufen, und sonst nicht. Ein `anim` mit eigenem Bereich
in einem gedimmten `anim` bleibt also voll stehen -- gemessen an einem inneren
`at: "1-"` in einem äußeren `at: "1"`.

Was ein inneres Element dagegen nie tut: früher erscheinen als das, worin es
steht. Sein Zustand wird an dem seines Wirts gedeckelt, die ganze Kette hinauf.
Ohne das stand ein `morph` in einem `anim(at: "2-")` schon auf Schritt 1 in
voller Stärke da, während sein eigener Satz noch unsichtbar war -- die Sprites
sind im Markup Geschwister, der Wirt kann also nichts verdecken. Weniger
sichtbar als sein Wirt darf ein inneres Element weiterhin sein; dafür ist sein
eigener Bereich da.

In der Praxis stehen `morph`, `video`, `embed` und `flipbook` damit ganz
außerhalb dieser Vererbung: alle vier haben `at: "1-"` als Vorgabe, einen
offenen Bereich, und ein offener kann zu einem geschlossenen nie passen. In
einem gedimmten Element bleiben sie voll stehen -- gemessen blieb ein `embed`
bei 1,00, während sein Wirt auf 0,65 ging --, und eine Formel in einer
gedimmten Zeile steht schwarz in einem grauen Satz. Wer das nicht will, gibt
dem inneren Element von Hand denselben geschlossenen Bereich oder dimmt die
Zeile nicht.

`at:` als Aufzählung behält hier seine gewohnte Bedeutung. `at: (2, 4)` mit
`after: "dimmed"` zeigt das Element auf Schritt 2, nimmt es auf 3 wieder weg,
bringt es auf 4 zurück und lässt es ab 5 gedimmt stehen. Die Lücke in der
Mitte macht die Aufzählung, nicht das Dimmen.

== Mehrere Fassungen an derselben Stelle

`alternatives` stellt mehrere Fassungen derselben Sache an denselben Ort, jede
die vorige ersetzend -- gedacht für Zwischenstände, die sich nicht bewegen,
sondern austauschen sollen.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    align(center, alternatives(
      $ (a + b)^2 $,
      $ (a + b)(a + b) $,
      $ a^2 + 2 a b + b^2 $,
    ))
  },
  source: ```typ
  #align(center, alternatives(
    $ (a + b)^2 $,
    $ (a + b)(a + b) $,
    $ a^2 + 2 a b + b^2 $,
  ))
  ```,
  width: 12cm,
)

Sie stehen in einem Kasten, der so groß ist wie die größte von ihnen, damit
ringsherum nichts springt. Jede Fassung nimmt genau einen Schritt; die letzte
bleibt bis zum Ende der Folie stehen. Auf Papier wird nur die letzte gesetzt --
in demselben Kasten, sodass die Seite die Abstände der Folie behält.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`start`], [erster Schritt; `auto` schließt an den Zeiger an],
  [`align`], [Ausrichtung im gemeinsamen Kasten (Vorgabe `top + left`)],
  [`enter`], [Bewegung beim Wechsel (Vorgabe `"fade"`)],
  [`duration`], [Dauer des Wechsels in Millisekunden],
  [`inline`], [hält die Fassungen in der laufenden Zeile],
)

#tip[
  Unterschiedlich hohe Fassungen wirken im gemeinsamen Kasten oft unruhig, weil
  die kürzeren oben kleben. `align: center + horizon` setzt jede in die Mitte
  des Kastens, und der Wechsel wird ruhig.
]

== Eine Zeichnung, die wächst

Eine CeTZ-Zeichnung und ein lilaq-Diagramm sind *ein* Stück, nicht viele. Typst
reicht den fertigen Satz heraus; was darin eine Linie und was eine Datenreihe
war, ist von außen nicht mehr zu greifen. Ein `anim` um eine einzelne Linie
gibt es deshalb nicht.

Was es gibt, ist die Zeichnung selbst -- so oft man sie haben will. `build`
ruft sie einmal je Schritt und legt die Fassungen deckungsgleich übereinander:
auf Stufe #box[$k$] steht die Zeichnung so, wie sie nach #box[$k$] Schritten
aussieht. Zu sehen ist immer genau eine.

Welches Stück wann dazukommt, sagt die Frage, die jede Stufe gereicht bekommt.
Sie heißt `ab`, weil sie dasselbe sagt wie `at:` sonst:

#show-example(
  rendered: {
    import "../src/lib.typ": *
    build(from => box(width: 260pt, height: 58pt, {
      place(bottom + left, line(length: 100%))
      place(bottom + left, line(angle: -90deg, length: 52pt))
      place(bottom + left, dx: 22%, rect(width: 12%, height: 22pt, fill: from(2, accent)))
      place(bottom + left, dx: 44%, rect(width: 12%, height: 36pt, fill: from(3, accent)))
      place(bottom + left, dx: 66%, rect(width: 12%, height: 50pt, fill: from(4, accent)))
    }), steps: 4)
  },
  source: ```typ
  #build(from => box(width: 260pt, height: 58pt, {
    place(bottom + left, line(length: 100%))
    place(bottom + left, line(angle: -90deg, length: 52pt))
    place(bottom + left, dx: 22%, rect(width: 12%, height: 22pt, fill: from(2, accent)))
    place(bottom + left, dx: 44%, rect(width: 12%, height: 36pt, fill: from(3, accent)))
    place(bottom + left, dx: 66%, rect(width: 12%, height: 50pt, fill: from(4, accent)))
  }), steps: 4)
  ```,
  width: 13cm,
)

`from(2, accent)` gibt die Farbe zurück, sobald das zweite Stück an der Reihe
ist, und sonst dieselbe Farbe mit Alpha 0. Das Achsenkreuz trägt keine Nummer
und steht deshalb von Anfang an da. `steps: 4` sagt, wie viele Stufen es
gibt; geraten wird das nicht, denn was der Zeichner mit seiner Frage anstellt,
sieht von außen niemand.

=== Warum Alpha 0 und nicht weglassen

Weil ein Stück, das fehlt, den Platz mitnimmt, den es hatte. Nachgemessen an
einer CeTZ-Zeichnung aus drei Linien, deren dritte über die beiden anderen
hinausragt, und an einem lilaq-Diagramm aus zwei Datenreihen:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Wie versteckt*], [*Was daraus wird*]),
  [weggelassen],
  [Der Platz ist weg. CeTZ misst 113 #sym.times 85 statt 198 #sym.times 170;
   bei lilaq wandert die `viewBox` von 186,58 auf 189,64, weil die Achse ohne
   die zweite Reihe andere Beschriftungen bekommt. Genau das ist der Sprung,
   den niemand will.],
  [`stroke: none`],
  [Das Maß bleibt, aber Typst schreibt den Pfad ohne jedes Strichattribut
   heraus -- aus 933 Bytes werden 831. Bei lilaq fallen damit die Marken einer
   Reihe als Geometrie mit weg, 141 Pfade statt 149.],
  [Alpha 0],
  [Das Maß bleibt, der Pfad bleibt vollständig, nur seine Farbe trägt 00:
   `stroke="#00000000"`, 935 Bytes gegen 933. Bei lilaq stehen alle 149 Pfade,
   und die `viewBox` steht auf die Stelle genau.],
)

Deshalb Alpha 0. `ab` macht daraus, was zu machen ist:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Was hineingeht*], [*Was herauskommt*]),
  [eine Farbe], [dieselbe Farbe mit Alpha 0],
  [ein Strich], [derselbe Strich mit durchsichtigem Pinsel; Dicke, Strichelung
                 und Enden bleiben, denn daran hängt das Maß],
  [ein Wörterbuch], [dasselbe Wörterbuch, in dem nur die Farben und Striche zu
                     Luft geworden sind],
  [Inhalt], [`hide(…)` -- gesetzt, aber nicht gezeichnet],
  [ein Verlauf], [nichts. Ein `gradient` hat keine Deckkraft, an der sich
                  drehen ließe; das Paket sagt es, statt es zu versuchen],
)

Was `ab` nicht umfärben kann, bekommt die Frage mit einem einzigen Argument:
`from(3)` ist wahr, sobald das dritte Stück an der Reihe ist. In CeTZ gehört
dorthin `hide(…, bounds: true)`, das ein ganzes Stück verschwinden lässt und
sein Maß behält.

=== Eine CeTZ-Zeichnung

Mit `#import "@preview/cetz:0.5.2"` daneben:

// check: folie pre=cetz
#show-code[```typ
#build(from => cetz.canvas({
  import cetz.draw: *
  line((0,0), (4,0))                          // steht von Anfang an
  line((4,0), (4,3), stroke: from(2, black))    // ab Schritt 2
  line((4,3), (0,0), stroke: from(3, 1.4pt + red))
  content((2.2, 1.8), from(4, [$c$]))
  if from(4) { circle((4,0), radius: 0.18) }
  else { hide(circle((4,0), radius: 0.18), bounds: true) }
}), steps: 4)
```]

=== Ein lilaq-Diagramm

Mit `#import "@preview/lilaq:0.6.0" as lq` daneben. Eine Datenreihe wird an
zwei Stellen zu Luft: an ihrer Farbe und an ihrer Beschriftung in der Legende.
Die zweite ist leicht zu vergessen -- der Eintrag steht sonst schon in der
Legende, während seine Kurve noch fehlt:

// check: folie pre=lilaq
#show-code[```typ
#build(from => lq.diagram(
  width: 7cm, height: 4.5cm,
  legend: (position: top + left),
  lq.plot(x, messung, color: from(1, red), label: from(1, [gemessen])),
  lq.plot(x, modell, color: from(2, blue), label: from(2, [Modell])),
), steps: 2)
```]

Weil die Reihe als Luft in den Daten stehen bleibt, rechnet lilaq seine Achsen
über beide -- die Skala steht von Anfang an fest, und die erste Kurve springt
nicht, wenn die zweite dazukommt. Wer die Reihe statt dessen weglassen würde,
bekäme mit ihr eine neue Achsenteilung.

=== Die Argumente

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`steps`], [Zahl der Stufen und damit der Schritte (Vorgabe 2)],
  [`start`], [erster Schritt; `auto` schließt an den Zeiger an],
  [`enter`], [Bewegung beim Erscheinen einer Stufe (Vorgabe `"fade"`);
              `"draw"` ist hier ein Fehler, siehe den nächsten Abschnitt],
  [`duration`], [Dauer in Millisekunden],
  [`easing`], [Kurve der Bewegung, siehe "Die Kurve"],
)

Auf Papier wird nur die letzte Stufe gesetzt, im Block derselben Größe: eine
Seite zeigt alle Schritte auf einmal, und übereinandergelegte Stufen gäben
Doppeldruck. Gemessen an einem Deck mit einer CeTZ-Zeichnung und einem
lilaq-Diagramm: die Seiten sind Bildpunkt für Bildpunkt dieselben wie die eines
Decks, das die Zeichnung schlicht hinschreibt. `build` kostet auf dem Papier
nichts.

Unter "Bewegung reduzieren" ändert sich ebenfalls nichts. Die Stufen blenden,
sie wandern nicht, und was die Einstellung wegnähme, wäre eine Bewegung, die es
hier nicht gibt.

#info[
  Warum immer nur *eine* Stufe zu sehen ist: weil sich gemalte Tinte addiert.
  Drei Stufen desselben lilaq-Diagramms übereinander, gegen dasselbe Diagramm
  einmal gesetzt -- 3,7 Prozent der Bildpunkte weichen um mehr als 8 von 255
  ab, die größte Abweichung 99. Achsen, Beschriftung und der halbdurchsichtige
  Kasten der Legende werden dreimal gemalt und werden dadurch fetter. Mit
  Stufen, die nur ihr eigenes Stück tragen, ist es nicht besser: dieselbe
  Messung ergibt 3,5 Prozent und eine größte Abweichung von 243, denn die
  Achsen gehören zu keinem Stück und stünden dann auf jeder Stufe. Eine Stufe
  auf einmal ist die einzige Anordnung, die genau das Bild ergibt, das
  dastünde, wenn man die Zeichnung einmal setzte.

  Der Preis dafür wäre der Übergang, denn zwei fast gleiche Bilder, die
  einander ablösen, blenden gegeneinander. In beide Richtungen ist das gelöst,
  und in beiden auf dieselbe Weise: die Stufe, die ohnehin dasteht, rührt sich
  nicht. Vorwärts bleibt die abtretende Stufe stehen, bis die neue vollständig
  da ist, und geht dann ohne Bewegung. Rückwärts kommt die *kleinere* Stufe
  herein und liegt vollständig unter der größeren, die noch abtritt: sie hat
  nichts zu blenden, sie ist einfach da. Was verschwindet, ist allein die
  Tinte, die die größere mehr hat.

  Nachgemessen an drei gestapelten Flächen -- die Bewegung angehalten, Bild
  für Bild abgelichtet und die Tinte am Bildpunkt gemessen: rückwärts sank
  die Tinte, die zwei Stufen teilen, auf *0,7522* und steht jetzt in beide
  Richtungen bei *1,0000*. Von Hand mit `enter: "draw"` gestapelt war die
  Senke tiefer, nämlich 0,4348, weil die Feder rückwärts über Tinte fuhr, die
  ohnehin lag; auch das ist damit weg.
]

#warning[
  Jede Stufe wird wirklich gesetzt. Vier Stufen heißen vier Layouts und vier
  SVG-Bäume in der Datei -- bei einer aufwendigen Zeichnung wächst beides
  ebenso schnell wie beim Daumenkino. Eine Zeichnung in zwanzig Stufen ist
  keine gute Idee.
]

== Ein Pfad, der sich selbst zeichnet

`enter: "draw"` lässt einen Strich *entstehen*, statt ihn einzublenden: die
Feder setzt an und fährt den Pfad ab, von seinem Anfang bis zu seinem Ende.

// check: folie pre=zeichnung
#show-code[```typ
#anim(schaltbild, enter: "draw", duration: 900)
#stagger(enter: "draw", stride: 1, achse, kurve, tangente)
```]

Das Mittel dahinter ist alt und schlicht. Ein gestrichener Pfad im SVG trägt
seine Länge in sich; `stroke-dasharray` teilt ihn in einen Strich von genau
dieser Länge und eine Lücke ebenso lang, und `stroke-dashoffset` schiebt den
Strich hinein. Bei vollem Versatz ist nichts da, bei null alles -- dazwischen
fährt eine Feder den Pfad ab.

`duration` gilt wie überall, aber eine Zeichnung will mehr Zeit als ein
Stichpunkt. 900 ist ein brauchbarer Anfang; die Vorgabe der Präsentation (520)
ist für drei lange Linien knapp.

=== Was sich abfahren lässt und was nicht

*Text nicht.* Typst setzt Glyphen als gefüllte Umrisse ohne Kontur -- ein "a"
ist eine Fläche und keine Linie, und eine Fläche hat keine Länge, an der
entlang etwas zu fahren wäre. Dasselbe gilt für alles Gefüllte: eine
Pfeilspitze, ein ausgefüllter Punkt, die Fläche einer Karte.

Deshalb ist `draw` zweierlei zugleich. *Die Striche zeichnen sich, alles übrige
blendet auf* -- so, wie es das ohne `draw` auch täte, und genau so lange. Die
Beschriftung einer Zeichnung kommt also, während die Linien entstehen, und
steht mit ihnen zusammen fertig da.

Ein Element, an dem sich *gar nichts* abfahren lässt, blendet vollständig --
aber nicht stillschweigend. Die Laufzeit sagt es in der Konsole des Browsers,
einmal je Element:

#show-code[```
typstage: enter: "draw" on slide 4 (element 2) finds no stroked path to
trace. What is drawn is an outline, and text has none: Typst sets glyphs
as filled shapes. The element fades in instead. draw is for a drawing,
the fade is for text.
```]

*Warum erst dort und nicht beim Übersetzen.* Weil Typst das SVG erst beim
Export herausgibt. Im Dokument gibt es keine Frage, die "hat dieser Inhalt eine
Kontur" beantwortete -- es ist derselbe blinde Fleck, wegen dessen dieses Paket
überhaupt mit Rechtecken in Signalfarbe arbeitet und den Browser zurückmelden
lässt, wo etwas steht. Erst im Browser steht der Pfad da und lässt sich zählen.
Der Prüflauf des Pakets liest diese Meldung mit aus, damit sie nicht eines
Tages aufhört zu kommen.

=== Alle zugleich, und wie man sie nacheinander bekommt

Alle gestrichenen Pfade eines Elements fahren *zugleich* los, und daran gibt es
nichts zu drehen. Die Reihenfolge im SVG ist die Malreihenfolge von Typst und
keine, die das Deck gewählt hätte; sie zur Erzählreihenfolge zu erklären wäre
dieselbe Anmaßung, die dieses Paket beim Magic Move ausdrücklich ablehnt, wo
Zeichen nicht nach Nachbarschaft einander zugeordnet werden. Und `duration`
wäre keine Zahl mehr, die sich lesen ließe: sieben Striche zu 900 ms
nacheinander sind 6,3 Sekunden.

Eine Reihenfolge sagt man also, statt sie zu erben. Jedes Stück bekommt seinen
eigenen Schritt:

// check: folie pre=zeichnung
#show-code[```typ
#stagger(enter: "draw", stride: 1, achse, kurve, tangente)
```]

=== Wo eine Zeichnung stehen muss

*Nicht auf dem ersten Schritt ihrer Folie.* Wer eine Folie betritt, sieht keine
Auftritte -- beim Folienwechsel stellt die Laufzeit nur den Zustand her, sonst
liefen der Folienübergang und ein Dutzend Einblendungen gegeneinander. Eine
Zeichnung auf Schritt eins stünde also einfach da. Sie braucht einen Schritt
vor sich:

// check: folie pre=zeichnung
#show-code[```typ
#anim[Erst der Satz, der die Zeichnung ankündigt.]
#anim(schaltbild, enter: "draw", duration: 900)
```]

Das gilt für jeden Effekt. Bei `draw` fällt es nur besonders auf, weil dort der
ganze Sinn im Weg steckt.

=== Wer Konturen liefert

Nachgemessen im ausgegebenen SVG, je ein Element mit `enter: "draw"`:

#table(
  columns: (1fr, auto, auto, auto),
  stroke: 0.5pt + luma(180),
  align: (left, right, right, right),
  table.header([*Gezeichnet mit*], [*Pfade*], [*gestrichen*], [*Glyphen*]),
  [cetz 0.5.2 -- drei Linien, ein Kreis, eine Beschriftung], [11], [4], [7],
  [cetz-plot 0.1.4 -- eine Funktion mit Schulbuchachsen], [59], [25], [53],
  [lilaq 0.6.0 -- zwei Datenreihen], [70], [64], [6],
  [fletcher 0.5.8 -- drei Knoten, zwei Kanten], [12], [6], [3],
  [circuiteria 0.2.1 -- zwei Blöcke, eine Leitung], [7], [3], [2],
  [Typsts eigenes `table` mit `stroke`], [13], [7], [6],
  [`line`, `rect(stroke: …)`, `circle(stroke: …)`], [3], [3], [0],
  [nur Text], [14], [0], [18],
)

Die Regel dahinter ist einfach: *was in Typst einen `stroke` bekommt, wird zu
einem Pfad mit Kontur und lässt sich abfahren; was eine `fill` bekommt, nicht.*
Ein Zeichenpaket liefert also genau so viel, wie es strichelt. Die 14 Pfade der
letzten Zeile sind keine Tinte -- es sind die Messrechtecke und Schnittmasken,
die das Paket und Typst in jede Ausgabe legen; keiner davon trägt eine Kontur.

Zwei Zahlen verdienen einen zweiten Blick. Bei `lilaq` sind 64 der 70 Pfade
gestrichen -- Gitter, Teilstriche, Rahmen und Marken gehören dazu --, und alle
64 fahren zugleich los. Das sieht nicht nach einer Zeichnung aus, die entsteht,
sondern nach einem Diagramm, das gleichmäßig hereinwischt. Bei `cetz` sind es
vier, und das ist der Fall, für den `draw` gemacht ist: wenige lange Linien,
denen ein Auge folgen kann. Für ein Diagramm ist die Zeichnung in Stufen aus
dem vorigen Abschnitt das bessere Mittel.

*Gestrichelte Linien bleiben bei der Blende.* Eine Strichelung steht in
demselben Attribut, das die Feder braucht; es zu überschreiben hieße, die
Strichelung für die Dauer der Zeichnung zu tilgen, und eine gestrichelte
Hilfslinie käme durchgezogen herein. Sie blendet also auf, während ihre
durchgezogenen Nachbarn sich zeichnen.

=== In beide Richtungen, und was an den Rändern gilt

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Wo], [Was geschieht]),
  [Zurückblättern],
  [Die Feder fährt heraus. `enter` gilt in beide Richtungen wie bei jedem
   Effekt: was sich gezeichnet hat, zeichnet sich zurück.],
  [Sprung auf einen Schritt],
  [Kein Zeichnen. Ein Sprung -- über die Adresse, über die Übersicht, beim
   Neuladen -- stellt den Endzustand her, und der ist die fertige Zeichnung.],
  [`exit: "draw"`],
  [Erlaubt und symmetrisch: ein Element, das seinen Bereich verlässt, nimmt
   seine Striche zurück, statt zu verblassen.],
  [Sprecheransicht],
  [Die Vorschau des nächsten Schritts zeigt den Ruhezustand, also die fertige
   Zeichnung. Bewegung gibt es dort keine.],
  [Papier],
  [Nichts. `enter` erreicht das PDF nie, die Zeichnung steht fertig da.
   Nachgemessen an den neun Beispielen dieses Pakets: dieselben Bytes wie ohne
   `draw`.],
  [Bewegung reduzieren],
  [Die Feder hält still, die Blende bleibt. Siehe gleich.],
)

=== Unter "Bewegung reduzieren"

Die Regel dieses Pakets lautet: *Deckkraft bleibt, Ortsveränderung fällt weg.*
Bei `draw` ist das keine Ausnahme, sondern der Regelfall in seiner reinsten
Form -- das Zeichnen *ist* der Weg. Nimmt man ihn heraus, bleibt genau die
Blende stehen, die ohnehin darunter lief, und die Zeichnung erscheint wie jedes
andere Element auch, in derselben Dauer.

Verloren geht dabei nichts, was das Argument trüge: eine Zeichnung, die
entsteht, sagt dasselbe wie eine, die dasteht, nur langsamer. Wo das einmal
nicht stimmt -- wo die Reihenfolge der Striche selbst etwas erklärt --, gehört
sie zusätzlich in Worte, und die liest auch, wer sie nicht laufen sieht.

Die Meldung über ein Element ohne Kontur kommt trotzdem. Sie gilt dem Deck und
nicht der Maschine, auf der es gerade läuft; wer die Einstellung anhat, soll
dieselbe Auskunft bekommen wie alle anderen.

=== Zusammen mit einer Zeichnung in Stufen

Beides zugleich geht nicht, und das Paket sagt es beim Übersetzen statt es zu
versuchen:

// check: folie pre=zeichnung bricht=is_at_odds_with_what_this_function_does
#show-code[```typ
#build(zeichner, enter: "draw")   // Fehler beim Übersetzen
```]

Jede Stufe einer Zeichnung aus dem vorigen Abschnitt ist die *ganze* Zeichnung.
Eine Stufe, die sich selbst zeichnete, zöge also bei jedem Schritt sämtliche
Striche noch einmal nach, auch die, die längst standen. Und sie täte es über
der abtretenden Stufe, die absichtlich stehenbleibt, bis die neue vollständig
da ist -- die Feder führe über Tinte, die schon liegt, und zu sehen wäre
nichts. Das Gegenteil dessen, was `draw` verspricht.

Rückwärts ist es dieselbe Vergeblichkeit von der anderen Seite. Dort steht die
hereinkommende Stufe sofort da, unter der, die noch abtritt, und eine Feder
liefe gar nicht erst los. Das Verbot gilt also nicht nur der einen Richtung; es
gilt beiden.

Wer eine Zeichnung wirklich Strich für Strich entstehen lassen will, gibt die
Striche als eigene Stücke hin und lässt jedes sich selbst zeichnen; wer ein
Diagramm in Stufen wachsen lassen will, lässt es bei seiner Blende.
== Eine Zeichnung, die sich bewegt

`build` lässt eine Zeichnung wachsen: Stück für Stück kommt etwas hinzu.
`scene` ist die andere Hälfte derselben Idee. Hier kommt nichts hinzu -- hier
ändert sich eine *Größe*, und das Bild hängt daran.

Die Regel in einem Satz: *das Deck schreibt eine Funktion von einem Wert auf
ein Bild und sagt, an welchen Werten der Vortrag hält. Typst rendert jeden Halt
und die Bilder dazwischen. Ein Schritt zieht das Bild von Halt zu Halt.*

// check: folie pre=szene
#show-example(
  rendered: {
    import "../src/lib.typ": *
    scene(x => box(width: 260pt, height: 64pt, {
      place(bottom + left, line(length: 100%))
      place(bottom + left, dx: 50%, line(angle: -90deg, length: 100%))
      place(horizon + left, dx: 50% + x * 8%,
            circle(radius: 7pt, fill: accent))
    }), stops: (-3, 0, 1.5, 3), tween: 8, width: 260pt, height: 64pt)
  },
  source: ```typ
  #scene(
    x => zeichnung-bei(x),
    stops: (-3, 0, 1.5, 3),   // vier Halte, drei Schritte
    tween: 8,                 // Bilder zwischen zwei Halten
  )
  ```,
  width: 13cm,
)

`stops` sind die Werte selbst, nicht `0.0` bis `1.0`. Genau das ist der
Unterschied zum Daumenkino: dort ist `t` ein Anteil an einer Laufzeit, hier ist
`x` die Größe, über die geredet wird. Wer die Tangente an der Stelle $-3$, im
Scheitel und bei $1.5$ zeigen will, schreibt diese drei Zahlen hin.

Die Szene verbraucht `stops.len() - 1` Schritte. Der erste Halt steht da,
sobald die Szene erscheint -- wie ein `morph` und anders als ein `anim` --,
jeder weitere kostet einen Tastendruck.

=== Was zu einem Halt gehört

Ein Satz daneben, eine Formel, eine zweite Zeichnung: `scene-layer` legt sich
auf den Schritt eines bestimmten Halts. Damit die Schicht ihre Szene
wiederfindet, bekommt die Szene einen Namen.

// check: folie pre=szene
#show-code[```typ
#scene("ableitung", x => tangente-an(f, x), stops: (-3, 0, 1.5, 3))

#scene-layer("ableitung", 2)[Im Scheitel ist die Steigung null.]
#scene-layer("ableitung", 4, enter: "scale")[$f'(x) = 1/2 x$]
```]

Das ist wortgleich zu `cue-layer` und aus demselben Grund: die Kopplung
fällt aus dem gemeinsamen Schritt heraus. Wer einen Halt verschiebt,
verschiebt alles mit, was daran hängt, und nirgends steht eine Zahl doppelt.
Die Szene muss dabei im Quelltext *vor* ihren Schichten stehen; steht sie
dahinter, sagt das Paket es.

=== Mehrere Größen zugleich

Ein Halt darf ein Tupel sein. Der Zeichner bekommt dann ebenso viele
Argumente:

// check: folie pre=szene
#show-code[```typ
#scene(
  (a, b) => rechteck-mit(breite: a, hoehe: b),
  stops: ((1, 1), (1, 3), (2, 3)),
  tween: 6,
)
```]

Erst wächst die Höhe, dann die Breite. Was dabei nicht geht: zwei Größen, die
sich *unabhängig* voneinander bewegen. Alles reist gemeinsam von Halt zu Halt.
In manim, wo diese Idee herkommt, könnten zwei `ValueTracker` getrennte Wege
gehen; hier gibt es nur einen Weg, und ein Tupel legt mehrere Größen darauf.

=== Die Argumente

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`stops`],
  [Die Werte, an denen der Vortrag hält. Mindestens zwei. Eine Zahl, eine
   Länge, ein Winkel, ein Anteil -- oder ein Tupel davon.],
  [`tween`],
  [Bilder *zwischen* zwei Halten (Vorgabe 8). Mit `0` springt die Szene.],
  [`start`],
  [Erster Schritt; `auto` nimmt den laufenden.],
  [`width`, `height`],
  [Der Kasten, in dem die Szene steht (Vorgabe `100%` und `190pt`).],
  [`duration`],
  [Wie lange ein Zug von Halt zu Halt dauert, in Millisekunden.],
  [`enter`],
  [Bewegung, mit der die Szene selbst auftritt (Vorgabe `"fade"`).],
  [`still`],
  [Was auf Papier steht, wenn nicht der letzte Halt.],
  [`steady`],
  [Was die Nachmessung der Bilder bedeutet: `auto` meldet, `false` nimmt die
   Szene aus der Prüfung, `true` besteht darauf. Siehe gleich.],
)

`duration` ist die Dauer des *Wegs*, nicht die der Blende, mit der die Szene
auftritt -- dieselbe Trennung, die `morph` mit seinem `duration` zieht. Beides
unter einen Namen zu legen zöge dieselbe Bewegung sichtbar auseinander.

Anders als `build` legt `scene` seine Bilder nicht übereinander. Die Stufen
einer `build`-Zeichnung liegen deckungsgleich, weil ein Stück, das noch nicht
dran ist, als Luft dasteht; die Bilder einer Szene sind Zeichnungen zu
verschiedenen Werten und dürfen ohne Weiteres verschieden groß ausfallen.
Deshalb steht eine Szene in einem Kasten fester Größe, und jedes Bild wird
darauf beschnitten. Wer `width` und `height` weglässt, bekommt die Vorgabe; wer
sie zu klein wählt, sieht es sofort.

Nachgemessen werden die Bilder trotzdem, und wozu, steht im Kasten gleich
darunter.

#warning[
  *Der Kasten steht still, die Tinte darin nicht von selbst.* Eine
  CeTZ-Leinwand wächst mit ihrem Inhalt. Reicht die Tangente bei $x = -3$
  weiter nach links als bei $x = 3$, ist die Leinwand dort breiter, und das
  Achsenkreuz sitzt an einer anderen Stelle im Kasten -- beim Blättern
  wandert dann das ganze Bild, obwohl sich nur ein Punkt bewegen sollte.
  Nachgemessen an einer Parabel mit Tangente, vier Halte und acht
  Zwischenbilder je Strecke: 28 Bilder, *19 verschiedene Lagen* der Tinte im
  Kasten.

  *Geradebiegen kann das Paket das nicht. Bemerken schon.* Jede Szene misst
  ihre Bilder nach, und weichen die Maße voneinander ab, sagt sie es mit
  Zahlen, statt den Vortragenden vor der Klasse damit zu überraschen:

  #show-code(```
  error: assertion failed: typstage: 1 scene draws frames of different sizes. …
    slide 4, from step 1: 28 frames in 19 different sizes, up to 28.35pt apart across and 53.86pt down
  ```)

  Woran das Geradebiegen scheitert, in einem Satz: `measure` antwortet mit
  einer Größe und nie damit, *wo* die Tinte darin liegt -- es gibt also keinen
  Versatz zu rechnen und nichts zu verschieben. `build` kann es, weil dort ein
  Stück, das noch nicht dran ist, als Luft dasteht und seinen Platz behält;
  hier gibt es kein gemeinsames Stück, dessen Platz zu behalten wäre, und vom
  Koordinatensystem der Zeichnung weiß `scene` nichts. Alle Bilder auf das
  größte Maß aufzupolstern hülfe nicht: der Kasten stünde dann still, die
  Leinwand darin läge trotzdem jedes Mal anders.

  Der Ausweg liegt in der Zeichnung: ihr eine feste Ausdehnung geben und das,
  was sich bewegt, darin halten. In CeTZ ist das ein `rect` mit durchsichtigem
  Strich, dieselbe Luft, mit der `ab` arbeitet:

  // check: folie pre=cetz
  ```typ
  #scene(x => cetz.canvas({
    import cetz.draw: *
    // Hält die Leinwand auf, egal wo der Punkt steht.
    rect((-4.4, -0.8), (4.4, 4.6), stroke: rgb(0, 0, 0, 0))
    line((-4, 0), (4, 0))
    circle((x, 0.25 * x * x), radius: 0.1)
  }), stops: (-3, 0, 3), height: 160pt)
  ```

  Damit steht die Breite fest. Was trotzdem hinausreicht -- eine Tangente etwa,
  die über den Rand hinausläuft --, muss gekappt werden, sonst zieht sie die
  Leinwand doch wieder auf: dieselbe Szene mit Rahmen und gekappter Tangente
  kam auf 7 Lagen statt 19, und die Breite stand auf den Punkt still.

  *Wenn die Bilder verschieden groß sein sollen*, sagt man das:
  `steady: false`. Ein Rechteck, das wächst, eine Zahl, die hochzählt -- dort
  ist der Unterschied die Sache selbst, und die Szene wird gar nicht erst
  gemessen. Umgekehrt besteht `steady: true` darauf, dass sie stillsteht, und
  bricht an Ort und Stelle ab statt am Ende des Decks. Was mit den Befunden
  geschieht, entscheidet `drift` an der Präsentation; siehe "drift".
]

Wer sich festlegen will, schreibt `steady: true`. Dann bricht die Szene an Ort
und Stelle ab, statt am Ende des Decks in einer Liste zu stehen:

// check: folie pre=cetz bricht=this_scene_draws_its
#show-code[```typ
#scene(x => cetz.canvas({
  import cetz.draw: *
  line((0, 0), (x, 0.25 * x * x))             // zieht die Leinwand mit
}), stops: (-3, 3), steady: true)             // Fehler beim Übersetzen
```]

Auf Papier steht der letzte Halt, wie bei `alternatives` -- eine Seite zeigt
alle Schritte auf einmal, und das ist der Zustand, in dem die Szene die Folie
verlässt. `still` setzt etwas anderes an seine Stelle. Der Schrittzeiger läuft
dort trotzdem, damit `info().step.total` in beiden Ausgaben dieselbe Zahl
nennt.

Unter "Bewegung reduzieren" fallen die Zwischenbilder weg: die Szene springt
von Halt zu Halt. Das ist die Regel des Pakets an jeder anderen Stelle auch --
was bleibt, ist das Ziel, was geht, ist der Weg. Siehe "Weniger Bewegung".

=== Was eine Szene kostet

Jedes Bild ist ein echtes Typst-Layout und liegt als eigener SVG-Baum in der
Datei. Die rohe Zahl allein gibt davon ein falsches Bild, deshalb stehen hier
beide.

Gemessen an einer CeTZ-Zeichnung, die eine Folie wirklich trüge: Achsen mit
Marken, eine Parabel aus 61 Stützstellen, Tangente, gestricheltes
Steigungsdreieck, zwei Beschriftungen. Typst 0.15.1, cetz 0.4.2.

#table(
  columns: (auto, auto, auto, auto),
  align: (left, right, right, right),
  stroke: 0.5pt + luma(180),
  table.header([*Bilder*], [*Übersetzung*], [*HTML roh*], [*HTML gzip*]),
  [2], [0,35 s], [238 559 B], [70 275 B],
  [6], [0,26 s], [302 054 B], [71 591 B],
  [12], [0,30 s], [397 320 B], [73 427 B],
  [24], [0,39 s], [587 817 B], [76 949 B],
  [48], [0,58 s], [968 815 B], [84 032 B],
  [96], [0,98 s], [1 730 833 B], [97 175 B],
)

Je zusätzlichem Bild: *15,9 kB roh, 286 B gzip, 8,1 ms Übersetzung.* Die Zeit
ist an der Steigung zwischen 12 und 96 Bildern abgelesen; die ersten Zeilen der
Tabelle tragen den Start des Übersetzers mit und sagen für sich genommen wenig.

Über die Leitung geht also rund ein Fünfzigstel dessen, was die rohe Zahl
befürchten lässt. Die SVG-Bäume einer Szene sind einander so ähnlich, dass gzip
98 Prozent davon wegnimmt. Eine Szene aus vier Halten und acht Zwischenbildern
je Strecke -- 28 Bilder -- kostet gegen dieselbe Zeichnung, einmal
hingeschrieben: 436 kB roh, *9 kB gzip*, 0,21 s Übersetzung. Auf Papier kostet
sie nichts: dort steht ein einziges Standbild.

#warning[
  Die gepackte Zahl ist die ehrliche, aber sie gilt nur, solange der Webserver
  auch packt. Wer die Datei per USB-Stick oder als Anhang weitergibt, trägt die
  rohe. Und die Übersetzungszeit ist immer die volle: acht Zwischenbilder je
  Strecke sind acht Layouts, ob sie sich später wegkomprimieren oder nicht.
]

*Und was das Nachmessen kostet.* Es ist ein weiteres Layout je Bild, und ein
Bild ist ein ganzes Layout -- die Rechnung verdoppelt sich also, allerdings nur
für die Bilder und nur im Browserzweig. Gemessen an derselben Szene aus 28
Bildern, fünfzehn Läufe, die schnellste Zeit: *434 ms ohne, 536 ms mit* -- rund
100 ms für die Szene, 3,6 ms je Bild. `steady: false` gibt sie einer einzelnen
Szene zurück, `drift: "none"` allen.

Warum die Prüfung trotzdem an ist, wo `overflow` es nicht ist: sie zahlt nur,
wer `scene` benutzt, und `overflow` misst jeden Rumpf jedes Decks und kostet das
1,2- bis 1,5-Fache der ganzen Übersetzung. Und was sie findet, ist beim
Schreiben unsichtbar -- jedes Bild für sich sieht richtig aus, und erst das
Blättern zeigt die wandernde Zeichnung.

#info[
  Woher die Idee kommt: `scene` ist manims `ValueTracker` zusammen mit
  `always_redraw`, ins Schrittmodell eines Vortrags übersetzt -- und die
  Übersetzung dreht ihn um. Dort ändert sich eine Zahl, während der Film läuft,
  und alles, was von ihr abhängt, wird pro Bild neu gezeichnet. Hier zeichnet
  Typst zur Übersetzungszeit, und eine Zahl kann nur an einem Schritt wechseln.
  Also werden die Bilder vorher gesetzt, und der Tastendruck fährt darüber.

  Was dabei gewonnen wird: das Bild ist eine Typst-Zeichnung, mit allem, was
  Typst kann, Formelsatz eingeschlossen, und sie bleibt in jeder Größe scharf.
  Was verloren geht: die Zwischenbilder sind gezählt und liegen in der Datei,
  und mehrere Größen können sich nicht unabhängig bewegen.
]

#info[
  *Und `.animate`?* In manim macht `obj.animate.shift(RIGHT)` aus einem
  Methodenaufruf eine Animation: man schreibt nicht den Zielzustand hin,
  sondern die Änderung. Dafür gibt es hier mit Absicht kein eigenes Wort, und
  der Grund ist nicht Bequemlichkeit, sondern was davon überhaupt übrig bliebe.

  Typst-Inhalt ist unveränderlich. Es gibt kein Objekt, an dem eine Methode
  etwas verschöbe -- `move(dx: 40pt, karte)` ist nicht dieselbe Karte an einer
  anderen Stelle, sondern ein neues Stück Inhalt. Eine typstage-Fassung von
  `.animate` könnte deshalb nur, was ein Browser mit einem *fertig gesetzten*
  Bild anstellen kann: verschieben, strecken, drehen, blenden. Alles Übrige,
  was manim unter dieser Schreibweise anbietet -- `set_color`, `set_value`,
  `become`, `next_to` --, heißt neu setzen, und neu setzen ist `scene`.

  Bliebe das Argument, dass vier Zwischenbilder weniger auch vier Bilder
  weniger sind. Es ist nachgemessen und trägt nicht. Dieselbe Bewegung -- eine
  Karte wandert nach rechts und wächst dabei -- kostet als `scene` mit acht
  Zwischenbildern *2,6 kB gepackt* über einer Folie, die dieselbe Karte nur
  hinstellt. Über zwei Folien mit `morph` geschrieben, also auf dem Weg, den
  ein Deck heute für dieselbe Geste nähme, kostet sie *12,0 kB*: die zweite
  Folie trägt Titel, Zier und alles Übrige noch einmal. Der Weg, den das Paket
  hat, ist bereits der billigere von beiden.
]

== In ein Detail hineinfahren

Manchmal ist der nächste Schritt eines Vortrags kein neuer Satz, sondern
derselbe Satz aus der Nähe: das eine Feld der Tabelle, der eine Term der
Gleichung, das eine Bauteil im Schaltbild. `camera` fährt darauf zu und wieder
weg.

Die Kamera zielt auf ein `pin`, und auf sonst nichts. Das ist der Name, den
dieses Paket ohnehin schon für ein benanntes Stück einer Folie führt, und sein
Rechteck ist genau das, was die Laufzeit zu jedem Schritt vermisst.

// check: folie
#show-code[```typ
#pin(<messwerk>, card(title: [Messwerk])[Thermoelement, Brücke, Verstärker.])

#camera(<messwerk>)
#anim[Und wieder heraus, im Schritt danach.]
```]

Dass das überhaupt geht, hat einen Grund, der eine Zeile wert ist. Typst gibt
zur Übersetzungszeit keine Geometrie heraus -- `here().position()` liefert in
der HTML-Ausgabe überall $(0, 0)$, und genau deshalb arbeitet dieses Paket mit
Rechtecken in Signalfarbe. Im Browser liegt die Sache umgekehrt: dort *müssen*
diese Rechtecke bekannt sein, sonst fände kein einziges Sprite seinen Platz.
Die Kamera hängt sich daran. Das Deck nennt einen Namen, keine Koordinate, und
wer die Folie umräumt, muss nichts nachrechnen.

=== Wie man wieder herauskommt

Gesagt, nicht geraten. `at` ist ein Schrittbereich wie überall sonst, und die
Folie wird genau so lange durch die Kamera gesehen, wie er gilt:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Geschrieben*], [*Was passiert*]),
  [`at: auto`],
  [Der nächste freie Schritt, und der danach führt wieder heraus. Die Vorgabe.],
  [`at: "3"`],
  [Hinein auf Schritt drei, heraus auf vier.],
  [`at: "3-5"`],
  [Der Ausschnitt hält über drei Schritte.],
  [`at: 3`],
  [Hinein auf Schritt drei und bleiben; der Folienwechsel führt heraus.],
)

Der Rückweg ist ein Schritt und wird als einer gezählt. Eine Folie, auf der
nichts steht als ein Pin und eine Fahrt darauf, hat drei Schritte: die ganze
Folie, den Ausschnitt, die ganze Folie. `info().step.total` sagt dieselbe Zahl,
und das Handout zählt genauso.

#info[
  `at: auto` ist hier ein *geschlossener* Bereich, bei `anim` dagegen ein
  offener. Der Unterschied ist Absicht. Ein Auftritt hat kein natürliches Ende
  -- was erschienen ist, bleibt. Eine Kamerafahrt hat eines: man kommt immer
  wieder heraus. Und niemals auf Schritt eins: Schritt eins ist die Folie, wie
  man sie betritt, und eine Fahrt dort hieße, dass niemand die Folie je ganz
  gesehen hat.
]

=== Was mitfährt und was stehenbleibt

Gefahren wird die Folie -- ihr Hintergrund und die Ebene der eingeblendeten
Teile darüber, beide gemeinsam und mit derselben Verschiebung. Die Folienzier
fährt *nicht* mit: Fußzeile, Seitenzahl, Fortschritt und laufender Kopf liegen
seit jeher als eigene Ebene über der Bühne, damit sie beim Folienwechsel nicht
mit hinausreisen. Genau das zahlt sich hier aus. Sie stehen still, während die
Folie unter ihnen größer wird, und bleiben lesbar.

Der Titel der Folie fährt dagegen mit. Er steht im Rumpf und gehört ihr.

Was aus dem Bild fährt, wird an der Kante der Bühne abgeschnitten und nicht
daneben gemalt -- dieselbe Kante, die eine überlaufende Folie beschneidet. Auch
die Tinte bleibt stehen, wo sie gezogen wurde: was jemand auf die Folie malt,
gehört nicht zur Folie.

=== Wie weit sie fährt

`margin` sagt, wie viel von der Folie um das Detail herum stehenbleibt,
gemessen an der *unverfahrenen* Folie. Die Kamera passt Detail plus Rand ins
Bild; die engere der beiden Richtungen entscheidet, damit das Ganze zu sehen
ist und nicht seine Mitte.

// check: folie
#show-code[```typ
#pin(<term>, $b^2$)
#camera(<term>, margin: 4pt, duration: 900, easing: "out-quad")
#anim[Danach.]
```]

Eine Grenze nach oben gibt es nicht. Ein Pin von der Größe eines Kommas wird
wandgroß gezeigt -- was Typst gesetzt hat, bleibt dabei scharf, weil es als
Vektor dasteht. Ein Video, ein Bild oder eine Einbettung in diesem Ausschnitt
wird es nicht.

Ein Detail, das schon so groß ist wie die Folie, gibt nichts zu fahren; dann
bleibt die Folie ganz.

=== Zwei Sonderfälle

*Zwei Pins desselben Namens auf einer Folie.* Die Kamera rahmt beide, also den
Kasten um sie herum. Das ist derselbe Fall, in dem sich bei einem `morph` eine
Glyphe sichtbar teilt, und hier ist es die Antwort auf „zeig mir diese beiden".

*Zwei Fahrten, die sich auf einem Schritt überlappen.* Die spätere im Quelltext
gewinnt. Eine Regel, die man nachlesen kann, ist besser als zwei Kameras, die
sich stumm streiten.

=== Beim Springen, beim Zurückblättern, auf Papier

Der Ausschnitt ist eine Funktion des Schritts und nichts sonst. Daraus folgt
alles Übrige von selbst:

- *Zurückblättern* fährt den Weg rückwärts und landet sauber wieder auf der
  ganzen Folie.
- *Ein Sprung* -- über die Übersicht, über `#3` in der Adresse, über einen
  Klick in der Sprecheransicht -- stellt den Ausschnitt, statt ihn zu fahren.
  Dort gibt es keinen Weg, den jemand gesehen hätte.
- *Die Sprecheransicht* zeigt die laufende Folie als das, was sie ist: dort
  steht die echte Bühne dieses Fensters, samt Fahrt. Und die Vorschau daneben
  trägt den Ausschnitt mit, denn ihre Frage ist nicht „wie sieht die Folie
  aus", sondern „was steht nach dem nächsten Tastendruck da".
- Unter *Bewegung reduzieren* springt die Kamera auf den Ausschnitt, statt
  dorthin zu fahren. Die Regel des Pakets an jeder anderen Stelle auch: was
  bleibt, ist das Ziel, was wegfällt, ist der Weg.

#warning[
  *Auf Papier gibt es keine Kamera.* Das Handout setzt jede Folie ganz, wie es
  sie ohne Fahrt setzte -- und das ist die einzige richtige Antwort: ein Blatt
  zeigt alle Schritte auf einmal, und ein Ausschnitt darauf wäre ein Blatt, auf
  dem die Hälfte fehlt. Auch die Druckansicht des Browsers (Taste `p`) setzt
  jede Folie ganz zurück.

  Daraus folgt eine Pflicht für das Deck: *die Folie muss ohne die Fahrt
  vollständig und lesbar sein.* Wer das Detail nur im Ausschnitt beschriftet
  -- eine 6-Punkt-Zeile, die man ja gleich heranholt --, hat auf Papier eine
  Zeile, die niemand liest. Die Kamera ist eine Betonung, kein Layout.
]

=== Wenn der Name nicht steht

Eine Kamera, die auf ein `pin` zielt, das es auf ihrer Folie nicht gibt, ist
ein Fehler beim Übersetzen und kein stummes Stehenbleiben:

// check: folie bricht=finds_no_pin_of_that_name
#show-code[```typ
#pin(<messwerk>, card[…])
#camera(<messerk>)          // ein Buchstabe zu wenig
```]

Gefragt wird am Ende des Dokuments und nicht an Ort und Stelle: eine Fahrt darf
vor ihrem Ziel stehen -- oft gehört sie an den Kopf der Folie --, und was auf
einer Folie steht, ist erst gesetzt, wenn sie gesetzt ist. Ein Pin auf der
Folie *davor* zählt nicht; das ist ein anderes Blatt Papier.

Eine Sache bleibt dabei offen, und sie muss offenbleiben: ein Pin, der in einem
`anim` steckt, das auf diesem Schritt noch nicht aufgedeckt ist, hat zwar ein
Rechteck, aber nichts Sichtbares darin. Die Kamera fährt dann auf eine leere
Stelle. Das kann beim Übersetzen niemand sehen -- welcher Schritt was zeigt,
entscheidet sich im Browser --, und es ist die eine Art, wie man eine Kamera
sinnlos machen kann, ohne dass das Paket etwas sagt.

#info[
  Woher die Idee kommt: manims `MovingCameraScene` bewegt die Kamera der Szene,
  `camera.frame.animate` fährt sie auf einen Ausschnitt. Der Unterschied ist,
  worauf gezielt wird. Dort ist es ein Punkt in einem Koordinatensystem, das
  die Szene selbst aufgespannt hat; hier ist es ein Stück gesetzter Text, das
  seine Lage erst im Browser bekommt -- und deshalb ein Name und keine Zahl.
]

== Drei Stolpersteine

*Nur Einblendungen zählen.* Der Zeiger zählt `anim`, `stagger`, `alternatives`
und `#pause` -- also alles, was etwas erscheinen lässt. Ein Applet, ein Video
oder ein `morph` verbraucht *keinen* Schritt und schiebt nichts weiter; solche
Elemente sind von Anfang an da. In einer zweispaltigen Folie ist das
entscheidend, denn die Stichpunkte neben einem Applet sollen bei eins beginnen
und nicht hinter dessen Bewegungen:

#show-code[```typ
#side-by-side(
  embed(url: "…", width: 100%, height: 220pt),   // kein Schritt
  stagger[
    - erster Stichpunkt                          // Schritt 1
    - zweiter Stichpunkt                         // Schritt 2
  ],
)
```]

*Ein Schritt vererbt sich nicht nach innen.* Jedes verfolgte Element trägt
seinen eigenen Schritt. Steckt eines im anderen, gilt für das innere trotzdem
dessen eigene Angabe:

#show-code(```typ
#anim(at: 3)[Ab Schritt drei -- #morph(<m>, $x^2$) aber ab Schritt eins.]
```)

Bei `morph` ist das richtig so: Das *Ziel* eines Fluges muss beim Betreten der
Folie schon stehen, sonst käme der Flug von der Vorfolie nirgends an. Bei einem
`anim` in einem `anim` ist es dagegen meist ein Versehen -- und es fällt erst
beim Blättern auf, wenn das äußere Element noch unsichtbar ist und das innere
schon steht.

*Ein Morph steht ab dem ersten Schritt.* Das ist die Vorgabe, und sie ist
meistens richtig: Ein Flugziel muss beim Betreten der Folie da sein, und weil
beim Zurückblättern die Rollen tauschen, gilt das für beide Enden einer Kette.
Daraus folgt: *ein Morph gehört nicht in etwas hinein, das erst später
erscheint.* Steht er in einer Kachel, die im zweiten Schritt kommt, dann
schwebt er schon im ersten Schritt allein an der Stelle, an der sein Behälter
erst später auftauchen wird:

#show-code(```typ
== In drei Schritten
#statement[#morph(<satz>, $a^2 + b^2 = c^2$)]   // steht ab Schritt eins
#tiles(card[…], card[…], card[…])               // erscheinen nacheinander
```)

Für das *erste* Glied einer Kette gibt es eine Ausnahme, und dafür nimmt `morph`
ein `at:`. Dort kommt kein Flug an -- die Vorfolie trägt ja keinen Morph dieses
Namens --, und beim Zurückblättern landet man auf dem *letzten* Schritt der
Folie, wo der Morph längst steht. Er darf also mit seiner Kachel erscheinen:

#show-code(```typ
== In drei Schritten
#tiles(
  card[Benennen …],
  card[#morph(<satz>, $a^2 + b^2 = c^2$, at: 2)],   // mit der zweiten Kachel
  card[Wurzel ziehen …],
)
```)

Trägt die Vorfolie doch einen gleichnamigen Morph, ginge der Flug zwischen den
beiden lautlos verloren -- die Formel erschiene einfach, statt zu fliegen. Das
Paket prüft das beim Übersetzen und sagt es, statt es geschehen zu lassen.

*Ein verschachteltes Element erbt sein Einblenden.* Steht ein verfolgtes Element
in einem anderen und erscheinen beide im selben Schritt, dann übernimmt das
innere `enter`, `duration` und `delay` vom äußeren, sofern es nichts Eigenes
angibt. Nötig ist das, weil die Bilder im Browser nebeneinander liegen und nicht
ineinander: Sie laufen nur dann im Gleichschritt, wenn sie dieselbe Bewegung mit
denselben Werten ausführen. Ohne das Erben käme ein Morph im dritten Punkt einer
gestaffelten Liste 120 Millisekunden vor seinem eigenen Stichpunkt. Wer etwas
Eigenes angibt, behält es -- und wer einen anderen Schritt wählt, erbt nichts,
denn dann sollen die beiden ja gerade nicht zusammen erscheinen.

*Ein `fr`-Abstand gehört nicht ins verfolgte Element.* `fr` heißt "Anteil an
dem, was übrig bleibt" -- und was übrig bleibt, verteilt der Elternteil unter
den Geschwistern. Ein verfolgtes Element wird aber allein gemessen und sieht
seine Geschwister nicht. Ein `#v(1fr)` unmittelbar in einem `anim` wird deshalb
durchgereicht statt verfolgt (an Leerraum ist ohnehin nichts zu animieren);
steht es zwischen anderem Inhalt, meldet das Paket einen Fehler, statt die
Folie stillschweigend verrutschen zu lassen:

// check: folie fehlt=1 weil=fr_spacer_inside_a_tracked_element
#show-code(```typ
#anim[Links #v(1fr) Rechts]        // Fehler -- das fr gehört nach draußen
#anim[Links] #v(1fr) #anim[Rechts] // so ist es gemeint
```)

Ein `fr` *innerhalb* eines Rasters ist davon nicht betroffen:
`anim(grid(rows: (1fr, 1fr), …))` verteilt das Raster unter sich selbst und
weiß daher, wovon es einen Anteil nehmen soll.

== Eine Grenze bei verfolgten Elementen

*Sehr dicke Striche.* Eine Linie misst 0pt hoch -- ihre Farbe liegt außerhalb
des Kastens. Damit ein flächenloses Element überhaupt erscheint, bekommt es eine
Schrifthöhe Luft nach jeder Seite. Was dicker aufträgt, wird beschnitten: bei
24pt Schrift und einem 60pt starken Strich bleiben von 91 Bildpunkten 72 übrig,
nachgemessen. Solche Striche gehören in einen `block` oder `rect` mit eigener
Höhe, dann gilt dessen Maß.

#info[
  Sonst braucht die Breite eines verfolgten Elements keine Aufmerksamkeit. Das
  Paket sieht dem Inhalt an, ob er den angebotenen Platz ausfüllen will -- ein
  `align` oder eine Blockgleichung will es, ein schmales Rechteck nicht --, und
  richtet sich danach. Messen genügt dafür nicht:
  `measure(align(center, rect(80pt)), width: 400pt)` liefert 80pt, nicht 400.
  Deshalb wird nachgesehen statt gemessen.

  Praktisch heißt das: `align(center, …)` in einem `anim` zentriert wie im PDF,
  und ein verfolgtes Element in einer `auto`-Rasterspalte lässt die
  `1fr`-Nachbarspalte stehen, statt sie auf null zu drücken.
]

*Was gar keine Fläche hat.* Ein senkrechter Strich misst null breit, ein
`place` misst null in beiden Richtungen und liegt außerdem gar nicht im Fluss.
Beide sind versorgt. Der Strich bekommt seine Luft wie jedes flächenlose
Element; das `place` wandert von selbst nach außen und das verfolgte Element
nach innen, damit die Marke dort steht, wo der Inhalt steht, und im Fluss
keinen Platz belegt:

// check: folie
#show-code(```typ
#anim(at: 2, place(top + left, dx: 20pt, dy: 50pt,
                   rect(width: 20pt, height: 20pt)))
```)

*Und wenn doch keines von beidem greift.* Dann sagt es die Laufzeit, statt das
Element zu verlieren. Zwei Fälle bleiben: eine Marke, die null breit oder null
hoch misst, und eine, die tiefer als vier verfolgte Elemente ineinander liegt
und deshalb keinen Ort mehr findet. Beide gehen einmal je Element in die
Konsole des Browsers:

#show-code[```
typstage: the tracked element 3 on slide 4 has a marker with no width.
Its sprite is given a viewport of that extent, and a viewport of zero
scales everything inside it to nothing: the element is in the page, with
its path and its colour, and cannot be seen. On paper it stands. Put it
in a box with a size, or give the element a width.
```]

Das ist der eine Ausgang, den es nicht geben darf: ein Deck verliert ein
Element, und nichts sagt es. Warum die Frage erst dort gestellt wird und nicht
beim Übersetzen, ist dieselbe Antwort wie bei `draw` -- ob ein Inhalt eine
Fläche hat, weiß Typst im Dokument nicht; erst im Browser liegt das Rechteck da
und lässt sich messen. Der Prüflauf des Pakets liest auch diese Meldung mit.

= Etwas vorführen statt behaupten

Ziel dieses Kapitels: eine Folie, auf der etwas geschieht, das Typst selbst
nicht bewegen kann -- eine Konstruktion, die sich verändert, ein Video, eine
gezeichnete Bewegung. Für alle drei ist mitbedacht, was auf dem Papier an ihre
Stelle tritt.

== Ein Applet neben den Stichpunkten

`geogebra()` bringt GeoGebra-Applets auf die Folie. Es war einmal ein eigenes
Paket und geht deshalb bis heute über die Brücke wie jedes fremde
Begleitpaket -- ein Deck ohne Applet trägt nichts davon mit sich.

Der übliche Aufbau einer solchen Folie: links die Konstruktion, rechts die
Stichpunkte, und darunter -- außerhalb des Layouts -- die Befehle, die das
Applet aufbauen und Schritt für Schritt weiterbewegen.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#show: presentation.with(theme: themes.lesson)

== Parametervariation

#side-by-side(
  geogebra(width: 100%, height: 330pt),
  stagger[
    - Ausgangslage: $a = 1$, die Normalparabel
    - $a = "2,5"$ -- gestreckt, schmaler und steiler
    - $a = "0,35"$ -- gestaucht, breiter und flacher
    - $a = -"1,5"$ -- gespiegelt an der $x$-Achse
  ],
)

#ggb-view(x: (-3.6, 4.6), y: (-3.4, 4.6), grid: false)
#ggb-run("a=1", "f(x)=a*x^2")
#ggb-style("f", color: accent, thickness: 6)
#ggb-tween("a", at: 2, to: 2.5, duration: 950)
#ggb-tween("a", at: 3, to: 0.35, duration: 950)
#ggb-tween("a", at: 4, to: -1.5, duration: 1300)
```]

`ggb-run` baut die Konstruktion auf, `ggb-style` gibt ihr die Farben der Folie,
und jedes `ggb-tween` lässt einen Wert auf einem Schritt an seinen neuen Wert
*laufen* statt zu springen. Die Stichpunkte daneben stehen auf denselben
Schritten: Punkt eins beschreibt das ruhende Startbild, jeder weitere die
Veränderung, die auf seinem Schritt läuft.

Kein Befehl nennt das Applet. Steht nur eines auf der Folie, finden die Befehle
es von selbst -- unabhängig davon, ob sie über oder unter ihm im Quelltext
stehen. Erst zwei Applets auf einer Folie brauchen Namen und ein `target:` an
jedem Befehl.

#tip[
  Ein Tween gehört auf Schritt 2 oder später. Beim Betreten einer Folie setzt
  die Laufzeitumgebung das Applet zurück und spielt alle Aufträge bis zum
  aktuellen Schritt *sofort* nach -- ein Tween auf Schritt 1 käme deshalb nie
  als Bewegung an. Schritt 1 ist das ruhende Startbild.
]

#info[
  Was `geogebra`, `ggb-run`, `ggb-tween` und ihre Geschwister im Einzelnen
  können, steht im Kapitel _GeoGebra_. Hier geht es nur darum, wie sie sich in
  den Ablauf einer Folie einfügen.

  Und eines gehört gleich hier gesagt: das Applet lädt zur Laufzeit von
  `geogebra.org` nach. Ohne Netz bleibt der Rahmen leer, und was darin läuft,
  steht unter GeoGebras Bedingungen.
]

== Was auf dem Papier an dieser Stelle steht

Im Browser steht dort das Applet, in der PDF bliebe ein leerer Kasten. Deshalb
nehmen sowohl `geogebra` als auch `embed` zwei Angaben, die allein die
gedruckte Ausgabe betreffen: `fallback` nimmt beliebigen Inhalt auf, der an die
Stelle des Rahmens tritt -- eine CeTZ-Zeichnung, ein Bild, eine Tabelle --, und
`link` setzt darunter eine im PDF anklickbare Adresse, über die der Leser des
Handouts zum lebenden Ding kommt. Ohne `fallback` bleibt ein Platzhalter mit
der Beschriftung aus `label`.

#show-example(
  rendered: {
    import "../src/lib.typ": embed
    embed(
      url: "https://www.geogebra.org/calculator",
      width: 100%, height: 70pt,
      link: "https://www.geogebra.org/calculator",
      label: [GeoGebra-Applet],
    )
  },
  source: ```typ
  #embed(
    url: "https://www.geogebra.org/calculator",
    width: 100%, height: 240pt,
    link: "https://www.geogebra.org/calculator",
    label: [GeoGebra-Applet],
  )
  ```,
  width: 12cm,
)

#tip[
  Eine kleine CeTZ-Skizze als `fallback` ist die Mühe wert, wo das Handout
  wirklich verteilt wird: Ein Applet, das im Unterricht die halbe Folie
  ausmacht, hinterlässt sonst ein graues Rechteck.
]

== Ein eigenes Dokument einbetten

`embed` setzt beliebige Web-Inhalte in einen abgeschotteten Rahmen: `url` lädt
eine Seite, `html` bettet ein eigenes Dokument als Text ein. Der Rahmen wird in
Folieneinheiten vermessen und mitskaliert, damit das eingebettete Dokument in
jedem Fenster denselben Ausschnitt zeigt.

#show-code[```typ
#embed(
  html: "<div style=\"height:100%;display:grid;place-items:center\">"
      + "<canvas id=\"c\" width=\"320\" height=\"200\"></canvas></div>"
      + "<script>/* zeichnet in c */</script>",
  width: 100%, height: 220pt,
  fallback: align(center + horizon, [eine laufende Zeichenfläche]),
)
```]

Ein Dokument, das mit `html` mitgegeben wird, bekommt den Grundstil des
Vortrags vorangestellt: es füllt seinen Rahmen, ist durchsichtig und trägt die
laufende Schrift -- Familie, Größe und Farbe an genau dieser Stelle des Decks.
Das lohnt sich zu wissen, denn im gezoomten Rahmen ist ein CSS-Pixel genau ein
Punkt der Folie. Wer sein Dokument in `em` bemaßt, dessen Inhalt wächst mit den
Folien mit; wer `15px` schreibt, hat unabhängig von der Fenstergröße 15 Punkte
neben einer 19-Punkt-Folienschrift stehen -- und wundert sich, warum die
Einbettung zu klein wirkt.

Der eigene Stil des Dokuments gewinnt, denn er steht dahinter. Wer den ganzen
Grundstil nicht will, schaltet ihn mit `style: false` ab und bekommt wieder
eine leere Browserseite.

#warning[
  `height: 100%` greift in einem eingebetteten Dokument nur, weil der Grundstil
  `html` und `body` eine Höhe gibt. Ein Prozentmaß braucht eine Höhe am
  Elternteil, und `body` hat von Haus aus keine. Ohne das ist der Rahmen so
  hoch wie sein Inhalt, klebt oben in der Box, und `justify-content: center`
  zentriert im Nichts.
]

Soll das eingebettete Dokument den Schritten der Folie folgen, bekommt es einen
Namen -- und `bridge-job` legt für einen Schritt einen Auftrag an diesen Namen
ab, den der Browser beim Erreichen des Schritts in den Rahmen zustellt:

#show-code[```typ
#embed(html: "…", bridge: <applet>, width: 100%, height: 240pt)
#bridge-job(<applet>, (befehl: "setze", wert: 3), at: 2)
```]

Was im Auftrag steht, ist allein Sache des Dokuments auf der anderen Seite:
`payload` ist ein Wörterbuch und wird ungelesen durchgereicht. Genau darauf
setzen die `ggb-`Befehle auf -- und jedes Begleitpaket kann es genauso tun.

#warning[
  *Das Dokument muss sich anmelden.* An einen Rahmen, der sich nie gemeldet
  hat, wird nichts zugestellt -- und zwar wortlos: keine Meldung, keine
  Warnung, das Applet sitzt einfach da. Ein Zeile genügt, und beide Felder
  werden gebraucht, denn alles ohne `typstage: 1` wird verworfen, bevor
  `ready` überhaupt angesehen wird.

  #show-code(```js
  parent.postMessage({ typstage: 1, ready: 1 }, "*");
  ```)
]

#warning[
  Beim Zurückblättern und beim Betreten einer Folie wird der ganze Lauf von
  vorn wiederholt. Aufträge müssen deshalb wiederholbar sein: "setze $a$ auf
  2,5" ist gut, "erhöhe $a$ um 1" nicht.
]

== Video

`video` legt ein echtes HTML5-Video über die Folie. Beim Betreten der Folie
läuft es an, beim Verlassen hält es an.

// check: folie dateien=welle.png
#show-code[```typ
#video("wellen.mp4", width: 100%, height: 240pt, poster: image("welle.png"))
```]

`autoplay` und `muted` sind an, `loop` und `controls` aus -- Browser lassen ein
Video von sich aus nur stumm anlaufen. `radius` rundet die Ecken; `at` und
`enter` sagen wie bei jedem Element, ab welchem Schritt es da ist und wie es
kommt.

#info[
  Auf Papier steht an dieser Stelle das `poster`, sonst eine graue Fläche. Ein
  Video ohne `poster` hinterlässt im Handout also ein leeres Rechteck.
]

== Daumenkino

`flipbook` ist der besondere Fall: Hier zeichnet Typst jedes Einzelbild. Die
Funktion `render` bekommt `t` von 0.0 bis 1.0 und gibt dazu das Bild -- alles,
was Typst kann, also auch CeTZ, Fletcher oder eine Formel. Die fertigen Bilder
liegen als SVG in der Datei und bleiben in jeder Größe scharf; der Browser
schaltet sie nur weiter.

#show-example(
  rendered: {
    import "../src/lib.typ": flipbook, accent
    flipbook(
      t => box(width: 100%, height: 100%,
        place(left + horizon, dx: t * 88%, circle(radius: 9pt, fill: accent))),
      frames: 24, fps: 20, width: 100%, height: 46pt,
    )
  },
  source: ```typ
  #flipbook(
    t => box(width: 100%, height: 100%,
      place(left + horizon, dx: t * 88%, circle(radius: 9pt, fill: accent))),
    frames: 24, fps: 20, width: 100%, height: 46pt,
  )
  ```,
  width: 12cm,
)

`frames` ist die Zahl der Einzelbilder (Vorgabe 24), `fps` das Tempo beim
Abspielen (Vorgabe 30). `loop` ist an und wiederholt von vorn; `pingpong` läuft
statt dessen vor und zurück und geht dem `loop` vor. Ist beides aus, bleibt das
letzte Bild stehen.

Die Uhr beginnt, wenn das Daumenkino zu sehen ist, und nicht, wenn seine Folie
kommt. Ein `flipbook(at: "3-", loop: false)` liegt auf den ersten beiden
Schritten auf Bild 0 still und fängt beim Aufdecken bei null an; wer
zurückblättert und es noch einmal aufdeckt, sieht es noch einmal von vorn. Auf Papier steht ein einziges: `render(0.0)`, oder was
`still` an seine Stelle setzt. Hat der Zuschauer im Betriebssystem
"Bewegung reduzieren" eingeschaltet, läuft das Daumenkino gar nicht erst los --
siehe "Weniger Bewegung".

#warning[
  Jedes Einzelbild wird wirklich gesetzt. 24 Bilder heißen 24 Layouts und 24
  SVG-Bäume in der Datei -- bei aufwendigen Zeichnungen wächst beides schnell.
]

= GeoGebra

Ziel dieses Kapitels: eine Konstruktion, die den Schritten der Folie folgt. Die
Konstruktion baut GeoGebra, die Dramaturgie kommt aus den Folien. Auf jedem
Schritt können Aufträge liegen -- Werte setzen, Objekte zeigen oder verbergen,
Farben ändern, den Ausschnitt verschieben, eine Bewegung anstoßen.

Das war einmal ein eigenes Paket, `typstage-geogebra`, und der Bauplan von
damals ist geblieben: alles hier steht auf denselben zwei öffentlichen Teilen,
die auch ein fremdes Begleitpaket benutzt -- `embed(bridge: …)` meldet einen
Rahmen als Ziel an, `bridge-job` schickt ihm auf einem Schritt etwas zu. Was in
den Aufträgen steht, liest der Kern nicht. Ein Deck ohne Applet zahlt deshalb
nichts dafür: Bootskript und Applet-Dokument entstehen erst, wenn `geogebra()`
gerufen wird, und ein Deck ohne diesen Ruf ist auf das Byte so groß wie vorher.

#warning[
  Ein gesetztes Applet lädt zur Laufzeit von `geogebra.org` nach und steht
  damit unter GeoGebras Bedingungen -- siehe „Wessen Applet das ist" am Ende
  dieses Kapitels.
]

== Schnellstart

Ein Applet steht mit `geogebra()` auf der Folie, die Befehle stehen im selben
Folienrumpf -- dort werden sie eingesammelt. Sie geben selbst nichts aus.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#presentation(
  slide([Ferngesteuert], {
    geogebra(app: "classic", perspective: "G", height: 240pt,
             link: "https://www.geogebra.org/calculator")
    ggb-run("a=1", "f(x)=a*x^2")
    ggb-set((a: 3), at: 2)
  }),
)
```]

Die Parabel steht von Anfang an da; auf Schritt 2 wird `a` auf 3 gesetzt und
sie zieht sich zusammen.

`at` ist bei allen Befehlen ein Schrittwähler wie bei `anim`: `2` heißt „ab
Schritt zwei“, `"1-2"`, `"2,4"` und `"-2"` heißen, was sie sagen. Vorgabe ist
`"1-"`, denn die meisten Aufträge richten die Konstruktion beim Betreten der
Folie ein. Der Applet-Rahmen selbst verbraucht keinen Schritt und schiebt auch
nichts weiter: die Stichpunkte neben ihm gehören auf Schritt eins, nicht hinter
seine Aufträge.

#info[
  Das Applet lebt nur im HTML-Export. Im PDF steht an seiner Stelle, was
  das Kapitel _Auf Papier_ beschreibt.
]

== Welches Applet gemeint ist

Im Schnellstart steht bei keinem Befehl ein Name. Mit einem Applet auf der
Folie gibt es nichts zu wählen, und die Befehle finden es von selbst -- gleich,
ob sie im Quelltext darüber oder darunter stehen.

Zwei Applets auf einer Folie brauchen Namen, und dann brauchen die Befehle
`target`. Der Name darf eine Zeichenkette sein oder eine Marke -- Typst färbt
sie als das, was sie ist:

#show-code[```typ
#geogebra(<links>, height: 200pt)
#geogebra(<rechts>, height: 200pt)
#ggb-run("A=(0,0)", target: <links>)
#ggb-run("B=(1,1)", target: "rechts")
```]

Fehlt die Angabe bei mehreren Applets, wird nicht geraten. Der Bau bricht ab
und nennt, was er gefunden hat:

#show-code[```
error: panicked with: typstage: 2 applets on this slide
(links, rechts) — say which one is meant, e.g. target: "links".
```]

Ebenso, wenn auf der Folie überhaupt kein Applet steht. Ein stillschweigend
fallengelassener Befehl ist weit schwerer zu bemerken als ein
fehlgeschlagener Bau.

== Die Konstruktion aufbauen

`ggb-run` nimmt beliebig viele GeoGebra-Befehle und gibt sie einzeln an
`evalCommand` weiter. Die Reihenfolge zählt: was gebraucht wird, muss vorher
entstanden sein.

// check: folie drin=applet
#show-code[```typ
#ggb-run(at: "1-",
         "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
         "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
```]

#warning[
  GeoGebras Skriptbefehle -- `SetColor`, `SetValue`, `SetVisibleInView` und
  Verwandte -- nimmt `evalCommand` *nicht* an; in `ggb-run` blieben sie
  wirkungslos. Dafür gibt es `ggb-set`, `ggb-style`, `ggb-show` und
  `ggb-hide`: sie greifen zur JavaScript-Schnittstelle, die das kann.
]

Was GeoGebra ablehnt, verschwindet nicht lautlos: das Applet meldet die
abgewiesenen Befehle zurück, und die Laufzeit schreibt sie in die Konsole des
Browsers.

Beim Betreten einer Folie und beim Zurückblättern wird der Lauf von seinem
Anfang an wiederholt -- das Applet geht dazu in seinen Ausgangszustand zurück.
Befehle sollten deshalb wiederholbar sein. Aus demselben Grund lohnt es sich,
die Farbe gleich auf `"1-"` festzulegen: beim Neuaufbau vergäbe GeoGebra sonst
die nächste Farbe seiner Palette, und die Folie sähe nach dem Zurückblättern
anders aus.

// check: folie drin=applet
#show-code[```typ
#ggb-run("a=1", "f(x)=a*x^2", at: "1-")
#ggb-style("f", at: "1-", color: dark, thickness: 3)
```]

#info[
  Eine `.ggb`-Datei lässt sich nicht einbetten: Typst kennt keine
  base64-Kodierung, und ohne sie kommt der Inhalt der Datei nie in die
  HTML-Datei. Die Konstruktion entsteht deshalb mit `ggb-run` -- oder sie wird
  über `material` von GeoGebra geladen: `geogebra(material: "abc123xy")`.
]

== Werte, Aussehen, Ausschnitt

`ggb-set` nimmt ein Wörterbuch aus Objektname und Wert, `ggb-show` und
`ggb-hide` beliebig viele Objektnamen. Üblich ist, alles zu Beginn aufzubauen
und erst sichtbar zu machen, wenn es an der Reihe ist:

// check: folie drin=applet
#show-code[```typ
#ggb-hide("P", "s", "t", at: "1-")
#ggb-show("P", "s", at: 2)
#ggb-set((a: 3), at: 2)
#ggb-set((a: -2, b: 0.5), at: 3)
```]

=== Aussehen

`ggb-style` nimmt die Objektnamen und dazu, was sich ändern soll. Alle Angaben
sind einzeln zu haben; was nicht genannt wird, bleibt, wie es ist.

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.4pt + luma(75%),
  table.header([*Angabe*], [*Wirkung*]),
  [`color`], [Farbe -- eine Typst-Farbe, keine GeoGebra-Farbe],
  [`thickness`], [Strichstärke],
  [`line-style`], [Strichart als Zahl (durchgezogen, gestrichelt, gepunktet …)],
  [`filling`], [Füllung, 0 bis 1],
  [`point-size`], [Punktgröße],
  [`trace`], [Spur an oder aus],
  [`label`], [Beschriftung sichtbar oder nicht],
  [`label-mode`], [Art der Beschriftung als Zahl (Name, Wert, Beschriftung …)],
  [`fixed`], [gegen Verschieben festhalten],
  [`caption`], [eigene Beschriftung],
  [`layer`], [Ebene, also was vor was liegt],
  [`position`], [Ort als `(x, y)`],
)

Dass `color` eine Typst-Farbe nimmt, ist der Punkt daran: die Konstruktion
trägt die Farben der Folien statt GeoGebras Palette.

// check: folie drin=applet
#show-code[```typ
#ggb-style("P", at: 2, color: accent, point-size: 6)
#ggb-style("s", at: 2, color: dark, thickness: 3)
#ggb-style("d", at: 3, color: accent, filling: 0.18, thickness: 4)
```]

=== Ausschnitt

`ggb-view` setzt den sichtbaren Bereich sowie Gitter und Achsen. `x` und `y`
wirken nur zusammen -- beide sind Paare aus kleinstem und größtem Wert.

// check: folie drin=applet
#show-code[```typ
#ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
#ggb-view(at: 3, axes: false)
```]

Das Applet nimmt die Maße des Kastens an, in dem es steht, und behält sie über
Schrittwechsel und Fenstergrößen hinweg. Wie viel Welt dabei zu sehen ist,
hängt also an `width` und `height` der `geogebra`-Zeile: ein breiter Kasten
zeigt mehr x-Bereich. Wer einen bestimmten Ausschnitt will, sagt ihn mit
`ggb-view` statt ihn sich aus der Breite zu ergeben.

== Bewegung

Es gibt zwei Arten, etwas in Bewegung zu setzen, und sie tun Verschiedenes.

`ggb-animate` startet GeoGebras eigene Animation. Sie läuft ohne Ende hin und
her, bis die Folie verlassen wird -- richtig für einen Punkt, der auf einem
Kreis umläuft, oder einen Schieberegler, der einen Zusammenhang vorführt.
`trace` schaltet die Spur der genannten Objekte ein, `speed` regelt das Tempo,
`playing: false` hält an.

// check: folie drin=applet
#show-code[```typ
#ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
```]

`ggb-tween` geht einmal von A nach B und bleibt dort. Der Browser zählt den
Wert Bild für Bild hoch; ein Objekt, das von ihm abhängt, wächst mit -- eine
Strecke, deren Endpunkt wandert, ein Bogen, dessen Winkel folgt. So zeichnet
sich die Konstruktion selbst. `from` gibt den Anfangswert, wenn er nicht der
gerade geltende sein soll, `duration` die Dauer in Millisekunden, `easing` den
Verlauf (`"ease-in-out"` oder `"linear"`).

// check: folie drin=applet
#show-code[```typ
#ggb-run("t_1=0", "s=Segment(A,(4*t_1,0))", at: "1-")
#ggb-tween("t_1", at: 2, to: 1, duration: 700)
```]

#warning[
  `ggb-tween` braucht eine Schrittnummer, keinen Bereich: `at: 2`, nicht
  `at: "2-"`. Sonst bricht der Bau mit „`ggb-tween() needs a step number`“ ab.

  Und ein Tween auf Schritt 1 käme nie als Bewegung an: beim Betreten einer
  Folie spielt die Laufzeit den Lauf bis zum aktuellen Schritt sofort nach, und
  Tweens werden dabei auf ihren Zielwert gesetzt statt abgespielt. Schritt 1
  ist zum Aufbauen da; gezeichnet wird ab Schritt 2.
]

Ab dem Schritt nach dem Tween sitzt der Wert ohnehin auf seinem Ziel. Wer
zurückblättert, sieht deshalb die fertige Zeichnung und nicht die Bewegung ein
zweites Mal.

== Auf Papier

Im PDF gibt es kein Applet. Ohne weitere Angabe bleibt ein beschrifteter
Platzhalter in der Größe des Rahmens; `link` setzt darunter den Weg zum
lebenden Applet, anklickbar im PDF.

#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  },
  source: ```typ
  #geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  ```,
  width: 12cm,
)

Besser ist eine eigene Zeichnung an seiner Stelle. `fallback` nimmt beliebigen
Inhalt -- ein Bild, eine Tabelle, und vor allem eine Zeichnung mit CeTZ:

// check: folie pre=cetz
#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    import "../src/lib.typ": dark
    import "@preview/cetz:0.5.2"
    geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
      fallback: cetz.canvas(length: 0.8cm, {
        import cetz.draw: *
        line((-2.6, 0), (2.6, 0), stroke: luma(70%))
        line((0, -0.4), (0, 2.6), stroke: luma(70%))
        line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
             stroke: dark + 1.6pt)
      }))
  },
  source: ```typ
  #geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
    fallback: cetz.canvas(length: 0.8cm, {
      import cetz.draw: *
      line((-2.6, 0), (2.6, 0), stroke: luma(70%))
      line((0, -0.4), (0, 2.6), stroke: luma(70%))
      line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
           stroke: dark + 1.6pt)
    }))
  ```,
  width: 12cm,
)

Beide Angaben wirken nur im PDF; im Browser steht dort das Applet selbst.

== Aussehen des Applets

Vorgabe ist `seamless: true`: das Applet trägt keinen eigenen Rahmen, und
seine Zeichenfläche bekommt die Farbe der Folie. Es sieht dann nicht mehr wie
ein Fenster im Fenster aus, sondern wie ein Teil der Folie. `background`
bestimmt diese Farbe; `auto` nimmt das Papierweiß der Präsentation, was auf
einer getönten Folie zu ändern ist.

#show-code[```typ
#geogebra(height: 240pt, background: rgb("#f4f1ea"))
#geogebra(height: 240pt, seamless: false)   // mit GeoGebras eigenem Rahmen
```]

#warning[
  Der Ausschnitt lässt sich mit der Hand nicht verschieben, und das ist die
  Vorgabe. Wer im Vortrag danebengreift, schöbe sonst die ganze Ebene weg, und
  die Konstruktion wäre fort -- gemeldet aus dem Gebrauch, nicht ausgedacht.
  `pan: true` gibt Verschieben und Zoomen zurück, wo sie zur Sache gehören;
  Punkte und Schieber lassen sich in beiden Fällen ziehen.
]

`font-size` ist die Schrift des Applets, gezählt in Punkten der Folie -- so wie
`width` und `height` es tun. Sie wächst deshalb mit der Folie mit, statt auf
dem Beamer in ihrer physischen Größe stehenzubleiben.

Vorgabe ist 20 und nicht GeoGebras 16. An gerenderten Bildern gemessen sind die
Achsenzahlen damit 0,71 so hoch wie der Fließtext der Folie, bei 16 nur 0,62 --
das eine ist eine untergeordnete Beschriftung, das andere ein Nachgedanke.

#warning[
  GeoGebra rastet die Größe in Stufen ein. Gemessen springt sie zwischen 20 und
  21: die Achsenzahlen gehen von 0,71 auf 1,12 des Fließtextes und sind dann so
  groß wie er. Wer einen Zwischenwert setzt, bekommt deshalb nicht unbedingt
  einen Zwischenschritt.
]

#show-code[```typ
#geogebra(height: 240pt, font-size: 22)      // größere Achsenzahlen
#geogebra(height: 240pt, pan: true)          // Ausschnitt von Hand
```]

`grid` und `axes` lassen GeoGebras Vorgabe stehen, solange sie `auto` sind,
und erzwingen sonst das eine oder andere. `perspective: "G"` zeigt nur die
Grafik-Ansicht, `app` wählt die GeoGebra-App (Vorgabe `"classic"`), `language`
die Sprache der Oberfläche, `animation-button` blendet GeoGebras Abspielknopf
ein.

#info[
  Das Applet wird von `codebase` geladen, ab Werk von `geogebra.org`. Ohne
  Netz bleibt der Rahmen leer; wer offline vorführt, legt GeoGebras Dateien
  daneben und zeigt mit `codebase` darauf.
]

=== Größe

`width` und `height` geben die Größe in den Maßen der Folie -- nicht in
Bildschirmpunkten.

Für die meisten Einbettungen spannt die Laufzeit den Rahmen in Punkten der
Folie auf und vergrößert ihn dann mit `zoom`. Ein Applet ist davon ausgenommen
und bekommt echte Bildschirmpunkte. Der Grund ist gemessen: Safari rechnet
diesen Zoom bei GeoGebra doppelt ein -- ein Leinwandpuffer von 1400 Punkten bei
253 Punkten Breite, also Zoom mal Zoom mal Bildschirmdichte. Das Applet
zeichnete zu klein, und wer die Größe dagegen korrigierte, verschob dafür den
Trefferpunkt: es zeichnete dann richtig, glaubte sich aber 704 Punkte breit,
während es 424 breit gezeigt wurde, und ein Punkt ließ sich nur noch greifen,
wenn man weit rechts daneben klickte.

Dass trotzdem in jedem Fenster derselbe Ausschnitt zu sehen ist, hängt deshalb
nicht an der Pixelzahl, sondern am Bereich. Den setzt das Applet beim ersten
Mal aus den Punktmaßen des Kastens, mit GeoGebras 50 Punkten je Einheit; danach
gilt, was `ggb-view` sagt, und eine Größenänderung lässt den Bereich stehen.

#tip[
  Zwei Applets nebeneinander stehen am besten in einem `grid`, jedes mit
  `width: 100%` und eigener Höhe.
]

== Aus der Sprecheransicht

Das Sprecherfenster von typstage führt von jedem Applet eine eigene Kopie. `m`
schaltet dort den Zeiger vom Stift auf die Einbettung um, und von da an ist das
Applet vor dem Vortragenden das lebende: einen Punkt ziehen, einen Schieber
schieben, den Ausschnitt verschieben -- die Kopie auf der Leinwand zieht nach.

Hinüber geht nur, was eine Hand bewegen kann: ein Punkt als seine Koordinaten,
ein Schieber als sein Wert. Alles, was daraus folgt, bleibt liegen, denn die
andere Kopie rechnet es sich selbst aus. Wird etwas angelegt, gelöscht oder
umbenannt, geht stattdessen die ganze Konstruktion.

#tip[
  Gemessen: ein Punkt auf einem Halbkreis meldete beim Ziehen vier Zustände je
  Bild -- den Punkt, beide Strecken und den Winkel. Die drei abhängigen sind
  nicht nur überflüssig, ihr XML definiert sie drüben neu, und das wischt die
  Spur weg, die der gezogene Punkt gerade gelegt hatte.
]

Nur was eine Hand berührt hat, wird gemeldet. Eine Animation, die ohnehin auf
beiden Seiten läuft, schickt deshalb nichts.

#warning[
  Ein Schrittwechsel setzt beide Kopien wie bisher aus der Basis zurück und
  spielt die Jobs der Folie erneut. Eine Änderung von Hand lebt also so lange
  wie der Schritt. Soll eine Position bleiben, gehört sie mit `ggb-set` ins
  Deck.
]

=== Die Tastatur

Wer das Applet anklickt, gibt ihm den Fokus, und von da an landet jede Taste
darin. Was der Kern dagegen tut, steht unter „Ein Rahmen, der den Fokus hat"
-- kurz: die Tasten des Vortrags werden aus dem Rahmen zurückgereicht, alles
übrige bleibt beim Applet. Nachgemessen hat dieses Applet für die Tastatur
ohnehin keine Verwendung: ohne Werkzeugleiste und ohne Eingabezeile ändert
keine Taste etwas an der Konstruktion.

#info[
  Sollte sich das je ändern, etwa mit eingeblendeter Werkzeugleiste, wandert
  eine mit der Tastatur gemachte Änderung mit: das Fenster, in dem die
  Spiegelung wach ist, öffnet sich auf eine Taste ebenso wie auf einen Druck.
]

#tip[
  Was sich nicht bewegen soll, gehört festgehalten. `ggb-style("A", "B",
  fixed: true)` nagelt die Punkte fest, die eine Konstruktion nur aufspannen.
  Sonst greift eine Hand im Vortrag leicht den Falschen: beim Satz des Thales
  etwa den Durchmesser statt des Punktes auf dem Halbkreis, und der ganze
  Bogen wandert mit. Gemessen am Beispiel-Deck: mit `fixed` bewegt weder ein
  Zug an A noch einer am Bogen irgendetwas, und C läuft weiter auf seiner Bahn.
]

Beim Bauen dafür lohnt ein Unterschied: `Point(k)` ist ein Punkt auf der Bahn,
den eine Hand nehmen kann; `Point(k, 0.3)` ist auf diesen Parameter festgelegt
und lässt sich gar nicht ziehen -- `isMoveable` antwortet dort mit falsch. Wo er
starten soll, sagt `position:`.

`examples/geogebra-sprecher.typ` ist ein Deck genau dazu: Thales mit einem Punkt, der über
den Halbkreis wandert, und eine Parabel mit zwei Schiebern.

== Wessen Applet das ist

Dieses Paket schickt GeoGebra nicht mit. Es setzt einen Rahmen auf die Folie,
und was darin läuft, holt der Browser beim Anzeigen von `codebase`, ab Werk
`https://www.geogebra.org/apps/`.

Daraus folgen drei Dinge, die vor dem Vortrag zu wissen sind:

+ *Ohne Netz bleibt der Rahmen leer.* Wer offline vorführt, legt GeoGebras
  Dateien daneben und zeigt mit `codebase` darauf.
+ *Das Applet steht unter GeoGebras Bedingungen*, nicht unter der MIT-Lizenz
  dieses Pakets. Die gilt für den Typst- und den Laufzeitcode hier; für
  GeoGebra gelten GeoGebras eigene Lizenz- und Nutzungsbedingungen, und für
  eine kommerzielle Verwendung sind sie zu lesen.
+ *Der Browser des Zuschauers spricht mit `geogebra.org`.* Wo das nicht
  erwünscht ist -- eine Klasse ohne Netz, ein Vortrag hinter einer Firewall,
  eine Datenschutzauflage --, ist `codebase` die Stelle, an der es sich
  umlenken lässt.

#info[
  Auf Papier ist davon nichts übrig: die PDF lädt nichts nach und zeigt, was
  unter „Auf Papier" beschrieben ist.
]

= Eine Rechnung entwickeln

Ziel dieses Kapitels: eine Umformung, der man mit den Augen folgen kann. Bei
einer Kette von Zwischenschritten ist die entscheidende Frage nicht, wie die
nächste Zeile aussieht, sondern *welches Zeichen wohin gewandert ist*. Genau
das leistet `morph`: dasselbe Objekt auf zwei Folien, und es fliegt von seinem
alten Platz an seinen neuen.

== Ein Name, zwei Folien

Mehr als ein gemeinsamer Name ist nicht nötig. Das Ding verschwindet dann nicht
und erscheint woanders neu, sondern fliegt hinüber und nimmt dabei die neue
Größe und die neue Gestalt an:

#show-code[```typ
== Der Satz des Pythagoras

#align(center, morph(<pythagoras>, $a^2 + b^2$))

== #h(0pt)

#place(center + horizon,
       morph(<pythagoras>, text(size: 2.6em)[$a^2 + b^2 = c^2$]))
```]

Der Name ist eine Zeichenkette oder eine Marke: `morph("pythagoras", …)` und
`morph(<pythagoras>, …)` bedeuten dasselbe. Die Marke liest sich besser, und
Typst färbt sie als das, was sie ist.

Ein Morph verbraucht keinen Schritt und schiebt auch keinen weiter: Er steht
von Anfang an auf seiner Folie. Auf Papier bleibt von ihm nichts als sein
Inhalt -- jede Folie setzt dort ihre eigene Fassung.

== Eine Umformungskette

Eine Rechnung über mehrere Folien folgt einem einfachen Muster: *eine Folie je
Zwischenschritt*, auf jeder derselbe Morph-Name, und darunter ein Satz, der
sagt, was gerade geschehen ist. Ein kleiner Helfer nimmt den immer gleichen
Aufbau auf:

#show-code[```typ
#let umform-dauer = 1500

#let umformung(gleichung, erklaerung) = {
  block(width: 100%, align(center, text(size: 1.9em, gleichung)))
  v(18pt)
  anim(block(width: 100%, align(center, text(size: 0.92em, erklaerung))),
       at: 2, enter: "fade-up")
}
```]

Damit besteht jede Folie der Kette aus zwei Zeilen:

// check: folgen davor
#show-code[```typ
== Die Regel am Term -- Schritt 1 von 3
#umformung(
  morph(<term>, $f(x) = 3 x^4$, duration: umform-dauer),
  [Ein Faktor $3$ und ein Exponent $4$ -- die Potenzregel behandelt
   die beiden verschieden.])

== Die Regel am Term -- Schritt 2 von 3
#umformung(
  morph(<term>, $f'(x) = 4 dot 3 x^(4 - 1)$, duration: umform-dauer),
  [Der Exponent tritt vorn als Faktor auf -- und bleibt zugleich oben
   stehen, wo nun eins abgezogen wird.])

== Die Regel am Term -- Schritt 3 von 3
#umformung(
  morph(<term>, $f'(x) = 12 x^3$, duration: umform-dauer),
  [Erst jetzt vorn ausgerechnet: $4 dot 3 = 12$.])
```]

Zwei Dinge daran sind Absicht. Erstens die *Dauer*: 1500 ms sind deutlich mehr
als die 520 ms einer gewöhnlichen Einblendung -- bei einer Umformung soll man
dem einzelnen Zeichen mit den Augen folgen können, nicht nur das Ergebnis
sehen. Zweitens steht die Erklärung auf Schritt 2: Erst fliegt der Term, dann
kommt der Satz dazu. So bleibt auf jeder Folie ein Moment, in dem nur die neue
Zeile dasteht.

Auf dem Papier setzt jede Folie ihre eigene Fassung -- die Kette wird zur
Rechnung, Zeile für Zeile:

#show-example(
  rendered: {
    import "../src/lib.typ": *
    let zeile(gleichung, erklaerung) = {
      block(width: 100%, align(center, text(size: 1.5em, gleichung)))
      v(6pt)
      block(width: 100%, align(center,
            text(size: 0.85em, fill: muted, erklaerung)))
      v(10pt)
    }
    zeile(morph(<term>, $f(x) = 3 x^4$), [Ein Faktor und ein Exponent.])
    zeile(morph(<term>, $f'(x) = 4 dot 3 x^(4 - 1)$),
          [Der Exponent tritt vorn als Faktor auf.])
    zeile(morph(<term>, $f'(x) = 12 x^3$), [Zum Schluss ausgerechnet.])
  },
  source: ```typ
  // drei aufeinanderfolgende Folien, wie sie im Foliensatz stehen
  #morph(<term>, $f(x) = 3 x^4$)
  #morph(<term>, $f'(x) = 4 dot 3 x^(4 - 1)$)
  #morph(<term>, $f'(x) = 12 x^3$)
  ```,
  width: 12cm,
)

#tip[
  Die Folientitel der Kette durchzunummerieren ("Schritt 2 von 3") kostet
  nichts und hilft im Unterricht sofort: Der Fortschrittsbalken zählt Folien,
  nicht Zwischenschritte einer Rechnung.
]

== Wenn die Zeichen falsch fliegen: pin

Die Paarung sucht sich zu jedem Zeichen der alten Folie das passende Zeichen
der neuen -- zuerst nach der *Form*, und wo das nicht reicht, nach Nähe.
Meistens stimmt das. Es stimmt nicht mehr, sobald zwei gleiche Zeichen im Spiel
sind und ausgerechnet diese die Plätze tauschen sollen: In
$f'(x) = 12 x^3 - 10 x + 2$ kann die Form nicht wissen, welche $2$ die aus
$2 x$ war -- sie verbindet die falsche, und die Zwei wandert in die Zwölf.

Dagegen hilft `pin`: Es gibt einem Stück innerhalb des Morphs einen eigenen
Namen. Gleiche Namen finden zueinander, bevor die Form befragt wird; alles
Übrige läuft weiter wie bisher.

#show-code(```typ
== Die Regel am Term -- Schritt 1 von 2
#morph(<term>, $f(x) = #pin(<faktor>)[3] x^#pin(<hoch>)[4]$)

== Die Regel am Term -- Schritt 2 von 2
#morph(<term>, $f'(x) = #pin(<hoch>)[4] dot #pin(<faktor>)[3] x^3$)
```)

#show-example(
  rendered: {
    import "../src/lib.typ": *
    align(center, {
      block(morph(<term>, text(size: 1.5em,
        $f(x) = #pin(<faktor>)[3] x^#pin(<hoch>)[4]$)))
      v(10pt)
      block(morph(<term>, text(size: 1.5em,
        $f'(x) = #pin(<hoch>)[4] dot #pin(<faktor>)[3] x^3$)))
    })
  },
  source: ```typ
  #morph(<term>, $f(x) = #pin(<faktor>)[3] x^#pin(<hoch>)[4]$)
  #morph(<term>, $f'(x) = #pin(<hoch>)[4] dot #pin(<faktor>)[3] x^3$)
  ```,
  width: 12cm,
)

Ein Pin ohne Gegenstück auf der anderen Folie fällt geräuschlos in den
Formabgleich zurück; ein Pin kostet also nichts, wo er nicht gebraucht wird.
Woran sich der Bedarf erkennen lässt: Ein Zeichen bleibt beim Blättern stehen,
obwohl es sich bewegen müsste, oder es fliegt sichtbar an die falsche Stelle.

#tip[
  In langen Ketten lohnt es, jedem wandernden Zeichen von vornherein einen Pin
  zu geben und die Namen über alle Folien der Kette durchzuhalten. Alles Übrige
  bleibt gewöhnlicher Satz und blendet mit der Folie über.
]

== Wo der Magic Move aufhört

Drei Grenzen sind zu kennen.

*Es fliegt nur zwischen benachbarten Folien.* Der Flug findet beim Blättern von
einer Folie zur unmittelbar nächsten oder vorigen statt. Sprünge -- die
Übersicht mit `o`, `Pos 1`, `Ende`, ein Sprung über die Adresszeile -- setzen
die Zielfolie ohne Bewegung. Ein Name auf Folie 3 und derselbe auf Folie 7 tun
darum nichts.

*Zwei gleiche Namen auf der Zielfolie teilen sich dieselbe Quelle.* Beide
starten sichtbar am selben Ort, das Zeichen spaltet sich vor den Augen der
Zuhörer. Wo das gewollt ist, ist es ein Mittel; wo nicht, ist es ein Fehler.
Umgekehrt gilt das nicht: Auf der Quellfolie zählt bei gleichem Namen nur der
letzte.

*Nicht alles ist Schrift.* Wie gepaart wird, sagt `match`:

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([`match`], [Bedeutung]),
  [`"auto"`],
  [Zeichenweise, sofern beide Seiten Zeichen enthalten und keine von beiden
   mehr als 48; sonst als ein Block. Die Vorgabe.],
  [`"glyph"`],
  [Immer zeichenweise, auch bei vielen Zeichen.],
  [`"block"`],
  [Immer als ein Rechteck: Das ganze Objekt wandert und wird dabei verzerrt.
   Das Richtige für Bilder, Zeichnungen und alles, was keine Schrift ist.],
)

`duration` gibt die Dauer des Fluges in Millisekunden an (Vorgabe 900). Der
Wert der Zielfolie gilt, sonst der der Quelle, sonst `duration` der
Präsentation.

== Wie die Folie selbst wechselt

`transition` bestimmt, wie eine Folie hereinkommt. Die Präsentation setzt die
Vorgabe für alle, eine einzelne Folie darf davon abweichen:

#show-code[```typ
#show: presentation.with(transition: "slide", transition-duration: 420)

== Diese eine anders
#transition("cover", from: "bottom")

// oder, in der Argumentform:
#slide([Diese eine anders], transition: (kind: "cover", from: "bottom"))[…]
```]

#table(
  columns: (auto, auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Art], [Angaben], [Was geschieht]),
  [`"none"`], [--], [Harter Schnitt.],
  [`"fade"`], [--], [Überblendung, nichts bewegt sich.],
  [`"slide"`], [`from`],
  [Die neue Folie rückt ein kurzes Stück heran und blendet dabei auf, die alte
   weicht in die Gegenrichtung.],
  [`"push"`], [`from`], [Die neue schiebt die alte über den Rand hinaus.],
  [`"cover"`], [`from`], [Die neue legt sich über die alte, die liegen bleibt.],
  [`"uncover"`], [`from`], [Die alte zieht fort und gibt die neue frei.],
  [`"zoom"`], [`direction`],
  [`"in"` lässt die neue nach vorn wachsen, `"out"` die alte nach hinten
   treten.],
  [`"blur"`], [--], [Unscharf hinüber.],
  [`"iris"`], [`direction`],
  [Eine runde Blende: `"open"` öffnet die neue Folie auf, `"close"` schließt
   die alte über ihr zu.],
  [`"wipe"`], [`direction`, `from`],
  [Dasselbe als gerade Kante; `from` nennt die Kante, an der sie beginnt.],
  [`"flip"`], [`axis`], [Umschlagen im Raum, wie ein gewendetes Blatt.],
  [`"cube"`], [`axis`],
  [Wie `flip`, aber als zwei Seiten eines Würfels, der sich weiterdreht.],
)

`from` ist `"right"` (Vorgabe), `"left"`, `"top"` oder `"bottom"`. `direction`
ist `"in"`/`"out"` bei `"zoom"` und `"open"`/`"close"` bei `"iris"` und
`"wipe"`, jeweils der erste Wert als Vorgabe. `axis` ist `"y"` (Vorgabe,
Drehung um die Senkrechte) oder `"x"`. `transition-duration` gilt für alle
Übergänge (Vorgabe 420 ms).

Drei Dinge sind an den Übergängen weniger selbstverständlich, als sie aussehen.

*Der Übergang gehört der Grenze zwischen zwei Folien, nicht der
Blätterrichtung.* Maßgeblich ist immer die Angabe der späteren der beiden
Folien -- derjenigen, die beim Vorwärtsblättern hereinkommt.

*Rückwärts läuft er als echte Umkehrung.* Nicht derselbe Übergang noch einmal,
sondern seitenverkehrt: Was hinausgeschoben wurde, kommt von derselben Seite
zurück; was sich zugezogen hat, öffnet sich wieder.

*Trifft ein Morph auf die Folie, überblendet sie.* Sobald zwischen zwei Folien
etwas fliegt, weicht der eingestellte Übergang einer schlichten Überblendung --
sonst schöbe die Folie das Objekt unter sich weg, das gerade über sie hinweg
fliegt. Für eine Umformungskette heißt das: Der Übergang muss nicht eigens
abgeschaltet werden.

#warning[
  Eine unbekannte Art bricht den Bau nicht ab, sondern wird im Browser zur
  Überblendung. Ein Tippfehler in `#transition("iirs")` fällt also erst auf,
  wenn nichts geschieht.
]

== Weniger Bewegung

Wer im Betriebssystem "Bewegung reduzieren" eingeschaltet hat, bekommt ein
ruhigeres Deck. Der Browser reicht die Einstellung als
`prefers-reduced-motion: reduce` durch, und die Laufzeit fragt sie bei jedem
Schritt und bei jedem Einzelbild neu ab: Wer sie mitten im Vortrag umlegt,
sieht die Wirkung beim nächsten Tastendruck, und ein laufendes Daumenkino hält
innerhalb eines Bildes an. Einzustellen gibt es dafür nichts, weder im Deck
noch beim Bauen.

Die Einstellung heißt "weniger Bewegung", nicht "keine Bewegung", und so ist
sie hier auch umgesetzt: *Deckkraft bleibt, Ortsveränderung fällt weg.* Eine
Einblendung sagt weiterhin "das hier ist neu" -- das ist ihre Aufgabe --, aber
nichts wandert dabei mehr über die Folie.

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([Was], [Was daraus wird]),
  [Einblendungen],
  [Jeder Effekt behält seine Deckkraft und verliert seinen Weg: `fade-up`,
   `fade-down`, `fade-left`, `fade-right`, `scale`, `scale-down`, `rise` und
   `blur` werden zur schlichten Überblendung. `fade` und `none` bleiben, wie
   sie sind. `duration` und `delay` ändern sich nicht.],
  [`enter: "draw"`],
  [Die Feder hält still, die Blende bleibt. Das Zeichnen *ist* der Weg, und
   was übrig bleibt, wenn man ihn herausnimmt, ist genau die Überblendung, die
   ohnehin darunter lief.],
  [Folienübergänge],
  [Jede Art außer `none` wird zur Überblendung, in derselben
   `transition-duration`. `none` bleibt der harte Schnitt.],
  [Magic Move],
  [Fällt aus. Es fliegt nichts, und die Folie wechselt so, wie sie es ohne
   Morph täte.],
  [Daumenkino],
  [Steht auf einem Bild still. Ohne `loop` und ohne `pingpong` ist es das
   letzte -- dort bliebe es ohnehin stehen, es fällt nur der Weg dorthin weg.
   Mit `loop` oder `pingpong` ist es das erste. `still` gilt dabei nicht: das
   Bild fürs Papier ist gesetzter Inhalt und steht gar nicht in der HTML, in
   der nur die Einzelbilder liegen.],
  [`scene`],
  [Springt von Halt zu Halt. Die Zwischenbilder liegen weiter in der Datei,
   aber es wird keines davon gezeigt. Was wegfällt, ist genau der Weg; die
   Halte selbst sind kein Weg, sondern der Inhalt.],
  [`after: "dimmed"`],
  [Bleibt. Ein Punkt, der zurücktritt, ändert seine Deckkraft und rührt sich
   nicht von der Stelle.],
  [Fortschrittsbalken der Sprecheransicht],
  [Springt auf seine neue Breite, statt hinzugleiten.],
)

Zwei Dinge bleiben mit Absicht unangetastet.

*Video.* Ein Video ist Inhalt, keine Verzierung, und es abzuschalten hieße,
etwas wegzunehmen statt es zu beruhigen. Wer nicht will, dass es von selbst
anläuft, schreibt `autoplay: false`; wer Bedienelemente gibt, überlässt die
Entscheidung dem Zuschauer.

*Eingebettete Dokumente.* Was in `embed` steckt oder über die Brücke bedient
wird, ist ein fremdes Dokument mit eigenem Stil, und die Laufzeit greift nicht
hinein. Die Einstellung erreicht es trotzdem: Auch dort ist
`matchMedia("(prefers-reduced-motion: reduce)").matches` wahr. Wer in einem
eingebetteten Dokument etwas animiert, schreibt dort also seine eigene
`@media`-Regel dafür. Im Beispiel `theme-night` tut das Ampelbrett das nicht,
und sein Blinken läuft unter der Einstellung weiter.

#info[
  Es gibt keinen Schalter, mit dem ein Deck die Einstellung überstimmt. Ein
  solcher Schalter wäre nur einen Halbsatz Arbeit, aber er beantwortete die
  falsche Frage: Ob eine Bewegung unentbehrlich ist, weiß das Paket nicht, und
  wer sie für unentbehrlich hält, schaltete ihn überall an. Wo eine Bewegung
  wirklich das Argument trägt -- das Daumenkino in `theme-default`, das eine
  Größe stetig durch die Null führt --, gehört sie zusätzlich in Worte, und die
  liest auch, wer sie nicht laufen sieht.
]

= Aus einer Quelle drei Ausgaben

Ziel dieses Kapitels: aus derselben Datei die Präsentation für die Leinwand,
den Foliensatz zum Nachlesen und das Handout zum Mitschreiben -- ohne eine
zweite Fassung zu pflegen.

== Der Foliensatz

Der PDF-Lauf ohne weitere Angabe ergibt eine Seite je Folie, in der Größe der
Leinwand. Jedes Element, das sich im Browser bewegt, steht darauf in seinem
Endzustand: Was eingeblendet wird, ist da; von mehreren Fassungen an derselben
Stelle steht die letzte. Was allein zur Bewegung gehört -- Notizen,
Folienübergänge, Aufträge an eingebettete Elemente --, sind Zustandsänderungen
ohne Ausgabe und fallen von selbst weg.

== Das Handout

Ein einziges Argument macht aus dem Foliensatz ein Handout auf A4:

#show-code[```typ
#show: presentation.with(handout: 3)   // drei Folien je Seite
```]

`handout` nimmt `true` (zwei je Seite) oder eine Zahl von 1 bis 6 und wirkt nur
auf die PDF; die HTML-Ausgabe übergeht es. Die Folien werden dabei nicht neu
gesetzt, sondern nur verkleinert -- ein Handout kann deshalb nicht von dem
abweichen, was auf der Leinwand stand.

=== Alle drei Ausgaben in einem Lauf

Seit Typst 0.15 kann eine Übersetzung mehrere Dateien schreiben. Das passt zu
diesem Paket, denn Vortrag, Foliensatz und Handout unterscheiden sich ohnehin
nur im Ziel und in einer Angabe. `bundle` schreibt alle drei auf einmal:

// check: dokument ziel=bundle
#show-code[```typ
#bundle(
  theme: themes.lesson,
  title: [Completing the Square],
  handout: "handout.pdf",
)[
  = Ein Abschnitt
  == Eine Folie
  Text.
]
```]

#show-code[```sh
typst compile --features bundle,html --format bundle vortrag.typ ausgabe
```]

`html`, `slides` und `handout` sind Dateinamen, `none` lässt die jeweilige
Ausgabe weg, `per-sheet` sind die Folien je Handout-Blatt. Alles Übrige geht
unverändert an `presentation`.

Die Zähler fangen dabei je Ausgabe neu an, nachgemessen am Foliensatz: er
nummeriert 1, 2, 3 und zählt nicht dort weiter, wo die HTML-Fassung aufgehört
hat, obwohl Typst die Introspektion über das ganze Bündel führt.

#warning[
  Zweierlei ist zu beachten. Das Bündel ist bei Typst ausdrücklich
  experimentell und ohne die Schalter `--features bundle,html` nicht zu haben.
  Und eine Datei, die `bundle` benutzt, lässt sich *nur* mit `--format bundle`
  übersetzen; ein gewöhnliches `typst compile vortrag.typ vortrag.pdf` bricht
  mit "constructing a document is only supported in the bundle target" ab. Wer
  beide Wege offenhalten will, legt den Rumpf in ein `#let` und ruft
  `presentation` von Hand.
]

Neben oder unter jeder Folie steht ihre Notiz; wo eine Folie keine hat, treten
Schreiblinien an ihre Stelle. Welches von beiden, entscheidet die Anzahl: Eine
16:9-Folie neben einer Notizspalte ist breit und niedrig, und bei bis zu zwei
Folien je Seite bliebe der größte Teil des Hochformats leer. Bis zwei stehen
die Notizen deshalb *darunter* und die Folie nimmt die volle Breite, ab drei
stehen sie *daneben*.

// Im HTML-Export wird `align` verworfen; als `rendered:` steht die Skizze
// in einem Rahmen und behält ihre Anordnung in beiden Ausgaben.
#show-example(rendered: align(center, {
  // Maßstäblich: Folie, Notizspalte und Abstände stehen im Verhältnis des
  // gesetzten Handouts, nur auf Daumennagelgröße gerechnet.
  let folie(w, h) = rect(width: w, height: h, fill: luma(93%), radius: 1pt,
                         stroke: 0.4pt + luma(65%))
  let linien(w, h, n) = block(width: w, height: h, stack(dir: ttb, spacing: h / n,
    ..range(n).map(_ => line(length: w, stroke: 0.4pt + luma(78%)))))
  let blatt(..teile) = block(width: 4cm, height: 5.7cm, inset: 3mm, radius: 2pt,
    fill: white, stroke: 0.5pt + luma(72%),
    stack(dir: ttb, spacing: 0.12cm, ..teile.pos()))
  grid(
    columns: (auto, auto), column-gutter: 1.4cm, row-gutter: 0.7em,
    align: center + top,
    blatt(..range(2).map(_ => stack(dir: ttb, spacing: 0.1cm,
      folie(3.4cm, 1.88cm), linien(3.4cm, 0.5cm, 3)))),
    blatt(..range(3).map(_ => grid(
      columns: (2.45cm, 0.89cm), column-gutter: 0.07cm, align: top,
      folie(2.45cm, 1.38cm), linien(0.89cm, 1.38cm, 6)))),
    raw("handout: true"), raw("handout: 3"),
  )
}), width: 11cm)

#tip[
  Titel- und Abschnittsfolien zählen auf dem Handout wie jede andere Folie und
  belegen einen eigenen Platz. Wer viele Abschnitte führt, rechnet sie beim
  Blattverbrauch mit.
]

== Notizen

`speaker-note` legt eine Notiz zur Folie ab. Sie steht im Folienrumpf oder als
Angabe `note` an `slide`:

#show-code[```typ
== Der Satz des Pythagoras
#speaker-note[
  Erst die Zerlegung zeigen, dann die Formel -- nicht umgekehrt.
]
```]

Im Browser holt die Taste `s` die Notiz der laufenden Folie für gut zwei
Sekunden an den unteren Rand -- sichtbar auf dem Bildschirm, der gerade
vorführt, und darum eher ein Stichwort als ein Manuskript. In die Einblendung
geht nur der reine Text ein; Auszeichnungen fallen weg.

Im Handout steht dieselbe Notiz bei ihrer Folie. Eine Notiz erfüllt damit zwei
Zwecke auf einmal: Gedächtnisstütze beim Vortrag und Erläuterung auf dem Blatt,
das die Klasse mitnimmt.

Eine Notiz muss Text tragen. Die Sprecheransicht befördert sie als
Zeichenkette, und das Handout druckt sie dort, wo Text darin steht -- eine
Notiz, die nur aus Layout besteht (ein `fit`, ein blankes `rect`, ein Bild),
käme also nirgends an. Das wird mit einer Meldung abgewiesen statt still
verschluckt. Was *gesehen* werden soll, gehört auf die Folie.

== Was auf dem Papier fehlt -- und was man dafür vorsieht

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Auf der Folie*], [*Auf dem Papier*]),
  [`anim`, `stagger`, `#pause`],
  [alles sichtbar, an derselben Stelle und im selben Platz],
  [`alternatives`],
  [nur die letzte Fassung, im gemeinsamen Kasten],
  [`morph`],
  [der Inhalt der jeweiligen Folie -- die Kette wird zur Rechnung],
  [`embed`, `geogebra`],
  [`fallback`, sonst ein Platzhalter mit `label`; darunter `link`],
  [`video`],
  [das `poster`, sonst eine graue Fläche],
  [`flipbook`],
  [ein einziges Bild: `still` oder `render(0.0)`],
  [`scene`],
  [ein einziges Bild: `still` oder der letzte Halt],
  [`speaker-note`],
  [im Handout bei der Folie, im gewöhnlichen Foliensatz nichts],
  [`transition`, `bridge-job`],
  [nichts -- sie gehören allein zur Bewegung],
)

#tip[
  Wer weiß, dass ein Handout entstehen wird, setzt `fallback` und `link` gleich
  beim Schreiben der Folie. Nachträglich muss jede eingebettete Stelle noch
  einmal aufgesucht werden.
]

== Die HTML weitergeben

Zur HTML-Ausgabe gehören zwei Dateien: eine Stilvorlage und die
Laufzeitumgebung, die die Bewegung ausführt. Wo sie herkommen, sagt `assets`:

#show-code[```typ
#show: presentation.with(assets: "inline")                          // Vorgabe
#show: presentation.with(assets: "split")
#show: presentation.with(assets: (cdn: "https://cdn.example.org/ts/"))
```]

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Wert*], [*Wirkung und Anlass*]),
  [`"inline"`], [Beide Dateien stehen im HTML. Eine einzige Datei, die sich
    verschicken, auf einen Stick legen und ohne Netz öffnen lässt. Vorgabe --
    und für den Unterricht meist die richtige Wahl.],
  [`"split"`], [Das HTML verweist auf `typstage-0.1.0.css` und
    `typstage-0.1.0.js` daneben. Angebracht, wo mehrere Vorträge in einem
    Ordner liegen: Der Browser lädt die Laufzeit einmal für alle.],
  [`(cdn: …)`], [Dieselben Namen unter der angegebenen Adresse. Für eine
    Website, die viele Vorträge trägt.],
)

#info[
  Wie viel `"split"` spart, hängt daran, wie groß das Deck selbst ist -- und bei
  einem kleinen ist es die Mehrheit. Gepackt gemessen: Laufzeit und Stilvorlage
  zusammen 78 kB; das kleinste Beispieldeck wiegt 136 kB, die Laufzeit ist also
  **57 % dessen, was über die Leitung geht**. Bei `theme-plain` sind es 27 %,
  bei `tour` 17 %.

  Mit `"split"` zahlt das *erste* Deck diese 78 kB, und jedes weitere im selben
  Ordner nichts mehr -- der Browser hat sie dann im Zwischenspeicher. Wer viele
  kurze Vorträge nebeneinander veröffentlicht, halbiert damit ungefähr, was
  seine Besucher laden.
]

Die Dateinamen führen die Version mit sich, damit mehrere Fassungen
nebeneinander liegen können und kein Browser einen neuen Vortrag aus einem
alten Zwischenspeicher bedient.

Typst legt keine Dateien an, also müssen die beiden bei `"split"` und beim CDN
einmal geschrieben werden. Ihr Inhalt steht in `runtime-files`; der
Bündel-Export gibt sie in demselben Lauf aus, in dem auch der Vortrag entsteht:

// check: ganz ziel=bundle
#show-code[```typ
#import "@schule/typstage:0.1.0": *

#document("vortrag.html", title: "Der Satz des Pythagoras")[
  #show: presentation.with(title: [Der Satz des Pythagoras], assets: "split")
  == Eine Folie
  Text auf der Folie.
]

#for datei in runtime-files {
  asset(datei.name, bytes(datei.content))
}
```]

#show-code[```bash
typst compile vortrag.typ ausgabe --format bundle --features bundle,html
```]

Im Ordner `ausgabe` liegen danach `vortrag.html` und die beiden Dateien, auf
die es verweist.

= Das eigene Aussehen

Ziel dieses Kapitels: eine Präsentation, die nach dem eigenen Fach und dem
eigenen Geschmack aussieht -- ohne dass die Bewegung darunter leidet.

== Ein fertiges Theme wählen

Das Aussehen steckt in einem *Theme*: Farben, Schriften, die Form des
Folientitels, der Fortschritt am Rand sowie Titel- und Abschnittsfolie. Fünf
sind mitgeliefert, `theme:` wählt eines aus:

#show-code[```typ
#show: presentation.with(theme: themes.lesson)
```]

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*Anlass*]),
  [`themes.default`], [Der Vortrag im hellen Saal -- dunkler Titelbalken,
    wachsender Fortschrittsbalken. Die Vorgabe.],
  [`themes.lesson`], [Der Unterricht: größere Schrift, kein Balken, der Titel
    über einem kräftigen Strich, unten eine wandernde Marke.],
  [`themes.night`], [Der abgedunkelte Raum: tiefer Grund, heller Satz, kühler
    Akzent, Fortschritt als dünne Linie an der Oberkante.],
  [`themes.plain`], [So wenig wie möglich: keine Fläche, kein Fortschritt,
    kleiner Titel und viel Luft für den Rumpf.],
  [`themes.editorial`], [Mit Charakter: Werkdruckpapier, Antiqua, Haarlinien
    -- ein Buch, keine Folie.],
)

Die fünf sind nicht dieselbe Folie in fünf Farben: Der Titel steht mal in einem
Balken, mal frei, mal unter einer Linie, und der Fortschritt wächst, wandert
oder fehlt ganz.

== Ein Theme abwandeln

Ein Theme ist ein Wörterbuch, und `+` schreibt einzelne Einträge um. Das ist
der kürzeste Weg zu einer eigenen Fassung -- etwa der Schulfarbe:

#show-code[```typ
#show: presentation.with(theme: themes.lesson + (accent: rgb("#2f7d32")))
```]

Wer alles selbst bestimmen will, baut mit `theme()` eines von Grund auf. Ohne
ein einziges Argument kommt genau die Vorgabe heraus; jedes Argument, das
gesetzt wird, ändert eine Sache:

#show-code[```typ
#let schule = theme(
  paper: rgb("#fbfaf6"),
  ink: rgb("#1c2126"),
  strong: rgb("#2b4c7e"),     // Titel, Kartenkopf, Abschnittsfläche
  accent: rgb("#e0762a"),     // Striche, Fortschritt, Merkkasten
  muted: rgb("#6b7280"),      // Fußzeile, Untertitel
  font: ("Source Sans 3", "DejaVu Sans"),
  size: 20pt,                 // Fließtext auf der Folie
  title-size: 26pt,
  header: "plain",
  rule-size: 3pt,
  footer: "fraction",
  progress: "tick",
)

#show: presentation.with(theme: schule)
```]

Die drei Bauformen der gewöhnlichen Folie:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Eintrag*], [*Werte*]),
  [`header`], [`"band"` -- farbiger Balken über die ganze Breite;
    `"plain"` -- der Titel steht auf dem Papier. Mit `rule-size` bekommt er
    eine Linie darunter. `"run"` -- eine Kopfzeile wie im Schulbuch:
    Foliennummer links, laufender Abschnitt rechts, eine Haarlinie darunter,
    und der Titel darunter. Sie liegt in derselben Ebene wie die Fußzeile und
    wandert beim Blättern nicht mit.],
  [`footer`], [`"fraction"` (3 / 12), `"number"` (3), `"center"` (mittig)
    oder `"none"`; `footer-rule` legt eine Haarlinie darüber.],
  [`progress`], [`"bar"` (wachsender Balken unten), `"top"` (dasselbe oben),
    `"tick"` (wandernde Marke auf einer Schiene) oder `"none"`.],
)

`box` sagt, wie eine `card` gebaut ist. `"bar"` ist die Vorgabe: weiße Fläche,
dünner Rahmen, farbiger Streifen mit versalem Etikett darüber. `"label"` kommt
aus dem Schulbuch: keine Kante, keine Rundung, eine getönte Fläche, und die
Beschriftung steht gemischtschriftlich in der Farbe im Kasten. Die Tönung
folgt dabei der mitgegebenen Farbe, ein blau beschrifteter Kasten steht also
auf Blau; ohne eigene Farbe gilt `surface`.

Dazu kommen `surface` und `border` für die Karten, `inverted` für hell auf
dunkel, `head-gap`, `foot-gap` und `band-height` für die Luft um den Rumpf --
und `title-slide` und `section`, die ganze Bilder sind: Funktionen
`(t, s, geo) => content`. Die vollständige Liste steht in der API-Referenz.

== Eine Palette wählen

Ein Theme sagt, wie eine Folie *gebaut* ist; eine *Palette* sagt, welche Farbe
sie hat. Beides ändert sich unabhängig voneinander: der Unterrichtsentwurf ist
auch im abgedunkelten Raum noch der Unterrichtsentwurf. Deshalb nimmt
`presentation` die Palette getrennt entgegen, und sie überschreibt
*teilweise* -- nur die Einträge, die dastehen:

#show-code[```typ
#show: presentation.with(theme: themes.lesson, palette: (accent: blue))
#show: presentation.with(theme: themes.lesson, palette: palettes.dark)
```]

Eine Palette trägt acht Einträge, und es sind genau die Farbeinträge eines
Themes: `paper` der Grund der Folie, `ink` der Fließtext, `strong` die
tragende dunkle Farbe, `accent` die Signalfarbe, `muted` das Nebensächliche,
`surface` der Grund einer Karte, `border` deren Kante und `inverted`, ob heller
Satz auf dunklem Grund steht. Ein Eintrag, den es nicht gibt, wird abgewiesen:
`palette: (acent: blue)` bricht mit einer Meldung ab, statt still nichts zu
tun.

Fünf Paletten sind mitgeliefert. Jede läuft mit jedem der fünf Themes:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Palette*], [*Woher*]),
  [`palettes.light`], [Genau die Farben von `themes.default`. Diese Palette
    ändert an der Vorgabe nichts.],
  [`palettes.mono`], [Das Grau von `themes.plain`, zwei Töne verschoben,
    damit es den Vertrag unten besteht.],
  [`palettes.textbook`], [Die am Schulbuch gemessenen Farben von
    `themes.lesson`, ein Grau verschoben.],
  [`palettes.parchment`], [Das Werkdruckpapier von `themes.editorial`, zwei
    Töne verschoben.],
  [`palettes.dark`], [Der dunkle Grund von `themes.night`, mit einem
    tieferen Akzent.],
)

Daraus folgt der Satz, der sonst ein eigenes Theme kostet: *ein weiteres
dunkles Theme braucht es nicht, weil Dunkelheit eine Palette ist und keine
Gestaltung.* `themes.lesson` mit `palettes.dark` ist weiterhin der
Unterrichtsentwurf, nur dunkel.

`themes.night` bleibt trotzdem ein Theme, und der Grund ist gemessen. Sein
Zyan `#5ec8f2` trägt die Überschrift auf dem eigenen Grund mit 9,77 zu 1 und
auf dem Grund, den eine umgedrehte Folie dahinterlegt, mit 1,59. Eine Farbe,
die auf beiden hält, müsste bei etwa 0,13 bis 0,23 relativer Leuchtdichte
liegen; das Zyan liegt bei 0,52. Also nimmt `palettes.dark` ein tieferes Blau,
das auf beiden hält, und `themes.night` behält das Zyan, um das herum es
entworfen wurde.

#warning[
  Zwei Farben eines Themes sind keine Paletteneinträge: `title-fill` und
  `rule-fill`. Ob sie mitfolgen, entscheidet das Theme. Alle fünf
  mitgelieferten lassen sie mitfolgen -- entweder als Funktion der Palette,
  `title-fill: p => p.strong`, oder als `none`, was den Akzent meint und mit
  ihm wandert. Beide haben dafür den Typ gewechselt: `themes.X.title-fill`
  *auszulesen* ergab früher eine Farbe und ergibt jetzt eine Funktion, und
  `rule-fill` ergibt `none`, wo es den Akzent ergab. Sie zu *schreiben*,
  `themes.X + (title-fill: red)`, ist unverändert. Ein eigenes Theme,
  das dort eine feste Farbe hinschreibt, behält sie unter jeder Palette. Das
  ist Absicht: eine Farbe, die jemand ausdrücklich genannt hat, wird nicht
  hinter seinem Rücken getauscht.
]

Und `themes.night` bleibt trotzdem ein Theme. Sein Zyan `#5ec8f2`
misst 9,77 zu 1 auf dem dunklen Grund und deshalb leuchtet es dort, aber nur
1,59 zu 1 auf seiner eigenen Schriftfarbe -- und genau die liegt hinter dem
Akzent, sobald eine Folie umgedreht wird. `palettes.dark` nimmt darum einen
tieferen Ton. Das Theme behält seinen; es ist eine Gestaltungsentscheidung,
und sie ist gemessen, nicht übersehen.

== Die Farben eines Themes

Sechs Rollen tragen ein Theme: `paper` der Grund der Folie, `ink` der
Fließtext, `strong` die tragende dunkle Farbe, `accent` die Signalfarbe,
`muted` das Nebensächliche, `surface` der Grund einer Karte. Mit `border` und
`inverted` sind es dieselben acht Einträge, die auch eine Palette trägt. Die
mitgelieferten Themes belegen sie verschieden:

#show-example(
  rendered: {
    import "../src/lib.typ": themes
    let feld(c) = block(width: 1.5cm, height: 0.8cm, fill: c,
                        stroke: 0.4pt + luma(70%), radius: 2pt)
    table(
      columns: (auto, auto, auto, auto, auto),
      stroke: none,
      align: (left + horizon, center, center, center, center),
      inset: 5pt,
      table.header([], raw("paper"), raw("strong"), raw("accent"), raw("muted")),
      ..("default", "lesson", "night", "plain", "editorial").map(n => {
        let t = themes.at(n)
        (raw(n), feld(t.paper), feld(t.strong), feld(t.accent), feld(t.muted))
      }).flatten(),
    )
  },
  source: ```typ
  #import "@schule/typstage:0.1.0": themes
  #themes.night.accent      // die Signalfarbe des Themes, als Farbe
  ```,
  width: 12cm,
)

`card` und `callout` holen sich ihre Farben von selbst aus dem laufenden
Theme; ein Wechsel des Themes färbt sie mit um. Wo eine einzelne Karte anders
aussehen soll, nimmt sie `color:` und `fill:` entgegen.

#tip[
  Eine eigene Bedeutungsfarbe -- blau für die Funktion, orange für ihre
  Steigung -- wird am besten einmal oben in der Datei festgelegt und dann
  überall mitgegeben, wo sie hingehört: `card(color: …)`, `callout(color: …)`,
  `ggb-style(color: …)`. Farbige Bedeutung, die über die ganze Präsentation
  durchgehalten wird, trägt mehr als jeder Übergang.
]

Unabhängig vom Theme gibt das Paket vier Farbkonstanten heraus -- `dark`,
`accent`, `paper` und `muted` --, die Palette des Vorgabe-Aussehens. Sie sind
handlich, wo eine Folie einen Farbton braucht und das Theme nicht gewechselt
wird; wer das Theme tauscht, greift besser auf dessen Einträge zu.

== Eine Folie umdrehen

Für die eine Folie, die nur eine große Zahl trägt, gibt es `invert`. Der Grund
wird zur Schriftfarbe der Palette, der Satz zu ihrem Grund; `muted`, `border`
und `surface` werden aus diesen beiden gemischt, `strong` und `accent` gehen
unverändert mit. Das Chrom zieht mit: Kopfzeile, Fußzeile, Foliennummer und
Fortschrittsbalken stehen in denselben Farben wie die Folie unter ihnen. Karte
und Merkkasten ebenso.

In der Überschriftenschreibweise steht `#invert` im Rumpf der Folie, so wie
`#pause`:

#show-code[```typ
== Erreicht bis 2026
#invert
#statement[74 %]
```]

In der Argumentschreibweise ist es ein Argument von `slide`:

// check: argument
#show-code[```typ
#slide([Erreicht bis 2026], invert: true)[#statement[74 %]]
```]

#warning[
  Nur eine gewöhnliche Folie dreht sich um. Titel- und Abschnittsfolie sind
  ganze Bilder, die das Theme selbst malt, und drei der fünf mitgelieferten
  bauen sie aus Farben, an die eine Umkehrung nicht heranreicht; beide nehmen
  das Argument deshalb nicht an.

  Die Marke `#invert` wird überall dort gefunden, wo der Rumpf begehbar ist:
  auf der obersten Ebene, in einem `block` oder `align`, in einer
  Tabellenzelle, in einem Raster, beliebig tief geschachtelt, in der
  Folienüberschrift selbst und hinter `#set`- und `#show`-Regeln. *Nicht*
  gefunden wird sie dort, wo der Inhalt an eine Closure abgegeben wird, in die
  der Lauf nicht hineinkommt -- in `context`, `fit`, `anim`, `card` und
  `alternatives` --, und die Folie bleibt dann einfach stehen, wie sie ist,
  ohne ein Wort. Gemessen sind das genau diese fünf. Wer eine davon braucht,
  schreibt die Folie als `slide(invert: true)`, was nie am Lauf hängt.
]

== Der Kontrastvertrag

Die mitgelieferten Paletten werden gemessen, bevor sie ausgeliefert werden.
Gerechnet wird der echte WCAG-2-Kontrast: jeder Kanal linearisiert, daraus die
relative Leuchtdichte $0.2126 R + 0.7152 G + 0.0722 B$, und aus zwei Dichten
das Verhältnis $(L_"hell" + 0.05) \/ (L_"dunkel" + 0.05)$. Sieben Paarungen
werden geprüft:

#table(
  columns: (auto, auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Paarung*], [*Mindestens*], [*Wofür*]),
  [`ink` auf `paper`], [4,5], [Fließtext auf der Folie],
  [`ink` auf `surface`], [4,5], [Fließtext in einer Karte],
  [`muted` auf `paper`], [4,5], [Fußzeile, Untertitel, Kopfzeile],
  [`accent` auf `paper`], [3,0], [Striche, Fortschritt, Marke],
  [`accent` auf `ink`], [3,0], [dasselbe auf einer umgedrehten Folie],
  [`accent` auf Schwarz], [3,0], [die Überzeit der Vollbilduhr],
  [`border` auf `paper`], [1,2], [Haarlinien],
)

Die letzte fällt aus der Reihe: ihr Grund ist keine Rolle der Palette, sondern
die Farbe Schwarz selbst. Die Vollbilduhr ist schwarz von Rand zu Rand, was
immer die Palette des Decks sagt, und ihre Überzeit steht in der Akzentfarbe.
Die fünf mitgelieferten Paletten messen dagegen 6,16 (`light`), 3,66 (`mono`),
4,83 (`textbook`), 4,69 (`parchment`) und 5,41 (`dark`).

Geprüft wird jede der fünf Paletten *und* ihre umgedrehte Form, als `assert`
in `src/palettes.typ`, das beim Laden des Pakets läuft. Eine Farbe, die dort
verschoben wird und den Vertrag verletzt, bricht den Bau mit der Zahl, die sie
verfehlt hat.

#warning[
  *Der Vertrag gilt nur für die mitgelieferten Paletten.* Eine eigene Palette
  wird nicht geprüft -- weder gewarnt noch umgefärbt. `palette-report(…)` gibt
  dieselbe Messung als Liste zurück, wer sie für die eigene Palette sehen will:

  #show-code[```typ
  #for f in palette-report((paper: white, ink: black, surface: white,
                            muted: luma(55%), accent: blue, border: luma(86%))) [
    #f.pair: #calc.round(f.ratio, digits: 2) (will #f.min) #f.ok \
  ]
  ```]

  `contrast(a, b)` ist die Rechnung selbst und nimmt zwei beliebige Farben.
]

*Und die fünf Themes bestehen ihn nicht.* Der Vertrag wurde über sie laufen
gelassen, bevor die Paletten entstanden; das Ergebnis steht hier, statt
stillschweigend weggefärbt zu werden:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Theme*], [*Was durchfällt*]),
  [`themes.default`], [nichts, alle sechs Paarungen halten],
  [`themes.lesson`], [`muted` auf `paper` misst 4,25 statt 4,5],
  [`themes.night`], [`accent` auf `ink` misst 1,59 statt 3,0],
  [`themes.plain`], [`muted` auf `paper` misst 3,35 statt 4,5;
    `accent` auf `ink` misst 1,27 statt 3,0],
  [`themes.editorial`], [`muted` auf `paper` misst 3,51 statt 4,5;
    `accent` auf `paper` misst 2,84 statt 3,0],
)

Keine dieser Farben wurde geändert. Sie stehen in gemessenen Gestaltungen --
die von `themes.lesson` stammen von einer Musterseite aus _Fundamente der
Mathematik_ --, und ein Wechsel hätte jedes bestehende Deck anders aussehen
lassen. Was `muted` trägt, ist Nebensächliches: Foliennummer, Untertitel,
Kopfzeile. Wer die Zahlen einhalten will, legt die passende Palette darüber:

#show-code[```typ
#show: presentation.with(theme: themes.editorial, palette: palettes.parchment)
```]

#warning[
  *Aus der Füllfarbe wird nicht auf die Schriftfarbe geschlossen.* Ein
  mattes Salbeigrün wie `#aebdb3` sieht für eine Helligkeitsregel "hell" aus,
  aber Weiß darauf misst 1,96 zu 1 -- weit unter den 4,5, die Fließtext will.
  Deshalb rechnet das Paket mit `contrast` und färbt nirgends automatisch um.

  Die eine Ausnahme steht im Theme, nicht in der Palette, und sie ist ebenfalls
  eine Messung: wo ein Theme `strong` als *Schrift* setzt -- die Überschrift in
  `themes.lesson`, der Abschnittstitel in `themes.plain` --, wählt es zwischen
  `strong` und `ink` nach dem gemessenen Kontrast gegen den Grund, weil dieselbe
  Farbe nicht zugleich dunkler Balken und Schrift auf dunklem Grund sein kann.
  Wo die zuerst genannte Farbe reicht, und das tut sie bei allen fünf Themes
  in ihren eigenen Farben, bleibt genau sie stehen.
]

== Die Leinwand

`presentation` bestimmt das Format der Folie. Weil es das Seitenformat setzt,
lässt es sich hier nicht vorführen, sondern nur zeigen:

#show-code[```typ
#show: presentation.with()                              // 16:9, die Vorgabe
#show: presentation.with(width: 800pt, height: 600pt)   // 4:3
#show: presentation.with(margin: 48pt)                  // mehr Luft
```]

Ohne Angabe ist die Folie 16:9 auf A4-Breite. Das ist kein Zufall: So trägt
eine Folie den Text in derselben körperlichen Größe wie eine Handout-Seite.
`height` ergibt jedes andere Verhältnis, `margin` den Abstand zum Rand.

Alles, was das Theme zeichnet -- Titel, Schriftgrößen, Linien, Fortschritt --,
ist auf der Vorgabe-Leinwand gemessen und skaliert mit der Breite mit. Eine
halb so breite Präsentation sieht darum gleich aus, nur kleiner. Wirklich
anders wird das Layout nur durch das *Verhältnis*. Der Browser folgt: Die Bühne
wird auf das Verhältnis eingepasst, die Bildchen der Übersicht und die
gedruckten Seiten ebenso.

== Typografie

Schrift und Schriftgröße kommen aus dem Theme (`font`, `size`, `title-font`,
`title-size`). Für alles Weitere -- Absätze, eigene Show-Regeln -- gibt es den
Haken `style`: eine Funktion, die um jeden Folienrumpf gelegt wird.

#show-code[```typ
#show: presentation.with(
  style: it => {
    set par(leading: 0.68em, spacing: 0.85em)
    show math.equation: set text(size: 1.05em)
    it
  },
)
```]

#warning[
  Alles, was über Größe, Farbe, Schrift, Schnitt, Lage und Sprache des Textes
  hinausgeht, gehört in `style` und nicht in eine `#set`-Regel im Dokument. Im
  Browser wird jedes bewegte Element ein zweites Mal gesetzt, in einem eigenen
  kleinen Rahmen; dieser Rahmen kennt die `#show`-Regeln der Folie nicht.
  `style` wird auf beides gelegt -- auf den Folienrumpf und auf jedes bewegte
  Element --, und nur so sehen Hintergrund und Bewegtes gleich aus.

  Für die Formen, die typstage selbst zeichnet, gibt es einen zweiten Weg:
  Label-Regeln vor `#show: presentation`. Sie erreichen mehr als `style`, denn
  sie erreichen auch Kopf, Fuß und Titelfolie. Siehe /Labels: jede gebaute Form
  ansprechen/ weiter unten.
]

#tip[
  Ein Folienrumpf ist ein Kasten fester Höhe. Ein `style`, der ihn zwischen
  zwei Bruchteilsabstände setzt, rückt auch eine kurze Folie in die senkrechte
  Mitte, statt sie oben ankleben zu lassen:

  ```typ
  style: it => { v(1fr); it; v(1fr) }
  ```

  Zentriert wird mit Abständen und nicht mit `align`, weil `align` als
  Stilregel bis in jede Rasterzelle durchschlagen würde -- das
  Aufzählungszeichen eines zweizeiligen Punktes rutschte dann neben dessen
  zweite Zeile.
]

== Bausteine für den Folienrumpf

Sechs Bausteine für den Rumpf. Es sind Inhaltsfunktionen, keine eigenen
Folienarten -- sie lassen sich schachteln, in eine Rasterzelle setzen und mit
`anim` einblenden.

=== card -- der benannte Kasten

#show-example(
  rendered: {
    import "../src/lib.typ": card
    card(title: [Potenzfunktion])[$f(x) = x^n$ mit $n in NN$.]
  },
  source: ```typ
  #card(title: [Potenzfunktion])[$f(x) = x^n$ mit $n in NN$.]
  ```,
  width: 11cm,
)

`number:` setzt zusätzlich eine Ziffernscheibe davor -- für Ablaufpläne, bei
denen die Nummer zur Sache gehört. `color:` färbt den Streifen, `fill:` die
Fläche.

#show-example(
  rendered: {
    import "../src/lib.typ": card
    card(number: 2, title: [Zweiter Schritt])[Ableiten, dann einsetzen.]
  },
  source: ```typ
  #card(number: 2, title: [Zweiter Schritt])[Ableiten, dann einsetzen.]
  ```,
  width: 11cm,
)

=== callout -- der Merksatz

#show-example(
  rendered: {
    import "../src/lib.typ": callout
    callout[Der Exponent entscheidet über die Symmetrie.]
  },
  source: ```typ
  #callout[Der Exponent entscheidet über die Symmetrie.]
  ```,
  width: 11cm,
)

`title:` ändert die Überschrift (Vorgabe "Merke"), `color:` die Farbe;
`title: none` lässt sie weg.

=== side-by-side -- zwei Spalten

Der Regelfall für eine Folie mit Anschauung: links die Zeichnung oder das
Applet, rechts der Text.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    side-by-side(
      card(title: [Gerader Exponent])[Achsensymmetrisch zur $y$-Achse.],
      stagger[
        - $f(-x) = f(x)$
        - Wertemenge $W = [0; oo[$
      ],
    )
  },
  source: ```typ
  #side-by-side(
    card(title: [Gerader Exponent])[Achsensymmetrisch zur $y$-Achse.],
    stagger[
      - $f(-x) = f(x)$
      - Wertemenge $W = [0; oo[$
    ],
  )
  ```,
  width: 13cm,
)

`split:` nimmt die Spaltenbreiten; die Vorgabe gibt der ersten Spalte etwas
mehr, weil dort meist die Anschauung steht. Mehr als zwei Spalten sind erlaubt
-- dann bekommen alle dieselbe Breite, sofern `split:` nicht ebenso viele Werte
nennt.

`equal: true` macht alle Spalten gleich hoch. Ohne das steht jeder Kasten so
hoch wie sein eigener Text, und zwei Karten nebeneinander sehen verschieden
gewichtet aus, obwohl sie es nicht sind. Dazu wird die Zeile einmal gemessen,
ihre größte Höhe festgesetzt, und `card` und `callout` füllen sie aus.

#warning[
  Ein `height: 100%` im Kasten allein täte es nicht. Ein Prozentmaß löst gegen
  die *Region* auf und nicht gegen die Rasterzeile; gemessen wurden zwei
  Kästen so beide seitenhoch statt gleich hoch. Deshalb reicht `side-by-side`
  die gemessene Länge weiter, und deshalb wirkt `equal` nur auf `card` und
  `callout` und nicht auf beliebigen Inhalt.
]

=== tiles -- das Kachelraster

Jede Kachel erscheint einen Schritt nach der vorigen. Genau dafür gibt es die
Funktion: von Hand wäre das ein `anim` je Kachel mit hochgezählter Nummer.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    tiles(
      card(title: [eins])[Beobachten],
      card(title: [zwei])[Vermuten],
      card(title: [drei])[Begründen],
    )
  },
  source: ```typ
  #tiles(
    card(title: [eins])[Beobachten],
    card(title: [zwei])[Vermuten],
    card(title: [drei])[Begründen],
  )
  ```,
  width: 13cm,
)

`columns:` legt die Spaltenzahl fest (Vorgabe: bis zu drei), `stride: 0` lässt
alle im selben Schritt erscheinen und staffelt nur über `stagger` in
Millisekunden -- dann läuft eine Welle durch das Raster statt einer Folge von
Schritten:

#show-code(```typ
#tiles(stride: 0, stagger: 90, [A], [B], [C], [D])
```)

`duration:` und `easing:` sind die von `anim` und gelten für jede Kachel
gleich: ein Raster bewegt sich als eine Sache. Ohne Angabe gilt die Dauer der
Präsentation und die Hauskurve.

#show-code(```typ
#tiles(duration: 500, easing: "out-back", [A], [B], [C])
```)

=== statement -- die große Aussage

#show-example(
  rendered: {
    import "../src/lib.typ": statement
    statement[$ a^2 + b^2 = c^2 $]
  },
  source: ```typ
  #statement[$ a^2 + b^2 = c^2 $]
  ```,
  width: 11cm,
)

`statement` fordert ausdrücklich die volle Breite an und zentriert darin --
genau das, woran ein blankes `align(center, …)` in einem verfolgten Element
scheitert.

=== fit -- den Inhalt auf seinen Platz rechnen

Für das eine Stück, dessen Größe nicht im Deck steht: die breite Tabelle aus
der Auswertung, das erzeugte Diagramm, die Liste aus einer Datendatei. Ohne
etwas dazwischen läuft so ein Block über den Rand. Im PDF sieht man ihn dort
noch stehen; im Browser sitzt die Folie in einem Rahmen fester Größe, und was
darüber hinausragt wird abgeschnitten.

// check: folgen pre=tabelle
#show-code(```typ
== Ergebnisse der Regression
#fit(wrap: false, meine-tabelle)
```)

`wrap: false`, weil der Block eine Tabelle ist. Alles, was sich selbst in
Spalten setzt, will so gemessen werden, wie es steht; der Grund steht zwei
Absätze weiter, und es ist die eine Angabe, die man vor dem ersten Gebrauch
kennen sollte.

`fit` misst den Block gegen den Platz, an dem er steht, und skaliert ihn
geometrisch: die Verhältnisse bleiben, ein Faktor von Hand entfällt. Gemessen
an einer Tabelle mit 9 Spalten und 22 Datenzeilen: der Rumpf einer Folie im Theme
`plain` ist 777,89 pt breit und 364,61 pt hoch, die Tabelle misst
572,09 pt #sym.times 571,60 pt, ist also 207 pt zu hoch. `fit` rechnet mit
63,8 % und setzt sie 364,6 pt hoch. In der HTML und im PDF gleichermaßen, denn
gerechnet wird beim Übersetzen.

*Erst die Breite anbieten, dann verkleinern.* Der Block bekommt die volle
Breite angeboten, bevor gemessen wird. Ein Absatz oder eine Liste bricht dann
um, statt zu schrumpfen, und nur was danach noch zu hoch ist, wird skaliert.
Gemessen an `lorem(60)`: frei gesetzt ist der Absatz eine einzige Zeile von
3490 pt, in der angebotenen Breite des Rumpfes
777,89 pt #sym.times 111,06 pt und passt damit bereits. Der Faktor kommt auf
100 %, `fit` rührt den Absatz nicht an, und die Folie mit `fit` und die ohne
sind im Absatzbereich pixelgleich. Ohne das Angebot der Breite käme derselbe
Absatz auf 22,3 % und stünde als Fadenzeile über der Folie.

Eine Tabelle, ein Diagramm oder eine Zeichnung ordnet sich dagegen selbst um,
wenn man ihr eine schmalere Breite anbietet, und das ändert das Bild statt
seiner Größe. `wrap: false` misst so einen Block genau so, wie er steht:

// check: folie pre=tabelle
#show-code(```typ
#fit(wrap: false, meine-tabelle)
```)

Gemessen an einer Tabelle mit 24 Spalten, die frei gesetzt 1316 pt breit ist:
mit dem Vorgabewert `wrap: true` quetscht Typst die Spalten in die 777,89 pt
des Rumpfes, die Ziffern überlagern sich, und der Faktor kommt bei 100 %
heraus, es wird also nichts skaliert. Mit `wrap: false` rechnet `fit` mit
59,1 %, und die Spalten behalten ihr Verhältnis.

*Es verkleinert nur.* `grow: true` bläst auch auf, was kleiner ist als sein
Platz -- für die eine große Zahl, die die Folie füllen soll. `shrink: false`
nimmt das Verkleinern weg und lässt nur das Vergrößern übrig.

#show-code(```typ
#fit(grow: true)[42%]
```)

`width` und `height` nehmen `auto`, eine Länge oder einen Anteil. Bei
`height: auto` nimmt sich der Block, was unter dem übrigen Inhalt der Folie
übrig bleibt; ein `fit` unter zwei Stichpunkten rechnet also mit den
Stichpunkten. Das hat eine Kehrseite, sobald etwas das `fit` umschließt: in
einem `card` wird der Kasten folienhoch, unten abgeschnitten, und *was nach
dem `card` steht, fällt von der Folie* -- in beiden Ausgaben gemessen. Das tut
das `1fr`, nicht das Skalieren: ein `card` um ein blankes
`block(height: 1fr)` verhält sich genauso. In einem `card` gibt man `height:`
ausdrücklich an, dann rechnet das `fit` damit.

#warning[
  *Keine Einblendung im `fit`.* Zweierlei übersteht das Messen nicht. Ein
  `pause` wird gefunden, indem der Folienrumpf abgelaufen wird, und ein
  gemessener Block ist eine Closure, in die dieser Lauf nicht hineinkommt:
  gemessen an einer Folie mit zwei Pausen fiel die Schrittzahl von drei auf
  eins, und nichts hat es gesagt. Und ein gemessener Block hat keine Höhe, gegen
  die er rechnen könnte -- die Breite ist die, die ein umbrechendes `fit`
  hineinreicht, die Höhe aber kommt unbegrenzt zurück, und genau an dieser
  Achse legt ein verfolgtes Element seine Größe und den Platz seiner Marke
  fest. Gemessen: ein `anim` in einem `fit` wurde gar nicht verkleinert und
  lief unten aus der Folie.

  `fit` bricht deshalb ab, mit Namen und Rat, für `pause`, `anim`, `stagger`,
  `alternatives`, `morph`, `tiles`, `video`, `embed`, `flipbook`, `build`
  und `scene` -- in
  beiden Ausgaben und auch dann, wenn das `fit` in einem anderen `fit` steckt.
  Der Ausweg ist, das `fit` *innerhalb* der Einblendung zu setzen statt darum
  herum:

  // check: folie pre=tabelle fehlt=2 weil=cannot_stand_inside_fit
  ```typ
  #anim(fit(wrap: false, meine-tabelle))   // so
  #fit(anim(meine-tabelle))                // nicht so
  ```
]

`speaker-note` und `bridge-job` dürfen im `fit` stehen. Sie legen keine
Geometrie fest, und eine Messung schreibt keinen Zustand fest, beide kommen
also nachgemessen genau einmal an. Die andere Richtung ist die, die nicht
geht: eine Notiz, die nur aus einem `fit` besteht, trägt keinen Text und
erreicht damit weder die Sprecheransicht noch das Handout. `speaker-note`
weist das mit einer Meldung ab.

Die Rechnung dahinter ist von mosaic übernommen, das sie aus Touying 0.7.4
übernommen hat; Touying schreibt die Arbeit daran Andreas Kröpelin
(Polylux PR #91) und ntjess zu.

=== overflow -- der Prüflauf vor dem Vortrag

`fit` beantwortet den einen Block, dessen Größe man schon ahnt. `overflow`
beantwortet die Frage, die man nicht Folie für Folie stellen kann: läuft
irgendwo in diesem Deck etwas über seinen Platz? Es misst jeden Folienrumpf
gegen den Platz, den das Theme ihm gibt, und nennt die, die nicht hineingehen.

#show-code(```typ
#show: presentation.with(overflow: "error")
```)

Standardmäßig aus, und dafür gedacht, für einen Lauf eingeschaltet zu werden --
nicht dafür, beim Schreiben mitzulaufen.

Ein Foliensatz braucht das dringender als ein Dokument. Auf einer Seite, die
man durchblättert, sieht man den Überlauf: die Zeile steht schlicht über dem
Rand und das Auge fängt sie. Eine typstage-Folie wird in einen SVG-Rahmen
fester Größe gesetzt und im Browser skaliert -- was übersteht, wird
abgeschnitten oder neben die Folie gezeichnet, und einen Vortrag, den man
durchklickt, sieht man darauf erst am Beamer.

/ `"none"`: es wird nichts gemessen. Der Vorgabewert.
/ `"error"`: das ganze Deck wird gebaut, und dann bricht es mit *allen* Stellen
  auf einmal ab statt mit der ersten. Ein Lauf, die ganze Liste.
/ `"record"`: es baut durch und legt stattdessen je Fund einen abfragbaren
  Datensatz ab, für ein Werkzeug oder ein Bauskript. Typst gibt einem Paket
  keinen Warnkanal, `"record"` gibt von sich aus also nichts aus.

Die Meldung nennt Folie, Schritt und das Maß (hier gekürzt, der Fließtext um
die Liste herum ist weggelassen):

#show-code(```
error: assertion failed: typstage: 2 slides run over the room the body has. …
  slide 2, from step 1 at the earliest: 311.14pt too tall, 675.76pt of content in 364.61pt of room
  slide 3, from step 2 at the earliest: 296.49pt too tall, 661.1pt of content in 364.61pt of room
Shorten the slide, split it, or put the block that does not fit into fit(). …
```)

*Warum beim Schritt "at the earliest" steht.* Eine Folie ist auf Schritt eins
genauso hoch wie auf Schritt fünf: jedes verfolgte Element hält seinen vollen
Platz von Anfang an mit `hide()`, ob der Rumpf passt, ist also eine Frage an
die Folie und nicht an den Schritt. Mit dem Schritt ändert sich nur, was
*gezeichnet* wird. Ein `anim`, das unten übersteht, ist bis zu seinem Schritt
unsichtbar, und erst dann gibt es etwas zu sehen.

Der Schritt wird aus den Einblendungen gerechnet: alles, was erst nach Schritt
k dazukommt, ist dort unsichtbar, und ist der Überlauf größer als das alles
zusammen, hängt schon auf Schritt k etwas über den Rand. Das ist eine untere
Schranke und keine genaue Antwort, denn die Summe zählt die Einblendungen und
sonst nichts -- die Zwischenräume, Blockabstand, ein `v()`, zählen in der Höhe
des Rumpfes und in keiner Einblendung. Gemessen: ein 350 pt hoher Kasten, ein
`v(100pt)` und ein `anim(at: 4)` darunter werden ab Schritt 1 gemeldet, während
der Überstand erst auf Schritt 4 auf den Schirm kommt. Wo das Überstehende
selbst eine Einblendung ist und nichts Leeres darüber steht, stimmt der Schritt
genau: `anim(at: 3)` wird ab Schritt 3 gemeldet. *Die Folie steht in beiden
Fällen richtig da*, und das ist der Teil, an dem man handelt. Auf Papier wird
gar kein Schritt genannt, weil dort jeder Schritt zugleich auf der Seite steht;
in den Datensätzen zeigt sich das als `step: 0`.

Die Datensätze holt man mit `typst eval`, und dafür muss das Deck auf
`overflow: "record"` stehen -- auf `"error"` bricht auch dieser Befehl mit dem
Fehler ab:

#show-code(```sh
typst eval --target html --features html --in deck.typ \
  'query(<typstage-overflow>).map(e => e.value)'
```)

und bekommt je Fund einen Eintrag:

#show-code(```json
[{"slide":2,"step":1,"height":675.76,"room":364.61,"over":311.14},
 {"slide":3,"step":2,"height":661.1,"room":364.61,"over":296.49}]
```)

#info[
  *Was die Prüfung nicht sieht.* Gemessen wird nur die Höhe. `measure` deckelt
  auch die Breite, die es meldet, bei der Breite, die es bekommt -- ein zu
  breiter Rumpf ist also nicht von einem zu unterscheiden, der seine Spalte
  füllt. Für diesen Fall ist `fit` die Antwort, und beide gehören zusammen: die
  Prüfung findet die Folie, `fit` richtet den Block.

  Viererlei wird übersehen statt gemeldet. Ein `height: 100%` im Rumpf misst 0,
  ein `1fr` fällt zusammen. Alles, was außerhalb seines eigenen Layoutkastens
  zeichnet -- `scale`, `move`, `place` mit Versatz --, ist für eine Messung
  unsichtbar. Und Titel- und Abschnittsfolien werden nie gemessen: das Theme
  zeichnet sie mit `place`, sie haben keinen Rumpfblock, über den etwas laufen
  könnte.

  Einerlei wird gemeldet, wo nichts zu sehen ist: nachlaufender Abstand, ein
  `v()` am Ende eines Rumpfes, nimmt in der Messung Platz und zeichnet nichts.
]

Gemessen über die sechs Beispieldecks: in der HTML kostet der Lauf merklich
mehr Zeit, je nach Deck und Verrechnung des Prozessstarts zwischen dem 1,2- und
dem 1,5-Fachen; auf Papier kostet er wenig, ein paar Millisekunden je Deck.
Über alle sechs Decks gelaufen meldet er nichts -- keines von ihnen läuft über.

=== drift -- der Melder für wandernde Szenen

`overflow` fragt, ob eine Folie in ihren Platz geht. `drift` fragt etwas
anderes, das man ebenso wenig Folie für Folie prüfen kann: steht eine Szene
beim Blättern still?

Eine Zeichnung ist so groß wie ihr Inhalt, eine CeTZ-Leinwand vor allem. Ändert
sich der Inhalt über die Halte einer `scene`, ist jedes Bild anders groß, und
die Zeichnung sitzt in ihrem Kasten jedes Mal woanders -- beim Blättern wandert
das ganze Bild, obwohl sich nur ein Punkt bewegen sollte. Jede Szene misst
deshalb ihre Bilder nach, und `drift` sagt, was mit den Funden geschieht.

/ `"error"`: das ganze Deck wird gebaut, und dann bricht es mit *allen* Szenen
  auf einmal ab. Der Vorgabewert.
/ `"record"`: es baut durch und legt je Fund einen abfragbaren Datensatz ab.
/ `"none"`: es wird gar nicht erst gemessen.

#show-code(```typ
#show: presentation.with(drift: "record")
```)

Die Meldung nennt Folie, Schritt und die Zahlen (hier gekürzt):

#show-code(```
error: assertion failed: typstage: 1 scene draws frames of different sizes. …
  slide 4, from step 1: 28 frames in 19 different sizes, up to 28.35pt apart across and 53.86pt down
```)

Die Datensätze holt man wie beim Überlauf, und dafür muss das Deck auf
`drift: "record"` stehen:

#show-code(```sh
typst eval --target html --features html --in deck.typ \
  'query(<typstage-drift>).map(e => e.value)'
```)

#show-code(```json
[{"slide":4,"step":1,"frames":28,"sizes":19,"width":28.35,"height":53.86}]
```)

*Warum dieser Melder an ist und `overflow` nicht.* Er kostet nur, wer `scene`
benutzt: gemessen an einer Szene aus 28 CeTZ-Bildern 434 ms ohne und 536 ms
mit, also rund 100 ms für diese eine Szene. `overflow` dagegen misst jeden
Rumpf jedes Decks. Und was er findet, ist beim Schreiben unsichtbar -- jedes
Bild für sich sieht richtig aus, und erst das Blättern zeigt die wandernde
Zeichnung. Gemessen wird nur im Browserzweig; auf Papier steht ein einziges
Standbild, und ein Standbild wandert nicht.

#info[
  *Was der Melder nicht kann, und woran es liegt.* Er sieht den Fall, er behebt
  ihn nicht. `measure` antwortet mit einer Größe und nie damit, *wo* die Tinte
  darin liegt -- es gibt also keinen Versatz zu rechnen und nichts zu
  verschieben.

  *Was er übersieht.* Gemessen wird die Zeichnung selbst, ohne Breitenbezug.
  Was sich auf `100%` setzt, misst dann für jedes Bild dasselbe und fällt aus
  der Prüfung -- zu Recht, denn so ein Bild hat seinen festen Rahmen schon.

  *Was er meldet, wo nichts wandert.* Eine Zeichnung, die nur nach rechts und
  nach unten wächst, bewegt ihre Tinte nicht, misst sich aber trotzdem
  verschieden. Genau dafür steht `steady: false` an der Szene.
]

=== Folien ohne Titel

Ein nacktes `==` lässt den Titelbalken weg; der Rumpf beginnt dann oben und
bekommt die Höhe, die sonst der Balken belegt hätte. Das ist die Folienart für
die eine große Formel -- und das Ziel eines Morphs, der in die Mitte fliegen
soll:

#show-code(```typ
==
#place(center + horizon, morph(<ableitung>, text(size: 2.4em)[
  $f'(x) = lim_(h -> 0) (f(x+h) - f(x)) / h$
]))
```)

In der Argumentform sind alle drei Schreibweisen erlaubt: `slide[Rumpf]` ohne
Titel, `slide(none)[Rumpf]` ausdrücklich ohne, `slide([Titel])[Rumpf]` mit.

== Labels: jede gebaute Form ansprechen

Jede Form, die typstage auf einer Folie selbst zeichnet -- die Grundfläche, das
Kopfband, der Folientitel, die Fußzeile, der Fortschritt, der Kasten, der
Merksatz, die große Aussage, Titel- und Abschnittsfolie, die Ersatzfläche eines
Videos --, trägt ein festes Typst-Label. Damit ist sie von außen ansprechbar:
eine gewöhnliche `show`-Regel genügt, kein Theme-Schlüssel, kein Fork.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#show label("ts-slide-header-band"): set rect(fill: rgb("#4c1d95"))
#show label("ts-slide-title"): set text(fill: rgb("#fde047"), style: "italic")
#show label("ts-card"): set block(fill: rgb("#eef2ff"))
#show label("ts-statement"): set text(fill: rgb("#be123c"), weight: "bold")

#show: presentation.with(theme: themes.default)
```]

Zwei Sorten Regeln decken alles ab, getrennt danach, was sie anfassen: die
*Flächen* -- Grundflächen, Bänder, Haarlinien, Balken, Kästen -- nehmen
`set rect(..)`, `set block(..)`, `set circle(..)` oder `set line(..)`, die
*Schriften* nehmen `set text(..)` mit Größe, Schnitt, Farbe, Schriftart,
Laufweite. Beides wirkt zur Übersetzungszeit, und deshalb steht das Ergebnis
gleich in der HTML und im PDF -- mit einer Ausnahme: Was nur im PDF gezeichnet
wird, weil im Browser das echte `<video>` oder `<iframe>` an seiner Stelle
steht, sieht man auch nur dort. Das betrifft die sechs Labels unter
/Medien und Handout/.

#warning[
  *Bei den Flächen* wirkt die Kurzform, die Langform nicht:

  ```typ
  #show label("ts-slide-progress"): set rect(fill: green)          // ja
  #show label("ts-slide-progress"): it => { set rect(fill: green); it }   // nein
  ```

  Die Kurzform legt die Stilregel *um* das gefundene Element, die Langform
  *hinein* -- und im Rechteck steckt kein zweites Rechteck, auf das sie noch
  wirken könnte. Wer die beiden Schreibweisen aus anderen Paketen als
  gleichwertig kennt, läuft hier auf.

  Bei den 16 Schrift-Labels sind beide Schreibweisen gleichwertig: dort steckt
  im gefundenen Element der Text, und den erreicht eine Regel auch von innen.
]

=== Wo die Regel stehen muss

*Vor* `#show: presentation`. Diese eine Stelle erreicht alles: den
Folienhintergrund, die Chrome-Schicht mit Kopf, Fuß und Fortschritt, die
Titelfolie und jedes bewegte Element.

Der Haken `style` erreicht *nicht* dasselbe. Er wird um den *Folienrumpf*
gelegt, und Kopf, Fuß, Fortschritt sowie Titel- und Abschnittsfolie entstehen
daneben, nicht darin. Gemessen, jede der 38 Regeln einzeln: aus `style`
heraus wirken genau die 13, die im Folienrumpf stehen -- die Bausteine
`ts-card…`, `ts-callout…`, `ts-statement` und die drei Ersatzflächen
`ts-media-…`. Die übrigen 25 bleiben dort stumm, ohne Warnung. `style` bleibt richtig für
Typografie, die den ganzen Rumpf betrifft; für Labels ist die Stelle vor
`#show: presentation` die richtige.

#warning[
  Eine `show`-Regel, die *hinter* `#show: presentation` steht, erreicht ein
  getracktes Element (`anim`, `morph`) nicht. Der Grund steht schon im
  Abschnitt über Typografie: Im Browser wird jedes bewegte Element ein zweites
  Mal gesetzt, in einem eigenen Rahmen, und dieser Rahmen kennt die
  `#show`-Regeln aus dem Dokumentrumpf nicht.

  ```typ
  #show: presentation.with(theme: themes.default)
  #show label("ts-statement"): set text(fill: green)   // zu spät
  == Eine Folie
  #statement[fest]
  #anim(statement[bewegt])
  ```

  In dieser Datei ist `fest` grün und `bewegt` schwarz: vier eingefärbte
  Flächen im Hintergrund, null in der Überlagerung. Steht dieselbe Regel eine
  Zeile weiter oben, sind es vier und sechs, und beide sehen gleich aus. Im
  PDF fällt der Unterschied nicht auf, weil dort nichts zweimal gesetzt wird.

  Das gilt für jede `#show`-Regel, nicht nur für Label-Regeln; es ist keine
  Eigenheit der Labels.
]

=== Was eine Label-Regel ändert und was nicht

Erreichbar ist, was das Paket *nicht* als ausdrückliches Argument schreibt.
Für die Schrift ist das alles; für die Flächen sind es `fill` und `stroke`
überall und `radius` überall dort, wo die Form eine Rundung hat -- genau die
gibt typstage seinen Formen über eine `set`-Regel.

`width` steht überall als Argument und ist deshalb nirgends erreichbar. Bei
`height` gibt es drei Ausnahmen, und sie sind es wert, genannt zu werden:
`ts-card`, `ts-card-bar` und `ts-callout` bekommen ihre Höhe als `auto`, und
`auto` ist kein Wert, der eine Regel schlagen könnte. Auch in einer Reihe
gleicher Höhe nicht: nachgemessen an der bemalten Fläche selbst wirkt
`height:` dort ebenso.

#show-code[```typ
#show label("ts-card"): set block(height: 150pt)   // wirkt
#show label("ts-card"): set block(width: 30%)      // wirkt nicht
```]

Die erste Zeile bläht den Kasten auf 150 pt auf und schiebt den Merksatz
darunter aus der Folie. Bei den Chrome-Flächen, den Grundflächen und dem
Handout-Rahmen wirkt weder das eine noch das andere; was dort eine
`width`-Regel scheinbar ändert, sind die Blöcke *im* Inhalt, siehe den
nächsten Kasten.

Nicht erreichbar ist auch die *Anordnung* der Folie. Wie hoch der Kopf baut,
wie weit die Linie unter dem Titel steht, wo der Balken sitzt -- das entsteht
in `place` und `layout`, während sich das Layout zusammensetzt, und keine
`show`-Regel reicht dort hinein. Dafür sind die Theme-Schlüssel da
(`head-gap`, `band-height`, `rule-size` und die übrigen); sie bleiben
unverändert bestehen.

#warning[
  Eine Regel auf `block` oder `rect` reicht nach *innen*: Sie gilt für die
  gelabelte Fläche und für jeden Block darin. Bei `fill`, `stroke` und
  `radius` ist das abgefangen -- der Kasten setzt innen wieder her, was das
  Dokument gesetzt hatte, sonst liefe seine Farbe über die runden Ecken
  hinaus. Bei den Abständen ist es nicht abgefangen, und dann verschiebt eine
  Label-Regel die Folie:

  ```typ
  #show label("ts-card"): set block(below: 60pt)
  == Eine Folie
  #card(title: [Kasten])[Rumpf]
  #callout(title: [Merke])[Merksatz]
  ```

  Gemessen mit `pdftotext -bbox` an genau dieser Folie: Der Merksatz rückt um
  31,2 pt nach unten, und alles unter ihm mit. Die Zahl ist `60pt` minus dem
  Blockabstand von 1,2 em, bei 24 pt Text also 28,8 pt, *je Kante*. Wer
  `above` und `below` zugleich setzt und einen Kasten hat, über dem noch etwas
  steht, bekommt beide Kanten und damit das Doppelte.

  Das ist keine Zusage, sondern eine Nebenwirkung von Typsts Stilregeln.
  Labels sind für Schrift und Fläche gedacht; wer Abstände will, nimmt die
  Argumente der Bausteine oder die Theme-Schlüssel.
]

=== Das vollständige Verzeichnis

Was hier steht, gibt es; was es gibt, steht hier. Die Namen folgen einem
Schema: `ts-`, dann der *Ort*, dann der *Teil* -- der Teil steht immer hinter
dem Ort, nie davor. Orte sind `slide` (die gewöhnliche Folie), `title-slide`,
`section-slide`, `card`, `callout`, `statement`, `media` und `handout`.

Zwei Paare unterscheiden sich nur in der Wortstellung, und ein Fehlgriff
bleibt stumm -- er tut einfach nichts. Deshalb hier nebeneinander:

#table(
  columns: (auto, 1fr),
  stroke: none,
  table.header([*Name*], [*Ort und Teil*]),
  [`ts-slide-title`], [Ort `slide`, Teil `title`: der Titel einer
    gewöhnlichen Folie],
  [`ts-title-slide-title`], [Ort `title-slide`, Teil `title`: der Titel der
    Titelfolie],
  [`ts-slide-title-rule`], [Ort `slide`: die Linie unter dem Folientitel],
  [`ts-title-slide-rule`], [Ort `title-slide`: die Zierlinie auf der
    Titelfolie],
)

Die Merkhilfe: Steht `slide` *vorn*, geht es um die gewöhnliche Folie; steht
es hinter `title` oder `section`, um jene Folienart.

Ein Label, das dieses Theme gerade nicht zeichnet -- ein Kopfband bei
`header: "run"` etwa --, gibt es auf dieser Folie nicht, und eine Regel darauf
tut dann nichts.

*Die gewöhnliche Folie*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*Was es ist*], [*Regel*]),
  [`ts-slide-ground`], [Die Grundfläche der Folie], [`rect`],
  [`ts-slide-header-band`], [Das Kopfband, nur bei `header: "band"`], [`rect`],
  [`ts-slide-header-text`], [Die laufende Kopfzeile aus Nummer und Abschnitt,
    nur bei `header: "run"`], [`text`],
  [`ts-slide-header-rule`], [Die Haarlinie darunter, nur bei `header: "run"`],
    [`rect`],
  [`ts-slide-title`], [Der Folientitel, bei allen drei Kopfarten], [`text`],
  [`ts-slide-title-rule`], [Die Linie unter dem Titel, nur wenn
    `rule-size > 0pt`], [`rect`],
  [`ts-slide-footer`], [Die Fußzeile], [`text`],
  [`ts-slide-number`], [Die Foliennummer darin], [`text`],
  [`ts-slide-footer-rule`], [Die Haarlinie darüber, nur wenn
    `footer-rule > 0pt`], [`rect`],
  [`ts-slide-progress`], [Der Fortschrittsbalken, bei `progress: "tick"` der
    wandernde Reiter], [`rect`],
  [`ts-slide-progress-track`], [Die Bahn, auf der er wandert, nur bei
    `progress: "tick"`], [`rect`],
)

*Die Titelfolie*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*Was es ist*], [*Regel*]),
  [`ts-title-slide-ground`], [Ihre Grundfläche], [`rect`],
  [`ts-title-slide-band`], [Das Band am oberen Rand, nur in `themes.lesson`],
    [`rect`],
  [`ts-title-slide-title`], [Ihr Titel], [`text`],
  [`ts-title-slide-subtitle`], [Ihr Untertitel], [`text`],
  [`ts-title-slide-rule`], [Die Zierlinie; `themes.editorial` hat zwei,
    `themes.plain` keine], [`rect`],
  [`ts-title-slide-byline`], [Die Zeile aus Verfasser und Datum], [`text`],
)

*Die Abschnittsfolie*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*Was es ist*], [*Regel*]),
  [`ts-section-slide-ground`], [Ihre Grundfläche], [`rect`],
  [`ts-section-slide-bar`], [Der Balken am linken Rand, nur in
    `themes.lesson`], [`rect`],
  [`ts-section-slide-title`], [Ihr Titel], [`text`],
  [`ts-section-slide-rule`], [Die Zierlinie; `themes.night` hat zwei,
    `themes.lesson` keine], [`rect`],
  [`ts-section-slide-parent`], [Die Zeile darüber, die sagt, unter welchen
    Abschnitten dieser hängt. Erst ab der zweiten Gliederungsebene, bei
    `slide-level: 2` also nie], [`text`],
)

Eine Abschnittsfolie hat in typstage keinen Untertitel, deshalb steht in der
Liste auch keiner.

*Die Bausteine im Folienrumpf*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*Was es ist*], [*Regel*]),
  [`ts-card`], [Der Kasten: Fläche, Rand, Rundung und alles darin], [`block`],
  [`ts-card-bar`], [Der farbige Reiter über ihm, nur bei `box: "bar"`],
    [`block`],
  [`ts-card-title`], [Seine Überschrift], [`text`],
  [`ts-card-disc`], [Die Scheibe der Nummer, nur bei `number:`], [`circle`],
  [`ts-card-number`], [Die Ziffer darin], [`text`],
  [`ts-card-body`], [Sein Rumpf], [`text`],
  [`ts-callout`], [Der Merksatz: Fläche, Balken, Rundung. Der Balken links
    ist kein eigenes Label, er ist der linke `stroke` dieses hier --
    `set block(stroke: (left: 4pt + red))` färbt ihn um], [`block`],
  [`ts-callout-title`], [Seine Überschrift], [`text`],
  [`ts-callout-body`], [Sein Rumpf], [`text`],
  [`ts-statement`], [Die große Aussage. `size` wirkt als Faktor darauf, weil
    `statement` in `em` misst], [`text`],
)

*Medien und Handout*

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  table.header([*Label*], [*Was es ist*], [*Regel*]),
  [`ts-media-fallback`], [Die Ersatzfläche, die im PDF für ein bewegtes
    Element steht. Nur eine Hülle, ohne eigene Farbe und ohne Rand: eine
    `radius`-Regel darauf sieht man deshalb nicht, eine `fill`-Regel schon],
    [`block`],
  [`ts-media-fallback-empty`], [Der graue Kasten darin, wenn kein `fallback:`
    angegeben ist. Er hat eine Fläche], [`block`],
  [`ts-media-poster`], [Die graue Fläche eines `video` ohne `poster:`],
    [`rect`],
  [`ts-handout-frame`], [Der gerahmte Kasten einer Folie auf der
    Handout-Seite], [`block`],
  [`ts-handout-lines`], [Die Schreiblinien daneben oder darunter], [`line`],
  [`ts-handout-note`], [Die Sprechernotiz, wo es eine gibt], [`text`],
)

#info[
  Drei Dinge, die dazugehören.

  *Ein Theme mit eigener Titelfolie zeichnet keins dieser Labels.*
  `title-slide` und `section` im Theme sind Funktionen und malen ihr Bild
  selbst; wer eine eigene mitbringt, verliert die sechs beziehungsweise vier
  Labels dieser Folienart, und nichts warnt davor. Die mitgelieferten fünf
  zeichnen, was ihr Bild braucht, und nicht mehr: Band und Balken gibt es nur
  in `themes.lesson`, `themes.plain` hat keine Zierlinie auf der Titelfolie,
  `themes.lesson` keine auf der Abschnittsfolie. Was welches Theme zeichnet,
  steht in der Spalte /Was es ist/.

  *Die unsichtbaren Markierungen tragen keins.* Jedes bewegte Element malt ein
  durchsichtiges Rechteck um sich, an dem der Browser es wiederfindet, und
  `pin` macht dasselbe für ein einzelnes Zeichen. Das ist Maschinerie und
  keine Form; beides bleibt namenlos.

  *Typst-Labels und die CSS-Klassen der Laufzeit sind zwei getrennte
  Namensräume.* `.ts-slide` im Stylesheet ist der `<section>` einer Folie im
  Browser, `ts-slide-title` ein Typst-Label -- sie liegen einen Bindestrich
  auseinander und haben nichts miteinander zu tun. Typsts HTML-Ausgabe legt
  allerdings an manche Formen ein `data-typst-label`-Attribut, an die
  Bausteine des Rumpfes zum Beispiel, an die Schriftformen nicht. Es ist
  Beiwerk von Typst, kein Versprechen dieses Pakets: Verlass dich für CSS
  nicht darauf.
]


== `info()`: was das Deck über sich selbst weiß

Labels sagen, wie eine gebaute Form aussieht. Sie sagen nicht, was in ihr
steht. Die Foliennummer, der Bruch, der Kapitelname in der Kopfzeile -- diese
Zahlen kannte bisher nur das Paket, und wer eine eigene Fußzeile bauen wollte,
musste selbst mitzählen. `info()` gibt sie heraus:

#show-code[```typ
#context {
  let deck = info()
  [#deck.section.title #h(1fr) #deck.slide.number / #deck.slide.total]
}
```]

Es ist dieselbe Lesung, die die eingebaute Fußzeile macht. Jede Zahl, die das
Paket auf eine Folie druckt -- die Foliennummer, der Bruch, die Länge des
Fortschrittsbalkens, die laufende Kopfzeile --, kommt aus diesem Wörterbuch und
aus keiner zweiten Zählung. Eine selbstgebaute Fußzeile und die eingebaute
können deshalb nicht verschiedene Zahlen drucken.

Was zurückkommt:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Feld*], [*Was darin steht*]),
  [`title`, `subtitle`], [Titel und Untertitel des Decks, so wie
    `presentation` oder eine `title-slide` sie bekommen haben],
  [`author`, `date`], [Ebendaher. `date` ist, was übergeben wurde: ein
    `datetime` oder Inhalt],
  [`slide.number`], [Diese Folie. Gezählt wie die Fußzeile zählt, Titel- und
    Abschnittsfolien also nicht mit],
  [`slide.total`], [So viele Folien werden gezählt],
  [`slide.numbered`], [Ob diese Folie mitgezählt wird. Auf einer Titel- oder
    Abschnittsfolie `false`],
  [`step.number`], [Der Schritt, auf dem der aufrufende Inhalt selbst steht],
  [`step.total`], [So viele Schritte hat diese Folie],
  [`section.number`], [Der wievielte Abschnitt gerade läuft, `0` vor dem
    ersten],
  [`section.total`], [So viele Abschnitte hat das Deck],
  [`section.title`], [Sein Titel, oder `none` vor dem ersten],
  [`levels`], [Ein Eintrag je Struktur-Ebene, von außen nach innen. Leer bei
    `slide-level: 1`],
  [`outline`], [Die ganze Gliederung, ein Eintrag je Abschnittsfolie in der
    Reihenfolge, in der sie kommen],
)

`section` meint immer die Ebene direkt über der Folie. Bei der Vorgabe
`slide-level: 2` ist das die einzige, die es gibt, und dann ist `section`
dasselbe wie `levels.last()` ohne dessen `depth`.

Wer mehr als eine Ebene hat -- siehe "Mehr als zwei Ebenen" --, findet sie in
`levels` und in `outline`:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Feld eines Eintrags*], [*Was darin steht*]),
  [`levels.at(i).depth`], [Die Überschriftentiefe, `1` für `=`, `2` für `==`],
  [`levels.at(i).title`], [Der Titel, oder `none`, solange auf dieser Ebene
    kein Abschnitt läuft],
  [`levels.at(i).number`], [Der wievielte Abschnitt dieser Ebene im *ganzen*
    Deck. Geht nie zurück und liest sich deshalb auch als Fortschritt],
  [`levels.at(i).total`], [So viele Abschnitte hat diese Ebene im ganzen Deck],
  [`levels.at(i).index`], [Der wievielte *unter demselben Elternteil* -- das,
    was Beamer als `1.2` druckt],
  [`levels.at(i).count`], [So viele Geschwister hat er dort. `index` und
    `count` sind `0`, solange auf dieser Ebene kein Abschnitt läuft],
  [`outline.at(j).depth`], [Ebendas für den Eintrag der Gliederung],
  [`outline.at(j).title`], [Sein Titel],
  [`outline.at(j).number`], [Dieselbe Zählung wie `levels.at(..).number`.
    Der Vergleich beider sagt, ob der Eintrag vorbei ist, läuft oder noch
    kommt],
  [`outline.at(j).here`], [Ob die gezeigte Folie genau dieser Eintrag ist.
    Nur eine Abschnittsfolie kann das sein, und lesen kann es dort nur eine
    eigene `section`-Funktion eines Themes -- eine Abschnittsfolie hat keinen
    Rumpf, in den ein Deck schreiben könnte],
)

Eine fortschreitende Gliederung braucht damit keine zweite Zählung:

// check: folie
#show-code[```typ
#context {
  let d = info()
  stack(spacing: 0.6em, ..d.outline.map(e => {
    let lauf = d.levels.at(e.depth - 1).number
    text(
      weight: if e.number == lauf { "bold" } else { "regular" },
      fill: if e.number <= lauf { black } else { luma(60%) },
      [#h((e.depth - 1) * 1.4em)#e.title],
    )
  }))
}
```]

Eine Zahl steht bewusst daneben: Sprecheransicht und Übersicht zählen *alle*
Folien, Titel- und Abschnittsfolien eingeschlossen, `info().slide.total` zählt
wie die Fußzeile und lässt sie aus. Auf einem Prüfstück mit einer Titelfolie,
zwei Abschnittsfolien und drei gewöhnlichen sind das 6 gegen 3.

=== Zwei Zählungen, nicht eine

Ein Deck, das Seiten zählt, käme mit einer Zahl aus. Dieses zählt in Folien
*und* in Schritten, und die beiden sind verschiedene Dinge: eine Folie ist ein
Bild, ein Schritt ist ein Tastendruck. Deshalb stehen sie getrennt und heißen
so, wie sie im ganzen Handbuch heißen.

`step.number` ist der Schritt, auf dem der aufrufende Inhalt selbst steht: im
Rumpf einer Folie `1`, innerhalb eines `anim`, eines `stagger` oder einer
`alternatives` der Schritt jener Einblendung -- und wo eine Einblendung über
mehrere Schritte steht, ihr erster. Das ist der Unterschied, auf den
es ankommt -- eine Anzeige, die den laufenden Schritt nennt, muss in den
Einblendungen sitzen, denn der Browser setzt nichts neu:

#show-code[```typ
#let stand = context {
  let d = info()
  [Schritt #d.step.number von #d.step.total]
}

== Vier Fassungen
#alternatives(stand, stand, stand, stand)
```]

Das druckt beim Blättern nacheinander "Schritt 1 von 4" bis "Schritt 4 von 4" -- gemessen an einem Prüfstück mit neun Schritten, an jedem einzelnen davon.

Auf dem Papier gibt es keinen laufenden Schritt: die Seite zeigt die Folie im
Endzustand, alles auf einmal. Dort ist `step.number` deshalb gleich
`step.total`.

#info[
  `step.total` zählt dasselbe wie die Laufzeit im Browser. Gegengeprüft an
  einem Deck, das jeden Baustein einmal enthält, der einen Schritt verbraucht
  -- `pause`, `stagger`, `anim` mit und ohne Nummer, `alternatives`, `tiles`,
  `morph`, `video`, `flipbook`: auf allen neun Folien mit Rumpf nennt `info()`
  dieselbe Zahl, die die Laufzeit im Browser zählt, und die PDF nennt sie
  ebenfalls.
]

=== Wohin die eigene Fußzeile gehört

Auf einer Titel- oder Abschnittsfolie zeichnet typstage keine Fußzeile. Wer
eine eigene baut, steht dort vor der Frage, was in den Zahlenplatz gehört --
und die Antwort ist: nichts. `slide.numbered` sagt, wann das der Fall ist:

#show-code[```typ
#let fusszeile = context {
  let d = info()
  let zahl = if d.slide.numbered [#d.slide.number / #d.slide.total] else []
  place(bottom + right, text(size: 12pt, fill: muted, zahl))
}
```]

Auf einer gewöhnlichen Folie steht sie im Rumpf, also in der Folie selbst:

// check: folgen davor
#show-code[```typ
== Eine Folie
#fusszeile
Der Text der Folie.
```]

Auf der Titel- und den Abschnittsfolien muss sie ins Theme: die beiden Bilder
sind Funktionen, und eine Funktion, die eine andere umschließt, ergänzt sie,
statt sie zu ersetzen.

#show-code[```typ
#let basis = themes.default
#let mit(f) = (t, s, geo) => { f(t, s, geo); fusszeile }

#show: presentation.with(
  theme: basis + (title-slide: mit(basis.title-slide), section: mit(basis.section)),
)
```]

#warning[
  *Nicht über `style:`.* Der Haken sieht nach der bequemen Abkürzung aus:
  `style: it => { fusszeile; it }` schriebe die Fußzeile auf jede Folie, ohne
  sie einzeln hinzuschreiben. Er ist aber zugleich die Vorlage, mit der jedes
  bewegte Element ein zweites Mal gesetzt wird -- und alles, was dort
  *zeichnet*, wird in jedem Sprite mitgezeichnet.

  Gemessen an einem Deck mit drei Einblendungen je Folie: die Fußzeile stand
  im Browser viermal auf der Folie statt einmal, und in einem Daumenkino aus
  sechs Einzelbildern noch sechsmal zusätzlich. Im Rumpf gezählt, dasselbe
  Deck, dieselben Sprites: einmal. Auf dem Papier fällt es nicht auf, dort gibt
  es keine Sprites.

  `style:` ist für Typografie da -- Schrift, Größe, Farbe, Zeilenabstand --,
  und dafür ist es genau richtig: Hintergrund und Sprite brauchen dieselbe.
]

#info[
  Eine im Rumpf platzierte Fußzeile sitzt am unteren Rand des *Rumpfes*, nicht
  am unteren Rand der Folie; dazwischen liegt der `foot-gap` des Themes. Ein
  `dy:` am `place` schiebt sie dorthin, wo sie hin soll.
]

#warning[
  `info()` liest den Stand der Folie, die gerade gesetzt wird, und braucht
  deshalb ein `context` um sich. *Vor* der Präsentation gibt es nichts zu
  lesen; dort bricht es mit einer Meldung ab, statt Nullen zu liefern.

  *Danach* nicht: wer die Folien als Argumente übergibt und unter den Aufruf
  noch ein `info()` schreibt, bekommt weiter die Zahlen der letzten Folie. Das
  ließe sich schließen, indem das Deck seinen Stand am Ende abräumt -- gemessen
  kostet das aber Übersetzungs-Spielraum: eine Folie mit einer Einblendung
  neben einem `tiles` ging damit von null auf drei
  "did not converge"-Meldungen. Eine Ecke, in der niemand steht, ist das nicht
  wert; in der Show-Regel-Form steht hinter dem Deck ohnehin nichts.
]


=== `deck-outline()`: wie das Deck geschnitten ist

`info()` sagt, *wo* man steht. Es sagt nicht, wie das Ganze gegliedert ist --
und wer sich eine Navigationsleiste baut, braucht genau das: welche Folien zu
welchem Abschnitt gehören. `deck-outline()` gibt es heraus, einen Eintrag je
Abschnitt, in der Reihenfolge, in der sie kommen:

// check: folie
#show-code[```typ
#context for a in deck-outline() [
  - #a.number. #a.title -- Folien #a.first bis #a.last (#a.count)
]
```]

An einem Deck mit `slide-level: 3` und zwei Teilen zu je zwei Unterabschnitten
kommt heraus: der erste Teil deckt die Folien 1 bis 3, seine beiden
Unterabschnitte 1 bis 2 und 3 bis 3, der zweite Teil 4 bis 7.

`first`, `last` und `count` zählen **transitiv**: unter einen Abschnitt der
Tiefe 1 fallen auch die Folien seiner Unterabschnitte. Eine Leiste, die nur
die unmittelbar eigenen zählte, zeigte für jede Oberüberschrift eine Null. Ein
Abschnitt ohne Folien unter sich hat `none` bei `first` und `last` und `0` bei
`count`.

#info[
  Gelesen wird nur, was jede Folie ohnehin mit sich trägt -- kein `query`, kein
  zweiter Gang durch das Dokument, dieselbe Antwort in beiden Ausgaben.
  Nachgemessen: `tour`, `theme-editorial` und `geogebra` sind mit und ohne
  diesen Aufruf byteidentisch, in HTML wie im PDF.
]

#warning[
  Ein fremdes Paket, das die Gliederung über `query(heading)` sucht, findet
  nichts: die Überschriftennotation zerlegt den Rumpf an seinen Überschriften
  und kopiert `depth` und `body` heraus, das Element selbst fällt weg. Das gilt
  in *beiden* Ausgaben, nicht nur im Browser. `deck-outline()` ist die Antwort
  darauf -- dieselbe Auskunft, ohne dass jemand ein Dokument durchsuchen muss,
  das so nicht gebaut ist.
]

= API-Referenz

Erzeugt aus den Kommentaren der Quelldateien. Die Reihenfolge folgt dem Aufbau
des Pakets: erst die Präsentation und ihre Folien, dann die Bausteine, dann
Medien und Brücke, zuletzt die Maße und Farben.

== Die Präsentation

// `split-body`, `pause-tokens` und `apply-pauses` zerlegen den Rumpf und
// gehören nicht zur öffentlichen Fläche.
#show-module(read("../src/present.typ"), name: "typstage",
             exclude: ("split-body", "pause-tokens", "apply-pauses",
                       "slides-from-body", "stiller-lauf"))

== Folien

#show-module(read("../src/slides.typ"), name: "typstage")

== Einblenden, Bewegen, Staffeln

// `anim-kern` ist das geprüfte Innere von `anim`. `stagger` benutzt es von
// innen, `lib.typ` reicht es nicht hinaus. Dasselbe gilt für die zwei
// Handlanger von `scene`.
#show-module(read("../src/elements.typ"), name: "typstage",
             exclude: ("anim-kern", "szene-messbar", "szene-zwischen"))

== Layouts

#show-module(read("../src/layout.typ"), name: "typstage")

== Themes

// Nur der Bauplan und die fünf fertigen; die einzelnen Titel- und
// Abschnittsbilder sind Bausteine daraus und stehen nicht für sich.
#show-module(read("../src/themes.typ"), name: "typstage",
             only: ("theme", "themes"))

== Paletten

// Nur, was `lib.typ` hinausreicht. `kanal`, `leuchtdichte`, `lesbar` und die
// Prüfung selbst sind Innenleben.
#show-module(read("../src/palettes.typ"), name: "typstage",
             only: ("palettes", "contrast", "palette-report"))

== Medien und Einbettungen

// `fallback-box` ist nicht mehr öffentlich; `embed` und `geogebra` benutzen es
// von innen, wenn im Seitensatz kein Applet steht.
#show-module(read("../src/media.typ"), name: "typstage",
             exclude: ("fallback-box",))

== Die Brücke

#show-module(read("../src/bridge.typ"), name: "typstage")

== GeoGebra

// `resolve-target` und `no-stray-target` gehören zum Innenleben; das
// Applet-Dokument in `applet.typ` erst recht.
#show-module(read("../src/geogebra.typ"), name: "typstage",
             exclude: ("resolve-target", "no-stray-target"))

== Maße, Farben, Laufzeitdateien

// Nur, was `lib.typ` auch hinausreicht.
#show-module(read("../src/config.typ"), name: "typstage",
             only: ("slide-width", "slide-height", "slide-margin",
                    "dark", "accent", "paper", "muted",
                    "runtime-version", "runtime-files"))
