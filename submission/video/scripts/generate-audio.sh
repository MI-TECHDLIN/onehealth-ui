#!/usr/bin/env bash
# Builds the Piper narration (Ripple's voice) into audio/, one WAV + timing JSON per scene.
set -euo pipefail

video_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
work_root="$video_root/.work/piper"
venv="$work_root/venv"
voice_root="$work_root/en_GB-alba-medium"
model="$voice_root/en_GB-alba-medium.onnx"
base_url="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium"

mkdir -p "$voice_root"
if [[ ! -x "$venv/bin/python" ]]; then
  "${PYTHON:-python3}" -m venv "$venv"
  "$venv/bin/pip" install --quiet --upgrade pip
  "$venv/bin/pip" install --quiet "piper-tts[alignment]"
fi
for file in en_GB-alba-medium.onnx en_GB-alba-medium.onnx.json; do
  if [[ ! -s "$voice_root/$file" ]]; then
    curl --fail --location --retry 3 --output "$voice_root/$file" "$base_url/$file"
  fi
done

"$venv/bin/python" "$video_root/scripts/generate_voice.py" \
  --voice-model "$model" \
  --out-dir "$video_root/audio"
