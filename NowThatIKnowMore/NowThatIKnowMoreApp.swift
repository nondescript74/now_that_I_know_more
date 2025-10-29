//
//  NowThatIKnowMoreApp.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/14/25.
//

import SwiftUI
import OSLog
import Combine

private struct MainTabView: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            MealPlan()
                .tabItem {
                    Label("Meal Plan", systemImage: "fork.knife")
                }
                .tag(0)
            ImageToListView()
                .tabItem {
                    Label("From Image", systemImage: "text.viewfinder")
                }
                .tag(1)
            APIKeyTabView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .tag(2)
            RecipeEditorView(recipe: Recipe(from: ["uuid": UUID(), "title": "New Recipe"])!)
                .tabItem {
                    Label("Edit Recipe", systemImage: "pencil")
                }
                .tag(3)
            DictionaryToRecipeView()
                .tabItem {
                    Label("Dict to Recipe", systemImage: "rectangle.and.text.magnifyingglass")
                }
                .tag(4)
            ClearRecipesTabView()
                .tabItem {
                    Label("Clear Recipes", systemImage: "trash")
                }
                .tag(5)
        }
    }
}

@main
struct NowThatIKnowMoreApp: App {
    @Environment(\.colorScheme) var colorScheme
    @State private var store: RecipeStore = RecipeStore()
    @State private var showLaunchScreen = true
    @State private var showImportPreview = false
    @State private var importedRecipe: Recipe?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(store)
                    .onOpenURL { url in
                        if url.pathExtension == "recipe" {
                            handleRecipeImport(from: url)
                        }
                    }
                    .sheet(isPresented: $showImportPreview) {
                        if let recipe = importedRecipe {
                            RecipeImportPreviewView(recipe: recipe, onImport: {
                                finalizeImport(recipe)
                                showImportPreview = false
                            }, onCancel: {
                                showImportPreview = false
                                importedRecipe = nil
                            })
                            .environment(store)
                        }
                    }
                    .alert(alertTitle, isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(AnyTransition.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showLaunchScreen = false }
                }
            }
        }
    }
    
    private func handleRecipeImport(from url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            alertTitle = "Error"
            alertMessage = "Unable to access the recipe file."
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
                showImportPreview = true
            } else if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let recipe = Recipe(from: dict) {
                importedRecipe = recipe
                showImportPreview = true
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
    }
    
    private func finalizeImport(_ recipe: Recipe) {
        // Check if recipe already exists
        if store.recipe(with: recipe.uuid) != nil {
            alertTitle = "Already Exists"
            alertMessage = "A recipe with this ID already exists in your collection. Would you like to replace it?"
            showAlert = true
            return
        }
        
        // Add the recipe
        store.add(recipe)
        
        alertTitle = "Success"
        alertMessage = "Recipe '\(recipe.title ?? "Untitled")' has been imported successfully!"
        showAlert = true
        
        importedRecipe = nil
    }
}

#Preview {
    MainTabView()
        .environment(RecipeStore())
}

