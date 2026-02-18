import Foundation
import SwiftUI

/// Manages user authentication state
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isSignedIn: Bool = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userPhotoURL: URL?
    
    private let defaults = UserDefaults.standard
    
    private init() {
        // Restore session from UserDefaults
        loadSavedSession()
    }
    
    /// User's initials for avatar display
    var userInitials: String {
        guard let name = userName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    // MARK: - Session Management
    
    /// Sign in with email and name (for demo/testing)
    func signIn(email: String, name: String) {
        self.userEmail = email
        self.userName = name
        self.isSignedIn = true
        saveSession()
    }
    
    /// Sign in with Google (Firebase Auth)
    func signInWithGoogle() async throws {
        // TODO: Implement Firebase Google Sign-In
        // This requires:
        // 1. Add GoogleService-Info.plist
        // 2. Add Firebase SDK via SPM
        // 3. Configure GIDSignIn
        
        // For now, throw not implemented
        throw AuthError.notImplemented
    }
    
    /// Sign out the current user
    func signOut() {
        self.userEmail = nil
        self.userName = nil
        self.userPhotoURL = nil
        self.isSignedIn = false
        clearSession()
    }
    
    /// Delete the user's account and sign out
    func deleteAccount() async throws {
        guard let email = userEmail else {
            throw AuthError.noCredentials
        }
        try await APIService.shared.deleteAccount(email: email)
        await MainActor.run {
            signOut()
        }
    }
    
    // MARK: - Persistence
    
    private func saveSession() {
        defaults.set(userEmail, forKey: "auth_email")
        defaults.set(userName, forKey: "auth_name")
        defaults.set(userPhotoURL?.absoluteString, forKey: "auth_photo_url")
        defaults.set(isSignedIn, forKey: "auth_signed_in")
    }
    
    private func loadSavedSession() {
        isSignedIn = defaults.bool(forKey: "auth_signed_in")
        userEmail = defaults.string(forKey: "auth_email")
        userName = defaults.string(forKey: "auth_name")
        if let photoURLString = defaults.string(forKey: "auth_photo_url") {
            userPhotoURL = URL(string: photoURLString)
        }
    }
    
    private func clearSession() {
        defaults.removeObject(forKey: "auth_email")
        defaults.removeObject(forKey: "auth_name")
        defaults.removeObject(forKey: "auth_photo_url")
        defaults.removeObject(forKey: "auth_signed_in")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notImplemented
    case googleSignInFailed(Error)
    case noCredentials
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Google Sign-In not yet configured. Use Demo Mode."
        case .googleSignInFailed(let error):
            return "Google Sign-In failed: \(error.localizedDescription)"
        case .noCredentials:
            return "No credentials found"
        }
    }
}
