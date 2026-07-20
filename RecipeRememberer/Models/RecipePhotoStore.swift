import Foundation

struct StoredRecipePhotoAssets: Equatable, Sendable {
    let frontPhotoFilename: String?
    let backPhotoFilename: String?

    var hasSavedPhotos: Bool {
        frontPhotoFilename != nil || backPhotoFilename != nil
    }
}

enum RecipePhotoStore {
    static func persistPhotos(
        from capture: RecipeCapturePayload,
        recipeID: String
    ) throws -> StoredRecipePhotoAssets {
        let directory = try photosDirectory()

        let frontPhotoFilename = "recipe-\(recipeID)-front.jpg"
        let backPhotoFilename = "recipe-\(recipeID)-back.jpg"

        try capture.frontImageData.write(
            to: directory.appending(path: frontPhotoFilename),
            options: [.atomic]
        )
        try capture.backImageData.write(
            to: directory.appending(path: backPhotoFilename),
            options: [.atomic]
        )

        return StoredRecipePhotoAssets(
            frontPhotoFilename: frontPhotoFilename,
            backPhotoFilename: backPhotoFilename
        )
    }

    static func deletePhotos(
        frontPhotoFilename: String?,
        backPhotoFilename: String?
    ) {
        let filenames = [frontPhotoFilename, backPhotoFilename].compactMap(\.self)
        guard !filenames.isEmpty else {
            return
        }

        guard let directory = try? photosDirectory() else {
            return
        }

        for filename in filenames {
            try? FileManager.default.removeItem(at: directory.appending(path: filename))
        }
    }

    static func url(for filename: String?) -> URL? {
        guard let filename else {
            return nil
        }

        guard let directory = try? photosDirectory() else {
            return nil
        }

        return directory.appending(path: filename)
    }

    private static func photosDirectory() throws -> URL {
        let directory = URL.applicationSupportDirectory
            .appending(path: "RecipePhotos", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
}
