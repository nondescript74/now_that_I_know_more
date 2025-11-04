# Recipe Import Implementation

Technical documentation for the recipe sharing and import system architecture.

---

## Overview

This document covers the technical implementation of the recipe sharing and import features. It's intended for developers who want to understand how the system works, modify it, or troubleshoot issues.

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface Layer                  │
├─────────────────────────────────────────────────────────┤
│ RecipeDetail.swift          │ RecipeImportPreviewView   │
│ - Email sharing button       │ - Import preview UI       │
│ - MFMailComposeViewController│ - Duplicate detection     │
│                              │ - Full recipe view        │
├─────────────────────────────────────────────────────────┤
│                  Application Logic Layer                 │
├─────────────────────────────────────────────────────────┤
│ NowThatIKnowMoreApp.swift   │ MealPlan.swift            │
│ - URL handler (onOpenURL)    │ - Manual import button    │
│ - Import preview state       │ - File picker             │
│ - Recipe store integration   │ - Sheet presentation      │
├─────────────────────────────────────────────────────────┤
│                     Data Layer                           │
├─────────────────────────────────────────────────────────┤
│ Recipe.swift                 │ RecipeStore.swift         │
│ - Data model (Codable)       │ - Storage management      │
│ - JSON serialization         │ - Duplicate detection     │
│                              │ - CRUD operations         │
├─────────────────────────────────────────────────────────┤
│                  iOS System Integration                  │
├─────────────────────────────────────────────────────────┤
│ Info.plist Configuration     │ MessageUI Framework       │
│ - Document type registration │ - MFMailComposeVC         │
│ - UTI declarations           │ - Email composition       │
└─────────────────────────────────────────────────────────┘
```

---

## Feature 1: Recipe Export (Email Sharing)

### Implementation Location
- **File**: `RecipeDetail.swift`
- **Component**: `emailRecipe()` method
- **UI**: "Email Recipe" button

### Flow Diagram

```
User taps "Email Recipe"
        ↓
Check MFMailComposeViewController.canSendMail()
        ↓
    ┌───────┴────────┐
   Yes              No
    ↓                ↓
Create email    Show alert
    ↓           (Configure Mail)
Generate HTML body
    ↓
Create .recipe file (JSON)
    ↓
Attach file to email
    ↓
Attach photos (up to 3)
    ↓
Present MFMailComposeViewController
    ↓
User sends email
    ↓
Recipient receives email + .recipe attachment
```

### Code Implementation

#### Email Availability Check

```swift
private func emailRecipe() {
    guard MFMailComposeViewController.canSendMail() else {
        showMailAlert = true
        return
    }
    showMailCompose = true
}
```

**Why this matters:**
- Prevents crashes on devices without Mail configured
- Provides helpful feedback to users
- Graceful degradation of functionality

#### File Generation

```swift
// Create .recipe file
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let recipeData = try encoder.encode(recipe)

// Write to temporary file
let filename = "\(recipe.title).recipe"
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(filename)
try recipeData.write(to: tempURL)
```

**Key points:**
- Uses `Codable` protocol for serialization
- ISO 8601 date encoding for compatibility
- Temporary directory for security and cleanup
- Filename includes recipe title for clarity

#### Email Composition

```swift
mailComposer.setSubject("Recipe: \(recipe.title)")
mailComposer.setMessageBody(htmlBody, isHTML: true)
mailComposer.addAttachmentData(recipeData, 
                               mimeType: "application/json", 
                               fileName: filename)

