import SwiftUI

/// Top-level shell. Gates the tabs behind calendar connection so the core
/// value (your real availability) is set up before anything else.
struct RootTabView: View {
    @EnvironmentObject private var calendar: CalendarStore

    var body: some View {
        Group {
            if calendar.access == .granted {
                tabs
            } else {
                ConnectCalendarView()
            }
        }
        .tint(Theme.Palette.primary)
        .task {
            // Refresh status when returning from Settings, and load events.
            calendar.refreshAuthorizationStatus()
            if calendar.access == .granted {
                await calendar.loadBusy(daysAhead: 14)
            }
        }
    }

    private var tabs: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "calendar") }
            FindTimeView()
                .tabItem { Label("Find Time", systemImage: "sparkles") }
            FriendsView()
                .tabItem { Label("Friends", systemImage: "person.2") }
        }
    }
}
