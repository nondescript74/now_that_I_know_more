# Launch Screen Image Size Guide

## How to Make Your Launch Screen Image Bigger

There are several approaches depending on how your launch screen is configured.

---

## Method 1: Using Storyboard (Most Common)

If you're using `LaunchScreen.storyboard`:

### Steps:

1. **Open LaunchScreen.storyboard** in Xcode
2. **Select the UIImageView** that contains your launch image
3. **Open the Attributes Inspector** (⌥⌘4)
4. **Check Content Mode** - ensure it's set to "Aspect Fit" or "Aspect Fill"

### Adjust Constraints:

5. **Open Size Inspector** (⌥⌘5)
6. **Find the constraints** on your image view
7. **Modify constraint constants** to make the image bigger:

```
Current (example)          →  New (bigger image)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Top: 100                   →  40
Bottom: 100                →  40
Leading: 80                →  30
Trailing: 80               →  30
```

**Or use percentage-based constraints:**
- Width: Equal to Superview Width × 0.9
- Height: Equal to Superview Height × 0.7
- Center X: Center in Superview
- Center Y: Center in Superview

### Visual Guide:

```
┌──────────────────────────┐
│                          │
│  ┌──────────────────┐   │  ← Small padding (20-40pts)
│  │                  │   │
│  │   Launch Image   │   │  ← Image takes up ~80-90% of screen
│  │                  │   │
│  └──────────────────┘   │
│                          │
└──────────────────────────┘
```

---

## Method 2: Using SwiftUI Launch Screen (iOS 14+)

If your app uses `Info.plist` with `UILaunchScreen` configuration:

### Option A: Update Info.plist

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchImage</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <false/>  <!-- Set to false for larger image -->
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
</dict>
```

### Option B: Use SwiftUI View (iOS 17+)

I've created `LaunchScreenView.swift` with three size options:

1. **LaunchScreenView** - Controlled with padding
   ```swift
   .padding(40)  // Current
   .padding(20)  // ← Change to this for bigger image
   ```

2. **LaunchScreenViewLarge** - Percentage-based sizing
   ```swift
   .frame(width: UIScreen.main.bounds.width * 0.8)  // 80% width
   .frame(height: UIScreen.main.bounds.height * 0.6) // 60% height
   ```

3. **LaunchScreenViewFullscreen** - Maximum size
   ```swift
   .padding(.horizontal, 20)  // Minimal padding
   .padding(.vertical, 60)
   ```

---

## Method 3: Using Asset Catalog

If using launch images in `Assets.xcassets`:

### Steps:

1. **Open Assets.xcassets**
2. **Find "LaunchImage" asset**
3. **Replace images** with larger versions
4. **Ensure proper dimensions**:
   - iPhone: 1170 × 2532 (or device-specific sizes)
   - iPad: 2048 × 2732

### Image Preparation:

```
Recommended approach:
━━━━━━━━━━━━━━━━━━━━
1. Create image at device resolution
2. Add transparent padding around the actual content
3. Less padding = bigger visible image

Example for iPhone:
┌────────────────┐
│  [transparent] │ ← 50px top padding
│   ┌────────┐   │
│   │ Image  │   │ ← Your actual image content
│   │        │   │
│   └────────┘   │
│  [transparent] │ ← 50px bottom padding
└────────────────┘
```

---

## Quick Fixes by Scenario

### Scenario 1: Image is too small with white space

**Fix:**
- Reduce padding/margins in constraints
- Change from 100pts to 40pts spacing

### Scenario 2: Image doesn't fill the screen

**Fix:**
```swift
// In SwiftUI:
.frame(maxWidth: .infinity, maxHeight: .infinity)
.padding(20) // Minimal padding

// In Storyboard:
// Set constraints to 20pts from edges
```

### Scenario 3: Image is clipped/cut off

**Fix:**
- Change Content Mode to "Aspect Fit"
- Ensure aspect ratio constraint is set correctly

---

## Recommended Sizes

### For Different Devices:

```
Device                 Image Size Recommendation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
iPhone (portrait)      70-80% of screen width
                       50-60% of screen height

iPad                   60-70% of screen width
                       40-50% of screen height
```

### Padding Values:

```
Effect Desired         Padding Value
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Very Large             20-30 pts
Large (Recommended)    40-50 pts
Medium                 60-80 pts
Small                  100+ pts
```

---

## Implementation Steps

### If Using Storyboard:

1. Open `LaunchScreen.storyboard`
2. Select the Image View
3. Open Size Inspector (⌥⌘5)
4. Edit constraints:
   ```
   Top Space to Safe Area: 40
   Leading Space to Safe Area: 30
   Trailing Space to Safe Area: 30
   Bottom Space to Safe Area: 40
   ```
5. Build and run to test

### If Using SwiftUI:

1. Use the provided `LaunchScreenView.swift`
2. Choose your preferred size variant:
   ```swift
   // Smaller padding = bigger image
   .padding(20)  // Very large
   .padding(40)  // Large
   .padding(60)  // Medium
   ```
3. Configure in `Info.plist` or as launch screen
4. Build and run to test

---

## Testing Your Changes

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Delete App**: Remove app from simulator/device
3. **Build and Run**: ⌘R
4. **Check Launch Screen**: Watch the launch screen on startup

**Note**: Launch screen changes can be cached. Always clean and reinstall.

---

## Common Issues

### Issue: Changes don't appear

**Solution:**
1. Clean build folder
2. Delete app from device/simulator
3. Restart Xcode
4. Build again

### Issue: Image is distorted

**Solution:**
- Use "Aspect Fit" content mode
- Check aspect ratio constraint
- Ensure image dimensions are correct

### Issue: Image varies by device

**Solution:**
- Use constraint-based layout (not fixed sizes)
- Use percentage-based sizing
- Test on multiple device sizes

---

## Example Constraint Calculations

### For 80% Screen Coverage:

```
Screen Width: 390pts (iPhone 14)
Desired: 80% width = 312pts image width

Padding needed:
Total horizontal space: 390pts
Image width: 312pts
Remaining space: 78pts
Left padding: 39pts
Right padding: 39pts

Set constraints:
Leading: 39pts
Trailing: 39pts
```

### For Maximum Size (Safe Areas):

```
Constraints:
Top: 20pts (minimal)
Leading: 20pts (minimal)
Trailing: 20pts (minimal)
Bottom: 20pts (minimal)

Result: Image fills almost entire screen
```

---

## Visual Examples

### Current (Small):
```
┌────────────────────┐
│                    │
│                    │
│    ┌────────┐     │ ← Small image
│    │  img   │     │
│    └────────┘     │
│                    │
│                    │
└────────────────────┘
```

### Desired (Large):
```
┌────────────────────┐
│ ┌────────────────┐ │
│ │                │ │
│ │     Image      │ │ ← Larger image
│ │                │ │
│ │                │ │
│ └────────────────┘ │
└────────────────────┘
```

---

## Quick Reference

**To make image bigger:**
- ✅ Reduce constraint constants
- ✅ Reduce padding values
- ✅ Increase percentage multipliers
- ✅ Use maxWidth/maxHeight in SwiftUI

**Common values:**
- Very large: 20-30 pts padding
- Large: 40 pts padding
- Medium: 60 pts padding

---

**Need Help?**

If you're still having trouble, you can:
1. Share a screenshot of your current launch screen
2. Check if you're using Storyboard or SwiftUI
3. Look at the Size Inspector constraints
4. Try the provided SwiftUI implementation

---

**Last Updated**: November 7, 2025
