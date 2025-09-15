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
//    @State private var createdRecipe: Recipe?
    @State private var showingRecipeSheet = false
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "Extract")
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
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
                                } else {
                                    logger.info("unknown recipe")
                                }
                            }
                        }
                        .disabled(urlString.isEmpty)
                    }
                    .padding()
                    
                    Text(resultText)
                        .padding()
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        
    }
    
    private func extractRecipe() async {
        logger.info("[extractRecipe] started, urlString: \(urlString)")
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
            logger.info("[extractRecipe] API call succeeded, got data of length: \(data.count)")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            logger.info("[extractRecipe] Attempting direct decode to Recipe")
            if let recipe = try? decoder.decode(Recipe.self, from: data) {
                extractedRecipe = fixImageType(for: recipe)
                logger.info("[extractRecipe] extractedRecipe set, image: \(self.extractedRecipe?.image ?? "nil")")
                recipeStore.add(extractedRecipe!)
                showingRecipeSheet = true
                resultText = ""
            } else {
                logger.info("[extractRecipe] Direct decode failed, trying fallback decode")
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = jsonObject as? [String: Any] {
                    logger.info("[extractRecipe] Attempting fallback decode from dictionary")
                    // Attempt fallback decode by re-encoding dict to data and decoding Recipe
                    if let dictData = try? JSONSerialization.data(withJSONObject: dict),
                       let fallbackRecipe = try? decoder.decode(Recipe.self, from: dictData) {
                        logger.info("extractRecipe Fallback decode succeeded)")
                        self.extractedRecipe = fixImageType(for: fallbackRecipe)
                        logger.info("[extractRecipe] extractedRecipe set, image: \(self.extractedRecipe?.image ?? "nil")")
                        recipeStore.add(self.extractedRecipe!)
                        self.showingRecipeSheet = true
                        self.resultText = ""
                    } else {
                        logger.info("extractRecipe Fallback decode failed, checking for title to build Recipe from dictionary")
                        if let title = dict["title"] as? String {
                            logger.info("[extractRecipe] Creating recipe from dictionary, title: \(title)")
                            // create a Recipe and save it to the extractedRecipe
                            if createRecipeFromDictionary(dict) == nil {
                                self.resultText = "Title: \(title)\n\n" + ((try? prettyPrinted(dict)) ?? String(describing: dict))
                                logger.info("can't parse dictionary to Recipe")
                            }
                            self.extractedRecipe = createRecipeFromDictionary(dict)
                            logger.info("extractRecipe createdRecipe, image: \(self.extractedRecipe?.image ?? "nil")")
                            extractedRecipe = fixImageType(for: extractedRecipe!)
                            recipeStore.add(self.extractedRecipe!)
                            self.showingRecipeSheet = true
                            self.resultText = "Title: \(title)"
                        } else {
                            self.resultText = (try? prettyPrinted(dict)) ?? String(describing: dict)
                        }
                    }
                    // Recipe was not saved due to type mismatch or fallback decode failed.
                } else if let arr = jsonObject as? [Any] {
                    logger.info("recipe not saved >>> Found array instead of dictionary")
                    self.resultText = try prettyPrinted(arr)
                }
            }
            logger.info("\(self.resultText, privacy: .public)")
            
        } catch {
            self.resultText = error.localizedDescription
        }
    }
    
    private func createRecipeFromDictionary(_ dict: [String: Any]) -> Recipe? {
        return Recipe(from: dict)
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
    
    private func fixImageType(for recipe: Recipe) -> Recipe {
        logger.info("fixImageType called for recipe with image: \(recipe.image ?? "nil"), imageType: \(recipe.imageType ?? "nil")")
        guard var dict = recipe.asDictionary else { return recipe }
        
        if let image = dict["image"] as? String, !image.isEmpty {
            let imageType = dict["imageType"] as? String
            let commonExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tiff", ".heic", ".avif", ".svg"]
            let hasKnownExtension = commonExtensions.contains { image.lowercased().hasSuffix($0) }
            if (imageType == nil || imageType?.isEmpty == true) && !hasKnownExtension {
                dict["image"] = image + "jpg"
                logger.info("[fixImageType] patched image (added jpg): \(dict["image"] as? String ?? "nil")")
            }
        }
        
        if let image = dict["image"] as? String, !image.isEmpty, let imageType = dict["imageType"] as? String, !imageType.isEmpty {
            let expectedSuffix = "." + imageType.lowercased()
            if !image.lowercased().hasSuffix(expectedSuffix) {
                dict["image"] = image + expectedSuffix
                logger.info("[fixImageType] patched image: \(dict["image"] as? String ?? "nil")")
            }
        }
        return Recipe(from: dict) ?? recipe
    }
}

private extension Recipe {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

#Preview {
    Extract().environment(RecipeStore())
}

