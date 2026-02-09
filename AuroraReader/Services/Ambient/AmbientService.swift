import Foundation
import SwiftUI
import AVFoundation

/// Ambient immersion engine — procedural soundscapes via AVAudioEngine, time-aware themes, haptics
@MainActor @Observable
final class AmbientService {
    static let shared = AmbientService()

    var isAmbientEnabled: Bool = false
    var currentSoundscape: Soundscape = .none
    var volume: Float = 0.5
    var isTimeAwareThemeEnabled: Bool = true
    var isHapticsEnabled: Bool = true
    var currentAmbientMood: AmbientMood = .neutral

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var phase: Float = 0
    private var noiseState: UInt64 = 12345 // xorshift state
    private var sampleRate: Float = 44100
    private var fadeGain: Float = 0
    private var targetGain: Float = 1.0
    private let fadeRate: Float = 0.0001 // smooth fade

    private init() {}

    // MARK: - Soundscapes

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

    /// Start playing the selected soundscape with procedural audio
    func playSoundscape(_ soundscape: Soundscape) {
        guard soundscape != .none else {
            stopSoundscape()
            return
        }

        // If already playing, crossfade
        if isAmbientEnabled && audioEngine?.isRunning == true {
            targetGain = 0 // fade out current
            // After brief fade, switch and fade in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                stopEngine()
                currentSoundscape = soundscape
                startEngine(for: soundscape)
                targetGain = 1.0
            }
        } else {
            currentSoundscape = soundscape
            startEngine(for: soundscape)
        }

