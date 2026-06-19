import SwiftUI

@main
struct BoraApp: App {
    @StateObject private var calendar = CalendarStore()
    @StateObject private var app = AppModel()
    @StateObject private var auth = AuthModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(calendar)
                .environmentObject(app)
                .environmentObject(auth)
        }
    }
}
