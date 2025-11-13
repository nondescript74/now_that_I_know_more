//
//  SettingsView.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 11/6/25.
//

import SwiftUI
import Photos

/// Settings and About screen with license review option
struct SettingsView: View {
    @State private var viewModel = LicenseAcceptanceViewModel()
    @State private var showFullLicense = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // About Section
                aboutSection
                
                // Copyright Section
                copyrightSection
                
                // License Section
                licenseSection
                
                // Permissions Section
                permissionsSection
                
                // Privacy Section
                privacySection
                
                // Credits Section
                creditsSection
                
                // Support Section
                supportSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFullLicense) {
                fullLicenseSheet
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack(spacing: 15) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("NowThatIKnowMore")
                        .font(.headline)
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Version \(version) (\(build))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Text("A comprehensive recipe management app with OCR import, meal planning, and Spoonacular API integration.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Copyright Section
    
    private var copyrightSection: some View {
        Section("Copyright") {
            VStack(alignment: .leading, spacing: 8) {
                Text("© 2025 Zahirudeen Premji")
                    .font(.subheadline)
                
                Text("All rights reserved. Licensed under Creative Commons Attribution 4.0 International License (CC BY 4.0).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - License Section
    
    private var licenseSection: some View {
        Section("License") {
            Button(action: {
                showFullLicense = true
            }) {
                HStack {
                    Label("View Full License", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("License Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("CC BY 4.0")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            
            if let acceptanceDate = viewModel.formattedAcceptanceDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("License Accepted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(acceptanceDate)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        Section("App Permissions") {
            // Photo Library Permission
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: photoLibraryIcon)
                    .font(.title3)
                    .foregroundStyle(photoLibraryColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Photo Library")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.photoStatusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Required to import recipe photos and add images to recipes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.photoLibraryStatus == .denied || viewModel.photoLibraryStatus == .restricted {
                        Button(action: {
                            viewModel.openSettings()
                        }) {
                            Text("Open Settings")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    } else if viewModel.photoLibraryStatus == .notDetermined {
                        Button(action: {
                            Task {
                                await viewModel.requestPhotoLibraryPermission()
                            }
                        }) {
                            Text("Grant Permission")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Mail Permission
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: mailIcon)
                    .font(.title3)
                    .foregroundStyle(mailColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mail")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.mailStatusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Required to email recipes. Configure an email account in Settings > Mail")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !viewModel.isMailAvailable {
                        Button(action: {
                            if let url = URL(string: "App-prefs:MAIL") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Configure Mail")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // App Version Info
            VStack(alignment: .leading, spacing: 4) {
                Text("App Version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.currentAppVersion)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var photoLibraryIcon: String {
        switch viewModel.photoLibraryStatus {
        case .authorized, .limited:
            return "photo.fill"
        case .denied, .restricted:
            return "photo.fill.on.rectangle.fill"
        case .notDetermined:
            return "photo"
        @unknown default:
            return "photo"
        }
    }
    
    private var photoLibraryColor: Color {
        switch viewModel.photoLibraryStatus {
        case .authorized, .limited:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var mailIcon: String {
        return viewModel.isMailAvailable ? "envelope.fill" : "envelope.badge.fill"
    }
    
    private var mailColor: Color {
        return viewModel.isMailAvailable ? .green : .orange
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section("Privacy") {
            privacyRow(
                icon: "hand.raised.fill",
                title: "No Data Collection",
                description: "We do not collect, store, or transmit any personal information"
            )
            
            privacyRow(
                icon: "iphone",
                title: "Local Storage Only",
                description: "All your recipes and data stay exclusively on your device"
            )
            
            privacyRow(
                icon: "chart.bar.fill",
                title: "No Analytics",
                description: "No tracking, telemetry, or usage analytics of any kind"
            )
            
            privacyRow(
                icon: "rectangle.slash",
                title: "No Advertisements",
                description: "Completely ad-free experience, no third-party ad networks"
            )
            
            privacyRow(
                icon: "wifi.slash",
                title: "Offline Functionality",
                description: "Core features work completely offline; network only for Spoonacular API"
            )
        }
    }
    
    private func privacyRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        Section("Credits & Acknowledgments") {
            creditRow(
                icon: "apple.logo",
                title: "Apple Frameworks",
                description: "Built with SwiftUI, Vision, and VisionKit"
            )
            
            creditRow(
                icon: "link",
                title: "Spoonacular API",
                description: "Recipe data powered by Spoonacular"
            )
            
            creditRow(
                icon: "heart.fill",
                title: "Open Source Community",
                description: "Thanks to the Swift and iOS developer community"
            )
            
            creditRow(
                icon: "person.2.fill",
                title: "Beta Testers",
                description: "Appreciation for feedback and suggestions"
            )
        }
    }
    
    private func creditRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section("Support") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Educational Purpose")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("This app is designed for personal recipe management and learning iOS development")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food Safety Notice")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Always verify recipes (especially OCR scans) and follow safe food handling practices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Full License Sheet
    
    private var fullLicenseSheet: some View {
        NavigationView {
            ScrollView {
                Text(licenseText)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Software License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFullLicense = false
                    }
                }
            }
        }
    }
    
    private var licenseText: String {
        guard let url = Bundle.main.url(forResource: "license", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Error loading license text."
        }
        return text
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
