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
            hellofreshCode: nil,
            frontRecognizedText: """
            HELLO FRESH
            Italienisches Gratin mit Bio-Rinderhackfleisch
            Kartoffeln und Porree
            35 - 45 Min 613 kcal
            """,
            backRecognizedText: """
            1 Kartoffel
            1 Porree
            1 Zwiebel
            """
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
func duplicateDetectorAllowsNearMatchInsteadOfExactEquality() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Italienisches Gratin mit Bio-Rinderhackfleisch",
            subtitle: "Kartoffeln und Porree",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Italienisches Gratin mit Bio-Rinderhackfleisch"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "Kartoffeln und Porree"),
            hellofreshCode: nil,
            frontRecognizedText: """
            HELLO FRESH
            Italienisches Gratin mit Bio-Rinderhackfleisch
            Kartoffeln und Porree
            Viel Gemüse High Protein
            """,
            backRecognizedText: """
            Ofenkartoffel
            Porree
            Knoblauchzehe
            """
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        Italienisches Gratin mit Rinderhackfleisch
        Kartoffeln & Porree
        Hallo Fresh
        """,
        among: savedRecipes
    )

    #expect(match?.title == "Italienisches Gratin mit Bio-Rinderhackfleisch")
}

@Test
func duplicateDetectorDoesNotCollapseDistinctRecipeTitlesIntoSavedRecipe() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Italienisches Gratin mit Bio-Rinderhackfleisch",
            subtitle: "Kartoffeln und Porree",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Italienisches Gratin mit Bio-Rinderhackfleisch"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "Kartoffeln und Porree"),
            hellofreshCode: "HF-DE-21",
            frontRecognizedText: """
            HELLO FRESH
            Italienisches Gratin mit Bio-Rinderhackfleisch
            Kartoffeln und Porree
            Viel Gemüse High Protein Kalorien im Blick 35 - 45 Min 613 kcal
            """,
            backRecognizedText: """
            Ofenkartoffel
            Zwiebel
            Knoblauchzehe
            Porree
            """
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        HELLO FRESH
        Hähnchenfilets in sticky Orangen-Zwiebelsoße
        mit Brokkoli und Rosmarin-Kartoffelspalten
        Viel Gemüse High Protein Schnell 25 - 35 Min 688 kcal
        """,
        among: savedRecipes
    )

    #expect(match == nil)
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
