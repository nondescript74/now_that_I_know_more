//
//  RecipeModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for Recipe persistence
//

import Foundation
import SwiftData

@Model
final class RecipeModel {
    @Attribute(.unique) var uuid: UUID
    var id: Int?
    var image: String?
    var imageType: String?
    var title: String?
    var readyInMinutes: Int?
    var servings: Int?
    var sourceURL: String?
    var vegetarian: Bool
    var vegan: Bool
    var glutenFree: Bool
    var dairyFree: Bool
    var veryHealthy: Bool
    var cheap: Bool
    var veryPopular: Bool
    var sustainable: Bool
    var lowFodmap: Bool
    var weightWatcherSmartPoints: Int?
    var gaps: String?
    var preparationMinutes: Int?
    var cookingMinutes: Int?
    var aggregateLikes: Int?
    var healthScore: Int?
    var creditsText: String?
    var sourceName: String?
    var pricePerServing: Int?
    var summary: String?
    var instructions: String?
    var spoonacularScore: Int?
    var spoonacularSourceURL: String?
    var createdAt: Date
    var modifiedAt: Date
    
    // Cuisine, dish types, diets, occasions stored as comma-separated strings
    var cuisinesString: String?
    var dishTypesString: String?
    var dietsString: String?
    var occasionsString: String?
    var daysOfWeekString: String?
    
