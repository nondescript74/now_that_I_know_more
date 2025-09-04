//
//  Welcome.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - Welcome
struct Recipe: Codable, Sendable, Identifiable {
    let uuid: UUID
    let id: Int?
    let image: String?
    let imageType, title: String?
    let readyInMinutes: JSONNull?
    let servings: Int?
    let sourceURL: String?
    let vegetarian, vegan, glutenFree, dairyFree: Bool?
    let veryHealthy, cheap, veryPopular, sustainable: Bool?
    let lowFodmap: Bool?
    let weightWatcherSmartPoints: Int?
    let gaps: String?
    let preparationMinutes, cookingMinutes: JSONNull?
    let aggregateLikes, healthScore: Int?
    let creditsText: String?
    let license: JSONNull?
    let sourceName: String?
    let pricePerServing: Int?
    let extendedIngredients: [ExtendedIngredient]?
    let summary: String?
    let cuisines, dishTypes, diets, occasions: [JSONAny]?
    let instructions: String?
    let analyzedInstructions: [AnalyzedInstruction]?
    let originalID: JSONNull?
    let spoonacularScore: Int?
    let spoonacularSourceURL: String?

    enum CodingKeys: String, CodingKey {
        case uuid
        case id, image, imageType, title, readyInMinutes, servings
        case sourceURL = "sourceUrl"
        case vegetarian, vegan, glutenFree, dairyFree, veryHealthy, cheap, veryPopular, sustainable, lowFodmap, weightWatcherSmartPoints, gaps, preparationMinutes, cookingMinutes, aggregateLikes, healthScore, creditsText, license, sourceName, pricePerServing, extendedIngredients, summary, cuisines, dishTypes, diets, occasions, instructions, analyzedInstructions
        case originalID = "originalId"
        case spoonacularScore
        case spoonacularSourceURL = "spoonacularSourceUrl"
    }

