#!/usr/bin/env bash
set -euo pipefail
ARCHIVE_REPO="https://github.com/StaticQuasar931/polytrack-0.5.2.git"
ARCHIVE_VERSION="0.5.2"
DEST="PolyTrackIOS/Game"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

git clone --depth 1 "$ARCHIVE_REPO" "$TMP_DIR/archive"
test -f "$TMP_DIR/archive/index.html"
test -f "$TMP_DIR/archive/main.bundle.js"
test -f "$TMP_DIR/archive/simulation_worker.bundle.js"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$TMP_DIR/archive/." "$DEST/"

python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")
config = '<script>window.polytrackModConfiguration = {modName: "PolyTrack iOS Offline", author: "red5225", unblocked: true};</script>\n'
if "polytrackModConfiguration" not in html:
    match = re.search(r"<head[^>]*>", html, flags=re.IGNORECASE)
    if match:
        html = html[:match.end()] + "\n" + config + html[match.end():]
    else:
        html = config + html
path.write_text(html, encoding="utf-8")
PY

echo "Prepared archived PolyTrack v0.5.2 assets:"
du -sh "$DEST"
test -f "$DEST/index.html"
test -f "$DEST/main.bundle.js"
test -f "$DEST/simulation_worker.bundle.js"
