# OneAquaHealth demo video

The hackathon demo video (about 3:25, 1920x1080, 30 fps), made in code with
[Remotion](https://www.remotion.dev). White background throughout, Ripple's
Piper voice, burned-in captions, and "Before" (old app) vs "Now" (new app)
phone frames side by side. The scene-by-scene script is in
[`script.md`](script.md); its source of truth is [`src/scenes.json`](src/scenes.json).

## Render

Needs Node 20+, ffmpeg/ffprobe, Python 3 with `venv`, and network access on the
first run (npm packages, the Piper voice, the official logo).

```bash
cd submission/video
npm install
npm run render      # -> out/onehealth-demo.mp4 (H.264 + AAC) and out/captions.srt
```

`npm run render` runs three steps, which can also be run alone:

| Step | Command | What it does |
|---|---|---|
| Narration | `npm run audio` | Creates a throwaway Piper virtualenv in `.work/piper/`, downloads `en_GB-alba-medium`, and writes one WAV plus a sentence-timing JSON per scene into `audio/`, reusing `scripts/narration/generate_narration.py`. Cached until `scenes.json` changes. |
| Assets | `npm run assets` | Copies the screenshots into `public/generated/`, applies the redactions, fetches the logo, sizes each scene to its narration, and writes `src/generated.ts`, `out/captions.srt` and `out/timeline.json`. |
| Video | `npx remotion render ...` | Renders the composition, then checks the file is under 200 MB. |

For a quick look without a full render: `npm run stills` writes one PNG per
scene to `out/stills/` (`node scripts/stills.mjs 0.3 shot-04-sign-in` picks a
point in the scene and specific scenes), and `npm run studio` opens Remotion's
live preview.

`out/`, `audio/`, `public/generated/`, `src/generated.ts`, `.work/` and
`node_modules/` are generated and git-ignored.

## Inputs

Screenshots are read from outside the repo and never committed:

- **Old app:** `OAH_OLD_DIR`, default
  `/workspaces/firstmate/projects/onehealth-ui/docs/current_ui_snippet/`:
  24 screenshots, numbered 1-24 in filename sort order.
- **New app:** `OAH_NEW_DIR`, default
  `/workspaces/firstmate/projects/onehealth-ui/docs/video-new/`, or
  `/workspaces/firstmate/data/oah-video/screens/` when only that one has files:
  named by shot number from the shot list (`01a.png`, `01b.png`, `04a.png`,
  ...; any name that starts with the two-digit shot number works). Several
  stills for one shot are shown in name order with a crossfade. Short clips
  (`.mp4`/`.mov`) are used instead of stills for shots 02, 09, 11 and 13 when
  present. A shot with no material shows a clearly labelled placeholder
  card, so the timeline can be reviewed before every screenshot exists.

| Shot | Now (new app) | Before (old #) |
|---|---|---|
| 01 | Splash with Ripple, first onboarding screen | 1, 2, 3 |
| 02 | Onboarding 1-5 with read-aloud highlighting | none |
| 03 | Language picker, Arabic right-to-left | 5 |
| 04 | Sign-in friendly error (`04a`, shown in the wipe), avatar picker | 22, 21, 23 |
| 05 | Map, pin preview, site page with timeline | 6, 7, 8 |
| 06 | Picture-choice question (`06a`, shown in the wipe), "Not sure" | 10, 11 |
| 07 | Glossary sheet, riparian questions | 12 |
| 08 | Overall health, feelings with N/A | 13, 14, 15 |
| 09 | Camera panel, retake hint | 9 |
| 10 | Review with completeness meter (`10a`, shown in the wipe) | 16 |
| 11 | Celebration and impact receipt | none |
| 12 | Offline pending, then sent | none |
| 13 | My Streams, profile, badges | 20, 19, 17, 18 |
| 14 | Settings: reminders | none |

### Redactions

Only login details are hidden, with solid bars burned into the copied
pixels (not a reversible blur): the account email on old #17 and #18, and
the password field on old #23. Coordinates are in `REDACTIONS` in
`scripts/prepare-assets.mjs`. Nothing else is blurred or covered.

### Zoom callouts

A scene can magnify one detail of its "Now" screenshot by adding
`"zoom": {"index": 0, "x": 0.5, "y": 0.32, "scale": 2.4}` to it in
`scenes.json` (`index` is the still, `x`/`y` are fractions of its width and
height). Set these only once the real screenshot is in place.

### Facts on screen

The short "Before"/"Now" notes beside the phones (`beforeFact`, `nowFact`)
quote only what the screenshots show, such as the old `"API call error (401)"`
message or the five "Select File" buttons on old #9. No numbers are invented.

## Credits and licences

- **Logo:** the official OneAquaHealth logo, used unmodified on the opening
  and closing cards only. It is downloaded at render time from
  <https://www.oneaquahealth.eu/app/uploads/2022/12/OneAquaHealth-Logo.svg>
  (the vector original, linked from oneaquahealth.eu) and is not committed.
- **Ripple:** drawn in `src/Ripple.tsx` from the design board's vector renders
  of the app's mascot moods (`lib/core/mascot/aqua_mascot.dart`), with the
  board's wave gesture.
- **Voice:** Piper `en_GB-alba-medium`, CC BY 4.0, credited on the end card.
- **Map data:** © OpenStreetMap contributors, tiles by OpenFreeMap (credited on
  the end card, for the map screenshots).
- **Fonts:** Baloo 2 (headings) and Noto Sans (body, captions), SIL Open Font
  Licence, via Fontsource.
- **Icons:** Phosphor (MIT), as in the app.
- **Remotion:** source-available under the Remotion License. Its Free License
  (checked against the `remotion@4.0.533` `LICENSE.md`) covers individuals,
  for-profit organizations with up to 3 employees and non-profits, for
  commercial or non-commercial video creation. Larger for-profit companies
  need a Company License.
