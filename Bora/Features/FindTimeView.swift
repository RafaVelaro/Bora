import SwiftUI

/// The heart of the app: pick friends, and see every window where you're all
/// free across the next week.
struct FindTimeView: View {
    @EnvironmentObject private var calendar: CalendarStore
    @EnvironmentObject private var app: AppModel

    private var days: [Date] { DateUtils.next(7) }

    /// Common free slots per day, dropping days with no overlap.
    private var slotsByDay: [(day: Date, slots: [FreeSlot])] {
        days.compactMap { day in
            let window = Availability.dayWindow(for: day)
            let slots = Availability.commonFreeSlots(in: window,
                                                     me: calendar.busy(on: day),
                                                     friends: app.selectedFriends,
                                                     minDuration: app.minDuration)
            return slots.isEmpty ? nil : (day, slots)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    friendSelector
                    DurationPicker(selection: $app.minMeetMinutes)

                    if app.selectedFriends.isEmpty {
                        Card {
                            EmptyStateView(systemImage: "person.2.circle",
                                           title: "Select friends to begin",
                                           message: "Tap people above to overlap your calendars.")
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    } else if slotsByDay.isEmpty {
                        Card {
                            EmptyStateView(systemImage: "calendar.badge.exclamationmark",
                                           title: "No shared free time this week",
                                           message: "Try removing a friend or widening your plannable hours.")
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    } else {
                        ForEach(slotsByDay, id: \.day) { entry in
                            daySection(day: entry.day, slots: entry.slots)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Find Time")
        }
    }

    // MARK: Friend selector

    private var friendSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(app.friends) { friend in
                    let isOn = app.selectedFriendIDs.contains(friend.id)
                    Button {
                        app.toggle(friend)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(initials: friend.initials,
                                           tint: app.tint(for: friend),
                                           size: 56)
                                    .opacity(isOn ? 1 : 0.4)
                                if isOn {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Palette.mint)
                                        .background(Circle().fill(.white))
                                }
                            }
                            Text(friend.name.split(separator: " ").first.map(String.init) ?? friend.name)
                                .font(.caption)
                                .foregroundStyle(isOn ? Theme.Palette.ink : Theme.Palette.inkTertiary)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: Day section

    private func daySection(day: Date, slots: [FreeSlot]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(DateUtils.relativeDayLabel(day))
                .font(.headline)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(slots) { slot in
                    SlotRow(slot: slot)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

private struct SlotRow: View {
    let slot: FreeSlot

    var body: some View {
        Card {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(Theme.Palette.primary)
                    .frame(width: 36, height: 36)
                    .background(Theme.Palette.primarySoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.interval.timeRangeLabel())
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Everyone's free")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer()
                TagPill(text: slot.duration.shortDuration,
                        fg: Theme.Palette.mint, bg: Theme.Palette.mintSoft)
            }
        }
    }
}