// Attach photos
for (index, photoURL) in recipe.userPhotoURLs.prefix(3).enumerated() {
    if let imageData = /* load image data */ {
        mailComposer.addAttachmentData(imageData,
                                       mimeType: "image/jpeg",
                                       fileName: "photo\(index + 1).jpg")
    }
}
```

**Design decisions:**
- HTML body for rich formatting
- Limit to 3 photos to keep email size reasonable
- MIME types properly set for compatibility
- Multiple attachments supported

### UIKit Bridge (UIViewControllerRepresentable)

```swift
struct MailComposeView: UIViewControllerRepresentable {
    let recipe: Recipe
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        // Configure mail composer...
        return mailComposer
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            isPresented = false
        }
    }
}
```

**Pattern:** UIKit integration in SwiftUI
- Uses `UIViewControllerRepresentable`
- Coordinator pattern for delegate callbacks
- Binding for dismissal control

---

## Feature 2: Recipe Import

### Implementation Location
- **File**: `NowThatIKnowMoreApp.swift` (URL handling)
- **File**: `RecipeImportPreviewView.swift` (Preview UI)
- **File**: `MealPlan.swift` (Manual import)

### Import Flow

```
Entry Point (one of three):
┌──────────────────────────────────────┐
│ 1. Email attachment tapped           │
│ 2. Files app file tapped             │
│ 3. Manual import button              │
└──────────┬───────────────────────────┘
           ↓
    iOS calls onOpenURL
           ↓
    Security-scoped resource access
           ↓
    Read file data
           ↓
    Parse JSON → Recipe object
           ↓
    Set importedRecipe state
           ↓
    Show RecipeImportPreviewView sheet
           ↓
┌──────────┴──────────┐
│  User Actions       │
├─────────────────────┤
│ • View preview      │
│ • View full recipe  │
│ • Check duplicates  │
│ • Import or Cancel  │
└──────────┬──────────┘
           ↓
    ┌──────┴──────┐
  Import       Cancel
    ↓              ↓
Add to store   Dismiss
    ↓
Success message
    ↓
Recipe in collection
```

### URL Handling Implementation

#### App-Level URL Handler

```swift
@main
struct NowThatIKnowMoreApp: App {
    @State private var recipeStore = RecipeStore()
    @State private var importedRecipe: Recipe?
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    
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
                .alert("Import Error", isPresented: $showImportError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(importErrorMessage)
                }
        }
    }
}
```

**Key components:**
- `@State` for import state management
- `.sheet(item:)` for preview presentation
- `.onOpenURL` for file association handling
- Error alert for user feedback

#### File Reading with Security Scope

```swift
private func handleRecipeImport(from url: URL) {
    // Validate file type
    guard url.pathExtension.lowercased() == "recipe" else {
        importErrorMessage = "Invalid file type. Expected .recipe file."
        showImportError = true
        return
    }
    
    // Security-scoped resource access
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
        if accessing {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    do {
        // Read file data
        let data = try Data(contentsOf: url)
        
        // Parse JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let recipe = try decoder.decode(Recipe.self, from: data)
        
        // Set state to show preview
        importedRecipe = recipe
        
    } catch {
        importErrorMessage = "Failed to import recipe: \(error.localizedDescription)"
        showImportError = true
    }
}
```

**Security considerations:**
- `startAccessingSecurityScopedResource()` required for files outside app sandbox
- `defer` ensures resource is always released
- Prevents unauthorized file access
- Follows iOS security best practices

#### Fallback JSON Parsing

```swift
// Primary: Decode directly to Recipe
let recipe = try decoder.decode(Recipe.self, from: data)

// Fallback: Parse as dictionary first
let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
```

**Why fallback matters:**
- Handles legacy formats
- More flexible error messages
- Can inspect structure before parsing
- Better debugging information

---

## Feature 3: Import Preview UI

### Component: RecipeImportPreviewView

#### Purpose
- Show recipe details before importing
- Allow user to review content
- Detect duplicate recipes
- Provide clear import/cancel actions

#### Layout Structure

```
┌─────────────────────────────────────┐
│         Navigation Bar               │
│  Cancel                    Import    │
├─────────────────────────────────────┤
│                                      │
│         Recipe Image                 │
│         (AsyncImage)                 │
│                                      │
├─────────────────────────────────────┤
│                                      │
│      Recipe Title                    │
│                                      │
│      Credits/Source                  │
│                                      │
├─────────────────────────────────────┤
│                                      │
│  ┌──────────┬──────────┬──────────┐ │
│  │  Icon    │   Icon   │   Icon   │ │
│  │  Label   │  Label   │  Label   │ │
│  │  Value   │  Value   │  Value   │ │
│  └──────────┴──────────┴──────────┘ │
│                                      │
├─────────────────────────────────────┤
│                                      │
│      Summary/Description             │
│                                      │
├─────────────────────────────────────┤
│                                      │
│   [View Full Recipe Button]          │
│                                      │
├─────────────────────────────────────┤
│  ⚠️  Duplicate Warning (if exists)   │
└─────────────────────────────────────┘
```

#### Key Features Implementation

**Duplicate Detection:**
```swift
private var isDuplicate: Bool {
    recipeStore.recipes.contains { $0.id == recipe.id }
}
```

**Info Cards with SF Symbols:**
```swift
private func infoCard(icon: String, label: String, value: String) -> some View {
    VStack(spacing: 4) {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(.blue.gradient)
        
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        
        Text(value)
            .font(.subheadline)
            .fontWeight(.semibold)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
}
```

**Full Recipe Sheet:**
```swift
.sheet(isPresented: $showFullRecipe) {
    NavigationStack {
        RecipeDetail(recipe: recipe)
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showFullRecipe = false }
                }
            }
    }
}
```

---

## Feature 4: Manual Import

### Implementation Location
- **File**: `MealPlan.swift`
- **Component**: Toolbar button + file picker

### Code Implementation

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button {
            showRecipeImport = true
        } label: {
            Label("Import Recipe", systemImage: "tray.and.arrow.down")
        }
    }
}
.fileImporter(
    isPresented: $showRecipeImport,
    allowedContentTypes: [.json],
    onCompletion: handleFileImport
)
```

