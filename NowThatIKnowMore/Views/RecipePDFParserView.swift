//
//  RecipePDFParserView.swift
//  NowThatIKnowMore
//
//  SwiftUI view for parsing recipes from PDF files
//  Alternative to photo-based OCR with better multi-column support
//

import SwiftUI
import SwiftData
@preconcurrency import PDFKit
internal import UniformTypeIdentifiers

struct RecipePDFParserView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPDF: URL?
    @State private var pdfDocument: PDFDocument?
    @State private var isImporting = false
    @State private var isParsing = false
    @State private var parsedRecipe: ParsedRecipe?
    @State private var parsedRecipeModel: RecipeModel?
    @State private var parseError: String?
    @State private var showSaveSuccess = false
    
    // Parser configuration
    @State private var selectedStrategy: RecipePDFParser.ColumnStrategy = .columnAware
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("PDF Recipe Parser")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Import recipes from PDF files. Better accuracy for multi-column layouts compared to photos.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // PDF Preview
                    if let document = pdfDocument {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PDF Preview")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if let page = document.page(at: 0) {
                                PDFPageView(page: page)
                                    .frame(height: 300)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                            }
                            
                            HStack {
                                Label("\(document.pageCount) page(s)", systemImage: "doc")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if let url = selectedPDF {
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { isImporting = true }) {
                            Label("Choose PDF File", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isParsing)
                        
                        if pdfDocument != nil {
                            // Parser Strategy Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Parsing Strategy")
                                    .font(.headline)
                                
                                Picker("Strategy", selection: $selectedStrategy) {
                                    Text("Column-Aware").tag(RecipePDFParser.ColumnStrategy.columnAware)
                                    Text("Sequential").tag(RecipePDFParser.ColumnStrategy.sequential)
                                    Text("Layout-Preserving").tag(RecipePDFParser.ColumnStrategy.preserveLayout)
                                }
                                .pickerStyle(.segmented)
                                
                                strategyDescriptionView
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .background(Color.accentColor.opacity(0.05))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            
                            // Parse Button
                            Button(action: parsePDF) {
                                HStack {
                                    if isParsing {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                        Text("Parsing...")
                                    } else {
                                        Label("Parse Recipe", systemImage: "wand.and.stars")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isParsing)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Display
                    if let error = parseError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Parse Error")
                                    .font(.headline)
                            }
                            
                            Text(error)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Parsed Recipe Display
                    if let recipe = parsedRecipeModel {
                        ParsedRecipeCard(
                            recipe: recipe,
                            onSave: {
                                saveRecipe(recipe)
                            },
                            onShare: {
                                shareRecipe(recipe)
                            }
                        )
                        .padding(.horizontal)
                    }
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Recipe Saved", isPresented: $showSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Recipe has been saved to your collection.")
        }
    }
    
    // MARK: - Strategy Description
    
    @ViewBuilder
    private var strategyDescriptionView: some View {
        switch selectedStrategy {
        case .columnAware:
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended for most recipes")
                        .fontWeight(.semibold)
                    Text("Detects and handles multi-column ingredient lists (imperial/metric). Best for recipe cards with table layouts.")
                }
            }
            
        case .sequential:
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "list.bullet")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Simple top-to-bottom reading")
                        .fontWeight(.semibold)
                    Text("Best for single-column recipes like magazine pages or simple printed recipes.")
                }
            }
            
        case .preserveLayout:
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "square.grid.3x3")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced layout detection")
                        .fontWeight(.semibold)
                    Text("Detects recipe sections based on spatial positioning. Use for complex layouts with multiple regions.")
                }
            }
        }
    }
    
    // MARK: - File Handling
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Security-scoped access
            guard url.startAccessingSecurityScopedResource() else {
                parseError = "Unable to access the selected file."
                return
            }
            
            // Load PDF
            if let document = PDFDocument(url: url) {
                self.selectedPDF = url
                self.pdfDocument = document
                self.parseError = nil
                print("📄 PDF loaded: \(url.lastPathComponent), \(document.pageCount) page(s)")
            } else {
                parseError = "Unable to load PDF document."
            }
            
            url.stopAccessingSecurityScopedResource()
            
        case .failure(let error):
            parseError = "File selection error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Parsing
    
    private func parsePDF() {
        guard let document = pdfDocument else {
            parseError = "No PDF document loaded."
            return
        }
        
        print("🔍 Starting PDF parse with strategy: \(selectedStrategy)")
        
        isParsing = true
        parseError = nil
        parsedRecipe = nil
        parsedRecipeModel = nil
        
        // Capture the strategy before entering background context
        let strategy = selectedStrategy
        
        // Parse on main thread since RecipePDFParser is main actor-isolated
        Task { @MainActor in
            let parser = RecipePDFParser(columnStrategy: strategy, debugMode: true)
            
            parser.parsePDF(document) { result in
                Task { @MainActor in
                    isParsing = false
                    
                    switch result {
                    case .success(let parsed):
                        print("✅ Parse successful: '\(parsed.title)'")
                        parsedRecipe = parsed
                        parsedRecipeModel = ParsedRecipeAdapter.convertToRecipeModel(parsed)
                        
                    case .failure(let error):
                        print("❌ Parse failed: \(error.localizedDescription)")
                        parseError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Save & Share
    
    private func saveRecipe(_ recipe: RecipeModel) {
        modelContext.insert(recipe)
        
        do {
            try modelContext.save()
            showSaveSuccess = true
            print("✅ Recipe saved to database")
        } catch {
            parseError = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
    
    private func shareRecipe(_ recipe: RecipeModel) {
        var text = (recipe.title ?? "Recipe") + "\n\n"
        
        if let servings = recipe.servings {
            text += "Servings: \(servings)\n\n"
        }
        
        text += "Ingredients:\n"
        if let ingredients = recipe.extendedIngredients {
            for ingredient in ingredients {
                if let original = ingredient.original {
                    text += "• \(original)\n"
                }
            }
        }
        
        if let instructions = recipe.instructions {
            text += "\nInstructions:\n\(instructions)\n"
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - PDF Page View

struct PDFPageView: View {
    let page: PDFPage
    
    var body: some View {
        GeometryReader { geometry in
            let image = page.thumbnail(of: geometry.size, for: .trimBox)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Parsed Recipe Card

struct ParsedRecipeCard: View {
    let recipe: RecipeModel
    let onSave: () -> Void
    let onShare: () -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Parsed Recipe")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() }}) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                
                // Title
                if let title = recipe.title {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                // Servings
                if let servings = recipe.servings {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Servings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "person.2")
                            Text("\(servings)")
                        }
                        .font(.subheadline)
                    }
                }
                
                // Ingredients
                if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients (\(ingredients.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(ingredients.indices, id: \.self) { index in
                            if let original = ingredients[index].original {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(original)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                
                // Instructions
                if let instructions = recipe.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(instructions)
                            .font(.subheadline)
                            .lineLimit(5)
                    }
                }
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: onSave) {
                        Label("Save Recipe", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    return RecipePDFParserView()
        .modelContainer(container)
}
