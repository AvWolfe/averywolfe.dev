#!/usr/bin/env bash
# Deploy public/ to averywolfe.dev. Dry run by default; pass --live to actually write.
set -euo pipefail

HOST=root@averywolfe.dev
DEST=/var/www/html/
SRC="$(cd "$(dirname "$0")" && pwd)/public/"

FLAGS=(-az --delete --checksum --exclude '.DS_Store' --exclude 'README.md')
[[ "${1:-}" == "--live" ]] || FLAGS+=(--dry-run)

rsync "${FLAGS[@]}" "$SRC" "$HOST:$DEST"

if [[ "${1:-}" == "--live" ]]; then
  echo "deployed. verifying:"
  curl -s -o /dev/null -w "  https://averywolfe.dev/  -> %{http_code}\n" https://averywolfe.dev/
else
  echo
  echo "(dry run — nothing changed. re-run with --live to deploy)"
fi
