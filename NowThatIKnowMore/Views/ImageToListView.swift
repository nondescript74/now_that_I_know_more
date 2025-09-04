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
    @State private var selectedTitleIndex: Int? = nil
    @State private var selectedSummaryIndex: Int? = nil
    @State private var selectedIngredientIndices: Set<Int> = []
    @State private var selectedInstructionIndices: Set<Int> = []
    @State private var saveMessage: String?
    @State private var savedRandoms: [Int] = []
    @State private var ingredientGroups: [[Int]] = []
    @State private var instructionGroups: [[Int]] = []
    @State private var groupingIngredient: [Int] = []
    @State private var groupingInstruction: [Int] = []
    @State private var editedTitle: String = ""
    @State private var editedSummary: String = ""
    @State private var credits: String = ""
    @State private var imageUrlText: String = ""
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image URL (optional)")
                            .font(.subheadline)
                        HStack {
                            TextField("Paste or enter image URL", text: $imageUrlText)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .disableAutocorrection(true)
                            if !imageUrlText.isEmpty {
                                Button(action: { imageUrlText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Clear URL")
                            }
                        }
                    }
                }
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                } else if !imageUrlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          let url = URL(string: imageUrlText.trimmingCharacters(in: .whitespacesAndNewlines)),
                          ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    AsyncImage(url: url) { phase in
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
                
                if isProcessing {
                    ProgressView("Extracting text...")
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                if !recognizedItems.isEmpty {
                    Section(header: Text("Designate Recipe Parts").font(.headline)) {
                        HStack {
                            Text("Title")
                            Picker("Title", selection: $selectedTitleIndex) {
                                Text("None").tag(Optional<Int>(nil))
                                ForEach(recognizedItems.indices, id: \.self) { i in
                                    Text(recognizedItems[i]).tag(Optional(i))
                                }
                            }
                        }
                        TextField("Edit Title", text: $editedTitle)
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                if let idx = selectedTitleIndex, editedTitle.isEmpty {
                                    editedTitle = recognizedItems[idx]
                                }
                            }
                            .onChange(of: selectedTitleIndex) { _, newValue in
                                if let idx = newValue {
                                    editedTitle = recognizedItems[idx]
                                } else {
                                    editedTitle = ""
                                }
                            }
                        HStack {
                            Text("Summary")
                            Picker("Summary", selection: $selectedSummaryIndex) {
                                Text("None").tag(Optional<Int>(nil))
                                ForEach(recognizedItems.indices, id: \.self) { i in
                                    Text(recognizedItems[i]).tag(Optional(i))
                                }
                            }
                        }
                        TextField("Edit Summary", text: $editedSummary)
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                if let idx = selectedSummaryIndex, editedSummary.isEmpty {
                                    editedSummary = recognizedItems[idx]
                                }
                            }
                            .onChange(of: selectedSummaryIndex) { _, newValue in
                                if let idx = newValue {
                                    editedSummary = recognizedItems[idx]
                                } else {
                                    editedSummary = ""
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Credits")
                                .font(.subheadline)
                            TextField("Enter credits (e.g. source or author)", text: $credits)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Added cuisine display here
                        if let cuisines = extractCuisines(), !cuisines.isEmpty {
                            HStack {
                                Text("Cuisine:")
                                    .fontWeight(.semibold)
                                Text(cuisines.joined(separator: ", "))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Ingredients").font(.subheadline)
                            ForEach(recognizedItems.indices, id: \.self) { i in
                                Button(action: { toggleIngredientGrouped(i) }) {
                                    HStack {
                                        Image(systemName: groupingIngredient.contains(i) ? "checkmark.square.fill" : "square")
                                        Text(recognizedItems[i])
                                    }
                                }.buttonStyle(.plain)
                            }
                            HStack {
                                Button("Add Ingredient Group") {
                                    if !groupingIngredient.isEmpty {
                                        ingredientGroups.append(groupingIngredient.sorted())
                                        groupingIngredient.removeAll()
                                    }
                                }.disabled(groupingIngredient.isEmpty)
                                Button("Clear Groups") {
                                    ingredientGroups.removeAll()
                                    groupingIngredient.removeAll()
                                }.disabled(ingredientGroups.isEmpty && groupingIngredient.isEmpty)
                            }
                            if !ingredientGroups.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ingredient Groups:").font(.caption)
                                    ForEach(ingredientGroups.indices, id: \.self) { gIndex in
                                        HStack {
                                            Text(ingredientGroups[gIndex].map { recognizedItems[$0] }.joined(separator: " | "))
                                                .font(.caption)
                                            Button(action: { ingredientGroups.remove(at: gIndex) }) {
                                                Image(systemName: "trash").foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Instructions").font(.subheadline)
                            ForEach(recognizedItems.indices, id: \.self) { i in
                                Button(action: { toggleInstructionGrouped(i) }) {
                                    HStack {
                                        Image(systemName: groupingInstruction.contains(i) ? "checkmark.square.fill" : "square")
                                        Text(recognizedItems[i])
                                    }
                                }.buttonStyle(.plain)
                            }
                            HStack {
                                Button("Add Instruction Group") {
                                    if !groupingInstruction.isEmpty {
                                        instructionGroups.append(groupingInstruction.sorted())
                                        groupingInstruction.removeAll()
                                    }
                                }.disabled(groupingInstruction.isEmpty)
                                Button("Clear Groups") {
                                    instructionGroups.removeAll()
                                    groupingInstruction.removeAll()
                                }.disabled(instructionGroups.isEmpty && groupingInstruction.isEmpty)
                            }
                            if !instructionGroups.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Instruction Groups:").font(.caption)
                                    ForEach(instructionGroups.indices, id: \.self) { gIndex in
                                        HStack {
                                            Text(instructionGroups[gIndex].map { recognizedItems[$0] }.joined(separator: " | "))
                                                .font(.caption)
                                            Button(action: { instructionGroups.remove(at: gIndex) }) {
                                                Image(systemName: "trash").foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Button("Save as Recipe") {
                            saveAsRecipe()
                        }
                        .disabled(selectedTitleIndex == nil || selectedIngredientIndices.isEmpty && ingredientGroups.isEmpty || selectedInstructionIndices.isEmpty && instructionGroups.isEmpty)
                        if let msg = saveMessage {
                            Text(msg).foregroundColor(.accentColor)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
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
        isProcessing = true
        errorMessage = nil
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                await recognizeText(in: image)
            } else {
                errorMessage = "Couldn't load image."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    @MainActor
    private func recognizeText(in image: UIImage) async {
        recognizedItems = []
        guard let cgImage = image.cgImage else {
            errorMessage = "Image format not supported."
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let allText = observations.compactMap { $0.topCandidates(1).first?.string }
            recognizedItems = allText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func toggleIngredientSelected(_ index: Int) {
        if selectedIngredientIndices.contains(index) {
            selectedIngredientIndices.remove(index)
        } else {
            selectedIngredientIndices.insert(index)
        }
    }
    
    private func toggleInstructionSelected(_ index: Int) {
        if selectedInstructionIndices.contains(index) {
            selectedInstructionIndices.remove(index)
        } else {
            selectedInstructionIndices.insert(index)
        }
    }
    
    private func toggleIngredientGrouped(_ index: Int) {
        if let idx = groupingIngredient.firstIndex(of: index) {
            groupingIngredient.remove(at: idx)
        } else {
            groupingIngredient.append(index)
        }
    }
    
    private func toggleInstructionGrouped(_ index: Int) {
        if let idx = groupingInstruction.firstIndex(of: index) {
            groupingInstruction.remove(at: idx)
        } else {
            groupingInstruction.append(index)
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
        guard let titleIndex = selectedTitleIndex else {
            saveMessage = "Please select a title."
            return
        }
        
        // Generate a new UUID for the recipe and image file
        let newUUID = UUID()
        
        // Determine the image path or URL to store:
        // Priority: image URL text (if valid and non-empty) > picked photo (saved locally) > nil
        var imagePath: String? = nil
        let trimmedUrlText = imageUrlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUrlText.isEmpty,
           let url = URL(string: trimmedUrlText),
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            imagePath = trimmedUrlText
        } else if let image = selectedImage {
            imagePath = saveImageToDocuments(uiImage: image, for: newUUID)
        }
        
        let title: String = {
            if !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return editedTitle
            } else {
                return recognizedItems[titleIndex]
            }
        }()
        let summary: String? = {
            if !editedSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return editedSummary
            } else if let summaryIndex = selectedSummaryIndex {
                return recognizedItems[summaryIndex]
            } else {
                return nil
            }
        }()
        
        let instructionLines: [String] = {
            if !instructionGroups.isEmpty {
                return instructionGroups.map { group in group.map { recognizedItems[$0] }.joined(separator: " ") }
            } else {
                return selectedInstructionIndices.sorted().map { recognizedItems[$0] }
            }
        }()
        let instructions = instructionLines.joined(separator: "\n")
        let steps: [Step] = instructionLines.enumerated().map { index, line in
            Step(number: index + 1, step: line, ingredients: nil, equipment: nil, length: nil)
        }
        let analyzedInstructions: [AnalyzedInstruction] = [AnalyzedInstruction(name: nil, steps: steps.isEmpty ? nil : steps)]
        
        let ingredientLines: [String] = {
            if !ingredientGroups.isEmpty {
                return ingredientGroups.map { group in group.map { recognizedItems[$0] }.joined(separator: " ") }
            } else {
                return selectedIngredientIndices.sorted().map { recognizedItems[$0] }
            }
        }()
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
            "creditsText": credits.trimmingCharacters(in: .whitespacesAndNewlines),
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
            saveMessage = "Failed to create recipe from inputs."
            return
        }
        
        recipeStore.add(recipe)
        saveMessage = "Recipe saved!"
        logger.info("Recipe saved with title: \(title, privacy: .public)")
    }
}

#Preview {
    ImageToListView()
        .environment(RecipeStore())
}
