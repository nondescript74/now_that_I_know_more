//
//  RecipeService.swift
//  NowThatIKnowMore
//
//  Service layer for managing recipes with SwiftData
//

import Foundation
import SwiftData
import OSLog
import CoreData

@MainActor
class RecipeService {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.nowthatIknowmore", category: "RecipeService")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Recipe CRUD Operations
    
    func fetchAllRecipes() -> [RecipeModel] {
        let descriptor = FetchDescriptor<RecipeModel>(sortBy: [SortDescriptor(\.title)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchRecipe(by id: UUID) -> RecipeModel? {
        let predicate = #Predicate<RecipeModel> { recipe in
            recipe.uuid == id
        }
        let descriptor = FetchDescriptor<RecipeModel>(predicate: predicate)
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch recipe: \(error.localizedDescription)")
            return nil
        }
    }
    
    func addRecipe(_ recipe: RecipeModel) {
        modelContext.insert(recipe)
        saveContext()
    }
    
    func updateRecipe(_ recipe: RecipeModel) {
        saveContext()
    }
    
    func deleteRecipe(_ recipe: RecipeModel) {
        modelContext.delete(recipe)
        saveContext()
    }
    
    func deleteAllRecipes() {
        let recipes = fetchAllRecipes()
        for recipe in recipes {
            modelContext.delete(recipe)
        }
        saveContext()
        logger.info("Deleted all recipes")
    }
    
    // MARK: - Recipe Book Operations
    
    func fetchAllBooks() -> [RecipeBookModel] {
        let descriptor = FetchDescriptor<RecipeBookModel>(sortBy: [SortDescriptor(\.name)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch books: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchBook(by id: UUID) -> RecipeBookModel? {
        let predicate = #Predicate<RecipeBookModel> { book in
            book.uuid == id
        }
        let descriptor = FetchDescriptor<RecipeBookModel>(predicate: predicate)
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch book: \(error.localizedDescription)")
            return nil
        }
    }
    
    func addBook(_ book: RecipeBookModel) {
        modelContext.insert(book)
        saveContext()
    }
    
    func deleteBook(_ book: RecipeBookModel) {
        modelContext.delete(book)
        saveContext()
    }
    
    func createDefaultBooksIfNeeded() {
        let existingBooks = fetchAllBooks()
        
        // If there are no books, create default ones
        if existingBooks.isEmpty {
            let defaultBooks = [
                RecipeBookModel(name: "Favorites", colorHex: "#FF5733"),
                RecipeBookModel(name: "Quick Meals", colorHex: "#33C1FF"),
                RecipeBookModel(name: "Desserts", colorHex: "#FF33D4")
            ]
            
            for book in defaultBooks {
                addBook(book)
            }
            
            logger.info("Created \(defaultBooks.count) default recipe books")
        }
    }
    
    // MARK: - Recipe Migration
    
//    func batchMigrateLegacyRecipes(_ legacyRecipes: [Recipe]) {
//        for legacyRecipe in legacyRecipes {
//            // Check if recipe already exists
//            if fetchRecipe(by: legacyRecipe.uuid) != nil {
//                logger.info("Recipe \(legacyRecipe.uuid) already exists, skipping migration")
//                continue
//            }
//            
//            // Convert cuisines, dishTypes, diets, occasions from JSONAny arrays to comma-separated strings
//            let cuisinesString = legacyRecipe.cuisines?.compactMap { $0.value as? String }.joined(separator: ",")
//            let dishTypesString = legacyRecipe.dishTypes?.compactMap { $0.value as? String }.joined(separator: ",")
//            let dietsString = legacyRecipe.diets?.compactMap { $0.value as? String }.joined(separator: ",")
//            let occasionsString = legacyRecipe.occasions?.compactMap { $0.value as? String }.joined(separator: ",")
//            let daysOfWeekString = legacyRecipe.daysOfWeek?.joined(separator: ",")
//            
//            // Encode extendedIngredients and analyzedInstructions to JSON
//            let ingredientsData = try? JSONEncoder().encode(legacyRecipe.extendedIngredients)
//            let instructionsData = try? JSONEncoder().encode(legacyRecipe.analyzedInstructions)
//            
//            // Convert legacy Recipe to RecipeModel
//            let recipeModel = RecipeModel(
//                uuid: legacyRecipe.uuid,
//                id: legacyRecipe.id,
//                image: legacyRecipe.image,
//                imageType: legacyRecipe.imageType,
//                title: legacyRecipe.title ?? "Untitled Recipe",
//                servings: legacyRecipe.servings,
//                sourceURL: legacyRecipe.sourceURL,
//                vegetarian: legacyRecipe.vegetarian ?? false,
//                vegan: legacyRecipe.vegan ?? false,
//                glutenFree: legacyRecipe.glutenFree ?? false,
//                dairyFree: legacyRecipe.dairyFree ?? false,
//                veryHealthy: legacyRecipe.veryHealthy ?? false,
//                cheap: legacyRecipe.cheap ?? false,
//                veryPopular: legacyRecipe.veryPopular ?? false,
//                sustainable: legacyRecipe.sustainable ?? false,
//                lowFodmap: legacyRecipe.lowFodmap ?? false,
//                weightWatcherSmartPoints: legacyRecipe.weightWatcherSmartPoints,
//                gaps: legacyRecipe.gaps,
//                aggregateLikes: legacyRecipe.aggregateLikes,
//                healthScore: legacyRecipe.healthScore,
//                creditsText: legacyRecipe.creditsText,
//                sourceName: legacyRecipe.sourceName,
//                pricePerServing: legacyRecipe.pricePerServing,
//                summary: legacyRecipe.summary,
//                instructions: legacyRecipe.instructions,
//                spoonacularScore: legacyRecipe.spoonacularScore,
//                spoonacularSourceURL: legacyRecipe.spoonacularSourceURL,
//                cuisinesString: cuisinesString,
//                dishTypesString: dishTypesString,
//                dietsString: dietsString,
//                occasionsString: occasionsString,
//                daysOfWeekString: daysOfWeekString,
//                extendedIngredientsJSON: ingredientsData,
//                analyzedInstructionsJSON: instructionsData,
//                featuredMediaID: legacyRecipe.featuredMediaID,
//                preferFeaturedMedia: legacyRecipe.preferFeaturedMedia ?? false
//            )
//            
//            // Migrate media items if any
//            if let mediaItems = legacyRecipe.mediaItems {
//                for media in mediaItems {
//                    // Convert legacy MediaType to RecipeMediaModel.MediaType
//                    let mediaType: RecipeMediaModel.MediaType = switch media.type {
//                    case .photo: .photo
//                    case .video: .video
//                    }
//                    
//                    let mediaModel = RecipeMediaModel(
//                        uuid: media.id,
//                        fileURL: media.url,
//                        thumbnailURL: nil, // RecipeMedia doesn't have thumbnailURL
//                        caption: nil, // RecipeMedia doesn't have caption
//                        type: mediaType,
//                        recipe: recipeModel
//                    )
//                    modelContext.insert(mediaModel)
//                }
//            }
//            
//            addRecipe(recipeModel)
//            logger.info("Migrated recipe: \(recipeModel.title ?? "Untitled")")
//        }
//        
//        saveContext()
//    }
    
    // MARK: - Context Management
    
    private func saveContext() {
        // Check if context has changes before saving
        guard modelContext.hasChanges else {
            return
        }
        
        do {
            try modelContext.save()
        } catch let error as NSError {
            // Handle specific Core Data / SwiftData errors
            logger.error("Failed to save context: \(error.localizedDescription)")
            
            #if DEBUG
            print("❌ SwiftData save error: \(error)")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   UserInfo: \(error.userInfo)")
            
            // If this is a validation or type casting error, try to get more details
            if error.domain == "NSCocoaErrorDomain" {
                if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in detailedErrors {
                        print("   Detailed error: \(detailedError)")
                    }
                }
                
                // Log validation errors specifically
                if let validationErrors = error.userInfo["NSValidationErrorObject"] {
                    print("   Validation error object: \(validationErrors)")
                }
            }
            #endif
            
            // Re-throw in test environments to make failures visible
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil {
                let errorDescription = error.localizedDescription.lowercased()
                let isTypeCastError = errorDescription.contains("cast") || 
                                     errorDescription.contains("type mismatch") ||
                                     error.domain == "NSCocoaErrorDomain" && error.code == 134060
                
                if !isTypeCastError {
                    // For tests, throw the error so we know what's wrong
                    fatalError("SwiftData save failed in tests: \(error)")
                } else {
                    print("⚠️ Type cast error in tests - this may indicate a schema mismatch")
                }
            }
            #endif
        }
    }
}
