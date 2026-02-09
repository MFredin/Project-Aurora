import Foundation
import SwiftUI
import AVFoundation

/// Ambient immersion engine — dynamic soundscapes, time-aware themes, haptics
@Observable
final class AmbientService {
    static let shared = AmbientService()

    var isAmbientEnabled: Bool = false
    var currentSoundscape: Soundscape = .none
    var volume: Float = 0.5
    var isTimeAwareThemeEnabled: Bool = true
    var isHapticsEnabled: Bool = true
    var currentAmbientMood: AmbientMood = .neutral

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    // MARK: - Soundscapes

    /// Recommends a soundscape based on book genre/content
    func recommendSoundscape(for bookTitle: String, genre: String?) -> Soundscape {
        let title = bookTitle.lowercased()
        let genreLower = (genre ?? "").lowercased()

        if genreLower.contains("fantasy") || genreLower.contains("adventure") || title.contains("dragon") || title.contains("quest") {
            return .enchantedForest
        }
        if genreLower.contains("sci-fi") || genreLower.contains("science fiction") || title.contains("space") || title.contains("star") {
            return .spaceAmbient
        }
        if genreLower.contains("horror") || genreLower.contains("thriller") || title.contains("dark") || title.contains("night") {
            return .thunderstorm
        }
        if genreLower.contains("romance") || genreLower.contains("poetry") {
            return .gentleRain
        }
        if genreLower.contains("mystery") || genreLower.contains("detective") {
            return .cafeAmbience
        }
        if genreLower.contains("history") || genreLower.contains("classic") {
            return .fireplaceCrackle
        }
        return .gentleRain
    }

    /// Start playing the selected soundscape
    func playSoundscape(_ soundscape: Soundscape) {
        currentSoundscape = soundscape
        guard soundscape != .none else {
            stopSoundscape()
            return
        }
        isAmbientEnabled = true
        // In production, this would load and loop audio files
        // For now, we track the state
    }

