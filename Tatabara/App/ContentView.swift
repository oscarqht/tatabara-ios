import SwiftUI

struct ContentView: View {
    @ObservedObject var model: TatabaraAppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            WorkoutTabView(model: model)
                .tabItem {
                    Label("Workout", systemImage: "timer")
                }
                .tag(AppTab.workout)

            HistoryPlaceholderView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)

            ProfilePlaceholderView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(TatabaraTheme.ColorPalette.primary)
        .toolbarBackground(TatabaraTheme.ColorPalette.background, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background(TatabaraTheme.ColorPalette.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView(model: TatabaraAppModel())
}
