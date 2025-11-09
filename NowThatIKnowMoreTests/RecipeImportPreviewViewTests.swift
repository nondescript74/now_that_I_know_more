//
//  RecipeImportPreviewViewTests.swift
//  NowThatIKnowMore
//
//  Test suite for RecipeImportPreviewView functions
//

import Testing
import SwiftUI
import SwiftData
@testable import NowThatIKnowMore

@Suite("Recipe Import Preview View Tests")
struct RecipeImportPreviewViewTests {
    
    // MARK: - Clean Summary Tests
    
    @Suite("HTML Summary Cleaning")
    struct CleanSummaryTests {
        
        @Test("Clean summary with basic HTML tags")
        func cleanBasicHTML() {
            let html = "<p>This is a simple paragraph.</p>"
            let result = cleanSummary(html)
            #expect(result == "This is a simple paragraph.")
        }
        
        @Test("Clean summary with bold and italic tags")
        func cleanBoldAndItalic() {
            let html = "<b>Bold text</b> and <i>italic text</i>"
            let result = cleanSummary(html)
            #expect(result == "Bold text and italic text")
        }
        
        @Test("Clean summary with line breaks")
        func cleanLineBreaks() {
            let html = "Line one<br>Line two<br/>Line three<br />Line four"
            let result = cleanSummary(html)
            #expect(result == "Line one Line two Line three Line four")
        }
        
        @Test("Clean summary with unordered list")
        func cleanUnorderedList() {
            let html = "<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>"
            let result = cleanSummary(html)
            #expect(result == "• First item • Second item • Third item")
        }
        
        @Test("Clean summary with nested HTML tags")
        func cleanNestedHTML() {
            let html = "<p><b>Bold paragraph</b> with <i>italic</i> text</p>"
            let result = cleanSummary(html)
            #expect(result == "Bold paragraph with italic text")
        }
        
        @Test("Clean summary with multiple spaces and newlines")
        func cleanExtraWhitespace() {
            let html = "<p>Text   with   spaces</p>\n\n<p>Another paragraph</p>"
            let result = cleanSummary(html)
            #expect(result == "Text   with   spaces Another paragraph")
        }
        
        @Test("Clean summary with empty string")
        func cleanEmptyString() {
            let html = ""
            let result = cleanSummary(html)
            #expect(result == "")
        }
        
        @Test("Clean summary with only whitespace")
        func cleanWhitespaceOnly() {
            let html = "   \n   \t   "
            let result = cleanSummary(html)
            #expect(result == "")
        }
        
        @Test("Clean summary with complex recipe description")
        func cleanComplexRecipeDescription() {
            let html = """
            <p>A <b>classic Italian</b> pasta dish.</p>
            <ul>
            <li>Easy to make</li>
            <li>Delicious taste</li>
            </ul>
            <p>Perfect for <i>weeknight dinners</i>.</p>
            """
            let result = cleanSummary(html)
            #expect(result.contains("classic Italian"))
            #expect(result.contains("•"))
            #expect(result.contains("Easy to make"))
            #expect(result.contains("weeknight dinners"))
        }
        
        @Test("Clean summary with self-closing br tags")
        func cleanSelfClosingBrTags() {
            let html = "Line 1<br/>Line 2<br />Line 3"
            let result = cleanSummary(html)
            #expect(result == "Line 1 Line 2 Line 3")
        }
        
        @Test("Clean summary with HTML entities preserved")
        func htmlEntitiesPreserved() {
            let html = "<p>Recipe with &amp; and &lt;ingredients&gt;</p>"
            let result = cleanSummary(html)
            #expect(result == "Recipe with &amp; and &lt;ingredients&gt;")
        }
        
        @Test("Clean summary with div and span tags")
        func cleanDivAndSpanTags() {
            let html = "<div><span>Inside span</span> and div</div>"
            let result = cleanSummary(html)
            #expect(result == "Inside span and div")
        }
        
        @Test("Clean summary filters empty lines")
        func filterEmptyLines() {
            let html = "<p>Line 1</p>\n\n\n<p>Line 2</p>"
            let result = cleanSummary(html)
            #expect(result == "Line 1 Line 2")
        }
    }
    
    // MARK: - RecipeModel Tests (SwiftData)
    
    @Suite("RecipeModel Creation and Properties")
    struct RecipeModelTests {
        
        @Test("Create recipe model with basic properties")
        func createBasicRecipeModel() {
            let recipe = RecipeModel(
                title: "Test Recipe",
                servings: 4,
                creditsText: "Test Chef",
                summary: "A test summary"
            )
            
            #expect(recipe.title == "Test Recipe")
            #expect(recipe.servings == 4)
            #expect(recipe.summary == "A test summary")
            #expect(recipe.creditsText == "Test Chef")
        }
        
