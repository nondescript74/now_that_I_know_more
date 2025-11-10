//
//  RecipeModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for Recipe persistence
//

import Foundation
import SwiftData

@Model
final class RecipeModel: Codable, Identifiable {
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
    var spoonacularScore: Double?
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
        spoonacularScore: Double? = nil,
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

// MARK: - Codable Conformance
extension RecipeModel {
    enum CodingKeys: String, CodingKey {
        case uuid, id, image, imageType, title, readyInMinutes, servings, sourceURL
        case vegetarian, vegan, glutenFree, dairyFree, veryHealthy, cheap, veryPopular
        case sustainable, lowFodmap, weightWatcherSmartPoints, gaps, preparationMinutes
        case cookingMinutes, aggregateLikes, healthScore, creditsText, sourceName
        case pricePerServing, summary, instructions, spoonacularScore, spoonacularSourceURL
        case createdAt, modifiedAt, cuisinesString, dishTypesString, dietsString
        case occasionsString, daysOfWeekString, extendedIngredientsJSON
        case analyzedInstructionsJSON, featuredMediaID, preferFeaturedMedia
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(
            uuid: try container.decode(UUID.self, forKey: .uuid),
            id: try container.decodeIfPresent(Int.self, forKey: .id),
            image: try container.decodeIfPresent(String.self, forKey: .image),
            imageType: try container.decodeIfPresent(String.self, forKey: .imageType),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            readyInMinutes: try container.decodeIfPresent(Int.self, forKey: .readyInMinutes),
            servings: try container.decodeIfPresent(Int.self, forKey: .servings),
            sourceURL: try container.decodeIfPresent(String.self, forKey: .sourceURL),
            vegetarian: try container.decode(Bool.self, forKey: .vegetarian),
            vegan: try container.decode(Bool.self, forKey: .vegan),
            glutenFree: try container.decode(Bool.self, forKey: .glutenFree),
            dairyFree: try container.decode(Bool.self, forKey: .dairyFree),
            veryHealthy: try container.decode(Bool.self, forKey: .veryHealthy),
            cheap: try container.decode(Bool.self, forKey: .cheap),
            veryPopular: try container.decode(Bool.self, forKey: .veryPopular),
            sustainable: try container.decode(Bool.self, forKey: .sustainable),
            lowFodmap: try container.decode(Bool.self, forKey: .lowFodmap),
            weightWatcherSmartPoints: try container.decodeIfPresent(Int.self, forKey: .weightWatcherSmartPoints),
            gaps: try container.decodeIfPresent(String.self, forKey: .gaps),
            preparationMinutes: try container.decodeIfPresent(Int.self, forKey: .preparationMinutes),
            cookingMinutes: try container.decodeIfPresent(Int.self, forKey: .cookingMinutes),
            aggregateLikes: try container.decodeIfPresent(Int.self, forKey: .aggregateLikes),
            healthScore: try container.decodeIfPresent(Int.self, forKey: .healthScore),
            creditsText: try container.decodeIfPresent(String.self, forKey: .creditsText),
            sourceName: try container.decodeIfPresent(String.self, forKey: .sourceName),
            pricePerServing: try container.decodeIfPresent(Int.self, forKey: .pricePerServing),
            summary: try container.decodeIfPresent(String.self, forKey: .summary),
            instructions: try container.decodeIfPresent(String.self, forKey: .instructions),
            spoonacularScore: try container.decodeIfPresent(Double.self, forKey: .spoonacularScore),
            spoonacularSourceURL: try container.decodeIfPresent(String.self, forKey: .spoonacularSourceURL),
            cuisinesString: try container.decodeIfPresent(String.self, forKey: .cuisinesString),
            dishTypesString: try container.decodeIfPresent(String.self, forKey: .dishTypesString),
            dietsString: try container.decodeIfPresent(String.self, forKey: .dietsString),
            occasionsString: try container.decodeIfPresent(String.self, forKey: .occasionsString),
            daysOfWeekString: try container.decodeIfPresent(String.self, forKey: .daysOfWeekString),
            extendedIngredientsJSON: try container.decodeIfPresent(Data.self, forKey: .extendedIngredientsJSON),
            analyzedInstructionsJSON: try container.decodeIfPresent(Data.self, forKey: .analyzedInstructionsJSON),
            featuredMediaID: try container.decodeIfPresent(UUID.self, forKey: .featuredMediaID),
            preferFeaturedMedia: try container.decode(Bool.self, forKey: .preferFeaturedMedia)
        )
        
