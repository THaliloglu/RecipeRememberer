import SwiftUI

struct ScanRecipeTitleSection: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var isLiveScannerPresented = false

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: AppStyle.cardSpacing) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Recipe")
                        .font(.headline)
                        .bold()

                    Text("Scan a card or type a title.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    ForEach(AppModel.SaveMode.allCases) { mode in
                        Button(mode.shortTitle) {
                            appModel.saveMode = mode
                        }
                    }
                } label: {
                    Label(appModel.saveMode.shortTitle, systemImage: "square.and.arrow.down.on.square")
                }
                .accessibilityLabel("Save Mode")
                .accessibilityValue(appModel.saveMode.shortTitle)
                .accessibilityHint(appModel.saveMode.detail)
            }

            Button(action: openScanner) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open Scanner")
                            .font(.headline)

                        Text("Front photo, back photo, then review")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("scanner.open")
            .accessibilityHint("Opens the camera to capture the front and back of a printed recipe card.")

            HStack(spacing: 12) {
                TextField("Recipe title", text: $appModel.titleScanInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit {
                        appModel.scanRecipeTitle(using: modelContext)
                    }

                Button("Check", systemImage: "text.viewfinder", action: checkTypedTitle)
                .buttonStyle(.bordered)
                .accessibilityHint("Compares the typed recipe title with your saved recipes.")
            }

            Text("The large recipe title on the front card is the main comparison signal.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
        .fullScreenCover(isPresented: $isLiveScannerPresented) {
            LiveTitleScannerView()
        }
    }

    private func openScanner() {
        isLiveScannerPresented = true
    }

    private func checkTypedTitle() {
        appModel.scanRecipeTitle(using: modelContext)
    }
}
