//
//  RecipeImagePreprocessor.swift
//  Recipe Image Preprocessor
//
//  Advanced image preprocessing for recipe OCR
//  Segments images into logical zones, enhances text regions, and prepares clean images for Vision
//

import UIKit
import CoreImage
import Vision

// MARK: - Recipe Zone Types

/// Logical zones in a recipe image
enum RecipeZone: String, CaseIterable {
    case title
    case ingredients
    case instructions
    case metadata       // Servings, prep time, etc.
    case decorative     // Photos, decorations to ignore
    
    var color: UIColor {
        switch self {
        case .title: return .systemPurple
        case .ingredients: return .systemGreen
        case .instructions: return .systemBlue
        case .metadata: return .systemOrange
        case .decorative: return .systemGray
        }
    }
}

// MARK: - Detected Zone

/// A detected zone in the image with its bounds and type
struct DetectedZone {
    let zone: RecipeZone
    let bounds: CGRect  // Normalized coordinates (0-1)
    let confidence: Float
    
    /// Convert to pixel coordinates for a given image size
    func pixelBounds(for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: bounds.origin.x * imageSize.width,
            y: bounds.origin.y * imageSize.height,
            width: bounds.width * imageSize.width,
            height: bounds.height * imageSize.height
        )
    }
}

// MARK: - Preprocessed Zone

/// A preprocessed image zone ready for OCR
struct PreprocessedZone {
    let zone: RecipeZone
    let image: UIImage
    let originalBounds: CGRect  // Normalized coordinates
    let textRegions: [CGRect]   // Text regions within this zone (normalized)
}

// MARK: - Preprocessing Options

struct PreprocessingOptions {
    /// Enable automatic zone detection
    var autoDetectZones: Bool = true
    
    /// Enable text region detection within zones
    var detectTextRegions: Bool = true
    
    /// Enable image enhancement (contrast, sharpness, denoising)
    var enhanceImage: Bool = true
    
    /// Convert to grayscale for better OCR
    var convertToGrayscale: Bool = true
    
    /// Apply adaptive thresholding to make text stand out
    var applyThresholding: Bool = true
    
    /// Deskew rotated images
    var deskewImage: Bool = true
    
    /// Target width for preprocessing (maintains aspect ratio)
    var targetWidth: CGFloat = 1024
    
    /// Minimum confidence for zone detection
    var minimumZoneConfidence: Float = 0.5
    
    static let `default` = PreprocessingOptions()
    static let highQuality = PreprocessingOptions(
        autoDetectZones: true,
        detectTextRegions: true,
        enhanceImage: true,
        convertToGrayscale: true,
        applyThresholding: true,
        deskewImage: true,
        targetWidth: 1536,
        minimumZoneConfidence: 0.4
    )
    static let fast = PreprocessingOptions(
        autoDetectZones: false,
        detectTextRegions: false,
        enhanceImage: true,
        convertToGrayscale: true,
        applyThresholding: false,
        deskewImage: false,
        targetWidth: 768,
        minimumZoneConfidence: 0.6
    )
}

// MARK: - Recipe Image Preprocessor

/// Advanced image preprocessor for recipe OCR
/// 
/// This class implements a multi-stage preprocessing pipeline:
/// 1. Zone Detection: Segments the image into logical recipe sections
/// 2. Text Region Detection: Finds text-heavy areas within each zone
/// 3. Image Enhancement: Applies filters to improve text clarity
/// 4. Zone Extraction: Creates clean, single-column images per zone
@MainActor
class RecipeImagePreprocessor {
    
    private let options: PreprocessingOptions
    private let ciContext: CIContext
    
