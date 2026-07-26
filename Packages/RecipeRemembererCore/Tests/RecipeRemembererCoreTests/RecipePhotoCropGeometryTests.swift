import CoreGraphics
import Testing
@testable import RecipeRemembererCore

@Test
func cropGeometryPreservesUpOrientationRect() {
    let rect = CGRect(x: 0.12, y: 0.28, width: 0.64, height: 0.31)

    let result = RecipePhotoCropGeometry.uprightNormalizedRect(
        from: rect,
        for: .up
    )

    #expect(result.isNearlyEqual(to: rect))
}

@Test
func cropGeometryRotatesRightOrientationIntoUprightSpace() {
    let rect = CGRect(x: 0.10, y: 0.25, width: 0.70, height: 0.35)

    let result = RecipePhotoCropGeometry.uprightNormalizedRect(
        from: rect,
        for: .right
    )

    #expect(result.isNearlyEqual(to: CGRect(x: 0.40, y: 0.10, width: 0.35, height: 0.70)))
}

@Test
func cropGeometryRotatesLeftOrientationIntoUprightSpace() {
    let rect = CGRect(x: 0.10, y: 0.25, width: 0.70, height: 0.35)

    let result = RecipePhotoCropGeometry.uprightNormalizedRect(
        from: rect,
        for: .left
    )

    #expect(result.isNearlyEqual(to: CGRect(x: 0.25, y: 0.20, width: 0.35, height: 0.70)))
}

@Test
func cropGeometryClampsOverflowingRectIntoUnitBounds() {
    let rect = CGRect(x: -0.08, y: 0.82, width: 0.42, height: 0.30)

    let result = RecipePhotoCropGeometry.uprightNormalizedRect(
        from: rect,
        for: .up
    )

    #expect(result.isNearlyEqual(to: CGRect(x: 0, y: 0.82, width: 0.34, height: 0.18)))
}

private extension CGRect {
    func isNearlyEqual(to other: CGRect, tolerance: CGFloat = 0.0001) -> Bool {
        abs(minX - other.minX) < tolerance
            && abs(minY - other.minY) < tolerance
            && abs(width - other.width) < tolerance
            && abs(height - other.height) < tolerance
    }
}