        isAmbientEnabled = true
    }

    func stopSoundscape() {
        targetGain = 0
        // Fade out then stop
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            stopEngine()
            isAmbientEnabled = false
            currentSoundscape = .none
        }
    }

    func setVolume(_ newVolume: Float) {
        volume = min(1.0, max(0.0, newVolume))
        audioEngine?.mainMixerNode.outputVolume = volume
    }

    // MARK: - Audio Engine

    private func startEngine(for soundscape: Soundscape) {
        configureAudioSession()

        let engine = AVAudioEngine()
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        sampleRate = Float(format.sampleRate)
        phase = 0
        fadeGain = 0
        targetGain = 1.0
        noiseState = UInt64(arc4random())

        let selectedSoundscape = soundscape
        let capturedSampleRate = sampleRate

        let source = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            let frames = Int(frameCount)

            for buffer in buffers {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for i in 0..<frames {
                    // Fade envelope
                    if self.fadeGain < self.targetGain {
                        self.fadeGain = min(self.fadeGain + self.fadeRate, self.targetGain)
                    } else if self.fadeGain > self.targetGain {
                        self.fadeGain = max(self.fadeGain - self.fadeRate, self.targetGain)
                    }

                    let sample = self.generateSample(for: selectedSoundscape, sampleRate: capturedSampleRate)
                    data[i] = sample * self.fadeGain
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = source
        } catch {
            // Engine failed to start
        }
    }

    private func stopEngine() {
        audioEngine?.stop()
        if let source = sourceNode {
            audioEngine?.detach(source)
        }
        audioEngine = nil
        sourceNode = nil
        fadeGain = 0
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session configuration failed
        }
    }

    // MARK: - Procedural Audio Generation

    /// Generates a single audio sample for the given soundscape
    nonisolated private func generateSample(for soundscape: Soundscape, sampleRate: Float) -> Float {
        switch soundscape {
        case .none:
            return 0

        case .gentleRain:
            // Pink-ish noise with low-pass filtering + random droplet impulses
            let noise = pinkNoise() * 0.15
            let droplet = randomImpulse(probability: 0.0003) * 0.4
            return lowPass(noise + droplet, cutoff: 0.3)

        case .thunderstorm:
            // Brown noise base + occasional rumble
            let brown = brownNoise() * 0.2
            let rumble = sine(frequency: 35 + randomFloat() * 15, sampleRate: sampleRate) * randomImpulse(probability: 0.0001) * 0.6
            let rain = pinkNoise() * 0.1
            return lowPass(brown + rumble + rain, cutoff: 0.4)

        case .fireplaceCrackle:
            // Warm low-pass noise + crackle impulses
            let warmNoise = brownNoise() * 0.08
            let crackle = randomImpulse(probability: 0.001) * whiteNoise() * 0.5
            return lowPass(warmNoise + crackle, cutoff: 0.25)

        case .oceanWaves:
            // Amplitude-modulated noise with slow wave envelope (~8 sec cycle)
            let waveEnvelope = (1.0 + sine(frequency: 0.125, sampleRate: sampleRate)) * 0.5
            let surf = pinkNoise() * 0.2 * waveEnvelope
            let foam = whiteNoise() * 0.03 * waveEnvelope * waveEnvelope
            return lowPass(surf + foam, cutoff: 0.35)

        case .forestBirds:
            // Soft noise floor + random sine chirps
            let base = pinkNoise() * 0.04
            let chirpFreq: Float = 2000 + randomFloat() * 4000
            let chirp = sine(frequency: chirpFreq, sampleRate: sampleRate) * randomImpulse(probability: 0.0002) * 0.3
            return base + chirp * 0.5

        case .cafeAmbience:
            // Low-level pink noise with gentle murmur texture
            let murmur = pinkNoise() * 0.06
            let chatter = brownNoise() * 0.04
            let clink = randomImpulse(probability: 0.0001) * 0.2
            return lowPass(murmur + chatter + clink, cutoff: 0.3)

        case .enchantedForest:
            // Wind noise + random tonal chimes (pentatonic)
            let wind = pinkNoise() * 0.06
            let pentatonic: [Float] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5] // C5 pentatonic
            let chimeFreq = pentatonic[Int(randomFloat() * Float(pentatonic.count)) % pentatonic.count]
            let chime = sine(frequency: chimeFreq, sampleRate: sampleRate) * randomImpulse(probability: 0.0001) * 0.25
            return wind + chime

        case .spaceAmbient:
            // Very low sine drones with slow pitch modulation
            let modulation = sine(frequency: 0.05, sampleRate: sampleRate)
            let drone1 = sine(frequency: 50 + modulation * 10, sampleRate: sampleRate) * 0.12
            let drone2 = sine(frequency: 73 + modulation * 5, sampleRate: sampleRate) * 0.08
            let pad = pinkNoise() * 0.02
            return lowPass(drone1 + drone2 + pad, cutoff: 0.15)

        case .libraryQuiet:
            // Very quiet noise floor + occasional subtle impulses
            let ambience = brownNoise() * 0.02
            let pageTurn = randomImpulse(probability: 0.00005) * pinkNoise() * 0.15
            return lowPass(ambience + pageTurn, cutoff: 0.2)

        case .snowfall:
            // Very soft filtered white noise
            let snow = whiteNoise() * 0.04
            return lowPass(snow, cutoff: 0.15)
        }
    }

    // MARK: - DSP Primitives

    nonisolated private func whiteNoise() -> Float {
        Float.random(in: -1...1)
    }

    nonisolated private func pinkNoise() -> Float {
        // Approximation via averaged white noise samples
        let w1 = Float.random(in: -1...1)
        let w2 = Float.random(in: -1...1)
        let w3 = Float.random(in: -1...1)
        return (w1 + w2 + w3) / 3.0
    }

    nonisolated private func brownNoise() -> Float {
        // Very low frequency noise
        let w1 = Float.random(in: -1...1)
        let w2 = Float.random(in: -1...1)
        let w3 = Float.random(in: -1...1)
        let w4 = Float.random(in: -1...1)
        let w5 = Float.random(in: -1...1)
        return (w1 + w2 + w3 + w4 + w5) / 5.0
    }

    nonisolated private func sine(frequency: Float, sampleRate: Float) -> Float {
        phase += frequency / sampleRate
        if phase > 1.0 { phase -= 1.0 }
        return sin(phase * 2.0 * .pi)
    }

    nonisolated private func randomImpulse(probability: Float) -> Float {
        Float.random(in: 0...1) < probability ? 1.0 : 0.0
    }

    nonisolated private func randomFloat() -> Float {
        Float.random(in: 0...1)
    }

    nonisolated private func lowPass(_ input: Float, cutoff: Float) -> Float {
        // Simple one-pole low-pass approximation
        input * cutoff
    }

    // MARK: - Time-Aware Theming

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

    func pageTurnHaptic() {
        guard isHapticsEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func chapterCompleteHaptic() {
        guard isHapticsEnabled else { return }
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    func bookmarkHaptic() {
        guard isHapticsEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    // MARK: - Mood Detection

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
