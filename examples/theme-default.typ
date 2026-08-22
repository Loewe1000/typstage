// themes.default — der Vortrag im hellen Saal.
//
// Zeigt: flipbook (ein Mäander wandert flussabwärts), stagger in
// Stücke-Form, morph mit pin (dieselbe Größe an drei Stellen einer
// Formel), eine titellose Folie, drei Übergangsarten, ein anim mit
// ausdrücklichem exit, Sprechernotizen.
//
//   typst compile theme-default.typ theme-default.html --format html --features html
//   typst compile theme-default.typ theme-default.pdf

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.default

// Farben für den Mäander, an das Theme angelehnt: Wasser in Blau, Ufer in
// Sand, Prallhang (Erosion) im Akzent des Themes, Gleithang (Ablagerung) in
// einem ruhigen Grün.
#let wasser = rgb("#3a6ea5")
#let ufer = rgb("#e9dab3")
#let ablagerung-farbe = rgb("#7c9464")

#show: presentation.with(
  theme: t,
  title: [Wie ein Fluss sein Bett gräbt],
  subtitle: [Erosion, Transport, Ablagerung — und wie ein Mäander wandert],
  author: [Institut für Geomorphologie],
  date: datetime(year: 2026, month: 3, day: 12),
  transition: "slide",
)

= Was Wasser mit Gestein macht

== Ein Fluss, drei Vorgänge

#speaker-note[
  Die Faustregel in der ersten Einblendung ist absichtlich zu einfach — sie
  soll kurz stehen und dann von der richtigen Erklärung abgelöst werden.
]

#side-by-side(
  split: (1fr, 1fr),
  card(title: [Der Kreislauf])[
    Ein Fluss nimmt Material auf, trägt es fort und legt es wieder ab. Alle
    drei Vorgänge laufen zu jeder Zeit — nur an verschiedenen Stellen.

    Im Oberlauf überwiegt das Aufnehmen, im Unterlauf das Ablegen.
  ],
  callout(title: [Merke])[
    Entscheidend ist die *Fließgeschwindigkeit*: Sie bestimmt, ob ein Korn
    liegen bleibt oder mitgeht.

    Sie hängt am Gefälle, an der Wassermenge und an der Rauheit des Bettes.
  ],
)

#anim([Vorläufige Faustregel: mehr Gefälle heißt mehr Kraft.],
      at: "2-2", enter: "fade-up", exit: "fade-left")

#anim([Entscheidend ist allein die Geschwindigkeit am Grund.],
      at: "3-", enter: "fade-up")

== Die Korngrößen

#transition("push")

#tiles(
  card(number: 1, title: [Ton])[unter 0,002 mm — schwebt, sinkt kaum],
  card(number: 2, title: [Sand])[0,063 bis 2 mm — springt über den Grund],
  card(number: 3, title: [Kies])[über 2 mm — rollt, und nur bei Hochwasser],
)

#v(1em)

#anim([Deshalb liegt im Oberlauf Geröll und im Mündungsdelta Ton.],
      at: "4-", enter: "fade-up")

== Was ein Fluss unterwegs sortiert

#transition("uncover")

// Stücke-Form: drei eigenständige Stücke, keine Liste. Jedes erscheint einen
// Schritt nach dem vorigen, ganz ohne Nummerierung von Hand.
#stagger(
  [#text(fill: t.strong, weight: "bold")[Oberlauf] — nur was zu schwer ist,
   um mitzugehen, bleibt liegen: Blöcke und grobes Geröll.],
  [#text(fill: t.strong, weight: "bold")[Mittelstrecke] — Sand wandert
   sprungweise über den Grund: heben, fallen, wieder heben.],
  [#text(fill: t.strong, weight: "bold")[Mündung] — erst im ruhigen Wasser
   des Deltas sinkt der feine Ton endgültig zu Boden.],
)

#v(1.2em)

#anim(callout(title: [Deshalb])[
  Ein Flussbett ist eine Sortiermaschine. Wer die Korngröße an einer Stelle
  kennt, weiß ungefähr, wie schnell das Wasser dort war.
], at: "4-", enter: "rise")

= Wie ein Mäander wandert

== Der Mäander wandert flussabwärts

#transition("wipe")

#speaker-note[
  Beim Abspielen darauf hinweisen, dass die Kurve nicht neu gezeichnet wird —
  dieselbe Welle verschiebt sich nur nach rechts. Genau das tut ein Mäander
  auch, nur über Jahre statt über Sekunden.
]

