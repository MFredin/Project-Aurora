import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Cloud Storage Provider

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

    /// Keychain keys for persisting auth tokens per provider
    var accessTokenKey: String { "aurora_\(rawValue)_access_token" }
    var refreshTokenKey: String { "aurora_\(rawValue)_refresh_token" }
    var expiresAtKey: String { "aurora_\(rawValue)_expires_at" }
    var userNameKey: String { "aurora_\(rawValue)_user_name" }
}

// MARK: - Cloud File

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

// MARK: - Cloud Auth State

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

    /// Persist tokens to Keychain
    func saveToKeychain() {
        KeychainHelper.save(key: provider.accessTokenKey, value: accessToken)
        if let refresh = refreshToken {
            KeychainHelper.save(key: provider.refreshTokenKey, value: refresh)
        }
        if let expires = expiresAt {
            KeychainHelper.save(key: provider.expiresAtKey, value: String(expires.timeIntervalSince1970))
        }
        if let name = userDisplayName {
            KeychainHelper.save(key: provider.userNameKey, value: name)
        }
    }

    /// Attempt to restore a saved auth state from Keychain
    static func loadFromKeychain(provider: CloudStorageProvider) -> CloudAuthState? {
        guard let accessToken = KeychainHelper.load(key: provider.accessTokenKey) else {
            return nil
        }
        let refreshToken = KeychainHelper.load(key: provider.refreshTokenKey)
        var expiresAt: Date? = nil
        if let expiresString = KeychainHelper.load(key: provider.expiresAtKey),
           let interval = Double(expiresString) {
            expiresAt = Date(timeIntervalSince1970: interval)
        }
        let userName = KeychainHelper.load(key: provider.userNameKey)
        return CloudAuthState(
            provider: provider,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            userDisplayName: userName
        )
    }

    /// Remove all tokens from Keychain
    static func clearKeychain(provider: CloudStorageProvider) {
        KeychainHelper.delete(key: provider.accessTokenKey)
        KeychainHelper.delete(key: provider.refreshTokenKey)
        KeychainHelper.delete(key: provider.expiresAtKey)
        KeychainHelper.delete(key: provider.userNameKey)
    }
}

// MARK: - Cloud Storage Error

enum CloudStorageError: LocalizedError {
    case notAuthenticated
    case providerNotFound
    case downloadFailed(String)
    case permissionDenied
    case networkError(String)
    case authenticationFailed(String)
    case missingAppKey(CloudStorageProvider)
    case unsupportedProvider(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not signed in to cloud storage"
        case .providerNotFound: return "Cloud provider not configured"
        case .downloadFailed(let d): return "Download failed: \(d)"
        case .permissionDenied: return "Permission denied"
        case .networkError(let d): return "Network error: \(d)"
        case .authenticationFailed(let d): return "Authentication failed: \(d)"
        case .missingAppKey(let p): return "No API key configured for \(p.displayName). Add it in Settings."
        case .unsupportedProvider(let d): return d
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

// MARK: - Cloud Storage Service Protocol

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

// MARK: - PKCE Helper

/// Generates PKCE code_verifier and code_challenge for OAuth2 flows
private enum PKCEHelper {
    static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationSession Presentation Context

/// Provides an anchor window for ASWebAuthenticationSession
private class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the first key window from connected scenes
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }
}

// MARK: - Dropbox Service

final class DropboxService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .dropbox
    private(set) var authState: CloudAuthState?

    private static let tokenURL = "https://api.dropboxapi.com/oauth2/token"
    private static let listFolderURL = "https://api.dropboxapi.com/2/files/list_folder"
    private static let downloadURL = "https://content.dropboxapi.com/2/files/download"
    private static let searchURL = "https://api.dropboxapi.com/2/files/search_v2"
    private static let callbackScheme = "aurora-reader"
    private static let redirectURI = "aurora-reader://oauth/dropbox"
    private static let appKeyKeychainKey = "aurora_dropbox_app_key"

    /// A strong reference kept alive during the auth session presentation
    private var presentationContext: AuthPresentationContext?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    /// Restores a previously saved auth state from the Keychain (called on init/restore)
    func restoreAuthState() {
        authState = CloudAuthState.loadFromKeychain(provider: .dropbox)
    }

    // MARK: Authenticate