        @Test("Recipe model with ingredients")
        func recipeModelWithIngredients() {
            let recipe = RecipeModel(
                title: "Recipe with Ingredients"
            )
            
            let ingredients = [
                ExtendedIngredient(
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
        }
        
        @Test("Recipe model with multiple properties")
        func recipeModelWithMultipleProperties() {
            let recipe = RecipeModel(
                title: "Complete Recipe",
                readyInMinutes: 30,
                servings: 6,
                vegetarian: true,
                vegan: false,
                glutenFree: true
            )
            
            #expect(recipe.title == "Complete Recipe")
            #expect(recipe.readyInMinutes == 30)
            #expect(recipe.servings == 6)
            #expect(recipe.vegetarian == true)
            #expect(recipe.vegan == false)
            #expect(recipe.glutenFree == true)
        }
        
        @Test("Recipe model UUID uniqueness")
        func recipeModelUUIDUniqueness() {
            let recipe1 = RecipeModel(title: "Recipe 1")
            let recipe2 = RecipeModel(title: "Recipe 2")
            
            #expect(recipe1.uuid != recipe2.uuid)
        }
        
        @Test("Recipe model with instructions")
        func recipeModelWithInstructions() {
            let recipe = RecipeModel(
                title: "Recipe with Instructions",
                instructions: "1. Boil water\n2. Add pasta\n3. Cook for 10 minutes"
            )
            
            #expect(recipe.instructions != nil)
            #expect(recipe.instructions?.contains("Boil water") == true)
        }
        
        @Test("Recipe model with cuisines")
        func recipeModelWithCuisines() {
            let recipe = RecipeModel(title: "Italian Dish")
            recipe.cuisines = ["Italian", "Mediterranean"]
            
            #expect(recipe.cuisines.count == 2)
            #expect(recipe.cuisines.contains("Italian"))
            #expect(recipe.cuisines.contains("Mediterranean"))
        }
        
        @Test("Recipe model with dish types")
        func recipeModelWithDishTypes() {
            let recipe = RecipeModel(title: "Lunch Recipe")
            recipe.dishTypes = ["lunch", "main course"]
            
            #expect(recipe.dishTypes.count == 2)
            #expect(recipe.dishTypes.contains("lunch"))
        }
        
        @Test("Recipe model timestamps")
        func recipeModelTimestamps() {
            let beforeCreation = Date()
            let recipe = RecipeModel(title: "Timestamp Test")
            let afterCreation = Date()
            
            #expect(recipe.createdAt >= beforeCreation)
            #expect(recipe.createdAt <= afterCreation)
            #expect(recipe.modifiedAt >= beforeCreation)
            #expect(recipe.modifiedAt <= afterCreation)
        }
        
        @Test("Recipe model with media items")
        @MainActor
        func recipeModelWithMediaItems() async throws {
            // Create in-memory model container
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: RecipeModel.self, RecipeMediaModel.self,
                configurations: config
            )
            let context = container.mainContext
            
            let recipe = RecipeModel(title: "Recipe with Media")
            context.insert(recipe)
            
            let media = RecipeMediaModel(
                fileURL: "/path/to/image.jpg",
                type: .photo,
                recipe: recipe
            )
            context.insert(media)
            
            try context.save()
            
            #expect(recipe.mediaItems?.count == 1)
            #expect(recipe.mediaItems?.first?.type == .photo)
        }
    }
    
    // MARK: - Recipe Image Handling Tests
    
    @Suite("Recipe Image and Media Handling")
    struct RecipeImageTests {
        
        @Test("Recipe with valid image URL")
        func recipeWithImageURL() {
            let recipe = RecipeModel(
                image: "https://example.com/image.jpg",
                title: "Recipe with Image",
                
            )
            
            #expect(recipe.image == "https://example.com/image.jpg")
            #expect(recipe.image?.isEmpty == false)
        }
        
        @Test("Recipe with empty image URL")
        func recipeWithEmptyImageURL() {
            let recipe = RecipeModel(
                image: "",
                title: "Recipe without Image"
            )
            
            #expect(recipe.image?.isEmpty == true)
        }
        
        @Test("Recipe with nil image URL")
        func recipeWithNilImageURL() {
            let recipe = RecipeModel(title: "No Image Recipe")
            
            #expect(recipe.image == nil)
        }
    }
}

// MARK: - Helper Functions

/// Helper function accessible from tests - wraps the private cleanSummary in RecipeImportPreviewView
//func cleanSummary(_ html: String) -> String {
//    var text = html.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
//    text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
//    text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
//    text = text.replacingOccurrences(of: "<ul>|</ul>", with: "", options: .regularExpression)
//    text = text.replacingOccurrences(of: "<b>(.*?)</b>", with: "$1", options: .regularExpression)
//    text = text.replacingOccurrences(of: "<i>(.*?)</i>", with: "$1", options: .regularExpression)
//    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
//    let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
//    return lines.filter { !$0.isEmpty }.joined(separator: " ")
//}