// `render` bekommt einen Bruchteil `frac` von 0 bis 1 und zeichnet damit ein
// Einzelbild: eine sinusförmige Flusslinie, deren Phase mit `frac`
// verschoben wird. Nach genau einer Wellenlänge Verschiebung sieht Bild 1
// wieder aus wie Bild 0 — die Schleife ist damit nahtlos.
#let render-maeander(frac) = {
  let w = 300pt
  let h = 190pt
  let amp = 38pt
  let periode = w * 0.55
  let versatz = frac * periode
  let n = 90
  // Etwas breiter als sichtbar zeichnen, damit am Rand keine Lücke entsteht —
  // `flipbook` schneidet ohnehin auf `width`/`height` zu.
  let rand = periode
  let xs = range(n + 1).map(i => -rand + i / n * (w + 2 * rand))
  let punkte = xs.map(x => (
    x, h / 2 + amp * calc.sin((x - versatz) / periode * 2 * calc.pi),
  ))
  let sichtbar = punkte.filter(p => p.at(0) >= 0pt and p.at(0) <= w)
  let ys = sichtbar.map(p => p.at(1))
  // Eigenes Zuschneiden: Im PDF (ein Einzelbild, `still`) legt `flipbook`
  // selbst keinen Rahmen darüber — ohne `clip: true` liefe die Welle über
  // ihr Sandrechteck hinaus.
  box(width: w, height: h, clip: true, {
    place(rect(width: w, height: h, fill: ufer, stroke: none))
    place(curve(
      stroke: 6pt + wasser,
      curve.move(punkte.first()),
      ..punkte.slice(1).map(p => curve.line(p)),
    ))
    // Prallhang (Außenkurve, Erosion) und Gleithang (Innenkurve, Ablagerung).
    //
    // Der Scheitel wird *gerechnet*, nicht gesucht. Über die sichtbare Breite
    // passen knapp zwei Wellenberge; wer den höchsten Abtastpunkt nimmt, hängt
    // am globalen Maximum — und welcher Berg das gerade ist, wechselt beim
    // Wandern. Gemessen sprang der Punkt zwischen 65pt und 346pt hin und her,
    // statt zu wandern.
    //
    // Aus der Phase folgt er dagegen unmittelbar: ein Maximum liegt bei
    // `versatz + periode * (1/4 + k)`, ein Minimum ein halbes Periodenmaß
    // weiter. Gesetzt wird auf *jeden* sichtbaren Scheitel — so wandert einer
    // rechts hinaus, während links der nächste hereinkommt.
    // `aussen` sagt, wo bei diesem Scheitel die Außenseite der Schleife liegt:
    // +1 unten, -1 oben. Beide Punkte sitzen am *selben* Scheitel — genau das
    // sagt die Folie ja: an jeder Schleife wird gleichzeitig abgetragen und
    // abgelagert, nur an verschiedenen Ufern.
    let scheitel(anteil, aussen) = {
      for k in range(-1, 3) {
        let x = versatz + periode * (anteil + k)
        if x >= 0pt and x <= w {
          let y = h / 2 + amp * calc.sin((x - versatz) / periode * 2 * calc.pi)
          place(dx: x - 5pt, dy: y + aussen * 9pt - 5pt,
                circle(radius: 5pt, fill: t.accent))
          place(dx: x - 5pt, dy: y - aussen * 9pt - 5pt,
                circle(radius: 5pt, fill: ablagerung-farbe))
        }
      }
    }
    scheitel(0.25, 1)
    scheitel(0.75, -1)
  })
}

// `auto` für die Zeichnung, `1fr` für den Text: das Daumenkino ist 300pt breit
// und bekommt genau so viel, der Rest gehört den Stichpunkten. Mit zwei
// `fr`-Anteilen bliebe links Leerlauf und rechts wäre es unnötig eng.
// Senkrecht in die Mitte des Rumpfs: die Zeichnung ist niedriger als die
// Folie, und oben angeschlagen sähe sie aus, als fehlte darunter etwas.
#v(1fr)

#side-by-side(
  split: (auto, 1fr),
  flipbook(
    render-maeander,
    frames: 30, fps: 15, width: 300pt, height: 190pt, loop: true,
  ),
  [
    #text(fill: t.accent, weight: "bold")[● Prallhang] — die Außenseite
    trägt ab.

    #v(0.4em)

    #text(fill: ablagerung-farbe, weight: "bold")[● Gleithang] — die
    Innenseite lagert ab.

    #v(0.6em)

    Beides passiert an jeder Schleife gleichzeitig und ständig. Darum bleibt
    die Schleife nicht stehen: Sie wandert als Ganzes flussabwärts.
  ],
)

#v(1fr)

== Kritische Geschwindigkeiten

#transition("cube")

#speaker-note[
  Hier nicht vorgreifen: Die zweite Ungleichung kommt erst auf der nächsten
  Folie, als derselbe Flug rückwärts gelesen.
]

// Quelle des Morphs. Die drei `v` sehen identisch aus — ohne Namen würde der
// Formabgleich sie nach *Position* paaren, und auf der nächsten Folie stehen
// sie in umgekehrter Reihenfolge. `pin` gibt jedem `v` eine feste Identität,
// die der Flug verfolgt statt der bloßen Form.
#statement(color: t.accent)[
  #morph(<schwellen>, $ #pin(<erosion>, $v_E$) > #pin(<transport>, $v_T$)
                        > #pin(<ablagerung>, $v_A$) $)
]

#anim([Ein ruhendes Korn braucht mehr Schwung als ein bereits bewegtes: Die
       Schwelle zum *Losreißen* $v_E$ liegt höher als die zum
       *Weitertragen* $v_T$, und die zum *Liegenbleiben* $v_A$ liegt am
       tiefsten.], at: "2-", enter: "fade-up")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift, der
// Rumpf bekommt dafür die ganze Höhe.
== #h(0pt)

#transition("zoom")

// Dieselben drei Namen, jetzt in umgekehrter Reihenfolge: Ein Hochwasser
// fließt langsamer aus, als es kam. Es unterschreitet zuerst $v_E$ — ohne
// neue Körner zu lösen, aber die alten trägt es weiter, bis es zuletzt
// unter $v_A$ fällt und auch sie liegen lässt. Dank `pin` fliegt jedes `v`
// zu seinem eigenen Platz, nicht zu dem, das zufällig dort steht, wo es
// hinkommt.
#place(center + horizon,
       morph(<schwellen>, text(size: 2.2em, fill: t.accent)[
         $ #pin(<ablagerung>, $v_A$) < #pin(<transport>, $v_T$)
           < #pin(<erosion>, $v_E$) $
       ]))
