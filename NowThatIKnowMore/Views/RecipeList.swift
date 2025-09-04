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
            List {
                ForEach(recipeStore.recipes, id: \.self) { recipe in
                    NavigationLink(destination: RecipeDetail(recipeID: recipe.uuid)) {
                        HStack {
                            if let urlString = recipe.image {
                                if let url = URL(string: urlString), url.scheme == "file" {
                                    // Local file URL: load as UIImage and show thumbnail
                                    if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundColor(.gray)
                                    }
                                } else if let url = URL(string: urlString) {
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
                .onDelete(perform: deleteRecipe)
            }
            .environment(recipeStore)
            .navigationTitle("Recipes")
            .toolbar {
                EditButton()
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
