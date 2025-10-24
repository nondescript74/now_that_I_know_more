//
//  RecipeImportView.swift
//  NowThatIKnowMore
//
//  Recipe import functionality for receiving recipes via email or file sharing
//

import SwiftUI
internal import UniformTypeIdentifiers

struct RecipeImportView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var importedRecipe: Recipe?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Import Recipe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Import recipes shared from other users via email or file sharing.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button(action: {
                    isImporting = true
                }) {
                    Label("Choose Recipe File", systemImage: "doc")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if let recipe = importedRecipe {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        
                        Text("Preview")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title ?? "Untitled Recipe")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let credits = recipe.creditsText, !credits.isEmpty {
                                Text(credits)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let servings = recipe.servings {
                                HStack {
                                    Image(systemName: "person.2")
                                    Text("Serves \(servings)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                                Text("\(ingredients.count) ingredients")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button(action: {
                            importRecipe(recipe)
                        }) {
                            Label("Import This Recipe", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json, UTType(filenameExtension: "recipe") ?? .json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Error"
                alertMessage = "Unable to access the file."
                showAlert = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                
                // Try to decode as Recipe
                let decoder = JSONDecoder()
                if let recipe = try? decoder.decode(Recipe.self, from: data) {
                    importedRecipe = recipe
                } else if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let recipe = Recipe(from: dict) {
                    importedRecipe = recipe
                } else {
                    alertTitle = "Error"
                    alertMessage = "Unable to parse recipe file. The file may be corrupted or in an invalid format."
                    showAlert = true
                }
            } catch {
                alertTitle = "Error"
                alertMessage = "Failed to read file: \(error.localizedDescription)"
                showAlert = true
            }
            
        case .failure(let error):
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func importRecipe(_ recipe: Recipe) {
        // Check if recipe already exists
        if recipeStore.recipe(with: recipe.uuid) != nil {
            alertTitle = "Already Exists"
            alertMessage = "A recipe with this ID already exists in your collection."
            showAlert = true
            return
        }
        
        // Add the recipe
        recipeStore.add(recipe)
        
        alertTitle = "Success"
        alertMessage = "Recipe '\(recipe.title ?? "Untitled")' has been imported successfully!"
        showAlert = true
    }
}

#Preview {
    let store = RecipeStore()
    return RecipeImportView()
        .environment(store)
}
