// Der Rundgang — dieses Deck zeigt jede Funktion des Pakets und handelt
// zugleich von ihr.
//
//   typst compile rundgang.typ rundgang.html --format html --features html
//   typst compile rundgang.typ rundgang.pdf
//   typst compile rundgang.typ handout.pdf     (mit handout: 3 unten)
//
// Bewusst in `themes.plain` gehalten: das Layout soll sich heraushalten,
// gezeigt wird das Paket, nicht der Geschmack.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(
  theme: themes.plain,
  title: [Ein Rundgang durch typstage],
  subtitle: [Jede Funktion einmal — und wozu sie da ist],
  author: [typstage #runtime-version],
  date: datetime(year: 2026, month: 8, day: 20),
  transition: "slide",
  // Beide Zeiten in Millisekunden: der Folienwechsel und das Einblenden.
  transition-duration: 420,
  duration: 520,
  // Der Stil-Haken gilt für Folien *und* für die bewegten Teile — beide werden
  // getrennt gesetzt und müssen dieselbe Typografie bekommen.
  style: it => { set par(justify: false); it },
)

= Worum es geht

== Eine Quelle, drei Ausgaben

#speaker-note[
  Hier nicht in die Technik gehen. Die Folie sagt, was hinten herauskommt;
  wie es gemacht ist, kommt gleich.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Was hineingeht])[
    Eine `.typ`-Datei. Überschriften trennen die Folien: `=` beginnt einen
    Abschnitt, `==` eine Folie, `== #h(0pt)` eine ohne Titelbalken.
  ],
  callout(title: [Was herauskommt])[
    Ein animierter Vortrag als einzelne HTML-Datei, ein Foliensatz als PDF —
    eine Seite je Folie, nicht je Schritt — und mit `handout: 3` ein Handout
    zum Mitschreiben.
  ],
)

#anim([Ohne Server, ohne Nachladen: die HTML-Datei trägt alles bei sich.],
      at: 2, enter: "fade-up")

== Zwei Wege, ein Deck zu bauen

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Über Überschriften])[
    #raw(lang: "typ", "#show: presentation.with(…)\n\n= Ein Abschnitt\n== Eine Folie\nInhalt …")

    Das ist der Weg für Vorträge, die man schreibt. Dieses Deck benutzt ihn.
  ],
  card(title: [Als Argumente])[
    #raw(lang: "typ", "#presentation(\n  title-slide(title: […]),\n  section([Ein Abschnitt]),\n  slide(title: […], note: […])[…],\n)")

    Der Weg für Vorträge, die *berechnet* werden — Folien aus einer Schleife.
    `theme-night` im selben Ordner macht es so.
  ],
)

#anim([Beides schließt sich aus: entweder Überschriften oder Argumente.],
      at: 2, enter: "fade-up")

== Typst setzt, der Browser bewegt

#statement(size: 1.3em)[
  Jede Folie wird von Typst gesetzt und als SVG eingebettet.
]

#anim([Die Anordnung ist deshalb dieselbe wie im PDF — auf den Punkt. Bewegt
       wird erst danach, und nur das, was angemeldet ist.],
      at: "2-", enter: "fade-up")

= Erscheinen lassen

== anim — ein Stück, ein Schritt

#transition("zoom")

#stagger(
  card(title: [`at: auto`])[Der nächste freie Schritt. Aufeinanderfolgende
    Einblendungen nummerieren sich dadurch selbst.],
  card(title: [`at: 3` und `at: "2-"`])[Eine Zahl heißt „ab hier". Beides ist
    dasselbe, einmal als Zahl, einmal als Auswahl geschrieben.],
)

#anim([Und `at: "1,3"` heißt: da, weg, wieder da.], at: "1,3", enter: "fade-left")

== stagger — mehreres nacheinander

#side-by-side(
  split: (1fr, 1fr),
  stagger[
    - Als Liste geschrieben — je Punkt ein Schritt.
    - Die Aufzählungszeichen setzt `stagger` selbst.
    - Sonst stünden sie da, bevor ihr Punkt erscheint.
  ],
  stagger(
    card(title: [Als Stücke])[Statt einer Liste beliebige Blöcke.],
    card(title: [`stride: 0`])[Alle im selben Schritt, gestaffelt nur über
      `stagger:` in Millisekunden.],
  ),
)

== pause — für Folien, die sich einfach entfalten

Kein `anim`, keine Schrittnummern: alles nach einem `#pause` kommt einen
Schritt später.

#pause

#callout(title: [Wo es nicht wirkt])[
  `#pause` wird auf oberster Ebene einer Folie gelesen. In einer Rasterzelle
  oder in einer Tabelle steht der Inhalt als Feld eines Elements — dort greift
  es nicht, und es braucht `anim`.
]

== alternatives — mehrere Fassungen an derselben Stelle

