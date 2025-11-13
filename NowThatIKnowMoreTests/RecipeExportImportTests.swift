//
//  RecipeExportImportTests.swift
//  NowThatIKnowMore
//
//  Comprehensive tests for recipe export and import functionality
//  Tests validate that recipes can be correctly encoded and decoded
//  without requiring mail services or physical devices
//

 
import Testing
import SwiftUI
import SwiftData
@testable import NowThatIKnowMore

@Suite("Recipe Export and Import Tests")
struct RecipeExportImportTests {
    
    // MARK: - Helper Methods
    
    /// Creates a comprehensive test recipe with all possible fields populated
    func createCompleteTestRecipe() -> RecipeModel {
        // Create extended ingredients
        let ingredient1 = ExtendedIngredient(
            id: 1001,
            aisle: "Baking",
            image: "flour.jpg",
            consistency: .solid,
            name: "all-purpose flour",
            nameClean: "all purpose flour",
            original: "2 cups all-purpose flour",
            originalName: "all-purpose flour",
            amount: 2.0,
            unit: "cups",
            meta: ["sifted"],
            measures: Measures(
                us: Metric(amount: 2.0, unitShort: "cups", unitLong: "cups"),
                metric: Metric(amount: 473.176, unitShort: "ml", unitLong: "milliliters")
            )
        )
        
        let ingredient2 = ExtendedIngredient(
            id: 1123,
            aisle: "Milk, Eggs, Other Dairy",
            image: "egg.jpg",
            consistency: .solid,
            name: "eggs",
            nameClean: "eggs",
            original: "3 large eggs",
            originalName: "eggs",
            amount: 3.0,
            unit: "large",
            meta: [],
            measures: Measures(
                us: Metric(amount: 3.0, unitShort: "", unitLong: ""),
                metric: Metric(amount: 3.0, unitShort: "", unitLong: "")
            )
        )
        
        // Create analyzed instructions
        let step1 = Step(
            number: 1,
            step: "Preheat your oven to 350°F (175°C).",
            ingredients: nil,
            equipment: nil,
            length: nil
        )
        
        let step2 = Step(
            number: 2,
            step: "In a large bowl, mix together the flour and eggs until well combined.",
            ingredients: nil,
            equipment: nil,
            length: nil
        )
        
        let instruction = AnalyzedInstruction(
            name: "Main Recipe",
            steps: [step1, step2]
        )
        
        // Create the recipe model with all fields populated
        let recipe = RecipeModel(
            uuid: UUID(),
            id: 12345,
            image: "https://example.com/recipe-image.jpg",
            imageType: "jpg",
            title: "Complete Test Recipe",
            readyInMinutes: 45,
            servings: 4,
            sourceURL: "https://example.com/recipe",
            vegetarian: true,
            vegan: false,
            glutenFree: false,
            dairyFree: false,
            veryHealthy: true,
            cheap: false,
            veryPopular: true,
            sustainable: true,
            lowFodmap: false,
            weightWatcherSmartPoints: 8,
            gaps: "no",
            preparationMinutes: 15,
            cookingMinutes: 30,
            aggregateLikes: 150,
            healthScore: 85,
            creditsText: "Test Chef",
            sourceName: "Test Kitchen",
            pricePerServing: 250,
            summary: "This is a comprehensive test recipe with all fields populated.",
            instructions: "Preheat oven. Mix ingredients. Bake until done.",
            spoonacularScore: 92.5,
            spoonacularSourceURL: "https://spoonacular.com/test-recipe",
            cuisinesString: "Italian,Mediterranean",
            dishTypesString: "main course,dinner",
            dietsString: "vegetarian",
            occasionsString: "lunch,dinner",
            daysOfWeekString: "Monday,Wednesday,Friday",
            featuredMediaID: nil,
            preferFeaturedMedia: false
        )
        
        // Set the complex properties using the computed properties
        recipe.extendedIngredients = [ingredient1, ingredient2]
        recipe.analyzedInstructions = [instruction]
        
        return recipe
    }
    
