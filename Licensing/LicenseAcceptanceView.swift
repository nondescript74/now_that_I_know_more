//
//  LicenseAcceptanceView.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 11/6/25.
//

import SwiftUI
import Photos

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// View presenting the license agreement for user acceptance
struct LicenseAcceptanceView: View {
    @State private var viewModel = LicenseAcceptanceViewModel()
    
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var showDeclineAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                Divider()
                
                // License Text with Scroll Tracking
                licenseScrollView
                
                Divider()
                
                // Permission Request Section (if needed)
                if viewModel.needsPermissionCheck && viewModel.hasScrolledToBottom {
                    permissionsSection
                    Divider()
                }
                
                // Agreement Section
                agreementSection
                
                // Action Buttons
                actionButtons
            }
            .navigationTitle("License Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled(true)
        }
        .alert("Decline License", isPresented: $showDeclineAlert) {
            Button("Review Again", role: .cancel) { }
            Button("Exit App", role: .destructive) {
                onDecline()
            }
        } message: {
            Text("You must accept the license agreement to use NowThatIKnowMore. Are you sure you want to exit?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Welcome to NowThatIKnowMore")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please read and accept the license agreement to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - License Scroll View
    
    private var licenseScrollView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(licenseText)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(
                            GeometryReader { contentGeometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: contentGeometry.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let contentHeight = geometry.size.height
                let progress = min(max(-offset / (contentHeight * 2), 0), 1)
                viewModel.updateScrollProgress(progress)
            }
            .overlay(alignment: .bottom) {
                if !viewModel.hasScrolledToBottom {
                    scrollIndicator
                }
            }
            .overlay(alignment: .top) {
                if !viewModel.hasScrolledToBottom {
                    progressBar
                }
            }
        }
    }
    
    // MARK: - Scroll Indicator
    
    private var scrollIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title)
                .foregroundStyle(.blue)
            
            Text("Please scroll to read the entire license")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
        .shadow(radius: 5)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * viewModel.scrollProgress, height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(viewModel.scrollProgress * 100))% read")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Agreement Section
    
    private var agreementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                if viewModel.hasScrolledToBottom {
                    viewModel.hasAgreed.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.hasAgreed ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(viewModel.hasScrolledToBottom ? .blue : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I have read and agree to the license agreement")
                            .font(.body)
                            .foregroundColor(viewModel.hasScrolledToBottom ? .primary : .secondary)
                        
                        if !viewModel.hasScrolledToBottom {
                            Text("Please scroll to the bottom first")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .disabled(!viewModel.hasScrolledToBottom)
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    Text("App Permissions")
                        .font(.headline)
                }
                
                Text("This app needs access to certain features. You can review or change these permissions anytime in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Photo Library Permission
            HStack(spacing: 12) {
                Image(systemName: "photo.fill")
                    .font(.title3)
                    .foregroundStyle(photoPermissionColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo Library")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Import recipe photos from your library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.photoLibraryStatus == .notDetermined {
                        Button("Grant Access") {
                            Task {
                                await viewModel.requestPhotoLibraryPermission()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.top, 4)
                    } else {
                        Text("Status: \(viewModel.photoStatusDescription)")
                            .font(.caption)
                            .foregroundColor(photoPermissionColor)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            // Mail Status
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.title3)
                    .foregroundStyle(mailPermissionColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mail")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Share recipes via email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Status: \(viewModel.mailStatusDescription)")
                        .font(.caption)
                        .foregroundColor(mailPermissionColor)
                    
                    if !viewModel.isMailAvailable {
                        Text("Configure an email account in Settings > Mail")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var photoPermissionColor: Color {
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
    
    private var mailPermissionColor: Color {
        return viewModel.isMailAvailable ? .green : .orange
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                showDeclineAlert = true
            }) {
                Text("Decline")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.acceptLicense()
                onAccept()
            }) {
                Text("Accept & Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canAccept ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.canAccept)
        }
        .padding()
    }
    
    // MARK: - License Text
    
    private var licenseText: String {
        // Load license.md from bundle
        guard let url = Bundle.main.url(forResource: "license", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Error loading license text. Please contact support."
        }
        return text
    }
}

// MARK: - Preview

#Preview {
    LicenseAcceptanceView(
        onAccept: { print("Accepted") },
        onDecline: { print("Declined") }
    )
}
