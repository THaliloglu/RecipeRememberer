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
                Section("Recipe Details") {
                    TextField("Recipe title", text: $title)
                        .textInputAutocapitalization(.words)

                    TextField("Subtitle", text: $subtitle)
                        .textInputAutocapitalization(.words)

                    TextField("HelloFresh code", text: $hellofreshCode)
                        .textInputAutocapitalization(.characters)
                }
            }
            .navigationTitle("Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
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
                }
            }
        }
    }
}
