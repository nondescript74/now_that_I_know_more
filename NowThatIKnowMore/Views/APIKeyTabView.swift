import SwiftUI

struct APIKeyTabView: View {
    var body: some View {
        NavigationStack {
            APIKeyEntryView()
                .navigationTitle("API Key")
        }
    }
}

#Preview {
    APIKeyTabView()
}
