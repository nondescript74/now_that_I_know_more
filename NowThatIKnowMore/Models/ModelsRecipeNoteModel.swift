//
//  RecipeNoteModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for user notes on recipes
//

import Foundation
import SwiftData

@Model
final class RecipeNoteModel {
    @Attribute(.unique) var uuid: UUID
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var isPinned: Bool
    var tags: String? // Comma-separated tags
    
    // Relationship back to recipe
    var recipe: RecipeModel?
    
    init(
        uuid: UUID = UUID(),
        content: String = "",
        isPinned: Bool = false,
        tags: [String] = [],
        recipe: RecipeModel? = nil
    ) {
        self.uuid = uuid
        self.content = content
        self.isPinned = isPinned
        self.tags = tags.joined(separator: ",")
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.recipe = recipe
    }
}

// MARK: - Computed Properties
extension RecipeNoteModel {
    var tagsList: [String] {
        get { tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { 
            tags = newValue.joined(separator: ",")
            modifiedAt = Date()
        }
    }
    
    /// Preview text for the note (first 100 characters)
    var preview: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(100)) + "..."
    }
}
