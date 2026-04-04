import SwiftUI

struct PlaceholderScreen: View {
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TatabaraTheme.ColorPalette.background,
                    TatabaraTheme.ColorPalette.surfaceLowest
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(eyebrow)
                    .font(TatabaraFont.body(12, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                    .tracking(3)
                    .textCase(.uppercase)

                Text(title)
                    .font(TatabaraFont.headline(44, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)
                    .textCase(.uppercase)

                Text(message)
                    .font(TatabaraFont.body(17, weight: .medium))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(28)
        }
    }
}
