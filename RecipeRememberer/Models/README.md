# Models

## Overview

App-module data types bridge recognition, SwiftData records, and captured photo files. SwiftData stores recipe metadata and filenames; `RecipePhotoStore` writes the image bytes separately under Application Support.

## Interface

- [RecipeCapturePayload.swift](./RecipeCapturePayload.swift) — `[RecipeCapturePayload.swift:RecipeCapturePayload]`: `RecipeCapturePayload` is an immutable `Equatable`, `Sendable` value carrying title, subtitle, source description, front/back image `Data`, front/back recognized text, and an analysis summary.
- [StoredRecipe.swift](./StoredRecipe.swift) — `[StoredRecipe.swift:StoredRecipe]`: `StoredRecipe` is the SwiftData `@Model`. Its initializer stores recipe details, optional photo filenames, and OCR/analysis text; `updateDetails(title:subtitle:)` edits names. `snapshot` produces a core `SavedRecipeSnapshot`; `savedPhotoCount` counts non-nil photo filenames. Stored fields also include normalized title/subtitle and `savedAt` / `updatedAt` timestamps.
- [RecipePhotoStore.swift](./RecipePhotoStore.swift) — `[RecipePhotoStore.swift:StoredRecipePhotoAssets]`, `[RecipePhotoStore.swift:RecipePhotoStore]`: `StoredRecipePhotoAssets` carries optional front/back filenames and `hasSavedPhotos`. `RecipePhotoStore.persistPhotos(from:recipeID:)` throws and returns those assets; `deletePhotos(frontPhotoFilename:backPhotoFilename:)` performs best-effort removal; `url(for:)` resolves an optional filename.

## Invariants

- `[StoredRecipe.swift:StoredRecipe.init]`, `[StoredRecipe.swift:StoredRecipe.updateDetails(title:subtitle:)]`, and `[StoredRecipe.swift:StoredRecipe.refreshNormalizedFields()]`: initialization and detail updates regenerate normalized keys through `RecipeNormalizer.normalizedKey(for:)`. Other direct property assignments do not invoke this helper. Detail updates refresh `updatedAt`; all persisted fields have defaults or are optional.
- `[StoredRecipe.swift:StoredRecipe.savedPhotoCount]` and `[RecipePhotoStore.swift:StoredRecipePhotoAssets.hasSavedPhotos]`: photo presence is determined by non-nil filenames, not file existence.
- `[RecipePhotoStore.swift:RecipePhotoStore.persistPhotos(from:recipeID:)]`: filenames are `recipe-<recipeID>-front.jpg` and `recipe-<recipeID>-back.jpg`. Front and back bytes are written sequentially with per-file `.atomic` options; a later failure does not clean up an earlier write. The function writes supplied data without image conversion or validation.
- `[RecipePhotoStore.swift:RecipePhotoStore.url(for:)]`: nil filenames or directory-creation failure return nil; otherwise the URL is returned without checking the image file exists.

## Side Effects

- `[StoredRecipe.swift:StoredRecipe.updateDetails(title:subtitle:)]`: mutates names, normalized keys, and the update timestamp. The model methods do not explicitly save a `ModelContext` or manage photo files.
- `[RecipePhotoStore.swift:RecipePhotoStore.photosDirectory()]`: creates `URL.applicationSupportDirectory/RecipePhotos` with intermediate directories. Persistence, deletion with nonempty filenames, and URL resolution with a non-nil filename all call this helper.
- `[RecipePhotoStore.swift:RecipePhotoStore.persistPhotos(from:recipeID:)]`: writes or replaces two files in that directory and propagates directory/write errors. Reusing a recipe ID reuses its filenames.
- `[RecipePhotoStore.swift:RecipePhotoStore.deletePhotos(frontPhotoFilename:backPhotoFilename:)]`: attempts to remove each supplied non-nil filename and ignores directory/removal errors; no filenames means no directory access.

## Verification

From the repository root, run the command documented in the root README and backed by the shared `RecipeRememberer` scheme:

```bash
xcodebuild -project RecipeRememberer.xcodeproj -scheme RecipeRememberer -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

This documentation update does not require running the build or tests.
