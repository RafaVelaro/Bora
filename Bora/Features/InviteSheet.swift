import SwiftUI
import UIKit

/// Add friends two ways: share your own invite code, or enter a friend's.
struct InviteSheet: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var myCode: String?
    @State private var creating = false

    @State private var codeToRedeem = ""
    @State private var redeeming = false
    @State private var addedName: String?

    @State private var errorMessage: String?

    private var shareMessage: String {
        let code = myCode ?? ""
        return "Let's stop planning in the group chat 🟠 Join me on Bora and we'll see when we're both free. Open the app and enter my invite code: \(code)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    yourCodeCard
                    addFriendCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.busy)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Add friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(Theme.Palette.primary)
                }
            }
        }
    }

    // MARK: Share your code

    private var yourCodeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Invite a friend",
                              subtitle: "Share your code — they enter it to connect with you.")

                if let code = myCode {
                    HStack {
                        Text(code)
                            .font(.title3.weight(.bold).monospaced())
                            .foregroundStyle(Theme.Palette.ink)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Palette.primarySoft)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Theme.Palette.primary)
                        }
                    }

                    ShareLink(item: shareMessage) {
                        Label("Share invite", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Palette.primary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                } else {
                    Button {
                        Task { await createCode() }
                    } label: {
                        Text(creating ? "Creating…" : "Create invite code")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(creating)
                }
            }
        }
    }

    // MARK: Redeem a code

    private var addFriendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Got a code?",
                              subtitle: "Enter a friend's invite code to connect.")

                if let addedName {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Palette.mint)
                        Text("Connected with \(addedName)!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Palette.ink)
                    }
                }

                HStack {
                    TextField("Invite code", text: $codeToRedeem)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .stroke(Theme.Palette.stroke, lineWidth: 1)
                        )
                    Button {
                        Task { await redeem() }
                    } label: {
                        Text(redeeming ? "…" : "Add")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, 14)
                            .background(canRedeem ? Theme.Palette.primary : Theme.Palette.inkTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                    }
                    .disabled(!canRedeem)
                }
            }
        }
    }

    private var canRedeem: Bool {
        !redeeming && !codeToRedeem.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Actions

    private func createCode() async {
        creating = true; errorMessage = nil
        defer { creating = false }
        do { myCode = try await app.createInviteToken() }
        catch { errorMessage = error.localizedDescription }
    }

    private func redeem() async {
        redeeming = true; errorMessage = nil; addedName = nil
        defer { redeeming = false }
        let before = Set(app.friends.map(\.id))
        do {
            try await app.redeemInvite(code: codeToRedeem)
            // Surface the newly-added friend's name, if we can spot it.
            addedName = app.friends.first { !before.contains($0.id) }?.name ?? "your friend"
            codeToRedeem = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
