import SwiftUI

struct SavedRecipeRow: View {
    let recipe: StoredRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.headline)

            if !recipe.subtitle.isEmpty {
                Text(recipe.subtitle)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let hellofreshCode = recipe.hellofreshCode {
                    Text(hellofreshCode)
                        .foregroundStyle(.secondary)
                }

                if recipe.savedPhotoCount > 0 {
                    Label(
                        "\(recipe.savedPhotoCount) photos",
                        systemImage: "photo.on.rectangle.angled"
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(recipe.savedAt, format: .dateTime.month().day().year())
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to review saved photos. Swipe for rename and delete options.")
    }
}