### File Import Handler

```swift
private func handleFileImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
        // Same security-scoped access pattern
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
            errorMessage = error.localizedDescription
            showError = true
        }
        
    case .failure(let error):
        errorMessage = error.localizedDescription
        showError = true
    }
}
```

**Pattern:** Result type handling
- Explicit success/failure paths
- Type-safe error handling
- Consistent with Swift conventions

---

## Info.plist Configuration

### Document Type Declaration

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

**Explanation:**
- `CFBundleTypeName`: Human-readable type name
- `CFBundleTypeRole`: App can edit (not just view)
- `LSHandlerRank`: This app "owns" this file type
- `LSItemContentTypes`: Reference to UTI declaration

### Uniform Type Identifier (UTI)

```xml
<key>UTExportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.nowthatiknowmore.recipe</string>
        
        <key>UTTypeDescription</key>
        <string>Recipe File</string>
        
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.json</string>
            <string>public.data</string>
        </array>
        
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

**Hierarchy:**
- `.recipe` files are a specialization of JSON
- JSON is a specialization of data
- Conforms to public types for compatibility
- Custom extension for app-specific handling

---

## Data Model

### Recipe Structure

```swift
struct Recipe: Codable, Identifiable {
    let id: UUID
    var title: String
    var summary: String?
    var servings: Int?
    var readyInMinutes: Int?
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var extendedIngredients: [Ingredient]
    var analyzedInstructions: [InstructionSet]
    var userPhotoURLs: [URL]
    var userVideoURLs: [URL]
    var creditsText: String?
    var sourceUrl: String?
    // ... additional properties
}
```

**Codable requirements:**
- All properties must conform to Codable
- UUIDs and URLs are automatically Codable
- Custom types (Ingredient, InstructionSet) also Codable
- Optional properties for flexibility

### JSON Encoding Strategy

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601
```

**Benefits:**
- Pretty printing for human readability
- Sorted keys for consistent output
- ISO 8601 dates for cross-platform compatibility
- Standard JSON format

---

## Error Handling

### Error Categories

1. **File Access Errors**
   - Permission denied
   - File not found
   - Invalid path

2. **Parsing Errors**
   - Invalid JSON syntax
   - Missing required fields
   - Type mismatches

3. **System Errors**
   - Mail not configured
   - Out of storage
   - Network errors (for external images)

### Error Presentation Strategy

```swift
@State private var showError = false
@State private var errorMessage = ""

// In error handler:
catch {
    errorMessage = userFriendlyMessage(for: error)
    showError = true
}

// Alert presentation:
.alert("Import Error", isPresented: $showError) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```

