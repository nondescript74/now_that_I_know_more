# Migration Guide: RecipeStore to SwiftData

## Overview

This guide explains how to transition your app from the legacy `RecipeStore` (JSON file persistence) to the new SwiftData architecture.

## What Changed

### Before (RecipeStore)
```swift
@Observable class RecipeStore {
    private(set) var recipes: [Recipe] = []
    
    func add(_ recipe: Recipe) {
        recipes.append(recipe)
        saveAll() // Saves to JSON file
    }
}

// In your view
@Environment(RecipeStore.self) private var store: RecipeStore
let recipes = store.recipes
```

### After (SwiftData)
```swift
@MainActor
class RecipeService {
    private let modelContext: ModelContext
    
    func addRecipe(_ recipe: RecipeModel) {
        modelContext.insert(recipe)
        try? modelContext.save()
    }
}

// In your view
@Environment(\.modelContext) private var modelContext
@Query private var recipes: [RecipeModel]
```

## Migration Steps

### Step 1: Update App Initialization

**Old:**
```swift
@main
struct NowThatIKnowMoreApp: App {
    @State private var store: RecipeStore = RecipeStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
```

**New:**
```swift
@main
struct NowThatIKnowMoreApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await migrateLegacyRecipes()
                }
        }
        .modelContainer(modelContainer)
    }
}
```

### Step 2: Automatic Data Migration

The app automatically migrates your existing recipes on first launch. No manual intervention required!

```swift
private func migrateLegacyRecipes() async {
    let migrationKey = "hasCompletedSwiftDataMigration"
    guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
    
    let legacyRecipes = store.recipes
    guard !legacyRecipes.isEmpty else {
        UserDefaults.standard.set(true, forKey: migrationKey)
        return
    }
    
    let service = RecipeService(modelContext: modelContainer.mainContext)
    await MainActor.run {
        service.batchMigrateLegacyRecipes(legacyRecipes)
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
```

**What Gets Migrated:**
- ✅ All recipe data
- ✅ Media items (photos/videos)
- ✅ User notes
- ✅ Recipe books (if you had custom collections)
- ✅ All relationships between entities

### Step 3: Update Your Views

#### Recipe List View

**Old:**
```swift
struct RecipeList: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    
    var body: some View {
        List(store.recipes) { recipe in
            Text(recipe.title ?? "Untitled")
        }
    }
}
```

**New:**
```swift
struct RecipeList: View {
    @Query(sort: \.modifiedAt, order: .reverse) 
    private var recipes: [RecipeModel]
    
    var body: some View {
        List(recipes) { recipe in
            Text(recipe.title ?? "Untitled")
        }
    }
}
```

#### Adding a Recipe

**Old:**
```swift
func addRecipe() {
    let recipe = Recipe(from: ["title": "New Recipe"])!
    store.add(recipe)
}
```

**New:**
```swift
@Environment(\.modelContext) private var modelContext

func addRecipe() {
    let recipe = RecipeModel(title: "New Recipe")
    modelContext.insert(recipe)
    try? modelContext.save()
}
```

#### Updating a Recipe

**Old:**
```swift
func updateRecipe(_ recipe: Recipe) {
    var updated = recipe
    updated.title = "Updated Title"
    store.update(updated)
}
```

**New:**
```swift
func updateRecipe(_ recipe: RecipeModel) {
    recipe.title = "Updated Title"
    recipe.modifiedAt = Date()
    try? modelContext.save()
}
```

#### Deleting a Recipe

**Old:**
```swift
func deleteRecipe(_ recipe: Recipe) {
    store.remove(recipe)
}
```

**New:**
```swift
@Environment(\.modelContext) private var modelContext

func deleteRecipe(_ recipe: RecipeModel) {
    modelContext.delete(recipe)
    try? modelContext.save()
}
```

#### Searching Recipes

**Old:**
```swift
var searchResults: [Recipe] {
    if searchQuery.isEmpty {
        return store.recipes
    }
    return store.recipes.filter { recipe in
        recipe.title?.localizedStandardContains(searchQuery) ?? false
    }
}
```

