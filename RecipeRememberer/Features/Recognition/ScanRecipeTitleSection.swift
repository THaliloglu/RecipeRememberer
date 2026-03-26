import SwiftUI

struct ScanRecipeTitleSection: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var isLiveScannerPresented = false

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe Title")
                        .font(.headline)
                        .bold()

                    Text("Use the camera or type a title.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Save mode", selection: $appModel.saveMode) {
                    Text("Ask First").tag(AppModel.SaveMode.confirmFirst)
                    Text("Auto Save").tag(AppModel.SaveMode.automatic)
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Button {
                isLiveScannerPresented = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open Scanner")
                            .font(.headline)

                        Text("Point at the printed recipe title")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 12) {
                TextField("Recipe title", text: $appModel.titleScanInput)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)

                Button("Check", systemImage: "text.viewfinder") {
                    appModel.scanRecipeTitle(using: modelContext)
                }
                .buttonStyle(.bordered)
            }

            if appModel.latestTitleScanResult.stage != .idle {
                TitleScanStatusCard(result: appModel.latestTitleScanResult)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 20))
        .sheet(isPresented: $isLiveScannerPresented) {
            LiveTitleScannerView { detectedTitle in
                appModel.scanRecipeTitle(detectedTitle, using: modelContext)
            }
        }
    }
}

private struct TitleScanStatusCard: View {
    let result: AppModel.TitleScanResult

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(iconStyle)

            VStack(alignment: .leading, spacing: 6) {
                Text(result.title)
                    .font(.headline)

                Text(result.message)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.background.opacity(0.65), in: .rect(cornerRadius: 18))
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

#Preview {
    ScanRecipeTitleSection()
        .environment(AppModel())
}
