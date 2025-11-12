# OCR Bounding Box Editor - User Guide

## Overview

The **OCR Bounding Box Editor** is an advanced feature that gives you complete control over how recipe images are parsed. Instead of letting the automatic parser interpret the layout, you can manually define regions and group text together for perfect accuracy.

## When to Use It

Use the bounding box editor when:
- The automatic parser misinterprets table layouts
- Text is read across columns instead of down rows
- You want to combine multiple words into a single ingredient
- The recipe has a complex or unusual layout
- You need maximum accuracy for a special recipe card

## How It Works

### Step 1: Select Your Image
1. Choose a recipe image using "Choose Photo" or "Take Photo"
2. Click **"Define Regions (Advanced)"** instead of "Parse Recipe"

### Step 2: Detect Text
- The app automatically detects all text in the image
- You'll see cyan boxes around each detected word
- Toggle "Show Text" / "Hide Text" to control visibility

### Step 3: Draw Regions
1. Click **"Draw Region"** to enter drawing mode
2. Select a region type:
   - **Title** (Purple) - Recipe name
   - **Servings** (Orange) - Serving information
   - **Ingredients** (Green) - Ingredient list
   - **Instructions** (Blue) - Cooking steps
   - **Notes** (Yellow) - Additional info
   - **Ignore** (Gray) - Skip this area

3. **Drag** to draw a rectangle around the region
4. The text within that region is automatically captured

### Step 4: Group Ingredients (Most Important!)

When you draw an **Ingredients** region, a grouping interface opens automatically:

#### Grouping Interface
- **Available Words**: All detected text in the region
- **Tap words** to select them (they turn green/blue)
- **Create Group**: Combines selected words into ONE ingredient line
- Each group becomes one ingredient in your final recipe

#### Example: "Coriander Chutney"

If OCR detected:
```
bunch    coriander    leaves
1-2
salt    to    taste
lemon    juice
2    tsp
```

You would create groups like:
1. Select: `bunch` + `coriander` + `leaves` + `1-2` → **Create Group** → "bunch coriander leaves 1-2"
2. Select: `salt` + `to` + `taste` → **Create Group** → "salt to taste"
3. Select: `lemon` + `juice` + `2` + `tsp` → **Create Group** → "lemon juice 2 tsp"

This gives you **3 ingredients** instead of a jumbled mess!

### Step 5: Review and Complete
- Check your ingredient lines in the grouped list
- Use **Undo** to remove the last region if needed
- Use **trash** icons to delete individual ingredient groups
- Click **"Done"** when finished

### Step 6: Final Result
- The app creates a recipe from your defined regions
- Ingredients use your exact groupings
- You can still edit in the parsed recipe view before saving

## Tips for Best Results

