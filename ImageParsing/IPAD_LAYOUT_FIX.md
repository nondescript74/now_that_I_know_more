# iPad Layout Fix: Recipe Import Views

## Problem

On iPad M2 Simulator, when navigating to the Recipe Import view:
- **Photo import option** appeared in the sidebar (incorrect)
- **PDF import option** appeared in main window with sidebar minimized (also incorrect)
- **Expected behavior**: Both should appear in the main window

## Root Cause

The `RecipeImportTabView` was creating a `NavigationStack`, but both child views (`RecipeImageParserView` and `RecipePDFParserView`) also had their own `.navigationTitle()` modifiers. This created conflicting navigation hierarchies.

Additionally, using `TabView` for switching between import modes was causing issues on iPad's split-view navigation.

## Solution

### 1. Removed Nested NavigationStack

**Before:**
```swift
var body: some View {
    NavigationStack {  // ❌ Creates nested navigation
        VStack {
            // Picker and content
        }
        .navigationTitle("Import Recipe")
    }
}
```

**After:**
```swift
var body: some View {
    VStack {  // ✅ No NavigationStack - parent handles it
        // Picker and content
    }
    .navigationTitle("Import Recipe")  // Applied at correct level
}
```

### 2. Replaced TabView with Conditional View

**Before:**
```swift
TabView(selection: $selectedImportMode) {
    RecipeImageParserView()
        .tag(ImportMode.photo)
    
    RecipePDFParserView()
        .tag(ImportMode.pdf)
}
.tabViewStyle(.page(indexDisplayMode: .never))
```

**After:**
```swift
Group {
    switch selectedImportMode {
    case .photo:
        RecipeImageParserView()
    case .pdf:
        RecipePDFParserView()
    }
}
```

**Why?**
- `TabView` with `.page` style was interfering with iPad's navigation system
- Conditional `Group` provides cleaner view switching
- Better integration with split-view navigation on iPad

### 3. Removed Duplicate Navigation Titles

**RecipeImageParserView.swift** - Removed:
```swift
.navigationTitle("Recipe Parser")  // ❌ Duplicate
```

**RecipePDFParserView.swift** - Removed:
```swift
.navigationTitle("PDF Recipe Parser")  // ❌ Duplicate
.navigationBarTitleDisplayMode(.inline)
```

The parent `RecipeImportTabView` now handles the navigation title:
```swift
.navigationTitle("Import Recipe")  // ✅ Single source of truth
.navigationBarTitleDisplayMode(.inline)
```

## Files Changed

1. **RecipeImportTabView.swift**
   - Removed `NavigationStack` wrapper
   - Replaced `TabView` with conditional `Group`
   - Moved `.navigationTitle()` to root level
   - Added `Identifiable` conformance to `ImportMode` enum

2. **RecipeImageParserView.swift**
   - Removed `.navigationTitle("Recipe Parser")`

3. **RecipePDFParserView.swift**
   - Removed `.navigationTitle("PDF Recipe Parser")`
   - Removed `.navigationBarTitleDisplayMode(.inline)`

4. **RecipePDFParserView.swift** (Bug Fix)
   - Fixed broken brace structure in `body`
   - Corrected indentation issues

## Testing on iPad

### Test Case 1: Navigate from Meal Plan
```
1. Open app on iPad simulator
2. Navigate to Meal Plan
3. Tap "Import Recipe"
4. Result: View opens in main window (not sidebar)
5. Toggle between Photo/PDF tabs
6. Result: Both modes display in main window
```

### Test Case 2: Direct Navigation
```
1. Navigate to recipe import from any view
2. Result: Opens in main content area
3. Switch between Photo and PDF modes
4. Result: Smooth transition, stays in main area
```

### Test Case 3: Sidebar Behavior
```
1. Open recipe import
2. Result: Sidebar remains visible (if previously visible)
3. Content displays in main window
4. Navigation hierarchy preserved
```

## iPad Navigation Best Practices

### ✅ Do

1. **Single NavigationStack** at app level
   ```swift
   NavigationStack {
       // All navigation happens here
   }
   ```

2. **NavigationLink for destinations**
   ```swift
   NavigationLink("Import Recipe", destination: RecipeImportTabView())
   ```

3. **One navigation title per view**
   ```swift
   .navigationTitle("Import Recipe")  // Only at the navigating view
   ```

### ❌ Don't

1. **Nested NavigationStacks**
   ```swift
   NavigationStack {  // Parent
       NavigationStack {  // ❌ Child conflicts
   ```

2. **Multiple navigation titles**
   ```swift
   .navigationTitle("A")  // Parent
   .navigationTitle("B")  // ❌ Child conflicts
   ```

3. **TabView for non-tab navigation**
   ```swift
   TabView(selection: $mode) {  // ❌ Use for app-level tabs only
       SubView1()
       SubView2()
   }
   ```

## Future Considerations

### If Using NavigationSplitView

For proper iPad sidebar + detail navigation:

```swift
NavigationSplitView {
    // Sidebar
    List(selection: $selection) {
        NavigationLink("Recipes", value: Route.recipes)
        NavigationLink("Import", value: Route.import)
    }
} detail: {
    // Detail (main content)
    NavigationStack {
        switch selection {
        case .recipes:
            RecipeListView()
        case .import:
            RecipeImportTabView()  // ✅ Works correctly now
        }
    }
}
```

### Responsive Design

Consider adapting layout based on size class:

```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .regular {
        // iPad layout
        iPadLayout
    } else {
        // iPhone layout
        iPhoneLayout
    }
}
```

## Summary

**Problem:** Nested NavigationStacks and TabView causing iPad layout issues  
**Solution:** Flat navigation hierarchy with conditional view switching  
**Result:** Both Photo and PDF import modes display correctly in main window on iPad

**Files Updated:** 3 (RecipeImportTabView, RecipeImageParserView, RecipePDFParserView)  
**Bug Fixes:** 1 (Fixed brace structure in RecipePDFParserView)  
**Status:** ✅ Ready for testing
