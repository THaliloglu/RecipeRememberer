import ImageIO
import Observation
import SwiftData
import Vision

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
        let sampleImageData: Data?

        init(
            entry: RecipeCatalogEntry,
            sourceDescription: String,
            sampleImageData: Data? = nil
        ) {
            id = entry.id
            title = entry.title
            subtitle = entry.subtitle
            hellofreshCode = entry.hellofreshCode
            self.sourceDescription = sourceDescription
            self.sampleImageData = sampleImageData
        }

        init(
            id: String = UUID().uuidString,
            title: String,
            subtitle: String,
            hellofreshCode: String?,
            sourceDescription: String,
            sampleImageData: Data? = nil
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.hellofreshCode = hellofreshCode
            self.sourceDescription = sourceDescription
            self.sampleImageData = sampleImageData
        }
    }

    var saveMode: SaveMode = .confirmFirst
    var latestFeedback: RecognitionFeedback?
    var latestVisualComparison: RecognitionFeedback?
    var titleScanInput = ""
    var latestTitleScanResult = TitleScanResult(
        title: "Ready to Scan",
        message: "Enter or dictate a recipe title to compare it against your saved recipes.",
        stage: .idle
    )
    var pendingRecipeDraft: PendingRecipeDraft?
    var isAnalyzingImportedCard = false
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
        latestVisualComparison = nil
        latestTitleScanResult = TitleScanResult(
            title: "Scanning Recipe Title",
            message: "Reading the recipe card title and comparing it with your library.",
            stage: .analyzing
        )

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
            latestTitleScanResult = TitleScanResult(
                title: "Scan Failed",
                message: "The selected photo could not be read.",
                stage: .failed
            )
            return
        }

        do {
            let savedRecipes = fetchStoredRecipes(using: modelContext)

            if let learnedMatch = RecipeVisualMatcher.bestMatch(for: imageData, among: savedRecipes) {
                let distanceDescription = learnedMatch.distance.formatted(
                    .number.precision(.fractionLength(2))
                )

                if RecipeVisualMatcher.isAccepted(learnedMatch) {
                    latestVisualComparison = RecognitionFeedback(
                        title: learnedMatch.recipe.title,
                        message: "Vision matched this photo to a recipe you already learned locally. Distance: \(distanceDescription).",
                        style: .success,
                        recipeID: nil
                    )

                    latestFeedback = RecognitionFeedback(
                        title: learnedMatch.recipe.title,
                        message: "This recipe is already saved in your library.",
                        style: .warning,
                        recipeID: nil
                    )
                    latestTitleScanResult = TitleScanResult(
                        title: learnedMatch.recipe.title,
                        message: "Matched one of your saved recipes using a learned local sample.",
                        stage: .matchedSavedRecipe
                    )
                    return
                }

                latestVisualComparison = RecognitionFeedback(
                    title: learnedMatch.recipe.title,
                    message: "Closest learned local sample found, but the visual similarity was too weak to trust automatically. Distance: \(distanceDescription). Falling back to bundled samples and OCR.",
                    style: .neutral,
                    recipeID: nil
                )
            }

            if let visualMatch = RecipeVisualMatcher.bestMatch(for: imageData, in: SampleRecipeCatalog.entries) {
                let distanceDescription = visualMatch.distance.formatted(
                    .number.precision(.fractionLength(2))
                )

                if RecipeVisualMatcher.isAccepted(visualMatch) {
                    latestVisualComparison = RecognitionFeedback(
                        title: visualMatch.entry.title,
                        message: "Vision visually matched this photo to a bundled reference card. Distance: \(distanceDescription).",
                        style: .success,
                        recipeID: visualMatch.entry.id
                    )

                    if let existingRecipe = storedRecipe(matching: visualMatch.entry, in: savedRecipes) {
                        let attachmentResult = attachSampleImageIfMissing(
                            from: imageData,
                            to: existingRecipe,
                            using: modelContext
                        )

                        latestFeedback = RecognitionFeedback(
                            title: visualMatch.entry.title,
                            message: duplicateMessage(for: attachmentResult),
                            style: .warning,
                            recipeID: visualMatch.entry.id
                        )
                    } else {
                        let draft = PendingRecipeDraft(
                            entry: visualMatch.entry,
                            sourceDescription: "Vision visual similarity"
                        )
                        saveOrStage(draft: draft, using: modelContext)
                    }

                    return
                }

                latestVisualComparison = RecognitionFeedback(
                    title: visualMatch.entry.title,
                    message: "Closest bundled visual sample found, but the similarity was too weak to trust automatically. Distance: \(distanceDescription). Falling back to OCR.",
                    style: .neutral,
                    recipeID: visualMatch.entry.id
                )
            } else {
                latestVisualComparison = RecognitionFeedback(
                    title: "No Visual Match",
                    message: "This photo did not match any bundled sample strongly enough for visual recognition. Falling back to OCR.",
                    style: .neutral,
                    recipeID: nil
                )
            }

            let requestHandler = ImageRequestHandler(image)
            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.automaticallyDetectsLanguage = true
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

            if let savedTitleMatch = DuplicateRecipeDetector.bestTitleMatch(
                for: detectedText,
                among: savedRecipes.map(\.snapshot)
            ), let existingRecipe = storedRecipe(
                matchingTitle: savedTitleMatch.title,
                hellofreshCode: savedTitleMatch.hellofreshCode,
                in: savedRecipes
            ) {
                let attachmentResult = attachSampleImageIfMissing(
                    from: imageData,
                    to: existingRecipe,
                    using: modelContext
                )

                latestFeedback = RecognitionFeedback(
                    title: existingRecipe.title,
                    message: "OCR title matching found this saved recipe. \(duplicateMessage(for: attachmentResult))",
                    style: .warning,
                    recipeID: nil
                )
                latestTitleScanResult = TitleScanResult(
                    title: existingRecipe.title,
                    message: "The scanned title matched a recipe already saved in your library.",
                    stage: .matchedSavedRecipe
                )
                return
            }

            if let match = RecipeMatcher.bestMatch(for: detectedText, in: SampleRecipeCatalog.entries) {
                if let existingRecipe = storedRecipe(matching: match, in: savedRecipes) {
                    let attachmentResult = attachSampleImageIfMissing(
                        from: imageData,
                        to: existingRecipe,
                        using: modelContext
                    )

                    latestFeedback = RecognitionFeedback(
                        title: match.title,
                        message: duplicateMessage(for: attachmentResult),
                        style: .warning,
                        recipeID: match.id
                    )
                    latestTitleScanResult = TitleScanResult(
                        title: match.title,
                        message: "The scanned title matched a recipe already saved in your library.",
                        stage: .matchedSavedRecipe
                    )
                } else {
                    let draft = PendingRecipeDraft(entry: match, sourceDescription: "OCR import")
                    latestTitleScanResult = TitleScanResult(
                        title: match.title,
                        message: "The scanned title matched a known recipe. Review it and save it if this is a new card for your library.",
                        stage: .matchedCatalogRecipe
                    )
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

            if let existingRecipe = storedRecipe(
                matchingTitle: title,
                hellofreshCode: nil,
                in: savedRecipes
            ) {
                let attachmentResult = attachSampleImageIfMissing(
                    from: imageData,
                    to: existingRecipe,
                    using: modelContext
                )

                latestFeedback = RecognitionFeedback(
                    title: title,
                    message: duplicateMessage(for: attachmentResult),
                    style: .warning,
                    recipeID: nil
                )
                latestTitleScanResult = TitleScanResult(
                    title: existingRecipe.title,
                    message: "The scanned title matched a recipe already saved in your library.",
                    stage: .matchedSavedRecipe
                )
            } else {
                let draft = PendingRecipeDraft(
                    title: title,
                    subtitle: subtitle.isEmpty ? "Imported from a HelloFresh card photo" : subtitle,
                    hellofreshCode: nil,
                    sourceDescription: "OCR import with local comparison sample",
                    sampleImageData: imageData
                )
                latestTitleScanResult = TitleScanResult(
                    title: title,
                    message: "No saved recipe matched this title. Review it and save it as a new recipe if it looks right.",
                    stage: .newRecipe
                )
                saveOrStage(draft: draft, using: modelContext)
            }
        } catch {
            let draft = PendingRecipeDraft(
                title: "Unknown HelloFresh Recipe",
                subtitle: "Saved from a card photo for later visual comparison",
                hellofreshCode: nil,
                sourceDescription: "unmatched card capture",
                sampleImageData: imageData
            )
            latestTitleScanResult = TitleScanResult(
                title: "Unknown HelloFresh Recipe",
                message: "The title could not be read cleanly. You can still save this card as a new local sample.",
                stage: .failed
            )
            saveOrStage(draft: draft, using: modelContext)
        }
    }

    func scanRecipeTitle(
        using modelContext: ModelContext
    ) {
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
                let draft = PendingRecipeDraft(entry: catalogMatch, sourceDescription: "title entry")
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
            subtitle: "Added from title entry",
            hellofreshCode: nil,
            sourceDescription: "title entry"
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
        let sampleImageFilename: String?

        if let sampleImageData = draft.sampleImageData {
            sampleImageFilename = try? RecipeSampleImageStore.saveSampleImage(
                sampleImageData,
                id: draft.id
            )
        } else {
            sampleImageFilename = nil
        }

        let recipe = StoredRecipe(
            title: draft.title,
            subtitle: draft.subtitle,
            hellofreshCode: draft.hellofreshCode,
            sourceDescription: draft.sourceDescription,
            sampleImageFilename: sampleImageFilename
        )

        modelContext.insert(recipe)

        do {
            try modelContext.save()
            pendingRecipeDraft = nil
            cardStatuses[draft.id] = .saved
            latestFeedback = RecognitionFeedback(
                title: draft.title,
                message: successMessage(for: draft, sampleImageFilename: sampleImageFilename),
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

    private func attachSampleImageIfMissing(
        from imageData: Data,
        to recipe: StoredRecipe,
        using modelContext: ModelContext
    ) -> SampleAttachmentResult {
        guard recipe.sampleImageFilename == nil else {
            return .alreadyPresent
        }

        let sampleID = recipe.normalizedTitle.isEmpty
            ? UUID().uuidString
            : recipe.normalizedTitle.replacing(" ", with: "-")

        guard let filename = try? RecipeSampleImageStore.saveSampleImage(imageData, id: sampleID) else {
            return .failed
        }

        recipe.sampleImageFilename = filename

        do {
            try modelContext.save()
            return .added
        } catch {
            return .failed
        }
    }

    private func duplicateMessage(for attachmentResult: SampleAttachmentResult) -> String {
        switch attachmentResult {
        case .added:
            return "This recipe is already saved. A local comparison sample was also added for future matching."
        case .alreadyPresent:
            return "This recipe is already saved."
        case .failed:
            return "This recipe is already saved, but the local comparison sample could not be stored."
        }
    }

    private func successMessage(
        for draft: PendingRecipeDraft,
        sampleImageFilename: String?
    ) -> String {
        if draft.sampleImageData != nil, sampleImageFilename != nil {
            return "Saved to your local recipe library from \(draft.sourceDescription), and stored a local comparison sample for future matching."
        }

        if draft.sampleImageData != nil {
            return "Saved to your local recipe library from \(draft.sourceDescription), but the local comparison sample could not be stored."
        }

        return "Saved to your local recipe library from \(draft.sourceDescription)."
    }

    private enum SampleAttachmentResult {
        case added
        case alreadyPresent
        case failed
    }
}
