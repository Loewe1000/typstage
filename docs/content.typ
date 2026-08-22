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
+ *Eine Rechnung entwickeln* -- Magic Move über mehrere Folien
+ *Aus einer Quelle drei Ausgaben* -- Präsentation, Foliensatz, Handout
+ *Das eigene Aussehen* -- Themes, Farben, Leinwand, Bausteine
+ *API-Referenz* -- vollständige Funktionsdokumentation

#info[
  Die gesetzten Beispiele dieses Handbuchs sind Papier und zeigen deshalb den
  Endzustand -- alles auf einmal. Was im Browser nacheinander geschieht, steht
  im Text daneben oder als Kommentar in der Quelle.
]

= Die erste Präsentation

Ziel dieses Kapitels: eine vollständige, vorführbare Präsentation, in zehn
Minuten und ohne Umwege.

== Eine Datei genügt

Mehr als dies braucht es nicht -- den Import, eine Show-Regel und
Überschriften. Die folgende Datei ist vollständig und lässt sich abtippen:

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  title: [Der Satz des Pythagoras],
  subtitle: [Eine Herleitung in vier Schritten],
  author: [Mathematik · Klasse 9],
  date: datetime.today(),
  transition: "slide",
)

= Worum es geht

== Die Behauptung

#speaker-note[Erst die Zerlegung zeigen, dann die Formel -- nicht umgekehrt.]

#stagger[
  - Ein rechtwinkliges Dreieck hat zwei Katheten und eine Hypotenuse.
  - Über jeder Seite steht ein Quadrat.
  - Die beiden kleinen sind zusammen so groß wie das große.
]

#v(1em)

#anim(callout[Genau das behauptet der Satz.], enter: "scale")

== Und das ist die Formel

#statement[$ a^2 + b^2 = c^2 $]
```]

Daraus entstehen vier Folien: die Titelfolie aus `title`, eine Abschnittsfolie
aus `=`, und je eine gewöhnliche Folie aus den beiden `==`. Der Text bis zur
nächsten Überschrift ist der Rumpf einer Folie.

So sieht der Rumpf der Folie „Die Behauptung" aus, wenn alle Schritte
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
  [`?`], [die Tastenbelegung einblenden],
)

Ein Klick in das linke Viertel des Fensters blättert zurück, jeder andere
vorwärts; innerhalb eines eingebetteten Elements bleibt der Klick bei diesem.
In der Übersicht führt ein Klick auf ein Vorschaubild zu dieser Folie.

Die Adresszeile trägt den laufenden Schritt mit, `#12` etwa den zwölften. Ein
neu geladenes Fenster steht damit wieder an derselben Stelle, und eine von Hand
geänderte Nummer springt dorthin -- praktisch, um im Vortrag eine bestimmte
Stelle sofort zu erreichen.

#warning[
  Inhalt, der vor der ersten Überschrift steht, gehört zu keiner Folie und
  erscheint nirgends. Ebenso erreicht ein `#set heading`, das nach der
  Show-Regel steht, die Folientitel nicht mehr -- sie verlassen den Bereich,
  den die Regel umschließt. Für die Typografie der Folien gibt es `style` --
  siehe das Kapitel „Das eigene Aussehen".
]

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

Vier Bausteine decken so gut wie alles ab. Sie lassen sich auf einer Folie
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
)

Dazu kommt `tiles` für ein Kachelraster, das sich von selbst staffelt (Kapitel
„Das eigene Aussehen"), und `morph` für Objekte, die zwischen zwei Folien
fliegen (Kapitel „Eine Rechnung entwickeln").

== Der Schrittzeiger

Jede Folie führt einen Schrittzeiger mit. `at` ist vorgabemäßig `auto`, und
`auto` heißt „der nächste freie Schritt". Aufeinanderfolgende Einblendungen
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
)

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
  [`"none"`], [ohne Bewegung -- der Inhalt ist schlicht da],
)

Die Himmelsrichtung im Namen ist die Bewegungsrichtung, nicht die Herkunft:
`"fade-right"` läuft nach rechts und kommt daher von links.

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

*Ein `fr`-Abstand gehört nicht ins verfolgte Element.* `fr` heißt „Anteil an
dem, was übrig bleibt" -- und was übrig bleibt, verteilt der Elternteil unter
den Geschwistern. Ein verfolgtes Element wird aber allein gemessen und sieht
seine Geschwister nicht. Ein `#v(1fr)` unmittelbar in einem `anim` wird deshalb
durchgereicht statt verfolgt (an Leerraum ist ohnehin nichts zu animieren);
steht es zwischen anderem Inhalt, meldet das Paket einen Fehler, statt die
Folie stillschweigend verrutschen zu lassen:

#show-code(```typ
#anim[Links #v(1fr) Rechts]        // Fehler -- das fr gehört nach draußen
#anim[Links] #v(1fr) #anim[Rechts] // so ist es gemeint
```)

Ein `fr` *innerhalb* eines Rasters ist davon nicht betroffen:
`anim(grid(rows: (1fr, 1fr), …))` verteilt das Raster unter sich selbst und
weiß daher, wovon es einen Anteil nehmen soll.

= Etwas vorführen statt behaupten

Ziel dieses Kapitels: eine Folie, auf der etwas geschieht, das Typst selbst
nicht bewegen kann -- eine Konstruktion, die sich verändert, ein Video, eine
gezeichnete Bewegung. Für alle drei ist mitbedacht, was auf dem Papier an ihre
Stelle tritt.

== Ein Applet neben den Stichpunkten

Das Begleitpaket `typstage-geogebra` bringt GeoGebra-Applets auf die Folie. Es
ist ein eigenes Paket, damit eine Präsentation ohne Applets nichts davon
mitschleppt; alles, was es vom Kern braucht, sind zwei Funktionen.

Der übliche Aufbau einer solchen Folie: links die Konstruktion, rechts die
Stichpunkte, und darunter -- außerhalb des Layouts -- die Befehle, die das
Applet aufbauen und Schritt für Schritt weiterbewegen.

#show-code[```typ
#import "@schule/typstage:0.1.0": *
#import "@schule/typstage-geogebra:0.1.0": *

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
  können, steht im Handbuch von `typstage-geogebra`. Hier geht es nur darum,
  wie sie sich in den Ablauf einer Folie einfügen.
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

