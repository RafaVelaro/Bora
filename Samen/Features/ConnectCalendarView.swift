import SwiftUI

/// First-run screen: explain the value, then connect the device calendar.
struct ConnectCalendarView: View {
    @EnvironmentObject private var calendar: CalendarStore

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.primarySoft)
                        .frame(width: 120, height: 120)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(Theme.Palette.primary)
                }

                Text("Plan time together,\nnot in the group chat")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.ink)

                Text("Samen reads only your busy times to find when you and your friends are all free. Your event details always stay private.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                ForEach(features, id: \.title) { item in
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.primary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Palette.ink)
                            Text(item.detail)
                                .font(.footnote)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)

            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    Task { await calendar.requestAccess() }
                } label: {
                    Text("Connect my calendar")
                }
                .buttonStyle(PrimaryButtonStyle())

                if calendar.access == .denied {
                    Text("Calendar access is off. Enable it in Settings › Samen to see your real availability.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.Palette.busy)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.background.ignoresSafeArea())
    }

    private let features: [(icon: String, title: String, detail: String)] = [
        ("lock.fill", "Private by design", "We never read titles, locations, or guests."),
        ("person.2.fill", "See friends' free time", "Overlap calendars in one tap."),
        ("sparkles", "Find the moment", "The app suggests when you can all meet.")
    ]
}
