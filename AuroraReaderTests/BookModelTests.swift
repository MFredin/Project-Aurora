import Testing
import Foundation
@testable import AuroraReader

@Suite("Book Model Tests")
struct BookModelTests {

    @Test("Book format detection from file extension")
    func formatDetection() {
        #expect(BookFormat.from(fileExtension: "epub") == .epub)
        #expect(BookFormat.from(fileExtension: "EPUB") == .epub)
        #expect(BookFormat.from(fileExtension: "pdf") == .pdf)
        #expect(BookFormat.from(fileExtension: "PDF") == .pdf)
        #expect(BookFormat.from(fileExtension: "txt") == .plainText)
        #expect(BookFormat.from(fileExtension: "text") == .plainText)
        #expect(BookFormat.from(fileExtension: "doc") == nil)
        #expect(BookFormat.from(fileExtension: "") == nil)
    }

    @Test("Book format display names")
    func formatDisplayNames() {
        #expect(BookFormat.epub.displayName == "EPUB")
        #expect(BookFormat.pdf.displayName == "PDF")
        #expect(BookFormat.plainText.displayName == "Plain Text")
    }

    @Test("Book format file extensions")
    func formatExtensions() {
        #expect(BookFormat.epub.fileExtension == "epub")
        #expect(BookFormat.pdf.fileExtension == "pdf")
        #expect(BookFormat.plainText.fileExtension == "txt")
    }

    @Test("Book initialization")
    func bookInit() {
        let url = URL(string: "file:///test/book.epub")!
        let book = Book(
            title: "Test Book",
            author: "Test Author",
            fileURL: url,
            format: .epub,
            fileSize: 1024
        )

        #expect(book.title == "Test Book")
        #expect(book.author == "Test Author")
        #expect(book.bookFormat == .epub)
        #expect(book.fileSize == 1024)
        #expect(book.lastOpened == nil)
        #expect(book.bookmarks.isEmpty)
    }

    @Test("Book default author")
    func bookDefaultAuthor() {
        let url = URL(string: "file:///test/book.pdf")!
        let book = Book(title: "Test", fileURL: url, format: .pdf)
        #expect(book.author == "Unknown Author")
    }

    @Test("Book formatted file size")
    func formattedFileSize() {
        let url = URL(string: "file:///test/book.epub")!
        let book = Book(title: "Test", fileURL: url, format: .epub, fileSize: 1_048_576)
        #expect(book.formattedFileSize.contains("MB") || book.formattedFileSize.contains("KB"))
    }
}

@Suite("BookChapter Tests")
struct BookChapterTests {

    @Test("Chapter word count")
    func wordCount() {
        let chapter = BookChapter(index: 0, title: "Test", content: "one two three four five")
        #expect(chapter.wordCount == 5)
    }

    @Test("Chapter reading time estimate")
    func readingTime() {
        let words = Array(repeating: "word", count: 500).joined(separator: " ")
        let chapter = BookChapter(index: 0, title: "Test", content: words)
        #expect(chapter.estimatedReadingTimeMinutes == 2)
    }

    @Test("Empty chapter minimum reading time")
    func emptyChapterReadingTime() {
        let chapter = BookChapter(index: 0, title: "Test", content: "")
        #expect(chapter.estimatedReadingTimeMinutes == 1)
    }
}

@Suite("ReadingProgress Tests")
struct ReadingProgressTests {

    @Test("Initial progress")
    func initialProgress() {
        let progress = ReadingProgress(currentChapter: 0, currentPage: 0, totalPages: 10)
        #expect(progress.progressPercentage == 0)
        #expect(progress.currentChapter == 0)
        #expect(progress.totalPages == 10)
    }

    @Test("Update progress")
    func updateProgress() {
        let progress = ReadingProgress(currentChapter: 0, currentPage: 0, totalPages: 10)
        progress.updateProgress(chapter: 5, page: 5, totalPages: 10)
        #expect(progress.currentChapter == 5)
        #expect(progress.progressPercentage == 0.5)
    }

    @Test("Zero total pages safety")
    func zeroTotalPages() {
        let progress = ReadingProgress(currentChapter: 0, currentPage: 0, totalPages: 0)
        #expect(progress.totalPages == 1) // Should clamp to 1
    }
}

@Suite("ParsedBook Tests")
struct ParsedBookTests {

    @Test("Total word count")
    func totalWordCount() {
        let chapters = [
            BookChapter(index: 0, title: "Ch1", content: "one two three"),
            BookChapter(index: 1, title: "Ch2", content: "four five six seven"),
        ]
        let book = ParsedBook(title: "Test", author: "Author", chapters: chapters, coverImageData: nil, metadata: [:])
        #expect(book.totalWordCount == 7)
    }

    @Test("Total reading time")
    func totalReadingTime() {
        let words = Array(repeating: "word", count: 750).joined(separator: " ")
        let chapters = [BookChapter(index: 0, title: "Ch1", content: words)]
        let book = ParsedBook(title: "Test", author: "Author", chapters: chapters, coverImageData: nil, metadata: [:])
        #expect(book.estimatedTotalReadingTimeMinutes == 3)
    }
}

@Suite("Bookmark Tests")
struct BookmarkTests {

    @Test("Bookmark initialization")
    func bookmarkInit() {
        let bookmark = Bookmark(title: "My Spot", chapter: 3, page: 3, textSnippet: "Some text here")
        #expect(bookmark.title == "My Spot")
        #expect(bookmark.chapter == 3)
        #expect(bookmark.textSnippet == "Some text here")
        #expect(bookmark.color == "blue")
    }
}

@Suite("ReaderTheme Tests")
struct ReaderThemeTests {

    @Test("All themes have display names")
    func displayNames() {
        for theme in ReaderTheme.allCases {
            #expect(!theme.displayName.isEmpty)
        }
    }

    @Test("Theme count")
    func themeCount() {
        #expect(ReaderTheme.allCases.count == 4)
    }
}
