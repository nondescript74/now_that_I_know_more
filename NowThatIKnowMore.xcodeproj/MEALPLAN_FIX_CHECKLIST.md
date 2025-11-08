# Meal Plan Fix Checklist

**Date Started:** _______________  
**Completed:** _______________

---

## Phase 1: Setup & Verification ✓

### 1. Add Diagnostic View
- [ ] Open `NowThatIKnowMoreApp.swift`
- [ ] Add diagnostic tab to MainTabView (after existing tabs):
  ```swift
  RecipeDiagnosticView()
      .tabItem {
          Label("Diagnostics", systemImage: "stethoscope")
      }
      .tag(7)
  ```
- [ ] Build and run app (Cmd+R)
- [ ] Navigate to Diagnostics tab

### 2. Run Initial Diagnostics
- [ ] Tap "Run Diagnostics" button
- [ ] Review console output
- [ ] Record findings:
  - Total recipes in SwiftData: ________
  - Recipes without UUID: ________ (should be 0)
  - Recipes without title: ________
  - Orphaned media: ________ (should be 0)
  - Orphaned notes: ________ (should be 0)

### 3. Create Backup
- [ ] In Diagnostics tab, tap "Export All Recipes"
- [ ] Save backup file to safe location
- [ ] Verify file is not empty

**Notes:** _______________________________________________
________________________________________________________

---

## Phase 2: Update Meal Plan View ✓

### 4. Locate MealPlan View
- [ ] Press Cmd+Shift+O in Xcode
- [ ] Search for "MealPlan"
- [ ] Found file: ____________________

### 5. Backup Original
- [ ] Right-click MealPlan file → Duplicate
- [ ] Rename to `MealPlan_Legacy.swift`
- [ ] Uncheck from target (File Inspector)

### 6. Update Imports
- [ ] Verify `import SwiftData` is present
- [ ] If not, add it below `import SwiftUI`

### 7. Replace Environment
**Find and replace:**
- [ ] ~~`@Environment(RecipeStore.self) private var store: RecipeStore`~~
- [ ] With: `@Environment(\.modelContext) private var modelContext`
- [ ] Add: `@Query(sort: \RecipeModel.daysOfWeekString) private var recipes: [RecipeModel]`

### 8. Update Delete Function
**Find:**
- [ ] Look for function that deletes recipes
- [ ] Current implementation: _______________________

**Replace with:**
```swift
func deleteRecipe(_ recipe: RecipeModel) {
    modelContext.delete(recipe)
    try? modelContext.save()
}
```
- [ ] Updated delete function

### 9. Update Recipe Access
**Replace:**
- [ ] All occurrences of `store.recipes` with `recipes`
- [ ] Count: ________ replacements made

### 10. Update Add Operations (if any)
**Find:**
- [ ] Look for functions that add recipes
- [ ] Current implementation: _______________________

**Replace with:**
```swift
func addRecipe(_ recipe: RecipeModel) {
    modelContext.insert(recipe)
    try? modelContext.save()
}
```
- [ ] Updated add function

### 11. Build & Fix Errors
- [ ] Press Cmd+B to build
- [ ] Errors found: ________ 
- [ ] All errors fixed

**Notes:** _______________________________________________
________________________________________________________

---

## Phase 3: Testing ✓

### 12. Test Recipe Deletion
- [ ] Run app (Cmd+R)
- [ ] Go to Meal Plan view
- [ ] Note a recipe to delete: ____________________
- [ ] Delete the recipe
- [ ] Go to Books tab
- [ ] Tap a book → Add Recipes
- [ ] **VERIFY:** Deleted recipe is NOT in the list ✓

### 13. Test Recipe Addition
- [ ] Create or import a new recipe
- [ ] Note recipe name: ____________________
- [ ] Verify it appears in Meal Plan
- [ ] Verify it appears in Books → Add Recipes

### 14. Test Persistence
- [ ] Make a change (delete or add a recipe)
- [ ] Force quit app
- [ ] Relaunch app
- [ ] **VERIFY:** Change persisted ✓

### 15. Run Diagnostics Again
- [ ] Go to Diagnostics tab
- [ ] Tap "Run Diagnostics"
- [ ] Compare with initial counts:
  - Total recipes: Was ______, Now ______
  - Orphaned records: ________ (should be 0)

**Issues found:** ________________________________________
________________________________________________________

---

## Phase 4: Remove RecipeStore ✓

### 16. Search for RecipeStore Usage
- [ ] Press Cmd+Shift+F (Find in Project)
- [ ] Search for: `RecipeStore.self`
- [ ] Results found: ________
- [ ] List files to update:
  1. ____________________
  2. ____________________
  3. ____________________

### 17. Update Each View
For each file found:
- [ ] Replace `@Environment(RecipeStore.self)` with `@Environment(\.modelContext)`
- [ ] Add `@Query` as needed
- [ ] Update CRUD operations
- [ ] Test the view

