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

# The fork's promo animation script dereferences the removed promo elements.
html, removed = re.subn(
    r'<script\b[^>]*>\s*//\s*Leave warning.*?</script\s*>',
    "",
    html,
    count=1,
    flags=re.IGNORECASE | re.DOTALL,
)
if removed != 1:
    raise SystemExit("Expected fork promo/leave-warning script was not found; refusing to build with the broken popup code")

config = '<script>window.polytrackModConfiguration = {modName: "PolyTrack iOS Offline", author: "red5225", unblocked: true};</script>\n'
if "polytrackModConfiguration" not in html:
    match = re.search(r"<head[^>]*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find HTML head element for game configuration")
    html = html[:match.end()] + "\n" + config + html[match.end():]

# Keep the native wrapper free of in-game mods; retain only a small non-blocking error notice.
error_tag = '<script defer src="./error-failsafe.js"></script>'
if error_tag not in html:
    match = re.search(r"</head\s*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find closing head element for error fail-safe")
    html = html[:match.start()] + error_tag + "\n" + html[match.start():]

path.write_text(html, encoding="utf-8")
PY

cat > "$DEST/error-failsafe.js" <<'JS'
/* Non-blocking error notice; this does not add gameplay mods or alter physics. */
(() => {
  let timer = 0, lastError = "", lastAt = 0;
  function showError(message) {
    const now = Date.now();
    const text = String(message || "Unknown game error").replace(/\s+/g, " ").slice(0, 180);
    if (text === lastError && now - lastAt < 1000) return;
    lastError = text; lastAt = now;
    let box = document.getElementById("pt-error-toast");
    if (!box) {
      box = document.createElement("div"); box.id = "pt-error-toast";
      Object.assign(box.style, {position:"fixed",top:"10px",right:"10px",zIndex:"2147483647",maxWidth:"min(300px, calc(100vw - 20px))",boxSizing:"border-box",padding:"8px 10px",border:"1px solid #d7dce2",borderRadius:"8px",background:"rgba(255,255,255,.97)",color:"#252a31",boxShadow:"0 3px 14px rgba(0,0,0,.2)",font:"12px/1.35 -apple-system,BlinkMacSystemFont,sans-serif",whiteSpace:"normal",overflowWrap:"anywhere",pointerEvents:"none"});
      document.documentElement.appendChild(box);
    }
    box.textContent = "Game hiccup — continuing. " + text; box.style.display = "block";
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => { if (box && box.isConnected) box.style.display = "none"; }, 5000);
  }
  window.addEventListener("error", event => {
    const message = event && (event.message || (event.error && event.error.message)) || "A game action failed";
    console.warn("[PolyTrack fail-safe]", message); showError(message); event.preventDefault();
  });
  window.addEventListener("unhandledrejection", event => {
    const reason = event && event.reason;
    const message = reason && reason.message ? reason.message : String(reason || "An async game action failed");
    console.warn("[PolyTrack fail-safe] Unhandled promise rejection:", message); showError(message); event.preventDefault();
  });
})();
JS

cat > "$DEST/GAME-FILES.txt" <<'TXT'
POLYTRACK IOS — EDITABLE GAME FILES

Files location: On My iPhone > PolyTrack > Game
The app copies the bundled game into this folder on first launch and serves the copy. Edits are kept between launches.

index.html is the game page. main.bundle.js and simulation_worker.bundle.js are compiled game code. tracks/, models/, and images/ contain assets. Keep a backup before editing code or assets.

The native app's Settings screen contains app-level options and the saved-data reset control. No in-game mods or cheat menu are included.

GitHub Actions creates an unsigned IPA; it does not install the app automatically. Download the IPA artifact from a successful workflow run and sign/sideload it with AltStore/SideStore or Sideloadly using a Mac/PC and your own Apple ID. Tapping an unsigned IPA in Files will not install it.

The Reset Saved Data action clears website storage only. It does not delete editable files in this folder.
TXT

echo "Prepared clean PolyTrack assets, removed the fork promo crash, and added the non-blocking error fail-safe."
du -sh "$DEST"
test -s "$DEST/index.html"
test -s "$DEST/main.bundle.js"
test -s "$DEST/simulation_worker.bundle.js"
test -s "$DEST/error-failsafe.js"

cat > "INSTALL-ON-IPHONE.txt" <<'TXT'
PolyTrack iOS build is packaged as an unsigned IPA. GitHub Actions does not install it on your iPhone. Download the PolyTrack-Offline-v0.5.2-unsigned-IPA artifact from the latest successful run, then sideload/sign it using AltStore/SideStore or Sideloadly with a Mac/PC and your Apple ID. Tapping an unsigned IPA in the iOS Files app will not install it.
TXT
