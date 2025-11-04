# Recipe Import Guide

Learn how to import recipes shared with you via email or files.

---

## Overview

When someone shares a recipe with you, you'll receive a `.recipe` file that you can easily import into your app. This guide covers all the ways you can import recipes.

---

## Three Ways to Import

### Method 1: From Email (Easiest) 📧

This is the most common way to receive and import recipes.

**Steps:**
1. **Open the email** containing the recipe
2. **Tap the `.recipe` attachment** (usually shown at the bottom of the email)
3. Tap the **Share icon** (box with arrow pointing up)
4. Scroll and select **"Open in NowThatIKnowMore"** or **"NowThatIKnowMore"**
5. The app opens with a **preview** of the recipe
6. Review the recipe details
7. Tap **"Import Recipe"**
8. Success! The recipe is now in your collection

**What you'll see in the preview:**
- Recipe photo
- Title and description
- Number of ingredients and steps
- Cooking time and servings
- Option to view full recipe details

---

### Method 2: From Files App 📁

If you saved the recipe file to your device:

**Steps:**
1. Open the **Files** app
2. Navigate to where you saved the `.recipe` file
3. **Tap the file**
4. Choose **"NowThatIKnowMore"** from the app list
5. Preview appears
6. Tap **"Import Recipe"**

**Tip:** You can organize recipe files in folders before importing them!

---

### Method 3: Manual Import 🔍

Use the built-in import feature in the app:

**Steps:**
1. Open **NowThatIKnowMore** app
2. Go to the **Meal Plan** tab
3. Tap the **import button** (down arrow icon) in the top-left corner
4. Choose **"Choose Recipe File"**
5. Browse to select the `.recipe` file
6. Preview appears
7. Tap **"Import Recipe"**

**When to use this:**
- You have multiple recipe files saved locally
- You prefer browsing for files yourself
- The automatic methods didn't work

---

## Import Preview Features

Before importing, you can review the recipe:

### Quick Preview
Shows at-a-glance information:
- 📸 **Hero Image**: Main recipe photo
- 📊 **Stats Card**: 
  - Number of ingredients
  - Number of steps
  - Servings
  - Cook time
- 📝 **Summary**: Recipe description
- ⚠️ **Duplicate Warning**: If recipe already exists

### Full Recipe View
Tap **"View Full Recipe"** to see:
- Complete ingredient list with measurements
- Step-by-step instructions
- All photos
- Nutritional information (if available)
- Source and credits

### Actions
- ✅ **Import Recipe**: Add to your collection
- ❌ **Cancel**: Don't import, close preview

---

## Duplicate Detection

The app automatically checks if you already have a recipe:

### If Recipe Exists
- 🟠 **Warning banner** appears in preview
- Shows message: "This recipe already exists in your collection"
- You can still choose to import (replaces the existing one)

### Why This Happens
- Recipe files have unique identifiers
- Someone sent you a recipe you already have
- You're re-importing an updated version

### What To Do
- **Cancel** if you don't want to replace the existing recipe
- **Import** if you want the updated/newer version
- Compare both versions by opening your existing recipe first

---

## What Gets Imported

When you import a recipe, you get:

### Recipe Content ✅
- Recipe title
- Description/summary
- Complete ingredient list with measurements
- Step-by-step instructions
- Cooking times (prep, cook, total)
- Servings and yield

### Media ✅
- Photos (if included)
- Photo URLs
- Video links (if included)

### Metadata ✅
- Nutritional information
- Difficulty level
- Recipe source/URL
- Credits and attribution
- Cuisine type
- Dish type (breakfast, dinner, etc.)

### Technical ✅
- Unique recipe identifier (UUID)
- Date created
- Original source information

---

## Requirements

### Device Requirements
- iOS 17.0 or later
- iPadOS 17.0 or later
- NowThatIKnowMore app installed

### File Requirements
- File extension must be `.recipe`
- File must contain valid JSON data
- File must follow recipe format specification

---

## Troubleshooting

### "Open in NowThatIKnowMore" Doesn't Appear

**Possible Causes:**
- App not installed
- File extension isn't `.recipe`
- iOS needs to restart
- App configuration issue

**Solutions:**
1. Make sure the app is installed
2. Check the file name ends with `.recipe`
3. Try saving the file to Files app first, then open it
4. Restart your device
5. Reinstall the app if problem persists
6. Use the manual import method instead

---

### Import Fails with Error Message

**"Unable to parse recipe file"**
- File is corrupted or incomplete
- Ask sender to re-send the recipe
- Try downloading the attachment again

**"Access denied" or "Cannot read file"**
- Security restriction on the file
- Try copying file to Files app first
- Use manual import method

**"Recipe data is invalid"**
- File doesn't contain required recipe fields
- File might be a different JSON format
- Contact sender to verify they used the share feature

---

### Recipe Already Exists Warning

**This is normal!** It means:
- You already have this exact recipe
- The unique identifier matches an existing recipe
- This is duplicate detection working correctly

**What to do:**
- Click **Cancel** to keep your existing version
- Click **Import** to replace with the new version
- Compare both versions before deciding

---

### Recipe Looks Incomplete After Import

