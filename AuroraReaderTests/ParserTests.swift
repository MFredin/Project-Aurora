import Testing
import Foundation
@testable import AuroraReader

@Suite("BookParserService Tests")
struct BookParserServiceTests {

    @Test("Supported formats include all expected types")
    func supportedFormats() {
        let service = BookParserService.shared
        let formats = service.supportedFormats()
        #expect(formats.contains(.epub))
        #expect(formats.contains(.pdf))
        #expect(formats.contains(.plainText))
    }

    @Test("Supported extensions")
    func supportedExtensions() {
        let service = BookParserService.shared
        let extensions = service.supportedExtensions()
        #expect(extensions.contains("epub"))
        #expect(extensions.contains("pdf"))
        #expect(extensions.contains("txt"))
    }

    @Test("Unsupported format throws error")
    func unsupportedFormat() async {
        let url = URL(fileURLWithPath: "/tmp/test.xyz")
        do {
            _ = try await BookParserService.shared.parse(fileURL: url)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is BookParserError)
        }
    }
}

@Suite("PlainTextParser Tests")
struct PlainTextParserTests {
    let parser = PlainTextParser()

    @Test("Can parse txt files")
    func canParseTxt() {
        let url = URL(fileURLWithPath: "/test/book.txt")
        #expect(parser.canParse(fileURL: url))
    }

    @Test("Cannot parse non-txt files")
    func cannotParseOther() {
        let url = URL(fileURLWithPath: "/test/book.pdf")
        #expect(!parser.canParse(fileURL: url))
    }

    @Test("Parse simple text file")
    func parseSimpleText() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).txt")
        let content = "This is a simple test file.\nWith multiple lines.\nFor testing purposes."
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let parsed = try await parser.parse(fileURL: tempURL)
        #expect(!parsed.title.isEmpty)
        #expect(parsed.chapters.count >= 1)
        #expect(parsed.chapters.first?.content.contains("simple test") == true)
    }

    @Test("Parse text file with chapter markers")
    func parseChapters() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_chapters_\(UUID()).txt")
        let content = """
        Chapter 1 Introduction

        This is the first chapter with enough content to be meaningful.
        It contains multiple sentences to make it a reasonable chapter.
        We want to test that the parser correctly identifies chapter boundaries.

        Chapter 2 The Middle

        This is the second chapter with its own content.
        It also has multiple lines to provide sufficient text.
        The parser should split this into a separate chapter.

        Chapter 3 The End

        This is the final chapter of our test document.
        It wraps up the story nicely with a conclusion.
        Testing is now complete for chapter detection.
        """
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let parsed = try await parser.parse(fileURL: tempURL)
        #expect(parsed.chapters.count >= 2)
    }

    @Test("Author extraction from header")
    func authorExtraction() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_author_\(UUID()).txt")
        let content = """
        The Great Novel
        by Jane Smith

        Once upon a time in a land far away, there lived a brave adventurer.
        This story tells of their journey across the vast wilderness.
        """
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let parsed = try await parser.parse(fileURL: tempURL)
        #expect(parsed.author == "Jane Smith")
    }
}

@Suite("EPUBParser Tests")
struct EPUBParserTests {
    let parser = EPUBParser()

    @Test("Can parse epub files")
    func canParseEpub() {
        let url = URL(fileURLWithPath: "/test/book.epub")
        #expect(parser.canParse(fileURL: url))
    }

    @Test("Cannot parse non-epub files")
    func cannotParseOther() {
        let url = URL(fileURLWithPath: "/test/book.pdf")
        #expect(!parser.canParse(fileURL: url))
    }
}

@Suite("PDFBookParser Tests")
struct PDFBookParserTests {
    let parser = PDFBookParser()

    @Test("Can parse pdf files")
    func canParsePdf() {
        let url = URL(fileURLWithPath: "/test/book.pdf")
        #expect(parser.canParse(fileURL: url))
    }

    @Test("Cannot parse non-pdf files")
    func cannotParseOther() {
        let url = URL(fileURLWithPath: "/test/book.epub")
        #expect(!parser.canParse(fileURL: url))
    }
}
