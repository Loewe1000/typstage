// Appearing, moving and staggering.

#import "internal.typ": (html-output, name-of, pin-index, pin-marker,
                        step-cursor, track)

/// Reveal content on particular steps.
///
/// `at` is a step selector. `auto` — the default — takes the next free step,
/// so consecutive `anim`s reveal one after another without any numbering.
/// Otherwise: `2` (from step two on), `"1-2"`, `(2, 4)`, `"3"`. An explicit
/// number also moves the cursor along, so a following `auto` carries on after
/// it instead of starting over.
///
/// `enter` applies in both directions: paging back plays the same effect in
/// reverse, taking the entrance back. `exit` only concerns a real departure,
/// when an element falls out of its range while moving forward.
#let anim(
  body,
  at: auto,
  enter: "fade-up",
  exit: "fade",
  duration: auto,
  delay: 0,
) = track("anim", body, at: at, extra: (
  enter: enter, exit: exit, delay: delay,
  duration: if duration == auto { none } else { duration },
))

/// Magic move: the same `name` on two slides, and the thing flies across.
///
/// The name is a string or a label — `morph(<pythagoras>, …)`.
///
/// `duration` ist 900 ms, nicht die Dauer der Präsentation: ein Flug quer über
/// die Folie braucht mehr Zeit als eine Einblendung, und in echten Decks wurde
/// die Vorgabe in 161 von 165 Fällen überschrieben. `auto` nimmt wieder die
/// Dauer der Präsentation.
///
/// `match` is `"auto"`, `"glyph"` (always per glyph) or `"block"` (always as
/// one rectangle).
///
/// Two names may be equal on the *target* slide. The runtime looks the source
/// up by name but iterates over the targets, so two targets sharing a name
/// both start from the same place and the glyph visibly splits in two.
/// `at` ist fast immer richtig, wie es ist. Ein Morph steht ab dem ersten
/// Schritt, weil ein Flugziel beim Betreten der Folie da sein muss — und weil
/// beim Zurückblättern die Rollen tauschen, gilt das für beide Enden.
///
/// Verzögern lohnt nur für das *erste* Glied einer Kette, etwa wenn die Formel
/// zusammen mit ihrer Kachel erscheinen soll. Erlaubt ist es genau dann, wenn
/// die Vorfolie keinen gleichnamigen Morph trägt; das Paket prüft das beim
/// Übersetzen und meldet sich, wenn es nicht stimmt.
#let morph(name, body, at: "1-", duration: 900, match: "auto", inline: true) = track(
  "morph", body, at: at, inline: inline,
  // `fly`, nicht `duration`: das hier ist die Dauer des *Fluges*, und der
  // Runtime las bisher dasselbe Attribut auch für das Einblenden. Ein Morph
  // mit `at:` blendete deshalb über 900ms ein, während die Karte daneben nach
  // 520ms fertig war — dieselbe Bewegung, sichtbar auseinandergezogen.
  extra: (name: name-of(name), match: match,
          fly: if duration == auto { none } else { duration }),
)

/// Several versions of the same thing, each replacing the one before.
///
/// ```typ
/// #alternatives(
///   $ (a + b)^2 $,
///   $ (a + b)(a + b) $,
///   $ a^2 + 2 a b + b^2 $,
/// )
/// ```
///
/// `inline: true` keeps the whole thing in the running line, for versions of a
/// single word or formula.
///
/// They all stand in the same place, in a box as large as the largest of them,
/// so nothing around them jumps as they change. Each takes one step; the last
/// one stays for the rest of the slide.
///
/// On paper only the last one is set — in the same box, so the page keeps the
/// spacing of the slide. Printing all of them would pile them on top of one
/// another.
#let alternatives(
  ..variants,
  start: auto,
  align: top + left,
  enter: "fade",
  duration: auto,
  inline: false,
) = {
  let items = variants.pos()
  assert(items.len() > 0,
         message: "typstage: alternatives() wants at least one version")
  // Wie bei `morph`: `layout()` arbeitet blockweise und bräche die Zeile, in
  // der die Fassungen stehen. Die Hülle muss deshalb um das Ganze liegen,
  // nicht darin.
  let shell-outer = if inline { box } else { it => it }
  shell-outer(layout(available => context {
    // Zweimal messen, das Größere gilt — dieselbe Falle wie in `track`:
    // `height: 100%` in einer Fassung fiele sonst auf null zusammen, eine
    // Messung nur gegen die verfügbare Höhe würde Überlauf kappen.
    let natural = items.map(v => measure(v, width: available.width))
    let bounded = items.map(v => measure(v, width: available.width,
                                         height: available.height))
    let w = calc.max(..natural.map(s => s.width), ..bounded.map(s => s.width))
    let h = calc.max(..natural.map(s => s.height), ..bounded.map(s => s.height))
    if not html-output.get() {
      return block(width: w, height: h, place(align, items.last()))
    }
    let first = if start == auto { step-cursor.get().first() + 1 } else { start }
    let last = items.len() - 1
    block(width: w, height: h, {
      for (i, v) in items.enumerate() {
        // Exactly this step for all but the last, which stays: `"3"` is that
        // one step, `"3-"` is from there on.
        let at = if i == last { str(first + i) + "-" } else { str(first + i) }
        place(align, anim(v, at: at, enter: enter, duration: duration))
      }
    })
  }))
}

