#!/usr/bin/env bash
# Turn a Godot Movie Maker capture into the web assets the site expects.
#
#   1. Record:  Godot --path <project> --write-movie ~/Desktop/battle.avi
#   2. Run:     tools/make-media.sh ~/Desktop/battle.avi
#   3. Optional: pull extra stills at chosen timestamps (see bottom).
#
# Writes straight into public/media/ using the filenames index.html looks for.
set -euo pipefail

SRC="${1:?usage: make-media.sh <capture.avi> [more timestamps...]}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/public/media"
mkdir -p "$OUT"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found — brew install ffmpeg"; exit 1; }

echo "→ trailer.mp4"
# crf 20 is visually clean for game footage; faststart puts the index up front so it
# starts playing before the whole file lands; yuv420p because some browsers refuse 4:4:4.
ffmpeg -loglevel error -y -i "$SRC" \
  -c:v libx264 -crf 20 -preset slow -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart \
  "$OUT/trailer.mp4"

DUR=$(ffprobe -loglevel error -show_entries format=duration -of csv=p=0 "$SRC")
echo "  duration ${DUR}s"

# Stills spread across the middle of the capture, skipping the first and last 10%
# where a battle is usually mid-setup or already decided.
grab () {  # grab <seconds> <outfile>
  ffmpeg -loglevel error -y -ss "$1" -i "$SRC" -frames:v 1 -q:v 2 "$OUT/$2"
  # keep the page light — 1920 wide, ~80% quality
  sips -s format jpeg -s formatOptions 80 -Z 1920 "$OUT/$2" --out "$OUT/$2" >/dev/null
  printf "  %-22s %sK\n" "$2" "$(( $(stat -f%z "$OUT/$2") / 1024 ))"
}

echo "→ stills"
for i in 1 2 3 4 5; do
  T=$(echo "$DUR $i" | awk '{printf "%.2f", $1 * (0.1 + 0.16 * $2)}')
  grab "$T" "shot-0$i.jpg"
done

# trailer poster + hero reuse the strongest frames; swap these once you pick favourites
cp "$OUT/shot-02.jpg" "$OUT/trailer-poster.jpg"
cp "$OUT/shot-03.jpg" "$OUT/hero.jpg"
echo "  trailer-poster.jpg, hero.jpg (copies — replace with your picks)"

echo
echo "done. review, then: ./deploy.sh --live"
echo
echo "To grab a specific moment instead:"
echo "  ffmpeg -ss 00:01:23 -i \"$SRC\" -frames:v 1 -q:v 2 \"$OUT/system-augments.jpg\""
