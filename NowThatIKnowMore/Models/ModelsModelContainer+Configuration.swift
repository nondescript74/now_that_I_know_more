//
//  ModelContainer+Configuration.swift
//  NowThatIKnowMore
//
//  SwiftData model container configuration
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Create the shared model container for the app
    static func create() throws -> ModelContainer {
        let schema = Schema([
            RecipeModel.self,
            RecipeMediaModel.self,
            RecipeNoteModel.self,
            RecipeBookModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    /// Create an in-memory container for previews and testing
    static func preview() throws -> ModelContainer {
        let schema = Schema([
            RecipeModel.self,
            RecipeMediaModel.self,
            RecipeNoteModel.self,
            RecipeBookModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        // Add sample data for previews
        let context = container.mainContext
        
        // Create sample recipe book
        let favoritesBook = RecipeBookModel(
            name: "Favorites",
            bookDescription: "My favorite recipes",
            colorHex: "#FF6B6B",
            iconName: "heart.fill",
            sortOrder: 0
        )
        context.insert(favoritesBook)
        
        // Create sample recipe
        let sampleRecipe = RecipeModel(
            title: "Sample Recipe",
            servings: 4,
            vegetarian: true,
            summary: "This is a sample recipe for preview purposes.",
            instructions: "1. Prepare ingredients\n2. Cook\n3. Enjoy!"
        )
        context.insert(sampleRecipe)
        
        // Add recipe to book
        favoritesBook.recipes = [sampleRecipe]
        
        // Create sample note
        let sampleNote = RecipeNoteModel(
            content: "This recipe tastes great with a side of garlic bread!",
            isPinned: true,
            tags: ["tip", "pairing"],
            recipe: sampleRecipe
        )
        context.insert(sampleNote)
        
        try? context.save()
        
        return container
    }
}
