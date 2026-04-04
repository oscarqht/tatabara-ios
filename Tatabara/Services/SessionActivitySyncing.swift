import Foundation

protocol SessionActivitySyncing: Sendable {
    func update(snapshot: TimerSessionSnapshot?)
}

struct NoopSessionActivitySyncer: SessionActivitySyncing {
    func update(snapshot: TimerSessionSnapshot?) {}
}
