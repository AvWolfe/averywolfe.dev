#!/usr/bin/env bash
# Cut a short silent loop out of a recording, for the clip grid on the site.
#
#   tools/make-clip.sh <source> <start> <seconds> <name> [height] [crf]
#   tools/make-clip.sh media-src/battle.avi 00:01:12 6 augment-naming
#
# Writes public/media/clip-<name>.mp4 plus clip-<name>.jpg as its poster frame.
# These behave like GIFs on the page (autoplay, muted, looped) at a fraction of the size.
# Nothing is deleted; an existing clip of the same name is kept as .prev.mp4.
set -euo pipefail

SRC="${1:?usage: make-clip.sh <source> <start> <seconds> <name> [height] [crf]}"
START="${2:?start timestamp, e.g. 00:01:12}"
SECS="${3:?length in seconds}"
NAME="${4:?short name, e.g. augment-naming}"
HEIGHT="${5:-720}"
CRF="${6:-27}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public/media/clip-$NAME.mp4"
POSTER="$ROOT/public/media/clip-$NAME.jpg"

[[ -f "$SRC" ]] || { echo "no such file: $SRC"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found — brew install ffmpeg"; exit 1; }

[[ -f "$OUT" ]] && cp "$OUT" "${OUT%.mp4}.prev.mp4" && echo "kept previous as clip-$NAME.prev.mp4"

# -an: no audio track at all. A muted autoplay video with no audio stream is what browsers
# actually allow to play without a user gesture, on every engine.
ffmpeg -loglevel error -y -ss "$START" -t "$SECS" -i "$SRC" \
  -r 30 -vf "scale=-2:${HEIGHT}" -crf "$CRF" \
  -c:v libx264 -preset slow -pix_fmt yuv420p -an \
  -movflags +faststart "$OUT"

# First frame as the poster, so the slot isn't blank before the video loads.
ffmpeg -loglevel error -y -ss "$START" -i "$SRC" -frames:v 1 -vf "scale=-2:${HEIGHT}" -q:v 3 "$POSTER"

printf "clip-%s.mp4  %s KB   (%ss, %sp)\n" "$NAME" "$(( $(stat -f%z "$OUT") / 1024 ))" "$SECS" "$HEIGHT"
printf "clip-%s.jpg  %s KB   poster\n" "$NAME" "$(( $(stat -f%z "$POSTER") / 1024 ))"
echo
echo "Add to public/index.html inside .shots — the slot picks it up automatically:"
echo "  <figure class=\"shot\">"
echo "    <div class=\"media empty\" data-slot=\"media/clip-$NAME.mp4\">"
echo "      <video autoplay muted loop playsinline poster=\"media/clip-$NAME.jpg\">"
echo "        <source src=\"media/clip-$NAME.mp4\" type=\"video/mp4\"></video>"
echo "    </div>"
echo "    <figcaption class=\"caption\">describe what it shows</figcaption>"
echo "  </figure>"
