# Where these images come from

The nine plates in `mosaic-greyscale.typ` stand in for the photographs of the
*Photojournalist Portfolio* template by SlidesCarnival, which this deck is
modelled on. **None of the template's photographs are used here**, and none of
them are redistributed with this package.

The template's layouts are CC BY 4.0 and are credited in the deck header. Its
photographs are credited only in aggregate ("from Pexels and Pixabay"), with no
per-file provenance, so they cannot be carried over responsibly.

## What these files are

Synthetic images, generated on **27 August 2026** with OpenAI's `gpt-image-2`
through the OpenAI Images API at quality `low`. Nothing was traced, sampled or
reproduced from an existing photograph. Each was generated from the prompt
below as a PNG, then converted to true greyscale with Pillow — `.convert("L")`,
one channel, no colour information left in the pixels — resized with Lanczos
and saved as WebP at quality 74.

True greyscale is not cosmetic. The deck's argument is that one `palette:`
dictionary colours the whole thing; an image carrying colour would be the one
piece that does not follow.

Measured on the shipped files rather than assumed: over every pixel of all
nine, the largest difference between the red, green and blue channels is **1 of
255**, and the mean difference is **at most 0.009**. WebP has no greyscale
storage mode, so a reader reports the files as RGB; what it reads back is the
one `L` value written three times, to within the single step that lossy WebP's
chroma subsampling costs. There is no tint.

## Sizes

Typst inlines an image as a `data:` URI once per **use**, not once per file: a
plate that appears on three slides is in the HTML three times. Each file is
therefore stored at 820 px on its long edge, or at the long edge of the largest
cell it ever appears in, whichever is smaller — `contact.webp` is only ever a
tile in the contact sheet, so it is stored at tile size.

| File | Pixels | Bytes | Where it appears |
|---|---|---|---|
| `photographer.webp` | 820x551 | 4 176 | cover, the big number |
| `street.webp` | 820x551 | 31 976 | contents, the contact sheet, the print |
| `facade.webp` | 820x551 | 20 966 | the contact sheet, closing |
| `trays.webp` | 820x273 | 5 326 | about us |
| `pier.webp` | 383x570 | 14 254 | the pier, exhibitions |
| `darkroom.webp` | 430x640 | 6 112 | the pier, the contact sheet, exhibitions |
| `hands.webp` | 430x640 | 9 266 | hello, mission and vision |
| `alley.webp` | 430x640 | 4 860 | our best shots, exhibitions |
| `contact.webp` | 520x349 | 18 988 | the contact sheet |

## Prompts

