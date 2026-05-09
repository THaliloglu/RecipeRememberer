import SwiftUI

struct RecentScanHistorySection: View {
    let records: [AppModel.RecentScanRecord]

    var body: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: AppStyle.cardSpacing) {
                Text("Recent Captures")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(records) { record in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: symbolName(for: record.stage))
                                .foregroundStyle(iconStyle(for: record.stage))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.title)
                                    .font(.subheadline)
                                    .bold()

                                if !record.subtitle.isEmpty {
                                    Text(record.subtitle)
                                        .foregroundStyle(.secondary)
                                }

                                if let hellofreshCode = record.hellofreshCode {
                                    Label(hellofreshCode, systemImage: "number.square")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Text(record.message)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Text(
                                    "\(record.capturedAt.formatted(date: .abbreviated, time: .shortened)) • \(record.sourceDescription)"
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

    private func symbolName(for stage: AppModel.TitleScanStage) -> String {
        switch stage {
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

    private func iconStyle(for stage: AppModel.TitleScanStage) -> AnyShapeStyle {
        switch stage {
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
