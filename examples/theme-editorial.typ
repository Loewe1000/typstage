// themes.editorial — mit Charakter.
//
// Zeigt: eine buchnahe Bühne (4:3, Ränder wie ein Satzspiegel), side-by-side,
// statement, card, callout, #pause, morph auf eine titellose Folie,
// Sprechernotizen.
//
//   typst compile theme-editorial.typ theme-editorial.html --format html --features html
//   typst compile theme-editorial.typ theme-editorial.pdf
//
// Als Merkblatt statt als Vortrag: `handout: 3` vorübergehend bei
// `presentation(..)` setzen (drei Folien pro Seite, ohne Übergänge) und
//   typst compile theme-editorial.typ handout.pdf
// bauen. Danach die Zeile wieder entfernen — das Deck selbst läuft ohne
// `handout:`.

#import "@schule/typstage:0.1.0": *

// Ein Theme ist ein Wörterbuch — man kann seine Farben auch selbst benutzen.
#let t = themes.editorial

#show: presentation.with(
  theme: t,
  title: [Der Rand des Satzspiegels],
  subtitle: [Woher die Maße kommen — und warum das Format selbst eine
    Behauptung ist],
  author: [Vortrag zur Buchgestaltung],
  date: datetime(year: 2026, month: 11, day: 6),
  transition: "fade",
  // 4:3 statt 16:9 — ein Vortrag über Seitenproportionen bleibt sonst
  // ausgerechnet auf einer Kinoleinwand hängen. Die Ränder sind absichtlich
  // ungleich: links (der Bund) schmal, rechts (der Daumen) breit, oben
  // schmaler als unten — genau die drei Maße, um die es gleich geht.
  // Alles im Theme skaliert mit; nur das Verhältnis ändert das Bild.
  width: 800pt,
  height: 600pt,
  margin: (left: 34pt, right: 50pt, top: 30pt, bottom: 44pt),
)

= Woher die Maße kommen

== Was der Körper vorgibt

#speaker-note[
  Hand heben, Buch imaginär halten. Der Daumen liegt am Außenrand — das ist
  der ganze Beweis, den man für diese Folie braucht.
]

#side-by-side(
  split: (1fr, 1fr),
  gutter: 20pt,
  align: top,
  card(title: [Der Bund], radius: 3pt, inset: (x: 14pt, y: 12pt))[
    Der innere Rand verschwindet in der Klebung oder Fadenheftung. Er darf
    schmal sein, weil dort nichts liegt außer dem Papier selbst.
  ],
  card(title: [Der Daumen], radius: 3pt, inset: (x: 14pt, y: 12pt))[
    Der äußere Rand trägt die Hand. Er muss breiter sein als der Bund, sonst
    deckt der Daumen beim Blättern die letzten Wörter jeder Zeile ab.
  ],
)

#pause

Kopf und Fuß folgen derselben Logik: der Kopfsteg bleibt schmal, der
Fußsteg nimmt Daumen, Seitenzahl und etwas Luft zum Kippen der Seite auf.

== Die Formel dahinter

#transition("cover")

Wer diese vier Maße nicht schätzt, sondern rechnet, landet immer wieder bei
derselben Reihe: innen, oben, außen, unten im Verhältnis 2 zu 3 zu 4 zu 6.

#pause

Man kennt sie unter zwei Namen — als mittelalterlicher Kanon, den Villard de
Honnecourt zeichnete, und als Van-de-Graaf-Konstruktion, benannt nach dem
Typografen, der sie im zwanzigsten Jahrhundert wiederentdeckte.

#callout(title: [Warum genau diese Zahlen], width: 62%)[
  Die Reihe teilt Blatt und Satzspiegel in Neuntel. Der Bund bekommt zwei
  Neuntel Breite, der Außenrand vier — exakt das Doppelte. Kein Zufall,
  sondern eine Konstruktion mit Lineal und Diagonale.
]

== Das Verhältnis, das bleibt

// Quelle des Morphs — steht ab dem ersten Schritt der Folie, weil `statement`
// von Anfang an da ist. Quelle und Ziel brauchen dieselbe Farbe, sonst
// wechselt die Formel mitten im Flug die Farbe.
#statement(size: 2.1em, color: t.accent, above: 1em, below: 0.6em)[
  #morph(<kanon>, [2 : 3 : 4 : 6])
]

#anim([Vier Zahlen, eine Bauanleitung: aus der Diagonale des Blattes und der
       Diagonale der Doppelseite ergibt sich der ganze Satzspiegel — ohne ein
       einziges Maßband.], at: 2, enter: "fade-up")

// Eine Folie ohne Titelbalken: `== #h(0pt)` gibt ihr keine Überschrift.
== #h(0pt)

#transition("flip")

// Ziel des Morphs, auf der unmittelbar folgenden Folie — kein Abschnitt
// dazwischen, sonst bricht der Flug lautlos ab.
// `match: "glyph"` erzwingt die zeichenweise Paarung. Von sich aus nimmt das
// Paket sie nur, solange keine Seite mehr als 48 Zeichen hat — hier sind es 50,
// und ohne die Angabe würde der ganze Block überblenden statt die Ziffern an
// ihre neuen Plätze fliegen zu lassen. Genau darum geht es auf dieser Folie.
#place(center + horizon,
  morph(<kanon>, match: "glyph", text(size: 1.7em, fill: t.accent)[
    Bund 2 · Kopf 3 · Außen 4 · Fuß 6 \
    dieselbe Reihe, jetzt mit Namen
  ]))

= Was bleibt

== Warum das Verhältnis überlebt

#speaker-note[
  Hier keine Eile. Der Punkt ist: das Auge hat sich nicht geändert, nur das
  Papier. Das darf einen Moment nachhallen.
]

Der Falzbogen, der die Neuntel-Teilung erzwang, ist verschwunden. Digital
gedruckt wird randlos, geheftet wird geklebt, geschraubt oder gar nicht.

#pause

Trotzdem zeichnen Setzer die Reihe weiter — nicht aus Nostalgie, sondern weil
die kurze Zeile und der freie Daumen keine Erfindung des Mittelalters waren,
sondern eine Antwort auf ein Auge und eine Hand, die seither gleich
geblieben sind.

#v(0.6em)

#card(title: [Und diese Folie], radius: 3pt, inset: (x: 16pt, y: 13pt))[
  trägt dieselbe Asymmetrie: ein Bühnenformat mit schmalem Bund links,
  breitem Rand rechts. Ein Vortrag über Ränder darf seinen eigenen haben.
]
