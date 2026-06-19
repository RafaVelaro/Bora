import Foundation
import SwiftUI

/// Drives the email one-time-code sign-in flow and exposes auth state to the UI.
@MainActor
final class AuthModel: ObservableObject {
    enum Step: Equatable {
        case email      // entering email address
        case code       // entering the 6-digit code
        case signedIn
    }

    @Published var step: Step
    @Published var email = ""
    @Published var code = ""
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let api = BoraAPI.shared

    init() {
        step = api.isSignedIn ? .signedIn : .email
    }

    var isSignedIn: Bool { step == .signedIn }

    func sendCode() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            try await api.sendEmailCode(trimmed)
            email = trimmed
            step = .code
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verify() async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter the code from your email."
            return
        }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            try await api.verifyEmailCode(email: email, code: trimmed)
            code = ""
            step = .signedIn
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startOver() {
        code = ""
        errorMessage = nil
        step = .email
    }

    func signOut() {
        api.signOut()
        email = ""; code = ""
        step = .email
    }
}