#alternatives(
  card(title: [Erste Fassung])[Eine löst die vorige ab, an genau derselben
    Stelle. Die Folie springt dabei nicht: reserviert wird der Platz der
    größten Fassung.],
  card(title: [Zweite Fassung])[Nützlich für dieselbe Aussage in mehreren
    Anläufen — oder für eine Zeichnung, die sich Schritt für Schritt ändert.],
  card(title: [Dritte Fassung])[`inline: true` macht daraus einen Wechsel
    mitten im Satz.],
)

= Bewegen

== morph — dasselbe Ding, neuer Ort

#speaker-note[Beim Blättern wirklich blättern lassen — im Standbild sieht man nichts.]

#statement(color: accent)[
  #morph(<formel>, $ e^(i pi) + 1 = 0 $)
]

#anim([Dieselbe Formel steht auf der nächsten Folie noch einmal. Sie erscheint
       dort nicht neu, sondern fliegt hinüber und wächst dabei.],
      at: "2-", enter: "fade-up")

#anim([Quelle und Ziel müssen auf *benachbarten* Folien stehen — der Flug
       entsteht beim Übergang zwischen genau zweien.], at: "3-", enter: "fade-up")

== #h(0pt)

#transition("fade")

#place(center + horizon,
       morph(<formel>, text(size: 2.2em, fill: accent)[$ e^(i pi) + 1 = 0 $]))

== pin — wenn die Form nicht reicht

#transition("push")

Die Zeichen werden nach ihrer Form gepaart. Kommt dasselbe Zeichen mehrfach
vor, kann das danebengehen — dann bekommt es mit `pin` einen Namen.

#statement[
  #morph(<summe>, $ #pin("a", $a$) + #pin("b", $b$) = c $)
]

== #h(0pt)

#transition("cover")

#place(center + horizon,
       morph(<summe>, text(size: 1.9em)[$ c = #pin("b", $b$) + #pin("a", $a$) $]))

= Bausteine

== Die fünf Layouts

#tiles(
  columns: (1fr, 1fr, 1fr),
  card(number: 1, title: [card])[Ein benannter Kasten. `number:` setzt eine
    Ziffernscheibe davor.],
  card(number: 2, title: [callout])[Der Merksatz mit dem Balken links.],
  card(number: 3, title: [side-by-side])[Spalten, `split:` gibt die Breiten.],
)

#anim(side-by-side(
  split: (1fr, 1fr), gutter: 24pt, align: horizon,
  card(number: 4, title: [statement])[Eine große Aussage in der Mitte —
    diese Folie benutzt gerade `tiles` und `side-by-side` zugleich.],
  card(number: 5, title: [tiles])[Ein Raster, das sich selbst staffelt: eine
    Kachel je Schritt, ohne Nummerierung von Hand.],
), at: "4-", enter: "rise", exit: "fade")

= Medien

// Die Zeichenfunktion bekommt einen eigenen Namen, damit `still` sie noch
// einmal aufrufen kann — für das eine Bild, das im PDF steht.
#let kurve(t) = {
  // `t` läuft von 0 bis 1, und Typst zeichnet jedes Bild einzeln. Hier wächst
  // eine Kurve von links nach rechts — man sieht dem Bild also an, dass es
  // gezeichnet wird und nicht bloß verschoben.
  let w = 340pt
  let h = 190pt
  let n = 60
  // `calc.round` liefert einen Fließkommawert; `range` will einen ganzen.
  let bis = calc.max(1, int(calc.round(n * t)))
  let punkte = range(bis + 1).map(i => (
    i / n * w,
    h / 2 - 54pt * calc.sin(i / n * 3 * calc.pi),
  ))
  box(width: w, height: h, clip: true, {
    place(rect(width: w, height: h, fill: luma(94%), stroke: none))
    place(curve(
      stroke: 4pt + accent,
      curve.move(punkte.first()),
      ..punkte.slice(1).map(p => curve.line(p)),
    ))
    place(dx: punkte.last().at(0) - 6pt, dy: punkte.last().at(1) - 6pt,
          circle(radius: 6pt, fill: accent, stroke: none))
  })
}

== Video und Daumenkino

// Senkrecht in die Mitte: die beiden Kästen sind niedriger als der Rumpf, und
// oben angeschlagen bliebe die untere Hälfte der Folie leer.
#v(1fr)

#side-by-side(
  split: (1fr, 1fr),
  // `poster` ist das Bild, das steht, solange nichts läuft — und im PDF, wo
  // gar nichts laufen kann. Ohne es bliebe dort ein leerer Kasten.
  // Genau das Seitenverhältnis des Clips (1280×720): sonst schneidet der
  // Rahmen an den Seiten etwas ab — im Browser wie auf Papier, beide füllen
  // den Kasten und beschneiden dafür.
  video("demo.mp4", width: 340pt, height: 191pt, muted: true, loop: true,
        controls: false, radius: 6pt, poster: image("demo-poster.png")),
  flipbook(
    kurve,
    frames: 30, fps: 24, width: 340pt, height: 190pt, pingpong: true,
    // Auf Papier gibt es keine Bewegung, also muss ein Bild genügen. `auto`
    // nähme das erste — hier wäre das ein Punkt am linken Rand. `still` setzt
    // stattdessen die fertige Kurve dorthin.
    still: kurve(1.0),
  ),
)

