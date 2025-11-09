//
//  INTEGRATION_GUIDE_FOR_NOWTHATIKNOWMORE.md
//  Recipe Image Parser Integration
//
//  Step-by-step guide to add recipe image parsing to your existing app
//

# Integration Guide: Adding Recipe Image Parser to Nowthatiknowmore

## 📋 Overview

This guide will help you integrate the recipe image parser into your existing Nowthatiknowmore recipe app in Xcode.

## 🚀 Step-by-Step Integration

### Step 1: Add Files to Your Xcode Project

1. Open your **Nowthatiknowmore** project in Xcode
2. In Xcode, right-click on your project folder in the Navigator
3. Select **"Add Files to Nowthatiknowmore..."**
4. Navigate to where you downloaded these files
5. Select these files to add:
   ```
   ✅ RecipeModels.swift
   ✅ RecipeImageParser.swift
   ✅ AdvancedRecipeImageParser.swift
   ✅ RecipeImageParserView.swift
   ```
6. Make sure **"Copy items if needed"** is checked
7. Click **Add**

### Step 2: Update Info.plist

1. In Xcode, find your **Info.plist** file (or Info tab in project settings)
2. Add these two privacy descriptions:

**Using Info.plist file directly:**
```xml
<key>NSCameraUsageDescription</key>
<string>Nowthatiknowmore needs camera access to capture recipe images</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Nowthatiknowmore needs photo library access to import recipe images</string>
```

**OR using Xcode GUI:**
- Click the **Info** tab in your target settings
- Click the **+** button under "Custom iOS Target Properties"
- Add:
  - **Privacy - Camera Usage Description**: "Nowthatiknowmore needs camera access to capture recipe images"
  - **Privacy - Photo Library Usage Description**: "Nowthatiknowmore needs photo library access to import recipe images"

### Step 3: Adapt Models to Your Existing Structure

If you already have Recipe/Ingredient models in Nowthatiknowmore, you need to modify the parser to use them:

**Option A: Your models already match the parser structure**
- If your models have `title`, `ingredients`, `instructions` properties, you're good to go!

**Option B: Your models are different**
Open `RecipeModels.swift` and modify the `Recipe` struct to match your existing model:

```swift
// Example: If your existing Recipe model has different properties
struct Recipe: Codable, Identifiable {
    let id: UUID
    var name: String           // Instead of 'title'
    var items: [Ingredient]    // Instead of 'ingredients'
    var steps: String?         // Instead of 'instructions'
    var yield: String?         // Instead of 'servings'
    
    // Add initializer that maps from parsed data
    init(fromParsed parsed: ParsedRecipe) {
        self.id = UUID()
        self.name = parsed.title
        self.items = parsed.ingredients
        self.steps = parsed.instructions
        self.yield = parsed.servings
    }
}
```

### Step 4: Add Navigation to Recipe Parser

You have several options for integrating the parser UI:

**Option 1: Add as a New Tab** (Recommended if you use TabView)

```swift
TabView {
    // Your existing tabs
    YourRecipeListView()
        .tabItem {
            Label("Recipes", systemImage: "book")
        }
    
    // Add the parser as a new tab
    RecipeImageParserView()
        .tabItem {
            Label("Import", systemImage: "camera")
        }
}
```

**Option 2: Add as a Sheet/Modal**

```swift
struct YourRecipeListView: View {
    @State private var showImporter = false
    
    var body: some View {
        NavigationView {
            // Your existing recipe list
            List {
                // ...
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showImporter = true }) {
                        Label("Import", systemImage: "camera")
                    }
                }
            }
            .sheet(isPresented: $showImporter) {
                RecipeImageParserView()
            }
        }
    }
}
```

**Option 3: Add as Navigation Link**

```swift
NavigationLink(destination: RecipeImageParserView()) {
    Label("Import Recipe from Photo", systemImage: "camera")
}
```

### Step 5: Implement Saving to Your App

Open `RecipeImageParserView.swift` and find the `saveToRecipesApp()` function around line 190.

Replace the TODO comment with your actual save logic:

**If using CoreData:**
```swift
private func saveToRecipesApp() {
    let context = PersistenceController.shared.container.viewContext
    let recipeEntity = RecipeEntity(context: context)
    recipeEntity.id = recipe.id
    recipeEntity.title = recipe.title
    recipeEntity.instructions = recipe.instructions
    recipeEntity.servings = recipe.servings
    recipeEntity.dateCreated = Date()
    
    for ingredient in recipe.ingredients {
        let ingredientEntity = IngredientEntity(context: context)
        ingredientEntity.id = ingredient.id
        ingredientEntity.imperialAmount = ingredient.imperialAmount
        ingredientEntity.name = ingredient.name
        ingredientEntity.metricAmount = ingredient.metricAmount
        ingredientEntity.recipe = recipeEntity
    }
    
    do {
        try context.save()
        // Show success message or dismiss view
    } catch {
        print("Error saving: \(error)")
    }
}
```

