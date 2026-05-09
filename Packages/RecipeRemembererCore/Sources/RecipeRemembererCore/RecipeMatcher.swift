import Foundation

public enum RecipeMatcher {
    public static func bestMatch(
        for detectedText: String,
        in catalog: [RecipeCatalogEntry]
    ) -> RecipeCatalogEntry? {
        let normalizedText = RecipeNormalizer.normalizedKey(for: detectedText)
        let detectedTokens = Set(RecipeNormalizer.normalizedTokens(for: detectedText))

        let scoredMatches = catalog.map { entry in
            (entry, score(for: entry, in: normalizedText, tokens: detectedTokens))
        }

        guard let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }), bestMatch.1 >= 6 else {
            return nil
        }

        return bestMatch.0
    }

    private static func score(
        for entry: RecipeCatalogEntry,
        in normalizedText: String,
        tokens: Set<String>
    ) -> Int {
        var total = 0

        let normalizedTitle = RecipeNormalizer.normalizedKey(for: entry.title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: entry.subtitle)
        let normalizedCode = RecipeNormalizer.normalizedKey(for: entry.hellofreshCode)
        let titleTokens = Set(RecipeNormalizer.normalizedTokens(for: entry.title))
        let subtitleTokens = Set(RecipeNormalizer.normalizedTokens(for: entry.subtitle))
        let sharedTitleTokens = titleTokens.intersection(tokens).count
        let sharedSubtitleTokens = subtitleTokens.intersection(tokens).count

        if normalizedText.contains(normalizedTitle) {
            total += 8
        }

        if normalizedText.contains(normalizedSubtitle) {
            total += 4
        }

        if normalizedText.contains(normalizedCode) {
            total += 10
        }

        total += sharedTitleTokens * 3
        total += sharedSubtitleTokens * 2

        if titleTokens.count >= 3, sharedTitleTokens >= titleTokens.count - 1 {
            total += 4
        }

        for token in entry.searchableTokens {
            let normalizedToken = RecipeNormalizer.normalizedKey(for: token)
            if tokens.contains(normalizedToken) || normalizedText.contains(normalizedToken) {
                total += 1
            }
        }

        return total
    }
}
