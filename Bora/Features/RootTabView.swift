import SwiftUI

/// Top-level shell. When the backend is configured, sign-in comes first; then
/// the tabs are gated behind calendar connection so the core value (your real
/// availability) is set up before anything else.
struct RootTabView: View {
    @EnvironmentObject private var calendar: CalendarStore
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var auth: AuthModel
    @State private var selection = 0

    /// Requires sign-in only when the backend is actually configured.
    private var needsSignIn: Bool {
        BoraConfig.isConfigured && !auth.isSignedIn
    }

    var body: some View {
        Group {
            if needsSignIn {
                SignInView()
            } else if calendar.access == .granted {
                tabs
            } else {
                ConnectCalendarView()
            }
        }
        .tint(Theme.Palette.primary)
        .task(id: gateKey) {
            calendar.refreshAuthorizationStatus()
            if calendar.access == .granted {
                await calendar.loadBusy(daysAhead: 14)
                await syncIfPossible()
            }
        }
    }

    /// Re-runs the task whenever sign-in or calendar access changes.
    private var gateKey: String {
        "\(auth.isSignedIn)-\(calendar.access)"
    }

    private func syncIfPossible() async {
        guard BoraConfig.isConfigured, auth.isSignedIn else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let window = DateInterval(start: start, duration: 14 * 24 * 60 * 60)
        await app.syncWithBackend(myBusy: calendar.myBusy, window: window)
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(0)
                .tabItem { Label("Today", systemImage: "calendar") }
            FindTimeView()
                .tag(1)
                .tabItem { Label("Find Time", systemImage: "sparkles") }
            PlansView()
                .tag(2)
                .tabItem { Label("Plans", systemImage: "calendar.badge.plus") }
            FriendsView()
                .tag(3)
                .tabItem { Label("Friends", systemImage: "person.2") }
        }
    }
}
