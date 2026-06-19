import SwiftUI

/// Turn a free-together window into a plan for a chosen subset of friends.
struct PlanSheet: View {
    let interval: DateInterval
    let candidateIDs: [UUID]

    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<UUID>
    @State private var title = ""
    @State private var creating = false
    @State private var errorMessage: String?

    init(interval: DateInterval, candidateIDs: [UUID]) {
        self.interval = interval
        self.candidateIDs = candidateIDs
        _selected = State(initialValue: Set(candidateIDs))
    }

    private var candidateFriends: [Friend] {
        app.friends.filter { candidateIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    timeCard
                    guestCard
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.busy)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("New plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.tint(Theme.Palette.inkSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await create() }
                } label: {
                    Text(creating ? "Creating…"
                         : "Plan with \(selected.count) friend\(selected.count == 1 ? "" : "s")")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(creating || selected.isEmpty)
                .padding(Theme.Spacing.md)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var timeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DateUtils.relativeDayLabel(interval.start))
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                        Text(interval.timeRangeLabel())
                            .font(.title2.bold())
                            .foregroundStyle(Theme.Palette.ink)
                    }
                    Spacer()
                    TagPill(text: interval.duration.shortDuration,
                            fg: Theme.Palette.mint, bg: Theme.Palette.mintSoft)
                }
                TextField("What's the plan? (optional)", text: $title)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Palette.background)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            }
        }
    }

    private var guestCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Who's invited?",
                              subtitle: "Tap to include only the friends you want.")
                ForEach(candidateFriends) { friend in
                    let isOn = selected.contains(friend.id)
                    Button {
                        if isOn { selected.remove(friend.id) } else { selected.insert(friend.id) }
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            AvatarView(initials: friend.initials,
                                       tint: app.tint(for: friend), size: 38)
                            Text(friend.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isOn ? Theme.Palette.primary : Theme.Palette.inkTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func create() async {
        creating = true; errorMessage = nil
        defer { creating = false }
        do {
            try await app.createPlan(title: title,
                                     interval: interval,
                                     guestIDs: Array(selected))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
