public struct SavedRecipeSnapshot: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let normalizedTitle: String
    public let normalizedSubtitle: String
    public let hellofreshCode: String?
    public let frontRecognizedText: String
    public let backRecognizedText: String

    public init(
        title: String,
        subtitle: String,
        normalizedTitle: String,
        normalizedSubtitle: String,
        hellofreshCode: String?,
        frontRecognizedText: String = "",
        backRecognizedText: String = ""
    ) {
        self.title = title
        self.subtitle = subtitle
        self.normalizedTitle = normalizedTitle
        self.normalizedSubtitle = normalizedSubtitle
        self.hellofreshCode = hellofreshCode
        self.frontRecognizedText = frontRecognizedText
        self.backRecognizedText = backRecognizedText
    }
}
