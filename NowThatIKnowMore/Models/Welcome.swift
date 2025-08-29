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
        case id, image, imageType, title, readyInMinutes, servings
        case sourceURL = "sourceUrl"
        case vegetarian, vegan, glutenFree, dairyFree, veryHealthy, cheap, veryPopular, sustainable, lowFodmap, weightWatcherSmartPoints, gaps, preparationMinutes, cookingMinutes, aggregateLikes, healthScore, creditsText, license, sourceName, pricePerServing, extendedIngredients, summary, cuisines, dishTypes, diets, occasions, instructions, analyzedInstructions
        case originalID = "originalId"
        case spoonacularScore
        case spoonacularSourceURL = "spoonacularSourceUrl"
    }

    // UUID is always generated during decode and not stored in JSON.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
        self.uuid = UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
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
}

// MARK: - AnalyzedInstruction
struct AnalyzedInstruction: Codable, Sendable {
    let name: String?
    let steps: [Step]?
}

// MARK: - Step
struct Step: Codable, Sendable {
    let number: Int?
    let step: String?
    let ingredients, equipment: [Ent]?
    let length: Length?
}

// MARK: - Ent
struct Ent: Codable, Sendable {
    let id: Int?
    let name, localizedName: String?
    let image: String?
    let temperature: Length?
}

// MARK: - Length
struct Length: Codable, Sendable {
    let number: Int?
    let unit: String?
}

// MARK: - ExtendedIngredient
struct ExtendedIngredient: Codable, Sendable {
    let id: Int?
    let aisle, image: String?
    let consistency: Consistency?
    let name, nameClean, original, originalName: String?
    let amount: Double?
    let unit: String?
    let meta: [String]?
    let measures: Measures?
}

enum Consistency: String, Codable, Sendable {
    case liquid = "LIQUID"
    case solid = "SOLID"
}

// MARK: - Measures
struct Measures: Codable, Sendable {
    let us, metric: Metric?
}

// MARK: - Metric
struct Metric: Codable, Sendable {
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

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
            return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
            return EncodingError.invalidValue(value, context)
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

