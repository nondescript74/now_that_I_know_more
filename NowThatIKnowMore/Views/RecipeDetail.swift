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
                            editedSummary = recipe.summary ?? ""
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
        // MARK: - Title & Credits Section
        VStack(alignment: .leading, spacing: 12) {
            TextField("Recipe Title", text: $editedTitle)
                .font(.title)
                .fontWeight(.bold)
                .textFieldStyle(.roundedBorder)
            
            TextField("Credits (optional)", text: $editedCreditsText)
                .font(.subheadline)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.top)
        
        // MARK: - Featured Image
        if let featuredURL = recipe.featuredMediaURL, !featuredURL.isEmpty {
            // Check if it's a remote URL (http/https)
            if featuredURL.hasPrefix("http://") || featuredURL.hasPrefix("https://") {
                if let url = URL(string: featuredURL) {
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
                            placeholderImage
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            } 
            // Handle local file paths
            else {
                let fileURL = URL(fileURLWithPath: featuredURL)
                if let data = try? Data(contentsOf: fileURL), let fileImage = UIImage(data: data) {
                    Image(uiImage: fileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                } else {
                    placeholderImage
                }
            }
        }

        // MARK: - Summary Section
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
            
            TextEditor(text: $editedSummary)
                .frame(minHeight: 80, maxHeight: 150)
                .font(.body)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }

        // MARK: - Save Button
        if hasUnsavedChanges(for: recipe) {
            HStack {
                Button("Save Changes") {
                    saveEdits()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    resetFields(for: recipe)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
        }
        
        if let msg = saveMessage {
            Text(msg)
                .foregroundColor(.green)
                .font(.subheadline)
        }

        Divider()
            .padding(.vertical, 8)

        // MARK: - Quick Info Section
        if hasQuickInfo(for: recipe) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Info")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let readyInMinutes = recipe.readyInMinutes, readyInMinutes > 0 {
                        quickInfoItem(icon: "clock", text: "\(readyInMinutes) min")
                    }
                    if let servings = recipe.servings, servings > 0 {
                        quickInfoItem(icon: "person.2", text: "Serves \(servings)")
                    }
                    if let cookingMinutes = recipe.cookingMinutes, cookingMinutes > 0 {
                        quickInfoItem(icon: "flame", text: "\(cookingMinutes) min cook")
                    }
                    if let preparationMinutes = recipe.preparationMinutes, preparationMinutes > 0 {
                        quickInfoItem(icon: "hourglass", text: "\(preparationMinutes) min prep")
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider()
                .padding(.vertical, 8)
        }
        
        // MARK: - Ingredients Section (IMPROVED)
        IngredientListView(ingredients: recipe.extendedIngredients ?? [])
            .padding(.vertical, 8)
        
        Divider()
            .padding(.vertical, 8)
        
        // MARK: - Instructions Section
        InstructionListView(instructions: recipe.analyzedInstructions, plainInstructions: recipe.instructions)
            .padding(.vertical, 8)
        
        Divider()
            .padding(.vertical, 8)
        
        // MARK: - Actions Section
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            
            // Edit Recipe
            NavigationLink(destination: RecipeEditorView(recipe: recipe)) {
                Label("Edit Full Recipe Details", systemImage: "pencil")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            
            // More Info
            Button(action: { showExtrasPanel = true }) {
                Label("View Additional Info", systemImage: "info.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            
            // Email Recipe
            Button(action: {
                if MFMailComposeViewController.canSendMail() {
                    showingEmailComposer = true
                } else {
                    showingMailNotAvailableAlert = true
                }
            }) {
                Label("Email Recipe", systemImage: "envelope")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .disabled(!MFMailComposeViewController.canSendMail())

            // Browser and sharing options (only if valid URL exists)
            if let sourceUrlString = recipe.sourceURL,
               let url = URL(string: sourceUrlString),
               url.scheme?.hasPrefix("http") == true {
                
                Button(action: { showingSafari = true }) {
                    Label("View in Browser", systemImage: "safari")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)

                Button(action: { showShareSheet = true }) {
                    Label("Share Recipe", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingContactPicker = true }) {
                    Label("Add Contacts for Sharing", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 4,
                    matching: .images,
                    photoLibrary: .shared()) {
                    Label("Add Photos for Sharing", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
        
        Spacer()
    }
    
    // MARK: - Helper Views
    
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
    
    private func quickInfoItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func hasUnsavedChanges(for recipe: RecipeModel) -> Bool {
        return editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.title ?? "") ||
               editedSummary.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.summary ?? "") ||
               editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines) != (recipe.creditsText ?? "")
    }
    
    private func resetFields(for recipe: RecipeModel) {
        editedTitle = recipe.title ?? ""
        editedSummary = recipe.summary ?? ""
        editedCreditsText = recipe.creditsText ?? ""
        saveMessage = nil
    }
    
    private func hasQuickInfo(for recipe: RecipeModel) -> Bool {
        return recipe.readyInMinutes ?? 0 > 0 ||
               recipe.servings ?? 0 > 0 ||
               recipe.cookingMinutes ?? 0 > 0 ||
               recipe.preparationMinutes ?? 0 > 0
    }
    
    private func saveEdits() {
        guard let currentRecipe = recipe else {
            saveMessage = "Save failed (recipe not found)."
            return
        }
        
        let titleToSave = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryToSave = editedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let creditsToSave = editedCreditsText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update the RecipeModel directly
        currentRecipe.title = titleToSave.isEmpty ? nil : titleToSave
        currentRecipe.summary = summaryToSave.isEmpty ? nil : summaryToSave
        currentRecipe.creditsText = creditsToSave.isEmpty ? nil : creditsToSave
        currentRecipe.modifiedAt = Date()
        
        do {
            try modelContext.save()
            saveMessage = "✓ Changes saved successfully!"
            
            // Clear message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveMessage = nil
            }
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
    
    private var validIngredients: [ExtendedIngredient] {
        ingredients.filter { ($0.original ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                
                if !validIngredients.isEmpty {
                    Spacer()
                    Text("\(validIngredients.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if validIngredients.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No ingredients found")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Use 'Edit Full Recipe Details' to add ingredients.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(validIngredients.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.accentColor)
                                .fontWeight(.bold)
                            Text(validIngredients[index].original ?? "")
                                .font(.body)
                        }
                    }
                }
                
                Button("Add to Reminders") {
                    reminderMessage = nil
                    selectedIndices = []
                    showReminderPicker = true
                }
                .padding(.top, 8)
                .buttonStyle(.bordered)
                
                if let msg = reminderMessage {
                    Text(msg)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 4)
                }
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            NavigationView {
                List {
                    // Picker for reminder list selection
                    if !availableReminderLists.isEmpty {
                        Section("Reminder List") {
                            Picker("List", selection: $selectedList) {
                                ForEach(availableReminderLists, id: \.calendarIdentifier) { calendar in
                                    Text(calendar.title).tag(calendar as EKCalendar?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    Section("Select Ingredients") {
                        ForEach(validIngredients.indices, id: \.self) { i in
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
                                Text(validIngredients[i].original ?? "")
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .navigationTitle("Add to Reminders")
                .navigationBarTitleDisplayMode(.inline)
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
                .safeAreaInset(edge: .bottom) {
                    if let msg = reminderMessage {
                        Text(msg)
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                    }
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
                let selected = self.selectedIndices.sorted().compactMap { idx in self.validIngredients[safe: idx]?.original }
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
                    self.reminderMessage = "✓ Added \(selected.count) ingredient\(selected.count == 1 ? "" : "s") to \(self.selectedList?.title ?? "list")"
                    // Delay dismissal so user can see the success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showReminderPicker = false
                    }
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
    
    private var hasInstructions: Bool {
        if let instructions = instructions, !instructions.isEmpty {
            return true
        }
        if let plainText = plainInstructions, !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            if !hasInstructions {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No instructions found")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Use 'Edit Full Recipe Details' to add instructions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                // First, try to display structured instructions
                if let instructions = instructions, !instructions.isEmpty {
                    ForEach(instructions) { instruction in
                        if let name = instruction.name, !name.isEmpty {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                                .padding(.top, 8)
                        }
                        
                        if let steps = instruction.steps, !steps.isEmpty {
                            ForEach(steps) { step in
                                if let stepText = step.step, !stepText.isEmpty {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(step.number ?? 0).")
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentColor)
                                            .frame(minWidth: 24, alignment: .trailing)
                                        
                                        Text(stepText)
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                // Fallback to plain text instructions (from OCR parsing)
                else if let plainText = plainInstructions, !plainText.isEmpty {
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
                        } else if !trimmedLine.isEmpty {
                            Text(trimmedLine)
                                .font(.body)
                                .padding(.leading, isVariationItem(trimmedLine) ? 12 : 0)
                                .padding(.vertical, 2)
                        }
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
            html += "<p>\(summary)</p>"
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

