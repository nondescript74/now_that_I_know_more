//
//  RecipeSharingGuide.md
//  NowThatIKnowMore
//
//  Guide for setting up recipe file type support
//

# Recipe Sharing Setup Guide

## Overview
This app now supports sharing recipes via email and importing them back. Recipes are exported as `.recipe` files (JSON format).

## Features Implemented

### 1. Recipe Export (Email Sharing)
- **Location**: `RecipeDetail.swift` and `RecipeEditorView.swift`
- **Button**: "Email Recipe"
- **Functionality**:
  - Exports recipe as `.recipe` file (JSON format)
  - Sends via email with formatted HTML preview
  - Includes first 3 user photos as attachments
  - Recipients can save the `.recipe` file

### 2. Recipe Import
- **Location**: `RecipeImportView.swift`
- **Functionality**:
  - File picker to select `.recipe` files
  - Preview recipe before importing
  - Validates and imports into RecipeStore
  - Prevents duplicate imports

### 3. File Type Support
The app registers `.recipe` as a custom file type.

## Required Info.plist Configuration

Add the following to your app's `Info.plist`:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Recipe</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.yourcompany.recipe</string>
        </array>
    </dict>
</array>

<key>UTExportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.json</string>
            <string>public.data</string>
        </array>
        <key>UTTypeDescription</key>
        <string>Recipe File</string>
        <key>UTTypeIdentifier</key>
        <string>com.yourcompany.recipe</string>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>recipe</string>
            </array>
            <key>public.mime-type</key>
            <array>
                <string>application/json</string>
            </array>
        </dict>
    </dict>
</array>
```

**Note**: Replace `com.yourcompany` with your actual bundle identifier prefix.

## Usage Instructions

### Sharing a Recipe (Sender)

1. **From Recipe Detail View**:
   - Navigate to a recipe
   - Tap "Email Recipe" button
   - Mail composer opens with:
     - Subject: "Recipe: [Recipe Title]"
     - HTML formatted email body with recipe preview
     - Attached `.recipe` file
     - First 3 user photos (if any)
   - Add recipients and send

2. **From Recipe Editor View**:
   - When editing an existing recipe
   - Tap "Email Recipe" button
   - Follow same steps as above

### Importing a Recipe (Receiver)

#### Method 1: From Email (iOS/iPadOS)
1. Open email with `.recipe` attachment
2. Tap the `.recipe` file attachment
3. Tap the Share button
4. Select "NowThatIKnowMore" from the app list
5. App opens with import preview
6. Tap "Import This Recipe"

#### Method 2: Manual Import
1. Save `.recipe` file to Files app
2. Open NowThatIKnowMore app
3. Navigate to import view (add button in main view)
4. Tap "Choose Recipe File"
5. Select the `.recipe` file
6. Preview appears
7. Tap "Import This Recipe"

## Integration with Main App

### Adding Import Button to Main View

Add this to your main recipes list view:

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            NavigationLink(destination: RecipeImportView()) {
                Label("Import Recipe", systemImage: "tray.and.arrow.down")
            }
            // ... other menu items
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

Or add a dedicated button:

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        NavigationLink(destination: RecipeImportView()) {
            Image(systemName: "tray.and.arrow.down")
        }
    }
}
```

### Handling App Launch with Recipe File

To handle opening `.recipe` files when tapped in Files or Mail, add this to your App struct:

```swift
@main
struct NowThatIKnowMoreApp: App {
    @State private var recipeStore = RecipeStore()
    @State private var importURL: URL?
    @State private var showImport = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(recipeStore)
                .sheet(isPresented: $showImport) {
                    if let url = importURL {
                        RecipeImportView(initialURL: url)
                    }
                }
                .onOpenURL { url in
                    if url.pathExtension == "recipe" {
                        importURL = url
                        showImport = true
                    }
                }
        }
    }
}
```

Then update `RecipeImportView` to accept an optional initial URL:

```swift
struct RecipeImportView: View {
    // ...existing code...
    
    init(initialURL: URL? = nil) {
        if let url = initialURL {
            // Auto-load the file
            self._isImporting = State(initialValue: false)
            // Process the URL immediately in onAppear
        }
    }
    
    // Add onAppear to process initialURL
}
```

## File Format

The `.recipe` file is a JSON representation of the Recipe object. Example:

```json
{
  "uuid": "123e4567-e89b-12d3-a456-426614174000",
  "title": "Chocolate Chip Cookies",
  "summary": "Delicious homemade cookies",
  "creditsText": "Grandma's Recipe",
  "servings": 24,
  "readyInMinutes": 30,
  "extendedIngredients": [...],
  "analyzedInstructions": [...],
  "userPhotoURLs": [...],
  "userVideoURLs": [...]
}
```

## Security Considerations

1. **File Validation**: The import process validates JSON structure
2. **Duplicate Prevention**: Checks UUID to prevent duplicate imports
3. **Sandboxing**: Uses security-scoped resources for file access
4. **Error Handling**: Comprehensive error messages for invalid files

## Testing

1. **Export Test**:
   - Create/edit a recipe
   - Tap "Email Recipe"
   - Send to yourself
   - Verify email contains HTML preview and attachment

2. **Import Test**:
   - Open email from step 1
   - Tap `.recipe` attachment
   - Share to app
   - Verify recipe imports correctly

3. **File Type Test**:
   - Save `.recipe` file to Files app
   - Long-press file
   - Verify "NowThatIKnowMore" appears in Open With menu

## Troubleshooting

### File Type Not Recognized
- Verify Info.plist configuration
- Clean build folder (Shift+Cmd+K)
- Delete and reinstall app
- Check bundle identifier matches

### Email Composer Doesn't Appear
- Ensure device has Mail app configured
- Check MFMailComposeViewController availability
- Test on physical device (Simulator may not have Mail setup)

### Import Doesn't Work
- Check file has `.recipe` extension
- Verify JSON is valid
- Check console for error messages
- Ensure RecipeStore is properly initialized

## Future Enhancements

Possible improvements:
- AirDrop support
- QR code sharing
- iCloud sharing links
- Recipe collections/bundles
- Version compatibility checking
- Recipe encryption for private recipes
