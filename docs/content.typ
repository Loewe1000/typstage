#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= Über dieses Paket

Das `typstage`-Paket erzeugt aus einer einzigen Typst-Datei eine animierte
Präsentation für den Browser -- und aus derselben Quelle eine PDF. Der Satz
dahinter lautet: *Typst setzt, der Browser bewegt.*

Der übliche Weg zu einer Präsentation aus Typst führt über eine PDF, in der
jeder Schritt eine eigene Seite belegt; bewegt wird dabei nichts. Der andere
Weg, Typsts eigener HTML-Export, überlässt die Anordnung dem Browser -- und
verliert damit gerade das, wofür Typst benutzt wird. `typstage` geht einen
dritten Weg: Jede Folie wird von Typst als SVG gesetzt und als solches in die
HTML-Datei geschrieben. Die Anordnung im Browser ist deshalb dieselbe wie auf
dem Papier, bis auf den Punkt genau. Bewegt wird erst danach: Was sich rühren
soll, wird im Quelltext angemeldet, und eine kleine Laufzeitumgebung im Browser
setzt es mit der Web Animations API in Bewegung.

Daraus folgt der Rest: Eine Folie ist eine Folie und kein Stapel von
Zwischenständen. Die PDF hat eine Seite je Folie, nicht eine je Schritt, und
was allein zur Bewegung gehört, fällt auf dem Papier von selbst weg.

Dieses Manual gliedert sich wie folgt:

+ *Erste Schritte* -- dieses Kapitel: Aufbau, Schreibweisen, Ausgaben, Steuerung
+ *Schritte* -- was auf welchem Schritt einer Folie erscheint
+ *Bewegung und Übergänge* -- wandernde Objekte und der Wechsel zwischen Folien
+ *Medien und Einbettungen* -- Video, fremde Dokumente, gezeichnete Animation
+ *Gestaltung* -- Maße, Farben und eigene Vorlagen
+ *API-Referenz* -- vollständige Funktionsdokumentation

= Schnellstart

Mehr als dies braucht eine vollständige Präsentation nicht: den Import, die
Show-Regel und Überschriften.

#show-code[```typ
#import "@schule/typstage:0.1.0": *

#show: presentation.with(title: [Der Satz des Pythagoras])

= Ein Abschnitt

== Eine Folie

Text auf der Folie.
```]

Daraus entstehen drei Folien: die Titelfolie aus `title`, die Abschnittsfolie
aus `=` und die Folie aus `==`. Übersetzt wird die Datei zweimal, einmal je
Ausgabe:

#show-code[```bash
typst compile vortrag.typ vortrag.html --format html --features html
typst compile vortrag.typ vortrag.pdf
```]

Die erste Zeile ergibt die animierte Präsentation, die zweite den Foliensatz
zum Ausdrucken. Beide lesen dieselbe Datei; keine Nachbearbeitung liegt
dazwischen.

#info[
  Der HTML-Export ist in Typst 0.15 noch als Vorschau gekennzeichnet und
  verlangt deshalb `--features html`. Die Warnung, die Typst dabei ausgibt,
  betrifft den Export im Allgemeinen, nicht dieses Paket.
]

= Zwei Schreibweisen

Dieselbe Präsentation lässt sich auf zwei Arten aufschreiben. Beide führen zu
derselben Ausgabe; `presentation` erkennt an dem, was es bekommt, welche
gemeint ist.

== Mit Überschriften

Als Show-Regel geschrieben, zerlegt `presentation` das Dokument an seinen
Überschriften. `=` erzeugt eine Abschnittsfolie, jede tiefere Überschrift eine
gewöhnliche Folie; der Text bis zur nächsten Überschrift ist ihr Inhalt.

#show-code[```typ
#show: presentation.with(title: [Vortrag], transition: "slide")

= Der Beweis          // Abschnittsfolie

== Die Zerlegung      // gewöhnliche Folie
Der Text dieser Folie.
```]

Auch Überschriften, die erst beim Setzen entstehen, werden zu Folien. Eine
Schleife über eine Liste ergibt so eine Folie je Eintrag:

#show-code[```typ
#for stoff in ("Wasser", "Luft", "Erde") [
  == #stoff
  Etwas über #stoff.
]
```]

#warning[
  Inhalt, der vor der ersten Überschrift steht, gehört zu keiner Folie und
  erscheint nirgends. Ebenso erreicht ein `#set heading`, das nach der
  Show-Regel steht, die Folientitel nicht mehr -- sie verlassen den Bereich,
  den die Regel umschließt.
]

