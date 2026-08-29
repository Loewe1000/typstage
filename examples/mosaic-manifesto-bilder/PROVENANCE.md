# Where these images come from

The four pictures in `mosaic-manifesto.typ` stand in for the photographs of the
*Minimalist White Slides* template by SlidesCarnival, which this deck is
modelled on. **None of the template's photographs are used here**, and none of
them are redistributed with this package.

The template's layouts are CC BY 4.0 and are credited in the deck header. Its
photographs are not credited per file, so they cannot be carried over
responsibly.

## What these files are

Synthetic images, generated on **29 August 2026** with OpenAI's `gpt-image-2`
through the OpenAI Images API at quality `low`. Nothing was traced, sampled or
reproduced from an existing photograph.

Each was generated as a PNG, resized with Lanczos so the long edge is 820 px,
and then reduced to a **true duotone** with Pillow: the tonal range is stretched
with `autocontrast` and mapped through a 256-step ramp from `#5e160f` in the
shadows to `#fffcf9` in the highlights. What is left is one colour. That is not
cosmetic — the deck's argument is a poster in a single ink, and a photograph
carrying a second colour would be the one thing on the slide that breaks it.
Saved as WebP at quality 74.

## No faces

The template's own pictures are stock portraits and meeting scenes. These four
keep the subject — people at work — and drop the faces: hands on a table seen
from above, a circle of arms from above, a room seen from behind. Nobody in
them is identifiable, and nobody is meant to be. A synthetic portrait would put
a face that belongs to no one in front of a room.

## The prompts

| File | What it shows | Prompt |
| --- | --- | --- |
| `table.webp` | Six pairs of hands and forearms reaching onto a wooden meeting table from every edge; notebooks, cups, a phone. No heads. | A photograph looking straight down onto a wooden meeting table. Six pairs of hands and forearms reach in from the edges of the frame: some resting on notebooks, one holding a pen, two clasped together in the middle. Coffee cups, a couple of closed notebooks and a phone lie on the table. Only hands, sleeves and forearms are visible — no faces, no heads, no shoulders, nobody identifiable. Plain everyday clothing, no visible text, no logos, no brand names, no screens showing content. Neutral daylight, warm oak table, calm documentary office photography, natural grain. |
| `hands.webp` | A ring of people seen from straight above, arms reaching in so the hands meet in the middle; a wooden floor, a table at the edge. | A photograph looking straight down from above onto a group of people standing in a loose circle, all reaching their arms up towards the centre so that their hands meet high in the middle of the frame — a team gesture. Seen sharply from overhead, so heads are foreshortened and no faces are visible at all; nobody identifiable. Plain everyday clothes in muted colours. They stand on a pale wooden floor beside a table with a couple of chairs. No text, no logos, no brand names, no screens. Even daylight, calm documentary photography, natural grain. |
| `team.webp` | A small team at a long table, seen from behind and above; blank laptop screens, a window on the left. | A photograph of a small team working around a long table in a bright plain room, seen from behind and slightly above so that only backs, shoulders and the backs of heads are visible — no faces at all, nobody identifiable. Open laptops with blank dark screens, notebooks and paper cups on the table; a large window on the left throwing even daylight across the room. Plain white walls, no pictures, no text, no logos, no writing on any surface. Muted everyday clothing. Calm documentary workplace photography, natural grain, soft contrast. |
| `desk.webp` | One pair of hands writing in a blank notebook, seen from above; a closed laptop, a cup, glasses, loose paper. | A photograph looking straight down onto a desk from above: one pair of hands writing in an open notebook with a pen, a closed laptop pushed to one side, a cup of coffee, a pair of reading glasses and a few loose sheets of blank paper. Only hands and forearms in frame — no face, no head, nobody identifiable. Nothing carries text: the notebook page is blank, no logos, no brand names, no printed words anywhere. Warm wooden desk, even soft daylight from one side, calm documentary photography, fine natural grain. |

## Licence

These files are part of this repository and carry its licence (MIT). They are
not part of the published package: `examples/` is excluded in `typst.toml`.
