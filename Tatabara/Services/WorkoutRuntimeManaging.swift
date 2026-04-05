import Foundation

@MainActor
protocol WorkoutRuntimeManaging: AnyObject {
    func start() async throws
    func pause()
    func resume()
    func stop()
}

final class NoopWorkoutRuntimeManager: WorkoutRuntimeManaging {
    func start() async throws {}
    func pause() {}
    func resume() {}
    func stop() {}
}

struct RuntimeAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}
