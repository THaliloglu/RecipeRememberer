import SwiftData
import SwiftUI

struct RecentSavedRecipesSection: View {
    @Query(sort: \StoredRecipe.savedAt, order: .reverse) private var savedRecipes: [StoredRecipe]

    var body: some View {
        let recentRecipes = Array(savedRecipes.prefix(3))

        if !recentRecipes.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.cardSpacing) {
                Text("Recently Saved")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(recentRecipes) { recipe in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.subheadline)
                                    .bold()

                                if !recipe.subtitle.isEmpty {
                                    Text(recipe.subtitle)
                                        .foregroundStyle(.secondary)
                                }

                                Text(
                                    "\(recipe.savedAt.formatted(date: .abbreviated, time: .shortened)) • \(recipe.sourceDescription)"
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(AppStyle.cardPadding)
            .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
        }
    }
}
