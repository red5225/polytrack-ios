#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT_DIR/PolyTrackIOS/Game-PolyMod"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
SOURCE="$TMP_DIR/polymod"
# The saved website capture omits loader/runtime files, so use the complete source tree.
git clone --quiet --depth 1 --filter=blob:none --sparse https://github.com/polytrackmods/PolyModLoader.git "$SOURCE"
git -C "$SOURCE" sparse-checkout set audio images lib models tracks
for required in index.html main.bundle.js simulation_worker.bundle.js error_screen.bundle.js PolyModLoader.js PolyTypes.js manifest.json polytrack_physics.wasm forced_square.woff2; do
  test -s "$SOURCE/$required" || { echo "Missing PolyModLoader source file: $required" >&2; exit 1; }
done
rm -rf "$DEST"; mkdir -p "$DEST"
for file in "$SOURCE"/*; do
  [[ -f "$file" ]] || continue
  case "$(basename "$file")" in .DS_Store|README.md|LICENSE.md|package.json|package-lock.json|pnpm-lock.yaml|PolyModLoader.d.ts|PolyTypes.d.ts) continue ;; esac
  cp "$file" "$DEST/"
done
for dir in audio images lib models tracks; do
  test -d "$SOURCE/$dir" || { echo "Missing PolyModLoader asset directory: $dir" >&2; exit 1; }
  cp -R "$SOURCE/$dir" "$DEST/$dir"
done
printf 'polymodloader\n' > "$DEST/.polytrack-ios-version"
test -s "$DEST/index.html"; test -s "$DEST/main.bundle.js"; test -s "$DEST/simulation_worker.bundle.js"
test -s "$DEST/PolyModLoader.js"; test -s "$DEST/PolyTypes.js"; test -s "$DEST/polytrack_physics.wasm"
echo "Prepared standalone PolyModLoader build: $(du -sh "$DEST" | cut -f1)"
