import Foundation
import HealthKit

enum WatchWorkoutRuntimeError: LocalizedError {
    case healthDataUnavailable
    case authorizationDenied
    case sessionAlreadyActive

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Health data is unavailable on this Apple Watch."
        case .authorizationDenied:
            "Allow Health access to keep workouts running reliably on Apple Watch."
        case .sessionAlreadyActive:
            "A workout session is already active."
        }
    }
}

@MainActor
final class WatchWorkoutRuntimeManager: NSObject, WorkoutRuntimeManaging {
    private let healthStore: HKHealthStore
    private var session: HKWorkoutSession?

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func start() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WatchWorkoutRuntimeError.healthDataUnavailable
        }

        guard session == nil else {
            throw WatchWorkoutRuntimeError.sessionAlreadyActive
        }

        try await requestAuthorizationIfNeeded()

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .highIntensityIntervalTraining
        configuration.locationType = .indoor

        let session = try HKWorkoutSession(
            healthStore: healthStore,
            configuration: configuration
        )

        session.delegate = self
        session.startActivity(with: .now)
        self.session = session
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func stop() {
        session?.end()
        session = nil
    }

    private func requestAuthorizationIfNeeded() async throws {
        let workoutType = HKObjectType.workoutType()

        if healthStore.authorizationStatus(for: workoutType) == .sharingDenied {
            throw WatchWorkoutRuntimeError.authorizationDenied
        }

        if healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized {
            return
        }

        try await healthStore.requestAuthorization(
            toShare: [workoutType],
            read: []
        )

        guard healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized else {
            throw WatchWorkoutRuntimeError.authorizationDenied
        }
    }
}

extension WatchWorkoutRuntimeManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended else { return }

        Task { @MainActor [weak self] in
            if self?.session === workoutSession {
                self?.session = nil
            }
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            if self?.session === workoutSession {
                self?.session = nil
            }
        }
    }
}
