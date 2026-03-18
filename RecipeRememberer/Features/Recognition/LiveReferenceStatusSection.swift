import SwiftUI

struct LiveReferenceStatusSection: View {
    private let entries = SampleRecipeCatalog.entries

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Comparison Readiness")
                .font(.title3)
                .bold()

            Text("Live card recognition only works for recipes whose front-card PNG is bundled with the app. Recipes without a bundled PNG still work through photo OCR.")
                .foregroundStyle(.secondary)

            ForEach(entries) { entry in
                LiveReferenceStatusRow(entry: entry)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}

private struct LiveReferenceStatusRow: View {
    let entry: RecipeCatalogEntry

    private var hasBundledReferenceImage: Bool {
        Bundle.main.url(
            forResource: entry.referenceImageName,
            withExtension: "png",
            subdirectory: "ReferenceCards"
        ) != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasBundledReferenceImage ? "checkmark.circle.fill" : "photo.badge.exclamationmark")
                .foregroundStyle(hasBundledReferenceImage ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)

                if !entry.subtitle.isEmpty {
                    Text(entry.subtitle)
                        .foregroundStyle(.secondary)
                }

                Text(hasBundledReferenceImage ? "Live scanner ready" : "OCR import only until \(entry.referenceImageName).png is added to ReferenceCards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    LiveReferenceStatusSection()
}
