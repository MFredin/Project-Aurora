import SwiftUI
import SwiftData

@main
struct AuroraReaderApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                WelcomeView()
            }
        }
        .modelContainer(for: [
            Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self,
            ReadingSession.self, ReadingStreak.self, Achievement.self, FriendProfile.self,
            Highlight.self, VocabularyEntry.self, KnowledgeNode.self,
            BookClub.self, ClubDiscussion.self
        ])
    }
}
