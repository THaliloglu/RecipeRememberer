import Foundation
import SwiftData
import UIKit

enum UITestLaunchConfiguration {
    static let shouldSeedLibrary = ProcessInfo.processInfo.arguments.contains("-uiTestSeedLibrary")
    static let shouldOpenLibraryOnLaunch = shouldSeedLibrary
    static let shouldAutoOpenRecipe = ProcessInfo.processInfo.arguments.contains("-uiTestAutoOpenRecipe")
    static let shouldUseMockScanner = ProcessInfo.processInfo.arguments.contains("-uiTestMockScanner")
    static let shouldUseMockScannerCapture = ProcessInfo.processInfo.arguments.contains("-uiTestMockScannerCapture")
}

@MainActor
enum UITestRecipeSeeder {
    static func seedLibraryIfNeeded(in modelContainer: ModelContainer) {
        guard UITestLaunchConfiguration.shouldSeedLibrary else {
            return
        }

        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<StoredRecipe>()
        let existingRecipes = (try? context.fetch(descriptor)) ?? []

        guard existingRecipes.isEmpty else {
            return
        }

        let payload = RecipeCapturePayload(
            title: "UI Test Recipe",
            subtitle: "Front and back photo preview",
            hellofreshCode: "HF-UI-1",
            sourceDescription: "ui test seed",
            frontImageData: samplePhotoData(
                title: "Front Photo",
                subtitle: "Preview and zoom test",
                topMarker: false
            ),
            backImageData: samplePhotoData(
                title: "Back Photo",
                subtitle: "Preview and zoom test",
                topMarker: false
            ),
            frontRecognizedText: "UI Test Recipe",
            backRecognizedText: "Back Photo",
            analysisSummary: "Seeded UI test recipe."
        )

        guard let storedPhotos = try? RecipePhotoStore.persistPhotos(
            from: payload,
            recipeID: "ui-test-recipe"
        ) else {
            return
        }

        let recipe = StoredRecipe(
            title: payload.title,
            subtitle: payload.subtitle,
            hellofreshCode: payload.hellofreshCode,
            sourceDescription: payload.sourceDescription,
            frontPhotoFilename: storedPhotos.frontPhotoFilename,
            backPhotoFilename: storedPhotos.backPhotoFilename,
            frontRecognizedText: payload.frontRecognizedText,
            backRecognizedText: payload.backRecognizedText,
            analysisSummary: payload.analysisSummary
        )

        context.insert(recipe)
        try? context.save()
    }

    static var mockScannerAnalysisResult: RecipePhotoAnalysis {
        RecipePhotoAnalysis(
            title: "Mock Scanner Recipe",
            subtitle: "Saved photo parity test",
            hellofreshCode: "HF-MOCK-1",
            frontRecognizedText: "Mock Scanner Recipe",
            backRecognizedText: "Saved photo parity test",
            analysisSummary: "Mock scanner capture for UI tests."
        )
    }

    static func mockScannerPhotoData(isFront: Bool) -> Data {
        let fullFrameData = if isFront {
            mockScannerFullFramePhotoData(
                title: "Front Mock",
                subtitle: "Guide crop should match saved photo",
                accentColor: .systemPink,
                secondaryAccentColor: .systemOrange
            )
        } else {
            mockScannerFullFramePhotoData(
                title: "Back Mock",
                subtitle: "Guide crop should match saved photo",
                accentColor: .systemTeal,
                secondaryAccentColor: .systemBlue
            )
        }

        return RecipePhotoGuideCropper.crop(
            photoData: fullFrameData,
            normalizedRect: mockScannerGuideNormalizedRect
        ) ?? fullFrameData
    }

    static func hasUITestInsideMarker(in photoURL: URL) -> Bool {
        guard let image = UIImage(contentsOfFile: photoURL.path) else {
            return false
        }

        return hasUITestInsideMarker(in: image)
    }

    static func hasUITestOutsideMarker(in photoURL: URL) -> Bool {
        guard let image = UIImage(contentsOfFile: photoURL.path) else {
            return false
        }

        return hasUITestOutsideMarker(in: image)
    }

    private static func samplePhotoData(
        title: String,
        subtitle: String,
        topMarker: Bool,
        accentColor: UIColor = .systemOrange,
        secondaryAccentColor: UIColor = .systemGreen
    ) -> Data {
        let size = CGSize(width: 1200, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor.systemBackground.setFill()
            context.fill(bounds)

            let accentFrame = CGRect(x: 48, y: 48, width: size.width - 96, height: size.height - 96)
            UIBezierPath(roundedRect: accentFrame, cornerRadius: 42).addClip()

            UIColor(red: 0.90, green: 0.95, blue: 0.86, alpha: 1).setFill()
            context.fill(accentFrame)

            if topMarker {
                UIColor.systemPink.setFill()
                context.cgContext.fill(
                    CGRect(x: 320, y: 54, width: 560, height: 44)
                )
            }

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                .foregroundColor: UIColor.label,
            ]

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
            ]

