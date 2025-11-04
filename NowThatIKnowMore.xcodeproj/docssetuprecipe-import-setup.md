# Recipe Import Setup Guide

## Overview

This guide walks you through configuring your Xcode project to support recipe import functionality. The setup enables your app to handle `.recipe` files from email attachments, the Files app, and other sources.

**Time Required**: 5 minutes

---

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ target deployment
- Basic familiarity with Info.plist configuration

---

## Configuration Steps

### Step 1: Open Info.plist Configuration

Choose one of these methods:

#### Method A: Visual Editor (Recommended)

1. Open your Xcode project
2. Select your app target in the project navigator
3. Click the **Info** tab
4. You'll see sections for "Custom iOS Target Properties"

#### Method B: Source Code Editor

1. Right-click `Info.plist` in the project navigator
2. Select **Open As** → **Source Code**
3. You can paste XML directly

---

### Step 2: Add Document Type Registration

This tells iOS that your app can open `.recipe` files.

#### Using Visual Editor:

1. Find the **"Document Types"** section (or add it)
2. Click the **"+"** button to add a new document type
3. Fill in these values:

| Field | Value |
|-------|-------|
| **Name** | `Recipe Document` |
| **Identifier** | `com.nowthatiknowmore.recipe` |
| **Role** | `Editor` |
| **Handler Rank** | `Owner` |

4. Under **"Additional document type properties"**, add:
   - **LSItemContentTypes**: Add item `com.nowthatiknowmore.recipe`

#### Using Source Code:

Add this to your Info.plist:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Recipe Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.nowthatiknowmore.recipe</string>
        </array>
    </dict>
</array>
```

---

### Step 3: Export Type Identifier

This declares the `.recipe` file type to the system.

#### Using Visual Editor:

1. Find the **"Exported Type Identifiers"** section (or add it)
2. Click the **"+"** button
3. Fill in these values:

| Field | Value |
|-------|-------|
| **Description** | `Recipe File` |
| **Identifier** | `com.nowthatiknowmore.recipe` |
| **Conforms To** | `public.json`, `public.data` |

4. Under **"Additional exported UTI properties"**, expand **UTTypeTagSpecification**:
   - **public.filename-extension**: Add item `recipe`
   - **public.mime-type**: Add item `application/json`

#### Using Source Code:

Add this to your Info.plist:

```xml
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
        <string>com.nowthatiknowmore.recipe</string>
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

---

## Complete Info.plist XML

Here's the complete configuration if you want to copy/paste:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys here -->
    
    <!-- Document Types -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Recipe Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.nowthatiknowmore.recipe</string>
            </array>
        </dict>
    </array>
    
    <!-- Exported Type -->
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
            <string>com.nowthatiknowmore.recipe</string>
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
</dict>
</plist>
```

---

## Verification

After adding the configuration:

### 1. Clean Build
- Press **Shift + Cmd + K** to clean
- Press **Cmd + B** to build

### 2. Reinstall App
- Delete the app from your device/simulator
- Run from Xcode to reinstall
- This ensures iOS registers the new document type

### 3. Test File Recognition
1. Send yourself a test recipe via email
2. Open the email on your device
3. Tap the `.recipe` attachment
4. You should see **"Open in NowThatIKnowMore"** in the share sheet

---

## Troubleshooting

### Issue: "Open in [App]" Doesn't Appear

**Possible Causes:**
- Info.plist not configured correctly
- App not reinstalled after configuration
- File extension is not `.recipe`
- iOS needs restart (rare)

**Solutions:**
1. Verify Info.plist configuration matches exactly
2. Clean build folder (Shift + Cmd + K)
3. Delete app from device
4. Rebuild and reinstall
5. Restart device if still not working

### Issue: Build Errors After Adding Config

**Possible Causes:**
- XML syntax error
- Duplicate keys

**Solutions:**
1. Check XML syntax carefully
2. Ensure `<array>` and `<dict>` tags are properly closed
3. Use the visual editor instead if XML is problematic

### Issue: App Crashes on File Open

**Possible Causes:**
- Missing `onOpenURL` handler in app
- File parsing error

**Solutions:**
1. Verify `NowThatIKnowMoreApp.swift` has `onOpenURL` modifier
2. Check console logs for error messages
3. Test with a known-good `.recipe` file

---

## Testing Checklist

After configuration, test these scenarios:

- [ ] Send recipe via email to yourself
- [ ] Tap `.recipe` attachment in Mail
- [ ] See "Open in NowThatIKnowMore" option
- [ ] App opens and shows import preview
- [ ] Import completes successfully
- [ ] Recipe appears in collection
- [ ] Test with Files app (save, then tap file)
- [ ] Test manual import button
- [ ] Test duplicate detection

---

## Code Integration

The Info.plist configuration works with the following code in `NowThatIKnowMoreApp.swift`:

```swift
@main
struct NowThatIKnowMoreApp: App {
    @State private var recipeStore = RecipeStore()
    @State private var importedRecipe: Recipe?
    @State private var showImportPreview = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(recipeStore)
                .sheet(item: $importedRecipe) { recipe in
                    RecipeImportPreviewView(
                        recipe: recipe,
                        onImport: { recipeToImport in
                            recipeStore.addRecipe(recipeToImport)
                            importedRecipe = nil
                        },
                        onCancel: {
                            importedRecipe = nil
                        }
                    )
                }
                .onOpenURL { url in
                    handleRecipeImport(from: url)
                }
        }
    }
    
    private func handleRecipeImport(from url: URL) {
        guard url.pathExtension == "recipe" else { return }
        
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            let recipe = try JSONDecoder().decode(Recipe.self, from: data)
            importedRecipe = recipe
        } catch {
            print("Failed to import recipe: \\(error)")
        }
    }
}
```

---

## Additional Resources

- **Apple Documentation**: [Declaring New Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/defining_file_and_data_types_for_your_app)
- **User Guide**: See `docs/guides/recipe-import.md` for end-user instructions
- **Architecture**: See `docs/architecture/recipe-import-implementation.md` for technical details

---

## Summary

✅ **What you configured:**
- Document type registration for `.recipe` files
- Exported type identifier for the custom file format
- System integration for file handling

✅ **What this enables:**
- Opening `.recipe` files from Mail
- Opening `.recipe` files from Files app
- "Share to" functionality for your app
- Seamless recipe import experience

✅ **Next steps:**
1. Build and test on a device
2. Share the user guide with your users
3. Monitor for any import issues

---

**Configuration complete!** Your app is now ready to handle recipe imports. 🎉
