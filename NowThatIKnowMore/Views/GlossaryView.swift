import SwiftUI

// MARK: - Models

struct GlossaryItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let alternateNames: [String]
    let description: String
    
    var displayName: String {
        if alternateNames.isEmpty {
            return name
        } else {
            return "\(name) (\(alternateNames.joined(separator: ", ")))"
        }
    }
    
    func matches(searchText: String) -> Bool {
        let lowercased = searchText.lowercased()
        return name.lowercased().contains(lowercased) ||
               alternateNames.contains(where: { $0.lowercased().contains(lowercased) }) ||
               description.lowercased().contains(lowercased)
    }
}

// MARK: - Glossary Data

extension GlossaryItem {
    static let allItems: [GlossaryItem] = [
        // Page 2 Items (alphabetically first)
        GlossaryItem(
            name: "Agar Agar",
            alternateNames: ["Chinese grass"],
            description: "Agar Agar is a vegetable product and is used for setting liquids without refrigeration."
        ),
        GlossaryItem(
            name: "Burghul",
            alternateNames: ["bulgar"],
            description: "Burghul is crushed wheat sometimes referred to as bulgar. It can be purchased from Lebanese speciality stores."
        ),
        GlossaryItem(
            name: "Cardamom",
            alternateNames: ["elaychi"],
            description: "There are different varieties of cardamom. One with green pods is commonly used. It can be used with or without pods. Freshly ground cardamom with pods is used all through the recipes. Note: cardamom is highly aromatic."
        ),
        GlossaryItem(
            name: "Cassava",
            alternateNames: ["mogo", "Yucca", "tapioca"],
            description: "Mogo is a tropical rootstock. It is also called Yucca or tapioca."
        ),
        GlossaryItem(
            name: "Chilli Powder",
            alternateNames: ["lal chutney"],
            description: "Chilli powders differ in strength. Therefore special care should be taken to use to your personal taste."
        ),
        GlossaryItem(
            name: "Cinnamon",
            alternateNames: ["tuj"],
            description: "Cinnamon has a pleasant, sweet taste and aroma. It can be purchased in sticks and powder form."
        ),
        GlossaryItem(
            name: "Citric Acid",
            alternateNames: ["limboo na phool"],
            description: "Citric acid is used instead of lemon juice. It can be easily purchased from an Indian grocery."
        ),
        GlossaryItem(
            name: "Cloves",
            alternateNames: ["laving"],
            description: "Cloves are aromatic, and are used whole or in powder form."
        ),
        GlossaryItem(
            name: "Coconut Cream",
            alternateNames: [],
            description: "There are different kinds of coconut cream or powder, which can be purchased from Indian speciality stores. Fresh coconut can be used as well. Chisel out white flesh, cut flesh into small pieces and blend with a little water. Squeeze the pulp through a sieve and use the white liquid instead of ready cream or powder. This process may be repeated for weaker milks. The used flesh should be discarded."
        ),
        GlossaryItem(
            name: "Coriander",
            alternateNames: ["dhana", "kothmir", "Chinese parsley", "cilantro"],
            description: "This can be purchased in seeds, coarsely ground or powder form. Fresh coriander leaves (kothmir) are also sold in some supermarkets and speciality food stores. It is also called Chinese parsley or cilantro. Can be grown from seed."
        ),
        GlossaryItem(
            name: "Cumin",
            alternateNames: ["jeera"],
            description: "This can be purchased in seed or powder form. Best ground in coffee grinder."
        ),
        GlossaryItem(
            name: "Curry Leaves",
            alternateNames: ["limdho"],
            description: "Curry leaves are like bay leaves, but much smaller. They are sold fresh or dry. Fresh can be kept frozen in a container until used."
        ),
        GlossaryItem(
            name: "Daals",
            alternateNames: ["lentils"],
            description: "Split beans are called daals (lentils). There are many different kinds of lentils. This is a good source of protein."
        ),
        GlossaryItem(
            name: "Edible Silver Paper",
            alternateNames: [],
            description: "Edible silver paper is used to garnish any sweet dish. It is available at Indian grocery stores. It is very delicate and should be handled carefully and gently."
        ),
        
        // Page 3 Items
        GlossaryItem(
            name: "Eno",
            alternateNames: ["Eno's Fruit Salt"],
            description: "Eno is a mixture of sodium bicarbonate and tartaric acid."
        ),
        GlossaryItem(
            name: "Fenugreek",
            alternateNames: ["methi", "methi ni bhaji"],
            description: "Fenugreek are tiny yellow seeds. They are used in pickles. Coarsely ground can be purchased from Indian grocery. They can also be grown and the leaves are used in special dishes, and leaves are called methi ni bhaji."
        ),
        GlossaryItem(
            name: "Garam Masala",
            alternateNames: [],
            description: "A combination of spices which varies from cook to cook in spiciness and hotness, see recipe page 18. Commercial versions are available in Indian or Oriental food stores."
        ),
        GlossaryItem(
            name: "Garlic",
            alternateNames: ["lasan"],
            description: "Garlic is sold in most food stores, either fresh, powdered, or in dehydrated flakes. It is also sold in paste form. Throughout this book, dehydrated flakes are used. Soak dehydrated garlic flakes in water for 2 hours, and then blend in food processor with the minimum amount of water necessary. This can be stored in refrigerator or freezer. MINIMUM amounts of garlic have been suggested in these recipes, add additional garlic according to your preference."
        ),
        GlossaryItem(
            name: "Ghee",
            alternateNames: ["clarified butter"],
            description: "The best-flavoured ghee is made from unsalted butter. See recipe, page 18."
        ),
        GlossaryItem(
            name: "Ginger",
            alternateNames: ["adu"],
            description: "It is sold as fresh root, dried, ready paste, and in cans. Through this book the cans are used. Discard the water and then blend in food processor with a little water. This can be stored in the refrigerator or freezer."
        ),
        GlossaryItem(
            name: "Gram Flour",
            alternateNames: ["channa no atto", "channa"],
            description: "This is the flour made from black chickpeas, and is also known as channa. It is very high in protein and is gluten-free. It is widely used for making savoury and sweet dishes."
        ),
        GlossaryItem(
            name: "Gum Arbic",
            alternateNames: ["gund"],
            description: "Gund is purchased in a crystalized form. When frying gund, special care should be taken. If fried in clarified butter, make sure that there is no water left, otherwise gum will not pop. It is important that gum (gund) pops up when fried and is no longer hard or sticky."
        ),
        GlossaryItem(
            name: "Hot Pepper",
            alternateNames: [],
            description: "A few varieties are available, fresh or in powder form. They are differentiated by colour and strength. As seeds can be very hot, they may be removed. Prepare with care under cold running water, (use gloves if necessary), wash hands immediately afterwards as handling may cause stinging of the skin. Making a small slit in pepper before frying will keep pepper from erupting in oil. (Ohio State University research has proven that capsaicine — a chemical found in hot peppers — significantly reduces cholesterol levels and can help ward off heart attacks and strokes)."
        ),
        GlossaryItem(
            name: "Joggery",
            alternateNames: ["ghor"],
            description: "Sold in Indian grocery stores. This is the semisolid stage of sugar cane. It has a light yellow to dark orange colour, and the flavour of molasses."
        ),
        GlossaryItem(
            name: "Kataifi Pastry",
            alternateNames: ["shredded dough"],
            description: "This is Lebanese pastry and is sold in supermarkets and Lebanese grocery stores."
        ),
        
        // Page 1 Items
        GlossaryItem(
            name: "Masoor",
            alternateNames: ["lentils"],
            description: "They are brown in color. Split masoor are red in colour."
        ),
        GlossaryItem(
            name: "Mustard Seeds",
            alternateNames: ["rai"],
            description: "They are round black seeds used to flavour vegetables and other dishes. Coarsely ground for pickles can be purchased from Indian grocery."
        ),
        GlossaryItem(
            name: "Nutmeg",
            alternateNames: ["jaiphal"],
            description: "It has a pleasant smell and is used in sweets."
        ),
        GlossaryItem(
            name: "Omum",
            alternateNames: ["ajma"],
            description: "Ajma are tiny seeds, sold in Indian grocery stores and are used for vegetable dishes."
        ),
        GlossaryItem(
            name: "Papadums",
            alternateNames: [],
            description: "A kind of flat crispy wafer which can be bought from Indian grocery stores, ready either to be broiled or deep-fried in oil."
        ),
        GlossaryItem(
            name: "Paprika Powder",
            alternateNames: [],
            description: "Paprika powder is not hot, as it is made from bell peppers. It is used to give color and reduce the hot taste. Use instead of chilli powder."
        ),
        GlossaryItem(
            name: "Patra",
            alternateNames: ["advi-na-bhajia"],
            description: "Patra are ready, canned in India, and can be purchased from Indian grocery store."
        ),
        GlossaryItem(
            name: "Poppy Seeds",
            alternateNames: ["khas khas"],
            description: "Poppy seeds are tiny seeds commonly used in sweet meats."
        ),
        GlossaryItem(
            name: "Rice",
            alternateNames: [],
            description: "There are many varieties of rice: long grain, Basmati rice, patna, American and more. For best results, the rice should be washed in 3 to 4 changes of water, then soaked for 10 to 20 minutes; longer soaking reduces the cooking time. Only the loose rice requires washing and soaking, the pre-packed varieties can be prepared as the package directs."
        ),
        GlossaryItem(
            name: "Saffron",
            alternateNames: ["kesar"],
            description: "Saffron is the most expensive spice available and is used for its flavour and colour in Biryani, pilau, and sweets."
        ),
        GlossaryItem(
            name: "Sugar Syrup",
            alternateNames: ["chasni", "tar"],
            description: "For various sweets different kinds of sugar syrup is required. The strength is measured by strings (tar). Boil sugar and water for few minutes and check by a drop between thumb and forefinger. Press and separate; if the syrup forms strings (tar) it is called one string of tar. If two or more strings form, the syrup will be thicker. It can also be tested with a candy thermometer or by dropping a drop on a plate. The lighter strength syrup will spread and heavier will stand like a ball."
        ),
        GlossaryItem(
            name: "Tapioca Starch",
            alternateNames: [],
            description: "Is purchased from any leading supermarket, Chinese or Indian grocery stores."
        ),
        GlossaryItem(
            name: "Turmeric",
            alternateNames: ["haldi"],
            description: "This is only used in a savoury dish to give colour. It has an antiseptic value. Salt and turmeric is used for sore throats and weak gums."
        ),
        GlossaryItem(
            name: "Wheatlets",
            alternateNames: ["sooji", "cream of wheat", "semolina"],
            description: "Wheatlets is also known as cream of wheat and semolina."
        ),
        GlossaryItem(
            name: "Yellow Food Colour",
            alternateNames: [],
            description: "Sold in Indian groceries in powder form."
        )
    ].sorted { $0.name < $1.name }
}

