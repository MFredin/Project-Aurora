import Foundation
import Compression

/// Pure-Swift ZIP extraction for iOS (replaces macOS-only Process/unzip)
/// Handles the ZIP format used by EPUB and CBZ files
enum ZIPExtractor {

    enum ZIPError: LocalizedError {
        case invalidArchive
        case decompressionFailed(String)
        case fileSystemError(String)

        var errorDescription: String? {
            switch self {
            case .invalidArchive: return "File is not a valid ZIP archive."
            case .decompressionFailed(let msg): return "Decompression failed: \(msg)"
            case .fileSystemError(let msg): return "File system error: \(msg)"
            }
        }
    }

    /// Extracts a ZIP archive to a destination directory
    static func extract(archiveURL: URL, to destinationURL: URL) throws {
        let data = try Data(contentsOf: archiveURL)

        // Verify ZIP magic bytes (PK\x03\x04)
        guard data.count > 4,
              data[0] == 0x50, data[1] == 0x4B,
              data[2] == 0x03, data[3] == 0x04 else {
            throw ZIPError.invalidArchive
        }

        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        // Parse local file headers
        var offset = 0
        while offset + 30 <= data.count {
            // Check for local file header signature PK\x03\x04
            guard data[offset] == 0x50, data[offset + 1] == 0x4B,
                  data[offset + 2] == 0x03, data[offset + 3] == 0x04 else {
                break
            }

            let compressionMethod = UInt16(data[offset + 8]) | (UInt16(data[offset + 9]) << 8)
            let compressedSize = readUInt32(data, at: offset + 18)
            let uncompressedSize = readUInt32(data, at: offset + 22)
            let fileNameLength = Int(UInt16(data[offset + 26]) | (UInt16(data[offset + 27]) << 8))
            let extraFieldLength = Int(UInt16(data[offset + 28]) | (UInt16(data[offset + 29]) << 8))

            let fileNameStart = offset + 30
            let fileNameEnd = fileNameStart + fileNameLength

            guard fileNameEnd <= data.count else { break }

            let fileNameData = data[fileNameStart..<fileNameEnd]
            guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                offset = fileNameEnd + extraFieldLength + Int(compressedSize)
                continue
            }

            let dataStart = fileNameEnd + extraFieldLength
            let dataEnd = dataStart + Int(compressedSize)

            guard dataEnd <= data.count else { break }

            let fileURL = destinationURL.appendingPathComponent(fileName)

            // Sanitize path to prevent zip slip attacks
            let canonicalDest = destinationURL.standardizedFileURL.path
            let canonicalFile = fileURL.standardizedFileURL.path
            guard canonicalFile.hasPrefix(canonicalDest) else {
                offset = dataEnd
                continue
            }

            if fileName.hasSuffix("/") {
                // Directory entry
                try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
            } else {
                // File entry
                let parentDir = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

                let compressedData = data[dataStart..<dataEnd]

                switch compressionMethod {
                case 0:
                    // Stored (no compression)
                    try Data(compressedData).write(to: fileURL)

                case 8:
                    // Deflate
                    let decompressed = try decompressDeflate(
                        Data(compressedData),
                        expectedSize: Int(uncompressedSize)
                    )
                    try decompressed.write(to: fileURL)

                default:
                    // Skip unsupported compression methods
                    break
                }
            }

            offset = dataEnd
        }
    }

    // MARK: - Deflate Decompression

    private static func decompressDeflate(_ input: Data, expectedSize: Int) throws -> Data {
        let bufferSize = max(expectedSize, 65536)
        var outputData = Data(count: bufferSize)
        let inputCount = input.count

        let decompressedSize = input.withUnsafeBytes { inputPtr -> Int in
            guard let inputBase = inputPtr.baseAddress else { return 0 }
            return outputData.withUnsafeMutableBytes { outputPtr -> Int in
                guard let outputBase = outputPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                return compression_decode_buffer(
                    outputBase, bufferSize,
                    inputBase.assumingMemoryBound(to: UInt8.self), inputCount,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        guard decompressedSize > 0 else {
            throw ZIPError.decompressionFailed("Deflate decompression returned 0 bytes")
        }

        outputData.count = decompressedSize
        return outputData
    }

    // MARK: - Helpers

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
