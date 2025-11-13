//
//  LicenseAcceptanceViewModel.swift
//  NowThatIKnowMore
//
//  Created by Zahirudeen Premji on 11/6/25.
//

import Foundation
import Observation
import Photos
import MessageUI
import UIKit

/// View model managing license acceptance state and persistence
@MainActor
@Observable
class LicenseAcceptanceViewModel {
    
    // MARK: - Properties
    
    /// Tracks whether the user has scrolled to the bottom of the license
    var hasScrolledToBottom: Bool = false
    
    /// Tracks whether the user has checked the "I agree" checkbox
    var hasAgreed: Bool = false
    
    /// Current scroll progress from 0.0 (top) to 1.0 (bottom)
    var scrollProgress: CGFloat = 0.0
    
    /// Tracks photo library permission status
    var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    
    /// Tracks mail availability status
    var isMailAvailable: Bool = false
    
    /// Tracks whether permissions need to be requested for this version
    var needsPermissionCheck: Bool = false
    
    // MARK: - Constants
    
    /// Current version of the license - increment when license text changes
    private let currentLicenseVersion = "1.0"
    
    /// UserDefaults key for storing accepted license version
    private let acceptedVersionKey = "acceptedLicenseVersion"
    
    /// UserDefaults key for storing acceptance date
    private let acceptanceDateKey = "licenseAcceptanceDate"
    
    /// UserDefaults key for storing the last app version that checked permissions
    private let lastPermissionCheckVersionKey = "lastPermissionCheckVersion"
    
    /// Threshold for considering the user has reached the bottom (95%)
    private let scrollThreshold: CGFloat = 0.95
    
    // MARK: - Initialization
    
    init() {
        checkPermissionsStatus()
        determineIfPermissionCheckNeeded()
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the user can accept the license (scrolled to bottom AND agreed)
    var canAccept: Bool {
        return hasScrolledToBottom && hasAgreed
    }
    
    /// Returns true if the current license version needs to be accepted OR permissions need checking
    var needsLicenseAcceptance: Bool {
        guard let acceptedVersion = UserDefaults.standard.string(forKey: acceptedVersionKey) else {
            return true // No version accepted yet
        }
        // Need acceptance if license version changed OR app version changed
        return acceptedVersion != currentLicenseVersion || needsPermissionCheck
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
    
    /// Returns the current app version
    var currentAppVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
    
    /// Returns a human-readable description of photo library status
    var photoStatusDescription: String {
        switch photoLibraryStatus {
        case .notDetermined:
            return "Not Yet Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized, .limited:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Returns a human-readable description of mail status
    var mailStatusDescription: String {
        return isMailAvailable ? "Available" : "Not Configured"
    }
    
    // MARK: - Permission Methods
    
    /// Checks current status of all permissions
    private func checkPermissionsStatus() {
        // Check photo library status
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // Check mail availability
        isMailAvailable = MFMailComposeViewController.canSendMail()
    }
    
    /// Determines if permissions need to be checked for this app version
    private func determineIfPermissionCheckNeeded() {
        let currentVersion = currentAppVersion
        let lastCheckedVersion = UserDefaults.standard.string(forKey: lastPermissionCheckVersionKey)
        
        // Need to check permissions if this is a new version or first run
        needsPermissionCheck = (lastCheckedVersion != currentVersion)
    }
    
    /// Requests photo library permission (safely handles main actor)
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        // Use callback-based API wrapped in continuation for proper thread handling
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
        
        // Update our tracked status on MainActor
        await MainActor.run {
            self.photoLibraryStatus = status
            print("📸 Photo permission granted: \(status == .authorized || status == .limited)")
        }
        
        return status
    }
    
    /// Marks that permissions have been verified for this version
    func markPermissionsVerified() {
        UserDefaults.standard.set(currentAppVersion, forKey: lastPermissionCheckVersionKey)
        UserDefaults.standard.synchronize()
        needsPermissionCheck = false
    }
    
    // MARK: - Public Methods
    
    /// Records that the user has accepted the current license version
    func acceptLicense() {
        UserDefaults.standard.set(currentLicenseVersion, forKey: acceptedVersionKey)
        UserDefaults.standard.set(Date(), forKey: acceptanceDateKey)
        markPermissionsVerified()
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
        UserDefaults.standard.removeObject(forKey: lastPermissionCheckVersionKey)
        UserDefaults.standard.synchronize()
        hasScrolledToBottom = false
        hasAgreed = false
        scrollProgress = 0.0
        checkPermissionsStatus()
        determineIfPermissionCheckNeeded()
    }
    
    /// Returns the current license version
    func getCurrentVersion() -> String {
        return currentLicenseVersion
    }
    
    /// Returns the accepted license version, if any
    func getAcceptedVersion() -> String? {
        return UserDefaults.standard.string(forKey: acceptedVersionKey)
    }
    
    /// Opens system settings to allow user to change permissions
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
