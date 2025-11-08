# Step-by-Step Fix Guide: Meal Plan SwiftData Integration

## Quick Summary

**Problem:** Recipes deleted in Meal Plan view remain in SwiftData, causing them to reappear when adding recipes to books.

**Root Cause:** Meal Plan is using the legacy `RecipeStore` instead of SwiftData's `RecipeModel`.

**Solution:** Update Meal Plan to use SwiftData directly.

---

## STEP 1: Add Diagnostic View to Your App (5 minutes)

This will help us see what's in SwiftData and verify recipe IDs.

### 1.1 Add the diagnostic tab

Open `NowThatIKnowMoreApp.swift` and add a new tab to `MainTabView`:

```swift
// Add this tab after your existing tabs (around line 54)
RecipeDiagnosticView()
    .tabItem {
        Label("Diagnostics", systemImage: "stethoscope")
    }
    .tag(7)  // Use next available tag number
```

### 1.2 Run the app and check diagnostics

1. Build and run your app
2. Navigate to the new "Diagnostics" tab
3. Tap "Run Diagnostics"
4. Review the console output for a full report

**What to look for:**
- Total recipe count in SwiftData
- Any recipes with missing UUIDs (should be 0)
- Any recipes with missing titles
- List of all recipe UUIDs and IDs

**Action:** Copy the diagnostic output and keep it for reference.

---

## STEP 2: Locate Your MealPlan View (5 minutes)

We need to find where MealPlan is defined. It's not in the files I can see, so let's locate it.

### 2.1 Search for the file

In Xcode:
1. Press `Cmd+Shift+O` (Open Quickly)
2. Type "MealPlan"
3. Look for files like:
   - `MealPlan.swift`
   - `MealPlanView.swift`
   - `WeeklyMealPlan.swift`

### 2.2 Identify the structure

Look for code like this:

```swift
struct MealPlan: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    
    // or
    
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [RecipeModel]
}
```

**Action:** Note which approach is currently used (RecipeStore or SwiftData).

---

## STEP 3: Backup Current Implementation (2 minutes)

Before making changes:

### 3.1 Create a backup

1. Find your MealPlan view file
2. Duplicate it: Right-click → Duplicate
3. Rename to `MealPlan_Legacy.swift`
4. Comment out or remove from target (uncheck in File Inspector)

This gives you a rollback option if needed.

---

## STEP 4: Update MealPlan to Use SwiftData (15-30 minutes)

Now we'll convert MealPlan to use SwiftData exclusively.

### 4.1 Update the imports

At the top of your MealPlan file:

```swift
import SwiftUI
import SwiftData  // Make sure this is imported
```

### 4.2 Replace RecipeStore with SwiftData

**OLD CODE (find and replace):**
```swift
@Environment(RecipeStore.self) private var store: RecipeStore
```

**NEW CODE:**
```swift
@Environment(\.modelContext) private var modelContext
@Query(sort: \RecipeModel.daysOfWeekString) private var recipes: [RecipeModel]
```

### 4.3 Update recipe access

**OLD CODE:**
```swift
let allRecipes = store.recipes
```

**NEW CODE:**
```swift
// Just use `recipes` directly - it's automatically populated by @Query
```

### 4.4 Update delete operations

**OLD CODE:**
```swift
func deleteRecipe(_ recipe: Recipe) {
    store.remove(recipe)
}
```

**NEW CODE:**
```swift
func deleteRecipe(_ recipe: RecipeModel) {
    modelContext.delete(recipe)
    try? modelContext.save()
}
```

### 4.5 Update add operations

**OLD CODE:**
```swift
func addRecipe(_ recipe: Recipe) {
    store.add(recipe)
}
```

**NEW CODE:**
```swift
func addRecipe(_ recipe: RecipeModel) {
    modelContext.insert(recipe)
    try? modelContext.save()
}
```

### 4.6 Update filter/search operations

If your MealPlan has filtering (e.g., by day of week):

**OLD CODE:**
```swift
let mondayRecipes = store.recipes.filter { recipe in
    recipe.daysOfWeek?.contains("Monday") == true
}
```

**NEW CODE - Option 1 (Simple filtering):**
```swift
let mondayRecipes = recipes.filter { recipe in
    recipe.daysOfWeek.contains("Monday")
}
```

**NEW CODE - Option 2 (Query with predicate):**
```swift
// At the property level:
@Query(
    filter: #Predicate<RecipeModel> { recipe in
        recipe.daysOfWeekString?.contains("Monday") == true
    }
)
private var mondayRecipes: [RecipeModel]
```

### 4.7 Update recipe display

**OLD CODE:**
```swift
ForEach(store.recipes) { recipe in
    RecipeRow(recipe: recipe)
}
```

**NEW CODE:**
```swift
ForEach(recipes) { recipe in
    RecipeRow(recipe: recipe)
}
.onDelete(perform: deleteRecipes)
```

With the delete function:
```swift
private func deleteRecipes(at offsets: IndexSet) {
    withAnimation {
        for index in offsets {
            let recipe = recipes[index]
            modelContext.delete(recipe)
        }
        try? modelContext.save()
    }
}
```

---

## STEP 5: Test Meal Plan Changes (10 minutes)

### 5.1 Build and run

1. Build your app (Cmd+B)
2. Fix any compilation errors
3. Run the app (Cmd+R)

### 5.2 Test recipe operations

