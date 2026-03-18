import Foundation

public enum RecipeMatcher {
    public static func bestMatch(
        for detectedText: String,
        in catalog: [RecipeCatalogEntry]
    ) -> RecipeCatalogEntry? {
        let normalizedText = RecipeNormalizer.normalizedKey(for: detectedText)
        let scoredMatches = catalog.map { entry in
            (entry, score(for: entry, in: normalizedText))
        }

        guard let bestMatch = scoredMatches.max(by: { $0.1 < $1.1 }), bestMatch.1 >= 3 else {
            return nil
        }

        return bestMatch.0
    }

    private static func score(
        for entry: RecipeCatalogEntry,
        in normalizedText: String
    ) -> Int {
        var total = 0

        let normalizedTitle = RecipeNormalizer.normalizedKey(for: entry.title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: entry.subtitle)
        let normalizedCode = RecipeNormalizer.normalizedKey(for: entry.hellofreshCode)

        if normalizedText.contains(normalizedTitle) {
            total += 6
        }

        if normalizedText.contains(normalizedSubtitle) {
            total += 3
        }

        if normalizedText.contains(normalizedCode) {
            total += 6
        }

        for token in entry.searchableTokens {
            let normalizedToken = RecipeNormalizer.normalizedKey(for: token)
            if normalizedText.contains(normalizedToken) {
                total += 1
            }
        }

        return total
    }
}
