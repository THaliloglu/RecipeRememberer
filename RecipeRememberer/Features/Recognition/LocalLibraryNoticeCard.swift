import SwiftUI

struct LocalLibraryNoticeCard: View {
    let title: String
    let message: String
    var caption: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "internaldrive.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .foregroundStyle(.secondary)

                if let caption {
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
        .accessibilityElement(children: .combine)
    }
}
