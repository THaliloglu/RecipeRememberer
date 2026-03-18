import SwiftUI

struct RecipeCardLabelView: View {
    @Environment(AppModel.self) private var appModel

    let entry: RecipeCatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.headline)

            Text(statusMessage)
                .foregroundStyle(statusStyle)

            Text(entry.hellofreshCode)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassBackgroundEffect()
    }

    private var statusMessage: String {
        switch appModel.cardStatus(for: entry.id) {
        case .ready:
            return "Ready to recognize"
        case .pendingSave:
            return "New card found. Waiting for save confirmation."
        case .alreadySaved:
            return "This recipe is already saved."
        case .saved:
            return "Saved to the local recipe library."
        }
    }

    private var statusStyle: AnyShapeStyle {
        switch appModel.cardStatus(for: entry.id) {
        case .ready:
            return AnyShapeStyle(.secondary)
        case .pendingSave:
            return AnyShapeStyle(.yellow)
        case .alreadySaved:
            return AnyShapeStyle(.orange)
        case .saved:
            return AnyShapeStyle(.green)
        }
    }
}
