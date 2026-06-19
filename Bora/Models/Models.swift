import Foundation

/// A person you can plan with. For now these are local/mock; later they'll be
/// backed by the sharing server and real synced calendars.
struct Friend: Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Two-letter initials shown in the avatar.
    var initials: String
    /// Index into `Theme.Palette.avatarTints`.
    var colorIndex: Int
    /// Busy blocks pulled from this friend's shared calendar (mock for now).
    var busy: [DateInterval]

    init(id: UUID = UUID(), name: String, colorIndex: Int, busy: [DateInterval]) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.busy = busy
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        self.initials = (first + last).uppercased()
    }
}

/// The "me" participant, sourced from the device calendar.
struct MyAvailability {
    var busy: [DateInterval]
}

/// A get-together proposed for a chosen subset of friends.
struct Plan: Identifiable, Hashable {
    let id: String
    var title: String
    var interval: DateInterval
    var creatorID: String
    var guestIDs: [UUID]
    var isMine: Bool

    var start: Date { interval.start }
}

/// A window of free time, optionally shared by several people.
struct FreeSlot: Identifiable, Hashable {
    let id = UUID()
    var interval: DateInterval
    /// Friend ids who are free during this slot (excludes "me").
    var participantIDs: Set<UUID>

    var start: Date { interval.start }
    var end: Date { interval.end }
    var duration: TimeInterval { interval.duration }
}
