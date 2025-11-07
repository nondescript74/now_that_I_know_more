//
//  CustomLaunchScreen.swift
//  NowThatIKnowMore
//
//  Custom launch screen with configurable image size
//

import SwiftUI

struct CustomLaunchScreen: View {
    var body: some View {
        ZStack {
            // Background color (matches your app theme)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Your app icon/logo - LARGE VERSION
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30) // ← ADJUST THIS: Smaller number = bigger image
                // Try these values:
                // .padding(20)  → Very large (recommended)
                // .padding(30)  → Large
                // .padding(40)  → Medium
                // .padding(60)  → Smaller
        }
    }
}

// Alternative: Specific size control
struct CustomLaunchScreenSized: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                // Precise size control
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.85)  // 85% of screen width
                    .frame(height: geometry.size.height * 0.6) // 60% of screen height
            }
        }
    }
}

// Alternative: Nearly fullscreen
struct CustomLaunchScreenFullscreen: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Maximum size
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20) // Minimal horizontal padding
                .padding(.vertical, 40)   // Small vertical padding for safe areas
        }
    }
}

#Preview("Custom Launch - Large") {
    CustomLaunchScreen()
}

#Preview("Custom Launch - Sized") {
    CustomLaunchScreenSized()
}

#Preview("Custom Launch - Fullscreen") {
    CustomLaunchScreenFullscreen()
}
