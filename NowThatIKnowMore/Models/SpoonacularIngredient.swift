//
//  SpoonacularIngredient.swift
//  NowThatIKnowMore
//
//  Model for Spoonacular ingredient reference data
//

import Foundation
import Observation

/// Represents a Spoonacular ingredient from the ingredients_list.json reference data
struct SpoonacularIngredient: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    
    /// Initialize from JSON
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Ingredient Manager
/// Manages the Spoonacular ingredients reference data
@MainActor
@Observable
final class SpoonacularIngredientManager {
    static let shared = SpoonacularIngredientManager()
    
    private(set) var ingredients: [SpoonacularIngredient] = []
    private(set) var isLoaded = false
    
    private let ingredientsByID: [Int: SpoonacularIngredient]
    private let ingredientsByName: [String: SpoonacularIngredient]
    
    private init() {
        // Load ingredients synchronously during initialization
        var loadedIngredients: [SpoonacularIngredient] = []
        var byID: [Int: SpoonacularIngredient] = [:]
        var byName: [String: SpoonacularIngredient] = [:]
        
        if let url = Bundle.main.url(forResource: "ingredients_list", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                loadedIngredients = try decoder.decode([SpoonacularIngredient].self, from: data)
                
                // Build lookup dictionaries for fast access
                byID = Dictionary(uniqueKeysWithValues: loadedIngredients.map { ($0.id, $0) })
                byName = Dictionary(uniqueKeysWithValues: loadedIngredients.map { ($0.name.lowercased(), $0) })
                
                print("✅ Loaded \(loadedIngredients.count) Spoonacular ingredients")
            } catch {
                print("❌ Failed to load ingredients: \(error)")
            }
        } else {
            print("❌ Could not find ingredients_list.json in bundle")
        }
        
        self.ingredientsByID = byID
        self.ingredientsByName = byName
        self.ingredients = loadedIngredients
        self.isLoaded = !loadedIngredients.isEmpty
    }
    
    /// Find an ingredient by its Spoonacular ID
    func ingredient(withID id: Int) -> SpoonacularIngredient? {
        return ingredientsByID[id]
    }
    
    /// Find an ingredient by name (case-insensitive)
    func ingredient(withName name: String) -> SpoonacularIngredient? {
        return ingredientsByName[name.lowercased()]
    }
    
    /// Search ingredients by partial name match
    func searchIngredients(query: String) -> [SpoonacularIngredient] {
        guard !query.isEmpty else { return ingredients }
        
        let lowercasedQuery = query.lowercased()
        return ingredients.filter { $0.name.lowercased().contains(lowercasedQuery) }
    }
    
    /// Get ingredient name from ID (convenience method)
    func ingredientName(forID id: Int) -> String? {
        return ingredientsByID[id]?.name
    }
}

// MARK: - ExtendedIngredient Extensions
extension ExtendedIngredient {
    /// Get the Spoonacular ingredient reference for this ingredient
    var spoonacularIngredient: SpoonacularIngredient? {
        guard let id = self.id else { return nil }
        return SpoonacularIngredientManager.shared.ingredient(withID: id)
    }
    
    /// Create an ExtendedIngredient from a SpoonacularIngredient with basic info
    static func from(spoonacularIngredient: SpoonacularIngredient, amount: Double = 1.0, unit: String = "serving") -> ExtendedIngredient {
        return ExtendedIngredient(
            id: spoonacularIngredient.id,
            aisle: nil,
            image: nil,
            consistency: nil,
            name: spoonacularIngredient.name,
            nameClean: spoonacularIngredient.name,
            original: "\(amount) \(unit) \(spoonacularIngredient.name)",
            originalName: spoonacularIngredient.name,
            amount: amount,
            unit: unit,
            meta: nil,
            measures: nil
        )
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension SpoonacularIngredient {
    static let preview = SpoonacularIngredient(id: 10020420, name: "angel hair pasta")
    
    static let previews: [SpoonacularIngredient] = [
        SpoonacularIngredient(id: 1002002, name: "5 spice powder"),
        SpoonacularIngredient(id: 11482, name: "acorn squash"),
        SpoonacularIngredient(id: 10020420, name: "angel hair pasta"),
        SpoonacularIngredient(id: 11215, name: "garlic"),
        SpoonacularIngredient(id: 11282, name: "onion"),
    ]
}
#endif