    // UUID is decoded from JSON and not generated during decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.imageType = try container.decodeIfPresent(String.self, forKey: .imageType)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.readyInMinutes = try container.decodeIfPresent(JSONNull.self, forKey: .readyInMinutes)
        self.servings = try container.decodeIfPresent(Int.self, forKey: .servings)
        self.sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        self.vegetarian = try container.decodeIfPresent(Bool.self, forKey: .vegetarian)
        self.vegan = try container.decodeIfPresent(Bool.self, forKey: .vegan)
        self.glutenFree = try container.decodeIfPresent(Bool.self, forKey: .glutenFree)
        self.dairyFree = try container.decodeIfPresent(Bool.self, forKey: .dairyFree)
        self.veryHealthy = try container.decodeIfPresent(Bool.self, forKey: .veryHealthy)
        self.cheap = try container.decodeIfPresent(Bool.self, forKey: .cheap)
        self.veryPopular = try container.decodeIfPresent(Bool.self, forKey: .veryPopular)
        self.sustainable = try container.decodeIfPresent(Bool.self, forKey: .sustainable)
        self.lowFodmap = try container.decodeIfPresent(Bool.self, forKey: .lowFodmap)
        self.weightWatcherSmartPoints = try container.decodeIfPresent(Int.self, forKey: .weightWatcherSmartPoints)
        self.gaps = try container.decodeIfPresent(String.self, forKey: .gaps)
        self.preparationMinutes = try container.decodeIfPresent(JSONNull.self, forKey: .preparationMinutes)
        self.cookingMinutes = try container.decodeIfPresent(JSONNull.self, forKey: .cookingMinutes)
        self.aggregateLikes = try container.decodeIfPresent(Int.self, forKey: .aggregateLikes)
        self.healthScore = try container.decodeIfPresent(Int.self, forKey: .healthScore)
        self.creditsText = try container.decodeIfPresent(String.self, forKey: .creditsText)
        self.license = try container.decodeIfPresent(JSONNull.self, forKey: .license)
        self.sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        self.pricePerServing = try container.decodeIfPresent(Int.self, forKey: .pricePerServing)
        self.extendedIngredients = try container.decodeIfPresent([ExtendedIngredient].self, forKey: .extendedIngredients)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.cuisines = try container.decodeIfPresent([JSONAny].self, forKey: .cuisines)
        self.dishTypes = try container.decodeIfPresent([JSONAny].self, forKey: .dishTypes)
        self.diets = try container.decodeIfPresent([JSONAny].self, forKey: .diets)
        self.occasions = try container.decodeIfPresent([JSONAny].self, forKey: .occasions)
        self.instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        self.analyzedInstructions = try container.decodeIfPresent([AnalyzedInstruction].self, forKey: .analyzedInstructions)
        self.originalID = try container.decodeIfPresent(JSONNull.self, forKey: .originalID)
        self.spoonacularScore = try container.decodeIfPresent(Int.self, forKey: .spoonacularScore)
        self.spoonacularSourceURL = try container.decodeIfPresent(String.self, forKey: .spoonacularSourceURL)
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
        try container.encodeIfPresent(vegetarian, forKey: .vegetarian)
        try container.encodeIfPresent(vegan, forKey: .vegan)
        try container.encodeIfPresent(glutenFree, forKey: .glutenFree)
        try container.encodeIfPresent(dairyFree, forKey: .dairyFree)
        try container.encodeIfPresent(veryHealthy, forKey: .veryHealthy)
        try container.encodeIfPresent(cheap, forKey: .cheap)
        try container.encodeIfPresent(veryPopular, forKey: .veryPopular)
        try container.encodeIfPresent(sustainable, forKey: .sustainable)
        try container.encodeIfPresent(lowFodmap, forKey: .lowFodmap)
        try container.encodeIfPresent(weightWatcherSmartPoints, forKey: .weightWatcherSmartPoints)
        try container.encodeIfPresent(gaps, forKey: .gaps)
        try container.encodeIfPresent(preparationMinutes, forKey: .preparationMinutes)
        try container.encodeIfPresent(cookingMinutes, forKey: .cookingMinutes)
        try container.encodeIfPresent(aggregateLikes, forKey: .aggregateLikes)
        try container.encodeIfPresent(healthScore, forKey: .healthScore)
        try container.encodeIfPresent(creditsText, forKey: .creditsText)
        try container.encodeIfPresent(license, forKey: .license)
        try container.encodeIfPresent(sourceName, forKey: .sourceName)
        try container.encodeIfPresent(pricePerServing, forKey: .pricePerServing)
        try container.encodeIfPresent(extendedIngredients, forKey: .extendedIngredients)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(cuisines, forKey: .cuisines)
        try container.encodeIfPresent(dishTypes, forKey: .dishTypes)
        try container.encodeIfPresent(diets, forKey: .diets)
        try container.encodeIfPresent(occasions, forKey: .occasions)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(analyzedInstructions, forKey: .analyzedInstructions)
        try container.encodeIfPresent(originalID, forKey: .originalID)
        try container.encodeIfPresent(spoonacularScore, forKey: .spoonacularScore)
        try container.encodeIfPresent(spoonacularSourceURL, forKey: .spoonacularSourceURL)
    }

    // Convenience failable initializer for Recipe from [String: Any] dictionary
    init?(from dict: [String: Any]) {
        self.uuid = dict["uuid"] as? UUID ?? UUID()
        self.id = dict["id"] as? Int
        self.image = dict["image"] as? String
        self.imageType = dict["imageType"] as? String
        self.title = dict["title"] as? String
        self.readyInMinutes = dict["readyInMinutes"] as? JSONNull
        self.servings = dict["servings"] as? Int
        self.sourceURL = dict["sourceUrl"] as? String ?? dict["sourceURL"] as? String
        self.vegetarian = dict["vegetarian"] as? Bool
        self.vegan = dict["vegan"] as? Bool
        self.glutenFree = dict["glutenFree"] as? Bool
        self.dairyFree = dict["dairyFree"] as? Bool
        self.veryHealthy = dict["veryHealthy"] as? Bool
        self.cheap = dict["cheap"] as? Bool
        self.veryPopular = dict["veryPopular"] as? Bool
        self.sustainable = dict["sustainable"] as? Bool
        self.lowFodmap = dict["lowFodmap"] as? Bool
        self.weightWatcherSmartPoints = dict["weightWatcherSmartPoints"] as? Int
        self.gaps = dict["gaps"] as? String
        self.preparationMinutes = dict["preparationMinutes"] as? JSONNull
        self.cookingMinutes = dict["cookingMinutes"] as? JSONNull
        self.aggregateLikes = dict["aggregateLikes"] as? Int
        self.healthScore = dict["healthScore"] as? Int
        self.creditsText = dict["creditsText"] as? String
        self.license = dict["license"] as? JSONNull
        self.sourceName = dict["sourceName"] as? String
        self.pricePerServing = dict["pricePerServing"] as? Int

        if let extArray = dict["extendedIngredients"] as? [[String: Any]] {
            self.extendedIngredients = extArray.compactMap { dict in
                guard let data = try? JSONSerialization.data(withJSONObject: dict),
                      let decoded = try? JSONDecoder().decode(ExtendedIngredient.self, from: data) else { return nil }
                return decoded
            }
        } else {
            self.extendedIngredients = nil
        }
        self.summary = dict["summary"] as? String
        self.cuisines = (dict["cuisines"] as? [Any])?.compactMap { JSONAny.wrap($0) }
        self.dishTypes = (dict["dishTypes"] as? [Any])?.compactMap { JSONAny.wrap($0) }
        self.diets = (dict["diets"] as? [Any])?.compactMap { JSONAny.wrap($0) }
        self.occasions = (dict["occasions"] as? [Any])?.compactMap { JSONAny.wrap($0) }
        self.instructions = dict["instructions"] as? String
        if let instArray = dict["analyzedInstructions"] as? [[String: Any]] {
            self.analyzedInstructions = instArray.compactMap { d in
                guard let data = try? JSONSerialization.data(withJSONObject: d),
                      let decoded = try? JSONDecoder().decode(AnalyzedInstruction.self, from: data) else { return nil }
                return decoded
            }
        } else {
            self.analyzedInstructions = nil
        }
        self.originalID = dict["originalId"] as? JSONNull
        self.spoonacularScore = dict["spoonacularScore"] as? Int
        self.spoonacularSourceURL = dict["spoonacularSourceUrl"] as? String ?? dict["spoonacularSourceURL"] as? String
    }
}

