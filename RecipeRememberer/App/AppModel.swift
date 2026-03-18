import ImageIO
import Observation
import SwiftData
import Vision

@MainActor
@Observable
final class AppModel {
    static let immersiveSpaceID = "RecipeScannerSpace"

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

    enum CardStatus {
        case ready
        case pendingSave
        case alreadySaved
        case saved
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
        let title: String
        let subtitle: String
        let hellofreshCode: String?
        let sourceDescription: String

        init(entry: RecipeCatalogEntry, sourceDescription: String) {
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
    var pendingRecipeDraft: PendingRecipeDraft?
    var isAnalyzingImportedCard = false
    var isImmersiveSpaceShown = false
    var librarySearchText = ""
    var lastImportedText = ""
    var cardStatuses: [String: CardStatus] = [:]

    private var recentRecognitionDates: [String: Date] = [:]

    func handleTrackedRecipe(
        _ entry: RecipeCatalogEntry,
        using modelContext: ModelContext
    ) {
        guard shouldAcceptRecognition(for: entry.id) else {
            return
        }

        let savedRecipes = fetchStoredRecipes(using: modelContext)
        let isDuplicate = DuplicateRecipeDetector.isDuplicate(candidate: entry, among: savedRecipes.map(\.snapshot))

        if isDuplicate {
            cardStatuses[entry.id] = .alreadySaved
            latestFeedback = RecognitionFeedback(
                title: entry.title,
                message: "This recipe is already saved.",
                style: .warning,
                recipeID: entry.id
            )
            return
        }

        let draft = PendingRecipeDraft(entry: entry, sourceDescription: "live card recognition")
        saveOrStage(draft: draft, using: modelContext)
    }

    func analyzeImportedCard(
        from imageData: Data,
        using modelContext: ModelContext
    ) async {
        isAnalyzingImportedCard = true
        defer { isAnalyzingImportedCard = false }

        guard
            let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            latestFeedback = RecognitionFeedback(
                title: "Import Failed",
                message: "The selected photo could not be read.",
                style: .warning,
                recipeID: nil
            )
            return
        }

        do {
            let requestHandler = ImageRequestHandler(image)
            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = [
                Locale.Language(identifier: "en-US"),
                Locale.Language(identifier: "de-DE"),
            ]
            request.usesLanguageCorrection = true
            request.minimumTextHeightFraction = 0.02

            let observations = try await requestHandler.perform(request)
            let orderedLines = observations.sorted { left, right in
                if left.isTitle != right.isTitle {
                    return left.isTitle && !right.isTitle
                }

                return left.confidence > right.confidence
            }

            let detectedText = orderedLines
                .prefix(12)
                .map(\.transcript)
                .joined(separator: "\n")

            lastImportedText = detectedText

            if let match = RecipeMatcher.bestMatch(for: detectedText, in: SampleRecipeCatalog.entries) {
                let savedRecipes = fetchStoredRecipes(using: modelContext)
                let isDuplicate = DuplicateRecipeDetector.isDuplicate(candidate: match, among: savedRecipes.map(\.snapshot))

                if isDuplicate {
                    latestFeedback = RecognitionFeedback(
                        title: match.title,
                        message: "This recipe is already saved.",
                        style: .warning,
                        recipeID: match.id
                    )
                } else {
                    let draft = PendingRecipeDraft(entry: match, sourceDescription: "OCR import")
                    saveOrStage(draft: draft, using: modelContext)
                }

                return
            }

            let title = orderedLines.first(where: \.isTitle)?.transcript
                ?? orderedLines.first?.transcript
                ?? "Unknown HelloFresh Recipe"
            let subtitle = orderedLines
                .dropFirst()
                .prefix(2)
                .map(\.transcript)
                .joined(separator: " • ")
            let savedRecipes = fetchStoredRecipes(using: modelContext)
            let isDuplicate = DuplicateRecipeDetector.isDuplicate(
                title: title,
                hellofreshCode: nil,
                among: savedRecipes.map(\.snapshot)
            )

            if isDuplicate {
                latestFeedback = RecognitionFeedback(
                    title: title,
                    message: "This recipe is already saved.",
                    style: .warning,
                    recipeID: nil
                )
            } else {
                let draft = PendingRecipeDraft(
                    title: title,
                    subtitle: subtitle.isEmpty ? "Imported from a HelloFresh card photo" : subtitle,
                    hellofreshCode: nil,
                    sourceDescription: "OCR import"
                )
                saveOrStage(draft: draft, using: modelContext)
            }
        } catch {
            latestFeedback = RecognitionFeedback(
                title: "OCR Failed",
                message: "The app could not recognize text from that card photo.",
                style: .warning,
                recipeID: nil
            )
        }
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

    func cardStatus(for recipeID: String) -> CardStatus {
        cardStatuses[recipeID] ?? .ready
    }

    private func shouldAcceptRecognition(for recipeID: String) -> Bool {
        let now = Date.now

        if let previousRecognition = recentRecognitionDates[recipeID],
           now.timeIntervalSince(previousRecognition) < 2 {
            return false
        }

        recentRecognitionDates[recipeID] = now
        return true
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
            cardStatuses[draft.id] = .pendingSave
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "New recipe detected. Save this HelloFresh card?",
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
            cardStatuses[draft.id] = .saved
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: "Saved to your local recipe library.",
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
}
