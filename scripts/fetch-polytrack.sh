#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_REPO="https://github.com/StaticQuasar931/polytrack-0.5.2.git"
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

# Remove only the third-party fork's promotional overlays and its controlling script.
python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")

patterns = [
    r'<div\s+id="staticMenu"[^>]*>.*?</div\s*>',
    r'<div\s+id="staticSlideMenu"[^>]*>.*?</div\s*>',
    r'<div\s+class="seo-hidden"[^>]*>.*?</div\s*>',
]
for pattern in patterns:
    html, count = re.subn(pattern, "", html, count=1, flags=re.IGNORECASE | re.DOTALL)
    if count != 1:
        raise SystemExit(f"Expected fork-added markup not found for pattern: {pattern}")

# This script is identifiable by its first comment and contains the fork's
# promotional rotator, keyboard toggle, and beforeunload warning.
html, count = re.subn(
    r'<script\b[^>]*>\s*//\s*Leave warning.*?</script\s*>',
    "",
    html,
    count=1,
    flags=re.IGNORECASE | re.DOTALL,
)
if count != 1:
    raise SystemExit("Expected fork-added popup/rotator script not found")

# Ensure the game canvas uses the full available iPhone viewport.
fullscreen_css = """
/* iPhone fullscreen layout: remove browser-style gutters around the game. */
html, body {
  width: 100% !important;
  height: 100% !important;
  min-width: 0 !important;
  min-height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
  background: #000 !important;
  overscroll-behavior: none;
  touch-action: none;
}
body { position: fixed; inset: 0; }
#screen {
  position: fixed !important;
  inset: 0 !important;
  display: block !important;
  width: 100vw !important;
  height: 100vh !important;
  height: 100dvh !important;
  margin: 0 !important;
  padding: 0 !important;
}
#ui, #transition-layer {
  position: fixed;
  inset: 0;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
}
canvas { max-width: none; max-height: none; }
"""
if "</style>" not in html.lower():
    raise SystemExit("Could not find the page style block to apply fullscreen layout")
html = re.sub(r"</style>", lambda m: fullscreen_css + "\n" + m.group(0), html, count=1, flags=re.IGNORECASE)

path.write_text(html, encoding="utf-8")
PY

# Keep the fork's expected configuration, without changing the official game bundles.
python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")
config = '<script>window.polytrackModConfiguration = {modName: "PolyTrack iOS Offline", author: "red5225", unblocked: true};</script>\n'
if "polytrackModConfiguration" not in html:
    match = re.search(r"<head[^>]*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find HTML head element for game configuration")
    html = html[:match.end()] + "\n" + config + html[match.end():]
path.write_text(html, encoding="utf-8")
PY

echo "Prepared PolyTrack v0.5.2 fullscreen assets without fork-added promotional popups:"
du -sh "$DEST"
test -f "$DEST/index.html"
test -f "$DEST/main.bundle.js"
test -f "$DEST/simulation_worker.bundle.js"
