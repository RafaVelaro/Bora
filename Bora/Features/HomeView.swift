import SwiftUI

/// "Today" overview: your free time for the selected day, plus a highlight of
/// when your selected friends are all free.
struct HomeView: View {
    @EnvironmentObject private var calendar: CalendarStore
    @EnvironmentObject private var app: AppModel

    @State private var selectedDay = Calendar.current.startOfDay(for: Date())

    private var days: [Date] { DateUtils.next(7) }

    private var window: DateInterval { Availability.dayWindow(for: selectedDay) }

    private var myFreeToday: [DateInterval] {
        Availability.freeSlots(in: window, busy: calendar.busy(on: selectedDay))
    }

    private var commonSlots: [FreeSlot] {
        Availability.commonFreeSlots(in: window,
                                     me: calendar.busy(on: selectedDay),
                                     friends: app.selectedFriends)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    DayStrip(days: days, selection: $selectedDay)

                    VStack(spacing: Theme.Spacing.lg) {
                        bestTimeCard
                        myFreeCard
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Bora")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Cards

    private var bestTimeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    SectionHeader(title: "Free together",
                                  subtitle: subtitleForSelectedFriends)
                    Spacer()
                }

                if app.selectedFriends.isEmpty {
                    EmptyStateView(systemImage: "person.2",
                                   title: "Pick some friends",
                                   message: "Choose friends in the Find Time tab to see when you're all free.")
                } else if let best = commonSlots.max(by: { $0.duration < $1.duration }) {
                    HStack(spacing: Theme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(best.interval.timeRangeLabel())
                                .font(.title2.bold())
                                .foregroundStyle(Theme.Palette.ink)
                            Text("\(DateUtils.relativeDayLabel(selectedDay)) · everyone's free")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                        }
                        Spacer()
                        TagPill(text: best.duration.shortDuration,
                                fg: Theme.Palette.mint, bg: Theme.Palette.mintSoft)
                    }

                    if commonSlots.count > 1 {
                        Text("+\(commonSlots.count - 1) more window\(commonSlots.count - 1 == 1 ? "" : "s") today")
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                    }
                } else {
                    EmptyStateView(systemImage: "calendar.badge.exclamationmark",
                                   title: "No shared free time",
                                   message: "Nobody overlaps on \(DateUtils.relativeDayLabel(selectedDay)). Try another day.")
                }
            }
        }
    }

    private var myFreeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Your free time",
                              subtitle: DateUtils.relativeDayLabel(selectedDay))

                if myFreeToday.isEmpty {
                    EmptyStateView(systemImage: "moon.zzz",
                                   title: "Fully booked",
                                   message: "You have no open slots in your plannable hours on this day.")
                } else {
                    ForEach(myFreeToday, id: \.start) { slot in
                        HStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.Palette.mint)
                                .frame(width: 4, height: 28)
                            Text(slot.timeRangeLabel())
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            Text(slot.duration.shortDuration)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                        }
                    }
                }
            }
        }
    }

    private var subtitleForSelectedFriends: String {
        let names = app.selectedFriends.map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
        switch names.count {
        case 0: return "No friends selected"
        case 1: return "with \(names[0])"
        case 2: return "with \(names[0]) & \(names[1])"
        default: return "with \(names[0]), \(names[1]) +\(names.count - 2)"
        }
    }
}
