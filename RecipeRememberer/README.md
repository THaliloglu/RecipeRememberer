# Recipe Rememberer App

## Overview

SwiftUI application composition, scanning and library features, and local recipe persistence. The app entry injects one `AppModel` and a `StoredRecipe` model container (`App/RecipeRemembererApp.swift:RecipeRemembererApp`).

## Subdirectories & Boundaries

- [App](./App/README.md): entry point, navigation, shared state, save decisions, and UI test launch configuration.
- [Features](./Features/README.md): recognition/capture and saved-library user interfaces.
- [Models](./Models/README.md): capture payload, SwiftData model, and photo file store.

## Interface

`[App/RecipeRemembererApp.swift:RecipeRemembererApp]` installs `RootView`, provides `AppModel` through the environment, and supplies the model container. The child contracts define module-internal app interfaces. Core algorithm sources are compiled directly into the app by `RecipeRememberer.xcodeproj/project.pbxproj:PBXSourcesBuildPhase`.

## Invariants

- `[App/AppModel.swift:AppModel]` is `@MainActor` and `@Observable`; the root owns it with `@State` (`RecipeRemembererApp`).
- `[Models/StoredRecipe.swift:StoredRecipe.refreshNormalizedFields()]` derives normalized keys from title/subtitle in initialization and `updateDetails(title:subtitle:)`.
- `[App/RecipeRemembererApp.swift:RecipeRemembererApp.modelContainer]` uses in-memory SwiftData storage when library seeding or mock scanner capture is enabled; otherwise it creates the configured persistent container. Container creation failure is fatal.
- `[Models/RecipePhotoStore.swift:RecipePhotoStore.persistPhotos(from:recipeID:)]` writes front/back files separately; the pair is not a single transaction with SwiftData.

## Side Effects

- `[Features/Recognition/RecipeCardCameraView.swift:RecipeCardCameraView]` provides camera capture; `[Features/Recognition/RecipePhotoAnalyzer.swift:RecipePhotoAnalyzer.analyze]` runs on-device text recognition.
- `[App/AppModel.swift:AppModel]` changes observable state and SwiftData records. `[Models/RecipePhotoStore.swift:RecipePhotoStore]` creates and accesses `Application Support/RecipePhotos`.
- `[App/AppModel.swift:AppModel.deleteRecipe(_:using:)]` deletes a SwiftData record without removing its photo files; see the App and Models contracts for failure behavior.

## Verification

From the repository root, using the shared scheme and an installed matching simulator:

```sh
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Core algorithms are also covered independently with `swift test --package-path Packages/RecipeRemembererCore`.
