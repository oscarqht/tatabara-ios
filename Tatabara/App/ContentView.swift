import SwiftUI

struct ContentView: View {
    @ObservedObject var model: TatabaraAppModel

    var body: some View {
        WorkoutTabView(model: model)
            .background(TatabaraTheme.ColorPalette.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView(model: TatabaraAppModel())
}
