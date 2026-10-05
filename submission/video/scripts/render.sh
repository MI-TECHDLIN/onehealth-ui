#!/usr/bin/env bash
# Full pipeline: narration -> assets/captions -> out/onehealth-demo.mp4 (H.264 + AAC).
set -euo pipefail

video_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$video_root"

npm run audio
npm run assets
mkdir -p out

npx remotion render src/index.ts OneHealthDemo out/onehealth-demo.mp4 \
  --overwrite \
  --codec=h264 \
  --audio-codec=aac \
  --audio-bitrate=192k \
  --crf=20 \
  --pixel-format=yuv420p \
  --concurrency="${RENDER_CONCURRENCY:-50%}"

max_bytes=200000000
size_bytes="$(stat -c '%s' out/onehealth-demo.mp4)"
if (( size_bytes >= max_bytes )); then
  echo "Output is over 200 MB; re-encoding at a lower quality."
  mv out/onehealth-demo.mp4 .work/onehealth-demo-large.mp4
  ffmpeg -y -hide_banner -loglevel error -i .work/onehealth-demo-large.mp4 \
    -c:v libx264 -preset medium -crf 25 -pix_fmt yuv420p \
    -c:a aac -b:a 160k -movflags +faststart out/onehealth-demo.mp4
fi

ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 out/onehealth-demo.mp4
