import CoreGraphics

enum RecipePhotoImageOrientation {
    case up
    case down
    case left
    case right
    case upMirrored
    case downMirrored
    case leftMirrored
    case rightMirrored
}

enum RecipePhotoCropGeometry {
    static func uprightNormalizedRect(
        from previewRect: CGRect,
        for imageOrientation: RecipePhotoImageOrientation
    ) -> CGRect {
        let transformedRect: CGRect = switch imageOrientation {
        case .up:
            previewRect
        case .down:
            CGRect(
                x: 1 - previewRect.maxX,
                y: 1 - previewRect.maxY,
                width: previewRect.width,
                height: previewRect.height
            )
        case .left:
            CGRect(
                x: previewRect.minY,
                y: 1 - previewRect.maxX,
                width: previewRect.height,
                height: previewRect.width
            )
        case .right:
            CGRect(
                x: 1 - previewRect.maxY,
                y: previewRect.minX,
                width: previewRect.height,
                height: previewRect.width
            )
        case .upMirrored:
            CGRect(
                x: 1 - previewRect.maxX,
                y: previewRect.minY,
                width: previewRect.width,
                height: previewRect.height
            )
        case .downMirrored:
            CGRect(
                x: previewRect.minX,
                y: 1 - previewRect.maxY,
                width: previewRect.width,
                height: previewRect.height
            )
        case .leftMirrored:
            CGRect(
                x: 1 - previewRect.maxY,
                y: 1 - previewRect.maxX,
                width: previewRect.height,
                height: previewRect.width
            )
        case .rightMirrored:
            CGRect(
                x: previewRect.minY,
                y: previewRect.minX,
                width: previewRect.height,
                height: previewRect.width
            )
        }

        return transformedRect
            .standardized
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}
