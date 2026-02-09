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

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.activity)

            KnowledgeGraphView()
                .tabItem {
                    Label("Knowledge", systemImage: "brain.head.profile.fill")
                }
                .tag(AppTab.knowledge)

            CloudLibraryView()
                .tabItem {
                    Label("Cloud", systemImage: "icloud.fill")
                }
                .tag(AppTab.cloud)

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
    case activity
    case knowledge
    case cloud
    case settings
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self,
            ReadingSession.self, ReadingStreak.self, Achievement.self, FriendProfile.self,
            Highlight.self, VocabularyEntry.self, KnowledgeNode.self,
            BookClub.self, ClubDiscussion.self
        ], inMemory: true)
}
