# Rückmeldung zu typstage 0.1.0

Zwei Punkte aus dem Bau eines Mathematik-Decks (Klasse 7, drei Diagramme
nebeneinander, die nacheinander besprochen werden): ein Effizienzproblem in
`build` und eine Abweichung zwischen HTML und PDF bei `anim`.

---

## 1. `build` rendert Stufen, die nichts Neues zeigen

### Beobachtung

Auf einer Folie stehen drei Diagramme nebeneinander. Jedes bekommt eine
Kamerafahrt, dann eine Ergänzung in der Zeichnung, dann ein Urteil daneben.
also drei Schritte je Diagramm, insgesamt zehn.

Das dritte Diagramm soll seine Ergänzung auf **Schritt 9** bekommen und vorher
unverändert dastehen. Um das zu erreichen, muss es mit `steps: 9` gebaut
werden. Die Stufen 1 bis 8 sind dabei **pixelgleich**, sie werden trotzdem
alle gerendert. Bei drei Diagrammen sind das 3 + 6 + 9 = 18 Renderings für
sechs unterschiedliche Bilder.

### Ursache

`src/elements.typ:968`

```typ
let stufen = range(1, steps + 1).map(k => draw(frage(k)))
```

`src/elements.typ:1006-1012`

```typ
let letzte = steps - 1
…
let bereich = if i == letzte { str(erster + i) + "-" } else { str(erster + i) }
```

Stufe *i* liegt fest auf Schritt `erster + i`. Dahinter steht die Annahme, dass
eine Zeichnung **Klick für Klick** wächst: Jeder Schritt bringt eine neue Stufe.

Diese Annahme trifft nicht zu, sobald zwischen zwei Stufen einer Zeichnung
etwas **anderes** auf der Folie passiert: eine Kamerafahrt, ein Urteil, ein
zweites Diagramm. Dann muss man die Lücken mit identischen Stufen auffüllen,
und die Zahl der Renderings wächst mit dem Abstand statt mit dem Inhalt.

### Vorschlag

Ein zusätzlicher Parameter `at`, der je Stufe einen Bereich annimmt, analog zu
dem, was `anim` ohnehin akzeptiert:

```typ
#let build(draw, steps: 2, start: auto, at: auto, enter: "fade", …)
```

In der Schleife:

```typ
let bereich = if at != auto { selector(at.at(i)) }
              else if i == letzte { str(erster + i) + "-" }
              else { str(erster + i) }
```

Der obige Fall wäre damit zwei Stufen lang statt neun:

```typ
build(from => diagramm(from), steps: 2, at: ("1-8", "9-"))
```

Zwei Kleinigkeiten gehören dazu:

- ein `assert`, dass `at` genau `steps` Einträge hat, sonst bekommt eine Stufe
  keinen Bereich und verschwindet stillschweigend;
- der Zeigerfortschritt in `src/elements.typ:996` rechnet mit
  `erster + steps - 1`. Bei explizitem `at` müsste dort das Maximum über
  `max-step(selector(…))` der angegebenen Bereiche stehen, sonst zählt das
  Handout weniger Schritte als der Vortrag.

Bestehende Decks bleiben unberührt: Wer `at` nicht angibt, bekommt weiterhin
das fortlaufende Verhalten.

---

## 2. `anim` zentriert im HTML, aber nicht im PDF

### Beobachtung

Unter jedem der drei Diagramme steht ein Urteil aus Symbol und Wort:

```typ
#let urteil(ok, wort, ab) = anim(at: ab, align(center, grid(
  columns: (auto, auto),
  column-gutter: 10pt,
  align: horizon,
  text(size: 1.3em, fill: …, fa-icon(…)),
  text(weight: "bold", fill: …, wort),
)))
```

Das Ganze steht in einem `stack` innerhalb einer `1fr`-Spalte eines Grids.

- **HTML:** Symbol und Wort stehen mittig unter dem Diagramm.
- **PDF:** Beide stehen linksbündig am Spaltenrand.

Dieselbe Quelle, zwei Ergebnisse. Da aus derselben Datei Vortrag und Handout
entstehen, fällt das unmittelbar auf.

### Reproduktion

Wichtig: Auf der **obersten Ebene einer Folie tritt der Fehler nicht auf**,
dort bekommt `align` in beiden Ausgaben die volle Breite. Es braucht einen
begrenzten Bereich, also eine Grid-Spalte:

```typ
#import "@schule/typstage:0.1.0": *
#show: presentation.with(transition: "none")

== Wie im Deck

#let saeule(nr, beschriftung) = stack(
  spacing: 6pt,
  text(weight: "bold")[Titel #nr],
  rect(width: 5cm, height: 2.4cm),
  anim(at: 2, align(center, grid(
    columns: (auto, auto), column-gutter: 10pt, align: horizon,
    circle(radius: 6pt, fill: green), text(weight: "bold", beschriftung),
  ))),
  anim(at: 3, block(width: 100%, align(center, grid(
    columns: (auto, auto), column-gutter: 10pt, align: horizon,
    circle(radius: 6pt, fill: blue), text(weight: "bold")[mit block],
  )))),
)

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 26pt,
  pin(<a>, saeule(1)[mittig?]),
  pin(<b>, saeule(2)[mittig?]),
  pin(<c>, saeule(3)[mittig?]),
)
```

Im PDF steht die grüne Zeile linksbündig, die blaue mittig. Im HTML stehen
beide mittig.

### Ursache

Der HTML-Zweig verbreitert Inhalt, der zentriert werden will, auf die
verfügbare Breite (`src/internal.typ:1354`)

```typ
let fuellt = will-fuellen(body)
let w = if inline or width != auto { m.width }
        else if fuellt { room }
        else { m.width }
```

`will-fuellen` (`src/internal.typ:769`) erkennt genau diesen Fall: ein `align`
an der Spitze des Bodys heißt „will die volle Breite".

Der Papierzweig steigt vorher aus (`src/internal.typ:1284`)

```typ
if not html-output.get() { return zaehlen + body }
```

und gibt den Body unverändert zurück. Im `stack` innerhalb einer Grid-Spalte
misst sich `align(center, …)` dann so schmal wie sein Inhalt, und es bleibt
nichts übrig, worin zentriert werden könnte. Der Kommentar bei `will-fuellen`
beschreibt genau diese Falle. Im HTML-Zweig ist sie umgangen, im Papierzweig
nicht.

### Vorschlag

Der Papierzweig müsste dieselbe Entscheidung treffen, ohne die Messung des
HTML-Zweigs zu wiederholen:

```typ
if not html-output.get() {
  return zaehlen + (if will-fuellen(body) {
    block(width: 100%, body)
  } else { body })
}
```

Für alles andere ändert sich nichts, weil `will-fuellen` nur bei `align` und
bei Block-Formeln zuschlägt.

Ein Rest bleibt: Im HTML füllt der Sprite `room`, also die **Spaltenbreite**,
auf Papier wären es 100 % des umgebenden `stack`, also dessen breitestes Kind.
Wo das Diagramm die Spalte fast ausfüllt, ist der Unterschied unsichtbar; ganz
deckungsgleich wird es damit aber nicht.

### Umgehung im Deck

Bis dahin lässt sich die Breite selbst nennen, im obigen Beispiel als blaue
Zeile geprüft:

```typ
anim(block(width: 100%, align(center, …)))
```
