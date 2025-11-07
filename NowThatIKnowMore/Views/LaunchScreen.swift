//
//  LaunchScreen.swift
//  NowThatIKnowMore
//
//  Launch screen with larger AppIconImage
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // App icon image - LARGER size
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20) // REDUCED from default - makes image BIGGER
                // Try even smaller values for an even larger image:
                // .padding(10)  - Very large
                // .padding(30)  - Large
                // .padding(50)  - Medium
        }
    }
}

// Alternative: Specific size control
struct LaunchScreenLarge: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // 80% of screen width, 60% of screen height
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width * 0.8,
                               height: geometry.size.height * 0.6)
                    
                    Spacer()
                }
            }
        }
    }
}

// Alternative: Maximum size (almost fullscreen)
struct LaunchScreenMaximum: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 15) // Minimal horizontal padding
                .padding(.vertical, 40)   // Some vertical padding
        }
    }
}

#Preview("Default - Larger") {
    LaunchScreen()
}

#Preview("Large") {
    LaunchScreenLarge()
}

#Preview("Maximum") {
    LaunchScreenMaximum()
}
