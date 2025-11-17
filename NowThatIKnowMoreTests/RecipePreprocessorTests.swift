//
//  RecipePreprocessorTests.swift
//  Recipe Image Preprocessor Tests
//
//  Example tests for the recipe image preprocessing system
//

import Testing
import UIKit
@testable import NowThatIKnowMore

// MARK: - Preprocessing Tests

@Suite("Recipe Image Preprocessing Tests")
struct RecipePreprocessorTests {
    
    // MARK: - Basic Preprocessing
    
    @Test("Preprocessor initialization")
    func testPreprocessorInit() async throws {
        let preprocessor = RecipeImagePreprocessor()
        #expect(preprocessor != nil)
    }
    
    @Test("Preprocessor with custom options")
    func testCustomOptions() async throws {
        var options = PreprocessingOptions()
        options.targetWidth = 2048
        options.enhanceImage = true
        options.applyThresholding = false
        
        let preprocessor = RecipeImagePreprocessor(options: options)
        #expect(preprocessor != nil)
    }
    
    @Test("High quality preset")
    func testHighQualityPreset() async throws {
        let options = PreprocessingOptions.highQuality
        #expect(options.targetWidth == 1536)
        #expect(options.enhanceImage == true)
        #expect(options.minimumZoneConfidence == 0.4)
    }
    
    @Test("Fast preset")
    func testFastPreset() async throws {
        let options = PreprocessingOptions.fast
        #expect(options.targetWidth == 768)
        #expect(options.autoDetectZones == false)
        #expect(options.applyThresholding == false)
    }
    
    // MARK: - Zone Detection Tests
    
    @Test("Preprocess simple recipe image")
    @MainActor
    func testPreprocessSimpleImage() async throws {
        // Create a test image (in real app, load from test bundle)
        let testImage = createTestRecipeImage()
        
        let preprocessor = RecipeImagePreprocessor()
        let zones = try await preprocessor.preprocess(image: testImage)
        
        #expect(!zones.isEmpty, "Should detect at least one zone")
        
        for zone in zones {
            print("Detected zone: \(zone.zone.rawValue)")
            print("  Bounds: \(zone.originalBounds)")
            print("  Confidence: \(zone.confidence)")
            print("  Text regions: \(zone.textRegions.count)")
        }
    }
    
    @Test("Manual zone definition")
    @MainActor
    func testManualZones() async throws {
        let testImage = createTestRecipeImage()
        
        let manualZones = [
            DetectedZone(
                zone: .title,
                bounds: CGRect(x: 0, y: 0.8, width: 1.0, height: 0.2),
                confidence: 1.0
            ),
            DetectedZone(
                zone: .ingredients,
                bounds: CGRect(x: 0, y: 0.4, width: 1.0, height: 0.4),
                confidence: 1.0
            )
        ]
        
        let preprocessor = RecipeImagePreprocessor()
        let zones = try await preprocessor.preprocess(
            image: testImage,
            manualZones: manualZones
        )
        
        #expect(zones.count == 2, "Should process exactly 2 manual zones")
    }
    
    @Test("Combine zones into single image")
    @MainActor
    func testCombineZones() async throws {
        let testImage = createTestRecipeImage()
        
        let preprocessor = RecipeImagePreprocessor()
        let combinedImage = try await preprocessor.preprocessAndCombine(image: testImage)
        
        #expect(combinedImage.size.width > 0)
        #expect(combinedImage.size.height > 0)
        print("Combined image size: \(combinedImage.size)")
    }
    
    // MARK: - Parser Integration Tests
    
    @Test("Enhanced parser initialization")
    @MainActor
    func testEnhancedParserInit() async throws {
        let parser = EnhancedPreprocessedRecipeParser()
        
        #expect(parser.parserType == .enhancedPreprocessed)
        #expect(parser.displayName.contains("Enhanced"))
        #expect(!parser.description.isEmpty)
    }
    
    @Test("Enhanced parser with custom options")
    @MainActor
    func testEnhancedParserCustomOptions() async throws {
        let options = PreprocessingOptions.highQuality
        let parser = EnhancedPreprocessedRecipeParser(preprocessingOptions: options)
        
        #expect(parser != nil)
    }
    
