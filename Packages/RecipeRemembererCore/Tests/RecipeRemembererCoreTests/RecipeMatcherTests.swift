import Testing
@testable import RecipeRemembererCore

@Test
func recipeMatcherFindsCatalogEntryFromOCRText() {
    let detectedText = """
    HELLOFRESH
    One-Pot Mushroom Rigatoni
    with parmesan and spinach
    HF-3017
    """

    let match = RecipeMatcher.bestMatch(for: detectedText, in: SampleRecipeCatalog.entries)

    #expect(match?.id == "one-pot-mushroom-rigatoni")
}

@Test
func recipeMatcherFindsGermanCatalogEntryFromOCRText() {
    let detectedText = """
    HELLO FRESH
    Italienisches Gratin mit Bio-Rinderhackfleisch
    Kartoffeln und Porree
    Viel Gemuse High Protein Kalorien im Blick 35 - 45 Min 613 kcal
    21
    """

    let match = RecipeMatcher.bestMatch(for: detectedText, in: SampleRecipeCatalog.entries)

    #expect(match?.id == "italienisches-gratin-rinderhackfleisch")
}

@Test
func recipeMatcherUsesSubtitleAndRecipeCodeSignals() {
    let detectedText = """
    parmesan and spinach
    HF-3017
    """

    let match = RecipeMatcher.bestMatch(for: detectedText, in: SampleRecipeCatalog.entries)

    #expect(match?.id == "one-pot-mushroom-rigatoni")
}
