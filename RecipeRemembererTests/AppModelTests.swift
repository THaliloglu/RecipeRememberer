import SwiftData
import XCTest
@testable import RecipeRememberer

@MainActor
final class AppModelTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([StoredRecipe.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        let recipes = try modelContext.fetch(FetchDescriptor<StoredRecipe>())
        for recipe in recipes {
            RecipePhotoStore.deletePhotos(
                frontPhotoFilename: recipe.frontPhotoFilename,
                backPhotoFilename: recipe.backPhotoFilename
            )
        }

        modelContainer = nil
        modelContext = nil
    }

    func testConfirmFirstCreatesPendingDraftWithoutSavingRecipe() throws {
        let appModel = AppModel()
        appModel.saveMode = .confirmFirst

        appModel.scanCapturedRecipe(
            sampleCapture(title: "Roasted Tomato Pasta", subtitle: "Herb butter"),
            using: modelContext
        )

        XCTAssertEqual(appModel.pendingRecipeDraft?.title, "Roasted Tomato Pasta")
        XCTAssertEqual(appModel.pendingRecipeDraft?.subtitle, "Herb butter")
        XCTAssertEqual(try fetchRecipes().count, 0)
        XCTAssertEqual(
            appModel.latestFeedback?.message,
            "Review or edit the scanned recipe before saving it. Recipes stay on this device unless you add sync later."
        )
    }

    func testAutomaticSavePersistsRecipeAndClearsDraft() throws {
        let appModel = AppModel()
        appModel.saveMode = .automatic

        appModel.scanCapturedRecipe(
            sampleCapture(title: "Lemon Rice Bowl", subtitle: "Crisp greens"),
            using: modelContext
        )

        let recipes = try fetchRecipes()
        XCTAssertEqual(recipes.count, 1)
        XCTAssertNil(appModel.pendingRecipeDraft)
        XCTAssertEqual(recipes.first?.title, "Lemon Rice Bowl")
        XCTAssertEqual(recipes.first?.subtitle, "Crisp greens")
        XCTAssertEqual(appModel.latestFeedback?.message, "Saved to your local recipe library from camera scanner.")
    }

    func testConfirmPendingSavePersistsEditedDraft() throws {
        let appModel = AppModel()
        appModel.saveMode = .confirmFirst

        appModel.scanCapturedRecipe(
            sampleCapture(title: "Mushroom Flatbread", subtitle: ""),
            using: modelContext
        )
        appModel.updatePendingDraft(subtitle: "Whipped ricotta")
        appModel.confirmPendingSave(using: modelContext)

        let recipes = try fetchRecipes()
        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes.first?.title, "Mushroom Flatbread")
        XCTAssertEqual(recipes.first?.subtitle, "Whipped ricotta")
        XCTAssertNil(appModel.pendingRecipeDraft)
    }

    func testDuplicateScanShowsWarningAndSkipsSaving() throws {
        let appModel = AppModel()
        appModel.saveMode = .automatic

        let originalCapture = sampleCapture(
            title: "Spiced Veggie Noodles",
            subtitle: "Sesame drizzle",
            frontRecognizedText: "Spiced Veggie Noodles\nSesame drizzle",
            backRecognizedText: "Sauce and garnish"
        )
        appModel.scanCapturedRecipe(originalCapture, using: modelContext)

        appModel.scanCapturedRecipe(
            sampleCapture(
                title: "Spiced Veggie Noodles",
                subtitle: "Sesame drizzle",
                frontRecognizedText: "Spiced Veggie Noodles\nSesame drizzle",
                backRecognizedText: "Sauce and garnish"
            ),
            using: modelContext
        )

        XCTAssertEqual(try fetchRecipes().count, 1)
        XCTAssertNil(appModel.pendingRecipeDraft)
        XCTAssertEqual(
            appModel.latestFeedback?.message,
            "This recipe is already saved in your local library."
        )
    }

    func testRenameRecipeRejectsDuplicateTitle() throws {
        let appModel = AppModel()
        appModel.saveMode = .automatic

        appModel.scanCapturedRecipe(
            sampleCapture(title: "Coconut Curry Rice", subtitle: "Snap peas"),
            using: modelContext
        )
        appModel.scanCapturedRecipe(
            sampleCapture(title: "Garlic Butter Orzo", subtitle: "Roasted broccoli"),
            using: modelContext
        )

        let recipes = try fetchRecipes()
        guard recipes.count == 2 else {
            return XCTFail("Expected two saved recipes.")
        }

        let recipeToRename = try XCTUnwrap(recipes.first(where: { $0.title == "Garlic Butter Orzo" }))
        let renamed = appModel.renameRecipe(
            recipeToRename,
            title: "Coconut Curry Rice",
            subtitle: "Snap peas",
            using: modelContext
        )

        XCTAssertFalse(renamed)
        XCTAssertEqual(recipeToRename.title, "Garlic Butter Orzo")
        XCTAssertEqual(
            appModel.latestFeedback?.message,
            "That edit would duplicate another saved recipe."
        )
    }

    private func fetchRecipes() throws -> [StoredRecipe] {
        try modelContext.fetch(
            FetchDescriptor<StoredRecipe>(
                sortBy: [SortDescriptor(\.savedAt, order: .forward)]
            )
        )
    }

    private func sampleCapture(
        title: String,
        subtitle: String,
        frontRecognizedText: String? = nil,
        backRecognizedText: String? = nil
    ) -> RecipeCapturePayload {
        RecipeCapturePayload(
            title: title,
            subtitle: subtitle,
            sourceDescription: "camera scanner",
            frontImageData: Data("front-photo".utf8),
            backImageData: Data("back-photo".utf8),
            frontRecognizedText: frontRecognizedText ?? title,
            backRecognizedText: backRecognizedText ?? subtitle,
            analysisSummary: "Unit test payload."
        )
    }
}
