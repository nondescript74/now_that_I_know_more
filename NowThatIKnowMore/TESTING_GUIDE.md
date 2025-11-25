# RecipeColumnDetector Testing Guide for Xcode

## Quick Start Testing

### 1. Add Test Images to Your Xcode Project

Add your recipe images to the Assets catalog or as file references:
- AmNC.png
- CaPi.png  
- Mpio.png
- etc.

### 2. Create a Test View Controller

```swift
import UIKit

class RecipeDetectorTestViewController: UIViewController {
    
    private let detector = RecipeColumnDetector()
    private var imageView: UIImageView!
    private var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        runTest()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Image view
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Result label
        resultLabel = UILabel()
        resultLabel.numberOfLines = 0
        resultLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            resultLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func runTest() {
        // Load test image - replace with your image name
        guard let image = UIImage(named: "AmNC") else {
            resultLabel.text = "❌ Could not load test image"
            return
        }
        
        imageView.image = image
        resultLabel.text = "🔄 Analyzing..."
        
        detector.analyzeRecipeCard(image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleResult(result, imageName: "AmNC")
            }
        }
    }
    
    private func handleResult(_ result: Result<RecipeAnalysis, Error>, imageName: String) {
        switch result {
        case .success(let analysis):
            displayAnalysis(analysis, imageName: imageName)
            
        case .failure(let error):
            resultLabel.text = "❌ Error: \(error.localizedDescription)"
        }
    }
    
    private func displayAnalysis(_ analysis: RecipeAnalysis, imageName: String) {
        var text = "📊 Analysis for \(imageName)\n\n"
        
        // Image info
        text += "📐 Size: \(Int(analysis.imageSize.width))x\(Int(analysis.imageSize.height))\n\n"
        
        // Divider info
        if let dividerX = analysis.columnLayout.verticalDividerX {
            text += "✅ Vertical Divider: x=\(String(format: "%.3f", dividerX))\n"
        } else {
            text += "⚠️  No vertical divider detected\n"
        }
        
        // Sections
        text += "\n📑 Sections: \(analysis.sections.count)\n"
        for section in analysis.sections {
            text += "  • \(section.type): \(section.textObservations.count) blocks\n"
        }
        
        // Ingredient rows
        text += "\n🥘 Ingredient Rows: \(analysis.ingredientRows.count)\n"
        
        for (index, row) in analysis.ingredientRows.prefix(5).enumerated() {
            text += "\nRow \(index + 1):\n"
            text += "  Left: \(row.leftColumnBlocks.count) blocks\n"
            text += "  Right: \(row.rightColumnBlocks.count) blocks\n"
            
            // Extract text
            let leftTexts = row.leftColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
            if !leftTexts.isEmpty {
                text += "  📝 \(leftTexts.joined(separator: " "))\n"
            }
            
            let rightTexts = row.rightColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
            if !rightTexts.isEmpty {
                text += "  📝 \(rightTexts.joined(separator: " "))\n"
            }
        }
        
        if analysis.ingredientRows.count > 5 {
            text += "\n... and \(analysis.ingredientRows.count - 5) more rows\n"
        }
        
        resultLabel.text = text
        
        // Optional: Generate debug visualization
        // let debugImage = generateDebugVisualization(image: imageView.image!, analysis: analysis)
        // imageView.image = debugImage
    }
}
```

### 3. Test in SwiftUI (Alternative)

```swift
import SwiftUI

struct RecipeDetectorTestView: View {
    @State private var result: String = "Tap to test"
    @State private var debugImage: UIImage?
    
    let detector = RecipeColumnDetector()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let debugImage = debugImage {
                    Image(uiImage: debugImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                }
                
                Button("Run Test") {
                    runTest()
                }
                .buttonStyle(.borderedProminent)
                
                Text(result)
                    .font(.system(.caption, design: .monospaced))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Recipe Detector Test")
    }
    
    private func runTest() {
        guard let image = UIImage(named: "AmNC") else {
            result = "❌ Could not load image"
            return
        }
        
        result = "🔄 Analyzing..."
        
        detector.analyzeRecipeCard(image: image) { analysisResult in
            DispatchQueue.main.async {
                switch analysisResult {
                case .success(let analysis):
                    self.result = formatAnalysis(analysis)
                    // self.debugImage = generateDebugVisualization(image: image, analysis: analysis)
                    
                case .failure(let error):
                    self.result = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatAnalysis(_ analysis: RecipeAnalysis) -> String {
        var text = "📊 Analysis Complete\n\n"
        
        if let dividerX = analysis.columnLayout.verticalDividerX {
            text += "✅ Divider at: \(String(format: "%.3f", dividerX))\n"
        } else {
            text += "⚠️  No divider detected\n"
        }
        
        text += "\n🥘 Found \(analysis.ingredientRows.count) ingredient rows\n"
        
        for (index, row) in analysis.ingredientRows.prefix(3).enumerated() {
            text += "\nRow \(index + 1):\n"
            
            let leftTexts = row.leftColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
            let rightTexts = row.rightColumnBlocks.compactMap { $0.topCandidates(1).first?.string }
            
            text += "  L: \(leftTexts.joined(separator: " "))\n"
            text += "  R: \(rightTexts.joined(separator: " "))\n"
        }
        
        return text
    }
}
```

