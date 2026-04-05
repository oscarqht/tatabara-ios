import Combine
import Foundation

@MainActor
final class TatabaraAppModel: ObservableObject {
    @Published var preset: WorkoutPreset {
        didSet {
            presetStore.save(preset)
        }
    }

    let timerEngine: TimerEngine
    @Published var runtimeAlert: RuntimeAlert?

    private let presetStore: PresetStore
    private let runtimeManager: WorkoutRuntimeManaging
    private var cancellables: Set<AnyCancellable> = []

    init(
        presetStore: PresetStore = PresetStore(),
        timerEngine: TimerEngine? = nil,
        runtimeManager: WorkoutRuntimeManaging? = nil
    ) {
        self.presetStore = presetStore
        self.timerEngine = timerEngine ?? TimerEngine()
        self.runtimeManager = runtimeManager ?? NoopWorkoutRuntimeManager()
        self.preset = presetStore.load()

        self.timerEngine.$snapshot
            .sink { [weak self] snapshot in
                self?.handleSnapshotChange(snapshot)
            }
            .store(in: &cancellables)
    }

    func startWorkout() async {
        guard !timerEngine.hasActiveSession else { return }

        do {
            try await runtimeManager.start()
            timerEngine.start(with: preset)
        } catch {
            runtimeAlert = RuntimeAlert(
                title: "Workout Unavailable",
                message: error.localizedDescription
            )
        }
    }

    func togglePauseResume() {
        guard let snapshot = timerEngine.snapshot else { return }

        if snapshot.isPaused {
            runtimeManager.resume()
        } else {
            runtimeManager.pause()
        }

        timerEngine.togglePauseResume()
    }

    func restartCurrentPhase() {
        timerEngine.restartCurrentPhase()
    }

    func stopWorkout() {
        runtimeManager.stop()
        timerEngine.stop()
    }

    func handleScenePhaseDidChange() {
        timerEngine.handleScenePhaseDidChange()
    }

    func clearRuntimeAlert() {
        runtimeAlert = nil
    }

    func resetCompletedSession() {
        guard timerEngine.snapshot?.phase == .completed else { return }
        timerEngine.stop()
    }

    private func handleSnapshotChange(_ snapshot: TimerSessionSnapshot?) {
        guard snapshot?.phase == .completed else { return }
        runtimeManager.stop()
    }
}
