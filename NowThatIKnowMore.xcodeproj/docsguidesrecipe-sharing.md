# Recipe Sharing Guide

Learn how to share your favorite recipes with friends and family using email.

---

## Overview

The app makes it easy to share recipes via email. When you share a recipe, recipients get:
- A beautifully formatted email with the full recipe
- A `.recipe` file attachment they can import into their own app
- Photos you've added to the recipe (up to 3)

---

## How to Share a Recipe

### Step-by-Step

1. **Open the recipe** you want to share
2. Scroll to find the **"Email Recipe"** button
3. Tap the button
4. The Mail composer will open automatically with:
   - Subject line: "Recipe: [Recipe Name]"
   - Beautifully formatted HTML email body
   - Recipe photos included in the email
   - A `.recipe` file attached
5. **Add recipients** to the To: field
6. (Optional) Add a personal message
7. Tap **Send**

### What Recipients See

#### In the Email Body
- Recipe title and description
- Complete ingredient list
- Step-by-step instructions
- Cooking time and servings
- Photos (if you added any)
- Nutritional information (if available)

#### As an Attachment
- A `.recipe` file they can tap to import
- See [Recipe Import Guide](recipe-import.md) for how recipients can import

---

## Requirements

### For Sending Recipes

**Mail App Configuration**
- Your device must have the Mail app configured with at least one email account
- If Mail isn't configured, the "Email Recipe" button will be disabled
- You'll see a helpful message explaining how to set up Mail

**Supported Devices**
- iPhone running iOS 17.0 or later
- iPad running iPadOS 17.0 or later

---

## Features

### Beautiful Email Formatting

The email is automatically formatted with:
- ✨ Professional layout with proper spacing
- 📸 Embedded recipe photos
- 📝 Organized ingredient list
- 🔢 Numbered cooking instructions
- 🍽️ Recipe metadata (servings, time, difficulty)

### Attachment Details

The `.recipe` file includes:
- Complete recipe data (ingredients, instructions, metadata)
- Recipe photos (URLs or embedded data)
- Video URLs (if you added any)
- Source and credit information
- Unique recipe identifier

### Privacy & Security

- ✅ No cloud services involved
- ✅ Direct email sharing only
- ✅ You control who receives the recipe
- ✅ No tracking or analytics
- ✅ Photos are sent directly, not stored elsewhere

---

## Tips for Best Results

### Before Sharing

1. **Add Photos**: Recipes with photos look better in emails
   - Add up to 3 photos for the best email size
   - First photo appears as the hero image
   
2. **Complete the Recipe**: Make sure you have:
   - A descriptive title
   - All ingredients listed
   - Clear step-by-step instructions
   - Cooking times and servings

3. **Add Credits**: If the recipe isn't yours, add attribution:
   - Original source
   - Author name
   - Website URL

### While Sharing

1. **Personalize It**: Add a message to your email
   - "You have to try this!"
   - "Made this last week, it was amazing!"
   - Share your own tips or modifications

2. **Multiple Recipients**: Share with multiple people at once
   - Great for sharing family recipes
   - Perfect for meal planning with friends

### After Sharing

1. **Follow Up**: Ask recipients if they received it
2. **Help with Import**: Share the import guide if needed
3. **Get Feedback**: Ask how they liked the recipe

---

## Troubleshooting

### "Email Recipe" Button is Disabled

**Why?**  
The Mail app is not configured on your device.

**Solution:**  
1. Go to **Settings** → **Mail**
2. Tap **Accounts**
3. Add an email account (iCloud, Gmail, etc.)
4. Return to the app
5. The button should now work

### Mail Composer Doesn't Open

**Possible Causes:**
- Mail app not configured
- iOS needs to be updated
- Temporary app glitch

**Solutions:**
1. Verify Mail app works by opening it directly
2. Restart the app
3. Restart your device
4. Check for iOS updates

### Email Looks Wrong

**Issue**: Email formatting appears broken
- This is usually a mail client issue on the recipient's end
- The HTML is standards-compliant
- Works with most modern email clients

