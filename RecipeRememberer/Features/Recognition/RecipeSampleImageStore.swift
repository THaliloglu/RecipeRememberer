import Foundation
import ImageIO
import UniformTypeIdentifiers

enum RecipeSampleImageStore {
    static func saveSampleImage(_ imageData: Data, id: String) throws -> String {
        let filename = "\(id).png"
        let destinationURL = samplesDirectory.appending(path: filename)

        guard
            let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
            let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            throw SampleStoreError.couldNotDecodeImage
        }

        try FileManager.default.createDirectory(
            at: samplesDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw SampleStoreError.couldNotWriteImage
        }

        return filename
    }

    static func url(for filename: String) -> URL {
        samplesDirectory.appending(path: filename)
    }

    private static var samplesDirectory: URL {
        URL.documentsDirectory.appending(path: "RecipeSamples")
    }

    enum SampleStoreError: Error {
        case couldNotDecodeImage
        case couldNotWriteImage
    }
}