== Als Argumente

Die Folien lassen sich auch einzeln übergeben. Dann ist jede Folie ein
Funktionsaufruf, und was sie ausmacht, steht in ihren Argumenten:

#show-code[```typ
#presentation(
  title-slide(title: [Der Satz des Pythagoras], author: [A. Schulz]),
  section[Der Beweis],
  slide([Die Zerlegung], note: [Zuerst das Quadrat zeigen.])[
    Der Text der Folie.
  ],
)
```]

Die Schreibweise mit Überschriften liest sich wie ein Dokument und ist der
Normalfall. Die Argumentform lohnt sich, wo die Folien berechnet werden -- aus
Daten etwa, über die eine Funktion läuft --, denn eine Liste von Folien lässt
sich mit `..` weiterreichen wie jedes andere Array.

= Drei Ausgaben aus einer Quelle

== Die animierte Präsentation

Der HTML-Lauf ergibt eine einzelne Datei, die sich mit einem Doppelklick
öffnen lässt -- ohne Server und ohne Netz, sofern die Laufzeitumgebung darin
steht; der letzte Abschnitt dieses Kapitels sagt, wovon das abhängt. Die
Folien liegen als SVG darin, bewegt werden sie vom Browser.

== Der Foliensatz

Der PDF-Lauf ergibt eine Seite je Folie, in der Größe der Leinwand. Jedes
Element, das sich im Browser bewegt, steht darauf in seinem Endzustand: was
eingeblendet wird, ist da; von mehreren Fassungen an derselben Stelle steht die
letzte. Was allein zur Bewegung gehört -- Notizen, Folienübergänge, Aufträge an
eingebettete Elemente --, sind Zustandsänderungen ohne Ausgabe und fallen von
selbst weg.

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
  belegen einen eigenen Platz.
]

= Steuerung im Browser

Die Laufzeitumgebung zählt in *Schritten*, nicht in Folien: Eine Folie mit drei
Einblendungen hat drei Schritte, und `→` geht zum nächsten, gleich ob der auf
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
geänderte Nummer springt dorthin.

= CSS und JavaScript

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
    verschicken, auf einen Stick legen und ohne Netz öffnen lässt. Vorgabe.],
  [`"split"`], [Das HTML verweist auf `typstage-0.1.0.css` und
    `typstage-0.1.0.js` daneben. Angebracht, wo mehrere Vorträge in einem
    Ordner liegen: Der Browser lädt die Laufzeit einmal für alle.],
  [`(cdn: …)`], [Dieselben Namen unter der angegebenen Adresse. Für eine
    Website, die viele Vorträge trägt.],
)

Die Dateinamen führen die Version mit sich. So können mehrere Fassungen
nebeneinander liegen, und kein Browser bedient einen neuen Vortrag aus einem
alten Zwischenspeicher.

Typst legt keine Dateien an, also müssen die beiden bei `"split"` und beim CDN
einmal geschrieben werden. Ihr Inhalt steht in `runtime-files`; der
Bündel-Export von Typst 0.15 gibt sie damit in demselben Lauf aus, in dem auch
der Vortrag entsteht:

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
die es verweist. Für das CDN werden dieselben zwei Dateien einmal unter die
angegebene Adresse gelegt.

= Schritte

Eine Folie ist keine Abbildung, sondern ein Ablauf. Sie besteht aus Schritten:
ein Tastendruck zeigt den nächsten Stichpunkt, der übernächste die Formel
darunter, und erst wenn auf der Folie nichts mehr aussteht, blättert der Druck
zur nächsten weiter. Was dabei auf welchem Schritt erscheint, sagt der Selektor
`at`.

Fünf Bausteine bestimmen diesen Ablauf: `anim` blendet ein, `pause` teilt eine
Folie ohne jede Umhüllung auf, `stagger` und `steps` staffeln mehrere Dinge
nacheinander, `alternatives` stellt mehrere Fassungen an denselben Ort. Sie
wirken alle im HTML-Ziel. Im PDF gibt es keine Schritte: dort steht jede Folie
auf einer Seite und jedes Element in seinem Endzustand. Derselbe Quelltext
ergibt beides, ohne Schalter im Dokument.

#info[
  Die Beispiele dieses Kapitels sind gesetztes Papier und zeigen deshalb den
  Endzustand — alles auf einmal. Was im Browser nacheinander geschieht, steht
  im Text daneben oder als Kommentar in der Quelle.
]

== Welcher Schritt

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

Eine ausgeschriebene Zahl setzt den Zeiger neu, und von dort zählt es weiter.
Eine einzelne Korrektur zwingt also nicht dazu, alles dahinter umzunummerieren:

#show-code[```typ
#anim[zuerst]           // 1
#anim(at: 4)[spät]      // 4
#anim[danach]           // 5
```]

=== Die Schreibweisen

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

Eine bloße Zahl ist ein offenes Ende: was einmal da ist, bleibt bis zum Ende
der Folie stehen. Das ist der Regelfall. Eine geschlossene Angabe wie `"1-2"`
oder `"3"` lässt das Element wieder verschwinden -- dann greift `exit`.

=== Nur Einblendungen zählen

#warning[
  Der Zeiger zählt ausschließlich Einblendungen: `anim`, `stagger`, `steps` --
  und damit auch `pause` und `alternatives`, die daraus gebaut sind. Ein
  Applet, ein Video oder ein `morph` verbraucht *keinen* Schritt und schiebt
  nichts weiter. Solche Elemente sind von Anfang an da.
]

Das ist leicht zu übersehen und in zweispaltigen Folien entscheidend. Neben
einem Applet stehen Stichpunkte, die bei eins beginnen sollen -- nicht hinter
den Bewegungen des Applets:

#show-code[```typ
#grid(
  columns: (1fr, 1fr),
  embed(url: "…", width: 100%, height: 220pt),   // kein Schritt
  stagger[
    - erster Stichpunkt                          // Schritt 1
    - zweiter Stichpunkt                         // Schritt 2
  ],
)
```]

Der Zeiger beginnt auf jeder Folie neu. Schrittnummern sind folienlokal; auf
der nächsten Folie steht wieder eins.

== anim

`anim` blendet Inhalt auf bestimmten Schritten ein. Das Argument ist beliebiger
Inhalt, alles Weitere steht in benannten Argumenten: `at`, `enter`, `exit`,
`duration` und `delay`.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    let karte(body) = block(
      fill: luma(96%), inset: 10pt, radius: 5pt, width: 100%, body,
    )
    grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 10pt,
      anim(karte[*von links* \ `enter: "fade-right"`], enter: "fade-right"),
      anim(karte[*von unten* \ `enter: "rise"`], enter: "rise"),
      anim(karte[*unscharf* \ `enter: "blur"`], enter: "blur"),
    )
  },
  source: ```typ
  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 10pt,
    anim(karte[*von links* \ `enter: "fade-right"`], enter: "fade-right"),
    anim(karte[*von unten* \ `enter: "rise"`], enter: "rise"),
    anim(karte[*unscharf* \ `enter: "blur"`], enter: "blur"),
  )
  ```,
  width: 14cm,
)

Im Browser stehen die drei Karten nacheinander auf den Schritten eins, zwei und
drei, jede mit ihrer eigenen Bewegung. Auf Papier stehen sie nebeneinander --
der Platz, den sie einnehmen, ist in beiden Zielen derselbe.

=== enter und exit

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Wert*], [*Bewegung*]),
  [`"fade"`], [nur Deckkraft; Vorgabe für `exit`],
  [`"fade-up"`], [aufblendend nach oben; Vorgabe für `enter`],
  [`"fade-down"`], [aufblendend nach unten],
  [`"fade-left"`], [aufblendend nach links, kommt also von rechts],
  [`"fade-right"`], [aufblendend nach rechts, kommt also von links],
  [`"scale"`], [wächst aus 86 % heran],
  [`"scale-down"`], [schrumpft aus 114 % zusammen],
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
Selektor ein Ende hat. Der Abgang läuft dabei etwas knapper als der Auftritt.

#show-code[```typ
#anim(at: "1-2", exit: "fade-down")[Nur für zwei Schritte da.]
```]

=== duration und delay

`duration` ist `auto` und übernimmt damit die Vorgabe der Präsentation
(`duration:` auf `presentation`, 520). `delay` ist 0. Beide Angaben sind Zahlen
in Millisekunden und gelten für den Auftritt; beim Zurückblättern entfällt die
Verzögerung, damit der Rückweg nicht zäh wird.

#show-code[```typ
#anim(duration: 900, delay: 200)[Langsam und ein wenig später.]
```]

== pause

Für eine Folie, die sich einfach nur entfaltet, muss nichts umhüllt werden.
`#pause` schiebt alles Folgende einen Schritt weiter.