    init(options: PreprocessingOptions = .default) {
        self.options = options
        self.ciContext = CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: false
        ])
    }
    
    // MARK: - Main Preprocessing Pipeline
    
    /// Preprocess an image for OCR with automatic zone detection
    func preprocess(image: UIImage) async throws -> [PreprocessedZone] {
        print("🔧 [Preprocessor] Starting preprocessing pipeline")
        print("   Input size: \(image.size)")
        print("   Options: auto-detect=\(options.autoDetectZones), enhance=\(options.enhanceImage)")
        
        // Step 1: Resize image if needed
        let resizedImage = resizeImage(image, targetWidth: options.targetWidth)
        print("📏 [Preprocessor] Resized to: \(resizedImage.size)")
        
        // Step 2: Deskew if enabled
        let deskewedImage = if options.deskewImage {
            await deskew(image: resizedImage)
        } else {
            resizedImage
        }
        
        // Step 3: Detect zones
        let zones = if options.autoDetectZones {
            await detectZones(in: deskewedImage)
        } else {
            // Default: treat entire image as one zone
            [DetectedZone(zone: .ingredients, 
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                         confidence: 1.0)]
        }
        
        print("🎯 [Preprocessor] Detected \(zones.count) zones")
        
        // Step 4: Process each zone
        var preprocessedZones: [PreprocessedZone] = []
        
        for detectedZone in zones {
            print("   Processing zone: \(detectedZone.zone.rawValue)")
            
            // Extract zone image
            guard let zoneImage = extractZone(from: deskewedImage, zone: detectedZone) else {
                print("   ⚠️ Failed to extract zone")
                continue
            }
            
            // Enhance zone image
            let enhancedImage = if options.enhanceImage {
                enhanceForOCR(image: zoneImage)
            } else {
                zoneImage
            }
            
            // Detect text regions if enabled
            let textRegions = if options.detectTextRegions {
                await detectTextRegions(in: enhancedImage)
            } else {
                [CGRect]()
            }
            
            print("   Found \(textRegions.count) text regions")
            
            let preprocessed = PreprocessedZone(
                zone: detectedZone.zone,
                image: enhancedImage,
                originalBounds: detectedZone.bounds,
                textRegions: textRegions
            )
            
            preprocessedZones.append(preprocessed)
        }
        
        print("✅ [Preprocessor] Completed preprocessing: \(preprocessedZones.count) zones ready")
        return preprocessedZones
    }
    
    /// Preprocess with manual zone definitions (for user-defined regions)
    func preprocess(image: UIImage, manualZones: [DetectedZone]) async throws -> [PreprocessedZone] {
        print("🔧 [Preprocessor] Starting preprocessing with \(manualZones.count) manual zones")
        
        // Step 1: Resize
        let resizedImage = resizeImage(image, targetWidth: options.targetWidth)
        
        // Step 2: Deskew if enabled
        let deskewedImage = if options.deskewImage {
            await deskew(image: resizedImage)
        } else {
            resizedImage
        }
        
        // Step 3: Process each manual zone
        var preprocessedZones: [PreprocessedZone] = []
        
        for detectedZone in manualZones {
            print("   Processing manual zone: \(detectedZone.zone.rawValue)")
            
            guard let zoneImage = extractZone(from: deskewedImage, zone: detectedZone) else {
                continue
            }
            
            let enhancedImage = if options.enhanceImage {
                enhanceForOCR(image: zoneImage)
            } else {
                zoneImage
            }
            
            let textRegions = if options.detectTextRegions {
                await detectTextRegions(in: enhancedImage)
            } else {
                [CGRect]()
            }
            
            let preprocessed = PreprocessedZone(
                zone: detectedZone.zone,
                image: enhancedImage,
                originalBounds: detectedZone.bounds,
                textRegions: textRegions
            )
            
            preprocessedZones.append(preprocessed)
        }
        
        print("✅ [Preprocessor] Completed preprocessing: \(preprocessedZones.count) zones ready")
        return preprocessedZones
    }
    
    // MARK: - Zone Detection
    
    /// Detect recipe zones using layout analysis and text distribution
    private func detectZones(in image: UIImage) async -> [DetectedZone] {
        guard let cgImage = image.cgImage else { return [] }
        
        var detectedZones: [DetectedZone] = []
        
        // Use Vision to detect text blocks and analyze their distribution
        let request = VNDetectTextRectanglesRequest()
        request.reportCharacterBoxes = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return [DetectedZone(zone: .ingredients, 
                                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                                   confidence: 1.0)]
            }
            
            print("📊 [ZoneDetector] Found \(observations.count) text blocks")
            
            // Analyze vertical distribution of text blocks
            let sortedByY = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            
            // Heuristic zone detection:
            // - Top 20%: Likely title/metadata
            // - Middle 40-50%: Likely ingredients (if text is list-like)
            // - Bottom 30-40%: Likely instructions (if text is paragraph-like)
            
