//
//  RecipeOCRBoundingBoxEditor.swift
//  NowThatIKnowMore
//
//  Interactive bounding box editor for OCR recipe parsing
//  Allows users to define regions and group text for better parsing accuracy
//

import SwiftUI
@preconcurrency import Vision

// MARK: - Region Types

enum OCRRegionType: String, CaseIterable, Codable {
    case title = "Title"
    case servings = "Servings"
    case ingredients = "Ingredients"
    case instructions = "Instructions"
    case notes = "Notes"
    case ignore = "Ignore"
    
    var color: Color {
        switch self {
        case .title: return .purple
        case .servings: return .orange
        case .ingredients: return .green
        case .instructions: return .blue
        case .notes: return .yellow
        case .ignore: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .title: return "textformat.size"
        case .servings: return "person.2"
        case .ingredients: return "list.bullet"
        case .instructions: return "doc.text"
        case .notes: return "note.text"
        case .ignore: return "xmark.circle"
        }
    }
}

// MARK: - OCR Region Model

struct OCRRegion: Identifiable, Codable {
    let id: UUID
    var type: OCRRegionType
    var rect: CGRect
    var textObservations: [OCRTextObservation]
    var ingredientGroups: [[OCRTextObservation]] // For ingredients: group words into single ingredients
    
    init(id: UUID = UUID(), type: OCRRegionType, rect: CGRect, textObservations: [OCRTextObservation] = []) {
        self.id = id
        self.type = type
        self.rect = rect
        self.textObservations = textObservations
        self.ingredientGroups = []
    }
    
    var text: String {
        if type == .ingredients && !ingredientGroups.isEmpty {
            // Return grouped text for ingredients
            return ingredientGroups.map { group in
                group.map { $0.text }.joined(separator: " ")
            }.joined(separator: "\n")
        } else {
            // Return all text concatenated
            return textObservations.map { $0.text }.joined(separator: " ")
        }
    }
}

// MARK: - OCR Text Observation Model

struct OCRTextObservation: Identifiable, Codable, Sendable {
    let id: UUID
    let text: String
    let boundingBox: CGRect
    var groupID: UUID? // For grouping into ingredients
    
    nonisolated init(id: UUID = UUID(), text: String, boundingBox: CGRect, groupID: UUID? = nil) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.groupID = groupID
    }
}

// MARK: - Bounding Box Editor View

struct RecipeOCRBoundingBoxEditor: View {
    let image: UIImage
    let onComplete: ([OCRRegion]) -> Void
    let onCancel: () -> Void
    
    @State private var regions: [OCRRegion] = []
    @State private var detectedTextObservations: [OCRTextObservation] = []
    @State private var isDetectingText = true
    @State private var selectedRegion: OCRRegion?
    @State private var selectedRegionType: OCRRegionType = .ingredients
    @State private var isDrawingMode = false
    @State private var showTextOverlay = true
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var imageSize: CGSize = .zero
    @State private var showGroupingView = false
    @State private var zoomScale: CGFloat = 2.0
    @State private var showMiniMap = true
    @State private var scrollPosition: CGPoint = .zero
    @State private var showHelpOverlay = true
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Instructions
                        instructionsBar
                        
