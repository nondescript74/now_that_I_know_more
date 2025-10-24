// MealPlan.swift
// NowThatIKnowMore
//
// Created for user meal planning.

import SwiftUI
import Combine
import OSLog

struct MealPlan: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var urlString = ""
    @State private var resultText = ""
    @State private var isLoading = false
    
    @State private var selectedDay: String = "All"
    @State private var showingDaySheetForRecipe: Recipe? = nil
    private static let daysOfWeek = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "MealPlan")
    
    private var filteredMealPlanRecipes: [Recipe] {
        if selectedDay == "All" {
            return recipeStore.recipes
        } else {
            return recipeStore.recipes.filter { $0.daysOfWeek?.contains(selectedDay) == true }
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
                                if let urlString = recipe.featuredMediaURL, !urlString.isEmpty, let url = URL(string: urlString) {
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
                                } else {
                                    Image(systemName: "photo").resizable().frame(width: 44, height: 44).foregroundColor(.gray)
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
            .toolbar { EditButton() }
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
                                    if recipe.daysOfWeek?.contains(day) == true {
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
    
    private func toggleAssignment(for recipe: Recipe, day: String) {
        guard let index = recipeStore.recipes.firstIndex(where: { $0.uuid == recipe.uuid }) else { return }
        var updatedRecipe = recipeStore.recipes[index]
        var assignedDays = updatedRecipe.daysOfWeek ?? []
        
        if let dayIndex = assignedDays.firstIndex(of: day) {
            assignedDays.remove(at: dayIndex)
        } else {
            assignedDays.append(day)
        }
        updatedRecipe.daysOfWeek = assignedDays.sorted()
        recipeStore.update(updatedRecipe)
    }
    
    private func clearAssignments(for recipe: Recipe) {
        guard let index = recipeStore.recipes.firstIndex(where: { $0.uuid == recipe.uuid }) else { return }
        var updatedRecipe = recipeStore.recipes[index]
        updatedRecipe.daysOfWeek = []
        recipeStore.update(updatedRecipe)
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
            if let recipe = try? decoder.decode(Recipe.self, from: data) {
                recipeStore.add(recipe)
                resultText = ""
                urlString = ""
                return
            }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let dict = jsonObject as? [String: Any] {
                var updatedDict = dict
                if let image = dict["image"] as? String,
                   let imageType = dict["imageType"] as? String,
                   !image.isEmpty,
                   !image.lowercased().hasSuffix(".jpg") &&
                   !image.lowercased().hasSuffix(".jpeg") &&
                   !image.lowercased().hasSuffix(".png") &&
                   !image.lowercased().hasSuffix(".gif") &&
                   !image.lowercased().hasSuffix(".webp") {
                    var suffixedImage = image + "." + imageType
                    if suffixedImage.lowercased().hasSuffix(".jpg") || suffixedImage.lowercased().hasSuffix(".jpeg") || suffixedImage.lowercased().hasSuffix(".png") || suffixedImage.lowercased().hasSuffix(".gif") || suffixedImage.lowercased().hasSuffix(".webp") {
                        // do nothing all is ok
                    } else {
                        // imageType is blank, add .jpg
                        suffixedImage = image + "jpg"
                    }
                    updatedDict["image"] = suffixedImage
                }
                if let fallback = Recipe(from: updatedDict) {
                    recipeStore.add(fallback)
                    resultText = ""
                    urlString = ""
                    return
                }
            }
            resultText = "Could not parse recipe."
        } catch {
            resultText = error.localizedDescription
        }
    }
    
    private func deleteRecipeFromPlan(at offsets: IndexSet) {
        let recipesToDelete = offsets.compactMap { index -> Recipe? in
            let filteredRecipes: [Recipe]
            if selectedDay == "All" {
                filteredRecipes = recipeStore.recipes
            } else {
                filteredRecipes = recipeStore.recipes.filter { $0.daysOfWeek?.isEmpty != false || $0.daysOfWeek?.contains(selectedDay) == true }
            }
            guard index < filteredRecipes.count else { return nil }
            return filteredRecipes[index]
        }
        for recipe in recipesToDelete {
            recipeStore.remove(recipe)
        }
    }
}

#Preview {
    MealPlan().environment(RecipeStore())
}

