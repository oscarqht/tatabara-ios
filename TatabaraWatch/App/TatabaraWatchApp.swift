import SwiftUI

@main
struct TatabaraWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private static let cueCoordinator = CompositeSessionCueCoordinator(
        coordinators: [
            SessionAudioCoordinator(),
            WatchSessionCueCoordinator(emitter: WatchKitCueEmitter())
        ]
    )
    @StateObject private var model = TatabaraAppModel(
        timerEngine: TimerEngine(cueCoordinator: cueCoordinator),
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
