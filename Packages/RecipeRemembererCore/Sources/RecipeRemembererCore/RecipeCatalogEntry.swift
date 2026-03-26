import Foundation

public struct RecipeCatalogEntry: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let hellofreshCode: String
    public let searchableTokens: [String]

    public init(
        id: String,
        title: String,
        subtitle: String,
        hellofreshCode: String,
        searchableTokens: [String]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
        self.searchableTokens = searchableTokens
    }
}
