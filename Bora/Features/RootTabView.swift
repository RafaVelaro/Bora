import SwiftUI

/// Top-level shell. Gates the tabs behind calendar connection so the core
/// value (your real availability) is set up before anything else.
struct RootTabView: View {
    @EnvironmentObject private var calendar: CalendarStore
    @State private var selection = 0

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
        TabView(selection: $selection) {
            HomeView()
                .tag(0)
                .tabItem { Label("Today", systemImage: "calendar") }
            FindTimeView()
                .tag(1)
                .tabItem { Label("Find Time", systemImage: "sparkles") }
            FriendsView()
                .tag(2)
                .tabItem { Label("Friends", systemImage: "person.2") }
        }
    }
}