extension Recipe: Equatable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.imageType == rhs.imageType &&
            lhs.title == rhs.title &&
            (lhs.readyInMinutes == nil) == (rhs.readyInMinutes == nil) &&
            lhs.servings == rhs.servings &&
            lhs.sourceURL == rhs.sourceURL &&
            lhs.vegetarian == rhs.vegetarian &&
            lhs.vegan == rhs.vegan &&
            lhs.glutenFree == rhs.glutenFree &&
            lhs.dairyFree == rhs.dairyFree &&
            lhs.veryHealthy == rhs.veryHealthy &&
            lhs.cheap == rhs.cheap &&
            lhs.veryPopular == rhs.veryPopular &&
            lhs.sustainable == rhs.sustainable &&
            lhs.lowFodmap == rhs.lowFodmap &&
            lhs.weightWatcherSmartPoints == rhs.weightWatcherSmartPoints &&
            lhs.gaps == rhs.gaps &&
            (lhs.preparationMinutes == nil) == (rhs.preparationMinutes == nil) &&
            (lhs.cookingMinutes == nil) == (rhs.cookingMinutes == nil) &&
            lhs.aggregateLikes == rhs.aggregateLikes &&
            lhs.healthScore == rhs.healthScore &&
            lhs.creditsText == rhs.creditsText &&
            (lhs.license == nil) == (rhs.license == nil) &&
            lhs.sourceName == rhs.sourceName &&
            lhs.pricePerServing == rhs.pricePerServing &&
            lhs.extendedIngredients == rhs.extendedIngredients &&
            lhs.summary == rhs.summary &&
            (lhs.cuisines?.count ?? 0) == (rhs.cuisines?.count ?? 0) &&
            (lhs.dishTypes?.count ?? 0) == (rhs.dishTypes?.count ?? 0) &&
            (lhs.diets?.count ?? 0) == (rhs.diets?.count ?? 0) &&
            (lhs.occasions?.count ?? 0) == (rhs.occasions?.count ?? 0) &&
            lhs.instructions == rhs.instructions &&
            lhs.analyzedInstructions == rhs.analyzedInstructions &&
            (lhs.originalID == nil) == (rhs.originalID == nil) &&
            lhs.spoonacularScore == rhs.spoonacularScore &&
            lhs.spoonacularSourceURL == rhs.spoonacularSourceURL
    }
}

extension Recipe: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(imageType)
        hasher.combine(title)
        hasher.combine(servings)
        hasher.combine(sourceURL)
        hasher.combine(vegetarian)
        hasher.combine(vegan)
        hasher.combine(glutenFree)
        hasher.combine(dairyFree)
        hasher.combine(veryHealthy)
        hasher.combine(cheap)
        hasher.combine(veryPopular)
        hasher.combine(sustainable)
        hasher.combine(lowFodmap)
        hasher.combine(weightWatcherSmartPoints)
        hasher.combine(gaps)
        hasher.combine(aggregateLikes)
        hasher.combine(healthScore)
        hasher.combine(creditsText)
        hasher.combine(sourceName)
        hasher.combine(pricePerServing)
        hasher.combine(extendedIngredients)
        hasher.combine(summary)
        hasher.combine(instructions)
        hasher.combine(analyzedInstructions)
        hasher.combine(spoonacularScore)
        hasher.combine(spoonacularSourceURL)
        // For optionals that are not Hashable (JSONNull, JSONAny arrays), hash their nil-ness or count
        hasher.combine(readyInMinutes != nil)
        hasher.combine(preparationMinutes != nil)
        hasher.combine(cookingMinutes != nil)
        hasher.combine(license != nil)
        hasher.combine(originalID != nil)
        hasher.combine(cuisines?.count ?? 0)
        hasher.combine(dishTypes?.count ?? 0)
        hasher.combine(diets?.count ?? 0)
        hasher.combine(occasions?.count ?? 0)
    }
}

