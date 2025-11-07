//
//  RecipeMediaView.swift
//  NowThatIKnowMore
//
//  View for managing recipe media (photos and videos)
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeMediaView: View {
    @Environment(\.modelContext) private var modelContext
    let recipe: RecipeModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var sortedMedia: [RecipeMediaModel] {
        recipe.mediaItems?.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add media buttons
                HStack(spacing: 16) {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label("Choose Photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        Task {
                            await loadSelectedPhotos(newItems)
                        }
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                
                // Media grid
                if sortedMedia.isEmpty {
                    ContentUnavailableView {
                        Label("No Photos", systemImage: "photo.on.rectangle.angled")
                    } description: {
                        Text("Add photos of your recipe to remember what it looks like")
                    }
                    .frame(height: 300)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(sortedMedia) { media in
                            MediaThumbnail(media: media, recipe: recipe)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Recipe Photos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                addPhoto(image)
            }
        }
    }
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    addPhoto(image)
                }
            }
        }
        selectedItems = []
    }
    
    private func addPhoto(_ image: UIImage) {
        guard let fileURL = RecipeMediaModel.saveImage(image, for: recipe.uuid) else {
            return
        }
        
        // Create thumbnail
        let thumbnail = RecipeMediaModel.createThumbnail(from: image)
        var thumbnailURL: String?
        if let thumbnail = thumbnail {
            thumbnailURL = RecipeMediaModel.saveImage(thumbnail, for: recipe.uuid)
        }
        
        let media = RecipeMediaModel(
            fileURL: fileURL,
            thumbnailURL: thumbnailURL,
            type: .photo,
            sortOrder: (recipe.mediaItems?.count ?? 0),
            recipe: recipe
        )
        
        modelContext.insert(media)
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Media Thumbnail

struct MediaThumbnail: View {
    @Environment(\.modelContext) private var modelContext
    let media: RecipeMediaModel
    let recipe: RecipeModel
    @State private var showDetail = false
    @State private var showDeleteAlert = false
    
    var isFeatured: Bool {
        recipe.featuredMediaID == media.uuid
    }
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            ZStack(alignment: .topTrailing) {
                // Image
                if let image = media.loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 180)
                        .overlay {
                            ProgressView()
                        }
                }
                
                // Featured badge
                if isFeatured {
                    Label("Featured", systemImage: "star.fill")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                setAsFeatured()
            } label: {
                Label("Set as Featured", systemImage: "star.fill")
            }
            .disabled(isFeatured)
            
            Button {
                addCaption()
            } label: {
                Label("Add Caption", systemImage: "text.quote")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMedia()
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
        .sheet(isPresented: $showDetail) {
            MediaDetailView(media: media, recipe: recipe)
        }
    }
    
    private func setAsFeatured() {
        recipe.featuredMediaID = media.uuid
        recipe.preferFeaturedMedia = true
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
    
    private func addCaption() {
        // This would open a caption editor
        showDetail = true
    }
    
    private func deleteMedia() {
        media.deleteFile()
        
        // If this was the featured media, clear it
        if recipe.featuredMediaID == media.uuid {
            recipe.featuredMediaID = nil
        }
        
        modelContext.delete(media)
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Media Detail View

struct MediaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let media: RecipeMediaModel
    let recipe: RecipeModel
    @State private var caption: String
    
    init(media: RecipeMediaModel, recipe: RecipeModel) {
        self.media = media
        self.recipe = recipe
        _caption = State(initialValue: media.caption ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Full size image
                if let image = media.loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Caption editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                    
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCaption()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveCaption() {
        media.caption = caption.isEmpty ? nil : caption
        media.modifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completion(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    let container = try! ModelContainer.preview()
    let context = container.mainContext
    
    let recipe = RecipeModel(
        title: "Sample Recipe",
        servings: 4,
        vegetarian: true
    )
    context.insert(recipe)
    
    return NavigationStack {
        RecipeMediaView(recipe: recipe)
    }
    .modelContainer(container)
}
