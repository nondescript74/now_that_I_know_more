//
//  RecipeBookModel.swift
//  NowThatIKnowMore
//
//  SwiftData model for recipe books (collections/categories)
//

import Foundation
import SwiftData

@Model
final class RecipeBookModel {
    @Attribute(.unique) var uuid: UUID
    var name: String
    var bookDescription: String?
    var colorHex: String? // Store color as hex string
    var iconName: String? // SF Symbol name
    var createdAt: Date
    var modifiedAt: Date
    var sortOrder: Int
    
    // Relationship to recipes (many-to-many)
    @Relationship var recipes: [RecipeModel]?
    
    init(
        uuid: UUID = UUID(),
        name: String,
        bookDescription: String? = nil,
        colorHex: String? = nil,
        iconName: String? = nil,
        sortOrder: Int = 0
    ) {
        self.uuid = uuid
        self.name = name
        self.bookDescription = bookDescription
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Computed Properties
extension RecipeBookModel {
    /// Number of recipes in this book
    var recipeCount: Int {
        recipes?.count ?? 0
    }
    
    /// Get the icon as an SF Symbol name or default
    var icon: String {
        iconName ?? "book.closed"
    }
}

// MARK: - Predefined Recipe Books
extension RecipeBookModel {
    static func createDefaultBooks() -> [RecipeBookModel] {
        return [
            RecipeBookModel(
                name: "Favorites",
                bookDescription: "My favorite recipes",
                colorHex: "#FF6B6B",
                iconName: "heart.fill",
                sortOrder: 0
            ),
            RecipeBookModel(
                name: "Quick & Easy",
                bookDescription: "Recipes ready in 30 minutes or less",
                colorHex: "#4ECDC4",
                iconName: "clock.fill",
                sortOrder: 1
            ),
            RecipeBookModel(
                name: "Healthy",
                bookDescription: "Nutritious and wholesome meals",
                colorHex: "#95E77D",
                iconName: "leaf.fill",
                sortOrder: 2
            ),
            RecipeBookModel(
                name: "Desserts",
                bookDescription: "Sweet treats and desserts",
                colorHex: "#FFE66D",
                iconName: "birthday.cake.fill",
                sortOrder: 3
            ),
            RecipeBookModel(
                name: "To Try",
                bookDescription: "Recipes I want to make",
                colorHex: "#A8DADC",
                iconName: "star.fill",
                sortOrder: 4
            )
        ]
    }
}