//            let _: CGFloat = 1.0
            let topThreshold: CGFloat = 0.8  // Top 20% (Y coords are inverted in Vision)
            let middleThreshold: CGFloat = 0.4  // Middle zone
            
            var titleObservations: [VNTextObservation] = []
            var upperObservations: [VNTextObservation] = []
            var lowerObservations: [VNTextObservation] = []
            
            for obs in sortedByY {
                let midY = obs.boundingBox.midY
                
                if midY > topThreshold {
                    titleObservations.append(obs)
                } else if midY > middleThreshold {
                    upperObservations.append(obs)
                } else {
                    lowerObservations.append(obs)
                }
            }
            
            // Create zones based on text distribution
            if !titleObservations.isEmpty {
                let bounds = boundingRect(for: titleObservations)
                let expandedBounds = expandBounds(bounds, by: 0.05, within: CGRect(x: 0, y: 0, width: 1, height: 1))
                detectedZones.append(DetectedZone(
                    zone: .title,
                    bounds: expandedBounds,
                    confidence: 0.8
                ))
                print("   📍 Title zone: \(expandedBounds)")
            }
            
            if !upperObservations.isEmpty {
                let bounds = boundingRect(for: upperObservations)
                let expandedBounds = expandBounds(bounds, by: 0.05, within: CGRect(x: 0, y: 0, width: 1, height: 1))
                
                // Determine if this looks like ingredients (list-like) or instructions (paragraph-like)
                let isListLike = isListLayout(upperObservations)
                let zone: RecipeZone = isListLike ? .ingredients : .instructions
                
                detectedZones.append(DetectedZone(
                    zone: zone,
                    bounds: expandedBounds,
                    confidence: 0.7
                ))
                print("   📍 \(zone.rawValue) zone: \(expandedBounds)")
            }
            
            if !lowerObservations.isEmpty {
                let bounds = boundingRect(for: lowerObservations)
                let expandedBounds = expandBounds(bounds, by: 0.05, within: CGRect(x: 0, y: 0, width: 1, height: 1))
                
                // Lower zone is typically instructions
                detectedZones.append(DetectedZone(
                    zone: .instructions,
                    bounds: expandedBounds,
                    confidence: 0.7
                ))
                print("   📍 Instructions zone: \(expandedBounds)")
            }
            
        } catch {
            print("❌ [ZoneDetector] Error: \(error)")
            // Fallback: single zone
            return [DetectedZone(zone: .ingredients, 
                               bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                               confidence: 1.0)]
        }
        
        // If no zones detected, return full image as ingredients zone
        if detectedZones.isEmpty {
            detectedZones.append(DetectedZone(
                zone: .ingredients,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                confidence: 1.0
            ))
        }
        
        return detectedZones
    }
    
    // MARK: - Text Region Detection
    
    /// Detect text regions within a zone for focused OCR
    private func detectTextRegions(in image: UIImage) async -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNDetectTextRectanglesRequest()
        request.reportCharacterBoxes = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            // Return bounding boxes of detected text regions
            return observations.map { $0.boundingBox }
            
        } catch {
            print("❌ [TextRegionDetector] Error: \(error)")
            return []
        }
    }
    
    // MARK: - Image Enhancement
    
    /// Enhance image for optimal OCR performance
    private func enhanceForOCR(image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        var processedImage = ciImage
        
        // Step 1: Convert to grayscale if enabled
        if options.convertToGrayscale {
            if let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") {
                grayscaleFilter.setValue(processedImage, forKey: kCIInputImageKey)
                if let output = grayscaleFilter.outputImage {
                    processedImage = output
                }
            }
        }
        
        // Step 2: Enhance contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.3, forKey: kCIInputContrastKey)  // Increase contrast
            contrastFilter.setValue(1.0, forKey: kCIInputSaturationKey)
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 3: Sharpen
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.5, forKey: kCIInputSharpnessKey)
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 4: Denoise (reduce noise)
        if let denoiseFilter = CIFilter(name: "CINoiseReduction") {
            denoiseFilter.setValue(processedImage, forKey: kCIInputImageKey)
            denoiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            if let output = denoiseFilter.outputImage {
                processedImage = output
            }
        }
        
        // Step 5: Adaptive thresholding (if enabled)
        // This makes text stand out dramatically
        if options.applyThresholding {
            processedImage = applyAdaptiveThreshold(to: processedImage)
        }
        
        // Convert back to UIImage
        let extent = processedImage.extent
        guard let cgImage = ciContext.createCGImage(processedImage, from: extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Apply adaptive thresholding to make text highly visible
    private func applyAdaptiveThreshold(to image: CIImage) -> CIImage {
        // Create a local average using a blur
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(5.0, forKey: kCIInputRadiusKey)
        
        guard let blurred = blurFilter.outputImage else { return image }
        
        // Subtract the blurred version from the original (local contrast)
        guard let subtractFilter = CIFilter(name: "CISubtractBlendMode") else { return image }
        subtractFilter.setValue(image, forKey: kCIInputImageKey)
        subtractFilter.setValue(blurred, forKey: kCIInputBackgroundImageKey)
        
        guard let subtracted = subtractFilter.outputImage else { return image }
        
        // Apply a threshold
        guard let thresholdFilter = CIFilter(name: "CIColorControls") else { return subtracted }
        thresholdFilter.setValue(subtracted, forKey: kCIInputImageKey)
        thresholdFilter.setValue(2.0, forKey: kCIInputContrastKey)
        thresholdFilter.setValue(0.2, forKey: kCIInputBrightnessKey)
        
        return thresholdFilter.outputImage ?? subtracted
    }
    
    // MARK: - Deskewing
    
    /// Detect and correct image rotation/skew
    private func deskew(image: UIImage) async -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        // Use Vision to detect text rectangles and calculate skew angle
        let request = VNDetectTextRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results,
                  !observations.isEmpty else {
                return image
            }
            
            // Calculate average rotation angle from text lines
            var angles: [CGFloat] = []
            
            for observation in observations {
                // Calculate angle from bounding box
                let topLeft = observation.topLeft
                let topRight = observation.topRight
                
                let dx = topRight.x - topLeft.x
                let dy = topRight.y - topLeft.y
                let angle = atan2(dy, dx)
                angles.append(angle)
            }
            
            guard !angles.isEmpty else { return image }
            
            // Calculate median angle (more robust than mean)
            let sortedAngles = angles.sorted()
            let medianAngle = sortedAngles[sortedAngles.count / 2]
            
            // Only correct if angle is significant (> 0.5 degrees)
            let angleDegrees = medianAngle * 180 / .pi
            guard abs(angleDegrees) > 0.5 else {
                print("📐 [Deskew] Image is level (angle: \(String(format: "%.2f", angleDegrees))°)")
                return image
            }
            
            print("📐 [Deskew] Correcting skew angle: \(String(format: "%.2f", angleDegrees))°")
            
            // Rotate image to correct skew
            guard let ciImage = CIImage(image: image) else { return image }
            let rotated = ciImage.transformed(by: CGAffineTransform(rotationAngle: -medianAngle))
            
            guard let rotatedCGImage = ciContext.createCGImage(rotated, from: rotated.extent) else {
                return image
            }
            
            return UIImage(cgImage: rotatedCGImage, scale: image.scale, orientation: image.imageOrientation)
            
        } catch {
            print("❌ [Deskew] Error: \(error)")
            return image
        }
    }
    
    // MARK: - Zone Extraction
    
    /// Extract a specific zone from the image
    private func extractZone(from image: UIImage, zone: DetectedZone) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let pixelBounds = zone.pixelBounds(for: imageSize)
        
        // Vision coordinates are flipped vertically
        let flippedY = imageSize.height - pixelBounds.maxY
        let flippedBounds = CGRect(
            x: pixelBounds.origin.x,
            y: flippedY,
            width: pixelBounds.width,
            height: pixelBounds.height
        )
        
        // Ensure bounds are within image
        let clampedBounds = flippedBounds.intersection(
            CGRect(origin: .zero, size: imageSize)
        )
        
        guard !clampedBounds.isEmpty,
              let croppedImage = cgImage.cropping(to: clampedBounds) else {
            return nil
        }
        
        return UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Helper Functions
    
    /// Resize image maintaining aspect ratio
    private func resizeImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
        let size = image.size
        
        guard size.width > targetWidth else {
            return image
        }
        
        let ratio = targetWidth / size.width
        let targetSize = CGSize(width: targetWidth, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Calculate bounding rectangle that contains all observations
    private func boundingRect(for observations: [VNTextObservation]) -> CGRect {
        guard !observations.isEmpty else {
            return .zero
        }
        
        var minX: CGFloat = 1.0
        var minY: CGFloat = 1.0
        var maxX: CGFloat = 0.0
        var maxY: CGFloat = 0.0
        
        for obs in observations {
            let box = obs.boundingBox
            minX = min(minX, box.minX)
            minY = min(minY, box.minY)
            maxX = max(maxX, box.maxX)
            maxY = max(maxY, box.maxY)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// Expand bounds by a percentage (for padding)
    private func expandBounds(_ bounds: CGRect, by percentage: CGFloat, within container: CGRect) -> CGRect {
        let expandX = bounds.width * percentage
        let expandY = bounds.height * percentage
        
        let expanded = CGRect(
            x: bounds.origin.x - expandX,
            y: bounds.origin.y - expandY,
            width: bounds.width + (expandX * 2),
            height: bounds.height + (expandY * 2)
        )
        
        // Clamp to container
        return expanded.intersection(container)
    }
    
    /// Determine if text observations are arranged in a list (vs paragraph)
    private func isListLayout(_ observations: [VNTextObservation]) -> Bool {
        guard observations.count > 2 else { return false }
        
        // List characteristics:
        // - Similar X positions (aligned left)
        // - Similar heights
        // - Regular vertical spacing
        
        let xPositions = observations.map { $0.boundingBox.origin.x }
        let avgX = xPositions.reduce(0, +) / CGFloat(xPositions.count)
        
        var xVariance: CGFloat = 0
        for x in xPositions {
            let diff = x - avgX
            xVariance += diff * diff
        }
        xVariance /= CGFloat(xPositions.count)
        
        // If X variance is low, it's likely a list (aligned)
        let standardDeviation = sqrt(xVariance)
        
        print("   📊 Layout analysis: stdDev=\(String(format: "%.4f", standardDeviation))")
        
        // Threshold: if std dev < 0.05 (5% of image width), consider it a list
        return standardDeviation < 0.05
    }
}

// MARK: - Integration Helper

extension RecipeImagePreprocessor {
    
    /// Convenience method to preprocess and combine zones into a single image
    /// Useful for feeding into existing parsers that expect a single image
    func preprocessAndCombine(image: UIImage) async throws -> UIImage {
        let zones = try await preprocess(image: image)
        
        // Combine zones vertically into a single clean image
        guard !zones.isEmpty else {
            return image
        }
        
        // Calculate total height
        let maxWidth = zones.map { $0.image.size.width }.max() ?? 0
        let totalHeight = zones.map { $0.image.size.height }.reduce(0, +)
        
        let combinedSize = CGSize(width: maxWidth, height: totalHeight)
        
        let renderer = UIGraphicsImageRenderer(size: combinedSize)
        let combinedImage = renderer.image { context in
            var yOffset: CGFloat = 0
            
            for zone in zones {
                let zoneImage = zone.image
                let rect = CGRect(
                    x: 0,
                    y: yOffset,
                    width: zoneImage.size.width,
                    height: zoneImage.size.height
                )
                zoneImage.draw(in: rect)
                yOffset += zoneImage.size.height
                
                // Add separator between zones
                if yOffset < totalHeight {
                    context.cgContext.setStrokeColor(UIColor.systemGray5.cgColor)
                    context.cgContext.setLineWidth(2)
                    context.cgContext.move(to: CGPoint(x: 0, y: yOffset))
                    context.cgContext.addLine(to: CGPoint(x: maxWidth, y: yOffset))
                    context.cgContext.strokePath()
                    yOffset += 2
                }
            }
        }
        
        return combinedImage
    }
}
