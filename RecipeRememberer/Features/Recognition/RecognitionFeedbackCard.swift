import SwiftUI

struct RecognitionFeedbackCard: View {
    let feedback: AppModel.RecognitionFeedback

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(iconStyle)

            VStack(alignment: .leading, spacing: 6) {
                Text(feedback.title)
                    .font(.headline)

                Text(feedback.message)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 24))
    }

    private var symbolName: String {
        switch feedback.style {
        case .neutral:
            return "viewfinder.circle"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconStyle: AnyShapeStyle {
        switch feedback.style {
        case .neutral:
            return AnyShapeStyle(.blue)
        case .success:
            return AnyShapeStyle(.green)
        case .warning:
            return AnyShapeStyle(.orange)
        }
    }
}
