//
//  RecipeImageParser.swift
//  Recipe Image Parser
//
//  Uses Vision framework to extract and parse recipe data from images
//

import UIKit
@preconcurrency import Vision
import VisionKit

// MARK: - Parser Protocol

/// Protocol that all recipe image parsers must conform to
protocol RecipeImageParserProtocol {
    /// Unique identifier for this parser type
    var parserType: RecipeParserType { get }
    
    /// Human-readable name for this parser
    var displayName: String { get }
    
    /// Description of what types of recipes this parser handles best
    var description: String { get }
    
    /// Parse a recipe image and return the result
    func parseRecipeImage(_ image: UIImage, completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void)
}

// MARK: - Parser Types

enum RecipeParserType: String, Codable, CaseIterable {
    case tableFormat = "table_format"
    case standardText = "standard_text"
    case handwritten = "handwritten"
    case magazine = "magazine"
    
    var displayName: String {
        switch self {
        case .tableFormat: return "Table Format (Recipe Cards)"
        case .standardText: return "Standard Text Format"
        case .handwritten: return "Handwritten Recipes"
        case .magazine: return "Magazine/Cookbook Pages"
        }
    }
}

// MARK: - Supporting Types

/// Internal structure for holding parsed text before converting to ParsedRecipe
struct ParsedRecipeText {
    var title: String = ""
    var servings: String?
    var lines: [String] = []
    var instructions: String?
}

// MARK: - Table Format Recipe Parser (Default)

/// Parser optimized for table-format recipe cards with imperial/metric columns
/// Best for: Indian recipe cards, printed recipe cards with structured layouts
class TableFormatRecipeParser: RecipeImageParserProtocol {
    
    let parserType: RecipeParserType = .tableFormat
    let displayName: String = "Table Format Parser"
    let description: String = "Optimized for recipe cards with table layouts containing imperial and metric measurements in columns."
    
    // MARK: - Main Parsing Function
    