    // JSON-encoded strings for complex data
    @Attribute(.externalStorage) var extendedIngredientsJSON: Data?
    @Attribute(.externalStorage) var analyzedInstructionsJSON: Data?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \RecipeMediaModel.recipe)
    var mediaItems: [RecipeMediaModel]?
    
    @Relationship(deleteRule: .cascade, inverse: \RecipeNoteModel.recipe)
    var notes: [RecipeNoteModel]?
    
    @Relationship(inverse: \RecipeBookModel.recipes)
    var books: [RecipeBookModel]?
    
    var featuredMediaID: UUID?
    var preferFeaturedMedia: Bool
    
    init(
        uuid: UUID = UUID(),
        id: Int? = nil,
        image: String? = nil,
        imageType: String? = nil,
        title: String? = nil,
        readyInMinutes: Int? = nil,
        servings: Int? = nil,
        sourceURL: String? = nil,
        vegetarian: Bool = false,
        vegan: Bool = false,
        glutenFree: Bool = false,
        dairyFree: Bool = false,
        veryHealthy: Bool = false,
        cheap: Bool = false,
        veryPopular: Bool = false,
        sustainable: Bool = false,
        lowFodmap: Bool = false,
        weightWatcherSmartPoints: Int? = nil,
        gaps: String? = nil,
        preparationMinutes: Int? = nil,
        cookingMinutes: Int? = nil,
        aggregateLikes: Int? = nil,
        healthScore: Int? = nil,
        creditsText: String? = nil,
        sourceName: String? = nil,
        pricePerServing: Int? = nil,
        summary: String? = nil,
        instructions: String? = nil,
        spoonacularScore: Int? = nil,
        spoonacularSourceURL: String? = nil,
        cuisinesString: String? = nil,
        dishTypesString: String? = nil,
        dietsString: String? = nil,
        occasionsString: String? = nil,
        daysOfWeekString: String? = nil,
        extendedIngredientsJSON: Data? = nil,
        analyzedInstructionsJSON: Data? = nil,
        featuredMediaID: UUID? = nil,
        preferFeaturedMedia: Bool = false
    ) {
        self.uuid = uuid
        self.id = id
        self.image = image
        self.imageType = imageType
        self.title = title
        self.readyInMinutes = readyInMinutes
        self.servings = servings
        self.sourceURL = sourceURL
        self.vegetarian = vegetarian
        self.vegan = vegan
        self.glutenFree = glutenFree
        self.dairyFree = dairyFree
        self.veryHealthy = veryHealthy
        self.cheap = cheap
        self.veryPopular = veryPopular
        self.sustainable = sustainable
        self.lowFodmap = lowFodmap
        self.weightWatcherSmartPoints = weightWatcherSmartPoints
        self.gaps = gaps
        self.preparationMinutes = preparationMinutes
        self.cookingMinutes = cookingMinutes
        self.aggregateLikes = aggregateLikes
        self.healthScore = healthScore
        self.creditsText = creditsText
        self.sourceName = sourceName
        self.pricePerServing = pricePerServing
        self.summary = summary
        self.instructions = instructions
        self.spoonacularScore = spoonacularScore
        self.spoonacularSourceURL = spoonacularSourceURL
        self.cuisinesString = cuisinesString
        self.dishTypesString = dishTypesString
        self.dietsString = dietsString
        self.occasionsString = occasionsString
        self.daysOfWeekString = daysOfWeekString
        self.extendedIngredientsJSON = extendedIngredientsJSON
        self.analyzedInstructionsJSON = analyzedInstructionsJSON
        self.featuredMediaID = featuredMediaID
        self.preferFeaturedMedia = preferFeaturedMedia
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Computed Properties
extension RecipeModel {
    var cuisines: [String] {
        get { cuisinesString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { cuisinesString = newValue.joined(separator: ",") }
    }
    
    var dishTypes: [String] {
        get { dishTypesString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { dishTypesString = newValue.joined(separator: ",") }
    }
    
    var diets: [String] {
        get { dietsString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { dietsString = newValue.joined(separator: ",") }
    }
    
    var occasions: [String] {
        get { occasionsString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { occasionsString = newValue.joined(separator: ",") }
    }
    
    var daysOfWeek: [String] {
        get { daysOfWeekString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { daysOfWeekString = newValue.joined(separator: ",") }
    }
    
    var extendedIngredients: [ExtendedIngredient]? {
        get {
            guard let data = extendedIngredientsJSON else { return nil }
            return try? JSONDecoder().decode([ExtendedIngredient].self, from: data)
        }
        set {
            extendedIngredientsJSON = try? JSONEncoder().encode(newValue)
            modifiedAt = Date()
        }
    }
    
    var analyzedInstructions: [AnalyzedInstruction]? {
        get {
            guard let data = analyzedInstructionsJSON else { return nil }
            return try? JSONDecoder().decode([AnalyzedInstruction].self, from: data)
        }
        set {
            analyzedInstructionsJSON = try? JSONEncoder().encode(newValue)
            modifiedAt = Date()
        }
    }
    
    /// Returns the URL of the featured media item, or falls back to the legacy image field
    var featuredMediaURL: String? {
        // If user explicitly prefers URL image over featured media, return the URL
        if !preferFeaturedMedia, let urlImage = image, !urlImage.isEmpty {
            return urlImage
        }
        
        // Otherwise, try to return featured media
        if let featuredID = featuredMediaID,
           let featured = mediaItems?.first(where: { $0.uuid == featuredID }) {
            return featured.fileURL
        }
        // Fall back to first media item if no featured is set
        if let firstMedia = mediaItems?.first {
            return firstMedia.fileURL
        }
        // Fall back to legacy image field
        return image
    }
    
    /// Returns the type of the featured media (photo or video)
    var featuredMediaType: RecipeMediaModel.MediaType? {
        if let featuredID = featuredMediaID,
           let featured = mediaItems?.first(where: { $0.uuid == featuredID }) {
            return featured.type
        }
        // Fall back to first media item if no featured is set
        if let firstMedia = mediaItems?.first {
            return firstMedia.type
        }
        // Legacy image field is assumed to be a photo
        return image != nil ? .photo : nil
    }
}

// MARK: - Conversion to/from legacy Recipe struct
extension RecipeModel {
    /// Convert from legacy Recipe struct
    @MainActor
    convenience init(from recipe: Recipe) {
        let ingredientsData = try? JSONEncoder().encode(recipe.extendedIngredients)
        let instructionsData = try? JSONEncoder().encode(recipe.analyzedInstructions)
        
        // Extract cuisines, dishTypes, diets, occasions from JSONAny arrays
        let cuisines = recipe.cuisines?.compactMap { jsonAny -> String? in
            if let str = jsonAny.value as? String { return str }
            return nil
        }.joined(separator: ",")
        
        let dishTypes = recipe.dishTypes?.compactMap { jsonAny -> String? in
            if let str = jsonAny.value as? String { return str }
            return nil
        }.joined(separator: ",")
        
        let diets = recipe.diets?.compactMap { jsonAny -> String? in
            if let str = jsonAny.value as? String { return str }
            return nil
        }.joined(separator: ",")
        
        let occasions = recipe.occasions?.compactMap { jsonAny -> String? in
            if let str = jsonAny.value as? String { return str }
            return nil
        }.joined(separator: ",")
        
        let daysOfWeek = recipe.daysOfWeek?.joined(separator: ",")
        
        // Handle readyInMinutes, preparationMinutes, cookingMinutes (which were JSONNull?)
        let readyInMinutes: Int? = nil // These were JSONNull in original
        let preparationMinutes: Int? = nil
        let cookingMinutes: Int? = nil
        
        self.init(
            uuid: recipe.uuid,
            id: recipe.id,
            image: recipe.image,
            imageType: recipe.imageType,
            title: recipe.title,
            readyInMinutes: readyInMinutes,
            servings: recipe.servings,
            sourceURL: recipe.sourceURL,
            vegetarian: recipe.vegetarian ?? false,
            vegan: recipe.vegan ?? false,
            glutenFree: recipe.glutenFree ?? false,
            dairyFree: recipe.dairyFree ?? false,
            veryHealthy: recipe.veryHealthy ?? false,
            cheap: recipe.cheap ?? false,
            veryPopular: recipe.veryPopular ?? false,
            sustainable: recipe.sustainable ?? false,
            lowFodmap: recipe.lowFodmap ?? false,
            weightWatcherSmartPoints: recipe.weightWatcherSmartPoints,
            gaps: recipe.gaps,
            preparationMinutes: preparationMinutes,
            cookingMinutes: cookingMinutes,
            aggregateLikes: recipe.aggregateLikes,
            healthScore: recipe.healthScore,
            creditsText: recipe.creditsText,
            sourceName: recipe.sourceName,
            pricePerServing: recipe.pricePerServing,
            summary: recipe.summary,
            instructions: recipe.instructions,
            spoonacularScore: recipe.spoonacularScore,
            spoonacularSourceURL: recipe.spoonacularSourceURL,
            cuisinesString: cuisines,
            dishTypesString: dishTypes,
            dietsString: diets,
            occasionsString: occasions,
            daysOfWeekString: daysOfWeek,
            extendedIngredientsJSON: ingredientsData,
            analyzedInstructionsJSON: instructionsData,
            featuredMediaID: recipe.featuredMediaID,
            preferFeaturedMedia: recipe.preferFeaturedMedia ?? false
        )
    }
    
    /// Convert to legacy Recipe struct (for backward compatibility)
    @MainActor
    func toLegacyRecipe() -> Recipe? {
        // This is complex due to the JSONAny types - create a dictionary and use Recipe(from:)
        var dict: [String: Any] = [
            "recipeFormatVersion": Recipe.currentFormatVersion,
            "uuid": uuid.uuidString,
            "title": title ?? "",
            "summary": summary ?? "",
            "creditsText": creditsText ?? ""
        ]
        
        if let id = id { dict["id"] = id }
        if let image = image { dict["image"] = image }
        if let imageType = imageType { dict["imageType"] = imageType }
        if let servings = servings { dict["servings"] = servings }
        if let sourceURL = sourceURL { dict["sourceUrl"] = sourceURL }
        dict["vegetarian"] = vegetarian
        dict["vegan"] = vegan
        dict["glutenFree"] = glutenFree
        dict["dairyFree"] = dairyFree
        dict["veryHealthy"] = veryHealthy
        dict["cheap"] = cheap
        dict["veryPopular"] = veryPopular
        dict["sustainable"] = sustainable
        dict["lowFodmap"] = lowFodmap
        if let weightWatcherSmartPoints = weightWatcherSmartPoints { dict["weightWatcherSmartPoints"] = weightWatcherSmartPoints }
        if let gaps = gaps { dict["gaps"] = gaps }
        if let aggregateLikes = aggregateLikes { dict["aggregateLikes"] = aggregateLikes }
        if let healthScore = healthScore { dict["healthScore"] = healthScore }
        if let sourceName = sourceName { dict["sourceName"] = sourceName }
        if let pricePerServing = pricePerServing { dict["pricePerServing"] = pricePerServing }
        if let instructions = instructions { dict["instructions"] = instructions }
        if let spoonacularScore = spoonacularScore { dict["spoonacularScore"] = spoonacularScore }
        if let spoonacularSourceURL = spoonacularSourceURL { dict["spoonacularSourceUrl"] = spoonacularSourceURL }
        
        if let daysOfWeek = daysOfWeekString?.components(separatedBy: ",").filter({ !$0.isEmpty }) {
            dict["daysOfWeek"] = daysOfWeek
        }
        
        if let ingredients = extendedIngredients {
            dict["extendedIngredients"] = try? ingredients.map { ingredient -> [String: Any] in
                let encoder = JSONEncoder()
                let data = try encoder.encode(ingredient)
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            }
        }
        
        if let instructions = analyzedInstructions {
            dict["analyzedInstructions"] = try? instructions.map { instruction -> [String: Any] in
                let encoder = JSONEncoder()
                let data = try encoder.encode(instruction)
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            }
        }
        
        return Recipe(from: dict)
    }
}
