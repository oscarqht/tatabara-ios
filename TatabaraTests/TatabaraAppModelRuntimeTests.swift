import XCTest
@testable import Tatabara

@MainActor
final class TatabaraAppModelRuntimeTests: XCTestCase {
    private final class RecordingRuntimeManager: WorkoutRuntimeManaging {
        private(set) var startCallCount = 0
        private(set) var pauseCallCount = 0
        private(set) var resumeCallCount = 0
        private(set) var stopCallCount = 0
        var startError: Error?

        func start() async throws {
            startCallCount += 1

            if let startError {
                throw startError
            }
        }

        func pause() {
            pauseCallCount += 1
        }

        func resume() {
            resumeCallCount += 1
        }

        func stop() {
            stopCallCount += 1
        }
    }

    private struct RuntimeFailure: LocalizedError {
        var errorDescription: String? { "Health access denied." }
    }

    func testStartWorkoutStartsRuntimeBeforeTimerSession() async {
        let runtimeManager = RecordingRuntimeManager()
        let model = TatabaraAppModel(
            timerEngine: TimerEngine(cueCoordinator: NoopSessionCueCoordinator()),
            runtimeManager: runtimeManager
        )

        await model.startWorkout()

        XCTAssertEqual(runtimeManager.startCallCount, 1)
        XCTAssertEqual(model.timerEngine.snapshot?.phase, .work)
        XCTAssertNil(model.runtimeAlert)
    }

    func testStartWorkoutPublishesAlertWhenRuntimeFails() async {
        let runtimeManager = RecordingRuntimeManager()
        runtimeManager.startError = RuntimeFailure()
        let model = TatabaraAppModel(
            timerEngine: TimerEngine(cueCoordinator: NoopSessionCueCoordinator()),
            runtimeManager: runtimeManager
        )

        await model.startWorkout()

        XCTAssertEqual(runtimeManager.startCallCount, 1)
        XCTAssertNil(model.timerEngine.snapshot)
        XCTAssertEqual(model.runtimeAlert?.message, "Health access denied.")
    }

    func testPauseResumeAndStopForwardToRuntimeManager() async {
        let runtimeManager = RecordingRuntimeManager()
        let model = TatabaraAppModel(
            timerEngine: TimerEngine(cueCoordinator: NoopSessionCueCoordinator()),
            runtimeManager: runtimeManager
        )

        await model.startWorkout()
        model.togglePauseResume()
        model.togglePauseResume()
        model.stopWorkout()

        XCTAssertEqual(runtimeManager.pauseCallCount, 1)
        XCTAssertEqual(runtimeManager.resumeCallCount, 1)
        XCTAssertEqual(runtimeManager.stopCallCount, 1)
        XCTAssertNil(model.timerEngine.snapshot)
    }

    func testCompletionStopsRuntimeWithoutClearingCompletedSnapshot() async {
        let runtimeManager = RecordingRuntimeManager()
        let model = TatabaraAppModel(
            timerEngine: TimerEngine(cueCoordinator: NoopSessionCueCoordinator()),
            runtimeManager: runtimeManager
        )
        let shortPreset = WorkoutPreset(workDurationSeconds: 1, restDurationSeconds: 1, cycleCount: 1)
        let startDate = Date.now

        model.preset = shortPreset
        await model.startWorkout()
        model.timerEngine.synchronize(now: startDate.addingTimeInterval(2))

        XCTAssertEqual(model.timerEngine.snapshot?.phase, .completed)
        XCTAssertEqual(runtimeManager.stopCallCount, 1)
    }
}
