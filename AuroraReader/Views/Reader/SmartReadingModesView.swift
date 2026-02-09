import SwiftUI

/// Reading mode options for enhanced reading experiences
enum SmartReadingMode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case bionic = "Bionic"
    case focus = "Focus"
    case speed = "Speed"
    case accessibility = "Accessibility"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .standard: return "text.alignleft"
        case .bionic: return "bold"
        case .focus: return "scope"
        case .speed: return "gauge.with.needle.fill"
        case .accessibility: return "accessibility"
        }
    }

    var description: String {
        switch self {
        case .standard: return "Normal reading experience"
        case .bionic: return "Bold first letters for faster scanning"
        case .focus: return "Pomodoro timer with ambient sounds"
        case .speed: return "Rapid Serial Visual Presentation (RSVP)"
        case .accessibility: return "Dyslexia-friendly font, line ruler, spacing"
        }
    }
}

/// Configuration for Focus/Pomodoro reading mode
struct FocusConfig {
    var readingMinutes: Int = 25
    var breakMinutes: Int = 5
    var sessionsBeforeLongBreak: Int = 4
    var enableSoundscape: Bool = true
}

/// Configuration for Speed Reading mode (RSVP)
struct SpeedReadingConfig {
    var wordsPerMinute: Int = 300
    var chunkSize: Int = 1
    var showProgress: Bool = true
}

/// Configuration for Accessibility mode
struct AccessibilityConfig {
    var useDyslexicFont: Bool = true
    var showLineRuler: Bool = true
    var enhancedSpacing: Bool = true
    var tintColor: Color = AuroraTheme.auroraTeal
    var rulerOpacity: Double = 0.3
}

// MARK: - Reading Mode Selector Sheet

struct ReadingModeSelector: View {
    @Binding var selectedMode: SmartReadingMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(SmartReadingMode.allCases) { mode in
                            readingModeCard(mode)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Reading Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func readingModeCard(_ mode: SmartReadingMode) -> some View {
        Button {
            selectedMode = mode
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.iconName)
                    .font(.title3)
                    .foregroundStyle(selectedMode == mode ? AuroraTheme.auroraTeal : AuroraTheme.textSecondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.rawValue)
                        .font(.body.weight(.medium))
                        .foregroundStyle(AuroraTheme.textPrimary)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }

                Spacer()

                if selectedMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
            .padding(14)
            .auroraCard()
        }
    }
}

// MARK: - Bionic Text Renderer

struct BionicTextView: View {
    let text: String
    let fontSize: CGFloat
    let fontFamily: String
    let textColor: Color

    var body: some View {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let bionicText = words.map { word -> AttributedString in
            guard !word.isEmpty else { return AttributedString(" ") }
            let boldCount = max(1, word.count / 2)
            let boldPart = String(word.prefix(boldCount))
            let normalPart = String(word.dropFirst(boldCount))

            var bold = AttributedString(boldPart)
            bold.font = .custom(fontFamily, size: fontSize).bold()
            bold.foregroundColor = textColor

            var normal = AttributedString(normalPart + " ")
            normal.font = .custom(fontFamily, size: fontSize)
            normal.foregroundColor = textColor.opacity(0.7)

            return bold + normal
        }.reduce(AttributedString()) { $0 + $1 }

        Text(bionicText)
            .textSelection(.enabled)
    }
}

// MARK: - Speed Reading (RSVP) View