#show-example(
  rendered: {
    block[Zuerst dies.]
    block[Dann das.]
    block[Und zuletzt dies.]
  },
  source: ```typ
  Zuerst dies.
  #pause
  Dann das.
  #pause
  Und zuletzt dies.
  ```,
  width: 12cm,
)

Die Läufe zwischen den Pausen werden vom Folienanfang an durchnummeriert: der
erste steht von Beginn an, der zweite erscheint auf Schritt zwei, der dritte
auf Schritt drei. Danach zählt der Zeiger regulär weiter -- ein `stagger` unter
zwei Pausen beginnt bei vier.

Eine Pause beginnt einen neuen Block, und das PDF setzt ihn genauso. Das ist
keine Kosmetik: im Browser ist ein eingeblendetes Element ohnehin ein Block,
auf Papier flösse es sonst im selben Absatz weiter. Beide Ziele werden deshalb
zum selben Umbruch angehalten.

#warning[
  `#pause` wird auf der obersten Ebene des Folienrumpfs gelesen, `#set`- und
  `#show`-Regeln eingeschlossen: eine Pause hinter `#set text(size: 20pt)`
  wirkt. In einer Rasterzelle, einer Tabelle oder einer Abbildung wird sie
  nicht gesehen -- dort ist der Inhalt ein Feld eines Elements und nicht mehr
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

