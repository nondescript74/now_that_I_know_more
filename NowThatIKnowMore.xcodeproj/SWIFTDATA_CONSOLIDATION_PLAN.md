# SwiftData Consolidation Plan

## Problem Statement

The app currently has **double bookkeeping** where recipes exist in both:
1. **Legacy RecipeStore** (JSON file persistence)
2. **SwiftData** (RecipeModel persistence)

### Current Issues

1. **MealPlan view deletes recipes from RecipeStore but NOT from SwiftData**
2. When adding recipes to books via RecipeBooksView, **all SwiftData recipes appear** (including those "deleted" in MealPlan)
3. This creates confusion where recipes appear deleted but still exist in the database
4. Need to verify all SwiftData recipes have valid IDs

## Solution Overview

We will:
1. **Eliminate RecipeStore entirely** - SwiftData becomes the single source of truth
2. **Update MealPlan view** to use SwiftData @Query instead of RecipeStore
3. **Verify all recipes have valid UUIDs and IDs**
4. **Remove RecipeStore from app environment**

## Step 1: Verify Recipe Data Integrity

### Check for Invalid IDs

Create a utility to verify all recipes in SwiftData:

```swift
@MainActor
func verifyRecipeIntegrity() {
    let service = RecipeService(modelContext: modelContext)
    let allRecipes = service.fetchAllRecipes()
    
    print("📊 SwiftData Recipe Audit:")
    print("   Total recipes: \(allRecipes.count)")
    
    // Check for missing UUIDs (should never happen since it's required)
    let recipesWithoutUUID = allRecipes.filter { $0.uuid.uuidString.isEmpty }
    print("   Recipes without UUID: \(recipesWithoutUUID.count)")
    
    // Check for missing IDs (Spoonacular API ID)
    let recipesWithoutID = allRecipes.filter { $0.id == nil }
    print("   Recipes without API ID: \(recipesWithoutID.count)")
    
    // Check for missing titles
    let recipesWithoutTitle = allRecipes.filter { $0.title == nil || $0.title?.isEmpty == true }
    print("   Recipes without title: \(recipesWithoutTitle.count)")
    
    // List all recipe UUIDs
    print("\n📋 All Recipe UUIDs:")
    for recipe in allRecipes {
        print("   • \(recipe.uuid.uuidString) - \(recipe.title ?? "Untitled") (ID: \(recipe.id?.description ?? "none"))")
    }
}
```

## Step 2: Update MealPlan to Use SwiftData

### Current State (Legacy)
```swift
struct MealPlan: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    
    var body: some View {
        // Uses store.recipes
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        store.remove(recipe)  // ❌ Only removes from JSON store
    }
}
```

### New State (SwiftData)
```swift
struct MealPlan: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeModel.daysOfWeekString) 
    private var recipes: [RecipeModel]
    
    var body: some View {
        // Uses recipes from @Query
    }
    
    func deleteRecipe(_ recipe: RecipeModel) {
        modelContext.delete(recipe)  // ✅ Actually deletes from SwiftData
        try? modelContext.save()
    }
}
```

## Step 3: Remove RecipeStore from App

### Changes to NowThatIKnowMoreApp.swift

**Remove:**
```swift
@State private var store: RecipeStore = RecipeStore()
```

**Remove:**
```swift
.environment(store)
```

**Remove migration logic** (after confirming all data is in SwiftData):
```swift
private func migrateLegacyRecipes() async {
    // This can be removed after migration is complete
}
```

## Step 4: Update All Views Using RecipeStore

### Views to Update:

1. **MealPlan** - Switch to @Query
2. **RecipeDetail** (if using store) - Use RecipeModel directly
3. **Any search/filter views** - Use RecipeService queries
4. **Recipe import flows** - Import directly to SwiftData

### Pattern for Conversion

**Before:**
```swift
@Environment(RecipeStore.self) private var store: RecipeStore

// Access recipes
let myRecipes = store.recipes

// Add recipe
store.add(newRecipe)

// Update recipe
store.update(modifiedRecipe)

// Delete recipe
store.remove(recipe)

// Find recipe
let found = store.recipe(with: uuid)
```

**After:**
```swift
@Environment(\.modelContext) private var modelContext
@Query private var recipes: [RecipeModel]
@State private var recipeService: RecipeService?

// Access recipes
let myRecipes = recipes // From @Query

// Add recipe
let recipe = RecipeModel(...)
modelContext.insert(recipe)
try? modelContext.save()

// Update recipe
recipe.title = "New Title"
recipe.modifiedAt = Date()
try? modelContext.save()

// Delete recipe
modelContext.delete(recipe)
try? modelContext.save()

// Find recipe
recipeService?.fetchRecipe(by: uuid)
```

## Step 5: Clean Up Legacy Files

