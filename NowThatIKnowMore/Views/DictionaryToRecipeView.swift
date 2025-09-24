// Moved to Views/DictionaryToRecipeView.swift
import SwiftUI
import OSLog
internal import UniformTypeIdentifiers

struct DictionaryToRecipeView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @State private var dictionaryInput: String = ""
    @State private var parseError: String? = nil
    @State private var parsedRecipe: Recipe? = nil
    @State private var showingFileImporter: Bool = false
    @State private var isAdding: Bool = false
    @State private var duplicateRecipe: Bool = false
    let logger = Logger(subsystem: "com.headydiscy.NowThatIKnowMore", category: "DictionaryToRecipe")
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                GroupBox(label: Label("Paste or Load Dictionary", systemImage: "doc.plaintext")) {
                    TextEditor(text: $dictionaryInput)
                        .padding(6)
                        .frame(minHeight: 120, maxHeight: 260)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                HStack {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Import File", systemImage: "folder")
                    }
                    .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.json, .plainText], allowsMultipleSelection: false) { result in
                        do {
                            guard let selected = try result.get().first,
                                  let data = try? Data(contentsOf: selected),
                                  let text = String(data: data, encoding: .utf8) else {
                                parseError = "Could not load file."
                                return
                            }
                            dictionaryInput = text
                        } catch {
                            parseError = error.localizedDescription
                        }
                    }
                    Spacer()
                    Button("Parse") { parseDictionaryInput() }
                        .buttonStyle(.borderedProminent)
                        .disabled(dictionaryInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let error = parseError, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                if duplicateRecipe {
                    Text("A recipe with the same title, source URL, and image already exists.")
                        .foregroundColor(.orange)
                        .font(.body.bold())
                }
                if let recipe = parsedRecipe {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preview:")
                                .font(.headline)
                            Text(recipe.title ?? "No Title")
                                .font(.title2.bold())
                            if let image = recipe.image, let url = URL(string: image) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty: ProgressView()
                                    case .success(let img): img.resizable().aspectRatio(contentMode: .fit).frame(height: 90)
                                    case .failure:
                                        Text("Image could not be loaded.")
                                            .foregroundColor(.red)
                                            .frame(height: 90)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    @unknown default: EmptyView()
                                    }
                                }
                            }
                            Text("Instructions:")
                                .font(.subheadline)
                            Text(recipe.instructions ?? "No instructions.")
                                .lineLimit(4)
                            Button {
                                isAdding = true
                                recipeStore.add(recipe)
                                isAdding = false
                                parseError = "Recipe added!"
                            } label: {
                                Label("Add to Recipes", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isAdding || duplicateRecipe)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxHeight: 340)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Dictionary to Recipe")
        }
    }

    private func parseDictionaryInput() {
        parseError = nil
        parsedRecipe = nil
        duplicateRecipe = false
        let text = dictionaryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        // Try to parse as JSON
        guard let data = text.data(using: .utf8) else {
            parseError = "Input is not valid UTF-8."
            return
        }
        if let recipe = Recipe.decodeFromJSONOrPatchedDict(data) {
            checkDuplicate(recipe)
            return
        }
        // Fallback: try parsing as dictionary
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let dict = json as? [String: Any],
           let recipe = Recipe.decodeFromPatchedDict(dict) {
            checkDuplicate(recipe)
            return
        }
        parseError = "Could not decode input as a Recipe."
    }

    private func checkDuplicate(_ recipe: Recipe) {
        if recipeStore.recipes.contains(where: { stored in
            stored.title == recipe.title &&
            stored.sourceURL == recipe.sourceURL &&
            stored.image == recipe.image
        }) {
            duplicateRecipe = true
            parsedRecipe = nil
        } else {
            duplicateRecipe = false
            parsedRecipe = recipe
        }
    }
}

#Preview {
    DictionaryToRecipeView().environment(RecipeStore())
}
