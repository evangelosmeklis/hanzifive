import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                StudyView()
            }
            .tabItem {
                Label("Study", systemImage: "character.textbox")
            }

            NavigationStack {
                ReviseView()
            }
            .tabItem {
                Label("Revise", systemImage: "arrow.triangle.2.circlepath")
            }

        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentView()
}
