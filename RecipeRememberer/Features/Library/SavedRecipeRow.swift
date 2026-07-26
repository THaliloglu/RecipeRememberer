import SwiftUI

struct SavedRecipeRow: View {
    let recipe: StoredRecipe

    var body: some View {
        HStack(spacing: 14) {
            SavedRecipeRowThumbnail(recipe: recipe)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        if !recipe.subtitle.isEmpty {
                            Text(recipe.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    Text(recipe.savedAt, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let hellofreshCode = recipe.hellofreshCode, !hellofreshCode.isEmpty {
                        Text(hellofreshCode)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary, in: .capsule)
                    }

                    Label(photoCountLabel, systemImage: "photo.on.rectangle.angled")
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: .capsule)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.06))
        }
        .contentShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to preview recipe photos and details. Swipe for rename and delete options.")
    }

    private var photoCountLabel: String {
        recipe.savedPhotoCount == 1 ? "1 photo" : "\(recipe.savedPhotoCount) photos"
    }
}
