//
//  RecipeMedia.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 10/24/25.
//

import Foundation

/// Represents a media item (photo or video) associated with a recipe
struct RecipeMedia: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let url: String
    let type: MediaType
    
    enum MediaType: String, Codable, Sendable {
        case photo
        case video
    }
    
    init(id: UUID = UUID(), url: String, type: MediaType) {
        self.id = id
        self.url = url
        self.type = type
    }
}
