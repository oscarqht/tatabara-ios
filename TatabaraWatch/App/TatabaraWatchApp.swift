import SwiftUI

@main
struct TatabaraWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = TatabaraAppModel(
        timerEngine: TimerEngine(cueCoordinator: WatchSessionCueCoordinator(emitter: WatchKitCueEmitter())),
        runtimeManager: WatchWorkoutRuntimeManager()
    )

    var body: some Scene {
        WindowGroup {
            WatchContentView(model: model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase, initial: true) { _, _ in
                    model.handleScenePhaseDidChange()
                }
        }
    }
}
