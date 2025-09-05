import SwiftUI

struct LaunchScreenView: View {
    @State private var opacity = 0.0
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "NowThatIKnowMore"
    }
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    private var copyright: String {
        "Copyright © \(Calendar.current.component(.year, from: Date())) Zahirudeen Premji"
    }
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .shadow(radius: 12)
                Text(appName)
                    .font(.largeTitle).fontWeight(.bold)
                Text("Version \(version) (\(build))")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(copyright)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
