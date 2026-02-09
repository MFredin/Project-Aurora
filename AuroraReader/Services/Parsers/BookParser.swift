import Foundation

/// Protocol defining the interface for all book format parsers
protocol BookParser {
    var supportedFormat: BookFormat { get }
    func parse(fileURL: URL) async throws -> ParsedBook
    func canParse(fileURL: URL) -> Bool
}

extension BookParser {
    func canParse(fileURL: URL) -> Bool {
        let ext = fileURL.pathExtension.lowercased()
        return BookFormat.from(fileExtension: ext) == supportedFormat
    }
}

/// Errors that can occur during book parsing
enum BookParserError: LocalizedError {
    case fileNotFound(URL)
    case invalidFormat(String)
    case parsingFailed(String)
    case unsupportedFormat(String)
    case corruptedFile(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .invalidFormat(let detail):
            return "Invalid format: \(detail)"
        case .parsingFailed(let detail):
            return "Parsing failed: \(detail)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .corruptedFile(let detail):
            return "Corrupted file: \(detail)"
        }
    }
}

/// Central service that delegates to format-specific parsers
final class BookParserService {
    static let shared = BookParserService()

    private var parsers: [BookFormat: BookParser] = [:]

    private init() {
        registerParser(EPUBParser())
        registerParser(PDFBookParser())
        registerParser(PlainTextParser())
    }

    func registerParser(_ parser: BookParser) {
        parsers[parser.supportedFormat] = parser
    }

    func parse(fileURL: URL) async throws -> ParsedBook {
        let ext = fileURL.pathExtension.lowercased()
        guard let format = BookFormat.from(fileExtension: ext) else {
            throw BookParserError.unsupportedFormat(ext)
        }
        guard let parser = parsers[format] else {
            throw BookParserError.unsupportedFormat(format.displayName)
        }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BookParserError.fileNotFound(fileURL)
        }
        return try await parser.parse(fileURL: fileURL)
    }

    func supportedFormats() -> [BookFormat] {
        Array(parsers.keys).sorted { $0.rawValue < $1.rawValue }
    }

    func supportedExtensions() -> [String] {
        parsers.keys.map { $0.fileExtension }
    }
}