### 18. Remove from App Initialization
In `NowThatIKnowMoreApp.swift`:
- [ ] Remove: `@State private var store: RecipeStore = RecipeStore()`
- [ ] Remove: `.environment(store)` from body
- [ ] Update MainTabView to remove RecipeStore environment

### 19. Update Preview
At bottom of file:
- [ ] Replace `.environment(RecipeStore())` 
- [ ] With: `.modelContainer(try! ModelContainer.preview())`

### 20. Optional: Comment Out Migration
- [ ] Comment out or remove `migrateLegacyRecipes()` function
- [ ] Comment out `.task { await migrateLegacyRecipes() }`

**Notes:** _______________________________________________
________________________________________________________

---

## Phase 5: Final Testing ✓

### 21. Complete App Test
- [ ] Build app (Cmd+B) - No errors
- [ ] Run app (Cmd+R)
- [ ] Test Meal Plan:
  - [ ] View recipes
  - [ ] Add recipe
  - [ ] Edit recipe
  - [ ] Delete recipe
- [ ] Test Books:
  - [ ] View books
  - [ ] Add recipes to book
  - [ ] Remove recipes from book
- [ ] Test Recipe Details:
  - [ ] View recipe
  - [ ] Edit recipe
  - [ ] Add media
  - [ ] Add notes

### 22. Persistence Test
- [ ] Make several changes
- [ ] Quit app completely
- [ ] Relaunch app
- [ ] **VERIFY:** All changes persisted ✓

### 23. Fresh Install Test (Optional)
- [ ] Delete app from device/simulator
- [ ] Build and run again
- [ ] Create a new recipe
- [ ] **VERIFY:** Works with fresh database ✓

### 24. Performance Check
- [ ] App launches quickly
- [ ] Lists scroll smoothly
- [ ] No lag when adding/deleting
- [ ] No memory warnings

**Issues found:** ________________________________________
________________________________________________________

---

## Phase 6: Cleanup ✓

### 25. Mark Legacy Code
In `RecipeStore.swift` (keep for now):
- [ ] Add deprecation comment at top:
  ```swift
  // ⚠️ DEPRECATED - Use SwiftData's RecipeModel instead
  // Kept temporarily for reference and emergency rollback
  ```

### 26. Update Documentation
- [ ] Mark RecipeStore sections as deprecated in docs
- [ ] Update any tutorials or guides
- [ ] Note migration date for future reference

### 27. Final Diagnostic Check
- [ ] Run diagnostics one last time
- [ ] Export backup of current state
- [ ] Save diagnostic output for records

**Notes:** _______________________________________________
________________________________________________________

---

## Success Verification ✓

All of the following should be true:

- [ ] Recipes deleted in Meal Plan are gone from everywhere
- [ ] No "ghost recipes" appear when adding to books
- [ ] All recipes have valid UUIDs
- [ ] No orphaned media or notes
- [ ] Changes persist after app restart
- [ ] No RecipeStore usage in active views
- [ ] App performs well
- [ ] No console errors
- [ ] Backup saved safely

---

## If Something Goes Wrong 🚨

### Emergency Rollback

1. [ ] Stop the app
2. [ ] Restore `MealPlan_Legacy.swift`
3. [ ] Re-enable RecipeStore in `NowThatIKnowMoreApp.swift`
4. [ ] Add back: `@State private var store: RecipeStore = RecipeStore()`
5. [ ] Add back: `.environment(store)`
6. [ ] Rebuild and run
7. [ ] Restore from backup if needed
8. [ ] Document what went wrong: ____________________

---

## Post-Migration

### Week 1 Monitoring
- [ ] Day 1: Check for any issues
- [ ] Day 3: Verify data integrity
- [ ] Day 7: Run diagnostics again

### Week 2 Monitoring
- [ ] Day 14: If all good, plan RecipeStore removal

### Future Cleanup (after 2 weeks)
- [ ] Delete `RecipeStore.swift`
- [ ] Delete `MealPlan_Legacy.swift` backup
- [ ] Remove migration code entirely
- [ ] Update all documentation

---

## Notes & Issues

**Issues encountered:**
________________________________________________________
________________________________________________________
________________________________________________________

**Solutions applied:**
________________________________________________________
________________________________________________________
________________________________________________________

**Lessons learned:**
________________________________________________________
________________________________________________________
________________________________________________________

---

**Completed by:** _______________  
**Date:** _______________  
**Time taken:** _______________ hours  
**Status:** ⭐ Success / ⚠️ Partial / ❌ Rolled back

---

**For detailed instructions, see:**
- `MEALPLAN_SWIFTDATA_FIX_GUIDE.md` - Step-by-step guide
- `SWIFTDATA_CONSOLIDATION_SUMMARY.md` - Overview
- `SWIFTDATA_QUICK_REFERENCE.md` - Code examples

**Last Updated:** November 8, 2025
