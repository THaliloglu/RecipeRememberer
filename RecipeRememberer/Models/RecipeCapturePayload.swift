import Foundation

struct RecipeCapturePayload: Equatable, Sendable {
    let title: String
    let subtitle: String
    let sourceDescription: String
    let frontImageData: Data
    let backImageData: Data
    let frontRecognizedText: String
    let backRecognizedText: String
    let analysisSummary: String
}
