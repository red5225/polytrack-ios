# PolyTrack iOS

An unofficial iOS shell for playing PolyTrack on iPhone. This project currently loads the official PolyTrack page directly in `WKWebView`; it does **not** redistribute or bundle PolyTrack game files.

- Official game: https://kodub.itch.io/polytrack
- Official creator site: https://www.kodub.com/
- Official PolyTrack terms: https://www.kodub.com/terms/polytrack
- Official CrazyGames page: https://www.crazygames.com/game/polytrack

## Status

**Prototype.** GitHub Actions builds an **unsigned device IPA** and an iOS Simulator build. The IPA is packaged for import into a sideloading/signing tool; it is **not signed and cannot be installed directly as-is**. Use a trusted sideloading tool such as AltStore or Sideloadly to sign it with your own Apple ID, following that tool's current instructions. Signing typically requires refreshing the app periodically with a free Apple ID; paid Apple Developer accounts have different signing options. Availability and limits may vary by tool and iOS version.

## Get the IPA

1. Open the repository's **Actions** tab: https://github.com/red5225/polytrack-ios/actions/workflows/ios-build.yml
2. Open the latest successful **Build iOS app** run.
3. In **Artifacts**, download `PolyTrack-unsigned-IPA`.
4. Extract the artifact ZIP to get `PolyTrack-unsigned.ipa`.
5. Import the IPA into your chosen sideloading tool and let it sign/install it on your iPhone.

If the build is red, open the failed run and inspect the first failed step before trying to install anything.

## Build locally

1. Install Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. From the repository root, run `xcodegen generate`.
3. Open `PolyTrackIOS.xcodeproj` in Xcode.
4. Choose an iPhone simulator and run the `PolyTrackIOS` scheme.

## Important licensing note

This app loads the official page and does not copy game assets or source files into this repository. PolyTrack is created by Kodub; this project is unofficial and not affiliated with or endorsed by Kodub, CrazyGames, Poki, or itch.io. See the official terms before modifying or redistributing the game. If the project later bundles/reuploads game files, that work must comply with the current terms, including non-commercial use, attribution, an obvious unofficial notice, and preserving outbound links.

## Artifacts

- `PolyTrack-unsigned-IPA`: device build, unsigned; import into a signing/sideloading tool.
- `PolyTrack-iOS-Simulator`: simulator-only app, not installable on a physical iPhone.
