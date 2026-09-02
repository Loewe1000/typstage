// Gegenprobe zum Überlaufmelder: dieses Deck *muss* abbrechen.
//
// `pruefe-decks.js` übersetzt es und meldet einen Fund, wenn es durchgeht.
// Der Grund: ein Melder, der nichts mehr meldet, fällt sonst niemandem auf.
// Im Prüfdeck nebenan steht `overflow: "error"` und dort läuft nichts über,
// also sagt es nur, dass der Prüfgang durchläuft, nicht dass er trifft.
//
// Die Folie ist mit Absicht zu hoch für den Platz, den das Thema ihr gibt,
// und der Text steht ohne `fit` darum herum, damit nichts ihn kleinrechnet.

#import "@preview/typstage:0.1.1": *

#show: presentation.with(theme: themes.lesson, overflow: "error")

== Zu hoch
#for i in range(0, 40) [
  Eine Zeile, die Platz braucht, Nummer #i.
]
