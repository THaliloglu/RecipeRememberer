# Recipe Rememberer

Scan printed HelloFresh recipe titles, detect duplicates, and build a local recipe card library on iPhone and iPad.

Point the camera at a recipe title, capture the text with `VisionKit`, compare it against your saved recipes, and save new cards into a local on-device library.

## About This Project

This is a vibe-coded project.

That means it was built through fast iteration and AI-assisted pairing, then cleaned up into a repo that is easier to run, understand, and publish. The current codebase is focused on the working iOS title-scanning flow rather than the earlier experimental visionOS ideas.

## Features

- Live recipe title scanning with `DataScannerViewController`
- Manual title entry fallback when live scanning is unavailable
- Duplicate detection against previously saved recipes
- Local persistence with `SwiftData`
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
- The project currently matches recipes primarily by recognized title text.
- This project is not affiliated with HelloFresh.
- Released under the [MIT License](LICENSE).

## GitHub Publishing Checklist

- Personal signing values were removed from the Xcode project.
- The bundle identifier was replaced with a generic example identifier.
- Local Xcode and SwiftPM build artifacts are ignored by [`.gitignore`](.gitignore).
