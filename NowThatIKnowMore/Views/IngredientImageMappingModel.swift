//
//  IngredientImageMappingModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for persisting ingredient image URL mappings
//

import Foundation
import SwiftData

@Model
final class IngredientImageMappingModel {
    /// Spoonacular ingredient ID (unique identifier)
    @Attribute(.unique) var ingredientID: Int
    
    /// Ingredient name (for reference)
    var ingredientName: String
    
    /// Successful image filename (e.g., "garlic.jpg", "chicken-breasts.jpg")
    var imageFilename: String?
    
    /// Whether this ingredient has been tested
    var tested: Bool
    
    /// Number of URLs attempted before success (or failure)
    var attemptsCount: Int
    
    /// Date when this mapping was last verified
    var lastVerified: Date
    
    /// Whether the ingredient has no available image on Spoonacular
    var noImageAvailable: Bool
    
    /// All URLs that were attempted (stored as JSON array string)
    var attemptedURLsJSON: String?
    
    init(
        ingredientID: Int,
        ingredientName: String,
        imageFilename: String? = nil,
        tested: Bool = false,
        attemptsCount: Int = 0,
        noImageAvailable: Bool = false,
        attemptedURLsJSON: String? = nil
    ) {
        self.ingredientID = ingredientID
        self.ingredientName = ingredientName
        self.imageFilename = imageFilename
        self.tested = tested
        self.attemptsCount = attemptsCount
        self.lastVerified = Date()
        self.noImageAvailable = noImageAvailable
        self.attemptedURLsJSON = attemptedURLsJSON
    }
    
    /// Get the full Spoonacular CDN URL for this ingredient's image
    var fullImageURL: URL? {
        guard let filename = imageFilename else { return nil }
        return URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(filename)")
    }
    
    /// Get attempted URLs as an array
    var attemptedURLs: [String] {
        get {
            guard let json = attemptedURLsJSON,
                  let data = json.data(using: .utf8),
                  let urls = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return urls
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                attemptedURLsJSON = json
            }
        }
    }
}

// MARK: - Service Layer

