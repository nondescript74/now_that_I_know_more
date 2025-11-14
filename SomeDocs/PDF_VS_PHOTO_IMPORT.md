# PDF Recipe Import vs Photo OCR

## Problem with Photo-Based OCR (Vision Framework)

When using the Vision framework to parse recipes from photos, especially those with **multi-column table layouts** (like recipe cards with imperial and metric columns), several issues arise:

### Issues with Vision Framework on Photos

1. **Column Confusion**
   - Vision reads text left-to-right within bounding boxes
   - Multi-column layouts get merged: `"1 cup sugar 250ml flour 125g"`
   - Difficult to determine which measurements belong to which ingredient

2. **Text Grouping Challenges**
   - Vision returns text observations as separate bounding boxes
   - Heuristics needed to group observations into rows
   - Threshold-based vertical grouping can fail with varied font sizes

3. **Image Quality Dependency**
   - Lighting, shadows, and glare affect OCR accuracy
   - Blurry photos reduce text recognition quality
   - Perspective distortion requires correction

4. **Performance Issues**
   - Large images can cause Vision framework to hang or crash
   - Requires image resizing (typically to 512px max dimension)
   - Resizing can reduce OCR accuracy

## Solution: PDF-Based Import

### Advantages of PDF Import

1. **Preserved Text Structure**
   - PDFs store text with exact positions and layout information
   - Text extraction is direct, not OCR-based
   - Column relationships are clearer from spatial data

2. **Better Multi-Column Handling**
   - Can detect columns based on horizontal gaps between text blocks
   - Spatial analysis determines reading order
   - Imperial/metric columns are easier to distinguish

3. **Consistent Quality**
   - Text is digital, not image-based
   - No image quality issues (lighting, focus, etc.)
   - No degradation from photo-to-digital conversion

4. **Performance Benefits**
   - Faster than Vision OCR
   - No image processing required
   - No resizing or preprocessing needed

## Implementation

### RecipePDFParser

The new `RecipePDFParser` class uses **PDFKit** to extract text with layout information:

```swift
// Three parsing strategies
enum ColumnStrategy {
    case sequential      // Simple top-to-bottom reading
    case columnAware     // Detects and handles multi-column layouts (RECOMMENDED)
    case preserveLayout  // Advanced spatial region detection
}
```

### Column-Aware Strategy (Recommended)

This strategy:
1. Extracts text blocks with their positions (CGRect bounds)
2. Groups blocks into horizontal rows based on Y-position
3. For each row, sorts blocks left-to-right
4. Detects multi-column rows by measuring horizontal gaps
5. In multi-column rows, treats each column as a separate ingredient line

**Example**: Recipe card with two columns

```
| 1 cup sugar       | 250 ml  |
| 2 cups flour      | 500 g   |
```

**Photo OCR might produce**:
```
"1 cup sugar 250 ml"  ❌ Confusing - which measurement goes with what?
"2 cups flour 500 g"
```

**PDF Parser produces**:
```
"1 cup" "sugar" "250 ml"  ✅ Clear column separation
"2 cups" "flour" "500 g"
```

### Usage

#### In RecipeImportView

The `RecipeImportView` now accepts PDF files in addition to JSON:

```swift
.fileImporter(
    isPresented: $isImporting,
    allowedContentTypes: [.json, .pdf, UTType(filenameExtension: "recipe")],
    allowsMultipleSelection: false
)
```

When a PDF is selected, it:
1. Loads the PDF with PDFKit
2. Runs `RecipePDFParser` on a background thread
3. Converts `ParsedRecipe` to `RecipeModel`
4. Shows preview with ingredients and instructions
5. Allows user to import into their collection

#### Standalone PDF Parser View

Use `RecipePDFParserView` for a dedicated PDF parsing interface:

```swift
// Shows PDF preview
// Allows strategy selection
// Parses and saves to SwiftData
```

## Comparison Table

| Feature | Photo OCR (Vision) | PDF Import (PDFKit) |
|---------|-------------------|---------------------|
| Multi-column support | ⚠️ Poor - requires complex heuristics | ✅ Excellent - spatial data preserved |
| Text accuracy | ⚠️ Variable - depends on image quality | ✅ Perfect - digital text |
| Performance | ⚠️ Slow - image processing + OCR | ✅ Fast - direct text extraction |
| Setup complexity | 🟡 Medium - image handling, resizing | 🟢 Simple - load PDF document |
| File size handling | ⚠️ Limited - large images cause issues | ✅ Good - handles multi-page PDFs |
| User experience | 📷 Take/choose photo | 📄 Select PDF file |

## Workflow Recommendations

### Use Photo OCR when:
- User has a physical recipe card they can photograph
- Recipe is printed on paper (magazine, book)
- No digital version is available
- Single-column layout

### Use PDF Import when:
- Recipe is already in PDF format (downloaded, emailed)
- Multi-column layouts (imperial/metric tables)
- Complex recipe cards
- Better accuracy is needed

## Future Enhancements

1. **Hybrid Approach**: Convert photo to PDF, then parse
   - Use iOS PDF creation APIs to convert photos to PDFs
   - Apply perspective correction before PDF creation
   - Get benefits of both approaches

2. **Intelligent Format Detection**
   - Analyze PDF structure to auto-select best parsing strategy
   - Detect table regions vs. continuous text
   - Handle mixed-format recipes

3. **Machine Learning**
   - Train model to identify recipe sections
   - Improve ingredient/instruction classification
   - Handle handwritten PDFs (with built-in OCR)

4. **Batch Import**
   - Allow selecting multiple PDFs at once
   - Parse and import entire recipe books
   - Progress tracking for large imports

## Code Files

- `RecipePDFParser.swift` - Core PDF parsing logic
- `RecipePDFParserView.swift` - SwiftUI interface for PDF parsing
- `RecipeImportView.swift` - Updated to accept both JSON and PDF files
- `RecipeImageParser.swift` - Existing photo OCR implementation (unchanged)

## Testing Suggestions

1. **Multi-column recipe cards**
   - Create PDF with imperial/metric columns
   - Test column detection accuracy
   - Verify correct ingredient parsing

2. **Complex layouts**
   - Recipes with images and text
   - Multi-page recipes
   - Recipes with notes sections

3. **Edge cases**
   - Empty PDFs
   - PDFs with no text (scanned images)
   - PDFs with tables, images, formatting

4. **Performance**
   - Large multi-page recipe books
   - Memory usage during parsing
   - UI responsiveness

## Migration Path

For users currently using photo-based import:

1. Keep existing `RecipeImageParser` functionality
2. Add PDF import as an alternative option
3. Update UI to show both options:
   - "Import from Photo" button
   - "Import from PDF" button
4. Gradually encourage PDF usage for complex recipes
5. Consider adding "Convert Photo to PDF" feature

## Conclusion

PDF-based recipe import provides significantly better results for **multi-column table layouts** compared to photo-based OCR. The preserved text structure and spatial information in PDFs make column detection and parsing much more reliable.

For your specific use case (multi-column ingredient tables with imperial and metric measurements), **PDF import is strongly recommended**.
