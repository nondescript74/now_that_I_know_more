# SwiftData Quick Reference

## Setup

### App Level
```swift
@main
struct MyApp: App {
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = try! ModelContainer.create()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

### View Level
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [RecipeModel]
    
    var body: some View {
        List(recipes) { recipe in
            Text(recipe.title ?? "Untitled")
        }
    }
}
```

## CRUD Operations

### Create
```swift
let recipe = RecipeModel(title: "New Recipe")
modelContext.insert(recipe)
try? modelContext.save()
```

### Read
```swift
// Simple query
@Query private var recipes: [RecipeModel]

// Sorted query
@Query(sort: \.title) private var recipes: [RecipeModel]

// Filtered query
@Query(filter: #Predicate<RecipeModel> { $0.vegetarian == true })
private var vegRecipes: [RecipeModel]

// Complex query
@Query(
    filter: #Predicate<RecipeModel> { recipe in
        recipe.vegetarian == true && 
        recipe.servings ?? 0 > 2
    },
    sort: \.modifiedAt,
    order: .reverse
) 
private var recipes: [RecipeModel]
```

### Update
```swift
recipe.title = "Updated Title"
recipe.modifiedAt = Date()
try? modelContext.save()
```

### Delete
```swift
modelContext.delete(recipe)
try? modelContext.save()
```

## Relationships

### One-to-Many
```swift
// In parent model
@Relationship(deleteRule: .cascade, inverse: \Child.parent)
var children: [Child]?

// In child model
var parent: Parent?
```

### Many-to-Many
```swift
// In RecipeModel
@Relationship(inverse: \RecipeBookModel.recipes)
var books: [RecipeBookModel]?

// In RecipeBookModel
@Relationship var recipes: [RecipeModel]?
```

### Adding to Relationship
```swift
// One-to-many
let media = RecipeMediaModel(fileURL: url, recipe: recipe)
modelContext.insert(media)

// Many-to-many
if book.recipes == nil {
    book.recipes = []
}
book.recipes?.append(recipe)
try? modelContext.save()
```

### Removing from Relationship
```swift
// One-to-many
modelContext.delete(media)  // Automatically removes from recipe

// Many-to-many
book.recipes?.removeAll { $0.uuid == recipe.uuid }
try? modelContext.save()
```

## Querying

### Basic Predicates
```swift
// Equality
#Predicate<RecipeModel> { $0.vegetarian == true }

// Comparison
#Predicate<RecipeModel> { $0.servings ?? 0 > 4 }

// String matching
#Predicate<RecipeModel> { 
    $0.title?.localizedStandardContains("pasta") ?? false 
}

// Multiple conditions (AND)
#Predicate<RecipeModel> { recipe in
    recipe.vegetarian == true && 
    recipe.glutenFree == true
}

// Optional unwrapping
#Predicate<RecipeModel> { recipe in
    (recipe.servings ?? 0) >= 4
}
```

### Sorting
```swift
// Single sort
@Query(sort: \.title) 
private var recipes: [RecipeModel]

// Multiple sorts
@Query(sort: [
    SortDescriptor(\.isPinned, order: .reverse),
    SortDescriptor(\.createdAt, order: .reverse)
]) 
private var notes: [RecipeNoteModel]

// With order
@Query(sort: \.modifiedAt, order: .reverse)
private var recipes: [RecipeModel]
```

### Fetch Descriptor
```swift
let descriptor = FetchDescriptor<RecipeModel>(
    predicate: #Predicate { $0.vegetarian == true },
    sortBy: [SortDescriptor(\.title)]
)

let results = try? modelContext.fetch(descriptor)
```

## Using RecipeService

### Initialize
```swift
@State private var service: RecipeService?

.onAppear {
    if service == nil {
        service = RecipeService(modelContext: modelContext)
    }
}
```

### Common Operations
```swift
// Fetch all recipes
let recipes = service.fetchRecipes()

// Search
let results = service.searchRecipes(query: "pasta")

// Filter
let vegRecipes = service.filterRecipes(vegetarian: true)

// Add to book
service.addRecipe(recipe, toBook: book)

// Add media
service.addMedia(media, toRecipe: recipe)

// Add note
service.addNote(note, toRecipe: recipe)
```

## Models

### Recipe
```swift
let recipe = RecipeModel(
    title: "Pasta",
    servings: 4,
    vegetarian: true,
    summary: "Delicious pasta dish",
    instructions: "1. Boil water\n2. Cook pasta"
)
```

### Media
```swift
let media = RecipeMediaModel(
    fileURL: "/path/to/image.jpg",
    thumbnailURL: "/path/to/thumb.jpg",
    caption: "Final dish",
    type: .photo,
    sortOrder: 0,
    recipe: recipe
)
```

### Note
```swift
let note = RecipeNoteModel(
    content: "Great recipe!",
    isPinned: true,
    tags: ["favorite", "easy"],
    recipe: recipe
)
```

### Book
```swift
let book = RecipeBookModel(
    name: "Favorites",
    bookDescription: "My favorite recipes",
    colorHex: "#FF6B6B",
    iconName: "heart.fill",
    sortOrder: 0
)
```

