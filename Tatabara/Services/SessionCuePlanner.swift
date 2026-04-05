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
        case .work:
            return phaseStartPrompt(
                for: segment,
                phaseStartOffset: phaseStartOffset
            ) + workVoicePrompts(
                durationSeconds: segment.durationSeconds,
                phaseStartOffset: phaseStartOffset
            ) + phaseEndPrompts(
                durationSeconds: segment.durationSeconds,
                phaseStartOffset: phaseStartOffset,
                finalBeep: .beepLong
            )

        case .rest:
            return phaseStartPrompt(
                for: segment,
                phaseStartOffset: phaseStartOffset
            ) + phaseEndPrompts(
                durationSeconds: segment.durationSeconds,
                phaseStartOffset: phaseStartOffset,
                finalBeep: .beepRestFinal
            )

        case .completed:
            return []
        }
    }

    private static func phaseStartPrompt(
        for segment: SessionSegment,
        phaseStartOffset: TimeInterval
    ) -> [SessionCue] {
        let cueKind: SessionCueKind

        switch segment.phase {
        case .work:
            cueKind = .voiceRound(segment.cycleIndex)
        case .rest:
            cueKind = .voiceRest
        case .completed:
            return []
        }

        return [
            SessionCue(
                offsetSeconds: phaseStartOffset,
                kind: cueKind
            )
        ]
    }

    private static func workVoicePrompts(
        durationSeconds: TimeInterval,
        phaseStartOffset: TimeInterval
    ) -> [SessionCue] {
        var cues: [SessionCue] = []

        if durationSeconds >= 30 {
            cues.append(
                SessionCue(
                    offsetSeconds: phaseStartOffset + (durationSeconds / 2),
                    kind: .voiceHalfway
                )
            )
        }

        if durationSeconds > 10 {
            cues.append(
                SessionCue(
                    offsetSeconds: phaseStartOffset + (durationSeconds - 10),
                    kind: .voiceTenSeconds
                )
            )
        }

        return cues
    }

    private static func phaseEndPrompts(
        durationSeconds: TimeInterval,
        phaseStartOffset: TimeInterval,
        finalBeep: SessionCueKind
    ) -> [SessionCue] {
        [
            SessionCue(
                offsetSeconds: phaseStartOffset + max(durationSeconds - 3, 0),
                kind: .beepShort
            ),
            SessionCue(
                offsetSeconds: phaseStartOffset + max(durationSeconds - 2, 0),
                kind: .beepShort
            ),
            SessionCue(
                offsetSeconds: phaseStartOffset + max(durationSeconds - 1, 0),
                kind: finalBeep
            )
        ]
    }
}
