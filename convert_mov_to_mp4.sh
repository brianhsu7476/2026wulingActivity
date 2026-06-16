#!/usr/bin/env bash
# Convert all .MOV files under photo/ to web-friendly H.264 .mp4 files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHOTO_DIR="${PHOTO_DIR:-$SCRIPT_DIR/photo}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required but not installed." >&2
  exit 1
fi

if [[ ! -d "$PHOTO_DIR" ]]; then
  echo "Photo directory not found: $PHOTO_DIR" >&2
  exit 1
fi

converted=0
skipped=0
failed=0

shopt -s nullglob nocaseglob
for mov in "$PHOTO_DIR"/*.MOV; do
  base="${mov%.*}"
  mp4="${base}.mp4"

  if [[ -f "$mp4" && "$mp4" -nt "$mov" ]]; then
    echo "skip: $(basename "$mp4") (already up to date)"
    skipped=$((skipped + 1))
    continue
  fi

  echo "convert: $(basename "$mov") -> $(basename "$mp4")"
  if ffmpeg -hide_banner -loglevel error -y -i "$mov" \
    -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    "$mp4"; then
    converted=$((converted + 1))
  else
    echo "failed: $(basename "$mov")" >&2
    failed=$((failed + 1))
  fi
done

echo "done: $converted converted, $skipped skipped, $failed failed"
