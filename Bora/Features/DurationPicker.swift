import SwiftUI

/// Horizontal pills to choose the minimum "free together" duration.
struct DurationPicker: View {
    @Binding var selection: Int   // minutes

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Free together for at least")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.Palette.inkSecondary)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(AppModel.durationPresets, id: \.self) { minutes in
                        let isOn = selection == minutes
                        Button {
                            selection = minutes
                        } label: {
                            Text(TimeInterval(minutes * 60).shortDuration)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isOn ? .white : Theme.Palette.ink)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(isOn ? Theme.Palette.primary : Theme.Palette.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.Palette.stroke,
                                                          lineWidth: isOn ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
}