        // Decode the timestamps
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(imageType, forKey: .imageType)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(readyInMinutes, forKey: .readyInMinutes)
        try container.encodeIfPresent(servings, forKey: .servings)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encode(vegetarian, forKey: .vegetarian)
        try container.encode(vegan, forKey: .vegan)
        try container.encode(glutenFree, forKey: .glutenFree)
        try container.encode(dairyFree, forKey: .dairyFree)
        try container.encode(veryHealthy, forKey: .veryHealthy)
        try container.encode(cheap, forKey: .cheap)
        try container.encode(veryPopular, forKey: .veryPopular)
        try container.encode(sustainable, forKey: .sustainable)
        try container.encode(lowFodmap, forKey: .lowFodmap)
        try container.encodeIfPresent(weightWatcherSmartPoints, forKey: .weightWatcherSmartPoints)
        try container.encodeIfPresent(gaps, forKey: .gaps)
        try container.encodeIfPresent(preparationMinutes, forKey: .preparationMinutes)
        try container.encodeIfPresent(cookingMinutes, forKey: .cookingMinutes)
        try container.encodeIfPresent(aggregateLikes, forKey: .aggregateLikes)
        try container.encodeIfPresent(healthScore, forKey: .healthScore)
        try container.encodeIfPresent(creditsText, forKey: .creditsText)
        try container.encodeIfPresent(sourceName, forKey: .sourceName)
        try container.encodeIfPresent(pricePerServing, forKey: .pricePerServing)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(spoonacularScore, forKey: .spoonacularScore)
        try container.encodeIfPresent(spoonacularSourceURL, forKey: .spoonacularSourceURL)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encodeIfPresent(cuisinesString, forKey: .cuisinesString)
        try container.encodeIfPresent(dishTypesString, forKey: .dishTypesString)
        try container.encodeIfPresent(dietsString, forKey: .dietsString)
        try container.encodeIfPresent(occasionsString, forKey: .occasionsString)
        try container.encodeIfPresent(daysOfWeekString, forKey: .daysOfWeekString)
        try container.encodeIfPresent(extendedIngredientsJSON, forKey: .extendedIngredientsJSON)
        try container.encodeIfPresent(analyzedInstructionsJSON, forKey: .analyzedInstructionsJSON)
        try container.encodeIfPresent(featuredMediaID, forKey: .featuredMediaID)
        try container.encode(preferFeaturedMedia, forKey: .preferFeaturedMedia)
        
        // Note: We intentionally don't encode the relationships (mediaItems, notes, books)
        // as these are managed by SwiftData and would create circular references
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
            // For local files, return the full resolved path
            if featured.fileURL.hasPrefix("/") {
                // Legacy absolute path
                return featured.fileURL
            } else {
                // New relative path - resolve to full path
                return featured.fullFileURL.path
            }
        }
        // Fall back to first media item if no featured is set
        if let firstMedia = mediaItems?.first {
            // For local files, return the full resolved path
            if firstMedia.fileURL.hasPrefix("/") {
                // Legacy absolute path
                return firstMedia.fileURL
            } else {
                // New relative path - resolve to full path
                return firstMedia.fullFileURL.path
            }
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
    static func from(recipe: Recipe) -> RecipeModel {
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
        
        return RecipeModel(
            uuid: recipe.uuid,
            id: recipe.id,
            image: recipe.image,
            imageType: recipe.imageType,
            title: recipe.title,
            readyInMinutes: recipe.readyInMinutes,
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
            preparationMinutes: recipe.preparationMinutes,
            cookingMinutes: recipe.cookingMinutes,
            aggregateLikes: recipe.aggregateLikes,
            healthScore: recipe.healthScore.map { Int($0) },
            creditsText: recipe.creditsText,
            sourceName: recipe.sourceName,
            pricePerServing: recipe.pricePerServing.map { Int($0) },
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
}
