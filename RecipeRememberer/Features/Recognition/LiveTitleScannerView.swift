import AVFoundation
import SwiftUI
import UIKit

struct LiveTitleScannerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

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
    @State private var frontOrientation: CaptureCardOrientation = .landscape
    @State private var backOrientation: CaptureCardOrientation = .landscape
    @State private var cameraZoomFactor = 1.0

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
                    .padding()
                case .permissionDenied:
                    ScannerStateCard(
                        title: "Camera Access Denied",
                        systemImage: "camera.badge.xmark",
                        message: "Enable camera access in Settings to capture your recipe cards.",
                        primaryActionTitle: "Open Settings",
                        primaryAction: openAppSettings
                    )
                    .padding()
                case let .error(message):
                    ScannerStateCard(
                        title: "Scanner Error",
                        systemImage: "exclamationmark.triangle.fill",
                        message: message,
                        primaryActionTitle: "Try Again",
                        primaryAction: resetScanner
                    )
                    .padding()
                }
            }
            .background(.background)
            .navigationTitle("Scan Recipe Card")
            .navigationBarTitleDisplayMode(.inline)
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
        GeometryReader { geometry in
            let panelHeight = bottomPanelHeight(for: geometry.size.height)
            let isReviewingCapture = analysisResult != nil || isAnalyzing
            let guideRect = CaptureGuideLayout.guideRect(
                in: geometry.size,
                bottomInset: panelHeight + 20,
                orientation: currentOrientation
            )

            ZStack(alignment: .bottom) {
                cameraSurface(guideRect: guideRect)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.24), .black.opacity(0.56)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                if !isReviewingCapture {
                    CaptureGuideFrame(
                        guideRect: guideRect,
                        orientation: currentOrientation,
                        viewportSize: geometry.size
                    )

                    VStack {
                        HStack {
                            CaptureStepOverlay(
                                step: captureStep,
                                orientation: currentOrientation,
                                frontCaptured: frontImageData != nil,
                                backCaptured: backImageData != nil,
                                isAnalyzing: isAnalyzing
                            )

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                    .padding(.top, 24)
                }

                ScannerBottomPanel(
                    analysisMessage: analysisMessage,
                    isAnalyzing: isAnalyzing,
                    analysisResult: analysisResult,
                    frontImageData: frontImageData,
                    frontOrientation: frontOrientation,
                    backImageData: backImageData,
                    backOrientation: backOrientation,
                    captureStep: captureStep,
                    currentOrientation: currentOrientation,
                    zoomFactor: $cameraZoomFactor,
                    onOrientationChange: updateCurrentOrientation,
                    onCapture: captureCurrentSide,
                    onStartOver: resetCapturedPhotos,
                    onCommit: commitDetectedRecipe,
                    onRetakeFront: retakeFrontPhoto,
                    onRetakeBack: retakeBackPhoto
                )
                .frame(maxWidth: .infinity)
                .frame(maxHeight: panelHeight)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(.black)
        }
    }

    private func bottomPanelHeight(for availableHeight: CGFloat) -> CGFloat {
        if analysisResult != nil {
            return min(max(availableHeight * 0.58, 420), 560)
        }

        if isAnalyzing {
            return min(max(availableHeight * 0.48, 340), 460)
        }

        return min(max(availableHeight * 0.28, 228), 300)
    }

    @ViewBuilder
    private func cameraSurface(guideRect: CGRect) -> some View {
        if UITestLaunchConfiguration.shouldUseMockScanner {
            MockScannerSurface(orientation: currentOrientation)
                .ignoresSafeArea(edges: .bottom)
        } else {
            RecipeCardCameraView(
                captureTrigger: captureTrigger,
                zoomFactor: CGFloat(cameraZoomFactor),
                guideRect: guideRect,
                onPhotoCapture: handleCapturedPhotoData,
                onError: handleFatalScannerError
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var scannerState: ScannerState {
        if UITestLaunchConfiguration.shouldUseMockScanner {
            return .ready
        }

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

        if UITestLaunchConfiguration.shouldUseMockScannerCapture {
            handleCapturedPhotoData(
                UITestRecipeSeeder.mockScannerPhotoData(isFront: captureStep == .front)
            )
            return
        }

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

        if UITestLaunchConfiguration.shouldUseMockScannerCapture {
            analysisResult = UITestRecipeSeeder.mockScannerAnalysisResult
            analysisMessage = "The card was analyzed. Review the detected recipe before saving it."
            isAnalyzing = false
            return
        }

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

        appModel.scanCapturedRecipe(payload, using: modelContext)
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

    private var currentOrientation: CaptureCardOrientation {
        switch captureStep {
        case .front:
            return frontOrientation
        case .back:
            return backOrientation
        }
    }

    private func updateCurrentOrientation(_ orientation: CaptureCardOrientation) {
        switch captureStep {
        case .front:
            frontOrientation = orientation
        case .back:
            backOrientation = orientation
        }
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

private enum CaptureCardOrientation: String, CaseIterable, Identifiable {
    case landscape
    case portrait

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .landscape:
            return "rectangle"
        case .portrait:
            return "rectangle.portrait"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .landscape:
            return 1.58
        case .portrait:
            return 0.72
        }
    }

    func instruction(for step: CaptureStep) -> String {
        switch (self, step) {
        case (.landscape, .front):
            return "Hold the front card wide in landscape so the title fills the guide."
        case (.portrait, .front):
            return "Hold the front card upright in portrait so the title stays inside the guide."
        case (.landscape, .back):
            return "Flip the card and keep it wide in landscape for the back photo."
        case (.portrait, .back):
            return "Flip the card and keep it upright in portrait for the back photo."
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
    let orientation: CaptureCardOrientation
    let frontCaptured: Bool
    let backCaptured: Bool
    let isAnalyzing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAnalyzing ? "Analyzing Card Photos" : step.overlayTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Text(isAnalyzing ? "Reading the captured front and back photos." : step.overlayMessage)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 12) {
                Label(frontCaptured ? "Front Ready" : "Front Pending", systemImage: frontCaptured ? "checkmark.circle.fill" : "circle")
                Label(backCaptured ? "Back Ready" : "Back Pending", systemImage: backCaptured ? "checkmark.circle.fill" : "circle")
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.black.opacity(0.62), in: .rect(cornerRadius: 20))
    }
}

private struct CaptureGuideFrame: View {
    let guideRect: CGRect
    let orientation: CaptureCardOrientation
    let viewportSize: CGSize

    var body: some View {
        Color.clear
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3, dash: [12, 8]))
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
                    .frame(width: guideRect.width, height: guideRect.height)
                    .overlay(alignment: .top) {
                        Text(orientation.title)
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.7), in: .capsule)
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                    }
                    .offset(x: guideRect.minX, y: guideRect.minY)
            }
            .frame(width: viewportSize.width, height: viewportSize.height)
            .allowsHitTesting(false)
    }
}

