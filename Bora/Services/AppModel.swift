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

    /// Minimum length a "free together" window must have to be shown.
    @Published var minMeetMinutes = 60
    /// Preset durations offered in the picker (minutes).
    static let durationPresets = [30, 45, 60, 90, 120, 180]
    var minDuration: TimeInterval { TimeInterval(minMeetMinutes * 60) }

    private let sync = SyncService()

    init(friends: [Friend] = MockData.sampleFriends()) {
        self.friends = friends
        // Pre-select the first couple so "Find time" shows results immediately.
        self.selectedFriendIDs = Set(friends.prefix(2).map(\.id))
    }

    /// Standard 14-day look-ahead window used for fetching friend availability.
    private var defaultWindow: DateInterval {
        let start = Calendar.current.startOfDay(for: Date())
        return DateInterval(start: start, duration: 14 * 24 * 60 * 60)
    }

    /// Push my availability and pull live friends from the backend. No-op unless
    /// the backend is configured and the user is signed in (otherwise we stay on
    /// mock data, so the app behaves exactly as before).
    func syncWithBackend(myBusy: [DateInterval], window: DateInterval) async {
        guard BoraConfig.isConfigured, BoraAPI.shared.isSignedIn else { return }
        do {
            try await sync.pushMyBusy(myBusy, window: window)
            try await loadFriends(window: window)
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    /// Reload just the friend list (e.g. after adding someone).
    func refreshFriends() async {
        guard BoraConfig.isConfigured, BoraAPI.shared.isSignedIn else { return }
        do { try await loadFriends(window: defaultWindow) }
        catch { lastSyncError = error.localizedDescription }
    }

    private func loadFriends(window: DateInterval) async throws {
        let live = try await sync.loadFriends(window: window)
        friends = live
        isLive = true
        // Keep any still-valid selection; otherwise pre-select a couple.
        let ids = Set(live.map(\.id))
        selectedFriendIDs = selectedFriendIDs.intersection(ids)
        if selectedFriendIDs.isEmpty {
            selectedFriendIDs = Set(live.prefix(2).map(\.id))
        }
    }

    /// Create a share-code token to invite a friend.
    func createInviteToken() async throws -> String {
        try await sync.createInvite()
    }

    /// Redeem a friend's invite code, then refresh the friend list.
    func redeemInvite(code: String) async throws {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw BoraError.server("Enter an invite code.") }
        try await sync.redeemInvite(token: trimmed)
        await refreshFriends()
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
