# Ingredient Image System

## Overview

The app now has a smart ingredient image caching system that learns and stores successful image URL mappings in SwiftData. This eliminates redundant network requests and provides a consistent user experience.

## Components

### 1. **IngredientImageMappingModel** 
SwiftData model that stores:
- Ingredient ID and name
- Successful image filename
- Whether tested
- Number of attempts
- Whether no image is available
- All attempted URLs

### 2. **IngredientImageMappingService**
Service layer that:
- Queries cached mappings
- Tests new ingredients
- Records successes and failures
- Generates smart URL variations

### 3. **IngredientImageView**
Reusable SwiftUI view that:
- Automatically checks cache first
- Falls back to testing if not cached
- Shows a beautiful placeholder for missing images
- Works with any size

### 4. **IngredientImageTest**
Testing UI that:
- Batch tests ingredients
- Shows success rates
- Saves results to database
- Provides statistics

## Usage

### Display an ingredient image:

```swift
// From an ExtendedIngredient
IngredientImageView(ingredient: extendedIngredient, size: 60)

// From a SpoonacularIngredient
IngredientImageView(spoonacularIngredient: ingredient, size: 80)

// Directly with ID and name
IngredientImageView(
    ingredientID: 11215, 
    ingredientName: "garlic", 
    size: 100
)
```

### Get image URL programmatically:

```swift
@Environment(\.modelContext) private var modelContext

func loadIngredientImage() async {
    let service = IngredientImageMappingService(modelContext: modelContext)
    
    if let url = await service.getImageURL(
        forIngredientID: 11215, 
        name: "garlic"
    ) {
        print("Image URL: \(url)")
    } else {
        print("No image available")
    }
}
```

### Save test results:

```swift
// In IngredientImageTest view:
// 1. Run tests
// 2. Tap menu (•••) in top right
// 3. Select "Save Results to Database"
```

## How It Works

### First Time:
1. User requests ingredient image
2. System checks cache (not found)
3. System generates smart URL variations:
   - Exact hyphenated: `garlic.jpg`
   - PNG version: `garlic.png`
   - Simplified: extract core ingredient
   - Plural variations: `garlics.jpg`
4. Tests each URL until one succeeds
5. Saves successful mapping to database

### Subsequent Times:
1. User requests same ingredient
2. System checks cache (found!)
3. Returns cached URL immediately
4. No network requests needed ✅

## Smart URL Generation

The system tries multiple strategies:

### 1. Exact Match
```
"garlic" → "garlic.jpg"
"olive oil" → "olive-oil.jpg"
```

### 2. Simplified
```
"dried basil" → "basil.jpg"
"boneless chicken breast" → "chicken.jpg"
```

### 3. Plural Variations
```
"banana" → "bananas.jpg"
"tomatoes" → "tomato.jpg"
```

### 4. Core Ingredient Extraction
```
"chive & onion cream cheese" → "cheese.jpg"
"apple butter spread" → "butter.jpg"
```

## Testing Workflow

### Initial Setup:
1. Navigate to "Img Test" tab
2. App automatically tests 30+ diverse ingredients
3. Review success rate
4. Save results to database

### Database Stats:
```
DB: 18/36
```
Shows: 18 successful mappings out of 36 tested

### Menu Options:
- **Retest All**: Run tests again
- **Save Results to Database**: Persist findings
- **View Database Stats**: See console statistics
- **Clear Database**: Reset for testing

## Database Schema

```swift
@Model
final class IngredientImageMappingModel {
    @Attribute(.unique) var ingredientID: Int
    var ingredientName: String
    var imageFilename: String?
    var tested: Bool
    var attemptsCount: Int
    var lastVerified: Date
    var noImageAvailable: Bool
    var attemptedURLsJSON: String?
}
```

## Integration Points

### RecipeDetail View
```swift
ForEach(recipe.extendedIngredients ?? [], id: \.id) { ingredient in
    HStack {
        IngredientImageView(ingredient: ingredient, size: 50)
        Text(ingredient.name ?? "")
    }
}
```

### Recipe Editor
```swift
IngredientImageView(
    ingredientID: ingredient.id,
    ingredientName: ingredient.name ?? "Unknown",
    size: 40
)
```

### Ingredient Picker
```swift
List(ingredients) { ingredient in
    HStack {
        IngredientImageView(
            spoonacularIngredient: ingredient, 
            size: 60
        )
        Text(ingredient.name)
    }
}
```

## Placeholder Design

When no image is available, shows:
- Gradient gray background
- Orange carrot icon 🥕
- "No Image" text (for larger sizes)
- Consistent rounded rectangle shape

## Performance Benefits

### Without Cache:
- 6-10 network requests per ingredient
- ~2-3 seconds per ingredient
- Repeated requests for same ingredient

### With Cache:
- 0 network requests (cached)
- Instant display
- One-time discovery cost

## Migration Strategy

Existing recipes will automatically benefit:
1. First view: discovers and caches
2. Subsequent views: uses cache
3. Gradual learning as users browse

## Future Enhancements

- [ ] Bulk test all 992 ingredients
- [ ] Export/import mapping database
- [ ] Image quality preferences (100x100 vs 500x500)
- [ ] Custom user-uploaded images
- [ ] Cloud sync of mappings

## Statistics Example

After initial testing:
```
📊 DATABASE STATISTICS
============================================================
Total entries: 36
✅ Successful mappings: 18
❌ No image available: 18
⏳ Untested: 0
============================================================
```

## Error Handling

- Invalid ingredient ID → Shows placeholder
- Network failure → Retries with next URL
- All URLs fail → Records as "no image"
- Cache miss → Automatically discovers and saves
