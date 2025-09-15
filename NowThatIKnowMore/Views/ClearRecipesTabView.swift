//
//  ClearRecipesTabView.swift
//  NowThatIKnowMore
//
//  Created by AI Assistant on 9/15/25.
//

import SwiftUI

struct ClearRecipesTabView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Button("Clear All Recipes") {
                    showingConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.title2.bold())
                .accessibilityLabel("Clear All Recipes")
                .alert("Are you sure you want to clear all recipes? This cannot be undone.", isPresented: $showingConfirmation) {
                    Button("Clear Recipes", role: .destructive) {
                        recipeStore.clear()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                Spacer()
            }
            .navigationTitle("Clear Recipes")
        }
    }
}

#Preview {
    ClearRecipesTabView()
        .environment(RecipeStore())
}
