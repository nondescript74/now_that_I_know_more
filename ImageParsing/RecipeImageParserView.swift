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
    
    var body: some View {
        NavigationView {
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
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Parser Type", selection: $selectedParserType) {
                                ForEach(RecipeParserFactory.availableParsers, id: \.self) { parserType in
                                    Text(parserType.displayName).tag(parserType)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
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
                        Button(action: {
                            print("🔘 [RecipeImageParserView] Parse button TAPPED")
                            // Add haptic feedback for tactile confirmation
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
                        ParsedRecipeDisplayView(recipe: recipe, showSuccessAlert: $showSuccessAlert)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Recipe Parser")
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
        
        // Resize image if it's too large (this often causes Vision to hang)
        let resizedImage = resizeImageIfNeeded(image)
        if image !== resizedImage {
            print("📐 Resized to: \(resizedImage.size.width)x\(resizedImage.size.height)")
        }
        
        // Add timeout mechanism
        var hasCompleted = false
        
        // Timeout after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
            if !hasCompleted {
                print("⏰ [RecipeImageParserView] Parse operation timed out after 30 seconds")
                isProcessing = false
                errorMessage = "Parsing timed out. The image may be too large or complex. Try a smaller or clearer image."
            }
        }
        
        // Get the appropriate parser for the selected type
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
                    // Convert to RecipeModel (SwiftData)
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
        
        // If image is already small enough, return it as-is
        guard maxSize > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxDimension / maxSize
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}

// MARK: - Parsed Recipe Display View

struct ParsedRecipeDisplayView: View {
    @Environment(\.modelContext) private var modelContext
    
    let recipe: RecipeModel
    @Binding var showSuccessAlert: Bool
    @State private var showEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text("Parsed Recipe")
                    .font(.headline)
                Spacer()
                Button(action: { showEditSheet = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            // Title
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
            
            // Servings
            if let servings = recipe.servings {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Servings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(servings)")
                        .font(.subheadline)
                }
            }
            
            // Ingredients
            if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients (\(ingredients.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(ingredients.indices, id: \.self) { index in
                        let ingredient = ingredients[index]
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                            VStack(alignment: .leading, spacing: 2) {
                                if let amount = ingredient.amount,
                                   let unit = ingredient.unit,
                                   let name = ingredient.name {
                                    HStack {
                                        Text("\(formatAmount(amount)) \(unit)")
                                            .bold()
                                        Text(name)
                                    }
                                    // Show metric if available
                                    if let metric = ingredient.measures?.metric,
                                       let metricAmount = metric.amount,
                                       let metricUnit = metric.unitShort {
                                        Text("\(formatAmount(metricAmount)) \(metricUnit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            
            // Instructions
            if let instructions = recipe.instructions {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Instructions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(instructions)
                        .font(.subheadline)
                }
            }
            
            // Actions
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
        .sheet(isPresented: $showEditSheet) {
            // TODO: Create a RecipeModel editor view
            // For now, editing is not supported for parsed recipes
            Text("Recipe editing coming soon!")
                .padding()
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        } else {
            return String(format: "%.2f", amount).replacingOccurrences(of: ".00", with: "")
        }
    }
    
    private func saveToRecipesApp() {
        // Insert the recipe into SwiftData
        modelContext.insert(recipe)
        
        do {
            try modelContext.save()
            // Show success feedback
            showSuccessAlert = true
            
            print("✅ Recipe saved to SwiftData: \(recipe.title ?? "Untitled")")
            print("   UUID: \(recipe.uuid)")
        } catch {
            print("❌ Failed to save recipe: \(error.localizedDescription)")
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
        if let ingredients = recipe.extendedIngredients {
            for ingredient in ingredients {
                if let amount = ingredient.amount,
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
