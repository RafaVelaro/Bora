import Foundation

/// Shared date formatting + the "next N days" strip used by Home and Find Time.
enum DateUtils {
    static func next(_ count: Int, from date: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: date)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// "Today", "Tomorrow", or "Mon 23".
    static func relativeDayLabel(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = .current
        f.dateFormat = "EEE d"
        return f.string(from: date)
    }

    /// Short weekday, e.g. "Mon".
    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = .current
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    /// Day of month number, e.g. "23".
    static func dayNumber(_ date: Date, calendar: Calendar = .current) -> String {
        "\(calendar.component(.day, from: date))"
    }
}
