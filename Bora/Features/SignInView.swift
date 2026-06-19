import SwiftUI

/// Email one-time-code sign-in. Shown only when the backend is configured and
/// the user isn't signed in yet.
struct SignInView: View {
    @EnvironmentObject private var auth: AuthModel

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.primarySoft)
                        .frame(width: 110, height: 110)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Theme.Palette.primary)
                }
                Text(auth.step == .code ? "Check your email" : "Welcome to Bora")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.Palette.ink)
                Text(auth.step == .code
                     ? "Enter the 6-digit code we sent to \(auth.email)."
                     : "We'll email you a code to sign in — no password needed.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()

            if auth.step == .code {
                codeEntry
            } else {
                emailEntry
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.busy)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.background.ignoresSafeArea())
    }

    private var emailEntry: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("you@email.com", text: $auth.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Palette.stroke, lineWidth: 1)
                )

            Button {
                Task { await auth.sendCode() }
            } label: {
                Text(auth.isWorking ? "Sending…" : "Send me a code")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(auth.isWorking)
        }
    }

    private var codeEntry: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("123456", text: $auth.code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2.weight(.semibold).monospacedDigit())
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Palette.stroke, lineWidth: 1)
                )

            Button {
                Task { await auth.verify() }
            } label: {
                Text(auth.isWorking ? "Verifying…" : "Verify & continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(auth.isWorking)

            Button("Use a different email") { auth.startOver() }
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
    }
}
