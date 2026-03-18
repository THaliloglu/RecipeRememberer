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
        .defaultSize(width: 960, height: 720)
        .modelContainer(modelContainer)

        ImmersiveSpace(id: AppModel.immersiveSpaceID) {
            RecipeScannerImmersiveView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        .modelContainer(modelContainer)
    }
}
