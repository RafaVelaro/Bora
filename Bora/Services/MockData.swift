import Foundation

/// Sample friends with plausible busy schedules so the overlap features are
/// demoable before the sharing backend exists. All times are generated
/// relative to "today" so the app always shows something live.
enum MockData {

    static func sampleFriends(calendar: Calendar = .current) -> [Friend] {
        let today = calendar.startOfDay(for: Date())

        func block(dayOffset: Int, startHour: Int, startMin: Int = 0,
                   durationMinutes: Int) -> DateInterval {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let start = calendar.date(bySettingHour: startHour, minute: startMin, second: 0, of: base) ?? base
            return DateInterval(start: start, duration: TimeInterval(durationMinutes * 60))
        }

        return [
            Friend(name: "Sanne de Vries", colorIndex: 0, busy: [
                block(dayOffset: 0, startHour: 9, durationMinutes: 180),
                block(dayOffset: 0, startHour: 18, durationMinutes: 90),
                block(dayOffset: 1, startHour: 10, durationMinutes: 120),
                block(dayOffset: 2, startHour: 9, durationMinutes: 480)
            ]),
            Friend(name: "Daan Jansen", colorIndex: 1, busy: [
                block(dayOffset: 0, startHour: 8, durationMinutes: 120),
                block(dayOffset: 0, startHour: 14, durationMinutes: 60),
                block(dayOffset: 1, startHour: 13, durationMinutes: 240),
                block(dayOffset: 2, startHour: 19, durationMinutes: 120)
            ]),
            Friend(name: "Emma Bakker", colorIndex: 2, busy: [
                block(dayOffset: 0, startHour: 12, durationMinutes: 90),
                block(dayOffset: 1, startHour: 9, durationMinutes: 60),
                block(dayOffset: 1, startHour: 18, durationMinutes: 120),
                block(dayOffset: 2, startHour: 10, durationMinutes: 120)
            ]),
            Friend(name: "Lars Visser", colorIndex: 3, busy: [
                block(dayOffset: 0, startHour: 10, durationMinutes: 60),
                block(dayOffset: 0, startHour: 20, durationMinutes: 60),
                block(dayOffset: 1, startHour: 15, durationMinutes: 90),
                block(dayOffset: 2, startHour: 14, durationMinutes: 180)
            ]),
            Friend(name: "Fleur Smit", colorIndex: 4, busy: [
                block(dayOffset: 0, startHour: 9, durationMinutes: 60),
                block(dayOffset: 1, startHour: 11, durationMinutes: 120),
                block(dayOffset: 2, startHour: 9, durationMinutes: 90)
            ])
        ]
    }

    /// A stand-in busy schedule for "me", used only for SwiftUI previews and
    /// before real calendar access is granted.
    static func sampleMyBusy(calendar: Calendar = .current) -> [DateInterval] {
        let today = calendar.startOfDay(for: Date())
        func block(dayOffset: Int, startHour: Int, durationMinutes: Int) -> DateInterval {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: base) ?? base
            return DateInterval(start: start, duration: TimeInterval(durationMinutes * 60))
        }
        return [
            block(dayOffset: 0, startHour: 9, durationMinutes: 120),
            block(dayOffset: 0, startHour: 15, durationMinutes: 60),
            block(dayOffset: 1, startHour: 9, durationMinutes: 240),
            block(dayOffset: 2, startHour: 13, durationMinutes: 120)
        ]
    }
}
