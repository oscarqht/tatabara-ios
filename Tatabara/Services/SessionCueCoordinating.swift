import Foundation

protocol SessionCueCoordinating: AnyObject {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment])
    func playCompletionCue()
    func stop()
}

final class NoopSessionCueCoordinator: SessionCueCoordinating {
    func play(snapshot: TimerSessionSnapshot, remainingSegments: [SessionSegment]) {}
    func playCompletionCue() {}
    func stop() {}
}
