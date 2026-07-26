import Foundation

public enum RecipeNormalizer {
    public static func normalizedKey(for value: String) -> String {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacing(/\band\b/, with: " ")
            .replacing(/[^a-zA-Z0-9]+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return folded.lowercased()
    }

    public static func normalizedTokens(for value: String) -> [String] {
        normalizedKey(for: value)
            .split(separator: " ")
            .map(String.init)
            .filter { token in
                token.count > 1 && !stopWords.contains(token)
            }
    }

    private static let stopWords: Set<String> = [
        "and",
        "das",
        "der",
        "die",
        "for",
        "fur",
        "hello",
        "fresh",
        "im",
        "in",
        "mit",
        "of",
        "ohne",
        "the",
        "und",
        "von",
        "with",
    ]
}
