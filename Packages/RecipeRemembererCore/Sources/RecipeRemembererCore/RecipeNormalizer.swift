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
}
