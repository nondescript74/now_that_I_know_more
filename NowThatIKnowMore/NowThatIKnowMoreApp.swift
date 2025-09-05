//
//  NowThatIKnowMoreApp.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/14/25.
//

import SwiftUI
import OSLog

private struct MainTabView: View {
    @Environment(RecipeStore.self) private var store: RecipeStore
    @SceneStorage("selectedTab") private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeList()
                .tabItem {
                    Label("Recipes", systemImage: "list.bullet")
                }
                .tag(0)
            Extract()
                .tabItem {
                    Label("Extract", systemImage: "square.and.arrow.down")
                }
                .tag(1)
            ImageToListView()
                .tabItem {
                    Label("From Image", systemImage: "text.viewfinder")
                }
                .tag(2)
            APIKeyTabView()
                .tabItem {
                    Label("API Key", systemImage: "key.fill")
                }
                .tag(3)
        }
    }
}

@main
struct NowThatIKnowMoreApp: App {
    @Environment(\.colorScheme) var colorScheme
    @State private var store: RecipeStore = RecipeStore()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
        }
    }
}

#Preview {
    MainTabView()
        .environment(RecipeStore())
}
