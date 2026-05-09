public enum DuplicateRecipeDetector {
    public static func isDuplicate(
        candidate: RecipeCatalogEntry,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        isDuplicate(
            title: candidate.title,
            subtitle: candidate.subtitle,
            hellofreshCode: candidate.hellofreshCode,
            among: savedRecipes
        )
    }

    public static func isDuplicate(
        title: String,
        hellofreshCode: String?,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        isDuplicate(
            title: title,
            subtitle: nil,
            hellofreshCode: hellofreshCode,
            among: savedRecipes
        )
    }

    public static func isDuplicate(
        title: String,
        subtitle: String?,
        hellofreshCode: String?,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: subtitle ?? "")

        return savedRecipes.contains { savedRecipe in
            if let hellofreshCode, let savedCode = savedRecipe.hellofreshCode, savedCode == hellofreshCode {
                return true
            }

            if savedRecipe.normalizedTitle == normalizedTitle {
                return true
            }

            if !normalizedSubtitle.isEmpty,
               savedRecipe.normalizedTitle == normalizedTitle,
               savedRecipe.normalizedSubtitle == normalizedSubtitle {
                return true
            }

            return false
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
            let subtitleTokens = Set(RecipeNormalizer.normalizedTokens(for: savedRecipe.subtitle))
            let sharedTitleTokens = titleTokens.intersection(detectedTokens).count
            let sharedSubtitleTokens = subtitleTokens.intersection(detectedTokens).count
            var score = 0

            if let code = savedRecipe.hellofreshCode,
               !code.isEmpty,
               normalizedDetectedText.contains(RecipeNormalizer.normalizedKey(for: code)) {
                score += 14
            }

            if !savedRecipe.normalizedTitle.isEmpty,
               normalizedDetectedText.contains(savedRecipe.normalizedTitle) {
                score += 10
            }

            if !normalizedDetectedText.isEmpty,
               savedRecipe.normalizedTitle.contains(normalizedDetectedText),
               normalizedDetectedText.count >= 12 {
                score += 6
            }

            score += sharedTitleTokens * 3
            score += sharedSubtitleTokens * 2

            if !savedRecipe.normalizedSubtitle.isEmpty,
               normalizedDetectedText.contains(savedRecipe.normalizedSubtitle) {
                score += 4
            }

            if titleTokens.count >= 3, sharedTitleTokens >= titleTokens.count - 1 {
                score += 4
            }

            if subtitleTokens.count >= 2, sharedSubtitleTokens >= subtitleTokens.count {
                score += 2
            }

            return (savedRecipe, score, sharedTitleTokens + sharedSubtitleTokens)
        }

        guard
            let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }),
            bestMatch.1 >= 7,
            bestMatch.2 >= 2 || bestMatch.0.hellofreshCode != nil
        else {
            return nil
        }

        return bestMatch.0
    }
}
