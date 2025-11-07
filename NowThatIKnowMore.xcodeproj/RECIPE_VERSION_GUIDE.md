# Recipe Format Versioning Guide

## Overview

The Recipe JSON format now includes a version field (`recipeFormatVersion`) to track compatibility and enable future migrations. This ensures that recipes shared between users can be properly imported even as the format evolves.

## Version History

### Version 2.0 (Current)
- **Date**: November 7, 2025
- **Changes**:
  - Added `recipeFormatVersion` field to track format version
  - SwiftData migration complete
  - Media items stored as relationships
  - Backward compatible with Version 1.0

### Version 1.0 (Legacy)
- Original JSON format without version field
- Used before SwiftData migration
- Still supported for import

## Implementation

### Recipe Struct

The `Recipe` struct now includes:

```swift
struct Recipe: Codable {
    // Recipe format version for compatibility tracking
    let recipeFormatVersion: String
    
    // Current version constant
    static let currentFormatVersion = "2.0"
    
    // ... other fields
}
```

### Encoding

When exporting recipes (via email or other means), the current version is always included:

```swift
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    // Always encode the current version
    try container.encode(Recipe.currentFormatVersion, forKey: .recipeFormatVersion)
    
    // ... encode other fields
}
```

### Decoding

When importing recipes, the version is decoded with a default for backward compatibility:

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // Version field with default for backward compatibility
    self.recipeFormatVersion = try container.decodeIfPresent(String.self, forKey: .recipeFormatVersion) ?? "1.0"
    
    // ... decode other fields
}
```

### Dictionary Initialization

The dictionary initializer also supports versioning:

```swift
init?(from dict: [String: Any]) {
    // Version field with default for backward compatibility
    self.recipeFormatVersion = dict["recipeFormatVersion"] as? String ?? "1.0"
    
    // ... initialize other fields
}
```

## Backward Compatibility

The implementation is **fully backward compatible**:

1. **Importing Old Recipes**: Recipes without a version field are automatically assigned version "1.0"
2. **Exporting New Recipes**: All exported recipes include the current version "2.0"
3. **No Breaking Changes**: Existing recipe files continue to work without modification

## JSON Example

### Version 2.0 Recipe

```json
{
  "recipeFormatVersion": "2.0",
  "uuid": "123e4567-e89b-12d3-a456-426614174000",
  "title": "Chocolate Chip Cookies",
  "servings": 24,
  "extendedIngredients": [...],
  "instructions": "...",
  "mediaItems": [...],
  "featuredMediaID": "...",
  ...
}
```

### Version 1.0 Recipe (Legacy)

```json
{
  "uuid": "123e4567-e89b-12d3-a456-426614174000",
  "title": "Chocolate Chip Cookies",
  "servings": 24,
  "extendedIngredients": [...],
  "instructions": "...",
  ...
}
```

Note: Version 1.0 files lack the `recipeFormatVersion` field entirely.

## Usage in Code

### Checking Recipe Version

```swift
let recipe = Recipe(from: jsonData)

switch recipe.recipeFormatVersion {
case "1.0":
    print("Legacy format")
    // Apply any necessary migrations
case "2.0":
    print("Current format")
default:
    print("Unknown version: \(recipe.recipeFormatVersion)")
}
```

### Creating New Recipes

When creating recipes programmatically, they automatically use the current version:

```swift
// Through encoding (automatic)
let recipe = Recipe(...)
let jsonData = try JSONEncoder().encode(recipe)
// Will include "recipeFormatVersion": "2.0"

// Through dictionary (manual)
let dict: [String: Any] = [
    "recipeFormatVersion": Recipe.currentFormatVersion,
    "uuid": UUID().uuidString,
    "title": "New Recipe",
    ...
]
let recipe = Recipe(from: dict)
```

### SwiftData Conversion

When converting from `RecipeModel` (SwiftData) to `Recipe` (JSON), the version is included:

```swift
func toLegacyRecipe() -> Recipe? {
    var dict: [String: Any] = [
        "recipeFormatVersion": Recipe.currentFormatVersion,
        "uuid": uuid.uuidString,
        ...
    ]
    return Recipe(from: dict)
}
```

## Future Versioning

When making breaking changes to the recipe format:

1. **Increment the version** in `Recipe.currentFormatVersion`
2. **Update the decoder** to handle the new fields
3. **Add migration logic** in the decoder or a separate migration function
4. **Document changes** in this file

### Example Migration Pattern

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let version = try container.decodeIfPresent(String.self, forKey: .recipeFormatVersion) ?? "1.0"
    self.recipeFormatVersion = version
    
    // Handle version-specific decoding
    if version == "1.0" {
        // Old format - may need special handling
        self.newField = nil
    } else if version == "2.0" {
        // Current format
        self.newField = try container.decodeIfPresent(String.self, forKey: .newField)
    } else {
        // Future version - try to decode anyway
        self.newField = try container.decodeIfPresent(String.self, forKey: .newField)
    }
    
    // ... decode other fields
}
```

## Benefits

1. **Forward Compatibility**: Newer versions of the app can import older recipe formats
2. **Backward Compatibility**: Older versions gracefully ignore unknown fields
3. **Migration Tracking**: Know which recipes need updating
4. **Debugging**: Easily identify format-related issues
5. **Feature Detection**: Enable/disable features based on version
6. **User Communication**: Inform users about format updates

## Testing

When testing recipe import/export:

1. **Test with version 1.0 files** (without the field)
2. **Test with version 2.0 files** (with the field)
3. **Test round-trip** (export then import)
4. **Test with unknown versions** (future-proofing)

## Related Files

- `Welcome.swift` - Recipe struct definition and encoding/decoding
- `Recipe+Decoding.swift` - Additional decoding logic
- `ModelsRecipeModel.swift` - SwiftData model and conversion
- `RecipeDetail.swift` - Export functionality

---

**Last Updated**: November 7, 2025
