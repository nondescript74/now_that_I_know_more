//
//  LicenseAcceptanceViewModel.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 11/6/25.
//

import Foundation
import Combine

/// View model managing license acceptance state and persistence
@MainActor
class LicenseAcceptanceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Tracks whether the user has scrolled to the bottom of the license
    @Published var hasScrolledToBottom: Bool = false
    
    /// Tracks whether the user has checked the "I agree" checkbox
    @Published var hasAgreed: Bool = false
    
    /// Current scroll progress from 0.0 (top) to 1.0 (bottom)
    @Published var scrollProgress: CGFloat = 0.0
    
    // MARK: - Constants
    
    /// Current version of the license - increment when license text changes
    private let currentLicenseVersion = "1.0"
    
    /// UserDefaults key for storing accepted license version
    private let acceptedVersionKey = "acceptedLicenseVersion"
    
    /// UserDefaults key for storing acceptance date
    private let acceptanceDateKey = "licenseAcceptanceDate"
    
    /// Threshold for considering the user has reached the bottom (95%)
    private let scrollThreshold: CGFloat = 0.95
    
    // MARK: - Computed Properties
    
    /// Returns true if the user can accept the license (scrolled to bottom AND agreed)
    var canAccept: Bool {
        return hasScrolledToBottom && hasAgreed
    }
    
    /// Returns true if the current license version needs to be accepted
    var needsLicenseAcceptance: Bool {
        guard let acceptedVersion = UserDefaults.standard.string(forKey: acceptedVersionKey) else {
            return true // No version accepted yet
        }
        return acceptedVersion != currentLicenseVersion
    }
    
    /// Returns the date when the license was accepted, if available
    var licenseAcceptanceDate: Date? {
        return UserDefaults.standard.object(forKey: acceptanceDateKey) as? Date
    }
    
    /// Returns formatted acceptance date string
    var formattedAcceptanceDate: String? {
        guard let date = licenseAcceptanceDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Public Methods
    
    /// Records that the user has accepted the current license version
    func acceptLicense() {
        UserDefaults.standard.set(currentLicenseVersion, forKey: acceptedVersionKey)
        UserDefaults.standard.set(Date(), forKey: acceptanceDateKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Updates the scroll progress and determines if user has reached bottom
    /// - Parameter progress: A value from 0.0 (top) to 1.0 (bottom)
    func updateScrollProgress(_ progress: CGFloat) {
        self.scrollProgress = progress
        
        // Mark as scrolled to bottom if progress exceeds threshold
        if progress >= scrollThreshold && !hasScrolledToBottom {
            hasScrolledToBottom = true
        }
    }
    
    /// Resets license acceptance (for testing/development only)
    func resetAcceptance() {
        UserDefaults.standard.removeObject(forKey: acceptedVersionKey)
        UserDefaults.standard.removeObject(forKey: acceptanceDateKey)
        UserDefaults.standard.synchronize()
        hasScrolledToBottom = false
        hasAgreed = false
        scrollProgress = 0.0
    }
    
    /// Returns the current license version
    func getCurrentVersion() -> String {
        return currentLicenseVersion
    }
    
    /// Returns the accepted license version, if any
    func getAcceptedVersion() -> String? {
        return UserDefaults.standard.string(forKey: acceptedVersionKey)
    }
}
