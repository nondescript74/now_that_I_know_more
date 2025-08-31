//
//  RecipeList.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI
import OSLog

struct RecipeList: View {
    let logger:Logger = .init(subsystem: "com.example.NowThatIKnowMore", category: "RecipeList")
    @Environment(RecipeStore.self) private var recipeStore
    var body: some View {
        NavigationStack {
            List(recipeStore.recipes) { recipe in
                NavigationLink(destination: Text("Recipe Details")) {
                    RecipeDetail(recipe: recipe)
                }
            }
            .navigationTitle("Recipes")
        }
        .onAppear {
            logger.info("\(recipeStore.recipes.isEmpty ? "No Recipes" : "Found Recipes" + recipeStore.recipes.count.description)")
        }
    }
}

#Preview {
    RecipeList()
        .environment(RecipeStore())
}