**Workaround**: Recipients can import the `.recipe` file attachment instead

### Attachment Not Included

**Issue**: Recipient doesn't see the `.recipe` file

**Possible Causes:**
- Some email clients hide attachments by default
- File was stripped by email server (rare)

**Solutions:**
1. Check spam/junk folder
2. Ask recipient to "Show all attachments"
3. Try sending again
4. Use AirDrop as an alternative (see below)

---

## Alternative Sharing Methods

### Using AirDrop

For quick sharing between nearby Apple devices:

1. Share a recipe via email (to generate the file)
2. Save the `.recipe` attachment to Files
3. Use AirDrop to send the file directly
4. Recipient opens the file in the app

**Benefits:**
- Instant transfer
- No email needed
- Works offline
- Larger file sizes supported

### Using Files App

1. Email yourself the recipe
2. Save the `.recipe` attachment to Files app
3. Share the file from Files using any method:
   - AirDrop
   - Messages
   - Third-party cloud storage
   - Slack, Teams, etc.

---

## Example Use Cases

### Family Recipe Collection
Share grandmother's recipes with all family members:
- Email to family group
- Everyone can import and keep their own copy
- Preserve family cooking traditions

### Meal Planning with Friends
Coordinate weekly meal plans:
- Share recipes you're making
- Friends can try your recipes
- Build a shared collection

### Recipe Backup
Email recipes to yourself:
- Keep backups in email
- Access from any device
- Save to cloud storage via email

### Teaching & Classes
Share recipes with students:
- Email class recipes
- Students import into their apps
- Everyone has the same version

---

## What Recipients Need

For recipients to **view** the recipe:
- ✅ Any email client (Gmail, Outlook, Apple Mail, etc.)
- ✅ The recipe displays beautifully in the email body

For recipients to **import** the recipe:
- ✅ NowThatIKnowMore app installed
- ✅ iOS 17.0 or later
- ✅ See [Recipe Import Guide](recipe-import.md) for instructions

---

## Privacy Considerations

### What Gets Shared
- ✅ Recipe title, description, and instructions
- ✅ Ingredients and cooking information
- ✅ Photos you added
- ✅ Credit/source information
- ✅ Metadata (servings, time, etc.)

### What Doesn't Get Shared
- ❌ Your personal notes (if added in future versions)
- ❌ Your cooking history or statistics
- ❌ Other recipes in your collection
- ❌ Your email address (beyond normal email behavior)
- ❌ Device or app usage data

---

## File Format Details

### About `.recipe` Files

- **Format**: JSON with custom extension
- **Size**: Typically 10-100 KB
- **Compatibility**: Works across iOS and iPadOS
- **Backup-friendly**: Can be saved anywhere
- **Human-readable**: Can open in text editor

### File Contents

The `.recipe` file contains:
```json
{
  "uuid": "unique-identifier",
  "title": "Recipe Name",
  "summary": "Description",
  "servings": 4,
  "readyInMinutes": 30,
  "extendedIngredients": [...],
  "analyzedInstructions": [...],
  "userPhotoURLs": [...],
  ...
}
```

---

## Getting Help

### For Senders
- Can't send email? Check troubleshooting above
- Email looks wrong? Verify recipe data is complete
- Button disabled? Configure Mail app in Settings

### For Recipients  
- Can't import recipe? See [Recipe Import Guide](recipe-import.md)
- Don't have the app? Download NowThatIKnowMore
- File not opening? Check file extension is `.recipe`

---

## Summary

✅ **Sharing is easy:**
1. Open recipe
2. Tap "Email Recipe"
3. Send!

✅ **Recipients get:**
- Beautiful email with full recipe
- Importable `.recipe` file
- Photos included

✅ **Privacy-focused:**
- Direct email sharing
- No cloud services
- You control everything

---

**Start sharing your favorite recipes today!** 🍳👨‍🍳👩‍🍳

---

**Next Steps:**
- Learn how to [import recipes](recipe-import.md)
- Read about [setup and configuration](../setup/recipe-import-setup.md)
- Explore the [technical implementation](../architecture/recipe-import-implementation.md)
