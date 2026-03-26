import SwiftData
import SwiftUI

@main
struct RecipeRemembererApp: App {
    @State private var appModel = AppModel()

    private let modelContainer: ModelContainer = {
        let schema = Schema([StoredRecipe.self])

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Unable to create model container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup("Recipe Rememberer", id: "mainWindow") {
            RootView()
                .environment(appModel)
        }
        .modelContainer(modelContainer)
    }
}
