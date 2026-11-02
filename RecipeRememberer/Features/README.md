# Features

## Overview

This directory groups the scanner and saved-library UI. It has no direct source files; its contracts are the module-internal interfaces documented below.

## Subdirectories & Boundaries

- [Recognition](./Recognition/README.md): two-photo capture, OCR, and pending-save review. [Recognition/ScannerDashboardView.swift:ScannerDashboardView] [Recognition/RecipePhotoAnalyzer.swift:RecipePhotoAnalyzer]
- [Library](./Library/README.md): saved recipe browsing, editing, deletion confirmation, and photo preview/sharing. [Library/LibraryView.swift:LibraryView] [Library/SavedRecipePhotoGallerySection.swift:SavedRecipePhotoGallerySection]

## Interface

- Scanner entry: `ScannerDashboardView`; library entry: `LibraryView`. Both obtain `AppModel` from the SwiftUI environment. [Recognition/ScannerDashboardView.swift:ScannerDashboardView] [Library/LibraryView.swift:LibraryView]
- Recognition passes a `RecipeCapturePayload` to `AppModel.scanCapturedRecipe`; Library calls `AppModel` for rename and deletion. These features delegate persistence policy to the app layer. [Recognition/LiveTitleScannerView.swift:commitDetectedRecipe] [Library/EditRecipeSheet.swift:body] [Library/LibraryView.swift:body]

## Invariants

- Scanner commit requires an analysis result and both captured images. Pending review requires a draft with a capture payload and disables saving for an empty trimmed title or detected duplicate. [Recognition/LiveTitleScannerView.swift:commitDetectedRecipe] [Recognition/PendingSaveCard.swift:PendingSaveCard] [Recognition/PendingSaveCard.swift:PendingRecipeDraftEditor]
- Library search matches title/subtitle using `localizedStandardContains`, and deletion requires confirmation. [Library/LibraryView.swift:filteredRecipes] [Library/LibraryView.swift:body]

## Side Effects

- Recognition requests camera permission, operates capture hardware, runs Vision OCR, and calls app-layer save/review operations. [Recognition/LiveTitleScannerView.swift:requestCameraAccess] [Recognition/RecipeCardCameraView.swift:RecipeCardCameraViewController] [Recognition/RecipePhotoAnalyzer.swift:RecipePhotoAnalyzer] [Recognition/PendingSaveCard.swift:PendingSaveCard]
- Library queries SwiftData, delegates mutations to `AppModel`, reads saved image files, and offers system sharing. [Library/LibraryView.swift:LibraryView] [Library/EditRecipeSheet.swift:body] [Library/SavedRecipePhotoGallerySection.swift:SavedRecipePhotoThumbnail] [Library/SavedRecipePhotoGallerySection.swift:ShareRecipePhotoButton]

## Verification

From the repository root, run the configured app test scheme:

```sh
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
