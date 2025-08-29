// MARK: - Identifiable conformance for AnalyzedInstruction and Step
import Foundation
extension AnalyzedInstruction: Identifiable {
    var id: String { name ?? UUID().uuidString }
}
extension Step: Identifiable {
    var id: Int { number ?? Int.random(in: 1...10_000_000) }
}

//
//  RecipeDetail.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI

struct RecipeDetail: View {
    @Environment(RecipeStore.self) private var recipeStore

    
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.title ?? "no title")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let imageUrlString = recipe.image, let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        case .failure(_):
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                if let summary = recipe.summary, !summary.isEmpty {
                    Text(attributedSummary(from: summary))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                IngredientListView(ingredients: recipe.extendedIngredients ?? [])
                
                InstructionListView(instructions: recipe.analyzedInstructions)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    private func attributedSummary(from html: String) -> AttributedString {
        var text = html.replacingOccurrences(of: "<b>", with: "\n   ")
        text = text.replacingOccurrences(of: "</b>", with: "\n   ")
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return AttributedString(text)
    }
}

private struct IngredientListView: View {
    let ingredients: [ExtendedIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(ingredients, id: \.original) { ingredient in
                Text("• \(ingredient.original ?? "")")
                    .font(.body)
            }
        }
    }
}

private struct InstructionListView: View {
    let instructions: [AnalyzedInstruction]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let instructions = instructions, !instructions.isEmpty {
                Text("Instructions")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(instructions) { instruction in
                    ForEach(instruction.steps ?? []) { step in
                        let stepText = step.step ?? ""
                        Text((step.number?.description ?? "0") + ". " + stepText)
                            .font(.body)
                    }
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    
}

