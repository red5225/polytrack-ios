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

python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")

# Remove the fork-added promo containers.
for pattern in (
    r'<div\s+id="staticMenu"[^>]*>.*?</div\s*>',
    r'<div\s+id="staticSlideMenu"[^>]*>.*?</div\s*>',
    r'<div\s+class="seo-hidden"[^>]*>.*?</div\s*>',
):
    html = re.sub(pattern, "", html, count=1, flags=re.IGNORECASE | re.DOTALL)

# IMPORTANT: the fork's "Leave warning" inline script animates the
# "More games by Static" tile and writes a.href. Once its tile is removed,
# that script dereferences null and crashes the loading page. Remove the
# script itself as well as the tile.
html, removed = re.subn(
    r'<script\b[^>]*>\s*//\s*Leave warning.*?</script\s*>',
    "",
    html,
    count=1,
    flags=re.IGNORECASE | re.DOTALL,
)
if removed != 1:
    raise SystemExit("Expected fork promo/leave-warning script was not found; refusing to build with the broken popup code")

fullscreen_css = """
/* Full-bleed layout for portrait and landscape iPhone screens. */
html, body {
  position: fixed !important;
  inset: 0 !important;
  width: 100% !important;
  height: 100% !important;
  min-width: 0 !important;
  min-height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  border: 0 !important;
  overflow: hidden !important;
  background: #000 !important;
  overscroll-behavior: none;
  touch-action: none;
}
#screen, #ui, #transition-layer {
  position: fixed !important;
  inset: 0 !important;
  width: 100vw !important;
  height: 100vh !important;
  height: 100dvh !important;
  min-width: 0 !important;
  min-height: 0 !important;
  max-width: none !important;
  max-height: none !important;
  margin: 0 !important;
  padding: 0 !important;
  border: 0 !important;
}
#screen { display: block !important; }
#screen canvas, canvas {
  display: block !important;
  width: 100% !important;
  height: 100% !important;
  max-width: none !important;
  max-height: none !important;
}
@media (orientation: landscape) {
  html, body, #screen, #ui, #transition-layer {
    width: 100vw !important;
    height: 100vh !important;
    height: 100dvh !important;
  }
}
"""
if "</style>" in html.lower():
    html = re.sub(r"</style>", lambda m: fullscreen_css + "\n" + m.group(0), html, count=1, flags=re.IGNORECASE)
else:
    html = re.sub(r"</head>", "<style>" + fullscreen_css + "</style>\n</head>", html, count=1, flags=re.IGNORECASE)

# Defensive cleanup if the promotion is inserted dynamically by another
# fork script in a future upstream revision.
promo_script = r"""
<script>
(function () {
  const promo = /more\s+games\s+by\s+static/i;
  function removePromo() {
    document.querySelectorAll('a,button,[role="button"],div,section,aside').forEach(function (el) {
      if (!el.isConnected || !promo.test((el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim())) return;
      let target = el;
      for (let i = 0; i < 4 && target.parentElement; i++) {
        const parent = target.parentElement;
        if (/^(A|BUTTON)$/.test(parent.tagName) || parent.id === 'staticMenu' || parent.id === 'staticSlideMenu') {
          target = parent;
        } else if (parent.children.length <= 2 && (parent.innerText || '').length < 180) {
          target = parent;
        } else {
          break;
        }
      }
      target.remove();
    });
  }
  removePromo();
  new MutationObserver(removePromo).observe(document.documentElement, { childList: true, subtree: true });
  window.addEventListener('load', removePromo);
})();
</script>
"""
if "</body>" in html.lower():
    html = re.sub(r"</body>", lambda m: promo_script + "\n" + m.group(0), html, count=1, flags=re.IGNORECASE)
else:
    html += promo_script

config = '<script>window.polytrackModConfiguration = {modName: "PolyTrack iOS Offline", author: "red5225", unblocked: true};</script>\n'
if "polytrackModConfiguration" not in html:
    match = re.search(r"<head[^>]*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find HTML head element for game configuration")
    html = html[:match.end()] + "\n" + config + html[match.end():]

path.write_text(html, encoding="utf-8")
PY

echo "Prepared fullscreen PolyTrack assets and removed the fork promo script that crashed loading."
du -sh "$DEST"
test -f "$DEST/index.html"
test -f "$DEST/main.bundle.js"
test -f "$DEST/simulation_worker.bundle.js"
