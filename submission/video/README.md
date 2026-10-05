# OneAquaHealth demo video

The hackathon demo video (about 3:16, 1920x1080, 30 fps), made in code with
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
| Assets | `npm run assets` | Copies the screenshots into `public/generated/`, applies the old-app redactions, fetches the logo, sizes each scene to its narration, and writes `src/generated.ts`, `out/captions.srt` and `out/timeline.json`. |
| Video | `npx remotion render ...` | Renders the composition, then checks the file is under 200 MB. |

For a quick look without a full render: `npm run stills` writes one PNG per
scene to `out/stills/` (`node scripts/stills.mjs 0.3 shot-04-sign-in` picks a
point in the scene and specific scenes), and `npm run studio` opens Remotion's
live preview.

`out/`, `audio/`, `public/generated/`, `src/generated.ts`, `.work/` and
`node_modules/` are generated and git-ignored.

## Inputs

- **Old app:** `OAH_OLD_DIR`, default
  `/workspaces/firstmate/projects/onehealth-ui/docs/current_ui_snippet/`:
  24 screenshots, numbered 1-24 in filename sort order. Read at render time,
  never committed.
- **New app:** the captain's own phone screenshots, committed under
  `screens/new/` with shot names (`01a.png`, `04b.png`, ...). Each scene lists
  the stills it shows in its `now` array in `src/scenes.json`; several stills
  crossfade in order.

### Swapping in new screenshots

The shot-to-file mapping lives in one place, `SHOTS` in
`scripts/import_new_shots.py`. When fresh screenshots arrive:

1. Point `SHOTS` at the new files (`OAH_CAPTAIN_DIR` sets the source folder,
   default `/workspaces/firstmate/data/oah-video/`).
2. Update `REDACTIONS` (the sign-in email box) and `TAP_DOTS` for the new
   images, or empty `TAP_DOTS` if "show taps" was off.
3. `python3 scripts/import_new_shots.py` (needs Pillow and NumPy), then
   `npm run render`. Adjust `now`, `zoom` and the narration in
   `src/scenes.json` if a scene gains or loses a screen.

The import makes only two edits: the email bar on `04a`, and removal of
Android's "show taps" dots (the phone's touch indicator, not app content).
A dot is removed by inverting its alpha blend with the indicator sprite
measured from these screenshots (`scripts/tap-dot-sprite.png`); its thin,
nearly opaque ring is filled in from the pixels around it. It also writes the
six README stills (`screens/01-onboarding-purpose.png` ...).

| Scene | Now (`screens/new/`) | Before (old #) |
|---|---|---|
| Welcome | 01a first onboarding screen (no splash shot) | 1, 2, 3 |
| Onboarding | 02a-02d onboarding 2-5, with Listen and the safety reminder | none |
| Language | 03a language picker | 5 |
| Sign-in | 04a friendly error (wipe and zoom), 04b avatar picker | 22, 21, 23 |
| Map | 05a map with pin preview, 05b "Which stream?" | 6, 7, 8 |
| Questions | 06a Yes / No / I'm not sure (wipe), 06b water height | 10, 11, 12 |
| Overall health | 08a overall assessment | 13, 14 |
| Photos | 09a "Photograph the stream" (wipe) | 9 |
| Submitted | 11a "Stream check submitted" | none |
| Profile | 13a weekly rhythm and evidence badges | 20, 19, 17, 18 |

### Redactions

Only login details are hidden, with solid bars burned into the pixels (not a
reversible blur): the account email on old #17 and #18 and the password field
on old #23 (`REDACTIONS` in `scripts/prepare-assets.mjs`), and the account
email in the new sign-in screenshot `04a` (`REDACTIONS` in
`scripts/import_new_shots.py`, burned into the committed copy). Nothing else
is blurred or covered.

### Zoom callouts

A scene can magnify one detail of its "Now" screenshot with
`"zoom": {"index": 0, "x": 0.5, "y": 0.32, "scale": 1.5}` in `scenes.json`
(`index` is the still in `now`, `x`/`y` are fractions of its width and
height). The magnifier shows only while that still is on screen.

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
