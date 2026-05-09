import CoreGraphics
import Testing
@testable import RecipeRemembererCore

@Test
func recipeCardTextParserExtractsEnglishCardDetails() {
    let lines = [
        RecipeCardTextLine(
            transcript: "HELLOFRESH",
            frame: CGRect(x: 20, y: 20, width: 140, height: 22)
        ),
        RecipeCardTextLine(
            transcript: "One-Pot Mushroom Rigatoni",
            frame: CGRect(x: 180, y: 22, width: 340, height: 34)
        ),
        RecipeCardTextLine(
            transcript: "with parmesan and spinach",
            frame: CGRect(x: 182, y: 60, width: 260, height: 24)
        ),
        RecipeCardTextLine(
            transcript: "HF-3017",
            frame: CGRect(x: 510, y: 22, width: 80, height: 24)
        ),
    ]

    let result = RecipeCardTextParser.parse(from: lines)

    #expect(result?.title == "One-Pot Mushroom Rigatoni")
    #expect(result?.subtitle == "with parmesan and spinach")
    #expect(result?.hellofreshCode == "HF-3017")
}

@Test
func recipeCardTextParserExtractsGermanCardDetails() {
    let lines = [
        RecipeCardTextLine(
            transcript: "HELLO FRESH",
            frame: CGRect(x: 20, y: 20, width: 150, height: 24)
        ),
        RecipeCardTextLine(
            transcript: "Italienisches Gratin mit Bio-Rinderhackfleisch",
            frame: CGRect(x: 180, y: 22, width: 600, height: 34)
        ),
        RecipeCardTextLine(
            transcript: "Kartoffeln und Porree",
            frame: CGRect(x: 180, y: 64, width: 280, height: 24)
        ),
        RecipeCardTextLine(
            transcript: "Viel Gemuse High Protein Kalorien im Blick 35 - 45 Min 613 kcal",
            frame: CGRect(x: 180, y: 98, width: 600, height: 18)
        ),
        RecipeCardTextLine(
            transcript: "21",
            frame: CGRect(x: 820, y: 16, width: 44, height: 44)
        ),
    ]

    let result = RecipeCardTextParser.parse(from: lines)

    #expect(result?.title == "Italienisches Gratin mit Bio-Rinderhackfleisch")
    #expect(result?.subtitle == "Kartoffeln und Porree")
    #expect(result?.hellofreshCode == nil)
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
