//
//  ParsedRecipeAdapter.swift
//  Recipe Image Parser - Nowthatiknowmore Integration
//
//  Converts simple parsed recipe data into the full Recipe model
//

import Foundation

/// Simple structure for parsed recipe data from images
struct ParsedRecipe {
    var title: String
    var servings: String?
    var ingredients: [ParsedIngredient]
    var instructions: String?
}

struct ParsedIngredient: Identifiable {
    let id = UUID()
    var imperialAmount: String
    var name: String
    var metricAmount: String?
}

/// Converts parsed recipe data into the full Nowthatiknowmore Recipe model
struct ParsedRecipeAdapter {
    
    static func convert(_ parsed: ParsedRecipe) -> Recipe {
        let uuid = UUID()
        
        // Parse servings if available
        var servingsNumber: Int?
        if let servingsText = parsed.servings {
            // Extract number from strings like "Makes 1/2 cup (125 mL)" or "Serves 4"
            let numbers = servingsText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            if let firstNumber = numbers.first, let num = Int(firstNumber) {
                servingsNumber = num
            }
        }
        
        // Convert parsed ingredients to ExtendedIngredient format
        let extendedIngredients = parsed.ingredients.enumerated().map { (index, ingredient) -> ExtendedIngredient in
            convertToExtendedIngredient(ingredient, index: index)
        }
        
        // Create the Recipe using the existing model structure
        // Note: Only include non-nil values in the dictionary
        var dict: [String: Any] = [
            "uuid": uuid,  // Pass UUID directly, not as string
            "title": parsed.title,
            "creditsText": "Imported from recipe card photo",
            "sourceName": "Recipe Card Import",
            "extendedIngredients": extendedIngredients.map { ingredientToDict($0) },
            "cuisines": [] as [Any],
            "dishTypes": [] as [Any],
            "diets": [] as [Any],
            "occasions": [] as [Any]
        ]
        
        // Add optional values only if present
        if let servings = servingsNumber {
            dict["servings"] = servings
        }
        if let instructions = parsed.instructions {
            dict["instructions"] = instructions
        }
        
        return Recipe(from: dict)!
    }
    
    private static func convertToExtendedIngredient(_ parsed: ParsedIngredient, index: Int) -> ExtendedIngredient {
        // Parse amount and unit from imperial string
        let components = parsed.imperialAmount.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        var amount: Double = 0.0
        var unit = ""
        
        // Handle different formats:
        // "1 tsp." -> amount=1, unit="tsp."
        // "1/2 cup" -> amount=0.5, unit="cup"
        // "1½ tbsp." -> amount=1.5, unit="tbsp."
        if components.count >= 1 {
            if let fractionValue = parseFraction(components[0]) {
                amount = fractionValue
            }
            // Get unit (could be at index 1 or combined with number)
            if components.count >= 2 {
                unit = components[1...].joined(separator: " ")
            }
        }
        
        // Parse metric amount if available
        var metricAmount: Double?
        var metricUnit = ""
        if let metric = parsed.metricAmount {
            let metricComponents = metric.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            if metricComponents.count >= 1,
               let value = parseFraction(metricComponents[0]) {
                metricAmount = value
            }
            if metricComponents.count >= 2 {
                metricUnit = metricComponents[1...].joined(separator: " ")
            }
        }
        
        let usMeasure = Metric(
            amount: amount,
            unitShort: unit,
            unitLong: expandUnit(unit)
        )
        
        let metricMeasure = Metric(
            amount: metricAmount,
            unitShort: metricUnit,
            unitLong: expandUnit(metricUnit)
        )
        
        let measures = Measures(
            us: usMeasure,
            metric: metricMeasure
        )
        
        // Build original string for display
        var originalString = parsed.imperialAmount
        if !parsed.name.isEmpty {
            originalString += " \(parsed.name)"
        }
        if let metric = parsed.metricAmount {
            originalString += " (\(metric))"
        }
        
        return ExtendedIngredient(
            id: 10000 + index, // Use offset IDs for parsed ingredients
            aisle: nil,
            image: nil,
            consistency: .solid,
            name: parsed.name,
            nameClean: parsed.name.lowercased(),
            original: originalString,
            originalName: parsed.name,
            amount: amount,
            unit: unit,
            meta: [],
            measures: measures
        )
    }
    
