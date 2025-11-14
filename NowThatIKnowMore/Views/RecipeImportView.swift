//
//  RecipeImportView.swift
//  NowThatIKnowMore
//
//  Recipe import functionality for receiving recipes via email or file sharing
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers
@preconcurrency import PDFKit

struct RecipeImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var importedRecipe: RecipeModel?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isParsingPDF = false
    @State private var pdfParseProgress = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Import Recipe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Import recipes from JSON files shared by other users, or parse PDF recipe documents.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Show parsing progress for PDFs
                if isParsingPDF {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(pdfParseProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Button(action: {
                    isImporting = true
                }) {
                    Label("Choose Recipe File", systemImage: "doc")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if let recipe = importedRecipe {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        
                        Text("Preview")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title ?? "Untitled Recipe")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let credits = recipe.creditsText, !credits.isEmpty {
                                Text(credits)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let servings = recipe.servings {
                                HStack {
                                    Image(systemName: "person.2")
                                    Text("Serves \(servings)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                                Text("\(ingredients.count) ingredients")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button(action: {
                            importRecipe(recipe)
                        }) {
                            Label("Import This Recipe", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [
                    .json,
                    .pdf,
                    UTType(filenameExtension: "recipe") ?? .json
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Error"
                alertMessage = "Unable to access the file."
                showAlert = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Determine file type
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                // Handle PDF import
                handlePDFImport(from: url)
            } else {
                // Handle JSON import
                handleJSONImport(from: url)
            }
            
        case .failure(let error):
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func handleJSONImport(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            
            // Try to decode as RecipeModel
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let recipe = try decoder.decode(RecipeModel.self, from: data)
            importedRecipe = recipe
        } catch {
            alertTitle = "Error"
            alertMessage = "Unable to parse recipe file: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func handlePDFImport(from url: URL) {
        print("📄 [RecipeImportView] Starting PDF import from: \(url.lastPathComponent)")
        
        isParsingPDF = true
        pdfParseProgress = "Loading PDF..."
        
        // Load PDF document
        guard let pdfDocument = PDFDocument(url: url) else {
            isParsingPDF = false
            alertTitle = "Error"
            alertMessage = "Unable to load PDF document."
            showAlert = true
            return
        }
        
        print("📄 [RecipeImportView] PDF loaded with \(pdfDocument.pageCount) page(s)")
        pdfParseProgress = "Parsing recipe from PDF..."
        
        // Parse PDF using Task for proper concurrency
        Task {
            let parser = await MainActor.run {
                RecipePDFParser(columnStrategy: .columnAware, debugMode: true)
            }
            
            let result = await withCheckedContinuation { continuation in
                parser.parsePDF(pdfDocument) { result in
                    continuation.resume(returning: result)
                }
            }
            
            await MainActor.run {
                self.isParsingPDF = false
                
                switch result {
                case .success(let parsedRecipe):
                    print("✅ [RecipeImportView] PDF parsed successfully: '\(parsedRecipe.title)'")
                    print("   Ingredients: \(parsedRecipe.ingredients.count)")
                    
                    // Convert ParsedRecipe to RecipeModel
                    let recipeModel = self.convertParsedRecipeToModel(parsedRecipe)
                    self.importedRecipe = recipeModel
                    
                case .failure(let error):
                    print("❌ [RecipeImportView] PDF parse failed: \(error.localizedDescription)")
                    self.alertTitle = "PDF Parse Error"
                    self.alertMessage = "Could not extract recipe from PDF: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func convertParsedRecipeToModel(_ parsedRecipe: ParsedRecipe) -> RecipeModel {
        print("🔄 [RecipeImportView] Converting ParsedRecipe to RecipeModel")
        
        // Convert ParsedIngredient array to ExtendedIngredient array
        var extendedIngredients: [ExtendedIngredient] = []
        
        for (index, ingredient) in parsedRecipe.ingredients.enumerated() {
            // Try to parse amount from imperial amount string
            let amountValue = parseAmount(from: ingredient.imperialAmount)
            let unit = extractUnit(from: ingredient.imperialAmount)
            
            // Create measures if we have metric info
            var measures: Measures?
            if let metricStr = ingredient.metricAmount {
                let metricAmount = parseAmount(from: metricStr)
                let metricUnit = extractUnit(from: metricStr)
                
                measures = Measures(
                    us: Metric(amount: amountValue, unitShort: unit, unitLong: unit),
                    metric: Metric(amount: metricAmount, unitShort: metricUnit, unitLong: metricUnit)
                )
            } else {
                measures = Measures(
                    us: Metric(amount: amountValue, unitShort: unit, unitLong: unit),
                    metric: nil
                )
            }
            
            let extended = ExtendedIngredient(
                id: index,
                aisle: nil,
                image: nil,
                consistency: nil,
                name: ingredient.name,
                nameClean: ingredient.name.lowercased(),
                original: "\(ingredient.imperialAmount) \(ingredient.name)".trimmingCharacters(in: .whitespaces),
                originalName: ingredient.name,
                amount: amountValue,
                unit: unit,
                meta: nil,
                measures: measures
            )
            
            extendedIngredients.append(extended)
        }
        
        // Encode ingredients to JSON
        let ingredientsData = try? JSONEncoder().encode(extendedIngredients)
        
        // Create RecipeModel
        let recipe = RecipeModel(
            uuid: UUID(),
            id: nil,
            image: nil,
            imageType: nil,
            title: parsedRecipe.title,
            servings: parseServings(from: parsedRecipe.servings),
            sourceURL: nil,
            instructions: parsedRecipe.instructions,
            cuisinesString: nil,
            dishTypesString: nil,
            dietsString: nil,
            occasionsString: nil,
            daysOfWeekString: nil,
            extendedIngredientsJSON: ingredientsData,
            analyzedInstructionsJSON: nil,
            featuredMediaID: nil,
            preferFeaturedMedia: false
        )
        
        print("✅ [RecipeImportView] RecipeModel created")
        return recipe
    }
    
    /// Parse numeric amount from a string like "2 cups" or "1.5"
    private func parseAmount(from text: String) -> Double? {
        let components = text.split(separator: " ")
        guard let firstComponent = components.first else { return nil }
        
        let cleaned = String(firstComponent).trimmingCharacters(in: CharacterSet(charactersIn: "(),[]"))
        
        // Handle fractions
        if cleaned.contains("/") {
            let parts = cleaned.split(separator: "/")
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Handle unicode fractions
        let fractionMap: [Character: Double] = [
            "½": 0.5, "¼": 0.25, "¾": 0.75,
            "⅓": 0.333, "⅔": 0.667,
            "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
        ]
        
        for (char, value) in fractionMap {
            if cleaned.contains(char) {
                return value
            }
        }
        
        // Try direct conversion
        return Double(cleaned)
    }
    
    /// Extract unit from a string like "2 cups" -> "cups"
    private func extractUnit(from text: String) -> String {
        let components = text.split(separator: " ")
        if components.count >= 2 {
            return String(components[1])
        }
        return ""
    }
    
    /// Parse servings number from text like "Serves 4" or "Makes 6"
    private func parseServings(from text: String?) -> Int? {
        guard let text = text else { return nil }
        
        // Extract first number found
        let pattern = "\\d+"
        if let range = text.range(of: pattern, options: .regularExpression) {
            let numberStr = String(text[range])
            return Int(numberStr)
        }
        
        return nil
    }
    
    private func importRecipe(_ recipe: RecipeModel) {
        // Check if recipe already exists
        if swiftDataRecipes.first(where: { $0.uuid == recipe.uuid }) != nil {
            alertTitle = "Already Exists"
            alertMessage = "A recipe with this ID already exists in your collection."
            showAlert = true
            return
        }
        
        // Convert Recipe to RecipeModel
        // Convert cuisines, dishTypes, diets, occasions from JSONAny arrays to comma-separated strings
        let cuisinesString = recipe.cuisines.compactMap { $0 }.joined(separator: ",")
        let dishTypesString = recipe.dishTypes.compactMap { $0 }.joined(separator: ",")
        let dietsString = recipe.diets.compactMap { $0 }.joined(separator: ",")
        let occasionsString = recipe.occasions.compactMap { $0 }.joined(separator: ",")
        let daysOfWeekString = recipe.daysOfWeek.joined(separator: ",")
        
        // Encode extendedIngredients and analyzedInstructions to JSON
        let ingredientsData = try? JSONEncoder().encode(recipe.extendedIngredients)
        let instructionsData = try? JSONEncoder().encode(recipe.analyzedInstructions)
        
        let recipeModel = RecipeModel(
            uuid: recipe.uuid,
            id: recipe.id,
            image: recipe.image,
            imageType: recipe.imageType,
            title: recipe.title ?? "Untitled Recipe",
            servings: recipe.servings,
            sourceURL: recipe.sourceURL,
            vegetarian: recipe.vegetarian,
            vegan: recipe.vegan,
            glutenFree: recipe.glutenFree,
            dairyFree: recipe.dairyFree,
            veryHealthy: recipe.veryHealthy,
            cheap: recipe.cheap,
            veryPopular: recipe.veryPopular,
            sustainable: recipe.sustainable,
            lowFodmap: recipe.lowFodmap,
            weightWatcherSmartPoints: recipe.weightWatcherSmartPoints,
            gaps: recipe.gaps,
            aggregateLikes: recipe.aggregateLikes,
            healthScore: recipe.healthScore,
            creditsText: recipe.creditsText,
            sourceName: recipe.sourceName,
            pricePerServing: recipe.pricePerServing,
            summary: recipe.summary,
            instructions: recipe.instructions,
            spoonacularScore: recipe.spoonacularScore,
            spoonacularSourceURL: recipe.spoonacularSourceURL,
            cuisinesString: cuisinesString,
            dishTypesString: dishTypesString,
            dietsString: dietsString,
            occasionsString: occasionsString,
            daysOfWeekString: daysOfWeekString,
            extendedIngredientsJSON: ingredientsData,
            analyzedInstructionsJSON: instructionsData,
            featuredMediaID: recipe.featuredMediaID,
            preferFeaturedMedia: recipe.preferFeaturedMedia
        )
        
        // Migrate media items if any
        if let mediaItems = recipe.mediaItems {
            for media in mediaItems {
                // Convert legacy MediaType to RecipeMediaModel.MediaType
                let mediaType: RecipeMediaModel.MediaType = switch media.type {
                case .photo: .photo
                case .video: .video
                }
                
                let mediaModel = RecipeMediaModel(
                    uuid: media.uuid,
                    fileURL: media.fileURL,
                    thumbnailURL: media.thumbnailURL,
                    caption: media.caption,
                    type: mediaType,
                    recipe: recipeModel
                )
                modelContext.insert(mediaModel)
            }
        }
        
        modelContext.insert(recipeModel)
        
        do {
            try modelContext.save()
            alertTitle = "Success"
            alertMessage = "Recipe '\(recipe.title ?? "Untitled")' has been imported successfully!"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save recipe: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    return RecipeImportView()
        .modelContainer(container)
}
