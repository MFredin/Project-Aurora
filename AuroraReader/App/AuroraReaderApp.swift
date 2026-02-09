import SwiftUI
import SwiftData

@main
struct AuroraReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self])
    }
}
