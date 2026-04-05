import SwiftUI

struct WatchContentView: View {
    @ObservedObject var model: TatabaraAppModel
    @ObservedObject private var timerEngine: TimerEngine

    init(model: TatabaraAppModel) {
        self.model = model
        _timerEngine = ObservedObject(wrappedValue: model.timerEngine)
    }

    var body: some View {
        Group {
            if timerEngine.snapshot != nil {
                WatchActiveTimerView(model: model, timerEngine: timerEngine)
            } else {
                WatchWorkoutSetupView(model: model)
            }
        }
        .background(TatabaraTheme.ColorPalette.background.ignoresSafeArea())
        .alert(item: $model.runtimeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK")) {
                    model.clearRuntimeAlert()
                }
            )
        }
    }
}