== stagger und steps

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

Die Zeilen werden dabei selbst gesetzt und nicht der Liste überlassen. Nur so
gehört das Aufzählungszeichen zum eingeblendeten Element -- sonst stünde es im
Hintergrund und wäre schon da, bevor sein Punkt erscheint. Nummerierte Listen
funktionieren genauso, mit den Zahlen an der Stelle der Punkte. Der Abstand
zwischen den Zeilen kommt aus `spacing` (0.65em).

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`start`], [erster Schritt; `auto` schließt an den Zeiger an],
  [`stride`], [Abstand der Schritte; `2` lässt je einen Schritt aus, `0` setzt
               alle Punkte auf denselben],
  [`stagger`], [zusätzliche Verzögerung je Position, in Millisekunden],
  [`enter`], [Bewegung der Punkte, wie bei `anim`],
  [`spacing`], [Abstand zwischen den Zeilen],
)

`stride: 0` und `stagger` gehören zusammen: alle Punkte erscheinen dann auf
einem einzigen Schritt, aber kurz nacheinander eingeschwenkt.

#show-code[```typ
#stagger(stride: 0, stagger: 60)[
  - alle drei auf Schritt eins
  - der zweite 60 ms später
  - der dritte 120 ms später
]
```]

Enthält der Rumpf keine Liste, wird er als ein Stück eingeblendet.

`steps` staffelt beliebige Blöcke, die keine Liste sind -- nach denselben
Regeln, `start` eingeschlossen.

#show-example(
  rendered: {
    import "../src/lib.typ": *
    let karte(body) = block(
      fill: luma(96%), inset: 10pt, radius: 5pt, width: 100%, body,
    )
    steps(
      karte[Erst die Behauptung],
      karte[dann die Begründung],
      karte[und zuletzt das Beispiel.],
    )
  },
  source: ```typ
  #steps(
    karte[Erst die Behauptung],
    karte[dann die Begründung],
    karte[und zuletzt das Beispiel.],
  )
  ```,
  width: 12cm,
)

== alternatives

`alternatives` stellt mehrere Fassungen derselben Sache an denselben Ort, jede
die vorige ersetzend. Sie stehen in einem Kasten, der so groß ist wie die
größte von ihnen, damit ringsherum nichts springt, während sie wechseln.

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

Jede Fassung nimmt genau einen Schritt; die letzte bleibt bis zum Ende der
Folie stehen. Drei Fassungen kosten also drei Schritte, und der Zeiger steht
danach auf dem letzten davon.

Auf Papier wird nur die letzte Fassung gesetzt -- in demselben Kasten, sodass
die Seite die Abstände der Folie behält. Alle zu drucken hieße, sie
übereinanderzustapeln.

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  table.header([*Argument*], [*Wirkung*]),
  [`start`], [erster Schritt; `auto` schließt an den Zeiger an],
  [`align`], [Ausrichtung der Fassungen im gemeinsamen Kasten
              (Vorgabe `top + left`)],
  [`enter`], [Bewegung beim Wechsel (Vorgabe `"fade"`)],
  [`duration`], [Dauer des Wechsels in Millisekunden],
)

#tip[
  Unterschiedlich hohe Fassungen wirken im gemeinsamen Kasten oft unruhig, weil
  die kürzeren oben kleben. `align: center + horizon` setzt jede in die Mitte
  des Kastens, und der Wechsel wird ruhig.
]

= Bewegung zwischen Folien

Beim Wechsel von einer Folie zur nächsten geschieht dreierlei, und zwar
unabhängig voneinander: ein benanntes Objekt kann von seinem alten Platz an
seinen neuen fliegen, die Folien selbst können auf eine bestimmte Weise
wechseln, und zu jeder Folie kann eine Notiz gehören, die nur der Vortragende
zu sehen bekommt.

== Magic Move

`morph` trägt ein Objekt über den Folienwechsel hinweg. Derselbe Name auf zwei
Folien genügt -- das Ding verschwindet dann nicht und erscheint woanders neu,
sondern fliegt hinüber und nimmt dabei die neue Größe und die neue Gestalt an.

#show-code[```typ
== Der Satz des Pythagoras