/// Ein benanntes Stück innerhalb eines Morphs.
///
/// Der Formabgleich paart Zeichen nach ihrem Umriss und, wo das nicht reicht,
/// nach Nähe. Meistens stimmt das. Wo nicht — weil aus der 3 in `3x^4` die 3
/// in `4 dot 3x^3` werden soll und dazwischen eine andere 3 steht —, bekommt
/// das Stück einen Namen, und die Paarung richtet sich danach.
///
/// ```typ
/// #morph(<term>)[$#pin(<faktor>)[3] x^#pin(<hoch>)[4]$]
/// … und auf der nächsten Folie …
/// #morph(<term>)[$#pin(<hoch>)[4] dot #pin(<faktor>)[3] x^3$]
/// ```
///
/// Gleiche Namen finden zueinander, bevor die Form befragt wird; alles
/// Übrige läuft weiter wie bisher. Ein Pin ohne Gegenstück auf der anderen
/// Folie fällt geräuschlos in den Formabgleich zurück.
///
/// Der Name ist eine Zeichenkette oder eine Marke.
#let pin(name, body) = box(fill: pin-marker(pin-index(name-of(name))), body)

/// Everything after this appears a step later.
///
/// The short form for slides that simply unfold: no `anim` around anything,
/// no step numbers.
///
/// ```typ
/// == A slide
/// First this.
/// #pause
/// Then that.
/// ```
///
/// It is read at the top level of the slide body, `#set` and `#show` rules
/// included. Inside a grid cell, a table or a figure it is not seen — there
/// the content is a field of an element, not part of the body — so reach for
/// `anim` in those places.
#let pause = metadata("typstage-pause")

/// Nacheinander erscheinen lassen — eine Liste oder mehrere Blöcke.
///
/// Zwei Schreibweisen, dieselbe Funktion:
///
/// ```typ
/// #stagger[
///   - erst dies
///   - dann das
/// ]
/// #stagger(card[links], card[rechts])
/// ```
///
/// Bei einer Liste werden die Aufzählungszeichen hier gesetzt und nicht `list`
/// überlassen: nur so gehört das Zeichen zum verfolgten Element. Bliebe es bei
/// der Liste, stünde es im Hintergrund — und wäre da, bevor sein Punkt
/// erscheint.
///
/// `start` ist `auto`: die Folge macht dort weiter, wo die Folie stehen
/// geblieben ist. `stride: 0` lässt alles im selben Schritt erscheinen und
/// staffelt nur über `stagger` in Millisekunden.
#let stagger(
  ..items,
  start: auto,
  stride: 1,
  enter: "fade-up",
  duration: auto,
  stagger: 60,
  spacing: 0.65em,
) = context {
  let start = if start == auto { step-cursor.get().first() + 1 } else { start }
  let gegeben = items.pos()
  assert(gegeben.len() > 0, message: "typstage: stagger() wants something to stagger")

  // Ein einzelnes Stück kann eine Liste sein — dann werden deren Punkte
  // gestaffelt. Alles andere sind die Stücke selbst.
  let punkte = if gegeben.len() == 1 {
    let body = gegeben.first()
    let parts = if body.has("children") { body.children } else { (body,) }
    parts.filter(c => c.func() in (list.item, enum.item))
  } else { () }

  if punkte.len() == 0 {
    // Keine Liste: die Stücke der Reihe nach, jedes als eigener Block.
    for (i, b) in gegeben.enumerate() {
      block(anim(b, at: str(start + i * stride) + "-",
                 enter: enter, duration: duration, delay: i * stagger))
    }
    return
  }

  let numbered = punkte.at(0).func() == enum.item
  let marks = punkte.enumerate().map(((i, p)) => {
    if numbered { [#(i + 1).] } else { [•] }
  })
  // One shared column width so the texts line up.
  let column = calc.max(..marks.map(m => measure(m).width.pt())) * 1pt

  for (i, p) in punkte.enumerate() {
    if i > 0 { v(spacing, weak: true) }
    anim(
      grid(
        columns: (column, 1fr),
        column-gutter: 0.5em,
        // Senkrecht ausdrücklich: eine `auto`-Ausrichtung erbt die des
        // umgebenden Rasters, und `side-by-side` gibt `horizon` vor. Das
        // Zeichen säße dann neben der Mitte eines zweizeiligen Punktes
        // statt neben seiner ersten Zeile.
        align: (right + top, left + top),
        marks.at(i), p.body,
      ),
      at: str(start + i * stride) + "-",
      enter: enter, duration: duration, delay: i * stagger,
    )
  }
}