    func parseRecipeImage(_ image: UIImage, completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void) {
        guard let cgImage = image.cgImage else {
            print("❌ [TableFormatParser] Invalid image - no CGImage")
            completion(.failure(.invalidImage))
            return
        }
        
        print("📸 [TableFormatParser] Starting Vision text recognition...")
        print("   Image size: \(cgImage.width) x \(cgImage.height)")
        
        // Perform Vision processing on background queue
        // Don't use [weak self] here - the parser needs to stay alive for the duration
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 [TableFormatParser] Creating Vision request...")
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            print("🔍 [TableFormatParser] Vision request configured")
            print("   Recognition level: accurate")
            print("   Language correction: enabled")
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            print("🔍 [TableFormatParser] Handler created, about to perform request...")
            
            do {
                try handler.perform([request])
                print("✅ [TableFormatParser] Vision request performed successfully")
                
                guard let observations = request.results else {
                    print("❌ [TableFormatParser] Request results are nil")
                    completion(.failure(.noTextFound))
                    return
                }
                
                print("📊 [TableFormatParser] Got \(observations.count) observations")
                
                guard !observations.isEmpty else {
                    print("❌ [TableFormatParser] No text observations found (empty array)")
                    completion(.failure(.noTextFound))
                    return
                }
                
                print("📝 [TableFormatParser] Found \(observations.count) text observations")
                print("🔄 [TableFormatParser] Extracting text...")
                
                let parsedText = self.extractText(from: observations)
                print("🔄 [TableFormatParser] Building recipe...")
                let recipe = self.buildRecipe(from: parsedText)
                
                print("✅ [TableFormatParser] Recipe parsed successfully: '\(recipe.title)'")
                print("   Ingredients: \(recipe.ingredients.count)")
                completion(.success(recipe))
                
            } catch {
                print("❌ [TableFormatParser] Vision error: \(error)")
                print("   Error type: \(type(of: error))")
                print("   Description: \(error.localizedDescription)")
                completion(.failure(.visionError(error)))
            }
        }
    }
    
    // MARK: - Text Extraction
    
    private nonisolated func extractText(from observations: [VNRecognizedTextObservation]) -> ParsedRecipeText {
        var parsed = ParsedRecipeText()
        
        // Sort observations by vertical position (top to bottom)
        let sortedObservations = observations.sorted { obs1, obs2 in
            obs1.boundingBox.origin.y > obs2.boundingBox.origin.y
        }
        
        var allLines: [String] = []
        
        for observation in sortedObservations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                allLines.append(text)
            }
        }
        
        // Debug: Print all extracted lines
        print("📝 [OCR] Extracted \(allLines.count) lines:")
        for (index, line) in allLines.enumerated() {
            print("   Line \(index): \"\(line)\"")
        }
        
        // Parse structure
        if let firstLine = allLines.first {
            parsed.title = firstLine
        }
        
        // Look for servings/makes line (second line usually)
        if allLines.count > 1 {
            let secondLine = allLines[1]
            if secondLine.lowercased().contains("makes") || 
               secondLine.lowercased().contains("serves") ||
               secondLine.lowercased().contains("quart") {
                parsed.servings = secondLine
                parsed.lines = Array(allLines.dropFirst(2))
            } else {
                parsed.lines = Array(allLines.dropFirst())
            }
        }
        
        // Separate ingredients from other sections
        // Stop parsing ingredients when we hit section markers
        if let variationsIndex = parsed.lines.firstIndex(where: { 
            $0.lowercased().contains("variations:") || 
            $0.lowercased().contains("variation:") 
        }) {
            // Everything after "Variations:" is not an ingredient
            parsed.instructions = parsed.lines[variationsIndex...].joined(separator: "\n")
            parsed.lines = Array(parsed.lines[..<variationsIndex])
            print("📋 [OCR] Found variations section at line \(variationsIndex)")
        }
        
        // Find where instructions begin (look for common instruction starters)
        var instructionStartIndex: Int?
        for (index, line) in parsed.lines.enumerated() {
            let lower = line.lowercased()
            if lower.hasPrefix("blend ") || lower.hasPrefix("cut ") || 
               lower.hasPrefix("heat ") || lower.hasPrefix("soak ") ||
               lower.hasPrefix("marinate ") || lower.hasPrefix("keeps ") ||
               (lower.contains("refrigerator") && lower.contains("time")) {
                instructionStartIndex = index
                break
            }
        }
        
        if let startIndex = instructionStartIndex {
            let instructionLines = parsed.lines[startIndex...]
            if let existingInstructions = parsed.instructions {
                parsed.instructions = instructionLines.joined(separator: "\n") + "\n" + existingInstructions
            } else {
                parsed.instructions = instructionLines.joined(separator: "\n")
            }
            parsed.lines = Array(parsed.lines[..<startIndex])
            print("📋 [OCR] Found instructions starting at line \(startIndex)")
        }
        
        return parsed
    }
    
    // MARK: - Recipe Building
    
    private nonisolated func buildRecipe(from parsed: ParsedRecipeText) -> ParsedRecipe {
        // Separate ingredients from instructions
        var ingredientLines: [String] = []
        var instructionLines: [String] = []
        
        for line in parsed.lines {
            if isInstructionLine(line) {
                instructionLines.append(line)
            } else {
                ingredientLines.append(line)
            }
        }
        
        let ingredients = parseIngredients(from: ingredientLines)
        
        // Combine all instructions into one string
        var allInstructions = instructionLines.joined(separator: "\n")
        if let existingInstructions = parsed.instructions {
            if !allInstructions.isEmpty {
                allInstructions += "\n" + existingInstructions
            } else {
                allInstructions = existingInstructions
            }
        }
        
        return ParsedRecipe(
            title: parsed.title,
            servings: parsed.servings,
            ingredients: ingredients,
            instructions: allInstructions.isEmpty ? nil : allInstructions
        )
    }
    
    // MARK: - Ingredient Parsing
    
    private nonisolated func parseIngredients(from lines: [String]) -> [ParsedIngredient] {
        print("🥘 [Parser] Parsing \(lines.count) potential ingredient lines")
        
        // First, try to intelligently combine lines that form a single ingredient
        let combinedLines = combineIngredientLines(lines)
        
        var ingredients: [ParsedIngredient] = []
        
        for line in combinedLines {
            // Check if this line looks like instructions rather than an ingredient
            if isInstructionLine(line) {
                print("   ⏭️  Skipping instruction line: \"\(line)\"")
                continue
            }
            
            // Try to parse multiple ingredients from a single line (for table formats)
            let parsedIngredients = parseIngredientLine(line)
            if parsedIngredients.isEmpty {
                print("   ❌ Could not parse: \"\(line)\"")
            } else {
                for ingredient in parsedIngredients {
                    print("   ✅ Parsed: \(ingredient.imperialAmount) \(ingredient.name) [\(ingredient.metricAmount ?? "no metric")]")
                }
            }
            ingredients.append(contentsOf: parsedIngredients)
        }
        
        print("🥘 [Parser] Total ingredients parsed: \(ingredients.count)")
        
        return ingredients
    }
    
    /// Combines lines that are part of the same ingredient (e.g., amount on one line, name on next)
    private nonisolated func combineIngredientLines(_ lines: [String]) -> [String] {
        var combined: [String] = []
        var i = 0
        
        print("🔄 [Parser] Combining split ingredient lines...")
        
        while i < lines.count {
            let line = lines[i]
            
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                i += 1
                continue
            }
            
            // Check if this line is just a measurement/amount
            if isJustMeasurement(line) && i + 1 < lines.count {
                let nextLine = lines[i + 1]
                
                // If next line is also a measurement, keep them separate
                if isJustMeasurement(nextLine) {
                    combined.append(line)
                    i += 1
                } else {
                    // Combine measurement with next line
                    let combinedLine = "\(line) \(nextLine)"
                    print("   📎 Combined: \"\(line)\" + \"\(nextLine)\" → \"\(combinedLine)\"")
                    combined.append(combinedLine)
                    i += 2
                    continue
                }
            }
            // Check if this line is just an ingredient name without amount
            else if !startsWithAmount(line) && i > 0 {
                let prevLine = lines[i - 1]
                // Check if we already used the previous line
                if !combined.isEmpty && combined.last == prevLine {
                    // Already combined, just add this line
                    combined.append(line)
                } else if isJustMeasurement(prevLine) {
                    // This shouldn't happen if we caught it above, but safety check
                    combined.append(line)
                } else {
                    combined.append(line)
                }
                i += 1
            } else {
                combined.append(line)
                i += 1
            }
        }
        
        print("🔄 [Parser] Combined \(lines.count) lines into \(combined.count) ingredient entries")
        return combined
    }
    
    /// Checks if a line is just a measurement without an ingredient name
    private nonisolated func isJustMeasurement(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        // Check for patterns like:
        // "2 tsp."
        // "10 mL"
        // "1 cup"
        // "1-2"
        
        if components.isEmpty { return false }
        
        // If it's just a number or measurement
        if components.count == 1 {
            return isAmount(components[0]) || isUnit(components[0])
        }
        
        // If it's amount + unit only (2 components)
        if components.count == 2 {
            return isAmount(components[0]) && isUnit(components[1])
        }
        
        // If it's amount + unit + maybe another amount (for ranges like "1-2 tsp.")
        if components.count == 3 {
            let hasAmount = isAmount(components[0])
            let hasUnit = isUnit(components[1]) || isUnit(components[2])
            let lastIsAmount = isAmount(components[2])
            return hasAmount && (hasUnit || lastIsAmount)
        }
        
        return false
    }
    
    /// Checks if a line starts with an amount (number, fraction, etc.)
    private nonisolated func startsWithAmount(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstComponent = trimmed.components(separatedBy: .whitespaces).first else {
            return false
        }
        return isAmount(firstComponent)
    }
    
    private nonisolated func isInstructionLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        
        // Keywords that indicate instruction lines
        let instructionKeywords = ["quarter", "chop", "slice", "sprinkle", "add", "mix", 
                                   "combine", "blend", "let cool", "remove", "boil", 
                                   "heat", "stir", "cook", "bake", "set aside", "cut",
                                   "soak", "marinate", "drain", "fill", "top with",
                                   "rub in", "keep", "refrigerat", "discard", "place on"]
        
        // Common instruction sentence starters
        let instructionStarters = ["blend all", "cut ", "heat ", "soak ", "marinate ",
                                   "drain ", "when all", "set aside", "fill ", "this ",
                                   "keeps in", "see photo"]
        
        // Check if line starts with instruction keywords
        for starter in instructionStarters {
            if lower.hasPrefix(starter) {
                return true
            }
        }
        
        // Check if line contains instruction keywords
        return instructionKeywords.contains { lower.contains($0) }
    }
    
    private nonisolated func parseIngredientLine(_ line: String) -> [ParsedIngredient] {
        // Pattern: "amount unit ingredient metric_amount metric_unit"
        // Examples:
        // "1 tsp. chilli powder 5 mL"
        // "2 lbs. lemons 1 kg 6 cups sugar 1.5 L" (multiple ingredients in one line)
        
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var ingredients: [ParsedIngredient] = []
        
        // Split into components
        let components = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        guard components.count >= 2 else { return [] }
        
        // Find all positions that could be the start of a new ingredient
        // (numbers or fractions at the beginning or after we've seen a complete ingredient)
        var ingredientStarts: [Int] = [0] // First ingredient always starts at 0
        
        for (index, component) in components.enumerated() {
            if index == 0 { continue }
            
            // Check if this looks like an amount (number or fraction)
            if isAmount(component) {
                // Make sure there's enough room for a valid ingredient after this
                if index + 1 < components.count {
                    ingredientStarts.append(index)
                }
            }
        }
        
        // Parse each ingredient segment
        for i in 0..<ingredientStarts.count {
            let startIndex = ingredientStarts[i]
            let endIndex = i + 1 < ingredientStarts.count ? ingredientStarts[i + 1] : components.count
            
            let ingredientComponents = Array(components[startIndex..<endIndex])
            
            if let ingredient = parseSingleIngredient(ingredientComponents) {
                ingredients.append(ingredient)
            }
        }
        
        return ingredients
    }
    
    private nonisolated func parseSingleIngredient(_ components: [String]) -> ParsedIngredient? {
        guard !components.isEmpty else { return nil }
        
        // Handle special case: ingredient without amount (e.g., "salt, to taste")
        if components.count == 1 || !isAmount(components[0]) {
            let ingredientName = components.joined(separator: " ")
            return ParsedIngredient(
                imperialAmount: "to taste",
                name: cleanIngredientName(ingredientName),
                metricAmount: nil
            )
        }
        
        guard components.count >= 2 else { return nil }
        
        // Find where metric measurements start (if any)
        var metricStartIndex: Int?
        
        for (index, component) in components.enumerated() {
            if index < 2 { continue } // Skip the first amount/unit
            
            // Look for metric indicators
            if component.contains("mL") || component.contains("ml") || 
               component.contains("L") || component.contains("g") || 
               component.contains("kg") {
                // Check if previous component is a number
                if index > 0, isAmount(components[index - 1]) {
                    metricStartIndex = index - 1
                    break
                }
                // Or this component starts with a number
                if isAmount(String(component.prefix(while: { $0.isNumber || $0 == "." || $0 == "," }))) {
                    metricStartIndex = index
                    break
                }
            }
            // Look for parentheses containing metric (e.g., "(125 mL)")
            else if component.hasPrefix("(") {
                metricStartIndex = index
                break
            }
            // Look for standalone numbers after we have amount + unit + name
            else if index >= 3, isAmount(component) {
                metricStartIndex = index
                break
            }
        }
        
        var imperialAmount = ""
        var ingredientName = ""
        var metricAmount: String?
        
        // Determine imperial amount (first 1-2 components)
        let firstComponent = components[0]
        var imperialEndIndex = 1
        
        if components.count > 1 {
            let secondComponent = components[1]
            // Check if second component is a unit
            if isUnit(secondComponent) {
                imperialAmount = "\(firstComponent) \(secondComponent)"
                imperialEndIndex = 2
            } else {
                imperialAmount = firstComponent
                imperialEndIndex = 1
            }
        } else {
            imperialAmount = firstComponent
        }
        
        // Determine ingredient name and metric
        if let metricIndex = metricStartIndex {
            // Ingredient name is between imperial and metric
            if metricIndex > imperialEndIndex {
                let nameComponents = Array(components[imperialEndIndex..<metricIndex])
                ingredientName = nameComponents.joined(separator: " ")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
            }
            
            // Metric is from metricIndex to end (or until we hit certain keywords)
            var metricEndIndex = components.count
            for (idx, comp) in components[metricIndex...].enumerated() {
                let lower = comp.lowercased()
                if lower == "or" || lower == "to" || lower.hasPrefix("chopped") {
                    metricEndIndex = metricIndex + idx
                    break
                }
            }
            
            let metricComponents = Array(components[metricIndex..<metricEndIndex])
            metricAmount = metricComponents.joined(separator: " ")
                .trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
        } else {
            // No metric - everything after imperial is the name
            if components.count > imperialEndIndex {
                let nameComponents = Array(components[imperialEndIndex...])
                ingredientName = nameComponents.joined(separator: " ")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
            }
        }
        
        // Clean up ingredient name
        ingredientName = cleanIngredientName(ingredientName)
        
        guard !imperialAmount.isEmpty, !ingredientName.isEmpty else { return nil }
        
        return ParsedIngredient(
            imperialAmount: imperialAmount,
            name: ingredientName,
            metricAmount: metricAmount
        )
    }
    
    private nonisolated func cleanIngredientName(_ name: String) -> String {
        var cleaned = name
        
        // Remove modifiers that should be separate
        let modifiersToRemove = [
            ", or to taste",
            " or to taste",
            ", to taste",
            " to taste",
            "*"
        ]
        
        for modifier in modifiersToRemove {
            cleaned = cleaned.replacingOccurrences(of: modifier, with: "")
        }
        
        // Handle "OR" alternatives (e.g., "chopped OR garlic powder")
        if cleaned.uppercased().contains(" OR ") {
            // Take the first option before "OR"
            if let orRange = cleaned.range(of: " OR ", options: .caseInsensitive) {
                cleaned = String(cleaned[..<orRange.lowerBound])
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private nonisolated func isAmount(_ text: String) -> Bool {
        // Check if text looks like an amount (number, fraction, or starts with a number)
        let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
        
        // Check for fractions
        if trimmed.contains("/") { return true }
        if trimmed.contains("½") || trimmed.contains("¼") || trimmed.contains("¾") ||
           trimmed.contains("⅓") || trimmed.contains("⅔") || trimmed.contains("⅛") { return true }
        
        // Check if it's a number
        if Double(trimmed) != nil { return true }
        
        // Check if it starts with a number
        if let firstChar = trimmed.first, firstChar.isNumber { return true }
        
        return false
    }
    
    private nonisolated func isUnit(_ text: String) -> Bool {
        let lower = text.lowercased().replacingOccurrences(of: ".", with: "")
        let units = ["tsp", "tbsp", "tablespoon", "teaspoon", "cup", "cups",
                     "oz", "ounce", "ounces", "lb", "lbs", "pound", "pounds",
                     "ml", "mL", "l", "L", "g", "kg", "gram", "grams",
                     "kilogram", "kilograms", "liter", "liters", "litre", "litres",
                     "bunch", "bunches", "quart", "quarts", "qt", "qts"]
        
        return units.contains { lower.hasPrefix($0) || lower == $0 }
    }
}

// MARK: - Parser Factory

/// Factory for creating recipe parsers
class RecipeParserFactory {
    
    /// Get a parser for a specific type
    static func parser(for type: RecipeParserType) -> RecipeImageParserProtocol {
        switch type {
        case .tableFormat:
            return TableFormatRecipeParser()
        case .standardText, .handwritten, .magazine:
            // For now, use table format as default
            // TODO: Implement specific parsers for these types
            return TableFormatRecipeParser()
        }
    }
    
    /// Get the default parser (table format for recipe cards)
    static var defaultParser: RecipeImageParserProtocol {
        return TableFormatRecipeParser()
    }
    
    /// Get all available parser types
    static var availableParsers: [RecipeParserType] {
        return [.tableFormat]
        // As you implement more parsers, add them here:
        // return [.tableFormat, .standardText, .handwritten, .magazine]
    }
}

// MARK: - Backward Compatibility

/// Alias for backward compatibility with existing code
/// Use RecipeParserFactory.defaultParser or TableFormatRecipeParser() instead for new code
typealias RecipeImageParser = TableFormatRecipeParser

// MARK: - Error Types

enum RecipeParserError: Error, LocalizedError {
    case invalidImage
    case visionError(Error)
    case noTextFound
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or cannot be processed."
        case .visionError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        case .noTextFound:
            return "No text was found in the image."
        case .parsingFailed:
            return "Failed to parse recipe from extracted text."
        }
    }
}