// MARK: - Views

struct GlossaryView: View {
    @State private var searchText = ""
    @State private var selectedItem: GlossaryItem?
    
    private var filteredItems: [GlossaryItem] {
        if searchText.isEmpty {
            return GlossaryItem.allItems
        } else {
            return GlossaryItem.allItems.filter { $0.matches(searchText: searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredItems) { item in
                Button {
                    selectedItem = item
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Ingredient Glossary")
            .searchable(text: $searchText, prompt: "Search ingredients...")
            .sheet(item: $selectedItem) { item in
                GlossaryDetailView(item: item)
            }
            .overlay {
                if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}

struct GlossaryDetailView: View {
    let item: GlossaryItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main name
                    Text(item.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Alternate names
                    if !item.alternateNames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Also Known As:")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            ForEach(item.alternateNames, id: \.self) { alternateName in
                                Text("• \(alternateName)")
                                    .font(.body)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(item.description)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Glossary List") {
    GlossaryView()
}

#Preview("Glossary Detail") {
    GlossaryDetailView(item: GlossaryItem.allItems[0])
}

// MARK: - Embedded Version for Help System

struct EmbeddedGlossaryView: View {
    @State private var searchText = ""
    @State private var selectedItem: GlossaryItem?
    
    private var filteredItems: [GlossaryItem] {
        if searchText.isEmpty {
            return GlossaryItem.allItems
        } else {
            return GlossaryItem.allItems.filter { $0.matches(searchText: searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search ingredients...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .padding(.bottom, 12)
            
            // Results count
            if !searchText.isEmpty {
                HStack {
                    Text("\(filteredItems.count) ingredient\(filteredItems.count == 1 ? "" : "s") found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
            
            // List
            if filteredItems.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxHeight: 400)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text(item.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 500)
            }
        }
        .sheet(item: $selectedItem) { item in
            GlossaryDetailView(item: item)
        }
    }
}

#Preview("Embedded Glossary") {
    EmbeddedGlossaryView()
        .padding()
}
