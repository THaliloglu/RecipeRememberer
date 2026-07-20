import Foundation
import Vision

struct RecipePhotoAnalysis: Equatable, Sendable {
    let title: String
    let subtitle: String
    let hellofreshCode: String?
    let frontRecognizedText: String
    let backRecognizedText: String
    let analysisSummary: String
}

enum RecipePhotoAnalyzer {
    static func analyze(
        frontImageData: Data,
        backImageData: Data
    ) async throws -> RecipePhotoAnalysis {
        async let frontDocument = recognizeText(in: frontImageData)
        async let backDocument = recognizeText(in: backImageData)

        let (front, back) = try await (frontDocument, backDocument)
        let prominentFrontTitle = prominentFrontTitle(from: front.lines)
        let parsedFrontRecipe = RecipeCardTextParser.parse(
            from: front.lines,
            preferredTitle: prominentFrontTitle
        )

        let title = parsedFrontRecipe?.title
            ?? prominentFrontTitle
            ?? fallbackTitle(from: front.lines)
            ?? fallbackTitle(from: back.lines)
            ?? ""
        let subtitle = parsedFrontRecipe?.subtitle
            ?? fallbackSubtitle(from: front.lines, title: title)
            ?? ""
        let hellofreshCode = parsedFrontRecipe?.hellofreshCode
            ?? firstMatch(
                in: "\(front.fullText)\n\(back.fullText)",
                for: #/\bHF(?:[- ]?[A-Z]{2,3})?[- ]?\d{1,4}\b/#
            )?
            .replacing(" ", with: "-")

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw RecipePhotoAnalyzerError.noRecipeTextDetected
        }

