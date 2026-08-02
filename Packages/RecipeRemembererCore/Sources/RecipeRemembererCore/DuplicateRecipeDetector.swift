public enum DuplicateRecipeDetector {
    public static func isDuplicate(
        title: String,
        subtitle: String?,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: subtitle ?? "")

        return savedRecipes.contains { savedRecipe in
            if savedRecipe.normalizedTitle != normalizedTitle {
                return false
            }

            if normalizedSubtitle.isEmpty {
                return true
            }

            if savedRecipe.normalizedSubtitle.isEmpty
                || savedRecipe.normalizedSubtitle == normalizedSubtitle {
                return true
            }

            let subtitleTokens = Set(RecipeNormalizer.normalizedTokens(for: normalizedSubtitle))
            let savedSubtitleTokens = Set(RecipeNormalizer.normalizedTokens(for: savedRecipe.normalizedSubtitle))
            guard !subtitleTokens.isEmpty, !savedSubtitleTokens.isEmpty else {
                return false
            }

            let sharedSubtitleTokens = subtitleTokens.intersection(savedSubtitleTokens).count
            let minimumExpectedOverlap = min(subtitleTokens.count, savedSubtitleTokens.count)

            return sharedSubtitleTokens >= max(2, minimumExpectedOverlap - 1)
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
                hasStrongTitleSignal
            )
        }

        guard
            let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }),
            bestMatch.1 >= 10,
            bestMatch.5 || bestMatch.2 >= 2,
            bestMatch.2 + bestMatch.3 + bestMatch.4 >= 3
        else {
            return nil
        }

        return bestMatch.0
    }
}