#align(center, morph(<pythagoras>, $a^2 + b^2$))

== #h(0pt)

#place(center + horizon,
       morph(<pythagoras>, text(size: 2.6em)[$a^2 + b^2 = c^2$]))
```]

Der Name ist eine Zeichenkette oder eine Marke: `morph("pythagoras", …)` und
`morph(<pythagoras>, …)` bedeuten dasselbe. Die Marke liest sich besser, und
Typst färbt sie als das, was sie ist -- als Namen.

Ein Morph verbraucht keinen Schritt und schiebt auch keinen weiter: er steht
von Anfang an auf seiner Folie. Auf Papier bleibt von ihm nichts als sein
Inhalt; jede Folie setzt dort ihre eigene Fassung.

#show-example(
  rendered: {
    import "../src/lib.typ": morph
    align(center, morph(<pythagoras>, $a^2 + b^2$))
  },
  source: ```typ
  #align(center, morph(<pythagoras>, $a^2 + b^2$))
  ```,
  width: 12cm,
)

=== Wie die Paarung arbeitet

Typst backt die Schriftgröße in die Umrisse: dasselbe Zeichen hat bei 20 pt
andere Pfaddaten als bei 34 pt. Für die Paarung wird jeder Umriss deshalb auf
seine größte Koordinate normiert. Übrig bleibt die Form, die Größe fällt
heraus -- ein $a$ findet sein $a$ auch dann wieder, wenn es unterwegs doppelt
so groß wird.

Gepaart wird in zwei Durchgängen: zuerst in Lesereihenfolge nach Form, wobei
jedes Zeichen der Quelle sich das erste noch freie Zeichen gleicher Form auf
der Zielfolie nimmt; was danach übrig ist, geht an das nächstgelegene freie
Zeichen -- sonst ginge ein Zeichen allein deshalb verloren, weil es den Platz
gewechselt hat. Zeichen der Quelle ohne Gegenstück blenden aus, Zeichen des
Ziels ohne Quelle blenden in der zweiten Hälfte der Bewegung ein.

#table(
  columns: (auto, 1fr),
  inset: 6pt,
  align: (left, left),
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(80%)) },
  table.header([`match`], [Bedeutung]),
  [`"auto"`],
  [Zeichenweise, sofern beide Seiten Zeichen enthalten und keine von beiden
   mehr als 48; sonst als ein Block. Die Vorgabe.],
  [`"glyph"`],
  [Immer zeichenweise, auch bei vielen Zeichen.],
  [`"block"`],
  [Immer als ein Rechteck: das ganze Objekt wandert und wird dabei verzerrt.
   Das Richtige für Bilder, Zeichnungen und alles, was keine Schrift ist.],
)

`duration` gibt die Dauer des Fluges in Millisekunden an. Der Wert der
Zielfolie gilt, sonst der der Quelle, sonst `duration` der Präsentation
(520 ms).

=== Wo es aufhört

Drei Grenzen sind zu kennen.

*Es fliegt nur zwischen benachbarten Folien.* Der Flug findet beim Weiterblättern
statt, von einer Folie zur unmittelbar nächsten oder vorigen. Sprünge -- die
Übersicht mit `o`, `Home`, `End`, ein Sprung über die Adresszeile -- setzen die
Zielfolie ohne Bewegung. Ein Name auf Folie 3 und derselbe auf Folie 7 tun
darum nichts.

*Zwei gleiche Namen auf der Zielfolie teilen sich dieselbe Quelle.* Gesucht wird
die Quelle über ihren Namen, gelaufen wird über die Ziele: beide starten
sichtbar am selben Ort, das Zeichen spaltet sich vor den Augen der Zuhörer.
Wo das gewollt ist, ist es ein Mittel; wo nicht, ist es ein Fehler.

*Auf der Quellfolie zählt bei gleichem Namen nur der letzte.* Umgekehrt gilt
die Aufteilung also nicht.

== Folienübergänge

`transition` bestimmt, wie eine Folie hereinkommt. Die Präsentation setzt die
Vorgabe für alle, eine einzelne Folie darf davon abweichen -- entweder als
Angabe an `slide` oder als Aufruf im Folienrumpf:

#show-code[```typ
#show: presentation.with(transition: "slide", transition-duration: 420)

