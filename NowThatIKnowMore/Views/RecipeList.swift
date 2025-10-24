//
//  RecipeList.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI
import OSLog

private struct CuisineName: Decodable { let name: String }

private struct RecipeThumbnail: View {
    let urlString: String?
    
    var body: some View {
        if let urlString = urlString {
            let url = URL(string: urlString) ?? URL(filePath: urlString)
            if url.scheme == "file" || url.pathComponents.first == "/" {
                // Local file URL
                if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    placeholderImage
                }
            } else if url.scheme == "http" || url.scheme == "https" {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 24, height: 24)
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    case .failure(_):
                        placeholderImage
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderImage
            }
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .foregroundColor(.gray)
    }
}

struct RecipeList: View {
    let logger:Logger = .init(subsystem: "com.example.NowThatIKnowMore", category: "RecipeList")
    @Environment(RecipeStore.self) private var recipeStore
    
    @State private var selectedDay: String = "All"
    private static let daysOfWeek = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private var cuisines: [String] {
        // Assuming cuisines is loaded or defined somewhere in this view context.
        // Since it was referenced in the instructions, adding a sample placeholder:
        // In real code, this should come from some data source.
        []
    }
    
    private var recipesByCuisine: [(cuisine: String, recipes: [Recipe])] {
        let filteredRecipes: [Recipe]
        if selectedDay == "All" {
            filteredRecipes = recipeStore.recipes
        } else {
            filteredRecipes = recipeStore.recipes.filter { recipe in
                guard let days = recipe.daysOfWeek, !days.isEmpty else { return true }
                return days.contains(selectedDay)
            }
        }
        
        let cuisineSections = cuisines.map { cuisine in
            (cuisine: cuisine, recipes: filteredRecipes.filter { ($0.cuisines?.compactMap { $0.value as? String } ?? []).contains(cuisine) })
        }.filter { !$0.recipes.isEmpty }
        let matchedIDs = Set(cuisineSections.flatMap { $0.recipes.map { $0.uuid } })
        let otherRecipes = filteredRecipes.filter { !matchedIDs.contains($0.uuid) }
        let allSections = cuisineSections + (otherRecipes.isEmpty ? [] : [(cuisine: "Other", recipes: otherRecipes)])
        return allSections
    }
    
    var body: some View {
        NavigationStack {
            Picker("Day of Week", selection: $selectedDay) {
                ForEach(Self.daysOfWeek, id: \.self) { day in
                    Text(day)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
            
            List {
                ForEach(recipesByCuisine, id: \.cuisine) { section in
                    Section(header: Text(section.cuisine)) {
                        ForEach(section.recipes, id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetail(recipeID: recipe.uuid)) {
                                HStack {
                                    RecipeThumbnail(urlString: recipe.featuredMediaURL)
                                    Text(recipe.title ?? "No Title")
                                }
                            }
                        }
                        .onDelete(perform: deleteRecipe)
                    }
                }
            }
            .environment(recipeStore)
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: RecipeImportView()) {
                        Label("Import", systemImage: "tray.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .onAppear {
            logger.info("\(recipeStore.recipes.isEmpty ? "No Recipes" : "Found Recipes" + recipeStore.recipes.count.description)")
        }
    }
    
    private func deleteRecipe(at offsets: IndexSet) {
        for index in offsets {
            recipeStore.remove(recipeStore.recipes[index])
        }
    }
}

#Preview {
    RecipeList()
        .environment(RecipeStore())
}
