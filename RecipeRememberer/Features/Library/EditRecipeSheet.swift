import SwiftData
import SwiftUI

struct EditRecipeSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: StoredRecipe

    @State private var title: String
    @State private var subtitle: String
    @State private var hellofreshCode: String

    init(recipe: StoredRecipe) {
        self.recipe = recipe
        _title = State(initialValue: recipe.title)
        _subtitle = State(initialValue: recipe.subtitle)
        _hellofreshCode = State(initialValue: recipe.hellofreshCode ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Recipe title", text: $title)
                        .textInputAutocapitalization(.words)

                    TextField("Subtitle", text: $subtitle)
                        .textInputAutocapitalization(.words)

                    TextField("HelloFresh code", text: $hellofreshCode)
                        .textInputAutocapitalization(.characters)
                }

                if recipe.savedPhotoCount > 0 {
                    Section("Photos") {
                        SavedRecipePhotoGallerySection(recipe: recipe)
                    }
                }
            }
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if hasChanges {
                        Button("Save") {
                            let didSave = appModel.renameRecipe(
                                recipe,
                                title: title,
                                subtitle: subtitle,
                                hellofreshCode: hellofreshCode,
                                using: modelContext
                            )

                            if didSave {
                                dismiss()
                            }
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var hasChanges: Bool {
        title != recipe.title
            || subtitle != recipe.subtitle
            || hellofreshCode != (recipe.hellofreshCode ?? "")
    }
}
