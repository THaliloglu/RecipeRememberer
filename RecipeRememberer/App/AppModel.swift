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

    struct PendingRecipeDraft: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let hellofreshCode: String?
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

    func scanRecipeTitle(using modelContext: ModelContext) {
        scanRecipeTitle(titleScanInput, using: modelContext)
    }

    func scanRecipeTitle(
        _ rawTitle: String,
        using modelContext: ModelContext
    ) {
        let inputTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        titleScanInput = inputTitle

        guard !inputTitle.isEmpty else {
            latestTitleScanResult = TitleScanResult(
                title: "No Title Entered",
                message: "Enter or dictate a recipe title first.",
                stage: .failed
            )
            latestFeedback = RecognitionFeedback(
                title: "No Title Entered",
                message: "Enter or dictate a recipe title first.",
                style: .warning,
                recipeID: nil
            )
            return
        }

        latestTitleScanResult = TitleScanResult(
            title: "Checking Recipe Title",
            message: "Comparing the entered title with your saved recipes.",
            stage: .analyzing
        )

        let savedRecipes = fetchStoredRecipes(using: modelContext)

        if let savedTitleMatch = DuplicateRecipeDetector.bestTitleMatch(
            for: inputTitle,
            among: savedRecipes.map(\.snapshot)
        ), let existingRecipe = storedRecipe(
            matchingTitle: savedTitleMatch.title,
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
                message: "This recipe is already saved.",
                style: .warning,
                recipeID: nil
            )
            return
        }

        if let catalogMatch = RecipeMatcher.bestMatch(for: inputTitle, in: SampleRecipeCatalog.entries) {
            if let existingRecipe = storedRecipe(matching: catalogMatch, in: savedRecipes) {
                latestTitleScanResult = TitleScanResult(
                    title: existingRecipe.title,
                    message: "This title matches a recipe already saved in your library.",
                    stage: .matchedSavedRecipe
                )
                latestFeedback = RecognitionFeedback(
                    title: existingRecipe.title,
                    message: "This recipe is already saved.",
                    style: .warning,
                    recipeID: catalogMatch.id
                )
            } else {
                let draft = PendingRecipeDraft(entry: catalogMatch, sourceDescription: "title scan")
                latestTitleScanResult = TitleScanResult(
                    title: catalogMatch.title,
                    message: "The title matches a known recipe. Save it if this is a new card for your library.",
                    stage: .matchedCatalogRecipe
                )
                saveOrStage(draft: draft, using: modelContext)
            }
            return
        }

        let draft = PendingRecipeDraft(
            title: inputTitle,
            subtitle: "Added from title scan",
            hellofreshCode: nil,
            sourceDescription: "title scan"
        )
        latestTitleScanResult = TitleScanResult(
            title: inputTitle,
            message: "No saved recipe matched this title. Save it as a new recipe if it looks right.",
            stage: .newRecipe
        )
        saveOrStage(draft: draft, using: modelContext)
    }

    func confirmPendingSave(using modelContext: ModelContext) {
        guard let draft = pendingRecipeDraft else {
            return
        }

        saveDraft(draft, using: modelContext)
    }

    func dismissPendingSave() {
        pendingRecipeDraft = nil
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
        using modelContext: ModelContext
    ) {
        if saveMode == .automatic {
            saveDraft(draft, using: modelContext)
        } else {
            pendingRecipeDraft = draft
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "New recipe detected from \(draft.sourceDescription). Save this HelloFresh card?",
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
            title: draft.title,
            subtitle: draft.subtitle,
            hellofreshCode: draft.hellofreshCode,
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
            hellofreshCode: entry.hellofreshCode,
            in: savedRecipes
        )
    }

    private func storedRecipe(
        matchingTitle title: String,
        hellofreshCode: String?,
        in savedRecipes: [StoredRecipe]
    ) -> StoredRecipe? {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)

        return savedRecipes.first { savedRecipe in
            if let hellofreshCode, let savedCode = savedRecipe.hellofreshCode, savedCode == hellofreshCode {
                return true
            }

            return savedRecipe.normalizedTitle == normalizedTitle
        }
    }
}
