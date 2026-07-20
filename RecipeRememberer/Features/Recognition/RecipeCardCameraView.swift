import AVFoundation
import SwiftUI
import UIKit

struct RecipeCardCameraView: UIViewControllerRepresentable {
    let captureTrigger: Int
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
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var isCaptureInFlight = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
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
        photoSettings.isHighResolutionPhotoEnabled = false
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
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

        onPhotoCapture?(photoData)
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else {
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

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
            captureSession.commitConfiguration()

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            isConfigured = true
        } catch {
            captureSession.commitConfiguration()
            onError?(error.localizedDescription)
        }
    }
}
