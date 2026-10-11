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

# Patch the simulation worker and its main-thread bridge for built-in practice cheats.
python3 - "$DEST/simulation_worker.bundle.js" "$DEST/main.bundle.js" <<'PY'
from pathlib import Path
import sys
worker_path, main_path = map(Path, sys.argv[1:])
w = worker_path.read_text(encoding="utf-8")
m = main_path.read_text(encoding="utf-8")

def replace_once(source, old, new, label):
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"Expected one {label} patch target, found {count}; refusing to build")
    return source.replace(old, new, 1)

m = replace_once(
    m,
    """mz(this, hz, new Worker("simulation_worker.bundle.js"), "f"),""",
    """mz(this, hz, (function(){const w=new Worker("simulation_worker.bundle.js");const p=w.postMessage.bind(w);w.postMessage=function(d,...a){if(d&&typeof d==="object")d.__ptCheats=globalThis.PolyTrackModsState||{};return p(d,...a)};globalThis.__polyTrackSimulationWorker=w;return w})(), "f"),""",
    "simulation worker bridge",
)
w = replace_once(
    w,
    """const e = new Ammo.btVector3(0,-9.82,0);
                Oh(this, Rh, "f").setGravity(e),
                Ammo.destroy(e)
            }
            dispose() {
                for (const {body: e} of Oh(this, Lh, "f"))""",
    """const e = new Ammo.btVector3(0,-9.82,0);
                Oh(this, Rh, "f").setGravity(e),
                Ammo.destroy(e)
            }
            dispose() {
                for (const {body: e} of Oh(this, Lh, "f"))""",
    "live gravity setter",
)
w = replace_once(
    w,
    """let t = new G_([]);
                const n = [];
                function i(e) {
                    switch (e.data.messageType) {""",
    """let t = new G_([]);
                let __ptCheats = {};
                const n = [];
                function i(e) {
                    if (e.data && e.data.__ptCheats) __ptCheats = Object.assign({}, e.data.__ptCheats);
                    switch (e.data.messageType) {""",
    "worker cheat state receiver",
)
w = replace_once(
    w,
    """t = new G_(e.data.trackParts),
                            function(e) {""",
    """t = new G_(e.data.trackParts),
                            function(e) {""",
    "initial gravity application",
)
w = replace_once(w, """const e = 4e3;
                S_(this, ZA, "f").applyEngineForce(e, 2),""", """const e = 4e3 * (__ptCheats.hyperBoost ? 4 : __ptCheats.speedBoost ? 2.5 : 1);
                S_(this, ZA, "f").applyEngineForce(e, 2),""", "engine force multiplier")
w = replace_once(w, """const e = 10;
                    S_(this, ZA, "f").setBrake(e, 0),""", """const e = __ptCheats.strongBrakes ? 24 : 10;
                    S_(this, ZA, "f").setBrake(e, 0),""", "brake multiplier")
w = replace_once(w, """const l = this.getWheelInContact(0) || this.getWheelInContact(1) || this.getWheelInContact(2) || this.getWheelInContact(3);
            if (!l && a""", """const l = this.getWheelInContact(0) || this.getWheelInContact(1) || this.getWheelInContact(2) || this.getWheelInContact(3);
            if (__ptCheats.airControl && !l && (r || s)) { const ptTorque = new Ammo.btVector3(0, r ? -650 : 650, 0); S_(this, JA, "f").applyTorque(ptTorque); Ammo.destroy(ptTorque); }
            if (!l && a""", "air control torque")
w = replace_once(w, """S_(this, ZA, "f").setSteeringValue(g, 0),
            S_(this, ZA, "f").setSteeringValue(g, 1);""", """g *= __ptCheats.precisionSteering ? 1.8 : 1;
            S_(this, ZA, "f").setSteeringValue(g, 0),
            S_(this, ZA, "f").setSteeringValue(g, 1);""", "precision steering")