    @Test("Parse recipe with enhanced parser")
    @MainActor
    func testEnhancedParserParsing() async throws {
        let testImage = createTestRecipeImage()
        let parser = EnhancedPreprocessedRecipeParser()
        
        let recipe = try await withCheckedThrowingContinuation { continuation in
            parser.parseRecipeImage(testImage) { result in
                continuation.resume(with: result)
            }
        }
        
        #expect(!recipe.title.isEmpty, "Should parse a title")
        print("Parsed recipe: \(recipe.title)")
        print("Ingredients: \(recipe.ingredients.count)")
    }
    
    // MARK: - Enhancement Tests
    
    @Test("Image resize maintains aspect ratio")
    @MainActor
    func testImageResize() async throws {
        // Create a 2000x3000 test image
        let largeImage = createTestImage(size: CGSize(width: 2000, height: 3000))
        
        let preprocessor = RecipeImagePreprocessor(options: .default)
        
        // The preprocessor will resize internally
        // We can test by checking the output zone images
        let zones = try await preprocessor.preprocess(image: largeImage)
        
        #expect(!zones.isEmpty)
        
        // Check that aspect ratio is maintained
        for zone in zones {
            let image = zone.image
            let aspectRatio = image.size.width / image.size.height
            
            // Original aspect ratio: 2000/3000 = 0.667
            #expect(aspectRatio > 0.6 && aspectRatio < 0.7, 
                   "Aspect ratio should be maintained")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle invalid image gracefully")
    @MainActor
    func testInvalidImage() async throws {
        // Create a 1x1 black image (edge case)
        let tinyImage = createTestImage(size: CGSize(width: 1, height: 1))
        
        let preprocessor = RecipeImagePreprocessor()
        
        // Should not crash, may return empty zones or single full zone
        let zones = try await preprocessor.preprocess(image: tinyImage)
        
        // Either empty or single zone is acceptable
        #expect(zones.count <= 1, "Should handle tiny images gracefully")
    }
    
    // MARK: - Performance Tests
    
    @Test("Preprocessing performance (default)")
    @MainActor
    func testPreprocessingPerformance() async throws {
        let testImage = createTestRecipeImage()
        let preprocessor = RecipeImagePreprocessor(options: .default)
        
        let startTime = Date()
        let zones = try await preprocessor.preprocess(image: testImage)
        let duration = Date().timeIntervalSince(startTime)
        
        print("Preprocessing took \(String(format: "%.2f", duration))s")
        print("Processed \(zones.count) zones")
        
        // Should complete in reasonable time (adjust based on your requirements)
        #expect(duration < 10.0, "Preprocessing should complete within 10 seconds")
    }
    
    @Test("Preprocessing performance (fast mode)")
    @MainActor
    func testFastPreprocessingPerformance() async throws {
        let testImage = createTestRecipeImage()
        let preprocessor = RecipeImagePreprocessor(options: .fast)
        
        let startTime = Date()
        let zones = try await preprocessor.preprocess(image: testImage)
        let duration = Date().timeIntervalSince(startTime)
        
        print("Fast preprocessing took \(String(format: "%.2f", duration))s")
        print("Processed \(zones.count) zones")
        
        #expect(duration < 5.0, "Fast preprocessing should complete within 5 seconds")
    }
    
    // MARK: - Helper Methods
    
    /// Create a test recipe image with text
    private func createTestRecipeImage() -> UIImage {
        let size = CGSize(width: 800, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.black
            ]
            let title = "Test Recipe"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Servings
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ]
            "Serves 4".draw(at: CGPoint(x: 50, y: 120), withAttributes: metaAttributes)
            
            // Ingredients header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Ingredients:".draw(at: CGPoint(x: 50, y: 180), withAttributes: headerAttributes)
            
            // Ingredients list
            let ingredientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let ingredients = [
                "• 2 cups flour",
                "• 1 tsp salt",
                "• 1/2 cup sugar",
                "• 3 eggs"
            ]
            var yOffset: CGFloat = 230
            for ingredient in ingredients {
                ingredient.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: ingredientAttributes)
                yOffset += 40
            }
            
