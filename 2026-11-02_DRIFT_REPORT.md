## README.md

- **Test command overstatement:** “Run the full test suite” labels an `xcodebuild ... test` command that runs only `RecipeRemembererTests` and `RecipeRemembererUITests`. The shared scheme does not include the separate SwiftPM `RecipeRemembererCoreTests` target. Relabel this as the app test suite and include the existing `swift test --package-path Packages/RecipeRemembererCore` command here, or link to System Verification. Evidence: [README](./README.md#testing), [scheme testables](./RecipeRememberer.xcodeproj/xcshareddata/xcschemes/RecipeRememberer.xcscheme), [package manifest](./Packages/RecipeRemembererCore/Package.swift) (`package.targets`).
- **Simulator setup omission:** The simulator note says capture is mocked for UI testing, but Running The App does not explain that mocks require explicit launch flags. `LiveTitleScannerView.cameraSurface` and `scannerState` use `-uiTestMockScanner`; `captureCurrentSide` and `analyzeCapturedPhotos` independently use `-uiTestMockScannerCapture`. A normal simulator launch does not automatically enable either. Document both flags for the complete simulated capture flow. Evidence: [launch configuration](./RecipeRememberer/App/UITestLaunchConfiguration.swift) (`UITestLaunchConfiguration`, lines 9–10), [scanner](./RecipeRememberer/Features/Recognition/LiveTitleScannerView.swift) (lines 169, 185, 236, 277).

## Packages/README.md

No drift detected.

## Packages/RecipeRemembererCore/README.md

No drift detected.

## Packages/RecipeRemembererCore/Sources/README.md

No drift detected.

## Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/README.md

- **Metadata classification coverage gap:** The parser contract refers to “nonmetadata” lines without documenting the exclusion policy that determines title/subtitle selection. `PreparedLine.extractBadgeValue(from:)` marks one- or two-digit strings as metadata; `isMetadataLine` also marks lines containing configured terms such as `min`, `kcal`, and `protein`. Describe this policy and cite `PreparedLine`; it can exclude a line before fallback anchoring or subtitle selection. Evidence: [contract](./Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/README.md#invariants), [parser](./Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/RecipeCardTextParser.swift) (`PreparedLine`, lines 229–293; `anchorIndex`, lines 83–112).

## RecipeRememberer/README.md

No drift detected.

## RecipeRememberer/App/README.md

No drift detected.

## RecipeRememberer/Features/README.md

No drift detected.

## RecipeRememberer/Features/Library/README.md

- **Adaptive action layout coverage gap:** The contract documents preview/share actions but omits their horizontal-to-vertical fallback. `SavedRecipePhotoActionRow.body` uses `ViewThatFits(in: .horizontal)`, tries a horizontal row with `SavedRecipePhotoActionLayout.minimumHorizontalRowWidth`, then stacks the buttons vertically when the row does not fit. Document this behavior and its dependency on the core layout constants. Evidence: [contract](./RecipeRememberer/Features/Library/README.md), [gallery](./RecipeRememberer/Features/Library/SavedRecipePhotoGallerySection.swift) (`SavedRecipePhotoActionRow`, lines 78–101), [layout constants](./Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/SavedRecipePhotoActionLayout.swift).

## RecipeRememberer/Features/Recognition/README.md

- **Title constraint is too broad:** “Candidate titles require at least six characters and two words” does not distinguish analyzer candidates from parser output. `isLikelyFrontTitleLine` applies those constraints to prominent/fallback candidates, but `analyze` first accepts `RecipeCardTextParser.parse` output. The parser has no equivalent length/word minimum; a single nonmetadata line such as `Soup` with no preferred title can produce a title. Qualify the constraint as applying only to analyzer candidate selection. Evidence: [contract](./RecipeRememberer/Features/Recognition/README.md#invariants), [analyzer](./RecipeRememberer/Features/Recognition/RecipePhotoAnalyzer.swift) (`analyze`, lines 21–25; `isLikelyFrontTitleLine`, lines 224–245), [parser](./Packages/RecipeRemembererCore/Sources/RecipeRemembererCore/RecipeCardTextParser.swift) (`parse`, `anchorIndex`).
- **Mock configuration coverage gap:** The contract describes mock scanner configuration and mock capture without identifying their separate switches. `shouldUseMockScanner` bypasses camera authorization and substitutes the preview; `shouldUseMockScannerCapture` supplies generated images and bypasses Vision analysis. Neither flag enables the other. Document this distinction so mock-preview launches are not mistaken for complete simulated capture. Evidence: [launch configuration](./RecipeRememberer/App/UITestLaunchConfiguration.swift) (`UITestLaunchConfiguration`, lines 9–10), [scanner](./RecipeRememberer/Features/Recognition/LiveTitleScannerView.swift) (`cameraSurface`, `scannerState`, `captureCurrentSide`, `analyzeCapturedPhotos`).
- **Analysis-summary generation coverage gap:** The contract lists `analysisSummary` as a result field but omits its implemented content policy: optional subtitle, a cooking-time range and calorie match extracted from front OCR, front/back line counts, and a conditional back-OCR note. Add this behavior and cite `analysisSummary(...)` / `firstMatch(in:for:)`; the summary is persisted in `StoredRecipe`. Evidence: [analyzer](./RecipeRememberer/Features/Recognition/RecipePhotoAnalyzer.swift) (lines 173–222), [save path](./RecipeRememberer/App/AppModel.swift) (`saveDraft(_:using:)`).

## RecipeRememberer/Models/README.md

No drift detected.