**New:**
```swift
@Query private var recipes: [RecipeModel]
@State private var searchQuery = ""

var searchResults: [RecipeModel] {
    if searchQuery.isEmpty {
        return recipes
    }
    return recipes.filter { recipe in
        recipe.title?.localizedStandardContains(searchQuery) ?? false
    }
}

// Or use RecipeService for more complex searches
let service = RecipeService(modelContext: modelContext)
let results = service.searchRecipes(query: searchQuery)
```

## Side-by-Side Comparison

| Task | Old (RecipeStore) | New (SwiftData) |
|------|-------------------|-----------------|
| **Initialize** | `@State var store = RecipeStore()` | `@Environment(\.modelContext) var modelContext` |
| **Fetch All** | `store.recipes` | `@Query var recipes: [RecipeModel]` |
| **Add** | `store.add(recipe)` | `modelContext.insert(recipe); try? modelContext.save()` |
| **Update** | `store.update(recipe)` | `recipe.property = value; try? modelContext.save()` |
| **Delete** | `store.remove(recipe)` | `modelContext.delete(recipe); try? modelContext.save()` |
| **Search** | Manual filter on array | `RecipeService.searchRecipes(query:)` |
| **Persistence** | JSON file | SQLite database |
| **Relationships** | Manual management | Automatic via `@Relationship` |

## Common Migration Issues

### Issue 1: Recipe Not Found After Migration

**Problem:** You're looking for a recipe by ID, but it's not found in SwiftData.

**Solution:** The migration preserves UUIDs, so lookups by UUID should work. Make sure you're using `RecipeModel` instead of `Recipe`:

```swift
// Old
let recipe = store.recipe(with: uuid)

// New
let service = RecipeService(modelContext: modelContext)
let recipe = service.fetchRecipe(uuid: uuid)
```

### Issue 2: Duplicate Recipes

**Problem:** Recipes appear twice after migration.

**Solution:** The migration checks for existing recipes by UUID. If you see duplicates, reset the migration:

```swift
// Clear migration flag
UserDefaults.standard.removeObject(forKey: "hasCompletedSwiftDataMigration")

// Delete SwiftData store
let storeURL = FileManager.default.urls(
    for: .applicationSupportDirectory, 
    in: .userDomainMask
)[0].appendingPathComponent("default.store")
try? FileManager.default.removeItem(at: storeURL)

// Restart app - migration will run again
```

### Issue 3: Media Items Not Showing

**Problem:** Photos aren't appearing after migration.

**Solution:** The migration copies media items to SwiftData, but the file paths should remain the same. Check file permissions:

```swift
let mediaFolder = FileManager.default.urls(
    for: .documentDirectory, 
    in: .userDomainMask
)[0].appendingPathComponent("RecipeMedia")

// Ensure folder exists
try? FileManager.default.createDirectory(
    at: mediaFolder, 
    withIntermediateDirectories: true
)
```

### Issue 4: Notes Missing Tags

**Problem:** Note tags aren't displaying correctly.

**Solution:** Tags are migrated from the legacy format. Verify the `tagsList` property is being used:

```swift
// Correct
let tags = note.tagsList  // Returns [String]

// Incorrect
let tags = note.tags  // Returns String? (comma-separated)
```

## Testing Your Migration

### 1. Backup Your Data

Before migrating, create a backup of your recipes:

```swift
func backupRecipes() {
    let store = RecipeStore()
    let backupURL = FileManager.default.urls(
        for: .documentDirectory, 
        in: .userDomainMask
    )[0].appendingPathComponent("recipes_backup.json")
    
    if let data = try? JSONEncoder().encode(store.recipes) {
        try? data.write(to: backupURL)
        print("✅ Backup saved to: \(backupURL.path)")
    }
}
```

### 2. Verify Migration Success

Add this to your app's debug menu:

