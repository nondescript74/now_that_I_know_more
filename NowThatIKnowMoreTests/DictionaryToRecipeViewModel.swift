// Ensure Welcome.swift (containing 'Recipe') and RecipeStore.swift (containing 'RecipeStore') are part of the build target for both the main app and the test target.
import Foundation
import struct Foundation.UUID
import OSLog
import Observation
import Combine
import NowThatIKnowMore

// Ensure Recipe+Decoding.swift (containing decodeFromJSONOrPatchedDict) is part of the build target.

@Observable
final class DictionaryToRecipeViewModel {
    var dictionaryInput: String = ""
    var parseError: String? = nil
    var parsedRecipe: Recipe? = nil
    var duplicateRecipe: Bool = false
    let logger = Logger(subsystem: "com.headydiscy.NowThatIKnowMore", category: "DictionaryToRecipeViewModel")
    let recipeStore: RecipeStore
    
    init(recipeStore: RecipeStore) {
        self.recipeStore = recipeStore
    }

    func parseDictionaryInput() {
        parseError = nil
        parsedRecipe = nil
        duplicateRecipe = false
        let text = dictionaryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = text.data(using: .utf8) else {
            parseError = "Input is not valid UTF-8."
            return
        }
        do {
            if let recipe = Recipe.decodeFromJSONOrPatchedDict(data) {
                checkDuplicate(recipe)
                return
            }
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = json as? [String: Any], let recipe = Recipe.decodeFromPatchedDict(dict) {
                checkDuplicate(recipe)
                return
            }
            parseError = "Could not decode input as a Recipe."
        } catch {
            parseError = "Parse error: \(error.localizedDescription)"
        }
    }

    private func checkDuplicate(_ recipe: Recipe) {
        if recipeStore.recipes.contains(where: { stored in
            stored.title == recipe.title &&
            stored.sourceURL == recipe.sourceURL &&
            stored.image == recipe.image
        }) {
            duplicateRecipe = true
            parsedRecipe = nil
        } else {
            duplicateRecipe = false
            parsedRecipe = recipe
        }
    }
}
