//
//  NowThatIKnowMoreTests.swift
//  NowThatIKnowMoreTests
//
//  Created by Zahirudeen Premji on 9/24/25.
//

import Testing
import SwiftData
import Foundation
@testable import NowThatIKnowMore

@Suite("NowThatIKnowMore Core Tests")
struct NowThatIKnowMoreTests {
    
    // MARK: - Test Helpers
    
    /// Creates an in-memory ModelContainer with all required models for testing
    @MainActor
    static func createTestContainer() throws -> ModelContainer {
        // Create schema explicitly to ensure proper registration
        let schema = Schema([
            RecipeModel.self,
            RecipeMediaModel.self,
            RecipeNoteModel.self,
            RecipeBookModel.self
        ])
        
        // Use a unique identifier for each test container to avoid conflicts
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: config
        )
        
        return container
    }
    
    // MARK: - RecipeModel Tests
    
    @Suite("RecipeModel Basic Operations")
    struct RecipeModelBasicTests {
        
        @Test("Create recipe with basic properties")
        func createBasicRecipe() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(
                title: "Test Recipe",
                servings: 4,
                creditsText: "Test Chef"
            )
            
            #expect(recipe.title == "Test Recipe")
            #expect(recipe.servings == 4)
            #expect(recipe.creditsText == "Test Chef")
            #expect(recipe.uuid != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        }
        
        @Test("Recipe UUID uniqueness")
        func testUUIDUniqueness() async throws {
            let recipe1 = NowThatIKnowMore.RecipeModel(title: "Recipe 1")
            let recipe2 = NowThatIKnowMore.RecipeModel(title: "Recipe 2")
            
            #expect(recipe1.uuid != recipe2.uuid)
        }
        
        @Test("Recipe with dietary flags")
        func testDietaryFlags() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(
                title: "Vegan Recipe",
                vegetarian: true,
                vegan: true,
                glutenFree: true,
                dairyFree: true
            )
            
            #expect(recipe.vegetarian == true)
            #expect(recipe.vegan == true)
            #expect(recipe.glutenFree == true)
            #expect(recipe.dairyFree == true)
        }
        
        @Test("Recipe timestamps are set")
        func testTimestamps() async throws {
            let beforeCreation = Date()
            let recipe = NowThatIKnowMore.RecipeModel(title: "Timestamp Test")
            let afterCreation = Date()
            
            #expect(recipe.createdAt >= beforeCreation)
            #expect(recipe.createdAt <= afterCreation)
            #expect(recipe.modifiedAt >= beforeCreation)
            #expect(recipe.modifiedAt <= afterCreation)
        }
    }
    
    // MARK: - RecipeModel Computed Properties Tests
    
    @Suite("RecipeModel Computed Properties")
    struct RecipeModelComputedPropertiesTests {
        
        @Test("Cuisines string conversion")
        func testCuisinesConversion() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Italian Dish")
            recipe.cuisines = ["Italian", "Mediterranean"]
            
            #expect(recipe.cuisinesString == "Italian,Mediterranean")
            #expect(recipe.cuisines.count == 2)
            #expect(recipe.cuisines.contains("Italian"))
        }
        
        @Test("Dish types string conversion")
        func testDishTypesConversion() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Lunch Recipe")
            recipe.dishTypes = ["lunch", "main course"]
            
            #expect(recipe.dishTypesString == "lunch,main course")
            #expect(recipe.dishTypes.count == 2)
        }
        
        @Test("Diets string conversion")
        func testDietsConversion() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Healthy Recipe")
            recipe.diets = ["gluten free", "dairy free"]
            
            #expect(recipe.dietsString == "gluten free,dairy free")
            #expect(recipe.diets.count == 2)
        }
        
        @Test("Days of week string conversion")
        func testDaysOfWeekConversion() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Weekly Recipe")
            recipe.daysOfWeek = ["Monday", "Wednesday", "Friday"]
            
            #expect(recipe.daysOfWeekString == "Monday,Wednesday,Friday")
            #expect(recipe.daysOfWeek.count == 3)
        }
    }
    
    // MARK: - RecipeService Tests
    
    @Suite("RecipeService Operations")
    struct RecipeServiceTests {
        
        @Test("Create and fetch recipe")
        @MainActor
        func testCreateAndFetchRecipe() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            // Create and add recipe
            let recipe = NowThatIKnowMore.RecipeModel(
                title: "Service Test Recipe",
                servings: 2
            )
            service.addRecipe(recipe)
            
            // Fetch all recipes
            let recipes = service.fetchAllRecipes()
            #expect(recipes.count == 1)
            #expect(recipes.first?.title == "Service Test Recipe")
        }
        
        @Test("Fetch recipe by UUID")
        @MainActor
        func testFetchRecipeByUUID() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            let recipe = NowThatIKnowMore.RecipeModel(title: "UUID Test Recipe")
            let uuid = recipe.uuid
            service.addRecipe(recipe)
            
            let fetchedRecipe = service.fetchRecipe(by: uuid)
            #expect(fetchedRecipe != nil)
            #expect(fetchedRecipe?.uuid == uuid)
        }
        
        @Test("Delete recipe")
        @MainActor
        func testDeleteRecipe() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            let recipe = NowThatIKnowMore.RecipeModel(title: "Delete Test Recipe")
            service.addRecipe(recipe)
            
            #expect(service.fetchAllRecipes().count == 1)
            
            service.deleteRecipe(recipe)
            
            #expect(service.fetchAllRecipes().count == 0)
        }
        
        @Test("Delete all recipes")
        @MainActor
        func testDeleteAllRecipes() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            service.addRecipe(NowThatIKnowMore.RecipeModel(title: "Recipe 1"))
            service.addRecipe(NowThatIKnowMore.RecipeModel(title: "Recipe 2"))
            service.addRecipe(NowThatIKnowMore.RecipeModel(title: "Recipe 3"))
            
            #expect(service.fetchAllRecipes().count == 3)
            
            service.deleteAllRecipes()
            
            #expect(service.fetchAllRecipes().count == 0)
        }
    }
    
    // MARK: - RecipeBookModel Tests
    
    @Suite("RecipeBook Operations")
    struct RecipeBookTests {
        
        @Test("Create recipe book")
        @MainActor
        func testCreateBook() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            let book = NowThatIKnowMore.RecipeBookModel(
                name: "My Cookbook",
                colorHex: "#FF5733"
            )
            service.addBook(book)
            
            let books = service.fetchAllBooks()
            #expect(books.count == 1)
            #expect(books.first?.name == "My Cookbook")
        }
        
        @Test("Create default books")
        @MainActor
        func testCreateDefaultBooks() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            service.createDefaultBooksIfNeeded()
            
            // Force a context save explicitly before fetching
            try context.save()
            
            let books = service.fetchAllBooks()
            #expect(books.count == 3)
            #expect(books.contains(where: { $0.name == "Favorites" }))
            #expect(books.contains(where: { $0.name == "Quick Meals" }))
            #expect(books.contains(where: { $0.name == "Desserts" }))
        }
        
        @Test("Delete recipe book")
        @MainActor
        func testDeleteBook() async throws {
            let container = try NowThatIKnowMoreTests.createTestContainer()
            let context = container.mainContext
            let service = NowThatIKnowMore.RecipeService(modelContext: context)
            
            let book = NowThatIKnowMore.RecipeBookModel(name: "Temporary Book")
            service.addBook(book)
            
            #expect(service.fetchAllBooks().count == 1)
            
            service.deleteBook(book)
            
            #expect(service.fetchAllBooks().count == 0)
        }
    }
    
    // MARK: - Ingredients and Instructions Tests
    
    @Suite("Recipe Ingredients and Instructions")
    struct IngredientsInstructionsTests {
        
        @Test("Recipe with ingredients")
        func testRecipeWithIngredients() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Recipe with Ingredients")
            
            let ingredients = [
                NowThatIKnowMore.ExtendedIngredient(
                    id: 1,
                    aisle: "Spices",
                    image: nil,
                    consistency: nil,
                    name: "Salt",
                    nameClean: "salt",
                    original: "1 tsp salt",
                    originalName: "salt",
                    amount: 1.0,
                    unit: "tsp",
                    meta: nil,
                    measures: nil
                )
            ]
            
            recipe.extendedIngredients = ingredients
            
            #expect(recipe.extendedIngredients?.count == 1)
            #expect(recipe.extendedIngredients?.first?.name == "Salt")
            #expect(recipe.extendedIngredients?.first?.amount == 1.0)
        }
        
        @Test("Recipe with analyzed instructions")
        @MainActor
        func testRecipeWithInstructions() async throws {
            let recipe = NowThatIKnowMore.RecipeModel(title: "Recipe with Instructions")
            
            let step = NowThatIKnowMore.Step(
                number: 1,
                step: "Boil water",
                ingredients: nil,
                equipment: nil,
                length: nil
            )
            
            let instruction = NowThatIKnowMore.AnalyzedInstruction(
                name: "",
                steps: [step]
            )
            
            recipe.analyzedInstructions = [instruction]
            
            #expect(recipe.analyzedInstructions?.count == 1)
            #expect(recipe.analyzedInstructions?.first?.steps?.count == 1)
            #expect(recipe.analyzedInstructions?.first?.steps?.first?.step == "Boil water")
        }
    }
}
