import SwiftData
import SwiftUI

struct PendingSaveCard: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    let draft: AppModel.PendingRecipeDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save New Recipe?")
                .font(.headline)

            Text(draft.title)
                .font(.title3)
                .bold()

            Text(draft.subtitle)
                .foregroundStyle(.secondary)

            if let hellofreshCode = draft.hellofreshCode {
                Text("HelloFresh code: \(hellofreshCode)")
                    .foregroundStyle(.secondary)
            }

            Text("Source: \(draft.sourceDescription)")
                .foregroundStyle(.secondary)

            HStack {
                Button("Save Recipe", systemImage: "square.and.arrow.down") {
                    appModel.confirmPendingSave(using: modelContext)
                }
                .buttonStyle(.borderedProminent)

                Button("Not Now", systemImage: "xmark") {
                    appModel.dismissPendingSave()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
