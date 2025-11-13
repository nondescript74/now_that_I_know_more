//
//  SpoonacularIngredientUsageExamples.swift
//  NowThatIKnowMore
//
//  Examples of how to use the SpoonacularIngredient model with ExtendedIngredient
//

import Foundation
import SwiftUI

// MARK: - Usage Examples

/// Example 1: Look up ingredient details by ID
func lookupIngredientByID() {
    let manager = SpoonacularIngredientManager.shared
    
    // Get the name for a Spoonacular ingredient ID
    if let name = manager.ingredientName(forID: 10020420) {
        print("Ingredient 10020420 is: \(name)")
        // Output: "angel hair pasta"
    }
    
    // Get full ingredient details
    if let ingredient = manager.ingredient(withID: 11215) {
        print("Found: \(ingredient.name) (ID: \(ingredient.id))")
        // Output: "Found: garlic (ID: 11215)"
    }
}

/// Example 2: Search for ingredients
func searchForIngredients() {
    let manager = SpoonacularIngredientManager.shared
    
    // Search for pasta-related ingredients
    let pastaIngredients = manager.searchIngredients(query: "pasta")
    print("Found \(pastaIngredients.count) pasta ingredients")
    
    // Print first 5 results
    for ingredient in pastaIngredients.prefix(5) {
        print("- \(ingredient.name) (ID: \(ingredient.id))")
    }
}

/// Example 3: Convert SpoonacularIngredient to ExtendedIngredient
func createExtendedIngredient() {
    let manager = SpoonacularIngredientManager.shared
    
    // Find a Spoonacular ingredient
    if let garlic = manager.ingredient(withName: "garlic") {
        // Convert to ExtendedIngredient
        let extendedIngredient = ExtendedIngredient.from(
            spoonacularIngredient: garlic,
            amount: 3.0,
            unit: "cloves"
        )
        
        print("Created ExtendedIngredient:")
        print("- ID: \(extendedIngredient.id ?? 0)")
        print("- Name: \(extendedIngredient.name ?? "")")
        print("- Original: \(extendedIngredient.original ?? "")")
        // Output: "3.0 cloves garlic"
    }
}

/// Example 4: Add ingredients to a recipe
@MainActor
func addIngredientsToRecipe(recipe: RecipeModel) {
    let manager = SpoonacularIngredientManager.shared
    
    // Get some ingredients
    guard let pasta = manager.ingredient(withName: "angel hair pasta"),
          let garlic = manager.ingredient(withName: "garlic"),
          let olivoil = manager.ingredient(withName: "olive oil") else {
        return
    }
    
    // Create ExtendedIngredients
    let ingredients = [
        ExtendedIngredient.from(spoonacularIngredient: pasta, amount: 8, unit: "oz"),
        ExtendedIngredient.from(spoonacularIngredient: garlic, amount: 3, unit: "cloves"),
        ExtendedIngredient.from(spoonacularIngredient: olivoil, amount: 2, unit: "tbsp")
    ]
    
    // Add to recipe
    recipe.extendedIngredients = ingredients
}

/// Example 5: Validate ExtendedIngredient IDs
@MainActor
func validateIngredientIDs(extendedIngredients: [ExtendedIngredient]) {
    let manager = SpoonacularIngredientManager.shared
    
    for ingredient in extendedIngredients {
        guard let id = ingredient.id else {
            print("⚠️ Ingredient has no ID: \(ingredient.name ?? "unknown")")
            continue
        }
        
        if let spoonacularIngredient = manager.ingredient(withID: id) {
            print("✅ Valid: \(spoonacularIngredient.name)")
        } else {
            print("❌ Unknown ID: \(id) - \(ingredient.name ?? "unknown")")
        }
    }
}

// MARK: - SwiftUI Integration Examples

/// Example View: Add ingredient to recipe
struct AddIngredientToRecipeView: View {
    let recipe: RecipeModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPicker = false
    
    var body: some View {
        VStack {
            Text("Add ingredients to: \(recipe.title ?? "Recipe")")
                .font(.headline)
                .padding()
            
            Button("Pick Ingredients") {
                showingPicker = true
            }
            .buttonStyle(.borderedProminent)
            
            if let ingredients = recipe.extendedIngredients {
                List(ingredients, id: \.id) { ingredient in
                    VStack(alignment: .leading) {
                        Text(ingredient.name ?? "Unknown")
                            .font(.body)
                        Text(ingredient.original ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            IngredientPickerView { selectedIngredients in
                addIngredientsToRecipe(selectedIngredients)
                showingPicker = false
            }
        }
    }
    
    @MainActor
    private func addIngredientsToRecipe(_ spoonacularIngredients: [SpoonacularIngredient]) {
        // Convert to ExtendedIngredients
        let newIngredients = spoonacularIngredients.map { ingredient in
            ExtendedIngredient.from(
                spoonacularIngredient: ingredient,
                amount: 1.0,
                unit: "serving"
            )
        }
        
        // Add to existing ingredients or create new array
        if var existing = recipe.extendedIngredients {
            existing.append(contentsOf: newIngredients)
            recipe.extendedIngredients = existing
        } else {
            recipe.extendedIngredients = newIngredients
        }
    }
}

/// Example View: Ingredient search and add
struct QuickIngredientAddView: View {
    let recipe: RecipeModel
    @State private var selectedIngredient: SpoonacularIngredient?
    @State private var amount: String = "1"
    @State private var unit: String = "serving"
    
    var body: some View {
        VStack(spacing: 16) {
            IngredientSearchField { ingredient in
                selectedIngredient = ingredient
            }
            
            if let selected = selectedIngredient {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected: \(selected.name)")
                        .font(.headline)
                    
                    HStack {
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        
                        TextField("Unit", text: $unit)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }
                    
                    Button("Add to Recipe") {
                        addIngredient(selected)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    @MainActor
    private func addIngredient(_ spoonacularIngredient: SpoonacularIngredient) {
        let amountValue = Double(amount) ?? 1.0
        
        let newIngredient = ExtendedIngredient.from(
            spoonacularIngredient: spoonacularIngredient,
            amount: amountValue,
            unit: unit
        )
        
        if var existing = recipe.extendedIngredients {
            existing.append(newIngredient)
            recipe.extendedIngredients = existing
        } else {
            recipe.extendedIngredients = [newIngredient]
        }
        
        // Reset
        selectedIngredient = nil
        amount = "1"
        unit = "serving"
    }
}

// MARK: - Testing Utilities

#if DEBUG
extension SpoonacularIngredientManager {
    /// Check if ingredients are loaded (for testing)
    static func waitForLoad() async {
        while !shared.isLoaded {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
#endif
