import SwiftUI
import PhotosUI
import Vision
import OSLog
import Combine

struct ImageToListView: View {
    @Environment(RecipeStore.self) private var recipeStore
    
    // Changed from single item/image to multiple selection and images
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var recognizedTextBlocks: [[String]] = [] // OCR results per image
    @State private var textBlockOffsets: [Int] = [] // Number of blank lines before each block
    
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
    
    // --- New states for deduplication and duplicate review ---
    @State private var deduplicatedItems: [String] = []
    @State private var duplicateInfo: [(index: Int, text: String)] = [] // Stores removed duplicates and their positions
    @State private var restoredDuplicates: Set<Int> = [] // Indices in duplicateInfo the user wants to restore
    @State private var showDeduplicationReview: Bool = false

    // Cook Minutes and Servings selection
    @SceneStorage("itl_cookMinutes") private var cookMinutes: String = ""
    @SceneStorage("itl_servings") private var servings: String = ""
    
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
    
    /// Combine recognized text blocks into final recognizedItems array, applying line offsets (blank lines)
    private func combinedRecognizedItems() -> [String] {
        var result: [String] = []
        for (block, offset) in zip(recognizedTextBlocks, textBlockOffsets) {
            result.append(contentsOf: Array(repeating: "", count: max(0, offset)))
            result.append(contentsOf: block)
        }
        return result
    }
    
