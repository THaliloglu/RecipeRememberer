import SwiftUI

struct ScannerDashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.sectionSpacing) {
                Text("Scan a recipe title, review it, check for duplicates, and save it to your local library.")
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isSummaryElement)

                LocalLibraryNoticeCard(
                    title: "Local-Only Storage",
                    message: "Recipes stay on this device by default. Nothing is uploaded unless you add sync later.",
                    caption: "Recipe Rememberer is an independent tool and is not affiliated with HelloFresh."
                )

                ScanRecipeTitleSection()

                if appModel.latestTitleScanResult.stage != .idle {
                    TitleScanStatusCard(result: appModel.latestTitleScanResult)
                }

                if let feedback = appModel.latestFeedback {
                    RecognitionFeedbackCard(feedback: feedback)
                }

                PendingSaveCard()

                RecentSavedRecipesSection()
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
