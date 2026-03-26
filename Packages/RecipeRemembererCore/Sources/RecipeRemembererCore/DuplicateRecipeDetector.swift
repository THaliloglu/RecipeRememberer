public enum DuplicateRecipeDetector {
    public static func isDuplicate(
        candidate: RecipeCatalogEntry,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: candidate.title)

        return savedRecipes.contains { savedRecipe in
            if let savedCode = savedRecipe.hellofreshCode, savedCode == candidate.hellofreshCode {
                return true
            }

            return savedRecipe.normalizedTitle == normalizedTitle
        }
    }

    public static func isDuplicate(
        title: String,
        hellofreshCode: String?,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)

        return savedRecipes.contains { savedRecipe in
            if let hellofreshCode, let savedCode = savedRecipe.hellofreshCode, savedCode == hellofreshCode {
                return true
            }

            return savedRecipe.normalizedTitle == normalizedTitle
        }
    }

    public static func bestTitleMatch(
        for detectedText: String,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> SavedRecipeSnapshot? {
        let normalizedDetectedText = RecipeNormalizer.normalizedKey(for: detectedText)
        let detectedTokens = Set(RecipeNormalizer.normalizedTokens(for: detectedText))

        let scoredMatches = savedRecipes.map { savedRecipe in
            let titleTokens = Set(RecipeNormalizer.normalizedTokens(for: savedRecipe.title))
            let sharedTokenCount = titleTokens.intersection(detectedTokens).count
            var score = 0

            if !savedRecipe.normalizedTitle.isEmpty,
               normalizedDetectedText.contains(savedRecipe.normalizedTitle) {
                score += 10
            }

            if !normalizedDetectedText.isEmpty,
               savedRecipe.normalizedTitle.contains(normalizedDetectedText),
               normalizedDetectedText.count >= 12 {
                score += 6
            }

            score += sharedTokenCount * 2

            if titleTokens.count >= 3, sharedTokenCount >= titleTokens.count - 1 {
                score += 3
            }

            if let firstPhrase = leadingPhrase(in: savedRecipe.title),
               normalizedDetectedText.contains(firstPhrase) {
                score += 2
            }

            return (savedRecipe, score, sharedTokenCount)
        }

        guard
            let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }),
            bestMatch.1 >= 6,
            bestMatch.2 >= 2
        else {
            return nil
        }

        return bestMatch.0
    }

    private static func leadingPhrase(in title: String) -> String? {
        let tokens = RecipeNormalizer.normalizedTokens(for: title)
        guard tokens.count >= 2 else {
            return nil
        }

        return tokens.prefix(3).joined(separator: " ")
    }
}
