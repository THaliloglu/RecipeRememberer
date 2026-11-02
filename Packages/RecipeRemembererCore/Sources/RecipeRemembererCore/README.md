# Recipe Rememberer Core Algorithms

## Overview

Synchronous value-based parsing, normalization, duplicate matching, crop geometry, and photo action layout. SwiftPM exports this directory as `RecipeRemembererCore`; the Xcode app also compiles these same source files directly into its own module (`RecipeRememberer.xcodeproj/project.pbxproj`, `PBXSourcesBuildPhase`).

## Interface

| Source | Contract |
| --- | --- |
| [RecipeNormalizer.swift](./RecipeNormalizer.swift) | Public `RecipeNormalizer.normalizedKey(for:)` and `normalizedTokens(for:)` normalize text for matching. |
| [RecipeCardTextParser.swift](./RecipeCardTextParser.swift) | Public `RecipeCardTextLine` and `RecipeCardScanResult` are immutable `Equatable`, `Sendable` values. `RecipeCardTextParser.parse(from:preferredTitle:)` returns an optional title/subtitle result. |
| [SavedRecipeSnapshot.swift](./SavedRecipeSnapshot.swift) | Public immutable `SavedRecipeSnapshot` carries display strings, normalized strings, and front/back recognized text; it is `Equatable` and `Sendable`. |
| [DuplicateRecipeDetector.swift](./DuplicateRecipeDetector.swift) | Public `DuplicateRecipeDetector.isDuplicate(title:subtitle:among:)` returns a Boolean; `bestTitleMatch(for:among:)` returns an optional snapshot. |
| [RecipePhotoCropGeometry.swift](./RecipePhotoCropGeometry.swift) | Internal `RecipePhotoImageOrientation` and `RecipePhotoCropGeometry.uprightNormalizedRect(from:for:)` provide eight orientation transforms; these are not public SwiftPM API. |
| [SavedRecipePhotoActionLayout.swift](./SavedRecipePhotoActionLayout.swift) | Public `SavedRecipePhotoActionLayout` exposes minimum button width 112, height 44, spacing 12, and minimum horizontal row width 236. |

## Invariants

- `[RecipeNormalizer.swift:RecipeNormalizer.normalizedKey(for:)]` folds case/diacritics using the current locale, replaces whole-word `and` and non-ASCII-alphanumeric runs with spaces, trims, then lowercases. `normalizedTokens(for:)` removes one-character tokens and configured stop words.
- `[SavedRecipeSnapshot.swift:SavedRecipeSnapshot.init]` stores supplied normalized fields unchanged. Callers must supply consistent keys when matching depends on them.
- `[DuplicateRecipeDetector.swift:DuplicateRecipeDetector.isDuplicate(title:subtitle:among:)]` requires equal normalized titles. Empty candidate or saved subtitles, or equal subtitle keys, match; otherwise nonempty subtitle token sets must overlap by at least `max(2, min(token counts) - 1)`.
- `[DuplicateRecipeDetector.swift:DuplicateRecipeDetector.bestTitleMatch(for:among:)]` returns the highest-scoring candidate only if its score is at least 10, its title-signal guard passes, and shared title/subtitle/front tokens total at least three.
- `[RecipeCardTextParser.swift:RecipeCardTextParser.parse(from:preferredTitle:)]` trims and drops empty OCR lines, sorts by ascending `minY` then `minX`, anchors using a preferred title or nonmetadata scoring, and returns `nil` without an anchor or nonempty cleaned title.
- Private `PreparedLine` classifies a trimmed one- or two-digit transcript as a numeric badge and metadata. Other lines are metadata when their normalized text matches a configured `metadataTerms` entry through `localizedStandardContains`, including terms such as `min`, `kcal`, and `protein`. This is not exact whole-word matching and does not require digits in a line containing a metadata term. The source list is authoritative. [RecipeCardTextParser.swift](./RecipeCardTextParser.swift): `PreparedLine.extractBadgeValue(from:)`, `PreparedLine.isMetadataLine(transcript:normalizedText:recognizedBadgeValue:)`, and `PreparedLine.metadataTerms`.
- Metadata lines are excluded from fallback anchor candidates, are not joined during title expansion, and are skipped during subtitle selection. Preferred-title equality and containment checks run before fallback filtering and can select a metadata anchor; metadata is not universally removed from parser input. `[RecipeCardTextParser.swift:RecipeCardTextParser.anchorIndex(in:preferredTitle:)]`, `shouldJoinTitleLine(previous:next:)`, and `subtitleCandidate(after:in:titleFrame:)`.
- `[RecipeCardTextParser.swift:RecipeCardTextParser.shouldJoinTitleLine(previous:next:)]` joins nearby, similarly sized, aligned nonmetadata lines. `subtitleCandidate(after:in:titleFrame:)` selects the first nearby subsequent nonmetadata line, or yields an empty subtitle through `parse`.
- `[RecipePhotoCropGeometry.swift:RecipePhotoCropGeometry.uprightNormalizedRect(from:for:)]` applies orientation, standardizes the result, and intersects it with the unit rectangle.

## Side Effects

None. These functions return values without filesystem, network, persistence, or camera operations. Normalization reads the current locale (`RecipeNormalizer.normalizedKey(for:)`).

## Verification

From the repository root:

```sh
swift test --package-path Packages/RecipeRemembererCore
```

The package test target is `RecipeRemembererCoreTests` (`../../Package.swift:package`).
