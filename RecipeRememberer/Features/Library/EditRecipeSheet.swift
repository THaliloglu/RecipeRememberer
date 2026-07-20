import SwiftData
import SwiftUI
import UIKit

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
                if recipe.savedPhotoCount > 0 {
                    Section("Saved Photos") {
                        SavedRecipePhotoStrip(recipe: recipe)
                    }
                }

                Section("Recipe") {
                    TextField("Recipe title", text: $title)
                        .textInputAutocapitalization(.words)

                    TextField("Subtitle", text: $subtitle)
                        .textInputAutocapitalization(.words)

                    TextField("HelloFresh code", text: $hellofreshCode)
                        .textInputAutocapitalization(.characters)
                }

                if !recipe.analysisSummary.isEmpty {
                    Section("Notes") {
                        Text(recipe.analysisSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Recipe")
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

private struct SavedRecipePhotoStrip: View {
    let recipe: StoredRecipe

    var body: some View {
        HStack(spacing: 12) {
            if let frontPhotoURL = RecipePhotoStore.url(for: recipe.frontPhotoFilename) {
                SavedRecipePhotoThumbnail(
                    title: "Front",
                    photoURL: frontPhotoURL
                )
            }

            if let backPhotoURL = RecipePhotoStore.url(for: recipe.backPhotoFilename) {
                SavedRecipePhotoThumbnail(
                    title: "Back",
                    photoURL: backPhotoURL
                )
            }
        }
    }
}

private struct SavedRecipePhotoThumbnail: View {
    let title: String
    let photoURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let uiImage = UIImage(contentsOfFile: photoURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipShape(.rect(cornerRadius: 18))
            } else {
                ContentUnavailableView(
                    "Photo Unavailable",
                    systemImage: "photo"
                )
                .frame(height: 120)
            }
        }
    }
}
