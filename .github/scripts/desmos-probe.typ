// Das Deck, an dem die Desmos-Brücke geprüft wird -- und das man von Hand
// öffnen kann, um ihr zuzusehen.
//
//   typst compile --features html --format html \
//     --input desmos-key=DEIN_SCHLÜSSEL \
//     .github/scripts/desmos-probe.typ probe.html
//
// Ohne `--input` nimmt es Desmos' Demo-Schlüssel. Der ist zum Ausprobieren
// gedacht und warnt bei jedem Aufruf in der Konsole des Browsers; einen
// eigenen gibt es über https://www.desmos.com/my-api.
//
// Es steht bewusst nicht in `examples/`. Was dort liegt, wird gebaut und auf
// die Projektseite gestellt, und ein veröffentlichtes Deck trüge den
// Schlüssel für jeden sichtbar mit sich.
#import "@preview/typstage:0.1.0": *

#let key = sys.inputs.at("desmos-key", default: demo-key)

#show: presentation.with(theme: themes.default, title: [Desmos an der Brücke])

== Eine Parabel, die sich öffnet

#desmos(
  <graph>,
  api-key: key,
  expressions: (a: "a=0.2", kurve: "y=a x^2"),
  bounds: (-5, 5, -2, 12),
  height: 220pt,
)

// Die Bewegung liegt auf genau diesem Schritt; ab dem nächsten steht der
// Endwert einfach da. Stünde hier "ab Schritt 2", liefe sie bei jedem
// Weiterblättern neu an.
#dsm-tween("a", to: 3.0, at: 2, duration: 900)
#anim(at: 2)[Der Faktor wächst von 0,2 auf 3.]

#dsm-set(("gerade": "y=2x"), at: 3)
#anim(at: 3)[Eine Gerade kommt dazu.]

// Verborgen, nicht entfernt: der Ausdruck bleibt im Rechner und rechnet mit.
#dsm-hide("gerade", at: 4)
#anim(at: 4)[Und ist wieder weg -- verborgen, nicht gelöscht.]