#anim([Links ein Video, rechts ein Daumenkino: Bild für Bild von Typst
       gezeichnet und im Browser abgespielt.], at: "2-", enter: "fade-up")

#v(1fr)

== Ein fremdes Dokument einbetten

// `embed` setzt beliebiges HTML in einen abgeschotteten Rahmen. Mit `bridge:`
// bekommt der Rahmen einen Namen, und `bridge-job` schickt ihm zu jedem Schritt
// eine Nachricht. Das Paket liest sie nicht — was sie bedeutet, weiß nur das
// Dokument drüben. Genau so treibt `typstage-geogebra` seine Applets.
// Ein `+` am Zeilenanfang wäre in Typst ein Aufzählungspunkt und würfe den
// Ausdruck zurück in den Textmodus. Die Klammern halten ihn im Code.
// Alles in `em`: `embed` stellt dem Dokument den Grundstil des Vortrags voran,
// und in einem gezoomten Rahmen ist ein CSS-Pixel genau ein Punkt der Folie.
// Damit wächst die Lampe mit den Folien mit. Stünde hier `78px`, bliebe sie
// auf dem Beamer so groß wie auf dem Laptop — also gemessen ein Drittel so
// breit im Verhältnis zur Folie.
#let ampel = (
  "<style>body{display:grid;place-items:center}"
  + "#p{width:3.4em;height:3.4em;border-radius:50%;background:"
  + themes.plain.muted.to-hex() + ";box-shadow:0 0 0 .3em "
  + themes.plain.border.to-hex() + ";transition:background .45s}</style>"
  + "<div><div id=p></div></div><script>"
  // Ohne diese Meldung bleibt der Rahmen stumm: der Runtime schaltet ihn erst
  // frei, wenn das Dokument sich gemeldet hat, und schickt ihm bis dahin nichts.
  + "parent.postMessage({typstage:1,ready:1},'*');"
  + "addEventListener('message',function(e){var d=e.data;"
  + "if(!d||d.typstage!==1||!d.jobs)return;"
  + "d.jobs.forEach(function(j){if(j.farbe)"
  + "document.getElementById('p').style.background=j.farbe;});});</script>"
)

#side-by-side(
  split: (1fr, 1fr),
  embed(html: ampel, width: 100%, height: 190pt, bridge: "ampel"),
  stagger[
    - Der Rahmen bekommt mit `bridge: "ampel"` einen Namen.
    - `bridge-job` schickt ihm zu jedem Schritt ein Wörterbuch.
    - Beim Zurückblättern wird der ganze Lauf mit einem `reset` wiederholt —
      Aufträge müssen also wiederholbar sein.
    - Das Dokument muss sich einmal melden (`postMessage({typstage: 1, ready: 1})`), sonst
      bekommt es nichts.
    - Der Rahmen wird in Folieneinheiten vermessen und mitskaliert. Eine Seite,
      die selbst umbricht, bekommt mit `zoom: false` stattdessen echte
      Bildschirmpixel.
  ],
)

#bridge-job("ampel", (farbe: "#d4d4d8"), at: 1)
#bridge-job("ampel", (farbe: "#eb5e28"), at: 2)
#bridge-job("ampel", (farbe: "#16a34a"), at: 3)

#context anim(
  text(size: 0.9em, fill: muted)[
    Auf dieser Folie gibt es #bridge-targets().len() benanntes Ziel:
    #raw(bridge-targets().join(", ")).
  ],
  at: "3-", enter: "fade",
)

= Aussehen und Ausgabe

== Themes sind Wörterbücher

#side-by-side(
  split: (1.2fr, 1fr),
  card(title: [Drei Wege])[
    `themes.night` nimmt eines der fünf mitgelieferten.

    `themes.lesson + (accent: blue)` ändert eines — ein Theme ist ein
    Wörterbuch, deshalb genügt `+`.

    `theme(paper: …, ink: …, accent: …)` baut eines von Grund auf.
  ],
  callout(title: [Was drinsteht])[
    Farben, Schriften, Größen — und je ein Wort für die gebauten Formen:
    `header`, `footer`, `progress`. Nur Titel- und Abschnittsfolie sind
    Funktionen: sie sind ganze Bilder, keine Abwandlungen voneinander.
  ],
)

== Was das Paket noch mitgibt

#stagger[
  - `slide-width`, `slide-height`, `slide-margin` — die Bühne, auf der alles
    gerechnet wird.
  - `accent`, `paper`, `muted`, `dark` — die Farben der Vorgabe.
  - `runtime-version` und `runtime-files` — für `assets: "split"`, wenn CSS und
    JavaScript neben der Datei liegen sollen statt darin.
]

#anim(callout(title: [Im Browser])[
  #text(size: 0.9em)[
    `→` `←` einen Schritt · `o` Übersicht · `f` Vollbild · `s` Notiz ·
    `p` Druckansicht · `Pos1` `Ende` Anfang und Schluss
  ]
], at: "4-", enter: "rise")
