// themes.night. The darkened room.
//
// A talk for on-call engineers: how a fleet is replaced overnight without
// anyone noticing. The deck leans on three things and little else: a morph
// that fills in a formula, `alternatives` that re-splits the same curve, and a
// live status board driven step by step through `bridge-job`.
//
//   typst compile theme-night.typ theme-night.html --format html --features html
//   typst compile theme-night.typ theme-night.pdf

#import "@schule/typstage:0.1.0": *

// A theme is a dictionary, so its colours are available to the deck itself.
#let t = themes.night

// The three signal colours, fixed once here and passed everywhere. They mean
// the same thing in a Typst drawing and in the embedded board, which is the
// only reason the board reads as part of the slide instead of as a web page
// that happens to sit on it.
#let ok = rgb("#3ecf8e")
#let warn = rgb("#f0b429")
#let bad = rgb("#ef5a5a")

// ───────────────────────────────────────────────────────────────────────────
//  Drawings. Plain Typst, no drawing package.
// ───────────────────────────────────────────────────────────────────────────

// One weekday of traffic, as a share of the day's peak, hour by hour. The
// second series is the part of it that is customer batch work: nearly flat in
// absolute terms, which is exactly why it dominates the trough.
#let load = (26, 19, 15, 13, 14, 18, 26, 38, 55, 70, 80, 86, 82,
             87, 92, 95, 91, 84, 74, 68, 63, 54, 43, 33, 26)
#let batch = (8, 11, 12, 11, 10, 8, 6, 5, 5, 5, 5, 5, 5,
              5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 7, 8)

// Data points to coordinates in a box of `w` by `h`, with the value scale
// running from 0 at the bottom to `top` at the top.
#let points(w, h, data, top: 100) = data.enumerate().map(((i, v)) => (
  w * i / (data.len() - 1), h * (1 - v / top)))

// The area under a series. Separate from the line because a filled `curve`
// closes back to its first point. The baseline has to be part of the path,
// and then the same path may not carry the stroke as well.
#let area(w, h, data, colour, top: 100) = curve(
  fill: colour, stroke: none,
  curve.move((0pt, h)),
  ..points(w, h, data, top: top).map(p => curve.line(p)),
  curve.line((w, h)),
  curve.close(),
)

#let line-of(w, h, data, colour, thick, top: 100) = curve(
  stroke: thick + colour,
  ..points(w, h, data, top: top).enumerate().map(((i, p)) =>
    if i == 0 { curve.move(p) } else { curve.line(p) }),
)

// The traffic chart in three readings of the same numbers. `window` marks the
// hours the work happens in, `split` separates the batch share out of the
// total. The total curve never moves, which is the whole point of showing
// them one after the other rather than side by side.
#let traffic(w, h, window: false, split: false) = {
  let ph = h - 20pt
  box(width: w, height: h, {
    place(top + left, rect(width: w, height: h, radius: 5pt,
                           fill: t.surface, stroke: 0.7pt + t.border))
    if window {
      place(top + left, dx: w * 2 / 24, dy: 1pt,
            rect(width: w * 3 / 24, height: ph,
                 fill: t.accent.transparentize(88%), stroke: none))
    }
    // Everything inside a sized box: `place` then measures against the box, so
    // a stroke that reaches past the last data point cannot shrink the frame.
    place(top + left, dy: 1pt, box(width: w, height: ph, {
      if split {
        place(top + left, area(w, ph, load, t.accent.transparentize(90%)))
        // Opaque, not a wash: laid over the total area a translucent amber
        // turns olive, and the split stops reading as a split.
        place(top + left, area(w, ph, batch, warn.darken(58%)))
        place(top + left, line-of(w, ph, batch, warn, 1.1pt))
      } else {
        place(top + left, area(w, ph, load, t.accent.transparentize(84%)))
      }
      place(top + left, line-of(w, ph, load, t.accent, 1.6pt))
    }))
    place(top + left, dx: 10pt, dy: 7pt, text(
      size: 0.5em, fill: t.muted, tracking: 0.6pt,
      upper[requests per second · one weekday · share of peak]))
    for hh in (0, 6, 12, 18, 24) {
      let shift = if hh == 0 { -5pt } else if hh == 24 { 20pt } else { 7pt }
      place(bottom + left, dx: w * hh / 24 - shift, dy: -3pt,
            text(size: 0.5em, fill: t.muted,
                 if hh < 10 { "0" + str(hh) } else { str(hh) }))
    }
  })
}

