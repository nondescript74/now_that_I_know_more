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
    @State private var selectedTab: Int = 0
    @State private var showSettings = false
    @State private var recipeService: RecipeService?
    
    init() {
        // Suppress UIKit navigation bar constraint warnings
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
    
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
                RecipeImportTabView()
                    .tabItem {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .tag(2)
                NavigationStack {
                    RecipeEditorView(recipe: nil)
                }
                    .tabItem {
                        Label("Edit Recipe", systemImage: "pencil")
                }
                    .tag(3)
                APIKeyTabView()
                    .tabItem {
                        Label("API Key", systemImage: "key.fill")
                    }
                    .tag(4)
                RecipeDiagnosticView()
                    .tabItem {
                        Label("Diagnostics", systemImage: "exclamationmark.circle")
                    }
                    .tag(5)
                IngredientImageTest()
                    .tabItem {
                        Label("Img Test", systemImage: "text.badge.plus")
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
    @State private var showLaunchScreen = true
    @State private var showImportPreview = false
    @State private var importedRecipe: RecipeModel?
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
                RecipeBookModel.self,
                IngredientImageMappingModel.self
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
        
        // Since we no longer have access to the old RecipeStore,
        // just mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration check completed")
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
            
            // Try to decode as RecipeModel directly
            let decoder = JSONDecoder()
            if let recipe = try? decoder.decode(RecipeModel.self, from: data) {
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
    
    @MainActor
    private func finalizeImport(_ recipe: RecipeModel) {
        let context = modelContainer.mainContext
        let service = RecipeService(modelContext: context)
        
        // Check if recipe already exists
        let descriptor = FetchDescriptor<RecipeModel>(
            predicate: #Predicate { $0.uuid == recipe.uuid }
        )
        
        do {
            let existingRecipes = try context.fetch(descriptor)
            if !existingRecipes.isEmpty {
                alertTitle = "Already Exists"
                alertMessage = "A recipe with this ID already exists in your collection. Would you like to replace it?"
                showAlert = true
                return
            }
            
            // Add the recipe using RecipeService
            // The recipe parameter is already a RecipeModel
            service.addRecipe(recipe)
            
            alertTitle = "Success"
            alertMessage = "Recipe '\(recipe.title ?? "Untitled")' has been imported successfully!"
            showAlert = true
            
            importedRecipe = nil
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to import recipe: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    MainTabView()
    
}

