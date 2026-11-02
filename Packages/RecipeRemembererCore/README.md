# Recipe Rememberer Core

## Overview

Swift package containing value-based recipe recognition and matching helpers. `[Package.swift:package]` declares Swift tools 6.2, Swift language mode 6, iOS 26.0 and macOS 15.0 minimum platforms, with no external package dependencies.

## Subdirectories & Boundaries

- [Sources](./Sources/README.md): the `RecipeRemembererCore` library target.
- [Package manifest](./Package.swift): the library product and `RecipeRemembererCoreTests` target. Tests remain outside the generated contract tree.

## Interface

`[Package.swift:package]` exports the `RecipeRemembererCore` library. Public APIs include `RecipeNormalizer`, `RecipeCardTextParser`, `DuplicateRecipeDetector`, `SavedRecipeSnapshot`, and `SavedRecipePhotoActionLayout`; the source contract describes their boundaries.

## Invariants

`[Package.swift:package]` makes the test target depend on the library target. `[Sources/RecipeRemembererCore/SavedRecipeSnapshot.swift:SavedRecipeSnapshot.init]` accepts normalized keys unchanged; matching callers must keep these consistent with `RecipeNormalizer`.

## Side Effects

None in the production algorithms. They do not persist recipes, access the camera, or perform networking.

## Verification

From the repository root:

```sh
swift test --package-path Packages/RecipeRemembererCore
```
