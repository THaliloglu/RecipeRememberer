// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RecipeRemembererCore",
    platforms: [
        .macOS("15.0"),
        .visionOS("2.0"),
    ],
    products: [
        .library(
            name: "RecipeRemembererCore",
            targets: ["RecipeRemembererCore"]
        ),
    ],
    targets: [
        .target(
            name: "RecipeRemembererCore"
        ),
        .testTarget(
            name: "RecipeRemembererCoreTests",
            dependencies: ["RecipeRemembererCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
