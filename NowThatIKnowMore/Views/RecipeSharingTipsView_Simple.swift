//
//  RecipeSharingTipsView_Simple.swift
//  NowThatIKnowMore
//
//  Simpler enhancement - just adds a few more helpful sections
//

import SwiftUI

struct RecipeSharingTipsView_Simple: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue.gradient)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Help & Guide")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Learn how to use all features")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // NEW: Quick Start Section
                Section("Quick Start") {
                    TipRow(
                        icon: "link.circle.fill",
                        color: .blue,
                        title: "Add from Web",
                        description: "Paste recipe URLs in the Meal Plan tab to import recipes from websites"
                    )
                    
                    TipRow(
                        icon: "calendar.badge.clock",
                        color: .purple,
                        title: "Plan Your Week",
                        description: "Tap the calendar icon on any recipe to assign it to specific days"
                    )
                    
                    TipRow(
                        icon: "line.3.horizontal.decrease",
                        color: .green,
                        title: "Filter by Day",
                        description: "Use the picker at the top to view recipes for a specific day"
                    )
                }
                
                // NEW: Adding Recipes Section
                Section("Adding Recipes") {
                    TipRow(
                        icon: "globe",
                        color: .blue,
                        title: "From Recipe Websites",
                        description: "Copy a recipe URL from Safari and paste it in the Meal Plan tab"
                    )
                    
                    TipRow(
                        icon: "text.viewfinder",
                        color: .purple,
                        title: "From Images",
                        description: "Use the 'From Image' tab to extract ingredients from photos"
                    )
                    
                    TipRow(
                        icon: "tray.and.arrow.down",
                        color: .green,
                        title: "Import Files",
                        description: "Use the import button to browse for .recipe files"
                    )
                    
                    InfoRow(
                        icon: "key.fill",
                        color: .orange,
                        text: "Note: Web import requires a Spoonacular API key (set in API Key tab)"
                    )
                }
                
                // Existing Sharing Section
                Section("Sharing Recipes") {
                    TipRow(
                        icon: "1.circle.fill",
                        title: "Open any recipe",
                        description: "Navigate to a recipe you want to share"
                    )
                    
                    TipRow(
                        icon: "2.circle.fill",
                        title: "Tap 'Email Recipe'",
                        description: "Find the Email Recipe button in the recipe detail view"
                    )
                    
                    TipRow(
                        icon: "3.circle.fill",
                        title: "Send the email",
                        description: "The email includes a formatted recipe and a .recipe file attachment"
                    )
                }
                
                Section("Importing Recipes") {
                    TipRow(
                        icon: "envelope.open.fill",
                        color: .green,
                        title: "From Email",
                        description: "Tap the .recipe attachment and choose 'Open in NowThatIKnowMore'"
                    )
                    
                    TipRow(
                        icon: "folder.fill",
                        color: .green,
                        title: "From Files",
                        description: "Tap any .recipe file in the Files app to import it"
                    )
                }
                
                Section("What's Included in Shared Recipes") {
                    FeatureRow(icon: "doc.text", title: "Complete recipe data")
                    FeatureRow(icon: "photo", title: "Recipe images")
                    FeatureRow(icon: "list.bullet", title: "Full ingredient list")
                    FeatureRow(icon: "text.alignleft", title: "Step-by-step instructions")
                    FeatureRow(icon: "clock", title: "Cooking times and servings")
                    FeatureRow(icon: "link", title: "Source information")
                }
                
                // NEW: Organizing Section
                Section("Organizing Your Meal Plan") {
                    TipRow(
                        icon: "calendar.badge.clock",
                        color: .purple,
                        title: "Assign to Days",
                        description: "Tap the calendar icon to assign a recipe to one or more days"
                    )
                    
                    TipRow(
                        icon: "line.3.horizontal.decrease.circle",
                        color: .blue,
                        title: "Filter View",
                        description: "Select 'All' to see all recipes, or pick a day to see only that day's meals"
                    )
                    
                    TipRow(
                        icon: "trash.circle.fill",
                        color: .red,
                        title: "Remove Recipes",
                        description: "Swipe left on any recipe to delete it from your collection"
                    )
                }
                
                // NEW: Tips & Troubleshooting
                Section("Tips & Troubleshooting") {
                    InfoRow(
                        icon: "lightbulb.fill",
                        color: .yellow,
                        text: "Plan your week on Sunday - assign recipes for the upcoming days"
                    )
                    
                    InfoRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: "Recipe files are small and perfect for sharing via email"
                    )
                    
                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        text: "Make sure Mail is configured on your device to send emails"
                    )
                    
                    InfoRow(
                        icon: "wifi",
                        color: .blue,
                        text: "Internet connection needed for web-based recipe imports"
                    )
                    
                    InfoRow(
                        icon: "shield.fill",
                        color: .blue,
                        text: "Recipes are shared directly - no cloud service involved"
                    )
                    
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: .purple,
                        text: "Duplicate recipes are detected automatically when importing"
                    )
                }
                
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.pink.gradient)
                        
                        Text("Happy Cooking!")
                            .font(.headline)
                        
                        Text("Plan meals, share recipes, and cook with confidence.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Help & Guide")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Reuse the same helper views
// TipRow, FeatureRow, InfoRow from the original file

#Preview {
    RecipeSharingTipsView_Simple()
}
