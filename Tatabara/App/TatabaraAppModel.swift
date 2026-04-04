import Foundation

@MainActor
final class TatabaraAppModel: ObservableObject {
    @Published var selectedTab: AppTab = .workout
    @Published var preset: WorkoutPreset {
        didSet {
            presetStore.save(preset)
        }
    }

    let timerEngine: TimerEngine

    private let presetStore: PresetStore

    init(
        presetStore: PresetStore = PresetStore(),
        timerEngine: TimerEngine = TimerEngine()
    ) {
        self.presetStore = presetStore
        self.timerEngine = timerEngine
        self.preset = presetStore.load()
    }

    func startWorkout() {
        timerEngine.start(with: preset)
    }

    func handleScenePhaseDidChange() {
        timerEngine.handleScenePhaseDidChange()
    }
}
