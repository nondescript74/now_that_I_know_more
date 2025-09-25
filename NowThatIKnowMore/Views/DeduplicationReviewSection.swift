import SwiftUI

struct DeduplicationReviewSection: View {
    let duplicateInfo: [(index: Int, text: String)]
    @Binding var restoredDuplicates: Set<Int>
    let onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Duplicate lines detected and removed.").bold()
            Text("Review and restore any lines below if needed.")
            ForEach(duplicateInfo.indices, id: \.self) { i in
                HStack {
                    Toggle(isOn: Binding(
                        get: { restoredDuplicates.contains(i) },
                        set: { checked in
                            if checked { restoredDuplicates.insert(i) } else { restoredDuplicates.remove(i) }
                        })
                    ) {
                        Text(duplicateInfo[i].text)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            Button("Apply & Continue") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(12)
    }
}

#Preview {
    @Previewable @State var restoredDuplicates: Set<Int> = []
    let duplicateInfo = [(0, "Line 1"), (2, "Line 3"), (4, "Line 5")]
    return DeduplicationReviewSection(
        duplicateInfo: duplicateInfo,
        restoredDuplicates: $restoredDuplicates,
        onApply: { print("Applied") }
    )
    .padding()
}
