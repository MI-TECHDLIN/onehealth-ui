# Onboarding narration generation

Produces the natural-voice narration the onboarding read-aloud control plays:
one Ogg Opus file plus a word-timing JSON sidecar per screen, under
`assets/audio/onboarding/<locale>/<screenId>.{ogg,json}`.

This is a **content-build tool**, not part of the Flutter app. It runs once
(per language) to produce committed asset files; the app only ever plays the
resulting `.ogg` files and reads the `.json` sidecars. Do not add a Flutter
or Dart SDK here, and do not run this from app code.

## Why Piper

The design report (`oah-design-preview`) evaluated on-device OS TTS, an
on-device neural model, and pre-generated Piper audio, and chose Piper:
citizen-science fieldwork happens outdoors on uncertain connectivity, so the
app should only ever play a small bundled file with zero runtime synthesis
cost. English narration uses Piper's `en_GB-alba-medium` voice (CC BY 4.0,
trained on University of Edinburgh CSTR Voice Cloning Toolkit data) --
credited on the app's Credits list in `lib/core/credits/third_party_credits.dart`.

## One-time setup

Piper is a Python tool. Install it in a throwaway virtualenv, never in the
Flutter project itself:

```bash
python3 -m venv /tmp/piper-venv
source /tmp/piper-venv/bin/activate
pip install --upgrade pip
pip install "piper-tts[alignment]"   # [alignment] pulls in `onnx`, needed for word timing
```

Encoding to Ogg Opus needs `ffmpeg` on PATH (e.g. `apt-get install ffmpeg` /
`brew install ffmpeg`).

Download a voice (English shown; see the Piper voice catalogue for others):

```bash
BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium"
mkdir -p /tmp/piper-voices/en_GB-alba-medium
curl -sL -o /tmp/piper-voices/en_GB-alba-medium/en_GB-alba-medium.onnx "$BASE/en_GB-alba-medium.onnx"
curl -sL -o /tmp/piper-voices/en_GB-alba-medium/en_GB-alba-medium.onnx.json "$BASE/en_GB-alba-medium.onnx.json"
```

Only use a voice whose dataset/model licence is on the design report's
approved list (MIT, Apache-2.0, ISC, SIL OFL, CC0, CC BY) -- check the
voice's `MODEL_CARD` file in the same directory before shipping it.

## Regenerating

```bash
source /tmp/piper-venv/bin/activate
python scripts/narration/generate_narration.py \
  --voice-model /tmp/piper-voices/en_GB-alba-medium/en_GB-alba-medium.onnx \
  --out-dir assets/audio/onboarding/en
```

Edit the `SCREENS` list at the top of `generate_narration.py` first if
onboarding copy changed -- its text **must** stay byte-for-byte identical to
the strings in `lib/l10n/app_en.arb` (`onboarding*Headline`/`*Body`/`*Point*`
keys) and to `lib/features/onboarding/onboarding_content.dart`'s page order,
since the sidecar's word list is what `ReadAloudHighlightedText` lines up
against the on-screen text by index.

## Adding another language

1. Download that language's approved voice (see the design report's vetted
   voice manifest) into its own `/tmp/piper-voices/<voice>/` directory.
2. Duplicate the `SCREENS` list with that language's reviewed translations
   (never ship a machine-translated-only narration -- the report requires a
   native-speaker review pass before a locale's narration ships).
3. Run the script with `--voice-model` pointing at that voice and `--out-dir
   assets/audio/onboarding/<languageCode>`.
4. Add the new output directory to `pubspec.yaml`'s `flutter.assets` list.

`ReadAloudService.load` already resolves narration by
`assets/audio/onboarding/<locale.languageCode>/<narrationId>`, and hides the
read-aloud control entirely when no file exists for the current locale --
there is no other wiring needed once the files are in place.

## How word timing works

Piper's `PiperVoice.load(..., include_alignments=True)` (needs the `onnx`
package) patches the voice model in memory so `synthesize(text,
include_alignments=True)` returns per-phoneme sample counts alongside the
audio. This script sums those into per-word spans by treating each
phonemized space as a word boundary.

**Known limitation, worth knowing before you regenerate:** espeak-ng's
English front end sometimes merges a short function-word pair into one
phonemized unit with no space between them -- for example "on the" inside
"Stay on the bank." comes back as a single `ɒnðə` block, one fewer boundary
than the sentence has words. When a sentence's boundary count doesn't match
its word count, this script falls back to splitting that one sentence's
measured audio duration across its words proportionally to word length
(character count) rather than guessing wrong boundaries. The sidecar's
top-level `"alignment"` field records which happened: `"piper-phoneme"`
(every word timed from real phoneme alignment) or
`"piper-phoneme-fallback"` (at least one sentence used the proportional
fallback). `assets/audio/onboarding/en/dataJourney.json` ships with the
fallback today, for exactly the "Stay on the bank." case above -- the
highlight will be close but not phoneme-exact for those four words.
