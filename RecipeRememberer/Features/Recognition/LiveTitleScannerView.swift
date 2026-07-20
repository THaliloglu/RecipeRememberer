import AVFoundation
import SwiftUI
import UIKit

struct LiveTitleScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onRecipeCaptured: (RecipeCapturePayload) -> Void

    @State private var captureStep: CaptureStep = .front
    @State private var frontImageData: Data?
    @State private var backImageData: Data?
    @State private var captureTrigger = 0
    @State private var analysisResult: RecipePhotoAnalysis?
    @State private var analysisMessage: String?
    @State private var fatalScannerErrorMessage: String?
    @State private var isAnalyzing = false
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var permissionRequestTask: Task<Void, Never>?
    @State private var analysisTask: Task<Void, Never>?

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
                        message: "Allow camera access so the app can photograph the front and back of each printed recipe card.",
                        primaryActionTitle: "Continue to Camera",
                        primaryAction: requestCameraAccess
                    )
                case .permissionDenied:
                    ScannerStateCard(
                        title: "Camera Access Denied",
                        systemImage: "camera.badge.xmark",
                        message: "Enable camera access in Settings to capture your recipe cards.",
                        primaryActionTitle: "Open Settings",
                        primaryAction: openAppSettings
                    )
                case let .error(message):
                    ScannerStateCard(
                        title: "Scanner Error",
                        systemImage: "exclamationmark.triangle.fill",
                        message: message,
                        primaryActionTitle: "Try Again",
                        primaryAction: resetScanner
                    )
                }
            }
            .padding()
            .navigationTitle("Scan Recipe Card")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: closeScanner)
                }
            }
            .task {
                refreshCameraAuthorization()
            }
            .onDisappear {
                permissionRequestTask?.cancel()
                analysisTask?.cancel()
                permissionRequestTask = nil
                analysisTask = nil
            }
        }
    }

    private var scannerContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.sectionSpacing) {
                ZStack(alignment: .bottomLeading) {
                    RecipeCardCameraView(
                        captureTrigger: captureTrigger,
                        onPhotoCapture: handleCapturedPhotoData,
                        onError: handleFatalScannerError
                    )
                    .frame(minHeight: 360)
                    .clipShape(.rect(cornerRadius: 28))

                    CaptureStepOverlay(
                        step: captureStep,
                        frontCaptured: frontImageData != nil,
                        backCaptured: backImageData != nil,
                        isAnalyzing: isAnalyzing
                    )
                    .padding()
                }

                if let analysisMessage {
                    Text(analysisMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let frontImageData {
                    CapturedPhotoStrip(
                        frontImageData: frontImageData,
                        backImageData: backImageData
                    )
                }

                if isAnalyzing {
                    ProgressView("Analyzing front and back card photos...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let analysisResult {
                    RecipePhotoAnalysisCard(analysisResult: analysisResult)

                    HStack {
                        Button(
                            "Continue to Save Review",
                            systemImage: "square.and.arrow.down.on.square",
                            action: commitDetectedRecipe
                        )
                        .buttonStyle(.borderedProminent)

                        Button("Retake Front", systemImage: "arrow.counterclockwise", action: retakeFrontPhoto)
                            .buttonStyle(.bordered)

                        Button("Retake Back", systemImage: "arrow.counterclockwise", action: retakeBackPhoto)
                            .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        Button(captureStep.buttonTitle, systemImage: "camera", action: captureCurrentSide)
                            .buttonStyle(.borderedProminent)

                        if frontImageData != nil {
                            Button("Start Over", systemImage: "arrow.counterclockwise", action: resetCapturedPhotos)
                                .buttonStyle(.bordered)
                        }
                    }

                    Text(captureStep.helpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var scannerState: ScannerState {
        if let fatalScannerErrorMessage {
            return .error(fatalScannerErrorMessage)
        }

        switch cameraAuthorizationStatus {
        case .notDetermined:
            return .needsPermission
        case .denied, .restricted:
            return .permissionDenied
        case .authorized:
            return .ready
        @unknown default:
            return .error("The camera authorization state is not supported on this device.")
        }
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

    private func refreshCameraAuthorization() {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }

    private func closeScanner() {
        dismiss()
    }

    private func captureCurrentSide() {
        analysisMessage = nil
        captureTrigger += 1
    }

    private func handleCapturedPhotoData(_ photoData: Data) {
        analysisMessage = nil

        switch captureStep {
        case .front:
            frontImageData = photoData
            backImageData = nil
            analysisResult = nil
            captureStep = .back
            analysisMessage = "Front photo captured. Flip the card and capture the back."
        case .back:
            backImageData = photoData
            analysisMessage = "Back photo captured. Analyzing both sides now."
            analyzeCapturedPhotos()
        }
    }

    private func analyzeCapturedPhotos() {
        guard let frontImageData, let backImageData else {
            return
        }

        analysisTask?.cancel()
        isAnalyzing = true
        analysisResult = nil

        analysisTask = Task {
            do {
                let analysisResult = try await RecipePhotoAnalyzer.analyze(
                    frontImageData: frontImageData,
                    backImageData: backImageData
                )
                guard !Task.isCancelled else {
                    return
                }

                self.analysisResult = analysisResult
                analysisMessage = "The card was analyzed. Review the detected recipe before saving it."
                isAnalyzing = false
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                self.analysisResult = nil
                analysisMessage = error.localizedDescription
                isAnalyzing = false
                captureStep = .back
            }
        }
    }

    private func commitDetectedRecipe() {
        guard
            let analysisResult,
            let frontImageData,
            let backImageData
        else {
            return
        }

        let payload = RecipeCapturePayload(
            title: analysisResult.title,
            subtitle: analysisResult.subtitle,
            hellofreshCode: analysisResult.hellofreshCode,
            sourceDescription: "two-photo scanner",
            frontImageData: frontImageData,
            backImageData: backImageData,
            frontRecognizedText: analysisResult.frontRecognizedText,
            backRecognizedText: analysisResult.backRecognizedText,
            analysisSummary: analysisResult.analysisSummary
        )

        onRecipeCaptured(payload)
        dismiss()
    }

    private func retakeFrontPhoto() {
        analysisTask?.cancel()
        captureStep = .front
        frontImageData = nil
        backImageData = nil
        analysisResult = nil
        isAnalyzing = false
        analysisMessage = "Capture the front of the recipe card again."
    }

    private func retakeBackPhoto() {
        analysisTask?.cancel()
        captureStep = .back
        backImageData = nil
        analysisResult = nil
        isAnalyzing = false
        analysisMessage = "Capture the back of the recipe card again."
    }

    private func resetCapturedPhotos() {
        analysisTask?.cancel()
        captureStep = .front
        frontImageData = nil
        backImageData = nil
        analysisResult = nil
        isAnalyzing = false
        analysisMessage = nil
    }

    private func resetScanner() {
        fatalScannerErrorMessage = nil
        resetCapturedPhotos()
        refreshCameraAuthorization()
    }

    private func handleFatalScannerError(_ message: String) {
        fatalScannerErrorMessage = message
    }
}

private enum ScannerState {
    case ready
    case needsPermission
    case permissionDenied
    case error(String)
}

private enum CaptureStep {
    case front
    case back

    var buttonTitle: String {
        switch self {
        case .front:
            return "Capture Front Photo"
        case .back:
            return "Capture Back Photo"
        }
    }

    var helpText: String {
        switch self {
        case .front:
            return "Capture the front of the card."
        case .back:
            return "Turn the card over and capture the back."
        }
    }

    var overlayTitle: String {
        switch self {
        case .front:
            return "Step 1 of 2"
        case .back:
            return "Step 2 of 2"
        }
    }

    var overlayMessage: String {
        switch self {
        case .front:
            return "Capture the front of the recipe card."
        case .back:
            return "Capture the back of the recipe card."
        }
    }
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
                .padding(.bottom)
        }
    }
}

private struct CaptureStepOverlay: View {
    let step: CaptureStep
    let frontCaptured: Bool
    let backCaptured: Bool
    let isAnalyzing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isAnalyzing ? "Analyzing Card Photos" : step.overlayTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Text(isAnalyzing ? "Reading the captured front and back photos." : step.overlayMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 12) {
                Label(frontCaptured ? "Front Ready" : "Front Pending", systemImage: frontCaptured ? "checkmark.circle.fill" : "circle")
                Label(backCaptured ? "Back Ready" : "Back Pending", systemImage: backCaptured ? "checkmark.circle.fill" : "circle")
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.95))
        }
        .padding(14)
        .background(.black.opacity(0.55), in: .rect(cornerRadius: 20))
    }
}

private struct CapturedPhotoStrip: View {
    let frontImageData: Data
    let backImageData: Data?

    var body: some View {
        HStack(spacing: 12) {
            CapturedPhotoThumbnail(
                title: "Front",
                imageData: frontImageData
            )

            if let backImageData {
                CapturedPhotoThumbnail(
                    title: "Back",
                    imageData: backImageData
                )
            }
        }
    }
}

private struct CapturedPhotoThumbnail: View {
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

private struct RecipePhotoAnalysisCard: View {
    let analysisResult: RecipePhotoAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Recipe")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text(analysisResult.title)
                    .font(.title3)
                    .bold()

                if !analysisResult.subtitle.isEmpty {
                    Text(analysisResult.subtitle)
                        .foregroundStyle(.secondary)
                }

                if let hellofreshCode = analysisResult.hellofreshCode {
                    Label(hellofreshCode, systemImage: "number.square")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
    }
}
