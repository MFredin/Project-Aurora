import Foundation

extension URL {
    /// Returns the file size in bytes, or nil if not accessible
    var fileSize: Int64? {
        let values = try? resourceValues(forKeys: [.fileSizeKey])
        return values?.fileSize.map { Int64($0) }
    }

    /// Returns true if the file exists at this URL
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
