# SwiftData Architecture Guide

## Overview

This app now uses **SwiftData** as the primary data persistence layer. SwiftData provides a modern, Swift-native way to manage your app's data with automatic persistence, relationships, and querying capabilities.

## Architecture Components

### 1. **Models** (Data Layer)

The app uses four main SwiftData models:

#### `RecipeModel`
The core recipe entity with all recipe information.

**Key Features:**
- Stores recipe metadata (title, servings, cooking time, etc.)
- Dietary information (vegetarian, vegan, gluten-free, etc.)
- Complex data stored as JSON (ingredients, instructions)
- External storage for large data using `@Attribute(.externalStorage)`
- Unique UUID for identification using `@Attribute(.unique)`

**Relationships:**
- One-to-many with `RecipeMediaModel` (photos/videos)
- One-to-many with `RecipeNoteModel` (user notes)
- Many-to-many with `RecipeBookModel` (collections)

#### `RecipeMediaModel`
Stores user-uploaded photos and videos for recipes.

**Key Features:**
- File URL storage for media files
- Thumbnail support
- Captions and sorting
- Helper methods for saving and loading images

**Relationships:**
- Many-to-one with `RecipeModel`

#### `RecipeNoteModel`
User notes attached to recipes.

**Key Features:**
- Rich text content
- Pinning capability for important notes
- Tag support for organization
- Automatic timestamps

**Relationships:**
- Many-to-one with `RecipeModel`

#### `RecipeBookModel`
Collections/categories for organizing recipes.

**Key Features:**
- Custom names and descriptions
- Color themes (stored as hex)
- SF Symbol icons
- Sort ordering
- Factory method for creating default books

**Relationships:**
- Many-to-many with `RecipeModel`

### 2. **Service Layer**

#### `RecipeService`
Centralized business logic for data operations.

**Benefits:**
- Encapsulates SwiftData operations
- Provides clean API for views
- Handles complex queries and filtering
- Manages relationships between models
- Includes migration utilities

**Key Methods:**

```swift
// Recipe operations
func fetchRecipes() -> [RecipeModel]
func addRecipe(_ recipe: RecipeModel)
func updateRecipe(_ recipe: RecipeModel)
func deleteRecipe(_ recipe: RecipeModel)

// Search and filtering
func searchRecipes(query: String) -> [RecipeModel]
func filterRecipes(vegetarian: Bool?, vegan: Bool?, ...) -> [RecipeModel]

// Book operations
func fetchRecipeBooks() -> [RecipeBookModel]
func addRecipe(_ recipe: RecipeModel, toBook book: RecipeBookModel)

// Media operations
func addMedia(_ media: RecipeMediaModel, toRecipe recipe: RecipeModel)
func setFeaturedMedia(_ media: RecipeMediaModel, for recipe: RecipeModel)

// Note operations
func addNote(_ note: RecipeNoteModel, toRecipe recipe: RecipeModel)
func fetchPinnedNotes(for recipe: RecipeModel) -> [RecipeNoteModel]

// Migration
func migrateFromLegacy(_ legacyRecipe: Recipe) -> RecipeModel
```

### 3. **Model Container Configuration**

The `ModelContainer` is configured in `ModelContainer+Configuration.swift`:

```swift
// Production container
let container = try ModelContainer.create()

// Preview container (in-memory with sample data)
let previewContainer = try ModelContainer.preview()
```

The container is injected at the app level in `NowThatIKnowMoreApp.swift`:

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
        }
        .modelContainer(modelContainer)
    }
}
```

### 4. **Views** (UI Layer)

The app includes three main view components for data management:

#### `RecipeBooksView`
- Browse and manage recipe books
- Add/edit/delete books
- Customize book appearance (colors, icons)
- Add recipes to books
- View recipes within books

#### `RecipeMediaView`
- Upload photos from camera or photo library
- View photo gallery for each recipe
- Set featured image
- Add captions to photos
- Delete photos

#### `RecipeNotesView`
- Create and edit notes
- Pin important notes
- Add tags for organization
- Quick tag suggestions
- Swipe actions for quick editing

## Using SwiftData in Your Views

### Basic Pattern

```swift
struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [RecipeModel]
    
    var body: some View {
        List(recipes) { recipe in
            Text(recipe.title ?? "Untitled")
        }
    }
}
```

### Filtered Queries

```swift
@Query(
    filter: #Predicate<RecipeModel> { recipe in
        recipe.vegetarian == true
    },
    sort: \.title
) 
private var vegetarianRecipes: [RecipeModel]
```

### Using RecipeService

```swift
struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recipeService: RecipeService?
    
    var body: some View {
        Text("Content")
            .onAppear {
                if recipeService == nil {
                    recipeService = RecipeService(modelContext: modelContext)
                }
            }
    }
    
    func addRecipe() {
        let recipe = RecipeModel(title: "New Recipe")
        recipeService?.addRecipe(recipe)
    }
}
```

### Creating Relationships

```swift
// Add a photo to a recipe
let media = RecipeMediaModel(
    fileURL: imageURL,
    type: .photo,
    recipe: recipe
)
modelContext.insert(media)
recipe.modifiedAt = Date()
try? modelContext.save()

