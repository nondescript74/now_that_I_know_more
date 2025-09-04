//
//  NowThatIKnowMoreApp.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/14/25.
//

import SwiftUI
import OSLog

@main
struct NowThatIKnowMoreApp: App {
    @Environment(\.colorScheme) var colorScheme
    @State private var store: RecipeStore = RecipeStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                RecipeList()
                    .tabItem {
                        Label("Recipes", systemImage: "list.bullet")
                    }
                Extract()
                    .tabItem {
                        Label("Extract", systemImage: "square.and.arrow.down")
                    }
                ImageToListView()
                    .tabItem {
                        Label("From Image", systemImage: "text.viewfinder")
                    }
                APIKeyTabView()
                    .tabItem {
                        Label("API Key", systemImage: "key.fill")
                    }
            }
            .environment(store)
        }
    }
}