    /// Creates a minimal test recipe with only required fields
    func createMinimalTestRecipe() -> RecipeModel {
        let recipe = RecipeModel(
            title: "Minimal Test Recipe",
            servings: 2
        )
        return recipe
    }
    
    /// Exports a recipe to JSON data using the same encoding strategy as the app
    func exportRecipeToJSON(_ recipe: RecipeModel) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(recipe)
    }
    
    /// Imports a recipe from JSON data using the same decoding strategy as the app
    func importRecipeFromJSON(_ data: Data) throws -> RecipeModel {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RecipeModel.self, from: data)
    }
    
    // MARK: - Basic Export Tests
    
    @Test("Export complete recipe to JSON")
    func testExportCompleteRecipe() throws {
        let recipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(recipe)
        
        #expect(data.count > 0, "Exported data should not be empty")
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        #expect(json is [String: Any], "Exported data should be a valid JSON dictionary")
    }
    
    @Test("Export minimal recipe to JSON")
    func testExportMinimalRecipe() throws {
        let recipe = createMinimalTestRecipe()
        let data = try exportRecipeToJSON(recipe)
        
        #expect(data.count > 0, "Exported data should not be empty")
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        #expect(json is [String: Any], "Exported data should be a valid JSON dictionary")
    }
    
    // MARK: - Basic Import Tests
    
    @Test("Import complete recipe from JSON")
    func testImportCompleteRecipe() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.uuid == originalRecipe.uuid, "UUID should match")
        #expect(importedRecipe.title == originalRecipe.title, "Title should match")
        #expect(importedRecipe.servings == originalRecipe.servings, "Servings should match")
    }
    
    @Test("Import minimal recipe from JSON")
    func testImportMinimalRecipe() throws {
        let originalRecipe = createMinimalTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.title == originalRecipe.title, "Title should match")
        #expect(importedRecipe.servings == originalRecipe.servings, "Servings should match")
    }
    
    // MARK: - Round-Trip Tests
    
    @Test("Round-trip export and import preserves all basic fields")
    func testRoundTripBasicFields() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        // Test UUID
        #expect(importedRecipe.uuid == originalRecipe.uuid, "UUID should be preserved")
        
        // Test basic string fields
        #expect(importedRecipe.title == originalRecipe.title, "Title should be preserved")
        #expect(importedRecipe.image == originalRecipe.image, "Image URL should be preserved")
        #expect(importedRecipe.imageType == originalRecipe.imageType, "Image type should be preserved")
        #expect(importedRecipe.sourceURL == originalRecipe.sourceURL, "Source URL should be preserved")
        #expect(importedRecipe.creditsText == originalRecipe.creditsText, "Credits should be preserved")
        #expect(importedRecipe.summary == originalRecipe.summary, "Summary should be preserved")
        #expect(importedRecipe.instructions == originalRecipe.instructions, "Instructions should be preserved")
        
        // Test numeric fields
        #expect(importedRecipe.id == originalRecipe.id, "ID should be preserved")
        #expect(importedRecipe.servings == originalRecipe.servings, "Servings should be preserved")
        #expect(importedRecipe.readyInMinutes == originalRecipe.readyInMinutes, "Ready in minutes should be preserved")
        #expect(importedRecipe.preparationMinutes == originalRecipe.preparationMinutes, "Preparation minutes should be preserved")
        #expect(importedRecipe.cookingMinutes == originalRecipe.cookingMinutes, "Cooking minutes should be preserved")
        #expect(importedRecipe.aggregateLikes == originalRecipe.aggregateLikes, "Aggregate likes should be preserved")
        #expect(importedRecipe.healthScore == originalRecipe.healthScore, "Health score should be preserved")
        #expect(importedRecipe.pricePerServing == originalRecipe.pricePerServing, "Price per serving should be preserved")
        #expect(importedRecipe.spoonacularScore == originalRecipe.spoonacularScore, "Spoonacular score should be preserved")
        
        // Test boolean fields
        #expect(importedRecipe.vegetarian == originalRecipe.vegetarian, "Vegetarian flag should be preserved")
        #expect(importedRecipe.vegan == originalRecipe.vegan, "Vegan flag should be preserved")
        #expect(importedRecipe.glutenFree == originalRecipe.glutenFree, "Gluten-free flag should be preserved")
        #expect(importedRecipe.dairyFree == originalRecipe.dairyFree, "Dairy-free flag should be preserved")
        #expect(importedRecipe.veryHealthy == originalRecipe.veryHealthy, "Very healthy flag should be preserved")
        #expect(importedRecipe.cheap == originalRecipe.cheap, "Cheap flag should be preserved")
        #expect(importedRecipe.veryPopular == originalRecipe.veryPopular, "Very popular flag should be preserved")
        #expect(importedRecipe.sustainable == originalRecipe.sustainable, "Sustainable flag should be preserved")
        #expect(importedRecipe.lowFodmap == originalRecipe.lowFodmap, "Low FODMAP flag should be preserved")
    }
    
    @Test("Round-trip export and import preserves date fields")
    func testRoundTripDateFields() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        // Dates should match within 1 second (accounting for potential precision loss)
        let createdAtDiff = abs(importedRecipe.createdAt.timeIntervalSince(originalRecipe.createdAt))
        let modifiedAtDiff = abs(importedRecipe.modifiedAt.timeIntervalSince(originalRecipe.modifiedAt))
        
        #expect(createdAtDiff < 1.0, "Created at date should be preserved (difference: \(createdAtDiff)s)")
        #expect(modifiedAtDiff < 1.0, "Modified at date should be preserved (difference: \(modifiedAtDiff)s)")
    }
    
    @Test("Round-trip export and import preserves array fields (cuisines, diets, etc.)")
    func testRoundTripArrayFields() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.cuisines == originalRecipe.cuisines, "Cuisines should be preserved")
        #expect(importedRecipe.dishTypes == originalRecipe.dishTypes, "Dish types should be preserved")
        #expect(importedRecipe.diets == originalRecipe.diets, "Diets should be preserved")
        #expect(importedRecipe.occasions == originalRecipe.occasions, "Occasions should be preserved")
        #expect(importedRecipe.daysOfWeek == originalRecipe.daysOfWeek, "Days of week should be preserved")
    }
    
    @Test("Round-trip export and import preserves extended ingredients")
    func testRoundTripExtendedIngredients() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        let originalIngredients = try #require(originalRecipe.extendedIngredients, "Original recipe should have ingredients")
        let importedIngredients = try #require(importedRecipe.extendedIngredients, "Imported recipe should have ingredients")
        
        #expect(importedIngredients.count == originalIngredients.count, "Ingredient count should match")
        
        for (index, originalIngredient) in originalIngredients.enumerated() {
            let importedIngredient = importedIngredients[index]
            
            #expect(importedIngredient.id == originalIngredient.id, "Ingredient \(index) ID should match")
            #expect(importedIngredient.name == originalIngredient.name, "Ingredient \(index) name should match")
            #expect(importedIngredient.original == originalIngredient.original, "Ingredient \(index) original text should match")
            #expect(importedIngredient.amount == originalIngredient.amount, "Ingredient \(index) amount should match")
            #expect(importedIngredient.unit == originalIngredient.unit, "Ingredient \(index) unit should match")
        }
    }
    
    @Test("Round-trip export and import preserves analyzed instructions")
    func testRoundTripAnalyzedInstructions() throws {
        let originalRecipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(originalRecipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        let originalInstructions = try #require(originalRecipe.analyzedInstructions, "Original recipe should have instructions")
        let importedInstructions = try #require(importedRecipe.analyzedInstructions, "Imported recipe should have instructions")
        
        #expect(importedInstructions.count == originalInstructions.count, "Instruction count should match")
        
        for (index, originalInstruction) in originalInstructions.enumerated() {
            let importedInstruction = importedInstructions[index]
            
            #expect(importedInstruction.name == originalInstruction.name, "Instruction \(index) name should match")
            
            let originalSteps = originalInstruction.steps ?? []
            let importedSteps = importedInstruction.steps ?? []
            
            #expect(importedSteps.count == originalSteps.count, "Instruction \(index) step count should match")
            
            for (stepIndex, originalStep) in originalSteps.enumerated() {
                let importedStep = importedSteps[stepIndex]
                
                #expect(importedStep.number == originalStep.number, "Instruction \(index) step \(stepIndex) number should match")
                #expect(importedStep.step == originalStep.step, "Instruction \(index) step \(stepIndex) text should match")
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Export and import recipe with nil optional fields")
    func testExportImportWithNilFields() throws {
        let recipe = RecipeModel(
            title: "Recipe with Nil Fields",
            servings: nil,
            sourceURL: nil,
            creditsText: nil,
            summary: nil
        )
        
        let data = try exportRecipeToJSON(recipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.title == recipe.title, "Title should be preserved")
        #expect(importedRecipe.servings == nil, "Nil servings should be preserved")
        #expect(importedRecipe.sourceURL == nil, "Nil source URL should be preserved")
        #expect(importedRecipe.creditsText == nil, "Nil credits should be preserved")
        #expect(importedRecipe.summary == nil, "Nil summary should be preserved")
    }
    
    @Test("Export and import recipe with empty strings")
    func testExportImportWithEmptyStrings() throws {
        let recipe = RecipeModel(
            title: "",
            sourceURL: "",
            creditsText: "",
            summary: ""
        )
        
        let data = try exportRecipeToJSON(recipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.title == "", "Empty title should be preserved")
        #expect(importedRecipe.sourceURL == "", "Empty source URL should be preserved")
        #expect(importedRecipe.creditsText == "", "Empty credits should be preserved")
        #expect(importedRecipe.summary == "", "Empty summary should be preserved")
    }
    
    @Test("Export and import recipe with empty arrays")
    func testExportImportWithEmptyArrays() throws {
        let recipe = createCompleteTestRecipe()
        recipe.cuisines = []
        recipe.dishTypes = []
        recipe.diets = []
        recipe.occasions = []
        recipe.daysOfWeek = []
        
        let data = try exportRecipeToJSON(recipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.cuisines.isEmpty, "Empty cuisines should be preserved")
        #expect(importedRecipe.dishTypes.isEmpty, "Empty dish types should be preserved")
        #expect(importedRecipe.diets.isEmpty, "Empty diets should be preserved")
        #expect(importedRecipe.occasions.isEmpty, "Empty occasions should be preserved")
        #expect(importedRecipe.daysOfWeek.isEmpty, "Empty days of week should be preserved")
    }
    
    @Test("Export and import recipe with special characters in strings")
    func testExportImportWithSpecialCharacters() throws {
        let recipe = RecipeModel(
            title: "Recipe with Special Characters: é, ñ, ü, 中文, 🍕",
            creditsText: "Chef José María",
            summary: "This recipe contains \"quotes\", 'apostrophes', and <html> tags & symbols."
        )
        
        let data = try exportRecipeToJSON(recipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.title == recipe.title, "Special characters in title should be preserved")
        #expect(importedRecipe.creditsText == recipe.creditsText, "Special characters in credits should be preserved")
        #expect(importedRecipe.summary == recipe.summary, "Special characters in summary should be preserved")
    }
    
    @Test("Export and import recipe with very long strings")
    func testExportImportWithLongStrings() throws {
        let longSummary = String(repeating: "This is a very long summary. ", count: 100)
        let longInstructions = String(repeating: "Step: Do something important. ", count: 100)
        
        let recipe = RecipeModel(
            title: "Recipe with Long Content",
            summary: longSummary,
            instructions: longInstructions
        )
        
        let data = try exportRecipeToJSON(recipe)
        let importedRecipe = try importRecipeFromJSON(data)
        
        #expect(importedRecipe.summary == recipe.summary, "Long summary should be preserved")
        #expect(importedRecipe.instructions == recipe.instructions, "Long instructions should be preserved")
    }
    
    // MARK: - Validation Tests
    
    @Test("Exported JSON contains required fields")
    func testExportedJSONStructure() throws {
        let recipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(recipe)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let jsonDict = try #require(json, "Should be able to parse as dictionary")
        
        // Check for required fields
        #expect(jsonDict["uuid"] != nil, "JSON should contain uuid")
        #expect(jsonDict["title"] != nil, "JSON should contain title")
        #expect(jsonDict["createdAt"] != nil, "JSON should contain createdAt")
        #expect(jsonDict["modifiedAt"] != nil, "JSON should contain modifiedAt")
        #expect(jsonDict["vegetarian"] != nil, "JSON should contain vegetarian")
        #expect(jsonDict["vegan"] != nil, "JSON should contain vegan")
        #expect(jsonDict["preferFeaturedMedia"] != nil, "JSON should contain preferFeaturedMedia")
    }
    
    @Test("Exported JSON date format is ISO 8601")
    func testExportedDateFormat() throws {
        let recipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(recipe)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let jsonDict = try #require(json, "Should be able to parse as dictionary")
        
        let createdAtString = try #require(jsonDict["createdAt"] as? String, "createdAt should be a string")
        let modifiedAtString = try #require(jsonDict["modifiedAt"] as? String, "modifiedAt should be a string")
        
        // Check ISO 8601 format (e.g., "2025-11-13T10:09:00Z")
        let iso8601Regex = #/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/#
        #expect(createdAtString.contains(iso8601Regex), "createdAt should be in ISO 8601 format")
        #expect(modifiedAtString.contains(iso8601Regex), "modifiedAt should be in ISO 8601 format")
    }
    
    @Test("Recipe maintains data integrity after multiple round trips")
    func testMultipleRoundTrips() throws {
        var currentRecipe = createCompleteTestRecipe()
        
        // Perform 5 round trips
        for iteration in 1...5 {
            let data = try exportRecipeToJSON(currentRecipe)
            currentRecipe = try importRecipeFromJSON(data)
            
            // Verify key fields are still intact
            #expect(currentRecipe.title == "Complete Test Recipe", "Title should remain intact after iteration \(iteration)")
            #expect(currentRecipe.servings == 4, "Servings should remain intact after iteration \(iteration)")
            
            let ingredients = try #require(currentRecipe.extendedIngredients, "Ingredients should remain intact after iteration \(iteration)")
            #expect(ingredients.count == 2, "Ingredient count should remain intact after iteration \(iteration)")
            
            let instructions = try #require(currentRecipe.analyzedInstructions, "Instructions should remain intact after iteration \(iteration)")
            #expect(instructions.count == 1, "Instruction count should remain intact after iteration \(iteration)")
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Export performance is acceptable")
    func testExportPerformance() throws {
        let recipe = createCompleteTestRecipe()
        
        let startTime = Date()
        _ = try exportRecipeToJSON(recipe)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 0.1, "Export should complete in less than 100ms (took \(duration * 1000)ms)")
    }
    
    @Test("Import performance is acceptable")
    func testImportPerformance() throws {
        let recipe = createCompleteTestRecipe()
        let data = try exportRecipeToJSON(recipe)
        
        let startTime = Date()
        _ = try importRecipeFromJSON(data)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 0.1, "Import should complete in less than 100ms (took \(duration * 1000)ms)")
    }
    
    // MARK: - User-Specified Recipe Test
    
    @Test("Custom recipe: User-specified recipe from parameters", arguments: [
        // You can add custom test recipes here
        ("My Custom Recipe", 4, true, false),
        ("Another Custom Recipe", 6, false, true),
        ("Vegan Delight", 2, true, true)
    ])
    func testCustomRecipe(title: String, servings: Int, vegetarian: Bool, vegan: Bool) throws {
        let recipe = RecipeModel(
            title: title,
            servings: servings,
            vegetarian: vegetarian,
            vegan: vegan
        )
        
        // Export
        let data = try exportRecipeToJSON(recipe)
        #expect(data.count > 0, "Should be able to export custom recipe '\(title)'")
        
        // Import
        let importedRecipe = try importRecipeFromJSON(data)
        
        // Validate
        #expect(importedRecipe.title == title, "Custom recipe title should be preserved")
        #expect(importedRecipe.servings == servings, "Custom recipe servings should be preserved")
        #expect(importedRecipe.vegetarian == vegetarian, "Custom recipe vegetarian flag should be preserved")
        #expect(importedRecipe.vegan == vegan, "Custom recipe vegan flag should be preserved")
    }
}

// MARK: - Integration Test Suite

@Suite("Recipe Export/Import Integration Tests")
struct RecipeExportImportIntegrationTests {
    
    @Test("Complete workflow: Create -> Export -> Import -> Validate")
    func testCompleteWorkflow() throws {
        // 1. Create a recipe
        let originalRecipe = RecipeModel(
            title: "Integration Test Recipe",
            readyInMinutes: 30,
            servings: 4,
            sourceURL: "https://example.com/recipe",
            vegetarian: true,
            summary: "A recipe created for integration testing",
            instructions: "Follow these steps carefully."
        )
        
        // Add ingredients
        originalRecipe.extendedIngredients = [
            ExtendedIngredient(
                id: 1,
                aisle: nil,
                image: nil,
                consistency: nil,
                name: "flour",
                nameClean: "flour",
                original: "2 cups flour",
                originalName: "flour",
                amount: 2.0,
                unit: "cups",
                meta: nil,
                measures: nil
            )
        ]
        
        // Add instructions
        originalRecipe.analyzedInstructions = [
            AnalyzedInstruction(
                name: "Main",
                steps: [
                    Step(number: 1, step: "Mix ingredients", ingredients: nil, equipment: nil, length: nil),
                    Step(number: 2, step: "Bake at 350°F", ingredients: nil, equipment: nil, length: nil)
                ]
            )
        ]
        
        // 2. Export the recipe
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let exportedData = try encoder.encode(originalRecipe)
        
        #expect(exportedData.count > 0, "Export should produce data")
        
        // 3. Import the recipe
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importedRecipe = try decoder.decode(RecipeModel.self, from: exportedData)
        
        // 4. Validate all fields match
        #expect(importedRecipe.uuid == originalRecipe.uuid)
        #expect(importedRecipe.title == originalRecipe.title)
        #expect(importedRecipe.readyInMinutes == originalRecipe.readyInMinutes)
        #expect(importedRecipe.servings == originalRecipe.servings)
        #expect(importedRecipe.sourceURL == originalRecipe.sourceURL)
        #expect(importedRecipe.vegetarian == originalRecipe.vegetarian)
        #expect(importedRecipe.summary == originalRecipe.summary)
        #expect(importedRecipe.instructions == originalRecipe.instructions)
        
        // Validate ingredients
        let originalIngredients = try #require(originalRecipe.extendedIngredients)
        let importedIngredients = try #require(importedRecipe.extendedIngredients)
        #expect(importedIngredients.count == originalIngredients.count)
        #expect(importedIngredients[0].original == originalIngredients[0].original)
        
        // Validate instructions
        let originalInstructions = try #require(originalRecipe.analyzedInstructions)
        let importedInstructions = try #require(importedRecipe.analyzedInstructions)
        #expect(importedInstructions.count == originalInstructions.count)
        #expect(importedInstructions[0].steps?.count == originalInstructions[0].steps?.count)
    }
    
    @Test("Simulate email attachment: Write to file and read back")
    func testFileBasedExportImport() throws {
        // Create a recipe
        let recipe = RecipeModel(
            title: "File Export Test Recipe",
            servings: 2,
            summary: "Testing file-based export and import"
        )
        
        // Export to data
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(recipe)
        
        // Write to temporary file (simulating email attachment)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-recipe.recipe")
        try data.write(to: tempURL)
        
        #expect(FileManager.default.fileExists(atPath: tempURL.path), "File should be written")
        
        // Read from file (simulating opening email attachment)
        let readData = try Data(contentsOf: tempURL)
        
        // Import the recipe
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importedRecipe = try decoder.decode(RecipeModel.self, from: readData)
        
        // Validate
        #expect(importedRecipe.uuid == recipe.uuid)
        #expect(importedRecipe.title == recipe.title)
        #expect(importedRecipe.servings == recipe.servings)
        #expect(importedRecipe.summary == recipe.summary)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
}
