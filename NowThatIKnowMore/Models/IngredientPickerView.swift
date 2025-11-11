//
//  IngredientPickerView.swift
//  NowThatIKnowMore
//
//  SwiftUI view for picking Spoonacular ingredients
//

import SwiftUI
import Combine

/// A searchable picker for selecting Spoonacular ingredients
struct IngredientPickerView: View {
    @StateObject private var manager = SpoonacularIngredientManager.shared
    @State private var searchText = ""
    @State private var selectedIngredients: [SpoonacularIngredient] = []
    
    var onIngredientsSelected: (([SpoonacularIngredient]) -> Void)?
    
    private var filteredIngredients: [SpoonacularIngredient] {
        manager.searchIngredients(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !manager.isLoaded {
                    ProgressView("Loading ingredients...")
                } else {
                    List {
                        ForEach(filteredIngredients) { ingredient in
                            Button {
                                toggleSelection(ingredient)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(ingredient.name)
                                            .font(.body)
                                        Text("ID: \(ingredient.id)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedIngredients.contains(ingredient) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search ingredients")
                }
            }
            .navigationTitle("Select Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onIngredientsSelected?(selectedIngredients)
                    }
                    .disabled(selectedIngredients.isEmpty)
                }
            }
        }
    }
    
    private func toggleSelection(_ ingredient: SpoonacularIngredient) {
        if let index = selectedIngredients.firstIndex(of: ingredient) {
            selectedIngredients.remove(at: index)
        } else {
            selectedIngredients.append(ingredient)
        }
    }
}

/// A compact ingredient search field
struct IngredientSearchField: View {
    @StateObject private var manager = SpoonacularIngredientManager.shared
    @State private var searchText = ""
    @State private var showingResults = false
    
    var onIngredientSelected: ((SpoonacularIngredient) -> Void)?
    
    private var searchResults: [SpoonacularIngredient] {
        manager.searchIngredients(query: searchText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Search ingredients...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _, newValue in
                    showingResults = !newValue.isEmpty
                }
            
            if showingResults && !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults.prefix(10)) { ingredient in
                            Button {
                                onIngredientSelected?(ingredient)
                                searchText = ""
                                showingResults = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ingredient.name)
                                            .font(.body)
                                        Text("ID: \(ingredient.id)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if ingredient.id != searchResults.prefix(10).last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
struct IngredientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientPickerView { ingredients in
            print("Selected: \(ingredients.map { $0.name })")
        }
    }
}

struct IngredientSearchField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            IngredientSearchField { ingredient in
                print("Selected: \(ingredient.name)")
            }
            .padding()
            
            Spacer()
        }
    }
}
#endif
