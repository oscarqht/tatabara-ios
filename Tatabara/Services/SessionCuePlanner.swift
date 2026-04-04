import Foundation

enum SessionCuePlanner {
    static func cues(
        for remainingSegments: [SessionSegment],
        currentElapsed: TimeInterval
    ) -> [SessionCue] {
        guard !remainingSegments.isEmpty else { return [] }

        var plannedCues: [SessionCue] = []
        var timelineOffset = -currentElapsed

        for segment in remainingSegments {
            plannedCues.append(contentsOf: cues(for: segment, phaseStartOffset: timelineOffset))
            timelineOffset += segment.durationSeconds
        }

        return plannedCues
            .filter { $0.offsetSeconds >= 0 }
            .sorted { $0.offsetSeconds < $1.offsetSeconds }
    }

    static func remainingDuration(
        for remainingSegments: [SessionSegment],
        currentElapsed: TimeInterval
    ) -> TimeInterval {
        max(remainingSegments.reduce(0) { $0 + $1.durationSeconds } - currentElapsed, 0)
    }

    private static func cues(for segment: SessionSegment, phaseStartOffset: TimeInterval) -> [SessionCue] {
        switch segment.phase {
        case .countdownToWork:
            return [
                SessionCue(offsetSeconds: phaseStartOffset, kind: .beepShort),
                SessionCue(offsetSeconds: phaseStartOffset + 1, kind: .beepShort),
                SessionCue(offsetSeconds: phaseStartOffset + 2, kind: .beepLong)
            ]

        case .countdownToRest:
            return [
                SessionCue(offsetSeconds: phaseStartOffset, kind: .beepShort),
                SessionCue(offsetSeconds: phaseStartOffset + 1, kind: .beepShort),
                SessionCue(offsetSeconds: phaseStartOffset + 2, kind: .beepRestFinal)
            ]

        case .work, .rest:
            var cues: [SessionCue] = []
            if segment.durationSeconds >= 20 {
                cues.append(
                    SessionCue(
                        offsetSeconds: phaseStartOffset + (segment.durationSeconds / 2),
                        kind: .voiceHalfway
                    )
                )
            }

            if segment.durationSeconds > 10 {
                cues.append(
                    SessionCue(
                        offsetSeconds: phaseStartOffset + (segment.durationSeconds - 10),
                        kind: .voiceTenSeconds
                    )
                )
            }

            return cues

        case .completed:
            return []
        }
    }
}
