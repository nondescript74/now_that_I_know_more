// MARK: - Identifiable conformance for AnalyzedInstruction and Step
import Foundation
import PhotosUI
import EventKit
import EventKitUI
import SafariServices
import UIKit
import Contacts
import ContactsUI
import MessageUI
import SwiftData

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
import SwiftData

struct RecipeDetail: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecipes: [RecipeModel]
    
    let recipeID: UUID
    
    private var recipe: RecipeModel? {
        allRecipes.first(where: { $0.uuid == recipeID })
    }
    
    @State private var editedTitle: String = ""
    @State private var editedSummary: String = ""
    @State private var editedCreditsText: String = ""
    @State private var didSetupFields = false
    @State private var saveMessage: String?
    @State private var showExtrasPanel: Bool = false
    @State private var showingSafari = false
    @State private var showShareSheet = false
    @State private var showingEmailComposer = false
    @State private var showingMailNotAvailableAlert = false
    
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
                    .onAppear {
                        if !didSetupFields {
                            editedTitle = recipe.title ?? ""
                            editedSummary = cleanSummary(recipe.summary ?? "")
                            editedCreditsText = recipe.creditsText ?? ""
                            didSetupFields = true
                        }
                    }
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
                    RecipeShareProvider(title: title, url: url, image: thumbnailImageFromImageURL(recipe.featuredMediaURL))
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
        .sheet(isPresented: $showingEmailComposer) {
            if let recipe = recipe {
                MailComposeView(recipe: recipe)
            }
        }
        .alert("Mail Not Available", isPresented: $showingMailNotAvailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Mail services are not available. Please configure Mail on your device to send email.")
        }
    }
    
    @ViewBuilder
    private func recipeDetailContent(for recipe: RecipeModel) -> some View {
        TextField("Title", text: $editedTitle)
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
            .textFieldStyle(.roundedBorder)
        
        TextField("Credits", text: $editedCreditsText)
            .textFieldStyle(.roundedBorder)
        
        // Display featured media or fall back to legacy image field
        if let featuredURL = recipe.featuredMediaURL, !featuredURL.isEmpty {
            let url = URL(string: featuredURL) ?? URL(filePath: featuredURL)
            if url.scheme == "http" || url.scheme == "https" {
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
            } else if url.scheme == "file" || url.pathComponents.first == "/" {
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
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }

        TextEditor(text: $editedSummary)
            .frame(minHeight: 60, maxHeight: 120)
            .font(.body)
            .foregroundColor(.secondary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            .padding(.bottom, 4)
        
        if !editedSummary.isEmpty && cleanSummary(editedSummary) != editedSummary {
            Text(cleanSummary(editedSummary))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }

        if (editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.title ?? "")
            || editedSummary.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.summary ?? "")
            || editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.creditsText ?? "")) {
            Button("Save Changes") {
                saveEdits()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 8)
            .disabled(
                (editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.title ?? "")) &&
                (editedSummary.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.summary ?? "")) &&
                (editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines) == (recipe.creditsText ?? ""))
            )
        }
        if let msg = saveMessage {
            Text(msg).foregroundColor(.accentColor)
        }
        
        Button(action: { showExtrasPanel = true }) {
            Label("More Info", systemImage: "info.circle")
        }
        .padding(.vertical, 4)

        NavigationLink(destination: RecipeEditorView(recipe: recipe)) {
            Label("Edit Recipe", systemImage: "pencil")
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 4)

        // --- Added Info Section ---
        VStack(alignment: .leading, spacing: 6) {
            Text("Info")
                .font(.headline)
            
            Group {
                if let readyInMinutes = recipe.readyInMinutes, readyInMinutes > 0 {
                    Label("\(readyInMinutes) min", systemImage: "clock")
                }
                if let cookingMinutes = recipe.cookingMinutes, cookingMinutes > 0 {
                    Label("\(cookingMinutes) min Cooking", systemImage: "flame")
                }
                if let preparationMinutes = recipe.preparationMinutes, preparationMinutes > 0 {
                    Label("\(preparationMinutes) min Prep", systemImage: "hourglass")
                }
                if let servings = recipe.servings, servings > 0 {
                    Label("Serves \(servings)", systemImage: "person.2")
                }
                if let aggregateLikes = recipe.aggregateLikes, aggregateLikes > 0 {
                    Label("\(aggregateLikes) Likes", systemImage: "hand.thumbsup")
                }
                if let healthScore = recipe.healthScore, healthScore > 0 {
                    Label("Health Score: \(healthScore)", systemImage: "heart")
                }
                if let spoonacularScore = recipe.spoonacularScore, spoonacularScore > 0 {
                    Label("Spoonacular Score: \(spoonacularScore)", systemImage: "star")
                }
                if let sourceUrl = recipe.sourceURL, !sourceUrl.isEmpty {
                    Label(sourceUrl, systemImage: "link")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if !recipe.cuisines.isEmpty {
                    Label(recipe.cuisines.joined(separator: ", "), systemImage: "fork.knife")
                }
                if !recipe.dishTypes.isEmpty {
                    Label(recipe.dishTypes.joined(separator: ", "), systemImage: "tag")
                }
                if !recipe.diets.isEmpty {
                    Label(recipe.diets.joined(separator: ", "), systemImage: "leaf")
                }
                if !recipe.occasions.isEmpty {
                    Label(recipe.occasions.joined(separator: ", "), systemImage: "calendar")
                }
            }
            .font(.subheadline)
        }
        // --- End Info Section ---
        
        Button(action: { showExtrasPanel = true }) {
            Label("More Info", systemImage: "info.circle")
        }
        .padding(.vertical, 4)
        
        Button("Email Recipe") {
            if MFMailComposeViewController.canSendMail() {
                showingEmailComposer = true
            } else {
                showingMailNotAvailableAlert = true
            }
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 4)
        .disabled(!MFMailComposeViewController.canSendMail())

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
        
        InstructionListView(instructions: recipe.analyzedInstructions, plainInstructions: recipe.instructions)
        
        Spacer()
    }
    
    private func saveEdits() {
        guard let currentRecipe = recipe else {
            saveMessage = "Save failed (recipe not found)."
            return
        }
        
        let titleToSave = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryToSave = cleanSummary(editedSummary)
        let creditsToSave = editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update the RecipeModel directly
        currentRecipe.title = titleToSave.isEmpty ? nil : titleToSave
        currentRecipe.summary = summaryToSave.isEmpty ? nil : summaryToSave
        currentRecipe.creditsText = creditsToSave.isEmpty ? nil : creditsToSave
        currentRecipe.modifiedAt = Date()
        
        do {
            try modelContext.save()
            saveMessage = "Saved!"
        } catch {
            saveMessage = "Save failed: \(error.localizedDescription)"
        }
    }
    
    private func thumbnailImageFromImageURL(_ imageUrlString: String?) -> UIImage? {
        guard let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) else {
            return nil
        }
        // Only load file URLs synchronously, as they're local and won't block the UI
        if url.scheme == "file" {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return image
            }
            return nil
        }
        // For HTTP/HTTPS URLs, return nil and let the caller handle async loading
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
                            // Create a new store instance on the main thread
                            let mainStore = EKEventStore()
                            let calendars = mainStore.calendars(for: .reminder)
                            self.availableReminderLists = calendars
                            self.selectedList = calendars.first(where: { $0.calendarIdentifier == mainStore.defaultCalendarForNewReminders()?.calendarIdentifier }) ?? calendars.first
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
                if let error = error {
                    self.reminderMessage = "Error: \(error.localizedDescription)"
                    return
                }
                guard granted else {
                    self.reminderMessage = "Access to Reminders not granted."
                    return
                }
                guard let calendar = self.selectedList else {
                    self.reminderMessage = "No reminder list selected."
                    return
                }
                let selected = self.selectedIndices.sorted().compactMap { idx in self.ingredients[safe: idx]?.original }
                if selected.isEmpty {
                    self.reminderMessage = "No ingredients selected."
                    return
                }
                // Create a new store instance on the main thread to avoid Sendable issues
                let mainStore = EKEventStore()
                for ingredient in selected where !ingredient.isEmpty {
                    let reminder = EKReminder(eventStore: mainStore)
                    reminder.title = ingredient
                    reminder.calendar = calendar
                    do {
                        try mainStore.save(reminder, commit: false)
                    } catch {
                        self.reminderMessage = "Failed to save reminder: \(error.localizedDescription)"
                        return
                    }
                }
                do {
                    try mainStore.commit()
                    self.reminderMessage = "Added \(selected.count) reminders to \(self.selectedList?.title ?? "list")."
                    self.showReminderPicker = false
                } catch {
                    self.reminderMessage = "Failed to commit reminders: \(error.localizedDescription)"
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
    let plainInstructions: String?
    
    init(instructions: [AnalyzedInstruction]?, plainInstructions: String? = nil) {
        self.instructions = instructions
        self.plainInstructions = plainInstructions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // First, try to display structured instructions
            if let instructions = instructions, !instructions.isEmpty {
                Text("Instructions")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(instructions) { instruction in
                    if let name = instruction.name, !name.isEmpty {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 4)
                    }
                    ForEach(instruction.steps ?? []) { step in
                        let stepText = step.step ?? ""
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(step.number ?? 0).")
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text(stepText)
                                .font(.body)
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
            // Fallback to plain text instructions (from OCR parsing)
            else if let plainText = plainInstructions, !plainText.isEmpty {
                Text("Instructions")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Split text to detect and highlight "Variations:" section
                let lines = plainText.components(separatedBy: .newlines)
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.lowercased().hasPrefix("variations:") || trimmedLine.lowercased().hasPrefix("variation:") {
                        // Highlight variation header
                        Text(trimmedLine)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                    } else if !trimmedLine.isEmpty {
                        Text(trimmedLine)
                            .font(.body)
                            .padding(.leading, isVariationItem(trimmedLine) ? 8 : 0)
                    }
                }
            }
        }
    }
    
    /// Determines if a line is a variation item (typically starts with a number)
    private func isVariationItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Check if line starts with number followed by period or parenthesis
        if let firstChar = trimmed.first, firstChar.isNumber {
            if trimmed.count > 1 {
                let secondChar = trimmed[trimmed.index(after: trimmed.startIndex)]
                return secondChar == "." || secondChar == ")" || secondChar == ":"
            }
        }
        return false
    }
}