    /// Expands abbreviated units to their full form
    private static func expandUnit(_ unit: String) -> String {
        let lower = unit.lowercased().replacingOccurrences(of: ".", with: "")
        switch lower {
        case "tsp": return "teaspoon"
        case "tbsp": return "tablespoon"
        case "oz": return "ounce"
        case "lb": return "pound"
        case "ml": return "milliliter"
        case "l": return "liter"
        case "g": return "gram"
        case "kg": return "kilogram"
        default: return unit
        }
    }
    
    private static func parseFraction(_ text: String) -> Double? {
        // Handle Unicode fractions
        let fractionMap: [Character: Double] = [
            "½": 0.5, "⅓": 0.333, "⅔": 0.667, "¼": 0.25,
            "¾": 0.75, "⅕": 0.2, "⅖": 0.4, "⅗": 0.6,
            "⅘": 0.8, "⅙": 0.167, "⅚": 0.833, "⅛": 0.125,
            "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
        ]
        
        if text.count == 1, let value = fractionMap[text.first!] {
            return value
        }
        
        // Handle slash fractions like "1/2"
        if text.contains("/") {
            let parts = text.split(separator: "/")
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]), denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Handle mixed numbers like "1½" or "1 1/2"
        let cleanText = text.replacingOccurrences(of: " ", with: "")
        for (char, value) in fractionMap {
            if cleanText.contains(char) {
                let wholeNumberPart = cleanText.replacingOccurrences(of: String(char), with: "")
                if let whole = Double(wholeNumberPart) {
                    return whole + value
                }
                return value
            }
        }
        
        // Try simple decimal or integer
        return Double(text)
    }
    
    private static func ingredientToDict(_ ingredient: ExtendedIngredient) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = ingredient.id
        dict["aisle"] = ingredient.aisle
        dict["image"] = ingredient.image
        dict["consistency"] = ingredient.consistency?.rawValue
        dict["name"] = ingredient.name
        dict["nameClean"] = ingredient.nameClean
        dict["original"] = ingredient.original
        dict["originalName"] = ingredient.originalName
        dict["amount"] = ingredient.amount
        dict["unit"] = ingredient.unit
        dict["meta"] = ingredient.meta
        
        if let measures = ingredient.measures {
            var measuresDict: [String: Any] = [:]
            if let us = measures.us {
                measuresDict["us"] = [
                    "amount": us.amount as Any,
                    "unitShort": us.unitShort as Any,
                    "unitLong": us.unitLong as Any
                ]
            }
            if let metric = measures.metric {
                measuresDict["metric"] = [
                    "amount": metric.amount as Any,
                    "unitShort": metric.unitShort as Any,
                    "unitLong": metric.unitLong as Any
                ]
            }
            dict["measures"] = measuresDict
        }
        
        return dict
    }
    
    // MARK: - RecipeModel Conversion (SwiftData)
    
    /// Convert a ParsedRecipe to a RecipeModel for SwiftData persistence
    static func convertToRecipeModel(_ parsed: ParsedRecipe) -> RecipeModel {
        // Parse servings to Int
        let servingsInt: Int? = {
            guard let servingsStr = parsed.servings else { return nil }
            // Extract first number from string
            let numbers = servingsStr.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            return Int(numbers)
        }()
        
        // Convert ParsedIngredients to ExtendedIngredients
        let extendedIngredients = parsed.ingredients.enumerated().map { index, parsedIng in
            convertToExtendedIngredient(parsedIng, index: index)
        }
        
        // Create the RecipeModel
        let recipe = RecipeModel(
            title: parsed.title.isEmpty ? "Untitled Recipe" : parsed.title,
            servings: servingsInt,
            creditsText: "Parsed from image", summary: nil,
            instructions: parsed.instructions
        )
        
        recipe.extendedIngredients = extendedIngredients
        
        return recipe
    }
}
