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
        // Note: For now, we leave this empty as ingredients editing is not fully implemented
        self._ingredients = State(initialValue: "")
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
        Section(header: Text("Ingredients (one per line)")) {
            BindableTextView(text: $ingredients, selectedRange: $ingredientsSelectedRange)
                .frame(minHeight: 60, maxHeight: 180)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            HStack(spacing: 12) {
                Button("Remove HTML Tags") {
                    ingredients = ingredients.strippedHTML
                    ingredientsSelectedRange = NSRange(location: min(ingredientsSelectedRange.location, ingredients.count), length: 0)
                }
                Button("Insert Indent") {
                    let indent = "→ "
                    let loc = min(ingredientsSelectedRange.location, ingredients.count)
                    ingredients.insert(contentsOf: indent, at: ingredients.index(ingredients.startIndex, offsetBy: loc))
                    ingredientsSelectedRange = NSRange(location: loc + indent.count, length: 0)
                }
                Text("(Use '→' for indentation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Button("Clear") { ingredients = "" }
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
            Button("Save Changes") { saveEdits() }
                .buttonStyle(.borderedProminent)
            
            if isEditingExisting, let _ = recipe {
                Button(action: {
                    showingEmailComposer = true
                }) {
                    Label("Email Recipe", systemImage: "envelope")
                }
                .buttonStyle(.bordered)
            }
            
            Button("Cancel", role: .destructive) { dismiss() }
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
    }
    
    private func saveEdits() {
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
            
            // Update media items relationship
            // Note: mediaItems are already managed through the relationship
            
            print("✅ [RecipeEditor] Recipe updated - Title: '\(existingRecipe.title ?? "nil")'")
            
            // Save context
            do {
                try modelContext.save()
                alertMessage = "Saved changes."
                showAlert = true
                dismiss()
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
            
            // Add media items
            for mediaItem in mediaItems {
                mediaItem.recipe = newRecipe
                modelContext.insert(mediaItem)
            }
            
            // Insert the new recipe
            modelContext.insert(newRecipe)
            
            print("✅ [RecipeEditor] New recipe created with UUID: \(newRecipe.uuid)")
            
            // Save context
            do {
                try modelContext.save()
                alertMessage = "Created new recipe."
                showAlert = true
                dismiss()
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