    func authenticate() async throws -> CloudAuthState {
        guard let appKey = KeychainHelper.load(key: Self.appKeyKeychainKey) else {
            throw CloudStorageError.missingAppKey(.dropbox)
        }

        let codeVerifier = PKCEHelper.generateCodeVerifier()
        let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: CloudStorageProvider.dropbox.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: appKey),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "token_access_type", value: "offline")
        ]

        guard let authURL = components.url else {
            throw CloudStorageError.authenticationFailed("Failed to construct Dropbox auth URL")
        }

        // Present the ASWebAuthenticationSession on the main actor
        let callbackCode: String = try await withCheckedThrowingContinuation { continuation in
            let context = AuthPresentationContext()
            self.presentationContext = context

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Self.callbackScheme
            ) { [weak self] callbackURL, error in
                self?.presentationContext = nil
                if let error = error {
                    continuation.resume(throwing: CloudStorageError.authenticationFailed(error.localizedDescription))
                    return
                }
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: CloudStorageError.authenticationFailed("No authorization code received"))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = false

            DispatchQueue.main.async {
                session.start()
            }
        }

        // Exchange authorization code for tokens
        let state = try await exchangeDropboxCode(callbackCode, codeVerifier: codeVerifier, appKey: appKey)
        authState = state
        state.saveToKeychain()
        return state
    }

    /// Exchanges the authorization code for access + refresh tokens via Dropbox token endpoint
    private func exchangeDropboxCode(_ code: String, codeVerifier: String, appKey: String) async throws -> CloudAuthState {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code=\(code)",
            "grant_type=authorization_code",
            "client_id=\(appKey)",
            "redirect_uri=\(Self.redirectURI)",
            "code_verifier=\(codeVerifier)"
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.authenticationFailed("Dropbox token exchange failed: \(body)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw CloudStorageError.authenticationFailed("Invalid Dropbox token response")
        }

        let refreshToken = json["refresh_token"] as? String
        let expiresIn = json["expires_in"] as? Double
        let expiresAt = expiresIn.map { Date().addingTimeInterval($0) }

        return CloudAuthState(
            provider: .dropbox,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            userDisplayName: nil
        )
    }

    // MARK: Refresh Token

    /// Refreshes the access token using the stored refresh token
    private func refreshAccessToken() async throws {
        guard let refresh = authState?.refreshToken else {
            throw CloudStorageError.notAuthenticated
        }
        guard let appKey = KeychainHelper.load(key: Self.appKeyKeychainKey) else {
            throw CloudStorageError.missingAppKey(.dropbox)
        }

        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=refresh_token",
            "refresh_token=\(refresh)",
            "client_id=\(appKey)"
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudStorageError.authenticationFailed("Dropbox token refresh failed")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String else {
            throw CloudStorageError.authenticationFailed("Invalid Dropbox refresh response")
        }

        let expiresIn = json["expires_in"] as? Double
        let expiresAt = expiresIn.map { Date().addingTimeInterval($0) }

        authState = CloudAuthState(
            provider: .dropbox,
            accessToken: newAccessToken,
            refreshToken: refresh,
            expiresAt: expiresAt,
            userDisplayName: authState?.userDisplayName
        )
        authState?.saveToKeychain()
    }

    /// Ensures the access token is valid, refreshing if needed
    private func ensureValidToken() async throws -> String {
        guard let state = authState else { throw CloudStorageError.notAuthenticated }
        if state.isExpired {
            try await refreshAccessToken()
        }
        guard let token = authState?.accessToken else { throw CloudStorageError.notAuthenticated }
        return token
    }

    // MARK: Disconnect

    func disconnect() async {
        authState = nil
        CloudAuthState.clearKeychain(provider: .dropbox)
    }

    // MARK: List Files

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        let token = try await ensureValidToken()

        var request = URLRequest(url: URL(string: Self.listFolderURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let folderPath = (path?.isEmpty ?? true) ? "" : path!
        let body: [String: Any] = [
            "path": folderPath,
            "recursive": false,
            "include_mounted_folders": true,
            "limit": 200
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.networkError("Dropbox list_folder failed: \(msg)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["entries"] as? [[String: Any]] else {
            throw CloudStorageError.invalidResponse
        }

        return entries.compactMap { entry -> CloudFile? in
            guard let tag = entry[".tag"] as? String,
                  let name = entry["name"] as? String,
                  let pathDisplay = entry["path_display"] as? String else { return nil }

            let isFolder = (tag == "folder")
            let size = entry["size"] as? Int64 ?? 0
            var modifiedDate: Date? = nil
            if let modString = entry["client_modified"] as? String {
                let formatter = ISO8601DateFormatter()
                modifiedDate = formatter.date(from: modString)
            }
            let id = entry["id"] as? String ?? pathDisplay

            return CloudFile(
                id: id,
                name: name,
                path: pathDisplay,
                size: size,
                modifiedDate: modifiedDate,
                provider: .dropbox,
                isFolder: isFolder,
                downloadURL: nil
            )
        }
    }

    // MARK: Download File

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        let token = try await ensureValidToken()

        var request = URLRequest(url: URL(string: Self.downloadURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Dropbox requires path in a JSON header
        let apiArg: [String: Any] = ["path": file.path]
        if let argData = try? JSONSerialization.data(withJSONObject: apiArg),
           let argString = String(data: argData, encoding: .utf8) {
            request.setValue(argString, forHTTPHeaderField: "Dropbox-API-Arg")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.downloadFailed("Dropbox download error: \(msg)")
        }

        try data.write(to: destination, options: .atomic)
        return destination
    }

    // MARK: Search Files

    func searchFiles(query: String) async throws -> [CloudFile] {
        let token = try await ensureValidToken()

        var request = URLRequest(url: URL(string: Self.searchURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "query": query,
            "options": [
                "max_results": 50,
                "file_status": "active",
                "filename_only": false
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.networkError("Dropbox search failed: \(msg)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let matches = json["matches"] as? [[String: Any]] else {
            throw CloudStorageError.invalidResponse
        }

        return matches.compactMap { match -> CloudFile? in
            guard let metadata = match["metadata"] as? [String: Any],
                  let inner = metadata["metadata"] as? [String: Any],
                  let tag = inner[".tag"] as? String,
                  let name = inner["name"] as? String,
                  let pathDisplay = inner["path_display"] as? String else { return nil }

            let isFolder = (tag == "folder")
            let size = inner["size"] as? Int64 ?? 0
            var modifiedDate: Date? = nil
            if let modString = inner["client_modified"] as? String {
                let formatter = ISO8601DateFormatter()
                modifiedDate = formatter.date(from: modString)
            }
            let id = inner["id"] as? String ?? pathDisplay

            return CloudFile(
                id: id,
                name: name,
                path: pathDisplay,
                size: size,
                modifiedDate: modifiedDate,
                provider: .dropbox,
                isFolder: isFolder,
                downloadURL: nil
            )
        }
    }
}

// MARK: - Google Drive Service

final class GoogleDriveService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .googleDrive
    private(set) var authState: CloudAuthState?

    private static let tokenURL = "https://oauth2.googleapis.com/token"
    private static let filesURL = "https://www.googleapis.com/drive/v3/files"
    private static let callbackScheme = "aurora-reader"
    private static let redirectURI = "aurora-reader://oauth/google"
    private static let appKeyKeychainKey = "aurora_google_client_id"
    private static let scope = "https://www.googleapis.com/auth/drive.readonly"

    /// Ebook MIME types recognized by Google Drive
    private static let ebookMimeTypes = [
        "application/epub+zip",
        "application/pdf",
        "application/x-mobipocket-ebook",
        "text/plain",
        "application/x-fictionbook+xml",
        "application/vnd.comicbook+zip",
        "application/rtf"
    ]

    /// Builds a Drive API query string that filters for ebook MIME types
    private static var mimeTypeQuery: String {
        let clauses = ebookMimeTypes.map { "mimeType='\($0)'" }
        return "(\(clauses.joined(separator: " or ")))"
    }

    /// A strong reference kept alive during the auth session presentation
    private var presentationContext: AuthPresentationContext?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    /// Restores a previously saved auth state from the Keychain
    func restoreAuthState() {
        authState = CloudAuthState.loadFromKeychain(provider: .googleDrive)
    }

    // MARK: Authenticate

    func authenticate() async throws -> CloudAuthState {
        guard let clientId = KeychainHelper.load(key: Self.appKeyKeychainKey) else {
            throw CloudStorageError.missingAppKey(.googleDrive)
        }

        let codeVerifier = PKCEHelper.generateCodeVerifier()
        let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: CloudStorageProvider.googleDrive.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            throw CloudStorageError.authenticationFailed("Failed to construct Google auth URL")
        }

        let callbackCode: String = try await withCheckedThrowingContinuation { continuation in
            let context = AuthPresentationContext()
            self.presentationContext = context

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Self.callbackScheme
            ) { [weak self] callbackURL, error in
                self?.presentationContext = nil
                if let error = error {
                    continuation.resume(throwing: CloudStorageError.authenticationFailed(error.localizedDescription))
                    return
                }
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: CloudStorageError.authenticationFailed("No authorization code received"))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = false

            DispatchQueue.main.async {
                session.start()
            }
        }

        let state = try await exchangeGoogleCode(callbackCode, codeVerifier: codeVerifier, clientId: clientId)
        authState = state
        state.saveToKeychain()
        return state
    }

    /// Exchanges the authorization code for Google OAuth tokens
    private func exchangeGoogleCode(_ code: String, codeVerifier: String, clientId: String) async throws -> CloudAuthState {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code=\(code)",
            "client_id=\(clientId)",
            "redirect_uri=\(Self.redirectURI)",
            "grant_type=authorization_code",
            "code_verifier=\(codeVerifier)"
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.authenticationFailed("Google token exchange failed: \(body)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw CloudStorageError.authenticationFailed("Invalid Google token response")
        }

        let refreshToken = json["refresh_token"] as? String
        let expiresIn = json["expires_in"] as? Double
        let expiresAt = expiresIn.map { Date().addingTimeInterval($0) }

        return CloudAuthState(
            provider: .googleDrive,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            userDisplayName: nil
        )
    }

    // MARK: Refresh Token

    private func refreshAccessToken() async throws {
        guard let refresh = authState?.refreshToken else {
            throw CloudStorageError.notAuthenticated
        }
        guard let clientId = KeychainHelper.load(key: Self.appKeyKeychainKey) else {
            throw CloudStorageError.missingAppKey(.googleDrive)
        }

        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=refresh_token",
            "refresh_token=\(refresh)",
            "client_id=\(clientId)"
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudStorageError.authenticationFailed("Google token refresh failed")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String else {
            throw CloudStorageError.authenticationFailed("Invalid Google refresh response")
        }

        let expiresIn = json["expires_in"] as? Double
        let expiresAt = expiresIn.map { Date().addingTimeInterval($0) }

        authState = CloudAuthState(
            provider: .googleDrive,
            accessToken: newAccessToken,
            refreshToken: refresh,
            expiresAt: expiresAt,
            userDisplayName: authState?.userDisplayName
        )
        authState?.saveToKeychain()
    }

    /// Ensures the access token is valid, refreshing if needed
    private func ensureValidToken() async throws -> String {
        guard let state = authState else { throw CloudStorageError.notAuthenticated }
        if state.isExpired {
            try await refreshAccessToken()
        }
        guard let token = authState?.accessToken else { throw CloudStorageError.notAuthenticated }
        return token
    }

    // MARK: Disconnect

    func disconnect() async {
        authState = nil
        CloudAuthState.clearKeychain(provider: .googleDrive)
    }

    // MARK: List Files

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        let token = try await ensureValidToken()

        var components = URLComponents(string: Self.filesURL)!

        // Build the query: filter by ebook mime types, optionally within a folder
        var queryParts = [Self.mimeTypeQuery, "trashed=false"]
        if let folderId = path, !folderId.isEmpty {
            queryParts.append("'\(folderId)' in parents")
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: queryParts.joined(separator: " and ")),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,size,modifiedTime,parents)"),
            URLQueryItem(name: "pageSize", value: "200"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.networkError("Google Drive list failed: \(msg)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [[String: Any]] else {
            throw CloudStorageError.invalidResponse
        }

        return files.compactMap { file -> CloudFile? in
            guard let id = file["id"] as? String,
                  let name = file["name"] as? String else { return nil }

            let mimeType = file["mimeType"] as? String ?? ""
            let isFolder = (mimeType == "application/vnd.google-apps.folder")
            let sizeString = file["size"] as? String ?? "0"
            let size = Int64(sizeString) ?? 0
            var modifiedDate: Date? = nil
            if let modString = file["modifiedTime"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                modifiedDate = formatter.date(from: modString)
            }

            return CloudFile(
                id: id,
                name: name,
                path: id, // Google Drive uses file IDs rather than paths
                size: size,
                modifiedDate: modifiedDate,
                provider: .googleDrive,
                isFolder: isFolder,
                downloadURL: "\(Self.filesURL)/\(id)?alt=media"
            )
        }
    }

    // MARK: Download File

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        let token = try await ensureValidToken()

        let downloadURLString = "\(Self.filesURL)/\(file.id)?alt=media"
        guard let url = URL(string: downloadURLString) else {
            throw CloudStorageError.downloadFailed("Invalid download URL for \(file.name)")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.downloadFailed("Google Drive download error: \(msg)")
        }

        try data.write(to: destination, options: .atomic)
        return destination
    }

    // MARK: Search Files

    func searchFiles(query: String) async throws -> [CloudFile] {
        let token = try await ensureValidToken()

        var components = URLComponents(string: Self.filesURL)!
        let searchQuery = "name contains '\(query)' and \(Self.mimeTypeQuery) and trashed=false"
        components.queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,size,modifiedTime,parents)"),
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw CloudStorageError.networkError("Google Drive search failed: \(msg)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [[String: Any]] else {
            throw CloudStorageError.invalidResponse
        }

        return files.compactMap { file -> CloudFile? in
            guard let id = file["id"] as? String,
                  let name = file["name"] as? String else { return nil }

            let mimeType = file["mimeType"] as? String ?? ""
            let isFolder = (mimeType == "application/vnd.google-apps.folder")
            let sizeString = file["size"] as? String ?? "0"
            let size = Int64(sizeString) ?? 0
            var modifiedDate: Date? = nil
            if let modString = file["modifiedTime"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                modifiedDate = formatter.date(from: modString)
            }

            return CloudFile(
                id: id,
                name: name,
                path: id,
                size: size,
                modifiedDate: modifiedDate,
                provider: .googleDrive,
                isFolder: isFolder,
                downloadURL: "\(Self.filesURL)/\(id)?alt=media"
            )
        }
    }
}