struct SpeedReadingView: View {
    let text: String
    @State private var config = SpeedReadingConfig()
    @State private var currentWordIndex = 0
    @State private var isPlaying = false
    @State private var timer: Timer?

    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    private var currentWord: String {
        guard currentWordIndex < words.count else { return "" }
        let endIndex = min(currentWordIndex + config.chunkSize, words.count)
        return words[currentWordIndex..<endIndex].joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 30) {
            // WPM control
            HStack {
                Text("\(config.wordsPerMinute) WPM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AuroraTheme.auroraTeal)

                Slider(value: Binding(
                    get: { Double(config.wordsPerMinute) },
                    set: { config.wordsPerMinute = Int($0) }
                ), in: 100...800, step: 50)
                .tint(AuroraTheme.auroraTeal)
            }
            .padding(.horizontal)

            Spacer()

            // Current word display
            VStack(spacing: 16) {
                Text(currentWord)
                    .font(.system(size: 36, weight: .medium, design: .serif))
                    .foregroundStyle(AuroraTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .animation(.none, value: currentWordIndex)

                // Focus indicator
                HStack(spacing: 0) {
                    Color.clear.frame(width: 80)
                    Rectangle()
                        .fill(AuroraTheme.auroraWarm)
                        .frame(width: 2, height: 20)
                    Color.clear.frame(width: 80)
                }
            }

            Spacer()

            // Progress
            VStack(spacing: 8) {
                ProgressView(value: Double(currentWordIndex), total: Double(max(words.count, 1)))
                    .tint(AuroraTheme.auroraTeal)

                Text("\(currentWordIndex)/\(words.count) words")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
            .padding(.horizontal)

            // Controls
            HStack(spacing: 40) {
                Button {
                    currentWordIndex = max(0, currentWordIndex - 10)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }

                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }

                Button {
                    currentWordIndex = min(words.count - 1, currentWordIndex + 10)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        let interval = 60.0 / Double(config.wordsPerMinute)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if currentWordIndex < words.count - config.chunkSize {
                currentWordIndex += config.chunkSize
            } else {
                isPlaying = false
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

// MARK: - Focus Mode Timer View

struct FocusModeView: View {
    @State private var config = FocusConfig()
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning = false
    @State private var isBreak = false
    @State private var completedSessions = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            // Timer display
            ZStack {
                Circle()
                    .stroke(AuroraTheme.surface, lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isBreak ? AuroraTheme.auroraGreen : AuroraTheme.auroraTeal,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .foregroundStyle(AuroraTheme.textPrimary)

                    Text(isBreak ? "Break" : "Reading")
                        .font(.caption)
                        .foregroundStyle(isBreak ? AuroraTheme.auroraGreen : AuroraTheme.auroraTeal)
                }
            }

            // Session indicators
            HStack(spacing: 8) {
                ForEach(0..<config.sessionsBeforeLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < completedSessions ? AuroraTheme.auroraTeal : AuroraTheme.surface)
                        .frame(width: 10, height: 10)
                }
            }

            // Controls
            HStack(spacing: 30) {
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }

                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }

                Button {
                    skipPhase()
                } label: {
                    Image(systemName: "forward.end.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textSecondary)
                }
            }
        }
        .padding()
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var progress: Double {
        let total = isBreak ? config.breakMinutes * 60 : config.readingMinutes * 60
        return 1.0 - (Double(timeRemaining) / Double(total))
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    phaseComplete()
                }
            }
        } else {
            timer?.invalidate()
        }
    }

    private func phaseComplete() {
        timer?.invalidate()
        isRunning = false

        if isBreak {
            isBreak = false
            timeRemaining = config.readingMinutes * 60
        } else {
            completedSessions += 1
            isBreak = true
            let isLongBreak = completedSessions % config.sessionsBeforeLongBreak == 0
            timeRemaining = (isLongBreak ? config.breakMinutes * 3 : config.breakMinutes) * 60
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        isRunning = false
        isBreak = false
        timeRemaining = config.readingMinutes * 60
    }

    private func skipPhase() {
        phaseComplete()
    }
}

// MARK: - Accessibility Reader View

struct AccessibilityOverlay: View {
    let lineHeight: CGFloat
    let rulerY: CGFloat
    let config: AccessibilityConfig

    var body: some View {
        if config.showLineRuler {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Dim area above
                    Color.black.opacity(config.rulerOpacity)
                        .frame(height: max(0, rulerY - lineHeight))

                    // Clear reading line
                    Color.clear
                        .frame(height: lineHeight * 2)

                    // Dim area below
                    Color.black.opacity(config.rulerOpacity)
                }
                .allowsHitTesting(false)
            }
        }
    }
}
