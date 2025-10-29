//
//  RecipeSharingTipsView.swift
//  NowThatIKnowMore
//
//  In-app tips for sharing and importing recipes
//

import SwiftUI

struct RecipeSharingTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection = .overview
    
    enum HelpSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case addingRecipes = "Adding Recipes"
        case organizing = "Organizing"
        case sharing = "Sharing"
        case tips = "Tips & Tricks"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .addingRecipes: return "plus.circle.fill"
            case .organizing: return "calendar.badge.clock"
            case .sharing: return "envelope.circle.fill"
            case .tips: return "lightbulb.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HelpSection.allCases) { section in
                            sectionButton(for: section)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                
                // Content
                ScrollView {
                    contentForSection(selectedSection)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
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
    
    private func sectionButton(for section: HelpSection) -> some View {
        let isSelected = selectedSection == section
        let foregroundColor: Color = isSelected ? .white : .primary
        let backgroundColor: AnyShapeStyle = isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.secondary.opacity(0.1))
        
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.title2)
                Text(section.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .frame(width: 90, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
        }
    }
    
    @ViewBuilder
    private func contentForSection(_ section: HelpSection) -> some View {
        switch section {
        case .overview:
            overviewContent
        case .addingRecipes:
            addingRecipesContent
        case .organizing:
            organizingContent
        case .sharing:
            sharingContent
        case .tips:
            tipsContent
        }
    }
    
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your complete meal planning companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // App Overview Section
            VStack(alignment: .leading, spacing: 12) {
                Text("App Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "calendar.badge.clock",
                        color: .blue,
                        title: "Meal Planning",
                        description: "Organize recipes by day of the week for easy meal planning"
                    )
                    
                    TipRow(
                        icon: "link.circle.fill",
                        color: .green,
                        title: "Web Import",
                        description: "Add recipes from the web using URLs from popular recipe sites"
                    )
                    
                    TipRow(
                        icon: "text.viewfinder",
                        color: .purple,
                        title: "Image Recognition",
                        description: "Extract ingredient lists from photos (requires API key)"
                    )
                    
                    TipRow(
                        icon: "envelope.fill",
                        color: .orange,
                        title: "Recipe Sharing",
                        description: "Share recipes via email and import recipes from others"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Quick Tips Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Tips")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    InfoRow(
                        icon: "hand.tap.fill",
                        color: .blue,
                        text: "Tap any recipe to view full details including ingredients and instructions"
                    )
                    
                    InfoRow(
                        icon: "calendar.badge.clock",
                        color: .green,
                        text: "Use the calendar icon to assign recipes to specific days of the week"
                    )
                    
                    InfoRow(
                        icon: "line.3.horizontal.decrease.circle",
                        color: .purple,
                        text: "Filter your meal plan by day using the picker at the top"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var addingRecipesContent: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Recipes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Multiple ways to build your collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // From Web URLs Section
            VStack(alignment: .leading, spacing: 12) {
                Text("From Web URLs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "1.circle.fill",
                        title: "Find a recipe online",
                        description: "Browse your favorite recipe websites in Safari"
                    )
                    
                    TipRow(
                        icon: "2.circle.fill",
                        title: "Copy the URL",
                        description: "Long press the address bar and copy the recipe page URL"
                    )
                    
                    TipRow(
                        icon: "3.circle.fill",
                        title: "Paste in Meal Plan",
                        description: "Return to the app and paste the URL in the text field"
                    )
                    
                    TipRow(
                        icon: "4.circle.fill",
                        title: "Tap 'Add'",
                        description: "The app will automatically extract and save the recipe"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // From Images Section
            VStack(alignment: .leading, spacing: 12) {
                Text("From Images")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "text.viewfinder",
                        color: .purple,
                        title: "Go to 'From Image' tab",
                        description: "Switch to the From Image tab in the main app"
                    )
                    
                    TipRow(
                        icon: "photo.fill",
                        color: .purple,
                        title: "Select an image",
                        description: "Choose a photo containing a recipe or ingredient list"
                    )
                    
                    TipRow(
                        icon: "sparkles",
                        color: .purple,
                        title: "Extract ingredients",
                        description: "The app will use AI to extract ingredients from the image"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Import from Files Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Import from Files")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "tray.and.arrow.down.fill",
                        color: .green,
                        title: "Tap Import button",
                        description: "Use the import button in the Meal Plan toolbar"
                    )
                    
                    TipRow(
                        icon: "folder.fill",
                        color: .green,
                        title: "Browse for .recipe files",
                        description: "Navigate to the .recipe file in the file picker"
                    )
                    
                    TipRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Preview and import",
                        description: "Review the recipe details and tap Import"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Requirements Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Requirements")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    InfoRow(
                        icon: "key.fill",
                        color: .orange,
                        text: "Web import requires a Spoonacular API key (set in API Key tab)"
                    )
                    
                    InfoRow(
                        icon: "wifi",
                        color: .blue,
                        text: "Internet connection needed for web-based imports"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }

    
    private var organizingContent: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.purple.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Organize Your Week")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Plan meals for each day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Assigning Days Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Assigning Days")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "calendar.badge.clock",
                        color: .purple,
                        title: "Tap the calendar icon",
                        description: "Each recipe in your list has a calendar icon on the right"
                    )
                    
                    TipRow(
                        icon: "hand.tap.fill",
                        color: .purple,
                        title: "Select days",
                        description: "Choose which days of the week to cook this recipe"
                    )
                    
                    TipRow(
                        icon: "checkmark.circle.fill",
                        color: .purple,
                        title: "Multiple days",
                        description: "You can assign the same recipe to multiple days"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Filtering Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Filtering")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "line.3.horizontal.decrease",
                        color: .blue,
                        title: "Day picker",
                        description: "Use the picker at the top to filter by day of the week"
                    )
                    
                    TipRow(
                        icon: "list.bullet",
                        color: .blue,
                        title: "View 'All' recipes",
                        description: "Select 'All' to see your entire recipe collection"
                    )
                    
                    TipRow(
                        icon: "calendar",
                        color: .blue,
                        title: "Daily view",
                        description: "Filter to a specific day to see just that day's meals"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Managing Recipes Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Managing Recipes")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "trash.fill",
                        color: .red,
                        title: "Delete recipes",
                        description: "Swipe left on any recipe to delete it from your collection"
                    )
                    
                    TipRow(
                        icon: "pencil.circle.fill",
                        color: .orange,
                        title: "Edit button",
                        description: "Tap Edit in the toolbar to enter deletion mode"
                    )
                    
                    TipRow(
                        icon: "xmark.circle.fill",
                        color: .purple,
                        title: "Clear day assignments",
                        description: "In the day picker sheet, tap 'Clear All Days' to unassign"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Pro Tips Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Pro Tips")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    InfoRow(
                        icon: "lightbulb.fill",
                        color: .yellow,
                        text: "Plan your week on Sunday - assign recipes for the upcoming days"
                    )
                    
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: .green,
                        text: "Reuse favorite recipes by assigning them to multiple weeks"
                    )
                    
                    InfoRow(
                        icon: "list.clipboard",
                        color: .blue,
                        text: "Keep unassigned recipes in 'All' as a recipe library"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var sharingContent: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange.gradient)
                    
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // How to Share Section
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Share")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
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
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // How to Import Section
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Import")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
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
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // What's Included Section
            VStack(alignment: .leading, spacing: 12) {
                Text("What's Included")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    FeatureRow(icon: "doc.text", title: "Complete recipe data")
                    FeatureRow(icon: "photo", title: "Recipe images")
                    FeatureRow(icon: "list.bullet", title: "Full ingredient list")
                    FeatureRow(icon: "text.alignleft", title: "Step-by-step instructions")
                    FeatureRow(icon: "clock", title: "Cooking times and servings")
                    FeatureRow(icon: "link", title: "Source information")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Tips Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Tips")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
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
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Closing message
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
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
    }

    
    private var tipsContent: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tips & Tricks")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Get the most out of the app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // API Setup Section
            VStack(alignment: .leading, spacing: 12) {
                Text("API Setup")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "key.fill",
                        color: .blue,
                        title: "Get an API key",
                        description: "Visit spoonacular.com to sign up for a free API key"
                    )
                    
                    TipRow(
                        icon: "gear",
                        color: .blue,
                        title: "Configure in app",
                        description: "Enter your API key in the 'API Key' tab"
                    )
                    
                    InfoRow(
                        icon: "info.circle.fill",
                        color: .blue,
                        text: "The free tier includes 150 API calls per day - plenty for personal use"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Recipe Details Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Recipe Details")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "photo.fill",
                        color: .purple,
                        title: "View images",
                        description: "Recipe photos load automatically when you view recipe details"
                    )
                    
                    TipRow(
                        icon: "list.number",
                        color: .purple,
                        title: "Step-by-step",
                        description: "Instructions are numbered for easy following while cooking"
                    )
                    
                    TipRow(
                        icon: "link.circle.fill",
                        color: .purple,
                        title: "Source links",
                        description: "Tap the source URL to visit the original recipe website"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Efficiency Tips Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Efficiency Tips")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    InfoRow(
                        icon: "bolt.fill",
                        color: .yellow,
                        text: "Use the 'All' filter to see your complete recipe library at once"
                    )
                    
                    InfoRow(
                        icon: "calendar.badge.plus",
                        color: .green,
                        text: "Batch-assign recipes on Sunday for the whole week ahead"
                    )
                    
                    InfoRow(
                        icon: "arrow.clockwise",
                        color: .blue,
                        text: "Import recipes when you find them, organize them later"
                    )
                    
                    InfoRow(
                        icon: "square.and.arrow.up",
                        color: .orange,
                        text: "Share recipe files via AirDrop for instant transfer to nearby devices"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Best Practices Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Best Practices")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    InfoRow(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        text: "Test recipe URLs in Safari first to ensure they're valid recipe pages"
                    )
                    
                    InfoRow(
                        icon: "trash.fill",
                        color: .red,
                        text: "Regularly clean up recipes you no longer need to keep your list manageable"
                    )
                    
                    InfoRow(
                        icon: "doc.badge.plus",
                        color: .purple,
                        text: "Create new recipes manually using the 'Edit Recipe' tab"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            // Troubleshooting Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Troubleshooting")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TipRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "Recipe won't import?",
                        description: "Check your API key and internet connection. Some websites may not be supported."
                    )
                    
                    TipRow(
                        icon: "envelope.badge.fill",
                        color: .orange,
                        title: "Email button disabled?",
                        description: "Configure at least one email account in Settings → Mail"
                    )
                    
                    TipRow(
                        icon: "photo.badge.exclamationmark",
                        color: .orange,
                        title: "Images not loading?",
                        description: "Check your internet connection. Some image URLs may be expired or invalid."
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
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
