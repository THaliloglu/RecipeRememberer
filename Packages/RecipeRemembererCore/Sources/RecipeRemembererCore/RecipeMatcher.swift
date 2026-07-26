import Foundation

public enum RecipeMatcher {
    public static func bestMatch(
        for detectedText: String,
        in catalog: [RecipeCatalogEntry]
    ) -> RecipeCatalogEntry? {
        let normalizedText = RecipeNormalizer.normalizedKey(for: detectedText)
        let detectedTokens = Set(RecipeNormalizer.normalizedTokens(for: detectedText))

        let scoredMatches = catalog.map { entry in
            (
                entry,
                signal(for: entry, in: normalizedText, tokens: detectedTokens)
            )
        }

        guard
            let bestMatch = scoredMatches.max(by: { $0.1.score < $1.1.score }),
            bestMatch.1.score >= 6,
            bestMatch.1.hasIdentitySignal
        else {
            return nil
        }

        return bestMatch.0
    }

    private static func signal(
        for entry: RecipeCatalogEntry,
        in normalizedText: String,
        tokens: Set<String>
    ) -> MatchSignal {
        var total = 0

        let normalizedTitle = RecipeNormalizer.normalizedKey(for: entry.title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: entry.subtitle)
        let normalizedCode = RecipeNormalizer.normalizedKey(for: entry.hellofreshCode)
        let titleTokens = Set(RecipeNormalizer.normalizedTokens(for: entry.title))
        let subtitleTokens = Set(RecipeNormalizer.normalizedTokens(for: entry.subtitle))
        let sharedTitleTokens = titleTokens.intersection(tokens).count
        let sharedSubtitleTokens = subtitleTokens.intersection(tokens).count

        let containsWholeTitle = normalizedText.contains(normalizedTitle)
        let containsWholeSubtitle = normalizedText.contains(normalizedSubtitle)
        let containsCode = normalizedText.contains(normalizedCode)

        if containsWholeTitle {
            total += 8
        }

        if containsWholeSubtitle {
            total += 4
        }

        if containsCode {
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

        return MatchSignal(
            score: total,
            hasIdentitySignal: containsCode
                || containsWholeTitle
                || sharedTitleTokens >= 2
                || (sharedTitleTokens >= 1 && sharedSubtitleTokens >= 2)
        )
    }
}

private struct MatchSignal {
    let score: Int
    let hasIdentitySignal: Bool
}
