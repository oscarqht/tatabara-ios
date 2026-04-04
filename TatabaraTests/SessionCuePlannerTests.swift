import XCTest
@testable import Tatabara

final class SessionCuePlannerTests: XCTestCase {
    func testPlannerAddsWorkoutCountdownPattern() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .countdownToWork, durationSeconds: 3, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertEqual(cues.map(\.kind), [.beepShort, .beepShort, .beepLong])
        XCTAssertEqual(cues.count, 3)
        XCTAssertEqual(cues[0].offsetSeconds, 0, accuracy: 0.001)
        XCTAssertEqual(cues[1].offsetSeconds, 1, accuracy: 0.001)
        XCTAssertEqual(cues[2].offsetSeconds, 2, accuracy: 0.001)
    }

    func testPlannerAddsVoicePromptsForLongWorkSegment() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertTrue(cues.contains(where: { $0.kind == .voiceHalfway && abs($0.offsetSeconds - 20) < 0.001 }))
        XCTAssertTrue(cues.contains(where: { $0.kind == .voiceTenSeconds && abs($0.offsetSeconds - 30) < 0.001 }))
    }

    func testPlannerSkipsHalfwayForShortSegment() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .rest, durationSeconds: 15, cycleIndex: 1)],
            currentElapsed: 0
        )

        XCTAssertFalse(cues.contains(where: { $0.kind == .voiceHalfway }))
        XCTAssertTrue(cues.contains(where: { $0.kind == .voiceTenSeconds }))
    }

    func testPlannerAccountsForElapsedTimeInCurrentSegment() {
        let cues = SessionCuePlanner.cues(
            for: [SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1)],
            currentElapsed: 28
        )

        XCTAssertEqual(cues.map(\.kind), [.voiceTenSeconds])
        XCTAssertNotNil(cues.first?.offsetSeconds)
        XCTAssertEqual(cues.first!.offsetSeconds, 2, accuracy: 0.001)
    }
}
