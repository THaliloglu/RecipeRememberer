import Foundation
import SwiftData

@Model
final class StoredRecipe {
    var title: String = ""
    var subtitle: String = ""
    var hellofreshCode: String?
    var normalizedTitle: String = ""
    var normalizedSubtitle: String = ""
    var sourceDescription: String = ""
    var frontPhotoFilename: String?
    var backPhotoFilename: String?
    var frontRecognizedText: String = ""
    var backRecognizedText: String = ""
    var analysisSummary: String = ""
    var savedAt: Date = Foundation.Date.now
    var updatedAt: Date = Foundation.Date.now

    init(
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        sourceDescription: String,
        frontPhotoFilename: String? = nil,
        backPhotoFilename: String? = nil,
        frontRecognizedText: String = "",
        backRecognizedText: String = "",
        analysisSummary: String = ""
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
        self.sourceDescription = sourceDescription
        self.frontPhotoFilename = frontPhotoFilename
        self.backPhotoFilename = backPhotoFilename
        self.frontRecognizedText = frontRecognizedText
        self.backRecognizedText = backRecognizedText
        self.analysisSummary = analysisSummary
        refreshNormalizedFields()
    }

    func updateDetails(
        title: String,
        subtitle: String,
        hellofreshCode: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
        updatedAt = .now
        refreshNormalizedFields()
    }

    var snapshot: SavedRecipeSnapshot {
        SavedRecipeSnapshot(
            title: title,
            subtitle: subtitle,
            normalizedTitle: normalizedTitle,
            normalizedSubtitle: normalizedSubtitle,
            hellofreshCode: hellofreshCode,
            frontRecognizedText: frontRecognizedText,
            backRecognizedText: backRecognizedText
        )
    }

    var savedPhotoCount: Int {
        [frontPhotoFilename, backPhotoFilename].compactMap(\.self).count
    }

    private func refreshNormalizedFields() {
        normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        normalizedSubtitle = RecipeNormalizer.normalizedKey(for: subtitle)
    }
}
