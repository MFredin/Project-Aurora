import SwiftUI
import SwiftData

@main
struct AuroraReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self,
            ReadingSession.self, ReadingStreak.self, Achievement.self, FriendProfile.self,
            Highlight.self, VocabularyEntry.self, KnowledgeNode.self,
            BookClub.self, ClubDiscussion.self
        ])
    }
}
