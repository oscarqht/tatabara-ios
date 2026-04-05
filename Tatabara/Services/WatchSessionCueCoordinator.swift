import Foundation

enum WatchCuePattern: Equatable {
    case phaseStart
    case countdownTick
    case countdownFinal
    case completion
}

protocol WatchCueEmitting: AnyObject, Sendable {
    func emit(_ pattern: WatchCuePattern)
}

protocol WatchCueTaskScheduling: AnyObject {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void) -> WatchCueScheduledTask
}

protocol WatchCueScheduledTask: AnyObject {
    func cancel()
}

final class WatchSessionCueCoordinator: SessionCueCoordinating {
    private let emitter: WatchCueEmitting
    private let scheduler: WatchCueTaskScheduling
    private var scheduledTasks: [WatchCueScheduledTask] = []

    init(
        emitter: WatchCueEmitting,
        scheduler: WatchCueTaskScheduling = DispatchWatchCueScheduler()
    ) {
        self.emitter = emitter
        self.scheduler = scheduler
    }

    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {
        stop()

        let events = Self.events(
            for: remainingSegments,
            currentElapsed: snapshot.elapsedSeconds
        )

        scheduledTasks = events.map { event in
            scheduler.schedule(after: event.offsetSeconds) { [weak emitter] in
                emitter?.emit(event.pattern)
            }
        }
    }

    func playCompletionCue() {
        stop()
        emitter.emit(.completion)
    }

    func stop() {
        scheduledTasks.forEach { $0.cancel() }
        scheduledTasks.removeAll()
    }

    static func events(
        for remainingSegments: [SessionSegment],
        currentElapsed: TimeInterval
    ) -> [WatchCueEvent] {
        SessionCuePlanner.cues(
            for: remainingSegments,
            currentElapsed: currentElapsed
        ).compactMap { cue in
            let pattern: WatchCuePattern

            switch cue.kind {
            case .voiceRound(_), .voiceRest:
                pattern = .phaseStart
            case .voiceHalfway, .voiceTenSeconds:
                return nil
            case .beepShort:
                pattern = .countdownTick
            case .beepLong, .beepRestFinal:
                pattern = .countdownFinal
            }

            return WatchCueEvent(
                offsetSeconds: cue.offsetSeconds,
                pattern: pattern
            )
        }
    }
}

struct WatchCueEvent: Equatable {
    let offsetSeconds: TimeInterval
    let pattern: WatchCuePattern
}

final class DispatchWatchCueScheduler: WatchCueTaskScheduling {
    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(label: "com.tatabara.watch-cues", qos: .userInitiated)) {
        self.queue = queue
    }

    func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void) -> WatchCueScheduledTask {
        let workItem = DispatchWorkItem(block: action)
        let normalizedDelay = max(delay, 0)
        queue.asyncAfter(deadline: .now() + normalizedDelay, execute: workItem)
        return DispatchWatchCueTask(workItem: workItem)
    }
}

final class DispatchWatchCueTask: WatchCueScheduledTask {
    private let workItem: DispatchWorkItem

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem.cancel()
    }
}