private enum CaptureGuideLayout {
    static func guideRect(
        in viewportSize: CGSize,
        bottomInset: CGFloat,
        orientation: CaptureCardOrientation
    ) -> CGRect {
        let availableWidth = max(viewportSize.width - 28, 220)
        let availableHeight = max(viewportSize.height - bottomInset - 104, 220)
        let fitWidth = min(availableWidth, availableHeight * orientation.aspectRatio)
        let fitHeight = fitWidth / orientation.aspectRatio
        let bottomSpacerMinimum = max(bottomInset - 18, 0)
        let extraHeight = max(viewportSize.height - fitHeight - 36 - bottomSpacerMinimum, 0)
        let topInset = 36 + (extraHeight / 2)
        let leadingInset = (viewportSize.width - fitWidth) / 2

        return CGRect(
            x: leadingInset,
            y: topInset,
            width: fitWidth,
            height: fitHeight
        )
    }
}

private struct MockScannerSurface: View {
    let orientation: CaptureCardOrientation

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.19, green: 0.2, blue: 0.22),
                    Color(red: 0.12, green: 0.13, blue: 0.15),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                Spacer()

                RoundedRectangle(cornerRadius: 28)
                    .fill(.white.opacity(0.18))
                    .overlay {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Mock Camera Preview")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("UI tests use this stable preview instead of requiring camera access.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.84))

                            Label("\(orientation.title) framing", systemImage: orientation.systemImage)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(22)
                    }
                    .frame(height: 180)
            }
            .padding(24)
        }
    }
}