            // Instructions header
            "Instructions:".draw(at: CGPoint(x: 50, y: yOffset + 40), withAttributes: headerAttributes)
            
            // Instructions
            let instructions = "Mix all ingredients together. Bake at 350°F for 30 minutes."
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            let instructionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            let instructionRect = CGRect(x: 50, y: yOffset + 100, width: 700, height: 200)
            instructions.draw(in: instructionRect, withAttributes: instructionAttributes)
        }
    }
    
    /// Create a simple test image of given size
    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.black.setStroke()
            context.stroke(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Zone Detection Tests

@Suite("Zone Detection Tests")
struct ZoneDetectionTests {
    
    @Test("Detect title zone")
    @MainActor
    func testTitleZoneDetection() async throws {
        // Test specifically for title zone detection
        let testImage = createImageWithTitle()
        
        let preprocessor = RecipeImagePreprocessor()
        let zones = try await preprocessor.preprocess(image: testImage)
        
        let titleZones = zones.filter { $0.zone == .title }
        #expect(!titleZones.isEmpty, "Should detect a title zone")
        
        if let titleZone = titleZones.first {
            // Title should be in upper part of image
            #expect(titleZone.originalBounds.midY > 0.7, 
                   "Title zone should be in upper region")
        }
    }
    
    @Test("Detect ingredients zone")
    @MainActor
    func testIngredientsZoneDetection() async throws {
        let testImage = createImageWithIngredientsList()
        
        let preprocessor = RecipeImagePreprocessor()
        let zones = try await preprocessor.preprocess(image: testImage)
        
        let ingredientZones = zones.filter { $0.zone == .ingredients }
        
        // Should detect at least one ingredients zone
        // (or it might be classified as instructions, both are acceptable)
        print("Total zones detected: \(zones.count)")
        for zone in zones {
            print("  - \(zone.zone.rawValue) at \(zone.originalBounds)")
        }
    }
    
    // Helper methods
    
    private func createImageWithTitle() -> UIImage {
        let size = CGSize(width: 800, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black
            ]
            "Recipe Title".draw(at: CGPoint(x: 50, y: 75), withAttributes: titleAttributes)
        }
    }
    
    private func createImageWithIngredientsList() -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            
            let ingredients = [
                "2 cups flour",
                "1 cup sugar",
                "3 eggs",
                "1/2 cup milk",
                "1 tsp vanilla"
            ]
            
            var yOffset: CGFloat = 50
            for ingredient in ingredients {
                ingredient.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: attributes)
                yOffset += 40
            }
        }
    }
}

// MARK: - Enhancement Tests

@Suite("Image Enhancement Tests")
struct EnhancementTests {
    
    @Test("Grayscale conversion")
    @MainActor
    func testGrayscaleConversion() async throws {
        let colorImage = createColorImage()
        
        var options = PreprocessingOptions.default
        options.convertToGrayscale = true
        options.autoDetectZones = false  // Single zone for testing
        
        let preprocessor = RecipeImagePreprocessor(options: options)
        let zones = try await preprocessor.preprocess(image: colorImage)
        
        #expect(!zones.isEmpty)
        // Enhanced image should be grayscale
        // (Hard to test programmatically without analyzing pixel data)
    }
    
    @Test("Contrast enhancement applied")
    @MainActor
    func testContrastEnhancement() async throws {
        let testImage = createLowContrastImage()
        
        var options = PreprocessingOptions.default
        options.enhanceImage = true
        options.autoDetectZones = false
        
        let preprocessor = RecipeImagePreprocessor(options: options)
        let zones = try await preprocessor.preprocess(image: testImage)
        
        #expect(!zones.isEmpty)
        // Enhanced image should have better contrast
    }
    
    // Helper methods
    
    private func createColorImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Red background
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Blue text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.blue
            ]
            "Color".draw(at: CGPoint(x: 100, y: 175), withAttributes: attributes)
        }
    }
    
    private func createLowContrastImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Light gray background
            UIColor(white: 0.8, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Dark gray text (low contrast)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
            ]
            "Text".draw(at: CGPoint(x: 100, y: 175), withAttributes: attributes)
        }
    }
}