| File | Prompt |
|---|---|
| `photographer.webp` | Black and white documentary photograph: a photographer at work, seen from directly behind, standing in the lower left of the frame and filling about a third of its height, camera raised to the eye, shoulders and elbows out, entirely a dark silhouette against bright even fog. No face, no features, nobody identifiable — only the back of a coat and the shape of the camera. Ahead: flat pale water and white haze, no horizon detail. Large areas of smooth even tone, very little texture. Pure monochrome, neutral greys, no colour tint at all. No text, no watermark, no logo. |
| `street.webp` | Black and white documentary photograph: a wet empty city street early in the morning after rain, seen down its length. Bright overcast sky, the white sky mirrored in the wet asphalt so the road is a pale band. Far away, one small human figure crossing, no bigger than a thumbnail, a dark silhouette, face not visible and nobody identifiable. Plain buildings on both sides in mid grey, haze at the far end. Mostly light and mid tones, few deep shadows, large smooth areas. Pure monochrome, neutral greys, no colour tint. No text, no signage, no watermark. |
| `facade.webp` | Black and white architectural photograph: a plain modernist concrete facade filling the whole frame, a strict regular grid of identical rectangular windows. Shot straight on, no perspective convergence, no sky, no ground, no street. Some windows dark, some pale, giving the grid a quiet rhythm. Flat even light, smooth concrete, very little surface texture. Pure monochrome, neutral greys, no colour tint. No people, no text, no watermark. |
| `trays.webp` | Black and white photograph, very wide panoramic crop: a darkroom bench in near darkness. Three shallow developing trays in a row on the right half of the frame, a print floating in the first tray catching the dim light, a pair of print tongs resting on the edge. The whole left half is deep black shadow with nothing in it. Only the trays and the wet print pick up light. Quiet, still, documentary. Pure monochrome, neutral greys, no colour tint. No people, no hands, no text, no watermark. |
| `pier.webp` | Black and white documentary photograph, vertical: a long wooden pier on piles running straight away from the camera into calm water and mist. Weathered planks and simple posts. The far end dissolves into white haze — no far shore, no boats, no building. Flat overcast light, water almost without ripple, large areas of smooth tone. Pure monochrome, neutral greys, no colour tint. No people, no text, no watermark. |
| `darkroom.webp` | Black and white photograph, vertical: a darkroom, freshly made prints pegged to a wire line to dry, hanging one behind the other. The prints are pale rectangles, their content indistinct — no faces on them. Everything else falls away into deep black shadow, one dim lamp out of frame. Simple and quiet, mostly black with a few bright shapes. Pure monochrome, neutral greys, no colour tint. No people, no text, no watermark. |
| `hands.webp` | Black and white photograph, vertical, close up: two hands loading a roll of 35 mm film into the back of an old manual camera. Only hands and camera, cropped at the wrists — no face, no arms, no person visible. Plain dark background thrown out of focus. Soft directional light on the metal top plate. Simple, few surfaces, smooth background. Pure monochrome, neutral greys, no colour tint. No text, no brand name, no watermark. |
| `alley.webp` | Black and white documentary photograph, vertical: a narrow street between tall plain buildings, looking down its length. A shaft of light falls across it far away, and one small human figure walks through it, tiny in the frame, backlit to a silhouette, no face visible and nobody identifiable. Haze in the air, walls in deep shadow, large smooth dark areas. Pure monochrome, neutral greys, no colour tint. No text, no signs, no watermark. |
| `contact.webp` | Black and white photograph seen straight down: a photographic contact sheet lying on a light table, a grid of small film frames with a magnifying loupe resting on it. The individual frames are small and their content is not readable — grey rectangles with faint shapes, no faces. Even backlight through the sheet, plain dark surround. Pure monochrome, neutral greys, no colour tint. No people, no legible text, no numbers, no watermark. |

Two motifs were generated twice and the first attempt thrown away, so those two
files are not the first thing the model returned: `photographer.webp`, because
the figure came back too small to read as somebody working, and `street.webp`,
because the first version was a night street so dark that the black plaque the
deck sets on it disappeared. The discarded files were not kept and are not in
this directory.

## People

Four of the nine images contain a human figure. None of them is a portrait of
anyone:

* `photographer.webp` — one person from behind, an unbroken black silhouette
  against fog. No face, no features, no skin, nothing identifiable.
* `street.webp` — one figure far down the street, a few pixels tall, a dark
  shape crossing the road.
* `alley.webp` — one figure at the far end of the alley, backlit, a few pixels
  tall.
* `hands.webp` — two hands on a camera, cropped at the wrists. No face, no
  arms, no person in the frame.

The other five — `facade`, `trays`, `pier`, `darkroom`, `contact` — have no
people in them at all. The prints in `darkroom.webp` and `trays.webp` and the
frames in `contact.webp` were looked at: they carry landscapes and indistinct
shapes, no faces and no legible text.

## What was deliberately not reproduced

The template's own photographs include a documentary portrait of a small child
against a wall, and several close portraits of faces. **No synthetic
documentary portrait of a recognisable person was made for this deck, and none
of a child.** Photojournalism is worth something because it shows what was
there; an invented documentary photograph asserts a reality that never existed,
and in a published example deck that is the wrong thing to ship. The slides
that carry those pictures in the template carry a pier, a darkroom, an alley
and a pair of hands here instead.

This set also replaces an earlier one — `fog`, `horizon`, `backlit`, `dunes`,
`facade` — which showed abstract landscapes: a foggy wood, a horizon, dunes.
Those were modelled on the drawn grey surfaces this deck used before, not on
the template, and the template is a photographer's portfolio in the documentary
tradition. They are gone.

## Terms

Whether and how generated images may be redistributed is governed by the terms
of the service that produced them — for these files, OpenAI's. Read those terms
rather than this paragraph; they change, and this file does not. What is stated
here is only what was done: which model, on which date, from which prompt.

If that position is ever unwelcome, the deck can go back to drawing its plates:
the geometric version stands in the history of `mosaic-greyscale.typ` and needs
no files at all.