private struct ExtraRecipeDetailsPanel: View {
    let recipe: RecipeModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let readyInMinutes = recipe.readyInMinutes, readyInMinutes > 0 {
                    FieldView(label: "Ready In Minutes", value: "\(readyInMinutes)")
                }
                if let servings = recipe.servings, servings > 0 {
                    FieldView(label: "Servings", value: "\(servings)")
                }
                if let aggregateLikes = recipe.aggregateLikes, aggregateLikes > 0 {
                    FieldView(label: "Likes", value: "\(aggregateLikes)")
                }
                if let healthScore = recipe.healthScore, healthScore > 0 {
                    FieldView(label: "Health Score", value: "\(healthScore)")
                }
                if let spoonacularScore = recipe.spoonacularScore, spoonacularScore > 0 {
                    FieldView(label: "Spoonacular Score", value: "\(spoonacularScore)")
                }
                if let sourceUrl = recipe.sourceURL, !sourceUrl.isEmpty {
                    FieldView(label: "Source URL", value: sourceUrl)
                }
                if !recipe.cuisines.isEmpty {
                    FieldView(label: "Cuisines", value: recipe.cuisines.joined(separator: ", "))
                }
                if !recipe.dishTypes.isEmpty {
                    FieldView(label: "Dish Types", value: recipe.dishTypes.joined(separator: ", "))
                }
                if !recipe.diets.isEmpty {
                    FieldView(label: "Diets", value: recipe.diets.joined(separator: ", "))
                }
                if !recipe.occasions.isEmpty {
                    FieldView(label: "Occasions", value: recipe.occasions.joined(separator: ", "))
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

// MARK: - Mail Compose View
private struct MailComposeView: UIViewControllerRepresentable {
    let recipe: RecipeModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        
        // Export recipe as JSON (using legacy format for compatibility)
        let recipeData = exportRecipeAsJSON(recipe)
        
        composer.setSubject("Recipe: \(recipe.title ?? "Untitled Recipe")")
        composer.setMessageBody(createEmailBody(recipe), isHTML: true)
        
        if let data = recipeData {
            composer.addAttachmentData(data, mimeType: "application/json", fileName: "\(recipe.title?.sanitizedForFileName ?? "recipe").recipe")
        }
        
        // Attach user photos if any
        if let mediaItems = recipe.mediaItems {
            for (index, mediaItem) in mediaItems.prefix(3).enumerated() {
                if mediaItem.type == .photo, let data = try? Data(contentsOf: URL(fileURLWithPath: mediaItem.fileURL)) {
                    composer.addAttachmentData(data, mimeType: "image/jpeg", fileName: "photo_\(index).jpg")
                }
            }
        }
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let dismissAction = dismiss
            Task { @MainActor in
                dismissAction()
            }
        }
    }
    
