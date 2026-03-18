import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var appModel

    @Query(sort: \StoredRecipe.savedAt, order: .reverse) private var savedRecipes: [StoredRecipe]

    var body: some View {
        @Bindable var appModel = appModel

        Group {
            if filteredRecipes.isEmpty {
                ContentUnavailableView(
                    "No Saved Recipes",
                    systemImage: "square.stack.3d.down.forward",
                    description: Text("Recognize a HelloFresh card in the scanner or import a recipe photo to start building your local library.")
                )
            } else {
                List(filteredRecipes) { recipe in
                    SavedRecipeRow(recipe: recipe)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Library")
        .searchable(text: $appModel.librarySearchText, prompt: "Search saved recipes")
    }

    private var filteredRecipes: [StoredRecipe] {
        guard !appModel.librarySearchText.isEmpty else {
            return savedRecipes
        }

        return savedRecipes.filter { recipe in
            recipe.title.localizedStandardContains(appModel.librarySearchText)
                || recipe.subtitle.localizedStandardContains(appModel.librarySearchText)
                || (recipe.hellofreshCode ?? "").localizedStandardContains(appModel.librarySearchText)
        }
    }
}
