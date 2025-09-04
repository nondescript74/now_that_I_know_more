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
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
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
                        HStack {
                            Text("Summary")
                            Picker("Summary", selection: $selectedSummaryIndex) {
                                Text("None").tag(Optional<Int>(nil))
                                ForEach(recognizedItems.indices, id: \.self) { i in
                                    Text(recognizedItems[i]).tag(Optional(i))
                                }
                            }
                        }
                        VStack(alignment: .leading) {
                            Text("Select Ingredients").font(.subheadline)
                            ForEach(recognizedItems.indices, id: \.self) { i in
                                Button(action: { toggleIngredientSelected(i) }) {
                                    HStack {
                                        Image(systemName: selectedIngredientIndices.contains(i) ? "checkmark.circle.fill" : "circle")
                                        Text(recognizedItems[i])
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                        VStack(alignment: .leading) {
                            Text("Select Instructions").font(.subheadline)
                            ForEach(recognizedItems.indices, id: \.self) { i in
                                Button(action: { toggleInstructionSelected(i) }) {
                                    HStack {
                                        Image(systemName: selectedInstructionIndices.contains(i) ? "checkmark.circle.fill" : "circle")
                                        Text(recognizedItems[i])
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                        Button("Save as Recipe") {
                            saveAsRecipe()
                        }
                        .disabled(selectedTitleIndex == nil || selectedIngredientIndices.isEmpty || selectedInstructionIndices.isEmpty)
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
    
    private func saveAsRecipe() {
        guard let titleIndex = selectedTitleIndex else {
            saveMessage = "Please select a title."
            return
        }
        
        let title = recognizedItems[titleIndex]
        let summary: String? = {
            if let summaryIndex = selectedSummaryIndex {
                return recognizedItems[summaryIndex]
            } else {
                return nil
            }
        }()
        
        
        let instructionLines = selectedInstructionIndices
            .sorted()
            .map { i in
                recognizedItems[i]
            }
        let instructions = instructionLines.joined(separator: "\n")
        let steps: [Step] = instructionLines.enumerated().map { index, line in
            Step(number: index + 1, step: line, ingredients: nil, equipment: nil, length: nil)
        }
        let analyzedInstructions: [AnalyzedInstruction] = [AnalyzedInstruction(name: nil, steps: steps.isEmpty ? nil : steps)]
        
        var ingredients: [ExtendedIngredient] = []
        for (index, selectedIndex) in selectedIngredientIndices.sorted().enumerated() {
            ingredients.append(
                ExtendedIngredient(
                    id: index,
                    aisle: "no aisle",
                    image: "no image",
                    consistency: Consistency.solid,
                    name: recognizedItems[selectedIndex],
                    nameClean: recognizedItems[selectedIndex],
                    original: recognizedItems[selectedIndex],
                    originalName: recognizedItems[selectedIndex],
                    amount: 0,
                    unit: "no unit",
                    meta: ["no meta"],
                    measures: Measures(us: Metric(amount: 0, unitShort: "0", unitLong: "0"), metric: Metric(amount: 0, unitShort: "0", unitLong: "0"))
                )
            )
        }
        
        let dict: [String: Any] = [
            "title": title.isEmpty ? "Untitled" : title,
            "summary": summary as Any,
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
