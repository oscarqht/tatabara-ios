import XCTest
@testable import Tatabara

final class SessionCuePlannerTests: XCTestCase {
    private func assertOffsets(
        _ actual: [TimeInterval],
        equalTo expected: [TimeInterval],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)

        for (actualOffset, expectedOffset) in zip(actual, expected) {
            XCTAssertEqual(actualOffset, expectedOffset, accuracy: 0.001, file: file, line: line)
        }
    }

    func testPlannerAddsWorkoutEndPatternAndVoicePrompts() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.voiceHalfway, .voiceTenSeconds, .beepShort, .beepShort, .beepLong])
        XCTAssertEqual(cues.count, 5)
        XCTAssertEqual(cues[0].offsetSeconds, 20, accuracy: 0.001)
        XCTAssertEqual(cues[1].offsetSeconds, 30, accuracy: 0.001)
        XCTAssertEqual(cues[2].offsetSeconds, 37, accuracy: 0.001)
        XCTAssertEqual(cues[3].offsetSeconds, 38, accuracy: 0.001)
        XCTAssertEqual(cues[4].offsetSeconds, 39, accuracy: 0.001)
    }

    func testPlannerAddsRestEndPatternOnly() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .rest, durationSeconds: 15, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.beepShort, .beepShort, .beepRestFinal])
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [12, 13, 14])
        XCTAssertFalse(cues.contains(where: { $0.kind == .voiceHalfway }))
        XCTAssertFalse(cues.contains(where: { $0.kind == .voiceTenSeconds }))
    }

    func testPlannerMatchesMultiCycleFortyFifteenTimeline() {
        let cues = SessionCuePlanner.cues(
            for: [
                SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1),
                SessionSegment(phase: .rest, durationSeconds: 15, cycleIndex: 1),
                SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 2)
            ],
            currentElapsed: 0
        )

        XCTAssertEqual(
            cues.map(\.kind),
            [
                .voiceHalfway, .voiceTenSeconds, .beepShort, .beepShort, .beepLong,
                .beepShort, .beepShort, .beepRestFinal,
                .voiceHalfway, .voiceTenSeconds, .beepShort, .beepShort, .beepLong
            ]
        )
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [20, 30, 37, 38, 39, 52, 53, 54, 75, 85, 92, 93, 94])
    }

    func testPlannerSkipsHalfwayForWorkoutShorterThanThirtySeconds() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 29, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.voiceTenSeconds, .beepShort, .beepShort, .beepLong])
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [19, 26, 27, 28])
        XCTAssertFalse(cues.contains(where: { $0.kind == .voiceHalfway }))
    }

    func testPlannerKeepsHalfwayForThirtySecondWorkout() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 30, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.voiceHalfway, .voiceTenSeconds, .beepShort, .beepShort, .beepLong])
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [15, 20, 27, 28, 29])
    }

    func testPlannerSkipsVoicePromptsWhenWorkoutIsTenSecondsOrLess() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 10, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.beepShort, .beepShort, .beepLong])
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [7, 8, 9])
    }

    func testPlannerAccountsForElapsedTimeInCurrentSegment() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1)],
            currentElapsed: 28
        )

        XCTAssertEqual(cues.map(\.kind), [.voiceTenSeconds, .beepShort, .beepShort, .beepLong])
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [2, 9, 10, 11])
    }

    func testPlannerSkipsExpiredWorkoutCuesAfterRecoveryButKeepsUpcomingPhases() {
        let cues = SessionCuePlanner.cues(
            for: [
                SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1),
                SessionSegment(phase: .rest, durationSeconds: 15, cycleIndex: 1),
                SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 2)
            ],
            currentElapsed: 35
        )

        XCTAssertEqual(
            cues.map(\.kind),
            [
                .beepShort, .beepShort, .beepLong,
                .beepShort, .beepShort, .beepRestFinal,
                .voiceHalfway, .voiceTenSeconds,
                .beepShort, .beepShort, .beepLong
            ]
        )
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [2, 3, 4, 17, 18, 19, 40, 50, 57, 58, 59])
    }
}
