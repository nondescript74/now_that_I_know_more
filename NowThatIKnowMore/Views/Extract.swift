//
//  Extract.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI
import Combine
import OSLog

struct Extract: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var urlString = ""
    @State private var resultText = ""
    @State private var showingAPIKeyEntry = false
    @State private var extractedRecipe: Recipe?
    @State private var showingRecipeSheet = false
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "Extract")
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Set API Key") {
                showingAPIKeyEntry = true
            }
            Button("Clear Recipes") {
                recipeStore.clear()
            }
            
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
            }
            .padding(.horizontal)
            
            Button("Extract Recipe") {
                Task {
                    await extractRecipe()
                }
            }
            .disabled(urlString.isEmpty)
            
            ScrollView {
                if let recipe = extractedRecipe {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.title ?? "No Title")
                            .font(.title)
                            .bold()
                        
                        if let summary = recipe.summary {
                            Text(stripHTML(from: summary))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                            Text("Ingredients:")
                                .font(.headline)
                            ForEach(ingredients, id: \.original) { ing in
                                Text("• \(ing.original ?? "")")
                            }
                        }
                        
                        if let steps = recipe.analyzedInstructions?.flatMap({ $0.steps ?? [] }), !steps.isEmpty {
                            Text("Instructions:")
                                .font(.headline)
                            ForEach(steps) { step in
                                Text("\(step.number ?? 0). \(step.step ?? "")")
                            }
                        }
                    }
                    .padding()
                } else {
                    Text(resultText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .monospaced()
                        .textSelection(.enabled)
                }
            }
            .frame(minHeight: 150, maxHeight: 400)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingAPIKeyEntry) {
            APIKeyEntryView()
        }
        .sheet(isPresented: $showingRecipeSheet) {
            if let recipe = extractedRecipe {
                RecipeDetail(recipe: recipe)
            }
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
                    if let title = dict["title"] as? String {
                        self.resultText = "Title: \(title)\n\n" + ((try? prettyPrinted(dict)) ?? String(describing: dict))
                    } else {
                        self.resultText = (try? prettyPrinted(dict)) ?? String(describing: dict)
                    }
                    recipeStore.add(jsonObject as! Recipe)
                    logger.info("\(self.resultText, privacy: .public)")
                } else if let arr = jsonObject as? [Any] {
                    self.resultText = (try? prettyPrinted(arr)) ?? String(describing: arr)
                }
            }
            
            // Commented out Recipe decoding and storage:
            // recipeStore.add(recipe)
            // self.resultText = "Saved: \(recipe.title ?? "No title")"
            logger.info("\(self.resultText, privacy: .public)")
            
        } catch {
            self.resultText = error.localizedDescription
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