private struct ScannerBottomPanel: View {
    let analysisMessage: String?
    let isAnalyzing: Bool
    let analysisResult: RecipePhotoAnalysis?
    let frontImageData: Data?
    let frontOrientation: CaptureCardOrientation
    let backImageData: Data?
    let backOrientation: CaptureCardOrientation
    let captureStep: CaptureStep
    let currentOrientation: CaptureCardOrientation
    @Binding var zoomFactor: Double
    let onOrientationChange: (CaptureCardOrientation) -> Void
    let onCapture: () -> Void
    let onStartOver: () -> Void
    let onCommit: () -> Void
    let onRetakeFront: () -> Void
    let onRetakeBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let analysisMessage {
                    Text(analysisMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isAnalyzing {
                    ProgressView("Analyzing front and back card photos...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let analysisResult {
                    if let frontImageData {
                        CapturedPhotoStrip(
                            frontImageData: frontImageData,
                            frontOrientation: frontOrientation,
                            backImageData: backImageData,
                            backOrientation: backOrientation
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    RecipePhotoAnalysisCard(analysisResult: analysisResult)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: onCommit) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Continue to Save Review", systemImage: "square.and.arrow.down.on.square")
                                .font(.headline)

                            Text("Use this scan and review the detected recipe details.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.84))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppStyle.cardPadding)
                        .padding(.vertical, 14)
                        .background(.blue.gradient, in: .rect(cornerRadius: AppStyle.cardCornerRadius))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        Button("Retake Front", systemImage: "arrow.counterclockwise", action: onRetakeFront)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                        Button("Retake Back", systemImage: "arrow.counterclockwise", action: onRetakeBack)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Text(currentOrientation.instruction(for: captureStep))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Tap the camera preview to focus before capturing the card.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button(captureStep.buttonTitle, systemImage: "camera", action: onCapture)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("scanner.captureButton")

                    if frontImageData != nil {
                        Button("Start Over", systemImage: "arrow.counterclockwise", action: onStartOver)
                            .buttonStyle(.bordered)
                    }

                    CaptureOrientationPicker(
                        selection: currentOrientation,
                        step: captureStep,
                        onSelect: onOrientationChange
                    )

                    CameraZoomControl(zoomFactor: $zoomFactor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppStyle.cardPadding)
        }
        .frame(maxWidth: .infinity)
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
    }
}

private struct CaptureOrientationPicker: View {
    let selection: CaptureCardOrientation
    let step: CaptureStep
    let onSelect: (CaptureCardOrientation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo Orientation")
                .font(.headline)

            Picker(
                "Photo Orientation",
                selection: Binding(
                    get: { selection },
                    set: { onSelect($0) }
                )
            ) {
                ForEach(CaptureCardOrientation.allCases) { orientation in
                    Label(orientation.title, systemImage: orientation.systemImage)
                        .tag(orientation)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("scanner.orientationPicker")

            Text("Choose how you want to hold the \(step == .front ? "front" : "back") of the recipe card.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CameraZoomControl: View {
    @Binding var zoomFactor: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Camera Zoom")
                    .font(.headline)

                Spacer()

                Text("\(zoomFactor.formatted(.number.precision(.fractionLength(1))))x")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $zoomFactor, in: 1...4, step: 0.25)
                .accessibilityIdentifier("scanner.zoomSlider")

            Text("Move the slider to zoom closer before taking the card photo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CapturedPhotoStrip: View {
    let frontImageData: Data
    let frontOrientation: CaptureCardOrientation
    let backImageData: Data?
    let backOrientation: CaptureCardOrientation?

    var body: some View {
        HStack(spacing: 12) {
            CapturedPhotoThumbnail(
                title: "Front • \(frontOrientation.title)",
                imageData: frontImageData
            )

            if let backImageData {
                CapturedPhotoThumbnail(
                    title: "Back • \((backOrientation ?? .landscape).title)",
                    imageData: backImageData
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(height: 96)
                    .clipShape(.rect(cornerRadius: 18))
            } else {
                ContentUnavailableView(
                    "Photo Unavailable",
                    systemImage: "photo"
                )
                .frame(height: 96)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
    }
}
