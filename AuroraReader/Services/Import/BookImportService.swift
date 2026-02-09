import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Service responsible for importing book files into the app's document storage
final class BookImportService {
    static let shared = BookImportService()

    private let fileManager = FileManager.default

    private var booksDirectory: URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let booksDir = documentsDir.appendingPathComponent("Books", isDirectory: true)
        if !fileManager.fileExists(atPath: booksDir.path) {
            try? fileManager.createDirectory(at: booksDir, withIntermediateDirectories: true)
        }
        return booksDir
    }

    /// Import a book file from the given URL into app storage
    func importBook(from sourceURL: URL) async throws -> (url: URL, format: BookFormat, fileSize: Int64) {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let ext = sourceURL.pathExtension.lowercased()
        guard let format = BookFormat.from(fileExtension: ext) else {
            throw ImportError.unsupportedFormat(ext)
        }

        // Create unique filename to avoid collisions
        let uniqueName = "\(UUID().uuidString)_\(sourceURL.lastPathComponent)"
        let destinationURL = booksDirectory.appendingPathComponent(uniqueName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw ImportError.copyFailed(error.localizedDescription)
        }

        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        return (destinationURL, format, fileSize)
    }

    /// Delete a book file from app storage
    func deleteBook(at fileURL: URL) throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Get the supported UTTypes for the file picker
    static var supportedContentTypes: [UTType] {
        [
            UTType(filenameExtension: "epub") ?? .data,
            .pdf,
            .plainText,
        ]
    }
}

enum ImportError: LocalizedError {
    case unsupportedFormat(String)
    case copyFailed(String)
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported file format: .\(ext)"
        case .copyFailed(let detail):
            return "Failed to import file: \(detail)"
        case .parseFailed(let detail):
            return "Failed to parse book: \(detail)"
        }
    }
}
