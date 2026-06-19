import SwiftUI

/// Horizontal scrollable day selector used at the top of Home and Find Time.
struct DayStrip: View {
    let days: [Date]
    @Binding var selection: Date

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(days, id: \.self) { day in
                    let isSelected = calendar.isDate(day, inSameDayAs: selection)
                    Button {
                        selection = day
                    } label: {
                        VStack(spacing: 4) {
                            Text(DateUtils.weekday(day))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Theme.Palette.inkSecondary)
                            Text(DateUtils.dayNumber(day))
                                .font(.headline)
                                .foregroundStyle(isSelected ? .white : Theme.Palette.ink)
                        }
                        .frame(width: 52, height: 64)
                        .background(isSelected ? Theme.Palette.primary : Theme.Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .stroke(Theme.Palette.stroke, lineWidth: isSelected ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
