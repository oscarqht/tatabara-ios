import XCTest
@testable import Tatabara

@MainActor
final class TimerEngineTests: XCTestCase {
    private func makeKinds(_ kinds: SessionCueKind...) -> [SessionCueKind] {
        kinds
    }

    private func assertKinds(
        _ actual: [SessionCueKind],
        equalTo expected: [SessionCueKind],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, expected, file: file, line: line)
    }

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

    private final class RecordingSessionAudioCoordinator: SessionAudioControlling {
        private(set) var playCalls: [(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment])] = []
        private(set) var completionCueCallCount = 0
        private(set) var stopCallCount = 0

        func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {
            playCalls.append((snapshot, remainingSegments))
        }

        func playCompletionCue() {
            completionCueCallCount += 1
        }

        func stop() {
            stopCallCount += 1
        }
    }

    private func allowDeferredAudioSync() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }

    func testEstimatedDurationExcludesCountdowns() {
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 3)
        XCTAssertEqual(preset.estimatedTotalDuration, 150)
    }

    func testBuildSegmentsCreatesWorkAndRestTransitions() {
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 2)
        let segments = TimerEngine.buildSegments(from: preset)

        XCTAssertEqual(segments.map(\.phase), [.work, .rest, .work])
    }

    func testPauseAndResumeKeepsRemainingTimeStable() {
        let engine = TimerEngine(audioCoordinator: NoopSessionAudioCoordinator())
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: .default, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(1.2))
        engine.pause(now: startDate.addingTimeInterval(1.2))
        let pausedRemaining = engine.snapshot?.remainingSeconds

        engine.resume(now: startDate.addingTimeInterval(9))
        engine.synchronize(now: startDate.addingTimeInterval(9))

        XCTAssertNotNil(pausedRemaining)
        XCTAssertNotNil(engine.snapshot?.remainingSeconds)
        XCTAssertEqual(engine.snapshot!.remainingSeconds, pausedRemaining!, accuracy: 0.01)
    }

    func testRestartCurrentPhaseResetsCurrentWorkout() {
        let engine = TimerEngine(audioCoordinator: NoopSessionAudioCoordinator())
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: .default, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(2.4))
        engine.restartCurrentPhase(now: startDate.addingTimeInterval(2.4))

        XCTAssertEqual(engine.snapshot?.phase, .work)
        XCTAssertNotNil(engine.snapshot?.remainingSeconds)
        XCTAssertEqual(engine.snapshot!.remainingSeconds, 40, accuracy: 0.01)
    }

    func testSynchronizeAdvancesAcrossBackgroundGap() {
        let engine = TimerEngine(audioCoordinator: NoopSessionAudioCoordinator())
        let preset = WorkoutPreset(workDurationSeconds: 20, restDurationSeconds: 10, cycleCount: 2)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: preset, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(29))

        XCTAssertEqual(engine.snapshot?.phase, .rest)
        XCTAssertEqual(engine.snapshot?.currentCycle, 1)
    }

    func testStartPublishesSessionBeforeAudioPlaybackBegins() async {
        let audioCoordinator = RecordingSessionAudioCoordinator()
        let engine = TimerEngine(audioCoordinator: audioCoordinator)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: .default, now: startDate)

        XCTAssertEqual(engine.snapshot?.phase, .work)
        XCTAssertTrue(audioCoordinator.playCalls.isEmpty)

        await allowDeferredAudioSync()

        XCTAssertEqual(audioCoordinator.playCalls.count, 1)
    }

    func testResumeRebuildsCueTimelineFromCurrentElapsedTime() async {
        let audioCoordinator = RecordingSessionAudioCoordinator()
        let engine = TimerEngine(audioCoordinator: audioCoordinator)
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 2)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: preset, now: startDate)
        await allowDeferredAudioSync()
        engine.synchronize(now: startDate.addingTimeInterval(12))
        engine.pause(now: startDate.addingTimeInterval(12))
        await allowDeferredAudioSync()
        engine.resume(now: startDate.addingTimeInterval(50))
        await allowDeferredAudioSync()

        guard let resumedPlayback = audioCoordinator.playCalls.last else {
            return XCTFail("Expected audio timeline to rebuild on resume.")
        }

        let cues = SessionCuePlanner.cues(
            for: resumedPlayback.remainingSegments,
            currentElapsed: resumedPlayback.snapshot.elapsedSeconds
        )

        assertKinds(
            cues.map(\.kind),
            equalTo: makeKinds(
                .voiceHalfway, .voiceTenSeconds,
                .beepShort, .beepShort, .beepLong,
                .voiceRest, .beepShort, .beepShort, .beepRestFinal,
                .voiceRound(2), .voiceHalfway, .voiceTenSeconds,
                .beepShort, .beepShort, .beepLong
            )
        )
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [8, 18, 25, 26, 27, 28, 40, 41, 42, 43, 63, 73, 80, 81, 82])
    }

    func testStopClearsSessionBeforeAudioTeardownRuns() async {
        let audioCoordinator = RecordingSessionAudioCoordinator()
        let engine = TimerEngine(audioCoordinator: audioCoordinator)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: .default, now: startDate)
        await allowDeferredAudioSync()

        engine.stop()

        XCTAssertNil(engine.snapshot)
        XCTAssertEqual(audioCoordinator.stopCallCount, 0)

        await allowDeferredAudioSync()

        XCTAssertEqual(audioCoordinator.stopCallCount, 1)
    }

    func testCompletionTriggersWorkoutCompleteCue() async {
        let audioCoordinator = RecordingSessionAudioCoordinator()
        let engine = TimerEngine(audioCoordinator: audioCoordinator)
        let preset = WorkoutPreset(workDurationSeconds: 5, restDurationSeconds: 3, cycleCount: 1)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: preset, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(TimerEngine.prestartDurationSeconds + 5))

        XCTAssertEqual(engine.snapshot?.phase, .completed)
        XCTAssertEqual(audioCoordinator.completionCueCallCount, 0)

        await allowDeferredAudioSync()

        XCTAssertEqual(audioCoordinator.completionCueCallCount, 1)
        XCTAssertEqual(audioCoordinator.stopCallCount, 0)
    }

    func testBackgroundRecoveryDoesNotReplayExpiredRestBeeps() {
        let engine = TimerEngine(audioCoordinator: NoopSessionAudioCoordinator())
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 2)
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: preset, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(46))

        XCTAssertEqual(engine.snapshot?.phase, .rest)
        XCTAssertEqual(engine.snapshot?.currentCycle, 1)

        let cues = SessionCuePlanner.cues(
            for: engine.remainingSegments(),
            currentElapsed: engine.snapshot?.elapsedSeconds ?? 0
        )

        assertKinds(
            cues.map(\.kind),
            equalTo: makeKinds(.beepShort, .beepShort, .beepRestFinal, .voiceRound(2), .voiceHalfway, .voiceTenSeconds, .beepShort, .beepShort, .beepLong)
        )
        assertOffsets(cues.map(\.offsetSeconds), equalTo: [6, 7, 8, 9, 29, 39, 46, 47, 48])
    }
}
