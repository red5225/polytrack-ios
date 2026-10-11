# PolyTrack iOS

An unofficial iOS shell for playing PolyTrack on iPhone. This project currently loads the official PolyTrack page directly in `WKWebView`; it does **not** redistribute or bundle PolyTrack game files.

- Official game: https://kodub.itch.io/polytrack
- Official creator site: https://www.kodub.com/
- Official PolyTrack terms: https://www.kodub.com/terms/polytrack
- Official CrazyGames page (required attribution/link for unofficial reuploads): https://www.crazygames.com/game/polytrack

## Status

**Prototype / CI scaffold.** GitHub Actions builds the iOS Simulator app and uploads it as an artifact. That simulator `.app` cannot be installed on a physical iPhone. A device build requires signing with an Apple development team, and distribution through the App Store would require a separate review of Apple's minimum-functionality rules and the game's permissions/terms.

## Build locally

1. Install Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. From the repository root, run `xcodegen generate`.
3. Open `PolyTrackIOS.xcodeproj` in Xcode.
4. Choose an iPhone simulator and run the `PolyTrackIOS` scheme.

## Important licensing note

This app loads the official page and does not copy game assets or source files into this repository. PolyTrack is created by Kodub; this project is unofficial and not affiliated with or endorsed by Kodub, CrazyGames, Poki, or itch.io. See the official terms before modifying or redistributing the game. If the project later bundles/reuploads game files, that work must comply with the current terms, including non-commercial use, attribution, an obvious unofficial notice, and preserving outbound links.

## CI artifacts

Open **Actions → Build iOS app → latest successful run → Artifacts** to get the simulator build. It is for simulator testing only, not direct iPhone installation.