## Expected Results from Test Images

Based on analysis of your sample images:

### AmNC.png (Ambli ni Chutney)
- **Expected divider**: ~x=0.30 (around 30% from left)
- **Expected rows**: 6-7 ingredient rows
- **Layout**: 3 columns (imperial | description | metric)

### CaPi.png (Carrot Pickle)
- **Expected divider**: ~x=0.30
- **Expected rows**: 7-8 ingredient rows
- **Layout**: 3 columns with some wrapped text

### Mpio.png (Mango Pickle in Oil)
- **Expected divider**: ~x=0.30
- **Expected rows**: 12-15 ingredient rows (complex recipe)
- **Layout**: 3 columns with long ingredient list

## Debugging Tips

### If Vertical Divider Not Detected:

```swift
// Add this to RecipeColumnDetector.swift after line detection
print("🔍 Debug: Checking for vertical divider...")
if let divider = verticalDivider {
    print("   Found at x=\(divider.startPoint.x)")
} else {
    print("   Not found, trying heuristic...")
    let heuristicDivider = detectVerticalDividerHeuristic(textObservations: textObservations)
    print("   Heuristic result: \(heuristicDivider ?? -1)")
}
```

### If Rows Not Grouping Correctly:

```swift
// Adjust threshold in groupIntoRows()
let rowHeightThreshold: CGFloat = 0.020 // Try 0.015, 0.020, 0.025

// Add debug output
print("🔍 Grouping \(textObservations.count) blocks into rows...")
print("   Threshold: \(rowHeightThreshold)")
```

### If Too Many/Few Horizontal Lines:

```swift
// In detectHorizontalLines(), adjust aspect ratio filter
if aspectRatio > 15.0 && box.width > 0.6 { // Try 10.0, 15.0, 20.0
    // More strict = fewer lines detected
}
```

## Common Issues and Solutions

### Issue 1: Text Blocks Not Detected
**Symptom**: Empty ingredient rows or few text observations
**Solution**: 
- Ensure image quality is good (not too blurry)
- Check if recognitionLevel is set to .accurate
- Verify image is loaded correctly

### Issue 2: Wrong Column Assignment
**Symptom**: Text clearly in right column appears in left
**Solution**:
- Print dividerX value and verify it's reasonable (0.3-0.5)
- Check if heuristic is being used (may need adjustment)
- Add debug visualization to see actual divider line

### Issue 3: Multi-line Ingredients Split
**Symptom**: "chopped or grated" appears as two separate rows
**Solution**:
- Decrease rowHeightThreshold (0.015 or 0.012)
- This will group closer Y-positions together

### Issue 4: Too Many Sections Detected
**Symptom**: More than 3-4 sections
**Solution**:
- Filter horizontal lines more strictly (higher aspect ratio)
- Only use lines that span >70% of image width

## Next Steps After Testing

1. **Validate on all 19 images** - Look for patterns in failures
2. **Tune thresholds** - Adjust based on results:
   - Row grouping threshold
   - Line detection thresholds
   - Column boundary positions

3. **Add fallback strategies**:
   - If no vertical line, try text gap analysis
   - If too few rows, try different grouping algorithm
   - If sections wrong, use text content hints (e.g., "Makes", "cup", "tsp")

4. **Build the UI** - Once detection is reliable, create the guided selection interface

## Performance Notes

- Text recognition is the slowest part (~1-2 seconds per image)
- Line detection is fast (~100ms)
- Consider caching results if user might cancel/retry

## Integration with Your Recipe App

```swift
// In your RecipeCardViewController or similar
func processRecipeImage(_ image: UIImage) {
    showLoadingIndicator()
    
    detector.analyzeRecipeCard(image: image) { [weak self] result in
        DispatchQueue.main.async {
            self?.hideLoadingIndicator()
            
            switch result {
            case .success(let analysis):
                // Show guided ingredient selection UI
                self?.showIngredientSelectionUI(analysis: analysis, originalImage: image)
                
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
}
```

## Additional Debug Helpers

Add these extensions for easier testing:

```swift
extension RecipeAnalysis {
    var debugDescription: String {
        var text = "RecipeAnalysis:\n"
        text += "  Sections: \(sections.count)\n"
        text += "  Ingredient Rows: \(ingredientRows.count)\n"
        text += "  Divider: \(columnLayout.verticalDividerX?.description ?? "none")\n"
        return text
    }
}

extension IngredientRow {
    var debugDescription: String {
        let leftText = leftColumnBlocks.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        let rightText = rightColumnBlocks.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        return "Row[y=\(yPosition)]: L[\(leftText)] | R[\(rightText)]"
    }
}
```

## Testing Checklist

- [ ] Detector compiles without errors
- [ ] Test image loads successfully
- [ ] Text recognition completes (check logs)
- [ ] Vertical divider detected (or heuristic used)
- [ ] Horizontal lines found
- [ ] Ingredient section identified
- [ ] Rows grouped (at least some)
- [ ] Text extracted from rows
- [ ] Column assignment makes sense

---

**Ready to test?** Start with the simplest recipe image (fewest ingredients) and work up to more complex ones.
