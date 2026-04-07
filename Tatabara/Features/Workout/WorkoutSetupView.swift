import SwiftUI

struct WorkoutSetupView: View {
    @Binding var preset: WorkoutPreset
    let onStart: () -> Void

    private let workValues = Array(stride(from: 10, through: 120, by: 5))
    private let restValues = Array(stride(from: 5, through: 90, by: 5))
    private let cycleValues = Array(1...50)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                pickerSection
                startButton
            }
            .padding(.horizontal, TatabaraTheme.Spacing.page)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(TatabaraTheme.ColorPalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Protocol 01")
                    .font(TatabaraFont.body(11, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                    .tracking(3)
                    .textCase(.uppercase)

                Text("New Workout")
                    .font(TatabaraFont.headline(40, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)
                    .textCase(.uppercase)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Est. Time")
                    .font(TatabaraFont.body(10, weight: .semibold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                    .tracking(1.8)
                    .textCase(.uppercase)

                Text(Self.durationFormatter.string(from: preset.estimatedTotalDuration) ?? "00:00")
                    .font(TatabaraFont.headline(24, weight: .semibold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.primary)
            }
        }
    }

    private var pickerSection: some View {
        HStack(spacing: 12) {
            ValueStepperColumn(
                title: "Workout",
                unitLabel: "Sec",
                accent: TatabaraTheme.ColorPalette.primary,
                values: workValues,
                selection: $preset.workDurationSeconds
            )

            ValueStepperColumn(
                title: "Rest",
                unitLabel: "Sec",
                accent: TatabaraTheme.ColorPalette.secondary,
                values: restValues,
                selection: $preset.restDurationSeconds
            )

            ValueStepperColumn(
                title: "Cycles",
                unitLabel: "Sets",
                accent: TatabaraTheme.ColorPalette.tertiary,
                values: cycleValues,
                selection: $preset.cycleCount
            )
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 12) {
                Text("Initialize Workout")
                    .font(TatabaraFont.headline(22, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)

                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color(red: 59 / 255, green: 74 / 255, blue: 0))
            .frame(maxWidth: .infinity)
            .frame(height: 80)
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
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .tatabaraGlow()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("initialize-workout-button")
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
}

#Preview {
    NavigationStack {
        WorkoutSetupView(
            preset: .constant(.default),
            onStart: {}
        )
    }
}
