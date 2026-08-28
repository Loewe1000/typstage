// A deck that draws its own table of contents, and knows where it stands.
//
//   typst compile gliedern.typ gliedern.html --format html --features html
//   typst compile gliedern.typ gliedern.pdf
//
// A long talk needs a slide the room can come back to. This deck builds that
// slide from the deck itself instead of a hand-kept list: `deck-outline()`
// says how the thing is cut -- one entry per section, with the slides beneath
// it -- and `info().section` says which one is running. Nothing is written
// twice, so nothing can drift.
//
// Two things follow from that, and both are the point:
//
//   * Rename a section and the contents slide renames itself.
//   * Move a slide from one part to another and the counts follow.
//
// `first`, `last` and `count` are transitive: a depth-1 section counts the
// slides of its sub-sections too.

#import "@schule/typstage:0.1.0": *

#let t = themes.editorial
#let hier = t.accent
#let leise = t.muted

// The contents slide, built once and shown four times. It takes the current
// section's number rather than a heading of its own, so the same function
// serves as the opening overview and as the divider between parts.
#let wegweiser(jetzt: none) = context {
  let teile = deck-outline().filter(a => a.depth == 1)
  let n = info().slide.total
  set text(size: 1.05em)
  grid(
    columns: (auto, 1fr, auto),
    column-gutter: 18pt,
    row-gutter: 14pt,
    // The count is set smaller than the row it belongs to, and a grid puts
    // every cell at the top of its row. Left alone, "3 slides" floated a
    // dozen pixels above the baseline of its own line; `bottom` puts it back
    // on it. Right-aligned as well, so the column has an edge instead of a
    // ragged one.
    align: (auto, auto, right + bottom),
    ..teile
      .map(a => {
        let da = jetzt != none and a.number == jetzt
        let farbe = if da { hier } else { leise }
        (
          text(fill: farbe, weight: if da { "bold" } else { "regular" },
               size: 1.2em)[#a.number],
          text(fill: if da { t.ink } else { leise },
               weight: if da { "bold" } else { "regular" })[#a.title],
          text(fill: leise, size: 0.8em)[
            #a.count #if a.count == 1 [slide] else [slides]
          ],
        )
      })
      .flatten()
  )
  v(0.8em)
  text(fill: leise, size: 0.8em)[#n slides in all]
}

#show: presentation.with(
  theme: t,
  title: [What a Map Cannot Say],
  subtitle: [Four things a projection decides for you],
  author: [Geography · Dr Halloran],
  date: [19 March 2026],
  transition: "fade",
  style: it => { v(1fr); it; v(1fr) },
)

// ═══════════════════════════════════════════════════════════════════════════

= Where we are going

== Contents

#speaker-note[
  Read the four parts out once, slowly. They will see this slide three more
  times, and each time one line will be the loud one.
]

#wegweiser()

// ═══════════════════════════════════════════════════════════════════════════

= Every map is a lie

== The claim

#speaker-note[
  The word "lie" is deliberate and they will push back on it. Let them.
]

#text(size: 1.4em)[A sphere does not fit on a rectangle.]

#v(0.6em)
#anim(at: "2-")[
  Every flat map has therefore decided what to keep and what to give up.
]

== What can be kept

#stagger(dim: true)[
  - *Shape*, locally: a small island looks like itself.
  - *Area*: two countries that are equally big cover equally much paper.
  - *Direction*: a straight line on the map is a straight course at sea.
]

#v(0.5em)
#anim(at: "4-", text(fill: hier)[Never all three at once.])

== Where we are

#speaker-note[
  The divider. It is the same slide as the contents, and the running part is
  the loud line -- nobody has to be told which one it is.
]

#wegweiser(jetzt: 2)

// ═══════════════════════════════════════════════════════════════════════════

= Mercator, and why it will not go away

== Straight lines at sea

#speaker-note[
  This is the part they half know from the internet. The interesting bit is
  not that Greenland is wrong, it is *why* the wrongness was worth it.
]

#text(size: 1.3em)[
  A course of constant compass bearing is a straight line on this map.
]

#v(0.6em)
#anim(at: "2-")[
  For four hundred years that was worth any amount of distortion at the poles.
]

== The price

#stagger[
  - Greenland looks the size of Africa. It is fourteen times smaller.
  - The distortion grows without limit toward the poles.
  - The poles themselves are not on the map at all.
]

== Where we are

#wegweiser(jetzt: 3)

// ═══════════════════════════════════════════════════════════════════════════

= What to ask of a map

== Three questions

#speaker-note[
  They should leave with these three, not with a list of projections.
]

#stagger(dim: true)[
  - What was this map *for*?
  - What did it give up to do that?
  - Who drew it, and when?
]

== Where we are

#wegweiser(jetzt: 4)
