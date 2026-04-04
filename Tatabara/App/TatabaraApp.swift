import SwiftUI

@main
struct TatabaraApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = TatabaraAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase, initial: true) { _, _ in
                    model.handleScenePhaseDidChange()
                }
        }
    }
}