Soll das eingebettete Dokument den Schritten der Folie folgen, bekommt es einen
Namen -- und `bridge-job` legt für einen Schritt einen Auftrag an diesen Namen
ab, den der Browser beim Erreichen des Schritts in den Rahmen zustellt:

#show-code[```typ
#embed(html: "…", bridge: <applet>, width: 100%, height: 240pt)
#bridge-job(<applet>, (befehl: "setze", wert: 3), at: 2)
```]

Was im Auftrag steht, ist allein Sache des Dokuments auf der anderen Seite:
`payload` ist ein Wörterbuch und wird ungelesen durchgereicht. Genau darauf
setzt `typstage-geogebra` auf -- und jedes andere Begleitpaket kann es genauso
tun.

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
  vorn wiederholt. Aufträge müssen deshalb wiederholbar sein: „setze $a$ auf
  2,5" ist gut, „erhöhe $a$ um 1" nicht.
]

== Video

`video` legt ein echtes HTML5-Video über die Folie. Beim Betreten der Folie
läuft es an, beim Verlassen hält es an.

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
letzte Bild stehen. Auf Papier steht ein einziges: `render(0.0)`, oder was
`still` an seine Stelle setzt.

#warning[
  Jedes Einzelbild wird wirklich gesetzt. 24 Bilder heißen 24 Layouts und 24
  SVG-Bäume in der Datei -- bei aufwendigen Zeichnungen wächst beides schnell.
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
  Die Folientitel der Kette durchzunummerieren („Schritt 2 von 3") kostet
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

Die Dateinamen führen die Version mit sich, damit mehrere Fassungen
nebeneinander liegen können und kein Browser einen neuen Vortrag aus einem
alten Zwischenspeicher bedient.

Typst legt keine Dateien an, also müssen die beiden bei `"split"` und beim CDN
einmal geschrieben werden. Ihr Inhalt steht in `runtime-files`; der
Bündel-Export gibt sie in demselben Lauf aus, in dem auch der Vortrag entsteht:

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
    eine Linie darunter.],
  [`footer`], [`"fraction"` (3 / 12), `"number"` (3), `"center"` (mittig)
    oder `"none"`; `footer-rule` legt eine Haarlinie darüber.],
  [`progress`], [`"bar"` (wachsender Balken unten), `"top"` (dasselbe oben),
    `"tick"` (wandernde Marke auf einer Schiene) oder `"none"`.],
)

Dazu kommen `surface` und `border` für die Karten, `inverted` für hell auf
dunkel, `head-gap`, `foot-gap` und `band-height` für die Luft um den Rumpf --
und `title-slide` und `section`, die ganze Bilder sind: Funktionen
`(t, s, geo) => content`. Die vollständige Liste steht in der API-Referenz.

== Die Farben eines Themes

Sechs Rollen tragen ein Theme: `paper` der Grund der Folie, `ink` der
Fließtext, `strong` die tragende dunkle Farbe, `accent` die Signalfarbe,
`muted` das Nebensächliche, `surface` der Grund einer Karte. Die
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

Fünf Bausteine für den Rumpf. Es sind Inhaltsfunktionen, keine eigenen
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

`title:` ändert die Überschrift (Vorgabe „Merke"), `color:` die Farbe;
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

= API-Referenz

Erzeugt aus den Kommentaren der Quelldateien. Die Reihenfolge folgt dem Aufbau
des Pakets: erst die Präsentation und ihre Folien, dann die Bausteine, dann
Medien und Brücke, zuletzt die Maße und Farben.

== Die Präsentation

// `split-body`, `pause-tokens` und `apply-pauses` zerlegen den Rumpf und
// gehören nicht zur öffentlichen Fläche.
#show-module(read("../src/present.typ"), name: "typstage",
             exclude: ("split-body", "pause-tokens", "apply-pauses"))

== Folien

#show-module(read("../src/slides.typ"), name: "typstage")

== Einblenden, Bewegen, Staffeln

#show-module(read("../src/elements.typ"), name: "typstage")

== Layouts

#show-module(read("../src/layout.typ"), name: "typstage")

== Themes

// Nur der Bauplan und die fünf fertigen; die einzelnen Titel- und
// Abschnittsbilder sind Bausteine daraus und stehen nicht für sich.
#show-module(read("../src/themes.typ"), name: "typstage",
             only: ("theme", "themes"))

== Medien und Einbettungen

// `fallback-box` ist nicht mehr öffentlich; `embed` und `geogebra` benutzen es
// von innen, wenn im Seitensatz kein Applet steht.
#show-module(read("../src/media.typ"), name: "typstage",
             exclude: ("fallback-box",))

== Die Brücke

#show-module(read("../src/bridge.typ"), name: "typstage")

== Maße, Farben, Laufzeitdateien

// Nur, was `lib.typ` auch hinausreicht.
#show-module(read("../src/config.typ"), name: "typstage",
             only: ("slide-width", "slide-height", "slide-margin",
                    "dark", "accent", "paper", "muted",
                    "runtime-version", "runtime-files"))
