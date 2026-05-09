import Testing
@testable import RecipeRemembererCore

@Test
func duplicateDetectorMatchesOnRecipeCode() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "One-Pot Mushroom Rigatoni",
            subtitle: "with parmesan and spinach",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "One-Pot Mushroom Rigatoni"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with parmesan and spinach"),
            hellofreshCode: "HF-3017"
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        candidate: SampleRecipeCatalog.entries[0],
        among: savedRecipes
    )

    #expect(isDuplicate)
}

@Test
func duplicateDetectorMatchesOnNormalizedTitle() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Chicken and Thyme Grain Bowl",
            subtitle: "",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Chicken and Thyme Grain Bowl"),
            normalizedSubtitle: "",
            hellofreshCode: nil
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        title: "Chicken & Thyme Grain Bowl",
        subtitle: "",
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
            subtitle: "Kartoffeln und Porree",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Italienisches Gratin mit Bio-Rinderhackfleisch"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "Kartoffeln und Porree"),
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

@Test
func duplicateDetectorMatchesOnTitleAndSubtitleTokens() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Creamy Dill Chicken",
            subtitle: "with roasted potatoes and green beans",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Creamy Dill Chicken"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with roasted potatoes and green beans"),
            hellofreshCode: nil
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        title: "Creamy Dill Chicken",
        subtitle: "Roasted Potatoes and Green Beans",
        hellofreshCode: nil,
        among: savedRecipes
    )

    #expect(isDuplicate)
}
