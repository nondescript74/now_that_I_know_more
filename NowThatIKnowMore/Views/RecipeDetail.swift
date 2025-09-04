// MARK: - Identifiable conformance for AnalyzedInstruction and Step
import Foundation
import PhotosUI

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

    let recipeID: UUID
    
    private var recipe: Recipe? {
        recipeStore.recipe(with: recipeID)
    }
    
    @State private var editedTitle: String = ""
    @State private var editedSummary: String = ""
    @State private var editedCreditsText: String = ""
    @State private var didSetupFields = false
    @State private var saveMessage: String?

    var body: some View {
        Group {
            if let recipe = recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Title", text: $editedTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Credits", text: $editedCreditsText)
                            .textFieldStyle(.roundedBorder)

                        if let imageUrlString = recipe.image, !imageUrlString.isEmpty {
                            if let url = URL(string: imageUrlString) {
                                if url.scheme == "file" {
                                    if let data = try? Data(contentsOf: url), let fileImage = UIImage(data: data) {
                                        Image(uiImage: fileImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(8)
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                } else if url.scheme == "http" || url.scheme == "https" {
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
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        TextEditor(text: $editedSummary)
                            .frame(minHeight: 60, maxHeight: 120)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                            .padding(.bottom, 4)

                        if (editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.title ?? "")
                            || editedSummary.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.summary ?? "")
                            || editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.creditsText ?? "")) {
                            Button("Save Changes") {
                                saveEdits()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, 8)
                            .disabled(
                                (editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.title ?? "")) &&
                                (editedSummary.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.summary ?? "")) &&
                                (editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.creditsText ?? ""))
                            )
                        }
                        if let msg = saveMessage {
                            Text(msg).foregroundColor(.accentColor)
                        }
                        
                        IngredientListView(ingredients: recipe.extendedIngredients ?? [])
                        
                        InstructionListView(instructions: recipe.analyzedInstructions)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .onAppear {
                        if !didSetupFields {
                            editedTitle = recipe.title ?? ""
                            editedSummary = recipe.summary ?? ""
                            editedCreditsText = recipe.creditsText ?? ""
                            didSetupFields = true
                        }
                    }
                }
            } else {
                Text("Recipe not found.")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .padding()
            }
        }
    }
    
    private func saveEdits() {
        guard let currentRecipe = recipe else {
            saveMessage = "Save failed (recipe not found)."
            return
        }
        
        let titleToSave = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryToSave = editedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let creditsToSave = editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Attempt to convert current recipe to a dictionary via encoding/decoding.
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(currentRecipe),
              var dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            saveMessage = "Save failed (unable to copy recipe)."
            return
        }
        dict["title"] = titleToSave.isEmpty ? nil : titleToSave
        dict["summary"] = summaryToSave.isEmpty ? nil : summaryToSave
        dict["creditsText"] = creditsToSave.isEmpty ? nil : creditsToSave
        dict["uuid"] = currentRecipe.uuid.uuidString
        // Retain original image without change
        dict["image"] = currentRecipe.image
        
        // Use Recipe(from:) convenience initializer
        guard let updatedRecipe = Recipe(from: dict) else {
            saveMessage = "Save failed (unable to construct recipe)."
            return
        }
        recipeStore.update(updatedRecipe)
        saveMessage = "Saved!"
    }
}

private struct IngredientListView: View {
    let ingredients: [ExtendedIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(ingredients, id: \.id) { ingredient in
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

#Preview {
    let store = RecipeStore()
    let recipe = store.recipes.first ?? Recipe(from: [
        "uuid": UUID(),
        "title": "Sample Recipe",
        "summary": "A preview recipe.",
        "creditsText": "Preview Chef"
    ])!
    if store.recipes.isEmpty { store.add(recipe) }
    return RecipeDetail(recipeID: recipe.uuid)
        .environment(store)
}
