//
//  PDFRecipeCreator.swift
//  NowThatIKnowMore
//
//  Utility to create sample PDF recipes for testing the PDF parser
//  Demonstrates creating multi-column recipe PDFs programmatically
//

import UIKit
import PDFKit

struct PDFRecipeCreator {
    
    /// Creates a sample multi-column recipe PDF for testing
    static func createSampleRecipePDF() -> PDFDocument? {
        // Create a PDF context
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Title
            let titleText = "Spicy Chicken Curry"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            titleText.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Servings
            let servingsText = "Serves 4"
            let bodyFont = UIFont.systemFont(ofSize: 14)
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.darkGray
            ]
            servingsText.draw(at: CGPoint(x: 50, y: 90), withAttributes: bodyAttributes)
            
            // Ingredients Header
            let ingredientsHeader = "Ingredients"
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ]
            ingredientsHeader.draw(at: CGPoint(x: 50, y: 130), withAttributes: headerAttributes)
            
            // Multi-column ingredient layout
            let ingredients = [
                ("2 lbs", "chicken thighs, cubed", "1 kg"),
                ("3 tbsp", "curry powder", "45 ml"),
                ("1 cup", "coconut milk", "250 ml"),
                ("2 tbsp", "vegetable oil", "30 ml"),
                ("1 large", "onion, diced", ""),
                ("4 cloves", "garlic, minced", ""),
                ("1 tsp", "ginger, grated", "5 ml"),
                ("2 cups", "tomatoes, diced", "500 g"),
                ("1 tsp", "salt", "5 ml"),
                ("½ tsp", "black pepper", "2.5 ml"),
                ("2 tbsp", "fresh cilantro", "30 ml")
            ]
            
            var yOffset: CGFloat = 170
            let lineHeight: CGFloat = 25
            
            // Column positions
            let imperialX: CGFloat = 60
            let ingredientX: CGFloat = 160
            let metricX: CGFloat = 360
            
            for (imperial, ingredient, metric) in ingredients {
                // Imperial amount (left column)
                imperial.draw(at: CGPoint(x: imperialX, y: yOffset), withAttributes: bodyAttributes)
                
                // Ingredient name (middle column)
                ingredient.draw(at: CGPoint(x: ingredientX, y: yOffset), withAttributes: bodyAttributes)
                
                // Metric amount (right column)
                if !metric.isEmpty {
                    metric.draw(at: CGPoint(x: metricX, y: yOffset), withAttributes: bodyAttributes)
                }
                
                yOffset += lineHeight
            }
            
            // Instructions Header
            yOffset += 30
            let instructionsHeader = "Instructions"
            instructionsHeader.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: headerAttributes)
            
            // Instructions
            yOffset += 40
            let instructions = """
            1. Heat oil in a large skillet over medium-high heat.
            
            2. Add onion and sauté until softened, about 5 minutes.
            
            3. Add garlic and ginger, cook for 1 minute until fragrant.
            
            4. Add chicken and brown on all sides, about 8 minutes.
            
            5. Stir in curry powder and cook for 1 minute.
            
            6. Add tomatoes and coconut milk. Bring to a simmer.
            
            7. Reduce heat and simmer for 20 minutes until chicken is cooked through.
            
            8. Season with salt and pepper. Garnish with cilantro.
            
            9. Serve hot with rice or naan bread.
            """
            
            let instructionParagraphStyle = NSMutableParagraphStyle()
            instructionParagraphStyle.lineSpacing = 8
            
            let instructionAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: instructionParagraphStyle
            ]
            
            let instructionRect = CGRect(x: 60, y: yOffset, width: 500, height: 400)
            instructions.draw(in: instructionRect, withAttributes: instructionAttributes)
        }
        
        return PDFDocument(data: data)
    }
    
    /// Creates a simple single-column recipe PDF
    static func createSimpleRecipePDF() -> PDFDocument? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let bodyFont = UIFont.systemFont(ofSize: 14)
            
            var yOffset: CGFloat = 50
            
            // Title
            "Classic Chocolate Chip Cookies".draw(
                at: CGPoint(x: 50, y: yOffset),
                withAttributes: [.font: titleFont]
            )
            yOffset += 40
            
            // Servings
            "Makes 24 cookies".draw(
                at: CGPoint(x: 50, y: yOffset),
                withAttributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            )
            yOffset += 40
            
            // Ingredients
            "Ingredients:".draw(
                at: CGPoint(x: 50, y: yOffset),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)]
            )
            yOffset += 30
            
            let ingredients = [
                "- 2¼ cups all-purpose flour",
                "- 1 tsp baking soda",
                "- 1 tsp salt",
                "- 1 cup butter, softened",
                "- ¾ cup granulated sugar",
                "- ¾ cup packed brown sugar",
                "- 2 large eggs",
                "- 2 tsp vanilla extract",
                "- 2 cups chocolate chips"
            ]
            
            for ingredient in ingredients {
                ingredient.draw(
                    at: CGPoint(x: 60, y: yOffset),
                    withAttributes: [.font: bodyFont]
                )
                yOffset += 25
            }
            
            yOffset += 20
            
            // Instructions
            "Instructions:".draw(
                at: CGPoint(x: 50, y: yOffset),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)]
            )
            yOffset += 30
            
            let instructions = """
            1. Preheat oven to 375°F (190°C).
            
            2. Mix flour, baking soda, and salt in a bowl.
            
            3. Beat butter and both sugars until creamy.
            
            4. Add eggs and vanilla, beat well.
            
            5. Gradually stir in flour mixture.
            
            6. Fold in chocolate chips.
            
            7. Drop rounded tablespoons onto ungreased cookie sheets.
            
            8. Bake 9-11 minutes until golden brown.
            
            9. Cool on baking sheets for 2 minutes, then transfer to wire racks.
            """
            
            let rect = CGRect(x: 60, y: yOffset, width: 500, height: 400)
            instructions.draw(in: rect, withAttributes: [.font: bodyFont])
        }
        
        return PDFDocument(data: data)
    }
    
    /// Save a PDF document to the app's documents directory
    static func savePDF(_ document: PDFDocument, filename: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        if document.write(to: fileURL) {
            print("✅ PDF saved to: \(fileURL.path)")
            return fileURL
        } else {
            print("❌ Failed to save PDF")
            return nil
        }
    }
    
    /// Load a saved PDF from documents directory
    static func loadPDF(filename: String) -> PDFDocument? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        if let document = PDFDocument(url: fileURL) {
            print("✅ PDF loaded from: \(fileURL.path)")
            return document
        } else {
            print("❌ Failed to load PDF")
            return nil
        }
    }
}

