import SwiftUI

struct WorkoutTabView: View {
    @ObservedObject var model: TatabaraAppModel

    var body: some View {
        NavigationStack {
            WorkoutSetupView(
                preset: $model.preset,
                onStart: model.startWorkout
            )
            .navigationDestination(
                isPresented: Binding(
                    get: { model.timerEngine.hasActiveSession },
                    set: { isPresented in
                        if !isPresented {
                            model.timerEngine.stop()
                        }
                    }
                )
            ) {
                ActiveTimerView(timerEngine: model.timerEngine)
            }
        }
    }
}
