# License System Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    NowThatIKnowMoreApp                      │
│                         @main                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │     LicenseGateView         │
        │   (Conditional Wrapper)     │
        └─────┬───────────────────┬───┘
              │                   │
    ┌─────────▼────────┐    ┌────▼─────────────┐
    │ License Needed?  │    │  Already Accepted│
    │      YES         │    │       NO         │
    └─────────┬────────┘    └────┬─────────────┘
              │                  │
              ▼                  │
┌──────────────────────────┐    │
│ LicenseAcceptanceView    │    │
│  - Header                │    │
│  - License Text          │    │
│  - Progress Bar          │    │
│  - Scroll Indicator      │    │
│  - Checkbox              │    │
│  - Accept/Decline        │    │
└──────────────────────────┘    │
              │                  │
     User Accepts                │
              │                  │
              ▼                  │
    ┌─────────────────┐          │
    │ Store in        │          │
    │ UserDefaults    │          │
    │  - Version      │          │
    │  - Date         │          │
    └─────────┬───────┘          │
              │                  │
              └──────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │       MainTabView           │
        │    (Main Application)       │
        └─────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   ┌────────┐   ┌─────────┐   ┌────────┐
   │ Meal   │   │   OCR   │   │  API   │
   │ Plan   │   │ Import  │   │  Key   │
   └────────┘   └─────────┘   └────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
                 ⚙️ Toolbar
                      │
                      ▼
              ┌───────────────┐
              │ SettingsView  │
              │ - About       │
              │ - Copyright   │
              │ - License     │
              │ - Privacy     │
              │ - Credits     │
              └───────────────┘
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    User Actions                         │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌─────────┐    ┌──────────┐    ┌──────────┐
    │ Scroll  │    │  Check   │    │  Tap     │
    │ License │    │   Box    │    │ Accept   │
    └────┬────┘    └─────┬────┘    └────┬─────┘
         │               │              │
         ▼               ▼              ▼
