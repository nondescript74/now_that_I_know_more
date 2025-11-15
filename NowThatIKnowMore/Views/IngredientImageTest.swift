//
//  IngredientImageTest.swift
//  NowThatIKnowMore
//
//  Test view to verify ingredient image loading with smart fallback strategy
//

import SwiftUI

struct IngredientImageTest: View {
    @Environment(\.modelContext) private var modelContext
    @State private var testResults: [TestResult] = []
    @State private var isLoading = true
    @State private var selectedStrategy: LoadingStrategy = .smart
    @State private var mappingService: IngredientImageMappingService?
    @State private var showSaveConfirmation = false
    @State private var savedCount = 0
    
    enum LoadingStrategy: String, CaseIterable {
        case smart = "Smart Fallback"
        case hyphenated = "Hyphenated Only"
        case simplified = "Simplified Only"
    }
    
    struct TestResult: Identifiable {
        let id = UUID()
        let ingredientName: String
        let ingredientID: Int?
        let successfulURL: String?
        let attemptedURLs: [String]
        let success: Bool
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Strategy Picker
                Picker("Loading Strategy", selection: $selectedStrategy) {
                    ForEach(LoadingStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    ProgressView("Loading test ingredients...")
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            summarySection()
                            
                            ForEach(testResults) { result in
                                ingredientResultRow(result: result)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Image Loading Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let service = mappingService {
                        let stats = service.getStatistics()
                        Text("DB: \(stats.successful)/\(stats.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Retest Sample (36)") {
                            Task {
                                await runTests()
                            }
                        }
                        
                        Button("Test ALL Ingredients") {
                            Task {
                                await testAllIngredients()
                            }
                        }
                        
                        Button("Save Results to Database") {
                            saveResultsToDatabase()
                        }
                        .disabled(testResults.isEmpty)
                        
                        Divider()
                        
                        Button("View Database Stats") {
                            showDatabaseStats()
                        }
                        
                        Button(role: .destructive) {
                            clearDatabase()
                        } label: {
                            Label("Clear Database", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Results Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Saved \(savedCount) ingredient image mappings to the database.")
            }
            .onAppear {
                if mappingService == nil {
                    mappingService = IngredientImageMappingService(modelContext: modelContext)
                }
            }
            .task {
                await runTests()
            }
        }
    }
    
    @ViewBuilder
    private func summarySection() -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Test Results")
                        .font(.headline)
                    Text("\(testResults.filter(\.success).count) / \(testResults.count) successful")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                let successRate = testResults.isEmpty ? 0 : Double(testResults.filter(\.success).count) / Double(testResults.count) * 100
                Text("\(Int(successRate))%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(successRate > 70 ? .green : successRate > 40 ? .orange : .red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func ingredientResultRow(result: TestResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                // Image preview
                if let urlString = result.successfulURL,
                   let url = URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(urlString)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            placeholderImage()
                        }
                    }
                } else {
                    placeholderImage()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.ingredientName)
                            .font(.headline)
                        if result.success {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let id = result.ingredientID {
                        Text("ID: \(id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let successful = result.successfulURL {
                        Text("✅ \(successful)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                Spacer()
            }
            
            // Show attempted URLs
            if !result.attemptedURLs.isEmpty {
                DisclosureGroup("Attempted URLs (\(result.attemptedURLs.count))") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.attemptedURLs, id: \.self) { url in
                            HStack {
                                Text(url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if url == result.successfulURL {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func placeholderImage() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
            Image(systemName: "photo")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Testing Logic
    
    private func runTests() async {
        print("\n🚀 Starting test run with strategy: \(selectedStrategy.rawValue)")
        
        isLoading = true
        testResults = []
        
        // Get diverse sample from SpoonacularIngredientManager
        let manager = SpoonacularIngredientManager.shared
        print("📚 SpoonacularIngredientManager has \(manager.ingredients.count) ingredients loaded")
        
        let sampleIngredients = selectDiverseSamples(from: manager.ingredients)
        print("🎯 Selected \(sampleIngredients.count) diverse ingredients for testing")
        
        var results: [TestResult] = []
        
        for (index, ingredient) in sampleIngredients.enumerated() {
            print("\n[\(index + 1)/\(sampleIngredients.count)] Testing: \(ingredient.name) (ID: \(ingredient.id))")
            let result = await testIngredient(name: ingredient.name, id: ingredient.id)
            results.append(result)
            
            // Progress update
            if result.success {
                print("   ✅ SUCCESS: \(result.successfulURL ?? "unknown")")
            } else {
                print("   ❌ FAILED after trying \(result.attemptedURLs.count) URLs")
            }
        }
        
        await MainActor.run {
            testResults = results
            isLoading = false
        }
        
        printTestSummary(results)
    }
    
    private func selectDiverseSamples(from ingredients: [SpoonacularIngredient]) -> [SpoonacularIngredient] {
        // Select a diverse sample of 30 ingredients
        let categories = [
            "flour", "sugar", "salt", "pepper", "butter", "oil", "milk", "egg", "cream",
            "garlic", "onion", "tomato", "potato", "carrot", "celery",
            "chicken", "beef", "pork", "fish", "shrimp",
            "pasta", "rice", "bread",
            "cheese", "yogurt",
            "apple", "banana", "lemon", "orange",
            "basil", "oregano", "thyme", "parsley",
            "vanilla", "cinnamon", "paprika"
        ]
        
        var selected: [SpoonacularIngredient] = []
        
        print("🔎 Searching for ingredients in categories...")
        for category in categories {
            if let found = ingredients.first(where: { $0.name.lowercased().contains(category) }) {
                selected.append(found)
                print("   ✓ Found '\(category)': \(found.name)")
            } else {
                print("   ✗ No match for '\(category)'")
            }
        }
        
        // If we don't have 30, add some random ones
        if selected.count < 30 {
            let needed = 30 - selected.count
            print("📝 Need \(needed) more ingredients, adding random ones...")
            let remaining = ingredients.filter { !selected.contains($0) }.shuffled()
            let additional = Array(remaining.prefix(needed))
            selected.append(contentsOf: additional)
            print("   Added: \(additional.map { $0.name }.joined(separator: ", "))")
        }
        
        print("✅ Final selection: \(selected.count) ingredients")
        return selected
    }
    
    private func testIngredient(name: String, id: Int) async -> TestResult {
        let urlsToTry = generateURLsToTry(for: name, strategy: selectedStrategy)
        print("   🔍 Generated \(urlsToTry.count) URLs to try: \(urlsToTry)")
        
        var attemptedURLs: [String] = []
        var successfulURL: String?
        
        for (urlIndex, urlFilename) in urlsToTry.enumerated() {
            attemptedURLs.append(urlFilename)
            let fullURL = "https://spoonacular.com/cdn/ingredients_100x100/\(urlFilename)"
            print("      [\(urlIndex + 1)/\(urlsToTry.count)] Trying: \(urlFilename)")
            
            if await testURL(fullURL) {
                successfulURL = urlFilename
                print("      ✅ FOUND IT!")
                break
            } else {
                print("      ❌ Not found")
            }
        }
        
        return TestResult(
            ingredientName: name,
            ingredientID: id,
            successfulURL: successfulURL,
            attemptedURLs: attemptedURLs,
            success: successfulURL != nil
        )
    }
    
    private func generateURLsToTry(for name: String, strategy: LoadingStrategy) -> [String] {
        switch strategy {
        case .smart:
            return smartFallbackURLs(for: name)
        case .hyphenated:
            return [normalizeToHyphenated(name, extension: "jpg")]
        case .simplified:
            return [simplifyIngredientName(name) + ".jpg"]
        }
    }
    
    /// Smart fallback strategy: Try multiple variations in order of likelihood
    private func smartFallbackURLs(for name: String) -> [String] {
        var urls: [String] = []
        print("      🧠 Smart fallback for '\(name)'")
        
        // 1. Check known mappings first
        if let knownFilename = IngredientImageMapper.shared.knownFilename(for: name) {
            print("         ✓ Found in known mappings: \(knownFilename)")
            urls.append(knownFilename)
        } else {
            print("         ⚠️ Not in known mappings")
        }
        
        // 2. Try exact hyphenated match with .jpg
        let hyphenatedJpg = normalizeToHyphenated(name, extension: "jpg")
        urls.append(hyphenatedJpg)
        print("         + Hyphenated .jpg: \(hyphenatedJpg)")
        
        // 3. Try exact hyphenated match with .png
        let hyphenatedPng = normalizeToHyphenated(name, extension: "png")
        urls.append(hyphenatedPng)
        print("         + Hyphenated .png: \(hyphenatedPng)")
        
        // 4. Try simplified version (last word) with .jpg
        let simplified = simplifyIngredientName(name)
        let simplifiedBase = normalizeToHyphenated(name, extension: "jpg").replacingOccurrences(of: ".jpg", with: "")
        if simplified != simplifiedBase {
            urls.append(simplified + ".jpg")
            urls.append(simplified + ".png")
            print("         + Simplified: \(simplified).jpg/png")
        }
        
        // 5. Try plural/singular variations
        let pluralVariations = generatePluralVariations(name)
        if !pluralVariations.isEmpty {
            print("         + Plural variations: \(pluralVariations.count) variants")
            urls.append(contentsOf: pluralVariations)
        }
        
        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueURLs = urls.filter { url in
            if seen.contains(url) {
                return false
            }
            seen.insert(url)
            return true
        }
        
        print("         → Total unique URLs: \(uniqueURLs.count)")
        return uniqueURLs
    }
    
    private func normalizeToHyphenated(_ name: String, extension: String) -> String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
            + ".\(`extension`)"
    }
    
    private func simplifyIngredientName(_ name: String) -> String {
        // Extract core ingredient from complex names
        let lowercased = name.lowercased()
        
        // Common ingredient keywords to extract
        let coreIngredients = [
            "flour", "sugar", "salt", "pepper", "butter", "oil", "milk", "cream", 
            "cheese", "yogurt", "egg", "chicken", "beef", "pork", "fish", "shrimp",
            "tomato", "potato", "onion", "garlic", "carrot", "celery",
            "pasta", "rice", "bread", "sauce",
            "apple", "banana", "lemon", "orange",
            "basil", "oregano", "thyme", "parsley", "cinnamon", "paprika", "vanilla"
        ]
        
        // Find the first matching core ingredient
        for core in coreIngredients {
            if lowercased.contains(core) {
                return core
            }
        }
        
        // Fallback: Take the last significant word
        let components = name.split(separator: " ")
        let lastWord = components.last.map(String.init) ?? name
        return lastWord
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    private func generatePluralVariations(_ name: String) -> [String] {
        var variations: [String] = []
        let normalized = normalizeToHyphenated(name, extension: "").dropLast() // Remove the dot
        
        // Try adding 's'
        variations.append(String(normalized) + "s.jpg")
        variations.append(String(normalized) + "s.png")
        
        // Try removing 's' if it ends with 's'
        if normalized.hasSuffix("s") {
            let singular = String(normalized.dropLast())
            variations.append(singular + ".jpg")
            variations.append(singular + ".png")
        }
        
        return variations
    }
    
    private func testURL(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            print("         ⚠️ Invalid URL: \(urlString)")
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                if !success {
                    print("         ℹ️ HTTP \(httpResponse.statusCode)")
                }
                return success
            }
            return false
        } catch {
            // Don't print every single network error to avoid clutter
            // print("         ⚠️ Error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func printTestSummary(_ results: [TestResult]) {
        let successful = results.filter(\.success).count
        let total = results.count
        let successRate = total > 0 ? Double(successful) / Double(total) * 100 : 0
        
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 INGREDIENT IMAGE TEST RESULTS")
        print(String(repeating: "=", count: 60))
        print("Strategy: \(selectedStrategy.rawValue)")
        print("Success Rate: \(successful)/\(total) (\(String(format: "%.1f", successRate))%)")
        print(String(repeating: "=", count: 60))
        
        print("\n✅ SUCCESSFUL (\(successful)):")
        for result in results.filter(\.success) {
            print("  • \(result.ingredientName) → \(result.successfulURL ?? "?")")
        }
        
        print("\n❌ FAILED (\(total - successful)):")
        for result in results.filter({ !$0.success }) {
            print("  • \(result.ingredientName)")
        }
        
        print("\n" + String(repeating: "=", count: 60) + "\n")
    }
    
    // MARK: - Database Operations
    
    @MainActor
    private func testAllIngredients() async {
        print("\n🚀 Starting FULL test of ALL ingredients")
        
        isLoading = true
        testResults = []
        
        let manager = SpoonacularIngredientManager.shared
        let allIngredients = manager.ingredients
        
        print("📚 Testing ALL \(allIngredients.count) ingredients - this will take a while!")
        print("⏰ Estimated time: ~\(allIngredients.count * 2 / 60) minutes")
        
        var results: [TestResult] = []
        let totalCount = allIngredients.count
        
        for (index, ingredient) in allIngredients.enumerated() {
            let progress = Int((Double(index + 1) / Double(totalCount)) * 100)
            
            if (index + 1) % 50 == 0 {
                print("\n📊 Progress: [\(index + 1)/\(totalCount)] - \(progress)%")
                print("   Successful so far: \(results.filter(\.success).count)")
            }
            
            let result = await testIngredient(name: ingredient.name, id: ingredient.id)
            results.append(result)
            
            // Auto-save every 100 ingredients
            if (index + 1) % 100 == 0 {
                print("💾 Auto-saving progress...")
                await MainActor.run {
                    testResults = results
                    saveResultsToDatabase()
                }
            }
        }
        
        await MainActor.run {
            testResults = results
            isLoading = false
        }
        
        printTestSummary(results)
        
        // Auto-save final results
        saveResultsToDatabase()
        print("\n✅ COMPLETED! Tested all \(totalCount) ingredients")
    }
    
    @MainActor
    private func saveResultsToDatabase() {
        guard let service = mappingService else { return }
        
        var savedSuccessfully = 0
        
        for result in testResults {
            guard let id = result.ingredientID else { continue }
            
            if result.success, let filename = result.successfulURL {
                service.recordSuccess(
                    ingredientID: id,
                    ingredientName: result.ingredientName,
                    imageFilename: filename,
                    attemptedURLs: result.attemptedURLs
                )
                savedSuccessfully += 1
            } else {
                service.recordFailure(
                    ingredientID: id,
                    ingredientName: result.ingredientName,
                    attemptedURLs: result.attemptedURLs
                )
                savedSuccessfully += 1
            }
        }
        
        savedCount = savedSuccessfully
        showSaveConfirmation = true
        
        print("💾 Saved \(savedSuccessfully) mappings to database")
    }
    
    @MainActor
    private func showDatabaseStats() {
        guard let service = mappingService else { return }
        
        let stats = service.getStatistics()
        print("\n" + String(repeating: "=", count: 60))
        print("📊 DATABASE STATISTICS")
        print(String(repeating: "=", count: 60))
        print("Total entries: \(stats.total)")
        print("✅ Successful mappings: \(stats.successful)")
        print("❌ No image available: \(stats.failed)")
        print("⏳ Untested: \(stats.untested)")
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    @MainActor
    private func clearDatabase() {
        guard let service = mappingService else { return }
        
        service.deleteAllMappings()
        print("🗑️ Cleared all database mappings")
    }
}

// MARK: - Ingredient Image Mapper
/// Maintains a mapping of known ingredient names to their Spoonacular image filenames
class IngredientImageMapper {
    static let shared = IngredientImageMapper()
    
    /// Known mappings from ingredient names to filenames
    /// This is built from successful test results and API documentation
    private var knownMappings: [String: String] = [
        // Verified from recent test results ✅
        "almond flour": "almond-flour.jpg",
        "salt": "salt.jpg",
        "celery salt": "salt.jpg",
        "avocado oil": "avocado-oil.jpg",
        "almond milk": "almond-milk.jpg",
        "hash brown potatoes": "hash-brown-potatoes.jpg",
        "baby carrots": "baby-carrots.jpg",
        "celery": "celery.jpg",
        "shrimp": "shrimp.jpg",
        "raw shrimp": "shrimp.jpg",
        "arborio rice": "arborio-rice.png",
        "apple": "apple.jpg",
        "banana": "bananas.jpg",  // Note: plural!
        "blood orange": "blood-orange.jpg",
        "basil": "basil.jpg",
        "dried basil": "basil.jpg",
        "oregano": "oregano.jpg",
        "thyme": "thyme.jpg",
        "dried thyme": "thyme.jpg",
        "parsley": "parsley.jpg",
        "cinnamon roll": "cinnamon-roll.jpg",
        "paprika": "paprika.jpg",
        
        // Previously verified
        "garlic": "garlic.jpg",
        "butter": "butter.jpg",
        "olive oil": "olive-oil.jpg",
        "flour": "flour.jpg",
        "sweet potato": "sweet-potato.jpg",
        "garlic powder": "garlic-powder.jpg",
        "chicken breast": "chicken-breasts.jpg", // Note: plural
        
        // Common ingredients (to be tested)
        "tomato": "tomatoes.jpg",
        "potato": "potatoes.jpg",
        "onion": "onions.jpg",
        "pepper": "pepper.jpg",
        "sugar": "white-sugar.jpg", // brown-sugar doesn't exist
        "milk": "milk.jpg",
        "egg": "egg.jpg",
        "cream": "heavy-cream.jpg",
        "cheese": "cheddar-cheese.jpg",
        "pasta": "pasta.jpg",
        "rice": "rice.jpg",
        "bread": "white-bread.jpg"
    ]
    
    private init() {}
    
    func knownFilename(for ingredientName: String) -> String? {
        return knownMappings[ingredientName.lowercased()]
    }
    
    /// Add a successful mapping to our known list
    func recordSuccessfulMapping(ingredientName: String, filename: String) {
        knownMappings[ingredientName.lowercased()] = filename
        print("📝 Recorded: '\(ingredientName)' → '\(filename)'")
    }
    
    /// Get all known mappings (for debugging)
    func getAllMappings() -> [String: String] {
        return knownMappings
    }
}

#Preview {
    IngredientImageTest()
}
