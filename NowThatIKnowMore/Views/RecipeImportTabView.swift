//
//  RecipeImportTabView.swift
//  NowThatIKnowMore
//
//  Unified import view that supports both photo and PDF imports
//

import SwiftUI
import SwiftData

struct RecipeImportTabView: View {
    @State private var selectedImportMode: ImportMode = .photo
    
    enum ImportMode: String, CaseIterable {
        case photo = "Photo"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .photo: return "camera"
            case .pdf: return "doc.text"
            }
        }
        
        var description: String {
            switch self {
            case .photo:
                return "Scan recipe cards and cookbook pages with your camera"
            case .pdf:
                return "Import recipes from PDF files with better multi-column support"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Selector
                Picker("Import Mode", selection: $selectedImportMode) {
                    ForEach(ImportMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Description
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    
                    Text(selectedImportMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Divider()
                
                // Content View
                TabView(selection: $selectedImportMode) {
                    RecipeImageParserView()
                        .tag(ImportMode.photo)
                    
                    RecipePDFParserView()
                        .tag(ImportMode.pdf)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RecipeImportTabView()
        .modelContainer(for: [RecipeModel.self, RecipeBookModel.self])
}
