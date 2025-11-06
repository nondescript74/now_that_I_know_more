//
//  LicenseGateView.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 11/6/25.
//

import SwiftUI

/// A container view that conditionally shows the license or the main app content
struct LicenseGateView<Content: View>: View {
    @StateObject private var viewModel = LicenseAcceptanceViewModel()
    @State private var hasAcceptedLicense = false
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if hasAcceptedLicense || !viewModel.needsLicenseAcceptance {
                content()
                    .transition(.opacity)
            } else {
                LicenseAcceptanceView(
                    onAccept: {
                        withAnimation {
                            hasAcceptedLicense = true
                        }
                    },
                    onDecline: {
                        // Gracefully exit the app
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            exit(0)
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Check if license has already been accepted
            hasAcceptedLicense = !viewModel.needsLicenseAcceptance
        }
    }
}

// MARK: - Preview

#Preview("With License Gate") {
    LicenseGateView {
        TabView {
            Text("Main Content")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
    }
}

#Preview("Main Content (License Accepted)") {
    // Simulate license already accepted
    let viewModel = LicenseAcceptanceViewModel()
    let _ = viewModel.acceptLicense()
    
    return LicenseGateView {
        TabView {
            Text("Main Content - License Already Accepted")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
    }
}
