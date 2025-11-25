# Recipe Detector Quick Reference Card

## 🚀 Instant Setup (Copy & Paste)

### 1. Basic Test in Your View
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        RecipeDetectorTestApp() // That's it!
    }
}
```

### 2. Quick UIKit Test
```swift
// In your view controller's viewDidLoad():
override func viewDidLoad() {
    super.viewDidLoad()
    quickTest_RecipeDetector() // See console output
}
```

### 3. Analyze Single Image
```swift
let detector = RecipeColumnDetector()
let image = UIImage(named: "AmNC")!

detector.analyzeRecipeCard(image: image) { result in
    switch result {
    case .success(let analysis):
        print("✅ Found \(analysis.ingredientRows.count) rows")
        
        // Get debug image
        if let debugImage = detector.generateDebugVisualization(
            originalImage: image,
            analysis: analysis
        ) {
            myImageView.image = debugImage
        }
        
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}
```

## 📊 Reading Results

### Check Divider Detection
```swift
if let dividerX = analysis.columnLayout.verticalDividerX {
    print("✅ Divider at x=\(dividerX)")
    // Good: 0.30-0.45 for your recipes
} else {
    print("⚠️  No divider - using heuristic")
}
```

### Check Row Count
```swift
let rowCount = analysis.ingredientRows.count
print("📝 Rows: \(rowCount)")
// Expected: 5-15 for typical recipes
```

### Check Column Distribution
```swift
for (i, row) in analysis.ingredientRows.enumerated() {
    let leftCount = row.leftColumnBlocks.count
    let rightCount = row.rightColumnBlocks.count
    print("Row \(i+1): L=\(leftCount), R=\(rightCount)")
}
```

### Extract Text
```swift
for row in analysis.ingredientRows {
    // Left column text
    let leftTexts = row.leftColumnBlocks.compactMap { 
        $0.topCandidates(1).first?.string 
    }
    print("Left: \(leftTexts.joined(separator: " "))")
    
    // Right column text
    let rightTexts = row.rightColumnBlocks.compactMap { 
        $0.topCandidates(1).first?.string 
    }
    print("Right: \(rightTexts.joined(separator: " "))")
}
```

## 🎨 Debug Visualization Options

### Show Everything
```swift
let debugImage = detector.generateDebugVisualization(
    originalImage: image,
    analysis: analysis,
    options: .detailed // Shows all overlays + text content
)
```

### Minimal (Just Rows & Divider)
```swift
let debugImage = detector.generateDebugVisualization(
    originalImage: image,
    analysis: analysis,
    options: .minimal // Clean view
)
```

### Custom
```swift
var options = DebugVisualizationOptions()
options.showVerticalDivider = true
options.showIngredientRows = true
options.showTextBlocks = false
options.showTextContent = false

let debugImage = detector.generateDebugVisualization(
    originalImage: image,
    analysis: analysis,
    options: options
)
```

## 🛠️ Common Adjustments

### Tune Row Grouping
```swift
// In RecipeColumnDetector.swift, line ~520
// Find: let rowHeightThreshold: CGFloat = 0.015

// Too many rows (ingredients split)?
let rowHeightThreshold: CGFloat = 0.020 // More grouping

// Too few rows (ingredients merged)?
let rowHeightThreshold: CGFloat = 0.012 // Less grouping
```

### Force Divider Position
```swift
// In analyzeLayout(), after line ~425
// Override detected divider:
let dividerX = 0.35 // Force specific position
```

### Adjust Line Detection Sensitivity
```swift
// In detectHorizontalLines(), line ~210
// For horizontal lines:
if aspectRatio > 10.0 && box.width > 0.5 {
    // ^ Try: 15.0 (stricter) or 8.0 (looser)
}

// In detectVerticalDivider(), line ~245
// For vertical line:
request.minimumConfidence = 0.2
// ^ Try: 0.1 (more sensitive) or 0.3 (less sensitive)
```

## 📱 Integration Patterns

### SwiftUI: Process on Appear
```swift
struct RecipeProcessingView: View {
    let recipeImage: UIImage
    @State private var analysis: RecipeAnalysis?
    
    var body: some View {
        VStack {
            // Show results
        }
        .onAppear {
            processImage()
        }
    }
    
    private func processImage() {
        RecipeColumnDetector().analyzeRecipeCard(image: recipeImage) { result in
            if case .success(let analysis) = result {
                self.analysis = analysis
            }
        }
    }
}
```

### UIKit: Process on Load
```swift
class RecipeProcessingVC: UIViewController {
    private let detector = RecipeColumnDetector()
    private var analysis: RecipeAnalysis?
    
    func processRecipeImage(_ image: UIImage) {
        showLoadingIndicator()
        
        detector.analyzeRecipeCard(image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                
                if case .success(let analysis) = result {
                    self?.analysis = analysis
                    self?.showIngredientSelection()
                }
            }
        }
    }
}
```

## 🔍 Debug Print Helpers

### Add to RecipeAnalysis
```swift
extension RecipeAnalysis {
    func printSummary() {
        print("📊 Analysis Summary")
        print("  Sections: \(sections.count)")
        print("  Rows: \(ingredientRows.count)")
        print("  Divider: \(columnLayout.verticalDividerX?.description ?? "none")")
    }
}
```

### Add to IngredientRow
```swift
extension IngredientRow {
    func printContent() {
        let left = leftColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
        let right = rightColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
        print("L: \(left) | R: \(right)")
    }
}
```

## ⚡ Performance Tips

### Cache Results
```swift
class RecipeProcessor {
    private var cache: [String: RecipeAnalysis] = [:]
    
