//
//  RecipeDiagnosticView.swift
//  NowThatIKnowMore
//
//  Diagnostic tool for verifying SwiftData recipe integrity
//

import SwiftUI
import SwiftData

struct RecipeDiagnosticView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecipes: [RecipeModel]
    @Query private var allBooks: [RecipeBookModel]
    @Query private var allMedia: [RecipeMediaModel]
    @Query private var allNotes: [RecipeNoteModel]
    
    @State private var recipeService: RecipeService?
    @State private var diagnosticResults: DiagnosticResults?
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section("Database Summary") {
                    HStack {
                        Text("Total Recipes")
                        Spacer()
                        Text("\(allRecipes.count)")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Recipe Books")
                        Spacer()
                        Text("\(allBooks.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Media Items")
                        Spacer()
                        Text("\(allMedia.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Notes")
                        Spacer()
                        Text("\(allNotes.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Integrity Check
                if let results = diagnosticResults {
                    Section("Data Integrity") {
                        DiagnosticRow(
                            label: "Valid UUIDs",
                            value: "\(results.validUUIDs)/\(allRecipes.count)",
                            isHealthy: results.validUUIDs == allRecipes.count
                        )
                        
                        DiagnosticRow(
                            label: "Has Spoonacular ID",
                            value: "\(results.recipesWithAPIID)",
                            isHealthy: true
                        )
                        
                        DiagnosticRow(
                            label: "Missing Titles",
                            value: "\(results.recipesWithoutTitle)",
                            isHealthy: results.recipesWithoutTitle == 0
                        )
                        
                        DiagnosticRow(
                            label: "Orphaned Media",
                            value: "\(results.orphanedMedia)",
                            isHealthy: results.orphanedMedia == 0
                        )
                        
                        DiagnosticRow(
                            label: "Orphaned Notes",
                            value: "\(results.orphanedNotes)",
                            isHealthy: results.orphanedNotes == 0
                        )
                    }
                    
                    // Recipe List
                    Section("All Recipes") {
                        ForEach(allRecipes) { recipe in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title ?? "Untitled Recipe")
                                    .font(.headline)
                                
                                HStack {
                                    Text("UUID:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(recipe.uuid.uuidString)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let id = recipe.id {
                                    HStack {
                                        Text("Spoonacular ID:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(id)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("No Spoonacular ID")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                
                                HStack {
                                    if let bookCount = recipe.books?.count, bookCount > 0 {
                                        Label("\(bookCount) books", systemImage: "books.vertical")
                                            .font(.caption2)
                                    }
                                    
                                    if let mediaCount = recipe.mediaItems?.count, mediaCount > 0 {
                                        Label("\(mediaCount) media", systemImage: "photo")
                                            .font(.caption2)
                                    }
                                    
                                    if let noteCount = recipe.notes?.count, noteCount > 0 {
                                        Label("\(noteCount) notes", systemImage: "note.text")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Problems Found
                    if !results.issues.isEmpty {
                        Section("Issues Found") {
                            ForEach(results.issues, id: \.self) { issue in
                                Label(issue, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                
                // Actions
                Section("Actions") {
                    Button(action: runDiagnostics) {
                        Label("Run Diagnostics", systemImage: "stethoscope")
                    }
                    
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Export All Recipes (Backup)", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button(action: exportRecipes) {
                            Label("Export All Recipes (Backup)", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    Button(role: .destructive, action: showDeleteConfirmation) {
                        Label("Delete All Recipes", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Recipe Diagnostics")
            .onAppear {
                if recipeService == nil {
                    recipeService = RecipeService(modelContext: modelContext)
                }
                runDiagnostics()
            }
        }
    }
    
    private func runDiagnostics() {
        let validUUIDs = allRecipes.filter { !$0.uuid.uuidString.isEmpty }.count
        let recipesWithAPIID = allRecipes.filter { $0.id != nil }.count
        let recipesWithoutTitle = allRecipes.filter { $0.title == nil || $0.title?.isEmpty == true }.count
        let orphanedMedia = allMedia.filter { $0.recipe == nil }.count
        let orphanedNotes = allNotes.filter { $0.recipe == nil }.count
        
        var issues: [String] = []
        
        if validUUIDs != allRecipes.count {
            issues.append("Some recipes have invalid UUIDs")
        }
        
        if recipesWithoutTitle > 0 {
            issues.append("\(recipesWithoutTitle) recipes missing titles")
        }
        
        if orphanedMedia > 0 {
            issues.append("\(orphanedMedia) orphaned media items")
        }
        
        if orphanedNotes > 0 {
            issues.append("\(orphanedNotes) orphaned notes")
        }
        
        diagnosticResults = DiagnosticResults(
            validUUIDs: validUUIDs,
            recipesWithAPIID: recipesWithAPIID,
            recipesWithoutTitle: recipesWithoutTitle,
            orphanedMedia: orphanedMedia,
            orphanedNotes: orphanedNotes,
            issues: issues
        )
        
        printDiagnosticReport()
    }
    
    private func printDiagnosticReport() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 SWIFTDATA RECIPE DIAGNOSTIC REPORT")
        print(String(repeating: "=", count: 60))
        print("\n📈 Summary:")
        print("   Total Recipes: \(allRecipes.count)")
        print("   Recipe Books: \(allBooks.count)")
        print("   Media Items: \(allMedia.count)")
        print("   Notes: \(allNotes.count)")
        
        if let results = diagnosticResults {
            print("\n🔍 Integrity Check:")
            print("   ✓ Valid UUIDs: \(results.validUUIDs)/\(allRecipes.count)")
            print("   • Recipes with API ID: \(results.recipesWithAPIID)")
            print("   • Recipes without Title: \(results.recipesWithoutTitle)")
            print("   • Orphaned Media: \(results.orphanedMedia)")
            print("   • Orphaned Notes: \(results.orphanedNotes)")
            
            if !results.issues.isEmpty {
                print("\n⚠️  Issues Found:")
                for issue in results.issues {
                    print("   - \(issue)")
                }
            } else {
                print("\n✅ No issues found! Database is healthy.")
            }
        }
        
        print("\n📋 Recipe Details:")
        for (index, recipe) in allRecipes.enumerated() {
            print("   \(index + 1). \(recipe.title ?? "Untitled")")
            print("      UUID: \(recipe.uuid.uuidString)")
            print("      Spoonacular ID: \(recipe.id?.description ?? "none")")
            print("      Books: \(recipe.books?.count ?? 0)")
            print("      Media: \(recipe.mediaItems?.count ?? 0)")
            print("      Notes: \(recipe.notes?.count ?? 0)")
            print("")
        }
        
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    private func exportRecipes() {
        exportURL = createExportFile()
    }
    
    private func createExportFile() -> URL? {
        // Create JSON export of all recipes
        var exportData: [[String: Any]] = []
        
        for recipe in allRecipes {
            var recipeDict: [String: Any] = [
                "uuid": recipe.uuid.uuidString,
                "title": recipe.title ?? "Untitled",
                "createdAt": recipe.createdAt.ISO8601Format(),
                "modifiedAt": recipe.modifiedAt.ISO8601Format()
            ]
            
            if let id = recipe.id {
                recipeDict["spoonacularID"] = id
            }
            
            if let servings = recipe.servings {
                recipeDict["servings"] = servings
            }
            
            // Add more fields as needed
            recipeDict["vegetarian"] = recipe.vegetarian
            recipeDict["vegan"] = recipe.vegan
            recipeDict["glutenFree"] = recipe.glutenFree
            
            exportData.append(recipeDict)
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) else {
            return nil
        }
        
        let fileName = "recipe_backup_\(Date().timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try? jsonData.write(to: fileURL)
        return fileURL
    }
    
    private func showDeleteConfirmation() {
        // This would show an alert - implement if needed
        print("⚠️  Delete all recipes requested")
    }
}

// MARK: - Supporting Views

struct DiagnosticRow: View {
    let label: String
    let value: String
    let isHealthy: Bool
    
    var body: some View {
        HStack {
            Label(label, systemImage: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isHealthy ? .green : .orange)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
        }
    }
}

struct DiagnosticResults {
    let validUUIDs: Int
    let recipesWithAPIID: Int
    let recipesWithoutTitle: Int
    let orphanedMedia: Int
    let orphanedNotes: Int
    let issues: [String]
}

#Preview {
    RecipeDiagnosticView()
        .modelContainer(try! ModelContainer.preview())
}
