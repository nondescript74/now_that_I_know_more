// New view for entering and saving Spoonacular API key
import SwiftUI

struct APIKeyEntryView: View {
    @AppStorage("spoonacularAPIKey") private var apiKey: String = ""
    @State private var tempKey: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Spoonacular API Key")) {
                    SecureField("Enter API Key", text: $tempKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Save") {
                        apiKey = tempKey
                        dismiss()
                    }
                    .disabled(tempKey.isEmpty || tempKey == apiKey)
                }
            }
            .navigationTitle("API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            tempKey = apiKey
        }
    }
}

#Preview {
    APIKeyEntryView()
}
