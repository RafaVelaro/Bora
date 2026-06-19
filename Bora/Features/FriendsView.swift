import SwiftUI

/// The friend list. Shows who's free right now and lets you add friends
/// (placeholder for the real invite/sharing flow).
struct FriendsView: View {
    @EnvironmentObject private var app: AppModel
    @State private var showingInvite = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    inviteCard

                    if app.friends.isEmpty {
                        Card {
                            EmptyStateView(systemImage: "person.2",
                                           title: "No friends yet",
                                           message: "Tap \u{201C}Invite a friend\u{201D} above to share your code, or enter a friend's code to connect.")
                        }
                    } else {
                        ForEach(app.friends) { friend in
                            FriendRow(friend: friend,
                                      tint: app.tint(for: friend),
                                      isFreeNow: isFreeNow(friend))
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Friends")
            .refreshable { await app.refreshFriends() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingInvite = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .tint(Theme.Palette.primary)
                }
            }
            .sheet(isPresented: $showingInvite) {
                InviteSheet()
            }
        }
    }

    private var inviteCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "link")
                    .font(.title2)
                    .foregroundStyle(Theme.Palette.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.Palette.primarySoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite your friends")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Share a code — or enter one to connect.")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
        }
        .onTapGesture { showingInvite = true }
    }

    private func isFreeNow(_ friend: Friend) -> Bool {
        let now = Date()
        return !friend.busy.contains { $0.contains(now) }
    }
}

private struct FriendRow: View {
    let friend: Friend
    let tint: Color
    let isFreeNow: Bool

    var body: some View {
        Card {
            HStack(spacing: Theme.Spacing.md) {
                AvatarView(initials: friend.initials, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isFreeNow ? Theme.Palette.mint : Theme.Palette.busy)
                            .frame(width: 7, height: 7)
                        Text(isFreeNow ? "Free now" : "Busy now")
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                    }
                }
                Spacer()
            }
        }
    }
}
