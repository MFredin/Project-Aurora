import Foundation
import AVFoundation

/// Text-to-speech service using AVSpeechSynthesizer
@MainActor @Observable
final class TextToSpeechService: NSObject {
    static let shared = TextToSpeechService()

    var isSpeaking: Bool = false
    var isPaused: Bool = false
    var currentProgress: Double = 0
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var selectedVoiceIdentifier: String?
    var currentUtteranceText: String = ""

    private let synthesizer = AVSpeechSynthesizer()
    private var totalLength: Int = 0
    private var spokenLength: Int = 0

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Controls

    func speak(_ text: String) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.pitchMultiplier = pitch
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.0

        if let voiceId = selectedVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        totalLength = text.count
        spokenLength = 0
        currentUtteranceText = text
        isSpeaking = true
        isPaused = false

        configureAudioSession()
        synthesizer.speak(utterance)
    }

    func pause() {
        guard isSpeaking, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentProgress = 0
        spokenLength = 0
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    // MARK: - Voice Selection

    static var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
    }

    static var enhancedVoices: [AVSpeechSynthesisVoice] {
        availableVoices.filter { $0.quality == .enhanced }
    }

    // MARK: - Private

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Audio session configuration failed — speech will still work
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let spoken = characterRange.location + characterRange.length
        let total = utterance.speechString.count
        let progress = total > 0 ? Double(spoken) / Double(total) : 0

        Task { @MainActor in
            self.spokenLength = spoken
            self.currentProgress = progress
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentProgress = 1.0
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentProgress = 0
        }
    }
}
