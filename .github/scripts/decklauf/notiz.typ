// Gegenprobe zu `plain-text`: eine Sprechernotiz aus zwei Absätzen.
//
// `pruefe-decks.js` übersetzt dieses Deck und liest `data-note` wörtlich aus.
// Dort muss zwischen den beiden Sätzen eine Leerzeile stehen.
//
// Warum es das braucht: die Notiz reist als HTML-Attribut und ist deshalb nur
// eine Zeichenkette. `plain-text` kannte `space`, aber keinen `parbreak` --
// gemessen kam die Notiz unten als "Erster Absatz.Zweiter Absatz." an, ohne
// auch nur ein Leerzeichen, und traf jede zweiabsätzige Notiz, die im Paket
// liegt, `geogebra-sprecher` eingeschlossen.
//
// Verglichen wird gegen den genauen Wortlaut und nicht gegen eine gezählte
// Zeilenzahl. Wie viele Zeilen daraus werden, hängt am Umbruch und damit an
// der Schrift des Rechners; was zwischen den Sätzen steht, hängt an nichts.

#import "@schule/typstage:0.1.0": *

#show: presentation.with(theme: themes.lesson)

== Zwei Absätze
#speaker-note[Erster Absatz.

Zweiter Absatz.]
Eine Folie muss etwas zu zeigen haben, sonst steht hier nichts.
