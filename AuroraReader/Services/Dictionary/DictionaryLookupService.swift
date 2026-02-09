import Foundation
import UIKit

/// Dictionary lookup service using the system dictionary
@MainActor @Observable
final class DictionaryLookupService {
    static let shared = DictionaryLookupService()

    var lastLookedUpWord: String = ""
    var recentLookups: [String] = []

    private let maxRecent = 50

    private init() {
        loadRecentLookups()
    }

    // MARK: - Lookup

    /// Check if a definition exists in the system dictionary
    func hasDefinition(for term: String) -> Bool {
        UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term)
    }

    /// Create a dictionary view controller for the given term
    func definitionViewController(for term: String) -> UIReferenceLibraryViewController? {
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, hasDefinition(for: cleaned) else { return nil }

        lastLookedUpWord = cleaned
        addToRecent(cleaned)
        return UIReferenceLibraryViewController(term: cleaned)
    }

    /// Extract the most likely word from a text selection
    func extractWord(from selection: String) -> String {
        let trimmed = selection.trimmingCharacters(in: .whitespacesAndNewlines)
        // If it's a single word, use it directly
        if !trimmed.contains(" ") {
            return trimmed
        }
        // If multi-word, take the first word
        return String(trimmed.split(separator: " ").first ?? Substring(trimmed))
    }

    // MARK: - Recent Lookups

    private func addToRecent(_ word: String) {
        recentLookups.removeAll { $0.lowercased() == word.lowercased() }
        recentLookups.insert(word, at: 0)
        if recentLookups.count > maxRecent {
            recentLookups = Array(recentLookups.prefix(maxRecent))
        }
        saveRecentLookups()
    }

    func clearRecentLookups() {
        recentLookups.removeAll()
        saveRecentLookups()
    }

    private func saveRecentLookups() {
        UserDefaults.standard.set(recentLookups, forKey: "aurora_recent_lookups")
    }

    private func loadRecentLookups() {
        recentLookups = UserDefaults.standard.stringArray(forKey: "aurora_recent_lookups") ?? []
    }
}

// MARK: - SwiftUI Bridge

import SwiftUI

/// SwiftUI wrapper for UIReferenceLibraryViewController
struct DictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