// One machine in the fleet. `state` is "up", "out" (drained for the swap) or
// "lost" (a zone that no longer has its quorum).
#let node(state) = {
  let fills = (up: t.surface, out: warn.darken(62%), lost: bad.darken(62%))
  let lines = (up: t.border, out: warn, lost: bad)
  square(size: 30pt, radius: 4pt,
         fill: fills.at(state), stroke: 1pt + lines.at(state))
}

// Three zones of six machines. `out` says which index is being swapped in
// each zone; more than two out of six and the zone is drawn as lost, because
// at that point the rollout is the outage.
#let fleet(out) = {
  let zones = ("eu-west-1a", "eu-west-1b", "eu-west-1c")
  let rows = ()
  for (zi, name) in zones.enumerate() {
    let down = out.at(zi)
    let left = 6 - down.len()
    let hurt = left < 5
    rows.push((
      text(size: 0.6em, fill: t.muted, raw(name)),
      stack(dir: ltr, spacing: 9pt, ..range(6).map(i =>
        node(if not down.contains(i) { "up" }
             else if hurt { "lost" } else { "out" }))),
      text(size: 0.6em, weight: "bold", fill: if hurt { bad } else { ok },
           str(left) + " of 6 serving"),
    ))
  }
  grid(columns: (auto, auto, auto), column-gutter: 16pt, row-gutter: 10pt,
       align: horizon, ..rows.flatten())
}

// p99 latency across the night, every fifteen minutes. Deliberately dull: the
// argument of the closing slide is that this curve says nothing.
// The parentheses are load-bearing: a `+` at the start of a line is a list
// marker in Typst and would throw the expression back into markup.
#let wobble(i) = (calc.sin(i * 1.7) * 6
  + calc.sin(i * 0.53) * 5
  + calc.cos(i * 2.9) * 3)
#let latency = range(33).map(i => 186 + wobble(i))

#let night-graph(w, h) = {
  let ph = h - 18pt
  // 22:00 to 06:00 in quarter hours; the rollout runs from 02:00 to 04:30.
  let i0 = 16
  let i1 = 26
  box(width: w, height: h, {
    place(top + left, rect(width: w, height: h, radius: 5pt,
                           fill: t.surface, stroke: 0.7pt + t.border))
    place(top + left, dx: w * i0 / 32, dy: 1pt,
          rect(width: w * (i1 - i0) / 32, height: ph,
               fill: t.accent.transparentize(90%), stroke: none))
    place(top + left, dy: 1pt, box(width: w, height: ph, {
      // The objective, dashed: the headroom is the reason nobody was woken.
      place(top + left, dy: ph * (1 - 250 / 400), line(
        length: w, stroke: (paint: t.muted, thickness: 0.7pt, dash: "dashed")))
      place(top + left, area(w, ph, latency, t.accent.transparentize(88%), top: 400))
      place(top + left, line-of(w, ph, latency, t.accent, 1.6pt, top: 400))
      // One tick per machine, in the groups of three they actually went in:
      // six waves, one machine per zone in each. Evenly spaced ticks would
      // quietly contradict the slide two before this one.
      for wave in range(6) {
        for j in range(3) {
          place(bottom + left, dx: w * (i0 + 0.5 + wave * 1.55 + j * 0.19) / 32,
                rect(width: 1.6pt, height: 8pt, fill: t.accent, stroke: none))
        }
      }
    }))
    place(top + left, dx: 10pt, dy: 6pt, text(
      size: 0.5em, fill: t.muted, tracking: 0.6pt,
      upper[p99 latency · 22:00 to 06:00]))
    place(top + right, dx: -10pt, dy: ph * (1 - 250 / 400) - 13pt,
          text(size: 0.5em, fill: t.muted)[objective 250 ms])
    for (i, lbl) in (("22:00", 0), ("00:00", 8), ("02:00", 16),
                     ("04:00", 24), ("06:00", 32)).enumerate() {
      place(bottom + left, dx: w * lbl.at(1) / 32 - (if i == 0 { 0pt }
              else if i == 4 { 26pt } else { 13pt }), dy: -2pt,
            text(size: 0.5em, fill: t.muted, lbl.at(0)))
    }
  })
}