    private func exportRecipeAsJSON(_ recipe: RecipeModel) -> Data? {
        // Export RecipeModel directly as JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(recipe)
    }
    
    private func createEmailBody(_ recipe: RecipeModel) -> String {
        var html = """
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
                h1 { color: #333; }
                h2 { color: #666; margin-top: 20px; }
                .info { background-color: #f5f5f5; padding: 10px; border-radius: 5px; }
                .ingredient { margin: 5px 0; }
                .step { margin: 10px 0; }
            </style>
        </head>
        <body>
            <h1>\(recipe.title ?? "Recipe")</h1>
        """
        
        if let credits = recipe.creditsText, !credits.isEmpty {
            html += "<p><em>\(credits)</em></p>"
        }
        
        if let summary = recipe.summary, !summary.isEmpty {
            html += "<p>\(cleanSummary(summary))</p>"
        }
        
        html += "<div class='info'>"
        if let servings = recipe.servings {
            html += "<p><strong>Servings:</strong> \(servings)</p>"
        }
        if let readyInMinutes = recipe.readyInMinutes {
            html += "<p><strong>Ready in:</strong> \(readyInMinutes) minutes</p>"
        }
        html += "</div>"
        
        if let ingredients = recipe.extendedIngredients, !ingredients.isEmpty {
            html += "<h2>Ingredients</h2><ul>"
            for ingredient in ingredients {
                if let original = ingredient.original {
                    html += "<li class='ingredient'>\(original)</li>"
                }
            }
            html += "</ul>"
        }
        
        if let instructions = recipe.analyzedInstructions, !instructions.isEmpty {
            html += "<h2>Instructions</h2>"
            for instruction in instructions {
                if let steps = instruction.steps {
                    html += "<ol>"
                    for step in steps {
                        if let stepText = step.step {
                            html += "<li class='step'>\(stepText)</li>"
                        }
                    }
                    html += "</ol>"
                }
            }
        }
        
        html += """
            <hr>
            <p><small>This recipe was shared from the NowThatIKnowMore app. To import this recipe, open the attached .recipe file in the app.</small></p>
        </body>
        </html>
        """
        
        return html
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    let sampleRecipe = RecipeModel(
        title: "Sample Recipe",
        creditsText: "Preview Chef",
        summary: "A preview recipe."
    )
    container.mainContext.insert(sampleRecipe)
    
    return RecipeDetail(recipeID: sampleRecipe.uuid)
        .modelContainer(container)
}