**Missing photos:**
- Original recipe didn't have photos
- Photos failed to load (check internet connection)
- Photos were too large and weren't included

**Missing information:**
- Original recipe was incomplete
- Sender created a minimal recipe
- Data was lost during file creation (rare)

**Solution:**
- Contact sender to verify original recipe
- Edit the recipe yourself to add missing info
- Ask for recipe to be re-sent

---

## Tips for Successful Imports

### Before Importing

1. **Check your email/file** is complete
   - Attachment is present
   - File size seems reasonable (not 0 KB)
   - File name ends with `.recipe`

2. **Preview first**
   - Look at the quick preview
   - Open full recipe view if needed
   - Verify it's the recipe you want

3. **Check for duplicates**
   - Notice the warning if it appears
   - Decide if you want to replace existing version

### While Importing

1. **Stay connected**
   - If recipe has external images, stay online
   - Photos load better with good internet

2. **Be patient**
   - Large recipes with many photos may take a moment
   - Don't close the app during import

3. **Review after import**
   - Find the recipe in your collection
   - Verify everything imported correctly
   - Add personal notes if desired

---

## After Import

### Finding Your Imported Recipe

The recipe will appear in:
- **Meal Plan tab**: Shows in your recipe collection
- Search for it by name
- Filter or sort to find it quickly

### What You Can Do Next

1. **Cook the recipe** 🍳
   - Follow the step-by-step instructions
   - Check off ingredients as you go

2. **Edit if needed** ✏️
   - Add your own notes
   - Adjust ingredient quantities
   - Add more photos

3. **Share with others** 📧
   - Pass it along to more friends
   - See [Recipe Sharing Guide](recipe-sharing.md)

4. **Organize** 📚
   - Add to meal plans
   - Tag or categorize
   - Create collections

---

## Privacy & Security

### What Happens to Your Data

✅ **Imported recipes are stored locally:**
- Saved on your device only
- Not uploaded to cloud servers
- Private to your app instance

✅ **Security measures:**
- Files are scanned for validity
- No code execution from files
- Security-scoped resource access
- Safe JSON parsing

✅ **No tracking:**
- We don't know what you import
- No analytics on imported recipes
- Your recipe collection stays private

---

## Advanced Topics

### File Format Details

The `.recipe` file is actually a JSON file:
- Human-readable text format
- Can be opened in any text editor
- Structure matches the Recipe data model
- Includes all recipe properties

**Example structure:**
```json
{
  "uuid": "123e4567-e89b-12d3-a456-426614174000",
  "title": "Chocolate Chip Cookies",
  "summary": "Delicious homemade cookies",
  "servings": 24,
  "readyInMinutes": 30,
  "extendedIngredients": [...],
  "analyzedInstructions": [...]
}
```

### Bulk Import

To import multiple recipes:
1. Save all `.recipe` files to a folder in Files app
2. Use manual import method
3. Import recipes one by one
4. Each will show preview before importing

**Future enhancement idea:** Multi-select import feature

### Recipe Bundles

**Current:** Import recipes individually  
**Future possibility:** Bundle multiple recipes into one file

---

## Troubleshooting Quick Reference

| Problem | Quick Fix |
|---------|-----------|
| Can't find "Open in App" | Save to Files, use manual import |
| Parse error | Ask sender to re-send file |
| Already exists warning | Choose to replace or cancel |
| Missing photos | Check internet connection |
| Button disabled | Verify file is `.recipe` format |
| Import hangs | Restart app, try again |
| File won't open | Check file isn't corrupted |

---

## Getting Help

### In-App Help
- Tap the **(?)** button in Meal Plan toolbar
- Shows quick tips and guidance
- Always available when you need it

### Documentation
- **This guide**: How to import recipes
- **[Sharing guide](recipe-sharing.md)**: How to share recipes
- **[Setup guide](../setup/recipe-import-setup.md)**: For developers

### Common Questions

**Q: Can I import recipes from websites?**  
A: Not directly. Recipes must be in `.recipe` format. Someone needs to share them with you using the app's share feature.

**Q: Can I import from other recipe apps?**  
A: Only if they export in `.recipe` format. Most apps use their own formats.

**Q: Is there a limit to how many recipes I can import?**  
A: No limit! Import as many as you'd like.

**Q: Can I undo an import?**  
A: Yes, just delete the recipe from your collection after importing.

**Q: Will imported recipes sync across devices?**  
A: Currently, recipes are stored locally. Cloud sync may come in a future update.

---

## Summary

✅ **Three import methods:**
1. From email (easiest)
2. From Files app
3. Manual import in app

✅ **Preview before import:**
- See recipe details
- View full recipe
- Check for duplicates

✅ **Safe and private:**
- Local storage only
- Security-scoped access
- No tracking

✅ **Easy troubleshooting:**
- Clear error messages
- Multiple import methods
- In-app help available

---

**Ready to import your first recipe?** 

Open an email with a `.recipe` attachment and give it a try! 🎉

---

**Related Guides:**
- [How to share recipes](recipe-sharing.md)
- [Developer setup](../setup/recipe-import-setup.md)
- [Technical details](../architecture/recipe-import-implementation.md)