### Drawing Regions
- **Draw tight boxes** around text you want to capture
- **Separate regions** for different sections (don't overlap)
- **Use "Show Text"** mode to see exactly what will be captured

### Grouping Ingredients
- **Select words in left-to-right, top-to-bottom order**
- The app auto-sorts by position, but selection order helps
- **One ingredient per group** - don't combine "carrots" and "onions"
- **Include amounts** - select both "2 cups" and "flour" together

### Common Patterns
| Recipe Format | Grouping Strategy |
|---------------|-------------------|
| Table with 3 columns | Group amount + unit + name from all 3 columns |
| Vertical list | Group entire horizontal line as one ingredient |
| Split measurements | Group "1/2" + "cup" + "sugar" + "250ml" as one |

## Troubleshooting

### "I don't see some words"
- The OCR might have missed them
- Try a clearer/higher resolution image
- Draw a very tight region around just that text

### "Words are in the wrong order"
- Select them in the order you want
- The app sorts by vertical (top to bottom), then horizontal (left to right)
- If needed, create multiple small regions instead of one large one

### "My ingredients are still combined"
- Make sure you're clicking "Create Group" after each ingredient
- Each click creates ONE ingredient line
- Don't select all words at once

### "The app is slow"
- Large/high-resolution images take longer
- The app auto-resizes very large images
- Be patient during text detection (can take 5-10 seconds)

## Workflow Comparison

### Automatic Parsing (Fast but Less Accurate)
```
1. Select image
2. Click "Parse Recipe"
3. Wait 5-10 seconds
4. Edit any mistakes
5. Save
```

### Manual Regions (Slower but Perfect Accuracy)
```
1. Select image
2. Click "Define Regions (Advanced)"
3. Wait for text detection
4. Draw regions (30-60 seconds)
5. Group ingredients (1-2 minutes)
6. Click Done
7. Save
```

**Best practice**: Try automatic first. If results are poor, use the manual editor.

## Examples

### Example 1: Simple Recipe Card

**Layout:**
```
┌─────────────────────┐
│  Chocolate Chip     │  ← Title region
│  Cookies            │
├─────────────────────┤
│  Makes: 24 cookies  │  ← Servings region
├─────────────────────┤
│  • 2 cups flour     │  ← Ingredients region
│  • 1 cup sugar      │     (group each line)
│  • 2 eggs           │
└─────────────────────┘
```

**Steps:**
1. Draw title region → "Chocolate Chip Cookies"
2. Draw servings region → "Makes: 24 cookies"
3. Draw ingredients region
   - Group: `2` + `cups` + `flour`
   - Group: `1` + `cup` + `sugar`
   - Group: `2` + `eggs`

### Example 2: Table Format (Your Coriander Chutney)

**Layout:**
```
┌─────────────────────────────────────┐
│  Coriander Chutney                  │  ← Title
├──────────────┬─────┬────────────────┤
│  Ingredient  │ Imp │    Metric      │  ← Ingredients
│  bunch coriander leaves   1-2       │     (one region,
│  salt, to taste                     │      group carefully)
│  lemon juice           2 tsp  10mL  │
└──────────────┴─────┴────────────────┘
```

**Steps:**
1. Draw title region
2. Draw ONE big ingredients region around the whole table
3. Group strategically:
   - `bunch` + `coriander` + `leaves` + `1-2`
   - `salt` + `to` + `taste`
   - `lemon` + `juice` + `2` + `tsp` + `10mL`

## Advanced Features

### Region Types Behavior
- **Title**: Becomes recipe title
- **Servings**: Parsed for serving count
- **Ingredients**: Can be grouped (opens grouping UI)
- **Instructions**: Becomes cooking steps
- **Notes**: Appended to instructions
- **Ignore**: Not included in final recipe

### Multiple Regions of Same Type
- You can draw multiple ingredient regions
- They'll all open for grouping sequentially
- Final recipe combines them in order

### Keyboard Shortcuts
- None currently, but you can use accessibility features

## Saving and Reusing Layouts

**Future enhancement:** The app could save region templates for:
- "Standard Recipe Card (3x5)"
- "Indian Recipe Card (Table Format)"
- "Magazine Column Layout"

This would let you reuse the same layout for similar recipe cards!

## Technical Notes

### Coordinate Systems
- Vision framework uses bottom-left origin, normalized 0-1
- SwiftUI uses top-left origin, in points
- The app handles all conversions automatically

### Text Detection
- Uses Apple's Vision framework
- Recognition level: Accurate (not Fast)
- Language correction: Enabled
- Supports multiple languages

### Performance
- Image resized to max 512pt dimension if larger
- Text detection runs on background thread
- UI updates happen on main thread

## Future Improvements

Potential enhancements:
1. **Template saving** - Save region layouts for reuse
2. **Auto-grouping suggestions** - AI-powered ingredient grouping
3. **Batch processing** - Process multiple recipe cards at once
4. **Export regions** - Share layouts with other users
5. **OCR confidence scores** - Show which text is uncertain

## Feedback

If you find this feature useful or have suggestions for improvement, please provide feedback!

---

**Version**: 1.0  
**Last Updated**: November 12, 2025  
**Compatible with**: iOS 17+
