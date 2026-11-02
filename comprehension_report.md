## What this proposes

Update four existing READMEs to resolve seven documentation drift findings without changing application code or behavior. The corrections distinguish the app and package test suites, give explicit simulator mock setup instructions, and explain parser metadata classification, adaptive photo actions, title-selection boundaries, independent mock switches, and persisted analysis summaries. Completion requires source-based verification, link and Markdown checks, and a disposition for each original finding.

## How the existing system works, per this document

The app scheme and core Swift package have separately configured test suites. Simulated scanning requires two independent switches: one replaces the preview and bypasses camera authorization, while the other generates captured images and substitutes analysis; saving still requires an explicit commit. Recognition prefers parser output over analyzer candidates, applies metadata filtering differently across parser decisions, and builds a conditional summary that is copied into the saved record. Photo actions try a horizontal arrangement before falling back to a vertical stack when the available space is insufficient.

## Findings

No Blocker, Major, or Nit comprehension findings. The proposal defines its scope, connects each correction to existing behavior and source evidence, and explains the exceptions needed to avoid misleading universal claims.

## Read receipt

Read the Comprehension persona first, the complete target document (lines 1–199), and all directly linked or explicitly referenced files: the drift report; root, core-source, library, and recognition READMEs; shared Xcode scheme; package manifest; `UITestLaunchConfiguration.swift` (including `UITestRecipeSeeder`); `RecipeCardTextParser.swift`; `SavedRecipePhotoGallerySection.swift`; `SavedRecipePhotoActionLayout.swift`; `RecipePhotoAnalyzer.swift`; `LiveTitleScannerView.swift`; and `AppModel.swift`. Proposed inline source links were interpreted relative to the README being described. No inaccessible inputs; no writes, builds, or other review reports.
