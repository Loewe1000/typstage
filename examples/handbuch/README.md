# Beispiele, die im Handbuch stehen

Die Dateien hier sind die vollständigen Präsentationen, die die beiden
Handbücher als „vollständig und lässt sich abtippen" zeigen. Das Handbuch
schreibt sie nicht ab, sondern liest sie:

```typ
#show-code(raw(read("../examples/handbuch/erste-praesentation.typ").trim(),
               block: true, lang: "typ"))
```

Damit kann der Abdruck nicht von der Datei abweichen, und
`.github/scripts/pruefe-beispiele.py` übersetzt genau die Zeichen, die im
Handbuch stehen.

| Datei | Handbuch |
| --- | --- |
| `erste-praesentation.typ` | `docs/content.typ`, „Eine Datei genügt" |
| `first-deck.typ` | `docs/content-en.typ`, „One file is enough" |

Nicht in `examples/` selbst ablegen: der Seitenbau übersetzt jede `.typ` dort
als eigene Präsentation, und die sechs Beispieldecks der Website sollen sechs
bleiben.
