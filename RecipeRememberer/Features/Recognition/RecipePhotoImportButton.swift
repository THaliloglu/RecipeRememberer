import PhotosUI
import SwiftData
import SwiftUI

struct RecipePhotoImportButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Analyze a Recipe Photo", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if appModel.isAnalyzingImportedCard {
                ProgressView("Analyzing recipe card...")
            }
        }
        .padding()
        .glassBackgroundEffect()
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                if let imageData = try? await newValue.loadTransferable(type: Data.self) {
                    await appModel.analyzeImportedCard(from: imageData, using: modelContext)
                }

                selectedPhoto = nil
            }
        }
    }
}