┌─────────────────────────────────────────────────────────┐
│          LicenseAcceptanceViewModel                     │
│                                                         │
│  @Published var hasScrolledToBottom: Bool              │
│  @Published var hasAgreed: Bool                        │
│  @Published var scrollProgress: CGFloat                │
│                                                         │
│  computed var canAccept: Bool {                        │
│    hasScrolledToBottom && hasAgreed                    │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   func acceptLicense()│
              └───────────┬───────────┘
                          │
                          ▼
          ┌──────────────────────────────┐
          │       UserDefaults           │
          │                              │
          │  "acceptedLicenseVersion"    │
          │         = "1.0"              │
          │                              │
          │  "licenseAcceptanceDate"     │
          │    = Date()                  │
          └──────────────────────────────┘
```

---

## State Machine

```
                    ┌─────────────┐
                    │ App Launch  │
                    └──────┬──────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Check UserDefaults     │
              │ for accepted version   │
              └────────┬───────────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
    [Not Found]                  [Found]
         │                           │
         ▼                           ▼
┌─────────────────┐         ┌────────────────┐
│ State: REQUIRES │         │ State: ACCEPTED│
│     LICENSE     │         │                │
└────────┬────────┘         └────────┬───────┘
         │                           │
         ▼                           │
┌─────────────────┐                 │
│ Show License    │                 │
│ Acceptance View │                 │
└────────┬────────┘                 │
         │                           │
    User Actions                     │
         │                           │
    ┌────┴────┐                     │
    │         │                      │
 Decline   Accept                    │
    │         │                      │
    ▼         ▼                      │
  Exit   Store Data                  │
  App       │                        │
            │                        │
            └────────────────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │ State: SHOW MAIN │
            │       APP        │
            └──────────────────┘
```

---

## Scroll Detection Flow

```
┌────────────────────────────────────────────┐
│          User Scrolls License              │
└────────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │  GeometryReader captures   │
    │  scroll offset via         │
    │  PreferenceKey             │
    └────────────┬───────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │  Calculate progress:       │
    │  progress = -offset /      │
    │    (height * 2)            │
    │  clamped [0.0, 1.0]        │
    └────────────┬───────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │  viewModel.updateScroll    │
    │  Progress(progress)        │
    └────────────┬───────────────┘
                 │
                 ▼
         ┌───────────────┐
         │ progress < 95%│
         └───────┬───────┘
                 │
      ┌──────────┴──────────┐
      │                     │
   [< 95%]              [≥ 95%]
      │                     │
      ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│ Show:        │    │ Set:             │
│ - Progress   │    │ hasScrolledTo    │
│   Bar        │    │ Bottom = true    │
│ - Scroll     │    │                  │
│   Indicator  │    │ Hide:            │
│              │    │ - Progress Bar   │
│ Keep:        │    │ - Scroll Indicator│
│ Checkbox     │    │                  │
│ DISABLED     │    │ Enable:          │
│              │    │ - Checkbox       │
└──────────────┘    └──────────────────┘
```

---

## UI Component Hierarchy

```
LicenseAcceptanceView
│
├── NavigationView
│   └── VStack (main container)
│       │
│       ├── Header Section
│       │   └── VStack
│       │       ├── Image (fork.knife.circle.fill)
│       │       ├── Text ("Welcome to...")
│       │       └── Text (subtitle)
│       │
│       ├── Divider
│       │
│       ├── License Scroll View
│       │   └── GeometryReader
│       │       └── ScrollView (with coordinateSpace)
│       │           └── VStack
│       │               └── Text (license.md content)
│       │                   └── GeometryReader (for offset)
│       │       
│       │       Overlays:
│       │       ├── Progress Bar (top, conditional)
│       │       └── Scroll Indicator (bottom, conditional)
│       │
│       ├── Divider
│       │
│       ├── Agreement Section
│       │   └── VStack
│       │       └── Button (checkbox)
│       │           └── HStack
│       │               ├── Image (checkmark)
│       │               └── VStack
│       │                   ├── Text ("I agree...")
│       │                   └── Text (warning, conditional)
│       │
│       └── Action Buttons
│           └── HStack
│               ├── Button ("Decline")
│               └── Button ("Accept & Continue")
│
└── .alert (Decline confirmation)
```

---

## Settings View Structure

```
SettingsView
│
└── NavigationView
    └── List
        │
        ├── Section: "About"
        │   ├── App Icon + Name + Version
        │   └── Description
        │
        ├── Section: "Copyright"
        │   └── Copyright text + License type
        │
        ├── Section: "License"
        │   ├── Button → "View Full License"
        │   ├── License Type (CC BY 4.0)
        │   └── Acceptance Date (if available)
        │
        ├── Section: "Privacy"
        │   ├── Row: No Data Collection
        │   ├── Row: Local Storage Only
        │   ├── Row: No Analytics
        │   ├── Row: No Advertisements
        │   └── Row: Offline Functionality
        │
        ├── Section: "Credits"
        │   ├── Row: Apple Frameworks
        │   ├── Row: Spoonacular API
        │   ├── Row: Open Source Community
        │   └── Row: Beta Testers
        │
        └── Section: "Support"
            ├── Row: Educational Purpose
            └── Row: Food Safety Notice
        
        .sheet(showFullLicense)
        └── Full License Text View
            └── ScrollView
                └── Text (license.md)
```

---

## User Acceptance Timeline

```
Time: 0s
┌────────────────────────┐
│  App Launches          │
│  License Gate checks   │
└───────────┬────────────┘
            │
Time: 0.1s  ▼
┌────────────────────────┐
│ License Screen Shows   │
│ Progress: 0%           │
│ Scroll Indicator: ✓    │
│ Checkbox: DISABLED     │
└───────────┬────────────┘
            │
Time: 10s   ▼
┌────────────────────────┐
│ User scrolling...      │
│ Progress: 45%          │
│ Scroll Indicator: ✓    │
│ Checkbox: DISABLED     │
└───────────┬────────────┘
            │
Time: 25s   ▼
┌────────────────────────┐
│ User reaches bottom    │
│ Progress: 96%          │
│ Scroll Indicator: ✗    │
│ Checkbox: ENABLED ✓    │
└───────────┬────────────┘
            │
Time: 27s   ▼
┌────────────────────────┐
│ User checks box        │
│ hasAgreed: true        │
│ Accept Button: ENABLED │
└───────────┬────────────┘
            │
Time: 28s   ▼
┌────────────────────────┐
│ User taps Accept       │
│ Store to UserDefaults  │
└───────────┬────────────┘
            │
Time: 28.5s ▼
┌────────────────────────┐
│ Fade transition        │
│ to Main App            │
└───────────┬────────────┘
            │
Time: 29s   ▼
┌────────────────────────┐
│ Main App Visible       │
│ User can now use app   │
└────────────────────────┘
```

---

## Persistence Layer

```
                    UserDefaults.standard
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Key: "acceptedLicenseVersion"                     │
│  Type: String                                       │
│  Value: "1.0"                                       │
│  Purpose: Track which version was accepted         │
│                                                     │
│  ─────────────────────────────────────────────     │
│                                                     │
│  Key: "licenseAcceptanceDate"                      │
│  Type: Date                                         │
│  Value: 2025-11-06 14:30:00 +0000                  │
│  Purpose: Record when license was accepted         │
│                                                     │
└─────────────────────────────────────────────────────┘
                          │
                          │ Read on launch
                          │ Write on accept
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ LicenseAcceptanceViewModel      │
        │                                 │
        │  needsLicenseAcceptance → Bool │
        │  licenseAcceptanceDate → Date?  │
        └─────────────────────────────────┘
```

---

## Version Update Flow

```
Current Version: "1.0" stored in UserDefaults
Developer Updates: currentLicenseVersion = "2.0"

                App Launch
                    │
                    ▼
        ┌───────────────────────┐
        │ Load from UserDefaults│
        │ acceptedVersion="1.0" │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Compare versions:     │
        │ "1.0" != "2.0"        │
        │ needsAcceptance=true  │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Show License Again    │
        │ (even if previously   │
        │  accepted v1.0)       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ User accepts v2.0     │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Store to UserDefaults:│
        │ version = "2.0"       │
        │ date = new Date()     │
        └───────────────────────┘
```

---

## Integration Points

```
NowThatIKnowMoreApp.swift
│
└── body: some Scene
    └── WindowGroup
        └── LicenseGateView ◄───── NEW WRAPPER
            │
            └── ZStack
                ├── MainTabView ◄───── Existing content preserved
                │   │
                │   ├── Tab 0: MealPlan
                │   ├── Tab 1: ImageToListView
                │   ├── Tab 2: RecipeImageParserView ◄───── NEW OCR tab
                │   ├── Tab 3: APIKeyTabView
                │   ├── Tab 4: RecipeEditorView
                │   ├── Tab 5: DictionaryToRecipeView
                │   └── Tab 6: ClearRecipesTabView
                │   
                │   └── .toolbar
                │       └── SettingsButton ◄───── NEW settings button
                │           └── .sheet
                │               └── SettingsView ◄───── NEW settings view
                │
                ├── RecipeImportPreviewView (sheet)
                ├── Alert (import status)
                └── LaunchScreenView (conditional)
```

---

## File Dependencies

```
license.md (Resource)
     │
     │ Loaded by
     ▼
LicenseAcceptanceView.swift
     │
     │ Uses
     ▼
LicenseAcceptanceViewModel.swift
     │
     │ Wrapped by
     ▼
LicenseGateView.swift
     │
     │ Wraps
     ▼
NowThatIKnowMoreApp.swift
     │
     │ Includes
     ▼
MainTabView
     │
     │ Toolbar contains
     ▼
SettingsView.swift
     │
     │ Displays
     ▼
license.md (via sheet)
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────┐
│ Potential Error Scenarios               │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│license.md│  │UserDefaults│  │User     │
│Missing   │  │Fails      │  │Declines │
└─────┬────┘  └─────┬────┘  └─────┬────┘
      │             │             │
      ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│Show error│  │Continue  │  │Show alert│
│message   │  │anyway    │  │"Exit App"│
│in view   │  │(fail-safe)│  │          │
└──────────┘  └──────────┘  └─────┬────┘
                                   │
                            User confirms
                                   │
                                   ▼
                            ┌──────────┐
                            │Exit app  │
                            │exit(0)   │
                            └──────────┘
```

---

## Summary

This license system provides:
- ✅ Clear visual hierarchy
- ✅ Logical state management
- ✅ Graceful error handling
- ✅ Version update support
- ✅ Persistent storage
- ✅ User-friendly flow
- ✅ Settings integration
- ✅ Complete documentation

All components work together to create a professional, legally compliant license acceptance system for your NowThatIKnowMore recipe app.
