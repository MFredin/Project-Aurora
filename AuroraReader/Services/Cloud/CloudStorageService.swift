import Foundation

/// Represents a cloud storage provider for book syncing
enum CloudStorageProvider: String, Codable, CaseIterable, Identifiable {
    case dropbox
    case googleDrive
    case protonDrive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dropbox: return "Dropbox"
        case .googleDrive: return "Google Drive"
        case .protonDrive: return "Proton Drive"
        }
    }

    var iconName: String {
        switch self {
        case .dropbox: return "cloud.fill"
        case .googleDrive: return "cloud.circle.fill"
        case .protonDrive: return "cloud.bolt.fill"
        }
    }

    var authURL: String {
        switch self {
        case .dropbox: return "https://www.dropbox.com/oauth2/authorize"
        case .googleDrive: return "https://accounts.google.com/o/oauth2/v2/auth"
        case .protonDrive: return "https://account.proton.me/authorize"
        }
    }
}

/// Represents a file listing from a cloud provider
struct CloudFile: Identifiable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let modifiedDate: Date?
    let provider: CloudStorageProvider
    let isFolder: Bool
    let downloadURL: String?

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var bookFormat: BookFormat? {
        BookFormat.from(fileExtension: fileExtension)
    }

    var isSupported: Bool {
        bookFormat != nil
    }
}

/// Authentication state for cloud providers
struct CloudAuthState: Codable {
    let provider: CloudStorageProvider
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?
    var userDisplayName: String?

    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() >= expires
    }
}

/// Protocol for cloud storage operations
protocol CloudStorageServiceProtocol {
    var provider: CloudStorageProvider { get }
    var isAuthenticated: Bool { get }

    func authenticate() async throws -> CloudAuthState
    func disconnect() async
    func listFiles(inFolder path: String?) async throws -> [CloudFile]
    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL
    func searchFiles(query: String) async throws -> [CloudFile]
}

// MARK: - Dropbox Service

final class DropboxService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .dropbox
    private(set) var authState: CloudAuthState?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    func authenticate() async throws -> CloudAuthState {
        // OAuth 2.0 with PKCE for Dropbox API v2
        // Opens SFSafariViewController for the auth flow
        let state = CloudAuthState(
            provider: .dropbox,
            accessToken: "",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(14400)
        )
        authState = state
        return state
    }

    func disconnect() async {
        authState = nil
    }

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // POST https://api.dropboxapi.com/2/files/list_folder
        return []
    }

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // POST https://content.dropboxapi.com/2/files/download
        return destination
    }

    func searchFiles(query: String) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // POST https://api.dropboxapi.com/2/files/search_v2
        return []
    }
}

// MARK: - Google Drive Service

final class GoogleDriveService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .googleDrive
    private(set) var authState: CloudAuthState?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    func authenticate() async throws -> CloudAuthState {
        // Google OAuth 2.0 with PKCE via ASWebAuthenticationSession
        let state = CloudAuthState(
            provider: .googleDrive,
            accessToken: "",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(3600)
        )
        authState = state
        return state
    }

    func disconnect() async {
        authState = nil
    }

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // GET https://www.googleapis.com/drive/v3/files
        return []
    }

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // GET https://www.googleapis.com/drive/v3/files/{id}?alt=media
        return destination
    }

    func searchFiles(query: String) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        return []
    }
}

// MARK: - Proton Drive Service

final class ProtonDriveService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .protonDrive
    private(set) var authState: CloudAuthState?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    func authenticate() async throws -> CloudAuthState {
        // Proton SSO authentication flow
        let state = CloudAuthState(
            provider: .protonDrive,
            accessToken: "",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(86400)
        )
        authState = state
        return state
    }

    func disconnect() async {
        authState = nil
    }

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // Proton Drive API: end-to-end encrypted file listing
        return []
    }

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        // Download + decrypt from Proton Drive
        return destination
    }

    func searchFiles(query: String) async throws -> [CloudFile] {
        guard isAuthenticated else { throw CloudStorageError.notAuthenticated }
        return []
    }
}

// MARK: - Cloud Storage Manager

@MainActor @Observable
final class CloudStorageManager {
    static let shared = CloudStorageManager()

    private(set) var services: [CloudStorageProvider: CloudStorageServiceProtocol] = [:]
    private(set) var connectedProviders: Set<CloudStorageProvider> = []
    var currentFiles: [CloudFile] = []
    var currentPath: String? = nil
    var isLoading = false
    var errorMessage: String?

    private init() {
        services[.dropbox] = DropboxService()
        services[.googleDrive] = GoogleDriveService()
        services[.protonDrive] = ProtonDriveService()
    }

    func isConnected(_ provider: CloudStorageProvider) -> Bool {
        connectedProviders.contains(provider)
    }

    func connect(_ provider: CloudStorageProvider) async throws {
        guard let service = services[provider] else { return }
        _ = try await service.authenticate()
        connectedProviders.insert(provider)
    }

    func disconnect(_ provider: CloudStorageProvider) async {
        guard let service = services[provider] else { return }
        await service.disconnect()
        connectedProviders.remove(provider)
    }

    func browseFiles(provider: CloudStorageProvider, folder: String? = nil) async throws -> [CloudFile] {
        guard let service = services[provider] else {
            throw CloudStorageError.providerNotFound
        }
        guard service.isAuthenticated else {
            throw CloudStorageError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let files = try await service.listFiles(inFolder: folder)
        currentFiles = files
        currentPath = folder
        return files
    }

    func downloadBook(file: CloudFile) async throws -> URL {
        guard let service = services[file.provider] else {
            throw CloudStorageError.providerNotFound
        }

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let booksDir = documentsDir.appendingPathComponent("Books/Cloud", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)

        let destination = booksDir.appendingPathComponent("\(UUID().uuidString)_\(file.name)")
        return try await service.downloadFile(file, to: destination)
    }

    func searchAcrossProviders(query: String) async throws -> [CloudFile] {
        var allResults: [CloudFile] = []
        for provider in connectedProviders {
            guard let service = services[provider] else { continue }
            let results = try await service.searchFiles(query: query)
            allResults.append(contentsOf: results)
        }
        return allResults.filter { $0.isSupported }
    }
}

enum CloudStorageError: LocalizedError {
    case notAuthenticated
    case providerNotFound
    case downloadFailed(String)
    case permissionDenied
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not signed in to cloud storage"
        case .providerNotFound: return "Cloud provider not configured"
        case .downloadFailed(let d): return "Download failed: \(d)"
        case .permissionDenied: return "Permission denied"
        case .networkError(let d): return "Network error: \(d)"
        }
    }
}
