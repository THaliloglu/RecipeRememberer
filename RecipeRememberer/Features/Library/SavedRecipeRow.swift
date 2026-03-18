import SwiftUI

struct SavedRecipeRow: View {
    let recipe: StoredRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.headline)

            Text(recipe.subtitle)
                .foregroundStyle(.secondary)

            HStack {
                if let hellofreshCode = recipe.hellofreshCode {
                    Text(hellofreshCode)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(recipe.savedAt, format: .dateTime.month().day().year())
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
        .padding(.vertical, 4)
    }
}
