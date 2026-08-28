// A lesson that is mostly the class working, and a deck that knows how long.
//
//   typst compile unterrichten.typ unterrichten.html --format html --features html
//   typst compile unterrichten.typ unterrichten.pdf
//
// Fermi questions: how do you get within a factor of ten of a number nobody
// looked up? The hour is four short bursts of work with a little talk between
// them, and the deck's job is to say how long each burst was meant to be --
// that is what `class-clock` is for.
//
// It starts nothing. `Shift+T` in the presenter view offers the number, the
// teacher confirms or changes it, and only then does the clock run: the deck
// knows how long the task was planned for, the room decides how long it gets.
// And because that clock stands *on* the slide instead of over it, the task
// stays readable while it counts, and paging ahead does not end it.
//
// Written for somebody who holds it: every working slide carries the minutes,
// a note, and nothing the class has to wait for.

#import "@schule/typstage:0.1.0": *

#let t = themes.lesson
#let zahl = t.accent
#let leise = t.muted

#show: presentation.with(
  theme: t,
  title: [How Many Piano Tuners?],
  subtitle: [Getting within a factor of ten of a number nobody looked up],
  author: [Maths · Mr Okonkwo],
  date: [12 March 2026],
  transition: "fade",
  // The planned length of the hour. The presenter view compares it with the
  // time actually spent and says whether the lesson is ahead or behind.
  duration: 45,
  style: it => { v(1fr); it; v(1fr) },
)

// ═══════════════════════════════════════════════════════════════════════════
//  What the question is

= The question

== A number nobody looked up

#speaker-note[
  Do not solve it. The point of the next forty minutes is that they solve it,
  badly, four times over, and that the fourth time is close.
]

#v(0.4em)
#text(size: 1.5em)[How many piano tuners work in this city?]
#v(0.6em)

#anim(at: "2-")[
  Nobody in this room knows. Nobody is going to look it up.
]

// The blank line matters. Without it the two blocks are one paragraph in
// Typst's eyes, and on paper the two sentences ran together into a single
// wrapping line -- two lines in the browser, one in the handout.
#anim(at: "3-")[
  And by the end of the hour we will have a number, and it will be close
  enough to argue about.
]

== The rule of the game

#speaker-note[
  Two minutes, no more. They will want to start guessing; let them, but the
  rule has to be said out loud first or the whole hour turns into a quiz.
]

#class-clock(2)

#stagger(dim: true)[
  - Break the question into smaller ones you *can* estimate.
  - Every estimate is allowed to be wrong by a factor of two.
  - Say your number out loud, even when you think it is silly.
]

#v(0.5em)
#text(fill: leise)[Two minutes. Read it, then we start.]

// ═══════════════════════════════════════════════════════════════════════════
//  The four bursts

= Four goes at it

== First go: alone

#speaker-note[
  Eight minutes, alone, on paper. Walk the room and say nothing. This is the
  burst where the clock matters most -- they will look up at it, and it should
  be on the slide with the task, not over it.
]

#class-clock(8)

#text(size: 1.3em)[Write down every smaller question you would need to answer.]

#v(0.5em)
#text(fill: leise)[
  Alone. No talking, no looking across. Eight minutes.
]

== Second go: in pairs

#speaker-note[
  Five minutes. Pairs, not fours -- in a four one person writes and three
  watch. The instruction to *compare lists* rather than agree on one is the
  whole difference.
]

#class-clock(5)

#text(size: 1.3em)[Compare your lists. Do not agree on one.]

#v(0.5em)
#stagger[
  - Which questions did you both write down?
  - Which did only one of you see?
]

== What the room found

#speaker-note[
  No clock here: this is the talking part, and it takes as long as it takes.
  Collect on the board. Expect population, pianos per household, tunings per
  year, tunings per day.
]

#text(size: 1.3em)[Call them out.]

#v(0.6em)
#text(fill: leise)[
  Everything worth writing on the board goes on the board.
]

== Third go: put numbers on them

#speaker-note[
  Ten minutes, in fours now, because the arithmetic is worth arguing over.
  This is the longest burst of the hour, and the one where somebody will
  discover their factor-of-two rule was generous.
]

#class-clock(10)

#text(size: 1.3em)[Now guess a number for each one. Ten minutes.]

#v(0.5em)
#text(fill: leise)[
  Fours. Wrong by a factor of two is fine. Wrong by a factor of ten is a
  question worth asking out loud.
]

// ═══════════════════════════════════════════════════════════════════════════
//  Landing it

= What we got

== The number

#speaker-note[
  Take three answers, write all three, and do not rank them. The interesting
  thing is the *spread*, and the spread is the lesson.
]

#text(size: 1.3em)[Three groups, three numbers.]

#v(0.6em)
#anim(at: "2-", text(size: 2em, fill: zahl)[within a factor of ten])
#v(0.4em)
#anim(at: "3-")[
  Which is what the method promises, and all it promises.
]

== Last go: what would you check first?

#speaker-note[
  Four minutes, and then the bell. They should leave with the one number they
  most distrust, not with an answer.
]

#class-clock(4)

#text(size: 1.3em)[
  Of all your guesses, which one would you look up first?
]

#v(0.5em)
#text(fill: leise)[
  One sentence on a slip of paper. Four minutes.
]
