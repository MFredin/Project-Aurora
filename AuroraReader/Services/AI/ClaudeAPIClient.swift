import Foundation

/// Client for interacting with the Anthropic Claude API
actor ClaudeAPIClient {
    static let shared = ClaudeAPIClient()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let apiKeyKey = "aurora_claude_api_key"

    var apiKey: String {
        UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
    }

    /// Sends a message to the Claude API and returns the text response
    func sendMessage(
        system: String,
        userMessage: String,
        model: String = "claude-sonnet-4-5-20250929",
        maxTokens: Int = 4096
    ) async throws -> String {
        guard isConfigured else {
            throw ClaudeAPIError.noAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ClaudeAPIError.parseError
        }

        return text
    }
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case parseError
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Claude API key not configured. Add your key in Settings → AI & Services."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from Claude API."
        case .parseError:
            return "Could not parse Claude API response."
        case .apiError(let code, let message):
            if code == 401 { return "Invalid API key. Check your key in Settings." }
            if code == 429 { return "Rate limit reached. Please wait a moment and try again." }
            return "API error (\(code)): \(message)"
        }
    }
}
