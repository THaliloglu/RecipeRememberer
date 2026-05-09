# Recipe Rememberer

Scan printed HelloFresh recipe titles, detect duplicates, and build a local recipe card library on iPhone and iPad.

Point the camera at a recipe title, capture the text with `VisionKit`, compare it against your saved recipes, and save new cards into a local on-device library.

## About This Project

This is a vibe-coded project.

That means it was built through fast iteration and AI-assisted pairing, then cleaned up into a repo that is easier to run, understand, and publish. The current codebase is focused on the working iOS title-scanning flow rather than the earlier experimental visionOS ideas.

## Features

- Live recipe title scanning with `DataScannerViewController`
- Manual title entry fallback when live scanning is unavailable
- Duplicate detection using title, subtitle, and optional HelloFresh code signals
- Local persistence with `SwiftData`
- Review-and-edit flow before saving live scanner captures
- Rename and delete controls for saved recipes
- Recent save feedback after each scan
- Searchable recipe library
- iPhone and iPad support

## Tech Stack

- Swift 6
- SwiftUI
- SwiftData
- VisionKit
- Xcode project, no third-party dependencies

## Requirements

- Xcode 26.3 or later
- iOS 26.0 or later
- A real iPhone or iPad for live camera scanning

The app runs in Simulator, but the camera-based title scanner is limited there. Manual title entry still works.

## Run The App

1. Open `RecipeRememberer.xcodeproj` in Xcode.
2. Select the `RecipeRememberer` scheme.
3. Choose an iPhone or iPad simulator, or a connected iOS device.
4. Press Run.

You can also build from Terminal:

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'generic/platform=iOS' build
```

## Project Structure

- [`RecipeRememberer/App`](RecipeRememberer/App): app entry, tabs, and shared app model
- [`RecipeRememberer/Features/Recognition`](RecipeRememberer/Features/Recognition): scanner flow and feedback UI
- [`RecipeRememberer/Features/Library`](RecipeRememberer/Features/Library): saved recipe list and search
- [`RecipeRememberer/Models`](RecipeRememberer/Models): `SwiftData` models
- [`Packages/RecipeRemembererCore`](Packages/RecipeRemembererCore): matching and normalization logic

## Notes

- Recipes are stored locally on the device.
- The live scanner is strongest when the printed title is clearly framed and well lit.
- This project is not affiliated with HelloFresh.
- Released under the [MIT License](LICENSE).

## Release Prep

- Support notes: [SUPPORT.md](SUPPORT.md)
- Privacy draft: [PRIVACY.md](PRIVACY.md)
- App Store metadata draft: [AppStoreMetadata.md](AppStoreMetadata.md)

## GitHub Publishing Checklist

- Personal signing values were removed from the Xcode project.
- The bundle identifier was replaced with a publishable placeholder identifier.
- Local Xcode and SwiftPM build artifacts are ignored by [`.gitignore`](.gitignore).
