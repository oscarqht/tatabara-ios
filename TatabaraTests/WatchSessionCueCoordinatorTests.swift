import XCTest
@testable import Tatabara

@MainActor
final class WatchSessionCueCoordinatorTests: XCTestCase {
    private final class RecordingEmitter: WatchCueEmitting, @unchecked Sendable {
        private(set) var patterns: [WatchCuePattern] = []

        func emit(_ pattern: WatchCuePattern) {
            patterns.append(pattern)
        }
    }

    private final class ManualTask: WatchCueScheduledTask {
        let delay: TimeInterval
        let action: @Sendable () -> Void
        private(set) var isCancelled = false

        init(delay: TimeInterval, action: @escaping @Sendable () -> Void) {
            self.delay = delay
            self.action = action
        }

        func run() {
            guard !isCancelled else { return }
            action()
        }

        func cancel() {
            isCancelled = true
        }
    }

    private final class ManualScheduler: WatchCueTaskScheduling {
        private(set) var tasks: [ManualTask] = []

        func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void) -> WatchCueScheduledTask {
            let task = ManualTask(delay: delay, action: action)
            tasks.append(task)
            return task
        }
    }

    func testEventsKeepOnlyWatchRelevantPatternsAfterRecovery() {
        let remainingSegments = [
            SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 1),
            SessionSegment(phase: .rest, durationSeconds: 15, cycleIndex: 1),
            SessionSegment(phase: .work, durationSeconds: 40, cycleIndex: 2)
        ]

        let events = WatchSessionCueCoordinator.events(
            for: remainingSegments,
            currentElapsed: 35
        )

        XCTAssertEqual(
            events,
            [
                WatchCueEvent(offsetSeconds: 2, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 3, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 4, pattern: .countdownFinal),
                WatchCueEvent(offsetSeconds: 5, pattern: .phaseStart),
                WatchCueEvent(offsetSeconds: 17, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 18, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 19, pattern: .countdownFinal),
                WatchCueEvent(offsetSeconds: 20, pattern: .phaseStart),
                WatchCueEvent(offsetSeconds: 57, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 58, pattern: .countdownTick),
                WatchCueEvent(offsetSeconds: 59, pattern: .countdownFinal)
            ]
        )
    }

    func testPlayCancelsPriorScheduleBeforeResumeRebuildsTimeline() {
        let emitter = RecordingEmitter()
        let scheduler = ManualScheduler()
        let coordinator = WatchSessionCueCoordinator(
            emitter: emitter,
            scheduler: scheduler
        )
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 2)
        let snapshot = TimerSessionSnapshot(
            preset: preset,
            phase: .work,
            currentCycle: 1,
            totalCycles: 2,
            phaseStartDate: .now,
            phaseEndDate: .now.addingTimeInterval(40),
            phaseDuration: 40,
            elapsedSeconds: 0,
            remainingSeconds: 40,
            progress: 0,
            isPaused: false,
            nextPhase: .rest,
            nextPhaseDuration: 15
        )
        let resumedSnapshot = TimerSessionSnapshot(
            preset: preset,
            phase: .work,
            currentCycle: 1,
            totalCycles: 2,
            phaseStartDate: .now,
            phaseEndDate: .now.addingTimeInterval(28),
            phaseDuration: 40,
            elapsedSeconds: 12,
            remainingSeconds: 28,
            progress: 0.3,
            isPaused: false,
            nextPhase: .rest,
            nextPhaseDuration: 15
        )
        let remainingSegments = TimerEngine.buildSegments(from: preset)

        coordinator.play(snapshot: snapshot, remainingSegments: remainingSegments)
        let originalTasks = scheduler.tasks

        coordinator.play(snapshot: resumedSnapshot, remainingSegments: remainingSegments)

        XCTAssertTrue(originalTasks.allSatisfy(\.isCancelled))
        XCTAssertEqual(scheduler.tasks.count, originalTasks.count + 11)
    }

    func testStopCancelsPendingTasksWithoutEmitting() {
        let emitter = RecordingEmitter()
        let scheduler = ManualScheduler()
        let coordinator = WatchSessionCueCoordinator(
            emitter: emitter,
            scheduler: scheduler
        )
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 1)
        let snapshot = TimerSessionSnapshot(
            preset: preset,
            phase: .work,
            currentCycle: 1,
            totalCycles: 1,
            phaseStartDate: .now,
            phaseEndDate: .now.addingTimeInterval(40),
            phaseDuration: 40,
            elapsedSeconds: 0,
            remainingSeconds: 40,
            progress: 0,
            isPaused: false,
            nextPhase: nil,
            nextPhaseDuration: nil
        )

        coordinator.play(
            snapshot: snapshot,
            remainingSegments: TimerEngine.buildSegments(from: preset)
        )
        coordinator.stop()
        scheduler.tasks.forEach { $0.run() }

        XCTAssertTrue(scheduler.tasks.allSatisfy(\.isCancelled))
        XCTAssertTrue(emitter.patterns.isEmpty)
    }

    func testCompletionCueCancelsPendingTasksAndEmitsImmediately() {
        let emitter = RecordingEmitter()
        let scheduler = ManualScheduler()
        let coordinator = WatchSessionCueCoordinator(
            emitter: emitter,
            scheduler: scheduler
        )
        let preset = WorkoutPreset(workDurationSeconds: 40, restDurationSeconds: 15, cycleCount: 1)
        let snapshot = TimerSessionSnapshot(
            preset: preset,
            phase: .work,
            currentCycle: 1,
            totalCycles: 1,
            phaseStartDate: .now,
            phaseEndDate: .now.addingTimeInterval(40),
            phaseDuration: 40,
            elapsedSeconds: 0,
            remainingSeconds: 40,
            progress: 0,
            isPaused: false,
            nextPhase: nil,
            nextPhaseDuration: nil
        )

        coordinator.play(
            snapshot: snapshot,
            remainingSegments: TimerEngine.buildSegments(from: preset)
        )
        coordinator.playCompletionCue()
        scheduler.tasks.forEach { $0.run() }

        XCTAssertEqual(emitter.patterns, [.completion])
        XCTAssertTrue(scheduler.tasks.allSatisfy(\.isCancelled))
    }
}
