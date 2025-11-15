//
//  IngredientImageView.swift
//  NowThatIKnowMore
//
//  A reusable view for displaying ingredient images with smart caching via SwiftData
//

import SwiftUI
import SwiftData

struct IngredientImageView: View {
    @Environment(\.modelContext) private var modelContext
    
    let ingredientID: Int?
    let ingredientName: String
    let size: CGFloat
    
    @State private var imageURL: URL?
    @State private var isLoading = true
    @State private var loadError = false
    
    init(ingredientID: Int?, ingredientName: String, size: CGFloat = 60) {
        self.ingredientID = ingredientID
        self.ingredientName = ingredientName
        self.size = size
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_):
                        placeholderImage(showError: true)
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        placeholderImage(showError: true)
                    }
                }
            } else {
                placeholderImage(showError: loadError)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func placeholderImage(showError: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: showError ? 
                            [Color.orange.opacity(0.2), Color.orange.opacity(0.1)] :
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            VStack(spacing: 4) {
                Image(systemName: showError ? "exclamationmark.triangle.fill" : "carrot.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(showError ? .orange.opacity(0.8) : .orange.opacity(0.6))
                
                if size > 50 {
                    Text(showError ? "Not Found" : "No Image")
                        .font(.system(size: size * 0.12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func loadImage() {
        // If we have no ID, we can't look up the image
        guard let id = ingredientID else {
            isLoading = false
            loadError = false
            return
        }
        
        Task { @MainActor in
            // Create service instance on main actor
            let service = IngredientImageMappingService(modelContext: modelContext)
            
            // Get image URL using the smart caching system
            let url = await service.getImageURL(forIngredientID: id, name: ingredientName)
            
            imageURL = url
            isLoading = false
            loadError = (url == nil)
            
            if url != nil {
                print("✅ [IngredientImageView] Loaded image for '\(ingredientName)' (ID: \(id)): \(url!.absoluteString)")
            } else {
                print("⚠️ [IngredientImageView] No image found for '\(ingredientName)' (ID: \(id))")
            }
        }
    }
}

// MARK: - Convenience Extensions

extension IngredientImageView {
    /// Create from an ExtendedIngredient
    init(ingredient: ExtendedIngredient, size: CGFloat = 60) {
        self.init(
            ingredientID: ingredient.id,
            ingredientName: ingredient.name ?? "Unknown",
            size: size
        )
    }
    
    /// Create from a SpoonacularIngredient
    init(spoonacularIngredient: SpoonacularIngredient, size: CGFloat = 60) {
        self.init(
            ingredientID: spoonacularIngredient.id,
            ingredientName: spoonacularIngredient.name,
            size: size
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Test with various sizes
        HStack {
            IngredientImageView(ingredientID: 11215, ingredientName: "garlic", size: 40)
            IngredientImageView(ingredientID: 11215, ingredientName: "garlic", size: 60)
            IngredientImageView(ingredientID: 11215, ingredientName: "garlic", size: 100)
        }
        
        // Test with missing image
        IngredientImageView(ingredientID: nil, ingredientName: "Unknown Ingredient", size: 60)
        
        // Test with specific ingredients
        HStack {
            IngredientImageView(ingredientID: 1001, ingredientName: "butter", size: 60)
            IngredientImageView(ingredientID: 9003, ingredientName: "apple", size: 60)
            IngredientImageView(ingredientID: 2028, ingredientName: "paprika", size: 60)
        }
    }
    .padding()
}
