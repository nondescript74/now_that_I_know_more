//
//  NowThatIKnowMoreApp.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/14/25.
//

import SwiftUI
import OSLog
import Combine

private struct MainTabView: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            MealPlan()
                .tabItem {
                    Label("Meal Plan", systemImage: "fork.knife")
                }
                .tag(0)
            ImageToListView()
                .tabItem {
                    Label("From Image", systemImage: "text.viewfinder")
                }
                .tag(1)
            APIKeyTabView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .tag(2)
            DictionaryToRecipeView()
                .tabItem {
                    Label("Dict to Recipe", systemImage: "rectangle.and.text.magnifyingglass")
                }
                .tag(3)
            ClearRecipesTabView()
                .tabItem {
                    Label("Clear Recipes", systemImage: "trash")
                }
                .tag(4)
        }
    }
}

@main
struct NowThatIKnowMoreApp: App {
    @Environment(\.colorScheme) var colorScheme
    @State private var store: RecipeStore = RecipeStore()
    @State private var showLaunchScreen = true
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(store)
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(AnyTransition.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showLaunchScreen = false }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(RecipeStore())
}
