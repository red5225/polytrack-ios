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

# Remove promotional overlays and scripts added by this third-party archive.
# Keep the game itself intact; original-game attribution remains in the native About sheet.
python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")

# Fork-added fixed menu, rotating social/feedback tile, and hidden SEO text.
for pattern in (
    r'<div\s+id="staticMenu"\b[^>]*>.*?</div>',
    r'<div\s+id="staticSlideMenu"\b[^>]*>.*?</div>',
    r'<div\s+class="seo-hidden"\b[^>]*>.*?</div>',
):
    html, count = re.subn(pattern, "", html, count=1, flags=re.IGNORECASE | re.DOTALL)
    if count != 1:
        raise SystemExit(f"Expected fork-added markup not found for pattern: {pattern}")

# This inline script controls the fork's menus, rotating widget, keyboard toggle,
# and leave-page warning. Do not touch the official game bundles.
html, count = re.subn(
    r'<script>\s*// Leave warning.*?</script>',
    "",
    html,
    count=1,
    flags=re.IGNORECASE | re.DOTALL,
)
if count != 1:
    raise SystemExit("Expected fork-added popup/rotator script not found")

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

# Keep the fork's expected configuration but do not modify the official game bundle.
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

echo "Prepared PolyTrack v0.5.2 fullscreen assets without fork-added promo popups:"
du -sh "$DEST"
test -f "$DEST/index.html"
test -f "$DEST/main.bundle.js"
test -f "$DEST/simulation_worker.bundle.js"
