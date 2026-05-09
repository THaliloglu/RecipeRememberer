import CoreGraphics
import Foundation

public struct RecipeCardTextLine: Equatable, Sendable {
    public let transcript: String
    public let frame: CGRect

    public init(
        transcript: String,
        frame: CGRect
    ) {
        self.transcript = transcript
        self.frame = frame
    }
}

public struct RecipeCardScanResult: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let hellofreshCode: String?

    public init(
        title: String,
        subtitle: String,
        hellofreshCode: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hellofreshCode = hellofreshCode
    }
}

public enum RecipeCardTextParser {
    public static func parse(
        from lines: [RecipeCardTextLine],
        preferredTitle: String? = nil
    ) -> RecipeCardScanResult? {
        let preparedLines = lines
            .map(PreparedLine.init)
            .filter { !$0.transcript.isEmpty }
            .sorted(by: sortPreparedLines)

        guard let anchorIndex = anchorIndex(in: preparedLines, preferredTitle: preferredTitle) else {
            return nil
        }

        let titleRange = expandedTitleRange(
            around: anchorIndex,
            in: preparedLines
        )
        let title = preparedLines[titleRange]
            .map(\.transcript)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return nil
        }

        let subtitle = subtitleCandidate(
            after: titleRange.upperBound,
            in: preparedLines,
            titleFrame: preparedLines[titleRange.lowerBound].frame
        ) ?? ""

        let hellofreshCode = preparedLines.lazy
            .compactMap(\.recognizedCode)
            .first

        return RecipeCardScanResult(
            title: title,
            subtitle: subtitle,
            hellofreshCode: hellofreshCode
        )
    }

    private static func sortPreparedLines(
        _ left: PreparedLine,
        _ right: PreparedLine
    ) -> Bool {
        if left.frame.minY == right.frame.minY {
            return left.frame.minX < right.frame.minX
        }

        return left.frame.minY < right.frame.minY
    }

    private static func anchorIndex(
        in lines: [PreparedLine],
        preferredTitle: String?
    ) -> Int? {
        if let preferredTitle {
            let normalizedPreference = RecipeNormalizer.normalizedKey(for: preferredTitle)

            if let exactMatch = lines.firstIndex(where: {
                RecipeNormalizer.normalizedKey(for: $0.transcript) == normalizedPreference
            }) {
                return exactMatch
            }

            if let containingMatch = lines.firstIndex(where: {
                RecipeNormalizer.normalizedKey(for: $0.transcript).contains(normalizedPreference)
                    || normalizedPreference.contains(RecipeNormalizer.normalizedKey(for: $0.transcript))
            }) {
                return containingMatch
            }
        }

        let meaningfulLineIndexes = lines.indices.filter { !lines[$0].isMetadata }
        guard !meaningfulLineIndexes.isEmpty else {
            return nil
        }

        return meaningfulLineIndexes.max { left, right in
            score(for: lines[left]) < score(for: lines[right])
        }
    }

    private static func expandedTitleRange(
        around anchorIndex: Int,
        in lines: [PreparedLine]
    ) -> ClosedRange<Int> {
        var lowerBound = anchorIndex
        var upperBound = anchorIndex

        while lowerBound > 0,
              shouldJoinTitleLine(
                previous: lines[lowerBound - 1],
                next: lines[lowerBound]
              ) {
            lowerBound -= 1
        }

        while upperBound < lines.index(before: lines.endIndex),
              shouldJoinTitleLine(
                previous: lines[upperBound],
                next: lines[upperBound + 1]
              ) {
            upperBound += 1
        }

        return lowerBound ... upperBound
    }

    private static func shouldJoinTitleLine(
        previous: PreparedLine,
        next: PreparedLine
    ) -> Bool {
        guard !previous.isMetadata, !next.isMetadata else {
            return false
        }

        let maximumHeight = max(previous.frame.height, next.frame.height)
        let minimumHeight = min(previous.frame.height, next.frame.height)
        let heightRatio = maximumHeight / max(minimumHeight, 1)
        let verticalGap = next.frame.minY - previous.frame.maxY
        let leadingDelta = abs(previous.frame.minX - next.frame.minX)

        return verticalGap <= maximumHeight * 1.1
            && heightRatio <= 1.22
            && leadingDelta <= maximumHeight * 2.2
    }

    private static func subtitleCandidate(
        after upperTitleIndex: Int,
        in lines: [PreparedLine],
        titleFrame: CGRect
    ) -> String? {
        let subtitleIndexes = lines.indices.filter { $0 > upperTitleIndex }

        for index in subtitleIndexes {
            let line = lines[index]
            guard !line.isMetadata else {
                continue
            }

            let verticalGap = line.frame.minY - titleFrame.maxY
            guard verticalGap <= max(titleFrame.height * 2.4, 42) else {
                break
            }

            return line.transcript
        }

        return nil
    }

    private static func score(for line: PreparedLine) -> Int {
        let wordCount = line.transcript.split(separator: " ").count
        let normalizedText = RecipeNormalizer.normalizedKey(for: line.transcript)
        let topBias = Int(max(0, 200 - line.frame.minY))
        let widthBonus = Int(line.frame.width / 12)
        let heightBonus = Int(line.frame.height * 10)
        let titleWordBonus = titleWords.reduce(into: 0) { partialResult, word in
            if normalizedText.localizedStandardContains(word) {
                partialResult += 24
            }
        }
        let mixedCaseBonus = line.transcript == line.transcript.lowercased() ? 0 : 10

        return wordCount * 90
            + widthBonus
            + heightBonus
            + titleWordBonus
            + mixedCaseBonus
            + topBias
            - (line.isMetadata ? 300 : 0)
            - (line.recognizedCode == nil ? 0 : 80)
    }

    private static var titleWords: [String] {
        [
            "gratin",
            "rigatoni",
            "pasta",
            "bowl",
            "salad",
            "chicken",
            "beef",
            "porree",
            "kartoffeln",
            "mushroom",
            "veggie",
        ]
    }
}

