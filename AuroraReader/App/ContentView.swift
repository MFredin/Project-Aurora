import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(AppTab.library)

            CloudLibraryView()
                .tabItem {
                    Label("Cloud", systemImage: "icloud.fill")
                }
                .tag(AppTab.cloud)

            GoodReadsView()
                .tabItem {
                    Label("Discover", systemImage: "text.magnifyingglass")
                }
                .tag(AppTab.discover)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
                .tag(AppTab.settings)
        }
        .tint(AuroraTheme.auroraTeal)
    }
}

enum AppTab: Hashable {
    case library
    case cloud
    case discover
    case settings
}

#Preview {
    ContentView()
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self], inMemory: true)
}
