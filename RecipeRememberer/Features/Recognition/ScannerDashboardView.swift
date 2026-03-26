import SwiftUI

struct ScannerDashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Scan a title, check for duplicates, and save new cards.")
                    .foregroundStyle(.secondary)

                ScanRecipeTitleSection()

                if let feedback = appModel.latestFeedback {
                    RecognitionFeedbackCard(feedback: feedback)
                }

                if let draft = appModel.pendingRecipeDraft {
                    PendingSaveCard(draft: draft)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("Scanner")
    }
}

#Preview {
    NavigationStack {
        ScannerDashboardView()
            .environment(AppModel())
    }
}