**Test Deletion:**
1. Go to Meal Plan view
2. Find a recipe you want to test with
3. Swipe to delete or use delete button
4. Go to Books tab
5. Try to add recipes to a book
6. **VERIFY:** The deleted recipe should NOT appear in the list

**Test Addition:**
1. Create or import a new recipe
2. Assign it to a day of the week (if applicable)
3. Go to Meal Plan
4. **VERIFY:** The new recipe appears

**Test Persistence:**
1. Make changes in Meal Plan
2. Force quit the app
3. Relaunch
4. **VERIFY:** Changes are still there

### 5.3 Run diagnostics again

1. Go to Diagnostics tab
2. Tap "Run Diagnostics"
3. **VERIFY:** Recipe count is correct
4. **VERIFY:** No orphaned records

---

## STEP 6: Remove RecipeStore from App (10 minutes)

Once Meal Plan works correctly, we can remove RecipeStore.

### 6.1 Check all views

Search your project for `@Environment(RecipeStore.self)`:

1. Press `Cmd+Shift+F` (Find in Project)
2. Search for: `RecipeStore.self`
3. Review each result
4. Make sure all views are updated to use SwiftData

### 6.2 Remove from app initialization

In `NowThatIKnowMoreApp.swift`:

**REMOVE THIS LINE:**
```swift
@State private var store: RecipeStore = RecipeStore()
```

**REMOVE THIS LINE (from MainTabView):**
```swift
@Environment(RecipeStore.self) private var store: RecipeStore
```

**REMOVE THIS LINE (from body):**
```swift
.environment(store)
```

### 6.3 Update the preview

At the bottom of the file, update the preview:

**OLD:**
```swift
#Preview {
    MainTabView()
        .environment(RecipeStore())
}
```

**NEW:**
```swift
#Preview {
    MainTabView()
        .modelContainer(try! ModelContainer.preview())
}
```

### 6.4 Remove migration code (optional)

After confirming everything works, you can remove the migration function:

```swift
// You can comment this out or delete it
// private func migrateLegacyRecipes() async { ... }
```

And remove the `.task` call:

```swift
// Remove or comment out:
// .task {
//     await migrateLegacyRecipes()
// }
```

---

## STEP 7: Clean Up Legacy Files (5 minutes)

### 7.1 Keep these files for now:

- `Recipe.swift` (still needed for import/export compatibility)
- `RecipeStore.swift` (keep temporarily in case of issues)

### 7.2 Mark as deprecated:

Add a comment at the top of RecipeStore.swift:

```swift
//
//  RecipeStore.swift
//  NowThatIKnowMore
//
//  ⚠️ DEPRECATED - This is legacy code. Use SwiftData's RecipeModel instead.
//  This file is kept temporarily for reference and emergency rollback.
//
```

### 7.3 Later removal (after 1-2 weeks of testing):

Once you're confident everything works:
1. Remove `RecipeStore.swift`
2. Remove any unused Recipe-related utility files
3. Update documentation to remove RecipeStore references

---

## Troubleshooting

### Issue: "Cannot find 'RecipeModel' in scope"

**Solution:** Make sure you have `import SwiftData` at the top of your file.

### Issue: Recipes not appearing after update

**Solution:** 
1. Check the @Query predicate isn't filtering them out
2. Verify recipes exist in SwiftData using Diagnostics tab
3. Try using a simple @Query without filters first

### Issue: App crashes on delete

**Solution:**
1. Make sure you're calling `modelContext.delete()` not `store.remove()`
2. Add error handling: `do { try modelContext.save() } catch { print(error) }`
3. Check cascade delete rules on relationships

### Issue: Changes not persisting

**Solution:**
1. Always call `try? modelContext.save()` after changes
2. Verify ModelContainer is properly injected with `.modelContainer(modelContainer)`
3. Check you're not using an in-memory container in production

### Issue: Duplicate recipes appearing

**Solution:**
1. Run diagnostics to check for duplicates
2. The UUID should be unique - if you have duplicates, you may need to clean them up
3. Consider adding a migration script to remove duplicates

---

## Verification Checklist

After completing all steps, verify:

- [ ] Diagnostics shows correct recipe count
- [ ] All recipes have valid UUIDs
- [ ] Recipes deleted in Meal Plan don't appear in Books
- [ ] New recipes can be added
- [ ] Changes persist after app restart
- [ ] No compiler warnings related to RecipeStore
- [ ] App performance is good
- [ ] No data loss occurred
- [ ] Console shows no SwiftData errors

---

## Emergency Rollback

If something goes wrong:

1. Restore `MealPlan_Legacy.swift` backup
2. Re-enable RecipeStore in app initialization
3. Rebuild and run
4. File an issue with details about what went wrong

---

## Next Steps

After successfully completing this migration:

1. **Test thoroughly** for 1-2 weeks
2. **Monitor** for any issues or edge cases
3. **Update documentation** to reflect SwiftData-only approach
4. **Consider adding** CloudKit sync for data backup
5. **Implement** export/import for user data portability

---

## Support Resources

- **SWIFTDATA_ARCHITECTURE.md** - Architecture overview
- **SWIFTDATA_CONSOLIDATION_PLAN.md** - Detailed migration plan
- **RecipeDiagnosticView.swift** - Tool for verifying data integrity
- **Apple SwiftData Documentation** - https://developer.apple.com/documentation/swiftdata

---

**Last Updated:** November 8, 2025  
**Estimated Time:** 1-2 hours  
**Difficulty:** Intermediate  
**Status:** Ready for Implementation
