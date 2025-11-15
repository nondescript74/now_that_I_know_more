# Ingredient Image System - Data Flow Diagram

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    NowThatIKnowMore App                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────────┐    ┌──────────────┐
│ Recipe Views │    │ Test Interface   │    │ Programmatic │
│              │    │                  │    │   Access     │
│ • Detail     │    │ • Quick Test     │    │              │
│ • Editor     │    │ • Full Test      │    │ • Services   │
│ • Cards      │    │ • Statistics     │    │ • Utilities  │
└──────┬───────┘    └────────┬─────────┘    └──────┬───────┘
       │                     │                      │
       └────────────┬────────┴──────────────────────┘
                    │
                    ▼
       ┌────────────────────────────┐
       │  IngredientImageView       │
       │  (SwiftUI Component)       │
       │                            │
       │  • Size configurable       │
       │  • Auto-caching            │
       │  • Placeholder fallback    │
       └────────────┬───────────────┘
                    │
                    ▼
       ┌────────────────────────────────┐
       │ IngredientImageMappingService  │
       │ (Business Logic Layer)         │
       │                                │
       │  • Cache lookup                │
       │  • Smart URL generation        │
       │  • Testing & validation        │
       │  • Result recording            │
       └────────┬───────────────────────┘
                │
       ┌────────┴─────────┐
       │                  │
       ▼                  ▼
┌──────────────┐   ┌──────────────────┐
│  SwiftData   │   │  Spoonacular CDN │
│   Database   │   │                  │
│              │   │  • 100x100 imgs  │
│  Cached      │   │  • JPG & PNG     │
│  Mappings    │   │  • Public API    │
└──────────────┘   └──────────────────┘
```

## 🔄 Request Flow

### First Time (Cache Miss)

```
1. User View Request
   └──► IngredientImageView(id: 11215, name: "garlic")
         │
         ▼
2. Check Cache
   └──► IngredientImageMappingService.getImageURL()
         │
         ├──► Query SwiftData for ingredientID: 11215
         │    └──► Not Found ❌
         │
         ▼
3. Generate Test URLs
   └──► smartFallbackURLs(for: "garlic")
         │
         ├──► "garlic.jpg"
         ├──► "garlic.png"
         ├──► "garlics.jpg"
         └──► "garlics.png"
         │
         ▼
4. Test URLs (in order)
   └──► testURL("https://spoonacular.com/.../garlic.jpg")
         │
         ├──► HTTP 200 ✅
         │    └──► Success! Found image
         │
         ▼
5. Save Mapping
   └──► recordSuccess(id: 11215, filename: "garlic.jpg")
         │
         └──► Insert into SwiftData ✅
         │
         ▼
6. Return URL
   └──► URL("https://spoonacular.com/.../garlic.jpg")
         │
         ▼
7. Display Image
   └──► AsyncImage loads and displays ✅
```

### Subsequent Times (Cache Hit)

```
1. User View Request
   └──► IngredientImageView(id: 11215, name: "garlic")
         │
         ▼
2. Check Cache
   └──► IngredientImageMappingService.getImageURL()
         │
         ├──► Query SwiftData for ingredientID: 11215
         │    └──► Found! ✅
         │         └──► imageFilename: "garlic.jpg"
         │
         ▼
3. Return Cached URL (instant)
   └──► URL("https://spoonacular.com/.../garlic.jpg")
         │
         ▼
4. Display Image
   └──► AsyncImage loads and displays ✅

⏱️  Time: <1ms (vs 2-3 seconds on first request)
📶 Network: 0 requests (vs 6-10 on first request)
```

## 🗄️ Database Schema

```
┌───────────────────────────────────────────────────┐
│     IngredientImageMappingModel (@Model)          │
├───────────────────────────────────────────────────┤
│                                                   │
│  @Attribute(.unique) ingredientID: Int           │  ◄── Primary Key
│  ingredientName: String                           │  ◄── "garlic"
│  imageFilename: String?                           │  ◄── "garlic.jpg"
│  tested: Bool                                     │  ◄── true/false
│  attemptsCount: Int                               │  ◄── 1 (found on first try)
│  lastVerified: Date                               │  ◄── 2025-11-15
│  noImageAvailable: Bool                           │  ◄── false
│  attemptedURLsJSON: String?                       │  ◄── ["garlic.jpg"]
│                                                   │
└───────────────────────────────────────────────────┘

Relationships:
• None (standalone cache)
• Could extend to link with RecipeModel in future

Indexes:
• Primary: ingredientID (unique)
• Secondary: tested (for filtering)

