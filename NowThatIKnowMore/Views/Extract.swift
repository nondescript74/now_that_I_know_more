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
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "Extract")
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Set API Key") {
                showingAPIKeyEntry = true
            }
            Button("Clear Recipes") {
                recipeStore.clear()
            }
            
            TextField("Paste recipe URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button("Extract Recipe") {
                Task {
                    await extractRecipe()
                }
            }
            .disabled(urlString.isEmpty)
            
            Text(resultText)
                .padding()
                .multilineTextAlignment(.center)
        }
        .sheet(isPresented: $showingAPIKeyEntry) {
            APIKeyEntryView()
        }
    }
    
    private func extractRecipe() async {
        resultText = "Loading..."
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
        // components.query = "url=\(urlString)&\(apiKey)"  // original line commented out
        
        guard let url = components.url else {
            resultText = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        logger.info("\(url, privacy: .public)")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = jsonObject as? [String: Any] {
                if let title = dict["title"] as? String {
                    self.resultText = "Title: \(title)\n\n" + ((try? prettyPrinted(dict)) ?? String(describing: dict))
                } else {
                    self.resultText = (try? prettyPrinted(dict)) ?? String(describing: dict)
                }
            } else if let arr = jsonObject as? [Any] {
                self.resultText = (try? prettyPrinted(arr)) ?? String(describing: arr)
            }
            
            // Commented out Recipe decoding and storage:
            // let decoder = JSONDecoder()
            // decoder.keyDecodingStrategy = .convertFromSnakeCase
            // let recipe = try decoder.decode(Recipe.self, from: data)
            // recipeStore.add(recipe)
            // self.resultText = "Saved: \(recipe.title ?? "No title")"
            // logger.info("\(self.resultText, privacy: .public)")
            
        } catch {
            self.resultText = error.localizedDescription
        }
    }
    
    private func prettyPrinted(_ object: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? String(describing: object)
    }
}

#Preview {
    Extract().environment(RecipeStore())
}
