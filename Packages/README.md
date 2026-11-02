# Packages

## Overview

Local Swift package boundary for recipe algorithms reused by the app source build.

## Subdirectories & Boundaries

- [RecipeRemembererCore](./RecipeRemembererCore/README.md): library product, production algorithms, and SwiftPM test target.

## Interface

`[RecipeRemembererCore/Package.swift:package]` declares the `RecipeRemembererCore` library product and `RecipeRemembererCoreTests` target.

## Invariants

The package uses Swift tools 6.2 and Swift language mode 6, with iOS 26.0 and macOS 15.0 minimum platforms (`RecipeRemembererCore/Package.swift:package`).

## Side Effects

None in the core algorithms; application persistence and capture live in the app subtree.

## Verification

From the repository root: `swift test --package-path Packages/RecipeRemembererCore`.
