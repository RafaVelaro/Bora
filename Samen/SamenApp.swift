import SwiftUI

@main
struct SamenApp: App {
    @StateObject private var calendar = CalendarStore()
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(calendar)
                .environmentObject(app)
        }
    }
}
