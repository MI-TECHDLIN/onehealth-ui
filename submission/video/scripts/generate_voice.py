#!/usr/bin/env python3
"""Generate one Piper narration WAV plus a timing sidecar per video scene.

Reuses the app's narration pipeline (scripts/narration/generate_narration.py,
Piper en_GB-alba-medium) one sentence at a time, so every caption sentence
gets the exact start/end time of its spoken audio. `piperText` may respell
words for pronunciation; it must keep the same sentences as `captionText`.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import wave
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[3]
VIDEO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "scripts" / "narration"))

from generate_narration import SENTENCE_SILENCE_MS, VOICE_ID, synthesize_sentence  # noqa: E402
from piper import PiperVoice  # noqa: E402

SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+")


def sentences(text: str) -> list[str]:
    return [part for part in SENTENCE_SPLIT.split(text.strip()) if part]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice-model", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, default=VIDEO_ROOT / "audio")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    scenes_bytes = (VIDEO_ROOT / "src" / "scenes.json").read_bytes()
    scenes = json.loads(scenes_bytes)
    for scene in scenes:
        spoken, shown = sentences(scene["piperText"]), sentences(scene["captionText"])
        if len(spoken) != len(shown):
            raise SystemExit(f"{scene['id']}: piperText and captionText must have the same sentences")

    cache_key = hashlib.sha256(scenes_bytes + Path(__file__).read_bytes()).hexdigest()
    stamp = args.out_dir / ".script-sha256"
    expected = [args.out_dir / f"{scene['id']}.{ext}" for scene in scenes for ext in ("wav", "json")]
    if stamp.exists() and stamp.read_text().strip() == cache_key and all(p.exists() for p in expected):
        print(f"Narration is current: {len(scenes)} scenes")
        return

    voice = PiperVoice.load(str(args.voice_model))
    sample_rate = voice.config.sample_rate
    silence = np.zeros(round(sample_rate * SENTENCE_SILENCE_MS / 1000), dtype=np.int16)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    for scene in scenes:
        chunks: list[np.ndarray] = []
        cues = []
        offset = 0
        for spoken, shown in zip(sentences(scene["piperText"]), sentences(scene["captionText"])):
            _, audio, _ = synthesize_sentence(voice, spoken, sample_rate, offset)
            start_ms = round(offset / sample_rate * 1000)
            offset += len(audio)
            cues.append({"text": shown, "startMs": start_ms, "endMs": round(offset / sample_rate * 1000)})
            chunks.extend([audio, silence])
            offset += len(silence)
        with wave.open(str(args.out_dir / f"{scene['id']}.wav"), "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(np.concatenate(chunks).tobytes())
        duration_ms = round(offset / sample_rate * 1000)
        sidecar = {"id": scene["id"], "voice": VOICE_ID, "durationMs": duration_ms, "cues": cues}
        (args.out_dir / f"{scene['id']}.json").write_text(json.dumps(sidecar, indent=2) + "\n", encoding="utf-8")
        print(f"{scene['id']}: {duration_ms} ms, {len(cues)} sentences")
    stamp.write_text(cache_key + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