@MainActor
class IngredientImageMappingService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Find a mapping for a specific ingredient ID
    func mapping(forIngredientID id: Int) -> IngredientImageMappingModel? {
        let descriptor = FetchDescriptor<IngredientImageMappingModel>(
            predicate: #Predicate { $0.ingredientID == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    /// Find a mapping for a specific ingredient name (case-insensitive)
    func mapping(forIngredientName name: String) -> IngredientImageMappingModel? {
        let lowercasedName = name.lowercased()
        let descriptor = FetchDescriptor<IngredientImageMappingModel>()
        guard let allMappings = try? modelContext.fetch(descriptor) else {
            return nil
        }
        return allMappings.first { $0.ingredientName.lowercased() == lowercasedName }
    }
    
    /// Save or update a mapping
    func saveMapping(_ mapping: IngredientImageMappingModel) {
        modelContext.insert(mapping)
        try? modelContext.save()
    }
    
    /// Record a successful image mapping
    func recordSuccess(
        ingredientID: Int,
        ingredientName: String,
        imageFilename: String,
        attemptedURLs: [String]
    ) {
        // Check if mapping already exists
        if let existing = mapping(forIngredientID: ingredientID) {
            existing.imageFilename = imageFilename
            existing.tested = true
            existing.attemptsCount = attemptedURLs.count
            existing.lastVerified = Date()
            existing.noImageAvailable = false
            existing.attemptedURLs = attemptedURLs
        } else {
            let newMapping = IngredientImageMappingModel(
                ingredientID: ingredientID,
                ingredientName: ingredientName,
                imageFilename: imageFilename,
                tested: true,
                attemptsCount: attemptedURLs.count,
                noImageAvailable: false
            )
            newMapping.attemptedURLs = attemptedURLs
            modelContext.insert(newMapping)
        }
        
        try? modelContext.save()
        print("📝 Saved mapping: \(ingredientName) → \(imageFilename)")
    }
    
    /// Record a failed mapping (no image available)
    func recordFailure(
        ingredientID: Int,
        ingredientName: String,
        attemptedURLs: [String]
    ) {
        // Check if mapping already exists
        if let existing = mapping(forIngredientID: ingredientID) {
            existing.imageFilename = nil
            existing.tested = true
            existing.attemptsCount = attemptedURLs.count
            existing.lastVerified = Date()
            existing.noImageAvailable = true
            existing.attemptedURLs = attemptedURLs
        } else {
            let newMapping = IngredientImageMappingModel(
                ingredientID: ingredientID,
                ingredientName: ingredientName,
                imageFilename: nil,
                tested: true,
                attemptsCount: attemptedURLs.count,
                noImageAvailable: true
            )
            newMapping.attemptedURLs = attemptedURLs
            modelContext.insert(newMapping)
        }
        
        try? modelContext.save()
        print("📝 Recorded no image available: \(ingredientName)")
    }
    
    /// Get all tested mappings
    func getAllMappings() -> [IngredientImageMappingModel] {
        let descriptor = FetchDescriptor<IngredientImageMappingModel>(
            sortBy: [SortDescriptor(\.ingredientName)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get statistics about tested ingredients
    func getStatistics() -> (total: Int, successful: Int, failed: Int, untested: Int) {
        let allMappings = getAllMappings()
        let total = allMappings.count
        let tested = allMappings.filter(\.tested)
        let successful = tested.filter { !$0.noImageAvailable && $0.imageFilename != nil }.count
        let failed = tested.filter(\.noImageAvailable).count
        let untested = total - tested.count
        
        return (total: total, successful: successful, failed: failed, untested: untested)
    }
    
    /// Delete all mappings (for testing purposes)
    func deleteAllMappings() {
        let descriptor = FetchDescriptor<IngredientImageMappingModel>()
        if let allMappings = try? modelContext.fetch(descriptor) {
            for mapping in allMappings {
                modelContext.delete(mapping)
            }
            try? modelContext.save()
        }
    }
    
    /// Get image URL for an ingredient, checking cache first
    func getImageURL(forIngredientID id: Int, name: String) async -> URL? {
        // 1. Check if we have a cached mapping
        if let mapping = mapping(forIngredientID: id) {
            if mapping.tested {
                if mapping.noImageAvailable {
                    print("ℹ️ Known to have no image: \(name)")
                    return nil
                }
                if let url = mapping.fullImageURL {
                    print("✅ Using cached mapping: \(name) → \(mapping.imageFilename ?? "")")
                    return url
                }
            }
        }
        
        // 2. Not cached - need to test and find the image
        print("🔍 Testing ingredient image: \(name)")
        let urlsToTry = generateURLsToTry(for: name)
        
        for urlFilename in urlsToTry {
            let fullURL = "https://spoonacular.com/cdn/ingredients_100x100/\(urlFilename)"
            if await testURL(fullURL) {
                // Found it! Save the mapping
                recordSuccess(
                    ingredientID: id,
                    ingredientName: name,
                    imageFilename: urlFilename,
                    attemptedURLs: urlsToTry
                )
                return URL(string: fullURL)
            }
        }
        
        // 3. Not found - record failure
        recordFailure(
            ingredientID: id,
            ingredientName: name,
            attemptedURLs: urlsToTry
        )
        
        return nil
    }
    
    // MARK: - Private Helpers
    
    private func generateURLsToTry(for name: String) -> [String] {
        var urls: [String] = []
        
        // 1. Try exact hyphenated match
        urls.append(normalizeToHyphenated(name, extension: "jpg"))
        urls.append(normalizeToHyphenated(name, extension: "png"))
        
        // 2. Try simplified version
        let simplified = simplifyIngredientName(name)
        if simplified != name.lowercased().replacingOccurrences(of: " ", with: "-") {
            urls.append(simplified + ".jpg")
            urls.append(simplified + ".png")
        }
        
        // 3. Try plural variations
        urls.append(contentsOf: generatePluralVariations(name))
        
        // Remove duplicates
        return Array(Set(urls))
    }
    
    private func normalizeToHyphenated(_ name: String, extension: String) -> String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
            + ".\(`extension`)"
    }
    
    private func simplifyIngredientName(_ name: String) -> String {
        let lowercased = name.lowercased()
        let coreIngredients = [
            "flour", "sugar", "salt", "pepper", "butter", "oil", "milk", "cream",
            "cheese", "yogurt", "egg", "chicken", "beef", "pork", "fish", "shrimp",
            "tomato", "potato", "onion", "garlic", "carrot", "celery",
            "pasta", "rice", "bread", "sauce",
            "apple", "banana", "lemon", "orange",
            "basil", "oregano", "thyme", "parsley", "cinnamon", "paprika", "vanilla"
        ]
        
        for core in coreIngredients {
            if lowercased.contains(core) {
                return core
            }
        }
        
        let components = name.split(separator: " ")
        return components.last.map(String.init)?.lowercased() ?? name.lowercased()
    }
    
    private func generatePluralVariations(_ name: String) -> [String] {
        var variations: [String] = []
        let normalized = normalizeToHyphenated(name, extension: "").dropLast()
        
        variations.append(String(normalized) + "s.jpg")
        variations.append(String(normalized) + "s.png")
        
        if normalized.hasSuffix("s") {
            let singular = String(normalized.dropLast())
            variations.append(singular + ".jpg")
            variations.append(singular + ".png")
        }
        
        return variations
    }
    
    private func testURL(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}
