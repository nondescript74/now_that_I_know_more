//
//  RecipeMigrationService.swift
//  NowThatIKnowMore
//
//  Service to migrate from JSON-based RecipeStore to SwiftData
//

import Foundation
import SwiftData

@MainActor
class RecipeMigrationService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Check if migration is needed
    func needsMigration() -> Bool {
        // Check if old recipes.json file exists
        let recipesFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recipes.json")
        
        guard FileManager.default.fileExists(atPath: recipesFileURL.path) else {
            return false
        }
        
        // Check if we already have recipes in SwiftData
        let descriptor = FetchDescriptor<RecipeModel>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        // Need migration if JSON file exists and we have no recipes in SwiftData
        return count == 0
    }
    
    /// Perform migration from JSON to SwiftData
    func migrate() async throws {
        print("🔄 Starting migration from JSON to SwiftData...")
        
        let recipesFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recipes.json")
        
        guard FileManager.default.fileExists(atPath: recipesFileURL.path) else {
            print("⚠️ No recipes.json file found")
            return
        }
        
        let data = try Data(contentsOf: recipesFileURL)
        
        // Try to decode as array of Recipe
        let recipes: [Recipe]
        do {
            recipes = try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            // Try migration from dictionary format
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                recipes = jsonArray.compactMap { Recipe(from: $0) }
            } else {
                throw error
            }
        }
        
        print("📦 Found \(recipes.count) recipes to migrate")
        
        // Create default recipe books
        let defaultBooks = RecipeBookModel.createDefaultBooks()
        for book in defaultBooks {
            modelContext.insert(book)
        }
        
        // Migrate each recipe
        var migratedCount = 0
        for recipe in recipes {
            let recipeModel = RecipeModel(from: recipe)
            modelContext.insert(recipeModel)
            
            // Migrate media items if they exist
            if let mediaItems = recipe.mediaItems {
                for (index, media) in mediaItems.enumerated() {
                    let mediaModel = RecipeMediaModel(
                        uuid: media.id,
                        fileURL: media.url,
                        type: media.type == .photo ? .photo : .video,
                        sortOrder: index,
                        recipe: recipeModel
                    )
                    modelContext.insert(mediaModel)
                }
            }
            
            // Auto-categorize recipes into appropriate books
            try autoCategorizeRecipe(recipeModel, into: defaultBooks)
            
            migratedCount += 1
            
            // Save every 10 recipes to avoid memory issues
            if migratedCount % 10 == 0 {
                try modelContext.save()
            }
        }
        
        // Final save
        try modelContext.save()
        
        print("✅ Migration complete! Migrated \(migratedCount) recipes")
        
        // Backup old file and remove it
        let backupURL = recipesFileURL.deletingPathExtension().appendingPathExtension("json.backup")
        try? FileManager.default.moveItem(at: recipesFileURL, to: backupURL)
        print("📝 Backed up old recipes to: \(backupURL.lastPathComponent)")
    }
    
    /// Auto-categorize a recipe into appropriate books based on its properties
    private func autoCategorizeRecipe(_ recipe: RecipeModel, into books: [RecipeBookModel]) throws {
        // Add to "Quick & Easy" if ready in 30 minutes or less
        if let readyInMinutes = recipe.readyInMinutes, readyInMinutes <= 30,
           let quickBook = books.first(where: { $0.name == "Quick & Easy" }) {
            if quickBook.recipes == nil {
                quickBook.recipes = []
            }
            quickBook.recipes?.append(recipe)
        }
        
        // Add to "Healthy" if it has a high health score
        if let healthScore = recipe.healthScore, healthScore >= 70,
           let healthyBook = books.first(where: { $0.name == "Healthy" }) {
            if healthyBook.recipes == nil {
                healthyBook.recipes = []
            }
            healthyBook.recipes?.append(recipe)
        }
        
        // Add to "Desserts" if it's in the dessert category
        if recipe.dishTypes.contains(where: { $0.lowercased().contains("dessert") }),
           let dessertBook = books.first(where: { $0.name == "Desserts" }) {
            if dessertBook.recipes == nil {
                dessertBook.recipes = []
            }
            dessertBook.recipes?.append(recipe)
        }
    }
}

// MARK: - RecipeMedia compatibility
struct RecipeMedia: Codable {
    let id: UUID
    let url: String
    let type: MediaType
    
    enum MediaType: String, Codable {
        case photo
        case video
    }
}
