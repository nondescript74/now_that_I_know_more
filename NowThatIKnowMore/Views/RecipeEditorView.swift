import SwiftUI
import Foundation
import PhotosUI
import AVKit
import MessageUI

struct RecipeEditorView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @Environment(\.dismiss) private var dismiss
    
    // The recipe to edit (optional - if nil, we're creating a new recipe)
    @State var recipe: Recipe?
    
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
    @State private var mediaItems: [RecipeMedia]
    @State private var featuredMediaID: UUID?
    @State private var preferFeaturedMedia: Bool
    
    // Editing mode helper for complex fields
    private static let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    init(recipe: Recipe? = nil) {
        self._recipe = State(initialValue: recipe)
        self._isEditingExisting = State(initialValue: recipe != nil)
        self._title = State(initialValue: recipe?.title ?? "")
        self._summary = State(initialValue: recipe?.summary ?? "")
        self._creditsText = State(initialValue: recipe?.creditsText ?? "")
        self._servings = State(initialValue: recipe?.servings.map { String($0) } ?? "")
        self._instructions = State(initialValue: recipe?.instructions ?? "")
        self._selectedDays = State(initialValue: recipe?.daysOfWeek ?? [])
        self._cuisines = State(initialValue: (recipe?.cuisines)?.compactMap { $0.value as? String }.joined(separator: ", ") ?? "")
        self._imageUrl = State(initialValue: recipe?.image ?? "")
        self._mediaItems = State(initialValue: recipe?.mediaItems ?? [])
        self._featuredMediaID = State(initialValue: recipe?.featuredMediaID)
        self._preferFeaturedMedia = State(initialValue: recipe?.preferFeaturedMedia ?? true)
//        if let list = recipe.extendedIngredients as? [[String: Any]] {
//            self._ingredients = State(initialValue: list.compactMap { $0["original"] as? String }.joined(separator: "\n"))
//        } else if let list = recipe.ingredients as? [String] {
//            self._ingredients = State(initialValue: list.joined(separator: "\n"))
//        } else {
//            self._ingredients = State(initialValue: "")
//        }
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
        if !recipeStore.recipes.isEmpty && !isEditingExisting {
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
            MediaGalleryView(
                mediaItems: mediaItems,
                featuredMediaID: featuredMediaID,
                onSelectFeatured: { mediaID in
                    featuredMediaID = mediaID
                },
                onAddMedia: { newMedia in
                    mediaItems.append(contentsOf: newMedia)
                    // If no featured media is set, make the first one featured
                    if featuredMediaID == nil, let first = newMedia.first {
                        featuredMediaID = first.id
                    }
                },
                onRemoveMedia: { mediaID in
                    mediaItems.removeAll { $0.id == mediaID }
                    // If we removed the featured media, select a new one
                    if featuredMediaID == mediaID {
                        featuredMediaID = mediaItems.first?.id
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
                TextField("Paste image url", text: $imageUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Clear") { imageUrl = "" }
            }
            if isValidImageUrl(imageUrl) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().scaledToFit().frame(height: 120)
                    case .failure: Image(systemName: "exclamationmark.triangle").foregroundColor(.red)
                    @unknown default: EmptyView()
                    }
                }
            }
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
        guard let url = URL(string: url.lowercased()), ["http", "https"].contains(url.scheme) else { return false }
        let validExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        let ext = url.pathExtension
        return validExtensions.contains(ext)
    }

    private func loadRecipe(_ selectedRecipe: Recipe) {
        recipe = selectedRecipe
        isEditingExisting = true
        title = selectedRecipe.title ?? ""
        summary = selectedRecipe.summary ?? ""
        creditsText = selectedRecipe.creditsText ?? ""
        servings = selectedRecipe.servings.map { String($0) } ?? ""
        instructions = selectedRecipe.instructions ?? ""
        selectedDays = selectedRecipe.daysOfWeek ?? []
        cuisines = (selectedRecipe.cuisines)?.compactMap { $0.value as? String }.joined(separator: ", ") ?? ""
        imageUrl = selectedRecipe.image ?? ""
        mediaItems = selectedRecipe.mediaItems ?? []
        featuredMediaID = selectedRecipe.featuredMediaID
        preferFeaturedMedia = selectedRecipe.preferFeaturedMedia ?? true
    }
    
    private func saveEdits() {
        let servingsValue: Int? = Int(servings) ?? recipe?.servings
        
        let idValue = recipe?.id
        let sourceUrlValue = recipe?.sourceURL
        let extendedIngredientsValue = recipe?.extendedIngredients?.compactMap { ingredient in
            if let data = try? JSONEncoder().encode(ingredient),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        }
        
        // Determine image and imageType to save based on imageUrl validity
        var imageToSave = recipe?.image
        var imageTypeToSave = recipe?.imageType
        if isValidImageUrl(imageUrl) {
            imageToSave = imageUrl
            imageTypeToSave = URL(string: imageUrl)?.pathExtension.lowercased()
        }
        
        var dict: [String: Any] = [
            "uuid": recipe?.uuid ?? UUID(),
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "summary": summary.trimmingCharacters(in: .whitespacesAndNewlines),
            "creditsText": creditsText.trimmingCharacters(in: .whitespacesAndNewlines),
            "instructions": instructions.trimmingCharacters(in: .whitespacesAndNewlines),
            "daysOfWeek": selectedDays,
            "cuisines": cuisines.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "ingredients": ingredients.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) },
            // Add other properties as needed
        ]
        if let idValue {
            dict["id"] = idValue
        }
        if let imageToSave {
            dict["image"] = imageToSave
        }
        if let imageTypeToSave {
            dict["imageType"] = imageTypeToSave
        }
        if let sourceUrlValue {
            dict["sourceUrl"] = sourceUrlValue
        }
        if let extendedIngredientsValue, !extendedIngredientsValue.isEmpty {
            dict["extendedIngredients"] = extendedIngredientsValue
        }
        if let servingsValue {
            dict["servings"] = servingsValue
        }
        
        // Add media items
        if !mediaItems.isEmpty {
            let mediaArray = mediaItems.map { media -> [String: Any] in
                return [
                    "id": media.id.uuidString,
                    "url": media.url,
                    "type": media.type.rawValue
                ]
            }
            dict["mediaItems"] = mediaArray
        }
        
        // Add featured media ID
        if let featuredID = featuredMediaID {
            dict["featuredMediaID"] = featuredID.uuidString
        }
        
        // Add image display preference
        dict["preferFeaturedMedia"] = preferFeaturedMedia
        
        // Add any additional fields from the original recipe that shouldn't be lost
        if let existingRecipe = recipe {
            let updated = Recipe(from: dict) ?? existingRecipe
            recipeStore.update(updated)
        } else {
            // Creating a new recipe
            if let newRecipe = Recipe(from: dict) {
                recipeStore.add(newRecipe)
            }
        }
        alertMessage = isEditingExisting ? "Saved changes." : "Created new recipe."
        showAlert = true
        dismiss()
    }
}