Queries:
• Find by ID: #Predicate { $0.ingredientID == id }
• Find by name: #Predicate { $0.ingredientName == name }
• Get all tested: #Predicate { $0.tested == true }
• Get successful: #Predicate { $0.imageFilename != nil }
• Get failed: #Predicate { $0.noImageAvailable == true }
```

## 🎯 URL Generation Strategy

```
Input: "dried basil"
│
├─► Step 1: Check Known Mappings
│   └─► IngredientImageMapper.shared.knownFilename(for: "dried basil")
│       └─► Result: "basil.jpg" ✅
│
├─► Step 2: Exact Hyphenated
│   └─► normalizeToHyphenated("dried basil", "jpg")
│       └─► Result: "dried-basil.jpg"
│
├─► Step 3: PNG Version
│   └─► normalizeToHyphenated("dried basil", "png")
│       └─► Result: "dried-basil.png"
│
├─► Step 4: Simplified Core
│   └─► simplifyIngredientName("dried basil")
│       │
│       ├─► Check coreIngredients list
│       │   └─► Contains "basil" ✅
│       │       └─► Result: "basil"
│       │
│       └─► Append extensions
│           ├─► "basil.jpg"
│           └─► "basil.png"
│
├─► Step 5: Plural Variations
│   └─► generatePluralVariations("dried basil")
│       ├─► "dried-basils.jpg"
│       ├─► "dried-basils.png"
│       └─► (no singular - doesn't end in 's')
│
└─► Final URL List (deduplicated):
    1. "basil.jpg"          ◄── From known mapping (tries first!)
    2. "dried-basil.jpg"
    3. "dried-basil.png"
    4. "basil.png"
    5. "dried-basils.jpg"
    6. "dried-basils.png"
```

## 📊 Statistics Tracking

```
Database Statistics Object
┌─────────────────────────────────┐
│  total: Int                     │ ◄── All entries in database
│  successful: Int                │ ◄── Has valid imageFilename
│  failed: Int                    │ ◄── noImageAvailable = true
│  untested: Int                  │ ◄── tested = false
└─────────────────────────────────┘

Example:
┌─────────────────────────────────┐
│  total: 992                     │
│  successful: 497                │  (50.1% success rate)
│  failed: 445                    │  (44.9% no image)
│  untested: 50                   │  (5.0% not yet tested)
└─────────────────────────────────┘

Display in UI:
"DB: 497/992"  ◄── Shows in nav bar
```

## 🧪 Testing Flow

```
Batch Test Process
│
├─► Initialize
│   ├─► Get SpoonacularIngredientManager.shared.ingredients
│   └─► Total: 992 ingredients
│
├─► For Each Ingredient
│   │
│   ├─► Test URLs
│   │   └─► Try each URL until success or all fail
│   │
│   ├─► Record Result
│   │   ├─► Success: save imageFilename
│   │   └─► Failure: mark noImageAvailable
│   │
│   └─► Auto-Save (every 100)
│       └─► Persist to database
│
└─► Complete
    ├─► Final save
    ├─► Print summary
    └─► Update UI

Progress Updates:
[50/992] - 5%
[100/992] - 10% ◄── Auto-save
[200/992] - 20% ◄── Auto-save
[300/992] - 30% ◄── Auto-save
...
[992/992] - 100% ◄── Final save ✅
```

## 🎨 Component Hierarchy

```
┌─────────────────────────────────────────────────────┐
│              Recipe Detail View                     │
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │        Ingredients Section                 │   │
│  │                                            │   │
│  │  ┌──────────────────────────────────────┐ │   │
│  │  │  Ingredient Row (ForEach)            │ │   │
│  │  │                                      │ │   │
│  │  │  ┌────────────────────────────────┐ │ │   │
│  │  │  │  IngredientImageView           │ │ │   │
│  │  │  │  ┌──────────────────────────┐  │ │ │   │
│  │  │  │  │  AsyncImage or          │  │ │ │   │
│  │  │  │  │  Placeholder            │  │ │ │   │
│  │  │  │  └──────────────────────────┘  │ │ │   │
│  │  │  └────────────────────────────────┘ │ │   │
│  │  │                                      │ │   │
│  │  │  Text(ingredient.name)               │ │   │
│  │  │  Text(ingredient.amount)             │ │   │
│  │  └──────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

Data Flow:
Recipe → ExtendedIngredient[] → ForEach → IngredientImageView
         └─► ingredient.id
         └─► ingredient.name
```

## 💾 Persistence Lifecycle

```
App Lifecycle
│
├─► App Launch
│   └─► SwiftData container initialized
│       └─► IngredientImageMappingModel registered
│
├─► First Use
│   ├─► User views recipe
│   ├─► IngredientImageView requested
│   ├─► Service queries empty database
│   ├─► Tests and discovers URLs
│   └─► Saves mappings
│
├─► Subsequent Uses
│   ├─► Service queries populated database
│   ├─► Instant cache hits
│   └─► No network requests
│
└─► App Termination
    └─► SwiftData auto-saves
        └─► All mappings persisted ✅

Next Launch:
└─► All cached mappings still available ✅
```

## 🔄 State Machine

```
Ingredient Image State
│
├─► UNKNOWN (initial)
│   │
│   ├──► [Request Image]
│   │    └──► → LOADING
│   │
│   └──► [In Database]
│        ├──► Has Image → CACHED
│        └──► No Image → NO_IMAGE
│
├─► LOADING (testing URLs)
│   │
│   ├──► [Success]
│   │    └──► → CACHED
│   │
│   └──► [All Failed]
│        └──► → NO_IMAGE
│
├─► CACHED (permanent)
│   └──► Display image from URL ✅
│
└─► NO_IMAGE (permanent)
    └──► Display placeholder ✅

State Transitions:
UNKNOWN → LOADING → CACHED ✅
UNKNOWN → LOADING → NO_IMAGE ✅
UNKNOWN → CACHED (if in database) ✅
UNKNOWN → NO_IMAGE (if in database) ✅
```

---

## 🎯 Key Takeaways

1. **Cache-First Architecture**: Always check SwiftData before network
2. **Smart Discovery**: Multiple URL strategies maximize success
3. **Persistent Learning**: Results saved permanently in SwiftData
4. **Graceful Degradation**: Beautiful placeholders for missing images
5. **Performance Optimized**: Instant lookups, batch processing, auto-save
6. **Developer Friendly**: One-line integration, fully documented

---

**This system provides a robust, performant, and maintainable solution for ingredient image display! 🚀**
