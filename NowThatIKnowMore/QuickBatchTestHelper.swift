//
//  QuickBatchTestHelper.swift
//  Utility functions for quick testing of multiple recipe images
//

import SwiftUI
import Vision

// MARK: - Quick Batch Test Function
/// Use this in console or in a test button to analyze all images at once
@MainActor
func quickTestAllRecipeImages() async {
    let imageNames = [
        "AmNC", "CaPi", "Mpio", "LaYS", "CoCh", "CuRa", "DhCh",
        "GrCu", "KhCh", "LiCh", "MaCh", "PaCh", "ToCh"
    ]
    
    print("\n" + String(repeating: "=", count: 60))
    print("🧪 BATCH TESTING RECIPE COLUMN DETECTOR")
    print(String(repeating: "=", count: 60) + "\n")
    
    let detector = RecipeColumnDetector()
    var successCount = 0
    var failCount = 0
    var dividerFoundCount = 0
    
    for imageName in imageNames {
        guard let image = UIImage(named: imageName) else {
            print("⚠️  Could not load: \(imageName)")
            failCount += 1
            continue
        }
        
        print("📝 Testing: \(imageName)")
        
        // Use continuation to properly handle async call
        let result = await withCheckedContinuation { continuation in
            detector.analyzeRecipeCard(image: image) { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success(let analysis):
            successCount += 1
            let hasDivider = analysis.columnLayout.verticalDividerX != nil
            if hasDivider { dividerFoundCount += 1 }
            
            let dividerStatus = hasDivider ? "✅" : "⚠️ "
            let dividerText = hasDivider
                ? String(format: "x=%.3f", analysis.columnLayout.verticalDividerX!)
                : "heuristic"
            
            print("   \(dividerStatus) Divider: \(dividerText)")
            print("   📊 Rows: \(analysis.ingredientRows.count)")
            
            // Check quality
            let rowCount = analysis.ingredientRows.count
            if rowCount < 3 {
                print("   ⚠️  Warning: Very few rows detected")
            } else if rowCount > 20 {
                print("   ⚠️  Warning: Many rows (might be over-segmented)")
            }
            
        case .failure(let error):
            failCount += 1
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        print("")
    }
    
    // Summary
    print(String(repeating: "=", count: 60))
    print("📊 SUMMARY")
    print(String(repeating: "=", count: 60))
    print("Total images tested: \(imageNames.count)")
    print("✅ Successful: \(successCount)")
    print("❌ Failed: \(failCount)")
    print("🎯 Divider found: \(dividerFoundCount)/\(successCount)")
    if successCount > 0 {
        let dividerRate = Double(dividerFoundCount) / Double(successCount) * 100
        print("📈 Divider detection rate: \(String(format: "%.1f%%", dividerRate))")
    }
    print(String(repeating: "=", count: 60) + "\n")
}

// MARK: - Single Image Quick Test
/// Quick console-based test for a single image
@MainActor
func quickTestSingleImage(named: String) async {
    print("\n🧪 Testing: \(named)")
    print(String(repeating: "-", count: 50))
    
    guard let image = UIImage(named: named) else {
        print("❌ Could not load image: \(named)")
        return
    }
    
    print("✅ Image loaded: \(Int(image.size.width)) × \(Int(image.size.height))px")
    
    let detector = RecipeColumnDetector()
    
    let result = await withCheckedContinuation { continuation in
        detector.analyzeRecipeCard(image: image) { result in
            continuation.resume(returning: result)
        }
    }
    
    switch result {
    case .success(let analysis):
        printDetailedAnalysis(analysis)
        
    case .failure(let error):
        print("❌ Analysis failed: \(error.localizedDescription)")
    }
    
    print(String(repeating: "-", count: 50) + "\n")
}

// MARK: - Detailed Analysis Printer
private func printDetailedAnalysis(_ analysis: RecipeAnalysis) {
    print("\n📊 ANALYSIS RESULTS:")
    
    // Divider
    print("\n🔍 Column Divider:")
    if let dividerX = analysis.columnLayout.verticalDividerX {
        print("   ✅ Found at x = \(String(format: "%.3f", dividerX))")
        let pixelX = Int(dividerX * analysis.imageSize.width)
        print("   📍 Pixel position: \(pixelX)px")
        
        // Quality check
        if dividerX >= 0.30 && dividerX <= 0.45 {
            print("   ✓ Position in good range (0.30-0.45)")
        } else if dividerX < 0.30 {
            print("   ⚠️  Position quite far left (< 0.30)")
        } else {
            print("   ⚠️  Position quite far right (> 0.45)")
        }
    } else {
        print("   ⚠️  No divider detected (using heuristic fallback)")
    }
    
    // Rows
    print("\n📝 Ingredient Rows: \(analysis.ingredientRows.count)")
    
    if analysis.ingredientRows.count >= 3 && analysis.ingredientRows.count <= 20 {
        print("   ✓ Row count in reasonable range")
    } else if analysis.ingredientRows.count < 3 {
        print("   ⚠️  Very few rows - ingredients might be merged")
        print("   💡 Try decreasing rowHeightThreshold")
    } else {
        print("   ⚠️  Many rows - ingredients might be split")
        print("   💡 Try increasing rowHeightThreshold")
    }
    
    // Column distribution
    print("\n📊 Column Distribution:")
    var bothColumnsCount = 0
    var leftOnlyCount = 0
    var rightOnlyCount = 0
    
    for row in analysis.ingredientRows {
        let hasLeft = !row.leftColumnBlocks.isEmpty
        let hasRight = !row.rightColumnBlocks.isEmpty
        
        if hasLeft && hasRight {
            bothColumnsCount += 1
        } else if hasLeft {
            leftOnlyCount += 1
        } else if hasRight {
            rightOnlyCount += 1
        }
    }
    
    print("   Both columns: \(bothColumnsCount)")
    print("   Left only: \(leftOnlyCount)")
    print("   Right only: \(rightOnlyCount)")
    
    if bothColumnsCount > analysis.ingredientRows.count / 2 {
        print("   ✓ Good column balance")
    } else {
        print("   ⚠️  Imbalanced columns - check divider position")
    }
    
    // Sample rows
    print("\n📋 Sample Rows (first 3):")
    for (i, row) in analysis.ingredientRows.prefix(3).enumerated() {
        let leftTexts = row.leftColumnBlocks
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        let rightTexts = row.rightColumnBlocks
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        
        print("   Row \(i + 1):")
        if !leftTexts.isEmpty {
            print("      L: \(leftTexts)")
        }
        if !rightTexts.isEmpty {
            print("      R: \(rightTexts)")
        }
    }
    
    if analysis.ingredientRows.count > 3 {
        print("   ... (\(analysis.ingredientRows.count - 3) more rows)")
    }
}

// MARK: - SwiftUI Test Button View
/// Add this to any SwiftUI view for quick testing
struct QuickBatchTestButton: View {
    @State private var isRunning = false
    @State private var showResults = false
    
    var body: some View {
        VStack {
            Button(action: runBatchTest) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Testing...")
                    } else {
                        Label("Run Batch Test", systemImage: "play.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
            
            if showResults {
                Text("✅ Batch test complete! Check console for results.")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding()
            }
        }
    }
    
    private func runBatchTest() {
        isRunning = true
        showResults = false
        
        Task { @MainActor in
            await quickTestAllRecipeImages()
            isRunning = false
            showResults = true
        }
    }
}

// MARK: - Individual Image Test Button
struct QuickSingleTestButton: View {
    let imageName: String
    @State private var isRunning = false
    
    var body: some View {
        Button(action: runTest) {
            HStack {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Label("Test \(imageName)", systemImage: "play.circle")
                }
            }
        }
        .disabled(isRunning)
    }
    
    private func runTest() {
        isRunning = true
        
        Task { @MainActor in
            await quickTestSingleImage(named: imageName)
            isRunning = false
        }
    }
}

// MARK: - Comparison Test
/// Compare results across multiple images to find patterns
@MainActor
func compareDetectionQuality(imageNames: [String]) async {
    print("\n" + String(repeating: "=", count: 70))
    print("🔬 DETECTION QUALITY COMPARISON")
    print(String(repeating: "=", count: 70) + "\n")
    
    struct ImageResult {
        let name: String
        let success: Bool
        let hasDivider: Bool
        let dividerX: CGFloat?
        let rowCount: Int
        let bothColumnsPercent: Double
    }
    
    var results: [ImageResult] = []
    let detector = RecipeColumnDetector()
    
    for imageName in imageNames {
        guard let image = UIImage(named: imageName) else { continue }
        
        let result = await withCheckedContinuation { continuation in
            detector.analyzeRecipeCard(image: image) { result in
                continuation.resume(returning: result)
            }
        }
        
        let imageResult: ImageResult
        switch result {
        case .success(let analysis):
            let bothCount = analysis.ingredientRows.filter {
                !$0.leftColumnBlocks.isEmpty && !$0.rightColumnBlocks.isEmpty
            }.count
            let percent = analysis.ingredientRows.count > 0
                ? Double(bothCount) / Double(analysis.ingredientRows.count) * 100
                : 0
            
            imageResult = ImageResult(
                name: imageName,
                success: true,
                hasDivider: analysis.columnLayout.verticalDividerX != nil,
                dividerX: analysis.columnLayout.verticalDividerX,
                rowCount: analysis.ingredientRows.count,
                bothColumnsPercent: percent
            )
            
        case .failure:
            imageResult = ImageResult(
                name: imageName,
                success: false,
                hasDivider: false,
                dividerX: nil,
                rowCount: 0,
                bothColumnsPercent: 0
            )
        }
        
        results.append(imageResult)
    }
    
    // Print comparison table
    print(String(format: "%-10s | %-8s | %-10s | %-6s | %-12s", "Image", "Divider", "Position", "Rows", "Both Cols %"))
    print(String(repeating: "-", count: 70))
    
    for result in results {
        let dividerIcon = result.hasDivider ? "✅" : "⚠️ "
        let position = result.dividerX.map { String(format: "%.3f", $0) } ?? "N/A"
        let quality = result.bothColumnsPercent >= 50 ? "✓" : "⚠"
        
        print(String(format: "%-10s | %-8s | %-10s | %-6d | %5.1f%% %s",
                     result.name,
                     dividerIcon,
                     position,
                     result.rowCount,
                     result.bothColumnsPercent,
                     quality))
    }
    
    print(String(repeating: "=", count: 70) + "\n")
}

// MARK: - Preview Test View
#Preview("Batch Test Button") {
    VStack(spacing: 20) {
        QuickBatchTestButton()
        
        Text("Or test individual images:")
            .font(.headline)
        
        QuickSingleTestButton(imageName: "AmNC")
        QuickSingleTestButton(imageName: "CaPi")
        QuickSingleTestButton(imageName: "Mpio")
    }
    .padding()
}
