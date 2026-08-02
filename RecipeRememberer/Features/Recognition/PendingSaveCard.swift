import SwiftData
import SwiftUI
import UIKit

struct PendingSaveCard: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let draft = appModel.pendingRecipeDraft, draft.capturePayload != nil {
            PendingRecipeDraftEditor(
                draft: draft,
                onSave: { title, subtitle in
                    appModel.updatePendingDraft(
                        title: title,
                        subtitle: subtitle
                    )
                    appModel.confirmPendingSave(using: modelContext)
                },
                onDismiss: appModel.dismissPendingSave
            )
        }
    }
}

private struct PendingRecipeDraftEditor: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    let draft: AppModel.PendingRecipeDraft
    let onSave: (String, String) -> Void
    let onDismiss: () -> Void
    
    @State private var title: String
    @State private var subtitle: String
    @State private var duplicateRecipe: StoredRecipe?

    init(
        draft: AppModel.PendingRecipeDraft,
        onSave: @escaping (String, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.draft = draft
        self.onSave = onSave
        self.onDismiss = onDismiss
        _title = State(initialValue: draft.title)
        _subtitle = State(initialValue: draft.subtitle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Recipe")
                .font(.headline)

            if let capturePayload = draft.capturePayload {
                PendingCapturedPhotoStrip(capturePayload: capturePayload)
            }

            TextField("Recipe title", text: $title)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)

            TextField("Subtitle (optional)", text: $subtitle)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)

            if let duplicateRecipe {
                Label(
                    "Already saved as \(duplicateRecipe.title).",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            } else if !draft.sourceDescription.isEmpty {
                Text("Detected from \(draft.sourceDescription).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Save Recipe", systemImage: "square.and.arrow.down") {
                    onSave(title, subtitle)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || duplicateRecipe != nil
                )

                Button("Not Now", systemImage: "xmark", action: onDismiss)
                    .buttonStyle(.bordered)
            }
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
        .task {
            refreshDuplicateRecipe()
        }
        .onChange(of: title) { _, _ in
            refreshDuplicateRecipe()
        }
        .onChange(of: subtitle) { _, _ in
            refreshDuplicateRecipe()
        }
    }

    private func refreshDuplicateRecipe() {
        duplicateRecipe = appModel.duplicateRecipe(
            title: title,
            subtitle: subtitle,
            capturePayload: draft.capturePayload,
            using: modelContext
        )
    }
}

private struct PendingCapturedPhotoStrip: View {
    let capturePayload: RecipeCapturePayload

    var body: some View {
        HStack(spacing: 12) {
            PendingCapturedPhotoThumbnail(
                title: "Front",
                imageData: capturePayload.frontImageData
            )
            PendingCapturedPhotoThumbnail(
                title: "Back",
                imageData: capturePayload.backImageData
            )
        }
    }
}

private struct PendingCapturedPhotoThumbnail: View {
    let title: String
    let imageData: Data

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .clipShape(.rect(cornerRadius: 18))
            } else {
                ContentUnavailableView(
                    "Photo Unavailable",
                    systemImage: "photo"
                )
                .frame(height: 112)
            }
        }
    }
}
