import Foundation
import SwiftData

@Model
final class StoredRecipe {
    var title: String = ""
    var subtitle: String = ""
    var hellofreshCode: String?
    var normalizedTitle: String = ""
    var sourceDescription: String = ""
    var sampleImageFilename: String?
    var savedAt: Date = Foundation.Date.now

    init(
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        sourceDescription: String,
        sampleImageFilename: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
        normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        self.sourceDescription = sourceDescription
        self.sampleImageFilename = sampleImageFilename
    }

    var snapshot: SavedRecipeSnapshot {
        SavedRecipeSnapshot(
            title: title,
            normalizedTitle: normalizedTitle,
            hellofreshCode: hellofreshCode
        )
    }

    var hasLearnedVisualSample: Bool {
        sampleImageFilename != nil
    }
}
