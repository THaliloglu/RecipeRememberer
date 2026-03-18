import Foundation

public struct RecipeCatalogEntry: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let hellofreshCode: String
    public let referenceImageName: String
    public let cardWidthMeters: Double
    public let cardHeightMeters: Double
    public let searchableTokens: [String]

    public init(
        id: String,
        title: String,
        subtitle: String,
        hellofreshCode: String,
        referenceImageName: String,
        cardWidthMeters: Double,
        cardHeightMeters: Double,
        searchableTokens: [String]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
        self.referenceImageName = referenceImageName
        self.cardWidthMeters = cardWidthMeters
        self.cardHeightMeters = cardHeightMeters
        self.searchableTokens = searchableTokens
    }
}
