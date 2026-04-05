import SwiftUI

struct WatchActiveTimerView: View {
    @ObservedObject var model: TatabaraAppModel
    @ObservedObject var timerEngine: TimerEngine

    var body: some View {
        if let snapshot = timerEngine.snapshot {
            GeometryReader { proxy in
                let metrics = LayoutMetrics(containerSize: proxy.size)

                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: metrics.verticalSpacing) {
                        cycleLabel(snapshot: snapshot, metrics: metrics)
                        timerRing(snapshot: snapshot, metrics: metrics)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: metrics.contentVerticalOffset)
                    .padding(.bottom, metrics.bottomControlClearance)

                    controls(snapshot: snapshot, metrics: metrics)
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.vertical, metrics.verticalPadding)
            }
        }
    }

    private func cycleLabel(snapshot: TimerSessionSnapshot, metrics: LayoutMetrics) -> some View {
        Text("Cycle \(snapshot.currentCycle) / \(snapshot.totalCycles)")
            .font(TatabaraFont.body(metrics.phaseSubtitleSize, weight: .medium))
            .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
    }

    private func timerRing(snapshot: TimerSessionSnapshot, metrics: LayoutMetrics) -> some View {
        let accent = accentColor(for: snapshot.phase)
        let remainingProgress = snapshot.phase == .completed ? 0.0 : max(1 - snapshot.progress, 0.02)

        return ZStack {
            Circle()
                .stroke(TatabaraTheme.ColorPalette.surfaceHighest, lineWidth: metrics.ringLineWidth)

            Circle()
                .trim(from: 0, to: remainingProgress)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: metrics.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .animation(.linear(duration: 0.08), value: remainingProgress)

            VStack(spacing: metrics.innerRingSpacing) {
                Text(formattedTime(snapshot.remainingSeconds))
                    .font(TatabaraFont.headline(metrics.timerFontSize, weight: .bold))
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: snapshot.remainingSeconds))

                if snapshot.isPaused {
                    Text("Paused")
                        .font(TatabaraFont.body(metrics.pauseLabelSize, weight: .semibold))
                        .foregroundStyle(TatabaraTheme.ColorPalette.textSecondary)
                }
            }
        }
        .frame(width: metrics.ringSize, height: metrics.ringSize)
    }

    private func controls(snapshot: TimerSessionSnapshot, metrics: LayoutMetrics) -> some View {
        Group {
            if snapshot.phase == .completed {
                Button("Done") {
                    model.resetCompletedSession()
                }
                .buttonStyle(.borderedProminent)
                .tint(TatabaraTheme.ColorPalette.primary)
            } else {
                compactButton("stop.fill", tint: TatabaraTheme.ColorPalette.error, metrics: metrics) {
                    model.stopWorkout()
                }
                .padding(.trailing, metrics.controlEdgeInset)
                .padding(.bottom, metrics.controlEdgeInset)
            }
        }
    }

    private func compactButton(_ systemImage: String, tint: Color, metrics: LayoutMetrics, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: metrics.controlIconSize, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: metrics.controlSize, height: metrics.controlSize)
                .background(TatabaraTheme.ColorPalette.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: metrics.controlCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.controlCornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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

private struct LayoutMetrics {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let verticalSpacing: CGFloat
    let ringSize: CGFloat
    let ringLineWidth: CGFloat
    let timerFontSize: CGFloat
    let innerRingSpacing: CGFloat
    let pauseLabelSize: CGFloat
    let phaseSubtitleSize: CGFloat
    let contentVerticalOffset: CGFloat
    let bottomControlClearance: CGFloat
    let controlSize: CGFloat
    let controlIconSize: CGFloat
    let controlCornerRadius: CGFloat
    let controlEdgeInset: CGFloat

    init(containerSize: CGSize) {
        let compactHeight = containerSize.height <= 205
        let veryCompactHeight = containerSize.height <= 190
        let compactWidth = containerSize.width <= 184

        horizontalPadding = compactWidth ? 8 : 10
        verticalPadding = veryCompactHeight ? 6 : (compactHeight ? 8 : 12)
        verticalSpacing = veryCompactHeight ? 4 : 6
        ringSize = veryCompactHeight ? 144 : (compactHeight ? 156 : 174)
        ringLineWidth = veryCompactHeight ? 6 : 8
        timerFontSize = veryCompactHeight ? 32 : (compactHeight ? 36 : 40)
        innerRingSpacing = veryCompactHeight ? 2 : 4
        pauseLabelSize = veryCompactHeight ? 9 : 11
        phaseSubtitleSize = veryCompactHeight ? 10 : 11
        contentVerticalOffset = veryCompactHeight ? -12 : -8
        bottomControlClearance = veryCompactHeight ? 30 : 36
        controlSize = veryCompactHeight ? 30 : 34
        controlIconSize = veryCompactHeight ? 11 : 12
        controlCornerRadius = veryCompactHeight ? 15 : 17
        controlEdgeInset = veryCompactHeight ? 2 : 4
    }
}
