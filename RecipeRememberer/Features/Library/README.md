# Library

## Overview

The saved-recipe browser, edit sheet, and photo preview/share UI. These views use the environment's `AppModel` and SwiftData model context; persistence operations remain in `AppModel`.

## Interface

All listed views have module-internal visibility; this directory declares no `public` API.

- [LibraryView.swift](./LibraryView.swift): `LibraryView` queries `StoredRecipe` by descending `savedAt`, filters the list, and presents editing and deletion controls. [LibraryView.swift:LibraryView]
- [EditRecipeSheet.swift](./EditRecipeSheet.swift): `EditRecipeSheet.init(recipe:)` initializes editable title/subtitle state from a stored recipe and includes its photo gallery. [EditRecipeSheet.swift:EditRecipeSheet]
- [SavedRecipeRow.swift](./SavedRecipeRow.swift): `SavedRecipeRow` displays recipe metadata and photo count. [SavedRecipeRow.swift:SavedRecipeRow]
- [SavedRecipeRowThumbnail.swift](./SavedRecipeRowThumbnail.swift): `SavedRecipeRowThumbnail` displays the front image or a fallback, with a count badge for multiple photos. [SavedRecipeRowThumbnail.swift:SavedRecipeRowThumbnail]
- [SavedRecipePhotoGallerySection.swift](./SavedRecipePhotoGallerySection.swift): `SavedRecipePhotoGallerySection` displays front/back photo cards with preview and sharing actions. Private helpers implement full-screen preview and a UIKit scroll view for zooming. [SavedRecipePhotoGallerySection.swift:SavedRecipePhotoGallerySection] [SavedRecipePhotoGallerySection.swift:ZoomableRecipePhotoScrollView]

## Invariants

- Empty search returns the complete query result; otherwise title and subtitle are matched using `localizedStandardContains`. [LibraryView.swift:filteredRecipes]
- Swipe deletion requires confirmation, disallows full swipe, and clears the pending deletion on confirmation, cancellation, or dialog dismissal. [LibraryView.swift:body]
- Save appears only when title/subtitle differ from the stored values, is disabled for a whitespace-only title, and dismisses the sheet only when `renameRecipe` returns `true`. [EditRecipeSheet.swift:hasChanges] [EditRecipeSheet.swift:body]
- Gallery assets are ordered Front then Back and included only when `RecipePhotoStore.url(for:)` returns a URL. An unreadable image receives an unavailable-state view. [SavedRecipePhotoGallerySection.swift:photos] [SavedRecipePhotoGallerySection.swift:SavedRecipePhotoThumbnail]
- Private `SavedRecipePhotoActionRow.body` uses `ViewThatFits(in: .horizontal)` to try the Preview/Share horizontal row first, then a vertical stack when that row does not fit. The horizontal candidate uses `SavedRecipePhotoActionLayout.minimumHorizontalRowWidth`; spacing and minimum button height use `actionButtonSpacing` and `minimumActionButtonHeight`. The row minimum is 236 points in its available space, not a screen-width or orientation breakpoint. See [gallery source](./SavedRecipePhotoGallerySection.swift) and `SavedRecipePhotoActionLayout` at repository path `/Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/SavedRecipePhotoActionLayout.swift`.
- Preview zoom ranges from 1 to 6. Changing image identity resets zoom; assigning the same identity leaves the existing image intact. [SavedRecipePhotoGallerySection.swift:ZoomableImageContainerView.configureView()] [SavedRecipePhotoGallerySection.swift:ZoomableImageContainerView.setImage(_:identifier:)]
- UI-test auto-opening requires `shouldAutoOpenRecipe`, a first saved recipe, and no prior auto-opening in the current view instance. [LibraryView.swift:hasAutoOpenedUITestRecipe] [LibraryView.swift:body]

## Side Effects

- Editing calls `AppModel.renameRecipe(_:title:subtitle:using:)`; confirmed deletion calls `AppModel.deleteRecipe(_:using:)`, passing the environment's model context. Row/rename actions present the edit sheet. [EditRecipeSheet.swift:body] [LibraryView.swift:body]
- Thumbnail and preview views resolve saved-photo URLs and synchronously load images using `UIImage(contentsOfFile:)`. [SavedRecipeRowThumbnail.swift:thumbnailContent] [SavedRecipePhotoGallerySection.swift:SavedRecipePhotoThumbnail] [SavedRecipePhotoGallerySection.swift:ZoomableSavedPhotoView]
- Preview selection presents a full-screen cover; `ShareLink` exposes the saved photo URL to system sharing. Zoom delegate callbacks update SwiftUI state through the bridge's binding. [SavedRecipePhotoGallerySection.swift:SavedRecipePhotoGallerySection] [SavedRecipePhotoGallerySection.swift:ShareRecipePhotoButton] [SavedRecipePhotoGallerySection.swift:ZoomableRecipePhotoScrollView]
- With `shouldUseMockScannerCapture`, preview accessibility labels call `UITestRecipeSeeder` marker checks against the photo URL. [SavedRecipePhotoGallerySection.swift:SavedRecipePhotoPreviewScreen]

## Verification

From the repository root, run the app scheme's configured unit and UI tests:

```sh
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The command is documented in the repository README and the shared scheme includes `RecipeRemembererTests` and `RecipeRemembererUITests`.