```swift
func verifyMigration() {
    let store = RecipeStore()
    let legacyCount = store.recipes.count
    
    let service = RecipeService(modelContext: modelContext)
    let migratedCount = service.fetchRecipes().count
    
    print("Legacy recipes: \(legacyCount)")
    print("Migrated recipes: \(migratedCount)")
    
    if legacyCount == migratedCount {
        print("✅ Migration successful!")
    } else {
        print("⚠️ Recipe count mismatch")
    }
}
```

### 3. Compare Recipe Data

```swift
func compareRecipe(uuid: UUID) {
    // Legacy
    let store = RecipeStore()
    let legacyRecipe = store.recipe(with: uuid)
    
    // SwiftData
    let service = RecipeService(modelContext: modelContext)
    let migratedRecipe = service.fetchRecipe(uuid: uuid)
    
    print("Legacy title: \(legacyRecipe?.title ?? "nil")")
    print("Migrated title: \(migratedRecipe?.title ?? "nil")")
    
    print("Legacy media count: \(legacyRecipe?.mediaItems?.count ?? 0)")
    print("Migrated media count: \(migratedRecipe?.mediaItems?.count ?? 0)")
}
```

## Rollback Plan

If you need to rollback to the old system:

### 1. Keep RecipeStore Code

Don't delete `RecipeStore.swift` until you're confident the migration worked.

### 2. Export from SwiftData

```swift
func exportToLegacyFormat() {
    let service = RecipeService(modelContext: modelContext)
    let recipes = service.fetchRecipes()
    
    // Convert to legacy Recipe structs
    let legacyRecipes = recipes.compactMap { $0.toLegacyRecipe() }
    
    // Save to JSON
    let store = RecipeStore()
    store.set(legacyRecipes)
}
```

### 3. Revert App Code

```swift
// In NowThatIKnowMoreApp.swift
@State private var store: RecipeStore = RecipeStore()

var body: some Scene {
    WindowGroup {
        ContentView()
            .environment(store)
    }
    // Remove .modelContainer() modifier
}
```

## Performance Improvements

SwiftData provides several performance benefits over the old JSON approach:

### 1. Lazy Loading
```swift
// Old: All recipes loaded into memory
let recipes = store.recipes  // Loads everything

// New: Only fetch what you need
@Query(
    filter: #Predicate<RecipeModel> { $0.vegetarian == true },
    limit: 20
) 
private var recentVegetarianRecipes: [RecipeModel]
```

### 2. Incremental Updates
```swift
// Old: Save entire recipes array
store.update(recipe)  // Saves all recipes to JSON

// New: Save only changed data
recipe.title = "Updated"
try? modelContext.save()  // Only saves changes
```

### 3. Efficient Queries
```swift
// Old: Filter in memory
let veganRecipes = store.recipes.filter { $0.vegan == true }

// New: Database-level filtering
@Query(filter: #Predicate<RecipeModel> { $0.vegan == true })
private var veganRecipes: [RecipeModel]
```

## Next Steps

After successful migration:

1. ✅ Test all recipe operations (CRUD)
2. ✅ Verify media files are accessible
3. ✅ Check note content and tags
4. ✅ Test search and filtering
5. ✅ Verify recipe book relationships
6. ✅ Test on multiple devices
7. ✅ Run performance tests with large datasets
8. ✅ Consider removing RecipeStore code

## Getting Help

If you encounter issues during migration:

1. Check the console for error messages
2. Review the `SWIFTDATA_ARCHITECTURE.md` guide
3. Verify your model definitions match the examples
4. Test with the preview container first
5. Use the backup/rollback procedures if needed

## Additional Resources

- `SWIFTDATA_ARCHITECTURE.md` - Complete architecture documentation
- `RecipeService.swift` - Service layer implementation
- `ModelContainer+Configuration.swift` - Container setup
- `RecipeBooksView.swift` - Example SwiftData usage
- `RecipeMediaView.swift` - Media management example
- `RecipeNotesView.swift` - Notes management example

---

**Last Updated:** November 7, 2025
**Migration Version:** 1.0
