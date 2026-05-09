import SwiftUI

struct TitleScanStatusCard: View {
    let result: AppModel.TitleScanResult

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(iconStyle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(result.title)
                    .font(.headline)

                Text(result.message)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppStyle.cardPadding)
        .padding(.vertical, 12)
        .background(.background.opacity(0.65), in: .rect(cornerRadius: AppStyle.compactCardCornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch result.stage {
        case .idle:
            return "text.viewfinder"
        case .analyzing:
            return "viewfinder.circle"
        case .matchedSavedRecipe:
            return "checkmark.circle.fill"
        case .matchedCatalogRecipe:
            return "doc.text.image"
        case .newRecipe:
            return "plus.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconStyle: AnyShapeStyle {
        switch result.stage {
        case .idle:
            return AnyShapeStyle(.secondary)
        case .analyzing:
            return AnyShapeStyle(.blue)
        case .matchedSavedRecipe:
            return AnyShapeStyle(.green)
        case .matchedCatalogRecipe:
            return AnyShapeStyle(.blue)
        case .newRecipe:
            return AnyShapeStyle(.orange)
        case .failed:
            return AnyShapeStyle(.red)
        }
    }
}
