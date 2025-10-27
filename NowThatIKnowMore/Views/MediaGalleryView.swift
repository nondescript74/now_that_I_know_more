//
//  MediaGalleryView.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 10/24/25.
//

import SwiftUI
import PhotosUI
import AVKit

/// A view that displays a gallery of media items and allows selection of a featured item
struct MediaGalleryView: View {
    let mediaItems: [RecipeMedia]
    let featuredMediaID: UUID?
    let onSelectFeatured: (UUID) -> Void
    let onAddMedia: ([RecipeMedia]) -> Void
    let onRemoveMedia: (UUID) -> Void
    
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingPhotoPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Media Gallery")
                    .font(.headline)
                Spacer()
                Button {
                    showingPhotoPicker = true
                } label: {
                    Label("Add Photos/Videos", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            if mediaItems.isEmpty {
                ContentUnavailableView {
                    Label("No Media", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Add photos or videos to your recipe")
                } actions: {
                    Button("Add Media") {
                        showingPhotoPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mediaItems) { media in
                            MediaThumbnailView(
                                media: media,
                                isFeatured: media.id == featuredMediaID,
                                onTap: {
                                    onSelectFeatured(media.id)
                                },
                                onRemove: {
                                    onRemoveMedia(media.id)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await loadMediaItems(from: newItems)
            }
        }
    }
    
    private func loadMediaItems(from items: [PhotosPickerItem]) async {
        var newMediaItems: [RecipeMedia] = []
        
        for item in items {
            // Try to load as image first
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Save to documents directory
                if let url = saveImageToDocuments(image: image) {
                    let media = RecipeMedia(url: url.path, type: .photo)
                    newMediaItems.append(media)
                }
            }
            // Could also handle video here - for now just handle photos
        }
        
        if !newMediaItems.isEmpty {
            onAddMedia(newMediaItems)
        }
        
        // Clear selection
        selectedPhotoItems = []
    }
    
    private func saveImageToDocuments(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recipe_\(UUID().uuidString).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
}

/// A thumbnail view for a single media item
private struct MediaThumbnailView: View {
    let media: RecipeMedia
    let isFeatured: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                ZStack {
                    if media.type == .photo {
                        PhotoThumbnail(url: media.url)
                    } else {
                        VideoThumbnail(url: media.url)
                    }
                    
                    if isFeatured {
                        VStack {
                            Spacer()
                            HStack {
                                Label("Featured", systemImage: "star.fill")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.gradient, in: Capsule())
                                Spacer()
                            }
                            .padding(8)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .padding(8)
            .confirmationDialog(
                "Remove this media?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    onRemove()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .frame(width: 120, height: 120)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isFeatured ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
}

private struct PhotoThumbnail: View {
    let url: String
    
    var body: some View {
        // First check if it's a web URL
        if let nsURL = URL(string: url),
           nsURL.scheme == "http" || nsURL.scheme == "https" {
            AsyncImage(url: nsURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            // Try loading as local file
            loadLocalImage
        }
    }
    
    @ViewBuilder
    private var loadLocalImage: some View {
        // Try multiple approaches to load local file
        if let uiImage = loadImage() {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipped()
        } else {
            placeholderImage
        }
    }
    
    private func loadImage() -> UIImage? {
        // Debug: Uncomment to see what URLs are being loaded
        // print("📷 Attempting to load image from: \(url)")
        
        // Method 1: Try as absolute file path
        if url.hasPrefix("/") {
            let fileURL = URL(fileURLWithPath: url)
            if let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                // print("✅ Loaded image via absolute path")
                return image
            }
        }
        
        // Method 2: Try URL(string:) and then as file URL
        if let nsURL = URL(string: url) {
            if let data = try? Data(contentsOf: nsURL),
               let image = UIImage(data: data) {
                // print("✅ Loaded image via URL(string:)")
                return image
            }
        }
        
        // Method 3: Try constructing file URL from path
        let fileURL = URL(fileURLWithPath: url)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // print("✅ Loaded image via fileURLWithPath")
            return image
        }
        
        // print("❌ Failed to load image from all methods")
        return nil
    }
    
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundColor(.gray)
            .frame(width: 120, height: 120)
    }
}

private struct VideoThumbnail: View {
    let url: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("Video")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .frame(width: 120, height: 120)
    }
}

#Preview {
    MediaGalleryView(
        mediaItems: [
            RecipeMedia(url: "https://example.com/image1.jpg", type: .photo),
            RecipeMedia(url: "https://example.com/image2.jpg", type: .photo),
            RecipeMedia(url: "https://example.com/video1.mp4", type: .video)
        ],
        featuredMediaID: nil,
        onSelectFeatured: { _ in },
        onAddMedia: { _ in },
        onRemoveMedia: { _ in }
    )
    .padding()
}
