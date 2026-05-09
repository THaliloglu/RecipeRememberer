import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StoredRecipe.savedAt, order: .reverse) private var savedRecipes: [StoredRecipe]

    @State private var recipeBeingEdited: StoredRecipe?
    @State private var recipePendingDeletion: StoredRecipe?
    @State private var isDeleteDialogPresented = false

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: 12) {
            LocalLibraryNoticeCard(
                title: "Local Recipe Library",
                message: "Recipes are stored only on this device right now. You can rename or delete them whenever you want.",
                caption: "This app is not affiliated with HelloFresh."
            )

            Group {
                if filteredRecipes.isEmpty {
                    if appModel.librarySearchText.isEmpty {
                        ContentUnavailableView(
                            "No Saved Recipes",
                            systemImage: "square.stack.3d.down.forward",
                            description: Text("Scan a HelloFresh recipe title in the scanner to start building your local library.")
                        )
                    } else {
                        ContentUnavailableView.search
                    }
                } else {
                    List {
                        ForEach(filteredRecipes) { recipe in
                            SavedRecipeRow(recipe: recipe)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        recipePendingDeletion = recipe
                                        isDeleteDialogPresented = true
                                    }

                                    Button("Rename", systemImage: "pencil") {
                                        recipeBeingEdited = recipe
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .listStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $appModel.librarySearchText, prompt: "Search saved recipes")
        .sheet(item: $recipeBeingEdited) { recipe in
            EditRecipeSheet(recipe: recipe)
        }
        .confirmationDialog(
            "Delete Recipe?",
            isPresented: $isDeleteDialogPresented,
            titleVisibility: .visible
        ) {
            if let recipePendingDeletion {
                Button("Delete", role: .destructive) {
                    appModel.deleteRecipe(recipePendingDeletion, using: modelContext)
                    self.recipePendingDeletion = nil
                }
            }

            Button("Cancel", role: .cancel) {
                recipePendingDeletion = nil
            }
        } message: {
            Text("This removes the recipe from your local library on this device.")
        }
        .onChange(of: isDeleteDialogPresented) { _, isPresented in
            if !isPresented {
                recipePendingDeletion = nil
            }
        }
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
