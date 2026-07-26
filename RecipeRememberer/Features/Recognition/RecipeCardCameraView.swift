import AVFoundation
import SwiftUI
import UIKit

struct RecipeCardCameraView: UIViewControllerRepresentable {
    let captureTrigger: Int
    let zoomFactor: CGFloat
    let guideRect: CGRect
    let onPhotoCapture: (Data) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> RecipeCardCameraViewController {
        let viewController = RecipeCardCameraViewController()
        viewController.onPhotoCapture = onPhotoCapture
        viewController.onError = onError
        return viewController
    }

    func updateUIViewController(
        _ uiViewController: RecipeCardCameraViewController,
        context: Context
    ) {
        uiViewController.onPhotoCapture = onPhotoCapture
        uiViewController.onError = onError
        uiViewController.setZoomFactor(zoomFactor)
        uiViewController.setGuideRect(guideRect)

        if context.coordinator.lastCaptureTrigger != captureTrigger {
            context.coordinator.lastCaptureTrigger = captureTrigger
            uiViewController.capturePhoto()
        }
    }
}

extension RecipeCardCameraView {
    final class Coordinator {
        var lastCaptureTrigger = 0
    }
}

@MainActor
final class RecipeCardCameraViewController: UIViewController, @preconcurrency AVCapturePhotoCaptureDelegate {
    var onPhotoCapture: ((Data) -> Void)?
    var onError: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let focusIndicatorView = FocusIndicatorView()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var cameraDevice: AVCaptureDevice?
    private var guideRect: CGRect = .zero
    private var isConfigured = false
    private var isCaptureInFlight = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureFocusIndicator()
        configureTapToFocus()
        configureSessionIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func capturePhoto() {
        guard isConfigured else {
            onError?("The camera session is not ready yet.")
            return
        }

        guard !isCaptureInFlight else {
            return
        }

        isCaptureInFlight = true

        let photoSettings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )
        } else {
            photoSettings = AVCapturePhotoSettings()
        }

        photoSettings.flashMode = .off
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    func setZoomFactor(_ zoomFactor: CGFloat) {
        guard let cameraDevice else {
            return
        }

        let supportedZoomFactor = min(
            max(zoomFactor, 1),
            min(cameraDevice.activeFormat.videoMaxZoomFactor, 5)
        )

        do {
            try cameraDevice.lockForConfiguration()
            cameraDevice.videoZoomFactor = supportedZoomFactor
            cameraDevice.unlockForConfiguration()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func setGuideRect(_ guideRect: CGRect) {
        self.guideRect = guideRect
    }

    @objc
    private func handlePreviewTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        guard let previewLayer else {
            return
        }

        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        focusCamera(at: devicePoint)
        showFocusIndicator(at: location)
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        isCaptureInFlight = false

        if let error {
            onError?(error.localizedDescription)
            return
        }

        guard let photoData = photo.fileDataRepresentation() else {
            onError?("The camera captured a photo, but it could not be processed.")
            return
        }

        let croppedPhotoData = cropPhotoDataToGuide(photoData) ?? photoData
        onPhotoCapture?(croppedPhotoData)
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else {
            return
        }

        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        } else {
            captureSession.sessionPreset = .photo
        }

        guard
            let cameraDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            )
        else {
            captureSession.commitConfiguration()
            onError?("The back camera is unavailable on this device.")
            return
        }

        do {
            let cameraInput = try AVCaptureDeviceInput(device: cameraDevice)

            guard captureSession.canAddInput(cameraInput) else {
                captureSession.commitConfiguration()
                onError?("The camera input could not be added.")
                return
            }

            captureSession.addInput(cameraInput)

            guard captureSession.canAddOutput(photoOutput) else {
                captureSession.commitConfiguration()
                onError?("The photo output could not be added.")
                return
            }

            captureSession.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
            photoOutput.isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureSupported
            captureSession.commitConfiguration()
            self.cameraDevice = cameraDevice
            configureDefaultCameraBehavior(for: cameraDevice)

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            view.bringSubviewToFront(focusIndicatorView)
            self.previewLayer = previewLayer
            isConfigured = true
        } catch {
            captureSession.commitConfiguration()
            onError?(error.localizedDescription)
        }
    }

    private func configureDefaultCameraBehavior(for cameraDevice: AVCaptureDevice) {
        do {
            try cameraDevice.lockForConfiguration()

            if cameraDevice.isFocusModeSupported(.continuousAutoFocus) {
                cameraDevice.focusMode = .continuousAutoFocus
            }

            if cameraDevice.isExposureModeSupported(.continuousAutoExposure) {
                cameraDevice.exposureMode = .continuousAutoExposure
            }

            cameraDevice.isSubjectAreaChangeMonitoringEnabled = true
            cameraDevice.unlockForConfiguration()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func configureTapToFocus() {
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handlePreviewTap(_:))
        )
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    private func focusCamera(at devicePoint: CGPoint) {
        guard let cameraDevice else {
            return
        }

        do {
            try cameraDevice.lockForConfiguration()

            if cameraDevice.isFocusPointOfInterestSupported {
                cameraDevice.focusPointOfInterest = devicePoint
            }

            if cameraDevice.isFocusModeSupported(.autoFocus) {
                cameraDevice.focusMode = .autoFocus
            } else if cameraDevice.isFocusModeSupported(.continuousAutoFocus) {
                cameraDevice.focusMode = .continuousAutoFocus
            }

            if cameraDevice.isExposurePointOfInterestSupported {
                cameraDevice.exposurePointOfInterest = devicePoint
            }

            if cameraDevice.isExposureModeSupported(.continuousAutoExposure) {
                cameraDevice.exposureMode = .continuousAutoExposure
            } else if cameraDevice.isExposureModeSupported(.autoExpose) {
                cameraDevice.exposureMode = .autoExpose
            }

            cameraDevice.unlockForConfiguration()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func configureFocusIndicator() {
        focusIndicatorView.isHidden = true
        focusIndicatorView.frame = CGRect(x: 0, y: 0, width: 88, height: 88)
        view.addSubview(focusIndicatorView)
    }

    private func showFocusIndicator(at location: CGPoint) {
        focusIndicatorView.center = location
        focusIndicatorView.alpha = 1
        focusIndicatorView.isHidden = false
        focusIndicatorView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

        UIView.animate(withDuration: 0.18) {
            self.focusIndicatorView.transform = .identity
        }

        UIView.animate(withDuration: 0.3, delay: 0.9) {
            self.focusIndicatorView.alpha = 0
        } completion: { _ in
            self.focusIndicatorView.isHidden = true
            self.focusIndicatorView.alpha = 1
        }
    }

    private func cropPhotoDataToGuide(_ photoData: Data) -> Data? {
        guard
            let previewLayer,
            !guideRect.isEmpty
        else {
            return nil
        }

        let normalizedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: guideRect)
        return RecipePhotoGuideCropper.crop(
            photoData: photoData,
            normalizedRect: normalizedRect
        )
    }
}

private final class FocusIndicatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemYellow.cgColor
        layer.cornerRadius = 18
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let crosshairPath = UIBezierPath()
        let inset: CGFloat = 26
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)

        crosshairPath.move(to: CGPoint(x: centerPoint.x, y: inset))
        crosshairPath.addLine(to: CGPoint(x: centerPoint.x, y: rect.height - inset))
        crosshairPath.move(to: CGPoint(x: inset, y: centerPoint.y))
        crosshairPath.addLine(to: CGPoint(x: rect.width - inset, y: centerPoint.y))

        UIColor.systemYellow.setStroke()
        crosshairPath.lineWidth = 1.5
        crosshairPath.stroke()
    }
}

