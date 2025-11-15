# Quick Start: Using the SwiftData Image System

## For Developers Adding New Views

### 1. Display Ingredient Images (Simplest)

```swift
import SwiftUI

struct MyIngredientList: View {
    let ingredients: [ExtendedIngredient]
    
    var body: some View {
        List(ingredients, id: \.id) { ingredient in
            HStack {
                // That's it! Just use IngredientImageView
                IngredientImageView(ingredient: ingredient, size: 50)
                
                Text(ingredient.name ?? "")
            }
        }
    }
}
```

**Requirements:**
- View must have `@Environment(\.modelContext)` in its hierarchy
- That's it! Caching is automatic.

### 2. Custom Ingredient Cards

```swift
struct IngredientCard: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        VStack {
            // Larger size for cards
            IngredientImageView(ingredient: ingredient, size: 100)
            
            Text(ingredient.name ?? "")
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
```

### 3. Different Ingredient Types

```swift
// From ExtendedIngredient (most common)
IngredientImageView(ingredient: extendedIngredient, size: 50)

// From SpoonacularIngredient
IngredientImageView(spoonacularIngredient: spoonacularIngredient, size: 50)

// From raw ID and name
IngredientImageView(
    ingredientID: 11215,
    ingredientName: "garlic",
    size: 50
)
```

### 4. Manual Service Usage (Advanced)

If you need more control:

```swift
struct CustomView: View {
    @Environment(\.modelContext) private var modelContext
    let ingredientID: Int
    let ingredientName: String
    
    @State private var imageURL: URL?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let url = imageURL {
                AsyncImage(url: url) { phase in
                    // Your custom image handling
                }
            } else {
                Text("No image")
            }
        }
        .task {
            // Create service
            let service = IngredientImageMappingService(modelContext: modelContext)
            
            // Get URL (cached or tested)
            imageURL = await service.getImageURL(
                forIngredientID: ingredientID,
                name: ingredientName
            )
            
            isLoading = false
        }
    }
}
```

## Common Patterns

### Ingredient Grid

```swift
struct IngredientGrid: View {
    let ingredients: [ExtendedIngredient]
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ingredients, id: \.id) { ingredient in
                    VStack {
                        IngredientImageView(
                            ingredient: ingredient,
                            size: 80
                        )
                        Text(ingredient.name ?? "")
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
        }
    }
}
```

### Ingredient Row with Details

```swift
struct DetailedIngredientRow: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        HStack(spacing: 12) {
            IngredientImageView(ingredient: ingredient, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name ?? "")
                    .font(.headline)
                
                if let original = ingredient.original {
                    Text(original)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let aisle = ingredient.aisle {
                    Label(aisle, systemImage: "cart.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
```

### Ingredient with Actions

```swift
struct ActionableIngredientRow: View {
    let ingredient: ExtendedIngredient
    @State private var isChecked = false
    
    var body: some View {
        HStack {
            IngredientImageView(ingredient: ingredient, size: 50)
            
            Text(ingredient.name ?? "")
            
            Spacer()
            
            Button {
                isChecked.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .green : .gray)
            }
        }
    }
}
```

## Size Guidelines

- **Small (40px)**: Compact lists, inline text
- **Medium (50-60px)**: Standard lists, cards
- **Large (80-100px)**: Grid views, featured ingredients
- **Extra Large (120px+)**: Detail views, hero images

## Error Handling

The view automatically handles:
- ✅ Loading states (spinner)
- ✅ Missing images (placeholder with icon)
- ✅ Network failures (orange warning indicator)
- ✅ Invalid IDs (graceful fallback)

You don't need to handle these manually!

## Performance Tips

### ✅ Do

```swift
// Create view once, reuse in List
ForEach(ingredients, id: \.id) { ingredient in
    IngredientImageView(ingredient: ingredient, size: 50)
}
```

### ❌ Don't

```swift
// Don't create new service for each image
ForEach(ingredients, id: \.id) { ingredient in
    CustomImageView(ingredient: ingredient) // Creates service per view
}
```

### ✅ Do

```swift
// Use LazyVStack/LazyVGrid for large lists
LazyVStack {
    ForEach(ingredients, id: \.id) { ingredient in
        IngredientImageView(ingredient: ingredient, size: 50)
    }
}
```

### ❌ Don't

```swift
// Don't load all images upfront in VStack
VStack { // Not lazy!
    ForEach(1...1000) { ... } // All load at once
}
```

## Debugging

### Check if Caching Works

Add this temporary code:

```swift
.task {
    let service = IngredientImageMappingService(modelContext: modelContext)
    let stats = service.getStatistics()
    print("📊 Cache Stats: \(stats.total) total, \(stats.successful) successful")
}
```

### Check Individual Ingredient

```swift
.task {
    let service = IngredientImageMappingService(modelContext: modelContext)
    if let mapping = service.mapping(forIngredientID: 11215) {
        print("✅ Cached: \(mapping.imageFilename ?? "nil")")
    } else {
        print("❌ Not cached")
    }
}
```

### Clear Cache (for testing)

```swift
Button("Clear Cache") {
    let service = IngredientImageMappingService(modelContext: modelContext)
    service.deleteAllMappings()
    print("🗑️ Cache cleared")
}
```

## Common Issues

### Images Not Loading?

**Check:**
1. Is `modelContext` in environment?
   ```swift
   .modelContainer(try! ModelContainer.create())
   ```

2. Does ingredient have ID?
   ```swift
   print(ingredient.id ?? -1) // Should not be nil
   ```

3. Is SwiftData configured?
   ```swift
   // In ModelContainer.create()
   for: IngredientImageMappingModel.self // Must be registered
   ```

### Images Loading Slowly?

**First time is expected!** Each ingredient:
1. Tests multiple URLs (garlic.jpg, garlic.png, etc.)
2. Saves successful URL to cache
3. Next time: instant from cache

**To speed up:**
- Consider prefetching when importing recipes
- Or accept slight delay on first view

### Placeholder Showing?

Three reasons:
1. **Loading**: Temporary, wait a moment
2. **No Image**: Ingredient not in Spoonacular database
3. **Network Error**: Check internet connection

Orange warning icon = no image found (cached, won't retry)

## Questions?

See full documentation:
- **`SWIFTDATA_IMAGE_INTEGRATION.md`** - Complete guide
- **`INTEGRATION_COMPLETE.md`** - What's implemented
- **`IngredientImageMappingModel.swift`** - Source code

## Need Help?

Check console logs for detailed information:
- `🔍` = Testing URLs
- `✅` = Success (cached)
- `📝` = Saved to cache
- `⚠️` = No image found
- `ℹ️` = Using cached data
