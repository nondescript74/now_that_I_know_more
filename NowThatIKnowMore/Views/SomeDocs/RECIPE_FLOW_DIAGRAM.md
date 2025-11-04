# Recipe Import & Export Flow Diagram

## Export Flow (Sending Recipes)

```
┌─────────────────────────┐
│   User Opens Recipe     │
│    in RecipeDetail      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Taps "Email Recipe"    │
│      Button             │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐     ┌────────────────────┐
│ Check if Mail is        │────▶│  Mail Not Config?  │
│    Available            │     │  Show Alert        │
└───────────┬─────────────┘     └────────────────────┘
            │ Mail Available
            ▼
┌─────────────────────────┐
│ MFMailComposeView       │
│    Opens with:          │
│  • HTML body            │
│  • .recipe attachment   │
│  • Photos (optional)    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   User Sends Email      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Recipient Receives     │
│    Email + Attachment   │
└─────────────────────────┘
```

## Import Flow (Receiving Recipes)

### Method 1: From Email/Files (Direct Open)

```
┌─────────────────────────┐
│  User Taps .recipe      │
│  File in Mail/Files     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  iOS Shows "Open in     │
│  NowThatIKnowMore"      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   App Launches via      │
│     onOpenURL           │
│ (NowThatIKnowMoreApp)   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  handleRecipeImport()   │
│  • Security-scoped      │
│  • Read file data       │
│  • Parse JSON           │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ RecipeImportPreviewView │
│      Shows:             │
│  • Image                │
│  • Title & Credits      │
│  • Stats                │
│  • Summary              │
│  • View Full Button     │
│  • Duplicate Warning?   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐     ┌────────────────────┐
│  User Taps "Import"     │     │   User Cancels     │
│      or "Replace"       │     │                    │
└───────────┬─────────────┘     └────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  finalizeImport()       │
│  • Add to RecipeStore   │
│  • Show success alert   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   Recipe Available in   │
│      Meal Plan          │
└─────────────────────────┘
```

### Method 2: Manual Import

```
┌─────────────────────────┐
│  User Opens Meal Plan   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Taps Import Button     │
│    (Top Left)           │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   RecipeImportView      │
│     Sheet Opens         │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Taps "Choose Recipe     │
│      File"              │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   System File Picker    │
│  (fileImporter)         │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  handleFileImport()     │
│  • Security-scoped      │
│  • Read file data       │
│  • Parse JSON           │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Show Preview in Same   │
│      Sheet              │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Import → Success!      │
└─────────────────────────┘
```

## Data Flow

### Recipe Object Transformation

```
Recipe (In-Memory)
       │
       ▼
JSON Encoding
       │
       ▼
.recipe File
(application/json)
       │
       ▼
Email Attachment
or File System
       │
       ▼
File Data
       │
       ▼
JSON Decoding
       │
       ▼
Recipe (In-Memory)
       │
       ▼
RecipeStore
```

## File Type Registration

```
iOS System Level
       │
       ▼
Info.plist Configuration
  • CFBundleDocumentTypes
  • UTExportedTypeDeclarations
       │
       ▼
iOS knows:
  • .recipe extension → NowThatIKnowMore
  • com.nowthatiknowmore.recipe → Your App
  • MIME: application/json
       │
       ▼
User Experience:
  • "Open in NowThatIKnowMore" appears
  • Custom icon shows for .recipe files
  • AirDrop works automatically
```

## Error Handling Paths

```
┌─────────────────────────┐
│   Import Attempt        │
└───────────┬─────────────┘
            │
            ├──▶ Can't Access File ───▶ Alert: "Unable to access file"
            │
            ├──▶ Invalid JSON ────────▶ Alert: "Unable to parse recipe"
            │
            ├──▶ Missing Fields ──────▶ Recipe(from:) returns nil
            │
            ├──▶ Duplicate UUID ──────▶ Warning shown in preview
            │
            └──▶ Success ─────────────▶ Recipe imported!
```

## Component Interaction

```
┌──────────────────────────────────────────────────────┐
│              NowThatIKnowMoreApp.swift               │
│  • onOpenURL handler                                 │
│  • State management                                  │
│  • Sheet presentation                                │
└────────┬─────────────────────────────────┬───────────┘
         │                                 │
         ▼                                 ▼
┌─────────────────────┐      ┌─────────────────────────┐
│  RecipeImportView   │      │ RecipeImportPreviewView │
│  • File picker      │      │ • Beautiful preview     │
│  • Manual import    │      │ • Full recipe view      │
└──────────┬──────────┘      │ • Import/cancel         │
           │                 └────────┬────────────────┘
           │                          │
           └──────────┬───────────────┘
                      │
                      ▼
           ┌──────────────────┐
           │   RecipeStore    │
           │  • Add recipe    │
           │  • Check dupes   │
           │  • Persist       │
           └──────────────────┘
```

## Security Flow

```
┌─────────────────────────┐
│   File URL Received     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ startAccessingSecurity  │
│    ScopedResource()     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   Read File Data        │
│   (within defer block)  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ stopAccessingSecurity   │
│    ScopedResource()     │
└─────────────────────────┘
```

## User Journey Map

```
Sender's Journey:
─────────────────
View Recipe → Email → Send → ✓ Shared

Recipient's Journey:
───────────────────
Receive Email → Tap Attachment → Preview → Import → ✓ Have Recipe

Alternative Journey:
──────────────────
Open App → Import Button → Choose File → Preview → Import → ✓ Have Recipe
```

## Success Metrics

```
✓ Email opened
✓ Attachment tapped
✓ App launched
✓ Preview shown
✓ Import completed
✓ Recipe appears in list
✓ User can cook it!
```

---

## Key Components

1. **RecipeDetail.swift** - Export via email
2. **NowThatIKnowMoreApp.swift** - Handle incoming files
3. **RecipeImportPreviewView.swift** - Beautiful preview
4. **RecipeImportView.swift** - Manual import
5. **RecipeStore.swift** - Data persistence
6. **Info.plist** - File type registration

## Critical Path

The most important path for smooth UX:

```
Email Tap → Preview (< 1s) → Import (< 0.5s) → Success
```

All animations and loading should be fast and responsive!
