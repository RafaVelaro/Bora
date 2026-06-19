import Foundation
import EventKit
import SwiftUI

/// Owns access to the device calendar (EventKit) and exposes the user's busy
/// blocks. This is the "connect your real calendar" half of the core feature.
@MainActor
final class CalendarStore: ObservableObject {

    enum Access: Equatable {
        case notDetermined
        case denied
        case granted
    }

    @Published var access: Access = .notDetermined
    @Published var myBusy: [DateInterval] = []
    @Published var isLoading = false

    private let store = EKEventStore()

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly, .authorized:
            access = .granted
        case .denied, .restricted:
            access = .denied
        case .notDetermined:
            access = .notDetermined
        @unknown default:
            access = .notDetermined
        }
    }

    /// Ask for calendar permission (iOS 17+ full-access prompt).
    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            access = granted ? .granted : .denied
            if granted {
                await loadBusy(daysAhead: 14)
            }
        } catch {
            access = .denied
        }
    }

    /// Pull events for the next `daysAhead` days and reduce them to busy blocks.
    func loadBusy(daysAhead: Int = 14) async {
        guard access == .granted else { return }
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: daysAhead, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        let blocks: [DateInterval] = events.compactMap { event in
            // Skip events the user marked as "free" / available.
            guard event.availability != .free else { return nil }
            guard event.endDate > event.startDate else { return nil }
            return DateInterval(start: event.startDate, end: event.endDate)
        }
        myBusy = Availability.normalize(blocks)
    }

    /// Busy blocks limited to a single day's plannable window.
    func busy(on date: Date) -> [DateInterval] {
        let window = Availability.dayWindow(for: date)
        return myBusy.compactMap { $0.intersection(with: window) }
    }
}