worker_path.write_text(w, encoding="utf-8")
main_path.write_text(m, encoding="utf-8")
print("Patched worker/main bundle cheat hooks successfully.")
PY

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
/* PolyTrack iOS practice mods. Editable in Files > On My iPhone > PolyTrack > Game. */
(() => {
  if (window.__polyTrackModsLoaded) return;
  window.__polyTrackModsLoaded = true;
  const cheats = { speedBoost:false, hyperBoost:false, airControl:false, precisionSteering:false, strongBrakes:false };
  window.PolyTrackModsState = cheats;
  const style = document.createElement("style");
  style.textContent = `
    #pt-mods-button { position:fixed; z-index:2147483647; left:10px; top:10px; border:1px solid #5689a1; border-radius:10px; padding:9px 12px; color:#eefaff; background:rgba(10,18,28,.94); font:700 13px -apple-system,BlinkMacSystemFont,sans-serif; letter-spacing:.5px; box-shadow:0 3px 16px #0008; }
    #pt-mods-panel { position:fixed; z-index:2147483647; left:10px; top:54px; width:min(290px,calc(100vw - 20px)); max-height:68vh; overflow:auto; box-sizing:border-box; padding:12px; border-radius:14px; border:1px solid #3c6278; color:#f2f8ff; background:rgba(8,13,22,.97); box-shadow:0 8px 28px #000b; font:14px -apple-system,BlinkMacSystemFont,sans-serif; }
    #pt-mods-panel[hidden] { display:none !important; } #pt-mods-panel h3 { margin:0 0 5px; font-size:16px; } #pt-mods-panel p { margin:6px 0 10px; color:#b9c9d7; font-size:12px; line-height:1.35; }
    .pt-mod-row { display:flex; align-items:center; justify-content:space-between; gap:8px; padding:9px 0; border-top:1px solid #ffffff22; } .pt-mod-row span { flex:1; } .pt-mod-row button { min-width:54px; color:white; background:#24475d; border:1px solid #5ca5c9; border-radius:8px; padding:7px 10px; }
  `;
  document.documentElement.appendChild(style);
  const openButton = document.createElement("button"); openButton.id = "pt-mods-button"; openButton.type = "button"; openButton.textContent = "MODS"; openButton.setAttribute("aria-label", "Open PolyTrack practice mods");
  const panel = document.createElement("section"); panel.id = "pt-mods-panel"; panel.hidden = true;
  panel.innerHTML = "<h3>Practice Mods</h3><p>Single-player physics tweaks. Changes take effect as the simulation receives its next update.</p>";
  openButton.addEventListener("click", () => { panel.hidden = !panel.hidden; });
  document.addEventListener("keydown", event => { if (event.key === "Escape") panel.hidden = true; });
  document.body.append(openButton, panel);
  const registerToggle = (name, enable, disable) => {
    const row = document.createElement("div"), label = document.createElement("span"), button = document.createElement("button");
    row.className = "pt-mod-row"; label.textContent = name; button.type = "button"; button.textContent = "OFF"; let active = false;
    button.addEventListener("click", () => { try { if (active) { if (typeof disable === "function") disable(); active=false; button.textContent="OFF"; } else { if (typeof enable === "function") enable(); active=true; button.textContent="ON"; } } catch(error) { console.error("[PolyTrackMods]",name,error); button.textContent="ERR"; } });
    row.append(label,button); panel.appendChild(row);
  };
  const toggleCheat = (label,key) => registerToggle(label,()=>{ cheats[key]=true; },()=>{ cheats[key]=false; });
  window.PolyTrackMods = Object.freeze({ version:"2.0", registerToggle, addStyle(cssText) { const s=document.createElement("style"); s.textContent=String(cssText); document.documentElement.appendChild(s); return s; } });
  toggleCheat("Speed boost · 2.5×","speedBoost");
  toggleCheat("Hyper boost · 4×","hyperBoost");
  toggleCheat("Air control","airControl");
  toggleCheat("Precision steering","precisionSteering");
  toggleCheat("Strong brakes","strongBrakes");
  registerToggle("Hide game HUD",()=>{const e=document.getElementById("ui");if(e)e.style.visibility="hidden";},()=>{const e=document.getElementById("ui");if(e)e.style.visibility="";});
  registerToggle("High-contrast HUD",()=>{const e=document.getElementById("ui");if(e)e.style.filter="contrast(1.35) brightness(1.12)";},()=>{const e=document.getElementById("ui");if(e)e.style.filter="";});
  console.info("[PolyTrackMods] Built-in practice mods loaded.");
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
- simulation_worker.bundle.js: physics simulation code
- mods.js: built-in practice mod menu and editable mod extension point
- tracks/, models/, images/: game assets

BUILT-IN PRACTICE MODS
Tap MODS in-game to toggle Speed boost (2.5x), Hyper boost (4x), Air control, Precision steering, Strong brakes, Hide game HUD, and High-contrast HUD. Physics mods are local single-player changes. No-clip and unlock-all-tracks are not included because they require additional collision/progression changes.

INSTALLING THE APP ON IPHONE
A GitHub Actions build does not install the app automatically. The artifact is an unsigned IPA, and iOS will not install it by tapping it in Files. Download the IPA from the GitHub Actions run's Artifacts section, then install/sign it with a sideloading tool such as AltStore/SideStore or Sideloadly using a Mac/PC and your own Apple ID. This project does not include an Apple signing certificate or provisioning profile.

The Info > Reset Game Data button clears website storage only. It does not delete or restore files in this folder.

Editing .js/.html/.json files may require a code editor app that can open files from the iOS Files app. Keep a backup of the Game folder before making changes.
TXT


echo "Prepared editable PolyTrack assets, removed the fork promo crash, and added the local mod loader."
du -sh "$DEST"
test -s "$DEST/index.html"
test -s "$DEST/main.bundle.js"
test -s "$DEST/simulation_worker.bundle.js"
test -s "$DEST/mods.js"

cat > "INSTALL-ON-IPHONE.txt" <<'TXT'
PolyTrack iOS build is packaged as an unsigned IPA. GitHub Actions does not install it on your iPhone. Download the PolyTrack-Offline-v0.5.2-unsigned-IPA artifact from the latest successful run, then sideload/sign it using AltStore/SideStore or Sideloadly with a Mac/PC and your Apple ID. Tapping an unsigned IPA in the iOS Files app will not install it.
TXT
