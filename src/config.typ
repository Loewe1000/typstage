// Sizes, colours and the runtime files.
//
// Everything here is data: nothing in this file produces output.

/// Version of the runtime. It goes into the asset file names so a CDN can hold
/// several releases side by side and no browser serves a stale one from cache.
#let runtime-version = "0.1.0"

/// Default slide geometry. 16:9 on an A4-width canvas, so a slide and a
/// handout page carry text at the same physical size. `presentation` takes
/// `width`, `height` and `margin` to override them.
#let slide-width = 841.89pt
#let slide-height = slide-width * 9 / 16
#let slide-margin = 32pt

/// Work out the canvas from what the deck asked for.
///
/// `scale` is the heart of it: everything the theme draws — header height,
/// type sizes, rules — is given in points of the default canvas and multiplied
/// by this. A deck at half the width then looks the same, only smaller,
/// instead of carrying a header built for a canvas twice its size.
///
/// Only the *ratio* really changes the layout, and that is the point: 4:3 is
/// `height: width * 3 / 4`.
#let canvas(width: auto, height: auto, margin: auto) = {
  let w = if width == auto { slide-width } else { width }
  let k = w / slide-width
  (
    width: w,
    height: if height == auto { w * 9 / 16 } else { height },
    margin: if margin == auto { slide-margin * k } else { margin },
    scale: k,
  )
}

/// Die vier Ränder des Canvas, einzeln.
///
/// `margin` darf eine Länge oder ein Wörterbuch sein; ein Theme will die vier
/// Werte einzeln haben und soll das nicht jedes Mal auseinandernehmen müssen.
#let margins(geo) = {
  let m = geo.margin
  if type(m) != dictionary { return (left: m, right: m, top: m, bottom: m) }
  let seite(name, achse) = m.at(name, default: m.at(achse, default: 0pt))
  (
    left: seite("left", "x"), right: seite("right", "x"),
    top: seite("top", "y"), bottom: seite("bottom", "y"),
  )
}

/// The default palette. Override it by wrapping the presentation in your own
/// document template — see `style` on `presentation`.
#let dark = rgb("#23303f")
#let accent = rgb("#eb5e28")
#let paper = rgb("#fafafa")
#let muted = luma(45%)

/// The two runtime files, read at compile time so there is a single source of
/// truth: whether they are inlined, linked next to the HTML or fetched from a
/// CDN, it is always this text.
#let runtime-css = read("../assets/typstage-" + runtime-version + ".css")
#let runtime-js = read("../assets/typstage-" + runtime-version + ".js")

/// Die Wörter, die die Laufzeit selbst anzeigt: der Hinweis bei `s` ohne
/// Notiz, die Tastenhilfe bei `?`, und die Beschriftungen der
/// Sprecheransicht.
///
/// Sie folgen `text.lang`, damit ein deutsches Deck deutsche und ein
/// englisches englische Wörter zeigt. Wer eine Sprache vermisst, reicht sie
/// über `words:` an `presentation` herein; Englisch ist der Rückfall.
///
/// `sp` steht für die Sprecheransicht. Die Schlüssel darin gehen unverändert
/// ins JSON und werden im Laufzeitcode so gelesen, deshalb tragen sie dort
/// keine Bindestriche.
#let runtime-words(lang) = {
  let listen = (
    de: (no-note: "keine Notiz",
         help: "← → blättern · o Übersicht · f Vollbild · s Notiz · n Sprecheransicht · p Druck",
         help-speaker-short: "← → blättern · b schwarz · e einfrieren · x Folie löschen · ? alle Tasten",
         help-speaker: "← → blättern · ↑ ↓ Notiz rollen · Pos1 zum Anfang · Ende zum Schluss · b schwarz · e einfrieren · t Zieldauer · r Uhr zurück · c Farbe · z Strich zurück · x Folie löschen · + − Notizgröße · o Übersicht · s Notiz im Balken · f Vollbild · n Vortrag nach vorn · p Druck",
         sp: (clock: "Uhrzeit", elapsed: "verstrichen", target: "Ziel (min)",
              left: "Rest", pace: "Plan", progress: "Fortschritt",
              note: "Notiz", next: "als Nächstes",
              nextStep: "nächster Schritt", nextSlide: "nächste Folie",
              end: "Ende des Vortrags", slide: "Folie", step: "Schritt",
              ahead: "vor Plan", behind: "hinter Plan", onplan: "im Plan",
              black: "schwarz", frozen: "eingefroren", pen: "Stift",
              lost: "kein Vortragsfenster")),
    en: (no-note: "no note",
         help: "← → page · o overview · f full screen · s note · n speaker view · p print",
         help-speaker-short: "← → page · b black · e freeze · x clear slide · ? all keys",
         help-speaker: "← → page · ↑ ↓ scroll note · Home to start · End to finish · b black · e freeze · t target · r reset clock · c colour · z undo stroke · x clear slide · + − note size · o overview · s note in bar · f full screen · n raise talk · p print",
         sp: (clock: "clock", elapsed: "elapsed", target: "target (min)",
              left: "remaining", pace: "pace", progress: "progress",
              note: "note", next: "up next",
              nextStep: "next step", nextSlide: "next slide",
              end: "end of talk", slide: "slide", step: "step",
              ahead: "ahead", behind: "behind", onplan: "on plan",
              black: "black", frozen: "frozen", pen: "pen",
              lost: "no talk window")),
    fr: (no-note: "aucune note",
         help: "← → naviguer · o aperçu · f plein écran · s note · n vue présentateur · p imprimer",
         help-speaker-short: "← → naviguer · b noir · e figer · x effacer la diapo · ? toutes les touches",
         help-speaker: "← → naviguer · ↑ ↓ défiler la note · Origine au début · Fin à la fin · b noir · e figer · t durée visée · r remettre à zéro · c couleur · z annuler le trait · x effacer la diapo · + − taille de la note · o aperçu · s note dans la barre · f plein écran · n ramener l'exposé · p imprimer",
         sp: (clock: "heure", elapsed: "écoulé", target: "durée (min)",
              left: "restant", pace: "rythme", progress: "avancement",
              note: "note", next: "ensuite",
              nextStep: "étape suivante", nextSlide: "diapo suivante",
              end: "fin de l'exposé", slide: "diapo", step: "étape",
              ahead: "en avance", behind: "en retard", onplan: "dans les temps",
              black: "noir", frozen: "figé", pen: "stylo",
              lost: "pas de fenêtre d'exposé")),
  )
  listen.at(lang, default: listen.en)
}

/// File name of an asset, carrying the version.
#let asset-name(extension) = "typstage-" + runtime-version + "." + extension

/// The runtime files, ready to be written next to the HTML.
///
/// Typst cannot create files. Whoever uses `assets: "split"` or a CDN writes
/// them out once — the content comes from here so the copies cannot drift.
#let runtime-files = (
  (name: asset-name("css"), content: runtime-css),
  (name: asset-name("js"), content: runtime-js),
)
