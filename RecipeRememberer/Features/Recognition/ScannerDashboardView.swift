import SwiftUI

struct ScannerDashboardView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var appModel = appModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Printed HelloFresh Recipe Cards")
                    .font(.largeTitle)
                    .bold()

                Text("Look at a recipe card in the mixed immersive scanner to identify it, compare it against your local library, and save it when it is new. Use photo OCR when you want to onboard cards that are not yet part of the live reference-image set.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    Picker("Save mode", selection: $appModel.saveMode) {
                        Text("Ask First").tag(AppModel.SaveMode.confirmFirst)
                        Text("Save Automatically").tag(AppModel.SaveMode.automatic)
                    }
                    .pickerStyle(.segmented)

                    Button(appModel.isImmersiveSpaceShown ? "Close Live Scanner" : "Open Live Scanner", systemImage: appModel.isImmersiveSpaceShown ? "xmark.circle" : "visionpro") {
                        Task {
                            if appModel.isImmersiveSpaceShown {
                                await dismissImmersiveSpace()
                                appModel.isImmersiveSpaceShown = false
                            } else {
                                let result = await openImmersiveSpace(id: AppModel.immersiveSpaceID)
                                appModel.isImmersiveSpaceShown = result == .opened
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Text("The scanner compares against bundled reference images inside `ReferenceCards`. Press `Open Live Scanner` to start the immersive card matcher.")
                        .foregroundStyle(.secondary)

                    Text("Tip: replace the sample assets in the `ReferenceCards` folder with scans or photos of your own HelloFresh card fronts for the best live tracking results.")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .glassBackgroundEffect()

                LiveReferenceStatusSection()

                RecipePhotoImportButton()

                if let feedback = appModel.latestFeedback {
                    RecognitionFeedbackCard(feedback: feedback)
                }

                if let draft = appModel.pendingRecipeDraft {
                    PendingSaveCard(draft: draft)
                }

                if !appModel.lastImportedText.isEmpty {
                    Text("Most Recent OCR Extract")
                        .font(.title3)
                        .bold()

                    Text(appModel.lastImportedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassBackgroundEffect()
                }
            }
            .padding()
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
