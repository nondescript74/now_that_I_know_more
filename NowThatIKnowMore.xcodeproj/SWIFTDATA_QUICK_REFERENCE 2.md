# SwiftData Quick Reference Card

## Common Patterns for Recipe App

### Setup in View

```swift
import SwiftUI
import SwiftData

struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [RecipeModel]
    
    var body: some View {
        // Your view code
    }
}
```

---

## CRUD Operations

### Create (Add)

```swift
func addRecipe() {
    let recipe = RecipeModel(
        title: "New Recipe",
        servings: 4,
        vegetarian: true
    )
    modelContext.insert(recipe)
    try? modelContext.save()
}
```

### Read (Query)

```swift
// Simple query - all recipes
@Query(sort: \RecipeModel.title) 
private var recipes: [RecipeModel]

// Filtered query - vegetarian only
@Query(
    filter: #Predicate<RecipeModel> { recipe in
        recipe.vegetarian == true
    },
    sort: \RecipeModel.title
) 
private var vegetarianRecipes: [RecipeModel]

// Find by UUID
func findRecipe(uuid: UUID) -> RecipeModel? {
    let descriptor = FetchDescriptor<RecipeModel>(
        predicate: #Predicate { $0.uuid == uuid }
    )
    return try? modelContext.fetch(descriptor).first
}
```

### Update

```swift
func updateRecipe(_ recipe: RecipeModel) {
    recipe.title = "Updated Title"
    recipe.servings = 6
    recipe.modifiedAt = Date()
    try? modelContext.save()
}
```

### Delete

```swift
func deleteRecipe(_ recipe: RecipeModel) {
    modelContext.delete(recipe)
    try? modelContext.save()
}

// Delete from list with swipe
.onDelete(perform: deleteRecipes)

private func deleteRecipes(at offsets: IndexSet) {
    withAnimation {
        for index in offsets {
            modelContext.delete(recipes[index])
        }
        try? modelContext.save()
    }
}
```

---

## Filtering & Sorting

### Multiple Conditions

```swift
@Query(
    filter: #Predicate<RecipeModel> { recipe in
        recipe.vegetarian == true && 
        recipe.glutenFree == true &&
        (recipe.readyInMinutes ?? 999) < 30
    },
    sort: \RecipeModel.title
)
private var quickVegetarianRecipes: [RecipeModel]
```

### Search

```swift
@State private var searchText = ""

var filteredRecipes: [RecipeModel] {
    if searchText.isEmpty {
        return recipes
    }
    return recipes.filter { recipe in
        recipe.title?.localizedCaseInsensitiveContains(searchText) == true
    }
}
```

### Sort Descriptors

```swift
@Query(sort: [
    SortDescriptor(\RecipeModel.modifiedAt, order: .reverse),
    SortDescriptor(\RecipeModel.title)
])
private var recentRecipes: [RecipeModel]
```

---

## Relationships

### Add Recipe to Book

```swift
func addRecipe(_ recipe: RecipeModel, toBook book: RecipeBookModel) {
    if book.recipes == nil {
        book.recipes = []
    }
    book.recipes?.append(recipe)
    book.modifiedAt = Date()
    try? modelContext.save()
}
```

### Remove Recipe from Book

```swift
func removeRecipe(_ recipe: RecipeModel, fromBook book: RecipeBookModel) {
    book.recipes?.removeAll { $0.uuid == recipe.uuid }
    book.modifiedAt = Date()
    try? modelContext.save()
}
```

### Add Media to Recipe

```swift
func addPhoto(image: UIImage, to recipe: RecipeModel) {
    guard let fileURL = RecipeMediaModel.saveImage(image, for: recipe.uuid) else {
        return
    }
    
    let media = RecipeMediaModel(
        fileURL: fileURL,
        type: .photo,
        recipe: recipe
    )
    
    modelContext.insert(media)
    recipe.modifiedAt = Date()
    try? modelContext.save()
}
```

### Add Note to Recipe

```swift
func addNote(text: String, to recipe: RecipeModel, pinned: Bool = false) {
    let note = RecipeNoteModel(
        content: text,
        isPinned: pinned,
        tags: [],
        recipe: recipe
    )
    
    modelContext.insert(note)
    recipe.modifiedAt = Date()
    try? modelContext.save()
}
```

---

## Advanced Queries

### Dynamic Predicate

```swift
func fetchRecipes(
    vegetarian: Bool? = nil,
    vegan: Bool? = nil,
    maxTime: Int? = nil
) -> [RecipeModel] {
    var descriptor = FetchDescriptor<RecipeModel>(
        sortBy: [SortDescriptor(\RecipeModel.title)]
    )
    
    // Build predicate dynamically
    descriptor.predicate = #Predicate { recipe in
        (vegetarian == nil || recipe.vegetarian == vegetarian!) &&
        (vegan == nil || recipe.vegan == vegan!) &&
        (maxTime == nil || (recipe.readyInMinutes ?? 999) <= maxTime!)
    }
    
    return (try? modelContext.fetch(descriptor)) ?? []
}
```

