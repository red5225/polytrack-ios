# PolyTrack iOS Offline

An unofficial, non-commercial iOS app shell that bundles an archived, self-contained PolyTrack browser build from an unofficial static-asset repository into the app bundle. It loads local files instead of the live game website.

## What is included

- Bundled PolyTrack **v0.5.2** browser files, including game scripts, models, tracks, images, audio and fonts available in the archive.
- Full-screen gameplay with the iOS status bar hidden.
- Local file loading, so core gameplay and included tracks can work without an internet connection.
- A credits/about screen with required attribution and links.

**Version note:** this intentionally bundles archived v0.5.2, not the newer official release. Features that depend on Kodub's servers—including online leaderboards, multiplayer and community services—may not work offline. This has not been verified as a fully offline replacement for every feature.

## Build and get the IPA

GitHub Actions downloads the archived game files during the build, injects the required mod configuration, verifies that the main game files are present, and packages the unsigned iOS app.

1. Open the [Actions workflow](https://github.com/red5225/polytrack-ios/actions/workflows/ios-build.yml).
2. Open the latest successful **Build iOS app** run.
3. Under **Artifacts**, download **PolyTrack-Offline-v0.5.2-unsigned-IPA**.
4. Extract the artifact ZIP to get the IPA file.
5. Import the IPA into a trusted iOS sideloading/signing tool and sign it with your own Apple ID as supported by that tool. The artifact is unsigned and cannot be installed directly as-is.

## Build locally

Requirements: macOS, Xcode, XcodeGen and Git.

```sh
bash scripts/fetch-polytrack.sh
xcodegen generate
xcodebuild -project PolyTrackIOS.xcodeproj -scheme PolyTrackIOS -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Attribution and terms

PolyTrack was created by **Kodub**. This is an unofficial, non-commercial port and is not affiliated with or endorsed by Kodub, CrazyGames, Poki or itch.io. The app preserves game navigation links and includes a clickable link to the official CrazyGames game page.

- Official game: https://kodub.itch.io/polytrack
- Official game page link required by Kodub's terms: https://www.crazygames.com/game/polytrack
- Creator website: https://www.kodub.com/
- Terms of Service: https://www.kodub.com/terms/polytrack
- Unofficial static-asset archive used for the v0.5.2 files: https://github.com/StaticQuasar931/polytrack-0.5.2

This project does not claim ownership of PolyTrack or its game assets. The bundled archive is downloaded at build time, not committed to this repository. The selected 0.5.2 repository notes that its bundle expects an allowed hosted origin; local iOS file loading may need additional compatibility work, so a successful compile does not guarantee the game starts. Review the original creator's current terms before redistributing builds; the terms require non-commercial use, attribution, an obvious unofficial notice, and preservation of outbound links.
