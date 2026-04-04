import Foundation

enum TimerPhase: String, Codable, CaseIterable, Identifiable {
    case countdownToWork
    case work
    case countdownToRest
    case rest
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdownToWork:
            "Ready"
        case .work:
            "Workout"
        case .countdownToRest:
            "Recover"
        case .rest:
            "Rest"
        case .completed:
            "Completed"
        }
    }

    var nextTitle: String {
        switch self {
        case .countdownToWork:
            "Workout"
        case .work:
            "Rest"
        case .countdownToRest:
            "Rest"
        case .rest:
            "Workout"
        case .completed:
            "Complete"
        }
    }
}
