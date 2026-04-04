import Foundation

struct PresetStore {
    private let defaults: UserDefaults
    private let storageKey = "tatabara.lastPreset"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> WorkoutPreset {
        guard
            let data = defaults.data(forKey: storageKey),
            let preset = try? JSONDecoder().decode(WorkoutPreset.self, from: data)
        else {
            return .default
        }

        return preset
    }

    func save(_ preset: WorkoutPreset) {
        guard let data = try? JSONEncoder().encode(preset) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
