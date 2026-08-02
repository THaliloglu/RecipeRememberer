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
                "Ask First"
            case .automatic:
                "Auto Save"
            }
        }

        var detail: String {
            switch self {
            case .confirmFirst:
                "Review each detected recipe before saving."
            case .automatic:
                "Save scanned recipe cards immediately when possible."
            }
        }
    }

    enum FeedbackStyle {
        case neutral
        case success
        case warning
    }

    struct RecognitionFeedback: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let style: FeedbackStyle
        let recipeID: String?
    }

    struct PendingRecipeDraft: Identifiable, Equatable {
        let id: String
        var title: String
        var subtitle: String
        let sourceDescription: String
        let capturePayload: RecipeCapturePayload?

        init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String,
            sourceDescription: String,
            capturePayload: RecipeCapturePayload? = nil
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.sourceDescription = sourceDescription
            self.capturePayload = capturePayload
        }
    }

    var saveMode: SaveMode = .confirmFirst
    var latestFeedback: RecognitionFeedback?
    var pendingRecipeDraft: PendingRecipeDraft?
    var librarySearchText = ""

    func dismissLatestFeedback(_ feedback: RecognitionFeedback? = nil) {
        guard let feedback else {
            latestFeedback = nil
            return
        }

        guard latestFeedback?.id == feedback.id else {
            return
        }

        latestFeedback = nil
    }

    func updatePendingDraft(
        title: String? = nil,
        subtitle: String? = nil
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

        pendingRecipeDraft = draft
    }

    func scanCapturedRecipe(
        _ capture: RecipeCapturePayload,
        using modelContext: ModelContext
    ) {
        let trimmedTitle = capture.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = capture.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            latestFeedback = RecognitionFeedback(
                title: "Missing Recipe Title",
                message: "A readable recipe title is required before saving.",
                style: .warning,
                recipeID: nil
            )
            pendingRecipeDraft = nil
            return
        }

        if let existingRecipe = duplicateRecipe(
            title: trimmedTitle,
            subtitle: trimmedSubtitle,
            capturePayload: capture,
            using: modelContext
        ) {
            latestFeedback = RecognitionFeedback(
                title: existingRecipe.title,
                message: "This recipe is already saved in your local library.",
                style: .warning,
                recipeID: nil
            )
            pendingRecipeDraft = nil
            return
        }

        let draft = PendingRecipeDraft(
            title: trimmedTitle,
            subtitle: trimmedSubtitle,
            sourceDescription: capture.sourceDescription,
            capturePayload: capture
        )

        if saveMode == .automatic {
            saveDraft(draft, using: modelContext)
            return
        }

        pendingRecipeDraft = draft
        latestFeedback = RecognitionFeedback(
            title: draft.title,
            message: "Review or edit the scanned recipe before saving it. Recipes stay on this device unless you add sync later.",
            style: .neutral,
            recipeID: draft.id
        )
    }

    func confirmPendingSave(using modelContext: ModelContext) {
        guard var draft = pendingRecipeDraft else {
            return
        }

        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.subtitle = draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !draft.title.isEmpty else {
            latestFeedback = RecognitionFeedback(
                title: "Missing Recipe Title",
                message: "Add or correct the recipe title before saving.",
                style: .warning,
                recipeID: draft.id
            )
            pendingRecipeDraft = draft
            return
        }

        if duplicateRecipe(
            title: draft.title,
            subtitle: draft.subtitle,
            capturePayload: draft.capturePayload,
            using: modelContext
        ) != nil {
            pendingRecipeDraft = draft
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "This recipe is already saved in your local library.",
                style: .warning,
                recipeID: draft.id
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
        using modelContext: ModelContext
    ) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)

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
            subtitle: trimmedSubtitle
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

    func duplicateRecipe(
        title: String,
        subtitle: String,
        capturePayload: RecipeCapturePayload? = nil,
        using modelContext: ModelContext
    ) -> StoredRecipe? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return nil
        }

        let savedRecipes = fetchStoredRecipes(using: modelContext)
        if let exactMatch = storedRecipe(
            matchingTitle: trimmedTitle,
            subtitle: trimmedSubtitle,
            in: savedRecipes
        ) {
            return exactMatch
        }

        let comparisonText = recognizedComparisonText(
            title: trimmedTitle,
            subtitle: trimmedSubtitle,
            capturePayload: capturePayload
        )

        guard let fuzzyMatch = DuplicateRecipeDetector.bestTitleMatch(
            for: comparisonText,
            among: savedRecipes.map(\.snapshot)
        ) else {
            return nil
        }

        return storedRecipe(
            matchingTitle: fuzzyMatch.title,
            subtitle: fuzzyMatch.subtitle,
            in: savedRecipes
        )
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

    private func saveDraft(
        _ draft: PendingRecipeDraft,
        using modelContext: ModelContext
    ) {
        let storedPhotoAssets: StoredRecipePhotoAssets

        if let capturePayload = draft.capturePayload {
            do {
                storedPhotoAssets = try RecipePhotoStore.persistPhotos(
                    from: capturePayload,
                    recipeID: draft.id
                )
            } catch {
                latestFeedback = RecognitionFeedback(
                    title: draft.title,
                    message: "The recipe was analyzed, but its front and back photos could not be saved.",
                    style: .warning,
                    recipeID: draft.id
                )
                return
            }
        } else {
            storedPhotoAssets = StoredRecipePhotoAssets(
                frontPhotoFilename: nil,
                backPhotoFilename: nil
            )
        }

        let recipe = StoredRecipe(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: draft.subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceDescription: draft.sourceDescription,
            frontPhotoFilename: storedPhotoAssets.frontPhotoFilename,
            backPhotoFilename: storedPhotoAssets.backPhotoFilename,
            frontRecognizedText: draft.capturePayload?.frontRecognizedText ?? "",
            backRecognizedText: draft.capturePayload?.backRecognizedText ?? "",
            analysisSummary: draft.capturePayload?.analysisSummary ?? ""
        )

        modelContext.insert(recipe)

        do {
            try modelContext.save()
            pendingRecipeDraft = nil
            librarySearchText = ""
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "Saved to your local recipe library from \(draft.sourceDescription).",
                style: .success,
                recipeID: draft.id
            )
        } catch {
            if storedPhotoAssets.hasSavedPhotos {
                RecipePhotoStore.deletePhotos(
                    frontPhotoFilename: storedPhotoAssets.frontPhotoFilename,
                    backPhotoFilename: storedPhotoAssets.backPhotoFilename
                )
            }
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "The recipe was recognized, but saving it failed.",
                style: .warning,
                recipeID: draft.id
            )
        }
    }

    private func storedRecipe(
        matchingTitle title: String,
        subtitle: String?,
        in savedRecipes: [StoredRecipe]
    ) -> StoredRecipe? {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)
        let normalizedSubtitle = RecipeNormalizer.normalizedKey(for: subtitle ?? "")

        return savedRecipes.first { savedRecipe in
            guard savedRecipe.normalizedTitle == normalizedTitle else {
                return false
            }

            if normalizedSubtitle.isEmpty {
                return true
            }

            return savedRecipe.normalizedSubtitle == normalizedSubtitle
                || savedRecipe.normalizedSubtitle.isEmpty
        }
    }

    private func recognizedComparisonText(
        title: String,
        subtitle: String,
        capturePayload: RecipeCapturePayload?
    ) -> String {
        var comparisonParts = [title, title]

        if !subtitle.isEmpty {
            comparisonParts.append(subtitle)
        }

        if let capturePayload {
            comparisonParts.append(capturePayload.frontRecognizedText)
            comparisonParts.append(capturePayload.backRecognizedText)
        }

        return comparisonParts
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }
}
