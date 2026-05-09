import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct LiveTitleScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onTitleCaptured: (String) -> Void

    @State private var detectedTitle = ""
    @State private var scannerErrorMessage: String?
    @State private var scannerSessionID = UUID()
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var permissionRequestTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                switch scannerState {
                case .ready:
                    scannerContent
                case .needsPermission:
                    ScannerStateCard(
                        title: "Camera Access Needed",
                        systemImage: "camera.badge.ellipsis",
                        message: "Allow camera access to scan printed recipe titles on your device.",
                        primaryActionTitle: "Continue to Camera",
                        primaryAction: requestCameraAccess
                    )
                case .permissionDenied:
                    ScannerStateCard(
                        title: "Camera Access Denied",
                        systemImage: "camera.badge.xmark",
                        message: "Enable camera access in Settings to use the live title scanner.",
                        primaryActionTitle: "Open Settings",
                        primaryAction: openAppSettings
                    )
                case .notSupported:
                    ContentUnavailableView(
                        "Live Scanner Unavailable",
                        systemImage: "camera.metering.unknown",
                        description: Text("This device does not support the live text scanner. You can still type or dictate the recipe title manually.")
                    )
                case let .error(message):
                    ScannerStateCard(
                        title: "Scanner Error",
                        systemImage: "exclamationmark.triangle.fill",
                        message: message,
                        primaryActionTitle: "Try Again",
                        primaryAction: retryScanner
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
            .task {
                cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
            .onDisappear {
                permissionRequestTask?.cancel()
                permissionRequestTask = nil
            }
        }
    }

    private var scannerContent: some View {
        VStack(spacing: 16) {
            DataScannerContainerView(
                detectedTitle: $detectedTitle,
                scannerErrorMessage: $scannerErrorMessage
            )
            .id(scannerSessionID)
            .clipShape(.rect(cornerRadius: 28))
            .overlay(alignment: .bottomLeading) {
                ScannerOverlayCard(
                    detectedTitle: detectedTitle,
                    captureQuality: captureQuality
                )
                .padding()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Aim the camera at the printed recipe title, then tap the matching text in the camera view to lock it in.")
                    .foregroundStyle(.secondary)

                if captureQuality == .weak {
                    Text("This capture looks a little weak. Move closer, steady the device, or tap a clearer line before saving.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if captureQuality == .good {
                    Button("Review Captured Title", systemImage: "pencil.and.outline") {
                        commitDetectedTitle()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Use Current Capture", systemImage: "checkmark.text.box") {
                        commitDetectedTitle()
                    }
                    .buttonStyle(.bordered)
                    .disabled(detectedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var scannerState: ScannerState {
        if let scannerErrorMessage {
            return .error(scannerErrorMessage)
        }

        switch cameraAuthorizationStatus {
        case .notDetermined:
            return .needsPermission
        case .denied, .restricted:
            return .permissionDenied
        case .authorized:
            guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else {
                return .notSupported
            }
            return .ready
        @unknown default:
            return .notSupported
        }
    }

    private var captureQuality: CaptureQuality {
        let trimmedTitle = detectedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmedTitle.split(separator: " ").count

        if trimmedTitle.isEmpty {
            return .empty
        }

        if trimmedTitle.count < 12 || wordCount < 2 {
            return .weak
        }

        return .good
    }

    private func requestCameraAccess() {
        permissionRequestTask?.cancel()
        permissionRequestTask = Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !Task.isCancelled else {
                return
            }
            cameraAuthorizationStatus = granted ? .authorized : .denied
            permissionRequestTask = nil
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }

    private func retryScanner() {
        scannerErrorMessage = nil
        detectedTitle = ""
        scannerSessionID = UUID()
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func commitDetectedTitle() {
        let trimmedTitle = detectedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        onTitleCaptured(trimmedTitle)
        dismiss()
    }
}

private enum ScannerState {
    case ready
    case needsPermission
    case permissionDenied
    case notSupported
    case error(String)
}

private enum CaptureQuality {
    case empty
    case weak
    case good
}

private struct ScannerStateCard: View {
    let title: String
    let systemImage: String
    let message: String
    let primaryActionTitle: String
    let primaryAction: () -> Void

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .overlay(alignment: .bottom) {
            Button(primaryActionTitle, action: primaryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(.bottom, 56)
    }
}

private struct ScannerOverlayCard: View {
    let detectedTitle: String
    let captureQuality: CaptureQuality

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detected Title")
                .font(.headline)

            Text(detectedTitle.isEmpty ? "No title captured yet" : detectedTitle)
                .foregroundStyle(.secondary)

            Text(qualityMessage)
                .font(.footnote)
                .foregroundStyle(qualityStyle)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    private var qualityMessage: String {
        switch captureQuality {
        case .empty:
            return "Point the camera at the printed recipe title."
        case .weak:
            return "Low-confidence capture."
        case .good:
            return "Looks good."
        }
    }

    private var qualityStyle: AnyShapeStyle {
        switch captureQuality {
        case .empty:
            return AnyShapeStyle(.secondary)
        case .weak:
            return AnyShapeStyle(.orange)
        case .good:
            return AnyShapeStyle(.green)
        }
    }
}

private struct DataScannerContainerView: UIViewControllerRepresentable {
    @Binding var detectedTitle: String
    @Binding var scannerErrorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            detectedTitle: $detectedTitle,
            scannerErrorMessage: $scannerErrorMessage
        )
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
                scannerErrorMessage = nil
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
        @Binding private var scannerErrorMessage: String?

        init(
            detectedTitle: Binding<String>,
            scannerErrorMessage: Binding<String?>
        ) {
            _detectedTitle = detectedTitle
            _scannerErrorMessage = scannerErrorMessage
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
            detectedTitle = ""
            scannerErrorMessage = error.localizedDescription
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

            scannerErrorMessage = nil
            detectedTitle = bestCandidate
        }

        private func score(for candidate: String) -> Int {
            let wordCount = candidate.split(separator: " ").count
            let hasMixedCase = candidate != candidate.lowercased()
            let normalizedCandidate = candidate.lowercased()
            let penalty = ignoredPhrases.reduce(into: 0) { partialResult, phrase in
                if normalizedCandidate.localizedStandardContains(phrase) {
                    partialResult += 160
                }
            }
            let digitPenalty = candidate.contains(where: \.isNumber) ? 40 : 0
            let titleBonus = titleWords.reduce(into: 0) { partialResult, word in
                if normalizedCandidate.localizedStandardContains(word) {
                    partialResult += 35
                }
            }

            return wordCount * 100
                + candidate.count
                + (hasMixedCase ? 20 : 0)
                + titleBonus
                - penalty
                - digitPenalty
        }

        private var ignoredPhrases: [String] {
            [
                "hello fresh",
                "hellofresh",
                "min",
                "kcal",
                "protein",
                "kalorien",
                "geschmack",
            ]
        }

        private var titleWords: [String] {
            [
                "gratin",
                "chicken",
                "rigatoni",
                "pasta",
                "soup",
                "bowl",
                "porree",
                "kartoffeln",
                "beef",
                "veggie",
            ]
        }
    }
}

#Preview {
    LiveTitleScannerView { _ in }
}