**User-friendly messages:**
```swift
func userFriendlyMessage(for error: Error) -> String {
    if error is DecodingError {
        return "This file doesn't contain a valid recipe. Please ask the sender to share it again."
    } else if (error as NSError).domain == NSCocoaErrorDomain {
        return "Unable to read the file. It may be corrupted or in the wrong format."
    } else {
        return "Import failed: \(error.localizedDescription)"
    }
}
```

---

## Testing Strategy

### Unit Testing

**Recipe Encoding/Decoding:**
```swift
func testRecipeEncodingDecoding() throws {
    let original = Recipe(/* test data */)
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Recipe.self, from: encoded)
    
    XCTAssertEqual(original.id, decoded.id)
    XCTAssertEqual(original.title, decoded.title)
    // ... more assertions
}
```

**Duplicate Detection:**
```swift
func testDuplicateDetection() {
    let store = RecipeStore()
    let recipe = Recipe(/* test data */)
    
    store.addRecipe(recipe)
    XCTAssertTrue(store.recipes.contains { $0.id == recipe.id })
    
    // Verify duplicate handling
    store.addRecipe(recipe) // Should replace, not duplicate
    XCTAssertEqual(store.recipes.count, 1)
}
```

### Integration Testing

**Email Composition:**
1. Create test recipe with all fields populated
2. Trigger email composition
3. Verify MFMailComposeViewController presents
4. Check subject line, body, attachments
5. Cancel and verify cleanup

**Import Flow:**
1. Generate `.recipe` file
2. Simulate file opening via `onOpenURL`
3. Verify preview sheet appears
4. Test import action
5. Verify recipe in store

### UI Testing

```swift
func testImportPreview() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Simulate file import
    // Verify preview appears
    XCTAssertTrue(app.staticTexts["Recipe Title"].exists)
    XCTAssertTrue(app.buttons["Import Recipe"].exists)
    
    // Test import action
    app.buttons["Import Recipe"].tap()
    
    // Verify success
    // Check recipe appears in list
}
```

---

## Performance Considerations

### File I/O Optimization

**Async file loading:**
```swift
Task {
    let data = try await Data(contentsOf: url)
    let recipe = try JSONDecoder().decode(Recipe.self, from: data)
    await MainActor.run {
        self.importedRecipe = recipe
    }
}
```

**Benefits:**
- Non-blocking file reads
- UI remains responsive
- Progress indication possible
- Better user experience

### Image Loading

**AsyncImage with caching:**
```swift
AsyncImage(url: recipe.imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    @unknown default:
        EmptyView()
    }
}
```

**Automatic optimizations:**
- Built-in caching
- Lazy loading
- Memory management
- Cancellation on view disappear

### JSON Parsing Performance

**Best practices:**
- Use `Codable` (faster than manual parsing)
- Decode only needed fields if possible
- Consider streaming for very large files
- Profile with Instruments if issues arise

---

## Security Best Practices

### Input Validation

```swift
// Validate file extension
guard url.pathExtension.lowercased() == "recipe" else {
    throw ImportError.invalidFileType
}

// Validate file size (prevent DoS)
let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
let fileSize = attributes[.size] as? Int ?? 0
guard fileSize < 10_000_000 else { // 10 MB limit
    throw ImportError.fileTooLarge
}

// Validate JSON structure
let recipe = try JSONDecoder().decode(Recipe.self, from: data)
guard !recipe.title.isEmpty else {
    throw ImportError.invalidRecipeData
}
```

### Sandboxing

- ✅ App sandbox prevents unauthorized file access
- ✅ Security-scoped resources for user-selected files
- ✅ Temporary directory for generated files
- ✅ No direct file system paths exposed to user

### Data Sanitization

```swift
// Clean HTML from user input
var cleanedSummary = recipe.summary?
    .replacingOccurrences(of: "<script>", with: "")
    .replacingOccurrences(of: "javascript:", with: "")

// Validate URLs
if let sourceUrl = recipe.sourceUrl,
   let url = URL(string: sourceUrl),
   url.scheme == "http" || url.scheme == "https" {
    // URL is valid
}
```

---

## Future Enhancements