// Add a recipe to a book
if book.recipes == nil {
    book.recipes = []
}
book.recipes?.append(recipe)
try? modelContext.save()
```

## Data Migration

The app automatically migrates legacy `Recipe` structs to SwiftData on first launch:

```swift
private func migrateLegacyRecipes() async {
    let migrationKey = "hasCompletedSwiftDataMigration"
    guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
    
    let legacyRecipes = store.recipes
    let service = RecipeService(modelContext: modelContainer.mainContext)
    
    await MainActor.run {
        service.batchMigrateLegacyRecipes(legacyRecipes)
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
```

This migration:
1. Checks if migration has already occurred
2. Loads recipes from the old `RecipeStore`
3. Converts each `Recipe` to a `RecipeModel`
4. Preserves all relationships (media, notes)
5. Marks migration as complete

## Best Practices

### 1. **Always Use MainActor for SwiftData**

```swift
@MainActor
class RecipeService {
    // Service methods
}
```

### 2. **Save After Modifications**

```swift
recipe.title = "Updated Title"
recipe.modifiedAt = Date()
try? modelContext.save()
```

### 3. **Use Delete Rules for Relationships**

```swift
@Relationship(deleteRule: .cascade, inverse: \RecipeMediaModel.recipe)
var mediaItems: [RecipeMediaModel]?
```

- `.cascade` - Delete related items when parent is deleted
- `.nullify` - Set relationships to nil (default for many-to-many)
- `.deny` - Prevent deletion if relationships exist

### 4. **Use External Storage for Large Data**

```swift
@Attribute(.externalStorage) 
var extendedIngredientsJSON: Data?
```

This prevents large blobs from being stored in the main database file.

### 5. **Leverage @Query for Automatic Updates**

```swift
@Query(sort: \.modifiedAt, order: .reverse) 
private var recipes: [RecipeModel]
```

Views automatically update when data changes.

### 6. **Use Unique Attributes**

```swift
@Attribute(.unique) 
var uuid: UUID
```

Prevents duplicate records and enables efficient lookups.

## Testing with SwiftData

### Preview Container

```swift
#Preview {
    RecipeBooksView()
        .modelContainer(try! ModelContainer.preview())
}
```

The preview container:
- Uses in-memory storage
- Pre-populates sample data
- Resets between previews

### Unit Testing

```swift
import Testing
import SwiftData

@Suite("Recipe Tests")
struct RecipeTests {
    @Test("Add recipe to book")
    func addRecipeToBook() throws {
        let container = try ModelContainer.preview()
        let context = container.mainContext
        let service = RecipeService(modelContext: context)
        
        let recipe = RecipeModel(title: "Test Recipe")
        let book = RecipeBookModel(name: "Test Book")
        
        service.addRecipe(recipe)
        service.addRecipeBook(book)
        service.addRecipe(recipe, toBook: book)
        
        #expect(book.recipes?.contains(where: { $0.uuid == recipe.uuid }) == true)
    }
}
```

## File Organization

```
Models/
├── RecipeModel.swift
├── RecipeMediaModel.swift
├── RecipeNoteModel.swift
├── RecipeBookModel.swift
└── ModelContainer+Configuration.swift

Services/
└── RecipeService.swift

Views/
├── RecipeBooksView.swift
├── RecipeMediaView.swift
└── RecipeNotesView.swift
```

## Common Tasks

### Add a New Recipe

```swift
let recipe = RecipeModel(
    title: "Pasta Carbonara",
    servings: 4,
    vegetarian: false
)
modelContext.insert(recipe)
try? modelContext.save()
```

### Search Recipes

```swift
let results = recipeService.searchRecipes(query: "pasta")
```

### Filter by Dietary Restrictions

```swift
let veganRecipes = recipeService.filterRecipes(
    vegan: true,
    glutenFree: true
)
```

### Add a Photo to Recipe

```swift
guard let fileURL = RecipeMediaModel.saveImage(image, for: recipe.uuid) else {
    return
}

let media = RecipeMediaModel(
    fileURL: fileURL,
    type: .photo,
    recipe: recipe
)
modelContext.insert(media)
try? modelContext.save()
```

### Create a Note

```swift
let note = RecipeNoteModel(
    content: "Reduce salt by half - too salty",
    isPinned: true,
    tags: ["modification", "tip"],
    recipe: recipe
)
modelContext.insert(note)
try? modelContext.save()
```

### Organize with Books

```swift
let favorites = RecipeBookModel(
    name: "Favorites",
    colorHex: "#FF6B6B",
    iconName: "heart.fill"
)
modelContext.insert(favorites)

favorites.recipes = [recipe1, recipe2, recipe3]
try? modelContext.save()
```

## Troubleshooting

### Migration Issues

If you encounter issues with migration:

```swift
// Reset migration flag
UserDefaults.standard.removeObject(forKey: "hasCompletedSwiftDataMigration")
```

### Viewing SwiftData Store

The SwiftData store is located at:
```swift
let storeURL = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("default.store")
```

### Performance Tips

1. **Use batch operations** for large datasets
2. **Limit @Query results** with predicates
3. **Fetch only needed properties** when possible
4. **Use external storage** for large media files
5. **Index frequently queried properties**

## Future Enhancements

Potential improvements to the architecture:

1. **CloudKit Sync** - Enable iCloud syncing
2. **Widgets** - Display recipes in widgets
3. **App Intents** - Siri shortcuts integration
4. **Background Processing** - Thumbnail generation
5. **Search Indexing** - Spotlight integration
6. **Export/Import** - Backup and restore functionality
7. **Recipe Sharing** - Share with other users
8. **Meal Planning** - Weekly meal schedule integration

## Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [WWDC SwiftData Videos](https://developer.apple.com/videos/swiftdata)
- [Migrating to SwiftData](https://developer.apple.com/documentation/swiftdata/migrating-to-swiftdata)

---

**Last Updated:** November 7, 2025