    func stopSoundscape() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAmbientEnabled = false
        currentSoundscape = .none
    }

    func setVolume(_ newVolume: Float) {
        volume = min(1.0, max(0.0, newVolume))
        audioPlayer?.volume = volume
    }

    // MARK: - Time-Aware Theming

    /// Returns theme adjustments based on time of day
    func timeAwareAdjustments() -> TimeAwareTheme {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<10:
            return TimeAwareTheme(
                name: "Morning Light",
                warmthShift: 0.05,
                brightnessAdjust: 0.1,
                suggestedTheme: .sepia,
                iconName: "sunrise.fill"
            )
        case 10..<17:
            return TimeAwareTheme(
                name: "Daylight",
                warmthShift: 0.0,
                brightnessAdjust: 0.0,
                suggestedTheme: .light,
                iconName: "sun.max.fill"
            )
        case 17..<20:
            return TimeAwareTheme(
                name: "Golden Hour",
                warmthShift: 0.1,
                brightnessAdjust: -0.05,
                suggestedTheme: .sepia,
                iconName: "sunset.fill"
            )
        case 20..<23:
            return TimeAwareTheme(
                name: "Evening",
                warmthShift: 0.0,
                brightnessAdjust: -0.15,
                suggestedTheme: .dark,
                iconName: "moon.fill"
            )
        default:
            return TimeAwareTheme(
                name: "Night",
                warmthShift: -0.05,
                brightnessAdjust: -0.25,
                suggestedTheme: .midnight,
                iconName: "moon.stars.fill"
            )
        }
    }

    // MARK: - Page Turn Haptics

    /// Trigger page turn haptic feedback
    func pageTurnHaptic() {
        guard isHapticsEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// Trigger chapter completion haptic
    func chapterCompleteHaptic() {
        guard isHapticsEnabled else { return }
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    /// Trigger bookmark saved haptic
    func bookmarkHaptic() {
        guard isHapticsEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    // MARK: - Mood Detection

    /// Analyzes chapter content to set ambient mood
    func detectMood(from text: String) -> AmbientMood {
        let lowered = text.lowercased()
        let tenseWords = ["fight", "battle", "chase", "escape", "danger", "fear", "scream", "blood", "death", "war"]
        let calmWords = ["peace", "gentle", "quiet", "meadow", "garden", "sleep", "dream", "soft", "warm", "smile"]
        let sadWords = ["loss", "grief", "tears", "lonely", "farewell", "goodbye", "mourn", "sorrow", "miss", "empty"]
        let joyWords = ["laugh", "celebrate", "dance", "love", "happy", "joy", "victory", "friend", "together", "light"]

        let tenseScore = tenseWords.reduce(0) { $0 + (lowered.contains($1) ? 1 : 0) }
        let calmScore = calmWords.reduce(0) { $0 + (lowered.contains($1) ? 1 : 0) }
        let sadScore = sadWords.reduce(0) { $0 + (lowered.contains($1) ? 1 : 0) }
        let joyScore = joyWords.reduce(0) { $0 + (lowered.contains($1) ? 1 : 0) }

        let maxScore = max(tenseScore, calmScore, sadScore, joyScore)
        guard maxScore > 0 else { return .neutral }

        if tenseScore == maxScore { return .tense }
        if calmScore == maxScore { return .calm }
        if sadScore == maxScore { return .melancholy }
        if joyScore == maxScore { return .joyful }
        return .neutral
    }
}

// MARK: - Supporting Types

enum Soundscape: String, CaseIterable, Identifiable {
    case none = "None"
    case gentleRain = "Gentle Rain"
    case thunderstorm = "Thunderstorm"
    case fireplaceCrackle = "Fireplace"
    case oceanWaves = "Ocean Waves"
    case forestBirds = "Forest Birds"
    case cafeAmbience = "Cafe Ambience"
    case enchantedForest = "Enchanted Forest"
    case spaceAmbient = "Space Ambient"
    case libraryQuiet = "Library Quiet"
    case snowfall = "Snowfall"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .none: return "speaker.slash.circle.fill"
        case .gentleRain: return "cloud.drizzle.circle.fill"
        case .thunderstorm: return "cloud.bolt.circle.fill"
        case .fireplaceCrackle: return "flame.circle.fill"
        case .oceanWaves: return "water.waves"
        case .forestBirds: return "leaf.circle.fill"
        case .cafeAmbience: return "cup.and.saucer.fill"
        case .enchantedForest: return "sparkles"
        case .spaceAmbient: return "moon.stars.circle.fill"
        case .libraryQuiet: return "books.vertical.circle.fill"
        case .snowfall: return "snowflake.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .none: return "No ambient sound"
        case .gentleRain: return "Soft rain on a window"
        case .thunderstorm: return "Distant thunder and heavy rain"
        case .fireplaceCrackle: return "Warm crackling fireplace"
        case .oceanWaves: return "Waves lapping on the shore"
        case .forestBirds: return "Birdsong in a quiet forest"
        case .cafeAmbience: return "Soft chatter and clinking cups"
        case .enchantedForest: return "Mystical winds and chimes"
        case .spaceAmbient: return "Deep cosmic drones"
        case .libraryQuiet: return "Subtle pages turning and clock ticking"
        case .snowfall: return "Quiet winter with gentle wind"
        }
    }
}

enum AmbientMood: String, CaseIterable {
    case neutral = "Neutral"
    case tense = "Tense"
    case calm = "Calm"
    case melancholy = "Melancholy"
    case joyful = "Joyful"

    var suggestedSoundscape: Soundscape {
        switch self {
        case .neutral: return .libraryQuiet
        case .tense: return .thunderstorm
        case .calm: return .gentleRain
        case .melancholy: return .gentleRain
        case .joyful: return .forestBirds
        }
    }
}

struct TimeAwareTheme {
    let name: String
    let warmthShift: Double
    let brightnessAdjust: Double
    let suggestedTheme: ReaderTheme
    let iconName: String
}
