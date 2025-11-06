# Fixed: Instructions Not Displaying in Recipe Detail View

## Problem
Instructions and variations from OCR-parsed recipes were visible in **Edit Mode** but **not displaying** in the Recipe Detail view.

## Root Cause
The `InstructionListView` component only supported **structured instructions** (`analyzedInstructions` array), but OCR-parsed recipes use **plain text instructions** (simple `instructions` string field).

### Recipe Data Structure:
```swift
// API/Spoonacular recipes use:
analyzedInstructions: [AnalyzedInstruction]  // Array of steps

// OCR-parsed recipes use:
instructions: String  // Plain text like "Blend all ingredients..."
```

The view only checked for `analyzedInstructions` and ignored the `instructions` field.

## Solution

### 1. Enhanced `InstructionListView` Component
Added support for both formats:

```swift
private struct InstructionListView: View {
    let instructions: [AnalyzedInstruction]?
    let plainInstructions: String?
    
    var body: some View {
        // Try structured instructions first
        if let instructions = instructions, !instructions.isEmpty {
            // Display numbered steps
        }
        // Fallback to plain text instructions
        else if let plainText = plainInstructions, !plainText.isEmpty {
            // Display as simple text block
        }
    }
}
```

### 2. Updated Call Site
Modified the view instantiation to pass both fields:

```swift
// Before:
InstructionListView(instructions: recipe.analyzedInstructions)

// After:
InstructionListView(
    instructions: recipe.analyzedInstructions,
    plainInstructions: recipe.instructions
)
```

## What's Fixed

✅ **OCR-parsed recipes** now show instructions in detail view
✅ **API recipes** still work with structured steps
✅ **Variations** are included (part of instructions string)
✅ **Backward compatible** - doesn't break existing recipes

## Display Format

### For Structured Instructions (API recipes):
```
Instructions
━━━━━━━━━━━━━━
1. Preheat oven to 350°F
2. Mix dry ingredients
3. Combine wet and dry
```

### For Plain Text Instructions (OCR recipes):
```
Instructions
━━━━━━━━━━━━━━
Blend all the ingredients to a smooth paste.
Keeps in refrigerator for a long time.

Variations:
1. Add 1 small fresh tomato, adjust salt and blend.
2. Add ½ cup (125 ml) chopped unripe mango, and blend.
```

## Testing

To verify the fix:
1. ✅ Parse a recipe card with OCR
2. ✅ Save it to your collection
3. ✅ View recipe in detail view
4. ✅ Instructions should now be visible
5. ✅ Variations should be visible
6. ✅ Both are also editable in Edit mode

## Files Modified

- **RecipeDetail.swift**
  - Enhanced `InstructionListView` with plain text support
  - Updated call to pass `recipe.instructions`
  - Improved formatting for better readability

## Related Components

The fix ensures consistency across:
- ✅ RecipeDetail view (fixed)
- ✅ RecipeEditorView (already working)
- ✅ ParsedRecipeDisplayView (already shows preview)
- ✅ Recipe sharing/export (includes instructions)

## Notes

The OCR parser combines all instruction-like text into the `instructions` field:
- Cooking steps ("Blend all ingredients...")
- Storage tips ("Keeps in refrigerator...")
- Variations ("Coconut Chutney: ...")

This is intentional - it preserves the original recipe card format and makes editing easier.
