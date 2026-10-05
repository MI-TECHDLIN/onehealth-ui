#!/usr/bin/env python3
"""Generate Piper narration audio + word-timing sidecars for the round-4
assessment question flow and its tap-to-explain glossary.

See `generate_narration.py` (onboarding's script) for the Piper setup and
regeneration instructions -- this reuses its synthesis pipeline so the two
narrated flows stay byte-for-byte consistent. One `.ogg`/`.json` pair is
produced per entry in SCREENS, under
`assets/audio/assessment/<locale>/<id>.{ogg,json}`.

Every SCREENS entry's text **must** stay byte-for-byte identical to the
matching English copy in `assets/data/assessment-content.json` (for
question/option text) or `lib/l10n/app_en.arb` (for glossary copy), since
`ReadAloudHighlightedText` lines up the sidecar's word list against the
on-screen text by index. Only the `prompt` segment of each question is
ever rendered with word-highlighting today (see
`lib/features/check/widgets/question_frame.dart`) -- the `options`
segment still ships full audio coverage per the build brief, it just has
no on-screen highlight consumer yet.

Usage (from the repo root, inside the Piper virtualenv):
    python scripts/narration/generate_assessment_narration.py \\
        --voice-model /path/to/en_GB-alba-medium.onnx \\
        --out-dir assets/audio/assessment/en
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_narration import synthesize_screen  # noqa: E402
from piper import PiperVoice  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT_DIR = REPO_ROOT / "assets" / "audio" / "assessment" / "en"

_NOT_SURE = "I'm not sure"


def _options(*labels: str, not_sure: bool = True) -> str:
    all_labels = list(labels) + ([_NOT_SURE] if not_sure else [])
    return ". ".join(all_labels) + "."


SCREENS = [
    dict(
        id="channelForm",
        segments=[
            ("prompt", "The channel form is..."),
            ("options", _options("Flat (A)", "U Shape (B)", "V Shape (C)")),
        ],
    ),
    dict(
        id="bottomChannelType",
        segments=[
            ("prompt", "The bottom of the wet channel is…"),
            (
                "options",
                _options(
                    "Natural (A)",
                    "Artificial (concrete or stones with concrete) (B)",
                ),
            ),
        ],
    ),
    dict(
        id="banksChannelType",
        segments=[
            ("prompt", "The banks of the channel are…"),
            (
                "options",
                _options(
                    "Natural (A)",
                    "Artificial (concrete or stones with concrete) (B)",
                    "Layed stones with no concrete (C)",
                ),
            ),
        ],
    ),
    dict(
        id="habitats",
        segments=[
            ("prompt", "Are there any habitats present?"),
            (
                "options",
                _options(
                    "Sand banks (A)",
                    "Sand islands (B)",
                    "Stone deposits (C)",
                    "Riffles, rapids, falls (D)",
                    "Aquatic vegetation (E)",
                    not_sure=False,
                ),
            ),
        ],
    ),
    dict(
        id="fallenBiomassTypes",
        segments=[
            ("prompt", "Are there any natural debris present?"),
            (
                "options",
                _options(
                    "Fallen trees (A)",
                    "Fallen branches (B)",
                    "Deposits of fallen leaves (C)",
                    not_sure=False,
                ),
            ),
        ],
    ),
    dict(
        id="waterFlow",
        segments=[
            ("prompt", "How is the water flowing"),
            (
                "options",
                _options(
                    "Fast (with waves or high velocity) (A)",
                    "Slow (B)",
                    "Stagnant/intermittent (C)",
                    "Dry (D)",
                ),
            ),
        ],
    ),
    dict(
        id="waterColor",
        segments=[
            ("prompt", "How is the water?"),
            (
                "options",
                _options(
                    "Clear/transparent (A)",
                    "Muddy/turbid (B)",
                    "Has foam (C)",
                    "Has colors/altered color (D)",
                ),
            ),
        ],
    ),
    dict(
        id="waterAbstraction",
        segments=[
            (
                "prompt",
                "Is there any kind of obvious water collection, use, removal "
                "from the stream?",
            ),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="hasDams",
        segments=[
            (
                "prompt",
                "Do you see any dams or other transversal artificial "
                "barriers (see some examples in images provided)?",
            ),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="pipes",
        segments=[
            ("prompt", "Are there pipes draining polluted water into the stream?"),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="waterDischarge",
        segments=[
            ("prompt", "Is there any kind of water entry or discharge of sewage?"),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="construction",
        segments=[
            ("prompt", "Is there any construction/works in stream?"),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="waterHeight",
        segments=[
            ("prompt", "What is the water height?"),
            (
                "options",
                "Please give your estimate in meters, use a dot as decimal "
                "point, for example one point five meters.",
            ),
        ],
    ),
    dict(
        id="downstreamPrimer",
        segments=[
            ("prompt", "Facing downstream"),
            (
                "options",
                "Left and right are defined as you face downstream, the "
                "direction the water is flowing.",
            ),
        ],
    ),
    dict(
        id="imperviousAreas",
        segments=[
            ("prompt", "Impervious Areas (Left)"),
            (
                "options",
                "Is more than one third of the left margin covered by "
                "impervious areas, such as roads, sidewalks or buildings? "
                "Yes. No. I'm not sure. Impervious Areas (Right). Is more "
                "than one third of the right margin covered by impervious "
                "areas, such as roads, sidewalks or buildings? Yes. No. "
                "I'm not sure.",
            ),
        ],
    ),
    dict(
        id="vegetationCoverage",
        segments=[
            ("prompt", "Vegetation (Left)"),
            (
                "options",
                "Is the left margin covered by vegetation? Yes. No. I'm "
                "not sure. Vegetation (Right). Is the right margin covered "
                "by vegetation? Yes. No. I'm not sure.",
            ),
        ],
    ),
    dict(
        id="hasInvasivePlantSpecies",
        segments=[
            ("prompt", "Do you see any non-native or invasive plant species?"),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="recentVegetationCuts",
        segments=[
            (
                "prompt",
                "Have there been recent cuts if vegetation (partial or "
                "total) on the banks (or just one of the banks) of the "
                "stream?",
            ),
            ("options", _options("Yes", "No")),
        ],
    ),
    dict(
        id="overallAssessment",
        segments=[
            (
                "prompt",
                "Provide an overall assessment of the stream ecosystem "
                "health (choose one of the below possibilities)",
            ),
            (
                "options",
                "Good quality. The ecosystem components are there: "
                "riparian vegetation, natural channel, good water "
                "quality, biodiversity. Moderate quality. Some "
                "alterations, still biodiverse, with vegetation in the "
                "margins, water looks good. Poor quality. Highly modified "
                "slash artificialized, loss of riparian vegetation, loss "
                "of habitats, polluted.",
            ),
        ],
    ),
    dict(
        id="feelings",
        segments=[
            ("prompt", "Which feeling(s) best describe your experience?"),
            (
                "options",
                "Research indicates that streams may influence human "
                "emotions. Drag your fingers on the slider to rate the "
                "intensity of what you are feeling. A higher rating means "
                "more intense feeling. Joy. Serenity. Anger. Fear.",
            ),
        ],
    ),
    dict(
        id="glossary_channel",
        segments=[
            (
                "prompt",
                "The channel is the path water flows through. Its shape "
                "and materials, natural or artificial, affect how healthy "
                "the stream can be.",
            ),
        ],
    ),
    dict(
        id="glossary_substrate",
        segments=[
            (
                "prompt",
                "Substrate is the material lining the streambed, like "
                "rock, gravel, concrete, or sand. It's what you're "
                "looking at when you check the channel's bottom.",
            ),
        ],
    ),
    dict(
        id="glossary_bank",
        segments=[
            (
                "prompt",
                "The bank is the sloped edge of the channel, between the "
                "water and the surrounding land.",
            ),
        ],
    ),
    dict(
        id="glossary_riparianZone",
        segments=[
            (
                "prompt",
                "The riparian zone, also called the margin, is the strip "
                "of land alongside a stream, usually covered by plants "
                "adapted to living near water.",
            ),
        ],
    ),
    dict(
        id="glossary_invasiveSpecies",
        segments=[
            (
                "prompt",
                "An invasive species is a non-native plant or animal that "
                "spreads aggressively and can crowd out the local wildlife "
                "a healthy stream depends on.",
            ),
        ],
    ),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice-model", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    voice = PiperVoice.load(str(args.voice_model), include_alignments=True)
    for screen in SCREENS:
        synthesize_screen(voice, screen, args.out_dir)


if __name__ == "__main__":
    main()
