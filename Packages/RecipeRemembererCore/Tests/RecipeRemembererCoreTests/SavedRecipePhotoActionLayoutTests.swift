import CoreGraphics
import Testing
@testable import RecipeRemembererCore

@Test
func savedRecipePhotoActionButtonsUseAccessibleMinimumHeight() {
    #expect(SavedRecipePhotoActionLayout.minimumActionButtonHeight >= 44)
}

@Test
func savedRecipePhotoActionButtonsReserveEnoughWidthForSingleLineLabels() {
    #expect(SavedRecipePhotoActionLayout.minimumActionButtonWidth >= 112)
}

@Test
func savedRecipePhotoActionRowThresholdMatchesTwoButtonsAndSpacing() {
    let expectedWidth = (SavedRecipePhotoActionLayout.minimumActionButtonWidth * 2)
        + SavedRecipePhotoActionLayout.actionButtonSpacing

    #expect(SavedRecipePhotoActionLayout.minimumHorizontalRowWidth == expectedWidth)
}
