//
//  RecipeList.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI
import OSLog
import SwiftData
private struct CuisineName: Decodable { let name: String }


private struct RecipeThumbnail: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss
    
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
    
    @Environment(\.modelContext) private var modelContext
    @Query private var swiftDataRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDay: String = "All"
    private static let daysOfWeek = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private var cuisines: [String] {
        // Assuming cuisines is loaded or defined somewhere in this view context.
        // Since it was referenced in the instructions, adding a sample placeholder:
        // In real code, this should come from some data source.
        []
    }
    
    private var recipesByCuisine: [(cuisine: String, recipes: [RecipeModel])] {
        let filteredRecipes: [RecipeModel]
        if selectedDay == "All" {
            filteredRecipes = swiftDataRecipes
        } else {
            filteredRecipes = swiftDataRecipes.filter { recipe in
                let days = recipe.daysOfWeek
                guard !days.isEmpty else { return true }
                return days.contains(selectedDay)
            }
        }
        
        // Break down the complex mapping into simpler steps
        let cuisineSectionsWithEmpty: [(cuisine: String, recipes: [RecipeModel])] = cuisines.map { cuisine in
            let recipesForCuisine = filteredRecipes.filter { recipe in
                let cuisineList = recipe.cuisines.compactMap { $0 }
                return cuisineList.contains(cuisine)
            }
            return (cuisine: cuisine, recipes: recipesForCuisine)
        }
        
        let cuisineSections = cuisineSectionsWithEmpty.filter { !$0.recipes.isEmpty }
        
        let matchedRecipeIDs = cuisineSections.flatMap { $0.recipes.map { $0.uuid } }
        let matchedIDs = Set(matchedRecipeIDs)
        
        let otherRecipes = filteredRecipes.filter { !matchedIDs.contains($0.uuid) }
        
        var allSections = cuisineSections
        if !otherRecipes.isEmpty {
            allSections.append((cuisine: "Other", recipes: otherRecipes))
        }
        
        return allSections
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayPicker
                recipeListView
            }
            .navigationTitle("Recipes")
            .toolbar {
                toolbarContent
            }
        }
        .onAppear {
            logRecipeCount()
        }
    }
    
    private var dayPicker: some View {
        Picker("Day of Week", selection: $selectedDay) {
            ForEach(Self.daysOfWeek, id: \.self) { day in
                Text(day)
            }
        }
        .pickerStyle(.segmented)
        .padding([.horizontal, .top])
    }
    
    private var recipeListView: some View {
        List {
            ForEach(recipesByCuisine, id: \.cuisine) { section in
                Section(header: Text(section.cuisine)) {
                    ForEach(section.recipes, id: \.self) { recipe in
                        recipeRow(for: recipe)
                    }
                    .onDelete(perform: {_ in })
                }
            }
        }
    }
    
    private func recipeRow(for recipe: RecipeModel) -> some View {
        NavigationLink(destination: RecipeDetail(recipeID: recipe.uuid)) {
            HStack {
                RecipeThumbnail(urlString: recipe.featuredMediaURL)
                Text(recipe.title ?? "No Title")
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            NavigationLink(destination: RecipeImportView()) {
                Label("Import", systemImage: "tray.and.arrow.down")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
        }
    }
    
    private func logRecipeCount() {
        if swiftDataRecipes.isEmpty {
            logger.info("No Recipes")
        } else {
            let recipeCount = swiftDataRecipes.count
            logger.info("Found Recipes: \(recipeCount)")
        }
    }
}

#Preview {

    RecipeList()
        
}