// MARK: - AnalyzedInstruction
struct AnalyzedInstruction: Codable, Sendable, Equatable, Hashable {
    let name: String?
    let steps: [Step]?

    init(name: String?, steps: [Step]?) {
        self.name = name
        self.steps = steps
    }
}

// MARK: - Step
struct Step: Codable, Sendable, Equatable, Hashable {
    let number: Int?
    let step: String?
    let ingredients, equipment: [Ent]?
    let length: Length?
}

// MARK: - Ent
struct Ent: Codable, Sendable, Equatable, Hashable {
    let id: Int?
    let name, localizedName: String?
    let image: String?
    let temperature: Length?
}

// MARK: - Length
struct Length: Codable, Sendable, Equatable, Hashable {
    let number: Int?
    let unit: String?
}

// MARK: - ExtendedIngredient
struct ExtendedIngredient: Codable, Sendable, Equatable, Hashable {
    let id: Int?
    let aisle, image: String?
    let consistency: Consistency?
    let name, nameClean, original, originalName: String?
    let amount: Double?
    let unit: String?
    let meta: [String]?
    let measures: Measures?
}

enum Consistency: String, Codable, Sendable, Equatable, Hashable {
    case liquid = "LIQUID"
    case solid = "SOLID"
}

// MARK: - Measures
struct Measures: Codable, Sendable, Equatable, Hashable {
    let us, metric: Metric?
}

// MARK: - Metric
struct Metric: Codable, Sendable, Equatable, Hashable {
    let amount: Double?
    let unitShort, unitLong: String?
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public func hash(into hasher: inout Hasher) {
        // All instances of JSONNull are considered equal, so hash a constant
        hasher.combine(0)
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
            return nil
    }

    required init?(stringValue: String) {
            key = stringValue
    }

    var intValue: Int? {
            return nil
    }

    var stringValue: String {
            return key
    }
}

class JSONAny: Codable {

    let value: Any
    init(_ value: Any) { self.value = value }

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
            return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
            return EncodingError.invalidValue(value, context)
    }
    
    static func wrap(_ value: Any) -> JSONAny? {
        if value is NSNull {
            return JSONAny(JSONNull())
        }
        return JSONAny(value)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if container.decodeNil() {
                    return JSONNull()
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if let value = try? container.decodeNil() {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer() {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
            if let value = try? container.decode(Bool.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Int64.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(String.self, forKey: key) {
                    return value
            }
            if let value = try? container.decodeNil(forKey: key) {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer(forKey: key) {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
            var arr: [Any] = []
            while !container.isAtEnd {
                    let value = try decode(from: &container)
                    arr.append(value)
            }
            return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
            var dict = [String: Any]()
            for key in container.allKeys {
                    let value = try decode(from: &container, forKey: key)
                    dict[key.stringValue] = value
            }
            return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
            for value in array {
                    if let value = value as? Bool {
                            try container.encode(value)
                    } else if let value = value as? Int64 {
                            try container.encode(value)
                    } else if let value = value as? Double {
                            try container.encode(value)
                    } else if let value = value as? String {
                            try container.encode(value)
                    } else if value is JSONNull {
                            try container.encodeNil()
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer()
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
            for (key, value) in dictionary {
                    let key = JSONCodingKey(stringValue: key)!
                    if let value = value as? Bool {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Int64 {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Double {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? String {
                            try container.encode(value, forKey: key)
                    } else if value is JSONNull {
                            try container.encodeNil(forKey: key)
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer(forKey: key)
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
            if let value = value as? Bool {
                    try container.encode(value)
            } else if let value = value as? Int64 {
                    try container.encode(value)
            } else if let value = value as? Double {
                    try container.encode(value)
            } else if let value = value as? String {
                    try container.encode(value)
            } else if value is JSONNull {
                    try container.encodeNil()
            } else {
                    throw encodingError(forValue: value, codingPath: container.codingPath)
            }
    }

    public required init(from decoder: Decoder) throws {
            if var arrayContainer = try? decoder.unkeyedContainer() {
                    self.value = try JSONAny.decodeArray(from: &arrayContainer)
            } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
                    self.value = try JSONAny.decodeDictionary(from: &container)
            } else {
                    let container = try decoder.singleValueContainer()
                    self.value = try JSONAny.decode(from: container)
            }
    }

    public func encode(to encoder: Encoder) throws {
            if let arr = self.value as? [Any] {
                    var container = encoder.unkeyedContainer()
                    try JSONAny.encode(to: &container, array: arr)
            } else if let dict = self.value as? [String: Any] {
                    var container = encoder.container(keyedBy: JSONCodingKey.self)
                    try JSONAny.encode(to: &container, dictionary: dict)
            } else {
                    var container = encoder.singleValueContainer()
                    try JSONAny.encode(to: &container, value: self.value)
            }
    }
}

