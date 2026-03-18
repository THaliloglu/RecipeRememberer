public enum DuplicateRecipeDetector {
    public static func isDuplicate(
        candidate: RecipeCatalogEntry,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: candidate.title)

        return savedRecipes.contains { savedRecipe in
            if let savedCode = savedRecipe.hellofreshCode, savedCode == candidate.hellofreshCode {
                return true
            }

            return savedRecipe.normalizedTitle == normalizedTitle
        }
    }

    public static func isDuplicate(
        title: String,
        hellofreshCode: String?,
        among savedRecipes: [SavedRecipeSnapshot]
    ) -> Bool {
        let normalizedTitle = RecipeNormalizer.normalizedKey(for: title)

        return savedRecipes.contains { savedRecipe in
            if let hellofreshCode, let savedCode = savedRecipe.hellofreshCode, savedCode == hellofreshCode {
                return true
            }

            return savedRecipe.normalizedTitle == normalizedTitle
        }
    }
}
