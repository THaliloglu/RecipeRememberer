import SwiftData
import SwiftUI

struct PendingSaveCard: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let draft = appModel.pendingRecipeDraft {
            PendingRecipeDraftEditor(
                draft: draft,
                onSave: { title, subtitle, hellofreshCode in
                    appModel.updatePendingDraft(
                        title: title,
                        subtitle: subtitle,
                        hellofreshCode: hellofreshCode
                    )
                    appModel.confirmPendingSave(using: modelContext)
                },
                onDismiss: appModel.dismissPendingSave
            )
        }
    }
}

private struct PendingRecipeDraftEditor: View {
    let draft: AppModel.PendingRecipeDraft
    let onSave: (String, String, String) -> Void
    let onDismiss: () -> Void
    
    @State private var title: String
    @State private var subtitle: String
    @State private var hellofreshCode: String

    init(
        draft: AppModel.PendingRecipeDraft,
        onSave: @escaping (String, String, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.draft = draft
        self.onSave = onSave
        self.onDismiss = onDismiss
        _title = State(initialValue: draft.title)
        _subtitle = State(initialValue: draft.subtitle)
        _hellofreshCode = State(initialValue: draft.hellofreshCode ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Before Saving")
                .font(.headline)

            Text("Edit the detected recipe if needed, then save it to your local library.")
                .foregroundStyle(.secondary)

            TextField("Recipe title", text: $title)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)

            TextField("Subtitle (optional)", text: $subtitle)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)

            TextField("HelloFresh code (optional)", text: $hellofreshCode)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.characters)

            if !draft.sourceDescription.isEmpty {
                Text("Detected from \(draft.sourceDescription). Saved recipes stay on this device unless you add sync later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Save Recipe", systemImage: "square.and.arrow.down") {
                    onSave(title, subtitle, hellofreshCode)
                }
                    .buttonStyle(.borderedProminent)

                Button("Not Now", systemImage: "xmark", action: onDismiss)
                    .buttonStyle(.bordered)
            }
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
    }
}
