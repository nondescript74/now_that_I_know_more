# Recipe Parser Architecture Guide

## Overview

The Recipe Image Parser system now uses a protocol-based architecture that allows you to have multiple parser implementations for different recipe card formats.

## Architecture Components

### 1. **RecipeImageParserProtocol**

The base protocol that all parsers must implement:

```swift
protocol RecipeImageParserProtocol {
    var parserType: RecipeParserType { get }
    var displayName: String { get }
    var description: String { get }
    
    func parseRecipeImage(_ image: UIImage, 
                         completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void)
}
```

### 2. **RecipeParserType**

An enum defining available parser types:

```swift
enum RecipeParserType: String, Codable, CaseIterable {
    case tableFormat     // Table-format recipe cards (current implementation)
    case standardText    // Standard text recipes
    case handwritten     // Handwritten recipes
    case magazine        // Magazine/cookbook pages
}
```

### 3. **Current Parser: TableFormatRecipeParser**

Optimized for recipe cards with table layouts, particularly:
- Indian recipe cards
- Printed recipe cards with imperial/metric columns
- Structured layouts with clear sections

**Features:**
- Multi-ingredient line parsing (handles table formats read left-to-right by OCR)
- Automatic section detection (title, servings, ingredients, instructions, variations)
- Imperial and metric measurement parsing
- Instruction keyword detection
- Support for fractions, unicode characters, and modifiers

### 4. **RecipeParserFactory**

Factory class for creating and managing parsers:

```swift
// Get a specific parser
let parser = RecipeParserFactory.parser(for: .tableFormat)

// Get the default parser
let defaultParser = RecipeParserFactory.defaultParser

// Get available parser types
let available = RecipeParserFactory.availableParsers
```

## Adding a New Parser

When you're ready to add a parser for a different recipe card format:

### Step 1: Create a New Parser Class

```swift
class StandardTextRecipeParser: RecipeImageParserProtocol {
    let parserType: RecipeParserType = .standardText
    let displayName: String = "Standard Text Parser"
    let description: String = "For recipes in standard paragraph format"
    
    func parseRecipeImage(_ image: UIImage, 
                         completion: @escaping @Sendable (Result<ParsedRecipe, RecipeParserError>) -> Void) {
        // Your parsing logic here
        // Can reuse Vision OCR extraction
        // Implement different text parsing strategy
    }
}
```

### Step 2: Update the Factory

```swift
class RecipeParserFactory {
    static func parser(for type: RecipeParserType) -> RecipeImageParserProtocol {
        switch type {
        case .tableFormat:
            return TableFormatRecipeParser()
        case .standardText:
            return StandardTextRecipeParser()  // Add your new parser
        case .handwritten:
            return HandwrittenRecipeParser()
        case .magazine:
            return MagazineRecipeParser()
        }
    }
    
    static var availableParsers: [RecipeParserType] {
        return [.tableFormat, .standardText, .handwritten, .magazine]
    }
}
```

### Step 3: Parser Selection UI

The UI automatically adapts:
- If only one parser is available: No picker is shown
- If multiple parsers are available: A segmented picker appears

## Usage Examples

### Using in RecipeImageParserView (Current)

```swift
struct RecipeImageParserView: View {
    @State private var selectedParserType: RecipeParserType = .tableFormat
    
    private func parseImage() {
        let parser = RecipeParserFactory.parser(for: selectedParserType)
        parser.parseRecipeImage(image) { result in
            // Handle result
        }
    }
}
```

### Direct Parser Usage

```swift
// Use a specific parser
let tableParser = TableFormatRecipeParser()
tableParser.parseRecipeImage(image) { result in
    // Handle result
}

// Or via factory
let parser = RecipeParserFactory.parser(for: .tableFormat)
parser.parseRecipeImage(image) { result in
    // Handle result
}
```

### Backward Compatibility

For existing code, `RecipeImageParser` is aliased to `TableFormatRecipeParser`:

```swift
// Still works
let parser = RecipeImageParser()
parser.parseRecipeImage(image) { result in
    // Handle result
}
```

## Current Parser Details: TableFormatRecipeParser

### Optimized For:
- Table-format recipe cards
- Multi-column layouts (imperial | metric)
- Indian recipe cards
- Structured printed recipes

### Handles:
- ✅ Multiple ingredients per OCR line
- ✅ Imperial and metric measurements
- ✅ Fractions (1/2, ½, ¾, etc.)
- ✅ Section detection (Variations, Instructions)
- ✅ Footnotes and asterisks
- ✅ "OR" alternatives
- ✅ Modifiers like "to taste"
- ✅ Various unit formats (tsp., tbsp, bunch, quart, etc.)

### Debug Logging:
Enable console logging to see:
- 📝 All OCR-extracted lines
- 📋 Section detection (variations, instructions)
- 🥘 Ingredient parsing results
- ✅/❌ Success/failure per line

## Design Philosophy

1. **Separation of Concerns**: Each parser handles a specific format type
2. **Extensibility**: Easy to add new parsers without modifying existing ones
3. **Testability**: Each parser can be tested independently
4. **User Choice**: Users can select the best parser for their recipe format
5. **Progressive Enhancement**: Start with one parser, add more as needed

## Future Parser Ideas

### StandardTextRecipeParser
- For recipes written in paragraph format
- "Add 2 cups flour to the mixture..."
- Less structured than table format

### HandwrittenRecipeParser
- Enhanced text correction
- More lenient parsing rules
- Handle variations in handwriting OCR accuracy

### MagazineRecipeParser
- Multi-column magazine layouts
- Decorative fonts
- Embedded photos and captions
- Page number handling

### WebpageRecipeParser
- Screenshot parsing
- Handle web formatting
- Detect recipe schema markup

## Testing Strategy

```swift
import Testing

@Suite("Recipe Parser Tests")
struct RecipeParserTests {
    
    @Test("Table Format Parser - Basic Ingredient")
    func testTableFormatBasicIngredient() async throws {
        let parser = TableFormatRecipeParser()
        let testImage = loadTestImage("lemon_chutney.png")
        
        let result = try await withCheckedThrowingContinuation { continuation in
            parser.parseRecipeImage(testImage) { result in
                continuation.resume(with: result)
            }
        }
        
        #expect(result.ingredients.count == 5)
        #expect(result.title == "Lemon Chutney")
    }
}
```

## Files

- **RecipeImageParser.swift**: Contains protocol, factory, and TableFormatRecipeParser
- **RecipeImageParserView.swift**: UI with parser selection
- **ParsedRecipeAdapter.swift**: Converts ParsedRecipe to Recipe model
- **RECIPE_PARSER_ARCHITECTURE.md**: This documentation

## Summary

The new architecture allows you to:
1. ✅ Use the current table format parser for your recipe cards
2. ✅ Easily add new parsers for different formats later
3. ✅ Switch between parsers without changing existing code
4. ✅ Maintain backward compatibility
5. ✅ Test parsers independently

When you're ready to add a new parser for a different recipe card format, just create a new class conforming to `RecipeImageParserProtocol` and add it to the factory!
