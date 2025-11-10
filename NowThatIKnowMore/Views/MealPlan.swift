// MealPlan.swift
// NowThatIKnowMore
//
// Created for user meal planning.

import SwiftUI
import SwiftData
import Combine
import OSLog

struct MealPlan: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    @State private var urlString = ""
    @State private var resultText = ""
    @State private var isLoading = false
    @State private var showingImportSheet = false
    @State private var showingSharingTips = false
    
    @State private var selectedDay: String = "All"
    @State private var showingDaySheetForRecipe: RecipeModel? = nil
    private static let daysOfWeek = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "MealPlan")
    
    private var filteredMealPlanRecipes: [RecipeModel] {
        if selectedDay == "All" {
            return swiftDataRecipes
        } else {
            return swiftDataRecipes.filter { $0.daysOfWeek.contains(selectedDay) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Day of Week", selection: $selectedDay) {
                    ForEach(Self.daysOfWeek, id: \.self) { day in
                        Text(day)
                    }
                }
                .pickerStyle(.menu)
                .padding([.horizontal, .top])
                
                HStack {
                    TextField("Paste recipe URL", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                    if !urlString.isEmpty {
                        Button(action: { urlString = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear URL")
                    }
                    Button("Add") {
                        Task { await addRecipeToMealPlan() }
                    }
                    .disabled(urlString.isEmpty || isLoading)
                }
                .padding()
                
                if isLoading {
                    ProgressView("Loading...").padding(.vertical)
                }
                if !resultText.isEmpty {
                    Text(resultText).foregroundColor(.secondary).padding(.bottom)
                }
                
                List {
                    ForEach(filteredMealPlanRecipes, id: \.uuid) { recipe in
                        NavigationLink(destination: RecipeDetail(recipeID: recipe.uuid)) {
                            HStack {
                                if let urlString = recipe.featuredMediaURL, !urlString.isEmpty {
                                    // Check if it's a remote URL (http/https)
                                    if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                                        if let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView().frame(width: 44, height: 44)
                                                case .success(let image):
                                                    image.resizable().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                                case .failure:
                                                    Image(systemName: "photo").resizable().frame(width: 44, height: 44).foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .onAppear {
                                                print("🖼️ [MealPlan] Showing remote image for '\(recipe.title ?? "nil")'")
                                                print("🖼️ [MealPlan] featuredMediaURL: '\(urlString)'")
                                            }
                                        } else {
                                            Image(systemName: "photo").resizable().frame(width: 44, height: 44).foregroundColor(.gray)
                                        }
                                    }
                                    // Handle local file paths
                                    else {
                                        let fileURL = URL(fileURLWithPath: urlString)
                                        if let data = try? Data(contentsOf: fileURL), let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .onAppear {
                                                    print("🖼️ [MealPlan] Showing local file image for '\(recipe.title ?? "nil")'")
                                                    print("🖼️ [MealPlan] file path: '\(urlString)'")
                                                    print("🖼️ [MealPlan] featuredMediaID: \(recipe.featuredMediaID?.uuidString ?? "nil")")
                                                    print("🖼️ [MealPlan] mediaItems count: \(recipe.mediaItems?.count ?? 0)")
                                                }
                                        } else {
                                            Image(systemName: "photo").resizable().frame(width: 44, height: 44).foregroundColor(.gray)
                                                .onAppear {
                                                    print("⚠️ [MealPlan] Failed to load local image for '\(recipe.title ?? "nil")'")
                                                    print("⚠️ [MealPlan] file path: '\(urlString)'")
                                                }
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo").resizable().frame(width: 44, height: 44).foregroundColor(.gray)
                                        .onAppear {
                                            print("📷 [MealPlan] No image for '\(recipe.title ?? "nil")'")
                                            print("📷 [MealPlan] image field: '\(recipe.image ?? "nil")'")
                                            print("📷 [MealPlan] mediaItems count: \(recipe.mediaItems?.count ?? 0)")
                                            print("📷 [MealPlan] featuredMediaID: \(recipe.featuredMediaID?.uuidString ?? "nil")")
                                        }
                                }
                                VStack(alignment: .leading) {
                                    Text(recipe.title ?? "No Title")
                                        .font(.headline)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button {
                                    showingDaySheetForRecipe = recipe
                                } label: {
                                    Image(systemName: "calendar.badge.clock")
                                        .imageScale(.large)
                                        .padding(.leading, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipeFromPlan)
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Meal Plan")
            .onAppear {
                logger.info("📋 [MealPlan] View appeared, total recipes: \(swiftDataRecipes.count)")
                for recipe in swiftDataRecipes {
                    logger.info("  - \(recipe.title ?? "nil") | UUID: \(recipe.uuid) | mediaItems: \(recipe.mediaItems?.count ?? 0) | featuredID: \(recipe.featuredMediaID?.uuidString ?? "nil")")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Recipe", systemImage: "tray.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingSharingTips = true
                        } label: {
                            Label("Sharing Tips", systemImage: "questionmark.circle")
                        }
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                RecipeImportView()
            }
            .sheet(isPresented: $showingSharingTips) {
                RecipeSharingTipsView()
            }
            .sheet(item: $showingDaySheetForRecipe) { recipe in
                VStack {
                    Text("Assign Days for \(recipe.title ?? "No Title")").font(.headline).padding(.top)
                    List {
                        ForEach(Self.daysOfWeek, id: \.self) { day in
                            Button {
                                toggleAssignment(for: recipe, day: day)
                                showingDaySheetForRecipe = nil
                            } label: {
                                HStack {
                                    Text(day)
                                    Spacer()
                                    if recipe.daysOfWeek.contains(day) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    Button("Clear All Days", role: .destructive) {
                        clearAssignments(for: recipe)
                        showingDaySheetForRecipe = nil
                    }
                    .padding()
                    Button("Done") {
                        showingDaySheetForRecipe = nil
                    }
                    .padding(.bottom)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func toggleAssignment(for recipe: RecipeModel, day: String) {
        var assignedDays = recipe.daysOfWeek
        
        if let dayIndex = assignedDays.firstIndex(of: day) {
            assignedDays.remove(at: dayIndex)
        } else {
            assignedDays.append(day)
        }
        recipe.daysOfWeek = assignedDays.sorted()
        
        // Save changes
        do {
            try modelContext.save()
            logger.info("[MealPlan] Updated days for recipe: \(recipe.title ?? "nil")")
        } catch {
            logger.error("[MealPlan] Failed to save recipe days: \(error.localizedDescription)")
        }
    }
    
    private func clearAssignments(for recipe: RecipeModel) {
        recipe.daysOfWeek = []
        
        // Save changes
        do {
            try modelContext.save()
            logger.info("[MealPlan] Cleared all days for recipe: \(recipe.title ?? "nil")")
        } catch {
            logger.error("[MealPlan] Failed to save recipe days: \(error.localizedDescription)")
        }
    }
    
    private func addRecipeToMealPlan() async {
        isLoading = true
        resultText = ""
        defer { isLoading = false }
        
        let endpoint = "https://api.spoonacular.com/recipes/extract"
        let apiKey = UserDefaults.standard.string(forKey: "spoonacularAPIKey") ?? ""
        guard !apiKey.isEmpty else {
            resultText = "API key not set."
            return
        }
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "url", value: urlString),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        guard let url = components.url else {
            resultText = "Invalid URL"
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30 // 30 seconds
        logger.info("[MealPlan] Fetching: \(url, privacy: .public)")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            logger.info("[MealPlan] API call succeeded, data len: \(data.count)")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // First, try to decode as Recipe struct and convert to RecipeModel
            if let recipe = try? decoder.decode(Recipe.self, from: data) {
                await addToSwiftDataFromRecipe(recipe)
                
                resultText = ""
                urlString = ""
                return
            } else {
                print("Could not decode Recipe")
            }
            
            resultText = "Could not parse recipe."
        } catch {
            resultText = error.localizedDescription
        }
    }
    
    @MainActor
    private func addToSwiftDataFromRecipe(_ recipe: Recipe) async {
        // Check if recipe already exists in SwiftData
        guard !swiftDataRecipes.contains(where: { $0.uuid == recipe.uuid }) else {
            logger.info("[MealPlan] Recipe already exists in SwiftData, skipping")
            return
        }
        
        // Convert Recipe to RecipeModel on MainActor
        let recipeModel = RecipeModel.from(recipe: recipe)
        
        // Insert the recipe directly
        modelContext.insert(recipeModel)
        
        do {
            try modelContext.save()
            logger.info("[MealPlan] Successfully added recipe to SwiftData")
        } catch {
            logger.error("[MealPlan] Failed to save recipe to SwiftData: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func addToSwiftData(_ recipe: RecipeModel) async {
        // Check if recipe already exists in SwiftData
        guard !swiftDataRecipes.contains(where: { $0.uuid == recipe.uuid }) else {
            logger.info("[MealPlan] Recipe already exists in SwiftData, skipping")
            return
        }
        
        // Insert the recipe directly
        modelContext.insert(recipe)
        
        do {
            try modelContext.save()
            logger.info("[MealPlan] Successfully added recipe to SwiftData")
        } catch {
            logger.error("[MealPlan] Failed to save recipe to SwiftData: \(error.localizedDescription)")
        }
    }
    
    private func deleteRecipeFromPlan(at offsets: IndexSet) {
        let recipesToDelete = offsets.compactMap { index -> RecipeModel? in
            guard index < filteredMealPlanRecipes.count else { return nil }
            return filteredMealPlanRecipes[index]
        }
        
        // Delete from SwiftData
        for recipe in recipesToDelete {
            logger.info("[MealPlan] Deleting recipe: '\(recipe.title ?? "nil")' (UUID: \(recipe.uuid.uuidString))")
            modelContext.delete(recipe)
        }
        
        // Save SwiftData changes
        do {
            try modelContext.save()
            logger.info("[MealPlan] Successfully saved SwiftData deletion")
        } catch {
            logger.error("[MealPlan] Failed to save SwiftData deletion: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MealPlan()
        .modelContainer(for: [RecipeModel.self, RecipeBookModel.self, RecipeMediaModel.self, RecipeNoteModel.self])
}

