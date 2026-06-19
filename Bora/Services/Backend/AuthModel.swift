import Foundation
import SwiftUI

/// Drives sign-in. Temporary email + password flow so we can test the live
/// backend on the free tier (no custom SMTP yet). Will be swapped for real
/// magic-link / Sign-in-with-Apple auth before launch.
@MainActor
final class AuthModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var signedIn: Bool

    private let api = BoraAPI.shared

    init() { signedIn = api.isSignedIn }

    var isSignedIn: Bool { signedIn }

    /// Sign in — creating the account first if it doesn't exist yet.
    func submit() async {
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard mail.contains("@"), password.count >= 6 else {
            errorMessage = "Enter an email and a password of at least 6 characters."
            return
        }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            do {
                try await api.signInWithPassword(email: mail, password: password)
            } catch {
                // No account yet (or wrong password) — try to create it.
                try await api.signUpWithPassword(email: mail, password: password)
            }
            signedIn = api.isSignedIn
            if !signedIn { errorMessage = "Could not sign in. Check your details." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        api.signOut()
        email = ""; password = ""
        signedIn = false
    }
}
