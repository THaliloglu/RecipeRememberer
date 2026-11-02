# App

## Overview

App entry, shared observable state, top-level navigation, and launch-argument helpers connect scanning and the saved library to SwiftData. Symbols here have app-module visibility; they are not a separately exported package.

## Interface

- [RecipeRemembererApp.swift](./RecipeRemembererApp.swift) — `[RecipeRemembererApp.swift:RecipeRemembererApp]`: `RecipeRemembererApp` owns `AppModel` and the `StoredRecipe` model container, injects both into the window, applies automatic-save launch configuration, and invokes seeding.
- [AppModel.swift](./AppModel.swift) — `[AppModel.swift:AppModel]`: `AppModel` exposes `SaveMode` (`confirmFirst`, `automatic`), `FeedbackStyle`, `RecognitionFeedback`, `PendingRecipeDraft`, and shared `saveMode`, `latestFeedback`, `pendingRecipeDraft`, and `librarySearchText` state.
- [AppModel.swift](./AppModel.swift) — `[AppModel.swift:AppModel]`: `scanCapturedRecipe(_:using:)`, `updatePendingDraft(title:subtitle:)`, `confirmPendingSave(using:)`, and `dismissPendingSave()` coordinate capture review and saving. `duplicateRecipe(title:subtitle:capturePayload:using:)`, `renameRecipe(_:title:subtitle:using:)`, and `deleteRecipe(_:using:)` provide library operations; `dismissLatestFeedback(_:)` clears feedback.
- [RootView.swift](./RootView.swift) — `[RootView.swift:RootView]`: `RootView` presents Scanner and Library tabs, each with a `NavigationStack`, and mirrors shared feedback into an alert.
- [AppStyle.swift](./AppStyle.swift) — `[AppStyle.swift:AppStyle]`: `AppStyle` defines shared section/card spacing, padding, and corner-radius constants.
- [UITestLaunchConfiguration.swift](./UITestLaunchConfiguration.swift) — `[UITestLaunchConfiguration.swift:UITestLaunchConfiguration]`, `[UITestLaunchConfiguration.swift:UITestRecipeSeeder]`: `UITestLaunchConfiguration` reads `-uiTestSeedLibrary`, `-uiTestAutoOpenRecipe`, `-uiTestMockScanner`, `-uiTestMockScannerCapture`, and `-uiTestAutomaticSaveMode`; `shouldOpenLibraryOnLaunch` follows seeding. `UITestRecipeSeeder` provides `seedLibraryIfNeeded(in:)`, `mockScannerAnalysisResult`, `mockScannerPhotoData(isFront:)`, and URL-based `hasUITestInsideMarker(in:)` / `hasUITestOutsideMarker(in:)` checks.

## Invariants

- `[AppModel.swift:AppModel]`: shared observable state is `@MainActor`; save mode starts as `confirmFirst`.
- `[AppModel.swift:scanCapturedRecipe(_:using:)]` and `[AppModel.swift:confirmPendingSave(using:)]`: trim title/subtitle and reject empty titles and detected duplicates before saving. Initial rejected captures clear the pending draft; confirmation rejection retains the draft for editing.
- `[AppModel.swift:storedRecipe(matchingTitle:subtitle:in:)]` and `[AppModel.swift:duplicateRecipe(title:subtitle:capturePayload:using:)]`: normalized title/subtitle matching precedes fuzzy title matching. An empty requested subtitle accepts any matching title; an empty saved subtitle also accepts a nonempty requested subtitle. Fuzzy comparison repeats the title and includes nonempty subtitle and captured OCR text.
- `[AppModel.swift:renameRecipe(_:title:subtitle:using:)]`: trims input, rejects empty titles, and excludes the edited recipe by `persistentModelID` when checking competing snapshots for duplicates.
- `[AppModel.swift:dismissLatestFeedback(_:)]`: passing a feedback value clears only feedback with the same UUID; omitting it clears unconditionally.
- `[RecipeRemembererApp.swift:modelContainer]`: schema contains `StoredRecipe`; seeding or mock-scanner-capture flags select in-memory model storage. Container creation failure terminates with `fatalError`.
- `[UITestLaunchConfiguration.swift:UITestRecipeSeeder.seedLibraryIfNeeded(in:)]`: seeding requires the seed flag and an empty fetched library; fetch failure is treated as empty. `[UITestLaunchConfiguration.swift:UITestRecipeSeeder.mockScannerPhotoData(isFront:)]` returns the guide crop when available, otherwise the full frame.

## Side Effects

- `[AppModel.swift:fetchStoredRecipes(using:)]`: fetches recipes newest-first by `savedAt`; failure sets warning feedback and returns an empty array, so duplicate checking does not propagate a fetch error.
- `[AppModel.swift:saveDraft(_:using:)]`: persists captured photos before inserting/saving a recipe. Success clears the pending draft and library search. Photo failure aborts before insertion; model save failure attempts photo deletion and reports warning feedback, without rolling back the inserted model.
- `[AppModel.swift:renameRecipe(_:title:subtitle:using:)]` and `[AppModel.swift:deleteRecipe(_:using:)]`: mutate the supplied model/context and save, setting success/warning feedback. Save failure does not roll back the mutation. Deletion does not call photo-file cleanup.
- `[RootView.swift:RootView.body]`: observes feedback, presents alerts, and clears matching shared feedback when dismissed.
- `[UITestLaunchConfiguration.swift:UITestRecipeSeeder.seedLibraryIfNeeded(in:)]`: writes generated JPEGs through `RecipePhotoStore`, inserts a recipe, and attempts `context.save()` with ignored errors. In-memory SwiftData configuration does not make these photo files in-memory. Mock-image generation uses UIKit; marker checks read supplied photo URLs.

## Verification

From the repository root, run the command documented in the root README and backed by the shared `RecipeRememberer` scheme:

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

This documentation update does not require running the build or tests.
