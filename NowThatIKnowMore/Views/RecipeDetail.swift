// MARK: - Identifiable conformance for AnalyzedInstruction and Step
import Foundation
import PhotosUI
import EventKit
import EventKitUI
import SafariServices
import UIKit
import Contacts
import ContactsUI

extension AnalyzedInstruction: Identifiable {
    var id: String { name ?? UUID().uuidString }
}
extension Step: Identifiable {
    var id: Int { number ?? Int.random(in: 1...10_000_000) }
}

//
//  RecipeDetail.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 8/27/25.
//

import SwiftUI

struct RecipeDetail: View {
    @Environment(RecipeStore.self) private var recipeStore

    let recipeID: UUID
    
    private var recipe: Recipe? {
        recipeStore.recipe(with: recipeID)
    }
    
    @State private var showExtrasPanel: Bool = false
    @State private var showingSafari = false
    @State private var showShareSheet = false
    
    @State private var selectedContacts: [CNContact] = []
    @State private var showingContactPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhotos: [UIImage] = []

    var body: some View {
        Group {
            if let recipe = recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        recipeDetailContent(for: recipe)
                    }
                    .padding(.horizontal)
                    .onChange(of: selectedPhotoItems) { _, newItems in
                        selectedPhotos.removeAll()
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        selectedPhotos.append(image)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Recipe not found.")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .padding()
            }
        }
        .sheet(isPresented: $showExtrasPanel) {
            if let recipe = recipe {
                ExtraRecipeDetailsPanel(recipe: recipe)
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let sourceUrlString = recipe?.sourceURL,
               let url = URL(string: sourceUrlString) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let recipe = recipe,
               let sourceUrlString = recipe.sourceURL,
               let url = URL(string: sourceUrlString),
               let title = recipe.title {
                let activityItems: [Any] = [
                    RecipeShareProvider(title: title, url: url, image: thumbnailImageFromImageURL(recipe.image))
                ] + selectedContacts.compactMap { $0.vCardData } + selectedPhotos
                ShareSheet(activityItems: activityItems)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView { contacts in
                selectedContacts = contacts
                showingContactPicker = false
            }
        }
    }
    
    @ViewBuilder
    private func recipeDetailContent(for recipe: Recipe) -> some View {
        Text(recipe.title ?? "")
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
        
        if let creditsText = recipe.creditsText, !creditsText.isEmpty {
            Text(creditsText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        if let imageUrlString = recipe.image, !imageUrlString.isEmpty {
            if let url = URL(string: imageUrlString) {
                if url.scheme == "file" {
                    if let data = try? Data(contentsOf: url), let fileImage = UIImage(data: data) {
                        Image(uiImage: fileImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                } else if url.scheme == "http" || url.scheme == "https" {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        case .failure(_):
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }

        if let summary = recipe.summary, !summary.isEmpty {
            Text(cleanSummary(summary))
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        
        Button(action: { showExtrasPanel = true }) {
            Label("More Info", systemImage: "info.circle")
        }
        .padding(.vertical, 4)

        // --- Added Info Section ---
        VStack(alignment: .leading, spacing: 6) {
            Text("Info")
                .font(.headline)
            
            Group {
                if let readyInMinutes = intValue(from: recipe.readyInMinutes), readyInMinutes > 0 {
                    Label("\(readyInMinutes) min", systemImage: "clock")
                }
                if let cookingMinutes = intValue(from: recipe.cookingMinutes), cookingMinutes > 0 {
                    Label("\(cookingMinutes) min Cooking", systemImage: "flame")
                }
                if let preparationMinutes = intValue(from: recipe.preparationMinutes), preparationMinutes > 0 {
                    Label("\(preparationMinutes) min Prep", systemImage: "hourglass")
                }
                if let servings = intValue(from: recipe.servings), servings > 0 {
                    Label("Serves \(servings)", systemImage: "person.2")
                }
                if let aggregateLikes = intValue(from: recipe.aggregateLikes), aggregateLikes > 0 {
                    Label("\(aggregateLikes) Likes", systemImage: "hand.thumbsup")
                }
                if let healthScore = intValue(from: recipe.healthScore), healthScore > 0 {
                    Label("Health Score: \(healthScore)", systemImage: "heart")
                }
                if let spoonacularScore = intValue(from: recipe.spoonacularScore), spoonacularScore > 0 {
                    Label("Spoonacular Score: \(spoonacularScore)", systemImage: "star")
                }
                if let sourceUrl = recipe.sourceURL, !sourceUrl.isEmpty {
                    Label(sourceUrl, systemImage: "link")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if let cuisines = recipe.cuisines, !cuisines.isEmpty {
                    Label(cuisines.map { formatJSONAny($0) }.joined(separator: ", "), systemImage: "fork.knife")
                }
                if let dishTypes = recipe.dishTypes, !dishTypes.isEmpty {
                    Label(dishTypes.map { formatJSONAny($0) }.joined(separator: ", "), systemImage: "tag")
                }
                if let diets = recipe.diets, !diets.isEmpty {
                    Label(diets.map { formatJSONAny($0) }.joined(separator: ", "), systemImage: "leaf")
                }
                if let occasions = recipe.occasions, !occasions.isEmpty {
                    Label(occasions.map { formatJSONAny($0) }.joined(separator: ", "), systemImage: "calendar")
                }
            }
            .font(.subheadline)
        }
        // --- End Info Section ---
        
        if let sourceUrlString = recipe.sourceURL,
           let url = URL(string: sourceUrlString),
           url.scheme?.hasPrefix("http") == true {
            Button("View in Browser") {
                showingSafari = true
            }
            .buttonStyle(.bordered)
            .padding(.vertical, 4)

            Button("Share") {
                showShareSheet = true
            }
            .buttonStyle(.bordered)
            .padding(.vertical, 4)
            
            Button("Add Contacts") {
                showingContactPicker = true
            }
            .buttonStyle(.bordered)
            .padding(.vertical, 4)
            
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 4,
                matching: .images,
                photoLibrary: .shared()) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
            }
            .padding(.vertical, 4)
        }
        
        IngredientListView(ingredients: recipe.extendedIngredients ?? [])
        
        InstructionListView(instructions: recipe.analyzedInstructions)
        
        Spacer()
    }
    
    private func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }
    
    private func formatJSONAny(_ value: Any) -> String {
        // Try to unwrap JSONAny recursively if possible:
        // Assuming JSONAny has a property 'value' that holds the wrapped value.
        // We use Mirror to reflect and unwrap.
        var currentValue: Any = value
        while true {
            let mirror = Mirror(reflecting: currentValue)
            if mirror.displayStyle == .class || mirror.displayStyle == .struct {
                if let child = mirror.children.first(where: { $0.label == "value" }) {
                    currentValue = child.value
                    continue
                }
            }
            break
        }
        
        // Now format based on the type of currentValue
        if currentValue is NSNull {
            return "—"
        }
        if let string = currentValue as? String {
            return string
        }
        if let int = currentValue as? Int {
            return String(int)
        }
        if let double = currentValue as? Double {
            return String(double)
        }
        if let bool = currentValue as? Bool {
            return bool ? "true" : "false"
        }
        if let array = currentValue as? [Any] {
            return array.map { formatJSONAny($0) }.joined(separator: ", ")
        }
        if let dict = currentValue as? [String: Any] {
            let formattedItems = dict.map { key, val in
                "\(key): \(formatJSONAny(val))"
            }.sorted()
            return formattedItems.joined(separator: ", ")
        }
        
        // fallback
        return String(describing: currentValue)
    }
    
    private func thumbnailImageFromImageURL(_ imageUrlString: String?) -> UIImage? {
        guard let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) else {
            return nil
        }
        if url.scheme == "file" {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return image
            }
            return nil
        } else if url.scheme == "http" || url.scheme == "https" {
            // Attempt to synchronously fetch image data (not recommended for production)
            // but per instructions, do synchronously if possible.
            let semaphore = DispatchSemaphore(value: 0)
            var fetchedImage: UIImage? = nil
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    fetchedImage = image
                }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + 3) // wait max 3 seconds
            return fetchedImage
        }
        return nil
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private class RecipeShareProvider: NSObject, UIActivityItemSource {
    let title: String
    let url: URL
    let image: UIImage?
    
    init(title: String, url: URL, image: UIImage?) {
        self.title = title
        self.url = url
        self.image = image
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "[\(title)]"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.url"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, messageForActivityType activityType: UIActivity.ActivityType?) -> String? {
        return "Shared by Asterisk"
    }
}

private struct IngredientListView: View {
    let ingredients: [ExtendedIngredient]
    
    @State private var showReminderPicker = false
    @State private var selectedIndices: Set<Int> = []
    @State private var reminderMessage: String?
    @State private var isAddingReminders = false
    
    // Added properties for reminder lists and selection
    @State private var availableReminderLists: [EKCalendar] = []
    @State private var selectedList: EKCalendar?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(ingredients, id: \.id) { ingredient in
                Text("• \(ingredient.original ?? "")")
                    .font(.body)
            }
            
            Button("Add Ingredients to Reminders") {
                reminderMessage = nil
                selectedIndices = []
                showReminderPicker = true
            }
            .padding(.top, 8)
            .buttonStyle(.bordered)
            
            if let msg = reminderMessage {
                Text(msg)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            NavigationView {
                List {
                    // Picker for reminder list selection
                    if !availableReminderLists.isEmpty {
                        Picker("Reminder List", selection: $selectedList) {
                            ForEach(availableReminderLists, id: \.calendarIdentifier) { calendar in
                                Text(calendar.title).tag(calendar as EKCalendar?)
                            }
                        }
                    }
                    
                    ForEach(ingredients.indices, id: \.self) { i in
                        Toggle(isOn: Binding(
                            get: { selectedIndices.contains(i) },
                            set: { val in
                                if val {
                                    selectedIndices.insert(i)
                                } else {
                                    selectedIndices.remove(i)
                                }
                            }
                        )) {
                            Text(ingredients[i].original ?? "")
                        }
                    }
                }
                .navigationTitle("Select Ingredients")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            isAddingReminders = true
                            addIngredientsToReminders()
                        }
                        .disabled(selectedIndices.isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showReminderPicker = false
                        }
                    }
                }
                if let msg = reminderMessage {
                    Text(msg)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .onAppear {
                let status = EKEventStore.authorizationStatus(for: .reminder)
                print("[DEBUG] Reminders authorization status (onAppear): \(status.rawValue)")
                let store = EKEventStore()
                store.requestFullAccessToReminders { granted, error in
                    print("[DEBUG] requestFullAccessToReminders (onAppear): granted=\(granted), error=\(error?.localizedDescription ?? "none")")
                    DispatchQueue.main.async {
                        if granted {
                            let calendars = store.calendars(for: .reminder)
                            self.availableReminderLists = calendars
                            self.selectedList = calendars.first(where: { $0.calendarIdentifier == store.defaultCalendarForNewReminders()?.calendarIdentifier }) ?? calendars.first
                        } else {
                            self.reminderMessage = "Access to Reminders not granted."
                        }
                    }
                }
            }
        }
    }
    
    private func addIngredientsToReminders() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        print("[DEBUG] Reminders authorization status (add): \(status.rawValue)")
        let store = EKEventStore()
        store.requestFullAccessToReminders { granted, error in
            print("[DEBUG] requestFullAccessToReminders (add): granted=\(granted), error=\(error?.localizedDescription ?? "none")")
            DispatchQueue.main.async {
                isAddingReminders = false
                if let error = error {
                    reminderMessage = "Error: \(error.localizedDescription)"
                    return
                }
                guard granted else {
                    reminderMessage = "Access to Reminders not granted."
                    return
                }
                guard let calendar = selectedList else {
                    reminderMessage = "No reminder list selected."
                    return
                }
                let selected = selectedIndices.sorted().compactMap { idx in ingredients[safe: idx]?.original }
                if selected.isEmpty {
                    reminderMessage = "No ingredients selected."
                    return
                }
                for ingredient in selected where !ingredient.isEmpty {
                    let reminder = EKReminder(eventStore: store)
                    reminder.title = ingredient
                    reminder.calendar = calendar
                    do {
                        try store.save(reminder, commit: false)
                    } catch {
                        reminderMessage = "Failed to save reminder: \(error.localizedDescription)"
                        return
                    }
                }
                do {
                    try store.commit()
                    reminderMessage = "Added \(selected.count) reminders to \(selectedList?.title ?? "list")."
                    showReminderPicker = false
                } catch {
                    reminderMessage = "Failed to commit reminders: \(error.localizedDescription)"
                }
            }
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

private struct InstructionListView: View {
    let instructions: [AnalyzedInstruction]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let instructions = instructions, !instructions.isEmpty {
                Text("Instructions")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(instructions) { instruction in
                    ForEach(instruction.steps ?? []) { step in
                        let stepText = step.step ?? ""
                        Text((step.number?.description ?? "0") + ". " + stepText)
                            .font(.body)
                    }
                }
            }
        }
    }
}

private struct ExtraRecipeDetailsPanel: View {
    let recipe: Recipe
    
    @Environment(\.dismiss) private var dismiss
    
    private func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            List {
                if let readyInMinutes = intValue(from: recipe.readyInMinutes), readyInMinutes > 0 {
                    FieldView(label: "Ready In Minutes", value: "\(readyInMinutes)")
                }
                if let servings = intValue(from: recipe.servings), servings > 0 {
                    FieldView(label: "Servings", value: "\(servings)")
                }
                if let aggregateLikes = intValue(from: recipe.aggregateLikes), aggregateLikes > 0 {
                    FieldView(label: "Likes", value: "\(aggregateLikes)")
                }
                if let healthScore = intValue(from: recipe.healthScore), healthScore > 0 {
                    FieldView(label: "Health Score", value: "\(healthScore)")
                }
                if let spoonacularScore = intValue(from: recipe.spoonacularScore), spoonacularScore > 0 {
                    FieldView(label: "Spoonacular Score", value: "\(spoonacularScore)")
                }
                if let sourceUrl = recipe.sourceURL, !sourceUrl.isEmpty {
                    FieldView(label: "Source URL", value: sourceUrl)
                }
                if let cuisines = recipe.cuisines, !cuisines.isEmpty {
                    FieldView(label: "Cuisines", value: cuisines.map { formatJSONAny($0) }.joined(separator: ", "))
                }
                if let dishTypes = recipe.dishTypes, !dishTypes.isEmpty {
                    FieldView(label: "Dish Types", value: dishTypes.map { formatJSONAny($0) }.joined(separator: ", "))
                }
                if let diets = recipe.diets, !diets.isEmpty {
                    FieldView(label: "Diets", value: diets.map { formatJSONAny($0) }.joined(separator: ", "))
                }
                if let occasions = recipe.occasions, !occasions.isEmpty {
                    FieldView(label: "Occasions", value: occasions.map { formatJSONAny($0) }.joined(separator: ", "))
                }
            }
            .navigationTitle("More Recipe Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private struct FieldView: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.headline)
                Text(value).font(.body)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatJSONAny(_ value: Any) -> String {
        // Try to unwrap JSONAny recursively if possible:
        // Assuming JSONAny has a property 'value' that holds the wrapped value.
        // We use Mirror to reflect and unwrap.
        var currentValue: Any = value
        while true {
            let mirror = Mirror(reflecting: currentValue)
            if mirror.displayStyle == .class || mirror.displayStyle == .struct {
                if let child = mirror.children.first(where: { $0.label == "value" }) {
                    currentValue = child.value
                    continue
                }
            }
            break
        }
        
        // Now format based on the type of currentValue
        if currentValue is NSNull {
            return "—"
        }
        if let string = currentValue as? String {
            return string
        }
        if let int = currentValue as? Int {
            return String(int)
        }
        if let double = currentValue as? Double {
            return String(double)
        }
        if let bool = currentValue as? Bool {
            return bool ? "true" : "false"
        }
        if let array = currentValue as? [Any] {
            return array.map { formatJSONAny($0) }.joined(separator: ", ")
        }
        if let dict = currentValue as? [String: Any] {
            let formattedItems = dict.map { key, val in
                "\(key): \(formatJSONAny(val))"
            }.sorted()
            return formattedItems.joined(separator: ", ")
        }
        
        // fallback
        return String(describing: currentValue)
    }
}

private func cleanSummary(_ html: String) -> String {
    var text = html.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
    text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "<ul>|</ul>", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "<b>(.*?)</b>", with: "**$1**", options: .regularExpression)
    text = text.replacingOccurrences(of: "<i>(.*?)</i>", with: "*$1*", options: .regularExpression)
    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
    return lines.filter { !$0.isEmpty }.map { $0 + "\n" }.joined()
}

extension CNContact {
    var vCardData: Data? {
        try? CNContactVCardSerialization.data(with: [self])
    }
}

private struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: ([CNContact]) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForSelectionOfProperty = nil
        picker.predicateForEnablingContact = nil
        return picker
    }
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: ([CNContact]) -> Void
        init(onSelect: @escaping ([CNContact]) -> Void) { self.onSelect = onSelect }
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) { onSelect(contacts) }
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) { onSelect([]) }
    }
}

#Preview {
    let store = RecipeStore()
    let recipe = store.recipes.first ?? Recipe(from: [
        "uuid": UUID(),
        "title": "Sample Recipe",
        "summary": "A preview recipe.",
        "creditsText": "Preview Chef"
    ])!
    if store.recipes.isEmpty { store.add(recipe) }
    return RecipeDetail(recipeID: recipe.uuid)
        .environment(store)
}

