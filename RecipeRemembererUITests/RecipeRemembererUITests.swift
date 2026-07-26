import XCTest

final class RecipeRemembererUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSavedRecipePreviewSupportsZoom() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestSeedLibrary",
            "-uiTestAutoOpenRecipe",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))

        let previewButton = app.buttons["savedRecipe.preview.front"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(previewButton.isHittable)
        previewButton.tap()

        let zoomablePhoto = app.otherElements["savedRecipe.zoomablePhoto"]
        XCTAssertTrue(zoomablePhoto.waitForExistence(timeout: 5))

        let zoomScaleLabel = app.staticTexts["savedRecipe.zoomScale"]
        XCTAssertTrue(zoomScaleLabel.waitForExistence(timeout: 5))

        let initialZoomLabel = zoomScaleLabel.label
        zoomablePhoto.pinch(withScale: 2.0, velocity: 1.0)

        let zoomChanged = NSPredicate(format: "label != %@", initialZoomLabel)
        let expectation = XCTNSPredicateExpectation(predicate: zoomChanged, object: zoomScaleLabel)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    func testScannerShowsVisibleCaptureButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestMockScanner"]
        app.launch()

        let openScannerButton = app.buttons["scanner.open"]
        XCTAssertTrue(openScannerButton.waitForExistence(timeout: 5))
        openScannerButton.tap()

        let captureButton = app.buttons["scanner.captureButton"]
        XCTAssertTrue(captureButton.waitForExistence(timeout: 5))
        XCTAssertTrue(captureButton.isHittable)
    }

    @MainActor
    func testMockScannerSavesGuideCroppedFrontAndBackPhotos() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestMockScanner",
            "-uiTestMockScannerCapture",
        ]
        app.launch()

        let openScannerButton = app.buttons["scanner.open"]
        XCTAssertTrue(openScannerButton.waitForExistence(timeout: 5))
        openScannerButton.tap()

        let captureButton = app.buttons["scanner.captureButton"]
        XCTAssertTrue(captureButton.waitForExistence(timeout: 5))
        captureButton.tap()
        captureButton.tap()

        let continueButton = app.buttons["Continue to Save Review"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let saveRecipeButton = app.buttons["Save Recipe"]
        XCTAssertTrue(saveRecipeButton.waitForExistence(timeout: 5))
        saveRecipeButton.tap()

        let libraryTabButton = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTabButton.waitForExistence(timeout: 5))
        libraryTabButton.tap()

        let savedRecipeButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Mock Scanner Recipe")
        ).firstMatch
        XCTAssertTrue(savedRecipeButton.waitForExistence(timeout: 5))
        savedRecipeButton.tap()

        let frontPreviewButton = app.buttons["savedRecipe.preview.front"]
        XCTAssertTrue(frontPreviewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(frontPreviewButton.isHittable)
        frontPreviewButton.tap()

        let frontInsideMarker = app.staticTexts["savedRecipe.insideMarker.front"]
        XCTAssertTrue(frontInsideMarker.waitForExistence(timeout: 5))
        XCTAssertEqual(frontInsideMarker.label, "present")

        let frontOutsideMarker = app.staticTexts["savedRecipe.outsideMarker.front"]
        XCTAssertTrue(frontOutsideMarker.waitForExistence(timeout: 5))
        XCTAssertEqual(frontOutsideMarker.label, "missing")
        app.buttons["Done"].tap()

        let backPreviewButton = app.buttons["savedRecipe.preview.back"]
        XCTAssertTrue(backPreviewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(backPreviewButton.isHittable)
        backPreviewButton.tap()

        let backInsideMarker = app.staticTexts["savedRecipe.insideMarker.back"]
        XCTAssertTrue(backInsideMarker.waitForExistence(timeout: 5))
        XCTAssertEqual(backInsideMarker.label, "present")

        let backOutsideMarker = app.staticTexts["savedRecipe.outsideMarker.back"]
        XCTAssertTrue(backOutsideMarker.waitForExistence(timeout: 5))
        XCTAssertEqual(backOutsideMarker.label, "missing")
    }

    @MainActor
    func testSavedRecipeOpenPreviewButtonsStayTappable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestSeedLibrary",
            "-uiTestAutoOpenRecipe",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))

        let openFrontPreviewButton = app.buttons["savedRecipe.openPreview.front"]
        XCTAssertTrue(openFrontPreviewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(openFrontPreviewButton.isHittable)
        openFrontPreviewButton.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let openBackPreviewButton = app.buttons["savedRecipe.openPreview.back"]
        XCTAssertTrue(openBackPreviewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(openBackPreviewButton.isHittable)
        openBackPreviewButton.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSavedRecipePhotoActionButtonsStayAlignedAndReadable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestSeedLibrary",
            "-uiTestAutoOpenRecipe",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))

        assertActionRowLayout(in: app, suffix: "front")
        assertActionRowLayout(in: app, suffix: "back")
    }

    private func assertActionRowLayout(in app: XCUIApplication, suffix: String) {
        let previewButton = app.buttons["savedRecipe.openPreview.\(suffix)"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 5))
        XCTAssertTrue(previewButton.isHittable)

        let shareButton = app.buttons["savedRecipe.share.\(suffix)"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        XCTAssertTrue(shareButton.isHittable)

        XCTAssertGreaterThan(previewButton.frame.width, 100)
        XCTAssertGreaterThan(shareButton.frame.width, 100)
        XCTAssertGreaterThan(previewButton.frame.height, 40)
        XCTAssertGreaterThan(shareButton.frame.height, 40)
        XCTAssertEqual(previewButton.frame.minY, shareButton.frame.minY, accuracy: 2)
        XCTAssertEqual(previewButton.frame.height, shareButton.frame.height, accuracy: 2)
    }
}
