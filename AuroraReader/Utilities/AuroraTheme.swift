import SwiftUI

/// Aurora/Northern Lights themed design system for the app
enum AuroraTheme {
    // MARK: - Core Aurora Palette

    /// Deep space background
    static let deepSpace = Color(red: 0.04, green: 0.04, blue: 0.12)
    /// Slightly lighter space for cards
    static let cosmos = Color(red: 0.07, green: 0.07, blue: 0.18)
    /// Card/surface background
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.22)
    /// Elevated surface
    static let surfaceElevated = Color(red: 0.13, green: 0.13, blue: 0.26)

    /// Primary aurora green
    static let auroraGreen = Color(red: 0.18, green: 0.87, blue: 0.56)
    /// Aurora teal/cyan
    static let auroraTeal = Color(red: 0.15, green: 0.78, blue: 0.82)
    /// Aurora blue
    static let auroraBlue = Color(red: 0.25, green: 0.47, blue: 0.95)
    /// Aurora purple/violet
    static let auroraPurple = Color(red: 0.58, green: 0.30, blue: 0.95)
    /// Aurora pink/magenta
    static let auroraPink = Color(red: 0.85, green: 0.25, blue: 0.65)
    /// Aurora warm (rare reddish aurora)
    static let auroraWarm = Color(red: 0.95, green: 0.45, blue: 0.30)

    /// Primary text on dark backgrounds
    static let textPrimary = Color(red: 0.93, green: 0.93, blue: 0.97)
    /// Secondary text
    static let textSecondary = Color(red: 0.62, green: 0.62, blue: 0.72)
    /// Tertiary/dimmed text
    static let textTertiary = Color(red: 0.40, green: 0.40, blue: 0.52)

    // MARK: - Gradients

    /// Main aurora gradient for backgrounds and large surfaces
    static let auroraGradient = LinearGradient(
        colors: [auroraPurple.opacity(0.6), auroraBlue.opacity(0.4), auroraTeal.opacity(0.5), auroraGreen.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle shimmer gradient for navigation bars
    static let navBarGradient = LinearGradient(
        colors: [deepSpace, cosmos.opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Accent gradient for buttons and interactive elements
    static let accentGradient = LinearGradient(
        colors: [auroraTeal, auroraGreen],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Secondary accent gradient
    static let secondaryGradient = LinearGradient(
        colors: [auroraBlue, auroraPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Warm accent gradient
    static let warmGradient = LinearGradient(
        colors: [auroraPink, auroraWarm],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Book Cover Palettes

    static let coverPalettes: [[Color]] = [
        [auroraPurple, auroraBlue],
        [auroraBlue, auroraTeal],
        [auroraTeal, auroraGreen],
        [auroraPink, auroraPurple],
        [auroraWarm, auroraPink],
        [auroraGreen, auroraTeal],
        [auroraBlue, auroraPurple.opacity(0.8)],
        [auroraPink.opacity(0.8), auroraBlue],
    ]

    static func coverGradient(for title: String) -> LinearGradient {
        let index = abs(title.hashValue) % coverPalettes.count
        return LinearGradient(
            colors: coverPalettes[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Component Styles

    /// Glowing border effect for focused/selected items
    static func glowBorder(color: Color = auroraTeal, radius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .strokeBorder(color.opacity(0.6), lineWidth: 1.5)
            .shadow(color: color.opacity(0.3), radius: 6)
    }

    /// Frosted glass material for overlays
    static let frostedGlass = Material.ultraThinMaterial

    // MARK: - Tab Bar

    static let tabBarBackground = Color(red: 0.05, green: 0.05, blue: 0.14).opacity(0.95)
    static let tabActive = auroraTeal
    static let tabInactive = textTertiary
}

// MARK: - Aurora View Modifiers

struct AuroraBackgroundModifier: ViewModifier {
    var style: AuroraBackgroundStyle = .standard

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    AuroraTheme.deepSpace.ignoresSafeArea()

                    switch style {
                    case .standard:
                        standardAurora
                    case .subtle:
                        subtleAurora
                    case .vibrant:
                        vibrantAurora
                    }
                }
            }
    }

    private var standardAurora: some View {
        ZStack {
            // Top-left green/teal glow
            Circle()
                .fill(AuroraTheme.auroraGreen.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            // Center blue glow
            Circle()
                .fill(AuroraTheme.auroraBlue.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 50, y: -50)

            // Bottom-right purple glow
            Circle()
                .fill(AuroraTheme.auroraPurple.opacity(0.10))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 100, y: 200)
        }
        .ignoresSafeArea()
    }

    private var subtleAurora: some View {
        Circle()
            .fill(AuroraTheme.auroraTeal.opacity(0.06))
            .frame(width: 400, height: 400)
            .blur(radius: 100)
            .offset(x: -50, y: -150)
            .ignoresSafeArea()
    }

    private var vibrantAurora: some View {
        ZStack {
            Circle()
                .fill(AuroraTheme.auroraGreen.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: -250)

            Circle()
                .fill(AuroraTheme.auroraTeal.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: 80, y: -100)

            Circle()
                .fill(AuroraTheme.auroraBlue.opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -60, y: 100)

            Circle()
                .fill(AuroraTheme.auroraPurple.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 100, y: 300)
        }
        .ignoresSafeArea()
    }
}

enum AuroraBackgroundStyle {
    case standard
    case subtle
    case vibrant
}

extension View {
    func auroraBackground(_ style: AuroraBackgroundStyle = .standard) -> some View {
        modifier(AuroraBackgroundModifier(style: style))
    }
}

// MARK: - Aurora Button Style

struct AuroraButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AuroraTheme.accentGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(gradient, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: AuroraTheme.auroraTeal.opacity(0.3), radius: configuration.isPressed ? 2 : 8)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Aurora Card Modifier

struct AuroraCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AuroraTheme.surface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

extension View {
    func auroraCard() -> some View {
        modifier(AuroraCardModifier())
    }
}