// MARK: - SwiftUI Preview Helper

#if DEBUG
import SwiftUI

struct PDFPreviewView: View {
    let document: PDFDocument
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<document.pageCount, id: \.self) { pageIndex in
                    if let page = document.page(at: pageIndex) {
                        let image = page.thumbnail(of: CGSize(width: 400, height: 600), for: .cropBox)
                        VStack {
                            Text("Page \(pageIndex + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 400)
                                .border(Color.gray, width: 1)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("PDF Preview")
    }
}

struct PDFCreatorTestView: View {
    @State private var samplePDF: PDFDocument?
    @State private var simplePDF: PDFDocument?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Multi-Column Recipe (Complex)") {
                    Button("Create Sample PDF") {
                        samplePDF = PDFRecipeCreator.createSampleRecipePDF()
                        if let pdf = samplePDF {
                            _ = PDFRecipeCreator.savePDF(pdf, filename: "sample_curry_recipe.pdf")
                        }
                    }
                    
                    if let pdf = samplePDF {
                        NavigationLink("View PDF") {
                            PDFPreviewView(document: pdf)
                        }
                    }
                }
                
                Section("Single-Column Recipe (Simple)") {
                    Button("Create Simple PDF") {
                        simplePDF = PDFRecipeCreator.createSimpleRecipePDF()
                        if let pdf = simplePDF {
                            _ = PDFRecipeCreator.savePDF(pdf, filename: "simple_cookie_recipe.pdf")
                        }
                    }
                    
                    if let pdf = simplePDF {
                        NavigationLink("View PDF") {
                            PDFPreviewView(document: pdf)
                        }
                    }
                }
                
                Section("Test Parsing") {
                    NavigationLink("Open PDF Parser") {
                        RecipePDFParserView()
                    }
                }
            }
            .navigationTitle("PDF Recipe Creator")
        }
    }
}

#Preview("PDF Creator Test") {
    PDFCreatorTestView()
}
#endif
