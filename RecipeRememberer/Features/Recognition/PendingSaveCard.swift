import SwiftData
import SwiftUI

struct PendingSaveCard: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    let draft: AppModel.PendingRecipeDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Recipe")
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

            if draft.sampleImageData != nil {
                Text("This save will also store a local comparison sample so future recipe photos can be matched visually.")
                    .foregroundStyle(.secondary)
            }

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
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 24))
    }
}
