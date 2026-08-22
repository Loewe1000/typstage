// Der Democlip für examples/rundgang.typ — 36 Bilder, 12 fps, nahtlos.
//
//   typst compile demo.typ "bild/{n}.png" --ppi 288
//   ffmpeg -framerate 12 -i bild/%d.png … demo.mp4
//
// Seitengröße in Punkten mal ppi/72 ergibt die Pixel: 320×180 bei 288 ppi
// sind 1280×720. Der Lichtstreifen wandert genau einmal durch, deshalb passt
// das letzte Bild wieder ans erste.
#set page(width: 320pt, height: 180pt, margin: 0pt, fill: rgb("#22303f"))
#set text(font: ("Inter", "Helvetica Neue"), fill: rgb("#eb5e28"))

#let bilder = 36

#for i in range(bilder) {
  let t = i / bilder
  let x = (t * 1.6 - 0.3) * 320pt
  page[
    #place(dx: x, dy: 0pt,
      rect(width: 70pt, height: 180pt, stroke: none,
           fill: gradient.linear(
             rgb("#22303f00"), rgb("#ffffff14"), rgb("#22303f00"),
             angle: 0deg)))
    #place(center + horizon,
      text(size: 34pt, weight: "bold", tracking: -0.5pt)[typstage])
    #place(bottom + center, dy: -18pt,
      text(size: 9pt, fill: rgb("#8fa0b4"), tracking: 1.2pt)[
        EINE QUELLE · DREI AUSGABEN])
  ]
}
