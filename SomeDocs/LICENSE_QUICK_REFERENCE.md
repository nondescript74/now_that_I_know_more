# License System Quick Reference

## 📦 Files Created

### Must Add to Xcode:
1. ✅ `license.md` - The legal license text (MUST add to app target!)
2. ✅ `LicenseAcceptanceViewModel.swift` - Business logic
3. ✅ `LicenseAcceptanceView.swift` - License presentation UI
4. ✅ `LicenseGateView.swift` - Wrapper that checks acceptance
5. ✅ `SettingsView.swift` - Settings screen with license review

### Already Updated:
6. ✅ `NowThatIKnowMoreApp.swift` - Wrapped in LicenseGateView

## ⚡ Quick Start

### Step 1: Add license.md to Xcode
1. Open Xcode
2. Drag `license.md` into your project
3. ✅ Check "Copy items if needed"
4. ✅ Check "NowThatIKnowMore" target
5. Click Add

### Step 2: Verify Integration
The code is already integrated! Just build and run:
```bash
⌘ + R (Build and Run)
```

### Step 3: Test First Launch
- App should show license screen
- Scroll to bottom
- Check "I agree"
- Tap "Accept & Continue"
- App should transition to main tabs

### Step 4: Test Settings
- Tap gear icon (⚙️) in toolbar
- Should see Settings with license info
- Tap "View Full License"
- Should show full license text

## 🔧 Development Testing

### Reset License Acceptance
```swift
// In Xcode debug console or in a test
let viewModel = LicenseAcceptanceViewModel()
viewModel.resetAcceptance()
print("License acceptance reset - will show on next launch")
```

### Check Acceptance Status
```swift
let viewModel = LicenseAcceptanceViewModel()
print("Needs acceptance: \(viewModel.needsLicenseAcceptance)")
print("Accepted version: \(viewModel.getAcceptedVersion() ?? "none")")
print("Acceptance date: \(viewModel.formattedAcceptanceDate ?? "none")")
```

### Manually Check UserDefaults
In Xcode Debug Console:
```swift
po UserDefaults.standard.string(forKey: "acceptedLicenseVersion")
po UserDefaults.standard.object(forKey: "licenseAcceptanceDate")
```

## 🎯 User Flow

### First Launch:
```
Launch → License Screen → Scroll → Check Box → Accept → Main App
```

### Subsequent Launches:
```
Launch → Main App (license skipped)
```

### Reviewing License:
```
Main App → Settings (⚙️) → View Full License
```

## 🔑 Key Features

### License Acceptance Requirements:
- ✅ Must scroll to 95% of license
- ✅ Must check "I agree" checkbox
- ✅ Both required to enable Accept button

### What Gets Stored:
```
UserDefaults Keys:
- "acceptedLicenseVersion" = "1.0"
- "licenseAcceptanceDate" = Date()
```

### Privacy Guarantees:
- ❌ No data collection
- ❌ No analytics
- ❌ No ads
- ❌ No tracking
- ✅ Local storage only
- ✅ API key stored locally

## 📝 Customization

### Change License Version
In `LicenseAcceptanceViewModel.swift`:
```swift
private let currentLicenseVersion = "2.0"  // Change this
```
Users who accepted v1.0 will see license again.

### Update License Text
1. Edit `license.md`
2. Change version in `LicenseAcceptanceViewModel`
3. Users will see updated license on next launch

### Adjust Scroll Threshold
In `LicenseAcceptanceViewModel.swift`:
```swift
private let scrollThreshold: CGFloat = 0.90  // 90% instead of 95%
```

## 🐛 Troubleshooting

### License Text Shows "Error loading..."
**Cause:** `license.md` not in bundle  
**Fix:** Add `license.md` to Xcode target

### License Shows Every Time
**Cause:** UserDefaults not saving  
**Fix:** Check target has proper entitlements

### Checkbox Won't Enable
**Cause:** Not scrolling far enough  
**Fix:** Scroll ALL the way to bottom

### Settings Gear Missing
**Cause:** Toolbar not showing  
**Fix:** Verify NavigationView wraps TabView

## 📱 Tab Structure (After Integration)

```
Tab 0: Meal Plan        (🍴)
Tab 1: From Image       (📷)
Tab 2: OCR Import       (📸) ← NEW! Recipe image parser
Tab 3: API Key          (🔑)
Tab 4: Edit Recipe      (✏️)
Tab 5: Dict to Recipe   (🔍)
Tab 6: Clear Recipes    (🗑️)

Toolbar: Settings       (⚙️) ← NEW!
```

## ✅ Verification Checklist

Before releasing:
- [ ] `license.md` added to Xcode project
- [ ] License shows on first launch
- [ ] Can scroll and read entire license
- [ ] Progress bar updates correctly
- [ ] Checkbox enables at bottom
- [ ] Accept button works
- [ ] Decline shows alert
- [ ] Settings shows acceptance date
- [ ] "View Full License" works in settings
- [ ] OCR Import tab visible
- [ ] Settings gear icon visible

## 🚀 Ready to Ship!

Once you verify all the above, your app has:
- ✅ Legal license compliance (CC BY 4.0)
- ✅ User consent tracking
- ✅ Privacy guarantees documented
- ✅ Food safety disclaimers
- ✅ Settings for license review
- ✅ OCR import integrated

## 📚 Full Documentation

See `LICENSE_SYSTEM_IMPLEMENTATION.md` for complete details.

---

**Questions?** Check the troubleshooting section or review the implementation guide.

Happy cooking! 🍳👨‍🍳👩‍🍳
