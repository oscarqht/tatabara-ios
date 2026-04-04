import Foundation

struct WorkoutPreset: Codable, Equatable, Hashable {
    var workDurationSeconds: Int
    var restDurationSeconds: Int
    var cycleCount: Int

    static let `default` = WorkoutPreset(
        workDurationSeconds: 40,
        restDurationSeconds: 15,
        cycleCount: 8
    )

    var estimatedTotalDuration: TimeInterval {
        let countdownToWorkTotal = cycleCount * 3
        let countdownToRestTotal = max(cycleCount - 1, 0) * 3
        let workTotal = cycleCount * workDurationSeconds
        let restTotal = max(cycleCount - 1, 0) * restDurationSeconds
        return TimeInterval(countdownToWorkTotal + countdownToRestTotal + workTotal + restTotal)
    }

    var intensityBars: [Double] {
        guard cycleCount > 0 else { return [] }
        return (0..<cycleCount).flatMap { index in
            let workHeight = min(1.0, 0.45 + (Double(index) / Double(max(cycleCount - 1, 1))) * 0.55)
            let restHeight = 0.2
            return index == cycleCount - 1 ? [workHeight] : [workHeight, restHeight]
        }
    }
}