## Previews

### Basic Preview
```swift
#Preview {
    ContentView()
        .modelContainer(try! ModelContainer.preview())
}
```

### Preview with Sample Data
```swift
#Preview {
    let container = try! ModelContainer.preview()
    let context = container.mainContext
    
    let recipe = RecipeModel(title: "Test Recipe")
    context.insert(recipe)
    
    return RecipeDetailView(recipe: recipe)
        .modelContainer(container)
}
```

## Common Patterns

### Computed Property for Relationships
```swift
extension RecipeModel {
    var sortedMedia: [RecipeMediaModel] {
        mediaItems?.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
    
    var pinnedNotes: [RecipeNoteModel] {
        notes?.filter { $0.isPinned }.sorted { $0.createdAt > $1.createdAt } ?? []
    }
}
```

### Conditional Queries
```swift
struct RecipeListView: View {
    let showOnlyVegetarian: Bool
    
    @Query private var recipes: [RecipeModel]
    
    init(showOnlyVegetarian: Bool) {
        self.showOnlyVegetarian = showOnlyVegetarian
        
        if showOnlyVegetarian {
            _recipes = Query(
                filter: #Predicate { $0.vegetarian == true },
                sort: \.title
            )
        } else {
            _recipes = Query(sort: \.title)
        }
    }
}
```

### Observing Changes
```swift
struct RecipeDetailView: View {
    @Bindable var recipe: RecipeModel
    
    var body: some View {
        Form {
            TextField("Title", text: $recipe.title ?? "")
            // Changes automatically saved when you modify recipe
        }
    }
}
```

## Error Handling

### Safe Save
```swift
do {
    try modelContext.save()
} catch {
    print("Failed to save: \(error.localizedDescription)")
    // Handle error
}
```

### Transaction
```swift
do {
    // Multiple operations
    modelContext.insert(recipe1)
    modelContext.insert(recipe2)
    book.recipes = [recipe1, recipe2]
    
    // Save all at once
    try modelContext.save()
} catch {
    // Roll back on error
    modelContext.rollback()
    print("Transaction failed: \(error)")
}
```

## Testing

### Basic Test
```swift
import Testing
import SwiftData

@Test("Create recipe")
func createRecipe() throws {
    let container = try ModelContainer.preview()
    let context = container.mainContext
    
    let recipe = RecipeModel(title: "Test")
    context.insert(recipe)
    try context.save()
    
    let descriptor = FetchDescriptor<RecipeModel>()
    let recipes = try context.fetch(descriptor)
    
    #expect(recipes.count == 1)
    #expect(recipes.first?.title == "Test")
}
```

### Service Test
```swift
@Test("Add recipe to book")
func addRecipeToBook() throws {
    let container = try ModelContainer.preview()
    let service = RecipeService(modelContext: container.mainContext)
    
    let recipe = RecipeModel(title: "Test")
    let book = RecipeBookModel(name: "Test Book")
    
    service.addRecipe(recipe)
    service.addRecipeBook(book)
    service.addRecipe(recipe, toBook: book)
    
    #expect(book.recipes?.count == 1)
    #expect(book.recipes?.first?.uuid == recipe.uuid)
}
```

## Performance Tips

### 1. Fetch Only What You Need
```swift
// ❌ Fetch everything
@Query private var recipes: [RecipeModel]

// ✅ Fetch with predicate
@Query(
    filter: #Predicate { $0.modifiedAt > Date().addingTimeInterval(-86400) }
)
private var recentRecipes: [RecipeModel]
```

### 2. Use External Storage
```swift
@Attribute(.externalStorage) 
var largeData: Data?
```

### 3. Batch Operations
```swift
// ❌ Save multiple times
for recipe in recipes {
    modelContext.insert(recipe)
    try? modelContext.save()
}

// ✅ Save once
for recipe in recipes {
    modelContext.insert(recipe)
}
try? modelContext.save()
```

### 4. Limit Results
```swift
let descriptor = FetchDescriptor<RecipeModel>(
    predicate: predicate,
    sortBy: [SortDescriptor(\.title)],
    fetchLimit: 50
)
```

## Debugging

### Print All Recipes
```swift
let descriptor = FetchDescriptor<RecipeModel>()
let recipes = try? modelContext.fetch(descriptor)
print("Total recipes: \(recipes?.count ?? 0)")
recipes?.forEach { print("- \($0.title ?? "Untitled")") }
```

### Check Relationships
```swift
print("Recipe: \(recipe.title ?? "Untitled")")
print("Media items: \(recipe.mediaItems?.count ?? 0)")
print("Notes: \(recipe.notes?.count ?? 0)")
print("Books: \(recipe.books?.count ?? 0)")
```

### Inspect Model Context
```swift
print("Has changes: \(modelContext.hasChanges)")
print("Inserted objects: \(modelContext.insertedModelsArray.count)")
print("Deleted objects: \(modelContext.deletedModelsArray.count)")
```

---

**Quick Tip:** Use `@Bindable` for two-way binding to SwiftData models in SwiftUI!
