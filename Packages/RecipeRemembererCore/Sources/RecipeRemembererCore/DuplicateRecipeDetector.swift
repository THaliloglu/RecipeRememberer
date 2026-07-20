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
            let frontRecognizedTextTokens = Set(RecipeNormalizer.normalizedTokens(for: savedRecipe.frontRecognizedText))
            let backRecognizedTextTokens = Set(RecipeNormalizer.normalizedTokens(for: savedRecipe.backRecognizedText))
            let sharedTitleTokens = titleTokens.intersection(detectedTokens).count
            let sharedSubtitleTokens = subtitleTokens.intersection(detectedTokens).count
            let sharedFrontRecognizedTextTokens = frontRecognizedTextTokens.intersection(detectedTokens).count
            let sharedBackRecognizedTextTokens = backRecognizedTextTokens.intersection(detectedTokens).count
            let hasStrongTitleSignal: Bool
            var score = 0

            if let code = savedRecipe.hellofreshCode,
               !code.isEmpty,
               normalizedDetectedText.contains(RecipeNormalizer.normalizedKey(for: code)) {
                score += 14
            }

            if titleTokens.count >= 3, sharedTitleTokens >= titleTokens.count - 1 {
                score += 10
                hasStrongTitleSignal = true
            } else if sharedTitleTokens >= 2 {
                score += 6
                hasStrongTitleSignal = true
            } else {
                hasStrongTitleSignal = false
            }

            if !savedRecipe.normalizedTitle.isEmpty,
               normalizedDetectedText.contains(savedRecipe.normalizedTitle) {
                score += 14
            }

            if !normalizedDetectedText.isEmpty,
               savedRecipe.normalizedTitle.contains(normalizedDetectedText),
               normalizedDetectedText.count >= 12 {
                score += 6
            }

            score += sharedTitleTokens * 3
            score += sharedSubtitleTokens * 2
            score += sharedFrontRecognizedTextTokens * 2
            score += sharedBackRecognizedTextTokens

            if !savedRecipe.normalizedSubtitle.isEmpty,
               normalizedDetectedText.contains(savedRecipe.normalizedSubtitle) {
                score += 4
            }

            if sharedFrontRecognizedTextTokens >= 6 {
                score += 6
            }

            if sharedBackRecognizedTextTokens >= 8 {
                score += 4
            }

            if subtitleTokens.count >= 2, sharedSubtitleTokens >= subtitleTokens.count {
                score += 2
            }

            return (
                savedRecipe,
                score,
                sharedTitleTokens,
                sharedSubtitleTokens,
                sharedFrontRecognizedTextTokens,
                hasStrongTitleSignal,
                savedRecipe.hellofreshCode != nil
            )
        }

        guard
            let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }),
            bestMatch.1 >= 10,
            bestMatch.5 || bestMatch.2 >= 2 || bestMatch.6,
            bestMatch.2 + bestMatch.3 + bestMatch.4 >= 3 || bestMatch.6
        else {
            return nil
        }

        return bestMatch.0
    }
}
