//
//  LaunchScreenView.swift
//  NowThatIKnowMore
//
//  Launch screen with larger image
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Launch image - VERY LARGE VERSION
            Image("AppIconImage") // Your app icon/logo (1024x1024)
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 350) // Explicit large size
                .clipped()
        }
    }
}

// Alternative: Larger image with specific size
struct LaunchScreenViewLarge: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("LaunchImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.8) // 80% of screen width
                    .frame(height: UIScreen.main.bounds.height * 0.6) // 60% of screen height
                
                Spacer()
            }
        }
    }
}

// Alternative: Full-screen image with minimal padding
struct LaunchScreenViewFullscreen: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            Image("LaunchImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 20) // Minimal horizontal padding
                .padding(.vertical, 60)   // Some vertical padding for safe areas
        }
    }
}

#Preview {
    LaunchScreenView()
}

#Preview("Large") {
    LaunchScreenViewLarge()
}

#Preview("Fullscreen") {
    LaunchScreenViewFullscreen()
}
