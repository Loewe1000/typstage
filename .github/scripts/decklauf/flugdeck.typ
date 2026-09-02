// Flugdeck: zwei Folien, ein `morph` und zwei Nachbarn.
//
//     typst compile --features html --format html flugdeck.typ flugdeck.html
//
// Wozu ein eigenes Deck: `flug-hoehe.js` prüft, was während eines Fluges
// übereinander liegt, und dafür braucht es eine Stelle, an der genau das
// entschieden werden muss — ein Element, das im Ruhezustand über dem Ziel des
// Fluges steht, und eines, das darunter steht. Das Prüfdeck nebenan hat diese
// Stellung nicht, und sie ihm anzubauen bewegte seinen ganzen Sollstand.
//
// Wer hier etwas ändert, ändert eine Messung. Die drei Rechtecke auf der
// zweiten Folie sind keine Gestaltung: `unten` steht in Quellreihenfolge vor
// dem `morph` und gehört unter den Geist, `oben` steht danach und gehört
// darüber, und beide überlappen die Bahn des Fluges. Ohne diese Überlappung
// prüfte der Lauf nichts.

#import "@preview/typstage:0.1.1": *

#presentation(
  title: [Flugdeck],
  author: [typstage #runtime-version],
  theme: themes.plain,
  margin: 0pt,
  // Ein Kreuzblenden, damit die abtretende Folie den Blick auf die neue nicht
  // durch eine Bewegung ersetzt: geprüft wird die Höhe, nicht der Übergang.
  transition: "fade",
  transition-duration: 440,
  duration: 520,

  // ── 1 Die Kachel ─────────────────────────────────────────────────────────
  slide(none)[
    #block(width: 100%, height: 100%, {
      place(top + left, dx: 60pt, dy: 50pt,
            morph(<tafel>, block(width: 150pt, height: 100pt, fill: luma(60)),
                  match: "block"))
    })
  ],

  // ── 2 Die Tafel, mit drei Nachbarn ───────────────────────────────────────
  // Die Tafel nimmt zwei Drittel der Breite. Das ist der Grund für das
  // Verhältnis: die Bahn des Fluges ist damit *nicht* die ganze Folie, und
  // rechts daneben ist Platz für einen Nachbarn, den der Flug nie berührt.
  slide(none)[
    #block(width: 100%, height: 100%, {
      // Vor dem `morph`: liegt auch im Ruhezustand darunter. Ein Flug, der
      // dieses hier mit hochzöge, zöge zu viel.
      place(top + left, dx: 40pt, dy: 150pt,
            anim(at: "1-", block(width: 190pt, height: 40pt, fill: blue,
                                 inset: 10pt)[UNTEN]))
      place(top + left, morph(<tafel>, block(width: 66%, height: 100%,
                                             fill: luma(60)), match: "block"))
      // Nach dem `morph` und in seiner Bahn: liegt darüber. Genau dieses hier
      // muss den Flug überdauern, ohne dahinter zu verschwinden.
      place(bottom + left, dx: 40pt, dy: -40pt,
            anim(at: "1-", block(width: 190pt, height: 40pt, fill: red,
                                 inset: 10pt)[OBEN]))
      // Nach dem `morph`, aber außerhalb seiner Bahn. Es liegt im Ruhezustand
      // ebenfalls darüber -- nur hat der Flug es nie verdeckt, und darum hat
      // er es auch nicht anzufassen. Wer es trotzdem hochzieht, lässt es einen
      // Lidschlag früher erscheinen als die Folie, zu der es gehört.
      place(top + right, dx: -30pt, dy: 40pt,
            anim(at: "1-", block(width: 150pt, height: 40pt, fill: green,
                                 inset: 10pt)[FERN]))
    })
  ],
)
