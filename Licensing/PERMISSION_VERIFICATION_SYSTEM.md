# Permission Verification System

## Overview

The NowThatIKnowMore app now includes an automatic permission verification system that checks and requests necessary permissions whenever a new version is installed. This ensures users always have the correct permissions set up for the app to function properly.

## Features

### Version-Based Permission Checks

The app automatically detects when a new version is installed and prompts users to verify their permissions. This happens:

- **On first launch** - New users are guided through the complete setup
- **On version updates** - Existing users are reminded to verify permissions
- **When license changes** - If the license version is updated

### Tracked Permissions

#### 1. Photo Library Access
- **Purpose**: Import recipe photos from the user's photo library
- **Framework**: Photos framework (`PHPhotoLibrary`)
- **Authorization Levels**:
  - `.notDetermined` - Permission not yet requested (shows "Grant Access" button)
  - `.authorized` - Full access granted
  - `.limited` - Limited photo selection access
  - `.denied` - User denied access (shows "Open Settings" link)
  - `.restricted` - Access restricted by parental controls/MDM

#### 2. Mail Availability
- **Purpose**: Share recipes via email
- **Framework**: MessageUI framework (`MFMailComposeViewController`)
- **Status Check**: Uses `MFMailComposeViewController.canSendMail()`
- **Note**: This checks if Mail is configured, not a traditional permission

## Implementation Details

### LicenseAcceptanceViewModel

The core logic is in `LicenseAcceptanceViewModel` which:

1. **Tracks app version** - Compares current version with last verified version
2. **Checks permission status** - Queries current authorization states
3. **Stores verification state** - Persists verification in UserDefaults
4. **Provides UI helpers** - Status descriptions, colors, icons

#### Key Properties

```swift
// Observable properties
var photoLibraryStatus: PHAuthorizationStatus
var isMailAvailable: Bool
var needsPermissionCheck: Bool

// Computed properties
var currentAppVersion: String
var photoStatusDescription: String
var mailStatusDescription: String
```

#### Key Methods

```swift
// Initialize and check current status
init()

// Request photo library permission
func requestPhotoLibraryPermission() async -> PHAuthorizationStatus

// Mark permissions as verified for current version
func markPermissionsVerified()

// Open system settings
func openSettings()
```

### UserDefaults Keys

The system uses three UserDefaults keys:

1. **`acceptedLicenseVersion`** - Stores the accepted license version
2. **`licenseAcceptanceDate`** - Date when license was accepted
3. **`lastPermissionCheckVersion`** - Last app version that verified permissions

### Version Comparison Logic

```swift
let currentVersion = "\(CFBundleShortVersionString) (\(CFBundleVersion))"
let lastCheckedVersion = UserDefaults.standard.string(forKey: "lastPermissionCheckVersion")
needsPermissionCheck = (lastCheckedVersion != currentVersion)
```

## User Experience Flow

### New User (First Launch)

1. **License Screen Appears**
   - User sees welcome message
   - Must scroll to read entire license
   - Permission section appears after scrolling

2. **Permission Review**
   - Photo Library: Shows "Grant Access" button
   - Mail: Shows current configuration status

3. **Accept & Continue**
   - User checks "I agree" checkbox
   - Taps "Accept & Continue"
   - App marks version as verified
   - Proceeds to main app

### Existing User (Version Update)

1. **License Screen Appears** (because version changed)
   - Shows familiar license (already scrolled before)
   - Permission section shows current status

2. **Quick Verification**
   - User can review current permissions
   - Can request photo access if needed
   - Can see mail configuration status

3. **Accept & Continue**
   - Quick acknowledgment
   - App records new version
   - Returns to app

## UI Components

### LicenseAcceptanceView

The main view that presents:
- License text with scroll tracking
- Permission request section (when needed)
- Agreement checkbox
- Accept/Decline buttons

#### Permission Section
Only shown when:
- User has scrolled to bottom AND
- Version needs permission check

### SettingsView

Shows comprehensive permission status:
- Current authorization states
- Colored status indicators (green/orange/red)
- Action buttons ("Grant Permission", "Open Settings", "Configure Mail")
- App version information

## Permission Status Indicators

### Photo Library

| Status | Color | Icon | Description |
|--------|-------|------|-------------|
| Authorized | 🟢 Green | `photo.fill` | Full access granted |
| Limited | 🟢 Green | `photo.fill` | Limited photo selection |
| Not Determined | 🟠 Orange | `photo` | Not yet requested |
| Denied | 🔴 Red | `photo.fill.on.rectangle.fill` | Access denied |
| Restricted | 🔴 Red | `photo.fill.on.rectangle.fill` | Restricted by system |

