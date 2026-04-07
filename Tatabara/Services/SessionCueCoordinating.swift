import Foundation

protocol SessionCueCoordinating: AnyObject {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment])
    func playCompletionCue()
    func stop()
}

final class CompositeSessionCueCoordinator: SessionCueCoordinating {
    private let coordinators: [SessionCueCoordinating]

    init(coordinators: [SessionCueCoordinating]) {
        self.coordinators = coordinators
    }

    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {
        coordinators.forEach { $0.play(snapshot: snapshot, remainingSegments: remainingSegments) }
    }

    func playCompletionCue() {
        coordinators.forEach { $0.playCompletionCue() }
    }

    func stop() {
        coordinators.forEach { $0.stop() }
    }
}

final class NoopSessionCueCoordinator: SessionCueCoordinating {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {}
    func playCompletionCue() {}
    func stop() {}
}
