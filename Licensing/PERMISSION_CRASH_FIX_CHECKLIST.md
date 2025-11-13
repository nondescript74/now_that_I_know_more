# Permission Crash Fix Checklist

## Issue
Runtime crash when clicking "Grant Access" for photo library permission.

## Root Causes

### 1. Missing Info.plist Entries (Most Common) ⚠️

**Why it crashes:** iOS requires you to declare why you need photo access BEFORE requesting it. Without the Info.plist entry, the app crashes immediately when you call `PHPhotoLibrary.requestAuthorization()`.

**Fix:** Add these entries to your `Info.plist` file:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>NowThatIKnowMore needs access to your photo library to import recipe photos and add images to your recipes.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>NowThatIKnowMore needs permission to save recipe photos to your photo library.</string>
```

**How to add in Xcode:**
1. Open your project in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Click the "+" button to add new entries
5. Search for "Privacy - Photo Library Usage Description"
6. Add the description text
7. Repeat for "Privacy - Photo Library Additions Usage Description"

### 2. Main Actor Issues

**Already Fixed:** The updated `LicenseAcceptanceViewModel.swift` now properly handles main actor with:

```swift
@MainActor
func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    
    await MainActor.run {
        self.photoLibraryStatus = status
    }
    
    return status
}
```

### 3. Observable vs ObservableObject

**Already Fixed:** The view model is now using `@Observable` instead of `ObservableObject`, which is the modern approach.

## Step-by-Step Fix

### Step 1: Verify Info.plist ✅

1. Open `Info.plist` (or go to Target > Info tab)
2. Check if these keys exist:
   - `NSPhotoLibraryUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`
3. If missing, add them with meaningful descriptions

**Alternative locations:**
- Right-click `Info.plist` in Project Navigator → Open As → Source Code
- Look for the XML keys above
- If not found, add them between `<dict>` tags

### Step 2: Clean Build ✅

1. In Xcode: Product → Clean Build Folder (⇧⌘K)
2. Delete app from simulator: Long press app icon → Remove App
3. Quit simulator completely
4. Rebuild and run

### Step 3: Test Permission Flow ✅

1. Launch app in simulator
2. License screen should appear
3. Scroll to bottom
4. Permission section appears
5. Click "Grant Access"
6. System permission dialog should appear (not crash)
7. Allow or deny permission
8. Status should update in UI

## Verification Commands

### Check Info.plist from Terminal
```bash
# Navigate to your project directory
cd /path/to/NowThatIKnowMore

# Check if Info.plist has photo descriptions
/usr/libexec/PlistBuddy -c "Print :NSPhotoLibraryUsageDescription" Info.plist
/usr/libexec/PlistBuddy -c "Print :NSPhotoLibraryAddUsageDescription" Info.plist
```

### Reset Simulator Permissions
```bash
# Reset all simulator content and settings
xcrun simctl erase all

# Or reset specific simulator
xcrun simctl erase <simulator-device-id>
```

## Common Error Messages

### Error: "This app has crashed because it attempted to access privacy-sensitive data..."

**Cause:** Missing `NSPhotoLibraryUsageDescription` in Info.plist

**Solution:** Add the Info.plist key as shown above

### Error: "Publishing changes from background threads is not allowed"

**Cause:** Updating `@Published` or `@Observable` properties from non-main thread

**Solution:** Already fixed with `@MainActor` annotation

### Error: "Cannot find 'PHPhotoLibrary' in scope"

**Cause:** Missing `import Photos`

**Solution:** Already added to `LicenseAcceptanceViewModel.swift`

## Testing Checklist

- [ ] Info.plist has `NSPhotoLibraryUsageDescription`
- [ ] Info.plist has `NSPhotoLibraryAddUsageDescription`
- [ ] Clean build performed
- [ ] App deleted from simulator
- [ ] Simulator restarted
- [ ] App launches without crash
- [ ] License screen appears
- [ ] Can scroll to bottom
- [ ] Permission section appears
- [ ] "Grant Access" button visible
- [ ] Clicking button shows system dialog (no crash)
- [ ] Can grant or deny permission
- [ ] Status updates correctly in UI
- [ ] Settings view shows correct permission status

## Expected Behavior

### First Launch (No Permissions)
1. License screen with scrollable license text
2. After scrolling: Permission section with "Grant Access" button
3. Clicking button: iOS system permission dialog
4. Granting: Button disappears, shows "Status: Authorized" (green)
5. Denying: Shows "Status: Denied" (red) with "Open Settings" link

### Subsequent Launches (Permissions Granted)
1. If version unchanged: No license screen (goes straight to app)
2. If version changed: License screen with current permission status
3. No "Grant Access" button (already authorized)
4. Shows "Status: Authorized" (green)

## Debug Logging

Add this to help debug permission issues:

```swift
// In LicenseAcceptanceViewModel.init()
print("📸 Photo Library Status: \(photoLibraryStatus.rawValue)")
print("📧 Mail Available: \(isMailAvailable)")
print("🔄 Needs Permission Check: \(needsPermissionCheck)")
print("📱 Current App Version: \(currentAppVersion)")
```

## Info.plist Template

Here's a complete template for all permissions your app might need:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... other Info.plist entries ... -->
    
    <!-- Photo Library -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>NowThatIKnowMore needs access to your photo library to import recipe photos and add images to your recipes.</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>NowThatIKnowMore needs permission to save recipe photos to your photo library.</string>
    
    <!-- Camera (for future use) -->
    <key>NSCameraUsageDescription</key>
    <string>NowThatIKnowMore needs access to your camera to take photos of recipes.</string>
    
    <!-- Reminders (already used in app) -->
    <key>NSRemindersUsageDescription</key>
    <string>NowThatIKnowMore needs access to Reminders to add recipe ingredients to your shopping list.</string>
    
    <!-- Contacts (for sharing) -->
    <key>NSContactsUsageDescription</key>
    <string>NowThatIKnowMore needs access to your contacts to share recipes with friends and family.</string>
    
</dict>
</plist>
```

## Still Crashing?

If the app still crashes after adding Info.plist entries:

1. **Check Console Output**
   - In Xcode: View → Debug Area → Activate Console (⇧⌘C)
   - Look for the exact error message

2. **Check Crash Log**
   - Xcode → Window → Devices and Simulators
   - Select your simulator
   - View Device Logs
   - Find most recent crash log

3. **Verify Info.plist Changes Were Applied**
   - Delete app from simulator
   - Clean build folder
   - Rebuild
   - Check app bundle contents

4. **Check for Typos**
   - Ensure Info.plist keys are EXACTLY as shown (case-sensitive)
   - No extra spaces in keys
   - Proper XML formatting

## Additional Resources

- [Apple: Requesting Authorization to Access Photos](https://developer.apple.com/documentation/photokit/phphotolibrary/1620736-requestauthorization)
- [Apple: Protecting the User's Privacy](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [Apple: Info.plist Key Reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html)

## Success Indicators ✅

You've successfully fixed the crash when:

1. ✅ App launches without crashing
2. ✅ "Grant Access" button can be clicked
3. ✅ iOS permission dialog appears
4. ✅ Permission status updates in UI
5. ✅ Settings view shows correct status
6. ✅ Photo picker works in other parts of app
7. ✅ No console errors about privacy

---

**Last Updated**: November 13, 2025
**Issue**: Permission request crash
**Status**: Documented
