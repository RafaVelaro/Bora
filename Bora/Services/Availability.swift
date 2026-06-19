import Foundation

/// Pure functions for turning busy blocks into free slots and overlapping them
/// across people. No UIKit / EventKit here so this stays trivially testable.
enum Availability {

    /// The hours of the day we consider "plannable" (default 08:00–23:00).
    static let dayStartHour = 8
    static let dayEndHour = 23

    /// Minimum length a gap must have to count as a usable free slot.
    static let minSlot: TimeInterval = 30 * 60

    /// Merge overlapping / touching intervals into a clean, sorted list.
    static func normalize(_ intervals: [DateInterval]) -> [DateInterval] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DateInterval] = [sorted[0]]
        for current in sorted.dropFirst() {
            let last = merged[merged.count - 1]
            if current.start <= last.end {
                let newEnd = max(last.end, current.end)
                merged[merged.count - 1] = DateInterval(start: last.start, end: newEnd)
            } else {
                merged.append(current)
            }
        }
        return merged
    }

    /// Free slots for a single person within `window`, given their busy blocks.
    static func freeSlots(in window: DateInterval,
                          busy: [DateInterval],
                          minDuration: TimeInterval = minSlot) -> [DateInterval] {
        // Clip busy blocks to the window and merge them.
        let clipped = busy.compactMap { $0.intersection(with: window) }
        let blocks = normalize(clipped)

        var slots: [DateInterval] = []
        var cursor = window.start
        for block in blocks {
            if block.start > cursor {
                let gap = DateInterval(start: cursor, end: block.start)
                if gap.duration >= minDuration { slots.append(gap) }
            }
            cursor = max(cursor, block.end)
        }
        if cursor < window.end {
            let gap = DateInterval(start: cursor, end: window.end)
            if gap.duration >= minDuration { slots.append(gap) }
        }
        return slots
    }

    /// The plannable window for a given calendar day.
    static func dayWindow(for date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: date) ?? date
        let end = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: date) ?? date
        return DateInterval(start: start, end: max(end, start))
    }

    /// Intersect everyone's free time within `window` and return common slots.
    /// `me` is always required; each friend's free time is intersected in turn.
    static func commonFreeSlots(in window: DateInterval,
                                me: [DateInterval],
                                friends: [Friend],
                                minDuration: TimeInterval = minSlot) -> [FreeSlot] {
        var running = freeSlots(in: window, busy: me, minDuration: 0)
        for friend in friends {
            let theirs = freeSlots(in: window, busy: friend.busy, minDuration: 0)
            running = intersect(running, theirs)
            if running.isEmpty { break }
        }
        return running
            .filter { $0.duration >= minDuration }
            .map { FreeSlot(interval: $0, participantIDs: Set(friends.map(\.id))) }
    }

    /// Intersection of two lists of intervals (both assumed sorted & merged).
    static func intersect(_ a: [DateInterval], _ b: [DateInterval]) -> [DateInterval] {
        var result: [DateInterval] = []
        var i = 0, j = 0
        while i < a.count && j < b.count {
            if let overlap = a[i].intersection(with: b[j]), overlap.duration > 0 {
                result.append(overlap)
            }
            if a[i].end < b[j].end { i += 1 } else { j += 1 }
        }
        return result
    }
}

// MARK: - Formatting helpers

extension TimeInterval {
    /// "1h 30m", "45m", "2h".
    var shortDuration: String {
        let totalMinutes = Int(self / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)m"
        case (_, 0): return "\(h)h"
        default: return "\(h)h \(m)m"
        }
    }
}

extension DateInterval {
    /// "13:00 – 15:30"
    func timeRangeLabel(calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = .current
        f.dateFormat = "HH:mm"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}