// ───────────────────────────────────────────────────────────────────────────
//  The status board. The embedded document and the states it is driven to.
// ───────────────────────────────────────────────────────────────────────────

// Every measurement in `em`, without exception. `embed` puts the deck's basic
// style in front of the document, and inside a zoomed frame one CSS pixel is
// one point of the slide, so `em` here means the same thing it means on the
// slide, and the board grows with the projection. A `px` anywhere below would
// stay laptop-sized on a twelve-foot screen.
//
// Single quotes throughout, so the Typst string needs no escaping and stays
// readable. The document ends up in the frame's `srcdoc`, which is quoted for
// us.
#let board-html = (
  "<style>"
  + "@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}"
  + ".b{height:100%;box-sizing:border-box;display:flex;flex-direction:column;"
  + "gap:.5em;padding:.85em 1em;border-radius:.4em;background:"
  + t.surface.to-hex() + ";border:1px solid " + t.border.to-hex() + "}"
  + ".hd{display:flex;align-items:baseline;gap:.7em;padding-bottom:.5em;"
  + "border-bottom:1px solid " + t.border.to-hex() + "}"
  + ".hd .t{font-size:.6em;font-weight:700;letter-spacing:.1em;"
  + "text-transform:uppercase;color:" + t.muted.to-hex() + "}"
  + ".hd .clk{margin-left:auto;font-size:.8em;font-weight:600;"
  + "font-variant-numeric:tabular-nums;color:" + t.ink.to-hex() + "}"
  + ".r{display:flex;align-items:center;gap:.6em;font-size:.8em}"
  + ".d{width:.6em;height:.6em;border-radius:50%;flex:none;"
  + "transition:background .35s}"
  + ".k{flex:1;color:" + t.muted.to-hex() + "}"
  + ".v{font-weight:600;font-variant-numeric:tabular-nums}"
  + ".bar{height:.45em;border-radius:.23em;overflow:hidden;background:"
  + t.border.to-hex() + "}"
  + ".bar i{display:block;height:100%;width:38%;background:" + ok.to-hex()
  + ";transition:width .7s ease,background .7s ease}"
  + ".sub{font-size:.62em;margin-top:.25em;color:" + t.muted.to-hex() + "}"
  + ".ft{margin-top:auto;padding-top:.5em;font-size:.62em;line-height:1.35;"
  + "color:" + t.muted.to-hex() + ";border-top:1px solid "
  + t.border.to-hex() + "}"
  + "</style>"
  + "<div class='b'>"
  + "<div class='hd'><span class='t'>on-call board</span>"
  + "<span class='t' style='opacity:.55'>fleet eu-west</span>"
  + "<span class='clk' id='clk'>03:02</span></div>"
  + "<div class='r'><span class='d' id='d1'></span>"
  + "<span class='k'>canary traffic</span><span class='v' id='v1'>0 %</span></div>"
  + "<div class='r'><span class='d' id='d2'></span>"
  + "<span class='k'>error rate, 5 min</span>"
  + "<span class='v' id='v2'>0.02 %</span></div>"
  + "<div class='r'><span class='d' id='d3'></span>"
  + "<span class='k'>p99 latency</span><span class='v' id='v3'>184 ms</span></div>"
  + "<div class='r'><span class='d' style='background:transparent'></span>"
  + "<span class='k'>error budget, month</span>"
  + "<span class='v' id='v4'>38 %</span></div>"
  + "<div class='bar'><i id='b4'></i></div>"
  // The callback to the slide before: the bar is a share, this line is the
  // forty-three minutes it is a share of.
  + "<div class='sub' id='sp'>16 of 43 minutes spent this month</div>"
  + "<div class='ft' id='ft'>wave 2 of 6 finished: 6 of 18 machines "
  + "on the new build</div>"
  + "</div>"
  + "<script>(function(){"
  + "var C={ok:'" + ok.to-hex() + "',warn:'" + warn.to-hex() + "',bad:'"
  + bad.to-hex() + "',off:'" + t.border.to-hex() + "'};"
  + "function q(i){return document.getElementById(i)}"
  + "function light(el,s){el.style.background=C[s]||C.off;"
  + "el.style.animation=(s=='warn'||s=='bad')"
  + "?'pulse 1.4s ease-in-out infinite':'none'}"
  // One job carries the whole state of the board, never a change to it. That
  // is what makes it repeatable: paging backwards replays the run from step
  // one, and the last job to arrive simply wins.
  + "function apply(j){"
  + "if(j.clock)q('clk').textContent=j.clock;"
  + "if(j.canary){q('v1').textContent=j.canary;light(q('d1'),j.canaryState)}"
  + "if(j.err){q('v2').textContent=j.err;light(q('d2'),j.errState)}"
  + "if(j.lat){q('v3').textContent=j.lat;light(q('d3'),j.latState)}"
  + "if(j.burn!=null){q('v4').textContent=j.burn+' %';"
  + "q('b4').style.width=j.burn+'%';"
  + "q('b4').style.background=C[j.burnState]||C.ok}"
  + "if(j.spent)q('sp').textContent=j.spent;"
  + "if(j.note)q('ft').textContent=j.note}"
  // Without this line the frame stays dark and silent: the runtime only marks
  // a frame live once it has said hello, and sends it nothing until then.
  + "parent.postMessage({typstage:1,ready:1},'*');"
  + "addEventListener('message',function(e){var d=e.data;"
  + "if(!d||d.typstage!==1||!d.jobs)return;d.jobs.forEach(apply)});"
  + "})()</script>"
)

