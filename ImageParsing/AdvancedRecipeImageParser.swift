//
//  AdvancedRecipeImageParser.swift
//  Recipe Image Parser
//
//  Enhanced parser with spatial layout analysis for multi-column recipe cards
//

import UIKit
@preconcurrency import Vision

class AdvancedRecipeImageParser {
    
    // MARK: - Structured Text Recognition
    
    struct RecognizedTextElement {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
        
        var centerX: CGFloat { boundingBox.midX }
        var centerY: CGFloat { boundingBox.midY }
    }
    
    // MARK: - Main Parsing Function
    
    func parseRecipeImage(_ image: UIImage, completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(.visionError(error)))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(.noTextFound))
                return
            }
            
            let elements = self.extractTextElements(from: observations)
            let recipe = self.buildRecipeFromSpatialLayout(elements: elements)
            completion(.success(recipe))
        }
        
        // Configure for accurate text recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(.visionError(error)))
            }
        }
    }
    
    // MARK: - Text Element Extraction
    
    private func extractTextElements(from observations: [VNRecognizedTextObservation]) -> [RecognizedTextElement] {
        var elements: [RecognizedTextElement] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !text.isEmpty {
                elements.append(RecognizedTextElement(
                    text: text,
                    boundingBox: observation.boundingBox,
                    confidence: topCandidate.confidence
                ))
            }
        }
        
        return elements
    }
    
    // MARK: - Spatial Layout Analysis
    
    private func buildRecipeFromSpatialLayout(elements: [RecognizedTextElement]) -> ParsedRecipe {
        // Sort by Y position (top to bottom) - remember Vision uses bottom-left origin
        let sortedElements = elements.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
        
        guard !sortedElements.isEmpty else {
            return ParsedRecipe(title: "Untitled Recipe", servings: nil, ingredients: [], instructions: nil)
        }
        
        // Extract title (first element)
        let title = sortedElements[0].text
        
        // Find servings/yield line
        var servings: String?
        var ingredientStartIndex = 1
        
        if sortedElements.count > 1 {
            let secondLine = sortedElements[1].text
            if secondLine.lowercased().contains("makes") ||
               secondLine.lowercased().contains("serves") ||
               (secondLine.lowercased().contains("cup") && 
                (secondLine.contains("½") || secondLine.contains("1/"))) {
                servings = secondLine
                ingredientStartIndex = 2
            }
        }
        
        // Find instructions (last line with instruction keywords)
        var instructions: String?
        var ingredientEndIndex = sortedElements.count
        
        if let lastElement = sortedElements.last,
           lastElement.text.lowercased().contains("combine") ||
           lastElement.text.lowercased().contains("mix") ||
           lastElement.text.lowercased().contains("blend") ||
           lastElement.text.lowercased().contains("thoroughly") {
            instructions = lastElement.text
            ingredientEndIndex = sortedElements.count - 1
        }
        
        // Extract ingredient elements
        let ingredientElements = Array(sortedElements[ingredientStartIndex..<ingredientEndIndex])
        
        // Group into rows and columns
        let ingredients = parseIngredientsWithSpatialLayout(elements: ingredientElements)
        
        return ParsedRecipe(
            title: title,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions
        )
    }
    
    // MARK: - Ingredient Parsing with Spatial Layout
    
    private func parseIngredientsWithSpatialLayout(elements: [RecognizedTextElement]) -> [ParsedIngredient] {
        // Detect if we have a two-column layout by analyzing X positions
        let xPositions = elements.map { $0.centerX }
        let avgX = xPositions.reduce(0, +) / CGFloat(xPositions.count)
        
        // Separate left and right columns
        let leftColumn = elements.filter { $0.centerX < avgX }.sorted { $0.centerY > $1.centerY }
        let rightColumn = elements.filter { $0.centerX >= avgX }.sorted { $0.centerY > $1.centerY }
        
        var ingredients: [ParsedIngredient] = []
        
        // Process left column
        ingredients.append(contentsOf: parseColumnIngredients(leftColumn))
        
        // Process right column
        ingredients.append(contentsOf: parseColumnIngredients(rightColumn))
        
        return ingredients
    }
    
    private func parseColumnIngredients(_ elements: [RecognizedTextElement]) -> [ParsedIngredient] {
        var ingredients: [ParsedIngredient] = []
        
        // Group elements into rows (elements at similar Y positions form one ingredient)
        var currentRow: [RecognizedTextElement] = []
        var lastY: CGFloat?
        let yThreshold: CGFloat = 0.02 // 2% of image height tolerance
        
        for element in elements {
            if let prevY = lastY, abs(element.centerY - prevY) > yThreshold {
                // New row detected - process the previous row
                if let ingredient = parseIngredientRow(currentRow) {
                    ingredients.append(ingredient)
                }
                currentRow = [element]
            } else {
                currentRow.append(element)
            }
            lastY = element.centerY
        }
        
        // Process last row
        if let ingredient = parseIngredientRow(currentRow) {
            ingredients.append(ingredient)
        }
        
        return ingredients
    }
    
    private func parseIngredientRow(_ row: [RecognizedTextElement]) -> ParsedIngredient? {
        guard !row.isEmpty else { return nil }
        
        // Sort row elements by X position (left to right)
        let sortedRow = row.sorted { $0.centerX < $1.centerX }
        
        // Typical pattern: [amount] [unit] [name] [metric_amount] [metric_unit]
        var imperialAmount = ""
        var ingredientName = ""
        var metricAmount: String?
        
        // Find metric unit indicator
        var metricStartIndex: Int?
        for (index, element) in sortedRow.enumerated() {
            let text = element.text
            if text.contains("mL") || text.contains("ml") || 
               text.contains("L") || text.contains("g") || text.contains("kg") {
                // Look back one element for the number
                if index > 0 {
                    metricStartIndex = index - 1
                } else {
                    metricStartIndex = index
                }
                break
            }
        }
        
        if let metricIndex = metricStartIndex {
            // Elements before metric are imperial amount and name
            let imperialElements = Array(sortedRow[0..<metricIndex])
            let metricElements = Array(sortedRow[metricIndex...])
            
            // First 1-2 elements are amount
            if imperialElements.count >= 1 {
                imperialAmount = imperialElements[0].text
                if imperialElements.count >= 2,
                   imperialElements[1].text.lowercased().contains("tsp") ||
                   imperialElements[1].text.lowercased().contains("tbsp") ||
                   imperialElements[1].text.lowercased().contains("cup") {
                    imperialAmount += " " + imperialElements[1].text
                    ingredientName = imperialElements[2...].map { $0.text }.joined(separator: " ")
                } else {
                    ingredientName = imperialElements[1...].map { $0.text }.joined(separator: " ")
                }
            }
            
            metricAmount = metricElements.map { $0.text }.joined(separator: " ")
        } else {
            // No metric found
            if sortedRow.count >= 2 {
                imperialAmount = sortedRow[0].text
                if sortedRow[1].text.lowercased().contains("tsp") ||
                   sortedRow[1].text.lowercased().contains("tbsp") {
                    imperialAmount += " " + sortedRow[1].text
                    ingredientName = sortedRow[2...].map { $0.text }.joined(separator: " ")
                } else {
                    ingredientName = sortedRow[1...].map { $0.text }.joined(separator: " ")
                }
            }
        }
        
        // Clean up
        imperialAmount = cleanText(imperialAmount)
        ingredientName = cleanText(ingredientName)
        if let metric = metricAmount {
            metricAmount = cleanText(metric)
        }
        
        guard !imperialAmount.isEmpty, !ingredientName.isEmpty else { return nil }
        
        return ParsedIngredient(
            imperialAmount: imperialAmount,
            name: ingredientName,
            metricAmount: metricAmount
        )
    }
    
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
}
