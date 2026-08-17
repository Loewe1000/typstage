// The generic step bridge.
//
// An embedded document cannot be driven from Typst — but it can be told, on
// every step, what to do. The core knows nothing about what is inside: it
// collects named jobs per slide, hands them to the runtime as JSON, and the
// runtime posts them into the frame whose element carries that name.
//
// A companion package builds the document with `embed(html: …, bridge: name)`
// and pushes its jobs here. `typstage-geogebra` is such a package; the same
// mechanism carries anything else that lives in an iframe.

#import "internal.typ": (bridge-jobs, name-of, selector, slide-counter,
                         step-cursor)

/// Send a job to a bridged element.
///
/// - `target` is the `bridge` name given to `embed`.
/// - `at` is a step selector, resolved exactly as for `anim`: `auto` takes
///   the next free step, an integer counts as "from this step on". The default
///   is `"1-"`, because most jobs set the document up on slide entry.
///
///   A job does not move the step cursor: an applet's tween and the bullet
///   explaining it usually belong on the *same* step, not one after the other.
/// - `payload` is a dictionary. Its meaning is entirely up to the document on
///   the other side — the core passes it through unread.
///
/// When paging backwards or entering a slide the runtime replays the whole run
/// from its start with a `reset` flag, so jobs should be repeatable.
#let bridge-job(target, payload, at: "1-") = {
  if at == auto { step-cursor.step() }
  context {
    let sel = if at == auto {
      str(step-cursor.get().first()) + "-"
    } else { selector(at) }
    bridge-jobs.update(a => a + ((t: name-of(target), at: sel) + payload,))
  }
}

/// The bridge names on the current slide, in the order they appear.
///
/// This is how a companion package can leave the applet unnamed: with exactly
/// one bridged element on the slide there is nothing to choose between.
///
/// Must be called in a context. Duplicates are dropped — a tracked element is
/// laid out twice, once in the background and once as its sprite, so it
/// announces itself twice.
#let bridge-targets() = {
  let n = slide-counter.get().first()
  query(<typstage-bridge-target>)
    .map(m => m.value)
    .filter(v => v.slide == n)
    .map(v => v.name)
    .dedup()
}