// Named arguments read better at the call site than a bare dictionary; the
// keys go over the wire in the shape the document's JavaScript wants them.
#let board-state(
  clock: "", canary: "", canary-light: "ok", err: "", err-light: "ok",
  lat: "", lat-light: "ok", burn: 0, burn-light: "ok", spent: "", note: "",
) = (
  clock: clock, canary: canary, canaryState: canary-light,
  err: err, errState: err-light, lat: lat, latState: lat-light,
  burn: burn, burnState: burn-light, spent: spent, note: note,
)

// One line of narration, timestamped like the board it stands next to.
#let beat(time, body) = block(width: 100%, {
  block(above: 0pt, below: 0.4em,
        text(size: 0.68em, weight: "bold", fill: t.accent, tracking: 1pt, time))
  block(above: 0pt, below: 0pt, text(size: 0.92em, body))
})

// ───────────────────────────────────────────────────────────────────────────
//  The deck.
// ───────────────────────────────────────────────────────────────────────────

#presentation(
  title-slide(
    title: [Deploying to a Fleet at 3 a.m.],
    subtitle: [Error budgets, one node at a time, and how to tell
               it went well],
    author: [SRE Summit · Hall 2],
    date: datetime(year: 2026, month: 9, day: 30),
  ),

  slide(
    title: [Three in the morning is not a time],
    note: [If the question about follow-the-sun teams comes, the answer is on
           the third reading: it is the batch work that pins the window, not
           the staffing.],
  )[
    // The same curve read three ways. Nothing here would survive as a static
    // picture: the total never moves, so the audience can see that the window
    // was placed on a measurement and that the trough is not empty: two
    // claims about one set of numbers, which is what `alternatives` is for.
    #alternatives(
      block(width: 100%, {
        traffic(778pt, 235pt)
        v(0.55em)
        text(size: 0.85em)[Requests per second across one weekday. Between
          02:00 and 05:00 this service runs at a seventh of its peak. That is
          a measurement, and it is the only reason anyone is awake.]
      }),
      block(width: 100%, {
        traffic(778pt, 235pt, window: true)
        v(0.55em)
        text(size: 0.85em)[So the window sits on the trough. Three hours,
          every night. When the curve moves, the window moves with it. Nobody
          negotiates it with a calendar.]
      }),
      block(width: 100%, {
        traffic(778pt, 235pt, window: true, split: true)
        v(0.55em)
        text(size: 0.85em)[But the trough is not empty, it is *different*.
          At 03:00, eleven of the thirteen remaining points are customers'
          batch jobs. The work nobody watches until morning.]
      }),
      start: 1, enter: "fade",
    )
  ],

  section([What the budget buys]),

  slide(
    title: [The number you are allowed to spend],
    note: [Say "allowed to spend" and not "may lose". The next slide only
           lands if the budget already sounds like an allowance.],
  )[
    #v(0.5em)
    // Source of the morph. The pins name the two parts that get replaced by
    // numbers on the next slide, so those glyphs land on their counterparts
    // instead of being matched by shape against whatever is nearest.
    #statement(color: t.accent, size: 1.5em)[
      #morph(<budget>)[
        $ "error budget" = (1 - #pin(<slo>)[$"SLO"$]) dot #pin(<win>)[$"window"$] $
      ]
    ]
    #v(0.2em)
    #stagger(
      [An SLO is a promise about a *window*, not about a request. Nothing is
       promised about the next call anyone makes.],
      [Whatever the promise leaves over is the budget. It belongs to whoever
       ships. It is the licence to change a running system.],
      // `start: 2`, not `auto`: the morph above stands from step one without
      // moving the step cursor, so `auto` would put the first line beside the
      // formula instead of after it.
      start: 2,
    )
    #v(1fr)
  ],

  slide(
    title: [Forty-three minutes],
    note: [Pause here. The room usually needs a second to accept that
           forty-three minutes is the whole allowance for a month.],
  )[
    #v(0.5em)
    // Target of the morph, on the immediately following slide. Anything
    // further apart does not fly. Same colour and same size as the source, so
    // only the two named parts visibly change.
    #statement(color: t.accent, size: 1.5em)[
      #morph(<budget>)[
        $ "error budget" = (1 - #pin(<slo>)[$99.9%$]) dot #pin(<win>)[$30 "days"$] $
      ]
    ]
    #v(0.2em)
    #anim(at: 2)[Three nines over a month is *43 minutes and 12 seconds*. That
      is not a target to beat. It is a quantity to spend.]
    #v(0.5em)
    #anim(at: 3, callout(title: [The part that surprises people])[
      A month that ends with the budget untouched is not a good month. It
      means the fleet was left alone, and everything that was not shipped is
      still waiting, in a bigger batch, for a riskier night.
    ])
  ],

  slide(
    title: [One node, three moves],
    note: [Three minutes of watching per node is the number people argue
           about. It is deliberately longer than the health check.],
  )[
    Eighteen machines, and every one of them goes through the same three moves.

    #v(0.7em)

    // Three steps in sequence, so the audience walks the loop once with the
    // speaker instead of reading all of it while the first sentence is still
    // being said.
    #tiles(
      card(number: 1, title: [Drain])[
        Out of the load balancer, then left to finish what it holds.
      ],
      card(number: 2, title: [Swap])[
        New image, new process. The old one stays on disk.
      ],
      card(number: 3, title: [Return])[
        Back in after three green checks, then three quiet minutes.
      ],
    )

    #v(0.9em)

    #anim(callout(title: [The rule everything else hangs on])[
      Never two nodes of one failure domain at a time. Break that rule and the
      rollout *is* the outage.
    ], enter: "rise")
    #v(1fr)
  ],

  slide(
    title: [Why one, and not three],
    note: [The number to say out loud is six waves: eighteen machines, three
           at a time, a little under two hours.],
  )[
    #v(0.7fr)
    // Same three machines out of service, arranged two ways. The picture is
    // the argument. "Three at once" is not the dangerous part, "three in one
    // place" is, and a still image could only make one of the two claims.
    #align(center, alternatives(
      block(width: 100%, {
        align(center, fleet(((0, 1, 2), (), ())))
        v(0.7em)
        align(center, text(size: 0.85em)[Three at once, all in one zone.
          1a is down to half its capacity, and the next single fault there
          takes the whole zone with it.])
      }),
      block(width: 100%, {
        align(center, fleet(((0,), (2,), (4,))))
        v(0.7em)
        align(center, text(size: 0.85em)[Three at once, one per zone. The same
          three machines, the same six waves, and no zone ever drops below
          five of six.])
      }),
      start: 1, enter: "fade", align: top + left,
    ))
    #v(1fr)
  ],

  section([The canary]),

  slide(
    title: [One percent, and nine minutes to read it],
    note: [Nine minutes is not a round number by accident. It is where the
           error-rate sample stops being noise at this traffic level.],
  )[
    One machine is given one percent of live traffic on the new build: one
    percent, not one eighteenth. Nothing else about the system changes.

    #v(0.6em)

    // Three signals, one at a time: each of them needs a sentence from the
    // speaker, and revealing all three at once means the room reads ahead.
    #stagger(
      [*Error rate*: measured against the same five minutes on the old build,
       never against zero.],
      [*p99 latency.* Long before the median moves, the tail shows a bad
       build first.],
      [*Budget burn rate.* Not how much is gone. How fast it is going
       right now.],
    )

    #v(0.6em)

    #anim(callout(title: [Why nine minutes])[
      Under nine, the sample is noise. Over fifteen, a bad build has reached
      enough people that the budget, not the canary, decides what happens next.
    ])
  ],

  slide(
    title: [The board at 03:11],
    note: [This is the second monitor on the on-call desk. Let it stand for a
           moment at the red step. People read it, and the point of the whole
           talk is that a machine noticed this before a human did.],
  )[
    #v(0.5fr)
    #side-by-side(
      split: (1.2fr, 1fr), gutter: 20pt,
      // The frame is named, and `bridge-job` sends it one dictionary per step
      // below. That is the reason this board is here rather than a screenshot:
      // it changes while the story is told, in the same rhythm as the words.
      embed(
        html: board-html,
        width: 100%, height: 272pt,
        bridge: "board",
        label: [On-call status board],
        // Paper can show a sequence where a screen can only show one moment,
        // so the stand-in is the whole run rather than a photograph of one
        // step of it. `label` names the frame for anyone reading the source.
        fallback: {
          set text(size: 0.62em)
          // `fallback-box` centres what it is given; the table wants its own
          // alignment back.
          set align(left)
          let row(colour, ..cells) = cells.pos().map(c => text(fill: colour, c))
          block(width: 100%, inset: 12pt, radius: 5pt, fill: t.surface,
                stroke: 0.7pt + t.border, {
            block(above: 0pt, below: 10pt, text(fill: t.muted, tracking: 1pt,
                  upper[on-call board · fleet eu-west]))
            grid(
              columns: (auto, 1fr, 1fr, 1fr, 1fr),
              column-gutter: 9pt, row-gutter: 7pt,
              align: (left, right, right, right, right),
              ..row(t.muted, [], [canary], [errors], [p99], [budget]),
              ..row(t.ink, [03:02], [0 %], [0.02 %], [184 ms], [38 %]),
              ..row(t.ink, [03:07], [1 %], [0.03 %], [191 ms], [38 %]),
              ..row(bad, [03:11], [1 %], [0.90 %], [612 ms], [51 %]),
              ..row(t.ink, [03:12], [0 %], [0.02 %], [186 ms], [51 %]),
              ..row(t.ink, [03:40], [1 %], [0.02 %], [188 ms], [51 %]),
            )
          })
        },
      ),
      // The narration replaces itself rather than piling up: the board shows
      // one moment, and so should the sentence beside it.
      alternatives(
        beat[03:02][Two waves are done. Six machines carry the new build and
                    nothing on this board has moved all night.],
        beat[03:07][The canary opens. One percent of requests, and nine
                    minutes of evidence to gather.],
        beat[03:11][Four minutes in: errors at forty-five times baseline, the
                    tail past 600 ms. The budget starts burning.],
        beat[03:12][Closed. One node reverted, thirteen percent of the month
                    spent in four minutes, and nobody was called.],
        beat[03:40][Second attempt, holding for twenty-eight minutes. Now the
                    rest of the fleet may follow.],
        start: 1, enter: "fade", align: horizon + left,
      ),
    )
    #v(1fr)

    // One job per step, each carrying the *whole* state of the board. Written
    // that way on purpose: paging backwards replays the run from step one, so
    // "set the error rate to 0.9 %" survives being applied twice while
    // "raise the error rate" would not.
    #bridge-job("board", board-state(
      clock: "03:02", canary: "0 %", canary-light: "off",
      err: "0.02 %", lat: "184 ms", burn: 38,
      spent: "16 of 43 minutes spent this month",
      note: "wave 2 of 6 finished: 6 of 18 machines on the new build",
    ), at: "1")

    #bridge-job("board", board-state(
      clock: "03:07", canary: "1 %",
      err: "0.03 %", lat: "191 ms", burn: 38,
      spent: "16 of 43 minutes spent this month",
      note: "canary open: 9 minutes of evidence needed before wave 3",
    ), at: "2")

    #bridge-job("board", board-state(
      clock: "03:11", canary: "1 %", canary-light: "warn",
      err: "0.90 %", err-light: "bad", lat: "612 ms", lat-light: "bad",
      burn: 51, burn-light: "bad",
      spent: "22 of 43 minutes spent this month",
      note: "error rate 45× baseline, budget burning at 14× the monthly rate",
    ), at: "3")

    #bridge-job("board", board-state(
      clock: "03:12", canary: "0 %", canary-light: "off",
      err: "0.02 %", lat: "186 ms", burn: 51, burn-light: "warn",
      spent: "22 of 43 minutes spent this month",
      note: "canary closed, one node reverted: 13 % of the month in 4 minutes",
    ), at: "4")

    #bridge-job("board", board-state(
      clock: "03:40", canary: "1 %",
      err: "0.02 %", lat: "188 ms", burn: 51, burn-light: "warn",
      spent: "22 of 43 minutes spent this month",
      note: "second attempt holding for 28 minutes, wave 3 resumes at 03:45",
    ), at: "5")
  ],

  slide(
    title: [The graph nobody has to look at],
    note: [Point at the ticks, not at the curve. Eighteen machines were
           replaced under a line that does not react.],
  )[
    #night-graph(778pt, 200pt)

    #v(0.5em)

    // A quiet slide on purpose, between the busiest one in the deck and the
    // close. One reveal, because the callout is an interpretation of the
    // picture and should not be read before the picture is.
    #text(size: 0.85em)[Each tick is one machine out and back: six waves of
      three, inside the shaded hours.]

    #v(0.6em)

    #anim(at: 2, callout(title: [What was delivered])[
      Nothing in this line. The rollout is invisible in the only signal the
      customer has.
    ])
    #v(1fr)
  ],

  slide(title: none)[
    #v(1fr)
    #statement(size: 1.4em, color: t.accent)[
      A good night is one you recognise only by what is missing.
    ]
    #v(0.6em)
    // `block(width: 100%)` around each line, not a bare `align`: a tracked
    // element is measured on its own and comes out as wide as its content, so
    // a lone `align(center, …)` would have nothing to centre in.
    #stagger(
      block(width: 100%, align(center)[No call at 03:14.]),
      block(width: 100%, align(center)[No line in the incident log.]),
      block(width: 100%,
            align(center)[And forty-three minutes that were spent, not saved.]),
      start: 2, spacing: 0.55em,
    )
    #v(1fr)
  ],

  // A darkened room punishes moving slide frames: the frame is the brightest
  // thing on the screen and pulls the eye off the sentence. Everything that
  // moves in this deck moves *inside* a slide, so the slide change itself is
  // the quietest one available.
  transition: "fade",
  transition-duration: 460,
  duration: 620,
  theme: t,
)
