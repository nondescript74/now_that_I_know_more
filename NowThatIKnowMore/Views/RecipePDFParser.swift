//
//  RecipePDFParser.swift
//  NowThatIKnowMore
//
//  PDF-based recipe parser using PDFKit for better text extraction
//  Handles multi-column layouts much better than Vision framework on photos
//

import Foundation
import PDFKit
import UIKit

// MARK: - PDF Parser Protocol

/// Parser for extracting recipe data from PDF documents
protocol RecipePDFParserProtocol {
    /// Parse a PDF document and extract recipe information
    func parsePDF(_ document: PDFDocument, completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void)
}

// MARK: - PDF Recipe Parser

/// Main PDF parser that extracts text from PDFs and converts to structured recipe data
/// PDFs preserve text structure better than photos, especially for multi-column layouts
class RecipePDFParser: RecipePDFParserProtocol, @unchecked Sendable {
    
    // MARK: - Configuration
    
    /// Strategy for handling multi-column layouts
    enum ColumnStrategy {
        case sequential      // Read left-to-right, top-to-bottom (default)
        case columnAware     // Detect columns and read column-by-column
        case preserveLayout  // Keep spatial relationships intact
    }
    
    private let columnStrategy: ColumnStrategy
    private let debugMode: Bool
    
    init(columnStrategy: ColumnStrategy = .columnAware, debugMode: Bool = true) {
        self.columnStrategy = columnStrategy
        self.debugMode = debugMode
    }
    
    // MARK: - Main Parsing Function
    
    func parsePDF(_ document: PDFDocument, completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void) {
        log("📄 [PDFParser] Starting PDF parsing...")
        log("   Pages: \(document.pageCount)")
        
        // Extract text from all pages
        var allText = ""
        var textWithLayout: [TextBlock] = []
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                log("⚠️ [PDFParser] Could not access page \(pageIndex)")
                continue
            }
            
            log("📖 [PDFParser] Processing page \(pageIndex + 1)...")
            
