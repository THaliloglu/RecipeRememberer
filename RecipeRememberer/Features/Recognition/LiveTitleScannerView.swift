import SwiftUI
import VisionKit

struct LiveTitleScannerView: View {
    @Environment(\.dismiss) private var dismiss

    let onTitleCaptured: (String) -> Void

    @State private var detectedTitle = ""

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    VStack(spacing: 16) {
                        DataScannerContainerView(detectedTitle: $detectedTitle)
                            .clipShape(.rect(cornerRadius: 28))
                            .overlay(alignment: .bottomLeading) {
                                ScannerOverlayCard(detectedTitle: detectedTitle)
                                    .padding()
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aim the camera at the printed recipe title, then tap the matching text in the camera view to lock it in.")
                                .foregroundStyle(.secondary)

                            Button("Use Detected Title", systemImage: "checkmark.text.box") {
                                let trimmedTitle = detectedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedTitle.isEmpty else {
                                    return
                                }

                                onTitleCaptured(trimmedTitle)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(detectedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Live Scanner Unavailable",
                        systemImage: "camera.metering.unknown",
                        description: Text("This device does not support the live text scanner. You can still type or dictate the recipe title manually.")
                    )
                }
            }
            .padding()
            .navigationTitle("Live Title Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ScannerOverlayCard: View {
    let detectedTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detected Title")
                .font(.headline)

            Text(detectedTitle.isEmpty ? "No title captured yet" : detectedTitle)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }
}

private struct DataScannerContainerView: UIViewControllerRepresentable {
    @Binding var detectedTitle: String

    func makeCoordinator() -> Coordinator {
        Coordinator(detectedTitle: $detectedTitle)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerViewController = DataScannerViewController(
            recognizedDataTypes: [
                .text(
                    languages: ["en", "de"],
                    textContentType: nil
                ),
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                context.coordinator.reportScannerError(error)
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding private var detectedTitle: String

        init(detectedTitle: Binding<String>) {
            _detectedTitle = detectedTitle
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateDetectedTitle(from: allItems.isEmpty ? addedItems : allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateDetectedTitle(from: allItems.isEmpty ? updatedItems : allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            updateDetectedTitle(from: [item])
        }

        func reportScannerError(_ error: Error) {
            detectedTitle = "Scanner error: \(error.localizedDescription)"
        }

        private func updateDetectedTitle(from items: [RecognizedItem]) {
            let candidates = items.compactMap { item in
                switch item {
                case let .text(text):
                    return text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                default:
                    return nil
                }
            }

            guard let bestCandidate = candidates.max(by: { left, right in
                score(for: left) < score(for: right)
            }) else {
                return
            }

            detectedTitle = bestCandidate
        }

        private func score(for candidate: String) -> Int {
            let wordCount = candidate.split(separator: " ").count
            return wordCount * 100 + candidate.count
        }
    }
}

#Preview {
    LiveTitleScannerView { _ in }
}
