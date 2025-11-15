# SwiftData Image Mapping Integration Guide

## Overview

The ingredient image system in NowThatIKnowMore now uses **SwiftData for persistent caching** of ingredient image URL mappings. This eliminates redundant network requests and provides a smooth, performant experience when displaying ingredient images across the app.

## Architecture

### Core Components

1. **`IngredientImageMappingModel`** (SwiftData Model)
   - Persists ingredient image URL mappings
   - Stores metadata about tested URLs, success/failure states
   - Unique constraint on `ingredientID`

2. **`IngredientImageMappingService`** (Service Layer)
   - Provides high-level API for image URL lookup
   - Handles intelligent URL generation and testing
   - Manages cache persistence via ModelContext

3. **`IngredientImageView`** (SwiftUI View)
   - Reusable view component for displaying ingredient images
   - Automatically uses caching via `IngredientImageMappingService`
   - Shows loading states and error indicators

## How It Works

### 1. First Load (No Cache)

When an ingredient image is requested for the first time:

```swift
let service = IngredientImageMappingService(modelContext: modelContext)
let url = await service.getImageURL(forIngredientID: 11215, name: "garlic")
```

**Process:**
1. Service checks SwiftData for existing mapping
2. No mapping found → generates candidate URLs:
   - `garlic.jpg`
   - `garlic.png`
   - `garlics.jpg` (plural variation)
   - etc.
3. Tests each URL sequentially via `URLSession`
4. First successful URL:
   - Saved to SwiftData with metadata
   - Returned to caller
5. If all fail:
   - Records `noImageAvailable = true`
   - Returns `nil`

### 2. Subsequent Loads (Cached)

On subsequent requests:

```swift
let url = await service.getImageURL(forIngredientID: 11215, name: "garlic")
// Returns immediately: https://spoonacular.com/cdn/ingredients_100x100/garlic.jpg
```

**Process:**
1. Service checks SwiftData
2. Mapping found with `tested = true`
3. If `noImageAvailable = true` → returns `nil` immediately
4. Otherwise → returns cached URL directly
5. **No network requests needed!**

## Integration in Views

### Using `IngredientImageView` (Recommended)

The simplest way to display ingredient images:

```swift
import SwiftUI
import SwiftData

struct MyRecipeView: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        HStack {
            // Automatically uses SwiftData caching
            IngredientImageView(ingredient: ingredient, size: 50)
            
            Text(ingredient.name ?? "")
        }
    }
}
```

**Key Features:**
- ✅ Automatic caching via SwiftData
- ✅ Loading states handled
- ✅ Error states with visual feedback
- ✅ Requires ModelContext from environment

### Manual Integration

If you need more control:

```swift
struct CustomIngredientView: View {
    @Environment(\.modelContext) private var modelContext
    let ingredient: ExtendedIngredient
    
    @State private var imageURL: URL?
    
    var body: some View {
        AsyncImage(url: imageURL) { phase in
            // Handle phases...
        }
        .task {
            let service = IngredientImageMappingService(modelContext: modelContext)
            imageURL = await service.getImageURL(
                forIngredientID: ingredient.id ?? 0,
                name: ingredient.name ?? ""
            )
        }
    }
}
```

## Current Integration Points

### ✅ Already Integrated

1. **`RecipeDetail.swift`**
   - `IngredientRowView` uses `IngredientImageView`
   - Displays ingredient thumbnails with smart caching
   - Supports ingredient mapping via picker

2. **`IngredientImageView.swift`**
   - Core reusable component
   - Full SwiftData integration
   - Convenience initializers for common types

3. **`RecipeEditorView.swift`**
   - Ingredient matcher uses image previews
   - Images automatically cached during selection

### 🔄 To Be Verified

Check these views to ensure they're using the new system:

1. **`RecipeImportPreviewView.swift`**
   - Should display ingredient images in preview
   - May need to add `IngredientImageView` if showing ingredients

2. **`MealPlan.swift`**
   - If displaying ingredients, should use `IngredientImageView`

3. Any custom recipe cards or ingredient lists

## ModelContainer Configuration

Ensure `IngredientImageMappingModel` is registered:

```swift
// In ModelsModelContainer+Configuration.swift
extension ModelContainer {
    static func create() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(
            for: RecipeModel.self,
            RecipeMediaModel.self,
            RecipeNoteModel.self,
            RecipeBookModel.self,
            IngredientImageMappingModel.self,  // ✅ Already added
            configurations: config
        )
    }
}
```

## Testing the Integration

### Test Cases

1. **First Load**
   ```
   1. Clear app data or use fresh install
   2. Open a recipe with ingredients
   3. Observe: Loading spinners → Images load
   4. Console: "📝 Saved mapping: garlic → garlic.jpg"
   ```

2. **Cached Load**
   ```
   1. Close and reopen the app
   2. Open the same recipe
   3. Observe: Images load instantly
   4. Console: "✅ Using cached mapping: garlic → garlic.jpg"
   ```

3. **Missing Images**
   ```
   1. View ingredient with no Spoonacular image
   2. Observe: Placeholder with warning icon
   3. Console: "📝 Recorded no image available: unknown-ingredient"
   4. Next load: Instant placeholder (no network request)
   ```

### Debug Logging

The system includes extensive logging:

```
🔍 [IngredientImageView] Testing ingredient image: garlic
✅ [IngredientImageView] Loaded image for 'garlic' (ID: 11215)
📝 [IngredientImageMappingService] Saved mapping: garlic → garlic.jpg
ℹ️ [IngredientImageMappingService] Known to have no image: exotic-spice
```

## Performance Benefits

### Before (Without Caching)
- Every view appearance triggers network requests
- 10-20 ingredients × 3-5 URL attempts = **30-100 network requests**
- Slow scrolling, repeated failed attempts
- High battery drain

### After (With SwiftData Caching)
- First load: Tests and caches once per ingredient
- Subsequent loads: **Zero network requests**
- Instant image display
- Minimal battery impact

## Best Practices

### ✅ Do

1. Use `IngredientImageView` whenever possible
2. Ensure `modelContext` is in environment
3. Let the service handle URL testing and caching
4. Check console logs during development

### ❌ Don't

1. Manually construct ingredient image URLs
2. Test URLs without saving results to cache
3. Bypass the service layer for "performance"
4. Clear SwiftData cache unnecessarily

## Troubleshooting

### Images Not Loading

**Check:**
1. Is `modelContext` available in environment?
2. Is `IngredientImageMappingModel` in ModelContainer?
3. Does ingredient have valid `id` and `name`?

**Debug:**
```swift
// Add temporary logging
print("🔍 Ingredient ID: \(ingredient.id ?? -1)")
print("🔍 Ingredient Name: \(ingredient.name ?? "nil")")
print("🔍 ModelContext: \(modelContext)")
```

### Cache Not Persisting

**Check:**
1. Is `ModelConfiguration` set to `isStoredInMemoryOnly: false`?
2. Are you calling `try? modelContext.save()` after changes?
3. Is the app properly saving on backgrounding?

### Slow Performance

**Check:**
1. Are you creating multiple `IngredientImageMappingService` instances?
   - Should create once per view/task
2. Are images being tested on main thread?
   - Service uses `async/await` to prevent blocking

## Migration Guide

If you have existing views displaying ingredient images:

### Before
```swift
struct OldIngredientView: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        if let imageName = ingredient.image {
            let url = URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(imageName)")
            AsyncImage(url: url) { ... }
        }
    }
}
```

### After
```swift
struct NewIngredientView: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        IngredientImageView(ingredient: ingredient, size: 50)
    }
}
```

**Benefits:**
- Automatic caching
- Error handling
- Loading states
- Consistent styling

## Future Enhancements

Potential improvements to the system:

1. **Prefetching**
   - Batch test ingredients when recipe is first imported
   - Background task to populate cache

2. **Analytics**
   - Track cache hit rate
   - Identify frequently missing ingredients

3. **User Customization**
   - Allow users to upload custom ingredient images
   - Override Spoonacular URLs with local images

4. **Expiration**
   - Add TTL to cached mappings
   - Re-verify old entries periodically

## Summary

The SwiftData-based ingredient image system provides:

✅ **Fast** - Cached images load instantly  
✅ **Efficient** - No redundant network requests  
✅ **Reliable** - Handles missing images gracefully  
✅ **Simple** - Drop-in `IngredientImageView` component  
✅ **Persistent** - Cache survives app restarts  

**All views displaying ingredients should now use this system for optimal performance!**
