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
    @SceneStorage("selectedTab") private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            MealPlan()
                .tabItem {
                    Label("Meal Plan", systemImage: "fork.knife")
                }
                .tag(1)
            RecipeList()
                .tabItem {
                    Label("Recipes", systemImage: "list.bullet")
                }
                .tag(0)
            Extract()
                .tabItem {
                    Label("Extract", systemImage: "square.and.arrow.down")
                }
                .tag(2)
            ImageToListView()
                .tabItem {
                    Label("From Image", systemImage: "text.viewfinder")
                }
                .tag(3)
            APIKeyTabView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .tag(4)
            ClearRecipesTabView()
                .tabItem {
                    Label("Clear Recipes", systemImage: "trash")
                }
                .tag(5)
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

