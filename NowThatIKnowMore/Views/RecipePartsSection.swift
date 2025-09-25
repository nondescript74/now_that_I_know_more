import SwiftUI

struct RecipePartsSection: View {
    @Binding var imageUrlText: String
    @Binding var isImageCollapsed: Bool
    @Binding var useLocalImage: Bool
    @Binding var selectedImages: [UIImage]
    @Binding var recognizedItems: [String]
    @Binding var selectedTitleIndicesState: Set<Int>
    @Binding var selectedSummaryIndicesState: Set<Int>
    @Binding var editedTitle: String
    @Binding var editedSummary: String
    @Binding var credits: String
    @Binding var cookMinutes: String
    @Binding var servings: String
    
    @Binding var selectedCuisine: String
    @Binding var dragOverIndex: Int?
    @Binding var selectedIngredientIndices: Set<Int>
    @Binding var selectedInstructionIndices: Set<Int>
    @Binding var ingredientGroups: [[Int]]
    @Binding var instructionGroups: [[Int]]
    @Binding var groupingIngredient: [Int]
    @Binding var groupingInstruction: [Int]
    @Binding var saveMessage: String?
    @Binding var isProcessing: Bool
    @Binding var errorMessage: String?
    
    var cuisinesList: [String]
    
    var cleanSummary: (String) -> String
    var extractTotalMinutes: (String) -> String?
    var extractFirstNumber: (String) -> String?
    var extractCuisines: () -> [String]?
    var toggleIngredientGrouped: (Int) -> Void
    var toggleInstructionGrouped: (Int) -> Void
    var mergeRecognizedItems: (_ source: Int, _ destination: Int) -> Void
    var canSaveRecipe: Bool
    var saveAsRecipe: () -> Void
    var joinedSelectedTitle: String
    var joinedSelectedSummary: String
    var joinedSelectedIngredients: [String]
    var joinedSelectedInstructions: [String]

    private var trimmedUrlText: String { imageUrlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var validUrl: URL? { URL(string: trimmedUrlText) }
    private var hasValidUrl: Bool {
        let trimmed = trimmedUrlText
        let url = validUrl
        guard !trimmed.isEmpty, let url, let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    var body: some View {
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
            
            // Show image usage toggle if both local images and valid URL exist
            if !selectedImages.isEmpty && self.hasValidUrl {
                Picker("Image Source", selection: $useLocalImage) {
                    Text("Use Local Photo(s)").tag(true)
                    Text("Use Web URL").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 4)
            }
            
            // Show clear button for selectedImages if present
            if !selectedImages.isEmpty {
                HStack(spacing: 8) {
                    Text("Local Photo\(selectedImages.count > 1 ? "s" : "") Selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button(action: {
                        self.selectedImages.removeAll()
                        self.recognizedItems.removeAll()
                        self.saveMessage = nil
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear local photo(s)")
                }
            }
            
            // Show collapse/show button and image for first selectedImage or URL depending on useLocalImage
            if !self.isImageCollapsed {
                if self.useLocalImage {
                    if !selectedImages.isEmpty {
                        Image(uiImage: selectedImages[0])
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
                    } else if !selectedImages.isEmpty {
                        EmptyView().onAppear { self.useLocalImage = true }
                    }
                }
            }
            
            // Show collapse/show button if either local image(s) or valid URL image present
            if (!selectedImages.isEmpty || self.hasValidUrl) {
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
                        // .onDrag and .onDrop commented out in original code remain same
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

                // Allow user to select credits from recognized text or enter manually
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credits")
                        .font(.subheadline)
                    if !recognizedItems.isEmpty {
                        Picker(selection: Binding(
                            get: {
                                // If the current credits matches a line, use its index, else -1 for custom
                                recognizedItems.firstIndex(where: { $0 == credits }) ?? -1
                            },
                            set: { idx in
                                if idx >= 0, idx < recognizedItems.count {
                                    credits = recognizedItems[idx]
                                }
                            }
                        ), label: Text("Select from text or enter manually")) {
                            Text("Custom...").tag(-1)
                            ForEach(recognizedItems.indices.filter { !recognizedItems[$0].trimmingCharacters(in: .whitespaces).isEmpty }, id: \.self) { i in
                                Text(recognizedItems[i]).tag(i)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    TextField("Enter credits (e.g. source or author)", text: $credits)
                        .textFieldStyle(.roundedBorder)
                }

                // Cook Minutes and Servings selection
                // Allow user to select cook time from recognized text or enter manually
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cook Minutes")
                        .font(.subheadline)
                    if !recognizedItems.isEmpty {
                        Picker(selection: Binding(
                            get: {
                                recognizedItems.firstIndex(where: { $0 == cookMinutes }) ?? -1
                            },
                            set: { idx in
                                if idx >= 0, idx < recognizedItems.count {
                                    // Updated to use extractTotalMinutes helper
                                    cookMinutes = extractTotalMinutes(recognizedItems[idx]) ?? extractFirstNumber(recognizedItems[idx]) ?? recognizedItems[idx]
                                }
                            }
                        ), label: Text("Select from text or enter manually")) {
                            Text("Custom...").tag(-1)
                            ForEach(recognizedItems.indices.filter { recognizedItems[$0].contains("min") || recognizedItems[$0].contains(":") || recognizedItems[$0].contains("hour") || recognizedItems[$0].contains("cook") || recognizedItems[$0].contains("time") || recognizedItems[$0].rangeOfCharacter(from: .decimalDigits) != nil }, id: \.self) { i in
                                Text(recognizedItems[i]).tag(i)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    TextField("e.g. 45 (minutes)", text: $cookMinutes)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }

                // Allow user to select servings from recognized text or enter manually
                VStack(alignment: .leading, spacing: 4) {
                    Text("Servings")
                        .font(.subheadline)
                    if !recognizedItems.isEmpty {
                        Picker(selection: Binding(
                            get: {
                                recognizedItems.firstIndex(where: { $0 == servings }) ?? -1
                            },
                            set: { idx in
                                if idx >= 0, idx < recognizedItems.count {
                                    servings = extractFirstNumber(recognizedItems[idx]) ?? recognizedItems[idx]
                                }
                            }
                        ), label: Text("Select from text or enter manually")) {
                            Text("Custom...").tag(-1)
                            ForEach(recognizedItems.indices.filter { recognizedItems[$0].lowercased().contains("serv") || recognizedItems[$0].rangeOfCharacter(from: .decimalDigits) != nil }, id: \.self) { i in
                                Text(recognizedItems[i]).tag(i)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    TextField("e.g. 4", text: $servings)
                        .keyboardType(.numberPad)
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
                
                // More Info (Cook Minutes and Servings)
                if !self.cookMinutes.trimmingCharacters(in: .whitespaces).isEmpty || !self.servings.trimmingCharacters(in: .whitespaces).isEmpty {
                    HStack(spacing: 16) {
                        if !self.cookMinutes.trimmingCharacters(in: .whitespaces).isEmpty {
                            Label("\(self.cookMinutes) min", systemImage: "clock")
                                .font(.subheadline)
                        }
                        if !self.servings.trimmingCharacters(in: .whitespaces).isEmpty {
                            Label("Serves \(self.servings)", systemImage: "person.2")
                                .font(.subheadline)
                        }
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
                                         self.mergeRecognizedItems(draggedIdx, i)
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
                                         self.mergeRecognizedItems(draggedIdx, i)
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
}

