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
    @State private var mealPlanRecipes: [Recipe] = []
    @State private var isLoading = false
    
    @State private var selectedDay: String = "Monday"
    private static let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    let logger: Logger = .init(subsystem: "com.headydiscy.NowThatIKnowMore", category: "MealPlan")
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Day of Week", selection: $selectedDay) {
                    ForEach(Self.daysOfWeek, id: \.self) { day in
                        Text(day)
                    }
                }
                .pickerStyle(.segmented)
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
                
                let filteredMealPlanRecipes = mealPlanRecipes.filter { $0.daysOfWeek?.isEmpty != false || $0.daysOfWeek?.contains(selectedDay) == true }
                
                List {
                    ForEach(filteredMealPlanRecipes, id: \.uuid) { recipe in
                        NavigationLink(destination: RecipeDetail(recipeID: recipe.uuid)) {
                            HStack {
                                if let urlString = recipe.image, let url = URL(string: urlString), !urlString.isEmpty {
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
                                    if let assignedDays = recipe.daysOfWeek, !assignedDays.isEmpty {
                                        Text(assignedDays.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("No days assigned")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Menu {
                                    ForEach(Self.daysOfWeek, id: \.self) { day in
                                        Button {
                                            toggleAssignment(for: recipe, day: day)
                                        } label: {
                                            Label(day, systemImage: recipe.daysOfWeek?.contains(day) == true ? "checkmark.circle.fill" : "circle")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        clearAssignments(for: recipe)
                                    } label: {
                                        Text("Clear All Days")
                                    }
                                } label: {
                                    Image(systemName: "calendar.badge.clock")
                                        .imageScale(.large)
                                        .padding(.leading, 4)
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipeFromPlan)
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Meal Plan")
            .toolbar { EditButton() }
        }
    }
    
    private func appendMealPlanRecipe(_ recipe: Recipe) {
        guard !mealPlanRecipes.contains(where: { $0.uuid == recipe.uuid }) else { return }
        mealPlanRecipes.append(recipe)
        recipeStore.add(recipe) // <-- Add this line!
    }
    
    private func toggleAssignment(for recipe: Recipe, day: String) {
        guard let index = mealPlanRecipes.firstIndex(where: { $0.uuid == recipe.uuid }) else { return }
        var updatedRecipe = mealPlanRecipes[index]
        var assignedDays = updatedRecipe.daysOfWeek ?? []
        
        if let dayIndex = assignedDays.firstIndex(of: day) {
            assignedDays.remove(at: dayIndex)
        } else {
            assignedDays.append(day)
        }
        updatedRecipe.daysOfWeek = assignedDays.sorted()
        mealPlanRecipes[index] = updatedRecipe
        recipeStore.update(updatedRecipe)
    }
    
    private func clearAssignments(for recipe: Recipe) {
        guard let index = mealPlanRecipes.firstIndex(where: { $0.uuid == recipe.uuid }) else { return }
        var updatedRecipe = mealPlanRecipes[index]
        updatedRecipe.daysOfWeek = []
        mealPlanRecipes[index] = updatedRecipe
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
        let request = URLRequest(url: url)
        logger.info("[MealPlan] Fetching: \(url, privacy: .public)")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            logger.info("[MealPlan] API call succeeded, data len: \(data.count)")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let recipe = try? decoder.decode(Recipe.self, from: data) {
                appendMealPlanRecipe(recipe)
                resultText = ""
                urlString = ""
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = jsonObject as? [String: Any], let fallback = Recipe(from: dict) {
                appendMealPlanRecipe(fallback)
                resultText = ""
                urlString = ""
                return
            }
            resultText = "Could not parse recipe."
        } catch {
            resultText = error.localizedDescription
        }
    }
    
    private func deleteRecipeFromPlan(at offsets: IndexSet) {
        mealPlanRecipes.remove(atOffsets: offsets)
    }
}

#Preview {
    MealPlan().environment(RecipeStore())
}
