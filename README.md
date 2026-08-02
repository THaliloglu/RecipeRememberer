# Recipe Rememberer

Recipe Rememberer is an iPhone and iPad app for scanning printed recipe cards, detecting likely duplicates, and saving them into a private on-device library.

## Project Status

This is a vibe-coded project that was iterated quickly and then tightened into a cleaner shipping baseline.

## What It Does

- Captures front and back photos of a printed recipe card
- Runs on-device OCR over both photos
- Detects recipe title and subtitle from the front card
- Checks the detected recipe against saved recipes with fuzzy text matching
- Supports `Ask First` and `Auto Save` save modes
- Stores recipes and captured card photos locally with `SwiftData`
- Lets you preview, share, rename, and delete saved recipes

## Tech Stack

- Swift 6
- SwiftUI
- SwiftData
- Vision
- AVFoundation
- XCTest for app and UI coverage
- Swift Testing for core package coverage

## Requirements

- Xcode 26.3 or later
- iOS 26.0 or later
- A real iPhone or iPad for camera capture

The app can run in Simulator, but camera capture is mocked there for UI testing.

## Running The App

1. Open `RecipeRememberer.xcodeproj` in Xcode.
2. Select the `RecipeRememberer` scheme.
3. Choose an iPhone or iPad simulator, or a connected iOS device.
4. Press Run.

Terminal build:

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'generic/platform=iOS' build
```

## Linting

If `swiftlint` is installed locally, run:

```bash
swiftlint lint --strict
```

## Testing

Run the full test suite:

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Before preparing a device build or TestFlight archive, set your own Apple Developer team and bundle identifier in Xcode.

## Project Structure

- `RecipeRememberer/App`: app entry, tabs, shared app state, UI test launch helpers
- `RecipeRememberer/Features/Recognition`: scanner capture flow and save review flow
- `RecipeRememberer/Features/Library`: saved recipe list, edit flow, preview/share flow
- `RecipeRememberer/Models`: `SwiftData` models and photo persistence
- `Packages/RecipeRemembererCore`: parser, duplicate detection, crop geometry, and layout helpers

## Privacy

- Recipes stay on-device.
- No account is required.
- No analytics or advertising SDKs are included.

## Release Notes

- Support draft: [SUPPORT.md](SUPPORT.md)
- Privacy draft: [PRIVACY.md](PRIVACY.md)
- App Store metadata draft: [AppStoreMetadata.md](AppStoreMetadata.md)

## License

Released under the [MIT License](LICENSE).
