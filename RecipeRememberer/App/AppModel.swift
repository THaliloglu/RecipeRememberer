import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppModel {
    enum SaveMode: String, CaseIterable, Identifiable {
        case confirmFirst
        case automatic

        var id: String { rawValue }

        var shortTitle: String {
            switch self {
            case .confirmFirst:
                return "Ask First"
            case .automatic:
                return "Auto Save"
            }
        }

        var detail: String {
            switch self {
            case .confirmFirst:
                return "Review each detected recipe before saving."
            case .automatic:
                return "Save manual title matches immediately when possible."
            }
        }
    }

    enum FeedbackStyle {
        case neutral
        case success
        case warning
    }

    enum TitleScanStage {
        case idle
        case analyzing
        case matchedSavedRecipe
        case matchedCatalogRecipe
        case newRecipe
        case failed
    }

    struct RecognitionFeedback: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let style: FeedbackStyle
        let recipeID: String?
    }

    struct TitleScanResult: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let stage: TitleScanStage
    }

    struct RecentScanRecord: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let subtitle: String
        let hellofreshCode: String?
        let message: String
        let stage: TitleScanStage
        let sourceDescription: String
        let capturedAt: Date
    }

    struct PendingRecipeDraft: Identifiable, Equatable {
        let id: String
        var title: String
        var subtitle: String
        var hellofreshCode: String?
        let sourceDescription: String

        init(
            entry: RecipeCatalogEntry,
            sourceDescription: String
        ) {
            id = entry.id
            title = entry.title
            subtitle = entry.subtitle
            hellofreshCode = entry.hellofreshCode
            self.sourceDescription = sourceDescription
        }

        init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String,
            hellofreshCode: String?,
            sourceDescription: String
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.hellofreshCode = hellofreshCode
            self.sourceDescription = sourceDescription
        }
    }

    private enum ScanSource {
        case manualEntry
        case liveScanner

        var description: String {
            switch self {
            case .manualEntry:
                return "manual title entry"
            case .liveScanner:
                return "live title scanner"
            }
        }

        var requiresReview: Bool {
            switch self {
            case .manualEntry:
                return false
            case .liveScanner:
                return true
            }
        }
    }

    var saveMode: SaveMode = .confirmFirst
    var latestFeedback: RecognitionFeedback?
    var titleScanInput = ""
    var latestTitleScanResult = TitleScanResult(
        title: "Ready to Scan",
        message: "Enter or scan a recipe title to compare it against your saved recipes.",
        stage: .idle
    )
    var pendingRecipeDraft: PendingRecipeDraft?
    var librarySearchText = ""
    var recentScanHistory: [RecentScanRecord] = []

    func scanRecipeTitle(using modelContext: ModelContext) {
        evaluateRecipeInput(
            title: titleScanInput,
            subtitle: nil,
            hellofreshCode: nil,
            source: .manualEntry,
            using: modelContext
        )
    }

    func scanCapturedTitle(
        _ capturedTitle: String,
        using modelContext: ModelContext
    ) {
        evaluateRecipeInput(
            title: capturedTitle,
            subtitle: nil,
            hellofreshCode: nil,
            source: .liveScanner,
            using: modelContext
        )
    }

    func scanCapturedRecipe(
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        using modelContext: ModelContext
    ) {
        evaluateRecipeInput(
            title: title,
            subtitle: subtitle,
            hellofreshCode: hellofreshCode,
            source: .liveScanner,
            using: modelContext
        )
    }

    func updatePendingDraft(
        title: String? = nil,
        subtitle: String? = nil,
        hellofreshCode: String? = nil
    ) {
        guard var draft = pendingRecipeDraft else {
            return
        }

        if let title {
            draft.title = title
        }

        if let subtitle {
            draft.subtitle = subtitle
        }

        if let hellofreshCode {
            draft.hellofreshCode = normalizedOptionalField(hellofreshCode)
        }

        pendingRecipeDraft = draft
    }

    func confirmPendingSave(using modelContext: ModelContext) {
        guard var draft = pendingRecipeDraft else {
            return
        }

        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.subtitle = draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.hellofreshCode = normalizedOptionalField(draft.hellofreshCode)

        guard !draft.title.isEmpty else {
            latestFeedback = RecognitionFeedback(
                title: "Missing Recipe Title",
                message: "Add or correct the recipe title before saving.",
                style: .warning,
                recipeID: draft.id
            )
            latestTitleScanResult = TitleScanResult(
                title: "Recipe Title Needed",
                message: "Review the detected recipe and add a title before saving it.",
                stage: .failed
            )
            pendingRecipeDraft = draft
            return
        }

        let savedRecipes = fetchStoredRecipes(using: modelContext)

        if DuplicateRecipeDetector.isDuplicate(
            title: draft.title,
            subtitle: draft.subtitle,
            hellofreshCode: draft.hellofreshCode,
            among: savedRecipes.map(\.snapshot)
        ) {
            pendingRecipeDraft = nil
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "This recipe is already saved in your local library.",
                style: .warning,
                recipeID: draft.id
            )
            latestTitleScanResult = TitleScanResult(
                title: draft.title,
                message: "Your edits still match an existing saved recipe, so nothing new was added.",
                stage: .matchedSavedRecipe
            )
            return
        }

        saveDraft(draft, using: modelContext)
    }

    func dismissPendingSave() {
        pendingRecipeDraft = nil
    }

    func renameRecipe(
        _ recipe: StoredRecipe,
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        using modelContext: ModelContext
    ) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCode = normalizedOptionalField(hellofreshCode)

        guard !trimmedTitle.isEmpty else {
            latestFeedback = RecognitionFeedback(
                title: "Rename Failed",
                message: "Recipe titles cannot be empty.",
                style: .warning,
                recipeID: nil
            )
            return false
        }

        let savedRecipes = fetchStoredRecipes(using: modelContext)
        let competingSnapshots = savedRecipes
            .filter { $0.persistentModelID != recipe.persistentModelID }
            .map(\.snapshot)

        if DuplicateRecipeDetector.isDuplicate(
            title: trimmedTitle,
            subtitle: trimmedSubtitle,
            hellofreshCode: normalizedCode,
            among: competingSnapshots
        ) {
            latestFeedback = RecognitionFeedback(
                title: trimmedTitle,
                message: "That edit would duplicate another saved recipe.",
                style: .warning,
                recipeID: nil
            )
            return false
        }

        recipe.updateDetails(
            title: trimmedTitle,
            subtitle: trimmedSubtitle,
            hellofreshCode: normalizedCode
        )

        do {
            try modelContext.save()
            latestFeedback = RecognitionFeedback(
                title: trimmedTitle,
                message: "Recipe details updated.",
                style: .success,
                recipeID: nil
            )
            return true
        } catch {
            latestFeedback = RecognitionFeedback(
                title: trimmedTitle,
                message: "The recipe was edited, but saving the changes failed.",
                style: .warning,
                recipeID: nil
            )
            return false
        }
    }

    func deleteRecipe(
        _ recipe: StoredRecipe,
        using modelContext: ModelContext
    ) {
        let recipeTitle = recipe.title
        modelContext.delete(recipe)

        do {
            try modelContext.save()
            latestFeedback = RecognitionFeedback(
                title: recipeTitle,
                message: "Recipe removed from your local library.",
                style: .success,
                recipeID: nil
            )
        } catch {
            latestFeedback = RecognitionFeedback(
                title: recipeTitle,
                message: "The recipe could not be removed from your library.",
                style: .warning,
                recipeID: nil
            )
        }
    }

    private func evaluateRecipeInput(
        title rawTitle: String,
        subtitle rawSubtitle: String?,
        hellofreshCode rawHellofreshCode: String?,
        source: ScanSource,
        using modelContext: ModelContext
    ) {
        let inputTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let inputSubtitle = rawSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let inputHellofreshCode = normalizedOptionalField(rawHellofreshCode)
        var detectedRecipeParts = [inputTitle]

        if !inputSubtitle.isEmpty {
            detectedRecipeParts.append(inputSubtitle)
        }

        if let inputHellofreshCode {
            detectedRecipeParts.append(inputHellofreshCode)
        }

        let combinedDetectedText = detectedRecipeParts.joined(separator: "\n")

        if source == .manualEntry {
            titleScanInput = inputTitle
        }

        guard !inputTitle.isEmpty else {
            latestTitleScanResult = TitleScanResult(
                title: "No Title Entered",
                message: "Enter or capture a recipe title first.",
                stage: .failed
            )
            latestFeedback = RecognitionFeedback(
                title: "No Title Entered",
                message: "Enter or capture a recipe title first.",
                style: .warning,
                recipeID: nil
            )
            appendRecentScan(
                title: "No Title Entered",
                subtitle: "",
                hellofreshCode: nil,
                stage: .failed,
                message: "Enter or capture a recipe title first.",
                sourceDescription: source.description
            )
            return
        }

        latestTitleScanResult = TitleScanResult(
            title: "Checking Recipe Title",
            message: "Comparing the detected recipe with your saved recipes.",
            stage: .analyzing
        )

        let savedRecipes = fetchStoredRecipes(using: modelContext)

        if let existingRecipe = storedRecipe(
            matchingTitle: inputTitle,
            subtitle: inputSubtitle,
            hellofreshCode: inputHellofreshCode,
            in: savedRecipes
        ) {
            latestTitleScanResult = TitleScanResult(
                title: existingRecipe.title,
                message: "This title matches a recipe already saved in your library.",
                stage: .matchedSavedRecipe
            )
            latestFeedback = RecognitionFeedback(
                title: existingRecipe.title,
                message: "This recipe is already saved in your local library.",
                style: .warning,
                recipeID: nil
            )
            pendingRecipeDraft = nil
            appendRecentScan(
                title: existingRecipe.title,
                subtitle: existingRecipe.subtitle,
                hellofreshCode: existingRecipe.hellofreshCode,
                stage: .matchedSavedRecipe,
                message: "Matched a recipe already saved in your library.",
                sourceDescription: source.description
            )
            return
        }

        if let savedTitleMatch = DuplicateRecipeDetector.bestTitleMatch(
            for: combinedDetectedText,
            among: savedRecipes.map(\.snapshot)
        ), let existingRecipe = storedRecipe(
            matchingTitle: savedTitleMatch.title,
            subtitle: savedTitleMatch.subtitle,
            hellofreshCode: savedTitleMatch.hellofreshCode,
            in: savedRecipes
        ) {
            latestTitleScanResult = TitleScanResult(
                title: existingRecipe.title,
                message: "This title matches a recipe already saved in your library.",
                stage: .matchedSavedRecipe
            )
            latestFeedback = RecognitionFeedback(
                title: existingRecipe.title,
                message: "This recipe is already saved in your local library.",
                style: .warning,
                recipeID: nil
            )
            pendingRecipeDraft = nil
            appendRecentScan(
                title: existingRecipe.title,
                subtitle: existingRecipe.subtitle,
                hellofreshCode: existingRecipe.hellofreshCode,
                stage: .matchedSavedRecipe,
                message: "Matched a saved recipe from your capture.",
                sourceDescription: source.description
            )
            return
        }

        if let catalogMatch = RecipeMatcher.bestMatch(
            for: combinedDetectedText,
            in: SampleRecipeCatalog.entries
        ) {
            if let existingRecipe = storedRecipe(
                matchingTitle: catalogMatch.title,
                subtitle: catalogMatch.subtitle,
                hellofreshCode: catalogMatch.hellofreshCode,
                in: savedRecipes
            ) {
                latestTitleScanResult = TitleScanResult(
                    title: existingRecipe.title,
                    message: "This title matches a recipe already saved in your library.",
                    stage: .matchedSavedRecipe
                )
                latestFeedback = RecognitionFeedback(
                    title: existingRecipe.title,
                    message: "This recipe is already saved in your local library.",
                    style: .warning,
                    recipeID: catalogMatch.id
                )
                pendingRecipeDraft = nil
                appendRecentScan(
                    title: existingRecipe.title,
                    subtitle: existingRecipe.subtitle,
                    hellofreshCode: existingRecipe.hellofreshCode,
                    stage: .matchedSavedRecipe,
                    message: "Matched a saved recipe after comparing with the known catalog.",
                    sourceDescription: source.description
                )
            } else {
                let draft = PendingRecipeDraft(
                    entry: catalogMatch,
                    sourceDescription: source.description
                )
                latestTitleScanResult = TitleScanResult(
                    title: catalogMatch.title,
                    message: "The title matches a known recipe. Review and save it if this is a new card for your library.",
                    stage: .matchedCatalogRecipe
                )
                saveOrStage(
                    draft: draft,
                    using: modelContext,
                    requiresReview: source.requiresReview
                )
                appendRecentScan(
                    title: draft.title,
                    subtitle: draft.subtitle,
                    hellofreshCode: draft.hellofreshCode,
                    stage: .matchedCatalogRecipe,
                    message: "Matched a known recipe and opened it for review.",
                    sourceDescription: source.description
                )
            }
            return
        }

        let draft = PendingRecipeDraft(
            title: inputTitle,
            subtitle: inputSubtitle,
            hellofreshCode: inputHellofreshCode,
            sourceDescription: source.description
        )
        latestTitleScanResult = TitleScanResult(
            title: inputTitle,
            message: "No saved recipe matched this title. Review it and save it as a new recipe if it looks right.",
            stage: .newRecipe
        )
        saveOrStage(
            draft: draft,
            using: modelContext,
            requiresReview: source.requiresReview
        )
        appendRecentScan(
            title: draft.title,
            subtitle: draft.subtitle,
            hellofreshCode: draft.hellofreshCode,
            stage: .newRecipe,
            message: "No duplicate was found. This capture is ready to review and save.",
            sourceDescription: source.description
        )
    }

    private func fetchStoredRecipes(using modelContext: ModelContext) -> [StoredRecipe] {
        let descriptor = FetchDescriptor<StoredRecipe>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            latestFeedback = RecognitionFeedback(
                title: "Library Unavailable",
                message: "Saved recipes could not be loaded from the local database.",
                style: .warning,
                recipeID: nil
            )
            return []
        }
    }

    private func saveOrStage(
        draft: PendingRecipeDraft,
        using modelContext: ModelContext,
        requiresReview: Bool
    ) {
        if requiresReview {
            pendingRecipeDraft = draft
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "Review or edit the scanned recipe before saving it. Recipes stay on this device unless you add sync later.",
                style: .neutral,
                recipeID: draft.id
            )
            return
        }

        if saveMode == .automatic {
            saveDraft(draft, using: modelContext)
        } else {
            pendingRecipeDraft = draft
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "New recipe detected from \(draft.sourceDescription). Review it and save this HelloFresh card?",
                style: .neutral,
                recipeID: draft.id
            )
        }
    }

    private func saveDraft(
        _ draft: PendingRecipeDraft,
        using modelContext: ModelContext
    ) {
        let recipe = StoredRecipe(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            hellofreshCode: normalizedOptionalField(draft.hellofreshCode),
            sourceDescription: draft.sourceDescription
        )

        modelContext.insert(recipe)

        do {
            try modelContext.save()
            pendingRecipeDraft = nil
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "Saved to your local recipe library from \(draft.sourceDescription).",
                style: .success,
                recipeID: draft.id
            )
        } catch {
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "The recipe was recognized, but saving it failed.",
                style: .warning,
                recipeID: draft.id
            )
        }
    }

    private func storedRecipe(
        matching entry: RecipeCatalogEntry,
        in savedRecipes: [StoredRecipe]
    ) -> StoredRecipe? {
        storedRecipe(
            matchingTitle: entry.title,
            subtitle: entry.subtitle,
            hellofreshCode: entry.hellofreshCode,
            in: savedRecipes
        )
    }

    private func storedRecipe(
        matchingTitle title: String,
        subtitle: String?,
        hellofreshCode: String?,
        in savedRecipes: [StoredRecipe]
    ) -> StoredRecipe? {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: subtitle ?? "")

        return savedRecipes.first { savedRecipe in
            if let hellofreshCode, let savedCode = savedRecipe.hellofreshCode, savedCode == hellofreshCode {
                return true
            }

            if savedRecipe.normalizedTitle != normalizedTitle {
                return false
            }

            if normalizedSubtitle.isEmpty {
                return true
            }

            return savedRecipe.normalizedSubtitle == normalizedSubtitle
                || savedRecipe.normalizedSubtitle.isEmpty
        }
    }

    private func normalizedOptionalField(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func appendRecentScan(
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        stage: TitleScanStage,
        message: String,
        sourceDescription: String
    ) {
        recentScanHistory.insert(
            RecentScanRecord(
                title: title,
                subtitle: subtitle,
                hellofreshCode: hellofreshCode,
                message: message,
                stage: stage,
                sourceDescription: sourceDescription,
                capturedAt: .now
            ),
            at: 0
        )

        if recentScanHistory.count > 6 {
            recentScanHistory.removeLast(recentScanHistory.count - 6)
        }
    }
}
