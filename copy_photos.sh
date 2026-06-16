#!/usr/bin/env bash
# Copy photos/videos listed in photolist from ~/Downloads to photo/.
# photolist lines are 4-digit suffixes (e.g. 0648 -> IMG_0648.HEIC / IMG_0648.MOV).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHOTOLIST="${PHOTOLIST:-$SCRIPT_DIR/photolist}"
SRC="${SRC:-$HOME/Downloads}"
DEST="${DEST:-$SCRIPT_DIR/photo}"

mkdir -p "$DEST"

copied=0
missing=0

while IFS= read -r num || [[ -n "$num" ]]; do
  num="${num//[$'\t\r\n ']/}"
  [[ -z "$num" || "$num" == \#* ]] && continue

  found=0
  for ext in HEIC MOV; do
    src="$SRC/IMG_${num}.${ext}"
    if [[ -f "$src" ]]; then
      cp -n "$src" "$DEST/"
      echo "copied: $(basename "$src")"
      copied=$((copied + 1))
      found=1
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    echo "missing: IMG_${num}.HEIC / IMG_${num}.MOV" >&2
    missing=$((missing + 1))
  fi
done < "$PHOTOLIST"

echo "done: $copied file(s) copied, $missing list entry(ies) with no match"
