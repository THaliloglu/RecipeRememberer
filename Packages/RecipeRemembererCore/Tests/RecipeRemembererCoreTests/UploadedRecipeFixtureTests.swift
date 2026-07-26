import CoreGraphics
import Testing
@testable import RecipeRemembererCore

struct UploadedRecipeFixture: Sendable {
    let id: String
    let title: String
    let subtitle: String
    let frontLines: [RecipeCardTextLine]
    let frontRecognizedText: String
    let backRecognizedText: String
}

private let uploadedRecipeFixtures: [UploadedRecipeFixture] = [
    UploadedRecipeFixture(
        id: "hf-de-21-gratin",
        title: "Italienisches Gratin mit Bio-Rinderhackfleisch",
        subtitle: "Kartoffeln und Porree",
        frontLines: [
            RecipeCardTextLine(
                transcript: "HELLO FRESH",
                frame: CGRect(x: 20, y: 20, width: 150, height: 24)
            ),
            RecipeCardTextLine(
                transcript: "Italienisches Gratin mit Bio-Rinderhackfleisch",
                frame: CGRect(x: 180, y: 22, width: 600, height: 34)
            ),
            RecipeCardTextLine(
                transcript: "Kartoffeln und Porree",
                frame: CGRect(x: 180, y: 64, width: 280, height: 24)
            ),
            RecipeCardTextLine(
                transcript: "Viel Gemuse High Protein Kalorien im Blick 35 - 45 Min 613 kcal",
                frame: CGRect(x: 180, y: 98, width: 600, height: 18)
            ),
            RecipeCardTextLine(
                transcript: "21",
                frame: CGRect(x: 820, y: 16, width: 44, height: 44)
            ),
        ],
        frontRecognizedText: """
        HELLO FRESH
        Italienisches Gratin mit Bio-Rinderhackfleisch
        Kartoffeln und Porree
        Viel Gemuse High Protein Kalorien im Blick 35 - 45 Min 613 kcal
        21
        """,
        backRecognizedText: """
        Los geht's
        Zutaten 2 - 4 Personen
        Ofenkartoffel
        Zwiebel
        Knoblauchzehe
        Porree
        Bio Rinderhackfleischzubereitung
        stückige Tomaten
        Gewürzmischung Hello Buon Appetito
        Rinderbrühe
        Hartkäse ital Art gerieben
        """
    ),
    UploadedRecipeFixture(
        id: "hf-de-12-spaghetti-puttanesca",
        title: "Spaghetti Puttanesca mit Kapern",
        subtitle: "Kalamata-Oliven und getrocknete Tomaten",
        frontLines: [
            RecipeCardTextLine(
                transcript: "HELLO FRESH",
                frame: CGRect(x: 20, y: 20, width: 150, height: 24)
            ),
            RecipeCardTextLine(
                transcript: "Spaghetti Puttanesca mit Kapern,",
                frame: CGRect(x: 180, y: 22, width: 520, height: 34)
            ),
            RecipeCardTextLine(
                transcript: "Kalamata-Oliven und getrocknete Tomaten",
                frame: CGRect(x: 182, y: 60, width: 420, height: 24)
            ),
            RecipeCardTextLine(
                transcript: "Viel Gemuse wenig Vorbereitung Vegetarisch 35 - 45 Min 842 kcal",
                frame: CGRect(x: 180, y: 98, width: 620, height: 18)
            ),
            RecipeCardTextLine(
                transcript: "12",
                frame: CGRect(x: 820, y: 18, width: 44, height: 44)
            ),
        ],
        frontRecognizedText: """
        HELLO FRESH
        Spaghetti Puttanesca mit Kapern
        Kalamata-Oliven und getrocknete Tomaten
        Viel Gemuse wenig Vorbereitung Vegetarisch 35 - 45 Min 842 kcal
        12
        """,
        backRecognizedText: """
        Los geht's
        Zutaten 2 - 4 Personen
        Spaghetti
        stukige Tomaten
        Kalamata-Oliven ohne Stein
        Kapern
        Getrocknete Tomaten mit Krautern
        Knoblauchzehe
        Zitrone gewachst
        milder Chili-Mix
        Basilikumpaste
        Hartkäse ital Art gerieben
        Vorbereitung
        Mit der Soße beginnen
        Pasta kochen
        Gericht vollenden
        Anrichten
        """
    ),
]

