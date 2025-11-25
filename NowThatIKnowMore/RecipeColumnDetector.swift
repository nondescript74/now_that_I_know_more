import Vision
import UIKit
import CoreImage

// MARK: - Data Models

struct RecipeSection {
    let type: SectionType
    let boundingBox: CGRect
    let textObservations: [VNRecognizedTextObservation]
    
    enum SectionType {
        case title
        case metadata // yield, serving info
        case ingredients
        case instructions
        case variations
    }
}

struct ColumnLayout {
    let verticalDividerX: CGFloat?
    let leftColumnBounds: CGRect
    let rightColumnBounds: CGRect?
    let imageSize: CGSize
    
    // Helper to determine which column a text block belongs to
    func columnForTextBlock(_ observation: VNRecognizedTextObservation) -> Column {
        let normalizedX = observation.boundingBox.midX
        
        if let dividerX = verticalDividerX {
            return normalizedX < dividerX ? .left : .right
        } else {
            // Fallback: if no divider detected, use positional heuristic
            return normalizedX < 0.6 ? .left : .right
        }
    }
    
    enum Column {
        case left
        case right
    }
}

struct IngredientRow: Sendable {
    let yPosition: CGFloat
    let height: CGFloat
    let leftColumnBlocks: [VNRecognizedTextObservation]
    let rightColumnBlocks: [VNRecognizedTextObservation]
    
    var boundingBox: CGRect {
        CGRect(x: 0, y: yPosition, width: 1.0, height: height)
    }
}

// MARK: - Main Detector Class

class RecipeColumnDetector {
    
    // MARK: - Public Interface
    
    func analyzeRecipeCard(image: UIImage) async throws -> RecipeAnalysis {
        guard let cgImage = image.cgImage else {
            throw RecipeError.invalidImage
        }
        
        // Step 1: Detect text
        let textObservations = try await detectText(in: cgImage)
        
        // Step 2: Detect horizontal lines (section dividers)
        let horizontalLines = (try? await detectHorizontalLines(in: cgImage)) ?? []
        
        // Step 3: Detect vertical divider
        let verticalDivider = try? await detectVerticalDivider(in: cgImage)
        
        // Step 4: Analyze and segment
        let analysis = analyzeLayout(
            textObservations: textObservations,
            horizontalLines: horizontalLines,
            verticalDivider: verticalDivider,
            imageSize: image.size
        )
        
        return analysis
    }
    
