import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct LiveTitleScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onRecipeCaptured: (String, String, String?) -> Void

    @State private var detectedRecipe = DetectedRecipeText()
    @State private var preferredTitle: String?
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
                detectedRecipe: $detectedRecipe,
                preferredTitle: $preferredTitle,
                scannerErrorMessage: $scannerErrorMessage
            )
            .id(scannerSessionID)
            .clipShape(.rect(cornerRadius: 28))
            .overlay(alignment: .bottomLeading) {
                ScannerOverlayCard(
                    detectedRecipe: detectedRecipe,
                    captureQuality: captureQuality
                )
                .padding()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Aim the camera at the recipe header, then tap the title line if you want to lock onto a specific result.")
                    .foregroundStyle(.secondary)

                if captureQuality == .weak {
                    Text("This capture still looks a little weak. Move closer, steady the device, or tap a clearer title line before saving.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if captureQuality == .good {
                    Button("Review Captured Recipe", systemImage: "pencil.and.outline") {
                        commitDetectedRecipe()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Use Current Capture", systemImage: "checkmark.text.box") {
                        commitDetectedRecipe()
                    }
                    .buttonStyle(.bordered)
                    .disabled(detectedRecipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        let trimmedTitle = detectedRecipe.title.trimmingCharacters(in: .whitespacesAndNewlines)
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
        detectedRecipe = DetectedRecipeText()
        preferredTitle = nil
        scannerSessionID = UUID()
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func commitDetectedRecipe() {
        let trimmedTitle = detectedRecipe.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        onRecipeCaptured(
            trimmedTitle,
            detectedRecipe.subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            normalizedOptionalField(detectedRecipe.hellofreshCode)
        )
        dismiss()
    }

    private func normalizedOptionalField(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

private struct DetectedRecipeText: Equatable {
    var title = ""
    var subtitle = ""
    var hellofreshCode: String?
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
    let detectedRecipe: DetectedRecipeText
    let captureQuality: CaptureQuality

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detected Recipe")
                .font(.headline)

            Text(detectedRecipe.title.isEmpty ? "No title captured yet" : detectedRecipe.title)
                .bold()
                .foregroundStyle(.primary)

            if !detectedRecipe.subtitle.isEmpty {
                Text(detectedRecipe.subtitle)
                    .foregroundStyle(.secondary)
            }

            if let hellofreshCode = detectedRecipe.hellofreshCode {
                Label(hellofreshCode, systemImage: "number.square")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(qualityMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
    @Binding var detectedRecipe: DetectedRecipeText
    @Binding var preferredTitle: String?
    @Binding var scannerErrorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            detectedRecipe: $detectedRecipe,
            preferredTitle: $preferredTitle,
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
        @Binding private var detectedRecipe: DetectedRecipeText
        @Binding private var preferredTitle: String?
        @Binding private var scannerErrorMessage: String?
        private var latestTextLines: [RecipeCardTextLine] = []

        init(
            detectedRecipe: Binding<DetectedRecipeText>,
            preferredTitle: Binding<String?>,
            scannerErrorMessage: Binding<String?>
        ) {
            _detectedRecipe = detectedRecipe
            _preferredTitle = preferredTitle
            _scannerErrorMessage = scannerErrorMessage
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateDetectedRecipe(from: allItems.isEmpty ? addedItems : allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateDetectedRecipe(from: allItems.isEmpty ? updatedItems : allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            if case let .text(text) = item {
                preferredTitle = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if latestTextLines.isEmpty, case let .text(text) = item {
                latestTextLines = [
                    RecipeCardTextLine(
                        transcript: text.transcript,
                        frame: boundingRect(for: text.bounds)
                    ),
                ]
            }

            updateDetectedRecipe(from: latestTextLines)
        }

        func reportScannerError(_ error: Error) {
            detectedRecipe = DetectedRecipeText()
            scannerErrorMessage = error.localizedDescription
        }

        private func updateDetectedRecipe(from items: [RecognizedItem]) {
            latestTextLines = items.compactMap { item -> RecipeCardTextLine? in
                guard case let .text(text) = item else {
                    return nil
                }

                return RecipeCardTextLine(
                    transcript: text.transcript,
                    frame: boundingRect(for: text.bounds)
                )
            }

            updateDetectedRecipe(from: latestTextLines)
        }

        private func updateDetectedRecipe(from lines: [RecipeCardTextLine]) {
            guard let parsedRecipe = RecipeCardTextParser.parse(
                from: lines,
                preferredTitle: preferredTitle
            ) else {
                return
            }

            scannerErrorMessage = nil
            detectedRecipe = DetectedRecipeText(
                title: parsedRecipe.title,
                subtitle: parsedRecipe.subtitle,
                hellofreshCode: parsedRecipe.hellofreshCode
            )
        }

        private func boundingRect(for bounds: RecognizedItem.Bounds) -> CGRect {
            let xValues = [
                bounds.topLeft.x,
                bounds.topRight.x,
                bounds.bottomLeft.x,
                bounds.bottomRight.x,
            ]
            let yValues = [
                bounds.topLeft.y,
                bounds.topRight.y,
                bounds.bottomLeft.y,
                bounds.bottomRight.y,
            ]
            let minX = xValues.min() ?? 0
            let maxX = xValues.max() ?? 0
            let minY = yValues.min() ?? 0
            let maxY = yValues.max() ?? 0

            return CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }
    }
}

#Preview {
    LiveTitleScannerView { _, _, _ in }
}
