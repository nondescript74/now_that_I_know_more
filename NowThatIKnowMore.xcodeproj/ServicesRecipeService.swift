//
//  RecipeService.swift
//  NowThatIKnowMore
//
//  Service layer for recipe management with SwiftData
//

import Foundation
import SwiftData

/// Service for managing recipes with SwiftData
@MainActor
class RecipeService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Recipe CRUD Operations
    
    /// Fetch all recipes
    func fetchRecipes() -> [RecipeModel] {
        let descriptor = FetchDescriptor<RecipeModel>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Fetch a recipe by UUID
    func fetchRecipe(uuid: UUID) -> RecipeModel? {
        let predicate = #Predicate<RecipeModel> { recipe in
            recipe.uuid == uuid
        }
        let descriptor = FetchDescriptor<RecipeModel>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }
    
    /// Add a new recipe
    func addRecipe(_ recipe: RecipeModel) {
        modelContext.insert(recipe)
        try? modelContext.save()
    }
    
    /// Update an existing recipe
    func updateRecipe(_ recipe: RecipeModel) {
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Delete a recipe
    func deleteRecipe(_ recipe: RecipeModel) {
        modelContext.delete(recipe)
        try? modelContext.save()
    }
    
    /// Delete multiple recipes
    func deleteRecipes(_ recipes: [RecipeModel]) {
        for recipe in recipes {
            modelContext.delete(recipe)
        }
        try? modelContext.save()
    }
    
    // MARK: - Recipe Search & Filtering
    
    /// Search recipes by title or summary
    func searchRecipes(query: String) -> [RecipeModel] {
        guard !query.isEmpty else { return fetchRecipes() }
        
        let predicate = #Predicate<RecipeModel> { recipe in
            recipe.title?.localizedStandardContains(query) ?? false ||
            recipe.summary?.localizedStandardContains(query) ?? false
        }
        
        let descriptor = FetchDescriptor<RecipeModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Filter recipes by dietary restrictions
    func filterRecipes(
        vegetarian: Bool? = nil,
        vegan: Bool? = nil,
        glutenFree: Bool? = nil,
        dairyFree: Bool? = nil
    ) -> [RecipeModel] {
        var predicates: [Predicate<RecipeModel>] = []
        
        if let vegetarian = vegetarian {
            let predicate = #Predicate<RecipeModel> { recipe in
                recipe.vegetarian == vegetarian
            }
            predicates.append(predicate)
        }
        
        if let vegan = vegan {
            let predicate = #Predicate<RecipeModel> { recipe in
                recipe.vegan == vegan
            }
            predicates.append(predicate)
        }
        
        if let glutenFree = glutenFree {
            let predicate = #Predicate<RecipeModel> { recipe in
                recipe.glutenFree == glutenFree
            }
            predicates.append(predicate)
        }
        
        if let dairyFree = dairyFree {
            let predicate = #Predicate<RecipeModel> { recipe in
                recipe.dairyFree == dairyFree
            }
            predicates.append(predicate)
        }
        
        // Combine predicates with AND logic
        let combinedPredicate = predicates.reduce(nil) { result, predicate in
            if let result = result {
                return #Predicate<RecipeModel> { recipe in
                    result.evaluate(recipe) && predicate.evaluate(recipe)
                }
            }
            return predicate
        }
        
        let descriptor = FetchDescriptor<RecipeModel>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Recipe Book Operations
    
    /// Fetch all recipe books
    func fetchRecipeBooks() -> [RecipeBookModel] {
        let descriptor = FetchDescriptor<RecipeBookModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Add a new recipe book
    func addRecipeBook(_ book: RecipeBookModel) {
        modelContext.insert(book)
        try? modelContext.save()
    }
    
    /// Update a recipe book
    func updateRecipeBook(_ book: RecipeBookModel) {
        book.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Delete a recipe book
    func deleteRecipeBook(_ book: RecipeBookModel) {
        modelContext.delete(book)
        try? modelContext.save()
    }
    
    /// Add a recipe to a book
    func addRecipe(_ recipe: RecipeModel, toBook book: RecipeBookModel) {
        if book.recipes == nil {
            book.recipes = []
        }
        
        if !(book.recipes?.contains(where: { $0.uuid == recipe.uuid }) ?? false) {
            book.recipes?.append(recipe)
            book.modifiedAt = Date()
            try? modelContext.save()
        }
    }
    
    /// Remove a recipe from a book
    func removeRecipe(_ recipe: RecipeModel, fromBook book: RecipeBookModel) {
        book.recipes?.removeAll { $0.uuid == recipe.uuid }
        book.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Create default recipe books if none exist
    func createDefaultBooksIfNeeded() {
        let existingBooks = fetchRecipeBooks()
        guard existingBooks.isEmpty else { return }
        
        let defaultBooks = RecipeBookModel.createDefaultBooks()
        for book in defaultBooks {
            modelContext.insert(book)
        }
        try? modelContext.save()
    }
    
    // MARK: - Media Operations
    
    /// Add media to a recipe
    func addMedia(_ media: RecipeMediaModel, toRecipe recipe: RecipeModel) {
        if recipe.mediaItems == nil {
            recipe.mediaItems = []
        }
        
        media.recipe = recipe
        modelContext.insert(media)
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Delete media from a recipe
    func deleteMedia(_ media: RecipeMediaModel) {
        media.deleteFile() // Remove file from disk
        modelContext.delete(media)
        try? modelContext.save()
    }
    
    /// Set featured media for a recipe
    func setFeaturedMedia(_ media: RecipeMediaModel, for recipe: RecipeModel) {
        recipe.featuredMediaID = media.uuid
        recipe.preferFeaturedMedia = true
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
    
    // MARK: - Note Operations
    
    /// Add a note to a recipe
    func addNote(_ note: RecipeNoteModel, toRecipe recipe: RecipeModel) {
        if recipe.notes == nil {
            recipe.notes = []
        }
        
        note.recipe = recipe
        modelContext.insert(note)
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Update a note
    func updateNote(_ note: RecipeNoteModel) {
        note.modifiedAt = Date()
        try? modelContext.save()
    }
    
    /// Delete a note
    func deleteNote(_ note: RecipeNoteModel) {
        modelContext.delete(note)
        try? modelContext.save()
    }
    
    /// Fetch pinned notes for a recipe
    func fetchPinnedNotes(for recipe: RecipeModel) -> [RecipeNoteModel] {
        recipe.notes?.filter { $0.isPinned }.sorted { $0.createdAt > $1.createdAt } ?? []
    }
    
    // MARK: - Migration from Legacy Recipe
    
    /// Migrate a legacy Recipe struct to RecipeModel
    func migrateFromLegacy(_ legacyRecipe: Recipe) -> RecipeModel {
        // Check if recipe already exists
        if let existing = fetchRecipe(uuid: legacyRecipe.uuid) {
            return existing
        }
        
        // Create new RecipeModel from legacy Recipe
        let recipeModel = RecipeModel(from: legacyRecipe)
        modelContext.insert(recipeModel)
        
        // Migrate media items if any
        if let mediaItems = legacyRecipe.mediaItems {
            for mediaItem in mediaItems {
                let mediaModel = RecipeMediaModel(
                    uuid: mediaItem.uuid,
                    fileURL: mediaItem.fileURL,
                    thumbnailURL: mediaItem.thumbnailURL,
                    caption: mediaItem.caption,
                    type: mediaItem.type,
                    sortOrder: mediaItem.sortOrder,
                    recipe: recipeModel
                )
                modelContext.insert(mediaModel)
            }
        }
        
        // Migrate notes if any
        if let notes = legacyRecipe.notes {
            for note in notes {
                let noteModel = RecipeNoteModel(
                    uuid: note.uuid,
                    content: note.content,
                    isPinned: note.isPinned,
                    tags: note.tagsList,
                    recipe: recipeModel
                )
                modelContext.insert(noteModel)
            }
        }
        
        try? modelContext.save()
        return recipeModel
    }
    
    /// Batch migrate all legacy recipes from RecipeStore
    func batchMigrateLegacyRecipes(_ legacyRecipes: [Recipe]) {
        for legacyRecipe in legacyRecipes {
            _ = migrateFromLegacy(legacyRecipe)
        }
    }
}
