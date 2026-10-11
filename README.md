# PolyTrack iOS Offline

An unofficial, non-commercial iOS app shell that bundles the PolyTrack browser game into the app. It serves the bundled files through a loopback HTTP server on the device instead of loading the game from a file URL or the live game website.

## What is included

- The uploaded PolyTrack v0.6.0 main game bundle, with missing static runtime assets assembled during the build.
- Full-screen gameplay with the iOS status bar hidden.
- On-device loopback serving so browser workers and local game assets can load from a normal HTTP origin.
- Native Settings/About screens, editable game files, and a saved-data reset control.
- No in-game cheat menu or gameplay physics modifications.

**Online-feature note:** the game files are served locally, but features that depend on online services—such as leaderboards and multiplayer—still require an internet connection. This is not claimed to be a fully offline replacement for every feature.

## Build and get the IPA

GitHub Actions starts with the game files uploaded under the saveweb2zip-com-historicalmathematics-xyz folder, keeps that uploaded v0.6.0 main bundle, then fetches its missing runtime assets from the matching source host and verifies the required files before packaging the unsigned iOS app.

1. Open the [Actions workflow](https://github.com/red5225/polytrack-ios/actions/workflows/ios-build.yml).
2. Open the latest successful **Build iOS app** run.
3. Under **Artifacts**, download **PolyTrack-Offline-v0.6.0-unsigned-IPA**.
4. Extract the artifact ZIP to get the IPA file.
5. Sign/sideload the IPA with a trusted iOS signing tool and your own Apple ID. The artifact is unsigned and cannot be installed directly as-is.

## Editable files and upgrades

The game copy is available in the iOS Files app at **On My iPhone > PolyTrack > Game**. Extra files you add are preserved when the app upgrades its bundled game version. When the bundled version changes, files that share names with bundled game files are refreshed once; back up edits to those same core files first.

The Settings screen's **Reset Saved Data** action clears browser storage only; it does not delete the editable game files.

## Build locally

Requirements: macOS, Xcode, XcodeGen, Git and network access to the source host for missing assets.

    bash scripts/fetch-polytrack.sh
    xcodegen generate
    xcodebuild -project PolyTrackIOS.xcodeproj -scheme PolyTrackIOS -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

## Attribution and terms

PolyTrack was created by **Kodub**. This is an unofficial, non-commercial port and is not affiliated with or endorsed by Kodub, CrazyGames, Poki or itch.io. The app preserves game navigation links and includes a clickable link to the official CrazyGames game page.

- Official game: https://kodub.itch.io/polytrack
- Official game page link required by Kodub's terms: https://www.crazygames.com/game/polytrack
- Creator website: https://www.kodub.com/
- Terms of Service: https://www.kodub.com/terms/polytrack
- Source host for the uploaded v0.6.0 browser snapshot: https://historicalmathematics.xyz/

This project does not claim ownership of PolyTrack or its game assets. Review the original creator's current terms before redistributing builds; the terms require non-commercial use, attribution, an obvious unofficial notice, and preservation of outbound links.
