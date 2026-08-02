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
    func testConfirmFirstScannerShowsSaveViewAfterAlertDismissal() throws {
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

        let alertTitle = app.alerts.staticTexts["Mock Scanner Recipe"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()

        let saveRecipeButton = app.buttons["Save Recipe"]
        XCTAssertTrue(saveRecipeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveRecipeButton.isHittable)
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

    @MainActor
    func testLibraryRecipeRowOpensDetailsFromCellTap() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeedLibrary"]
        app.launch()

        let recipeRow = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "UI Test Recipe")
        ).firstMatch
        XCTAssertTrue(recipeRow.waitForExistence(timeout: 5))

        recipeRow.tap()

        XCTAssertTrue(app.navigationBars.staticTexts["Recipe"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLibrarySwipeDeleteRemovesRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSeedLibrary"]
        app.launch()

        let recipeRow = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "UI Test Recipe")
        ).firstMatch
        XCTAssertTrue(recipeRow.waitForExistence(timeout: 5))

        recipeRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmDeleteButton = app.sheets.buttons["Delete"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        XCTAssertFalse(recipeRow.waitForExistence(timeout: 2))
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

    @MainActor
    func testRetakeFrontDoesNotForceFullRestart() throws {
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

        let retakeFrontButton = app.buttons["Retake Front"]
        XCTAssertTrue(retakeFrontButton.waitForExistence(timeout: 5))
        retakeFrontButton.tap()

        let recaptureFrontButton = app.buttons["Capture Front Photo"]
        XCTAssertTrue(recaptureFrontButton.waitForExistence(timeout: 5))
        recaptureFrontButton.tap()

        let continueButton = app.buttons["Continue to Save Review"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testRetakeBackKeepsFrontAndReturnsToBackCapture() throws {
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

        let retakeBackButton = app.buttons["Retake Back"]
        XCTAssertTrue(retakeBackButton.waitForExistence(timeout: 5))
        retakeBackButton.tap()

        let recaptureBackButton = app.buttons["Capture Back Photo"]
        XCTAssertTrue(recaptureBackButton.waitForExistence(timeout: 5))
        recaptureBackButton.tap()

        let continueButton = app.buttons["Continue to Save Review"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testScannerFeedbackAppearsAsOneTimeAlert() throws {
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

        let alertTitle = app.alerts.staticTexts["Mock Scanner Recipe"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 5))

        let dismissButton = app.alerts.buttons["OK"]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 5))
        dismissButton.tap()

        XCTAssertFalse(alertTitle.exists)
        XCTAssertFalse(app.staticTexts["Saved to your local recipe library from two-photo scanner."].exists)
    }

    @MainActor
    func testMockScannerAutoSaveSkipsManualReview() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestMockScanner",
            "-uiTestMockScannerCapture",
            "-uiTestAutomaticSaveMode",
        ]
        app.launch()

        let openScannerButton = app.buttons["scanner.open"]
        XCTAssertTrue(openScannerButton.waitForExistence(timeout: 5))
        openScannerButton.tap()

        let captureButton = app.buttons["scanner.captureButton"]
        XCTAssertTrue(captureButton.waitForExistence(timeout: 5))
        captureButton.tap()
        captureButton.tap()

        let saveToLibraryButton = app.buttons["Save to Library"]
        XCTAssertTrue(saveToLibraryButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Auto Save is on. This scan will be saved directly to your local recipe library."].exists
        )
        XCTAssertTrue(
            app.staticTexts["The card was analyzed. Auto Save is on, so this scan can be saved to your library now."].exists
        )
        saveToLibraryButton.tap()

        XCTAssertFalse(app.buttons["Save Recipe"].waitForExistence(timeout: 2))

        let alertTitle = app.alerts.staticTexts["Mock Scanner Recipe"]
        XCTAssertTrue(alertTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.alerts.staticTexts["Saved to your local recipe library from two-photo scanner."].exists
        )

        app.alerts.buttons["OK"].tap()

        let libraryTabButton = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTabButton.waitForExistence(timeout: 5))
        libraryTabButton.tap()

        let savedRecipeButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Mock Scanner Recipe")
        ).firstMatch
        XCTAssertTrue(savedRecipeButton.waitForExistence(timeout: 5))
    }
}
