import Foundation
import SwiftUI

/// App-wide state that isn't the device calendar: the friend list and which
/// friends are currently selected for "find time". Later this is backed by the
/// sharing server.
@MainActor
final class AppModel: ObservableObject {
    @Published var friends: [Friend]
    @Published var selectedFriendIDs: Set<UUID>
    /// True once friends come from the live backend rather than mock data.
    @Published var isLive = false
    @Published var lastSyncError: String?

    private let sync = SyncService()

    init(friends: [Friend] = MockData.sampleFriends()) {
        self.friends = friends
        // Pre-select the first couple so "Find time" shows results immediately.
        self.selectedFriendIDs = Set(friends.prefix(2).map(\.id))
    }

    /// Push my availability and pull live friends from the backend. No-op unless
    /// the backend is configured and the user is signed in (otherwise we stay on
    /// mock data, so the app behaves exactly as before).
    func syncWithBackend(myBusy: [DateInterval], window: DateInterval) async {
        guard BoraConfig.isConfigured, BoraAPI.shared.isSignedIn else { return }
        do {
            try await sync.pushMyBusy(myBusy, window: window)
            let live = try await sync.loadFriends(window: window)
            friends = live
            isLive = true
            // Keep any still-valid selection; otherwise pre-select a couple.
            let ids = Set(live.map(\.id))
            selectedFriendIDs = selectedFriendIDs.intersection(ids)
            if selectedFriendIDs.isEmpty {
                selectedFriendIDs = Set(live.prefix(2).map(\.id))
            }
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    /// Create a share-link token to invite a friend.
    func createInviteToken() async throws -> String {
        try await sync.createInvite()
    }

    var selectedFriends: [Friend] {
        friends.filter { selectedFriendIDs.contains($0.id) }
    }

    func toggle(_ friend: Friend) {
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    func tint(for friend: Friend) -> Color {
        Theme.Palette.avatarTints[friend.colorIndex % Theme.Palette.avatarTints.count]
    }
}
