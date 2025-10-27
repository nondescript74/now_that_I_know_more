# Recipe Import Setup Guide

This guide explains how to configure your app to handle `.recipe` files received via email or file sharing.

## Info.plist Configuration

Add the following to your `Info.plist` file to register the `.recipe` document type:

### Option 1: Using Xcode's Target Settings (Recommended)

1. Select your app target in Xcode
2. Go to the "Info" tab
3. Expand "Document Types" section
4. Click the "+" button to add a new document type
5. Configure as follows:
   - **Name**: Recipe Document
   - **Types**: com.nowthatiknowmore.recipe
   - **Role**: Viewer (or Editor if you want to support editing)
   - **Icon**: (Optional) Add an icon for recipe files

6. Expand "Exported Type Identifiers" section
7. Click the "+" button to add a new type
8. Configure as follows:
   - **Description**: Recipe Document
   - **Identifier**: com.nowthatiknowmore.recipe
   - **Conforms To**: public.json
   - **Extensions**: recipe

### Option 2: Manual Info.plist XML

If you prefer to edit the Info.plist XML directly, add:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Recipe Document</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.nowthatiknowmore.recipe</string>
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
        <string>Recipe Document</string>
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

## How It Works

Once configured, your app will:

1. **Email Attachments**: When a user receives an email with a `.recipe` attachment, they can tap it and see "Open in NowThatIKnowMore"
2. **Files App**: `.recipe` files in the Files app will show your app icon and can be opened with your app
3. **AirDrop**: Received `.recipe` files via AirDrop will automatically offer to open in your app

## Testing the Import

### Creating a Test Recipe File

1. Run your app and view any recipe
2. Tap "Email Recipe"
3. Send the email to yourself
4. On the receiving device, tap the `.recipe` attachment
5. Choose "NowThatIKnowMore" from the share sheet

### Manual Testing

You can also create a test file:

1. Create a file named `test.recipe` with valid JSON recipe data
2. AirDrop it to your device or add it to Files app
3. Tap the file to open it in your app

## Current Implementation Status

✅ `onOpenURL` handler in `NowThatIKnowMoreApp.swift`
✅ `RecipeImportView` with file picker and preview
✅ `MailComposeView` exports recipes as `.recipe` files
✅ Security-scoped resource access
✅ Duplicate detection

⚠️ **Needs Setup**: Info.plist configuration (see above)

## User Experience Flow

1. User receives email with recipe attachment
2. Tap `.recipe` file in Mail app
3. iOS shows "Open in NowThatIKnowMore"
4. App opens with RecipeImportView
5. Preview of recipe is shown
6. User taps "Import This Recipe"
7. Recipe is added to their collection

## Troubleshooting

**Problem**: "Open in NowThatIKnowMore" doesn't appear
- **Solution**: Make sure Info.plist is properly configured and app is installed

**Problem**: Import fails with "Unable to access file"
- **Solution**: Ensure security-scoped resource access is working (already implemented)

**Problem**: Recipe file shows as generic document
- **Solution**: Add a custom icon for the recipe document type in your asset catalog

## Advanced: Custom Recipe Icon

To make `.recipe` files visually distinct:

1. Create an icon for recipe documents (suggested: fork and knife symbol)
2. Add it to your asset catalog as "RecipeDocumentIcon"
3. In document type configuration, set the icon file name
