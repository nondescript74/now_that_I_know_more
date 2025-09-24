import Testing
@testable import NowThatIKnowMore

@Suite("DictionaryToRecipeView basic UI and logic behavior")
struct DictionaryToRecipeViewTests {
    @Test("Parsing valid recipe JSON successfully populates preview")
    func parsesValidRecipe() async throws {
        let validJSON = """
        { "title": "Test Recipe", "image": "https://example.com/image.jpg", "sourceUrl": "https://example.com/recipe" }
        """
        let env = RecipeStore()
        let viewModel = DictionaryToRecipeViewModel(recipeStore: env)
        viewModel.dictionaryInput = validJSON
        viewModel.parseDictionaryInput()
        #expect(viewModel.parsedRecipe?.title == "Test Recipe")
        #expect(viewModel.parsedRecipe?.image == "https://example.com/image.jpg")
        #expect(viewModel.parsedRecipe?.sourceURL == "https://example.com/recipe")
    }

    @Test("Shows error for invalid JSON input")
    func showsParseErrorForInvalidJSON() async throws {
        let invalidJSON = "{ this is invalid json }"
        let env = RecipeStore()
        let viewModel = DictionaryToRecipeViewModel(recipeStore: env)
        viewModel.dictionaryInput = invalidJSON
        viewModel.parseDictionaryInput()
        #expect(viewModel.parseError != nil)
    }

    @Test("Detects duplicate recipe by title, sourceUrl, and image")
    func detectsDuplicateRecipe() async throws {
        let validJSON = """
        { "title": "Dup Recipe", "image": "dupe.jpg", "sourceUrl": "dupe" }
        """
        let env = RecipeStore()
        let existing = Recipe(from: ["title": "Dup Recipe", "image": "dupe.jpg", "sourceUrl": "dupe"])!
        env.add(existing)
        let viewModel = DictionaryToRecipeViewModel(recipeStore: env)
        viewModel.dictionaryInput = validJSON
        viewModel.parseDictionaryInput()
        #expect(viewModel.duplicateRecipe)
    }

    @Test("Add button is disabled for duplicate")
    func addButtonDisabledForDuplicate() async throws {
        let validJSON = """
        { "title": "Dup Recipe", "image": "dupe.jpg", "sourceUrl": "dupe" }
        """
        let env = RecipeStore()
        let existing = Recipe(from: ["title": "Dup Recipe", "image": "dupe.jpg", "sourceUrl": "dupe"])!
        env.add(existing)
        let viewModel = DictionaryToRecipeViewModel(recipeStore: env)
        viewModel.dictionaryInput = validJSON
        viewModel.parseDictionaryInput()
        #expect(viewModel.duplicateRecipe)
    }
}