@Test(arguments: uploadedRecipeFixtures)
func uploadedRecipeFixturesParseExpectedTitleAndSubtitle(
    fixture: UploadedRecipeFixture
) {
    let result = RecipeCardTextParser.parse(from: fixture.frontLines)

    #expect(result?.title == fixture.title)
    #expect(result?.subtitle == fixture.subtitle)
}

@Test
func uploadedGermanFixtureStillMatchesKnownCatalogRecipe() {
    let germanFixture = uploadedRecipeFixtures[0]
    let detectedText = [
        germanFixture.title,
        germanFixture.subtitle,
        germanFixture.frontRecognizedText,
        germanFixture.backRecognizedText,
    ].joined(separator: "\n")

    let match = RecipeMatcher.bestMatch(
        for: detectedText,
        in: SampleRecipeCatalog.entries
    )

    #expect(match?.id == "italienisches-gratin-rinderhackfleisch")
}

@Test
func uploadedSpaghettiFixtureStaysOutsideKnownCatalog() {
    let spaghettiFixture = uploadedRecipeFixtures[1]
    let detectedText = [
        spaghettiFixture.title,
        spaghettiFixture.subtitle,
        spaghettiFixture.frontRecognizedText,
        spaghettiFixture.backRecognizedText,
    ].joined(separator: "\n")

    let match = RecipeMatcher.bestMatch(
        for: detectedText,
        in: SampleRecipeCatalog.entries
    )

    #expect(match == nil)
}

@Test
func uploadedSpaghettiFixtureMatchesSavedRecipeFromFuzzyRecognizedText() {
    let spaghettiFixture = uploadedRecipeFixtures[1]
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: spaghettiFixture.title,
            subtitle: spaghettiFixture.subtitle,
            normalizedTitle: RecipeNormalizer.normalizedKey(for: spaghettiFixture.title),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: spaghettiFixture.subtitle),
            hellofreshCode: nil,
            frontRecognizedText: spaghettiFixture.frontRecognizedText,
            backRecognizedText: spaghettiFixture.backRecognizedText
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        HELLO FRESH
        Spaghetti Puttanesca Kapern
        Kalamata Oliven und getrocknete Tomaten
        Vegetarisch 35 45 Min 842 kcal
        Kapern
        Basilikumpaste
        """,
        among: savedRecipes
    )

    #expect(match?.title == spaghettiFixture.title)
    #expect(match?.subtitle == spaghettiFixture.subtitle)
}

@Test
func unrelatedRecipeDoesNotFalseMatchUploadedSpaghettiFixture() {
    let spaghettiFixture = uploadedRecipeFixtures[1]
    let savedRecipes = [
        SavedRecipeSnapshot(
            title: spaghettiFixture.title,
            subtitle: spaghettiFixture.subtitle,
            normalizedTitle: RecipeNormalizer.normalizedKey(for: spaghettiFixture.title),
            normalizedSubtitle: RecipeNormalizer.normalizedKey(for: spaghettiFixture.subtitle),
            hellofreshCode: nil,
            frontRecognizedText: spaghettiFixture.frontRecognizedText,
            backRecognizedText: spaghettiFixture.backRecognizedText
        ),
    ]

    let match = DuplicateRecipeDetector.bestTitleMatch(
        for: """
        Cremige Zitronenspaghetti
        mit Brokkoli und Frischkäse
        Hello Fresh
        """,
        among: savedRecipes
    )

    #expect(match == nil)
}
