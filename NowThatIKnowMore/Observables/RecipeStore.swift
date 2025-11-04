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
    
    func update(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.uuid == recipe.uuid }) {
            print("🔍 [RecipeStore] Updating recipe at index \(idx)")
            print("🔍 [RecipeStore] Old title: '\(recipes[idx].title ?? "nil")'")
            print("🔍 [RecipeStore] New title: '\(recipe.title ?? "nil")'")
            print("🔍 [RecipeStore] Old image: '\(recipes[idx].image ?? "nil")'")
            print("🔍 [RecipeStore] New image: '\(recipe.image ?? "nil")'")
            print("🔍 [RecipeStore] Old mediaItems count: \(recipes[idx].mediaItems?.count ?? 0)")
            print("🔍 [RecipeStore] New mediaItems count: \(recipe.mediaItems?.count ?? 0)")
            print("🔍 [RecipeStore] Old featuredMediaID: \(recipes[idx].featuredMediaID?.uuidString ?? "nil")")
            print("🔍 [RecipeStore] New featuredMediaID: \(recipe.featuredMediaID?.uuidString ?? "nil")")
            print("🔍 [RecipeStore] Old preferFeaturedMedia: \(recipes[idx].preferFeaturedMedia ?? false)")
            print("🔍 [RecipeStore] New preferFeaturedMedia: \(recipe.preferFeaturedMedia ?? false)")
            print("🔍 [RecipeStore] Old featuredMediaURL: '\(recipes[idx].featuredMediaURL ?? "nil")'")
            print("🔍 [RecipeStore] New featuredMediaURL: '\(recipe.featuredMediaURL ?? "nil")'")
            
            // Create a new array to ensure SwiftUI detects the change
            var updatedRecipes = recipes
            updatedRecipes[idx] = recipe
            recipes = updatedRecipes
            
            saveAll()
            print("✅ [RecipeStore] Recipe updated and saved")
        } else {
            print("❌ [RecipeStore] Recipe with UUID \(recipe.uuid) not found in store")
            print("❌ [RecipeStore] Available UUIDs: \(recipes.map { $0.uuid.uuidString }.joined(separator: ", "))")
        }
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
            do {
                let loaded = try JSONDecoder().decode([Recipe].self, from: data)
                recipes = loaded
            } catch {
                // Migration path: decode as [[String: Any]]
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    // Attempt to migrate older recipe dictionaries to Recipe instances.
                    let migrated = jsonArray.compactMap { dict -> Recipe? in
                        var dict = dict
                        // Insert missing fields for migration compatibility.
                        if dict["creditsText"] == nil { dict["creditsText"] = "" }
                        // Add more field migrations here as needed.
                        return Recipe(from: dict)
                    }
                    recipes = migrated
                    saveAll()
                } else {
                    print("Failed to migrate old recipes: \(error)")
                }
            }
        } catch {
            print("Failed to load recipes: \(error)")
        }
    }
}
