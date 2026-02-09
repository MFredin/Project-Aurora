import Foundation
import SwiftData
import SwiftUI

@Model
final class UserPreferences {
    var id: UUID
    var fontSizeRaw: Double
    var fontFamily: String
    var lineSpacing: Double
    var marginSize: Double
    var themeRaw: String
    var brightnessOverride: Double?
    var isScrollModeEnabled: Bool
    var keepScreenAwake: Bool

    init() {
        self.id = UUID()
        self.fontSizeRaw = 18.0
        self.fontFamily = "Georgia"
        self.lineSpacing = 1.4
        self.marginSize = 16.0
        self.themeRaw = ReaderTheme.light.rawValue
        self.brightnessOverride = nil
        self.isScrollModeEnabled = false
        self.keepScreenAwake = true
    }

    var fontSize: CGFloat {
        get { CGFloat(fontSizeRaw) }
        set { fontSizeRaw = Double(newValue) }
    }

    var theme: ReaderTheme {
        get { ReaderTheme(rawValue: themeRaw) ?? .light }
        set { themeRaw = newValue.rawValue }
    }

    static let availableFonts = [
        "Georgia",
        "Palatino",
        "Times New Roman",
        "San Francisco",
        "Helvetica Neue",
        "Avenir",
        "Charter",
        "Iowan Old Style"
    ]
}

enum ReaderTheme: String, Codable, CaseIterable {
    case light
    case sepia
    case dark
    case midnight

    var displayName: String {
        rawValue.capitalized
    }

    var backgroundColor: Color {
        switch self {
        case .light: return Color(.systemBackground)
        case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.87)
        case .dark: return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .midnight: return Color(red: 0.05, green: 0.05, blue: 0.08)
        }
    }

    var textColor: Color {
        switch self {
        case .light: return .primary
        case .sepia: return Color(red: 0.35, green: 0.25, blue: 0.15)
        case .dark: return Color(red: 0.85, green: 0.85, blue: 0.85)
        case .midnight: return Color(red: 0.7, green: 0.7, blue: 0.75)
        }
    }
}
