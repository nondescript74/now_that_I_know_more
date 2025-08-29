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
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "Extract")
    
    var body: some View {
        VStack(spacing: 20) {
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
    }
    
    private func extractRecipe() async {
        resultText = "Loading..."
        let endpoint = "https://api.spoonacular.com/recipes/extract"
        let apiKey = "&apiKey=27d2d9f90a8d4bf48e69ad6b819d7c1c"
        
        var components = URLComponents(string: endpoint)!
        components.query = "&url=\(urlString)" + apiKey
        
        guard let url = components.url else {
            resultText = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        logger.info("\(url, privacy: .public)")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let recipe = try JSONDecoder().decode(Recipe.self, from: data)
            recipeStore.add(recipe)
            self.resultText = "Saved: \(recipe.title ?? "No title")"
            logger.info("\(self.resultText, privacy: .public)")
        } catch {
            self.resultText = error.localizedDescription
        }
    }
}

#Preview {
    Extract().environment(RecipeStore())
}