### Fetch Count

```swift
func recipeCount() -> Int {
    let descriptor = FetchDescriptor<RecipeModel>()
    return (try? modelContext.fetchCount(descriptor)) ?? 0
}
```

### Batch Operations

```swift
func deleteAllRecipes() {
    let recipes = (try? modelContext.fetch(FetchDescriptor<RecipeModel>())) ?? []
    for recipe in recipes {
        modelContext.delete(recipe)
    }
    try? modelContext.save()
}
```

---

## Error Handling

### Safe Save

```swift
func saveContext() {
    do {
        try modelContext.save()
        print("✅ Saved successfully")
    } catch {
        print("❌ Save failed: \(error.localizedDescription)")
        // Optionally show alert to user
    }
}
```

### Rollback Changes

```swift
func cancelChanges() {
    modelContext.rollback()
}
```

---

## Testing & Debugging

### Preview Container

```swift
#Preview {
    MyView()
        .modelContainer(try! ModelContainer.preview())
}
```

### Print All Recipes

```swift
func debugPrintRecipes() {
    let recipes = (try? modelContext.fetch(FetchDescriptor<RecipeModel>())) ?? []
    print("📚 Total recipes: \(recipes.count)")
    for recipe in recipes {
        print("  • \(recipe.title ?? "Untitled") (UUID: \(recipe.uuid.uuidString))")
    }
}
```

### Check for Orphaned Records

```swift
func findOrphanedMedia() -> [RecipeMediaModel] {
    let descriptor = FetchDescriptor<RecipeMediaModel>()
    let allMedia = (try? modelContext.fetch(descriptor)) ?? []
    return allMedia.filter { $0.recipe == nil }
}
```

---

## Common Gotchas

### ❌ DON'T: Modify @Query directly

```swift
// This won't work:
@Query private var recipes: [RecipeModel]
recipes.append(newRecipe) // ❌ Error: Cannot modify let constant
```

### ✅ DO: Insert into modelContext

```swift
@Query private var recipes: [RecipeModel]
modelContext.insert(newRecipe) // ✅ Correct
```

---

### ❌ DON'T: Forget to save

```swift
recipe.title = "New Title"
// Missing save!
```

### ✅ DO: Always save after changes

```swift
recipe.title = "New Title"
try? modelContext.save() // ✅ Correct
```

---

### ❌ DON'T: Use RecipeStore methods

```swift
store.add(recipe) // ❌ Old way
store.remove(recipe) // ❌ Old way
```

### ✅ DO: Use modelContext

```swift
modelContext.insert(recipe) // ✅ New way
modelContext.delete(recipe) // ✅ New way
```

---

## Migration Checklist

When updating a view from RecipeStore to SwiftData:

- [ ] Add `import SwiftData`
- [ ] Replace `@Environment(RecipeStore.self)` with `@Environment(\.modelContext)`
- [ ] Add `@Query` for recipe list
- [ ] Replace `store.add()` with `modelContext.insert()`
- [ ] Replace `store.remove()` with `modelContext.delete()`
- [ ] Replace `store.update()` with direct property changes + save
- [ ] Replace `store.recipes` with query result
- [ ] Add `try? modelContext.save()` after changes
- [ ] Test all CRUD operations
- [ ] Verify changes persist after app restart

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Recipe not appearing | Check @Query predicate isn't filtering it out |
| Changes not saving | Add `try? modelContext.save()` |
| "Cannot find RecipeModel" | Import SwiftData |
| Duplicate recipes | Check UUID is unique, clean up duplicates |
| Crash on delete | Verify cascade delete rules are set correctly |
| Orphaned media | Check relationship is set: `media.recipe = recipe` |

---

## File Locations

```
Models/
├── RecipeModel.swift              - Main recipe data
├── RecipeMediaModel.swift         - Photos/videos
├── RecipeNoteModel.swift          - User notes
├── RecipeBookModel.swift          - Collections
└── ModelContainer+Configuration.swift - Container setup

Services/
└── RecipeService.swift            - Business logic

Views/
├── RecipeBooksView.swift          - Manage books
├── RecipeMediaView.swift          - Photo gallery
├── RecipeNotesView.swift          - Notes UI
└── RecipeDiagnosticView.swift    - Debug tool
```

---

**Quick Help:** 
- For full architecture: See `SWIFTDATA_ARCHITECTURE.md`
- For migration: See `MEALPLAN_SWIFTDATA_FIX_GUIDE.md`
- For consolidation: See `SWIFTDATA_CONSOLIDATION_PLAN.md`

**Last Updated:** November 8, 2025