        return RecipePhotoAnalysis(
            title: normalizedTitle,
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            hellofreshCode: hellofreshCode,
            frontRecognizedText: front.fullText,
            backRecognizedText: back.fullText,
            analysisSummary: analysisSummary(
                title: normalizedTitle,
                subtitle: subtitle,
                hellofreshCode: hellofreshCode,
                frontText: front.fullText,
                backText: back.fullText,
                frontLineCount: front.lines.count,
                backLineCount: back.lines.count
            )
        )
    }

    private static func prominentFrontTitle(from lines: [RecipeCardTextLine]) -> String? {
        let candidates = lines
            .map { line in
                (
                    line: line,
                    text: line.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { candidate in
                isLikelyFrontTitleLine(candidate.text)
            }

        guard !candidates.isEmpty else {
            return nil
        }

        return candidates.max { left, right in
            titleCandidateScore(for: left.line, text: left.text)
                < titleCandidateScore(for: right.line, text: right.text)
        }?.text
    }

    private static func recognizeText(
        in imageData: Data
    ) throws -> RecognizedRecipeDocument {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.minimumTextHeight = 0.02

        let imageHandler = VNImageRequestHandler(data: imageData)
        try imageHandler.perform([request])

        let observations = request.results ?? []
        let lines = observations.compactMap { observation -> RecipeCardTextLine? in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }

            let transformedFrame = CGRect(
                x: observation.boundingBox.minX * 1_000,
                y: (1 - observation.boundingBox.maxY) * 1_000,
                width: observation.boundingBox.width * 1_000,
                height: observation.boundingBox.height * 1_000
            )

            return RecipeCardTextLine(
                transcript: candidate.string,
                frame: transformedFrame
            )
        }

        let orderedText = lines
            .sorted { lhs, rhs in
                if lhs.frame.minY == rhs.frame.minY {
                    return lhs.frame.minX < rhs.frame.minX
                }

                return lhs.frame.minY < rhs.frame.minY
            }
            .map(\.transcript)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return RecognizedRecipeDocument(
            lines: lines,
            fullText: orderedText
        )
    }

    private static func fallbackTitle(from lines: [RecipeCardTextLine]) -> String? {
        let candidates = lines
            .map { line in
                (
                    line: line,
                    text: line.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { candidate in
                isLikelyFrontTitleLine(candidate.text)
            }

        return candidates.max { left, right in
            titleCandidateScore(for: left.line, text: left.text)
                < titleCandidateScore(for: right.line, text: right.text)
        }?.text
    }

    private static func fallbackSubtitle(
        from lines: [RecipeCardTextLine],
        title: String
    ) -> String? {
        let orderedLines = lines
            .sorted { lhs, rhs in
                if lhs.frame.minY == rhs.frame.minY {
                    return lhs.frame.minX < rhs.frame.minX
                }

                return lhs.frame.minY < rhs.frame.minY
            }
            .map(\.transcript)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let titleIndex = orderedLines.firstIndex(of: title) else {
            return orderedLines.dropFirst().first
        }

        guard orderedLines.indices.contains(titleIndex + 1) else {
            return nil
        }

        return orderedLines[titleIndex + 1]
    }

    private static func analysisSummary(
        title: String,
        subtitle: String,
        hellofreshCode: String?,
        frontText: String,
        backText: String,
        frontLineCount: Int,
        backLineCount: Int
    ) -> String {
        var summaryParts = ["Detected “\(title)” from the front card photo."]

        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSubtitle.isEmpty {
            summaryParts.append("Subtitle: \(trimmedSubtitle).")
        }

        if let hellofreshCode {
            summaryParts.append("HelloFresh code: \(hellofreshCode).")
        }

        if let cookingTime = firstMatch(
            in: frontText,
            for: #/\b\d{1,2}\s*[-–]\s*\d{1,2}\s*(?:Min|Minutes?)\b/#
        ) {
            summaryParts.append("Estimated cooking time: \(cookingTime).")
        }

        if let calories = firstMatch(
            in: frontText,
            for: #/\b\d{2,4}\s*kcal\b/#
        ) {
            summaryParts.append("Calories noted: \(calories).")
        }

        summaryParts.append(
            "Captured \(frontLineCount) front-card text lines and \(backLineCount) back-card text lines for later reference."
        )

        if !backText.isEmpty {
            summaryParts.append("Back card OCR is stored with the recipe for later comparison and review.")
        }

        return summaryParts.joined(separator: " ")
    }

    private static func firstMatch(
        in text: String,
        for pattern: Regex<Substring>
    ) -> String? {
        guard let match = text.firstMatch(of: pattern) else {
            return nil
        }

        return String(match.output)
    }

    private static func isLikelyFrontTitleLine(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = RecipeNormalizer.normalizedKey(for: trimmedText)
        let wordCount = trimmedText.split(separator: " ").count

        guard trimmedText.count >= 6, wordCount >= 2 else {
            return false
        }

        let blockedTerms = [
            "hellofresh",
            "kcal",
            "min",
            "minutes",
            "portion",
            "portionen",
            "zutaten",
            "zubereitung",
            "ofen",
            "protein",
        ]

        return !blockedTerms.contains { normalizedText.localizedStandardContains($0) }
    }

    private static func titleCandidateScore(
        for line: RecipeCardTextLine,
        text: String
    ) -> Double {
        let normalizedText = RecipeNormalizer.normalizedKey(for: text)
        let wordCount = text.split(separator: " ").count
        let topBias = max(0, 420 - line.frame.minY)
        let leftBias = max(0, 240 - line.frame.minX)
        let topBandBonus = line.frame.minY < 220 ? 180.0 : 0.0
        let titleWordBonus = [
            "mit",
            "and",
            "with",
            "gratin",
            "pasta",
            "bowl",
            "salat",
            "salad",
            "kartoffeln",
            "porree",
        ].reduce(into: 0.0) { partialResult, word in
            if normalizedText.localizedStandardContains(word) {
                partialResult += 24
            }
        }

        return line.frame.height * 1_200
            + line.frame.width * 0.35
            + Double(wordCount) * 110
            + topBias
            + leftBias
            + topBandBonus
            + titleWordBonus
    }
}

private struct RecognizedRecipeDocument: Sendable {
    let lines: [RecipeCardTextLine]
    let fullText: String
}

enum RecipePhotoAnalyzerError: LocalizedError {
    case noRecipeTextDetected

    var errorDescription: String? {
        switch self {
        case .noRecipeTextDetected:
            return "No recipe title could be recognized from the card photos."
        }
    }
}
