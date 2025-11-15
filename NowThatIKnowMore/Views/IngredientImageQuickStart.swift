//
//  IngredientImageQuickStart.swift
//  NowThatIKnowMore
//
//  Quick reference examples for using the ingredient image system
//

import SwiftUI
import SwiftData

// MARK: - Example 1: Basic Usage in a List

struct RecipeIngredientsListExample: View {
    let ingredients: [ExtendedIngredient]
    
    var body: some View {
        List(ingredients, id: \.id) { ingredient in
            HStack(spacing: 12) {
                // Just add this one line!
                IngredientImageView(ingredient: ingredient, size: 50)
                
                VStack(alignment: .leading) {
                    Text(ingredient.name ?? "Unknown")
                        .font(.body)
                    Text(ingredient.original ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Example 2: Recipe Card with Ingredient Preview

struct RecipeCardWithIngredientsExample: View {
    let recipe: RecipeModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.title ?? "Untitled")
                .font(.headline)
            
            // Show first 4 ingredient images
            HStack(spacing: 8) {
                ForEach(recipe.extendedIngredients?.prefix(4) ?? [], id: \.id) { ingredient in
                    IngredientImageView(ingredient: ingredient, size: 40)
                }
                
                if let count = recipe.extendedIngredients?.count, count > 4 {
                    Text("+\(count - 4)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Example 3: Ingredient Picker with Images

struct IngredientPickerWithImagesExample: View {
    @Environment(\.modelContext) private var modelContext
    let ingredients: [SpoonacularIngredient]
    @Binding var selectedIngredients: [SpoonacularIngredient]
    
    var body: some View {
        List(ingredients) { ingredient in
            Button {
                if selectedIngredients.contains(ingredient) {
                    selectedIngredients.removeAll { $0.id == ingredient.id }
                } else {
                    selectedIngredients.append(ingredient)
                }
            } label: {
                HStack {
                    IngredientImageView(
                        spoonacularIngredient: ingredient,
                        size: 50
                    )
                    
                    Text(ingredient.name)
                    
                    Spacer()
                    
                    if selectedIngredients.contains(ingredient) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

// MARK: - Example 4: Programmatic Image Loading

struct ProgrammaticImageLoadingExample: View {
    @Environment(\.modelContext) private var modelContext
    @State private var imageURL: URL?
    
    var body: some View {
        VStack {
            if let url = imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 200, height: 200)
            } else {
                Text("Loading...")
            }
            
            Button("Load Garlic Image") {
                Task {
                    await loadImage()
                }
            }
        }
    }
    
    private func loadImage() async {
        let service = IngredientImageMappingService(modelContext: modelContext)
        
        // This checks cache first, then tests if needed
        if let url = await service.getImageURL(
            forIngredientID: 11215,
            name: "garlic"
        ) {
            await MainActor.run {
                imageURL = url
            }
        }
    }
}

// MARK: - Example 5: Grid of Ingredients

struct IngredientGridExample: View {
    let ingredients: [ExtendedIngredient]
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ingredients, id: \.id) { ingredient in
                    VStack {
                        IngredientImageView(
                            ingredient: ingredient,
                            size: 80
                        )
                        
                        Text(ingredient.name ?? "")
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Example 6: Shopping List with Images

struct ShoppingListExample: View {
    let items: [(ingredient: ExtendedIngredient, quantity: String)]
    @State private var checkedItems: Set<Int> = []
    
    var body: some View {
        List {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                
                Button {
                    if let id = item.ingredient.id {
                        if checkedItems.contains(id) {
                            checkedItems.remove(id)
                        } else {
                            checkedItems.insert(id)
                        }
                    }
                } label: {
                    HStack {
                        IngredientImageView(
                            ingredient: item.ingredient,
                            size: 40
                        )
                        
                        VStack(alignment: .leading) {
                            Text(item.ingredient.name ?? "")
                                .strikethrough(
                                    checkedItems.contains(item.ingredient.id ?? -1)
                                )
                            Text(item.quantity)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if checkedItems.contains(item.ingredient.id ?? -1) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Example 7: Recipe Step with Ingredient Highlights

struct RecipeStepWithIngredientsExample: View {
    let stepText: String
    let ingredientsInStep: [ExtendedIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stepText)
                .font(.body)
            
            // Show ingredients mentioned in this step
            if !ingredientsInStep.isEmpty {
                HStack(spacing: 8) {
                    Text("Ingredients:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(ingredientsInStep, id: \.id) { ingredient in
                        IngredientImageView(
                            ingredient: ingredient,
                            size: 30
                        )
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Example 8: Batch Testing View

struct BatchTestingExample: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isRunning = false
    @State private var progress: Double = 0
    @State private var currentIngredient: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if isRunning {
                ProgressView(value: progress) {
                    Text("Testing ingredients...")
                }
                Text(currentIngredient)
                    .font(.caption)
            } else {
                Button("Test All Ingredients") {
                    Task {
                        await testAllIngredients()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func testAllIngredients() async {
        isRunning = true
        let service = IngredientImageMappingService(modelContext: modelContext)
        let ingredients = SpoonacularIngredientManager.shared.ingredients
        
        for (index, ingredient) in ingredients.enumerated() {
            await MainActor.run {
                currentIngredient = ingredient.name
                progress = Double(index) / Double(ingredients.count)
            }
            
            // Test and save
            _ = await service.getImageURL(
                forIngredientID: ingredient.id,
                name: ingredient.name
            )
        }
        
        await MainActor.run {
            isRunning = false
            progress = 1.0
        }
    }
}

// MARK: - Example 9: Custom Size Variations

struct CustomSizeVariationsExample: View {
    let ingredient: ExtendedIngredient
    
    var body: some View {
        VStack(spacing: 20) {
            // Thumbnail
            IngredientImageView(ingredient: ingredient, size: 30)
            
            // Small
            IngredientImageView(ingredient: ingredient, size: 50)
            
            // Medium (default)
            IngredientImageView(ingredient: ingredient, size: 60)
            
            // Large
            IngredientImageView(ingredient: ingredient, size: 100)
            
            // Extra Large
            IngredientImageView(ingredient: ingredient, size: 150)
        }
    }
}

// MARK: - Example 10: Fallback to Generic Image

struct FallbackImageExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // Ingredient with no ID (will show placeholder)
            IngredientImageView(
                ingredientID: nil,
                ingredientName: "Unknown Ingredient",
                size: 60
            )
            
            // Ingredient that doesn't exist (will test, fail, show placeholder)
            IngredientImageView(
                ingredientID: 99999999,
                ingredientName: "Fake Ingredient",
                size: 60
            )
        }
    }
}

// MARK: - Previews

#Preview("List Example") {
    RecipeIngredientsListExample(ingredients: [
        ExtendedIngredient(
            id: 11215,
            aisle: nil,
            image: "garlic.jpg",
            consistency: nil,
            name: "garlic",
            nameClean: "garlic",
            original: "2 cloves garlic",
            originalName: "garlic",
            amount: 2,
            unit: "cloves",
            meta: nil,
            measures: nil
        ),
        ExtendedIngredient(
            id: 1001,
            aisle: nil,
            image: "butter.jpg",
            consistency: nil,
            name: "butter",
            nameClean: "butter",
            original: "1 cup butter",
            originalName: "butter",
            amount: 1,
            unit: "cup",
            meta: nil,
            measures: nil
        ),
        ExtendedIngredient(
            id: 9003,
            aisle: nil,
            image: "apple.jpg",
            consistency: nil,
            name: "apple",
            nameClean: "apple",
            original: "1 apple",
            originalName: "apple",
            amount: 1,
            unit: "",
            meta: nil,
            measures: nil
        )
    ])
}

#Preview("Grid Example") {
    IngredientGridExample(ingredients: [
        ExtendedIngredient(
            id: 11215,
            aisle: nil,
            image: "garlic.jpg",
            consistency: nil,
            name: "garlic",
            nameClean: "garlic",
            original: "2 cloves garlic",
            originalName: "garlic",
            amount: 2,
            unit: "cloves",
            meta: nil,
            measures: nil
        ),
        ExtendedIngredient(
            id: 1001,
            aisle: nil,
            image: "butter.jpg",
            consistency: nil,
            name: "butter",
            nameClean: "butter",
            original: "1 cup butter",
            originalName: "butter",
            amount: 1,
            unit: "cup",
            meta: nil,
            measures: nil
        ),
        ExtendedIngredient(
            id: 9003,
            aisle: nil,
            image: "apple.jpg",
            consistency: nil,
            name: "apple",
            nameClean: "apple",
            original: "1 apple",
            originalName: "apple",
            amount: 1,
            unit: "",
            meta: nil,
            measures: nil
        ),
        ExtendedIngredient(
            id: 2028,
            aisle: nil,
            image: "paprika.jpg",
            consistency: nil,
            name: "paprika",
            nameClean: "paprika",
            original: "1 tsp paprika",
            originalName: "paprika",
            amount: 1,
            unit: "tsp",
            meta: nil,
            measures: nil
        )
    ])
}

#Preview("Size Variations") {
    CustomSizeVariationsExample(
        ingredient: ExtendedIngredient(
            id: 11215,
            aisle: nil,
            image: "garlic.jpg",
            consistency: nil,
            name: "garlic",
            nameClean: "garlic",
            original: "2 cloves garlic",
            originalName: "garlic",
            amount: 2,
            unit: "cloves",
            meta: nil,
            measures: nil
        )
    )
}
