import SwiftUI
import Foundation

struct RecipeEditorView: View {
    @Environment(RecipeStore.self) private var recipeStore
    @Environment(\.dismiss) private var dismiss
    
    // The recipe to edit (passed in)
    @State var recipe: Recipe
    
    // Editable fields (initialized from recipe)
    @State private var title: String
    @State private var summary: String
    @State private var creditsText: String
    @State private var servings: String
    @State private var instructions: String
    @State private var selectedDays: [String]
    @State private var cuisines: String
    @State private var imageUrl: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var summarySelectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var instructionsSelectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var ingredients: String = ""
    @State private var ingredientsSelectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Editing mode helper for complex fields
    private static let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    init(recipe: Recipe) {
        self._recipe = State(initialValue: recipe)
        self._title = State(initialValue: recipe.title ?? "")
        self._summary = State(initialValue: recipe.summary ?? "")
        self._creditsText = State(initialValue: recipe.creditsText ?? "")
        self._servings = State(initialValue: recipe.servings.map { String($0) } ?? "")
        self._instructions = State(initialValue: recipe.instructions ?? "")
        self._selectedDays = State(initialValue: recipe.daysOfWeek ?? [])
        self._cuisines = State(initialValue: (recipe.cuisines)?.compactMap { $0.value as? String }.joined(separator: ", ") ?? "")
        self._imageUrl = State(initialValue: recipe.image ?? "")
//        if let list = recipe.extendedIngredients as? [[String: Any]] {
//            self._ingredients = State(initialValue: list.compactMap { $0["original"] as? String }.joined(separator: "\n"))
//        } else if let list = recipe.ingredients as? [String] {
//            self._ingredients = State(initialValue: list.joined(separator: "\n"))
//        } else {
//            self._ingredients = State(initialValue: "")
//        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                HStack {
                    TextField("Title", text: $title)
                    Button("Clear") { title = "" }
                }
                HStack {
                    TextField("Credits", text: $creditsText)
                    Button("Clear") { creditsText = "" }
                }
                HStack {
                    BindableTextView(text: $summary, selectedRange: $summarySelectedRange)
                        .frame(minHeight: 40, maxHeight: 150)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    Button("Clear") { summary = "" }
                }
                HStack(spacing: 12) {
                    Button("Remove HTML Tags") {
                        summary = summary.strippedHTML
                        summarySelectedRange = NSRange(location: min(summarySelectedRange.location, summary.count), length: 0)
                    }
                    Button("Insert Indent") {
                        let indent = "→ "
                        let loc = min(summarySelectedRange.location, summary.count)
                        summary.insert(contentsOf: indent, at: summary.index(summary.startIndex, offsetBy: loc))
                        summarySelectedRange = NSRange(location: loc + indent.count, length: 0)
                    }
                    Text("(Use '→' for indentation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("Image URL (optional)")) {
                HStack {
                    TextField("Paste image url", text: $imageUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button("Clear") { imageUrl = "" }
                }
                if isValidImageUrl(imageUrl) {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty: ProgressView()
                        case .success(let image): image.resizable().scaledToFit().frame(height: 120)
                        case .failure: Image(systemName: "exclamationmark.triangle").foregroundColor(.red)
                        @unknown default: EmptyView()
                        }
                    }
                }
            }
            Section(header: Text("Servings")) {
                HStack {
                    TextField("Servings", text: $servings)
                        .keyboardType(.numberPad)
                    Button("Clear") { servings = "" }
                }
            }
            Section(header: Text("Cuisines (comma separated)")) {
                HStack {
                    TextField("Cuisines", text: $cuisines)
                        .autocorrectionDisabled()
                    Button("Clear") { cuisines = "" }
                }
            }
            Section(header: Text("Ingredients (one per line)")) {
                BindableTextView(text: $ingredients, selectedRange: $ingredientsSelectedRange)
                    .frame(minHeight: 60, maxHeight: 180)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                HStack(spacing: 12) {
                    Button("Remove HTML Tags") {
                        ingredients = ingredients.strippedHTML
                        ingredientsSelectedRange = NSRange(location: min(ingredientsSelectedRange.location, ingredients.count), length: 0)
                    }
                    Button("Insert Indent") {
                        let indent = "→ "
                        let loc = min(ingredientsSelectedRange.location, ingredients.count)
                        ingredients.insert(contentsOf: indent, at: ingredients.index(ingredients.startIndex, offsetBy: loc))
                        ingredientsSelectedRange = NSRange(location: loc + indent.count, length: 0)
                    }
                    Text("(Use '→' for indentation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button("Clear") { ingredients = "" }
            }
            Section(header: Text("Instructions")) {
                BindableTextView(text: $instructions, selectedRange: $instructionsSelectedRange)
                    .frame(minHeight: 80, maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                HStack(spacing: 12) {
                    Button("Remove HTML Tags") {
                        instructions = instructions.strippedHTML
                        instructionsSelectedRange = NSRange(location: min(instructionsSelectedRange.location, instructions.count), length: 0)
                    }
                    Button("Insert Indent") {
                        let indent = "→ "
                        let loc = min(instructionsSelectedRange.location, instructions.count)
                        instructions.insert(contentsOf: indent, at: instructions.index(instructions.startIndex, offsetBy: loc))
                        instructionsSelectedRange = NSRange(location: loc + indent.count, length: 0)
                    }
                    Text("(Use '→' for indentation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button("Clear") { instructions = "" }
            }
            Section(header: Text("Days of Week")) {
                ForEach(Self.daysOfWeek, id: \.self) { day in
                    Toggle(day, isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { val in
                            if val { selectedDays.append(day) }
                            else { selectedDays.removeAll { $0 == day } }
                        }
                    ))
                }
                Button("Clear Days") { selectedDays.removeAll() }
            }
            Section {
                Button("Save Changes") { saveEdits() }
                    .buttonStyle(.borderedProminent)
                Button("Cancel", role: .destructive) { dismiss() }
            }
        }
        .navigationTitle("Edit Recipe")
        .alert("Edit", isPresented: $showAlert, actions: { Button("OK", role: .cancel) { } }, message: { Text(alertMessage) })
    }
    
    private func isValidImageUrl(_ url: String) -> Bool {
        guard let url = URL(string: url.lowercased()), ["http", "https"].contains(url.scheme) else { return false }
        let validExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        let ext = url.pathExtension
        return validExtensions.contains(ext)
    }

    private func saveEdits() {
        let servingsValue: Int? = Int(servings) ?? recipe.servings
        
        let idValue = recipe.id
        let sourceUrlValue = recipe.sourceURL
        let extendedIngredientsValue = recipe.extendedIngredients?.compactMap { ingredient in
            if let data = try? JSONEncoder().encode(ingredient),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        }
        
        // Determine image and imageType to save based on imageUrl validity
        var imageToSave = recipe.image
        var imageTypeToSave = recipe.imageType
        if isValidImageUrl(imageUrl) {
            imageToSave = imageUrl
            imageTypeToSave = URL(string: imageUrl)?.pathExtension.lowercased()
        }
        
        var dict: [String: Any] = [
            "uuid": recipe.uuid,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "summary": summary.trimmingCharacters(in: .whitespacesAndNewlines),
            "creditsText": creditsText.trimmingCharacters(in: .whitespacesAndNewlines),
            "instructions": instructions.trimmingCharacters(in: .whitespacesAndNewlines),
            "daysOfWeek": selectedDays,
            "cuisines": cuisines.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "ingredients": ingredients.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) },
            // Add other properties as needed
        ]
        if let idValue {
            dict["id"] = idValue
        }
        if let imageToSave {
            dict["image"] = imageToSave
        }
        if let imageTypeToSave {
            dict["imageType"] = imageTypeToSave
        }
        if let sourceUrlValue {
            dict["sourceUrl"] = sourceUrlValue
        }
        if let extendedIngredientsValue, !extendedIngredientsValue.isEmpty {
            dict["extendedIngredients"] = extendedIngredientsValue
        }
        if let servingsValue {
            dict["servings"] = servingsValue
        }
        // Add any additional fields from the original recipe that shouldn't be lost
        let updated = Recipe(from: dict) ?? recipe
        recipeStore.update(updated)
        alertMessage = "Saved changes."
        showAlert = true
        dismiss()
    }
}

struct BindableTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.clear
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if uiView.selectedRange != selectedRange { uiView.selectedRange = selectedRange }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: BindableTextView
        init(_ parent: BindableTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}

#Preview {
    let store = RecipeStore()
    let recipe = store.recipes.first ?? Recipe(from: ["uuid": UUID(), "title": "Sample Recipe"])!
    return NavigationStack {
        RecipeEditorView(recipe: recipe).environment(store)
    }
}
