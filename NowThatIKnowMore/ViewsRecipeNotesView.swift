//
//  RecipeNotesView.swift
//  NowThatIKnowMore
//
//  View for managing recipe notes
//

import SwiftUI
import SwiftData

struct RecipeNotesView: View {
    @Environment(\.modelContext) private var modelContext
    let recipe: RecipeModel
    @State private var showAddNote = false
    @State private var editingNote: RecipeNoteModel?
    
    var sortedNotes: [RecipeNoteModel] {
        let notes = recipe.notes ?? []
        return notes.sorted { note1, note2 in
            // Pinned notes first
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            // Then by creation date (newest first)
            return note1.createdAt > note2.createdAt
        }
    }
    
    var body: some View {
        List {
            if sortedNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Add notes to remember tips, substitutions, or modifications")
                } actions: {
                    Button("Add Note") {
                        showAddNote = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(sortedNotes) { note in
                    NoteRow(note: note)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingNote = note
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                togglePin(note)
                            } label: {
                                Label("Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(note.isPinned ? .orange : .yellow)
                        }
                        .onTapGesture {
                            editingNote = note
                        }
                }
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddNote = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            NoteEditView(recipe: recipe)
        }
        .sheet(item: $editingNote) { note in
            NoteEditView(recipe: recipe, note: note)
        }
    }
    
    private func deleteNote(_ note: RecipeNoteModel) {
        withAnimation {
            modelContext.delete(note)
            recipe.modifiedAt = Date()
            try? modelContext.save()
        }
    }
    
    private func togglePin(_ note: RecipeNoteModel) {
        withAnimation {
            note.isPinned.toggle()
            note.modifiedAt = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: RecipeNoteModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with pin and date
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if note.createdAt != note.modifiedAt {
                    Text("Edited")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Content
            Text(note.content)
                .font(.body)
                .lineLimit(5)
            
            // Tags
            if !note.tagsList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(note.tagsList, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}

// MARK: - Note Edit View

struct NoteEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let recipe: RecipeModel
    let note: RecipeNoteModel?
    
    @State private var content: String
    @State private var isPinned: Bool
    @State private var tags: [String]
    @State private var newTag: String = ""
    @FocusState private var isContentFocused: Bool
    
    init(recipe: RecipeModel, note: RecipeNoteModel? = nil) {
        self.recipe = recipe
        self.note = note
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _tags = State(initialValue: note?.tagsList ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                        .focused($isContentFocused)
                    
                    Toggle("Pin Note", isOn: $isPinned)
                } header: {
                    Text("Note Content")
                } footer: {
                    Text("Pinned notes appear at the top of your notes list")
                }
                
                Section("Tags") {
                    // Existing tags
                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    removeTag(tag)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("#\(tag)")
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Add new tag
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
                
                Section {
                    // Quick tag suggestions
                    FlowLayout(spacing: 8) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button {
                                addSuggestedTag(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Suggested Tags")
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isContentFocused = false
                        }
                    }
                }
            }
            .onAppear {
                // Auto-focus on content when creating new note
                if note == nil {
                    isContentFocused = true
                }
            }
        }
    }
    
    private var suggestedTags: [String] {
        let allTags = ["tip", "substitution", "modification", "pairing", "timing", "serving"]
        return allTags.filter { !tags.contains($0) }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        
        tags.append(trimmedTag)
        newTag = ""
    }
    
    private func addSuggestedTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveNote() {
        if let note = note {
            // Update existing note
            note.content = content
            note.isPinned = isPinned
            note.tagsList = tags
            note.modifiedAt = Date()
        } else {
            // Create new note
            let newNote = RecipeNoteModel(
                content: content,
                isPinned: isPinned,
                tags: tags,
                recipe: recipe
            )
            modelContext.insert(newNote)
        }
        
        recipe.modifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    let container = try! ModelContainer.preview()
    let context = container.mainContext
    
    let recipe = RecipeModel(
        title: "Sample Recipe",
        servings: 4,
        vegetarian: true
    )
    context.insert(recipe)
    
    let note1 = RecipeNoteModel(
        content: "This recipe tastes amazing with a side of garlic bread!",
        isPinned: true,
        tags: ["tip", "pairing"],
        recipe: recipe
    )
    context.insert(note1)
    
    let note2 = RecipeNoteModel(
        content: "Can substitute almond milk for regular milk",
        isPinned: false,
        tags: ["substitution"],
        recipe: recipe
    )
    context.insert(note2)
    
    return NavigationStack {
        RecipeNotesView(recipe: recipe)
    }
    .modelContainer(container)
}