private struct PreparedLine {
    let transcript: String
    let frame: CGRect
    let normalizedText: String
    let recognizedCode: String?
    let isMetadata: Bool

    init(line: RecipeCardTextLine) {
        let transcript = line.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = RecipeNormalizer.normalizedKey(for: transcript)

        self.transcript = transcript
        self.frame = line.frame
        self.normalizedText = normalizedText
        self.recognizedCode = PreparedLine.extractCode(from: transcript)
        self.isMetadata = PreparedLine.isMetadataLine(
            transcript: transcript,
            normalizedText: normalizedText,
            recognizedCode: recognizedCode
        )
    }

    private static func extractCode(from transcript: String) -> String? {
        let uppercaseTranscript = transcript.uppercased()
        let pattern = #/\bHF(?:[- ]?[A-Z]{2,3})?[- ]?\d{1,4}\b/#

        guard let match = uppercaseTranscript.firstMatch(of: pattern) else {
            return nil
        }

        return String(match.output).replacing(" ", with: "-")
    }

    private static func isMetadataLine(
        transcript: String,
        normalizedText: String,
        recognizedCode: String?
    ) -> Bool {
        if recognizedCode != nil {
            return true
        }

        if normalizedText == "hello fresh" || normalizedText == "hellofresh" {
            return true
        }

        if transcript.contains(where: \.isNumber),
           metadataTerms.contains(where: normalizedText.localizedStandardContains) {
            return true
        }

        return metadataTerms.contains(where: normalizedText.localizedStandardContains)
    }

    private static var metadataTerms: [String] {
        [
            "hello fresh",
            "hellofresh",
            "kcal",
            "min",
            "protein",
            "kalorien",
            "geschmack",
            "naturlicher",
            "ohne",
            "viel gemuse",
            "high protein",
            "gewurzmischung",
        ]
    }
}
