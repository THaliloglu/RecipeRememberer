import SwiftUI

struct ScannerDashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.sectionSpacing) {
                ScanRecipeTitleSection()

                if let feedback = appModel.latestFeedback {
                    RecognitionFeedbackCard(feedback: feedback)
                }

                PendingSaveCard()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        ScannerDashboardView()
            .environment(AppModel())
    }
}
