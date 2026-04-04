import SwiftUI

struct ValueStepperColumn: View {
    let title: String
    let unitLabel: String
    let accent: Color
    let values: [Int]
    @Binding var selection: Int

    private var currentIndex: Int {
        values.firstIndex(of: selection) ?? 0
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(title)
                    .font(TatabaraFont.body(11, weight: .bold))
                    .foregroundStyle(accent)
                    .tracking(1.8)
                    .textCase(.uppercase)

                Text(unitLabel)
                    .font(TatabaraFont.body(9, weight: .medium))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary.opacity(0.55))
                    .tracking(1.6)
                    .textCase(.uppercase)
            }

            button(systemImage: "minus") {
                moveSelection(-1)
            }

            VStack(spacing: 12) {
                ForEach(visibleValues, id: \.self) { value in
                    Text(formattedValue(value))
                        .font(value == selection ? TatabaraFont.headline(46, weight: .bold) : TatabaraFont.headline(30, weight: .medium))
                        .foregroundStyle(color(for: value))
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText(value: Double(value)))
                        .accessibilityIdentifier("\(title.lowercased())-value-\(value)")
                }
            }
            .frame(maxHeight: .infinity)

            button(systemImage: "plus") {
                moveSelection(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 360)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(TatabaraTheme.ColorPalette.surfaceLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(TatabaraTheme.ColorPalette.outline.opacity(0.18), lineWidth: 1)
        )
    }

    private var visibleValues: [Int] {
        let lowerBound = max(currentIndex - 2, 0)
        let upperBound = min(currentIndex + 2, values.count - 1)
        return Array(values[lowerBound...upperBound])
    }

    private func button(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(TatabaraTheme.ColorPalette.surfaceHighest)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func moveSelection(_ delta: Int) {
        let nextIndex = min(max(currentIndex + delta, 0), values.count - 1)
        selection = values[nextIndex]
    }

    private func formattedValue(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    private func color(for value: Int) -> Color {
        if value == selection {
            return accent
        }

        let distance = abs(value - selection)
        switch distance {
        case 0:
            return accent
        case 1...4:
            return TatabaraTheme.ColorPalette.textSecondary.opacity(0.55)
        default:
            return TatabaraTheme.ColorPalette.textSecondary.opacity(0.2)
        }
    }
}
