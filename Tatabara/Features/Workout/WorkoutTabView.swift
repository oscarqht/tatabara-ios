import SwiftUI

struct WorkoutTabView: View {
    @ObservedObject var model: TatabaraAppModel
    @ObservedObject private var timerEngine: TimerEngine
    @State private var route: WorkoutRoute?

    init(model: TatabaraAppModel) {
        self.model = model
        _timerEngine = ObservedObject(wrappedValue: model.timerEngine)
    }

    var body: some View {
        NavigationStack {
            WorkoutSetupView(
                preset: $model.preset,
                onStart: {
                    Task {
                        await model.startWorkout()
                    }
                }
            )
            .navigationDestination(item: $route) { _ in
                ActiveTimerView(timerEngine: timerEngine)
            }
        }
        .onChange(of: timerEngine.snapshot, initial: true) { _, snapshot in
            route = (snapshot != nil && snapshot?.phase != .completed) ? .activeSession : nil
        }
    }
}

private enum WorkoutRoute: String, Identifiable {
    case activeSession

    var id: String { rawValue }
}
