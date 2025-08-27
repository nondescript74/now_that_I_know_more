//
//  Extract.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI

struct Extract: View {
    @State private var urlString = ""
    @State private var resultText = ""
    
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
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            self.resultText = json?["title"] as? String ?? "No title found"
        } catch {
            self.resultText = error.localizedDescription
        }
    }
}

#Preview {
    Extract()
}
