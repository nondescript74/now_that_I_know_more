//
//  RecipeSharingTipsView.swift
//  NowThatIKnowMore
//
//  In-app tips for sharing and importing recipes
//

import SwiftUI

struct RecipeSharingTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue.gradient)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share Recipes")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Send recipes to friends and family")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("How to Share") {
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
                
                Section("How to Import") {
                    TipRow(
                        icon: "tray.and.arrow.down.fill",
                        color: .green,
                        title: "From Email",
                        description: "Tap the .recipe attachment in the email and choose 'Open in NowThatIKnowMore'"
                    )
                    
                    TipRow(
                        icon: "folder.fill",
                        color: .green,
                        title: "From Files",
                        description: "Tap any .recipe file in the Files app to import it"
                    )
                    
                    TipRow(
                        icon: "square.and.arrow.down",
                        color: .green,
                        title: "Manual Import",
                        description: "Use the import button in the Meal Plan tab to browse for .recipe files"
                    )
                }
                
                Section("What's Included") {
                    FeatureRow(icon: "doc.text", title: "Complete recipe data")
                    FeatureRow(icon: "photo", title: "Recipe images")
                    FeatureRow(icon: "list.bullet", title: "Full ingredient list")
                    FeatureRow(icon: "text.alignleft", title: "Step-by-step instructions")
                    FeatureRow(icon: "clock", title: "Cooking times and servings")
                    FeatureRow(icon: "link", title: "Source information")
                }
                
                Section("Tips") {
                    InfoRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: "Recipe files are small and email-friendly"
                    )
                    
                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        text: "Make sure Mail is configured on your device to send emails"
                    )
                    
                    InfoRow(
                        icon: "shield.fill",
                        color: .blue,
                        text: "Recipes are shared directly - no cloud service involved"
                    )
                    
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: .purple,
                        text: "Duplicate recipes are detected automatically"
                    )
                }
                
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.pink.gradient)
                        
                        Text("Share the love of cooking!")
                            .font(.headline)
                        
                        Text("Exchange recipes with friends, family, and fellow food enthusiasts.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Recipe Sharing")
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

struct TipRow: View {
    var icon: String
    var color: Color = .blue
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FeatureRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
        }
    }
}

struct InfoRow: View {
    var icon: String
    var color: Color
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    RecipeSharingTipsView()
}
