//
//  NowThatIKnowMoreApp.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/14/25.
//

import SwiftUI
import SwiftData
import OSLog
import Combine

private struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RecipeStore.self) private var store: RecipeStore
    @State private var selectedTab: Int = 0
    @State private var showSettings = false
    @State private var recipeService: RecipeService?
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                MealPlan()
                    .tabItem {
                        Label("Meal Plan", systemImage: "fork.knife")
                    }
                    .tag(0)
                RecipeBooksView()
                    .tabItem {
                        Label("Books", systemImage: "books.vertical")
                    }
                    .tag(1)
                RecipeImageParserView()
                    .tabItem {
                        Label("OCR Import", systemImage: "camera")
                    }
                    .tag(2)
                APIKeyTabView()
                    .tabItem {
                        Label("API Key", systemImage: "key.fill")
                    }
                    .tag(3)
                RecipeEditorView(recipe: Recipe(from: ["uuid": UUID(), "title": "New Recipe"])!)
                    .tabItem {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    .tag(4)
                DictionaryToRecipeView()
                    .tabItem {
                        Label("Dict to Recipe", systemImage: "rectangle.and.text.magnifyingglass")
                    }
                    .tag(5)
                ClearRecipesTabView()
                    .tabItem {
                        Label("Clear Recipes", systemImage: "trash")
                    }
                    .tag(6)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if recipeService == nil {
                recipeService = RecipeService(modelContext: modelContext)
                // Create default books if needed
                recipeService?.createDefaultBooksIfNeeded()
            }
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
    
    // SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                RecipeModel.self,
                RecipeMediaModel.self,
                RecipeNoteModel.self,
                RecipeBookModel.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LicenseGateView {
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
                        .task {
                            // Migrate legacy recipes on first launch
                            await migrateLegacyRecipes()
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
        .modelContainer(modelContainer)
    }
    
    private func migrateLegacyRecipes() async {
        // Check if migration has already been done
        let migrationKey = "hasCompletedSwiftDataMigration"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        
        // Get legacy recipes from RecipeStore
        let legacyRecipes = store.recipes
        guard !legacyRecipes.isEmpty else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }
        
        // Migrate to SwiftData
        let context = modelContainer.mainContext
        let service = RecipeService(modelContext: context)
        
        await MainActor.run {
            service.batchMigrateLegacyRecipes(legacyRecipes)
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("✅ Successfully migrated \(legacyRecipes.count) recipes to SwiftData")
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

