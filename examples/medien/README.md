# Wie `demo.mp4` entsteht

`demo-clip.typ` zeichnet die 36 Bilder des Clips, `ffmpeg` setzt sie zusammen.
Beides von Hand, wenn sich der Clip ändern soll — der Seitenbau rührt ihn nicht
an, sondern kopiert nur `demo.mp4` und `demo-poster.png` neben die Seiten.

```sh
typst compile demo-clip.typ "bild/{n}.png" --ppi 288
ffmpeg -framerate 12 -pattern_type glob -i 'bild/*.png' \
  -c:v libx264 -pix_fmt yuv420p -crf 26 -preset slow -movflags +faststart \
  -an ../demo.mp4
cp bild/01.png ../demo-poster.png
```

Die Seite ist 320×180 Punkt groß; bei 288 ppi sind das 1280×720 Pixel. Der
Lichtstreifen wandert genau einmal durch, deshalb schließt das letzte Bild
wieder ans erste an.

Nicht in `examples/` selbst ablegen: der Seitenbau übersetzt jede `.typ` dort
als eigene Präsentation.