**If using SwiftData (iOS 17+):**
```swift
@Environment(\.modelContext) private var modelContext

private func saveToRecipesApp() {
    let recipeModel = RecipeModel(from: recipe)
    modelContext.insert(recipeModel)
    
    do {
        try modelContext.save()
        // Show success message or dismiss view
    } catch {
        print("Error saving: \(error)")
    }
}
```

**If using simple file storage:**
```swift
private func saveToRecipesApp() {
    var recipes = loadRecipes() // Your existing load function
    recipes.append(recipe)
    saveRecipes(recipes) // Your existing save function
}
```

### Step 6: Test the Integration

1. Build and run your app (⌘R)
2. Navigate to the Recipe Image Parser
3. Take a photo or select your Dhokra Chutney image
4. Tap "Parse Recipe"
5. Review the parsed data
6. Tap "Save to Recipes"
7. Verify the recipe appears in your recipe list

## 🎨 Customization Options

### Change Colors/Styling

The parser uses standard SwiftUI buttons. To match your app's theme:

```swift
// In RecipeImageParserView.swift
Button(action: parseImage) {
    Label("Parse Recipe", systemImage: "doc.text.magnifyingglass")
}
.buttonStyle(.borderedProminent)
.tint(.yourAppColor) // Add your custom color
```

### Add Custom Fields

If your recipes have additional fields (like cuisine type, difficulty, etc.), modify the `Recipe` struct:

```swift
struct Recipe: Codable, Identifiable {
    let id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: String?
    var servings: String?
    
    // Add your custom fields
    var cuisine: String?
    var prepTime: Int?
    var difficulty: String?
    var tags: [String] = []
}
```

Then update the parser to allow setting these after parsing:

```swift
// Add to ParsedRecipeView
TextField("Cuisine", text: $cuisine)
Picker("Difficulty", selection: $difficulty) {
    // ...
}
```

### Use Advanced Parser by Default

If the basic parser doesn't work well with your recipe cards, switch to the advanced parser:

In `RecipeImageParserView.swift`, replace:
```swift
private let parser = RecipeImageParser()
```

With:
```swift
private let parser = AdvancedRecipeImageParser()
```

## 🐛 Troubleshooting

### "No such module 'Vision'" error
- Make sure your deployment target is iOS 15.0 or later
- Vision framework is included by default in iOS

### Camera/Photos not working
- Double-check Info.plist has the privacy descriptions
- Test on a real device (camera doesn't work in simulator)
- Go to Settings → Privacy → Camera/Photos and ensure permission is granted

### Parsing results are inaccurate
- Try the `AdvancedRecipeImageParser` instead
- Ensure images have good lighting and are in focus
- Recipe cards should be photographed straight-on
- Check that text is clearly visible

### Recipes not appearing after saving
- Add print statements in `saveToRecipesApp()` to debug
- Verify your data persistence layer is working
- Check that you're refreshing the recipe list view after saving

## 📚 Additional Features to Consider

Once the basic integration works, you can add:

1. **Batch Processing**: Import multiple recipe cards at once
2. **Edit Before Save**: Allow full editing of parsed recipes
3. **Recipe Templates**: Save common parsing patterns
4. **OCR Training**: Learn from corrections to improve accuracy
5. **Cloud Sync**: Share recipes across devices

## 🔗 Related Files

For more advanced integration examples, see:
- `RecipesAppIntegration.swift` - Detailed CoreData/SwiftData examples
- `RecipeParserTests.swift` - Testing and debugging utilities
- `README.md` - Complete documentation

## ✅ Quick Checklist

Before you start:
- [ ] Xcode project is backed up
- [ ] You know where your existing Recipe models are
- [ ] You know how your app currently saves recipes

During integration:
- [ ] All 4 Swift files added to project
- [ ] Info.plist privacy descriptions added
- [ ] Models adapted (if necessary)
- [ ] Navigation/UI integration completed
- [ ] Save function implemented
- [ ] App builds without errors

Testing:
- [ ] Can open the parser view
- [ ] Can select/take photos
- [ ] Parsing produces results
- [ ] Can save parsed recipes
- [ ] Recipes appear in your recipe list

## 🎉 You're Done!

Once everything is working, you'll be able to quickly import recipes by taking photos of recipe cards. The parser will handle the OCR and formatting automatically!

If you run into any issues, the `RecipeParserTests.swift` file has debugging utilities you can use to see what the parser is detecting.
