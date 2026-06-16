#!/usr/bin/env bash
# Convert all .HEIC files under photo/ to web-friendly .jpg files.
# Uses pillow-heif because ffmpeg/heif-convert often fail on iPhone HDR HEIC.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHOTO_DIR="${PHOTO_DIR:-$SCRIPT_DIR/photo}"
VENV_DIR="${VENV_DIR:-$SCRIPT_DIR/.tools/heif-venv}"
PYTHON="${VENV_DIR}/bin/python"

if [[ ! -d "$PHOTO_DIR" ]]; then
  echo "Photo directory not found: $PHOTO_DIR" >&2
  exit 1
fi

if [[ ! -x "$PYTHON" ]]; then
  echo "Setting up HEIC converter environment..."
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install -q --upgrade pip pillow pillow-heif
fi

shopt -s nullglob nocaseglob
heic_files=("$PHOTO_DIR"/*.HEIC)
if [[ ${#heic_files[@]} -eq 0 ]]; then
  echo "No .HEIC files found in $PHOTO_DIR"
  exit 0
fi

"$PYTHON" - "$PHOTO_DIR" "${heic_files[@]}" <<'PY'
import sys
from pathlib import Path

import pillow_heif
from PIL import Image

pillow_heif.register_heif_opener()

photo_dir = Path(sys.argv[1])
files = [Path(p) for p in sys.argv[2:]]

converted = skipped = failed = 0

for heic in files:
    jpg = heic.with_suffix(".jpg")
    if jpg.exists() and jpg.stat().st_mtime >= heic.stat().st_mtime:
        print(f"skip: {jpg.name} (already up to date)")
        skipped += 1
        continue

    print(f"convert: {heic.name} -> {jpg.name}")
    try:
        with Image.open(heic) as im:
            im.save(jpg, format="JPEG", quality=90, optimize=True)
        converted += 1
    except Exception as exc:
        print(f"failed: {heic.name} ({exc})", file=sys.stderr)
        failed += 1

print(f"done: {converted} converted, {skipped} skipped, {failed} failed")
sys.exit(1 if failed else 0)
PY
