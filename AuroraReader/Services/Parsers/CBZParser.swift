import Foundation

/// Parser for CBZ (Comic Book ZIP) and CBR (Comic Book RAR) archives
/// Extracts sequential images as "pages" for comic reading
final class CBZParser: BookParser {
    let supportedFormat: BookFormat = .cbz

    func parse(fileURL: URL) async throws -> ParsedBook {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cbz_\(UUID().uuidString)")

        defer { try? FileManager.default.removeItem(at: tempDir) }

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // CBZ is a ZIP archive containing images
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", fileURL.path, "-d", tempDir.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw BookParserError.parsingFailed("Could not extract CBZ archive")
        }

        // Find all image files, sorted by name
        let imageExtensions = Set(["jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff"])
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: tempDir, includingPropertiesForKeys: nil) else {
            throw BookParserError.parsingFailed("Could not read archive contents")
        }

        var imageFiles: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if imageExtensions.contains(fileURL.pathExtension.lowercased()) {
                imageFiles.append(fileURL)
            }
        }

        imageFiles.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        guard !imageFiles.isEmpty else {
            throw BookParserError.parsingFailed("No images found in comic archive")
        }

        // Use first image as cover
        let coverData = try? Data(contentsOf: imageFiles[0])

        // Group images into chapters (every 20 pages)
        let pagesPerChapter = 20
        var chapters: [BookChapter] = []
        for i in stride(from: 0, to: imageFiles.count, by: pagesPerChapter) {
            let end = min(i + pagesPerChapter, imageFiles.count)
            let pageList = (i..<end).map { "Page \($0 + 1)" }.joined(separator: "\n")
            let title = imageFiles.count <= pagesPerChapter
                ? "Full Comic"
                : "Pages \(i + 1)-\(end)"
            chapters.append(BookChapter(index: chapters.count, title: title, content: pageList))
        }

        let title = fileURL.deletingPathExtension().lastPathComponent

        return ParsedBook(
            title: title,
            author: "Unknown Author",
            chapters: chapters,
            coverImageData: coverData,
            metadata: ["pages": "\(imageFiles.count)", "format": "CBZ"]
        )
    }
}

/// CBR parser (Comic Book RAR) - same structure, different archive format
final class CBRParser: BookParser {
    let supportedFormat: BookFormat = .cbr

    func parse(fileURL: URL) async throws -> ParsedBook {
        // CBR uses RAR compression - requires unrar utility
        // Structure is identical to CBZ but with RAR archive
        throw BookParserError.parsingFailed("CBR support requires the unrar utility. Consider converting to CBZ format.")
    }
}