    /// Deduplicate lines keeping info about removed duplicates for possible restoration
    private func deduplicateLinesWithInfo(_ lines: [String]) -> ([String], [(index: Int, text: String)]) {
        var seen = Set<String>()
        var deduped: [String] = []
        var removed: [(Int, String)] = []
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { deduped.append(line); continue }
            if seen.contains(trimmed) {
                removed.append((idx, line))
            } else {
                seen.insert(trimmed)
                deduped.append(line)
            }
        }
        return (deduped, removed)
    }
    
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "ImageToListView")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // PhotosPicker with multiple selection, max 5 images
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Select up to 5 Images")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .onChange(of: selectedItems) { _, newItems in
                    Task {
                        await loadImages(from: newItems)
                    }
                }
                
                // Show recognizedTextBlocks to order and offset lines before final combined recognizedItems
                // Only show if deduplication review is not active and recognizedItems is empty (i.e. before continue)
                if recognizedTextBlocks.count > 1 && !showDeduplicationReview && recognizedItems.isEmpty {
                    VStack(spacing: 12) {
                        Text("Arrange Recognized Text Blocks")
                            .font(.headline)
                        
                        ForEach(recognizedTextBlocks.indices, id: \.self) { i in
                            VStack(alignment: .leading) {
                                HStack(alignment: .center, spacing: 12) {
                                    if i < selectedImages.count {
                                        Image(uiImage: selectedImages[i])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(6)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Block #\(i+1)")
                                            .font(.subheadline)
                                            .bold()
                                        Text("\(recognizedTextBlocks[i].count) lines recognized")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        // Move up if possible
                                        guard i > 0 else { return }
                                        recognizedTextBlocks.swapAt(i, i-1)
                                        textBlockOffsets.swapAt(i, i-1)
                                    }) {
                                        Image(systemName: "arrow.up.circle")
                                            .font(.title2)
                                    }
                                    .disabled(i == 0)
                                    Button(action: {
                                        // Move down if possible
                                        guard i < recognizedTextBlocks.count - 1 else { return }
                                        recognizedTextBlocks.swapAt(i, i+1)
                                        textBlockOffsets.swapAt(i, i+1)
                                    }) {
                                        Image(systemName: "arrow.down.circle")
                                            .font(.title2)
                                    }
                                    .disabled(i == recognizedTextBlocks.count - 1)
                                }
                                HStack {
                                    Text("Lines before: \(textBlockOffsets[i])")
                                    Spacer()
                                    Stepper(value: Binding(
                                        get: { textBlockOffsets[i] },
                                        set: { newValue in
                                            guard newValue >= 0 else { return }
                                            textBlockOffsets[i] = newValue
                                        }
                                    ), in: 0...20) {
                                        EmptyView()
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Combined Text Preview:")
                                .font(.headline)
                            ScrollView {
                                Text(combinedRecognizedItems().joined(separator: "\n"))
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        Button("Continue") {
                            // Deduplicate lines and save removed lines info for review
                            let (deduped, removed) = deduplicateLinesWithInfo(self.combinedRecognizedItems())
                            self.deduplicatedItems = deduped
                            self.duplicateInfo = removed
                            self.restoredDuplicates = []
                            self.showDeduplicationReview = !removed.isEmpty
                            if removed.isEmpty {
                                // No duplicates, proceed as before
                                self.recognizedItems = deduped
                                self.selectedTitleIndicesState = self.selectedTitleIndices
                                self.selectedSummaryIndicesState = self.selectedSummaryIndices
                                if self.editedTitle.isEmpty { self.editedTitle = self.joinedSelectedTitle }
                                if self.editedSummary.isEmpty { self.editedSummary = self.joinedSelectedSummary }
                                self.saveMessage = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Deduplication review UI shown when duplicates were removed
                if showDeduplicationReview {
                    VStack(spacing: 12) {
                        Text("Duplicate lines detected and removed.").bold()
                        Text("Review and restore any lines below if needed.")
                        ForEach(duplicateInfo.indices, id: \.self) { i in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { restoredDuplicates.contains(i) },
                                    set: { checked in
                                        if checked { restoredDuplicates.insert(i) } else { restoredDuplicates.remove(i) }
                                    })
                                ) {
                                    Text(duplicateInfo[i].text)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        Button("Apply & Continue") {
                            // Reconstruct recognizedItems, restoring selected duplicates to their original positions
                            var items = deduplicatedItems
                            // Insert restored duplicate lines at their original indices offset by previously inserted lines
                            for (offset, idx) in restoredDuplicates.sorted().enumerated() {
                                let info = duplicateInfo[idx]
                                let insertAt = info.index + offset
                                if insertAt <= items.count {
                                    items.insert(info.text, at: insertAt)
                                } else {
                                    items.append(info.text)
                                }
                            }
                            self.recognizedItems = items
                            self.showDeduplicationReview = false
                            self.selectedTitleIndicesState = self.selectedTitleIndices
                            self.selectedSummaryIndicesState = self.selectedSummaryIndices
                            if self.editedTitle.isEmpty { self.editedTitle = self.joinedSelectedTitle }
                            if self.editedSummary.isEmpty { self.editedSummary = self.joinedSelectedSummary }
                            self.saveMessage = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                }
                
                // Show recipePartsSection only if recognizedItems is not empty and no deduplication review is active
                if !recognizedItems.isEmpty && !showDeduplicationReview {
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
            // Remove mergedImage and imageOffsets related onChange triggers, just keep imageUrlText for URL handling
            .onChange(of: imageUrlText) { _, newText in
                if self.hasValidUrl && self.recognizedItems.isEmpty {
                    self.useLocalImage = false
                } else if !self.recognizedItems.isEmpty {
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
                        self.recognizedTextBlocks.removeAll()
                        self.textBlockOffsets.removeAll()
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
                                    cookMinutes = extractTotalMinutes(from: recognizedItems[idx]) ?? extractFirstNumber(from: recognizedItems[idx]) ?? recognizedItems[idx]
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
                                    servings = extractFirstNumber(from: recognizedItems[idx]) ?? recognizedItems[idx]
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
        // This function stub can be expanded if recipe.cuisines is added later.
        return nil
    }
    
    /// Load multiple images from array of PhotosPickerItem
    private func loadImages(from items: [PhotosPickerItem]) async {
        self.isProcessing = true
        self.errorMessage = nil
        var loadedImages: [UIImage] = []
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
                return
            }
        }
        
        DispatchQueue.main.async {
            self.selectedImages = loadedImages
            self.recognizedTextBlocks.removeAll()
            self.textBlockOffsets.removeAll()
            self.recognizedItems.removeAll()
            self.saveMessage = nil
        }
        
        // Recognize text for each image and store results separately
        var blocks: [[String]] = []
        for image in loadedImages {
            let lines = await recognizeTextForMerge(in: image)
            blocks.append(lines)
        }
        
        DispatchQueue.main.async {
            self.recognizedTextBlocks = blocks
            self.textBlockOffsets = Array(repeating: 0, count: blocks.count)
            // Initially do not set recognizedItems until user presses "Continue"
            self.isProcessing = false
        }
    }
    
    /// Recognize text for a single image and return lines (no state update)
    @MainActor
    private func recognizeTextForMerge(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else {
            return []
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        
        guard let observations = request.results else {
            return []
        }
        
        let allText = observations.compactMap { $0.topCandidates(1).first?.string }
        return allText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
        // if useLocalImage == true and selectedImage present -> save first selected image
        // else if useLocalImage == false and valid URL present -> use URL
        // else if only one option is present, default to that
        
        var imagePath: String? = nil
        
        if self.useLocalImage {
            if let firstImage = self.selectedImages.first {
                imagePath = saveImageToDocuments(uiImage: firstImage, for: newUUID)
            } else if self.hasValidUrl {
                imagePath = self.trimmedUrlText
            }
        } else {
            if self.hasValidUrl {
                imagePath = self.trimmedUrlText
            } else if let firstImage = self.selectedImages.first {
                imagePath = saveImageToDocuments(uiImage: firstImage, for: newUUID)
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
        
        // Cook Minutes and Servings parsing
        let cookMinutesInt: Int? = Int(cookMinutes.trimmingCharacters(in: .whitespacesAndNewlines))
        let servingsInt: Int? = Int(servings.trimmingCharacters(in: .whitespacesAndNewlines))

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
            "readyInMinutes": cookMinutesInt as Any,
            "servings": servingsInt ?? servings as Any,
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
    
    // Extract first integer from a string (for cook time/servings)
    private func extractFirstNumber(from text: String) -> String? {
        let pattern = "\\d{1,4}"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }
    
    // Extracts total minutes (e.g., "1 hour 30 minutes" -> "90")
    /// Extracts total minutes from text like "1 hour 20 min" or "90 min" (returns nil if not found)
    private func extractTotalMinutes(from text: String) -> String? {
        let lower = text.lowercased()
        let hourPattern = "(\\d+)\\s*(hour|hr|hrs)"
        let minutePattern = "(\\d+)\\s*(minute|min|mins)"
        var total = 0
        var found = false
        if let hourMatch = lower.range(of: hourPattern, options: .regularExpression) {
            let hourStr = String(lower[hourMatch])
            if let hourNum = Int(hourStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                total += hourNum * 60
                found = true
            }
        }
        if let minMatch = lower.range(of: minutePattern, options: .regularExpression) {
            let minStr = String(lower[minMatch])
            if let minNum = Int(minStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                total += minNum
                found = true
            }
        }
        // If no patterns matched, fallback to first number
        if !found {
            return extractFirstNumber(from: text)
        }
        return total > 0 ? String(total) : nil
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
