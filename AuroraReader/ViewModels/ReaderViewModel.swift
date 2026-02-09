import Foundation
import SwiftUI
import SwiftData

/// View model for the Book Reader screen
@MainActor @Observable
final class ReaderViewModel {
    var book: Book
    var chapters: [BookChapter] = []
    var currentChapterIndex: Int = 0
    var isLoading: Bool = true
    var errorMessage: String?
    var showTableOfContents: Bool = false
    var showSettings: Bool = false
    var showBookmarkSheet: Bool = false
    var isToolbarVisible: Bool = true
    var scrollOffset: Double = 0
    var isSpeaking: Bool = false

    private var modelContext: ModelContext?

    init(book: Book) {
        self.book = book
        self.currentChapterIndex = book.readingProgress?.currentChapter ?? 0
        self.scrollOffset = book.readingProgress?.scrollOffset ?? 0
    }

    var currentChapter: BookChapter? {
        guard currentChapterIndex >= 0, currentChapterIndex < chapters.count else {
            return nil
        }
        return chapters[currentChapterIndex]
    }

    var progressText: String {
        guard !chapters.isEmpty else { return "" }
        return "Chapter \(currentChapterIndex + 1) of \(chapters.count)"
    }

    var progressPercentage: Double {
        guard !chapters.isEmpty else { return 0 }
        return Double(currentChapterIndex + 1) / Double(chapters.count)
    }

    var canGoToPreviousChapter: Bool {
        currentChapterIndex > 0
    }

    var canGoToNextChapter: Bool {
        currentChapterIndex < chapters.count - 1
    }

    // MARK: - Actions

    func loadBook(modelContext: ModelContext) async {
        self.modelContext = modelContext
        isLoading = true

        guard let fileURL = book.fileURLValue else {
            errorMessage = "Book file not found"
            isLoading = false
            return
        }

        do {
            let parsedBook = try await BookParserService.shared.parse(fileURL: fileURL)
            chapters = parsedBook.chapters

            // Restore reading position
            if let progress = book.readingProgress {
                currentChapterIndex = min(progress.currentChapter, chapters.count - 1)
            }

            book.lastOpened = Date()
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func goToNextChapter() {
        guard canGoToNextChapter else { return }
        currentChapterIndex += 1
        saveProgress()
    }

    func goToPreviousChapter() {
        guard canGoToPreviousChapter else { return }
        currentChapterIndex -= 1
        saveProgress()
    }

    func goToChapter(at index: Int) {
        guard index >= 0, index < chapters.count else { return }
        currentChapterIndex = index
        showTableOfContents = false
        saveProgress()
    }

    func toggleToolbar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isToolbarVisible.toggle()
        }
    }

    func addBookmark(title: String, modelContext: ModelContext) {
        let bookmark = Bookmark(
            title: title,
            chapter: currentChapterIndex,
            page: currentChapterIndex,
            textSnippet: String(currentChapter?.content.prefix(100) ?? "")
        )
        bookmark.book = book
        book.bookmarks.append(bookmark)
        try? modelContext.save()
    }

    func removeBookmark(_ bookmark: Bookmark, modelContext: ModelContext) {
        book.bookmarks.removeAll { $0.id == bookmark.id }
        modelContext.delete(bookmark)
        try? modelContext.save()
    }

    func updateScrollOffset(_ offset: Double) {
        scrollOffset = offset
        book.readingProgress?.updateScrollOffset(offset)
        // Don't save on every scroll — debounce in the view
    }

    func saveScrollPosition() {
        guard let modelContext else { return }
        book.readingProgress?.updateScrollOffset(scrollOffset)
        try? modelContext.save()
    }

    // MARK: - Text-to-Speech

    private var ttsService: TextToSpeechService { TextToSpeechService.shared }

    func toggleSpeech() {
        if isSpeaking {
            ttsService.stop()
            isSpeaking = false
        } else if let chapter = currentChapter {
            ttsService.speak(chapter.content)
            isSpeaking = true
        }
    }

    func stopSpeech() {
        ttsService.stop()
        isSpeaking = false
    }

    // MARK: - Private

    private func saveProgress() {
        guard let modelContext else { return }

        if let progress = book.readingProgress {
            progress.updateProgress(
                chapter: currentChapterIndex,
                page: currentChapterIndex,
                totalPages: chapters.count
            )
            progress.updateScrollOffset(scrollOffset)
        } else {
            let progress = ReadingProgress(
                currentChapter: currentChapterIndex,
                currentPage: currentChapterIndex,
                totalPages: chapters.count
            )
            book.readingProgress = progress
        }

        try? modelContext.save()
    }
}
