import Foundation
import SwiftUI

/// App-wide state that isn't the device calendar: the friend list and which
/// friends are currently selected for "find time". Later this is backed by the
/// sharing server.
@MainActor
final class AppModel: ObservableObject {
    @Published var friends: [Friend]
    @Published var selectedFriendIDs: Set<UUID>

    init(friends: [Friend] = MockData.sampleFriends()) {
        self.friends = friends
        // Pre-select the first couple so "Find time" shows results immediately.
        self.selectedFriendIDs = Set(friends.prefix(2).map(\.id))
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
