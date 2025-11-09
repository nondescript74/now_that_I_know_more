//
//  RecipeImportView.swift
//  NowThatIKnowMore
//
//  Recipe import functionality for receiving recipes via email or file sharing
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct RecipeImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var importedRecipe: RecipeModel?
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
                
                // Try to decode as RecipeModel
                let decoder = JSONDecoder()
                let recipe = try decoder.decode(RecipeModel.self, from: data)
                importedRecipe = recipe
            } catch {
                alertTitle = "Error"
                alertMessage = "Unable to parse recipe file: \(error.localizedDescription)"
                showAlert = true
            }
            
        case .failure(let error):
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func importRecipe(_ recipe: RecipeModel) {
        // Check if recipe already exists
        if swiftDataRecipes.first(where: { $0.uuid == recipe.uuid }) != nil {
            alertTitle = "Already Exists"
            alertMessage = "A recipe with this ID already exists in your collection."
            showAlert = true
            return
        }
        
        // Convert Recipe to RecipeModel
        // Convert cuisines, dishTypes, diets, occasions from JSONAny arrays to comma-separated strings
        let cuisinesString = recipe.cuisines.compactMap { $0 }.joined(separator: ",")
        let dishTypesString = recipe.dishTypes.compactMap { $0 }.joined(separator: ",")
        let dietsString = recipe.diets.compactMap { $0 }.joined(separator: ",")
        let occasionsString = recipe.occasions.compactMap { $0 }.joined(separator: ",")
        let daysOfWeekString = recipe.daysOfWeek.joined(separator: ",")
        
        // Encode extendedIngredients and analyzedInstructions to JSON
        let ingredientsData = try? JSONEncoder().encode(recipe.extendedIngredients)
        let instructionsData = try? JSONEncoder().encode(recipe.analyzedInstructions)
        
        let recipeModel = RecipeModel(
            uuid: recipe.uuid,
            id: recipe.id,
            image: recipe.image,
            imageType: recipe.imageType,
            title: recipe.title ?? "Untitled Recipe",
            servings: recipe.servings,
            sourceURL: recipe.sourceURL,
            vegetarian: recipe.vegetarian,
            vegan: recipe.vegan,
            glutenFree: recipe.glutenFree,
            dairyFree: recipe.dairyFree,
            veryHealthy: recipe.veryHealthy,
            cheap: recipe.cheap,
            veryPopular: recipe.veryPopular,
            sustainable: recipe.sustainable,
            lowFodmap: recipe.lowFodmap,
            weightWatcherSmartPoints: recipe.weightWatcherSmartPoints,
            gaps: recipe.gaps,
            aggregateLikes: recipe.aggregateLikes,
            healthScore: recipe.healthScore,
            creditsText: recipe.creditsText,
            sourceName: recipe.sourceName,
            pricePerServing: recipe.pricePerServing,
            summary: recipe.summary,
            instructions: recipe.instructions,
            spoonacularScore: recipe.spoonacularScore,
            spoonacularSourceURL: recipe.spoonacularSourceURL,
            cuisinesString: cuisinesString,
            dishTypesString: dishTypesString,
            dietsString: dietsString,
            occasionsString: occasionsString,
            daysOfWeekString: daysOfWeekString,
            extendedIngredientsJSON: ingredientsData,
            analyzedInstructionsJSON: instructionsData,
            featuredMediaID: recipe.featuredMediaID,
            preferFeaturedMedia: recipe.preferFeaturedMedia
        )
        
        // Migrate media items if any
        if let mediaItems = recipe.mediaItems {
            for media in mediaItems {
                // Convert legacy MediaType to RecipeMediaModel.MediaType
                let mediaType: RecipeMediaModel.MediaType = switch media.type {
                case .photo: .photo
                case .video: .video
                }
                
                let mediaModel = RecipeMediaModel(
                    uuid: media.uuid,
                    fileURL: media.fileURL,
                    thumbnailURL: media.thumbnailURL,
                    caption: media.caption,
                    type: mediaType,
                    recipe: recipeModel
                )
                modelContext.insert(mediaModel)
            }
        }
        
        modelContext.insert(recipeModel)
        
        do {
            try modelContext.save()
            alertTitle = "Success"
            alertMessage = "Recipe '\(recipe.title ?? "Untitled")' has been imported successfully!"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save recipe: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    return RecipeImportView()
        .modelContainer(container)
}
