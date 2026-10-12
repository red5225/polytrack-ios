#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/saveweb2zip-com-historicalmathematics-xyz"
DEST="$ROOT_DIR/PolyTrackIOS/Game"
BASE_URL="https://historicalmathematics.xyz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Keep the uploaded v0.6.0 game bundle and fill its missing runtime assets.
for file in index.html js/main.bundle.js js/error_screen.bundle.js js/lb.js js/manifest.json fonts/forced_square.woff2 images/logo.svg images/discord.svg; do
  test -s "$SOURCE_DIR/$file" || { echo "Missing uploaded game file: $SOURCE_DIR/$file" >&2; exit 1; }
done
rm -rf "$DEST"
mkdir -p "$DEST/images"
cp "$SOURCE_DIR/index.html" "$DEST/index.html"
cp "$SOURCE_DIR/js/main.bundle.js" "$DEST/main.bundle.js"
cp "$SOURCE_DIR/js/error_screen.bundle.js" "$DEST/error_screen.bundle.js"
cp "$SOURCE_DIR/js/lb.js" "$DEST/lb.js"
cp "$SOURCE_DIR/js/manifest.json" "$DEST/manifest.json"
cp "$SOURCE_DIR/fonts/forced_square.woff2" "$DEST/forced_square.woff2"
cp -R "$SOURCE_DIR/images/." "$DEST/images/"

python3 - "$DEST/index.html" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")
html = re.sub(
    r'\s*<!--\s*Google tag \(gtag\.js\)\s*-->.*?</script>\s*<script>\s*window\.dataLayer\s*=.*?</script>',
    '', html, count=1, flags=re.IGNORECASE | re.DOTALL
)
for old, new in (
    ("fonts/forced_square.woff2", "forced_square.woff2"),
    ("js/manifest.json", "manifest.json"),
    ("js/error_screen.bundle.js", "error_screen.bundle.js"),
    ("js/lb.js", "lb.js"),
    ("js/main.bundle.js", "main.bundle.js"),
):
    html = html.replace(old, new)
html = re.sub(r'<script\b[^>]*src=["\'](?:\./)?mods\.js["\'][^>]*>\s*</script\s*>', '', html, flags=re.I)
error_tag = '<script defer src="./error-failsafe.js"></script>'
if error_tag not in html:
    match = re.search(r"</head\s*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find closing head element")
    html = html[:match.start()] + error_tag + "\n" + html[match.start():]
path.write_text(html, encoding="utf-8")
PY

download_asset() {
  local path="$1" target="$DEST/$1" tmp
  [[ -s "$target" ]] && return 0
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "$TMP_DIR/asset.XXXXXX")"
  echo "Fetching $path"
  if ! curl --fail --location --silent --show-error --retry 3 --retry-all-errors "$BASE_URL/$path" -o "$tmp"; then
    rm -f "$tmp"; echo "Failed to fetch: $path" >&2; return 1
  fi
  if ! python3 - "$tmp" "$path" <<'PY'
from pathlib import Path
import sys
data = Path(sys.argv[1]).read_bytes()
name = sys.argv[2].lower()
if not data or data.lstrip().lower().startswith((b"<!doctype html", b"<html")): raise SystemExit(1)
if name.endswith(".wasm") and not data.startswith(b"\x00asm"): raise SystemExit(1)
if name.endswith(".track") and not data.startswith(b"PolyTrack"): raise SystemExit(1)
PY
  then
    rm -f "$tmp"; echo "Invalid source response for: $path" >&2; return 1
  fi
  mv "$tmp" "$target"
}

for asset in simulation_worker.bundle.js polytrack_physics.wasm forced_square.json lib/draco/draco_decoder.wasm lib/draco/draco_wasm_wrapper.js 124.bundle.js 142.bundle.js 168.bundle.js 280.bundle.js 57.bundle.js 789.bundle.js 982.bundle.js; do
  download_asset "$asset"
done

python3 - "$DEST" "$TMP_DIR/assets.txt" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
out = Path(sys.argv[2])
scripts = list(root.glob("*.js"))
path_re = re.compile(r"""['"]((?:images|models|audio|tracks|lib)/[^'"]+\.(?:svg|png|jpe?g|webp|glb|gltf|ogg|mp3|track|wasm|json|woff2?|ttf))['"]""", re.I)
official_re = re.compile(r"""['"]((?:summer|winter|desert)\d+\.track)['"]""", re.I)
assets = {"polytrack_physics.wasm", "forced_square.json", "forced_square.woff2", "lib/draco/draco_decoder.wasm"}
for script in scripts:
    content = script.read_text(encoding="utf-8", errors="ignore")
    assets.update(path_re.findall(content))
    assets.update("tracks/official/" + name for name in official_re.findall(content))
out.write_text("\n".join(sorted(assets)) + "\n", encoding="utf-8")
print("Found", len(assets), "static assets across", len(scripts), "JavaScript files.")
PY
while IFS= read -r asset; do
  [[ -n "$asset" ]] && download_asset "$asset"
done < "$TMP_DIR/assets.txt"

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
POLYTRACK IOS — EDITABLE GAME FILES (v0.6.0)

Files location: On My iPhone > PolyTrack > Game
The app copies the bundled v0.6.0 game into this folder on first launch and serves the copy. Edits persist between launches.

index.html is the game page. main.bundle.js and simulation_worker.bundle.js are compiled game code. tracks/, models/, and images/ contain assets. Keep a backup before editing code or assets.

The native app Settings screen contains app-level options and the saved-data reset control. No in-game cheat menu or gameplay physics modifications are included.

GitHub Actions creates an unsigned IPA; it does not install the app automatically. Download the IPA artifact from a successful workflow run and sign/sideload it with AltStore/SideStore or Sideloadly using a Mac/PC and your own Apple ID. Tapping an unsigned IPA in Files will not install it.

The Reset Saved Data action clears website storage only. It does not delete editable files in this folder.
TXT

echo "Prepared PolyTrack v0.6.0 from the uploaded game bundle and its referenced assets."
du -sh "$DEST"
test -s "$DEST/index.html"
test -s "$DEST/main.bundle.js"
test -s "$DEST/simulation_worker.bundle.js"
test -s "$DEST/polytrack_physics.wasm"
test -s "$DEST/lib/draco/draco_decoder.wasm"
test -s "$DEST/lib/draco/draco_wasm_wrapper.js"
test -s "$DEST/tracks/official/summer1.track"
test -s "$DEST/tracks/official/winter5.track"
test -s "$DEST/tracks/community/marvelous_marble.track"
test -s "$DEST/models/car.glb"
test -s "$DEST/images/icon.svg"
printf '0.6.0\n' > "$DEST/.polytrack-ios-version"
grep -q '0.6.0' "$DEST/main.bundle.js"
test -s "$DEST/error-failsafe.js"

cat > "INSTALL-ON-IPHONE.txt" <<'TXT'
PolyTrack iOS build is packaged as an unsigned IPA. GitHub Actions does not install it on your iPhone. Download the PolyTrack-Offline-v0.6.0-unsigned-IPA artifact from the latest successful run, then sideload/sign it using AltStore/SideStore or Sideloadly with a Mac/PC and your Apple ID. Tapping an unsigned IPA in the iOS Files app will not install it.
TXT
