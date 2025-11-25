//
//  RecipeOCRTypes.swift
//  NowThatIKnowMore
//
//  Shared types for OCR recipe parsing
//  These types are used across the app and should be included in all targets
//

import SwiftUI
import Foundation

// MARK: - Region Types

enum OCRRegionType: String, CaseIterable, Codable, Sendable {
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

struct OCRRegion: Identifiable, Codable, Sendable {
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
