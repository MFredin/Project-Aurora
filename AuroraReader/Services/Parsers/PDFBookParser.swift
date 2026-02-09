import Foundation
import PDFKit

/// Parser for PDF format documents
final class PDFBookParser: BookParser {
    let supportedFormat: BookFormat = .pdf

    func parse(fileURL: URL) async throws -> ParsedBook {
        guard let pdfDocument = PDFDocument(url: fileURL) else {
            throw BookParserError.parsingFailed("Could not open PDF document")
        }

        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw BookParserError.parsingFailed("PDF has no pages")
        }

        // Extract metadata
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
            ?? fileURL.deletingPathExtension().lastPathComponent
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
            ?? "Unknown Author"

        var metadata: [String: String] = [:]
        if let subject = pdfDocument.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String {
            metadata["subject"] = subject
        }
        if let creator = pdfDocument.documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String {
            metadata["creator"] = creator
        }

        // Extract chapters based on PDF outline or fallback to page groups
        let chapters = extractChapters(from: pdfDocument)

        // Try to extract cover image from first page
        let coverImageData = extractCoverImage(from: pdfDocument)

        return ParsedBook(
            title: title,
            author: author,
            chapters: chapters,
            coverImageData: coverImageData,
            metadata: metadata
        )
    }

    // MARK: - Chapter Extraction

    private func extractChapters(from document: PDFDocument) -> [BookChapter] {
        // Try to use PDF outline (table of contents) first
        if let outlineChapters = extractChaptersFromOutline(document: document),
           !outlineChapters.isEmpty {
            return outlineChapters
        }

        // Fallback: group pages into chapters
        return extractChaptersByPageGroups(document: document)
    }

    private func extractChaptersFromOutline(document: PDFDocument) -> [BookChapter]? {
        guard let outline = document.outlineRoot, outline.numberOfChildren > 0 else {
            return nil
        }

        var chapters: [BookChapter] = []

        for i in 0..<outline.numberOfChildren {
            guard let item = outline.child(at: i) else { continue }
            let title = item.label ?? "Section \(i + 1)"

            var pageRange: Range<Int>?
            if let destination = item.destination, let page = destination.page,
               let pageIndex = document.index(for: page) {
                let startPage = pageIndex
                // Find end page (start of next chapter or end of document)
                var endPage = document.pageCount - 1
                if i + 1 < outline.numberOfChildren,
                   let nextItem = outline.child(at: i + 1),
                   let nextDest = nextItem.destination,
                   let nextPage = nextDest.page,
                   let nextIndex = document.index(for: nextPage) {
                    endPage = nextIndex - 1
                }
                pageRange = startPage..<(endPage + 1)
            }

            let content: String
            if let range = pageRange {
                content = extractText(from: document, pageRange: range)
            } else {
                content = ""
            }

            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chapters.append(BookChapter(index: i, title: title, content: content))
            }
        }

        return chapters.isEmpty ? nil : chapters
    }

    private func extractChaptersByPageGroups(document: PDFDocument) -> [BookChapter] {
        let pageCount = document.pageCount
        let pagesPerChapter = 20
        var chapters: [BookChapter] = []

        var chapterIndex = 0
        var currentPage = 0

        while currentPage < pageCount {
            let endPage = min(currentPage + pagesPerChapter, pageCount)
            let range = currentPage..<endPage

            let content = extractText(from: document, pageRange: range)
            let title: String
            if pageCount <= pagesPerChapter {
                title = "Full Document"
            } else {
                title = "Pages \(currentPage + 1)–\(endPage)"
            }

            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chapters.append(BookChapter(index: chapterIndex, title: title, content: content))
                chapterIndex += 1
            }

            currentPage = endPage
        }

        return chapters
    }

    private func extractText(from document: PDFDocument, pageRange: Range<Int>) -> String {
        var text = ""
        for pageIndex in pageRange {
            if let page = document.page(at: pageIndex),
               let pageText = page.string {
                text += pageText + "\n\n"
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Cover Image

    private func extractCoverImage(from document: PDFDocument) -> Data? {
        guard let firstPage = document.page(at: 0) else { return nil }

        let pageRect = firstPage.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let thumbnailSize = CGSize(
            width: min(pageRect.width * scale, 600),
            height: min(pageRect.height * scale, 800)
        )

        let thumbnail = firstPage.thumbnail(of: thumbnailSize, for: .mediaBox)
        return thumbnail.pngData()
    }
}