// MARK: - Proton Drive Service

/// Proton Drive integration stub.
///
/// Proton Drive requires Proton's proprietary SDK (ProtonCore) for authentication
/// and end-to-end encrypted file operations. The SDK handles SRP authentication,
/// key management, and encrypted file transfers which cannot be replicated via
/// simple REST calls. Once the ProtonCore SDK is integrated as a dependency,
/// this service should be implemented using:
///   - `ProtonCore-Login` for authentication
///   - `ProtonCore-Crypto` for key/passphrase operations
///   - `PMDrive` (Proton Drive module) for file listing, download, and search
final class ProtonDriveService: CloudStorageServiceProtocol {
    let provider: CloudStorageProvider = .protonDrive
    private(set) var authState: CloudAuthState?

    var isAuthenticated: Bool { authState != nil && !(authState?.isExpired ?? true) }

    func authenticate() async throws -> CloudAuthState {
        // Proton Drive requires Proton's proprietary SDK (ProtonCore) for SRP-based
        // authentication and end-to-end encrypted file operations. Standard OAuth2
        // flows are not supported. Integrate the ProtonCore SDK to enable this provider.
        throw CloudStorageError.unsupportedProvider(
            "Proton Drive requires Proton's proprietary SDK (ProtonCore) for authentication. " +
            "Standard OAuth2 is not supported. Please integrate ProtonCore-Login and PMDrive."
        )
    }

