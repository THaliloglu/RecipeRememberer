import CoreGraphics
import Testing
@testable import RecipeRemembererCore

@Test
func recipeCardTextParserExtractsFrontCardTitleAndSubtitle() {
    let lines = [
        RecipeCardTextLine(
            transcript: "WEEK 21",
            frame: CGRect(x: 20, y: 20, width: 140, height: 22)
        ),
        RecipeCardTextLine(
            transcript: "One-Pan Tomato Chicken",
            frame: CGRect(x: 180, y: 22, width: 340, height: 34)
        ),
        RecipeCardTextLine(
            transcript: "with lemon rice",
            frame: CGRect(x: 182, y: 60, width: 260, height: 24)
        ),
    ]

    let result = RecipeCardTextParser.parse(from: lines)

    #expect(result?.title == "One-Pan Tomato Chicken")
    #expect(result?.subtitle == "with lemon rice")
}

@Test
func recipeCardTextParserIgnoresMetadataAndBadgeNumbers() {
    let lines = [
        RecipeCardTextLine(
            transcript: "High Protein 35 - 45 Min 613 kcal",
            frame: CGRect(x: 180, y: 98, width: 600, height: 18)
        ),
        RecipeCardTextLine(
            transcript: "21",
            frame: CGRect(x: 820, y: 16, width: 44, height: 44)
        ),
        RecipeCardTextLine(
            transcript: "Italian Beef Bake",
            frame: CGRect(x: 180, y: 22, width: 600, height: 34)
        ),
        RecipeCardTextLine(
            transcript: "with potatoes and leeks",
            frame: CGRect(x: 180, y: 64, width: 280, height: 24)
        ),
    ]

    let result = RecipeCardTextParser.parse(from: lines)

    #expect(result?.title == "Italian Beef Bake")
    #expect(result?.subtitle == "with potatoes and leeks")
}

@Test
func recipeCardTextParserMergesWrappedTitleLines() {
    let lines = [
        RecipeCardTextLine(
            transcript: "Creamy Sun-Dried Tomato",
            frame: CGRect(x: 180, y: 22, width: 320, height: 32)
        ),
        RecipeCardTextLine(
            transcript: "Chicken Pasta",
            frame: CGRect(x: 182, y: 58, width: 210, height: 31)
        ),
        RecipeCardTextLine(
            transcript: "with garlic breadcrumbs",
            frame: CGRect(x: 182, y: 98, width: 250, height: 22)
        ),
    ]

    let result = RecipeCardTextParser.parse(from: lines)

    #expect(result?.title == "Creamy Sun-Dried Tomato Chicken Pasta")
    #expect(result?.subtitle == "with garlic breadcrumbs")
}
