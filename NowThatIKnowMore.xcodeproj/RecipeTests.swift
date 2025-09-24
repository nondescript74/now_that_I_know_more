import Testing
import Foundation

@Suite("Recipe URL and Decoding Tests")
struct RecipeTests {
    @Test("Validate sourceURL is a proper URL")
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
    func testRecipeDecodingAndReadability() async throws {
        // Sample JSON data with valid fields
        let json = """
        {
            "uuid": "EEF0B2C9-CA2A-4AF5-89B8-8A5C6D2E085A",
            "id": 101,
            "image": "https://example.com/food.jpg",
            "imageType": "jpg",
            "title": "Fresh Salad",
            "servings": 2,
            "sourceUrl": "https://test.com/recipe",
            "vegetarian": true,
            "instructions": "Mix ingredients.",
            "analyzedInstructions": [
                { "name": "", "steps": [{"number":1,"step":"Mix all.","ingredients":[],"equipment":[],"length":null}] }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let recipe = try decoder.decode(Recipe.self, from: json)
        #expect(recipe.title != nil && !recipe.title!.isEmpty, "Recipe should have a non-empty title")
        #expect(recipe.instructions != nil && !recipe.instructions!.isEmpty, "Recipe should have instructions")
        #expect(recipe.sourceURL != nil && URL(string: recipe.sourceURL!) != nil, "Recipe should have a valid source URL")
    }

    @Test("Recipe decoding fails for missing required fields")
    func testRecipeDecodingFailsForMalformedJSON() async throws {
        let json = """
        {
            "id": 1,
            "title": "Incomplete Recipe"
            // missing uuid, sourceUrl, and instructions
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
