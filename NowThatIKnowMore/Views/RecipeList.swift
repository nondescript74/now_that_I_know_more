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
            List(recipeStore.recipes, id: \.self) { recipe in
                NavigationLink(destination: RecipeDetail(recipe: recipe)) {
                    HStack {
                        if let urlString = recipe.image, let url = URL(string: urlString) {
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
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .foregroundColor(.gray)
                        }
                        Text(recipe.title ?? "No Title")
                    }
                }
            }
            .environment(recipeStore)
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
