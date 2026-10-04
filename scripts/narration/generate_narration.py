#!/usr/bin/env python3
"""Generate Piper narration audio + word-timing sidecars for onboarding.

See scripts/narration/README.md for setup (Piper install, voice download)
and regeneration instructions. Re-run this whenever onboarding copy changes,
or copy its SCREENS/segment pattern to add a new locale or narrated flow
(for example the assessment questions).

Usage (from the repo root, inside the Piper virtualenv described in the
README):
    python scripts/narration/generate_narration.py \\
        --voice-model /path/to/en_GB-alba-medium.onnx \\
        --out-dir assets/audio/onboarding/en
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from piper import PiperVoice

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT_DIR = REPO_ROOT / "assets" / "audio" / "onboarding" / "en"
SENTENCE_SILENCE_MS = 320
VOICE_ID = "en_GB-alba-medium"

# Each screen is an ordered list of (segment_id, text) pairs. segment_id
# matches the id a widget passes to ReadAloudHighlightedText so on-screen
# highlighting can resolve its slice of the shared word-index space.
SCREENS = [
    dict(
        id="problem",
        segments=[
            ("headline", "Your stream is part of city health"),
            (
                "body",
                "Urban streams connect people, wildlife and plants. When a "
                "stream struggles, the effects can reach the whole "
                "neighbourhood.",
            ),
        ],
    ),
    dict(
        id="oneHealth",
        segments=[
            ("headline", "One stream. Many lives."),
            (
                "body",
                "One Health means ecosystem, animal and human health are "
                "connected. Caring for one helps us understand the others.",
            ),
        ],
    ),
    dict(
        id="fieldCheck",
        segments=[
            ("headline", "Look, photograph, answer"),
            (
                "body",
                "Ripple helps you capture the stream, its banks and "
                "biodiversity, then answer simple picture-based questions. "
                "About 8 to 12 minutes.",
            ),
        ],
    ),
    dict(
        id="dataJourney",
        segments=[
            ("headline", "Your data reaches researchers"),
            (
                "body",
                "Standardised observations add local detail to a growing "
                "evidence base, helping teams monitor change and "
                "investigate early-warning indicators.",
            ),
            (
                "safety",
                "A quick safety reminder. Stay on the bank. Never enter "
                "the water. Watch for slippery or steep banks. Children "
                "check streams with an adult. Skip the check in bad "
                "weather or high water.",
            ),
        ],
    ),
    dict(
        id="getStarted",
        segments=[
            ("headline", "Ready when you are"),
            (
                "body",
                "Check a nearby stream now, or explore the map first. You "
                "can review safety tips before every visit.",
            ),
        ],
    ),
]


@dataclass
class WordSpan:
    text: str
    start_ms: int
    end_ms: int


def word_tokens(text: str) -> list[str]:
    return text.split()


def align_sentence(
    alignments, sample_rate: int, base_samples: int
) -> tuple[list[WordSpan], int, int]:
    """Map one sentence's Piper phoneme alignments to per-word spans.

    Returns (spans, word_count_from_alignment, total_samples).
    """
    groups: list[tuple[str, int]] = []
    current = 0
    started = False
    for a in alignments:
        if a.phoneme == "^":
            continue
        if a.phoneme == "$":
            if started:
                groups.append(("", current))
            break
        if a.phoneme == " ":
            if started:
                groups.append(("", current))
            current = 0
            started = False
            continue
        current += a.num_samples
        started = True
    else:
        if started:
            groups.append(("", current))

    total_samples = sum(samples for _, samples in groups)
    spans: list[WordSpan] = []
    offset = base_samples
    for _, samples in groups:
        start_ms = round(offset / sample_rate * 1000)
        offset += samples
        end_ms = round(offset / sample_rate * 1000)
        spans.append(WordSpan("", start_ms, end_ms))
    return spans, len(groups), total_samples


def fallback_spans(
    words: list[str], total_samples: int, base_samples: int, sample_rate: int
) -> list[WordSpan]:
    weights = [max(1, len(w)) for w in words]
    total_weight = sum(weights)
    spans = []
    offset = base_samples
    for word, weight in zip(words, weights):
        samples = round(total_samples * weight / total_weight)
        start_ms = round(offset / sample_rate * 1000)
        offset += samples
        end_ms = round(offset / sample_rate * 1000)
        spans.append(WordSpan(word, start_ms, end_ms))
    return spans


def synthesize_sentence(
    voice: PiperVoice, sentence: str, sample_rate: int, offset_samples: int
) -> tuple[list[WordSpan], np.ndarray, bool]:
    chunk_audio = None
    chunk_alignments = None
    for chunk in voice.synthesize(sentence, include_alignments=True):
        chunk_audio = chunk.audio_int16_array
        chunk_alignments = chunk.phoneme_alignments
    if chunk_audio is None:
        return [], np.zeros(0, dtype=np.int16), False

    words = word_tokens(sentence)
    if chunk_alignments is not None:
        spans, word_count, consumed = align_sentence(
            chunk_alignments, sample_rate, offset_samples
        )
        if word_count == len(words) and consumed > 0:
            for span, word in zip(spans, words):
                span.text = word
            return spans, chunk_audio, False

    return (
        fallback_spans(words, len(chunk_audio), offset_samples, sample_rate),
        chunk_audio,
        True,
    )


def synthesize_screen(voice: PiperVoice, screen: dict, out_dir: Path) -> None:
    sample_rate = voice.config.sample_rate
    silence_samples = round(sample_rate * SENTENCE_SILENCE_MS / 1000)

    all_samples: list[np.ndarray] = []
    all_spans: list[WordSpan] = []
    segment_word_counts: list[tuple[str, int]] = []
    used_fallback = False
    offset_samples = 0

    for segment_id, segment_text in screen["segments"]:
        segment_word_count = 0
        sentences = [s for s in re.split(r"(?<=[.!?])\s+", segment_text) if s]
        for sentence in sentences:
            spans, audio, fallback = synthesize_sentence(
                voice, sentence, sample_rate, offset_samples
            )
            used_fallback = used_fallback or fallback
            all_spans.extend(spans)
            segment_word_count += len(spans)
            all_samples.append(audio)
            offset_samples += len(audio)
            silence = np.zeros(silence_samples, dtype=np.int16)
            all_samples.append(silence)
            offset_samples += silence_samples
        segment_word_counts.append((segment_id, segment_word_count))

    full_audio = np.concatenate(all_samples)

    out_dir.mkdir(parents=True, exist_ok=True)
    wav_path = out_dir / f"{screen['id']}.wav"
    with wave.open(str(wav_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(full_audio.tobytes())

    ogg_path = out_dir / f"{screen['id']}.ogg"
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-c:a", "libopus", "-b:a", "32k", "-vbr", "on",
            "-application", "voip",
            str(ogg_path),
        ],
        check=True,
    )
    wav_path.unlink()

    duration_ms = round(offset_samples / sample_rate * 1000)
    sidecar = {
        "id": screen["id"],
        "locale": "en",
        "voice": VOICE_ID,
        "sampleRate": sample_rate,
        "durationMs": duration_ms,
        "segments": [
            {"id": seg_id, "words": count} for seg_id, count in segment_word_counts
        ],
        "words": [span.text for span in all_spans],
        "timings": [{"start": span.start_ms, "end": span.end_ms} for span in all_spans],
        "alignment": "piper-phoneme-fallback" if used_fallback else "piper-phoneme",
    }
    json_path = out_dir / f"{screen['id']}.json"
    json_path.write_text(json.dumps(sidecar, indent=2) + "\n", encoding="utf-8")
    print(
        f"{screen['id']}: duration={duration_ms}ms words={len(all_spans)} "
        f"segments={segment_word_counts} fallback={used_fallback}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--voice-model",
        type=Path,
        required=True,
        help="Path to the Piper .onnx voice model (its .onnx.json config "
        "must sit alongside it).",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_OUT_DIR,
        help=f"Output directory for .ogg/.json pairs (default: {DEFAULT_OUT_DIR}).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    voice = PiperVoice.load(str(args.voice_model), include_alignments=True)
    for screen in SCREENS:
        synthesize_screen(voice, screen, args.out_dir)


if __name__ == "__main__":
    main()
