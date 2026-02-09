import SwiftUI

/// Ambient immersion control panel for the reader
struct AmbientControlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ambientService = AmbientService.shared

    let bookTitle: String
    let genre: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Current mood
                        moodCard

                        // Soundscape selector
                        soundscapeSection

                        // Time-aware theme
                        timeAwareSection

                        // Haptics toggle
                        hapticsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Ambient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Mood Card

    private var moodCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(AuroraTheme.auroraPurple)
                Text("Reading Mood")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(AmbientMood.allCases, id: \.self) { mood in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(ambientService.currentAmbientMood == mood
                                  ? moodColor(mood)
                                  : AuroraTheme.surface)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(moodEmoji(mood))
                                    .font(.body)
                            }

                        Text(mood.rawValue)
                            .font(.caption2)
                            .foregroundStyle(
                                ambientService.currentAmbientMood == mood
                                    ? AuroraTheme.textPrimary
                                    : AuroraTheme.textTertiary
                            )
                    }
                    .onTapGesture {
                        ambientService.currentAmbientMood = mood
                    }
                }
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Soundscape Section

    private var soundscapeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(AuroraTheme.auroraTeal)
                Text("Soundscape")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()

                if ambientService.currentSoundscape != .none {
                    Button {
                        ambientService.stopSoundscape()
                    } label: {
                        Text("Stop")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AuroraTheme.auroraWarm)
                    }
                }
            }

            // Suggested soundscape
            let suggested = ambientService.recommendSoundscape(for: bookTitle, genre: genre)
            if suggested != .none {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.auroraGreen)
                    Text("Suggested: \(suggested.rawValue)")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textSecondary)
                    Spacer()
                    Button {
                        ambientService.playSoundscape(suggested)
                    } label: {
                        Text("Play")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AuroraTheme.auroraTeal)
                    }
                }
                .padding(10)
                .background(AuroraTheme.auroraGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            // All soundscapes
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(Soundscape.allCases) { soundscape in
                    Button {
                        ambientService.playSoundscape(soundscape)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: soundscape.iconName)
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    ambientService.currentSoundscape == soundscape
                                        ? AuroraTheme.auroraTeal
                                        : AuroraTheme.textSecondary
                                )

                            Text(soundscape.rawValue)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(
                                    ambientService.currentSoundscape == soundscape
                                        ? AuroraTheme.textPrimary
                                        : AuroraTheme.textTertiary
                                )
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ambientService.currentSoundscape == soundscape
                                ? AuroraTheme.auroraTeal.opacity(0.12)
                                : AuroraTheme.surface.opacity(0.5),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                }
            }

            // Volume slider
            if ambientService.currentSoundscape != .none {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)

                    Slider(
                        value: Binding(
                            get: { ambientService.volume },
                            set: { ambientService.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .tint(AuroraTheme.auroraTeal)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Time Aware Section

    private var timeAwareSection: some View {
        let theme = ambientService.timeAwareAdjustments()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: theme.iconName)
                    .foregroundStyle(AuroraTheme.auroraWarm)
                Text("Time-Aware Theme")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $ambientService.isTimeAwareThemeEnabled)
                    .tint(AuroraTheme.auroraTeal)
                    .labelsHidden()
            }

            if ambientService.isTimeAwareThemeEnabled {
                HStack(spacing: 12) {
                    Image(systemName: theme.iconName)
                        .font(.title2)
                        .foregroundStyle(AuroraTheme.auroraWarm)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AuroraTheme.textPrimary)
                        Text("Suggested: \(theme.suggestedTheme.displayName) theme")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Haptics Section

    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(AuroraTheme.auroraBlue)
                Text("Haptic Feedback")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $ambientService.isHapticsEnabled)
                    .tint(AuroraTheme.auroraTeal)
                    .labelsHidden()
            }

            if ambientService.isHapticsEnabled {
                Text("Subtle vibrations on page turns, bookmarks, and chapter completions")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Helpers

    private func moodEmoji(_ mood: AmbientMood) -> String {
        switch mood {
        case .neutral: return "😌"
        case .tense: return "😰"
        case .calm: return "🧘"
        case .melancholy: return "😢"
        case .joyful: return "😄"
        }
    }

    private func moodColor(_ mood: AmbientMood) -> Color {
        switch mood {
        case .neutral: return AuroraTheme.auroraTeal
        case .tense: return AuroraTheme.auroraWarm
        case .calm: return AuroraTheme.auroraGreen
        case .melancholy: return AuroraTheme.auroraBlue
        case .joyful: return AuroraTheme.auroraPink
        }
    }
}
