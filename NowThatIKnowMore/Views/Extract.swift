//
//  Extract.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI
import Combine
import OSLog

extension JSONAny {
    static func wrap(_ value: Any) -> JSONAny {
        // Encodes the value as JSON and decodes as JSONAny
        let data = try! JSONSerialization.data(withJSONObject: [value], options: [])
        return try! JSONDecoder().decode([JSONAny].self, from: data)[0]
    }
}

struct Extract: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var urlString = ""
    @State private var resultText = ""
    @State private var extractedRecipe: Recipe?
    @State private var createdRecipe: Recipe?
    @State private var showingRecipeSheet = false
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "Extract")
    
    var body: some View {
        VStack {
            HStack {
                TextField("Paste recipe URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                if !urlString.isEmpty {
                    Button(action: { urlString = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear URL")
                }
                Button("Extract") {
                    Task {
                        await extractRecipe()
                        if extractedRecipe != nil {
                            logger.info("extractedRecipe: \(String(describing: extractedRecipe))")
                        } else if createdRecipe != nil {
                            logger.info("createdRecipe: \(String(describing: createdRecipe))")
                        } else {
                            logger.info("unknown recipe")
                        }
                    }
                }
                .disabled(urlString.isEmpty)
            }
            .padding()
            
            Spacer()
            
            Button("Clear Recipes") {
                recipeStore.clear()
            }
            
            Text(resultText)
                .padding()
        }
    }
    
    private func extractRecipe() async {
        resultText = "Loading..."
        extractedRecipe = nil
        let endpoint = "https://api.spoonacular.com/recipes/extract"
        
        let apiKey = UserDefaults.standard.string(forKey: "spoonacularAPIKey") ?? ""
        if apiKey.isEmpty {
            resultText = "API key not set."
            return
        }
        
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "url", value: urlString),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            resultText = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        logger.info("\(url, privacy: .public)")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let recipe = try? decoder.decode(Recipe.self, from: data) {
                extractedRecipe = recipe
                recipeStore.add(recipe)
                showingRecipeSheet = true
                resultText = ""
            } else {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = jsonObject as? [String: Any] {
                    // Attempt fallback decode by re-encoding dict to data and decoding Recipe
                    if let dictData = try? JSONSerialization.data(withJSONObject: dict),
                       let fallbackRecipe = try? decoder.decode(Recipe.self, from: dictData) {
                        self.extractedRecipe = fallbackRecipe
                        self.createdRecipe = nil
                        recipeStore.add(fallbackRecipe)
                        self.showingRecipeSheet = true
                        self.resultText = ""
                    } else {
                        if let title = dict["title"] as? String {
                            // create a Recipe and save it to the extractedRecipe
                            if createRecipeFromDictionary(dict) == nil {
                                self.resultText = "Title: \(title)\n\n" + ((try? prettyPrinted(dict)) ?? String(describing: dict))
                                logger.info("can't parse dictionary to Recipe")
                            }
                            self.createdRecipe = createRecipeFromDictionary(dict)
                            recipeStore.add(self.createdRecipe!)
                            self.extractedRecipe = nil
                            self.showingRecipeSheet = true
                            self.resultText = "Title: \(title)"
                        } else {
                            self.resultText = (try? prettyPrinted(dict)) ?? String(describing: dict)
                        }
                    }
                    // Recipe was not saved due to type mismatch or fallback decode failed.
                } else if let arr = jsonObject as? [Any] {
                    self.resultText = try prettyPrinted(arr)
                }
            }
            logger.info("\(self.resultText, privacy: .public)")
            
        } catch {
            self.resultText = error.localizedDescription
        }
    }
    
    private func createRecipeFromDictionary(_ dict: [String: Any]) -> Recipe? {
        // Uses new Recipe(from:) initializer for dynamic dictionary input
        if let recipe = Recipe(from: dict) {
            return recipe
        } else {
            return nil
        }
    }
    
    private func prettyPrinted(_ object: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? String(describing: object)
    }
    
    private func stripHTML(from string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        if let attributed = try? NSAttributedString(data: data,
                                                    options: [.documentType: NSAttributedString.DocumentType.html,
                                                              .characterEncoding: String.Encoding.utf8.rawValue],
                                                    documentAttributes: nil) {
            return attributed.string
        }
        return string
    }
}

#Preview {
    Extract().environment(RecipeStore())
}
