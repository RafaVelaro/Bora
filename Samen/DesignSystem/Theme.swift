import SwiftUI

/// Central design tokens for Samen — colors, typography, spacing, radii.
/// Keeping these in one place makes it trivial to retune the look later.
enum Theme {

    // MARK: Colors

    enum Palette {
        /// Dutch-orange primary accent.
        static let primary = Color(hex: 0xFF6F4E)
        static let primarySoft = Color(hex: 0xFFE4DC)
        /// Secondary accent for "free / available" states.
        static let mint = Color(hex: 0x2BB673)
        static let mintSoft = Color(hex: 0xDDF3E8)
        /// Busy / blocked state.
        static let busy = Color(hex: 0xE9536B)
        static let busySoft = Color(hex: 0xFBE0E5)

        static let ink = Color(hex: 0x1C1B2E)
        static let inkSecondary = Color(hex: 0x6A6880)
        static let inkTertiary = Color(hex: 0x9C9AB0)

        static let background = Color(hex: 0xF7F6FB)
        static let surface = Color.white
        static let stroke = Color(hex: 0xECEAF3)

        /// Friendly avatar tints, cycled by index.
        static let avatarTints: [Color] = [
            Color(hex: 0xFF6F4E),
            Color(hex: 0x5B8DEF),
            Color(hex: 0x2BB673),
            Color(hex: 0xF2A93B),
            Color(hex: 0x9B6DEF),
            Color(hex: 0xEF6D9B)
        ]
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Radii

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let pill: CGFloat = 999
    }
}

// MARK: - Color hex helper

extension Color {
    /// Initialise from a 24-bit hex value, e.g. `Color(hex: 0xFF6F4E)`.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Reusable view styling

/// Soft card container used throughout the app.
struct Card<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Palette.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

/// Primary call-to-action button style.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.Palette.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
