import SwiftUI

struct ActiveTimerView: View {
    @ObservedObject var timerEngine: TimerEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TatabaraTheme.ColorPalette.background.ignoresSafeArea()

            if let snapshot = timerEngine.snapshot {
                VStack(spacing: 28) {
                    sessionHeader(snapshot: snapshot)
                    timerRing(snapshot: snapshot)
                    nextUpCard(snapshot: snapshot)
                    controlBar(snapshot: snapshot)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: timerEngine.snapshot?.phase, initial: true) { _, phase in
            if phase == .completed || timerEngine.snapshot == nil {
                dismiss()
            }
        }
    }

    private func sessionHeader(snapshot: TimerSessionSnapshot) -> some View {
        VStack(spacing: 10) {
            Text("Current Session")
                .font(TatabaraFont.body(11, weight: .bold))
                .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                .tracking(3)
                .textCase(.uppercase)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("Cycle \(snapshot.currentCycle)")
                    .font(TatabaraFont.headline(44, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.primary)

                Text("/ \(snapshot.totalCycles)")
                    .font(TatabaraFont.headline(22, weight: .light))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
            }
        }
        .padding(.top, 12)
    }

    private func timerRing(snapshot: TimerSessionSnapshot) -> some View {
        let accent = accentColor(for: snapshot.phase)
        let remainingProgress = snapshot.phase == .completed ? 0.0 : max(1 - snapshot.progress, 0.02)

        return ZStack {
            Circle()
                .stroke(TatabaraTheme.ColorPalette.surfaceHighest, lineWidth: 10)

            Circle()
                .trim(from: 0, to: remainingProgress)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .animation(.linear(duration: 0.08), value: remainingProgress)
                .tatabaraGlow(accent)

            VStack(spacing: 10) {
                Text(snapshot.phase.title)
                    .font(TatabaraFont.body(11, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                    .tracking(3)
                    .textCase(.uppercase)

                Text(formattedTime(snapshot.remainingSeconds))
                    .font(TatabaraFont.headline(88, weight: .bold))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText(value: snapshot.remainingSeconds))
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .tatabaraGlow(accent)

                if snapshot.isPaused {
                    Text("Paused")
                        .font(TatabaraFont.body(13, weight: .semibold))
                        .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                }
            }
        }
        .frame(maxWidth: 340)
        .aspectRatio(1, contentMode: .fit)
        .padding(.top, 6)
    }

    private func nextUpCard(snapshot: TimerSessionSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Next Up")
                    .font(TatabaraFont.body(11, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                    .tracking(2)
                    .textCase(.uppercase)

                Text(snapshot.nextPhase?.title ?? "Complete")
                    .font(TatabaraFont.headline(28, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textPrimary)
                    .textCase(.uppercase)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Duration")
                    .font(TatabaraFont.body(11, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                    .tracking(2)
                    .textCase(.uppercase)

                Text(formattedTime(snapshot.nextPhaseDuration ?? 0))
                    .font(TatabaraFont.headline(28, weight: .bold))
                    .foregroundStyle(TatabaraTheme.ColorPalette.secondary)
                    .textCase(.uppercase)
            }
        }
        .tatabaraCardStyle()
    }

    private func controlBar(snapshot: TimerSessionSnapshot) -> some View {
        HStack(spacing: 24) {
            SmallControlButton(
                systemImage: "arrow.counterclockwise",
                tint: TatabaraTheme.ColorPalette.secondary,
                action: { timerEngine.restartCurrentPhase() }
            )
            .accessibilityIdentifier("restart-phase-button")

            Button {
                timerEngine.togglePauseResume()
            } label: {
                Image(systemName: snapshot.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Color(red: 83 / 255, green: 102 / 255, blue: 0))
                    .frame(width: 92, height: 92)
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
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .tatabaraGlow()
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("pause-resume-button")

            SmallControlButton(
                systemImage: "stop.fill",
                tint: TatabaraTheme.ColorPalette.error,
                action: timerEngine.stop
            )
            .accessibilityIdentifier("stop-session-button")
        }
        .padding(.top, 6)
    }

    private func accentColor(for phase: TimerPhase) -> Color {
        switch phase {
        case .work:
            TatabaraTheme.ColorPalette.primary
        case .rest:
            TatabaraTheme.ColorPalette.secondary
        case .completed:
            TatabaraTheme.ColorPalette.tertiary
        }
    }

    private func formattedTime(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded(.up))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct SmallControlButton: View {
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 64, height: 64)
                .background(TatabaraTheme.ColorPalette.surfaceLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ActiveTimerView(timerEngine: TimerEngine())
    }
}
