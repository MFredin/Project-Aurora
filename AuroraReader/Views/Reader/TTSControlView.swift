import SwiftUI
import AVFoundation

/// Floating TTS control panel for the reader
struct TTSControlView: View {
    @State private var ttsService = TextToSpeechService.shared
    let chapterContent: String
    let onDismiss: () -> Void

    @State private var showVoicePicker = false

    var body: some View {
        VStack(spacing: 12) {
            // Progress
            if ttsService.isSpeaking || ttsService.isPaused {
                ProgressView(value: ttsService.currentProgress)
                    .tint(AuroraTheme.auroraTeal)
            }

            // Controls
            HStack(spacing: 20) {
                // Rate control
                Menu {
                    ForEach([("0.5x", Float(0.35)), ("0.75x", Float(0.42)), ("1x", Float(0.5)), ("1.25x", Float(0.55)), ("1.5x", Float(0.62)), ("2x", Float(0.75))], id: \.0) { label, rate in
                        Button(label) {
                            ttsService.rate = rate
                        }
                    }
                } label: {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.body)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }

                Spacer()

                // Rewind (restart)
                Button {
                    ttsService.stop()
                    ttsService.speak(chapterContent)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.body)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }

                // Play/Pause
                Button {
                    if ttsService.isSpeaking {
                        ttsService.togglePause()
                    } else {
                        ttsService.speak(chapterContent)
                    }
                } label: {
                    Image(systemName: ttsService.isSpeaking && !ttsService.isPaused ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }

                // Stop
                Button {
                    ttsService.stop()
                    onDismiss()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.body)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }

                Spacer()

                // Voice picker
                Button {
                    showVoicePicker = true
                } label: {
                    Image(systemName: "person.wave.2.fill")
                        .font(.body)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .sheet(isPresented: $showVoicePicker) {
            voicePickerSheet
        }
    }

    private var voicePickerSheet: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                List {
                    let voices = TextToSpeechService.availableVoices
                    let enhanced = voices.filter { $0.quality == .enhanced }
                    let standard = voices.filter { $0.quality != .enhanced }

                    if !enhanced.isEmpty {
                        Section("Enhanced") {
                            ForEach(enhanced, id: \.identifier) { voice in
                                voiceRow(voice)
                            }
                        }
                        .listRowBackground(AuroraTheme.surface)
                    }

                    Section("Standard") {
                        ForEach(standard, id: \.identifier) { voice in
                            voiceRow(voice)
                        }
                    }
                    .listRowBackground(AuroraTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showVoicePicker = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func voiceRow(_ voice: AVSpeechSynthesisVoice) -> some View {
        Button {
            ttsService.selectedVoiceIdentifier = voice.identifier
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.name)
                        .foregroundStyle(AuroraTheme.textPrimary)
                    Text(voice.language)
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
                Spacer()
                if voice.quality == .enhanced {
                    Text("HD")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AuroraTheme.auroraTeal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AuroraTheme.auroraTeal.opacity(0.15), in: Capsule())
                }
                if ttsService.selectedVoiceIdentifier == voice.identifier {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
    }
}
