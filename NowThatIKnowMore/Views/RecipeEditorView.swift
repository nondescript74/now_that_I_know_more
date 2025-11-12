import SwiftUI
import SwiftUI
import Foundation
import PhotosUI
import AVKit
import MessageUI
import SwiftData
import UIKit


struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    
    // The recipe to edit (optional - if nil, we're creating a new recipe)
    @State var recipe: RecipeModel?
    
    // Recipe selection state
    @State private var showRecipePicker = false
    @State private var isEditingExisting = false
    
    // Editable fields (initialized from recipe)
    @State private var title: String
    @State private var summary: String
    @State private var creditsText: String
    @State private var servings: String
    @State private var instructions: String
    @State private var selectedDays: [String]
    @State private var cuisines: String
    @State private var imageUrl: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var summarySelectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var instructionsSelectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var ingredients: String = ""
    @State private var ingredientsSelectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var showingEmailComposer = false
    @State private var showIngredientMatcher = false
    @State private var unmatchedIngredients: [(line: String, matches: [SpoonacularIngredient])] = []
    
    // Media gallery state
    @State private var mediaItems: [RecipeMediaModel]
    @State private var featuredMediaID: UUID?
    @State private var preferFeaturedMedia: Bool
    
    // Photo picker for image URL field
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // Editing mode helper for complex fields
    private static let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    init(recipe: RecipeModel? = nil) {
        self._recipe = State(initialValue: recipe)
        self._isEditingExisting = State(initialValue: recipe != nil)
        self._title = State(initialValue: recipe?.title ?? "")
        self._summary = State(initialValue: recipe?.summary ?? "")
        self._creditsText = State(initialValue: recipe?.creditsText ?? "")
        self._servings = State(initialValue: recipe?.servings.map { String($0) } ?? "")
        self._instructions = State(initialValue: recipe?.instructions ?? "")
        self._selectedDays = State(initialValue: recipe?.daysOfWeek ?? [])
        self._cuisines = State(initialValue: recipe?.cuisines.joined(separator: ", ") ?? "")
        self._imageUrl = State(initialValue: recipe?.image ?? "")
        self._mediaItems = State(initialValue: recipe?.mediaItems ?? [])
        self._featuredMediaID = State(initialValue: recipe?.featuredMediaID)
        self._preferFeaturedMedia = State(initialValue: recipe?.preferFeaturedMedia ?? false)
        
        // Initialize ingredients from extendedIngredients if available
        if let extendedIngredients = recipe?.extendedIngredients, !extendedIngredients.isEmpty {
            let ingredientLines = extendedIngredients.compactMap { $0.original }.joined(separator: "\n")
            self._ingredients = State(initialValue: ingredientLines)
        } else {
            self._ingredients = State(initialValue: "")
        }
    }
    
    var body: some View {
        Form {
            recipeSelectionSection
            basicInfoSection
            mediaSection
            imageURLSection
            servingsSection
            cuisinesSection
            ingredientsSection
            instructionsSection
            daysOfWeekSection
            actionSection
        }
        .navigationTitle(isEditingExisting ? "Edit Recipe" : "Create Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveEdits()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Edit", isPresented: $showAlert, actions: { Button("OK", role: .cancel) { } }, message: { Text(alertMessage) })
        .sheet(isPresented: $showingEmailComposer) {
            if let recipe = recipe {
                MailComposeView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showRecipePicker) {
            NavigationStack {
                RecipePickerView(onSelect: { selectedRecipe in
                    loadRecipe(selectedRecipe)
                    showRecipePicker = false
                })
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showRecipePicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showIngredientMatcher) {
            IngredientMatcherView(
                unmatchedIngredients: $unmatchedIngredients,
                onComplete: { matches in
                    showIngredientMatcher = false
                    finalizeSaveWithMatches(matches)
                },
                onCancel: {
                    showIngredientMatcher = false
                }
            )
        }
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var recipeSelectionSection: some View {
        if !swiftDataRecipes.isEmpty && !isEditingExisting {
            Section(header: Text("Choose Recipe")) {
                Button("Select Existing Recipe to Edit") {
                    showRecipePicker = true
                }
                .buttonStyle(.bordered)
                
                Text("Or create a new recipe below")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        if isEditingExisting {
            Section {
                HStack {
                    Text("Editing: \(recipe?.title ?? "Recipe")")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Spacer()
                    Button("Switch Recipe") {
                        showRecipePicker = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section(header: Text("Basic Info")) {
            HStack {
                TextField("Title", text: $title)
                Button("Clear") { title = "" }
            }
            HStack {
                TextField("Credits", text: $creditsText)
                Button("Clear") { creditsText = "" }
            }
            HStack {
                BindableTextView(text: $summary, selectedRange: $summarySelectedRange)
                    .frame(minHeight: 40, maxHeight: 150)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                Button("Clear") { summary = "" }
            }
            HStack(spacing: 12) {
                Button("Remove HTML Tags") {
                    summary = summary.strippedHTML
                    summarySelectedRange = NSRange(location: min(summarySelectedRange.location, summary.count), length: 0)
                }
                Button("Insert Indent") {
                    let indent = "→ "
                    let loc = min(summarySelectedRange.location, summary.count)
                    summary.insert(contentsOf: indent, at: summary.index(summary.startIndex, offsetBy: loc))
                    summarySelectedRange = NSRange(location: loc + indent.count, length: 0)
                }
                Text("(Use '→' for indentation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var mediaSection: some View {
        Section(header: Text("Photos & Videos")) {
            // Convert UUID-based state to PersistentIdentifier for MediaGalleryView
            MediaGalleryWrapper(
                mediaItems: mediaItems,
                featuredMediaUUID: featuredMediaID,
                onSelectFeaturedUUID: { uuid in
                    featuredMediaID = uuid
                },
                onAddMedia: { newMedia in
                    mediaItems.append(contentsOf: newMedia)
                    // If no featured media is set, make the first one featured
                    if featuredMediaID == nil, let first = newMedia.first {
                        featuredMediaID = first.uuid
                    }
                },
                onRemoveMediaUUID: { uuid in
                    mediaItems.removeAll { $0.uuid == uuid }
                    // If we removed the featured media, select a new one
                    if featuredMediaID == uuid {
                        featuredMediaID = mediaItems.first?.uuid
                    }
                }
            )
            
            Text("Tap a photo or video to set it as featured. The featured media will be shown on the recipe card.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Display preference toggle
            if !mediaItems.isEmpty && isValidImageUrl(imageUrl) {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Toggle("Prefer Featured Media Over URL Image", isOn: $preferFeaturedMedia)
                    Text(preferFeaturedMedia ? 
                         "The featured media will be displayed instead of the image URL." :
                         "The image URL will be displayed instead of the featured media.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var imageURLSection: some View {
        Section(header: Text("Image URL (optional)")) {
            HStack {
                TextField("Paste image url or select from Photos", text: $imageUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Clear") { imageUrl = "" }
            }
            
            // Photo picker button
            HStack {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Select from Photos", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let newItem,
                           let data = try? await newItem.loadTransferable(type: Data.self) {
                            // Save to temporary location
                            if let savedURL = saveImageToDocuments(data: data) {
                                imageUrl = savedURL.absoluteString
                            }
                        }
                    }
                }
                
                Spacer()
                
                Text("or paste a URL above")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isValidImageUrl(imageUrl) {
                if let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: ProgressView()
                        case .success(let image): 
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .cornerRadius(8)
                        case .failure: 
                            // For local files, try loading directly
                            if url.scheme == "file", let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            }
                        @unknown default: EmptyView()
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to save image to documents directory
    private func saveImageToDocuments(data: Data) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // Create a unique filename
        let fileName = "recipe_image_\(UUID().uuidString).jpg"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("❌ Failed to save image: \(error)")
            return nil
        }
    }
    
    private var servingsSection: some View {
        Section(header: Text("Servings")) {
            HStack {
                TextField("Servings", text: $servings)
                    .keyboardType(.numberPad)
                Button("Clear") { servings = "" }
            }
        }
    }
    
    private var cuisinesSection: some View {
        Section(header: Text("Cuisines (comma separated)")) {
            HStack {
                TextField("Cuisines", text: $cuisines)
                    .autocorrectionDisabled()
                Button("Clear") { cuisines = "" }
            }
        }
    }
    
    private var ingredientsSection: some View {
        let ingredientCount = ingredients
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        
        return Section(header: HStack {
            Text("Ingredients (one per line)")
            Spacer()
            if ingredientCount > 0 {
                Text("\(ingredientCount) ingredient\(ingredientCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
        }) {
            BindableTextView(text: $ingredients, selectedRange: $ingredientsSelectedRange)
                .frame(minHeight: 80, maxHeight: 200)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            if ingredients.isEmpty {
                Text("Enter each ingredient on a separate line. Example:\n• 2 cups flour\n• 1 tsp salt\n• 3 eggs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            HStack(spacing: 12) {
                Button("Remove HTML Tags") {
                    ingredients = ingredients.strippedHTML
                    ingredientsSelectedRange = NSRange(location: min(ingredientsSelectedRange.location, ingredients.count), length: 0)
                }
                .font(.caption)
                
                Button("Insert Indent") {
                    let indent = "→ "
                    let loc = min(ingredientsSelectedRange.location, ingredients.count)
                    ingredients.insert(contentsOf: indent, at: ingredients.index(ingredients.startIndex, offsetBy: loc))
                    ingredientsSelectedRange = NSRange(location: loc + indent.count, length: 0)
                }
                .font(.caption)
            }
            
            Button("Clear All") {
                ingredients = ""
                ingredientsSelectedRange = NSRange(location: 0, length: 0)
            }
            .foregroundColor(.red)
        }
    }
    
    private var instructionsSection: some View {
        Section(header: Text("Instructions")) {
            BindableTextView(text: $instructions, selectedRange: $instructionsSelectedRange)
                .frame(minHeight: 80, maxHeight: 200)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            HStack(spacing: 12) {
                Button("Remove HTML Tags") {
                    instructions = instructions.strippedHTML
                    instructionsSelectedRange = NSRange(location: min(instructionsSelectedRange.location, instructions.count), length: 0)
                }
                Button("Insert Indent") {
                    let indent = "→ "
                    let loc = min(instructionsSelectedRange.location, instructions.count)
                    instructions.insert(contentsOf: indent, at: instructions.index(instructions.startIndex, offsetBy: loc))
                    instructionsSelectedRange = NSRange(location: loc + indent.count, length: 0)
                }
                Text("(Use '→' for indentation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Button("Clear") { instructions = "" }
        }
    }
    
    private var daysOfWeekSection: some View {
        Section(header: Text("Days of Week")) {
            ForEach(Self.daysOfWeek, id: \.self) { day in
                Toggle(day, isOn: Binding(
                    get: { selectedDays.contains(day) },
                    set: { val in
                        if val { selectedDays.append(day) }
                        else { selectedDays.removeAll { $0 == day } }
                    }
                ))
            }
            Button("Clear Days") { selectedDays.removeAll() }
        }
    }
    
    private var actionSection: some View {
        Section {
            if isEditingExisting, let _ = recipe {
                Button(action: {
                    showingEmailComposer = true
                }) {
                    Label("Email Recipe", systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func isValidImageUrl(_ url: String) -> Bool {
        guard let parsedUrl = URL(string: url) else { return false }
        
        let validExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"]
        let ext = parsedUrl.pathExtension.lowercased()
        
        // Check for remote URLs (http/https)
        if ["http", "https"].contains(parsedUrl.scheme) {
            return validExtensions.contains(ext)
        }
        
        // Check for file URLs (Photos library or local files)
        if ["file"].contains(parsedUrl.scheme) {
            return validExtensions.contains(ext) || url.contains("assets-library://") || url.contains(".JPG") || url.contains(".PNG")
        }
        
        // Check for Photos library asset URLs
        if url.hasPrefix("assets-library://") || url.hasPrefix("ph://") {
            return true
        }
        
        return false
    }

    private func loadRecipe(_ selectedRecipe: RecipeModel) {
        recipe = selectedRecipe
        isEditingExisting = true
        title = selectedRecipe.title ?? ""
        summary = selectedRecipe.summary ?? ""
        creditsText = selectedRecipe.creditsText ?? ""
        servings = selectedRecipe.servings.map { String($0) } ?? ""
        instructions = selectedRecipe.instructions ?? ""
        selectedDays = selectedRecipe.daysOfWeek
        cuisines = selectedRecipe.cuisines.joined(separator: ", ")
        imageUrl = selectedRecipe.image ?? ""
        mediaItems = selectedRecipe.mediaItems ?? []
        featuredMediaID = selectedRecipe.featuredMediaID
        preferFeaturedMedia = selectedRecipe.preferFeaturedMedia
        
        // Load ingredients from extendedIngredients
        if let extendedIngredients = selectedRecipe.extendedIngredients, !extendedIngredients.isEmpty {
            ingredients = extendedIngredients.compactMap { $0.original }.joined(separator: "\n")
        } else {
            ingredients = ""
        }
    }
    
    // MARK: - Ingredient Matching Helpers
    
    /// Finds a matching ingredient from existing ingredients using smart fuzzy matching
    /// This preserves image data and other metadata when ingredients are edited
    private func findMatchingIngredient(for line: String, in existingIngredients: [ExtendedIngredient]) -> ExtendedIngredient? {
        let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Strategy 1: Exact match on original text (highest confidence)
        if let exactMatch = existingIngredients.first(where: {
            $0.original?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanedLine
        }) {
            print("✅ [IngredientMatch] Exact match: '\(line)' -> '\(exactMatch.original ?? "")'")
            return exactMatch
        }
        
        // Strategy 2: Match by nameClean (core ingredient name)
        let extractedName = extractIngredientName(from: line)
        if let nameMatch = existingIngredients.first(where: {
            guard let nameClean = $0.nameClean else { return false }
            return nameClean.lowercased().contains(extractedName.lowercased()) ||
                   extractedName.lowercased().contains(nameClean.lowercased())
        }) {
            print("✅ [IngredientMatch] Name match: '\(line)' -> '\(nameMatch.nameClean ?? "")'")
            return nameMatch
        }
        
        // Strategy 3: Match by ingredient name field
        if let nameFieldMatch = existingIngredients.first(where: {
            guard let name = $0.name else { return false }
            return name.lowercased().contains(extractedName.lowercased()) ||
                   extractedName.lowercased().contains(name.lowercased())
        }) {
            print("✅ [IngredientMatch] Name field match: '\(line)' -> '\(nameFieldMatch.name ?? "")'")
            return nameFieldMatch
        }
        
        // Strategy 4: Fuzzy match on key words (for ingredients with measurements changed)
        let lineWords = extractKeyWords(from: cleanedLine)
        if let fuzzyMatch = existingIngredients.first(where: { existing in
            guard let originalText = existing.original?.lowercased() else { return false }
            let existingWords = extractKeyWords(from: originalText)
            
            // Check if at least one significant word matches
            let commonWords = Set(lineWords).intersection(Set(existingWords))
            return !commonWords.isEmpty
        }) {
            print("✅ [IngredientMatch] Fuzzy match: '\(line)' -> '\(fuzzyMatch.original ?? "")'")
            return fuzzyMatch
        }
        
        print("⚠️ [IngredientMatch] No match found for: '\(line)'")
        return nil
    }
    
    /// Extracts the core ingredient name from a line of text
    /// Removes quantities, measurements, and preparation methods
    private func extractIngredientName(from line: String) -> String {
        var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Common measurement units to strip out
        let measurements = [
            "cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp",
            "pound", "pounds", "lb", "lbs", "ounce", "ounces", "oz", "gram", "grams", "g",
            "kilogram", "kilograms", "kg", "milliliter", "milliliters", "ml", "liter", "liters", "l",
            "pinch", "dash", "handful", "piece", "pieces", "slice", "slices", "clove", "cloves",
            "can", "cans", "package", "packages", "jar", "jars", "box", "boxes"
        ]
        
        // Common preparation words to strip
        let preparations = [
            "chopped", "diced", "sliced", "minced", "grated", "shredded", "peeled", "crushed",
            "fresh", "dried", "ground", "whole", "halved", "quartered", "finely", "coarsely",
            "optional", "approximately", "slightly"
        ]
        
        // Multi-word phrases to strip (handled separately to avoid regex issues)
        let multiWordPhrases = [
            "to taste",
            "or more",
            "or less",
            "as needed",
            "if needed"
        ]
        
        // Common descriptive words to strip
        let descriptors = [
            "large", "medium", "small", "big", "tiny", "extra", "super",
            "hot", "cold", "warm", "sweet", "spicy", "mild", "ripe", "unripe",
            "red", "green", "yellow", "white", "black", "brown", "orange", "purple"
        ]
        
        // Remove numbers, fractions, and special fraction characters at the start
        cleaned = cleaned.replacingOccurrences(of: "^[0-9\\/\\.\\-\\s¼½¾⅓⅔⅛⅜⅝⅞]+", with: "", options: .regularExpression)
        
        // Remove measurement words (case insensitive)
        for measurement in measurements {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(measurement)\\b", with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove preparation words
        for prep in preparations {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(prep)\\b", with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove multi-word phrases (case insensitive, exact phrase match)
        for phrase in multiWordPhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }
        
        // Remove descriptive words
        for descriptor in descriptors {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(descriptor)\\b", with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove parentheses and their contents
        cleaned = cleaned.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        
        // Clean up extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading/trailing commas and 'of'
        cleaned = cleaned.replacingOccurrences(of: "^[,\\s]*of\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        
        return cleaned.isEmpty ? line : cleaned
    }
    
    /// Extracts key words from ingredient text for fuzzy matching
    /// Filters out common stop words, measurements, and quantities
    private func extractKeyWords(from text: String) -> [String] {
        let stopWords = Set([
            "a", "an", "the", "of", "to", "for", "with", "and", "or", "in", "on", "at", "by",
            "fresh", "dried", "ground", "whole", "large", "small", "medium", "about", "approximately"
        ])
        
        // Split into words and filter
        let words = text.lowercased()
            .replacingOccurrences(of: "[^a-z\\s]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map { String($0) }
            .filter { word in
                !stopWords.contains(word) &&
                word.count > 2 && // Ignore very short words
                !word.allSatisfy { $0.isNumber } // Ignore pure numbers
            }
        
        return words
    }
    
    private func saveEdits() {
        // First, check for ingredients that need manual matching
        checkForUnmatchedIngredients()
    }
    
    private func checkForUnmatchedIngredients() {
        // Parse ingredients (one per line)
        let ingredientLines = ingredients
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Get existing ingredients to preserve image data
        let existingIngredients = recipe?.extendedIngredients ?? []
        let manager = SpoonacularIngredientManager.shared
        
        // Check each ingredient for matches
        var unmatched: [(line: String, matches: [SpoonacularIngredient])] = []
        
        for line in ingredientLines {
            let extractedName = extractIngredientName(from: line)
            let existingMatch = findMatchingIngredient(for: line, in: existingIngredients)
            
            // Skip if already has an image
            if existingMatch?.image != nil && !(existingMatch?.image?.isEmpty ?? true) {
                continue
            }
            
            // Try exact name match first
            if let _ = manager.ingredient(withName: extractedName) {
                continue // Exact match found, no user input needed
            }
            
            // Check for partial matches
            let searchResults = manager.searchIngredients(query: extractedName)
            
            if searchResults.isEmpty {
                // No matches at all - user will have to skip this one
                print("⚠️ [Spoonacular] No matches found for '\(extractedName)'")
            } else if searchResults.count == 1 {
                // Single match - we'll use it automatically
                print("✅ [Spoonacular] Single match for '\(extractedName)': '\(searchResults[0].name)'")
            } else {
                // Multiple matches - need user input
                unmatched.append((line: line, matches: Array(searchResults.prefix(10))))
                print("🔍 [Spoonacular] Multiple matches for '\(extractedName)': \(searchResults.count) options")
            }
        }
        
        // If there are unmatched ingredients, show the matcher UI
        if !unmatched.isEmpty {
            unmatchedIngredients = unmatched
            showIngredientMatcher = true
        } else {
            // No unmatched ingredients, proceed with save
            performSave(with: [:])
        }
    }
    
    private func finalizeSaveWithMatches(_ matches: [String: SpoonacularIngredient]) {
        performSave(with: matches)
    }
    
    private func performSave(with userSelectedMatches: [String: SpoonacularIngredient]) {
        let servingsValue: Int? = Int(servings) ?? recipe?.servings
        
        // Determine image and imageType to save based on imageUrl validity
        var imageToSave: String?
        var imageTypeToSave: String?
        
        if isValidImageUrl(imageUrl) {
            // User entered a valid URL - use it
            imageToSave = imageUrl
            imageTypeToSave = URL(string: imageUrl)?.pathExtension.lowercased()
        } else if imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // User cleared the field - explicitly set to nil
            imageToSave = nil
            imageTypeToSave = nil
        } else {
            // Field has invalid content - preserve original
            imageToSave = recipe?.image
            imageTypeToSave = recipe?.imageType
        }
        
        // Parse cuisines
        let cuisinesArray = cuisines
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Parse ingredients (one per line)
        let ingredientLines = ingredients
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Get existing ingredients to preserve image data
        let existingIngredients = recipe?.extendedIngredients ?? []
        
        // Pre-fetch Spoonacular matches for all ingredients that need them
        // This is done outside the map to ensure main actor access
        var spoonacularMatches: [String: SpoonacularIngredient] = userSelectedMatches
        let manager = SpoonacularIngredientManager.shared
        
        for line in ingredientLines {
            // Skip if user already selected a match
            if spoonacularMatches[line] != nil {
                continue
            }
            
            let extractedName = extractIngredientName(from: line)
            
            // Check if we need to look up this ingredient using smart matching
            let existingMatch = findMatchingIngredient(for: line, in: existingIngredients)
            
            // Only lookup if no existing image
            if existingMatch?.image == nil || existingMatch?.image?.isEmpty == true {
                // Try exact name match
                if let match = manager.ingredient(withName: extractedName) {
                    spoonacularMatches[line] = match
                    print("🔍 [Spoonacular] Found exact match for '\(extractedName)': '\(match.name)' (ID: \(match.id))")
                } else {
                    // Try search - take first result if only one
                    let searchResults = manager.searchIngredients(query: extractedName)
                    if searchResults.count == 1 {
                        spoonacularMatches[line] = searchResults[0]
                        print("🔍 [Spoonacular] Found single search match for '\(extractedName)': '\(searchResults[0].name)' (ID: \(searchResults[0].id))")
                    } else if !searchResults.isEmpty {
                        print("⚠️ [Spoonacular] Multiple matches for '\(extractedName)', but no user selection")
                    } else {
                        print("⚠️ [Spoonacular] No match found for '\(extractedName)'")
                    }
                }
            } else {
                print("ℹ️ [Spoonacular] Skipping lookup for '\(line)' - already has image: \(existingMatch?.image ?? "unknown")")
            }
        }
        
        // Convert to ExtendedIngredient array, preserving images where possible
        let extendedIngredients: [ExtendedIngredient] = ingredientLines.enumerated().map { index, line in
            // Try to find a matching existing ingredient using smart matching
            let matchingExistingIngredient = findMatchingIngredient(for: line, in: existingIngredients)
            
            // Extract the ingredient name for this line
            let extractedName = extractIngredientName(from: line)
            
            // Get pre-fetched Spoonacular match
            let spoonacularMatch = spoonacularMatches[line]
            var imageFilename: String?
            
            // Use existing image if available
            if let existingImage = matchingExistingIngredient?.image, !existingImage.isEmpty {
                imageFilename = existingImage
                print("✅ [IngredientImage] Using existing image for '\(line)': \(existingImage)")
            } else if let match = spoonacularMatch {
                // Construct image filename from Spoonacular ingredient
                let imageName = match.name.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: ",", with: "")
                imageFilename = "\(imageName).jpg"
                print("🖼️ [IngredientImage] Using Spoonacular image for '\(line)': '\(match.name)' -> \(imageFilename ?? "none")")
            } else {
                print("⚠️ [IngredientImage] No image available for '\(line)'")
            }
            
            return ExtendedIngredient(
                id: spoonacularMatch?.id ?? matchingExistingIngredient?.id ?? (index + 1),
                aisle: matchingExistingIngredient?.aisle,
                image: imageFilename,
                consistency: matchingExistingIngredient?.consistency,
                name: spoonacularMatch?.name ?? matchingExistingIngredient?.name ?? extractedName,
                nameClean: spoonacularMatch?.name ?? matchingExistingIngredient?.nameClean ?? extractedName,
                original: line,
                originalName: matchingExistingIngredient?.originalName,
                amount: matchingExistingIngredient?.amount,
                unit: matchingExistingIngredient?.unit,
                meta: matchingExistingIngredient?.meta,
                measures: matchingExistingIngredient?.measures
            )
        }
        
        if let existingRecipe = recipe {
            // Update existing recipe
            print("🔍 [RecipeEditor] Updating existing recipe with UUID: \(existingRecipe.uuid)")
            
            existingRecipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existingRecipe.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            existingRecipe.creditsText = creditsText.trimmingCharacters(in: .whitespacesAndNewlines)
            existingRecipe.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            existingRecipe.servings = servingsValue
            existingRecipe.image = imageToSave
            existingRecipe.imageType = imageTypeToSave
            existingRecipe.cuisines = cuisinesArray
            existingRecipe.daysOfWeek = selectedDays
            existingRecipe.featuredMediaID = featuredMediaID
            existingRecipe.preferFeaturedMedia = preferFeaturedMedia
            existingRecipe.modifiedAt = Date()
            
            // Update ingredients
            existingRecipe.extendedIngredients = extendedIngredients.isEmpty ? nil : extendedIngredients
            
            // Update media items relationship
            // Note: mediaItems are already managed through the relationship
            
            print("✅ [RecipeEditor] Recipe updated - Title: '\(existingRecipe.title ?? "nil")', Ingredients: \(extendedIngredients.count)")
            
            // Save context
            do {
                try modelContext.save()
                alertMessage = "✓ Saved changes successfully!"
                showAlert = true
                
                // Dismiss after a short delay so user sees the success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            } catch {
                print("❌ [RecipeEditor] Failed to save context: \(error)")
                alertMessage = "Failed to save changes: \(error.localizedDescription)"
                showAlert = true
            }
        } else {
            // Create new recipe
            print("🔍 [RecipeEditor] Creating new recipe")
            
            let newRecipe = RecipeModel(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                servings: servingsValue,
                creditsText: creditsText.trimmingCharacters(in: .whitespacesAndNewlines),
                instructions: instructions.trimmingCharacters(in: .whitespacesAndNewlines),
                cuisinesString: cuisinesArray.joined(separator: ","),
                daysOfWeekString: selectedDays.joined(separator: ","),
                featuredMediaID: featuredMediaID,
                preferFeaturedMedia: preferFeaturedMedia
            )
            
            newRecipe.image = imageToSave
            newRecipe.imageType = imageTypeToSave
            
            // Set ingredients
            newRecipe.extendedIngredients = extendedIngredients.isEmpty ? nil : extendedIngredients
            
            // Add media items
            for mediaItem in mediaItems {
                mediaItem.recipe = newRecipe
                modelContext.insert(mediaItem)
            }
            
            // Insert the new recipe
            modelContext.insert(newRecipe)
            
            print("✅ [RecipeEditor] New recipe created with UUID: \(newRecipe.uuid), Ingredients: \(extendedIngredients.count)")
            
            // Save context
            do {
                try modelContext.save()
                alertMessage = "✓ Created new recipe successfully!"
                showAlert = true
                
                // Dismiss after a short delay so user sees the success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            } catch {
                print("❌ [RecipeEditor] Failed to save new recipe: \(error)")
                alertMessage = "Failed to create recipe: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// MARK: - Recipe Picker View
private struct RecipePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    let onSelect: (RecipeModel) -> Void
    
    @State private var searchText = ""
    
    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return swiftDataRecipes
        }
        return swiftDataRecipes.filter { recipe in
            (recipe.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredRecipes, id: \.uuid) { recipe in
                Button(action: {
                    onSelect(recipe)
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title ?? "Untitled Recipe")
                            .font(.headline)
                        if let creditsText = recipe.creditsText, !creditsText.isEmpty {
                            Text(creditsText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Select Recipe")
        .searchable(text: $searchText, prompt: "Search recipes")
    }
}

struct BindableTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.clear
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if uiView.selectedRange != selectedRange { uiView.selectedRange = selectedRange }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: BindableTextView
        init(_ parent: BindableTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}

// MARK: - Mail Compose View for RecipeEditor
private struct MailComposeView: UIViewControllerRepresentable {
    let recipe: RecipeModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        
        // Export recipe as JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let recipeData = try? encoder.encode(recipe)
        
        composer.setSubject("Recipe: \(recipe.title ?? "Untitled Recipe")")
        composer.setMessageBody(createEmailBody(recipe), isHTML: true)
        
        if let data = recipeData {
            composer.addAttachmentData(data, mimeType: "application/json", fileName: "\(recipe.title?.sanitizedForFileName ?? "recipe").recipe")
        }
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let dismissAction = dismiss
            Task { @MainActor in
                dismissAction()
            }
        }
    }
    
    private func createEmailBody(_ recipe: RecipeModel) -> String {
        let html = """
        <html>
        <head>
            <style>
                body { font-family: -apple-system, sans-serif; }
                h1 { color: #333; }
            </style>
        </head>
        <body>
            <h1>\(recipe.title ?? "Recipe")</h1>
            <p>This recipe was shared from the NowThatIKnowMore app.</p>
            <p>To import this recipe, open the attached .recipe file in the app.</p>
        </body>
        </html>
        """
        return html
    }
}

// MARK: - Ingredient Matcher View

private struct IngredientMatcherView: View {
    @Binding var unmatchedIngredients: [(line: String, matches: [SpoonacularIngredient])]
    let onComplete: ([String: SpoonacularIngredient]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedMatches: [String: SpoonacularIngredient?] = [:]
    
    var body: some View {
        NavigationStack {
            List {
                if unmatchedIngredients.isEmpty {
                    Text("No ingredients need matching")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(unmatchedIngredients.indices, id: \.self) { index in
                        ingredientMatchSection(at: index)
                    }
                }
            }
            .navigationTitle("Match Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        // Filter out skipped ingredients (where value is nil) and unwrap
                        let confirmedMatches = selectedMatches.compactMapValues { $0 }
                        onComplete(confirmedMatches)
                    }
                    .disabled(selectedMatches.count != unmatchedIngredients.count)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomStatusBar
            }
        }
    }
    
    @ViewBuilder
    private func ingredientMatchSection(at index: Int) -> some View {
        let item = unmatchedIngredients[index]
        
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Original ingredient text
                ingredientHeader(for: item)
                
                Text("Select the best match:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Possible matches
                ForEach(item.matches) { match in
                    matchButton(for: match, item: item)
                }
                
                // Skip option
                skipButton(for: item)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Ingredient \(index + 1) of \(unmatchedIngredients.count)")
        }
    }
    
    @ViewBuilder
    private func ingredientHeader(for item: (line: String, matches: [SpoonacularIngredient])) -> some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
            Text(item.line)
                .font(.headline)
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func matchButton(for match: SpoonacularIngredient, item: (line: String, matches: [SpoonacularIngredient])) -> some View {
        let isSelected = selectedMatches[item.line]??.id == match.id
        
        Button(action: {
            selectedMatches[item.line] = match
        }) {
            HStack(spacing: 12) {
                ingredientImageThumbnail(for: match)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("ID: \(match.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func ingredientImageThumbnail(for match: SpoonacularIngredient) -> some View {
        let imageName = match.name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ",", with: "")
        let imageURL = URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(imageName).jpg")
        
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            case .empty, .failure:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            @unknown default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func skipButton(for item: (line: String, matches: [SpoonacularIngredient])) -> some View {
        let isSkipped = selectedMatches[item.line] == nil && selectedMatches.keys.contains(item.line)
        
        Button(action: {
            selectedMatches[item.line] = nil
        }) {
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.orange)
                Text("Skip (no image)")
                    .foregroundColor(.orange)
                Spacer()
                if isSkipped {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSkipped ? Color.orange.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var bottomStatusBar: some View {
        VStack(spacing: 8) {
            if selectedMatches.count == unmatchedIngredients.count {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All ingredients reviewed!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
            } else {
                let remainingCount = unmatchedIngredients.count - selectedMatches.count
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Review \(remainingCount) more ingredient\(remainingCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
    }
}

// MARK: - Media Gallery Wrapper to convert UUID <-> PersistentIdentifier
private struct MediaGalleryWrapper: View {
    let mediaItems: [RecipeMediaModel]
    let featuredMediaUUID: UUID?
    let onSelectFeaturedUUID: (UUID) -> Void
    let onAddMedia: ([RecipeMediaModel]) -> Void
    let onRemoveMediaUUID: (UUID) -> Void
    
    var body: some View {
        MediaGalleryView(
            mediaItems: mediaItems,
            featuredMediaID: convertUUIDToID(featuredMediaUUID),
            onSelectFeatured: { persistentID in
                if let uuid = convertIDToUUID(persistentID) {
                    onSelectFeaturedUUID(uuid)
                }
            },
            onAddMedia: onAddMedia,
            onRemoveMedia: { persistentID in
                if let uuid = convertIDToUUID(persistentID) {
                    onRemoveMediaUUID(uuid)
                }
            }
        )
    }
    
    private func convertUUIDToID(_ uuid: UUID?) -> PersistentIdentifier? {
        guard let uuid = uuid else { return nil }
        return mediaItems.first(where: { $0.uuid == uuid })?.id
    }
    
    private func convertIDToUUID(_ id: PersistentIdentifier) -> UUID? {
        return mediaItems.first(where: { $0.id == id })?.uuid
    }
}