    func disconnect() async {
        authState = nil
        CloudAuthState.clearKeychain(provider: .protonDrive)
    }

    func listFiles(inFolder path: String?) async throws -> [CloudFile] {
        throw CloudStorageError.unsupportedProvider("Proton Drive requires the ProtonCore SDK")
    }

    func downloadFile(_ file: CloudFile, to destination: URL) async throws -> URL {
        throw CloudStorageError.unsupportedProvider("Proton Drive requires the ProtonCore SDK")
    }

    func searchFiles(query: String) async throws -> [CloudFile] {
        throw CloudStorageError.unsupportedProvider("Proton Drive requires the ProtonCore SDK")
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

    /// Tracks which providers have API keys configured in the Keychain
    var appKeys: [CloudStorageProvider: String] {
        var keys: [CloudStorageProvider: String] = [:]
        if let dbKey = KeychainHelper.load(key: "aurora_dropbox_app_key") {
            keys[.dropbox] = dbKey
        }
        if let gKey = KeychainHelper.load(key: "aurora_google_client_id") {
            keys[.googleDrive] = gKey
        }
        // Proton Drive does not use a simple API key
        return keys
    }

    private init() {
        let dropboxService = DropboxService()
        let googleService = GoogleDriveService()
        let protonService = ProtonDriveService()

        services[.dropbox] = dropboxService
        services[.googleDrive] = googleService
        services[.protonDrive] = protonService

        // Restore any previously saved auth states from Keychain
        restoreSavedAuthStates()
    }

    /// Restores saved authentication states from Keychain on launch.
    /// If valid (non-expired) tokens exist for a provider, marks it as connected.
    private func restoreSavedAuthStates() {
        if let dropbox = services[.dropbox] as? DropboxService {
            dropbox.restoreAuthState()
            if dropbox.isAuthenticated {
                connectedProviders.insert(.dropbox)
            }
        }
        if let google = services[.googleDrive] as? GoogleDriveService {
            google.restoreAuthState()
            if google.isAuthenticated {
                connectedProviders.insert(.googleDrive)
            }
        }
        // Proton Drive cannot be restored without the proprietary SDK
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
