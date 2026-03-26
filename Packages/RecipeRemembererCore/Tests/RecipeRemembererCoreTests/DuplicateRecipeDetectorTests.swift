import Testing
@testable import RecipeRemembererCore

@Test
func duplicateDetectorMatchesOnRecipeCode() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "One-Pot Mushroom Rigatoni",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "One-Pot Mushroom Rigatoni"),
            hellofreshCode: "HF-3017"
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        candidate: SampleRecipeCatalog.entries[1],
        among: savedRecipes
    )

    #expect(isDuplicate)
}

@Test
func duplicateDetectorMatchesOnNormalizedTitle() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Chicken and Thyme Grain Bowl",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Chicken and Thyme Grain Bowl"),
            hellofreshCode: nil
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        title: "Chicken & Thyme Grain Bowl",
        hellofreshCode: nil,
        among: savedRecipes
    )

    #expect(isDuplicate)
}

@Test
func duplicateDetectorFindsSavedRecipeFromOCRTitleTokens() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Italienisches Gratin mit Bio-Rinderhackfleisch",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Italienisches Gratin mit Bio-Rinderhackfleisch"),
            hellofreshCode: nil
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        HELLO FRESH
        Italienisches Gratin mit Bio Rinderhackfleisch
        Kartoffeln und Porree
        """,
        among: savedRecipes
    )

    #expect(match?.title == "Italienisches Gratin mit Bio-Rinderhackfleisch")
}
