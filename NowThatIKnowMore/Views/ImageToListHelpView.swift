import SwiftUI

struct ImageToListHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Introduction
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Use Image to List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Convert recipe images into structured recipes using OCR (Optical Character Recognition). Follow these steps to get the best results.")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Step 1: Select Images
                    HelpStepView(
                        stepNumber: 1,
                        title: "Select Recipe Images",
                        icon: "photo.on.rectangle.angled",
                        iconColor: .blue,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tap 'Select 1-5 Images' to choose photos from your library.")
                                
                                Text("**Tips for best results:**")
                                    .fontWeight(.semibold)
                                    .padding(.top, 4)
                                
                                BulletPoint(text: "Use clear, well-lit photos")
                                BulletPoint(text: "Ensure text is readable and not blurry")
                                BulletPoint(text: "Select up to 5 images if recipe spans multiple pages")
                                BulletPoint(text: "Images will be processed in order")
                            }
                        }
                    )
                    
                    // Step 2: Arrange Text Blocks
                    HelpStepView(
                        stepNumber: 2,
                        title: "Arrange Recognized Text Blocks",
                        icon: "arrow.up.arrow.down",
                        iconColor: .orange,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("After OCR completes, arrange the text blocks in the correct order.")
                                
                                BulletPoint(text: "Use ↑↓ buttons to reorder blocks")
                                BulletPoint(text: "Add blank lines between blocks using the stepper")
                                BulletPoint(text: "Preview combined text before continuing")
                                BulletPoint(text: "Tap 'Continue' when order looks correct")
                            }
                        }
                    )
                    
                    // Step 3: Review Duplicates
                    HelpStepView(
                        stepNumber: 3,
                        title: "Review Duplicate Lines (if any)",
                        icon: "doc.on.doc",
                        iconColor: .purple,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("If duplicate lines are detected, you'll see a review screen.")
                                
                                BulletPoint(text: "Duplicates are automatically removed")
                                BulletPoint(text: "Select any duplicates you want to restore")
                                BulletPoint(text: "Tap 'Apply Changes' to continue")
                            }
                        }
                    )
                    
                    // Step 4: Assign Recipe Parts
                    HelpStepView(
                        stepNumber: 4,
                        title: "Assign Recipe Parts",
                        icon: "list.bullet.rectangle",
                        iconColor: .green,
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Organize recognized text into recipe sections. Each line can only be used once.")
                                    .fontWeight(.medium)
                                
                                // Title Section
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Title", systemImage: "textformat.size")
                                        .fontWeight(.semibold)
                                    BulletPoint(text: "Select one or more lines for the recipe title")
                                    BulletPoint(text: "Selected lines appear at the top")
                                    BulletPoint(text: "Edit the combined title if needed")
                                }
                                
                                // Summary Section
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Summary", systemImage: "text.alignleft")
                                        .fontWeight(.semibold)
                                    BulletPoint(text: "Choose lines that describe the recipe")
                                    BulletPoint(text: "Optional but recommended")
                                }
                                
                                // Ingredients Section
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Ingredients", systemImage: "cart")
                                        .fontWeight(.semibold)
                                    BulletPoint(text: "Select lines and tap 'Add Ingredient Group'")
                                    BulletPoint(text: "Create multiple groups for sections (e.g., 'For the sauce')")
                                    BulletPoint(text: "Drag and drop to merge lines")
                                    BulletPoint(text: "Items in blue are being grouped, green are completed")
                                }
                                
                                // Instructions Section
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Instructions", systemImage: "list.number")
                                        .fontWeight(.semibold)
                                    BulletPoint(text: "Same grouping system as ingredients")
                                    BulletPoint(text: "Each group becomes one instruction step")
                                }
                            }
                        }
                    )
                    
                    // Step 5: Add Details
                    HelpStepView(
                        stepNumber: 5,
                        title: "Add Recipe Details",
                        icon: "info.circle",
                        iconColor: .cyan,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "Image: Add URL or use selected photo")
                                BulletPoint(text: "Cuisine: Select from dropdown")
                                BulletPoint(text: "Credits: Source or author name")
                                BulletPoint(text: "Cook Minutes: Select from text or enter manually")
                                BulletPoint(text: "Servings: Select from text or enter manually")
                            }
                        }
                    )
                    
                    // Step 6: Save
                    HelpStepView(
                        stepNumber: 6,
                        title: "Save Your Recipe",
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Once you've assigned Title, Ingredients, and Instructions:")
                                
                                BulletPoint(text: "The 'Save as Recipe' button will activate")
                                BulletPoint(text: "Tap to save to your recipe collection")
                                BulletPoint(text: "Recipe will appear in your main list")
                            }
                        }
                    )
                    
                    Divider()
                    
                    // Tips & Tricks
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tips & Tricks", systemImage: "lightbulb.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        TipCard(
                            icon: "hand.draw",
                            title: "Drag to Merge",
                            description: "Drag one line onto another to combine them. Useful for fixing split text."
                        )
                        
                        TipCard(
                            icon: "eye.slash",
                            title: "Auto-Hiding",
                            description: "Lines assigned to one section automatically disappear from other sections to prevent duplicates."
                        )
                        
                        TipCard(
                            icon: "arrow.counterclockwise",
                            title: "Undo Selections",
                            description: "Tap a selected line (with checkmark) to unselect it. It will reappear in other sections."
                        )
                        
                        TipCard(
                            icon: "list.bullet.indent",
                            title: "Grouping Strategy",
                            description: "For ingredients: Group items by recipe section. For instructions: Group sentences that form one step."
                        )
                    }
                    
                    Divider()
                    
                    // Common Issues
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Troubleshooting", systemImage: "wrench.and.screwdriver.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        IssueCard(
                            issue: "Text not recognized accurately",
                            solution: "Try taking a clearer photo with better lighting. Ensure text is large and readable."
                        )
                        
                        IssueCard(
                            issue: "Text in wrong order",
                            solution: "Use the arrow buttons in Step 2 to reorder text blocks before continuing."
                        )
                        
                        IssueCard(
                            issue: "Can't find a line I need",
                            solution: "Check if it's already selected in another section. Unselect it there to make it available again."
                        )
                        
                        IssueCard(
                            issue: "Save button disabled",
                            solution: "Ensure you've selected at least: 1 title line, 1 ingredient group, and 1 instruction group."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

struct HelpStepView<Content: View>: View {
    let stepNumber: Int
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Step \(stepNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.headline)
                }
                
                Spacer()
            }
            
            content
                .padding(.leading, 56)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
            Spacer()
        }
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct IssueCard: View {
    let issue: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(issue)
                    .fontWeight(.semibold)
            }
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(solution)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    ImageToListHelpView()
}