            NSString(string: title).draw(
                in: CGRect(x: 96, y: 96, width: size.width - 192, height: 80),
                withAttributes: titleAttributes
            )

            NSString(string: subtitle).draw(
                in: CGRect(x: 96, y: 184, width: size.width - 192, height: 50),
                withAttributes: subtitleAttributes
            )

            let plateFrame = CGRect(x: 220, y: 260, width: 420, height: 420)
            accentColor.setFill()
            context.cgContext.fillEllipse(in: plateFrame)

            secondaryAccentColor.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 760, y: 300, width: 220, height: 220))

            UIColor.systemBlue.withAlphaComponent(0.18).setFill()
            context.cgContext.fill(CGRect(x: 760, y: 96, width: 180, height: 180))
        }

        return image.jpegData(compressionQuality: 0.92) ?? Data()
    }

    private static var mockScannerGuideNormalizedRect: CGRect {
        CGRect(x: 0.12, y: 0.30, width: 0.76, height: 0.40)
    }

    private static func mockScannerFullFramePhotoData(
        title: String,
        subtitle: String,
        accentColor: UIColor,
        secondaryAccentColor: UIColor
    ) -> Data {
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.systemPink.setFill()
            context.cgContext.fill(CGRect(x: 430, y: 90, width: 340, height: 50))

            let cardRect = CGRect(x: 140, y: 480, width: 920, height: 560)
            UIColor.white.setFill()
            context.cgContext.fill(cardRect)

            UIColor.systemGreen.setFill()
            context.cgContext.fill(CGRect(x: cardRect.minX + 260, y: cardRect.minY + 18, width: 400, height: 38))

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .bold),
                .foregroundColor: UIColor.label,
            ]

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
            ]

            NSString(string: title).draw(
                in: CGRect(x: cardRect.minX + 48, y: cardRect.minY + 76, width: 720, height: 60),
                withAttributes: titleAttributes
            )

            NSString(string: subtitle).draw(
                in: CGRect(x: cardRect.minX + 48, y: cardRect.minY + 140, width: 720, height: 40),
                withAttributes: subtitleAttributes
            )

            accentColor.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: cardRect.minX + 110, y: cardRect.minY + 190, width: 390, height: 390))

            secondaryAccentColor.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: cardRect.minX + 620, y: cardRect.minY + 220, width: 170, height: 170))
        }

        return image.jpegData(compressionQuality: 0.92) ?? Data()
    }

    private static func hasUITestInsideMarker(in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            return false
        }

        let sampleRect = CGRect(
            x: cgImage.width / 2 - 40,
            y: 40,
            width: 80,
            height: 30
        )

        return sampleRectHasColor(sampleRect, in: cgImage) { redAverage, greenAverage, blueAverage in
            greenAverage > 160 && redAverage < 140 && blueAverage < 140
        }
    }

    private static func hasUITestOutsideMarker(in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            return false
        }

        let sampleRect = CGRect(
            x: cgImage.width / 2 - 40,
            y: 80,
            width: 80,
            height: 30
        )

        return sampleRectHasColor(sampleRect, in: cgImage) { redAverage, greenAverage, blueAverage in
            redAverage > 180 && blueAverage > 120 && greenAverage < 140
        }
    }

    private static func sampleRectHasColor(
        _ sampleRect: CGRect,
        in cgImage: CGImage,
        matches: (_ redAverage: Int, _ greenAverage: Int, _ blueAverage: Int) -> Bool
    ) -> Bool {
        guard let sampledImage = cgImage.cropping(to: sampleRect) else {
            return false
        }

        let pixelData = sampledImage.dataProvider?.data
        guard let bytes = pixelData.flatMap(CFDataGetBytePtr) else {
            return false
        }

        let pixelCount = sampledImage.width * sampledImage.height
        guard pixelCount > 0 else {
            return false
        }

        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0

        for pixelIndex in 0..<pixelCount {
            let offset = pixelIndex * 4
            redTotal += Int(bytes[offset])
            greenTotal += Int(bytes[offset + 1])
            blueTotal += Int(bytes[offset + 2])
        }

        let divisor = max(pixelCount, 1)
        let redAverage = redTotal / divisor
        let greenAverage = greenTotal / divisor
        let blueAverage = blueTotal / divisor

        return matches(redAverage, greenAverage, blueAverage)
    }
}
