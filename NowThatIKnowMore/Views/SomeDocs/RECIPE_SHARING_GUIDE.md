# Recipe Sharing & Import Guide

## How to Share Recipes

### Sharing via Email

1. Open any recipe in your collection
2. Scroll down and tap **"Email Recipe"**
3. The email composer will open with:
   - A beautifully formatted HTML email body
   - An attached `.recipe` file containing all recipe data
   - Optional: Photos you've added to the recipe
4. Send the email to anyone!

### What Recipients Receive

When someone receives your email, they get:
- **Email Body**: A nicely formatted recipe with ingredients and instructions
- **Attachment**: A `.recipe` file they can import into their own app

## How to Import Recipes

There are **three ways** to import recipes:

### Method 1: From Email (Easiest)

1. Open the email containing the recipe
2. Tap the `.recipe` attachment
3. Choose **"Open in NowThatIKnowMore"** from the share menu
4. Review the recipe preview
5. Tap **"Import Recipe"**
6. Done! The recipe is now in your collection

### Method 2: From Files App

1. Save the `.recipe` file to your Files app
2. Tap the file
3. Choose **"Open in NowThatIKnowMore"**
4. Review and import as above

### Method 3: Manual Import

1. Open the app and go to the **Meal Plan** tab
2. Tap the **Import** button (down arrow icon) in the top left
3. Choose **"Choose Recipe File"**
4. Browse for the `.recipe` file
5. Review and import

## Import Features

### Preview Before Import
Before adding a recipe to your collection, you can:
- View the recipe image
- See ingredients count and cooking time
- Read the summary/description
- Check servings information
- Open the full recipe details

### Duplicate Detection
The app automatically checks if you already have this recipe:
- If it exists, you'll see a warning
- You can choose to replace the existing recipe
- Or cancel the import

### What Gets Imported
When you import a recipe, you get:
- Recipe title and description
- Full ingredient list
- Step-by-step instructions
- Cooking times and servings
- Nutritional information (if available)
- Photos and images
- Credits and source URL

## Tips

### For Senders
- Make sure to tap "Send" after the email composer opens
- The `.recipe` file is small and email-friendly
- Recipients don't need an email client configured to view the recipe in the email body
- But they do need the app to import the `.recipe` file

### For Recipients
- If "Open in NowThatIKnowMore" doesn't appear, make sure:
  - The app is installed
  - The file extension is `.recipe` (not `.txt` or `.json`)
  - Your iOS is up to date
- You can also save the file first and import later

## Troubleshooting

**Problem**: Can't send email
- **Solution**: Configure Mail app on your device, or the button will be disabled with a helpful message

**Problem**: "Open in NowThatIKnowMore" doesn't appear
- **Solution**: The app needs to be configured to handle `.recipe` files (see RECIPE_IMPORT_SETUP.md)

**Problem**: Import fails with "Unable to parse"
- **Solution**: The file may be corrupted. Ask the sender to re-send it

**Problem**: Recipe already exists
- **Solution**: This is normal! You can replace it if you want the updated version

## Privacy Note

- Recipe sharing is done via standard email
- No cloud services are used
- Recipe data stays between you and your recipients
- Photos are attached directly to emails (up to 3 photos)

## Advanced: AirDrop

You can also share recipes via AirDrop:
1. Export the recipe via email (to get the `.recipe` file)
2. Save the attachment
3. AirDrop the `.recipe` file directly
4. Recipient can open it in the app immediately

## File Format

The `.recipe` file is actually a JSON file with a custom extension. This means:
- It's human-readable (you can open it in a text editor)
- It's compatible with JSON tools
- It's easy to back up or archive
- It's cross-platform compatible

## Future Ideas

Potential enhancements for recipe sharing:
- QR code generation for quick sharing
- Bulk export/import
- Recipe collections or bundles
- Share to social media
- Recipe URL scheme (nowthatiknowmore://import/...)

---

**Enjoy sharing recipes with friends and family!** 🍳👨‍🍳👩‍🍳
