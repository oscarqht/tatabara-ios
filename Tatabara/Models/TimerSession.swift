import Foundation

struct SessionSegment: Equatable, Hashable, Identifiable {
    let id = UUID()
    let phase: TimerPhase
    let durationSeconds: TimeInterval
    let cycleIndex: Int
}

struct TimerSession: Equatable {
    let preset: WorkoutPreset
    let segments: [SessionSegment]
    var currentSegmentIndex: Int
    var phaseStartDate: Date
    var phaseEndDate: Date
    var isPaused: Bool
    var pausedRemainingDuration: TimeInterval?
    var completedAt: Date?
}

struct TimerSessionSnapshot: Equatable, Identifiable {
    var id: String {
        "\(phase.rawValue)-\(currentCycle)-\(Int(remainingSeconds.rounded(.down)))"
    }

    let preset: WorkoutPreset
    let phase: TimerPhase
    let currentCycle: Int
    let totalCycles: Int
    let phaseStartDate: Date
    let phaseEndDate: Date
    let phaseDuration: TimeInterval
    let elapsedSeconds: TimeInterval
    let remainingSeconds: TimeInterval
    let progress: Double
    let isPaused: Bool
    let nextPhase: TimerPhase?
    let nextPhaseDuration: TimeInterval?
}
