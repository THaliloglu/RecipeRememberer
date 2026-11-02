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
- Stores recipe records locally with `SwiftData` and captured photos in Application Support
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

The app can run in Simulator. Mocked scanning requires the explicit launch arguments below; a normal simulator run does not enable mocks automatically.

## Running The App

1. Open `RecipeRememberer.xcodeproj` in Xcode.
2. Select the `RecipeRememberer` scheme.
3. Choose an iPhone or iPad simulator, or a connected iOS device.
4. Press Run.

### Simulated Scanning

1. Edit the `RecipeRememberer` scheme and select its Run action's Arguments settings.
2. Add and enable `-uiTestMockScanner` and `-uiTestMockScannerCapture` as two separate launch arguments, not environment variables.
3. Select an iPhone or iPad simulator and run the app.
4. Open Scanner, capture the front and back, and use the explicit commit action after the fixed analysis result appears.

The first argument replaces the camera preview and bypasses camera authorization. The second supplies generated photos and a fixed analysis result. Neither argument enables the other; use both for the complete simulator flow. See the [recognition contract](./RecipeRememberer/Features/Recognition/README.md) for the separate branches.

With `Ask First`, commit continues to pending save review. With `Auto Save`, commit attempts to save directly. Duplicate detection and save errors still apply. This flow exercises the capture/save interface without verifying camera hardware or Vision OCR.

Remove or disable both arguments before using the normal camera flow on a device.

### Terminal Build

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'generic/platform=iOS' build
```

## Linting

If `swiftlint` is installed locally, run:

```bash
swiftlint lint --strict
```

## Testing

Run the app unit and UI tests (`RecipeRemembererTests` and `RecipeRemembererUITests`):

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Run the separate core Swift package tests (`RecipeRemembererCoreTests`):

```bash
swift test --package-path Packages/RecipeRemembererCore
```

Run both commands to cover the app and package test suites. The Xcode scheme does not include the package test target. The simulator destination must be installed; choose another available destination if needed. These commands are also listed under [System Verification](#system-verification).

Before preparing a device build or TestFlight archive, set your own Apple Developer team and bundle identifier in Xcode.

## Project Structure

- [App contract](./RecipeRememberer/App/README.md): app entry, tabs, shared app state, UI test launch helpers
- [Recognition contract](./RecipeRememberer/Features/Recognition/README.md): scanner capture flow and save review flow
- [Library contract](./RecipeRememberer/Features/Library/README.md): saved recipe list, edit flow, preview/share flow
- [Models contract](./RecipeRememberer/Models/README.md): `SwiftData` models and photo persistence
- [Core package contract](./Packages/RecipeRemembererCore/README.md): parser, duplicate detection, crop geometry, and layout helpers

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

## System Overview

The SwiftUI app captures recipe-card photos, recognizes their text on-device, and passes capture payloads to `AppModel` for duplicate checking and save decisions. Saved recipes use SwiftData, while front/back images are separate files in Application Support. The library reads saved records and offers editing, preview, sharing, and deletion. See the component contracts for implementation guards and failure paths.

## Subdirectories & System Boundaries

- [Application](./RecipeRememberer/README.md): composition, shared state, features, and persistence models.
- [Packages](./Packages/README.md): the independently testable `RecipeRemembererCore` Swift package.
- [Xcode project](./RecipeRememberer.xcodeproj/project.pbxproj): app and XCTest targets. Its source build phase compiles the core source files directly into the app; the app does not depend on the SwiftPM library product.
- [Shared scheme](./RecipeRememberer.xcodeproj/xcshareddata/xcschemes/RecipeRememberer.xcscheme): app build and the `RecipeRemembererTests` / `RecipeRemembererUITests` testables. Test-only and asset directories have no generated contracts.

## Interface

The [application contract](./RecipeRememberer/README.md) rolls up app-module interfaces; the [core source contract](./Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/README.md) distinguishes public package APIs from internal geometry helpers. There are no production source files directly in this repository root.

## Global Invariants

- `[RecipeRememberer/App/AppModel.swift:AppModel]` is `@MainActor` and `@Observable`; `[RecipeRememberer/App/RecipeRemembererApp.swift:RecipeRemembererApp]` owns and injects it using SwiftUI state/environment.
- `[RecipeRememberer/Models/StoredRecipe.swift:StoredRecipe.refreshNormalizedFields()]` applies `RecipeNormalizer.normalizedKey(for:)` to title/subtitle during initialization and detail updates. Duplicate detection compares these stored keys (`DuplicateRecipeDetector.isDuplicate(title:subtitle:among:)`).
- `[RecipeRememberer/App/RecipeRemembererApp.swift:RecipeRemembererApp.modelContainer]` configures in-memory storage for seeded/mock-capture UI test launches; production uses the default persistent configuration.
- `[Packages/RecipeRemembererCore/Package.swift:package]` requires Swift tools 6.2, Swift language mode 6, and iOS 26.0 / macOS 15.0 minimum platforms. The Xcode project sets the iOS deployment target to 26.0 and Swift language mode to 6.

## Global Side Effects

- `[RecipeRememberer/Features/Recognition/RecipeCardCameraView.swift:RecipeCardCameraView]` uses camera capture; `[RecipeRememberer/Features/Recognition/RecipePhotoAnalyzer.swift:RecipePhotoAnalyzer.analyze]` performs on-device OCR.
- `[RecipeRememberer/App/AppModel.swift:AppModel]` mutates observable state and saves/inserts/deletes SwiftData records. `[RecipeRememberer/Models/RecipePhotoStore.swift:RecipePhotoStore]` creates and accesses `Application Support/RecipePhotos`; writes are atomic per file, not transactional across both photos and SwiftData.
- `[RecipeRememberer/App/AppModel.swift:AppModel.deleteRecipe(_:using:)]` does not delete photo files. Persistence error handling and cleanup boundaries are documented in the App and Models contracts.
- Library sharing presents a system share flow (`RecipeRememberer/Features/Library/SavedRecipePhotoGallerySection.swift`).

## System Verification

Run from this repository root:

```sh
swift test --package-path Packages/RecipeRemembererCore
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The simulator command requires that device/runtime to be installed; select another available destination if needed. These commands target the package manifest and shared Xcode scheme, respectively. Documentation bootstrap validates contracts and links without claiming a fresh application test run.
