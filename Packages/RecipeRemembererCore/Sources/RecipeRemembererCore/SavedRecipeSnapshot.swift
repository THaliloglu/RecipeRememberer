public struct SavedRecipeSnapshot: Equatable, Sendable {
    public let title: String
    public let normalizedTitle: String
    public let hellofreshCode: String?

    public init(
        title: String,
        normalizedTitle: String,
        hellofreshCode: String?
    ) {
        self.title = title
        self.normalizedTitle = normalizedTitle
        self.hellofreshCode = hellofreshCode
    }
}
