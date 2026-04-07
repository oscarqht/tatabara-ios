import SwiftUI

struct WatchWorkoutSetupView: View {
    private enum FocusTarget: Hashable {
        case work
        case rest
        case cycles
    }

    @ObservedObject var model: TatabaraAppModel
    @FocusState private var focusedControl: FocusTarget?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                header
                stepperCard(
                    title: "Work",
                    value: model.preset.workDurationSeconds,
                    range: 10...120,
                    step: 5,
                    focusTarget: .work,
                    tint: TatabaraTheme.ColorPalette.primary
                ) { model.preset.workDurationSeconds = $0 }
                stepperCard(
                    title: "Rest",
                    value: model.preset.restDurationSeconds,
                    range: 5...90,
                    step: 5,
                    focusTarget: .rest,
                    tint: TatabaraTheme.ColorPalette.secondary
                ) { model.preset.restDurationSeconds = $0 }
                stepperCard(
                    title: "Cycles",
                    value: model.preset.cycleCount,
                    range: 1...50,
                    step: 1,
                    focusTarget: .cycles,
                    tint: TatabaraTheme.ColorPalette.tertiary
                ) { model.preset.cycleCount = $0 }
                startButton
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .onAppear {
            // Prevent watchOS from restoring Digital Crown input to the last
            // focused stepper when returning from the active workout screen.
            DispatchQueue.main.async {
                focusedControl = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tatabara")
                .font(TatabaraFont.body(10, weight: .bold))
                .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                .tracking(2)
                .textCase(.uppercase)

            Text("Watch HIIT")
                .font(TatabaraFont.headline(24, weight: .bold))
                .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)

            Text("Total \(formattedTime(model.preset.estimatedTotalDuration))")
                .font(TatabaraFont.body(12, weight: .semibold))
                .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
        }
        .padding(.bottom, 4)
    }

    private func stepperCard(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        focusTarget: FocusTarget,
        tint: Color,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(TatabaraFont.body(12, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(value)")
                    .font(TatabaraFont.headline(20, weight: .bold))
                    .foregroundStyle(tint)
            }

            Stepper(value: Binding(
                get: { value },
                set: onChange
            ), in: range, step: step) {
                Text(step == 1 ? "Adjust sets" : "Adjust in \(step)s")
                    .font(TatabaraFont.body(11, weight: .medium))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)
            }
            .tint(tint)
            .focused($focusedControl, equals: focusTarget)
        }
        .padding(12)
        .background(TatabaraTheme.ColorPalette.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    private var startButton: some View {
        Button {
            Task {
                await model.startWorkout()
            }
        } label: {
            Text("Start Workout")
                .font(TatabaraFont.body(13, weight: .bold))
                .foregroundStyle(Color(red: 59 / 255, green: 74 / 255, blue: 0))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            TatabaraTheme.ColorPalette.primaryGlow,
                            TatabaraTheme.ColorPalette.primary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private func formattedTime(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
