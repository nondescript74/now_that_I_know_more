import SwiftUI
import Foundation
import PhotosUI
import AVKit

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
    
    // Media (photos and videos) captured/selected by the user
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var userPhotos: [UIImage] = []
    @State private var userVideos: [URL] = []
    @State private var showingImagePicker = false
    @State private var showingVideoPicker = false
    @State private var showingCamera = false
    @State private var cameraMediaType: UIImagePickerController.CameraCaptureMode = .photo
    
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
        
        // Initialize media from recipe if available
        var photos: [UIImage] = []
        var videos: [URL] = []
        
        if let recipe = recipe,
           let data = try? JSONEncoder().encode(recipe),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Load photo URLs
            if let photoURLStrings = dict["userPhotoURLs"] as? [String] {
                for urlString in photoURLStrings {
                    let url = URL(fileURLWithPath: urlString)
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        photos.append(image)
                    }
                }
            }
            
            // Load video URLs
            if let videoURLStrings = dict["userVideoURLs"] as? [String] {
                for urlString in videoURLStrings {
                    let url = URL(fileURLWithPath: urlString)
                    if FileManager.default.fileExists(atPath: url.path) {
                        videos.append(url)
                    }
                }
            }
        }
        
        self._userPhotos = State(initialValue: photos)
        self._userVideos = State(initialValue: videos)
        
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
            // Recipe selection section - only show if we have recipes available and not already editing
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
            Section(header: Text("Servings")) {
                HStack {
                    TextField("Servings", text: $servings)
                        .keyboardType(.numberPad)
                    Button("Clear") { servings = "" }
                }
            }
            Section(header: Text("Cuisines (comma separated)")) {
                HStack {
                    TextField("Cuisines", text: $cuisines)
                        .autocorrectionDisabled()
                    Button("Clear") { cuisines = "" }
                }
            }
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
            
            Section(header: Text("Photos & Videos")) {
                // Photo Picker
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()
                ) {
                    Label("Select from Library", systemImage: "photo.on.rectangle")
                }
                
                // Camera button for photos
                Button(action: {
                    cameraMediaType = .photo
                    showingCamera = true
                }) {
                    Label("Take Photo", systemImage: "camera")
                }
                
                // Camera button for videos
                Button(action: {
                    cameraMediaType = .video
                    showingCamera = true
                }) {
                    Label("Record Video", systemImage: "video")
                }
                
                // Display selected photos
                if !userPhotos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos (\(userPhotos.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(userPhotos.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: userPhotos[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button(action: {
                                            userPhotos.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Display selected videos
                if !userVideos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Videos (\(userVideos.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ForEach(userVideos.indices, id: \.self) { index in
                            HStack {
                                VideoPlayer(player: AVPlayer(url: userVideos[index]))
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    userVideos.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                if !userPhotos.isEmpty || !userVideos.isEmpty {
                    Button("Clear All Media", role: .destructive) {
                        userPhotos.removeAll()
                        userVideos.removeAll()
                        selectedPhotoItems.removeAll()
                    }
                }
            }
            
            Section {
                Button("Save Changes") { saveEdits() }
                    .buttonStyle(.borderedProminent)
                Button("Cancel", role: .destructive) { dismiss() }
            }
        }
        .navigationTitle(isEditingExisting ? "Edit Recipe" : "Create Recipe")
        .alert("Edit", isPresented: $showAlert, actions: { Button("OK", role: .cancel) { } }, message: { Text(alertMessage) })
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
        .sheet(isPresented: $showingCamera) {
            CameraView(mediaType: cameraMediaType, onPhotoCaptured: { image in
                userPhotos.append(image)
                showingCamera = false
            }, onVideoCaptured: { videoURL in
                userVideos.append(videoURL)
                showingCamera = false
            }, onCancel: {
                showingCamera = false
            })
        }
        .onChange(of: selectedPhotoItems) { oldItems, newItems in
            Task {
                for item in newItems {
                    // Try to load as image first
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            userPhotos.append(image)
                        }
                    } else if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                        await MainActor.run {
                            userVideos.append(movie.url)
                        }
                    }
                }
            }
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
        
        // Load existing user photos and videos if they exist
        userPhotos.removeAll()
        userVideos.removeAll()
        
        // Try to extract custom fields from the recipe using reflection or JSONSerialization
        if let data = try? JSONEncoder().encode(selectedRecipe),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Load photo URLs
            if let photoURLStrings = dict["userPhotoURLs"] as? [String] {
                for urlString in photoURLStrings {
                    let url = URL(fileURLWithPath: urlString)
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        userPhotos.append(image)
                    }
                }
            }
            
            // Load video URLs
            if let videoURLStrings = dict["userVideoURLs"] as? [String] {
                for urlString in videoURLStrings {
                    let url = URL(fileURLWithPath: urlString)
                    if FileManager.default.fileExists(atPath: url.path) {
                        userVideos.append(url)
                    }
                }
            }
        }
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
        
        // Save user photos and videos to documents directory
        var savedPhotoURLs: [String] = []
        var savedVideoURLs: [String] = []
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recipeFolderName = (recipe?.uuid ?? UUID()).uuidString
        let recipeMediaFolder = documentsPath.appendingPathComponent("RecipeMedia/\(recipeFolderName)")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: recipeMediaFolder, withIntermediateDirectories: true)
        
        // Save photos
        for (index, photo) in userPhotos.enumerated() {
            if let data = photo.jpegData(compressionQuality: 0.8) {
                let filename = "photo_\(index)_\(UUID().uuidString).jpg"
                let fileURL = recipeMediaFolder.appendingPathComponent(filename)
                try? data.write(to: fileURL)
                savedPhotoURLs.append(fileURL.path)
            }
        }
        
        // Save video URLs
        for videoURL in userVideos {
            // If it's already in our documents, just store the path
            // Otherwise, copy it
            if videoURL.path.contains(documentsPath.path) {
                savedVideoURLs.append(videoURL.path)
            } else {
                let filename = "video_\(UUID().uuidString).mov"
                let destinationURL = recipeMediaFolder.appendingPathComponent(filename)
                try? FileManager.default.copyItem(at: videoURL, to: destinationURL)
                savedVideoURLs.append(destinationURL.path)
            }
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
        
        // Store media URLs in the dictionary
        if !savedPhotoURLs.isEmpty {
            dict["userPhotoURLs"] = savedPhotoURLs
        }
        if !savedVideoURLs.isEmpty {
            dict["userVideoURLs"] = savedVideoURLs
        }
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

// MARK: - Video Transferable
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let mediaType: UIImagePickerController.CameraCaptureMode
    let onPhotoCaptured: (UIImage) -> Void
    let onVideoCaptured: (URL) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = mediaType
        
        if mediaType == .photo {
            picker.mediaTypes = ["public.image"]
        } else {
            picker.mediaTypes = ["public.movie"]
        }
        
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPhotoCaptured: onPhotoCaptured, onVideoCaptured: onVideoCaptured, onCancel: onCancel)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPhotoCaptured: (UIImage) -> Void
        let onVideoCaptured: (URL) -> Void
        let onCancel: () -> Void
        
        init(onPhotoCaptured: @escaping (UIImage) -> Void, onVideoCaptured: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPhotoCaptured = onPhotoCaptured
            self.onVideoCaptured = onVideoCaptured
            self.onCancel = onCancel
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onPhotoCaptured(image)
            } else if let videoURL = info[.mediaURL] as? URL {
                // Copy to a permanent location in documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = documentsPath.appendingPathComponent(UUID().uuidString + ".mov")
                
                try? FileManager.default.copyItem(at: videoURL, to: destinationURL)
                onVideoCaptured(destinationURL)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
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
