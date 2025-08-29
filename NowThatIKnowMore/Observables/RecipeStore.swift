// RecipeStore.swift
// NowThatIKnowMore
//
// Created to manage recipes in memory.

import Foundation
import Combine

@Observable class RecipeStore {
    private(set) var recipes: [Recipe] = []
    
    private var recipesFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recipes.json")
    }

    init() {
        loadRecipes()
    }

    // Adds a new recipe if it does not already exist (by UUID)
    func add(_ recipe: Recipe) {
        guard !recipes.contains(where: { $0.uuid == recipe.uuid }) else { return }
        recipes.append(recipe)
        saveRecipes()
    }
    
    // Remove a recipe by UUID
    func remove(_ recipe: Recipe) {
        recipes.removeAll { $0.uuid == recipe.uuid }
        saveRecipes()
    }
    
    // Get a recipe by UUID
    func recipe(with uuid: UUID) -> Recipe? {
        recipes.first { $0.uuid == uuid }
    }
    
    // Replace all recipes
    func set(_ newRecipes: [Recipe]) {
        recipes = newRecipes
        saveRecipes()
    }
    
    // Clear all recipes
    func clear() {
        recipes.removeAll()
        saveRecipes()
    }

    private func saveRecipes() {
        do {
            let data = try JSONEncoder().encode(recipes)
            try data.write(to: recipesFileURL, options: .atomic)
        } catch {
            print("Failed to save recipes: \(error)")
        }
    }

    private func loadRecipes() {
        let url = recipesFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode([Recipe].self, from: data)
            recipes = loaded
        } catch {
            print("Failed to load recipes: \(error)")
        }
    }
}
