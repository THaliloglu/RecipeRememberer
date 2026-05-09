public struct SavedRecipeSnapshot: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let normalizedTitle: String
    public let normalizedSubtitle: String
    public let hellofreshCode: String?

    public init(
        title: String,
        subtitle: String,
        normalizedTitle: String,
        normalizedSubtitle: String,
        hellofreshCode: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.normalizedTitle = normalizedTitle
        self.normalizedSubtitle = normalizedSubtitle
        self.hellofreshCode = hellofreshCode
    }
}
