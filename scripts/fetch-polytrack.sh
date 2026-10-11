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

python3 - "$DEST" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
html_path = root / "index.html"
html = html_path.read_text(encoding="utf-8")
config = '<script>window.polytrackModConfiguration = {modName: "PolyTrack iOS Offline", author: "red5225", unblocked: true};</script>\\n'
if "polytrackModConfiguration" not in html:
    match = re.search(r"<head[^>]*>", html, flags=re.IGNORECASE)
    if match:
        html = html[:match.end()] + "\\n" + config + html[match.end():]
    else:
        html = config + html
html_path.write_text(html, encoding="utf-8")

# The archive's own README says its bundle only runs on approved hosted origins.
# This app serves its bundled assets on loopback HTTP, so rewrite that allow-list
# hostname in local JavaScript bundles to match the app's 127.0.0.1 origin.
replacements = 0
for js_path in root.rglob("*.js"):
    source = js_path.read_text(encoding="utf-8", errors="replace")
    updated = source.replace("htmlunblockedgames.github.io", "127.0.0.1")
    replacements += source.count("htmlunblockedgames.github.io")
    if updated != source:
        js_path.write_text(updated, encoding="utf-8")
if replacements == 0:
    raise SystemExit("Could not find the archive's documented hosted-origin allow-list in JavaScript bundles")
print(f"Patched {replacements} approved-host references for local loopback serving")
PY

echo "Prepared archived PolyTrack v${ARCHIVE_VERSION} assets:"
du -sh "$DEST"
test -f "$DEST/index.html"
test -f "$DEST/main.bundle.js"
test -f "$DEST/simulation_worker.bundle.js"