// MARK: - Recipe Picker View
private struct RecipePickerView: View {
    @Environment(RecipeStore.self) private var recipeStore
    let onSelect: (Recipe) -> Void
    
    @State private var searchText = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipeStore.recipes
        }
        return recipeStore.recipes.filter { recipe in
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
    let recipe: Recipe
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
            dismiss()
        }
    }
    
    private func createEmailBody(_ recipe: Recipe) -> String {
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

//extension String {
//    var sanitizedForFileName: String {
//        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
//        return components(separatedBy: invalidCharacters).joined(separator: "_")
//    }
//}

#Preview("Edit Existing Recipe") {
    let store = RecipeStore()
    let recipe = store.recipes.first ?? Recipe(from: ["uuid": UUID(), "title": "Sample Recipe"])!
    if store.recipes.isEmpty {
        store.add(recipe)
    }
    return NavigationStack {
        RecipeEditorView(recipe: recipe).environment(store)
    }
}

#Preview("Create New Recipe") {
    let store = RecipeStore()
    // Add a few recipes to demonstrate the picker
    let recipe1 = Recipe(from: ["uuid": UUID(), "title": "Pasta Carbonara", "creditsText": "Italian Chef"])!
    let recipe2 = Recipe(from: ["uuid": UUID(), "title": "Chicken Tikka Masala", "creditsText": "Indian Chef"])!
    store.add(recipe1)
    store.add(recipe2)
    return NavigationStack {
        RecipeEditorView().environment(store)
    }
}
