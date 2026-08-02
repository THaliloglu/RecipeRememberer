import Testing
@testable import RecipeRemembererCore

@Test
func duplicateDetectorMatchesOnNormalizedTitle() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Chicken and Thyme Grain Bowl",
            subtitle: "",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Chicken and Thyme Grain Bowl"),
            normalizedSubtitle: ""
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        title: "Chicken & Thyme Grain Bowl",
        subtitle: "",
        among: savedRecipes
    )

    #expect(isDuplicate)
}

@Test
func duplicateDetectorMatchesOnTitleAndSubtitleTogether() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Creamy Dill Chicken",
            subtitle: "with roasted potatoes and green beans",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Creamy Dill Chicken"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with roasted potatoes and green beans")
        ),
    ]

    let isDuplicate = DuplicateRecipeDetector.isDuplicate(
        title: "Creamy Dill Chicken",
        subtitle: "Roasted Potatoes and Green Beans",
        among: savedRecipes
    )

    #expect(isDuplicate)
}

@Test
func duplicateDetectorFindsSavedRecipeFromOCRTitleTokens() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Italian Beef Bake",
            subtitle: "with potatoes and leeks",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Italian Beef Bake"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with potatoes and leeks"),
            frontRecognizedText: """
            Italian Beef Bake
            with potatoes and leeks
            35 - 45 Min 613 kcal
            """,
            backRecognizedText: """
            potatoes
            leeks
            onion
            """
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        Italian Beef Bake
        potatoes and leeks
        """,
        among: savedRecipes
    )

    #expect(match?.title == "Italian Beef Bake")
}

@Test
func duplicateDetectorAllowsNearMatchInsteadOfExactEquality() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Orange Chicken Traybake",
            subtitle: "with broccoli and roast potatoes",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Orange Chicken Traybake"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with broccoli and roast potatoes"),
            frontRecognizedText: """
            Orange Chicken Traybake
            with broccoli and roast potatoes
            High Protein
            """,
            backRecognizedText: """
            broccoli
            potatoes
            orange sauce
            """
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        Orange Chicken Bake
        broccoli and roast potatoes
        """,
        among: savedRecipes
    )

    #expect(match?.title == "Orange Chicken Traybake")
}

@Test
func duplicateDetectorDoesNotCollapseDistinctRecipeTitlesIntoSavedRecipe() {
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: "Orange Chicken Traybake",
            subtitle: "with broccoli and roast potatoes",
            normalizedTitle: RecipeNormalizer.normalizedKey(for: "Orange Chicken Traybake"),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: "with broccoli and roast potatoes"),
            frontRecognizedText: """
            Orange Chicken Traybake
            with broccoli and roast potatoes
            25 - 35 Min
            """,
            backRecognizedText: """
            broccoli
            orange sauce
            potatoes
            """
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        Creamy Mushroom Pasta
        with spinach and garlic crumbs
        """,
        among: savedRecipes
    )

    #expect(match == nil)
}
