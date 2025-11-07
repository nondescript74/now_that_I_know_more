//
//  RecipeBooksView.swift
//  NowThatIKnowMore
//
//  View for managing recipe books
//

import SwiftUI
import SwiftData

struct RecipeBooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeBookModel.sortOrder) private var books: [RecipeBookModel]
    @State private var showAddBook = false
    @State private var editingBook: RecipeBookModel?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(books) { book in
                    NavigationLink {
                        RecipeBookDetailView(book: book)
                    } label: {
                        RecipeBookRow(book: book)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteBook(book)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            editingBook = book
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onMove(perform: moveBooks)
            }
            .navigationTitle("Recipe Books")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddBook = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAddBook) {
                RecipeBookEditView()
            }
            .sheet(item: $editingBook) { book in
                RecipeBookEditView(book: book)
            }
        }
    }
    
    private func deleteBook(_ book: RecipeBookModel) {
        withAnimation {
            modelContext.delete(book)
            try? modelContext.save()
        }
    }
    
    private func moveBooks(from source: IndexSet, to destination: Int) {
        var updatedBooks = books
        updatedBooks.move(fromOffsets: source, toOffset: destination)
        
        // Update sort orders
        for (index, book) in updatedBooks.enumerated() {
            book.sortOrder = index
        }
        
        try? modelContext.save()
    }
}

// MARK: - Recipe Book Row

struct RecipeBookRow: View {
    let book: RecipeBookModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: book.colorHex ?? "#007AFF"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: book.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                
                if let description = book.bookDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text("\(book.recipeCount) recipes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Recipe Book Detail View

struct RecipeBookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let book: RecipeBookModel
    @State private var showAddRecipes = false
    
    var recipes: [RecipeModel] {
        book.recipes?.sorted { $0.modifiedAt > $1.modifiedAt } ?? []
    }
    
    var body: some View {
        List {
            if recipes.isEmpty {
                ContentUnavailableView {
                    Label("No Recipes", systemImage: "book.closed")
                } description: {
                    Text("Add recipes to this book to get started")
                } actions: {
                    Button("Add Recipes") {
                        showAddRecipes = true
                    }
                }
            } else {
                ForEach(recipes) { recipe in
                    NavigationLink {
                        // RecipeDetailView(recipe: recipe)
                        Text("Recipe Detail: \(recipe.title ?? "Untitled")")
                    } label: {
                        RecipeRowView(recipe: recipe)
                    }
                }
                .onDelete(perform: removeRecipes)
            }
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddRecipes = true
                } label: {
                    Label("Add Recipes", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddRecipes) {
            AddRecipesToBookView(book: book)
        }
    }
    
    private func removeRecipes(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let recipe = recipes[index]
                book.recipes?.removeAll { $0.uuid == recipe.uuid }
            }
            book.modifiedAt = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Recipe Row View

struct RecipeRowView: View {
    let recipe: RecipeModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageURL = recipe.featuredMediaURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.gray)
                    }
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let servings = recipe.servings {
                        Label("\(servings)", systemImage: "person.2")
                            .font(.caption)
                    }
                    
                    if let readyIn = recipe.readyInMinutes {
                        Label("\(readyIn) min", systemImage: "clock")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                
                // Dietary tags
                HStack(spacing: 4) {
                    if recipe.vegetarian {
                        DietaryTag(text: "Vegetarian", color: .green)
                    }
                    if recipe.vegan {
                        DietaryTag(text: "Vegan", color: .green)
                    }
                    if recipe.glutenFree {
                        DietaryTag(text: "GF", color: .orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DietaryTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Add Recipes to Book View

struct AddRecipesToBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allRecipes: [RecipeModel]
    let book: RecipeBookModel
    @State private var selectedRecipes: Set<UUID> = []
    
    var recipesNotInBook: [RecipeModel] {
        let bookRecipeIDs = Set(book.recipes?.map { $0.uuid } ?? [])
        return allRecipes.filter { !bookRecipeIDs.contains($0.uuid) }
    }
    
    var body: some View {
        NavigationStack {
            List(recipesNotInBook) { recipe in
                Button {
                    toggleSelection(recipe)
                } label: {
                    HStack {
                        RecipeRowView(recipe: recipe)
                        
                        Spacer()
                        
                        if selectedRecipes.contains(recipe.uuid) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selectedRecipes.count)") {
                        addSelectedRecipes()
                        dismiss()
                    }
                    .disabled(selectedRecipes.isEmpty)
                }
            }
        }
    }
    
    private func toggleSelection(_ recipe: RecipeModel) {
        if selectedRecipes.contains(recipe.uuid) {
            selectedRecipes.remove(recipe.uuid)
        } else {
            selectedRecipes.insert(recipe.uuid)
        }
    }
    
    private func addSelectedRecipes() {
        let recipesToAdd = allRecipes.filter { selectedRecipes.contains($0.uuid) }
        
        if book.recipes == nil {
            book.recipes = []
        }
        
        book.recipes?.append(contentsOf: recipesToAdd)
        book.modifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Recipe Book Edit View

struct RecipeBookEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let book: RecipeBookModel?
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: Color
    @State private var selectedIcon: String
    
    init(book: RecipeBookModel? = nil) {
        self.book = book
        _name = State(initialValue: book?.name ?? "")
        _description = State(initialValue: book?.bookDescription ?? "")
        _selectedColor = State(initialValue: Color(hex: book?.colorHex ?? "#007AFF"))
        _selectedIcon = State(initialValue: book?.iconName ?? "book.closed")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Icon") {
                    IconPicker(selectedIcon: $selectedIcon)
                }
                
                Section("Color") {
                    ColorPicker("Book Color", selection: $selectedColor)
                }
            }
            .navigationTitle(book == nil ? "New Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveBook() {
        if let book = book {
            // Update existing book
            book.name = name
            book.bookDescription = description.isEmpty ? nil : description
            book.colorHex = selectedColor.toHex()
            book.iconName = selectedIcon
            book.modifiedAt = Date()
        } else {
            // Create new book
            let newBook = RecipeBookModel(
                name: name,
                bookDescription: description.isEmpty ? nil : description,
                colorHex: selectedColor.toHex(),
                iconName: selectedIcon,
                sortOrder: 0
            )
            modelContext.insert(newBook)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Icon Picker

struct IconPicker: View {
    @Binding var selectedIcon: String
    
    let icons = [
        "book.closed", "book.closed.fill", "books.vertical", "heart.fill",
        "star.fill", "clock.fill", "leaf.fill", "birthday.cake.fill",
        "flame.fill", "fork.knife", "carrot.fill", "fish.fill"
    ]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0.0
        let g = components?[1] ?? 0.0
        let b = components?[2] ?? 0.0
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}

#Preview {
    RecipeBooksView()
        .modelContainer(try! ModelContainer.preview())
}
