# Core Sources

## Overview

Source tree for the `RecipeRemembererCore` SwiftPM library target (`../Package.swift:package`).

## Subdirectories & Boundaries

- [RecipeRemembererCore](./RecipeRemembererCore/README.md): normalization, OCR line parsing, duplicate matching, orientation geometry, and photo action layout.

## Interface

The child contract lists the exported value types and algorithms, and distinguishes internal crop geometry from public package API.

## Invariants

`RecipeNormalizer.normalizedKey(for:)` defines the matching keys used by `DuplicateRecipeDetector`; `SavedRecipeSnapshot.init` accepts precomputed keys unchanged. See the child contract for exact guards.

## Side Effects

None in this directory; the child algorithms have no persistence or camera operations.

## Verification

From the repository root: `swift test --package-path Packages/RecipeRemembererCore`.
