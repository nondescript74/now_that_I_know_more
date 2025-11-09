# SwiftData Data Flow Diagrams

## App Lifecycle and Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Launch                                │
│                                                                   │
│  NowThatIKnowMoreApp.init()                                      │
│    ├─ Create ModelContainer                                      │
│    ├─ Initialize ModelContext                                    │
│    └─ Check for migration                                        │
│                                                                   │
│  .onAppear                                                        │
│    └─ migrateLegacyRecipes()                                     │
│         ├─ Check UserDefaults flag                               │
│         ├─ Load legacy recipes from JSON                         │
│         ├─ Convert to RecipeModel                                │
│         ├─ Insert into ModelContext                              │
│         ├─ Save to SwiftData                                     │
│         └─ Set migration complete flag                           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Recipe CRUD Flow

### Creating a Recipe

```
User Action                View Layer              Service Layer           Data Layer
───────────               ────────────            ─────────────           ──────────

Tap "Add"      ─→   Show edit form
                           │
Enter details  ─→    Update @State
                           │
Tap "Save"     ─→    Create RecipeModel ─→  Insert into context ─→  Write to SQLite
                           │                        │
                           │                        ├─ Generate UUID
                           │                        ├─ Set timestamps
                           │                        └─ Validate relationships
                           │
                     Dismiss sheet
                           │
                     @Query refreshes ←────── Model change notification
                           │
                     UI updates automatically
```

### Reading Recipes

```
View Lifecycle            Query System            Data Layer              Database
──────────────           ────────────            ──────────              ────────

View appears   ─→   @Query initialized  ─→   Fetch from context  ─→   SQL SELECT
                           │                        │                        │
                           │                        │                   Load models
                           │                        │                        │
                           │                        ├───────────────────────┘
                           │                        │
                    Populate @Query    ←──────  Return [RecipeModel]
                           │
                    Render List
                           │
Data changes   ─→   Auto-refresh       ─→   Fetch updated data  ─→   SQL SELECT
                           │                        │
                    UI updates          ←──────  New results
```

### Updating a Recipe

```
User Action                View Layer              Model Layer             Database
───────────               ────────────            ───────────             ────────

Edit field     ─→   Update @Bindable   ─→   Modify property     ─→   Mark as changed
                           │                        │
                           │                  Set modifiedAt
                           │                        │
Tap "Save"     ─→    Call save()       ─→   modelContext.save() ─→   SQL UPDATE
                           │                        │
                           │                        ├─ Transaction begin
                           │                        ├─ Write changes
                           │                        └─ Commit
                           │
                    @Query refreshes   ←──────  Change notification
                           │
                     UI updates
```

### Deleting a Recipe

```
User Action                View Layer              Service Layer           Database
───────────               ────────────            ─────────────           ────────

Swipe left     ─→   Show delete button
                           │
Confirm delete ─→    modelContext.delete() ─→  Mark for deletion  ─→  SQL DELETE
                           │                        │                        │
                           │                        ├─ Cascade to media     │
                           │                        ├─ Cascade to notes     │
                           │                        └─ Nullify book refs    │
                           │                        │                        │
                           │                   Save context          ─→  Commit
                           │                        │
                     @Query refreshes   ←──────  Deletion notification
                           │
                    Remove from list
```

## Relationship Management

### Adding a Photo to Recipe

```
User Action                View Layer              Model Layer             File System
───────────               ────────────            ───────────             ───────────

Select photo   ─→   PhotosPicker
                           │
                    Load image data
                           │
                    Compress image      ─→   Save to disk       ─→   Write JPEG
                           │                        │                        │
                           │                   Get file path      ←──────  Return URL
                           │                        │
                    Create MediaModel   ─→   Set recipe relationship
                           │                        │
                    Insert & save       ─→   Update parent timestamps
                           │                        │
                    @Query refreshes    ←──────  Change notification
                           │
                    Display in gallery


Recipe Deletion Cascade:

Recipe deleted ─→  Delete rule: .cascade  ─→  Delete all media items
                           │                           │
                           │                    Delete files from disk
                           │                           │
                           │                           └─ Cleanup thumbnails
```

### Adding Recipe to Book

```
User Action                View Layer              Model Layer             Database
───────────               ────────────            ───────────             ────────

Select recipes ─→   Track selections
                           │
Tap "Add"      ─→    Append to book.recipes ─→  Update relationship ─→  SQL INSERT
                           │                        │                    (join table)
                           │                        │
                           │                   Update timestamps
                           │                        │
                     Save context        ─→   Commit changes      ─→  Transaction
                           │
                     @Query refreshes    ←──────  Notification
                           │
                    Show in book list


Many-to-Many Relationships:

RecipeModel ←──────────────────────────────────→ RecipeBookModel
      │                                                 │
      │         SwiftData Join Table                   │
      │              (automatic)                        │
      │                                                 │
   recipes[] ←──────────────────────────────────→  books[]
```

## Query Flow with Predicates

```
View Declaration          Query Compilation       Database Query          Result
────────────────         ─────────────────       ──────────────          ──────

@Query(                                          SELECT * FROM Recipe
  filter: #Predicate {   ─→  Compile to SQL ─→  WHERE vegetarian = 1    ─→  [Recipe1,
    $0.vegetarian              predicate           AND servings > 2             Recipe3,
    == true &&                                     ORDER BY modifiedAt          Recipe5]
    $0.servings > 2                                DESC;
  },
  sort: \.modifiedAt,
  order: .reverse
) var recipes


Optimization:

User types    ─→   Update predicate  ─→   New SQL query   ─→   Filtered results
in search             (debounced)           (efficient)           (instant UI)
```