            // Get text from page
            if let pageText = page.string {
                allText += pageText + "\n"
                
                // Extract text with spatial information for better column handling
                if columnStrategy != .sequential {
                    let blocks = extractTextBlocks(from: page)
                    textWithLayout.append(contentsOf: blocks)
                    log("   Found \(blocks.count) text blocks")
                }
            }
        }
        
        log("📝 [PDFParser] Total text length: \(allText.count) characters")
        
        guard !allText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            log("❌ [PDFParser] No text found in PDF")
            completion(.failure(.noTextFound))
            return
        }
        
        // Parse the extracted text based on strategy
        let parsedText: ParsedRecipeText
        
        switch columnStrategy {
        case .sequential:
            parsedText = parseSequentialText(allText)
        case .columnAware:
            parsedText = parseColumnAwareText(textWithLayout)
        case .preserveLayout:
            parsedText = parseLayoutPreservingText(textWithLayout)
        }
        
        // Build final recipe
        let recipe = buildRecipe(from: parsedText)
        
        log("✅ [PDFParser] Recipe parsed successfully: '\(recipe.title)'")
        log("   Ingredients: \(recipe.ingredients.count)")
        
        completion(.success(recipe))
    }
    
    // MARK: - Text Extraction with Layout
    
    /// Represents a block of text with its position on the page
    nonisolated struct TextBlock: Sendable {
        let text: String
        let bounds: CGRect
        let pageIndex: Int
        
        var centerX: CGFloat { bounds.midX }
        var centerY: CGFloat { bounds.midY }
        var left: CGFloat { bounds.minX }
        var right: CGFloat { bounds.maxX }
        var top: CGFloat { bounds.maxY }  // PDF coordinates: origin at bottom-left
        var bottom: CGFloat { bounds.minY }
    }
    
    /// Extract text blocks with their positions from a PDF page
    private nonisolated func extractTextBlocks(from page: PDFPage) -> [TextBlock] {
        var blocks: [TextBlock] = []
        
        guard let pageContent = page.string else { return [] }
        
        // Split into lines
        let lines = pageContent.components(separatedBy: .newlines)
        
        // Attempt to get selection bounds for each line
        // This is a heuristic approach since PDFPage doesn't expose detailed layout info easily
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Try to find this text in the page
            if let selection = page.selection(for: NSRange(location: 0, length: line.utf16.count)) {
                let bounds = selection.bounds(for: page)
                let block = TextBlock(
                    text: trimmed,
                    bounds: bounds,
                    pageIndex: page.pageRef?.pageNumber ?? 0
                )
                blocks.append(block)
            } else {
                // Fallback: create block with estimated position
                let estimatedY = CGFloat(lines.count - index) * 20  // Rough estimate
                let bounds = CGRect(x: 0, y: estimatedY, width: 500, height: 20)
                let block = TextBlock(
                    text: trimmed,
                    bounds: bounds,
                    pageIndex: page.pageRef?.pageNumber ?? 0
                )
                blocks.append(block)
            }
        }
        
        return blocks
    }
    
    // MARK: - Parsing Strategies
    
    /// Parse text sequentially (simple line-by-line reading)
    private nonisolated func parseSequentialText(_ text: String) -> ParsedRecipeText {
        log("📖 [PDFParser] Using sequential parsing strategy")
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        log("   Lines: \(lines.count)")
        
        return parseRecipeStructure(from: lines)
    }
    
    /// Parse text with column awareness (handles multi-column layouts)
    private nonisolated func parseColumnAwareText(_ blocks: [TextBlock]) -> ParsedRecipeText {
        log("📊 [PDFParser] Using column-aware parsing strategy")
        
        // Group blocks by vertical position (rows)
        let rows = groupBlocksIntoRows(blocks)
        log("   Grouped into \(rows.count) rows")
        
        // For each row, sort blocks left-to-right
        var orderedLines: [String] = []
        for row in rows {
            let sortedBlocks = row.sorted { $0.left < $1.left }
            
            // Detect if this row has multiple columns
            let hasMultipleColumns = detectColumns(in: sortedBlocks)
            
            if hasMultipleColumns {
                log("   📋 Multi-column row detected with \(sortedBlocks.count) blocks")
                // In multi-column ingredient tables, we want to read each column separately
                // This prevents "1 cup sugar 250 ml flour 125 g" from becoming one line
                for block in sortedBlocks {
                    orderedLines.append(block.text)
                }
            } else {
                // Single column or continuous text - join the blocks
                let lineText = sortedBlocks.map { $0.text }.joined(separator: " ")
                orderedLines.append(lineText)
            }
        }
        
        log("   Extracted \(orderedLines.count) ordered lines")
        
        return parseRecipeStructure(from: orderedLines)
    }
    
    /// Parse text preserving spatial layout (most accurate for complex layouts)
    private nonisolated func parseLayoutPreservingText(_ blocks: [TextBlock]) -> ParsedRecipeText {
        log("🗺️ [PDFParser] Using layout-preserving parsing strategy")
        
        // Detect regions (title, ingredients, instructions) based on spatial clustering
        let regions = detectRegions(in: blocks)
        log("   Detected \(regions.count) regions")
        
        var parsed = ParsedRecipeText()
        
        for region in regions {
            switch region.type {
            case .title:
                parsed.title = region.text
                log("   📌 Title: \(region.text)")
                
            case .servings:
                parsed.servings = region.text
                log("   👥 Servings: \(region.text)")
                
            case .ingredients:
                parsed.lines.append(contentsOf: region.lines)
                log("   🥕 Ingredients: \(region.lines.count) lines")
                
            case .instructions:
                parsed.instructions = region.text
                log("   📖 Instructions found")
            }
        }
        
        return parsed
    }
    
    // MARK: - Layout Analysis
    
    /// Group text blocks into rows based on vertical position
    private nonisolated func groupBlocksIntoRows(_ blocks: [TextBlock]) -> [[TextBlock]] {
        guard !blocks.isEmpty else { return [] }
        
        // Sort blocks by Y position (top to bottom)
        let sortedBlocks = blocks.sorted { $0.top > $1.top }
        
        var rows: [[TextBlock]] = []
        var currentRow: [TextBlock] = []
        var currentY = sortedBlocks.first!.top
        
        // Threshold for considering blocks on the same row (10% of page height or 20pt, whichever is smaller)
        let pageHeight = blocks.map { $0.bounds.maxY }.max() ?? 1000
        let rowThreshold = min(pageHeight * 0.10, 20.0)
        
        for block in sortedBlocks {
            if abs(block.top - currentY) <= rowThreshold {
                // Same row
                currentRow.append(block)
            } else {
                // New row
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [block]
                currentY = block.top
            }
        }
        
        // Add last row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    /// Detect if a row of blocks represents multiple columns
    private nonisolated func detectColumns(in blocks: [TextBlock]) -> Bool {
        guard blocks.count >= 2 else { return false }
        
        // Calculate gaps between consecutive blocks
        let sortedBlocks = blocks.sorted { $0.left < $1.left }
        var gaps: [CGFloat] = []
        
        for i in 0..<(sortedBlocks.count - 1) {
            let gap = sortedBlocks[i + 1].left - sortedBlocks[i].right
            gaps.append(gap)
        }
        
        // If we have significant gaps (> 30pt), consider it multi-column
        let significantGaps = gaps.filter { $0 > 30 }
        return !significantGaps.isEmpty
    }
    
    // MARK: - Region Detection
    
    enum RegionType {
        case title
        case servings
        case ingredients
        case instructions
    }
    
    nonisolated struct Region: Sendable {
        let type: RegionType
        let text: String
        let lines: [String]
        let blocks: [TextBlock]
    }
    
    /// Detect different recipe regions based on spatial clustering and content
    private nonisolated func detectRegions(in blocks: [TextBlock]) -> [Region] {
        var regions: [Region] = []
        
        // Sort blocks top to bottom
        let sortedBlocks = blocks.sorted { $0.top > $1.top }
        
        // First block is likely the title
        if let firstBlock = sortedBlocks.first {
            regions.append(Region(
                type: .title,
                text: firstBlock.text,
                lines: [firstBlock.text],
                blocks: [firstBlock]
            ))
        }
        
        // Look for section headers and group subsequent blocks
        var currentRegion: RegionType?
        var currentBlocks: [TextBlock] = []
        
        for (index, block) in sortedBlocks.enumerated() {
            if index == 0 { continue }  // Skip title
            
            let lowerText = block.text.lowercased()
            
            // Detect section headers
            if lowerText.contains("ingredient") {
                // Save previous region
                if let region = currentRegion, !currentBlocks.isEmpty {
                    regions.append(createRegion(type: region, blocks: currentBlocks))
                }
                currentRegion = .ingredients
                currentBlocks = []
                continue
            } else if lowerText.contains("instruction") || lowerText.contains("direction") || lowerText.contains("method") {
                // Save previous region
                if let region = currentRegion, !currentBlocks.isEmpty {
                    regions.append(createRegion(type: region, blocks: currentBlocks))
                }
                currentRegion = .instructions
                currentBlocks = []
                continue
            } else if lowerText.contains("serves") || lowerText.contains("makes") || lowerText.contains("yield") {
                // Servings info
                if currentRegion == nil {
                    regions.append(Region(
                        type: .servings,
                        text: block.text,
                        lines: [block.text],
                        blocks: [block]
                    ))
                    continue
                }
            }
            
            // Add block to current region
            if currentRegion != nil {
                currentBlocks.append(block)
            }
        }
        
        // Save last region
        if let region = currentRegion, !currentBlocks.isEmpty {
            regions.append(createRegion(type: region, blocks: currentBlocks))
        }
        
        return regions
    }
    
    private nonisolated func createRegion(type: RegionType, blocks: [TextBlock]) -> Region {
        let lines = blocks.map { $0.text }
        let text = lines.joined(separator: "\n")
        return Region(type: type, text: text, lines: lines, blocks: blocks)
    }
    
    // MARK: - Recipe Structure Parsing
    
    /// Parse recipe structure from ordered lines
    private nonisolated func parseRecipeStructure(from lines: [String]) -> ParsedRecipeText {
        var parsed = ParsedRecipeText()
        
        // Detect recipe sections
        var ingredientStart: Int?
        var ingredientEnd: Int?
        var instructionStart: Int?
        
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Title is usually the first line
            if index == 0 {
                parsed.title = line
                continue
            }
            
            // Look for servings info
            if parsed.servings == nil && (lower.contains("serves") || lower.contains("makes") || lower.contains("yield") || lower.contains("servings")) {
                parsed.servings = line
                continue
            }
            
            // Detect ingredient section
            if lower == "ingredients" || lower == "ingredients:" {
                ingredientStart = index + 1
                log("   📋 Found ingredients section at line \(index)")
                continue
            }
            
            // Detect instruction section
            if lower == "instructions" || lower == "instructions:" || 
               lower == "directions" || lower == "directions:" ||
               lower == "method" || lower == "method:" ||
               lower == "preparation" || lower == "preparation:" {
                ingredientEnd = index
                instructionStart = index + 1
                log("   📖 Found instructions section at line \(index)")
                continue
            }
        }
        
        // If no explicit sections, try to detect implicitly
        if ingredientStart == nil {
            // Assume ingredients start after title and servings (around line 1-2)
            ingredientStart = parsed.servings != nil ? 2 : 1
        }
        
        if ingredientEnd == nil && instructionStart == nil {
            // Try to find where instructions begin by looking for instruction verbs
            for (index, line) in lines.enumerated() {
                if index < (ingredientStart ?? 0) { continue }
                
                if isInstructionLine(line) {
                    ingredientEnd = index
                    instructionStart = index
                    log("   📖 Detected instructions start at line \(index)")
                    break
                }
            }
            
            if ingredientEnd == nil {
                ingredientEnd = lines.count
            }
        }
        
        // Extract ingredients
        if let start = ingredientStart {
            let end = ingredientEnd ?? lines.count
            parsed.lines = Array(lines[start..<min(end, lines.count)])
            log("   🥕 Extracted \(parsed.lines.count) ingredient lines")
        }
        
        // Extract instructions
        if let start = instructionStart {
            let instructionLines = Array(lines[start..<lines.count])
            parsed.instructions = instructionLines.joined(separator: "\n")
            log("   📖 Extracted instructions (\(instructionLines.count) lines)")
        }
        
        return parsed
    }
    
    // MARK: - Recipe Building
    
    private nonisolated func buildRecipe(from parsed: ParsedRecipeText) -> ParsedRecipe {
        log("🔨 [PDFParser] Building recipe from parsed text")
        
        // Parse ingredients
        let ingredients = parseIngredients(from: parsed.lines)
        log("   Parsed \(ingredients.count) ingredients")
        
        return ParsedRecipe(
            title: parsed.title.isEmpty ? "Untitled Recipe" : parsed.title,
            servings: parsed.servings,
            ingredients: ingredients,
            instructions: parsed.instructions
        )
    }
    
    // MARK: - Ingredient Parsing
    
    private nonisolated func parseIngredients(from lines: [String]) -> [ParsedIngredient] {
        var ingredients: [ParsedIngredient] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Skip lines that look like instructions
            if isInstructionLine(trimmed) {
                continue
            }
            
            // Remove bullet points and numbering
            let cleaned = trimmed
                .replacingOccurrences(of: "^[-–•*]\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            if let ingredient = parseIngredient(cleaned) {
                ingredients.append(ingredient)
                log("   ✅ \(ingredient.imperialAmount) \(ingredient.name)")
            }
        }
        
        return ingredients
    }
    
    /// Parse a single ingredient line
    /// Handles formats like:
    /// - "2 cups flour"
    /// - "1 lb chicken, cubed"
    /// - "Salt to taste"
    /// - "2 cups (500ml) milk"
    private nonisolated func parseIngredient(_ text: String) -> ParsedIngredient? {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else { return nil }
        
        var amountStr = ""
        var unitStr = ""
        var nameWords: [String] = []
        var metricStr: String?
        
        var i = 0
        
        // Step 1: Extract amount
        if i < words.count && isAmount(words[i]) {
            amountStr = words[i]
            i += 1
            
            // Check for compound amounts like "1 1/2"
            if i < words.count && isAmount(words[i]) {
                amountStr += " " + words[i]
                i += 1
            }
        }
        
        // Step 2: Extract unit
        if i < words.count && isUnit(words[i]) {
            unitStr = words[i]
            i += 1
        }
        
        // Step 3: Extract metric (if in parentheses)
        let remainingText = words[i...].joined(separator: " ")
        if let metricMatch = extractMetricMeasurement(remainingText) {
            metricStr = metricMatch
            // Remove metric from remaining text
            let cleanedRemaining = remainingText.replacingOccurrences(of: metricMatch, with: "")
                .replacingOccurrences(of: "[]", with: "")
                .replacingOccurrences(of: "()", with: "")
                .trimmingCharacters(in: .whitespaces)
            nameWords = cleanedRemaining.split(separator: " ").map(String.init)
        } else {
            // No metric, rest is ingredient name
            nameWords = Array(words[i...])
        }
        
        // Build result
        let imperialAmount = !amountStr.isEmpty ? "\(amountStr) \(unitStr)".trimmingCharacters(in: .whitespaces) : ""
        let name = nameWords.joined(separator: " ")
        
        guard !name.isEmpty else { return nil }
        
        return ParsedIngredient(
            imperialAmount: imperialAmount,
            name: name,
            metricAmount: metricStr
        )
    }
    
    // MARK: - Helper Functions
    
    private nonisolated func isInstructionLine(_ text: String) -> Bool {
        let lower = text.lowercased()
        let instructionStarters = [
            "place", "mix", "combine", "heat", "cook", "bake",
            "add", "stir", "blend", "pour", "serve", "garnish",
            "marinate", "skewer", "grill", "baste", "chop",
            "preheat", "whisk", "fold", "sauté", "simmer",
            "bring to", "remove from", "set aside", "let stand"
        ]
        
        return instructionStarters.contains { lower.hasPrefix($0) }
    }
    
    private nonisolated func isAmount(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "(),[]"))
        
        // Fractions
        if trimmed.contains("/") { return true }
        if trimmed.contains("½") || trimmed.contains("¼") || trimmed.contains("¾") ||
           trimmed.contains("⅓") || trimmed.contains("⅔") { return true }
        
        // Ranges
        if trimmed.range(of: "^\\d+[-–]\\d+", options: .regularExpression) != nil {
            return true
        }
        
        // Numbers
        if Double(trimmed) != nil { return true }
        if let firstChar = trimmed.first, firstChar.isNumber { return true }
        
        return false
    }
    
    private nonisolated func isUnit(_ text: String) -> Bool {
        let lower = text.lowercased().replacingOccurrences(of: ".", with: "")
        let units = [
            "tsp", "tbsp", "tablespoon", "tablespoons", "teaspoon", "teaspoons",
            "cup", "cups", "oz", "ounce", "ounces", "lb", "lbs", "pound", "pounds",
            "ml", "mL", "l", "L", "g", "kg", "gram", "grams",
            "kilogram", "kilograms", "liter", "liters", "litre", "litres",
            "bunch", "bunches", "quart", "quarts", "qt",
            "pinch", "dash", "clove", "cloves", "sprig", "sprigs",
            "can", "cans", "package", "pkg"
        ]
        return units.contains { lower.hasPrefix($0) || lower == $0 }
    }
    
    private nonisolated func extractMetricMeasurement(_ text: String) -> String? {
        // Pattern: (250ml) or [500g] or (1.5L)
        let patterns = [
            "\\(([\\d.]+\\s*(?:ml|mL|l|L|g|kg))\\)",
            "\\[([\\d.]+\\s*(?:ml|mL|l|L|g|kg))\\]"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let match = String(text[range])
                return match.trimmingCharacters(in: CharacterSet(charactersIn: "()[]"))
            }
        }
        
        return nil
    }
    
    private nonisolated func log(_ message: String) {
        if debugMode {
            print(message)
        }
    }
}

// MARK: - Supporting Types

// Note: ParsedRecipeText is defined in RecipeImageParser.swift and shared between parsers
