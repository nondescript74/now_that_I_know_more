# Quick Start: Add Recipe Parser to Nowthatiknowmore

## 🎯 30-Second Overview
Add these 4 files → Update Info.plist → Add to your UI → Done!

## ⚡ Quick Steps

### 1. Add Files to Xcode (2 minutes)
Drag these into your Xcode project:
```
✅ RecipeModels.swift
✅ RecipeImageParser.swift  
✅ AdvancedRecipeImageParser.swift
✅ RecipeImageParserView.swift
```

### 2. Update Info.plist (1 minute)
Add these two lines:
- **Camera**: "Nowthatiknowmore needs camera access to capture recipe images"
- **Photo Library**: "Nowthatiknowmore needs photo library access to import recipe images"

### 3. Add to Your App (2 minutes)
Choose ONE option:

**As a new tab:**
```swift
RecipeImageParserView()
    .tabItem { Label("Import", systemImage: "camera") }
```

**As a button/sheet:**
```swift
.toolbar {
    Button { showParser = true } label: {
        Label("Import", systemImage: "camera")
    }
}
.sheet(isPresented: $showParser) {
    RecipeImageParserView()
}
```

### 4. Connect Save Function (5 minutes)
In `RecipeImageParserView.swift`, find `saveToRecipesApp()` and add your save logic.

Example:
```swift
private func saveToRecipesApp() {
    // Add to your existing recipe storage
    myRecipeManager.add(recipe)
    
    // Or if using CoreData:
    let context = persistenceController.context
    let entity = RecipeEntity(context: context)
    entity.title = recipe.title
    // ... etc
    try? context.save()
}
```

## ✅ Done!

Run your app, tap Import, take a photo of a recipe, and watch it parse automatically!

## 📖 Need More Details?

See `INTEGRATION_GUIDE_FOR_NOWTHATIKNOWMORE.md` for complete instructions.

## 🎨 Your Recipe Card Format

The parser is optimized for cards like your Dhokra Chutney image:
- Title at top
- "Makes X cup (X mL)" servings line  
- Two columns with ingredients
- Each row: amount | name | metric
- Instructions at bottom

## 🔧 Tips

- Use good lighting when photographing recipes
- Keep camera straight-on (not angled)
- If basic parser doesn't work well, switch to `AdvancedRecipeImageParser`

## 🐛 Problems?

- **Can't find files?** All files are in `/mnt/user-data/outputs/`
- **Parse results wrong?** Try `AdvancedRecipeImageParser` instead
- **Camera not working?** Check Info.plist has privacy descriptions
- **Recipes not saving?** Add debug prints in `saveToRecipesApp()`

---

**Next time you open Xcode:** Just drag the 4 Swift files into your project and you're 90% done!
