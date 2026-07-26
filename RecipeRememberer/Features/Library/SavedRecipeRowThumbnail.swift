import SwiftUI
import UIKit

struct SavedRecipeRowThumbnail: View {
    let recipe: StoredRecipe

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            thumbnailContent

            if recipe.savedPhotoCount > 1 {
                Text("\(recipe.savedPhotoCount)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7), in: .capsule)
                    .padding(8)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let frontPhotoURL = RecipePhotoStore.url(for: recipe.frontPhotoFilename),
           let uiImage = UIImage(contentsOfFile: frontPhotoURL.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle()
                    .fill(.quaternary)

                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