    // Legacy callback-based API for backwards compatibility
    func analyzeRecipeCard(image: UIImage, completion: @escaping @Sendable (Result<RecipeAnalysis, Error>) -> Void) {
        Task {
            do {
                let analysis = try await analyzeRecipeCard(image: image)
                completion(.success(analysis))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Text Detection
    
    private func detectText(in cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                
                // Configure for high accuracy
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                    
                    guard let observations = request.results else {
                        continuation.resume(throwing: RecipeError.noTextDetected)
                        return
                    }
                    
                    continuation.resume(returning: observations)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Line Detection
    
    private func detectHorizontalLines(in cgImage: CGImage) async throws -> [DetectedLine] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectRectanglesRequest()
                request.minimumAspectRatio = 0.01
                request.maximumAspectRatio = 1.0
                request.minimumSize = 0.1
                request.minimumConfidence = 0.3
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                    
                    guard let observations = request.results else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    // Filter for horizontal lines (rectangles with high aspect ratio)
                    let horizontalLines = observations.compactMap { observation -> DetectedLine? in
                        let box = observation.boundingBox
                        let aspectRatio = box.width / box.height
                        
                        // Horizontal line: width >> height
                        if aspectRatio > 10.0 && box.width > 0.5 {
                            return DetectedLine(
                                startPoint: CGPoint(x: box.minX, y: box.midY),
                                endPoint: CGPoint(x: box.maxX, y: box.midY),
                                orientation: .horizontal,
                                confidence: observation.confidence
                            )
                        }
                        return nil
                    }
                    
                    continuation.resume(returning: horizontalLines)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func detectVerticalDivider(in cgImage: CGImage) async throws -> DetectedLine? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Use edge detection to find the vertical divider
                let request = VNDetectRectanglesRequest()
                request.minimumAspectRatio = 0.01
                request.maximumAspectRatio = 1.0
                request.minimumSize = 0.1
                request.minimumConfidence = 0.2
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                    
                    guard let observations = request.results else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Filter for vertical lines (rectangles with low aspect ratio)
                    let verticalLines = observations.compactMap { observation -> DetectedLine? in
                        let box = observation.boundingBox
                        let aspectRatio = box.width / box.height
                        
                        // Vertical line: height >> width, and positioned in middle region
                        if aspectRatio < 0.1 && box.height > 0.3 && box.midX > 0.3 && box.midX < 0.7 {
                            return DetectedLine(
                                startPoint: CGPoint(x: box.midX, y: box.minY),
                                endPoint: CGPoint(x: box.midX, y: box.maxY),
                                orientation: .vertical,
                                confidence: observation.confidence
                            )
                        }
                        return nil
                    }
                    
                    // Return the most confident vertical line
                    let bestLine = verticalLines.max { $0.confidence < $1.confidence }
                    continuation.resume(returning: bestLine)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Alternative Vertical Divider Detection using Edge Detection
    
    private func detectVerticalDividerUsingEdges(in cgImage: CGImage) async throws -> DetectedLine? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Create CIImage for edge detection
                let ciImage = CIImage(cgImage: cgImage)
                
                guard let edgeFilter = CIFilter(name: "CIEdges") else {
                    continuation.resume(returning: nil)
                    return
                }
                
                edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
                edgeFilter.setValue(2.0, forKey: kCIInputIntensityKey)
                
                guard let edgeOutput = edgeFilter.outputImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let context = CIContext()
                guard let edgeCGImage = context.createCGImage(edgeOutput, from: edgeOutput.extent) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Now use line detection on edge image
                let request = VNDetectContoursRequest()
                let handler = VNImageRequestHandler(cgImage: edgeCGImage, options: [:])
                
                do {
                    try handler.perform([request])
                    
                    // Process contours to find vertical lines
                    guard let observations = request.results else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Analyze contours for vertical line candidates
                    let verticalLine = self.findVerticalLineInContours(observations, imageSize: ciImage.extent.size)
                    continuation.resume(returning: verticalLine)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    nonisolated private func findVerticalLineInContours(_ observations: [VNContoursObservation], imageSize: CGSize) -> DetectedLine? {
        // Analyze contours to find strong vertical line in middle region
        var verticalCandidates: [(x: CGFloat, strength: Float)] = []
        
        for observation in observations {
            let normalizedPath = observation.normalizedPath
            
            // Check if contour is predominantly vertical
            let bounds = normalizedPath.boundingBox
            if bounds.height > 0.3 && bounds.width < 0.05 && bounds.midX > 0.3 && bounds.midX < 0.7 {
                verticalCandidates.append((x: bounds.midX, strength: observation.confidence))
            }
        }
        
        // Find the strongest candidate
        guard let best = verticalCandidates.max(by: { $0.strength < $1.strength }) else {
            return nil
        }
        
        return DetectedLine(
            startPoint: CGPoint(x: best.x, y: 0.2),
            endPoint: CGPoint(x: best.x, y: 0.8),
            orientation: .vertical,
            confidence: best.strength
        )
    }
    
    // MARK: - Heuristic Vertical Divider Detection
    
    private func detectVerticalDividerHeuristic(textObservations: [VNRecognizedTextObservation]) -> CGFloat? {
        // Analyze the X-positions of text blocks to find a gap
        let xPositions = textObservations.map { $0.boundingBox.midX }.sorted()
        
        guard xPositions.count > 5 else { return nil }
        
        // Look for the largest gap in the middle region (0.3 to 0.7)
        var maxGap: CGFloat = 0
        var dividerPosition: CGFloat?
        
        for i in 0..<(xPositions.count - 1) {
            let gap = xPositions[i + 1] - xPositions[i]
            let midPoint = (xPositions[i] + xPositions[i + 1]) / 2
            
            if midPoint > 0.3 && midPoint < 0.7 && gap > maxGap {
                maxGap = gap
                dividerPosition = midPoint
            }
        }
        
        // Only accept if gap is significant (> 5% of image width)
        return maxGap > 0.05 ? dividerPosition : nil
    }
    
    // MARK: - Layout Analysis
    
    private func analyzeLayout(
        textObservations: [VNRecognizedTextObservation],
        horizontalLines: [DetectedLine],
        verticalDivider: DetectedLine?,
        imageSize: CGSize
    ) -> RecipeAnalysis {
        
        // Step 1: Segment sections using horizontal lines
        let sections = segmentSections(textObservations: textObservations, horizontalLines: horizontalLines)
        
        // Step 2: Determine vertical divider position (use detected line or heuristic)
        let dividerX = verticalDivider?.startPoint.x ?? detectVerticalDividerHeuristic(textObservations: textObservations)
        
        // Step 3: Create column layout
        let columnLayout = createColumnLayout(dividerX: dividerX, imageSize: imageSize)
        
        // Step 4: Extract ingredient section
        guard let ingredientSection = sections.first(where: { $0.type == .ingredients }) else {
            return RecipeAnalysis(
                sections: sections,
                columnLayout: columnLayout,
                ingredientRows: [],
                imageSize: imageSize
            )
        }
        
        // Step 5: Group ingredient text blocks into rows
        let ingredientRows = groupIntoRows(
            textObservations: ingredientSection.textObservations,
            columnLayout: columnLayout
        )
        
        return RecipeAnalysis(
            sections: sections,
            columnLayout: columnLayout,
            ingredientRows: ingredientRows,
            imageSize: imageSize
        )
    }
    
    private func segmentSections(
        textObservations: [VNRecognizedTextObservation],
        horizontalLines: [DetectedLine]
    ) -> [RecipeSection] {
        
        // Sort lines by Y position (top to bottom in normalized coordinates)
        let sortedLines = horizontalLines.sorted { $0.startPoint.y > $1.startPoint.y }
        
        // Vision framework uses bottom-left origin, so Y=1.0 is top of image
        var sections: [RecipeSection] = []
        
        // Title section (everything above first horizontal line)
        if let firstLine = sortedLines.first {
            let titleObservations = textObservations.filter { $0.boundingBox.minY > firstLine.startPoint.y }
            if !titleObservations.isEmpty {
                sections.append(RecipeSection(
                    type: .title,
                    boundingBox: combinedBoundingBox(titleObservations),
                    textObservations: titleObservations
                ))
            }
        }
        
        // Ingredient section (between first and second horizontal lines, or first line to bottom if only one line)
        if sortedLines.count >= 2 {
            let topY = sortedLines[0].startPoint.y
            let bottomY = sortedLines[1].startPoint.y
            
            let ingredientObservations = textObservations.filter { obs in
                obs.boundingBox.midY < topY && obs.boundingBox.midY > bottomY
            }
            
            if !ingredientObservations.isEmpty {
                sections.append(RecipeSection(
                    type: .ingredients,
                    boundingBox: combinedBoundingBox(ingredientObservations),
                    textObservations: ingredientObservations
                ))
            }
            
            // Instructions and variations (below second line)
            let remainingObservations = textObservations.filter { $0.boundingBox.maxY < bottomY }
            if !remainingObservations.isEmpty {
                sections.append(RecipeSection(
                    type: .instructions,
                    boundingBox: combinedBoundingBox(remainingObservations),
                    textObservations: remainingObservations
                ))
            }
        } else if let firstLine = sortedLines.first {
            // Only one line found - everything below is ingredients
            let ingredientObservations = textObservations.filter { $0.boundingBox.maxY < firstLine.startPoint.y }
            if !ingredientObservations.isEmpty {
                sections.append(RecipeSection(
                    type: .ingredients,
                    boundingBox: combinedBoundingBox(ingredientObservations),
                    textObservations: ingredientObservations
                ))
            }
        }
        
        return sections
    }
    
    private func createColumnLayout(dividerX: CGFloat?, imageSize: CGSize) -> ColumnLayout {
        if let dividerX = dividerX {
            return ColumnLayout(
                verticalDividerX: dividerX,
                leftColumnBounds: CGRect(x: 0, y: 0, width: dividerX, height: 1.0),
                rightColumnBounds: CGRect(x: dividerX, y: 0, width: 1.0 - dividerX, height: 1.0),
                imageSize: imageSize
            )
        } else {
            // No divider detected - assume single wide column or use default split
            return ColumnLayout(
                verticalDividerX: nil,
                leftColumnBounds: CGRect(x: 0, y: 0, width: 0.6, height: 1.0),
                rightColumnBounds: CGRect(x: 0.6, y: 0, width: 0.4, height: 1.0),
                imageSize: imageSize
            )
        }
    }
    
    private func groupIntoRows(
        textObservations: [VNRecognizedTextObservation],
        columnLayout: ColumnLayout
    ) -> [IngredientRow] {
        
        // Sort by Y position (top to bottom)
        let sorted = textObservations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        
        var rows: [IngredientRow] = []
        var currentRowBlocks: [VNRecognizedTextObservation] = []
        var currentRowY: CGFloat?
        
        let rowHeightThreshold: CGFloat = 0.015 // ~1.5% of image height for grouping
        
        for observation in sorted {
            let blockY = observation.boundingBox.midY
            
            if let rowY = currentRowY {
                // Check if this block belongs to the current row
                if abs(blockY - rowY) < rowHeightThreshold {
                    currentRowBlocks.append(observation)
                } else {
                    // Start a new row
                    if !currentRowBlocks.isEmpty {
                        rows.append(createIngredientRow(from: currentRowBlocks, columnLayout: columnLayout))
                    }
                    currentRowBlocks = [observation]
                    currentRowY = blockY
                }
            } else {
                // First block
                currentRowBlocks.append(observation)
                currentRowY = blockY
            }
        }
        
        // Add the last row
        if !currentRowBlocks.isEmpty {
            rows.append(createIngredientRow(from: currentRowBlocks, columnLayout: columnLayout))
        }
        
        return rows
    }
    
    private func createIngredientRow(
        from observations: [VNRecognizedTextObservation],
        columnLayout: ColumnLayout
    ) -> IngredientRow {
        
        let leftBlocks = observations.filter { columnLayout.columnForTextBlock($0) == .left }
        let rightBlocks = observations.filter { columnLayout.columnForTextBlock($0) == .right }
        
        let allYs = observations.flatMap { [$0.boundingBox.minY, $0.boundingBox.maxY] }
        let minY = allYs.min() ?? 0
        let maxY = allYs.max() ?? 0
        
        return IngredientRow(
            yPosition: minY,
            height: maxY - minY,
            leftColumnBlocks: leftBlocks.sorted { $0.boundingBox.minX < $1.boundingBox.minX },
            rightColumnBlocks: rightBlocks.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        )
    }
    
    private func combinedBoundingBox(_ observations: [VNRecognizedTextObservation]) -> CGRect {
        guard !observations.isEmpty else { return .zero }
        
        let minX = observations.map { $0.boundingBox.minX }.min() ?? 0
        let maxX = observations.map { $0.boundingBox.maxX }.max() ?? 0
        let minY = observations.map { $0.boundingBox.minY }.min() ?? 0
        let maxY = observations.map { $0.boundingBox.maxY }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Supporting Types

struct DetectedLine {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let orientation: Orientation
    let confidence: Float
    
    enum Orientation {
        case horizontal
        case vertical
    }
}

struct RecipeAnalysis {
    let sections: [RecipeSection]
    let columnLayout: ColumnLayout
    let ingredientRows: [IngredientRow]
    let imageSize: CGSize
}

enum RecipeError: Error {
    case invalidImage
    case noTextDetected
    case noIngredientsFound
}

// MARK: - Usage Example

/*
 let detector = RecipeColumnDetector()
 
 // Modern async/await API
 Task {
     do {
         let analysis = try await detector.analyzeRecipeCard(image: recipeImage)
         print("Found \(analysis.ingredientRows.count) ingredient rows")
         
         if let dividerX = analysis.columnLayout.verticalDividerX {
             print("Vertical divider at x: \(dividerX)")
         }
         
         for (index, row) in analysis.ingredientRows.enumerated() {
             print("\nRow \(index + 1):")
             print("  Left column blocks: \(row.leftColumnBlocks.count)")
             print("  Right column blocks: \(row.rightColumnBlocks.count)")
             
             // Extract text from blocks
             for block in row.leftColumnBlocks {
                 if let text = block.topCandidates(1).first?.string {
                     print("    Left: \(text)")
                 }
             }
             
             for block in row.rightColumnBlocks {
                 if let text = block.topCandidates(1).first?.string {
                     print("    Right: \(text)")
                 }
             }
         }
     } catch {
         print("Error: \(error)")
     }
 }
 
 // Or using the legacy callback-based API
 detector.analyzeRecipeCard(image: recipeImage) { result in
     switch result {
     case .success(let analysis):
         print("Found \(analysis.ingredientRows.count) ingredient rows")
         
         if let dividerX = analysis.columnLayout.verticalDividerX {
             print("Vertical divider at x: \(dividerX)")
         }
         
         for (index, row) in analysis.ingredientRows.enumerated() {
             print("\nRow \(index + 1):")
             print("  Left column blocks: \(row.leftColumnBlocks.count)")
             print("  Right column blocks: \(row.rightColumnBlocks.count)")
             
             // Extract text from blocks
             for block in row.leftColumnBlocks {
                 if let text = block.topCandidates(1).first?.string {
                     print("    Left: \(text)")
                 }
             }
             
             for block in row.rightColumnBlocks {
                 if let text = block.topCandidates(1).first?.string {
                     print("    Right: \(text)")
                 }
             }
         }
         
     case .failure(let error):
         print("Error: \(error)")
     }
 }
 */
