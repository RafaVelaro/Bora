import SwiftUI

/// Upcoming plans — ones you created or were invited to.
struct PlansView: View {
    @EnvironmentObject private var app: AppModel

    private var upcoming: [Plan] {
        app.plans.filter { $0.interval.end >= Date() }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    if upcoming.isEmpty {
                        Card {
                            EmptyStateView(systemImage: "calendar.badge.plus",
                                           title: "No plans yet",
                                           message: "Open Find Time, tap a window you're all free, and pick who to invite.")
                        }
                    } else {
                        ForEach(upcoming) { plan in
                            PlanRowView(plan: plan)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Plans")
            .refreshable { await app.loadPlans() }
        }
    }
}

private struct PlanRowView: View {
    @EnvironmentObject private var app: AppModel
    let plan: Plan

    private var resolvableGuests: [Friend] {
        plan.guestIDs.compactMap { id in app.friends.first { $0.id == id } }
    }

    private var detail: String {
        if plan.isMine {
            let names = plan.guestIDs.map { app.name(forUserID: $0) }
            return names.isEmpty ? "Just you" : "With " + names.joined(separator: ", ")
        } else {
            let creator = UUID(uuidString: plan.creatorID).map { app.name(forUserID: $0) } ?? "A friend"
            return "\(creator) invited you"
        }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.ink)
                        Text("\(DateUtils.relativeDayLabel(plan.start)) · \(plan.interval.timeRangeLabel())")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                    }
                    Spacer()
                    TagPill(text: plan.interval.duration.shortDuration,
                            fg: Theme.Palette.mint, bg: Theme.Palette.mintSoft)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    if !resolvableGuests.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(resolvableGuests.prefix(5)) { friend in
                                AvatarView(initials: friend.initials,
                                           tint: app.tint(for: friend), size: 28)
                                    .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 2))
                            }
                        }
                    }
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
