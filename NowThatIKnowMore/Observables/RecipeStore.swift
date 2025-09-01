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
        loadAll()
    }
    
    func add(_ recipe: Recipe) {
        guard !recipes.contains(where: { $0.uuid == recipe.uuid }) else { return }
        recipes.append(recipe)
        saveAll()
    }
    
    func remove(_ recipe: Recipe) {
        recipes.removeAll { $0.uuid == recipe.uuid }
        saveAll()
    }
    
    func recipe(with uuid: UUID) -> Recipe? {
        recipes.first { $0.uuid == uuid }
    }
    
    func set(_ newRecipes: [Recipe]) {
        recipes = newRecipes
        saveAll()
    }
    
    func clear() {
        recipes.removeAll()
        saveAll()
    }

    
    private func saveAll() {
        do {
            let data = try JSONEncoder().encode(recipes)
            try data.write(to: recipesFileURL, options: .atomic)
        } catch {
            print("Failed to save recipes: \(error)")
        }
    }
    
    private func loadAll() {
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
