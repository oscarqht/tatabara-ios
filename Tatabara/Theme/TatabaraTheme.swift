import SwiftUI

enum TatabaraTheme {
    enum ColorPalette {
        static let background = Color(red: 14 / 255, green: 14 / 255, blue: 14 / 255)
        static let surfaceLowest = Color.black
        static let surfaceLow = Color(red: 19 / 255, green: 19 / 255, blue: 19 / 255)
        static let surfaceHigh = Color(red: 32 / 255, green: 31 / 255, blue: 31 / 255)
        static let surfaceHighest = Color(red: 38 / 255, green: 38 / 255, blue: 38 / 255)
        static let primary = Color(red: 244 / 255, green: 1.0, blue: 200 / 255)
        static let primaryGlow = Color(red: 207 / 255, green: 252 / 255, blue: 0)
        static let secondary = Color(red: 0, green: 244 / 255, blue: 254 / 255)
        static let tertiary = Color(red: 255 / 255, green: 238 / 255, blue: 171 / 255)
        static let error = Color(red: 1.0, green: 115 / 255, blue: 81 / 255)
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 173 / 255, green: 170 / 255, blue: 170 / 255)
        static let outline = Color(red: 73 / 255, green: 72 / 255, blue: 71 / 255)
    }

    enum Spacing {
        static let page: CGFloat = 20
        static let card: CGFloat = 24
        static let control: CGFloat = 16
    }

    enum Radius {
        static let card: CGFloat = 30
        static let pill: CGFloat = 999
        static let control: CGFloat = 24
    }
}

enum TatabaraFont {
    static func headline(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Space Grotesk", size: size).weight(weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }
}

struct TatabaraGlowModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.22), radius: 24, x: 0, y: 8)
            .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 0)
    }
}

extension View {
    func tatabaraCardStyle() -> some View {
        self
            .padding(TatabaraTheme.Spacing.card)
            .background(
                LinearGradient(
                    colors: [
                        TatabaraTheme.ColorPalette.surfaceHigh.opacity(0.92),
                        TatabaraTheme.ColorPalette.surfaceLow.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: TatabaraTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TatabaraTheme.Radius.card, style: .continuous)
                    .stroke(TatabaraTheme.ColorPalette.primary.opacity(0.08), lineWidth: 1)
            )
    }

    func tatabaraGlassStyle() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.24))
            .background(TatabaraTheme.ColorPalette.surfaceHighest.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: TatabaraTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TatabaraTheme.Radius.card, style: .continuous)
                    .stroke(TatabaraTheme.ColorPalette.primary.opacity(0.1), lineWidth: 1)
            )
    }

    func tatabaraGlow(_ color: Color = TatabaraTheme.ColorPalette.primary) -> some View {
        modifier(TatabaraGlowModifier(color: color))
    }
}