    func analyze(image: UIImage, id: String) {
        if let cached = cache[id] {
            completion(.success(cached))
            return
        }
        // ... analyze and cache
    }
}
```

### Process in Background
```swift
DispatchQueue.global(qos: .userInitiated).async {
    detector.analyzeRecipeCard(image: image) { result in
        DispatchQueue.main.async {
            // Update UI
        }
    }
}
```

## 🎯 Quality Checks

### Validate Results
```swift
func validateAnalysis(_ analysis: RecipeAnalysis) -> Bool {
    // Check minimum rows
    guard analysis.ingredientRows.count >= 3 else { return false }
    
    // Check column distribution
    let withBothColumns = analysis.ingredientRows.filter { 
        !$0.leftColumnBlocks.isEmpty && !$0.rightColumnBlocks.isEmpty 
    }.count
    
    guard withBothColumns > analysis.ingredientRows.count / 2 else { 
        return false 
    }
    
    return true
}
```

## 📋 Files You Need

1. **RecipeColumnDetector.swift** ← Core engine
2. **RecipeColumnDetectorDebugVisualizer.swift** ← Visual debugging
3. **RecipeDetectorCompleteTest.swift** ← Ready-to-use test app

Optional:
4. **RecipeColumnDetectorTester.swift** ← Advanced testing
5. **TESTING_GUIDE.md** ← Detailed guide
6. **README.md** ← Full documentation

## 🆘 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| No divider detected | Lower `minimumConfidence` to 0.1 |
| Too many rows | Increase `rowHeightThreshold` to 0.020 |
| Too few rows | Decrease `rowHeightThreshold` to 0.012 |
| Wrong columns | Check divider X (should be 0.30-0.45) |
| No text detected | Check image quality/size |
| Slow performance | Process in background queue |

## ✅ Ready to Test?

```swift
// 1. Add files to Xcode
// 2. Add test images to Assets
// 3. Run this:

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RecipeDetectorTestApp()
        }
    }
}

// 4. Tap "Load & Analyze"
// 5. Review results!
```

---
💡 **Pro Tip**: Start with the simplest recipe image first!
