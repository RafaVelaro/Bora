import SwiftUI

/// Temporary email + password sign-in for testing the live backend.
/// Enter any email and a password (6+ chars) — it signs you in, creating the
/// account on first use.
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
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Theme.Palette.primary)
                }
                Text("Welcome to Bora")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.Palette.ink)
                Text("Sign in to sync your availability with friends. New here? Just pick a password — we'll create your account.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                field {
                    TextField("you@email.com", text: $auth.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                field {
                    SecureField("Password (6+ characters)", text: $auth.password)
                        .textContentType(.password)
                }

                Button {
                    Task { await auth.submit() }
                } label: {
                    Text(auth.isWorking ? "Signing in…" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(auth.isWorking)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.busy)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Text("Temporary login for testing — real email sign-in coming before launch.")
                .font(.caption)
                .foregroundStyle(Theme.Palette.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func field<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.md)
            .background(Theme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Palette.stroke, lineWidth: 1)
            )
    }
}