### Mail

| Status | Color | Icon | Description |
|--------|-------|------|-------------|
| Available | 🟢 Green | `envelope.fill` | Mail configured and ready |
| Not Configured | 🟠 Orange | `envelope.badge.fill` | No mail account set up |

## Developer Notes

### Testing Permission Flows

To test the permission verification system:

```swift
// In development, you can reset all permissions:
let viewModel = LicenseAcceptanceViewModel()
viewModel.resetAcceptance()

// This clears:
// - Accepted license version
// - License acceptance date
// - Last permission check version
```

### Changing App Version

When you increment the app version in Xcode:
1. Update `CFBundleShortVersionString` (e.g., "1.0" → "1.1")
2. Update `CFBundleVersion` (e.g., "1" → "2")
3. Next launch will trigger permission verification

### Adding New Permissions

To add a new permission to track:

1. **Update ViewModel**
```swift
// Add property
var newPermissionStatus: SomeAuthorizationStatus = .notDetermined

// Add status check in init()
private func checkPermissionsStatus() {
    // ... existing checks
    newPermissionStatus = SomeFramework.authorizationStatus()
}

// Add request method
func requestNewPermission() async -> SomeAuthorizationStatus {
    let status = await SomeFramework.requestAuthorization()
    newPermissionStatus = status
    return status
}
```

2. **Update UI**
- Add permission row to `LicenseAcceptanceView.permissionsSection`
- Add permission row to `SettingsView.permissionsSection`

3. **Update Documentation**
- Add to this file's "Tracked Permissions" section

## Info.plist Requirements

Ensure your Info.plist includes usage descriptions:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>NowThatIKnowMore needs access to your photo library to import recipe photos and add images to your recipes.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>NowThatIKnowMore needs permission to save recipe photos to your photo library.</string>
```

Note: Mail doesn't require Info.plist entries as it uses the system Mail composer.

## Best Practices

### For Users
1. **Review permissions** when prompted after updates
2. **Grant photo access** to use OCR import features
3. **Configure Mail** to share recipes via email
4. **Check Settings** anytime to review permission status

### For Developers
1. **Increment version** properly in Xcode for each release
2. **Test permission flows** with reset functionality
3. **Update license version** only when terms actually change
4. **Document new permissions** when adding features
5. **Use async/await** for permission requests to avoid blocking UI

## Privacy Commitment

This system aligns with NowThatIKnowMore's privacy principles:

✅ **Transparent** - Clear explanation of why permissions are needed
✅ **User Control** - Easy access to permission settings
✅ **Minimal** - Only requests necessary permissions
✅ **No Hidden Tracking** - All permissions have clear purposes
✅ **Local Storage** - Permission state stored only on device

## Troubleshooting

### Issue: License keeps appearing on every launch

**Solution**: Check that `acceptLicense()` is being called after user accepts. Verify UserDefaults is not being cleared accidentally.

### Issue: Photo permission request doesn't appear

**Solution**: 
1. Check that `needsPermissionCheck` is true
2. Verify user has scrolled to bottom (`hasScrolledToBottom`)
3. Check system Privacy settings for the app

### Issue: Mail shows as unavailable

**Solution**: 
1. Go to Settings > Mail
2. Add an email account
3. Verify account is active
4. Restart the app

### Issue: Permission status not updating

**Solution**: The view model checks status on initialization. If permissions change while the view is open, they may not update immediately. Consider adding an `.onAppear` refresh in views.

## Future Enhancements

Potential additions to consider:

- [ ] Notifications permission (for recipe timers)
- [ ] Calendar permission (for meal planning)
- [ ] Contacts permission (for recipe sharing)
- [ ] Camera permission (for direct photo capture)
- [ ] Reminders permission (already implemented for ingredients)

Each new permission should follow the same pattern established here.

## References

- [Apple Developer: Requesting Authorization to Access Photos](https://developer.apple.com/documentation/photokit/requesting_authorization_to_access_photos)
- [Apple Developer: MessageUI Framework](https://developer.apple.com/documentation/messageui)
- [Swift Observation Framework](https://developer.apple.com/documentation/observation)
- [UserDefaults Best Practices](https://developer.apple.com/documentation/foundation/userdefaults)

---

**Last Updated**: November 13, 2025
**Version**: 1.0
**Author**: Development Team