### Potential Improvements

1. **Batch Import**
   - Import multiple recipes at once
   - Progress indicator for bulk operations
   - Summary of imported recipes

2. **Cloud Sync**
   - iCloud Drive integration
   - Sync recipes across devices
   - Conflict resolution

3. **Recipe Collections**
   - Bundle multiple recipes
   - Themed collections (e.g., "Holiday Recipes")
   - Import entire collections at once

4. **QR Code Sharing**
   - Generate QR codes for recipes
   - Scan QR codes to import
   - Instant sharing without email

5. **Import from URLs**
   - Parse recipe from website URL
   - Structured data extraction
   - Direct import from recipe sites

6. **Version Control**
   - Track recipe modifications
   - Merge changes from shared recipes
   - Rollback to previous versions

7. **Enhanced Preview**
   - Ingredient substitutions
   - Nutrition calculator
   - Serving size adjuster in preview

### Technical Debt

- Consider streaming JSON parser for very large files
- Add comprehensive error logging
- Implement analytics (privacy-conscious)
- Add unit test coverage for edge cases
- Document API for third-party integration

---

## API Reference

### Key Methods

#### NowThatIKnowMoreApp

```swift
private func handleRecipeImport(from url: URL)
```
- **Parameters**: `url` - File URL from `onOpenURL`
- **Returns**: None (updates state)
- **Throws**: Sets error state on failure

#### RecipeImportPreviewView

```swift
init(recipe: Recipe, 
     onImport: @escaping (Recipe) -> Void, 
     onCancel: @escaping () -> Void)
```
- **Parameters**:
  - `recipe`: Recipe to preview
  - `onImport`: Callback when user imports
  - `onCancel`: Callback when user cancels
- **Returns**: View

#### MailComposeView

```swift
init(recipe: Recipe, isPresented: Binding<Bool>)
```
- **Parameters**:
  - `recipe`: Recipe to share
  - `isPresented`: Binding to control presentation
- **Returns**: UIViewControllerRepresentable

### State Management

```swift
// App-level state
@State private var importedRecipe: Recipe?
@State private var showImportError: Bool = false
@State private var importErrorMessage: String = ""

// View-level state
@State private var showFullRecipe: Bool = false
@State private var showMailCompose: Bool = false
@State private var showMailAlert: Bool = false
```

---

## Debugging Tips

### Common Issues

**Import not working:**
1. Check Info.plist configuration
2. Verify file extension is `.recipe`
3. Clean build and reinstall app
4. Check console for error messages

**Preview not showing:**
1. Verify `importedRecipe` state is set
2. Check `.sheet(item:)` is present
3. Ensure Recipe conforms to Identifiable
4. Look for SwiftUI view hierarchy issues

**Email not sending:**
1. Verify Mail app is configured
2. Check device (not simulator)
3. Test MFMailComposeViewController.canSendMail()
4. Review coordinator delegate implementation

### Console Logging

```swift
// Add detailed logging for debugging
do {
    let recipe = try decoder.decode(Recipe.self, from: data)
    print("✅ Successfully decoded recipe: \(recipe.title)")
    print("📊 Ingredients: \(recipe.extendedIngredients.count)")
    print("📝 Steps: \(recipe.analyzedInstructions.count)")
} catch let DecodingError.keyNotFound(key, context) {
    print("❌ Missing key: \(key.stringValue)")
    print("   Context: \(context.debugDescription)")
} catch {
    print("❌ Import failed: \(error)")
}
```

---

## Conclusion

This implementation provides a complete, production-ready recipe sharing and import system with:

✅ **Robust error handling**  
✅ **Security-conscious design**  
✅ **User-friendly interface**  
✅ **Cross-device compatibility**  
✅ **Extensible architecture**  

The system follows iOS best practices and provides a solid foundation for future enhancements.

---

## Related Documentation

- [Setup Guide](../setup/recipe-import-setup.md) - Configuration instructions
- [Sharing Guide](../guides/recipe-sharing.md) - How to share recipes
- [Import Guide](../guides/recipe-import.md) - How to import recipes

---

**Last Updated**: November 2025  
**Version**: 1.0