After verifying everything works:

1. **Delete RecipeStore.swift**
2. **Delete any Recipe store related utilities**
3. **Update all documentation** to remove RecipeStore references

## Step 6: Data Migration Safety

### Backup Before Changes

Users should be able to export their recipes before the change:

```swift
func exportAllRecipes() -> URL? {
    let service = RecipeService(modelContext: modelContext)
    let allRecipes = service.fetchAllRecipes()
    
    // Convert to JSON
    let recipeDicts = allRecipes.compactMap { $0.toLegacyRecipe() }
    
    guard let data = try? JSONEncoder().encode(recipeDicts) else {
        return nil
    }
    
    // Save to file
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("recipes_backup_\(Date().timeIntervalSince1970).json")
    
    try? data.write(to: fileURL)
    return fileURL
}
```

## Implementation Checklist

### Phase 1: Verification ✅
- [ ] Run recipe integrity check
- [ ] Verify all recipes have UUIDs
- [ ] Check for duplicate recipes
- [ ] Confirm all relationships are intact (books, media, notes)
- [ ] Export backup of all recipes

### Phase 2: MealPlan Update 🔄
- [ ] Locate MealPlan view file
- [ ] Replace @Environment(RecipeStore.self) with @Environment(\.modelContext)
- [ ] Replace recipe list with @Query
- [ ] Update delete operations to use modelContext.delete()
- [ ] Update any add/edit operations to use SwiftData
- [ ] Test all CRUD operations in MealPlan

### Phase 3: Remove RecipeStore 🗑️
- [ ] Remove RecipeStore initialization from app
- [ ] Remove .environment(store) from app
- [ ] Search for all @Environment(RecipeStore.self) usage
- [ ] Update all remaining views to use SwiftData
- [ ] Remove migration logic (keep for reference)
- [ ] Delete RecipeStore.swift file

### Phase 4: Testing 🧪
- [ ] Test recipe creation
- [ ] Test recipe editing
- [ ] Test recipe deletion from MealPlan
- [ ] Test recipe deletion from Books
- [ ] Test adding recipes to books
- [ ] Verify deleted recipes don't reappear
- [ ] Test app restart (data persistence)
- [ ] Test with fresh install (no migration)

### Phase 5: Documentation 📝
- [ ] Update README to remove RecipeStore references
- [ ] Update architecture docs
- [ ] Add note about SwiftData-only approach
- [ ] Document rollback procedure (if needed)

## Rollback Plan

If issues occur:

1. **Keep RecipeStore code** in git history
2. **Restore from backup** using export function
3. **Re-enable migration** if needed
4. **File bug report** with specific issue details

## Testing Commands

### View All SwiftData Recipes
```swift
let service = RecipeService(modelContext: modelContext)
let allRecipes = service.fetchAllRecipes()
print("Total recipes in SwiftData: \(allRecipes.count)")
for recipe in allRecipes {
    print("  \(recipe.uuid) | \(recipe.title ?? "No title") | ID: \(recipe.id?.description ?? "nil")")
}
```

### Delete All SwiftData Recipes (for testing)
```swift
let service = RecipeService(modelContext: modelContext)
service.deleteAllRecipes()
UserDefaults.standard.removeObject(forKey: "hasCompletedSwiftDataMigration")
```

### Check for Orphaned Records
```swift
// Check for media items without recipes
let descriptor = FetchDescriptor<RecipeMediaModel>()
let allMedia = try? modelContext.fetch(descriptor)
let orphanedMedia = allMedia?.filter { $0.recipe == nil } ?? []
print("Orphaned media items: \(orphanedMedia.count)")

// Check for notes without recipes
let noteDescriptor = FetchDescriptor<RecipeNoteModel>()
let allNotes = try? modelContext.fetch(noteDescriptor)
let orphanedNotes = allNotes?.filter { $0.recipe == nil } ?? []
print("Orphaned notes: \(orphanedNotes.count)")
```

## Expected Outcomes

After completion:

✅ **Single source of truth** - Only SwiftData stores recipes  
✅ **Proper deletion** - Recipes deleted in MealPlan are gone from everywhere  
✅ **No ghost recipes** - Adding recipes to books shows only existing recipes  
✅ **Valid IDs** - All recipes have proper UUIDs and optional Spoonacular IDs  
✅ **Simplified codebase** - No more double bookkeeping  
✅ **Better performance** - SwiftData's efficient querying and caching  

## Support

If you encounter issues:

1. Check console logs for SwiftData errors
2. Verify ModelContainer is properly configured
3. Ensure @Query predicates are correct
4. Check cascade delete rules on relationships
5. Review SWIFTDATA_ARCHITECTURE.md for patterns

---

**Created:** November 8, 2025  
**Status:** Planning Phase  
**Owner:** Development Team
