import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(AppTab.library)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
    }
}

enum AppTab: Hashable {
    case library
    case settings
}

#Preview {
    ContentView()
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self], inMemory: true)
}
