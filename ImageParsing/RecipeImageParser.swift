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
class TableFormatRecipeParser: RecipeImageParserProtocol, @unchecked Sendable {
    
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
        
        // Resize image if needed to prevent Vision framework hangs
        let processedImage = resizeImageIfNeeded(image)
        guard let processedCGImage = processedImage.cgImage else {
            print("❌ [TableFormatParser] Failed to get CGImage from resized image")
            completion(.failure(.invalidImage))
            return
        }
        
        if processedImage !== image {
            print("📐 [TableFormatParser] Image resized to: \(processedCGImage.width) x \(processedCGImage.height)")
        }
        
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
            
            let handler = VNImageRequestHandler(cgImage: processedCGImage, options: [:])
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
    
    /// Resizes image if it exceeds maximum dimensions to prevent Vision framework hangs
    /// Uses 512px max to keep memory usage low while maintaining OCR accuracy
    private nonisolated func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat = 512) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        // If image is already small enough, return it as-is
        guard maxSize > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxDimension / maxSize
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    // MARK: - Text Extraction
    
    /// Groups text observations that appear on the same horizontal line
    /// This is crucial for table-format recipes where columns get read separately
    private nonisolated func groupObservationsByRow(_ observations: [VNRecognizedTextObservation]) -> [[VNRecognizedTextObservation]] {
        // Group observations that have similar Y coordinates (within a threshold)
        // Use the height of text boxes to determine threshold - more adaptive than fixed percentage
        let sortedByY = observations.sorted { obs1, obs2 in
            obs1.boundingBox.origin.y > obs2.boundingBox.origin.y
        }
        
        // Calculate average text height for adaptive threshold
        let avgHeight = observations.map { $0.boundingBox.height }.reduce(0, +) / CGFloat(observations.count)
        let verticalThreshold = avgHeight * 0.75 // 75% of average text height
        
        print("📏 [OCR] Average text height: \(String(format: "%.4f", avgHeight)), threshold: \(String(format: "%.4f", verticalThreshold))")
        
        var rows: [[VNRecognizedTextObservation]] = []
        
        for observation in sortedByY {
            let currentY = observation.boundingBox.origin.y
            let currentHeight = observation.boundingBox.height
            
            // Try to find an existing row this observation belongs to
            var foundRow = false
            for (index, row) in rows.enumerated() {
                // Check if this observation overlaps vertically with any observation in this row
                // Use the midpoint of the bounding box for better accuracy
                if let firstInRow = row.first {
                    let rowY = firstInRow.boundingBox.origin.y
                    let rowHeight = firstInRow.boundingBox.height
                    let rowMidpoint = rowY + (rowHeight / 2)
                    let currentMidpoint = currentY + (currentHeight / 2)
                    
                    // Check if midpoints are close enough
                    if abs(currentMidpoint - rowMidpoint) < verticalThreshold {
                        rows[index].append(observation)
                        foundRow = true
                        break
                    }
                }
            }
            
            // If not found, create a new row
            if !foundRow {
                rows.append([observation])
            }
        }
        
        print("🔲 [OCR] Grouped \(observations.count) observations into \(rows.count) rows")
        
        return rows
    }
    
    private nonisolated func extractText(from observations: [VNRecognizedTextObservation]) -> ParsedRecipeText {
        var parsed = ParsedRecipeText()
        
        // First, group observations by their vertical position (same row)
        let groupedByRow = groupObservationsByRow(observations)
        
        // Convert each row group to a single line of text
        var allLines: [String] = []
        
        for rowObservations in groupedByRow {
            // Sort by horizontal position (left to right)
            let sortedByX = rowObservations.sorted { obs1, obs2 in
                obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
            }
            
            // Combine text from this row
            let rowTexts = sortedByX.compactMap { observation -> String? in
                guard let topCandidate = observation.topCandidates(1).first else { return nil }
                let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }
            
            if !rowTexts.isEmpty {
                // Join with space to create a single line
                allLines.append(rowTexts.joined(separator: " "))
            }
        }
        
        // Debug: Print all extracted lines
        print("📝 [OCR] Extracted \(allLines.count) lines (grouped by row):")
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
        
        // Join all components to check for complex metric formats
        let fullText = components.joined(separator: " ")
        
        // Handle special case: ingredient without amount (e.g., "salt, to taste")
        if components.count == 1 || !isAmount(components[0]) {
            let ingredientName = cleanIngredientName(fullText)
            return ParsedIngredient(
                imperialAmount: "to taste",
                name: ingredientName,
                metricAmount: nil
            )
        }
        
        guard components.count >= 2 else { return nil }
        
        // First, try to extract metric using specialized patterns
        var extractedMetric: String?
        if containsMetricUnits(fullText) {
            extractedMetric = extractMetricMeasurement(fullText)
            if let metric = extractedMetric {
                print("   📐 Extracted metric: '\(metric)' from '\(fullText)'")
            }
        }
        
        // Strategy: Find all measurement clusters (amount + optional unit)
        // Then determine which is imperial and which is metric
        var measurementClusters: [(startIndex: Int, endIndex: Int, text: String)] = []
        var i = 0
        
        while i < components.count {
            if isAmount(components[i]) {
                var clusterEnd = i + 1
                // Check if next component is a unit
                if clusterEnd < components.count && isUnit(components[clusterEnd]) {
                    clusterEnd += 1
                }
                
                let clusterText = Array(components[i..<clusterEnd]).joined(separator: " ")
                measurementClusters.append((startIndex: i, endIndex: clusterEnd, text: clusterText))
                i = clusterEnd
            } else {
                i += 1
            }
        }
        
        print("   🔍 Found \(measurementClusters.count) measurement cluster(s) in: \(components.joined(separator: " "))")
        
        var imperialAmount = ""
        var ingredientName = ""
        var metricAmount: String?
        var imperialEndIndex = 0
        var metricStartIndex: Int?
        
        if measurementClusters.isEmpty {
            // No measurements found - treat entire thing as ingredient name
            ingredientName = fullText
            imperialAmount = "to taste"
        } else if measurementClusters.count == 1 {
            // Only one measurement - it's the imperial amount
            let cluster = measurementClusters[0]
            imperialAmount = cluster.text
            imperialEndIndex = cluster.endIndex
            
            // Everything after is the ingredient name (minus any extracted metric)
            if imperialEndIndex < components.count {
                var nameComponents = Array(components[imperialEndIndex...])
                let namePart = nameComponents.joined(separator: " ")
                
                // If we extracted metric earlier, remove it from name
                if let metric = extractedMetric {
                    ingredientName = namePart.replacingOccurrences(of: metric, with: "")
                    metricAmount = metric
                } else {
                    ingredientName = namePart
                }
            }
        } else {
            // Multiple measurements - first is imperial, determine which is metric
            let firstCluster = measurementClusters[0]
            imperialAmount = firstCluster.text
            imperialEndIndex = firstCluster.endIndex
            
            // Use extracted metric if available, otherwise look for metric among clusters
            if let metric = extractedMetric {
                metricAmount = metric
                
                // Find where metric starts to properly extract ingredient name
                for cluster in measurementClusters.dropFirst() {
                    if cluster.text.contains("mL") || cluster.text.contains("ml") ||
                       cluster.text.contains("L") || cluster.text.contains("g") ||
                       cluster.text.contains("kg") {
                        metricStartIndex = cluster.startIndex
                        break
                    }
                }
            } else {
                // Look for metric among remaining clusters
                for cluster in measurementClusters.dropFirst() {
                    // Check if this cluster contains metric units
                    let hasMetricUnit = cluster.text.contains("mL") || cluster.text.contains("ml") ||
                                       cluster.text.contains("L") || cluster.text.contains("g") ||
                                       cluster.text.contains("kg")
                    
                    // Or if it's in parentheses
                    let inParentheses = cluster.startIndex < components.count &&
                                       components[cluster.startIndex].hasPrefix("(")
                    
                    // Or if the first cluster has imperial units and this doesn't
                    let firstHasImperialUnit = firstCluster.text.contains("tsp") || 
                                              firstCluster.text.contains("tbsp") ||
                                              firstCluster.text.contains("cup") ||
                                              firstCluster.text.contains("oz") ||
                                              firstCluster.text.contains("lb")
                    
                    if hasMetricUnit || inParentheses || (firstHasImperialUnit && cluster.startIndex > imperialEndIndex) {
                        metricStartIndex = cluster.startIndex
                        
                        // Extract metric measurement
                        var metricEndIdx = cluster.endIndex
                        // Include everything up to next non-measurement component
                        while metricEndIdx < components.count {
                            let comp = components[metricEndIdx]
                            if comp.lowercased() == "or" || comp.lowercased() == "to" {
                                break
                            }
                            if isAmount(comp) || isUnit(comp) || comp.contains("mL") || comp.contains("g") {
                                metricEndIdx += 1
                            } else {
                                break
                            }
                        }
                        
                        let metricComponents = Array(components[cluster.startIndex..<metricEndIdx])
                        metricAmount = metricComponents.joined(separator: " ")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
                        break
                    }
                }
            }
            
            // Ingredient name is between imperial and metric (or after imperial if no metric)
            if let metricIdx = metricStartIndex {
                if metricIdx > imperialEndIndex {
                    let nameComponents = Array(components[imperialEndIndex..<metricIdx])
                    ingredientName = nameComponents.joined(separator: " ")
                }
            } else {
                // No metric found - everything after imperial is the name
                if imperialEndIndex < components.count {
                    let nameComponents = Array(components[imperialEndIndex...])
                    ingredientName = nameComponents.joined(separator: " ")
                }
            }
        }
        
        // Clean up ingredient name
        ingredientName = cleanIngredientName(ingredientName).trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
        
        // If no ingredient name found, it might be all measurements - skip this
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
        
        // Remove common preparation instructions that sometimes get included
        let preparationPatterns = [
            "peeled and",
            "washed and",
            "diced",
            "chopped", 
            "sliced",
            "minced",
            "crushed",
            "grated",
            "shredded",
            "finely",
            "coarsely",
            "roughly",
            "fresh",
            "dried",
            "ground"
        ]
        
        // Only remove these if they appear at the end or in parentheses
        for pattern in preparationPatterns {
            // Remove if in parentheses: "tomatoes (diced)"
            let parenthesesPattern = " \\(\(pattern)[^)]*\\)"
            cleaned = cleaned.replacingOccurrences(
                of: parenthesesPattern,
                with: "",
                options: .regularExpression
            )
            
            // Keep patterns that are part of the ingredient name (e.g., "ground beef", "fresh coriander")
            // Only remove if followed by "and" or at the very end as a modifier
            let modifierPattern = ",\\s*\(pattern)\\s*$"
            cleaned = cleaned.replacingOccurrences(
                of: modifierPattern,
                with: "",
                options: .regularExpression
            )
        }
        
        // Handle multi-line descriptions by keeping only the main ingredient
        // Remove text after common delimiters that indicate preparation steps
        let delimiters = [" (see ", " - ", " – "]
        for delimiter in delimiters {
            if let range = cleaned.range(of: delimiter, options: .caseInsensitive) {
                cleaned = String(cleaned[..<range.lowerBound])
            }
        }
        
        // Clean up extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private nonisolated func isAmount(_ text: String) -> Bool {
        // Check if text looks like an amount (number, fraction, range, or starts with a number)
        let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "(),"))
        
        // Check for fractions (Unicode and ASCII)
        if trimmed.contains("/") { return true }
        if trimmed.contains("½") || trimmed.contains("¼") || trimmed.contains("¾") ||
           trimmed.contains("⅓") || trimmed.contains("⅔") || trimmed.contains("⅛") ||
           trimmed.contains("⅜") || trimmed.contains("⅝") || trimmed.contains("⅞") { return true }
        
        // Check for ranges (e.g., "1-2", "1–2", "1 to 2", "1•2")
        let rangePattern = "^\\d+[-–•]\\d+"
        if trimmed.range(of: rangePattern, options: .regularExpression) != nil {
            return true
        }
        
        // Check if it's a decimal number (e.g., "1.5", "0.25")
        if Double(trimmed) != nil { return true }
        
        // Check if it starts with a number (e.g., "2cups", "10mL")
        if let firstChar = trimmed.first, firstChar.isNumber { return true }
        
        // Check for parentheses with numbers (e.g., "(250-375")
        let parenNumberPattern = "\\(?\\d+"
        if trimmed.range(of: parenNumberPattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private nonisolated func isUnit(_ text: String) -> Bool {
        let lower = text.lowercased().replacingOccurrences(of: ".", with: "")
        
        // Remove parentheses for checking
        let cleaned = lower.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        
        let units = ["tsp", "tbsp", "tablespoon", "teaspoon", "cup", "cups",
                     "oz", "ounce", "ounces", "lb", "lbs", "pound", "pounds",
                     "ml", "mL", "l", "L", "g", "kg", "gram", "grams",
                     "kilogram", "kilograms", "liter", "liters", "litre", "litres",
                     "bunch", "bunches", "quart", "quarts", "qt", "qts",
                     "pinch", "dash", "clove", "cloves", "sprig", "sprigs"]
        
        return units.contains { cleaned.hasPrefix($0) || cleaned == $0 }
    }
    
    /// Checks if a string contains metric measurements
    private nonisolated func containsMetricUnits(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("ml") || lower.contains("mL") ||
               lower.contains(" l") || lower.contains("(l") ||
               lower.contains(" g") || lower.contains("(g") ||
               lower.contains("kg")
    }
    
    /// Extracts metric measurement from complex formats like "(250-375 mL)" or "1 cup/250 mL"
    private nonisolated func extractMetricMeasurement(_ text: String) -> String? {
        // Pattern 1: Parentheses format "(250 mL)" or "(250-375 mL)"
        let parenPattern = "\\(([^)]*(?:mL|ml|L|g|kg)[^)]*)\\)"
        if let range = text.range(of: parenPattern, options: .regularExpression) {
            let match = String(text[range])
            return match.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        }
        
        // Pattern 2: Slash format "1 cup/250 mL" or "2 tbsp/30 mL"
        let slashPattern = "/\\s*([\\d.-]+\\s*(?:mL|ml|L|g|kg))"
        if let range = text.range(of: slashPattern, options: .regularExpression) {
            let match = String(text[range])
            return match.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        }
        
        // Pattern 3: Standalone metric after imperial "2 tsp 10 mL"
        // Extract everything from first metric unit onwards
        if let mlRange = text.range(of: "\\d+[\\d.-]*\\s*(?:mL|ml)", options: .regularExpression) {
            return String(text[mlRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
        }
        
        if let gRange = text.range(of: "\\d+[\\d.-]*\\s*(?:g|kg)", options: .regularExpression) {
            return String(text[gRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
        }
        
        if let lRange = text.range(of: "\\d+[\\d.-]*\\s*L", options: .regularExpression) {
            return String(text[lRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
        }
        
        return nil
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