enum RecipePhotoGuideCropper {
    static func crop(photoData: Data, normalizedRect: CGRect) -> Data? {
        guard
            let image = UIImage(data: photoData),
            let normalizedImage = image.normalizedUpImage(),
            let cgImage = normalizedImage.cgImage
        else {
            return nil
        }

        let boundedRect = normalizedRect.standardized.intersection(
            CGRect(x: 0, y: 0, width: 1, height: 1)
        )
        guard !boundedRect.isEmpty else {
            return nil
        }

        let uprightRect = RecipePhotoCropGeometry.uprightNormalizedRect(
            from: boundedRect,
            for: image.imageOrientation.recipePhotoImageOrientation
        )

        let cropRect = CGRect(
            x: uprightRect.minX * CGFloat(cgImage.width),
            y: uprightRect.minY * CGFloat(cgImage.height),
            width: uprightRect.width * CGFloat(cgImage.width),
            height: uprightRect.height * CGFloat(cgImage.height)
        )
        .integral
        .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard
            !cropRect.isEmpty,
            let croppedImage = cgImage.cropping(to: cropRect)
        else {
            return nil
        }

        return UIImage(cgImage: croppedImage).jpegData(compressionQuality: 0.92)
    }
}

private extension UIImage {
    func normalizedUpImage() -> UIImage? {
        if imageOrientation == .up {
            return self
        }

        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

private extension UIImage.Orientation {
    var recipePhotoImageOrientation: RecipePhotoImageOrientation {
        switch self {
        case .up:
            .up
        case .down:
            .down
        case .left:
            .left
        case .right:
            .right
        case .upMirrored:
            .upMirrored
        case .downMirrored:
            .downMirrored
        case .leftMirrored:
            .leftMirrored
        case .rightMirrored:
            .rightMirrored
        @unknown default:
            .up
        }
    }
}
