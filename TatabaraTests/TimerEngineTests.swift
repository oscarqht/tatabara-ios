import XCTest
@testable import Tatabara

@MainActor
final class TimerEngineTests: XCTestCase {
    func testEstimatedDurationIncludesCountdowns() {
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 3)
        XCTAssertEqual(preset.estimatedTotalDuration, 147)
    }

    func testBuildSegmentsCreatesCountdownsAndRestTransitions() {
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 2)
        let segments = TimerEngine.buildSegments(from: preset)

        XCTAssertEqual(segments.map(\.phase), [.countdownToWork, .work, .countdownToRest, .rest, .countdownToWork, .work])
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

    func testRestartCurrentPhaseResetsCountdown() {
        let engine = TimerEngine(audioCoordinator: NoopSessionAudioCoordinator())
        let startDate = Date(timeIntervalSince1970: 100)

        engine.start(with: .default, now: startDate)
        engine.synchronize(now: startDate.addingTimeInterval(2.4))
        engine.restartCurrentPhase(now: startDate.addingTimeInterval(2.4))

        XCTAssertEqual(engine.snapshot?.phase, .countdownToWork)
        XCTAssertNotNil(engine.snapshot?.remainingSeconds)
        XCTAssertEqual(engine.snapshot!.remainingSeconds, 3, accuracy: 0.01)
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
}
