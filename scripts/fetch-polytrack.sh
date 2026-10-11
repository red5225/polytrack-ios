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

mod_tag = '<script defer src="./mods.js"></script>'
if mod_tag not in html:
    match = re.search(r"</head\s*>", html, flags=re.IGNORECASE)
    if not match:
        raise SystemExit("Could not find closing head element for mods loader")
    html = html[:match.start()] + mod_tag + "\n" + html[match.start():]

path.write_text(html, encoding="utf-8")
PY

cat > "$DEST/mods.js" <<'JS'
/* PolyTrack iOS mod loader.
   This file is editable in Files > On My iPhone > PolyTrack > Game.
   Add personal single-player UI mods by calling:
   PolyTrackMods.registerToggle("My mod", () => { /* enable */ }, () => { /* disable */ });
*/
(() => {
  if (window.__polyTrackModsLoaded) return;
  window.__polyTrackModsLoaded = true;

  const style = document.createElement("style");
  style.textContent = `
    #pt-mods-button {
      position: fixed; z-index: 2147483647; left: 10px; top: 10px;
      border: 1px solid rgba(120,220,255,.7); border-radius: 10px;
      padding: 9px 12px; color: #eefaff; background: rgba(10,18,28,.92);
      font: 700 13px -apple-system, BlinkMacSystemFont, sans-serif;
      letter-spacing: .5px; box-shadow: 0 3px 16px #0008;
    }
    #pt-mods-panel {
      position: fixed; z-index: 2147483647; left: 10px; top: 54px;
      width: min(270px, calc(100vw - 20px)); max-height: 65vh; overflow: auto;
      box-sizing: border-box; padding: 12px; border-radius: 14px;
      border: 1px solid #3c6278; color: #f2f8ff; background: rgba(8,13,22,.97);
      box-shadow: 0 8px 28px #000b; font: 14px -apple-system, BlinkMacSystemFont, sans-serif;
    }
    #pt-mods-panel[hidden] { display: none !important; }
    #pt-mods-panel h3 { margin: 0 0 8px; font-size: 16px; }
    #pt-mods-panel p { margin: 6px 0 10px; color: #b9c9d7; font-size: 12px; line-height: 1.35; }
    .pt-mod-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 9px 0; border-top: 1px solid #ffffff22; }
    .pt-mod-row button { color: white; background: #24475d; border: 1px solid #5ca5c9; border-radius: 8px; padding: 7px 10px; }
  `;
  document.documentElement.appendChild(style);

  const openButton = document.createElement("button");
  openButton.id = "pt-mods-button";
  openButton.type = "button";
  openButton.textContent = "MODS";
  openButton.setAttribute("aria-label", "Open PolyTrack mods menu");

  const panel = document.createElement("section");
  panel.id = "pt-mods-panel";
  panel.hidden = true;
  panel.innerHTML = "<h3>Practice Mods</h3><p>Single-player helpers. Custom toggles can be added in this editable mods.js file.</p>";

  openButton.addEventListener("click", () => { panel.hidden = !panel.hidden; });
  document.addEventListener("keydown", event => {
    if (event.key === "Escape") panel.hidden = true;
  });
  document.body.append(openButton, panel);

  const registerToggle = (name, enable, disable) => {
    const row = document.createElement("div");
    row.className = "pt-mod-row";
    const label = document.createElement("span");
    label.textContent = name;
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "OFF";
    let active = false;
    button.addEventListener("click", () => {
      try {
        if (active) { if (typeof disable === "function") disable(); active = false; button.textContent = "OFF"; }
        else { if (typeof enable === "function") enable(); active = true; button.textContent = "ON"; }
      } catch (error) {
        console.error("[PolyTrackMods]", name, error);
        button.textContent = "ERR";
      }
    });
    row.append(label, button);
    panel.appendChild(row);
  };

  window.PolyTrackMods = Object.freeze({
    version: "1.0",
    registerToggle,
    addStyle(cssText) {
      const customStyle = document.createElement("style");
      customStyle.textContent = String(cssText);
      document.documentElement.appendChild(customStyle);
      return customStyle;
    }
  });

  registerToggle("Hide game HUD", () => {
    const ui = document.getElementById("ui");
    if (ui) ui.style.visibility = "hidden";
  }, () => {
    const ui = document.getElementById("ui");
    if (ui) ui.style.visibility = "";
  });

  registerToggle("High-contrast HUD", () => {
    const ui = document.getElementById("ui");
    if (ui) ui.style.filter = "contrast(1.35) brightness(1.12)";
  }, () => {
    const ui = document.getElementById("ui");
    if (ui) ui.style.filter = "";
  });

  console.info("[PolyTrackMods] Loaded. Custom toggles can be registered from mods.js.");
})();

JS

cat > "$DEST/MODS-README.txt" <<'TXT'
POLYTRACK IOS — EDITABLE GAME FILES

Files location:
On My iPhone > PolyTrack > Game

The app copies the bundled game into this folder on first launch and then serves the copy. Edits made here are kept between launches.

Useful files:
- index.html: game page and script/style loading
- main.bundle.js: compiled game code (large/minified; back it up before editing)
- mods.js: runs after the game bundle and contains the small MODS menu
- tracks/, models/, images/: game assets

MOD MENU
Tap MODS in the game. The starter toggles change HUD presentation only. This is an extension point, not a claim that unsupported physics cheats already work.

Custom toggle example — add near the bottom of mods.js, before the final closing wrapper if you want it to run in the same scope:
PolyTrackMods.registerToggle("My UI tweak",
  () => { document.body.style.filter = "saturate(1.3)"; },
  () => { document.body.style.filter = ""; }
);

Editing .js/.html/.json files may require a code editor app that can open files from the iOS Files app. Keep a backup of the Game folder before making changes.

The Info > Reset Game Data button clears website storage only. It does not delete or restore files in this folder.

TXT

echo "Prepared editable PolyTrack assets, removed the fork promo crash, and added the local mod loader."
du -sh "$DEST"
test -s "$DEST/index.html"
test -s "$DEST/main.bundle.js"
test -s "$DEST/simulation_worker.bundle.js"
test -s "$DEST/mods.js"
