//
//  RecipeMediaModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for recipe media (user photos, videos)
//

import Foundation
import SwiftData
import UIKit

@Model
final class RecipeMediaModel {
    @Attribute(.unique) var uuid: UUID
    var fileURL: String
    var thumbnailURL: String?
    var caption: String?
    var typeRawValue: String
    var createdAt: Date
    var modifiedAt: Date
    var sortOrder: Int
    
    // Relationship back to recipe
    var recipe: RecipeModel?
    
    init(
        uuid: UUID = UUID(),
        fileURL: String,
        thumbnailURL: String? = nil,
        caption: String? = nil,
        type: MediaType = .photo,
        sortOrder: Int = 0,
        recipe: RecipeModel? = nil
    ) {
        self.uuid = uuid
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.typeRawValue = type.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.recipe = recipe
    }
    
    enum MediaType: String, Codable {
        case photo
        case video
    }
    
    var type: MediaType {
        get { MediaType(rawValue: typeRawValue) ?? .photo }
        set { 
            typeRawValue = newValue.rawValue
            modifiedAt = Date()
        }
    }
}

// MARK: - Helper Methods
extension RecipeMediaModel {
    /// Save an image to the app's documents directory
    static func saveImage(_ image: UIImage, for recipeID: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaFolder = documentsPath.appendingPathComponent("RecipeMedia", isDirectory: true)
        
        // Create media folder if it doesn't exist
        try? FileManager.default.createDirectory(at: mediaFolder, withIntermediateDirectories: true)
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = mediaFolder.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    /// Create a thumbnail for an image
    static func createThumbnail(from image: UIImage) -> UIImage? {
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Load image from file URL
    func loadImage() -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileURL)) else { return nil }
        return UIImage(data: data)
    }
    
    /// Delete media file from disk
    func deleteFile() {
        try? FileManager.default.removeItem(atPath: fileURL)
        if let thumbnailURL = thumbnailURL {
            try? FileManager.default.removeItem(atPath: thumbnailURL)
        }
    }
}
