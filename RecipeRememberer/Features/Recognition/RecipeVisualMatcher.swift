import Foundation
import ImageIO
import Vision

struct RecipeVisualMatch {
    let entry: RecipeCatalogEntry
    let distance: Float
}

struct StoredRecipeVisualMatch {
    let recipe: StoredRecipe
    let distance: Float
}

enum RecipeVisualMatcher {
    static let acceptedDistanceThreshold: Float = 18

    static func bestMatch(
        for imageData: Data,
        in catalog: [RecipeCatalogEntry]
    ) -> RecipeVisualMatch? {
        guard let queryFeaturePrint = featurePrint(for: imageData) else {
            return nil
        }

        var bestMatch: RecipeVisualMatch?

        for entry in catalog {
            guard
                let referenceImageURL = Bundle.main.url(
                    forResource: entry.referenceImageName,
                    withExtension: "png",
                    subdirectory: "ReferenceCards"
                ),
                let referenceFeaturePrint = featurePrint(for: referenceImageURL)
            else {
                continue
            }

            do {
                var distance = Float.zero
                try referenceFeaturePrint.computeDistance(&distance, to: queryFeaturePrint)

                if let bestMatch, bestMatch.distance <= distance {
                    continue
                }

                bestMatch = RecipeVisualMatch(entry: entry, distance: distance)
            } catch {
                continue
            }
        }

        return bestMatch
    }

    static func bestMatch(
        for imageData: Data,
        among storedRecipes: [StoredRecipe]
    ) -> StoredRecipeVisualMatch? {
        guard let queryFeaturePrint = featurePrint(for: imageData) else {
            return nil
        }

        var bestMatch: StoredRecipeVisualMatch?

        for recipe in storedRecipes {
            guard
                let sampleImageFilename = recipe.sampleImageFilename,
                let referenceFeaturePrint = featurePrint(
                    for: RecipeSampleImageStore.url(for: sampleImageFilename)
                )
            else {
                continue
            }

            do {
                var distance = Float.zero
                try referenceFeaturePrint.computeDistance(&distance, to: queryFeaturePrint)

                if let bestMatch, bestMatch.distance <= distance {
                    continue
                }

                bestMatch = StoredRecipeVisualMatch(recipe: recipe, distance: distance)
            } catch {
                continue
            }
        }

        return bestMatch
    }

    static func isAccepted(_ match: RecipeVisualMatch) -> Bool {
        match.distance <= acceptedDistanceThreshold
    }

    static func isAccepted(_ match: StoredRecipeVisualMatch) -> Bool {
        match.distance <= acceptedDistanceThreshold
    }

    private static func featurePrint(for imageData: Data) -> VNFeaturePrintObservation? {
        guard
            let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }

        let request = VNGenerateImageFeaturePrintRequest()
        let requestHandler = VNImageRequestHandler(cgImage: image)

        do {
            try requestHandler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }

    private static func featurePrint(for imageURL: URL) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let requestHandler = VNImageRequestHandler(url: imageURL)

        do {
            try requestHandler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
}