                        // Image with overlays
                        ZStack(alignment: .topTrailing) {
                            ScrollViewReader { scrollProxy in
                                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                                    imageWithOverlays(containerSize: geometry.size)
                                        .background(GeometryReader { imageGeometry in
                                            Color.clear.onAppear {
                                                imageSize = imageGeometry.size
                                            }
                                        })
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    let delta = value / zoomScale
                                                    zoomScale = min(max(1.0, zoomScale * delta), 5.0)
                                                }
                                        )
                                }
                            }
                            
                            // Mini-map
                            if showMiniMap && !isDetectingText {
                                MiniMapView(
                                    image: image,
                                    regions: regions,
                                    imageSize: calculateImageDisplaySize(containerSize: geometry.size),
                                    containerSize: geometry.size
                                )
                                .frame(width: 120, height: 160)
                                .padding(8)
                            }
                        }
                        
                        // Zoom controls
                        zoomControls
                        
                        // Bottom toolbar
                        bottomToolbar
                    }
                    
                    // Loading overlay
                    if isDetectingText {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Detecting text in image...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    
                    // Help overlay (first time)
                    if showHelpOverlay {
                        HelpOverlayView(onDismiss: {
                            withAnimation {
                                showHelpOverlay = false
                            }
                        })
                    }
                }
            }
            .navigationTitle("Define Regions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(regions)
                    }
                    .disabled(regions.isEmpty)
                }
            }
            .sheet(isPresented: $showGroupingView) {
                if let region = selectedRegion,
                   let index = regions.firstIndex(where: { $0.id == region.id }) {
                    IngredientGroupingView(
                        region: $regions[index],
                        onDismiss: { showGroupingView = false }
                    )
                }
            }
        }
        .onAppear {
            detectTextInImage()
        }
    }
    
    // MARK: - UI Components
    
    private var instructionsBar: some View {
        VStack(spacing: 8) {
            Text(isDrawingMode ? "Draw a rectangle to define a region" : "Tap a region to edit or select 'Draw Region' to add new")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if isDrawingMode {
                HStack(spacing: 15) {
                    ForEach(OCRRegionType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedRegionType = type
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                Text(type.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundColor(selectedRegionType == type ? .white : .gray)
                            .padding(8)
                            .background(selectedRegionType == type ? type.color : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color.black.opacity(0.8))
    }
    
    @ViewBuilder
    private func imageWithOverlays(containerSize: CGSize) -> some View {
        let displaySize = calculateImageDisplaySize(containerSize: containerSize)
        
        ZStack(alignment: .topLeading) {
            // Base image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: displaySize.width, height: displaySize.height)
            
            // Text observations overlay
            if showTextOverlay && !detectedTextObservations.isEmpty {
                ForEach(detectedTextObservations) { observation in
                    let rect = convertToDisplayCoordinates(observation.boundingBox, displaySize: displaySize)
                    
                    Rectangle()
                        .stroke(Color.cyan, lineWidth: 1)
                        .background(Color.cyan.opacity(0.1))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            
            // Existing regions
            ForEach(regions) { region in
                let rect = convertToDisplayCoordinates(region.rect, displaySize: displaySize)
                
                Rectangle()
                    .stroke(region.type.color, lineWidth: 3)
                    .background(region.type.color.opacity(0.2))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .onTapGesture {
                        if !isDrawingMode {
                            selectedRegion = region
                            if region.type == .ingredients {
                                showGroupingView = true
                            }
                        }
                    }
                
                // Region label
                Text(region.type.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(region.type.color)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: rect.minX + 40, y: rect.minY - 10)
            }
            
            // Drawing overlay
            if isDrawingMode, let start = dragStart, let current = dragCurrent {
                let drawRect = CGRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
                
                Rectangle()
                    .stroke(selectedRegionType.color, lineWidth: 3)
                    .background(selectedRegionType.color.opacity(0.2))
                    .frame(width: drawRect.width, height: drawRect.height)
                    .position(x: drawRect.midX, y: drawRect.midY)
            }
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .gesture(
            isDrawingMode ? DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStart == nil {
                        dragStart = value.location
                    }
                    dragCurrent = value.location
                }
                .onEnded { value in
                    finishDrawing(start: dragStart!, end: value.location, displaySize: displaySize)
                    dragStart = nil
                    dragCurrent = nil
                } : nil
        )
    }
    
    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button(action: {
                showMiniMap.toggle()
            }) {
                Image(systemName: showMiniMap ? "map.fill" : "map")
                    .foregroundColor(.white)
                    .padding(8)
            }
            
            Image(systemName: "minus.magnifyingglass")
                .foregroundColor(.white)
                .font(.caption)
            
            Slider(value: $zoomScale, in: 1.0...5.0, step: 0.5)
                .accentColor(.white)
                .frame(maxWidth: 200)
            
            Image(systemName: "plus.magnifyingglass")
                .foregroundColor(.white)
                .font(.caption)
            
            Text("\(Int(zoomScale * 100))%")
                .foregroundColor(.white)
                .font(.caption)
                .frame(minWidth: 50)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 15) {
            Button(action: {
                isDrawingMode.toggle()
                dragStart = nil
                dragCurrent = nil
            }) {
                Label(isDrawingMode ? "Cancel Drawing" : "Draw Region", systemImage: isDrawingMode ? "xmark" : "plus.rectangle.on.rectangle")
                    .foregroundColor(.white)
                    .padding()
                    .background(isDrawingMode ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                showTextOverlay.toggle()
            }) {
                Label(showTextOverlay ? "Hide Text" : "Show Text", systemImage: showTextOverlay ? "eye.slash" : "eye")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
            }
            
            if !regions.isEmpty {
                Button(action: {
                    regions.removeLast()
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Helper Functions
    
    private func calculateImageDisplaySize(containerSize: CGSize) -> CGSize {
        // Use the zoom scale to determine image size
        // This allows users to zoom and pan to draw precise bounding boxes
        let scaledWidth = image.size.width * zoomScale
        let scaledHeight = image.size.height * zoomScale
        
        return CGSize(width: scaledWidth, height: scaledHeight)
    }
    
    private func convertToDisplayCoordinates(_ normalizedRect: CGRect, displaySize: CGSize) -> CGRect {
        // Vision coordinates: origin at bottom-left, normalized 0-1
        // SwiftUI coordinates: origin at top-left, in points
        
        let x = normalizedRect.minX * displaySize.width
        let y = (1 - normalizedRect.maxY) * displaySize.height // Flip Y
        let width = normalizedRect.width * displaySize.width
        let height = normalizedRect.height * displaySize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func convertToNormalizedCoordinates(_ displayRect: CGRect, displaySize: CGSize) -> CGRect {
        // Convert back to Vision coordinates
        let x = displayRect.minX / displaySize.width
        let y = 1 - (displayRect.maxY / displaySize.height) // Flip Y back
        let width = displayRect.width / displaySize.width
        let height = displayRect.height / displaySize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func finishDrawing(start: CGPoint, end: CGPoint, displaySize: CGSize) {
        let drawRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        guard drawRect.width > 20 && drawRect.height > 20 else { return }
        
        let normalizedRect = convertToNormalizedCoordinates(drawRect, displaySize: displaySize)
        
        // Find text observations within this region
        let observationsInRegion = detectedTextObservations.filter { observation in
            normalizedRect.intersects(observation.boundingBox)
        }
        
        let newRegion = OCRRegion(
            type: selectedRegionType,
            rect: normalizedRect,
            textObservations: observationsInRegion
        )
        
        regions.append(newRegion)
        
        // Auto-open grouping view for ingredient regions
        if selectedRegionType == .ingredients {
            selectedRegion = newRegion
            isDrawingMode = false
            showGroupingView = true
        }
    }
    
    private func detectTextInImage() {
        guard let cgImage = image.cgImage else {
            isDetectingText = false
            return
        }
        
        // Perform Vision request off the main thread
        Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let observations = request.results else {
                    await MainActor.run {
                        isDetectingText = false
                    }
                    return
                }
                
                let textObs = observations.compactMap { observation -> OCRTextObservation? in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return OCRTextObservation(text: text, boundingBox: observation.boundingBox)
                }
                
                await MainActor.run {
                    detectedTextObservations = textObs
                    isDetectingText = false
                    print("✅ Detected \(textObs.count) text observations")
                }
            } catch {
                print("❌ Text detection error: \(error)")
                await MainActor.run {
                    isDetectingText = false
                }
            }
        }
    }
}

// MARK: - Ingredient Grouping View

struct IngredientGroupingView: View {
    @Binding var region: OCRRegion
    let onDismiss: () -> Void
    
    @State private var selectedObservations: Set<UUID> = []
    @State private var currentGroupColor: Color = .green
    
    private let groupColors: [Color] = [.green, .blue, .purple, .orange, .pink, .yellow, .red, .cyan]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Group words to form complete ingredients")
                        .font(.headline)
                    Text("Tap words in order, then tap 'Create Group'. Each row will be one ingredient line.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // Existing groups
                        if !region.ingredientGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ingredient Lines (\(region.ingredientGroups.count))")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(region.ingredientGroups.indices, id: \.self) { index in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                        Text(region.ingredientGroups[index].map { $0.text }.joined(separator: " "))
                                            .font(.subheadline)
                                        Spacer()
                                        Button(action: {
                                            deleteGroup(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(groupColors[index % groupColors.count].opacity(0.2))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                            
                            Divider()
                                .padding()
                        }
                        
                        // Available words
                        Text("Available Words")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Tap words to select them, then create a group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                            ForEach(region.textObservations) { observation in
                                let isInGroup = region.ingredientGroups.contains { group in
                                    group.contains { $0.id == observation.id }
                                }
                                
                                if !isInGroup {
                                    Button(action: {
                                        toggleSelection(observation)
                                    }) {
                                        Text(observation.text)
                                            .font(.subheadline)
                                            .padding(8)
                                            .background(selectedObservations.contains(observation.id) ? currentGroupColor.opacity(0.8) : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedObservations.contains(observation.id) ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Bottom actions
                VStack(spacing: 10) {
                    if !selectedObservations.isEmpty {
                        Text("Selected: \(selectedObservations.count) word\(selectedObservations.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                createGroup()
                            }) {
                                Label("Create Group", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: {
                                selectedObservations.removeAll()
                            }) {
                                Label("Clear", systemImage: "xmark")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Group Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(_ observation: OCRTextObservation) {
        if selectedObservations.contains(observation.id) {
            selectedObservations.remove(observation.id)
        } else {
            selectedObservations.insert(observation.id)
        }
    }
    
    private func createGroup() {
        guard !selectedObservations.isEmpty else { return }
        
        // Get observations in selection order
        let selectedObs = region.textObservations.filter { selectedObservations.contains($0.id) }
        
        // Sort by vertical position (top to bottom), then horizontal (left to right)
        let sortedObs = selectedObs.sorted { a, b in
            if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.02 {
                return a.boundingBox.midY > b.boundingBox.midY // Flip for Vision coords
            } else {
                return a.boundingBox.minX < b.boundingBox.minX
            }
        }
        
        region.ingredientGroups.append(sortedObs)
        selectedObservations.removeAll()
        
        // Cycle color for next group
        let currentIndex = groupColors.firstIndex(of: currentGroupColor) ?? 0
        currentGroupColor = groupColors[(currentIndex + 1) % groupColors.count]
    }
    
    private func deleteGroup(at index: Int) {
        region.ingredientGroups.remove(at: index)
    }
}

// MARK: - Help Overlay View

struct HelpOverlayView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Title
                VStack(spacing: 8) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Quick Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top)
                
                // Tips
                VStack(alignment: .leading, spacing: 16) {
                    helpItem(
                        icon: "hand.pinch",
                        title: "Zoom",
                        description: "Pinch to zoom or use the slider (100% - 500%)"
                    )
                    
                    helpItem(
                        icon: "map.fill",
                        title: "Mini-Map",
                        description: "View the entire image and your regions at a glance"
                    )
                    
                    helpItem(
                        icon: "rectangle.on.rectangle",
                        title: "Draw Regions",
                        description: "Tap 'Draw Region', select a type, then drag to create boxes"
                    )
                    
                    helpItem(
                        icon: "hand.tap",
                        title: "Edit Ingredients",
                        description: "Tap ingredient regions to group words into lines"
                    )
                    
                    helpItem(
                        icon: "eye",
                        title: "Text Overlay",
                        description: "Toggle to show/hide detected text boundaries"
                    )
                }
                .padding(.horizontal, 30)
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Got It!")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 400)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
    }
    
    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Mini Map View

struct MiniMapView: View {
    let image: UIImage
    let regions: [OCRRegion]
    let imageSize: CGSize
    let containerSize: CGSize
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Thumbnail image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 160)
            
            // Region overlays
            ForEach(regions) { region in
                let rect = convertToMiniMapCoordinates(region.rect)
                
                Rectangle()
                    .stroke(region.type.color, lineWidth: 1)
                    .background(region.type.color.opacity(0.3))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
        )
    }
    
    private func convertToMiniMapCoordinates(_ normalizedRect: CGRect) -> CGRect {
        let miniMapSize = CGSize(width: 120, height: 160)
        
        // Calculate aspect-fit size for the image within the minimap
        let imageAspect = image.size.width / image.size.height
        let miniMapAspect = miniMapSize.width / miniMapSize.height
        
        var displaySize: CGSize
        if imageAspect > miniMapAspect {
            // Image is wider - fit to width
            displaySize = CGSize(width: miniMapSize.width, height: miniMapSize.width / imageAspect)
        } else {
            // Image is taller - fit to height
            displaySize = CGSize(width: miniMapSize.height * imageAspect, height: miniMapSize.height)
        }
        
        // Vision coordinates: origin at bottom-left, normalized 0-1
        // SwiftUI coordinates: origin at top-left, in points
        let x = normalizedRect.minX * displaySize.width
        let y = (1 - normalizedRect.maxY) * displaySize.height // Flip Y
        let width = normalizedRect.width * displaySize.width
        let height = normalizedRect.height * displaySize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Preview

#if DEBUG
struct RecipeOCRBoundingBoxEditor_Previews: PreviewProvider {
    static var previews: some View {
        if let image = UIImage(systemName: "doc.text.image")?.withTintColor(.black, renderingMode: .alwaysOriginal) {
            RecipeOCRBoundingBoxEditor(
                image: image,
                onComplete: { regions in
                    print("Completed with \(regions.count) regions")
                },
                onCancel: {
                    print("Cancelled")
                }
            )
        }
    }
}
#endif
