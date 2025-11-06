# Improved Ingredient Parsing for Column Layouts

## Problem Identified
Recipe cards with column layouts were being parsed poorly:
```
Column 1 (Amount)    Column 2 (Ingredient)    Column 3 (Metric)
2 tsp.               lemon juice               10 mL
1                    bunch coriander
```

OCR was extracting these as **separate lines**:
- Line: "2 tsp."
- Line: "lemon juice"
- Line: "10 mL"

The old parser couldn't connect them together.

## Solution Implemented

### 1. **Smart Line Combination** (`combineIngredientLines`)
Before parsing, intelligently combines lines that belong together:

**Detects:**
- Lines that are just measurements ("2 tsp.", "10 mL")
- Lines that are just ingredient names ("lemon juice", "coriander")

**Combines:**
```
"2 tsp." + "lemon juice" → "2 tsp. lemon juice"
"bunch" + "coriander" → "bunch coriander"
```

**Logic:**
```swift
if isJustMeasurement(line) && nextLineExists {
    if !isJustMeasurement(nextLine) {
        combine(line, nextLine)
    }
}
```

### 2. **Better Measurement Detection** (`isJustMeasurement`)
Identifies lines that are ONLY measurements:
- "2 tsp." ✅
- "10 mL" ✅
- "1-2" ✅
- "bunch coriander" ❌ (has ingredient name)

### 3. **Handles Ingredients Without Amounts**
Special case for ingredients like:
- "salt, to taste"
- "pepper"
- "garnish"

These get parsed with `imperialAmount: "to taste"`

## Expected Improvements

### Before:
```
🥘 [Parser] Parsing 9 potential ingredient lines
   ✅ Parsed: salt, to taste [no metric]
   ✅ Parsed: bunch coriander [no metric]
   ❌ Could not parse: "10 mL"
   ✅ Parsed: lemon juice [no metric]
   ❌ Could not parse: "2 tsp."
   ❌ Could not parse: "leaves*"
   ❌ Could not parse: "1•2"
   ❌ Could not parse: "1-2"
   ✅ Parsed: whole hot peppers [no metric]
🥘 [Parser] Total ingredients parsed: 4
```

### After (Expected):
```
🔄 [Parser] Combining split ingredient lines...
   📎 Combined: "2 tsp." + "lemon juice" → "2 tsp. lemon juice"
   📎 Combined: "bunch" + "coriander" → "bunch coriander"
   📎 Combined: "10 mL" + "leaves*" → "10 mL leaves*"
   📎 Combined: "1-2" + "whole hot peppers" → "1-2 whole hot peppers"
🔄 [Parser] Combined 9 lines into 5 ingredient entries
🥘 [Parser] Parsing 5 potential ingredient lines
   ✅ Parsed: to taste salt, to taste [no metric]
   ✅ Parsed: 2 tsp. lemon juice [10 mL]
   ✅ Parsed: bunch coriander [no metric]
   ✅ Parsed: 10 mL leaves* [no metric]
   ✅ Parsed: 1-2 whole hot peppers [no metric]
🥘 [Parser] Total ingredients parsed: 5
```

## How It Works

### Step 1: Line Combination
```
Input:  ["salt, to taste", "bunch", "coriander", "10 mL", "lemon juice", "2 tsp."]
Output: ["salt, to taste", "bunch coriander", "10 mL lemon juice", "2 tsp."]
```

### Step 2: Ingredient Parsing
Each combined line is parsed:
- `"2 tsp. lemon juice"` → amount: "2 tsp.", name: "lemon juice"
- `"bunch coriander"` → amount: "bunch", name: "coriander"
- `"salt, to taste"` → amount: "to taste", name: "salt"

### Step 3: Metric Detection
If a line has both imperial and metric:
```
"2 tsp. lemon juice 10 mL"
→ imperial: "2 tsp."
→ name: "lemon juice"
→ metric: "10 mL"
```

## Testing

Run the same recipe card image again. You should see:
1. ✅ More lines combined (shown in logs)
2. ✅ Better ingredient parsing (5+ instead of 4)
3. ✅ Metric measurements captured
4. ✅ Fewer "Could not parse" errors

## Edge Cases Handled

- **Range amounts**: "1-2 tsp." or "1•2"
- **Text-only ingredients**: "salt, to taste"
- **Split measurements**: "2" on one line, "tsp." on next
- **Metric in parentheses**: "(125 mL)"
- **Multiple spaces**: "  2   tsp.  "

## Future Improvements

Could add:
- More sophisticated column detection (using bounding boxes)
- Better handling of fractions split across lines
- Recognition of "bunch", "pinch", etc. as valid amounts
- Context-aware parsing (curry recipes vs baking recipes)
