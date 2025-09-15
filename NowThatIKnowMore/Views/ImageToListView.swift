import SwiftUI
import PhotosUI
import Vision
import OSLog

struct ImageToListView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var recognizedItems: [String] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @SceneStorage("itl_selectedTitleIndices") private var selectedTitleIndicesString: String = ""
    @State private var selectedTitleIndicesState: Set<Int> = []
    @State private var selectedSummaryIndicesState: Set<Int> = []
    // Local computed property for Set<Int>:
    private var selectedTitleIndices: Set<Int> {
        get { Set(selectedTitleIndicesString.split(separator: ",").compactMap { Int($0) }) }
        set { selectedTitleIndicesString = newValue.map(String.init).joined(separator: ",") }
    }

    @SceneStorage("itl_selectedSummaryIndices") private var selectedSummaryIndicesString: String = ""
    private var selectedSummaryIndices: Set<Int> {
        get { Set(selectedSummaryIndicesString.split(separator: ",").compactMap { Int($0) }) }
        set { selectedSummaryIndicesString = newValue.map(String.init).joined(separator: ",") }
    }

    @State private var selectedIngredientIndices: Set<Int> = []
    @State private var selectedInstructionIndices: Set<Int> = []
    @State private var saveMessage: String?
    @State private var savedRandoms: [Int] = []
    @State private var ingredientGroups: [[Int]] = []
    @State private var instructionGroups: [[Int]] = []
    @State private var groupingIngredient: [Int] = []
    @State private var groupingInstruction: [Int] = []
    @SceneStorage("itl_editedTitle") private var editedTitle: String = ""
    @SceneStorage("itl_editedSummary") private var editedSummary: String = ""
    @SceneStorage("itl_credits") private var credits: String = ""
    @SceneStorage("itl_imageUrlText") private var imageUrlText: String = ""
    @State private var isImageCollapsed = false

    // New state to select which image to use if both local image and URL are present
    @State private var useLocalImage: Bool = true

    // Replace static cuisines list with dynamic loaded list
    @State private var cuisinesList: [String] = []

    @State private var selectedCuisine: String = ""
    
    // New state for drag-over highlight for Title drag-and-merge
    @State private var dragOverIndex: Int? = nil

    private var trimmedUrlText: String { imageUrlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var validUrl: URL? { URL(string: trimmedUrlText) }
    private var hasValidUrl: Bool {
        let trimmed = trimmedUrlText
        let url = validUrl
        guard !trimmed.isEmpty, let url, let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    // --- Begin new helpers ---
    private var joinedSelectedTitle: String {
        let indices = selectedTitleIndicesState.sorted()
        let selectedStrings = indices.compactMap { self.recognizedItems[safe: $0] }
        return selectedStrings.joined(separator: " ")
    }
    private var joinedSelectedSummary: String {
        let indices = selectedSummaryIndicesState.sorted()
        let selectedStrings = indices.compactMap { self.recognizedItems[safe: $0] }
        return selectedStrings.joined(separator: " ")
    }
    private var joinedSelectedIngredients: [String] {
        if !ingredientGroups.isEmpty {
            var result = [String]()
            for group in ingredientGroups {
                let groupItems = group.compactMap { index -> String? in
                    self.recognizedItems[safe: index]
                }
                let joined = groupItems.joined(separator: " ")
                result.append(joined)
            }
            return result
        } else {
            let indices: [Int] = selectedIngredientIndices.sorted()
            let items: [String] = indices.compactMap { index in
                self.recognizedItems[safe: index]
            }
            return items
        }
    }
    private var joinedSelectedInstructions: [String] {
        if !instructionGroups.isEmpty {
            var result = [String]()
            for group in instructionGroups {
                let groupItems = group.compactMap { index -> String? in
                    self.recognizedItems[safe: index]
                }
                let joined = groupItems.joined(separator: " ")
                result.append(joined)
            }
            return result
        } else {
            let indices: [Int] = selectedInstructionIndices.sorted()
            let items: [String] = indices.compactMap { index in
                self.recognizedItems[safe: index]
            }
            return items
        }
    }
    private var canSaveRecipe: Bool {
        let hasTitle: Bool = !selectedTitleIndicesState.isEmpty
        let hasIngredients: Bool = (!selectedIngredientIndices.isEmpty) || (!ingredientGroups.isEmpty)
        let hasInstructions: Bool = (!selectedInstructionIndices.isEmpty) || (!instructionGroups.isEmpty)
        let allSectionsPresent: Bool = hasTitle && hasIngredients && hasInstructions
        return allSectionsPresent
    }
    // --- End new helpers ---

    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "ImageToListView")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Select JPEG or PNG Image")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        await loadImage(from: newItem)
                    }
                }
                
                if !recognizedItems.isEmpty {
                    recipePartsSection
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                self.selectedTitleIndicesState = self.selectedTitleIndices
                self.selectedSummaryIndicesState = self.selectedSummaryIndices
                if self.selectedCuisine.isEmpty {
                    self.selectedCuisine = ""
                }
                if cuisinesList.isEmpty {
                    loadCuisinesList()
                }
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    self.useLocalImage = true
                } else if self.hasValidUrl {
                    self.useLocalImage = false
                }
            }
            .onChange(of: imageUrlText) { _, newText in
                if self.hasValidUrl && self.selectedImage == nil {
                    self.useLocalImage = false
                } else if self.selectedImage != nil {
                    self.useLocalImage = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var recipePartsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image URL (optional)")
                .font(.subheadline)
            HStack {
                TextField("Paste or enter image URL", text: $imageUrlText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .disableAutocorrection(true)
                if !self.imageUrlText.isEmpty {
                    Button(action: { self.imageUrlText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear URL")
                }
            }
            
            // Show image usage toggle if both local image and valid URL exist
            if self.selectedImage != nil && self.hasValidUrl {
                Picker("Image Source", selection: $useLocalImage) {
                    Text("Use Local Photo").tag(true)
                    Text("Use Web URL").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 4)
            }
            
            // Show clear button for local image if present
            if self.selectedImage != nil {
                HStack(spacing: 8) {
                    Text("Local Photo Selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button(action: {
                        self.selectedImage = nil
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear local photo")
                }
            }
            
            // Show collapse/show button and image for selectedImage or URL based on useLocalImage
            if !self.isImageCollapsed {
                if self.useLocalImage {
                    if let image = self.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    } else if self.hasValidUrl {
                        AsyncImage(url: self.validUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxHeight: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                            case .failure:
                                Image(systemName: "exclamationmark.triangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                } else {
                    // useLocalImage == false, show URL image only if valid URL
                    if self.hasValidUrl {
                        AsyncImage(url: self.validUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxHeight: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                            case .failure:
                                Image(systemName: "exclamationmark.triangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if self.selectedImage != nil {
                        EmptyView().onAppear { self.useLocalImage = true }
                    }
                }
            }
            
            // Show collapse/show button if either local image or valid URL image present
            if (self.selectedImage != nil || self.hasValidUrl) {
                Button(self.isImageCollapsed ? "Show Image" : "Collapse Image") {
                    self.isImageCollapsed.toggle()
                }
            }
            
            if self.isProcessing {
                ProgressView("Extracting text...")
            }
            
            if let error = self.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Designate Recipe Parts")
                    .font(.headline)
                
                // Replace Title Picker with multiple toggle buttons and drag-and-merge capability
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                    ForEach(self.recognizedItems.indices, id: \.self) { i in
                        ZStack {
                            Button(action: {
                                if self.selectedTitleIndicesState.contains(i) {
                                    self.selectedTitleIndicesState.remove(i)
                                } else {
                                    self.selectedTitleIndicesState.insert(i)
                                }
                            }) {
                                HStack {
                                    Image(systemName: self.selectedTitleIndicesState.contains(i) ? "checkmark.square.fill" : "square")
                                    Text(self.recognizedItems[i])
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .background(self.dragOverIndex == i ? Color.accentColor.opacity(0.1) : Color.clear)
                        .onDrag {
                            NSItemProvider(object: String(i) as NSString)
                        }
                        .onDrop(of: ["public.text"], isTargeted: Binding(get: { self.dragOverIndex == i }, set: { val in self.dragOverIndex = val ? i : nil })) { providers in
                            if let provider = providers.first {
                                _ = provider.loadObject(ofClass: NSString.self) { (draggedIdxStr, _) in
                                    guard let draggedIdxStr = draggedIdxStr as? String, let draggedIdx = Int(draggedIdxStr), draggedIdx != i else { return }
                                    DispatchQueue.main.async {
                                        self.mergeRecognizedItems(source: draggedIdx, destination: i)
                                    }
                                }
                                return true
                            }
                            return false
                        }
                    }
                }
                TextField("Edit Title", text: $editedTitle)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        if self.editedTitle.isEmpty {
                            self.editedTitle = self.joinedSelectedTitle
                        }
                    }
                    .onChange(of: self.selectedTitleIndicesState) { _, _ in
                        if self.editedTitle.isEmpty || self.editedTitle != self.joinedSelectedTitle {
                            self.editedTitle = self.joinedSelectedTitle
                        }
                    }

                // Replace Summary Picker with multiple toggle buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                    ForEach(self.recognizedItems.indices, id: \.self) { i in
                        Button(action: {
                            if self.selectedSummaryIndicesState.contains(i) {
                                self.selectedSummaryIndicesState.remove(i)
                            } else {
                                self.selectedSummaryIndicesState.insert(i)
                            }
                        }) {
                            HStack {
                                Image(systemName: self.selectedSummaryIndicesState.contains(i) ? "checkmark.square.fill" : "square")
                                Text(self.recognizedItems[i])
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                TextField("Edit Summary", text: $editedSummary)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        if self.editedSummary.isEmpty {
                            self.editedSummary = self.joinedSelectedSummary
                        }
                    }
                    .onChange(of: self.selectedSummaryIndicesState) { _, _ in
                        if self.editedSummary.isEmpty || self.editedSummary != self.joinedSelectedSummary {
                            self.editedSummary = self.joinedSelectedSummary
                        }
                    }
                if !editedSummary.isEmpty && cleanSummary(editedSummary) != editedSummary {
                    Text(cleanSummary(editedSummary))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                // Insert Cuisine Picker here (after Summary)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cuisine")
                    Picker("Cuisine", selection: $selectedCuisine) {
                        Text("None").tag("")
                        ForEach(cuisinesList, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Credits")
                        .font(.subheadline)
                    TextField("Enter credits (e.g. source or author)", text: $credits)
                        .textFieldStyle(.roundedBorder)
                }

                // Added cuisine display here
                if let cuisines = self.extractCuisines(), !cuisines.isEmpty {
                    HStack {
                        Text("Cuisine:")
                            .fontWeight(.semibold)
                        Text(cuisines.joined(separator: ", "))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Ingredients").font(.subheadline)
                    ForEach(self.recognizedItems.indices, id: \.self) { i in
                        ZStack {
                            Button(action: { self.toggleIngredientGrouped(i) }) {
                                HStack {
                                    Image(systemName: self.groupingIngredient.contains(i) ? "checkmark.square.fill" : "square")
                                    Text(self.recognizedItems[i])
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .background(self.dragOverIndex == i ? Color.accentColor.opacity(0.1) : Color.clear)
                        .onDrag {
                            NSItemProvider(object: String(i) as NSString)
                        }
                        .onDrop(of: ["public.text"], isTargeted: Binding(get: { self.dragOverIndex == i }, set: { val in self.dragOverIndex = val ? i : nil })) { providers in
                            if let provider = providers.first {
                                _ = provider.loadObject(ofClass: NSString.self) { (draggedIdxStr, _) in
                                    guard let draggedIdxStr = draggedIdxStr as? String, let draggedIdx = Int(draggedIdxStr), draggedIdx != i else { return }
                                    DispatchQueue.main.async {
                                        self.mergeRecognizedItems(source: draggedIdx, destination: i)
                                    }
                                }
                                return true
                            }
                            return false
                        }
                    }
                    HStack {
                        Button("Add Ingredient Group") {
                            if !self.groupingIngredient.isEmpty {
                                self.ingredientGroups.append(self.groupingIngredient.sorted())
                                self.groupingIngredient.removeAll()
                            }
                        }.disabled(self.groupingIngredient.isEmpty)
                        Button("Clear Groups") {
                            self.ingredientGroups.removeAll()
                            self.groupingIngredient.removeAll()
                        }.disabled(self.ingredientGroups.isEmpty && self.groupingIngredient.isEmpty)
                    }
                    if !self.ingredientGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ingredient Groups:").font(.caption)
                            ForEach(self.ingredientGroups.indices, id: \.self) { gIndex in
                                HStack {
                                    Text(self.ingredientGroups[gIndex].map { self.recognizedItems[$0] }.joined(separator: " | "))
                                        .font(.caption)
                                    Button(action: { self.ingredientGroups.remove(at: gIndex) }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Instructions").font(.subheadline)
                    ForEach(self.recognizedItems.indices, id: \.self) { i in
                        ZStack {
                            Button(action: { self.toggleInstructionGrouped(i) }) {
                                HStack {
                                    Image(systemName: self.groupingInstruction.contains(i) ? "checkmark.square.fill" : "square")
                                    Text(self.recognizedItems[i])
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .background(self.dragOverIndex == i ? Color.accentColor.opacity(0.1) : Color.clear)
                        .onDrag {
                            NSItemProvider(object: String(i) as NSString)
                        }
                        .onDrop(of: ["public.text"], isTargeted: Binding(get: { self.dragOverIndex == i }, set: { val in self.dragOverIndex = val ? i : nil })) { providers in
                            if let provider = providers.first {
                                _ = provider.loadObject(ofClass: NSString.self) { (draggedIdxStr, _) in
                                    guard let draggedIdxStr = draggedIdxStr as? String, let draggedIdx = Int(draggedIdxStr), draggedIdx != i else { return }
                                    DispatchQueue.main.async {
                                        self.mergeRecognizedItems(source: draggedIdx, destination: i)
                                    }
                                }
                                return true
                            }
                            return false
                        }
                    }
                    HStack {
                        Button("Add Instruction Group") {
                            if !self.groupingInstruction.isEmpty {
                                self.instructionGroups.append(self.groupingInstruction.sorted())
                                self.groupingInstruction.removeAll()
                            }
                        }.disabled(self.groupingInstruction.isEmpty)
                        Button("Clear Groups") {
                            self.instructionGroups.removeAll()
                            self.groupingInstruction.removeAll()
                        }.disabled(self.instructionGroups.isEmpty && self.groupingInstruction.isEmpty)
                    }
                    if !self.instructionGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instruction Groups:").font(.caption)
                            ForEach(self.instructionGroups.indices, id: \.self) { gIndex in
                                HStack {
                                    Text(self.instructionGroups[gIndex].map { self.recognizedItems[$0] }.joined(separator: " | "))
                                        .font(.caption)
                                    Button(action: { self.instructionGroups.remove(at: gIndex) }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                Button("Save as Recipe") {
                    self.saveAsRecipe()
                }
                .disabled(!self.canSaveRecipe)
                if let msg = self.saveMessage {
                    Text(msg).foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func extractCuisines() -> [String]? {
        // Attempt to extract cuisine strings from recognizedItems by best effort:
        // Since recognizedItems is [String], and we don't have a recipe.cuisines property,
        // we can try to find lines that start with or contain "Cuisine" and parse them.
        // Alternatively, no direct cuisine extraction is possible here, so return nil.
        // The instructions imply a property like recipe.cuisines, but it's not present here.
        // So, we'll return nil to not show anything.
        // This function stub can be expanded if recipe.cuisines is added later.
        return nil
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        self.isProcessing = true
        self.errorMessage = nil
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.selectedImage = image
                self.useLocalImage = true
                await recognizeText(in: image)
            } else {
                self.errorMessage = "Couldn't load image."
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isProcessing = false
    }
    
    @MainActor
    private func recognizeText(in image: UIImage) async {
        self.recognizedItems = []
        guard let cgImage = image.cgImage else {
            self.errorMessage = "Image format not supported."
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let allText = observations.compactMap { $0.topCandidates(1).first?.string }
            self.recognizedItems = allText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func toggleIngredientSelected(_ index: Int) {
        if self.selectedIngredientIndices.contains(index) {
            self.selectedIngredientIndices.remove(index)
        } else {
            self.selectedIngredientIndices.insert(index)
        }
    }
    
    private func toggleInstructionSelected(_ index: Int) {
        if self.selectedInstructionIndices.contains(index) {
            self.selectedInstructionIndices.remove(index)
        } else {
            self.selectedInstructionIndices.insert(index)
        }
    }
    
    private func toggleIngredientGrouped(_ index: Int) {
        if let idx = self.groupingIngredient.firstIndex(of: index) {
            self.groupingIngredient.remove(at: idx)
        } else {
            self.groupingIngredient.append(index)
        }
    }
    
    private func toggleInstructionGrouped(_ index: Int) {
        if let idx = self.groupingInstruction.firstIndex(of: index) {
            self.groupingInstruction.remove(at: idx)
        } else {
            self.groupingInstruction.append(index)
        }
    }
    
    /// Saves a UIImage as JPEG to the app's documents directory with a filename based on the UUID.
    /// Returns the file URL string if successful, nil otherwise.
    private func saveImageToDocuments(uiImage: UIImage, for id: UUID) -> String? {
        guard let data = uiImage.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = "recipe_\(id.uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url.absoluteString
        } catch {
            print("Failed to save image file: \(error)")
            return nil
        }
    }
    
    private func saveAsRecipe() {
        if self.selectedTitleIndicesState.isEmpty {
            self.saveMessage = "Please select at least one title line."
            return
        }
        
        // Generate a new UUID for the recipe and image file
        let newUUID = UUID()
        
        // Determine the image path or URL to store based on useLocalImage:
        // Priority:
        // if useLocalImage == true and selectedImage present -> save local image
        // else if useLocalImage == false and valid URL present -> use URL
        // else if only one option is present, default to that
        
        var imagePath: String? = nil
        
        if self.useLocalImage {
            if let image = self.selectedImage {
                imagePath = saveImageToDocuments(uiImage: image, for: newUUID)
            } else if self.hasValidUrl {
                imagePath = self.trimmedUrlText
            }
        } else {
            if self.hasValidUrl {
                imagePath = self.trimmedUrlText
            } else if let image = self.selectedImage {
                imagePath = saveImageToDocuments(uiImage: image, for: newUUID)
            }
        }
        
        let titleJoined = self.joinedSelectedTitle
        
        let title: String = {
            if !self.editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return self.editedTitle
            } else {
                return titleJoined
            }
        }()
        let summary: String? = {
            let rawSummary = !self.editedSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? self.editedSummary
                : self.joinedSelectedSummary
            let cleaned = cleanSummary(rawSummary)
            return cleaned.isEmpty ? nil : cleaned
        }()

        // Add cuisines variable:
        let cuisines: [Any]? = selectedCuisine.isEmpty ? nil : [selectedCuisine]
        
        let instructionLines: [String] = self.joinedSelectedInstructions
        let instructions = instructionLines.joined(separator: "\n")
        let steps: [Step] = instructionLines.enumerated().map { index, line in
            Step(number: index + 1, step: line, ingredients: nil, equipment: nil, length: nil)
        }
        let analyzedInstructions: [AnalyzedInstruction] = [AnalyzedInstruction(name: nil, steps: steps.isEmpty ? nil : steps)]
        
        let ingredientLines: [String] = self.joinedSelectedIngredients
        var ingredients: [ExtendedIngredient] = []
        for (index, line) in ingredientLines.enumerated() {
            ingredients.append(
                ExtendedIngredient(
                    id: index,
                    aisle: "no aisle",
                    image: "no image",
                    consistency: Consistency.solid,
                    name: line,
                    nameClean: line,
                    original: line,
                    originalName: line,
                    amount: 0,
                    unit: "no unit",
                    meta: ["no meta"],
                    measures: Measures(us: Metric(amount: 0, unitShort: "0", unitLong: "0"), metric: Metric(amount: 0, unitShort: "0", unitLong: "0"))
                )
            )
        }
        
        var dict: [String: Any] = [
            "title": title.isEmpty ? "Untitled" : title,
            "summary": summary as Any,
            "creditsText": self.credits.trimmingCharacters(in: .whitespacesAndNewlines),
            "cuisines": cuisines as Any,
            "instructions": instructions,
            "analyzedInstructions": analyzedInstructions.map { [
                "name": $0.name as Any,
                "steps": $0.steps?.map { [
                    "number": $0.number as Any,
                    "step": $0.step as Any,
                    "ingredients": [],
                    "equipment": [],
                    "length": nil
                ] } ?? []
            ] },
            "extendedIngredients": ingredients.map { ingredient in
                [
                    "id": ingredient.id as Any,
                    "aisle": ingredient.aisle as Any,
                    "image": ingredient.image as Any,
                    "consistency": ingredient.consistency?.rawValue as Any,
                    "name": ingredient.name as Any,
                    "nameClean": ingredient.nameClean as Any,
                    "original": ingredient.original as Any,
                    "originalName": ingredient.originalName as Any,
                    "amount": ingredient.amount as Any,
                    "unit": ingredient.unit as Any,
                    "meta": ingredient.meta as Any,
                    "measures": [
                        "us": [
                            "amount": ingredient.measures?.us?.amount as Any,
                            "unitShort": ingredient.measures?.us?.unitShort as Any,
                            "unitLong": ingredient.measures?.us?.unitLong as Any
                        ],
                        "metric": [
                            "amount": ingredient.measures?.metric?.amount as Any,
                            "unitShort": ingredient.measures?.metric?.unitShort as Any,
                            "unitLong": ingredient.measures?.metric?.unitLong as Any
                        ]
                    ]
                ]
            }
        ]
        
        // Add image path and UUID to dictionary (imagePath may be nil if no image was saved or no valid URL entered)
        dict["image"] = imagePath as Any
        dict["uuid"] = newUUID
        
        guard let recipe = Recipe(from: dict) else {
            self.saveMessage = "Failed to create recipe from inputs."
            return
        }
        
        self.recipeStore.add(recipe)
        self.saveMessage = "Recipe saved!"
        self.logger.info("Recipe saved with title: \(title, privacy: .public)")
    }

    private struct CuisineName: Decodable {
        let name: String
    }
    
    private func loadCuisinesList() {
        if let url = Bundle.main.url(forResource: "cuisines", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode([CuisineName].self, from: data) {
                cuisinesList = decoded.map { $0.name }
            } else if let decodedStrings = try? JSONDecoder().decode([String].self, from: data) {
                cuisinesList = decodedStrings
            }
        }
    }
    
    private func mergeRecognizedItems(source: Int, destination: Int) {
        guard source != destination, source < recognizedItems.count, destination < recognizedItems.count else { return }
        let merged = recognizedItems[source] + " " + recognizedItems[destination]
        var newItems = recognizedItems
        let removeFirst = max(source, destination)
        let keep = min(source, destination)
        newItems[keep] = merged
        newItems.remove(at: removeFirst)
        recognizedItems = newItems
        // For safety, clear all selection/grouping states
        selectedTitleIndicesState.removeAll()
        selectedSummaryIndicesState.removeAll()
        selectedIngredientIndices.removeAll()
        selectedInstructionIndices.removeAll()
        ingredientGroups.removeAll()
        instructionGroups.removeAll()
        groupingIngredient.removeAll()
        groupingInstruction.removeAll()
    }
    
    private func cleanSummary(_ html: String) -> String {
        var text = html.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<ul>|</ul>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<b>(.*?)</b>", with: "**$1**", options: .regularExpression)
        text = text.replacingOccurrences(of: "<i>(.*?)</i>", with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ImageToListView()
        .environment(RecipeStore())
}

