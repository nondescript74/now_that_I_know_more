//
//  RecipeList.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI

struct RecipeList: View {
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
    }
}

#Preview {
    RecipeList()
        .environment(RecipeStore())
}