== Diese eine anders
#transition("cover", from: "bottom")

// oder, in der anderen Schreibweise:
#slide([Diese eine anders], transition: (kind: "cover", from: "bottom"))[…]
```]

Die Arten und ihre Angaben:

#table(
  columns: (auto, auto, 1fr),
  inset: 6pt,
  align: (left, left, left),
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
  [Eine runde Blende: `"open"` öffnet die neue Folie auf, `"close"` schließt die
   alte über ihr zu.],
  [`"wipe"`], [`direction`, `from`],
  [Dasselbe als gerade Kante; `from` nennt zusätzlich, an welcher Kante sie
   beginnt.],
  [`"flip"`], [`axis`],
  [Umschlagen im Raum, wie ein gewendetes Blatt.],
  [`"cube"`], [`axis`],
  [Wie `flip`, aber als zwei Seiten eines Würfels, der sich weiterdreht.],
)

`from` ist `"right"` (Vorgabe), `"left"`, `"top"` oder `"bottom"` und nennt,
woher die neue Folie kommt; bei `"wipe"` ist es die Kante, an der die Blende
ansetzt, und ohne Angabe die linke. `direction` ist `"in"`/`"out"` bei `"zoom"`
und `"open"`/`"close"` bei `"iris"` und `"wipe"`, jeweils der erste Wert als
Vorgabe. `axis` ist `"y"` (Vorgabe, Drehung um die Senkrechte) oder `"x"`.

Drei Dinge sind an den Übergängen weniger selbstverständlich, als sie aussehen.

*Der Übergang gehört der Grenze zwischen zwei Folien, nicht der
Blätterrichtung.* Maßgeblich ist immer die Angabe der späteren der beiden
Folien -- also derjenigen, die beim Vorwärtsblättern hereinkommt. Rückwärts
gilt dieselbe Angabe; sie wandert nicht auf die andere Folie. Die Angabe an
einer Folie beschreibt darum wirklich, wie diese Folie hereinkommt.

*Rückwärts läuft er als echte Umkehrung.* Nicht derselbe Übergang noch einmal,
sondern seitenverkehrt: was hinausgeschoben wurde, kommt von derselben Seite
zurück; was sich zugezogen hat, öffnet sich wieder.

*Trifft ein Morph auf die Folie, überblendet sie.* Sobald zwischen zwei Folien
etwas fliegt, weicht der eingestellte Übergang einer schlichten Überblendung.
Sonst schöbe die Folie das Objekt unter sich weg, das gerade über sie hinweg
fliegt -- die Bewegung trägt in diesem Fall der Morph.

`transition-duration` an der Präsentation gilt für alle Übergänge und ist in
Millisekunden angegeben (Vorgabe 420). Eine eigene Dauer je Übergang gibt es
nicht.

#warning[
  Eine unbekannte Art bricht den Bau nicht ab, sondern wird im Browser zur
  Überblendung. Ein Tippfehler in `#transition("iirs")` fällt also erst auf,
  wenn nichts geschieht.
]

== Notizen

`speaker-note` legt eine Notiz zur Folie ab. Sie steht im Folienrumpf, oder als
Angabe `note` an `slide`:

#show-code[```typ
== Der Satz des Pythagoras
#speaker-note[
  Erst die Zerlegung zeigen, dann die Formel -- nicht umgekehrt.
]

