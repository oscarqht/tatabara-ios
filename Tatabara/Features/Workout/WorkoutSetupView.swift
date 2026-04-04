import SwiftUI

struct WorkoutSetupView: View {
    @Binding var preset: WorkoutPreset
    let onStart: () -> Void

    private let workValues = Array(stride(from: 10, through: 120, by: 5))
    private let restValues = Array(stride(from: 5, through: 90, by: 5))
    private let cycleValues = Array(1...20)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                pickerSection
                intensityCard
                startButton
            }
            .padding(.horizontal, TatabaraTheme.Spacing.page)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(TatabaraTheme.ColorPalette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(TatabaraTheme.ColorPalette.primary)
            }

            ToolbarItem(placement: .principal) {
                Text("Tatabara")
                    .font(TatabaraFont.headline(22, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(TatabaraTheme.ColorPalette.primary)
            }
        }
        .toolbarBackground(TatabaraTheme.ColorPalette.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TatabaraTheme.ColorPalette.secondary.opacity(0.22))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensity Profile")
                        .font(TatabaraFont.headline(20, weight: .bold))
                        .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)
                        .textCase(.uppercase)

                    Text("High-intensity interval training designed for fast transitions and crisp cues.")
                        .font(TatabaraFont.body(13, weight: .medium))
                        .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(preset.intensityBars.enumerated()), id: \.offset) { _, height in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(height > 0.21 ? TatabaraTheme.ColorPalette.primary : TatabaraTheme.ColorPalette.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: CGFloat(26 + (height * 60)))
                }
            }
            .frame(height: 96, alignment: .bottom)
        }
        .tatabaraGlassStyle()
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
