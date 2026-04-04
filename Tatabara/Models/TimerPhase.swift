import Foundation

enum TimerPhase: String, Codable, CaseIterable, Identifiable {
    case work
    case rest
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            "Workout"
        case .rest:
            "Rest"
        case .completed:
            "Completed"
        }
    }

    var nextTitle: String {
        switch self {
        case .work:
            "Rest"
        case .rest:
            "Workout"
        case .completed:
            "Complete"
        }
    }
}
