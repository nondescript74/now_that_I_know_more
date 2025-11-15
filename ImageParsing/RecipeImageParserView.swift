//
//  RecipeImageParserView.swift
//  Recipe Image Parser
//
//  SwiftUI interface for capturing and parsing recipe images
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeImageParserView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedImage: UIImage?
    @State private var parsedRecipe: ParsedRecipe?
    @State private var parsedRecipeModel: RecipeModel?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showSuccessAlert = false
    @State private var selectedParserType: RecipeParserType = .tableFormat
    @State private var showBoundingBoxEditor = false
    @State private var definedRegions: [OCRRegion] = []
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Image Display Section
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else {
                        placeholderView
                    }
                    
                    // Parser Selection (only show available parsers)
                    if RecipeParserFactory.availableParsers.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parser Type")
                                .font(.headline)
                            
                            Picker("Parser Type", selection: $selectedParserType) {
                                ForEach(RecipeParserFactory.availableParsers, id: \.self) { parserType in
                                    Text(parserType.displayName).tag(parserType)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            // Show description of selected parser
                            let parser = RecipeParserFactory.parser(for: selectedParserType)
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.accentColor)
                                    .font(.caption)
                                
                                Text(parser.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 4)
                            
                            // Visual guide for each parser type
                            parserGuideView(for: selectedParserType)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 15) {
                        Button(action: { showImagePicker = true }) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showCamera = true }) {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    // Parse Button
                    if selectedImage != nil {
                        VStack(spacing: 10) {
                            Button(action: {
                                print("🎯 [RecipeImageParserView] Define Regions button TAPPED")
                                showBoundingBoxEditor = true
                            }) {
                                Label("Define Regions (Advanced)", systemImage: "rectangle.3.group")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.bordered)
                            .padding(.horizontal)
                            
                            // Help text for Define Regions feature
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.accentColor)
                                    .font(.caption2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Draw boxes around recipe sections for better accuracy")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("Use pinch to zoom, slider to adjust size, mini-map to navigate")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                            
                            Button(action: {
                                print("🔘 [RecipeImageParserView] Parse button TAPPED")
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                parseImage()
                            }) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                    Text("Parsing...")
                                        .foregroundColor(.white)
                                } else {
                                    Label("Parse Recipe", systemImage: "doc.text.magnifyingglass")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                        .padding(.horizontal)
                        }
                    }
                    
                    // Error Display
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Parsed Recipe Display
                    if let recipe = parsedRecipeModel {
                        ParsedRecipeDisplayView(recipe: recipe, sourceImage: selectedImage, showSuccessAlert: $showSuccessAlert)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showImagePicker) {
                RecipeImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                RecipeImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .alert("Recipe Saved", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The recipe has been saved to your collection.")
            }
            .fullScreenCover(isPresented: $showBoundingBoxEditor) {
                if let image = selectedImage {
                    RecipeOCRBoundingBoxEditor(
                        image: image,
                        onComplete: { regions in
                            definedRegions = regions
                            showBoundingBoxEditor = false
                            parseImageWithRegions(regions)
                        },
                        onCancel: {
                            showBoundingBoxEditor = false
                        }
                    )
                }
            }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 15) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Select a recipe image to parse")
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func parseImage() {
        guard let image = selectedImage else { 
            errorMessage = "No image selected"
            return 
        }
        
        print("🚀 [RecipeImageParserView] Starting to parse image...")
        print("🖼️ Original image: \(image.size.width)x\(image.size.height) @ \(image.scale)x scale")
        
        isProcessing = true
        errorMessage = nil
        parsedRecipe = nil
        parsedRecipeModel = nil
        
        let resizedImage = resizeImageIfNeeded(image)
        if image !== resizedImage {
            print("📐 Resized to: \(resizedImage.size.width)x\(resizedImage.size.height)")
        }
        
        var hasCompleted = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
            if !hasCompleted {
                print("⏰ [RecipeImageParserView] Parse operation timed out after 30 seconds")
                isProcessing = false
                errorMessage = "Parsing timed out. The image may be too large or complex. Try a smaller or clearer image."
            }
        }
        
        let parser = RecipeParserFactory.parser(for: selectedParserType)
        print("📦 [RecipeImageParserView] Using parser: \(type(of: parser))")
        
        parser.parseRecipeImage(resizedImage) { result in
            DispatchQueue.main.async { [self] in
                guard !hasCompleted else {
                    print("⚠️ [RecipeImageParserView] Completion called after timeout")
                    return
                }
                hasCompleted = true
                isProcessing = false
                
                switch result {
                case .success(let parsed):
                    print("✅ [RecipeImageParserView] Parse successful!")
                    print("   Title: \(parsed.title)")
                    print("   Ingredients: \(parsed.ingredients.count)")
                    parsedRecipe = parsed
                    parsedRecipeModel = ParsedRecipeAdapter.convertToRecipeModel(parsed)
                    print("✅ [RecipeImageParserView] Converted to RecipeModel")
                case .failure(let error):
                    print("❌ [RecipeImageParserView] Parse failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat = 512) -> UIImage {
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        guard maxSize > maxDimension else {
            return image
        }
        
        let ratio = maxDimension / maxSize
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    // MARK: - Parse with Defined Regions
    
    private func parseImageWithRegions(_ regions: [OCRRegion]) {
        print("🎯 [RecipeImageParserView] Parsing with \(regions.count) user-defined regions")
        
        // Build a ParsedRecipe from the regions
        var title = ""
        var servingsText: String? = nil
        var ingredients: [ParsedIngredient] = []
        var instructions = ""
        
        for region in regions {
            switch region.type {
            case .title:
                title = region.text
                print("📝 Title: \(title)")
                
            case .servings:
                servingsText = region.text
                print("👥 Servings: \(servingsText ?? "none")")
                
            case .ingredients:
                // Use the grouped ingredients
                if !region.ingredientGroups.isEmpty {
                    for group in region.ingredientGroups {
                        let ingredientText = group.map { $0.text }.joined(separator: " ")
                        let parsed = ParsedIngredient(
                            imperialAmount: "",
                            name: ingredientText,
                            metricAmount: nil
                        )
                        ingredients.append(parsed)
                        print("🥕 Ingredient: \(ingredientText)")
                    }
                } else {
                    // Fall back to all text
                    let ingredientText = region.text
                    let parsed = ParsedIngredient(
                        imperialAmount: "",
                        name: ingredientText,
                        metricAmount: nil
                    )
                    ingredients.append(parsed)
                }
                
            case .instructions:
                instructions = region.text
                print("📖 Instructions: \(instructions)")
                
            case .notes:
                // Could append to instructions or summary
                if !instructions.isEmpty {
                    instructions += "\n\n" + region.text
                } else {
                    instructions = region.text
                }
                
            case .ignore:
                // Skip
                continue
            }
        }
        
        // Create ParsedRecipe
        let parsedResult = ParsedRecipe(
            title: title,
            servings: servingsText,
            ingredients: ingredients,
            instructions: instructions
        )
        
        DispatchQueue.main.async {
            self.parsedRecipe = parsedResult
            self.parsedRecipeModel = ParsedRecipeAdapter.convertToRecipeModel(parsedResult)
            print("✅ [RecipeImageParserView] Created recipe from regions")
        }
    }
    
    // MARK: - Parser Guide Views
    
    @ViewBuilder
    private func parserGuideView(for type: RecipeParserType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best for:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            switch type {
            case .tableFormat:
                VStack(alignment: .leading, spacing: 4) {
                    guideItem(icon: "tablecells", text: "Recipe cards with columns")
                    guideItem(icon: "chart.bar.doc.horizontal", text: "Table layouts with imperial/metric")
                    guideItem(icon: "rectangle.split.3x1", text: "Structured ingredient lists")
                }
                
            case .standardText:
                VStack(alignment: .leading, spacing: 4) {
                    guideItem(icon: "list.bullet", text: "Bulleted ingredient lists")
                    guideItem(icon: "book.closed", text: "Cookbook pages")
                    guideItem(icon: "doc.plaintext", text: "Magazine recipes")
                    guideItem(icon: "note.text", text: "Simple printed recipes")
                }
                
            case .handwritten:
                VStack(alignment: .leading, spacing: 4) {
                    guideItem(icon: "pencil.and.scribble", text: "Handwritten recipe cards")
                    guideItem(icon: "hand.point.right", text: "Personal recipe notes")
                }
                
            case .magazine:
                VStack(alignment: .leading, spacing: 4) {
                    guideItem(icon: "newspaper", text: "Magazine layouts")
                    guideItem(icon: "photo.on.rectangle", text: "Multi-column formats")
                }
            }
        }
        .padding(.top, 4)
    }
    
    private func guideItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.caption2)
                .frame(width: 16)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Parsed Recipe Display View

struct ParsedRecipeDisplayView: View {
    @Environment(\.modelContext) private var modelContext
    
    let recipe: RecipeModel
    let sourceImage: UIImage?
    @Binding var showSuccessAlert: Bool
    @State private var showEditSheet = false
    @State private var editingIngredientIndex: Int?
    @State private var editedIngredients: [ExtendedIngredient] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Parsed Recipe")
                    .font(.headline)
                Spacer()
                Text("Tap ingredients to edit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if let title = recipe.title {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.title2)
                        .bold()
                }
            }
            
            if let servings = recipe.servings {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Servings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(servings)")
                        .font(.subheadline)
                }
            }
            
            // Ingredients (Editable)
            if !editedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Ingredients (\(editedIngredients.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: addNewIngredient) {
                            Label("Add", systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    ForEach(editedIngredients.indices, id: \.self) { index in
                        ingredientRow(for: index)
                    }
                }
            }
            
            if let instructions = recipe.instructions {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Instructions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(instructions)
                        .font(.subheadline)
                }
            }
            
            HStack {
                Button(action: saveToRecipesApp) {
                    Label("Save to Recipes", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: shareRecipe) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            // Initialize edited ingredients from recipe
            if editedIngredients.isEmpty, let ingredients = recipe.extendedIngredients {
                editedIngredients = ingredients
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    @ViewBuilder
    private func ingredientRow(for index: Int) -> some View {
        let ingredient = editedIngredients[index]
        
        VStack(spacing: 0) {
            if editingIngredientIndex == index {
                // Edit mode
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Amount", text: Binding(
                            get: { ingredient.original ?? "" },
                            set: { newValue in
                                editedIngredients[index] = updateIngredient(ingredient, withText: newValue)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        Button("Done") {
                            editingIngredientIndex = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button(action: {
                            deleteIngredient(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                // Display mode
                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let original = ingredient.original, !original.isEmpty {
                            Text(original)
                                .font(.subheadline)
                        } else if let amount = ingredient.amount,
                                  let unit = ingredient.unit,
                                  let name = ingredient.name {
                            HStack {
                                Text("\(formatAmount(amount)) \(unit)")
                                    .bold()
                                Text(name)
                            }
                            if let metric = ingredient.measures?.metric,
                               let metricAmount = metric.amount,
                               let metricUnit = metric.unitShort {
                                Text("\(formatAmount(metricAmount)) \(metricUnit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        editingIngredientIndex = index
                    }
                }
            }
        }
    }
    
    private func addNewIngredient() {
        let newIngredient = ExtendedIngredient(
            id: nil,
            aisle: nil,
            image: nil,
            consistency: nil,
            name: "New ingredient",
            nameClean: nil,
            original: "1 new ingredient",
            originalName: nil,
            amount: 1.0,
            unit: "",
            meta: nil,
            measures: nil
        )
        editedIngredients.append(newIngredient)
        editingIngredientIndex = editedIngredients.count - 1
    }
    
    private func deleteIngredient(at index: Int) {
        withAnimation {
            editedIngredients.remove(at: index)
            editingIngredientIndex = nil
        }
    }
    
    private func updateIngredient(_ ingredient: ExtendedIngredient, withText text: String) -> ExtendedIngredient {
        // Create a new ExtendedIngredient with updated values
        // since the struct properties are immutable (let constants)
        
        // Try to parse amount and name from the text
        let components = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var newAmount = ingredient.amount
        var newUnit = ingredient.unit
        var newName = ingredient.name
        
        if components.count >= 2 {
            // First component might be amount
            if let amount = Double(components[0]) {
                newAmount = amount
                newUnit = components.count > 1 ? components[1] : ""
                newName = components.dropFirst(2).joined(separator: " ")
            } else {
                newName = text
            }
        } else if !text.isEmpty {
            newName = text
        }
        
        // Return a new instance with updated values
        return ExtendedIngredient(
            id: ingredient.id,
            aisle: ingredient.aisle,
            image: ingredient.image,
            consistency: ingredient.consistency,
            name: newName,
            nameClean: ingredient.nameClean,
            original: text,  // Update the original text field
            originalName: ingredient.originalName,
            amount: newAmount,
            unit: newUnit,
            meta: ingredient.meta,
            measures: ingredient.measures
        )
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        } else {
            return String(format: "%.2f", amount).replacingOccurrences(of: ".00", with: "")
        }
    }
    
    private func saveToRecipesApp() {
        print("💾 [SaveRecipe] Starting save process...")
        print("💾 [SaveRecipe] Recipe UUID: \(recipe.uuid)")
        print("💾 [SaveRecipe] Recipe title: \(recipe.title ?? "nil")")
        
        // Update recipe with edited ingredients before saving
        recipe.extendedIngredients = editedIngredients
        
        modelContext.insert(recipe)
        print("💾 [SaveRecipe] Inserted recipe into context")
        
        if let image = sourceImage {
            if let filePath = RecipeMediaModel.saveImage(image, for: recipe.uuid) {
                print("💾 [SaveRecipe] Image saved to disk: \(filePath)")
                
                let mediaModel = RecipeMediaModel(
                    fileURL: filePath,
                    type: .photo,
                    sortOrder: 0,
                    recipe: recipe
                )
                
                print("💾 [SaveRecipe] Created mediaModel with UUID: \(mediaModel.uuid)")
                
                modelContext.insert(mediaModel)
                print("💾 [SaveRecipe] Inserted mediaModel into context")
                
                if recipe.mediaItems == nil {
                    recipe.mediaItems = []
                }
                recipe.mediaItems?.append(mediaModel)
                print("💾 [SaveRecipe] Added media to recipe.mediaItems array")
                
                recipe.featuredMediaID = mediaModel.uuid
                recipe.preferFeaturedMedia = true
                
                print("💾 [SaveRecipe] Set recipe.featuredMediaID = \(mediaModel.uuid)")
                print("💾 [SaveRecipe] Set recipe.preferFeaturedMedia = true")
                print("💾 [SaveRecipe] recipe.mediaItems?.count = \(recipe.mediaItems?.count ?? 0)")
            } else {
                print("⚠️ [SaveRecipe] Failed to save source image to disk")
            }
        } else {
            print("⚠️ [SaveRecipe] No source image available")
        }
        
        do {
            print("💾 [SaveRecipe] Attempting to save context...")
            try modelContext.save()
            print("✅ [SaveRecipe] Context saved successfully!")
            
            print("🔍 [SaveRecipe] Post-save verification:")
            print("   - recipe.uuid: \(recipe.uuid)")
            print("   - recipe.featuredMediaID: \(recipe.featuredMediaID?.uuidString ?? "nil")")
            print("   - recipe.preferFeaturedMedia: \(recipe.preferFeaturedMedia)")
            print("   - recipe.mediaItems?.count: \(recipe.mediaItems?.count ?? 0)")
            print("   - recipe.featuredMediaURL: \(recipe.featuredMediaURL ?? "nil")")
            
            if let firstMedia = recipe.mediaItems?.first {
                print("   - First media UUID: \(firstMedia.uuid)")
                print("   - First media fileURL: \(firstMedia.fileURL)")
                print("   - First media recipe relationship: \(firstMedia.recipe != nil ? "✅" : "❌")")
            }
            
            showSuccessAlert = true
            
        } catch {
            print("❌ [SaveRecipe] Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private func shareRecipe() {
        let text = formatRecipeForSharing()
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatRecipeForSharing() -> String {
        var text = recipe.title ?? "Recipe" + "\n\n"
        
        if let servings = recipe.servings {
            text += "Servings: \(servings)\n\n"
        }
        
        text += "Ingredients:\n"
        for ingredient in editedIngredients {
            if let original = ingredient.original {
                text += "• \(original)\n"
            } else if let amount = ingredient.amount,
                      let unit = ingredient.unit,
                      let name = ingredient.name {
                text += "• \(formatAmount(amount)) \(unit) \(name)"
                if let metric = ingredient.measures?.metric,
                   let metricAmount = metric.amount,
                   let metricUnit = metric.unitShort {
                    text += " (\(formatAmount(metricAmount)) \(metricUnit))"
                }
                text += "\n"
            }
        }
        
        if let instructions = recipe.instructions {
            text += "\nInstructions:\n\(instructions)\n"
        }
        
        return text
    }
}

// MARK: - Image Picker

struct RecipeImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: RecipeImagePicker
        
        init(_ parent: RecipeImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct RecipeImageParserView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeImageParserView()
    }
}
