# Recipe Image Display Preference Implementation Guide

## Overview
This guide explains how to add a user preference for choosing between displaying the image URL or the featured media in recipes.

## Recipe Model Changes Required

You'll need to add two new properties to your `Recipe` model:

### 1. Add the `preferFeaturedMedia` Property

Add this stored property to your Recipe struct/class:

```swift
var preferFeaturedMedia: Bool?
```

This property controls which image source to display when both are available:
- `true` (default): Display the featured media from the media gallery
- `false`: Display the image from the URL field
- `nil`: Defaults to `true` for backward compatibility

### 2. Update the `featuredMediaURL` Computed Property

Modify your existing `featuredMediaURL` computed property to respect the preference:

```swift
var featuredMediaURL: String? {
    // If user explicitly prefers URL image over featured media, return the URL
    if preferFeaturedMedia == false, let urlImage = image, !urlImage.isEmpty {
        return urlImage
    }
    
    // Otherwise, try to return featured media
    if let featuredID = featuredMediaID,
       let featured = mediaItems?.first(where: { $0.id == featuredID }) {
        return featured.url
    }
    
    // Fall back to the URL image if no featured media exists
    return image
}
```

### Logic Flow:

1. **User prefers URL image** (`preferFeaturedMedia == false`):
   - Return the `image` URL if it exists
   - Otherwise fall through to featured media

2. **User prefers featured media** (`preferFeaturedMedia == true` or `nil`):
   - Try to find and return the featured media item
   - If no featured media exists, fall back to the `image` URL

3. **No preference set** (backward compatibility):
   - Treat as `true`, preferring featured media

## Usage in RecipeEditorView

The `RecipeEditorView` has been updated to:

1. **Display a toggle** when both an image URL and featured media exist:
   ```swift
   Toggle("Prefer Featured Media Over URL Image", isOn: $preferFeaturedMedia)
   ```

2. **Show helpful text** explaining the current selection:
   - When enabled: "The featured media will be displayed instead of the image URL."
   - When disabled: "The image URL will be displayed instead of the featured media."

3. **Save the preference** when the recipe is saved

## Display Behavior in RecipeDetail

The `RecipeDetail` view already uses `recipe.featuredMediaURL`, so once you update the Recipe model as described above, it will automatically respect the user's preference.

### Current RecipeDetail Logic:
```swift
if let featuredURL = recipe.featuredMediaURL, !featuredURL.isEmpty {
    // Display the image from featuredURL
    // (This will now be either the featured media or the URL image based on preference)
}
```

## Migration and Backward Compatibility

- **Existing recipes**: Will have `preferFeaturedMedia = nil`, which defaults to `true`
- **New recipes**: Will default to `true` (prefer featured media)
- **No breaking changes**: Existing code continues to work without modification

## Example Recipe JSON Structure

```json
{
  "uuid": "...",
  "title": "Example Recipe",
  "image": "https://example.com/recipe.jpg",
  "mediaItems": [
    {
      "id": "...",
      "url": "/path/to/local/image.jpg",
      "type": "photo"
    }
  ],
  "featuredMediaID": "...",
  "preferFeaturedMedia": true
}
```

## Testing Scenarios

### Scenario 1: Both URL and Featured Media Exist
- Set `preferFeaturedMedia = true` → Display featured media
- Set `preferFeaturedMedia = false` → Display URL image

### Scenario 2: Only URL Exists
- Display URL image regardless of preference

### Scenario 3: Only Featured Media Exists
- Display featured media regardless of preference

### Scenario 4: Neither Exists
- Display placeholder image

## Implementation Checklist

- [x] Add `@State private var preferFeaturedMedia: Bool` to RecipeEditorView
- [x] Initialize `preferFeaturedMedia` in RecipeEditorView's init
- [x] Add toggle UI in mediaSection
- [x] Update `loadRecipe()` to load the preference
- [x] Update `saveEdits()` to save the preference
- [ ] Add `var preferFeaturedMedia: Bool?` to Recipe model
- [ ] Update `featuredMediaURL` computed property in Recipe model
- [ ] Update Recipe's `Codable` conformance if needed
- [ ] Update Recipe's initializer to handle the new field
- [ ] Test with existing recipes
- [ ] Test with new recipes

## Notes

- The preference only appears when both an image URL and featured media exist
- This gives users full control over which image source to display
- The UI is intuitive and provides clear feedback about the current selection
- The implementation maintains backward compatibility with existing recipes