// oder:
#slide([Der Satz des Pythagoras], note: [Erst die Zerlegung zeigen.])[…]
```]

Im Browser holt die Taste `s` die Notiz der laufenden Folie für gut zwei
Sekunden als Einblendung an den unteren Rand -- sichtbar auf dem Bildschirm,
der gerade vorführt, und darum eher ein Stichwort als ein Manuskript. In die
Einblendung geht nur der reine Text ein; Auszeichnungen fallen weg.

Im Handout steht jede Notiz bei ihrer Folie: bei einer oder zwei Folien je
Seite darunter, ab drei daneben. Wo eine Folie keine Notiz hat, treten
Linien an ihre Stelle. In der gewöhnlichen PDF -- eine Seite je Folie, ohne
`handout` -- erzeugt eine Notiz gar nichts; sie ist dort nur eine
Zustandsänderung ohne Ausgabe.

= Medien und Einbettungen

Drei Bausteine bringen auf die Folie, was Typst selbst nicht bewegen kann: ein
Video, ein fremdes Dokument, eine von Typst gezeichnete Animation. Für alle
drei ist mitbedacht, was in der PDF an ihre Stelle tritt.

== Video

`video` legt ein echtes HTML5-Video über die Folie. Beim Betreten der Folie
läuft es an, beim Verlassen hält es an.

#show-code[```typ
#video("wellen.mp4", width: 100%, height: 240pt, poster: image("welle.png"))
```]

Wichtig sind `src` (der Pfad, wie ihn der Browser sieht), `width` und `height`,
`poster` (ein Standbild), sowie `autoplay`, `loop`, `muted` und `controls`.
`autoplay` und `muted` sind an, `loop` und `controls` aus -- Browser lassen ein
Video von sich aus nur stumm anlaufen. `radius` rundet die Ecken, `at` und
`enter` sagen wie bei jedem Element, ab welchem Schritt es da ist und wie es
kommt.

#info[
  Auf Papier steht an dieser Stelle das `poster`, sonst eine graue Fläche.
  Ein Video ohne `poster` hinterlässt im Handout also ein leeres Rechteck.
]

== Eingebettete Dokumente

`embed` setzt beliebige Web-Inhalte in einen abgeschotteten Rahmen: `url` lädt
eine Seite, `html` bettet ein eigenes Dokument als Text ein. Der Rahmen wird in
Folieneinheiten vermessen und mitskaliert, damit das eingebettete Dokument in
jedem Fenster denselben Ausschnitt sieht.

In der PDF steht kein Rahmen, dort bliebe ein leerer Kasten. Deshalb gibt es
zwei Angaben, die allein die gedruckte Ausgabe betreffen: `fallback` nimmt
beliebigen Inhalt auf, der an die Stelle des Rahmens tritt -- eine
CeTZ-Zeichnung, ein Bild, eine Tabelle --, und `link` setzt darunter eine im
PDF anklickbare Adresse, über die der Leser des Handouts zum lebenden Ding
kommt. Ohne `fallback` bleibt ein Platzhalter mit der Beschriftung `label`.

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

== Daumenkino

`flipbook` ist der besondere Fall: hier zeichnet Typst jedes Einzelbild. Die
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

== Die Brücke

Ein eingebettetes Dokument lässt sich von Typst aus nicht steuern -- ihm lässt
sich aber bei jedem Schritt sagen, was zu tun ist. Genau das leistet die
Brücke: `embed(bridge: <name>, …)` gibt dem Rahmen einen Namen, `bridge-job`
legt für einen Schritt eine Aufgabe an diesen Namen ab, und der Browser stellt
sie beim Erreichen des Schritts in den Rahmen zu. Was in der Aufgabe steht, ist
allein Sache des Dokuments auf der anderen Seite: `payload` ist ein Wörterbuch
und wird ungelesen durchgereicht. So steuert ein Begleitpaket ein eingebettetes
Dokument, ohne dass der Kern etwas davon wissen muss.

#show-code[```typ
#embed(html: "…", bridge: <applet>, width: 100%, height: 240pt)
#bridge-job(<applet>, (befehl: "setze", wert: 3), at: 2)
```]

`at` ist ein Schrittwähler wie bei `anim`, die Vorgabe `"1-"` -- die meisten
Aufgaben richten das Dokument beim Betreten der Folie ein. Eine Aufgabe rückt
den Schrittzeiger nicht weiter. Beim Zurückblättern und beim Betreten einer
Folie wird der ganze Lauf von vorn wiederholt, weshalb Aufgaben wiederholbar
sein müssen.

`typstage-geogebra` ist ein solches Begleitpaket: es baut die Konstruktion mit
GeoGebra und holt die Dramaturgie aus den Folien. Alles, was es vom Kern
braucht, sind `embed(bridge: …)` und `bridge-job`.

= Gestaltung

== Die Leinwand

`presentation` bestimmt das Format der Folie -- und weil es das Seitenformat
setzt, lässt es sich hier nicht vorführen, sondern nur zeigen:

#show-code[```typ
#show: presentation.with()                              // 16:9, die Vorgabe
#show: presentation.with(width: 800pt, height: 600pt)   // 4:3
#show: presentation.with(margin: 48pt)                  // mehr Luft
```]

Ohne Angabe ist die Folie 16:9 auf A4-Breite (841.89 pt). Das ist kein Zufall:
so trägt eine Folie den Text in derselben körperlichen Größe wie eine
Handout-Seite. `height` ergibt jedes andere Verhältnis, `margin` den Abstand
zum Rand -- ohne Angabe 32 pt, mit der Breite mitskaliert.

Alles, was das Thema zeichnet -- das Titelband, die Schriftgrößen, die Linien,
der Fortschrittsbalken --, ist auf der Vorgabe-Leinwand gemessen und skaliert
mit der Breite mit. Eine halb so breite Präsentation sieht darum gleich aus,
nur kleiner, statt einen Kopf zu tragen, der für die doppelte Breite gebaut
wurde. Wirklich anders wird das Layout nur durch das *Verhältnis*. Der Browser
folgt: die Bühne wird auf das Verhältnis eingepasst, die Bildchen der Übersicht
und die gedruckten Seiten ebenso.

== Farben und Typografie

Vier Farben tragen das Thema. Sie sind aus dem Paket zu haben und lassen sich
im eigenen Satz weiterverwenden -- etwa als `accent.lighten(85%)` für den
Untergrund einer Karte.

#show-example(
  rendered: {
    import "../src/lib.typ": dark, accent, paper, muted
    let feld(c, n) = {
      block(width: 2.6cm, height: 1.1cm, fill: c,
            stroke: 0.5pt + luma(70%), radius: 3pt)
      v(4pt)
      align(center, raw(n))
    }
    grid(
      columns: 4, column-gutter: 10pt,
      feld(dark, "dark"), feld(accent, "accent"),
      feld(paper, "paper"), feld(muted, "muted"),
    )
  },
  source: ```typ
  #import "@schule/typstage:0.1.0": dark, accent, paper, muted
  ```,
  width: 12cm,
)

`dark` trägt Titelband und Abschnittsfolie, `accent` die Marken und den
Fortschrittsbalken, `paper` den Untergrund, `muted` die Nebensachen. Es sind
Konstanten des Pakets: der Rahmen um die Folie greift unmittelbar auf sie zu
und ist darum nicht auszutauschen.

Für die Typografie gibt es den Haken `style`: eine Funktion, die um jeden
Folienrumpf gelegt wird.

#show-code[```typ
#show: presentation.with(
  style: it => {
    set text(font: "Libertinus Serif")
    set par(justify: true)
    show math.equation: set text(size: 1.05em)
    it
  },
)
```]

Dass es diesen Haken überhaupt gibt, hat einen handfesten Grund. Im Browser
wird jedes bewegte Element ein zweites Mal gesetzt, in einem eigenen kleinen
Rahmen neben der Folie. Größe, Farbe, Schrift, Schnitt, Lage und Sprache des
Textes werden dabei mitgenommen, alles Übrige aber nicht: `#show`-Regeln und
`#set`-Regeln für Absätze oder Formeln kennt dieser Rahmen nicht. `style` wird
auf beides gelegt -- auf den Folienrumpf und auf jedes einzelne bewegte Element
--, und nur so sehen Hintergrund und Bewegtes gleich aus.

#info[
  Alles, was über die sechs Texteigenschaften hinausgeht, gehört deshalb in
  `style` und nicht in eine `#set`-Regel im Dokument.
]

= API-Referenz

Erzeugt aus den Kommentaren der Quelldateien. Die Reihenfolge folgt dem
Aufbau des Pakets: erst die Präsentation und ihre Folien, dann die Bausteine,
dann Medien und Brücke, zuletzt die Maße und Farben.

== Die Präsentation

// `split-body`, `pause-tokens` und `apply-pauses` zerlegen den Rumpf und
// gehören nicht zur öffentlichen Fläche.
#show-module(read("../src/present.typ"), name: "typstage",
             exclude: ("split-body", "pause-tokens", "apply-pauses"))

== Folien

#show-module(read("../src/slides.typ"), name: "typstage")

== Einblenden, Bewegen, Staffeln

#show-module(read("../src/elements.typ"), name: "typstage")

== Medien und Einbettungen

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
