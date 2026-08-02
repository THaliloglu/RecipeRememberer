import SwiftData
import SwiftUI

@main
struct RecipeRemembererApp: App {
    @State private var appModel = AppModel()

    private let modelContainer: ModelContainer = {
        let schema = Schema([StoredRecipe.self])
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: UITestLaunchConfiguration.shouldSeedLibrary
                || UITestLaunchConfiguration.shouldUseMockScannerCapture
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create model container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup("Recipe Rememberer", id: "mainWindow") {
            RootView()
                .environment(appModel)
                .task {
                    if UITestLaunchConfiguration.shouldUseAutomaticSaveMode {
                        appModel.saveMode = .automatic
                    }
                    UITestRecipeSeeder.seedLibraryIfNeeded(in: modelContainer)
                }
        }
        .modelContainer(modelContainer)
    }
}
