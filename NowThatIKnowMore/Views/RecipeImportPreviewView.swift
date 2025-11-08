//
//  RecipeImportPreviewView.swift
//  NowThatIKnowMore
//
//  Preview and import recipes received via email or file sharing
//

import SwiftUI

struct RecipeImportPreviewView: View {
    let recipe: Recipe
    let onImport: () -> Void
    let onCancel: () -> Void
    
    @Environment(RecipeStore.self) private var store
    @State private var showFullRecipe = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top, 20)
                    
                    Text("Recipe Received")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You've received a recipe! Preview it below and tap Import to add it to your collection.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Recipe Preview Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Featured Image
                        if let featuredURL = recipe.featuredMediaURL, !featuredURL.isEmpty {
                            if let url = URL(string: featuredURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 200)
                                            .clipped()
                                            .cornerRadius(12)
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                    case .failure(_):
                                        recipeIconPlaceholder
                                    @unknown default:
                                        recipeIconPlaceholder
                                    }
                                }
                            } else {
                                recipeIconPlaceholder
                            }
                        } else {
                            recipeIconPlaceholder
                        }
                        
                        // Recipe Title and Credits
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title ?? "Untitled Recipe")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let credits = recipe.creditsText, !credits.isEmpty {
                                Label {
                                    Text(credits)
                                        .foregroundColor(.secondary)
                                } icon: {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        // Recipe Info Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            if let servings = recipe.servings {
                                InfoCard(icon: "person.2.fill", label: "Servings", value: "\(servings)")
                            }
                            
                            if let readyInMinutes = recipe.readyInMinutes {
                                InfoCard(icon: "clock.fill", label: "Ready In", value: "\(readyInMinutes) min")
                            }
                            
                            if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                                InfoCard(icon: "list.bullet", label: "Ingredients", value: "\(ingredients.count)")
                            }
                            
                            if let instructions = recipe.analyzedInstructions, !instructions.isEmpty {
                                let stepCount = instructions.reduce(0) { $0 + ($1.steps?.count ?? 0) }
                                if stepCount > 0 {
                                    InfoCard(icon: "text.alignleft", label: "Steps", value: "\(stepCount)")
                                }
                            }
                        }
                        
                        // Summary (if available)
                        if let summary = recipe.summary, !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                
                                Text(cleanSummary(summary))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(4)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        // View Full Recipe Button
                        Button(action: { showFullRecipe = true }) {
                            Label("View Full Recipe", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                        
                        // Check if recipe already exists
                        if store.recipe(with: recipe.uuid) != nil {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("This recipe already exists in your collection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: onImport) {
                            Label(store.recipe(with: recipe.uuid) != nil ? "Replace Existing Recipe" : "Import Recipe", 
                                  systemImage: store.recipe(with: recipe.uuid) != nil ? "arrow.triangle.2.circlepath" : "tray.and.arrow.down.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(store.recipe(with: recipe.uuid) != nil ? Color.orange : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFullRecipe) {
                NavigationStack {
                    RecipeDetail(recipeID: recipe.uuid)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showFullRecipe = false
                                }
                            }
                        }
                }
                .environment(RecipeStore.previewStore(with: [recipe]))
            }
        }
    }
    
    private var recipeIconPlaceholder: some View {
        VStack {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray.gradient)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// Helper function
private func cleanSummary(_ html: String) -> String {
    var text = html.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
    text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "<ul>|</ul>", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "<b>(.*?)</b>", with: "$1", options: .regularExpression)
    text = text.replacingOccurrences(of: "<i>(.*?)</i>", with: "$1", options: .regularExpression)
    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
    return lines.filter { !$0.isEmpty }.joined(separator: " ")
}

// Extension to create preview RecipeStore
extension RecipeStore {
    static func previewStore(with recipes: [Recipe]) -> RecipeStore {
        let store = RecipeStore()
        // Filter out duplicates based on UUID
        var uniqueRecipes: [Recipe] = []
        for recipe in recipes {
            if !uniqueRecipes.contains(where: { $0.uuid == recipe.uuid }) {
                uniqueRecipes.append(recipe)
            }
        }
        // Set the recipes using the public method
        store.set(uniqueRecipes)
        return store
    }
}

#Preview {
    let sampleRecipe = Recipe(from: [
        "uuid": UUID(),
        "title": "Delicious Pasta Carbonara",
        "summary": "A classic Italian pasta dish with eggs, cheese, and bacon.",
        "creditsText": "Shared by Chef Mario",
        "servings": 4,
        "readyInMinutes": 30
    ])!
    
    return RecipeImportPreviewView(
        recipe: sampleRecipe,
        onImport: { print("Import tapped") },
        onCancel: { print("Cancel tapped") }
    )
    .environment(RecipeStore())
}
