//#if !canImport(XCTest) && !canImport(Testing)
//#warning("Recipe+Decoding.swift is NOT being included in the test target.\nIf you see this warning in your main app build only, everything is OK.\nIf you do NOT see this warning in your test build, Recipe+Decoding.swift is missing from the test target!")
//#endif

// Recipe+Decoding.swift
// Shared decoding logic for Recipe (including MealPlan and DictionaryToRecipeView)
import Foundation

extension Recipe {
    /// Decodes a Recipe from JSON Data, handling image + imageType correction when needed.
    /// - Parameter data: The JSON data to decode.
    /// - Returns: a valid Recipe if possible, or nil.
    static func decodeFromJSONOrPatchedDict(_ data: Data) -> Recipe? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Try direct decoding first
        if let recipe = try? decoder.decode(Recipe.self, from: data) {
            return recipe
        }
        // Try as dictionary fallback
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              var dict = jsonObject as? [String: Any] else {
            return nil
        }
        patchImageAndType(in: &dict)
        return Recipe(from: dict)
    }

    /// Decodes a Recipe from a dictionary, with image/imageType patching.
    static func decodeFromPatchedDict(_ dictIn: [String: Any]) -> Recipe? {
        var dict = dictIn
        patchImageAndType(in: &dict)
        return Recipe(from: dict)
    }

    /// Patches image string using imageType if needed, in-place.
    private static func patchImageAndType(in dict: inout [String: Any]) {
        // Patch only if image is present and imageType is present, and image doesn't end with common extension
        guard let image = dict["image"] as? String,
              let imageType = dict["imageType"] as? String,
              !image.isEmpty,
              !image.lowercased().hasSuffix(".jpg"),
              !image.lowercased().hasSuffix(".jpeg"),
              !image.lowercased().hasSuffix(".png"),
              !image.lowercased().hasSuffix(".gif"),
              !image.lowercased().hasSuffix(".webp")
        else { return }
        // Add period if needed
        var suffixedImage = image
        let hasPeriod = image.hasSuffix(".") || imageType.hasPrefix(".")
        // Only add if not already included
        if hasPeriod {
            suffixedImage += imageType
        } else if !imageType.isEmpty {
            suffixedImage += "." + imageType
        } else {
            suffixedImage += ".jpg"
        }
        dict["image"] = suffixedImage
    }
}
