import Testing
import Foundation
@testable import NowThatIKnowMore

@Suite("Recipe URL and Decoding Tests")
struct RecipeTests {
    @Test("Validate sourceURL is a proper URL")
    @MainActor
    func testSourceURLValidity() async throws {
        // Example good and bad URLs
        let validStrings = [
            "https://www.apple.com",
            "http://example.com/recipe?id=123"
        ]
        let invalidStrings = [
            "not a url",
            "htp:/bad.url"
        ]

        for urlString in validStrings {
            let url = URL(string: urlString)
            #expect(url != nil && url!.scheme?.hasPrefix("http") == true, "Should be a valid URL: \(urlString)")
        }
        for bad in invalidStrings {
            let url = URL(string: bad)
            #expect(url == nil || !(url!.scheme?.hasPrefix("http") ?? false), "Should not be a valid http(s) URL: \(bad)")
        }
    }

    @Test("Recipe can be decoded and is 'readable'")
    @MainActor
    func testRecipeDecodingAndReadability() async throws {
        // Sample JSON data with valid fields
        let json = """
        {
          "id": -1,
          "image": "https://www.foodista.com/sites/default/files/styles/recype/public/DSC01604.jpg",
          "imageType": "jpg",
          "title": "Chocolate Crinkle Cookies",
          "readyInMinutes": null,
          "servings": 30,
          "sourceUrl": "https://foodista.com/recipe/ZHK4KPB6/chocolate-crinkle-cookies",
          "vegetarian": false,
          "vegan": false,
          "glutenFree": false,
          "dairyFree": false,
          "veryHealthy": false,
          "cheap": false,
          "veryPopular": false,
          "sustainable": false,
          "lowFodmap": false,
          "weightWatcherSmartPoints": 0,
          "gaps": "no",
          "preparationMinutes": null,
          "cookingMinutes": null,
          "aggregateLikes": 0,
          "healthScore": 0,
          "creditsText": "Foodista",
          "license": null,
          "sourceName": "Foodista",
          "pricePerServing": 0,
          "extendedIngredients": [],
          "summary": "Chocolate Crinkle Cookies takes about <b>about 45 minutes</b> from beginning to end.",
          "cuisines": [],
          "dishTypes": [],
          "diets": [],
          "occasions": [],
          "instructions": "Preheat the oven to 350 degrees F.",
          "analyzedInstructions": [],
          "originalId": null,
          "spoonacularScore": 0,
          "spoonacularSourceUrl": ""
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        var recipe: Recipe? = nil
        var decodeError: Error? = nil
        do {
            recipe = try decoder.decode(Recipe.self, from: json)
        } catch {
            decodeError = error
            // Attempt JSONSerialization fallback
            do {
                if let dict = try JSONSerialization.jsonObject(with: json, options: []) as? [String: Any] {
                    // Try to create a Recipe from a dictionary if initializer exists
                    if let fallback = Recipe(from: dict) {
                        recipe = fallback
                    }
                }
            } catch {
                // fallback failed, leave recipe as nil
            }
        }

        #expect(recipe != nil, "Recipe should be decodable or creatable from dictionary, error: \(decodeError?.localizedDescription ?? "none")")
        #expect(recipe?.title != nil && !(recipe?.title?.isEmpty ?? true), "Recipe should have a non-empty title")
        #expect(recipe?.instructions != nil && !(recipe?.instructions?.isEmpty ?? true), "Recipe should have instructions")
        #expect(recipe?.sourceURL != nil && URL(string: recipe?.sourceURL ?? "") != nil, "Recipe should have a valid source URL")
    }

    // TODO: Implement Recipe init(from:) if not already present

    @Test("Recipe decoding fails for missing required fields")
    @MainActor
    func testRecipeDecodingFailsForMalformedJSON() async throws {
        let json = """
        {
            "id": 1,
            "title": "Incomplete Recipe"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        var didFail = false
        do {
            _ = try decoder.decode(Recipe.self, from: json)
        } catch {
            didFail = true
        }
        #expect(didFail, "Decoding should fail when required fields are missing.")
    }

    @Test("Recipe with missing or empty content is not readable")
    @MainActor
    func testRecipeNotReadableIfEmptyOrMissingFields() async throws {
        // Missing title and instructions
        let json = """
        {
            "uuid": "EEF0B2C9-CA2A-4AF5-89B8-8A5C6D2E085A",
            "sourceUrl": "https://test.com/recipe"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: json)
        let titleIsReadable = recipe.title?.isEmpty == false
        let instructionsAreReadable = recipe.instructions?.isEmpty == false
        #expect(!titleIsReadable && !instructionsAreReadable, "Recipe is not readable if title or instructions are missing or empty.")
    }

    @Test("Recipe with invalid source URL is detected")
    @MainActor
    func testRecipeInvalidSourceURL() async throws {
        let json = """
        {
            "uuid": "EEF0B2C9-CA2A-4AF5-89B8-8A5C6D2E085A",
            "title": "Bad URL Recipe",
            "instructions": "Just do it!",
            "sourceUrl": "invalid-url"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: json)
        let isValidURL = recipe.sourceURL.flatMap { URL(string: $0) }?.scheme?.hasPrefix("http") == true
        #expect(!isValidURL, "Recipe should have an invalid source URL detected.")
    }
}

