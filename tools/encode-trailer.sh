#!/usr/bin/env bash
# Encode an edited cut into the web trailer. Reads a master, writes public/media/trailer.mp4.
#
#   tools/encode-trailer.sh media-src/my-edit.mov
#
# The master is never modified or moved. Nothing is deleted. If public/media/trailer.mp4 already
# exists it's kept as trailer.prev.mp4 rather than overwritten outright.
set -euo pipefail

SRC="${1:?usage: encode-trailer.sh <edited-video> [crf] [height]}"
CRF="${2:-24}"
HEIGHT="${3:-720}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public/media/trailer.mp4"

[[ -f "$SRC" ]] || { echo "no such file: $SRC"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found — brew install ffmpeg"; exit 1; }

echo "source:  $SRC"
ffprobe -loglevel error -show_entries format=duration:stream=width,height \
        -of default=noprint_wrappers=1 "$SRC" | sed 's/^/  /'

# Don't clobber a previous encode outright. The backup goes to media-src/prev/, NOT next to the
# output — anything left in public/media/ gets deployed, and a spare 20 MB copy would ship too.
PREV="$ROOT/media-src/prev"
[[ -f "$OUT" ]] && mkdir -p "$PREV" && cp "$OUT" "$PREV/trailer-$(date +%Y%m%d-%H%M%S).mp4" \
  && echo "previous kept in media-src/prev/"

echo "encoding ${HEIGHT}p30 crf${CRF}…"
ffmpeg -loglevel error -y -i "$SRC" \
  -r 30 -vf "scale=-2:${HEIGHT}" -crf "$CRF" \
  -c:v libx264 -preset medium -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart \
  "$OUT"

SIZE=$(( $(stat -f%z "$OUT") / 1048576 ))
DUR=$(ffprobe -loglevel error -show_entries format=duration -of csv=p=0 "$OUT")
printf "\ndone: public/media/trailer.mp4 — %s MB, %.0f s\n" "$SIZE" "$DUR"
[[ $SIZE -gt 20 ]] && echo "note: over 20 MB. Trim the cut, or re-run with a higher crf (e.g. 27)."
echo "master left untouched at: $SRC"