## Service Layer Operations

```
View Layer                RecipeService           ModelContext            Database
──────────               ─────────────           ────────────            ────────

service.searchRecipes(   ─→  Build predicate    ─→  Create descriptor
  query: "pasta"              for search              with filter
)                                  │                        │
                                   │                   Fetch from DB    ─→  Query
                                   │                        │
                                   │                   Filter results   ←─  Rows
                                   │                        │
                              Sort results    ←──────  Return models
                                   │
return results      ←──────  [RecipeModel]


service.filterRecipes(   ─→  Combine predicates ─→  Complex query     ─→  Optimized
  vegetarian: true,           (AND logic)             (single pass)         SELECT
  glutenFree: true
)

service.addRecipe(       ─→  Insert model       ─→  Validate           ─→  Insert row
  recipe,                     ├─ Set timestamps      ├─ Check unique        ├─ Check
  toBook: book                ├─ Link relationship   └─ Update refs          │  constraints
)                             └─ Save context                            ─→  Commit
```

## Preview System Flow

```
#Preview Declaration      Container Creation      Sample Data            View Render
────────────────────     ──────────────────      ───────────            ───────────

#Preview {               ─→  ModelContainer      ─→  Create in-memory  ─→  Instantiate
  RecipeBooksView()           .preview()               SQLite store         view with
    .modelContainer(                                        │                context
      try!                                            Insert sample            │
      ModelContainer                                  data (books,             │
        .preview()                                    recipes, etc.)           │
    )                                                        │                 │
}                                                            │                 │
                                                        Return context    ─→  Render UI


Preview Data Lifecycle:

Create preview ─→  In-memory store ─→  Add sample data ─→  Render view
                         │                                      │
                         │                                  Interact
                         │                                      │
                         │                              Modify data
                         │                                      │
Dismiss preview ─→  Destroy store  ←─────────────────────  Cleanup
```

## Migration Flow

```
App Launch              Migration Check          Legacy Store            SwiftData
──────────             ───────────────          ────────────            ─────────

Start app    ─→   Check flag:                  
                   "hasCompleted...Migration"
                         │
                         ├─ Already done? ──────────────────→  Skip migration
                         │
                         └─ Not done? ──────→  Load recipes.json
                                                      │
                                               Parse [Recipe]
                                                      │
                                                      ├──→  Recipe 1 ─→  Convert to
                                                      │                   RecipeModel
                                                      │                       │
                                                      ├──→  Recipe 2 ─→  Insert into
                                                      │                   context
                                                      │                       │
                                                      └──→  Recipe N ─→  Save all
                                                                              │
                                               Set flag = true        ←──────┘
                                                      │
                                               Complete migration


Conversion Details:

Recipe (struct)          Adapter Layer           RecipeModel (@Model)
───────────────         ─────────────           ────────────────────

uuid                ─→  Direct copy          ─→  uuid (unique)
title               ─→  Direct copy          ─→  title
ingredients         ─→  JSON encode          ─→  extendedIngredientsJSON
mediaItems          ─→  Convert each         ─→  Create RecipeMediaModel
notes               ─→  Convert each         ─→  Create RecipeNoteModel
books               ─→  Link relationships   ─→  Establish many-to-many
```

## Performance Optimizations

```
Query Strategy            Optimization            Result
──────────────           ────────────            ──────

Fetch all recipes    ─→  Add predicate      ─→  Only load recent
@Query                   (last 30 days)         Reduce memory

Large images         ─→  External storage   ─→  Keep DB small
@Attribute               (.externalStorage)     Fast queries

Many relationships   ─→  Lazy loading       ─→  Load on demand
                         (automatic)            Faster initial load

Frequent saves       ─→  Batch operations   ─→  Reduce I/O
                         (single save)          Better performance

Search queries       ─→  Database-level     ─→  Instant results
                         filtering              No memory overhead
```

## Error Handling Flow

```
User Action              Try Operation           Handle Error            Recovery
───────────             ─────────────           ────────────            ────────

Save recipe    ─→   try context.save()  ─→  catch {              ─→  Show alert
                           │                    ├─ Log error             │
                           │                    ├─ Rollback              │
                           ├─ Success           └─ Notify user           │
                           │                                              │
                           └────────────────────────────────────────────→  Continue


Transaction Pattern:

Start operation          Begin transaction       Commit/Rollback         UI Update
───────────────         ─────────────────       ───────────────         ─────────

Multiple inserts ─→  Batch in context    ─→  All succeed? ──→  Commit  ─→  Success
                           │                        │
                           │                    Any fail? ───→  Rollback ─→  Error
```

## Data Sync Pattern (Future)

```
Local Change             CloudKit Sync           Remote Store            Merge
────────────            ─────────────           ────────────            ─────

Modify recipe   ─→   Push to iCloud      ─→   Update remote   ─→   Sync to
on Device A             (automatic)              database            Device B
                                                                          │
                                                                     Pull changes
                                                                          │
                                                                     Merge conflicts
                                                                          │
                                                                     Update local DB
                                                                          │
                                                                     Notify views
```

---

These diagrams illustrate the complete data flow through your SwiftData architecture, from user interactions to database persistence and back to the UI.
